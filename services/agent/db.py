import os
import sqlite3
from contextlib import contextmanager
from datetime import datetime, timezone
from pathlib import Path


DB_PATH = Path(os.getenv("CHAT_DB_PATH", Path(__file__).with_name("chat.db")))


def _utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _connect() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


@contextmanager
def get_conn():
    conn = _connect()
    try:
        yield conn
        conn.commit()
    finally:
        conn.close()


def init_db() -> None:
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)

    with get_conn() as conn:
        conn.executescript(
            """
            CREATE TABLE IF NOT EXISTS chat_sessions (
                id TEXT PRIMARY KEY,
                title TEXT NOT NULL DEFAULT 'New conversation',
                persona TEXT NOT NULL,
                flavor_id TEXT,
                created_at TEXT NOT NULL,
                last_active_at TEXT NOT NULL,
                last_message TEXT NOT NULL DEFAULT ''
            );

            CREATE TABLE IF NOT EXISTS chat_messages (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                session_id TEXT NOT NULL,
                role TEXT NOT NULL CHECK (role IN ('system', 'user', 'assistant')),
                content TEXT NOT NULL,
                created_at TEXT NOT NULL,
                FOREIGN KEY (session_id) REFERENCES chat_sessions(id) ON DELETE CASCADE
            );

            CREATE INDEX IF NOT EXISTS idx_chat_messages_session_created
            ON chat_messages(session_id, created_at, id);
            """
        )


def ensure_session(session_id: str, persona: str, flavor_id: str | None = None) -> bool:
    with get_conn() as conn:
        existing = conn.execute(
            "SELECT id FROM chat_sessions WHERE id = ?",
            (session_id,),
        ).fetchone()
        if existing:
            return False

        now = _utc_now()
        conn.execute(
            """
            INSERT INTO chat_sessions (id, persona, flavor_id, created_at, last_active_at)
            VALUES (?, ?, ?, ?, ?)
            """,
            (session_id, persona, flavor_id, now, now),
        )
        conn.execute(
            """
            INSERT INTO chat_messages (session_id, role, content, created_at)
            VALUES (?, 'system', ?, ?)
            """,
            (session_id, persona, now),
        )
        return True


def add_message(session_id: str, role: str, content: str) -> None:
    now = _utc_now()
    with get_conn() as conn:
        conn.execute(
            """
            INSERT INTO chat_messages (session_id, role, content, created_at)
            VALUES (?, ?, ?, ?)
            """,
            (session_id, role, content, now),
        )
        conn.execute(
            """
            UPDATE chat_sessions
            SET last_active_at = ?, last_message = CASE WHEN ? = 'assistant' THEN ? ELSE last_message END
            WHERE id = ?
            """,
            (now, role, content, session_id),
        )


def set_session_title_if_default(session_id: str, title: str) -> None:
    with get_conn() as conn:
        conn.execute(
            """
            UPDATE chat_sessions
            SET title = ?
            WHERE id = ? AND title = 'New conversation'
            """,
            (title, session_id),
        )


def get_session_messages(session_id: str, include_system: bool = True) -> list[dict]:
    query = """
        SELECT role, content, created_at
        FROM chat_messages
        WHERE session_id = ?
    """
    params: list[str] = [session_id]
    if not include_system:
        query += " AND role != 'system'"
    query += " ORDER BY created_at ASC, id ASC"

    with get_conn() as conn:
        rows = conn.execute(query, params).fetchall()
        return [
            {
                "role": row["role"],
                "content": row["content"],
                "timestamp": row["created_at"],
            }
            for row in rows
        ]


def list_sessions() -> list[dict]:
    with get_conn() as conn:
        rows = conn.execute(
            """
            SELECT id, title, created_at, last_active_at, last_message
            FROM chat_sessions
            ORDER BY last_active_at DESC, created_at DESC
            """
        ).fetchall()
        return [dict(row) for row in rows]


def delete_session(session_id: str) -> bool:
    with get_conn() as conn:
        result = conn.execute(
            "DELETE FROM chat_sessions WHERE id = ?",
            (session_id,),
        )
        return result.rowcount > 0
