#!/bin/sh
# Entrypoint for muse-ai-bot on Northflank.
# Secrets are read ONLY from environment variables set in Northflank.
# Never put a token or cookies in this file, in the repo, or in chat.
set -e

mkdir -p "$HOME/.config/muse-cli"
chmod 700 "$HOME/.config/muse-cli" || true

# Start the server-browser cookie renewal loop in the background.
# It starts headless Chrome, tries `muse-cli auth export` every 6h,
# and never blocks the bot itself.
if [ -x /renew-cookies.sh ]; then
  nohup /renew-cookies.sh >/tmp/renew-cookies.log 2>&1 &
fi

# Optional: muse.ai cookies as one line, e.g. "hatch_sess=...; other=..."
# If not set, the bot starts with the token only and the owner can
# send fresh cookies later with /login in Telegram.
if [ -n "$MUSE_COOKIES" ]; then
  printf '%s\n' "$MUSE_COOKIES" > "$HOME/.config/muse-cli/cookies.txt"
  chmod 600 "$HOME/.config/muse-cli/cookies.txt"
fi

# First run only: if telegram.json does not exist yet and a token is
# provided as a Northflank secret, run setup with the token piped in.
# muse-cli documents this: `muse-cli telegram setup < token.txt`
# The token is never a command-line argument.
if [ ! -f "$HOME/.config/muse-cli/telegram.json" ] && [ -n "$TELEGRAM_BOT_TOKEN" ]; then
  printf '%s' "$TELEGRAM_BOT_TOKEN" | muse-cli telegram setup
fi

# Allow extra Telegram users without re-pairing: TELEGRAM_ALLOWED_USER_IDS
# is a comma-separated list of numeric Telegram user ids, set as a
# Northflank secret. On every start, merge them into telegram.json's
# allowed_user_ids (owner and token are preserved). The bot reads the
# config at startup, so a restart/redeploy applies the change.
if [ -n "$TELEGRAM_ALLOWED_USER_IDS" ] && [ -f "$HOME/.config/muse-cli/telegram.json" ]; then
  TELEGRAM_ALLOWED_USER_IDS="$TELEGRAM_ALLOWED_USER_IDS" python3 -c '
import json, os
p = os.path.expanduser("~/.config/muse-cli/telegram.json")
with open(p) as f:
    conf = json.load(f)
allowed = set(int(x) for x in (conf.get("allowed_user_ids") or []))
for x in os.environ["TELEGRAM_ALLOWED_USER_IDS"].split(","):
    x = x.strip()
    if x:
        allowed.add(int(x))
if conf.get("owner_id"):
    allowed.add(int(conf["owner_id"]))
conf["allowed_user_ids"] = sorted(allowed)
with open(p, "w") as f:
    json.dump(conf, f)
os.chmod(p, 0o600)
print("allowed Telegram users:", conf["allowed_user_ids"])
'
fi

# Run the bot in the foreground. Northflank restarts it if it stops.
exec muse-cli telegram run
