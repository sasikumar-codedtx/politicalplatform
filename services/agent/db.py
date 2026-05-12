import os
import psycopg2
import psycopg2.extras
from contextlib import contextmanager
from datetime import datetime, timezone

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://app:devpassword123@localhost:5432/political_platform"
)


def _utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _connect():
    conn = psycopg2.connect(DATABASE_URL)
    conn.autocommit = False
    return conn


@contextmanager
def get_conn():
    conn = _connect()
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def init_db() -> None:
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("CREATE EXTENSION IF NOT EXISTS vector;")
            cur.execute("""
                CREATE TABLE IF NOT EXISTS chat_sessions (
                    id TEXT PRIMARY KEY,
                    title TEXT NOT NULL DEFAULT 'New conversation',
                    persona TEXT NOT NULL,
                    flavor_id TEXT,
                    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
                    last_active_at TIMESTAMPTZ NOT NULL DEFAULT now(),
                    last_message TEXT NOT NULL DEFAULT ''
                );
            """)
            cur.execute("""
                CREATE TABLE IF NOT EXISTS chat_messages (
                    id BIGSERIAL PRIMARY KEY,
                    session_id TEXT NOT NULL REFERENCES chat_sessions(id) ON DELETE CASCADE,
                    role TEXT NOT NULL CHECK (role IN ('system', 'user', 'assistant')),
                    content TEXT NOT NULL,
                    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
                );
            """)
            cur.execute("""
                CREATE INDEX IF NOT EXISTS idx_chat_messages_session
                ON chat_messages(session_id, created_at ASC, id ASC);
            """)


def ensure_session(session_id: str, persona: str, flavor_id: str | None = None) -> bool:
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT id FROM chat_sessions WHERE id = %s", (session_id,))
            if cur.fetchone():
                return False

            now = _utc_now()
            cur.execute(
                """
                INSERT INTO chat_sessions (id, persona, flavor_id, created_at, last_active_at)
                VALUES (%s, %s, %s, %s, %s)
                """,
                (session_id, persona, flavor_id, now, now),
            )
            cur.execute(
                """
                INSERT INTO chat_messages (session_id, role, content, created_at)
                VALUES (%s, 'system', %s, %s)
                """,
                (session_id, persona, now),
            )
            return True


def add_message(session_id: str, role: str, content: str) -> None:
    now = _utc_now()
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO chat_messages (session_id, role, content, created_at)
                VALUES (%s, %s, %s, %s)
                """,
                (session_id, role, content, now),
            )
            if role == 'assistant':
                cur.execute(
                    """
                    UPDATE chat_sessions
                    SET last_active_at = %s, last_message = %s
                    WHERE id = %s
                    """,
                    (now, content, session_id),
                )
            else:
                cur.execute(
                    "UPDATE chat_sessions SET last_active_at = %s WHERE id = %s",
                    (now, session_id),
                )


def set_session_title_if_default(session_id: str, title: str) -> None:
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                UPDATE chat_sessions SET title = %s
                WHERE id = %s AND title = 'New conversation'
                """,
                (title, session_id),
            )


def get_session_messages(session_id: str, include_system: bool = True) -> list[dict]:
    query = """
        SELECT role, content, created_at
        FROM chat_messages
        WHERE session_id = %s
    """
    if not include_system:
        query += " AND role != 'system'"
    query += " ORDER BY created_at ASC, id ASC"

    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(query, (session_id,))
            return [
                {
                    "role": row["role"],
                    "content": row["content"],
                    "timestamp": row["created_at"].isoformat() if hasattr(row["created_at"], "isoformat") else str(row["created_at"]),
                }
                for row in cur.fetchall()
            ]


def list_sessions() -> list[dict]:
    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute("""
                SELECT id, title, created_at, last_active_at, last_message
                FROM chat_sessions
                ORDER BY last_active_at DESC, created_at DESC
            """)
            return [
                {
                    "id": row["id"],
                    "title": row["title"],
                    "created_at": row["created_at"].isoformat() if hasattr(row["created_at"], "isoformat") else str(row["created_at"]),
                    "last_active_at": row["last_active_at"].isoformat() if hasattr(row["last_active_at"], "isoformat") else str(row["last_active_at"]),
                    "last_message": row["last_message"],
                }
                for row in cur.fetchall()
            ]


def delete_session(session_id: str) -> bool:
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM chat_sessions WHERE id = %s", (session_id,))
            return cur.rowcount > 0
