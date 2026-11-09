#!/bin/sh
# Renew muse.ai cookies from the Chrome running inside this server.
# This is the "server browser" renewal loop.
#
# How it works:
# - Starts headless Google Chrome with remote debugging on port 9222,
#   using the profile in /root/.config/chrome-profile.
# - Runs `muse-cli auth export`, which reads the muse.ai cookies from
#   that Chrome and saves them to ~/.config/muse-cli/cookies.txt.
# - Repeats every 6 hours.
#
# Honest limit: Chrome can only export cookies for a muse.ai login
# that already exists in its profile. This script cannot log in to
# muse.ai by itself: the first login must be done by a human in a
# browser window, with the account's password / verification if Meta
# asks for it. Until that first login exists in the server Chrome
# profile, auth export will fail with "No muse.ai tab" or
# "No hatch_sess", and the bot will keep asking for /login in Telegram.
# The Chrome profile must also survive restarts: on Northflank that
# needs a persistent volume mounted at /root/.config, otherwise a
# redeploy wipes the profile and the login with it.
while true; do
  echo "[renew] starting headless Chrome..."
  google-chrome --headless=new --no-sandbox --disable-gpu \
    --remote-debugging-port=9222 \
    --user-data-dir=/root/.config/chrome-profile \
    https://muse.ai/ >/tmp/chrome.log 2>&1 &
  CHROME_PID=$!
  sleep 10
  echo "[renew] running muse-cli auth export..."
  if muse-cli auth export; then
    echo "[renew] cookies renewed OK"
  else
    echo "[renew] auth export failed (no logged-in muse.ai tab yet?) - will retry in 6h"
  fi
  kill "$CHROME_PID" 2>/dev/null || true
  wait "$CHROME_PID" 2>/dev/null || true
  echo "[renew] sleeping 6h..."
  sleep 21600
done
