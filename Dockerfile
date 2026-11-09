# muse-cli Telegram bot on Northflank
# Put this file at the root of a fork of
# https://github.com/thoitiettxl-cyber/muse-cli
# (the original repo has no Dockerfile, so Northflank cannot build it as-is).
FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1
ENV PIP_NO_CACHE_DIR=1
ENV CHROME_BIN=/usr/bin/google-chrome

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl git ca-certificates gnupg wget nodejs npm \
    && rm -rf /var/lib/apt/lists/*

# Google Chrome, for muse-cli auth export (agent-browser reads its cookies).
RUN wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O /tmp/chrome.deb \
    && apt-get update \
    && apt-get install -y /tmp/chrome.deb \
    && rm -f /tmp/chrome.deb \
    && rm -rf /var/lib/apt/lists/*

# agent-browser is what `muse-cli auth export` uses to read Chrome cookies.
RUN npm i -g agent-browser

WORKDIR /app

# Copy the muse-cli source from the build context (the repo root).
COPY . /app

# Install muse-cli from the local source. This provides the `muse-cli` command.
RUN pip install --no-cache-dir .

COPY entrypoint.sh /entrypoint.sh
COPY renew-cookies.sh /renew-cookies.sh
RUN chmod +x /entrypoint.sh /renew-cookies.sh

# The bot uses long polling to Telegram, it does not need a public HTTP port.
ENTRYPOINT ["/entrypoint.sh"]
