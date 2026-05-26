from flask import Flask, request, jsonify
from database import init_database, get_connection
import sqlite3
import random
import string

rooms = {}
app = Flask(__name__)

init_database()

@app.route("/status")
def status():
    return {"ok": True}

@app.route("/login", methods=["POST"])
def login():

    data = request.json

    username = data.get("username")

    conn = get_connection()

    cursor = conn.cursor()

    cursor.execute(
        "SELECT * FROM players WHERE username = ?",
        (username,)
    )

    player = cursor.fetchone()

    conn.close()

    if player is None:

        return jsonify({
            "success": False,
            "message": "Player not found"
        }), 404

    return jsonify({
        "success": True,
        "player": {
            "id": player["id"],
            "username": player["username"],
            "coins": player["coins"],
            "level": player["level"]
        }
    })
@app.route("/leaderboard")
def leaderboard():

    conn = get_connection()

    cursor = conn.cursor()

    cursor.execute("""
    SELECT username, coins, level
    FROM players
    ORDER BY coins DESC
    LIMIT 10
    """)

    players = cursor.fetchall()

    conn.close()

    result = []

    for player in players:

        result.append({
            "username": player["username"],
            "coins": player["coins"],
            "level": player["level"]
        })

    return jsonify({
        "success": True,
        "leaderboard": result
    })

@app.route("/create_room", methods=["POST"])
def create_room():

    data = request.json
    player_id = data["player_id"]

    room_code = ''.join(random.choices(string.ascii_uppercase, k=4))

    rooms[room_code] = {
        "players": [player_id],
        "moves": []
    }

    return jsonify({
        "success": True,
        "room_code": room_code
    })
    
@app.route("/join_room", methods=["POST"])
def join_room():

    data = request.json

    player_id = data["player_id"]
    room_code = data["room_code"]

    if room_code not in rooms:
        return jsonify({
            "success": False,
            "message": "Room not found"
        })

    rooms[room_code]["players"].append(player_id)

    return jsonify({
        "success": True
    })

@app.route("/send_move", methods=["POST"])
def send_move():

    data = request.json

    room_code = data["room_code"]

    move_data = {
        "player_id": data["player_id"],
        "move": data["move"]
    }

    rooms[room_code]["moves"].append(move_data)

    return jsonify({
        "success": True
    })

@app.route("/get_moves/<room_code>", methods=["GET"])
def get_moves(room_code):

    if room_code not in rooms:
        return jsonify({
            "success": False
        })

    return jsonify({
        "success": True,
        "moves": rooms[room_code]["moves"]
    })

@app.post("/submit_word")
def submit_word():
    data = request.get_json()

    room_code = data.get("room_code")
    player_id = data.get("player_id")
    word = data.get("word", "").strip()

    if room_code not in rooms:
        return jsonify(success=False, reason="room_not_found")

    room = rooms[room_code]

    if "taken_words" not in room:
        room["taken_words"] = set()
    if "scores" not in room:
        room["scores"] = {}
    if "moves" not in room:
        room["moves"] = []

    if word in room["taken_words"]:
        return jsonify(success=False, reason="already_taken")

    # ✅ امتیاز (قابل تغییر)
    score = len(word) * 2

    room["taken_words"].add(word)
    room["scores"][player_id] = room["scores"].get(player_id, 0) + score

    room["moves"].append({
        "player_id": player_id,
        "word": word,
        "score": score
    })

    return jsonify(
        success=True,
        score_added=score,
        total_score=room["scores"][player_id]
    )

@app.route("/update_player", methods=["POST"])
def update_player():

    data = request.json

    player_id = data.get("id")
    coins = data.get("coins")
    level = data.get("level")

    conn = get_connection()

    cursor = conn.cursor()

    cursor.execute("""
    UPDATE players
    SET coins = ?, level = ?
    WHERE id = ?
    """, (coins, level, player_id))

    conn.commit()

    conn.close()

    return jsonify({
        "success": True
    })

@app.route("/register", methods=["POST"])
def register():

    data = request.json

    username = data.get("username")

    if not username:
        return jsonify({
            "success": False,
            "message": "Username is required"
        }), 400

    try:

        conn = get_connection()

        cursor = conn.cursor()

        cursor.execute(
            "INSERT INTO players (username) VALUES (?)",
            (username,)
        )

        conn.commit()

        player_id = cursor.lastrowid

        conn.close()

        return jsonify({
            "success": True,
            "player_id": player_id
        })

    except sqlite3.IntegrityError:

        return jsonify({
            "success": False,
            "message": "Username already exists"
        }), 400

app.run(host="0.0.0.0", port=8000)
