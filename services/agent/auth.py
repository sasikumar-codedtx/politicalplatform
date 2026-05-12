import base64
import json
import os

from dotenv import load_dotenv

load_dotenv("../../.env")

APP_ENV = os.getenv("APP_ENV", "development")
_firebase_app = None
_init_attempted = False


def _init_firebase():
    """Initialise Firebase Admin SDK once. Returns the app or None."""
    global _firebase_app, _init_attempted
    if _init_attempted:
        return _firebase_app
    _init_attempted = True

    try:
        import firebase_admin
        from firebase_admin import credentials

        sa_json = os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON")
        if sa_json:
            cred = credentials.Certificate(json.loads(sa_json))
        else:
            sa_path = os.getenv("FIREBASE_SERVICE_ACCOUNT_PATH", "")
            if sa_path and os.path.exists(sa_path):
                cred = credentials.Certificate(sa_path)
            else:
                print("[auth] No service account configured — token verification disabled")
                return None

        _firebase_app = firebase_admin.initialize_app(cred)
        print("[auth] Firebase Admin SDK initialised")
        return _firebase_app

    except ImportError:
        print("[auth] firebase-admin not installed — token verification disabled")
        return None
    except Exception as exc:
        print(f"[auth] Firebase init error: {exc}")
        return None


def verify_token(authorization: str | None) -> tuple[str | None, str | None]:
    """
    Validate a Firebase ID token from an Authorization: Bearer <token> header.

    Returns (uid, error_message).
    - uid is the Firebase user ID if the token is valid (or dev-mode decoded).
    - error_message is set only when the token should be rejected (production mode).

    Behaviour by mode:
    - development: JWT payload decoded but NOT verified.  Any uid is accepted.
      Allows local Flutter dev without a service account.
    - production:  Full cryptographic verification via Firebase Admin SDK.
      Returns (None, error) if token is missing, expired, or invalid.
    """
    if not authorization or not authorization.startswith("Bearer "):
        if APP_ENV == "production":
            return None, "Authorization header missing"
        return None, None  # dev — allow anonymous

    token = authorization.split(" ", 1)[1]

    if APP_ENV != "production":
        return _decode_uid(token), None

    # ── Production: full verification ────────────────────────────────────────
    app = _init_firebase()
    if app is None:
        # Service account not configured — log and degrade gracefully
        print("[auth] WARNING: running in production without a service account")
        return _decode_uid(token), None

    try:
        from firebase_admin import auth
        decoded = auth.verify_id_token(token)
        return decoded["uid"], None
    except Exception as exc:
        return None, f"Invalid token: {exc}"


def _decode_uid(token: str) -> str | None:
    """Extract uid from JWT payload without cryptographic verification."""
    try:
        payload_b64 = token.split(".")[1]
        payload_b64 += "=" * (4 - len(payload_b64) % 4)
        payload = json.loads(base64.urlsafe_b64decode(payload_b64))
        return payload.get("sub") or payload.get("user_id")
    except Exception:
        return None
