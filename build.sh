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

function update_version() {
  local version_type=$1
  local version_file=$2

  local current_version
  current_version=$(cat "$version_file")
  IFS='.' read -r major minor patch <<< "$current_version"

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
  echo "$new_version" > "$version_file"
  echo "Version updated to $new_version"
}

########################
#         MAIN         #
########################
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
  update_version "$NEW_VERSION_TYPE" "src/version.txt"
fi

mkdir -p "$OUT_DIR"
build "$OUT_DIR/deploy"
