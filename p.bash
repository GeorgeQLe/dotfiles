# p - jump to a project directory by partial name match
# Usage: p [query]
#   p          - list all projects
#   p foo      - cd to project matching "foo" (substring, case-insensitive)
#   p foo<Tab> - tab-complete project names (prefix match)

p() {
  local base="$HOME/projects"
  local query="$1"

  # Find leaf project dirs (contain a project marker, exclude build artifacts)
  local dirs
  dirs=$(find "$base" -maxdepth 5 -type f \( \
    -name 'package.json' -o -name 'Cargo.toml' -o -name 'go.mod' \
    -o -name 'pyproject.toml' -o -name 'Makefile' \
  \) -not -path '*/node_modules/*' -not -path '*/.next/*' \
     -not -path '*/.nuxt/*' -not -path '*/dist/*' \
     -not -path '*/target/*' -not -path '*/.cache/*' \
  | sed 's|/[^/]*$||' | sort -u)

  # Also include dirs with .git (find -name .git -type d)
  local git_dirs
  git_dirs=$(find "$base" -maxdepth 5 -name '.git' -type d \
    -not -path '*/node_modules/*' \
  | sed 's|/\.git$||' | sort -u)

  # Merge and deduplicate
  dirs=$(printf '%s\n%s' "$dirs" "$git_dirs" | sort -u | grep -v '^$')

  # Filter by query if provided
  if [[ -n "$query" ]]; then
    dirs=$(echo "$dirs" | while IFS= read -r d; do
      local name="${d##*/}"
      if [[ "${name,,}" == *"${query,,}"* ]]; then
        echo "$d"
      fi
    done)
  fi

  # Count matches
  local count
  count=$(echo "$dirs" | grep -c .)

  if [[ "$count" -eq 0 ]]; then
    echo "No projects matching '$query'"
    return 1
  elif [[ "$count" -eq 1 ]]; then
    cd "$dirs" || return 1
    echo "→ $(pwd)"
  else
    echo "Multiple matches:"
    local i=1
    local arr=()
    while IFS= read -r d; do
      local rel="${d#$base/}"
      printf "  %d) %s\n" "$i" "$rel"
      arr+=("$d")
      ((i++))
    done <<< "$dirs"
    echo ""
    read -rp "Pick [1-$count]: " choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= count )); then
      cd "${arr[$((choice-1))]}" || return 1
      echo "→ $(pwd)"
    else
      echo "Cancelled."
      return 1
    fi
  fi
}

_p_completion() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local base="$HOME/projects"
  local cache_file="/tmp/_p_completion_cache_$(id -u)"
  local cache_ttl=300

  # Rebuild cache if missing or stale (>5 min)
  if [[ ! -f "$cache_file" ]] || \
     [[ $(( $(date +%s) - $(stat -c %Y "$cache_file") )) -gt $cache_ttl ]]; then
    {
      find "$base" -maxdepth 5 -type f \( \
        -name 'package.json' -o -name 'Cargo.toml' -o -name 'go.mod' \
        -o -name 'pyproject.toml' -o -name 'Makefile' \
      \) -not -path '*/node_modules/*' -not -path '*/.next/*' \
         -not -path '*/.nuxt/*' -not -path '*/dist/*' \
         -not -path '*/target/*' -not -path '*/.cache/*' \
      | sed 's|/[^/]*$||'
      find "$base" -maxdepth 5 -name '.git' -type d \
        -not -path '*/node_modules/*' \
      | sed 's|/\.git$||'
    } | sort -u | grep -v '^$' | xargs -I{} basename {} | sort -u > "$cache_file"
  fi

  COMPREPLY=( $(compgen -W "$(cat "$cache_file")" -- "$cur") )
}
complete -F _p_completion p
