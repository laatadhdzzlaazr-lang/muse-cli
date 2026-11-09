#!/bin/sh
# Entrypoint for muse-ai-bot on Northflank.
# Secrets are read ONLY from environment variables set in Northflank.
# Never put a token or cookies in this file, in the repo, or in chat.
set -e

mkdir -p "$HOME/.config/muse-cli"
chmod 700 "$HOME/.config/muse-cli" || true

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

# Run the bot in the foreground. Northflank restarts it if it stops.
exec muse-cli telegram run
