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


def _iso(value) -> str:
    return value.isoformat() if hasattr(value, "isoformat") else str(value)


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
            # User profiles — keyed by Firebase uid. Photo bytes live here so
            # the same login shows the same photo/name on every device.
            cur.execute("""
                CREATE TABLE IF NOT EXISTS user_profiles (
                    uid         TEXT PRIMARY KEY,
                    name        TEXT NOT NULL DEFAULT '',
                    city        TEXT NOT NULL DEFAULT '',
                    avatar      BYTEA,
                    avatar_mime TEXT,
                    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
                );
            """)
            # Citizen complaints — per uid, with a status an admin can advance.
            cur.execute("""
                CREATE TABLE IF NOT EXISTS complaints (
                    id          BIGSERIAL PRIMARY KEY,
                    uid         TEXT NOT NULL,
                    title       TEXT NOT NULL,
                    description TEXT NOT NULL DEFAULT '',
                    category    TEXT NOT NULL DEFAULT 'General',
                    status      TEXT NOT NULL DEFAULT 'Pending',
                    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
                );
            """)
            cur.execute("""
                CREATE INDEX IF NOT EXISTS idx_complaints_uid
                ON complaints(uid, created_at DESC);
            """)
            # TVK membership — the Join form. serial drives the printed member id.
            # One login can register several members (family / booth sign-ups),
            # so uid is NOT unique — serial is the key.
            cur.execute("""
                CREATE TABLE IF NOT EXISTS members (
                    uid        TEXT NOT NULL,
                    serial     BIGSERIAL,
                    name       TEXT NOT NULL DEFAULT '',
                    email      TEXT NOT NULL DEFAULT '',
                    mobile     TEXT NOT NULL DEFAULT '',
                    dob        TEXT NOT NULL DEFAULT '',
                    gender     TEXT NOT NULL DEFAULT '',
                    district   TEXT NOT NULL DEFAULT '',
                    pin        TEXT NOT NULL DEFAULT '',
                    booth      TEXT NOT NULL DEFAULT '',
                    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
                );
            """)
            # Migrate the old one-member-per-login shape (uid was the PK).
            cur.execute("ALTER TABLE members DROP CONSTRAINT IF EXISTS members_pkey;")
            cur.execute("""
                DO $$ BEGIN
                    IF NOT EXISTS (
                        SELECT 1 FROM pg_constraint
                        WHERE conrelid = 'members'::regclass AND contype = 'p'
                    ) THEN
                        ALTER TABLE members ADD PRIMARY KEY (serial);
                    END IF;
                END $$;
            """)
            cur.execute("CREATE INDEX IF NOT EXISTS idx_members_uid ON members(uid);")
    _seed_prompts_if_empty()


# ── User profile ──────────────────────────────────────────────────────────────

def get_profile(uid: str) -> dict:
    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(
                "SELECT name, city, (avatar IS NOT NULL) AS has_avatar, updated_at "
                "FROM user_profiles WHERE uid = %s",
                (uid,),
            )
            row = cur.fetchone()
            if not row:
                return {"name": "", "city": "", "has_avatar": False, "updated_at": None}
            return {
                "name": row["name"],
                "city": row["city"],
                "has_avatar": row["has_avatar"],
                "updated_at": _iso(row["updated_at"]) if row["updated_at"] else None,
            }


def upsert_profile(uid: str, name: str | None, city: str | None) -> None:
    with get_conn() as conn:
        with conn.cursor() as cur:
            # INSERT coalesces NULL→'' to satisfy NOT NULL on first write. The
            # UPDATE uses the RAW params (NULL when a field was omitted) so a
            # partial update keeps the other field instead of blanking it.
            cur.execute(
                """
                INSERT INTO user_profiles (uid, name, city, updated_at)
                VALUES (%s, COALESCE(%s, ''), COALESCE(%s, ''), now())
                ON CONFLICT (uid) DO UPDATE SET
                    name = COALESCE(%s, user_profiles.name),
                    city = COALESCE(%s, user_profiles.city),
                    updated_at = now()
                """,
                (uid, name, city, name, city),
            )


def set_profile_avatar(uid: str, data: bytes, mime: str) -> None:
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO user_profiles (uid, avatar, avatar_mime, updated_at)
                VALUES (%s, %s, %s, now())
                ON CONFLICT (uid) DO UPDATE SET
                    avatar = EXCLUDED.avatar,
                    avatar_mime = EXCLUDED.avatar_mime,
                    updated_at = now()
                """,
                (uid, psycopg2.Binary(data), mime),
            )


def get_profile_avatar(uid: str) -> tuple[bytes, str] | None:
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT avatar, avatar_mime FROM user_profiles WHERE uid = %s", (uid,))
            row = cur.fetchone()
            if not row or row[0] is None:
                return None
            return bytes(row[0]), (row[1] or "image/jpeg")


# ── Complaints ──────────────────────────────────────────────────────────────

def add_complaint(uid: str, title: str, description: str, category: str) -> dict:
    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(
                """
                INSERT INTO complaints (uid, title, description, category)
                VALUES (%s, %s, %s, %s)
                RETURNING id, title, description, category, status, created_at
                """,
                (uid, title, description, category),
            )
            row = cur.fetchone()
            return {
                "id": row["id"],
                "title": row["title"],
                "description": row["description"],
                "category": row["category"],
                "status": row["status"],
                "created_at": _iso(row["created_at"]),
            }


def _member_row_to_dict(row: dict) -> dict:
    return {
        "member_id": f"TVK-2026-{str(row['serial']).zfill(8)}",
        "name": row["name"],
        "email": row["email"],
        "mobile": row["mobile"],
        "dob": row["dob"],
        "gender": row["gender"],
        "district": row["district"],
        "booth": row["booth"],
        "pin": row["pin"],
        "created_at": _iso(row["created_at"]),
    }


_MEMBER_COLS = ("serial, name, email, mobile, dob, gender, district, pin, booth, created_at")


def add_member(uid: str, name: str, email: str, mobile: str, dob: str,
               gender: str, district: str, pin: str, booth: str) -> dict:
    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(
                f"""
                INSERT INTO members (uid, name, email, mobile, dob, gender, district, pin, booth)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                RETURNING {_MEMBER_COLS}
                """,
                (uid, name, email, mobile, dob, gender, district, pin, booth),
            )
            return _member_row_to_dict(cur.fetchone())


def list_members(uid: str) -> list[dict]:
    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(
                f"SELECT {_MEMBER_COLS} FROM members WHERE uid = %s ORDER BY serial",
                (uid,),
            )
            return [_member_row_to_dict(r) for r in cur.fetchall()]


def get_member(uid: str) -> dict | None:
    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(
                f"SELECT {_MEMBER_COLS} FROM members WHERE uid = %s "
                "ORDER BY serial DESC LIMIT 1",
                (uid,),
            )
            row = cur.fetchone()
            return _member_row_to_dict(row) if row else None


def list_complaints(uid: str) -> list[dict]:
    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(
                """
                SELECT id, title, description, category, status, created_at
                FROM complaints WHERE uid = %s ORDER BY created_at DESC
                """,
                (uid,),
            )
            return [
                {
                    "id": row["id"],
                    "title": row["title"],
                    "description": row["description"],
                    "category": row["category"],
                    "status": row["status"],
                    "created_at": _iso(row["created_at"]),
                }
                for row in cur.fetchall()
            ]


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
                    "updated_at":  _iso(row["updated_at"]),
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
                    "timestamp": _iso(row["created_at"]),
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
                    "created_at": _iso(row["created_at"]),
                    "last_active_at": _iso(row["last_active_at"]),
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
                    "created_at": _iso(row["created_at"]),
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
        "created_at": _iso(row["created_at"]),
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
                    "created_at": _iso(row["created_at"]),
                }
                for row in cur.fetchall()
            ]
