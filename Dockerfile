# muse-cli Telegram bot on Northflank
# Put this file at the root of a fork of
# https://github.com/thoitiettxl-cyber/muse-cli
# (the original repo has no Dockerfile, so Northflank cannot build it as-is).
FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1
ENV PIP_NO_CACHE_DIR=1

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl git ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the muse-cli source from the build context (the repo root).
COPY . /app

# Install muse-cli from the local source. This provides the `muse-cli` command.
RUN pip install --no-cache-dir .

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# The bot uses long polling to Telegram, it does not need a public HTTP port.
ENTRYPOINT ["/entrypoint.sh"]
