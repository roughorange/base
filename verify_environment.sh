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
        -name "docker-compose*.yml" -o \
        -name ".babelrc" -o \
        -name ".eslintrc*" -o \
        -name "tsconfig*.json" -o \
        -name "webpack.config.js" -o \
        -name "next.config.js" -o \
        -name "vite.config.js" -o \
        -name ".gitignore" -o \
        -name ".prettierrc*" -o \
        -name "jest.config.*" -o \
        -name "rollup.config.*" -o \
        -name "requirements.txt" -o \
        -name "main.py" \
    \) -type f \
    -not -path "*/node_modules/*" \
    -not -path "*/.git/*" \
    -not -path "*/venv/*" \
    -not -path "*/__pycache__/*" \
    -not -path "*/.mypy_cache/*" \
    -not -path "*/.pytest_cache/*" \
    -not -path "*/.vscode/*" \
    -not -path "*/.idea/*" \
    -not -path "*/.vs/*" \
    -not -path "*/env/*" \
    -not -path "*/virtualenv/*" \
    -not -path "*/.env/*" \
    -not -path "*/build/*" \
    -not -path "*/dist/*" \
    -not -name "package-lock.json" \
    -not -name "yarn.lock" \
    -not -name "$FINGERPRINT_FILE" \
    -not -name "*.pyc" \
    -maxdepth 4 \
    2>/dev/null
}

get_folder_structure() {
    local dir="$1" prefix="$2" max_depth="3" current_depth="$4"
    [[ "$current_depth" -gt "$max_depth" ]] && return
    for item in "$dir"/*; do
        if [[ -d "$item" && ! "$item" =~ (node_modules|\.git|venv|__pycache__|\.vscode|\.idea|build|dist)$ ]]; then
            echo "${prefix}${item##*/}/"
            get_folder_structure "$item" "$prefix  " "$max_depth" $((current_depth + 1))
        elif [[ -f "$item" && "${item##*/}" != "$FINGERPRINT_FILE" ]]; then
            echo "${prefix}${item##*/}"
        fi
    done
}

limit_file_content() {
    local file="$1"
    local max_size=$((5 * 1024))  # 5 KB
    local file_size=$(stat -c%s "$file")
    if [[ "$file_size" -gt "$max_size" ]]; then
        head -c $max_size "$file" | escape_json
        echo "... (file truncated)"
    else
        cat "$file" | escape_json
    fi
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
json_output+="\"git\":\"$(command -v git &> /dev/null && echo "Installed" || echo "Not installed")\","
json_output+="\"gitVersion\":\"$(safe_exec "git --version" || echo "N/A")\","
json_output+="\"gitBranch\":\"$(safe_exec "git rev-parse --abbrev-ref HEAD" || echo "N/A")\","
json_output+="\"lastCommit\":\"$(safe_exec "git log -1 --format=%cd" || echo "N/A")\""
json_output+="},"

json_output+="\"files\":["
while IFS= read -r file; do
    relpath=$(realpath --relative-to="$(pwd)" "$file")
    content=$(limit_file_content "$file")  # Capture file content here
    json_output+="{"
    json_output+="\"path\":\"$relpath\","
    json_output+="\"size\":$(stat -c%s "$file"),"
    json_output+="\"lastModified\":\"$(stat -c%y "$file")\","
    json_output+="\"content\":\"$content\""  # Add file content to JSON output
    json_output+="},"
done < <(find_config_files ".")
json_output=${json_output%,}  # Remove trailing comma

json_output+="],\"folderStructure\":["
while IFS= read -r line; do
    json_output+="\"$line\","
done < <(get_folder_structure "." "" 3 0)
json_output=${json_output%,}

json_output+="]}"

echo "$json_output" > "$FINGERPRINT_FILE"

echo "Environment verification completed. Results written to $FINGERPRINT_FILE"
