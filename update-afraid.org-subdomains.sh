#!/usr/bin/env sh

if [ $# -eq 0 ]; then
    echo "Usage: $0 <token1> [token2] ..."
    echo "Example: $0 abc123 def456"
    exit 1
fi

for token in "$@"; do
    fetch -q -o /dev/null "https://sync.afraid.org/u/${token}/"
done
