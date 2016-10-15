#!/usr/bin/env bash

SITE=https://www.theleagueofmoveabletype.com

fonts=$(curl "$SITE" 2>/dev/null | sed -ne 's/<img.*cloudfront.*images\/\(.*\)-[[:digit:]-]\..*$/\1/p')

echo "["

for f in $fonts; do
    url="$SITE/$f/download"
    hash=$(nix-prefetch-url --type sha256 "$url" 2>/dev/null)
    cat <<EOF
  {
    url = "$url";
    sha256 = "$hash";
    name = "$f.zip";
  }
EOF
done

echo "]"


