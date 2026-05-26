import sqlite3

DATABASE_NAME = "game.db"

def get_connection():

    conn = sqlite3.connect(DATABASE_NAME)

    conn.row_factory = sqlite3.Row

    return conn

def init_database():

    conn = get_connection()

    cursor = conn.cursor()

    cursor.execute("""
    CREATE TABLE IF NOT EXISTS players (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE,
        coins INTEGER DEFAULT 0,
        level INTEGER DEFAULT 1
    )
    """)

    conn.commit()
    conn.close()
