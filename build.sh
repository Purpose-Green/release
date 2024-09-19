#!/bin/bash

source src/check_os.sh

function build() {
  local out=$1

  generate_bin "$out"
  generate_checksum "$out"

  echo "⚡️Build completed⚡️"
}

function generate_bin() {
  local out=$1
  local temp
  temp="$(dirname "$out")/temp.sh"

  echo '#!/bin/bash' > "$temp"
  echo "Generating the '$(basename "$out")' in the '$(dirname "$out")' folder..."
  for file in src/*.sh; do
    {
      echo "# $file"
      tail -n +2 "$file" >> "$temp"
      echo ""
    } >> "$temp"
  done

  cat "$ENTRY_POINT" >> "$temp"
  grep -v '^source' "$temp" > "$out"
  rm "$temp"
  chmod u+x "$out"
}

function generate_checksum() {
  local out=$1

  if [[ "$_OS" == "Windows" ]]; then
    return
  fi

  if [[ "$_OS" == "OSX" ]]; then
    checksum=$(shasum -a 256 "$out")
  elif [[ "$_OS" == "Linux" ]]; then
    checksum=$(sha256sum "$out")
  fi

  echo "$checksum" > "$(dirname "$out")/checksum"
  echo "$checksum"
}

function get_current_version() {
  local file_with_version=$1
  grep "declare -r $VERSION_VAR_NAME=" "$file_with_version" \
      | sed "s/declare -r $VERSION_VAR_NAME=\"\([0-9]*\.[0-9]*\.[0-9]*\)\"/\1/"
}

function update_version() {
  local version_type=$1
  local file_with_version=$2

  local current_version
  current_version=$(grep "declare -r $VERSION_VAR_NAME=" "$file_with_version" \
    | sed "s/declare -r $VERSION_VAR_NAME=\"\([0-9]*\.[0-9]*\.[0-9]*\)\"/\1/")

  IFS='.' read -r major minor patch <<< "$current_version"

  # Increment the appropriate version part
  case "$version_type" in
    major)
      major=$((major + 1))
      minor=0
      patch=0
      ;;
    minor)
      minor=$((minor + 1))
      patch=0
      ;;
    patch)
      patch=$((patch + 1))
      ;;
    *)
      echo "Invalid version increment option: $version_type. Use major, minor, or patch."
      exit 1
      ;;
  esac

  local new_version="$major.$minor.$patch"
  local search_pattern="declare -r $VERSION_VAR_NAME=\"[0-9]*\.[0-9]*\.[0-9]*\""
  local replace_pattern="declare -r $VERSION_VAR_NAME=\"$new_version\""

  sed -i.bak \
    "s/$search_pattern/$replace_pattern/" \
    "$file_with_version"

  rm "${file_with_version}.bak"

  echo "$new_version"
}

# shellcheck disable=SC2155
function update_changelog() {
  local target_version=$1
  local new_version=$2
  local new_tag=$2

  local changelog_file="CHANGELOG.md"
  local current_date=$(date +'%Y-%m-%d')
  local previous_tag=$(git describe --tags "$(git rev-list --tags --max-count=1)" 2>/dev/null || echo "v0")
  local remote_url=$(git remote get-url origin)
  local repo_info=$(echo "$remote_url" | sed -E 's|git@github\.com:||; s|\.git$||')
  local changelog_url="https://github.com/$repo_info/compare/$previous_tag...$new_tag"

  local commits=$(git log "$target_version"..HEAD --oneline)

  local temp_file=$(mktemp)
  # Add the new entry
  {
    echo "# Changelog"
    echo
    echo "## [$new_version]($changelog_url) - $current_date"
    echo
    while IFS= read -r commit; do
      echo "- $commit"
    done <<< "$commits"
    # Append existing changelog content
    sed '1{/^# Changelog/d;}' "$changelog_file"
  } > "$temp_file"

  # Replace the original changelog with the updated one
  mv "$temp_file" "$changelog_file"
}

########################
#         MAIN         #
########################
VERSION_VAR_NAME="RELEASE_VERSION"
ENTRY_POINT="release"
OUT_DIR="bin"
NEW_VERSION_TYPE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --new)
      shift
      NEW_VERSION_TYPE="$1"
      ;;
    *)
      OUT_DIR="$1"
      ;;
  esac
  shift
done

if [[ "$NEW_VERSION_TYPE" != "" ]]; then
  NEW_VERSION=$(update_version "$NEW_VERSION_TYPE" "$ENTRY_POINT")
  echo "Updated version: $NEW_VERSION"
  update_changelog "origin/prod" "$NEW_VERSION"
else
  echo "Current version: $(get_current_version "$ENTRY_POINT")"
fi

mkdir -p "$OUT_DIR"
build "$OUT_DIR/$ENTRY_POINT"
