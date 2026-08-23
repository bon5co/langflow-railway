"""Re-apply the deploy's superuser password on every boot.

Langflow creates the superuser only once (``get_or_create_super_user`` returns
None when the user already exists) and its ``langflow superuser`` CLI requires
an auth token when AUTO_LOGIN is off, so there is no upstream path to change the
password afterwards. A fresh Railway deploy has no SMTP either, which means the
emailed-reset path does not exist. Writing the hash here makes a redeploy a
working password reset.

Runs before the server starts. If the database has no ``user`` table yet (first
boot), it does nothing and Langflow's own startup seeds the account from the
same environment variables.
"""

import os
import sys

from lfx.services.settings.auth import AuthSettings
from sqlalchemy import create_engine, text

username = os.environ["LANGFLOW_SUPERUSER"]
password = os.environ["LANGFLOW_SUPERUSER_PASSWORD"]
url = os.environ.get("LANGFLOW_DATABASE_URL", "")

if not url:
    print("[rotate] no LANGFLOW_DATABASE_URL; skipping", flush=True)
    sys.exit(0)

if url.startswith("postgres://"):
    url = "postgresql://" + url[len("postgres://") :]

hashed = AuthSettings(CONFIG_DIR=os.environ["LANGFLOW_CONFIG_DIR"]).pwd_context.hash(password)

try:
    engine = create_engine(url, pool_pre_ping=True)
    with engine.begin() as conn:
        exists = conn.execute(text("SELECT to_regclass('public.\"user\"')")).scalar()
        if not exists:
            print("[rotate] user table absent (first boot); Langflow will seed it", flush=True)
            sys.exit(0)
        result = conn.execute(
            text(
                'UPDATE "user" SET password = :p, is_active = true, is_superuser = true '
                "WHERE username = :u"
            ),
            {"p": hashed, "u": username},
        )
        print(f"[rotate] superuser rows updated: {result.rowcount}", flush=True)
except Exception as exc:  # noqa: BLE001 - a rotation failure must not block the boot
    print(f"[rotate] skipped: {exc}", flush=True)
