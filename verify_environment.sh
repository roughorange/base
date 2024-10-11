#!/bin/bash

set -euo pipefail

FINGERPRINT_FILE="verify-fingerprint.json"

safe_exec() {
    if ! output=$(eval "$1" 2>&1); then
        echo "Error executing $1: $output" >&2
        return 1
    fi
    echo "$output"
}

escape_json() {
    sed 's/\\/\\\\/g; s/"/\\"/g; s/\//\\\//g; s/\x08/\\b/g; s/\x0c/\\f/g; s/\n/\\n/g; s/\r/\\r/g; s/\t/\\t/g' | tr -d '\n'
}

find_config_files() {
    find "$1" \( \
        -name "*.json" -o \
        -name "*.yml" -o \
        -name "*.yaml" -o \
        -name "*.toml" -o \
        -name "*.ini" -o \
        -name "*.conf" -o \
        -name "*.config" -o \
        -name ".env*" -o \
        -name "Dockerfile*" -o \
        -name "docker-compose*.yml" \
    \) -type f \
    -not -path "*/node_modules/*" \
    -not -path "*/.git/*" \
    -not -name "$FINGERPRINT_FILE" \
    2>/dev/null
}

get_folder_structure() {
    local dir="$1" prefix="$2" max_depth="$3" current_depth="$4"
    [[ "$current_depth" -gt "$max_depth" ]] && return
    for item in "$dir"/*; do
        if [[ -d "$item" ]]; then
            echo "${prefix}${item##*/}/"
            get_folder_structure "$item" "$prefix  " "$max_depth" $((current_depth + 1))
        elif [[ -f "$item" && "${item##*/}" != "$FINGERPRINT_FILE" ]]; then
            echo "${prefix}${item##*/}"
        fi
    done
}

# Check if fingerprint file exists and prompt for overwrite
if [[ -f "$FINGERPRINT_FILE" ]]; then
    read -p "Fingerprint file $FINGERPRINT_FILE already exists. Overwrite? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Operation cancelled."
        exit 1
    fi
fi

json_output="{\"environmentStatus\":{"
json_output+="\"os\":\"$(uname -s)\","
json_output+="\"osVersion\":\"$(uname -r)\","
json_output+="\"architecture\":\"$(uname -m)\","
json_output+="\"docker\":\"$(command -v docker &> /dev/null && echo "Installed" || echo "Not installed")\","
json_output+="\"dockerVersion\":\"$(safe_exec "docker --version" || echo "N/A")\","
json_output+="\"dockerMode\":\"$(docker info 2>/dev/null | grep -q "rootless" && echo "Rootless" || echo "Standard")\","
json_output+="\"git\":\"$(command -v git &> /dev/null && echo "Installed" || echo "Not installed")\","
json_output+="\"gitVersion\":\"$(safe_exec "git --version" || echo "N/A")\","
json_output+="\"gitBranch\":\"$(safe_exec "git rev-parse --abbrev-ref HEAD" || echo "N/A")\","
json_output+="\"lastCommit\":\"$(safe_exec "git log -1 --format=%cd" || echo "N/A")\""
json_output+="},\"configurationFiles\":["

while IFS= read -r file; do
    relpath=$(realpath --relative-to="$(pwd)" "$file")
    content=$(< "$file" escape_json)
    json_output+="{"
    json_output+="\"path\":\"$relpath\","
    json_output+="\"size\":$(stat -c%s "$file"),"
    json_output+="\"lastModified\":\"$(stat -c%y "$file")\","
    json_output+="\"content\":\"$content\""
    json_output+="},"
done < <(find_config_files ".")
json_output=${json_output%,}

json_output+="],\"folderStructure\":["
while IFS= read -r line; do
    json_output+="\"$line\","
done < <(get_folder_structure "." "" 3 0)
json_output=${json_output%,}

json_output+="]}"

echo "$json_output" > "$FINGERPRINT_FILE"

echo "Environment verification completed. Results written to $FINGERPRINT_FILE"