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

  cat deploy >> "$temp"
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
      ;;
    minor)
      minor=$((minor + 1))
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

########################
#         MAIN         #
########################
VERSION_VAR_NAME="DEPLOY_VERSION"
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
  echo "Updated version: $(update_version "$NEW_VERSION_TYPE" "deploy")"
else
  echo "Current version: $(get_current_version "deploy")"
fi

mkdir -p "$OUT_DIR"
build "$OUT_DIR/deploy"
