"""Tiny SQLite store with FAKE seed data (no real users)."""
import os
import sqlite3

DATA_DIR = os.path.join(os.path.dirname(__file__), "data")
DB_PATH = os.environ.get("DEMO_DB_PATH", os.path.join(DATA_DIR, "demo.db"))

SEED_USERS = [
    ("alice", "alice@example.invalid"),
    ("bob", "bob@example.invalid"),
    ("carol", "carol@example.invalid"),
]


def get_conn() -> sqlite3.Connection:
    return sqlite3.connect(DB_PATH)


def init_db() -> None:
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    with get_conn() as conn:
        conn.execute(
            "CREATE TABLE IF NOT EXISTS users ("
            "id INTEGER PRIMARY KEY, username TEXT UNIQUE, email TEXT, password_hash TEXT)"
        )
        conn.executemany(
            "INSERT OR IGNORE INTO users (username, email) VALUES (?, ?)", SEED_USERS
        )
