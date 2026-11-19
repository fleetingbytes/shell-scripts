#!/usr/bin/env sh

if [ $# -eq 0 ]; then
    echo "Usage: $0 <token1> [token2 ...]"
    echo "Example: $0 token-1 token-2 token-3"
    exit 1
fi

for token in "$@"; do
    fetch -q -o /dev/null "https://freedns.afraid.org/dynamic/update.php?${token}"
done
