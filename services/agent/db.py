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
            cur.execute("ALTER TABLE complaints ADD COLUMN IF NOT EXISTS device_id TEXT NOT NULL DEFAULT '';")
            cur.execute("CREATE INDEX IF NOT EXISTS idx_complaints_device ON complaints(device_id);")
            cur.execute("""
                CREATE INDEX IF NOT EXISTS idx_complaints_uid
                ON complaints(uid, created_at DESC);
            """)
            # Optional evidence file (image / pdf / zip / anything) per complaint.
            cur.execute("ALTER TABLE complaints ADD COLUMN IF NOT EXISTS attachment BYTEA;")
            cur.execute("ALTER TABLE complaints ADD COLUMN IF NOT EXISTS attachment_name TEXT NOT NULL DEFAULT '';")
            cur.execute("ALTER TABLE complaints ADD COLUMN IF NOT EXISTS attachment_mime TEXT NOT NULL DEFAULT '';")
            # TVK membership — the Join form. serial drives the printed member id.
            # One login can register several members (family / booth sign-ups),
            # so uid is NOT unique — serial is the key. device_id lets a
            # not-logged-in citizen register on their phone; on login those
            # rows are adopted (uid stamped) so they sync across devices.
            cur.execute("""
                CREATE TABLE IF NOT EXISTS members (
                    uid        TEXT NOT NULL DEFAULT '',
                    device_id  TEXT NOT NULL DEFAULT '',
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
            cur.execute("ALTER TABLE members ALTER COLUMN uid SET DEFAULT '';")
            cur.execute("ALTER TABLE members ADD COLUMN IF NOT EXISTS device_id TEXT NOT NULL DEFAULT '';")
            cur.execute("CREATE INDEX IF NOT EXISTS idx_members_uid ON members(uid);")
            cur.execute("CREATE INDEX IF NOT EXISTS idx_members_device ON members(device_id);")
            # Community polls — anyone (logged in or by device) can create + vote.
            cur.execute("""
                CREATE TABLE IF NOT EXISTS polls (
                    id            BIGSERIAL PRIMARY KEY,
                    flavor_id     TEXT NOT NULL DEFAULT '',
                    question      TEXT NOT NULL,
                    options       JSONB NOT NULL DEFAULT '[]',
                    duration_days INT NOT NULL DEFAULT 2,
                    creator       TEXT NOT NULL DEFAULT '',
                    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
                );
            """)
            cur.execute("CREATE INDEX IF NOT EXISTS idx_polls_flavor ON polls(flavor_id, created_at DESC);")
            # One row per (poll, voter). voter is a uid when logged in, else a
            # device id — adopted onto the uid on login, same as members.
            cur.execute("""
                CREATE TABLE IF NOT EXISTS poll_votes (
                    poll_id      BIGINT NOT NULL REFERENCES polls(id) ON DELETE CASCADE,
                    voter        TEXT NOT NULL,
                    option_index INT NOT NULL,
                    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
                    PRIMARY KEY (poll_id, voter)
                );
            """)
            cur.execute("CREATE INDEX IF NOT EXISTS idx_poll_votes_voter ON poll_votes(voter);")
            # Forum (community wall) — posts, likes and comments are shared by
            # every user, so counts are real instead of phone-local.
            cur.execute("""
                CREATE TABLE IF NOT EXISTS forum_posts (
                    id         BIGSERIAL PRIMARY KEY,
                    flavor_id  TEXT NOT NULL DEFAULT '',
                    author     TEXT NOT NULL DEFAULT '',
                    user_name  TEXT NOT NULL DEFAULT '',
                    body       TEXT NOT NULL DEFAULT '',
                    media_type TEXT NOT NULL DEFAULT 'none',
                    media_url  TEXT NOT NULL DEFAULT '',
                    status     TEXT NOT NULL DEFAULT 'approved',
                    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
                );
            """)
            cur.execute("CREATE INDEX IF NOT EXISTS idx_forum_posts_flavor ON forum_posts(flavor_id, created_at DESC);")
            # Official posts mirrored from the channel's YouTube Posts tab.
            cur.execute("ALTER TABLE forum_posts ADD COLUMN IF NOT EXISTS external_id TEXT NOT NULL DEFAULT '';")
            cur.execute("ALTER TABLE forum_posts ADD COLUMN IF NOT EXISTS link_url TEXT NOT NULL DEFAULT '';")
            cur.execute("ALTER TABLE forum_posts ADD COLUMN IF NOT EXISTS is_official BOOLEAN NOT NULL DEFAULT FALSE;")
            cur.execute(
                "CREATE UNIQUE INDEX IF NOT EXISTS idx_forum_posts_external "
                "ON forum_posts(external_id) WHERE external_id <> '';"
            )
            # Uploaded attachment (image/video) for member posts.
            cur.execute("ALTER TABLE forum_posts ADD COLUMN IF NOT EXISTS media BYTEA;")
            cur.execute("ALTER TABLE forum_posts ADD COLUMN IF NOT EXISTS media_mime TEXT NOT NULL DEFAULT '';")
            cur.execute("""
                CREATE TABLE IF NOT EXISTS forum_likes (
                    post_id    BIGINT NOT NULL REFERENCES forum_posts(id) ON DELETE CASCADE,
                    voter      TEXT NOT NULL,
                    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
                    PRIMARY KEY (post_id, voter)
                );
            """)
            cur.execute("CREATE INDEX IF NOT EXISTS idx_forum_likes_voter ON forum_likes(voter);")
            cur.execute("""
                CREATE TABLE IF NOT EXISTS forum_comments (
                    id         BIGSERIAL PRIMARY KEY,
                    post_id    BIGINT NOT NULL REFERENCES forum_posts(id) ON DELETE CASCADE,
                    author     TEXT NOT NULL DEFAULT '',
                    user_name  TEXT NOT NULL DEFAULT '',
                    body       TEXT NOT NULL DEFAULT '',
                    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
                );
            """)
            cur.execute("CREATE INDEX IF NOT EXISTS idx_forum_comments_post ON forum_comments(post_id, created_at DESC);")
            # Campaign toolkit — admin-published posters / media / slogans /
            # hashtags per flavor. Public read; admin writes.
            cur.execute("""
                CREATE TABLE IF NOT EXISTS toolkit_items (
                    id         BIGSERIAL PRIMARY KEY,
                    flavor_id  TEXT NOT NULL DEFAULT '',
                    kind       TEXT NOT NULL DEFAULT 'Posters',
                    title      TEXT NOT NULL DEFAULT '',
                    image_url  TEXT NOT NULL DEFAULT '',
                    link_url   TEXT NOT NULL DEFAULT '',
                    subtitle   TEXT NOT NULL DEFAULT '',
                    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
                );
            """)
            cur.execute("CREATE INDEX IF NOT EXISTS idx_toolkit_flavor_kind ON toolkit_items(flavor_id, kind, created_at DESC);")
            # Admin-published content — News + Events (CMS). Public read per flavor.
            cur.execute("""
                CREATE TABLE IF NOT EXISTS news (
                    id           BIGSERIAL PRIMARY KEY,
                    flavor_id    TEXT NOT NULL DEFAULT '',
                    title        TEXT NOT NULL,
                    summary      TEXT NOT NULL DEFAULT '',
                    category     TEXT NOT NULL DEFAULT 'Party',
                    image_url    TEXT NOT NULL DEFAULT '',
                    published_at TIMESTAMPTZ NOT NULL DEFAULT now()
                );
            """)
            cur.execute("CREATE INDEX IF NOT EXISTS idx_news_flavor ON news(flavor_id, published_at DESC);")
            cur.execute("""
                CREATE TABLE IF NOT EXISTS events (
                    id         BIGSERIAL PRIMARY KEY,
                    flavor_id  TEXT NOT NULL DEFAULT '',
                    title      TEXT NOT NULL,
                    description TEXT NOT NULL DEFAULT '',
                    location   TEXT NOT NULL DEFAULT '',
                    event_type TEXT NOT NULL DEFAULT 'Event',
                    image_url  TEXT NOT NULL DEFAULT '',
                    starts_at  TIMESTAMPTZ NOT NULL DEFAULT now()
                );
            """)
            cur.execute("CREATE INDEX IF NOT EXISTS idx_events_flavor ON events(flavor_id, starts_at DESC);")
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

def _adopt_complaints(cur, uid: str, device_id: str) -> None:
    """Move complaints raised on this device before login onto the account."""
    if not uid or not device_id:
        return
    cur.execute(
        "UPDATE complaints SET uid = %s WHERE device_id = %s "
        "AND (uid = '' OR uid IS NULL)",
        (uid, device_id),
    )


def add_complaint(uid: str, device_id: str, title: str, description: str,
                  category: str,
                  attachment: bytes | None = None, attachment_name: str = "",
                  attachment_mime: str = "") -> dict:
    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(
                """
                INSERT INTO complaints (uid, device_id, title, description, category,
                                        attachment, attachment_name, attachment_mime)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                RETURNING id, title, description, category, status, created_at, attachment_name
                """,
                (uid, device_id, title, description, category,
                 psycopg2.Binary(attachment) if attachment else None,
                 attachment_name, attachment_mime),
            )
            row = cur.fetchone()
            return {
                "id": row["id"],
                "title": row["title"],
                "description": row["description"],
                "category": row["category"],
                "status": row["status"],
                "created_at": _iso(row["created_at"]),
                "has_attachment": bool(row["attachment_name"]),
                "attachment_name": row["attachment_name"],
            }


def get_complaint_attachment(uid: str, device_id: str,
                             complaint_id: int) -> tuple[bytes, str, str] | None:
    with get_conn() as conn:
        with conn.cursor() as cur:
            if uid:
                _adopt_complaints(cur, uid, device_id)
                where, args = "uid = %s", (complaint_id, uid)
            else:
                where = "device_id = %s AND (uid = '' OR uid IS NULL)"
                args = (complaint_id, device_id)
            cur.execute(
                "SELECT attachment, attachment_mime, attachment_name FROM complaints "
                f"WHERE id = %s AND {where}",
                args,
            )
            row = cur.fetchone()
            if not row or row[0] is None:
                return None
            return bytes(row[0]), (row[1] or "application/octet-stream"), (row[2] or "file")


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


def _adopt_members(cur, uid: str, device_id: str) -> None:
    """Stamp this device's anonymous member rows onto the logged-in account so
    they sync across the user's other devices. Idempotent — hits 0 rows once
    stamped. Ownership MOVES (not shared) so a co-user of the same phone never
    sees another account's members."""
    if not uid or not device_id:
        return
    cur.execute(
        "UPDATE members SET uid = %s WHERE device_id = %s AND (uid = '' OR uid IS NULL)",
        (uid, device_id),
    )


def add_member(uid: str, device_id: str, name: str, email: str, mobile: str, dob: str,
               gender: str, district: str, pin: str, booth: str) -> dict:
    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(
                f"""
                INSERT INTO members (uid, device_id, name, email, mobile, dob, gender, district, pin, booth)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                RETURNING {_MEMBER_COLS}
                """,
                (uid, device_id, name, email, mobile, dob, gender, district, pin, booth),
            )
            return _member_row_to_dict(cur.fetchone())


def list_members(uid: str, device_id: str) -> list[dict]:
    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            if uid:
                _adopt_members(cur, uid, device_id)
                cur.execute(
                    f"SELECT {_MEMBER_COLS} FROM members WHERE uid = %s ORDER BY serial",
                    (uid,),
                )
            else:
                cur.execute(
                    f"SELECT {_MEMBER_COLS} FROM members "
                    "WHERE device_id = %s AND (uid = '' OR uid IS NULL) ORDER BY serial",
                    (device_id,),
                )
            return [_member_row_to_dict(r) for r in cur.fetchall()]


def get_member(uid: str, device_id: str) -> dict | None:
    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            if uid:
                _adopt_members(cur, uid, device_id)
                cur.execute(
                    f"SELECT {_MEMBER_COLS} FROM members WHERE uid = %s "
                    "ORDER BY serial DESC LIMIT 1",
                    (uid,),
                )
            else:
                cur.execute(
                    f"SELECT {_MEMBER_COLS} FROM members "
                    "WHERE device_id = %s AND (uid = '' OR uid IS NULL) "
                    "ORDER BY serial DESC LIMIT 1",
                    (device_id,),
                )
            row = cur.fetchone()
            return _member_row_to_dict(row) if row else None


# ── Polls ─────────────────────────────────────────────────────────────────────

def _adopt_poll_votes(cur, uid: str, device_id: str) -> None:
    """Move this device's anonymous votes onto the logged-in account. Dedupe
    first: if the account already voted on a poll this device also voted on,
    drop the device row so the (poll_id, voter) PK move can't collide."""
    if not uid or not device_id:
        return
    cur.execute(
        "DELETE FROM poll_votes WHERE voter = %s AND poll_id IN "
        "(SELECT poll_id FROM poll_votes WHERE voter = %s)",
        (device_id, uid),
    )
    cur.execute("UPDATE poll_votes SET voter = %s WHERE voter = %s", (uid, device_id))
    cur.execute("UPDATE polls SET creator = %s WHERE creator = %s", (uid, device_id))


def _voter(cur, uid: str, device_id: str) -> str:
    """Effective vote identity: the uid when logged in (adopting any device
    votes first), else the device id."""
    if uid:
        _adopt_poll_votes(cur, uid, device_id)
        return uid
    return device_id or ""


def add_poll(flavor_id: str, question: str, options: list[str],
             duration_days: int, creator: str) -> dict:
    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(
                """
                INSERT INTO polls (flavor_id, question, options, duration_days, creator)
                VALUES (%s, %s, %s, %s, %s)
                RETURNING id, question, options, duration_days, created_at
                """,
                (flavor_id, question, psycopg2.extras.Json(options), duration_days, creator),
            )
            return _poll_row_to_dict(cur.fetchone(), None)


def list_polls(flavor_id: str, uid: str, device_id: str) -> list[dict]:
    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            voter = _voter(cur, uid, device_id)
            cur.execute(
                """
                SELECT p.id, p.question, p.options, p.duration_days, p.created_at,
                       (SELECT COUNT(*) FROM poll_votes v WHERE v.poll_id = p.id) AS responses,
                       (SELECT v.option_index FROM poll_votes v
                        WHERE v.poll_id = p.id AND v.voter = %s) AS my_vote
                FROM polls p
                WHERE p.flavor_id = %s
                ORDER BY p.created_at DESC
                """,
                (voter, flavor_id),
            )
            return [_poll_row_to_dict(r, r["my_vote"]) for r in cur.fetchall()]


def vote_poll(poll_id: int, voter: str, option_index: int) -> None:
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO poll_votes (poll_id, voter, option_index)
                VALUES (%s, %s, %s)
                ON CONFLICT (poll_id, voter)
                DO UPDATE SET option_index = EXCLUDED.option_index
                """,
                (poll_id, voter, option_index),
            )


def count_polls_participated(uid: str, device_id: str) -> int:
    with get_conn() as conn:
        with conn.cursor() as cur:
            voter = _voter(cur, uid, device_id)
            if not voter:
                return 0
            cur.execute(
                "SELECT COUNT(DISTINCT poll_id) FROM poll_votes WHERE voter = %s",
                (voter,),
            )
            return int(cur.fetchone()[0])


def _poll_row_to_dict(row: dict, my_vote: int | None) -> dict:
    created = row["created_at"]
    days_left = row["duration_days"]
    if created is not None:
        elapsed = (datetime.now(timezone.utc) - created).days
        days_left = max(0, row["duration_days"] - elapsed)
    return {
        "id": row["id"],
        "question": row["question"],
        "options": row["options"] or [],
        "responses": int(row.get("responses") or 0),
        "days_left": days_left,
        "my_vote": my_vote,
    }


def _adopt_forum(cur, uid: str, device_id: str) -> None:
    """Move this device's anonymous forum activity onto the logged-in account."""
    if not uid or not device_id:
        return
    cur.execute(
        "DELETE FROM forum_likes WHERE voter = %s AND post_id IN "
        "(SELECT post_id FROM forum_likes WHERE voter = %s)",
        (device_id, uid),
    )
    cur.execute("UPDATE forum_likes SET voter = %s WHERE voter = %s", (uid, device_id))
    cur.execute("UPDATE forum_posts SET author = %s WHERE author = %s", (uid, device_id))
    cur.execute("UPDATE forum_comments SET author = %s WHERE author = %s", (uid, device_id))


def forum_actor(uid: str, device_id: str) -> str:
    """Effective forum identity, adopting device activity on login."""
    with get_conn() as conn:
        with conn.cursor() as cur:
            if uid:
                _adopt_forum(cur, uid, device_id)
                return uid
            return device_id or ""


def _forum_row_to_dict(row: dict) -> dict:
    created = row["created_at"]
    # An uploaded attachment is served from our own endpoint; the app builds the
    # absolute URL from `has_media`. `media_url` stays for official (YouTube)
    # posts that carry a remote thumbnail.
    has_media = bool(row.get("has_media")) or row.get("media") is not None
    return {
        "id": str(row["id"]),
        "user_id": row["author"],
        "user_name": row["user_name"],
        "text": row["body"],
        "media_type": row["media_type"],
        "media_url": row["media_url"],
        "has_media": has_media,
        "status": row["status"],
        "like_count": int(row.get("like_count") or 0),
        "comment_count": int(row.get("comment_count") or 0),
        "liked": bool(row.get("liked")),
        "link_url": row.get("link_url") or "",
        "is_official": bool(row.get("is_official")),
        "created_at": created.isoformat() if created else None,
    }


def upsert_official_post(flavor_id: str, external_id: str, user_name: str,
                         body: str, media_type: str, media_url: str,
                         link_url: str, created_at) -> None:
    """Insert a channel post once; later syncs only refresh its content."""
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO forum_posts
                    (flavor_id, author, user_name, body, media_type, media_url,
                     status, external_id, link_url, is_official, created_at)
                VALUES (%s, 'official', %s, %s, %s, %s, 'approved', %s, %s, TRUE, %s)
                ON CONFLICT (external_id) WHERE external_id <> ''
                DO UPDATE SET body = EXCLUDED.body,
                              media_type = EXCLUDED.media_type,
                              media_url = EXCLUDED.media_url,
                              user_name = EXCLUDED.user_name
                """,
                (flavor_id, user_name, body, media_type, media_url,
                 external_id, link_url, created_at),
            )


def list_forum_posts(flavor_id: str, actor: str, status: str = "",
                     mine_only: bool = False) -> list[dict]:
    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            # Never SELECT the media bytes in a list — only whether one exists.
            sql = """
                SELECT p.id, p.author, p.user_name, p.body, p.media_type,
                       p.media_url, p.status, p.link_url, p.is_official, p.created_at,
                       (p.media IS NOT NULL) AS has_media,
                       (SELECT COUNT(*) FROM forum_likes l WHERE l.post_id = p.id) AS like_count,
                       (SELECT COUNT(*) FROM forum_comments c WHERE c.post_id = p.id) AS comment_count,
                       EXISTS (SELECT 1 FROM forum_likes l
                               WHERE l.post_id = p.id AND l.voter = %s) AS liked
                FROM forum_posts p
                WHERE p.flavor_id = %s
            """
            params: list = [actor, flavor_id]
            if status:
                sql += " AND p.status = %s"
                params.append(status)
            if mine_only:
                sql += " AND p.author = %s"
                params.append(actor)
            sql += " ORDER BY p.created_at DESC"
            cur.execute(sql, tuple(params))
            return [_forum_row_to_dict(r) for r in cur.fetchall()]


def add_forum_post(flavor_id: str, author: str, user_name: str, body: str,
                   media_type: str, media_url: str, status: str,
                   media: bytes | None = None, media_mime: str = "") -> dict:
    # An uploaded file wins over a URL and sets the media type from its mime.
    if media:
        media_type = "video" if media_mime.startswith("video") else "image"
        media_url = ""
    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(
                """
                INSERT INTO forum_posts
                    (flavor_id, author, user_name, body, media_type, media_url,
                     status, media, media_mime)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                RETURNING id, author, user_name, body, media_type, media_url,
                          status, link_url, is_official, created_at,
                          (media IS NOT NULL) AS has_media
                """,
                (flavor_id, author, user_name, body, media_type, media_url, status,
                 psycopg2.Binary(media) if media else None, media_mime),
            )
            return _forum_row_to_dict(cur.fetchone())


def get_forum_media(post_id: int) -> tuple[bytes, str] | None:
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT media, media_mime FROM forum_posts WHERE id = %s",
                        (post_id,))
            row = cur.fetchone()
            if not row or row[0] is None:
                return None
            return bytes(row[0]), (row[1] or "application/octet-stream")


def delete_forum_post(post_id: int, actor: str) -> None:
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "DELETE FROM forum_posts WHERE id = %s AND author = %s",
                (post_id, actor),
            )


def set_forum_post_status(post_id: int, status: str) -> None:
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "UPDATE forum_posts SET status = %s WHERE id = %s", (status, post_id)
            )


def toggle_forum_like(post_id: int, voter: str) -> dict:
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "DELETE FROM forum_likes WHERE post_id = %s AND voter = %s",
                (post_id, voter),
            )
            liked = cur.rowcount == 0
            if liked:
                cur.execute(
                    "INSERT INTO forum_likes (post_id, voter) VALUES (%s, %s)",
                    (post_id, voter),
                )
            cur.execute(
                "SELECT COUNT(*) FROM forum_likes WHERE post_id = %s", (post_id,)
            )
            return {"liked": liked, "like_count": int(cur.fetchone()[0])}


def list_forum_comments(post_id: int) -> list[dict]:
    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(
                """
                SELECT id, post_id, author, user_name, body, created_at
                FROM forum_comments WHERE post_id = %s ORDER BY created_at DESC
                """,
                (post_id,),
            )
            return [
                {
                    "id": str(r["id"]),
                    "post_id": str(r["post_id"]),
                    "user_id": r["author"],
                    "user_name": r["user_name"],
                    "text": r["body"],
                    "created_at": r["created_at"].isoformat() if r["created_at"] else None,
                }
                for r in cur.fetchall()
            ]


def add_forum_comment(post_id: int, author: str, user_name: str, body: str) -> dict:
    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(
                """
                INSERT INTO forum_comments (post_id, author, user_name, body)
                VALUES (%s, %s, %s, %s)
                RETURNING id, post_id, author, user_name, body, created_at
                """,
                (post_id, author, user_name, body),
            )
            r = cur.fetchone()
            return {
                "id": str(r["id"]),
                "post_id": str(r["post_id"]),
                "user_id": r["author"],
                "user_name": r["user_name"],
                "text": r["body"],
                "created_at": r["created_at"].isoformat() if r["created_at"] else None,
            }


def _toolkit_row(row: dict) -> dict:
    return {
        "id": str(row["id"]),
        "kind": row["kind"],
        "title": row["title"],
        "image_url": row["image_url"],
        "link_url": row["link_url"],
        "subtitle": row["subtitle"],
    }


def list_toolkit_items(flavor_id: str, kind: str = "") -> list[dict]:
    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            if kind:
                cur.execute(
                    "SELECT * FROM toolkit_items WHERE flavor_id = %s AND kind = %s "
                    "ORDER BY created_at DESC", (flavor_id, kind))
            else:
                cur.execute(
                    "SELECT * FROM toolkit_items WHERE flavor_id = %s "
                    "ORDER BY kind, created_at DESC", (flavor_id,))
            return [_toolkit_row(r) for r in cur.fetchall()]


def add_toolkit_item(flavor_id: str, kind: str, title: str, image_url: str,
                     link_url: str, subtitle: str) -> dict:
    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(
                """
                INSERT INTO toolkit_items
                    (flavor_id, kind, title, image_url, link_url, subtitle)
                VALUES (%s, %s, %s, %s, %s, %s) RETURNING *
                """,
                (flavor_id, kind, title, image_url, link_url, subtitle),
            )
            return _toolkit_row(cur.fetchone())


def delete_toolkit_item(item_id: int) -> None:
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM toolkit_items WHERE id = %s", (item_id,))


def list_complaints(uid: str, device_id: str = "") -> list[dict]:
    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            # Logged in: everything on the account (adopting this device's
            # pre-login complaints first). Not logged in: this device only.
            if uid:
                _adopt_complaints(cur, uid, device_id)
                where, arg = "uid = %s", uid
            else:
                where = "device_id = %s AND (uid = '' OR uid IS NULL)"
                arg = device_id
            cur.execute(
                f"""
                SELECT id, title, description, category, status, created_at, attachment_name
                FROM complaints WHERE {where} ORDER BY created_at DESC
                """,
                (arg,),
            )
            return [
                {
                    "id": row["id"],
                    "title": row["title"],
                    "description": row["description"],
                    "category": row["category"],
                    "status": row["status"],
                    "created_at": _iso(row["created_at"]),
                    "has_attachment": bool(row["attachment_name"]),
                    "attachment_name": row["attachment_name"],
                }
                for row in cur.fetchall()
            ]


def list_all_complaints() -> list[dict]:
    """Every complaint, for the admin panel."""
    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(
                """
                SELECT id, title, description, category, status, created_at,
                       attachment_name
                FROM complaints ORDER BY created_at DESC
                """
            )
            return [
                {
                    "id": row["id"],
                    "title": row["title"],
                    "description": row["description"],
                    "category": row["category"],
                    "status": row["status"],
                    "created_at": _iso(row["created_at"]),
                    "has_attachment": bool(row["attachment_name"]),
                    "attachment_name": row["attachment_name"],
                }
                for row in cur.fetchall()
            ]


def set_complaint_status(complaint_id: int, status: str) -> None:
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "UPDATE complaints SET status = %s WHERE id = %s",
                (status, complaint_id),
            )


# ── News + Events (admin CMS) ─────────────────────────────────────────────────

def _fmt_date(dt) -> str:
    return f"{dt.strftime('%b')} {dt.day}, {dt.year}"


def _fmt_time(dt) -> str:
    return dt.strftime("%I:%M %p").lstrip("0").lower()


def add_news(flavor_id: str, title: str, summary: str, category: str, image_url: str) -> dict:
    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(
                """
                INSERT INTO news (flavor_id, title, summary, category, image_url)
                VALUES (%s, %s, %s, %s, %s)
                RETURNING id, title, summary, category, image_url, published_at
                """,
                (flavor_id, title, summary, category, image_url),
            )
            return _news_row_to_dict(cur.fetchone())


def list_news(flavor_id: str, limit: int = 50) -> list[dict]:
    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(
                """
                SELECT id, title, summary, category, image_url, published_at
                FROM news WHERE flavor_id = %s ORDER BY published_at DESC LIMIT %s
                """,
                (flavor_id, limit),
            )
            return [_news_row_to_dict(r) for r in cur.fetchall()]


def delete_news(news_id: int) -> bool:
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM news WHERE id = %s", (news_id,))
            return cur.rowcount > 0


def _news_row_to_dict(row: dict) -> dict:
    dt = row["published_at"]
    return {
        "id": str(row["id"]),
        "title": row["title"],
        "summary": row["summary"],
        "category": row["category"],
        "image_url": row["image_url"],
        "date": _fmt_date(dt),
        "time": _fmt_time(dt),
    }


def add_event(flavor_id: str, title: str, description: str, location: str,
              event_type: str, image_url: str, starts_at) -> dict:
    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(
                """
                INSERT INTO events (flavor_id, title, description, location, event_type, image_url, starts_at)
                VALUES (%s, %s, %s, %s, %s, %s, COALESCE(%s::timestamptz, now()))
                RETURNING id, title, description, location, event_type, image_url, starts_at
                """,
                (flavor_id, title, description, location, event_type, image_url, starts_at),
            )
            return _event_row_to_dict(cur.fetchone())


def list_events(flavor_id: str, limit: int = 50) -> list[dict]:
    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(
                """
                SELECT id, title, description, location, event_type, image_url, starts_at
                FROM events WHERE flavor_id = %s ORDER BY starts_at DESC LIMIT %s
                """,
                (flavor_id, limit),
            )
            return [_event_row_to_dict(r) for r in cur.fetchall()]


def delete_event(event_id: int) -> bool:
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM events WHERE id = %s", (event_id,))
            return cur.rowcount > 0


def _event_row_to_dict(row: dict) -> dict:
    dt = row["starts_at"]
    return {
        "id": str(row["id"]),
        "title": row["title"],
        "description": row["description"],
        "location": row["location"],
        "type": row["event_type"],
        "image_url": row["image_url"],
        "date": _fmt_date(dt),
        "time": _fmt_time(dt),
    }


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
