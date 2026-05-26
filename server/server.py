from flask import Flask, request
from flask_socketio import SocketIO, emit, join_room, leave_room
import random
import string
import json
import uuid

# Load levels from levels.json
with open("levels.json", "r", encoding="utf-8") as f:
    LEVELS = json.load(f)

app = Flask(__name__)
app.config['SECRET_KEY'] = 'secret!'
socketio = SocketIO(app, cors_allowed_origins="*")

# Dictionary to store room data
# room_code: {
#   "players": { player_id: { "sid": sid, "name": name, "score": 0 } },
#   "puzzle": { "grid": [...], "words": { "WORD1": score, "WORD2": score } },
#   "puzzle_words_details": { "WORD1": score, ... } # A copy of words for faster lookup
#   "taken_words": { "WORD1": player_id_who_took_it, ... },
#   "game_over": False
# }
rooms = {}

# Helper function to generate a unique room code
def generate_room_code(length=6):
    while True:
        code = ''.join(random.choices(string.ascii_uppercase + string.digits, k=length))
        if code not in rooms:
            return code

# Helper to get player ID by session ID (sid)
def get_player_id_by_sid(room_code, sid):
    room = rooms.get(room_code)
    if not room:
        return None
    for player_id, p_data in room["players"].items():
        if p_data["sid"] == sid:
            return player_id
    return None

# Helper to get the opponent's ID
def get_opponent_id(room_code, current_player_id):
    room = rooms.get(room_code)
    if not room:
        return None
    for player_id in room["players"]:
        if player_id != current_player_id:
            return player_id
    return None

@socketio.on('create_room')
def create_room(data):
    player_name = data.get("player_name")

    if not player_name:
        emit("error", {"message": "Invalid player name"})
        return

    # Select a random puzzle
    puzzle = random.choice(LEVELS)

    # Generate room code
    room_code = generate_room_code()

    # Initialize room data
    player_id = str(uuid.uuid4())
    rooms[room_code] = {
        "players": {
            player_id: {"sid": request.sid, "name": player_name, "score": 0}
        },
        "puzzle": puzzle,
        "puzzle_words_details": puzzle["words"].copy(), # Store a copy for efficient lookup
        "taken_words": {},
        "game_over": False
    }

    # Join the socket to the room
    join_room(room_code)
    print(f"Room {room_code} created by {player_name} ({player_id}). SID: {request.sid}")

    # Emit success message to the creator
    emit("room_created", {
        "room_code": room_code,
        "player_id": player_id,
        "puzzle": puzzle # send the whole puzzle including grid and words
    })

@socketio.on("join_room")
def on_join_room(data):
    room_code = data.get("room_code")
    player_name = data.get("player_name", "Player2")

    if room_code not in rooms:
        emit("error", {"message": "Room not found"})
        return

    room = rooms[room_code]

    if len(room["players"]) >= 2:
        emit("error", {"message": "Room is full"})
        return

    # Generate player ID for the joining player
    player_id = str(uuid.uuid4())
    room["players"][player_id] = {
        "sid": request.sid,
        "name": player_name,
        "score": 0
    }

    join_room(room_code)
    print(f"Player {player_name} ({player_id}) joined room {room_code}. SID: {request.sid}")

    # Emit success message to the joining player
    emit("room_joined", {
        "room_code": room_code,
        "player_id": player_id,
        "puzzle": room["puzzle"],
        "players_in_room": {
            pid: {"name": pdata["name"], "score": pdata["score"]}
            for pid, pdata in room["players"].items()
        }
    })

    # Notify all other players in the room (the creator)
    emit("player_joined", {
        "player_id": player_id,
        "player_name": player_name
    }, room=room_code, include_self=False) # do not send to the joining player themselves

@socketio.on("submit_word")
def on_submit_word(data):
    room_code = data.get("room_code")
    word = data.get("word", "").strip().upper()

    if room_code not in rooms:
        emit("word_result", {
            "success": False,
            "message": "Room not found"
        })
        return

    room = rooms[room_code]

    if room["game_over"]:
        emit("word_result", {
            "success": False,
            "message": "Game is already over"
        })
        return

    player_id = get_player_id_by_sid(room_code, request.sid)
    if not player_id:
        emit("word_result", {
            "success": False,
            "message": "Player not found in room"
        })
        return

    # Check if word is valid for the puzzle
    if word not in room["puzzle_words_details"]:
        emit("word_result", {
            "success": False,
            "message": "Invalid word"
        })
        return

    # Check if word has already been taken
    if word in room["taken_words"]:
        # If the word is already taken, inform the player
        emit("word_result", {
            "success": False,
            "message": "Word already taken by another player" if room["taken_words"][word] != player_id else "You already found this word."
        })
        return

    points = room["puzzle_words_details"][word]
    room["taken_words"][word] = player_id # Mark word as taken by this player
    room["players"][player_id]["score"] += points

    print(f"Player {player_id} in room {room_code} submitted word '{word}' for {points} points.")

    # Prepare current scores for update
    current_scores = {
        pid: pdata["score"] for pid, pdata in room["players"].items()
    }

    # Emit to all in room that a word was found and scores are updated
    socketio.emit("word_found", {
        "success": True,
        "word": word,
        "points": points,
        "found_by_player_id": player_id,
        "scores": current_scores,
        "your_score": room["players"][player_id]["score"] # specific to the player who submitted
    }, room=room_code)

    # Check if all words are found (game over)
    if len(room["taken_words"]) == len(room["puzzle_words_details"]):
        room["game_over"] = True
        print(f"Game over for room {room_code}.")
        socketio.emit("game_over", {
            "scores": current_scores,
            "taken_words": room["taken_words"] # Show who took which word
        }, room=room_code)

@socketio.on("leave_room")
def on_leave_room(data):
    room_code = data.get("room_code")
    player_id = get_player_id_by_sid(room_code, request.sid)

    if room_code in rooms and player_id:
        leave_room(room_code)
        del rooms[room_code]["players"][player_id]
        print(f"Player {player_id} left room {room_code}.")

        emit("room_left", {"message": "You left the room."})

        # Notify others in the room
        if rooms[room_code]["players"]:
            socketio.emit("player_left", {
                "player_id": player_id,
                "message": f"Player {player_id} has left the room."
            }, room=room_code)
        else:
            # If room is empty, delete it
            del rooms[room_code]
            print(f"Room {room_code} is empty and deleted.")
    else:
        emit("error", {"message": "Could not leave room / Room or player not found."})
@socketio.on("test")
def test():
    puzzle = LEVELS[0]
    print("puzzles:",puzzle)
    emit("puzzle_data", puzzle)
    print('tesssssssssssssssst')
@socketio.on("disconnect")
def on_disconnect():
    print(f"Client disconnected: {request.sid}")
    for room_code, room in list(rooms.items()): # Iterate over a copy to allow deletion
        disconnected_player_id = None
        for player_id, p_data in room["players"].items():
            if p_data["sid"] == request.sid:
                disconnected_player_id = player_id
                break

        if disconnected_player_id:
            player_name = room["players"][disconnected_player_id]["name"]
            del room["players"][disconnected_player_id]
            print(f"Player {player_name} ({disconnected_player_id}) disconnected from room {room_code}.")

            if len(room["players"]) == 0:
                del rooms[room_code]
                print(f"Room {room_code} is empty and deleted after disconnect.")
            else:
                # Notify remaining players
                socketio.emit("player_disconnected", {
                    "player_id": disconnected_player_id,
                    "player_name": player_name,
                    "message": f"{player_name} has disconnected."
                }, room=room_code)
            break # Player found and processed, exit loop

@socketio.on("get_puzzle")
def get_puzzle(data):
    level_index = data.get("index", 0)

    puzzle = LEVELS[level_index]
    print("puzzles:",puzzle)
    emit("puzzle_data", puzzle)


if __name__ == "__main__":
    print("Starting Flask-SocketIO server on 0.0.0.0:5000")
    socketio.run(app, host="0.0.0.0", port=5010, debug=True)
