import os
from pathlib import Path
import psycopg2
import psycopg2.extras
from contextlib import contextmanager
from datetime import datetime, timezone
from dotenv import load_dotenv

# Defensive .env load — db.py can be imported before agent.py in some entry
# paths (alembic, scripts, the gateway). Absolute path keeps this robust to
# whatever cwd uvicorn ends up using.
_ENV_PATH = Path(__file__).resolve().parents[2] / ".env"
if _ENV_PATH.exists():
    load_dotenv(_ENV_PATH)

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
                    user_id TEXT,
                    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
                    last_active_at TIMESTAMPTZ NOT NULL DEFAULT now(),
                    last_message TEXT NOT NULL DEFAULT ''
                );
            """)
            # Safe migration: add user_id column if it doesn't exist yet
            cur.execute("""
                ALTER TABLE chat_sessions
                ADD COLUMN IF NOT EXISTS user_id TEXT;
            """)
            cur.execute("""
                CREATE INDEX IF NOT EXISTS idx_chat_sessions_user
                ON chat_sessions(user_id, last_active_at DESC);
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
            cur.execute("""
                CREATE TABLE IF NOT EXISTS documents (
                    id         BIGSERIAL PRIMARY KEY,
                    flavor_id  TEXT NOT NULL,
                    title      TEXT NOT NULL,
                    content    TEXT NOT NULL,
                    embedding  vector(768),
                    source     TEXT,
                    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
                );
            """)
            cur.execute("""
                CREATE INDEX IF NOT EXISTS idx_documents_flavor
                ON documents(flavor_id);
            """)
            cur.execute("""
                CREATE INDEX IF NOT EXISTS idx_documents_embedding
                ON documents USING ivfflat (embedding vector_cosine_ops)
                WITH (lists = 10);
            """)
            cur.execute("""
                CREATE TABLE IF NOT EXISTS audit_logs (
                    id          BIGSERIAL PRIMARY KEY,
                    action      TEXT NOT NULL,
                    entity_type TEXT,
                    entity_id   TEXT,
                    metadata    JSONB,
                    status      TEXT NOT NULL DEFAULT 'success',
                    error_msg   TEXT,
                    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
                );
            """)
            cur.execute("""
                CREATE INDEX IF NOT EXISTS idx_audit_logs_created
                ON audit_logs(created_at DESC);
            """)
            cur.execute("""
                CREATE TABLE IF NOT EXISTS prompts (
                    key         TEXT PRIMARY KEY,
                    content     TEXT NOT NULL,
                    category    TEXT NOT NULL DEFAULT 'misc',
                    label       TEXT NOT NULL DEFAULT '',
                    description TEXT NOT NULL DEFAULT '',
                    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
                );
            """)
            cur.execute("""
                CREATE INDEX IF NOT EXISTS idx_prompts_category
                ON prompts(category);
            """)
            cur.execute("""
                CREATE TABLE IF NOT EXISTS avatars (
                    id              TEXT PRIMARY KEY,
                    flavor_id       TEXT,
                    name            TEXT NOT NULL DEFAULT '',
                    face_avatar_id  TEXT,
                    piper_voice_id  TEXT,
                    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
                );
            """)
            # Migration: drop legacy columns from earlier avatar paths
            # (Sketchfab embed, D-ID, RPM GLB, photo→GLB placeholder). Existing
            # rows lose their data here, which is intended — those paths are
            # gone. Wrapped in DO blocks so it's idempotent.
            for col in ("photo_filename", "source_url", "embed_url",
                        "did_source_url", "did_voice_id", "needs_regeneration"):
                cur.execute(f"ALTER TABLE avatars DROP COLUMN IF EXISTS {col};")
            # Ensure the kept columns exist (covers upgrades from the cleanup-
            # era schema where face_avatar_id / piper_voice_id were ADDs).
            cur.execute("ALTER TABLE avatars ADD COLUMN IF NOT EXISTS face_avatar_id TEXT;")
            cur.execute("ALTER TABLE avatars ADD COLUMN IF NOT EXISTS piper_voice_id TEXT;")
            cur.execute("""
                CREATE INDEX IF NOT EXISTS idx_avatars_flavor
                ON avatars(flavor_id, created_at DESC);
            """)
    _seed_prompts_if_empty()


def _seed_prompts_if_empty() -> None:
    """Seed the prompts table on first run using the bundled factory defaults.

    Each row is inserted with ON CONFLICT DO NOTHING — once a key exists the
    admin UI owns it, and subsequent startups never overwrite admin edits.
    Label/description are kept in sync with the seed file via the UPDATE so
    that UI metadata stays current even after admins edit the content.
    """
    from seed_prompts import SEED_PROMPTS
    with get_conn() as conn:
        with conn.cursor() as cur:
            for key, spec in SEED_PROMPTS.items():
                cur.execute(
                    """
                    INSERT INTO prompts (key, content, category, label, description)
                    VALUES (%s, %s, %s, %s, %s)
                    ON CONFLICT (key) DO UPDATE
                        SET category    = EXCLUDED.category,
                            label       = EXCLUDED.label,
                            description = EXCLUDED.description
                    """,
                    (key, spec["content"], spec["category"], spec["label"], spec["description"]),
                )


def get_prompt_content(key: str) -> str | None:
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT content FROM prompts WHERE key = %s", (key,))
            row = cur.fetchone()
            return row[0] if row else None


def upsert_prompt(key: str, content: str) -> None:
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                UPDATE prompts SET content = %s, updated_at = now()
                WHERE key = %s
                """,
                (content, key),
            )
            if cur.rowcount == 0:
                cur.execute(
                    """
                    INSERT INTO prompts (key, content, category, label, description)
                    VALUES (%s, %s, 'misc', %s, '')
                    """,
                    (key, content, key),
                )


def list_prompts() -> list[dict]:
    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute("""
                SELECT key, content, category, label, description, updated_at
                FROM prompts ORDER BY category ASC, key ASC
            """)
            return [
                {
                    "key":         row["key"],
                    "content":     row["content"],
                    "category":    row["category"],
                    "label":       row["label"],
                    "description": row["description"],
                    "updated_at":  row["updated_at"].isoformat() if hasattr(row["updated_at"], "isoformat") else str(row["updated_at"]),
                }
                for row in cur.fetchall()
            ]


def delete_prompt(key: str) -> bool:
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM prompts WHERE key = %s", (key,))
            return cur.rowcount > 0


def ensure_session(session_id: str, persona: str, flavor_id: str | None = None, user_id: str | None = None) -> bool:
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT id FROM chat_sessions WHERE id = %s", (session_id,))
            if cur.fetchone():
                return False

            now = _utc_now()
            cur.execute(
                """
                INSERT INTO chat_sessions (id, persona, flavor_id, user_id, created_at, last_active_at)
                VALUES (%s, %s, %s, %s, %s, %s)
                """,
                (session_id, persona, flavor_id, user_id, now, now),
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


def list_sessions(user_id: str | None = None) -> list[dict]:
    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            if user_id:
                cur.execute("""
                    SELECT id, title, created_at, last_active_at, last_message, user_id
                    FROM chat_sessions
                    WHERE user_id = %s
                    ORDER BY last_active_at DESC, created_at DESC
                """, (user_id,))
            else:
                cur.execute("""
                    SELECT id, title, created_at, last_active_at, last_message, user_id
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
                    "user_id": row["user_id"],
                }
                for row in cur.fetchall()
            ]


def delete_session(session_id: str) -> bool:
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM chat_sessions WHERE id = %s", (session_id,))
            return cur.rowcount > 0


# ── Document / RAG functions ──────────────────────────────────────────────────

def embedding_to_str(embedding: list[float]) -> str:
    return "[" + ",".join(str(x) for x in embedding) + "]"


def upsert_document(flavor_id: str, title: str, content: str, embedding: list[float], source: str | None = None) -> int:
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO documents (flavor_id, title, content, embedding, source)
                VALUES (%s, %s, %s, %s::vector, %s)
                RETURNING id
                """,
                (flavor_id, title, content, embedding_to_str(embedding), source),
            )
            return cur.fetchone()[0]


def list_documents(flavor_id: str | None = None) -> list[dict]:
    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            if flavor_id:
                cur.execute(
                    "SELECT id, flavor_id, title, source, created_at, LEFT(content, 200) AS preview FROM documents WHERE flavor_id = %s ORDER BY id DESC",
                    (flavor_id,),
                )
            else:
                cur.execute(
                    "SELECT id, flavor_id, title, source, created_at, LEFT(content, 200) AS preview FROM documents ORDER BY id DESC"
                )
            return [
                {
                    **dict(row),
                    "created_at": row["created_at"].isoformat() if hasattr(row["created_at"], "isoformat") else str(row["created_at"]),
                }
                for row in cur.fetchall()
            ]


def delete_document(doc_id: int) -> bool:
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM documents WHERE id = %s", (doc_id,))
            return cur.rowcount > 0


def search_documents(flavor_id: str, query_embedding: list[float], top_k: int = 3) -> list[dict]:
    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(
                """
                SELECT title, content, source,
                       1 - (embedding <=> %s::vector) AS similarity
                FROM documents
                WHERE flavor_id = %s
                ORDER BY embedding <=> %s::vector
                LIMIT %s
                """,
                (embedding_to_str(query_embedding), flavor_id, embedding_to_str(query_embedding), top_k),
            )
            return [dict(row) for row in cur.fetchall()]


def document_count(flavor_id: str) -> int:
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT COUNT(*) FROM documents WHERE flavor_id = %s", (flavor_id,))
            return cur.fetchone()[0]


# ── Audit log functions ───────────────────────────────────────────────────────

import json as _json

def audit(action: str, entity_type: str | None = None, entity_id: str | None = None,
          metadata: dict | None = None, status: str = "success", error_msg: str | None = None) -> None:
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    INSERT INTO audit_logs (action, entity_type, entity_id, metadata, status, error_msg)
                    VALUES (%s, %s, %s, %s, %s, %s)
                    """,
                    (action, entity_type, str(entity_id) if entity_id else None,
                     _json.dumps(metadata) if metadata else None, status, error_msg),
                )
    except Exception:
        pass  # Never let audit logging break the main flow


# ── Avatar functions ──────────────────────────────────────────────────────────

def register_avatar(avatar_id: str, name: str, flavor_id: str | None,
                    face_avatar_id: str | None = None,
                    piper_voice_id: str | None = None) -> None:
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO avatars (id, flavor_id, name, face_avatar_id, piper_voice_id)
                VALUES (%s, %s, %s, %s, %s)
                """,
                (avatar_id, flavor_id, name, face_avatar_id, piper_voice_id),
            )


_AVATAR_COLS = "id, flavor_id, name, face_avatar_id, piper_voice_id, created_at"


def list_avatars(flavor_id: str | None = None) -> list[dict]:
    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            if flavor_id:
                cur.execute(
                    f"SELECT {_AVATAR_COLS} FROM avatars WHERE flavor_id = %s ORDER BY created_at DESC",
                    (flavor_id,),
                )
            else:
                cur.execute(f"SELECT {_AVATAR_COLS} FROM avatars ORDER BY created_at DESC")
            return [_avatar_row_to_dict(row) for row in cur.fetchall()]


def get_avatar(avatar_id: str) -> dict | None:
    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(f"SELECT {_AVATAR_COLS} FROM avatars WHERE id = %s", (avatar_id,))
            row = cur.fetchone()
            return _avatar_row_to_dict(row) if row else None


def _avatar_row_to_dict(row) -> dict:
    return {
        **dict(row),
        "created_at": row["created_at"].isoformat() if hasattr(row["created_at"], "isoformat") else str(row["created_at"]),
    }


def delete_avatar(avatar_id: str) -> dict | None:
    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(
                "DELETE FROM avatars WHERE id = %s RETURNING id",
                (avatar_id,),
            )
            row = cur.fetchone()
            return dict(row) if row else None


def list_audit_logs(limit: int = 100) -> list[dict]:
    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(
                "SELECT id, action, entity_type, entity_id, metadata, status, error_msg, created_at FROM audit_logs ORDER BY created_at DESC LIMIT %s",
                (limit,),
            )
            return [
                {
                    **dict(row),
                    "metadata": row["metadata"] if isinstance(row["metadata"], dict) else (_json.loads(row["metadata"]) if row["metadata"] else None),
                    "created_at": row["created_at"].isoformat() if hasattr(row["created_at"], "isoformat") else str(row["created_at"]),
                }
                for row in cur.fetchall()
            ]
