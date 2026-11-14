#!/usr/bin/env bash
set -euo pipefail

login="$1"
shift
readme="README.md"
block="$(mktemp)"

{
  echo "| Repository | Latest release | Published |"
  echo "|---|---|---|"
  for repo in "$@"; do
    if rel="$(gh api "repos/$repo/releases/latest" --jq '[.tag_name, .html_url, (.published_at | .[0:10])] | @tsv' 2>/dev/null)"; then
      IFS=$'\t' read -r tag url date <<<"$rel"
      echo "| [$repo](https://github.com/$repo) | [$tag]($url) | $date |"
    fi
  done
  merged="$(gh api -X GET search/issues -f q="is:pr is:merged author:$login" --jq .total_count)"
  reviewed="$(gh api -X GET search/issues -f q="is:pr reviewed-by:$login -author:$login" --jq .total_count)"
  echo
  echo "Public merged pull requests: **$merged** · Pull requests reviewed: **$reviewed**"
} >"$block"

awk -v f="$block" '
  /<!-- live:start -->/ { print; while ((getline line < f) > 0) print line; skip = 1; next }
  /<!-- live:end -->/   { skip = 0 }
  !skip
' "$readme" >"$readme.new"
mv "$readme.new" "$readme"
