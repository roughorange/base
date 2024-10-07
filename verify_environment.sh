#!/bin/bash

PROJECT_DIR="/workspace/base"
FINGERPRINT_FILE="$PROJECT_DIR/verify_environment_fingerprint.json"

# Directories and files to exclude
EXCLUDE_DIRS=("node_modules" ".venv" "env" "venv" ".git" "__pycache__")
EXCLUDE_FILES=("package-lock.json" "yarn.lock" "poetry.lock" "verify_environment_fingerprint.json")

# Function to hide cursor
hide_cursor() {
    tput civis
}

# Function to show cursor
show_cursor() {
    tput cnorm
}

# Function to display a simple spinner animation
show_spinner() {
    local delay=0.1
    local spinstr='|/-\'
    while :
    do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
}

# Function to check if a path should be excluded
should_exclude() {
    local path="$1"
    for dir in "${EXCLUDE_DIRS[@]}"; do
        [[ "$path" == *"/$dir"* ]] && return 0
    done
    local filename=$(basename "$path")
    for file in "${EXCLUDE_FILES[@]}"; do
        [[ "$filename" == "$file" ]] && return 0
    done
    return 1
}

# Function to generate a fingerprint of the workspace
generate_fingerprint() {
    local fingerprint="{"
    local file_count=0
    local dir_count=0
    local symlink_count=0

    while IFS= read -r -d '' item; do
        if should_exclude "$item"; then
            continue
        fi

        local escaped_path=$(printf '%s' "$item" | sed 's/"/\\"/g')
        if [[ -L "$item" ]]; then
            local target=$(readlink "$item")
            local escaped_target=$(printf '%s' "$target" | sed 's/"/\\"/g')
            fingerprint+="\"$escaped_path\":{\"type\":\"symlink\",\"target\":\"$escaped_target\"},"
            ((symlink_count++))
        elif [[ -d "$item" ]]; then
            fingerprint+="\"$escaped_path\":{\"type\":\"directory\"},"
            ((dir_count++))
        elif [[ -f "$item" ]]; then
            local hash=$(sha256sum "$item" | awk '{print $1}')
            fingerprint+="\"$escaped_path\":{\"type\":\"file\",\"hash\":\"$hash\"},"
            ((file_count++))
        fi
    done < <(find "$PROJECT_DIR" -print0)

    fingerprint=${fingerprint%,}
    fingerprint+="}"

    echo "$fingerprint"
    echo "FILES_FOUND:$file_count"
    echo "FOLDERS_FOUND:$dir_count"
    echo "SYMLINKS_FOUND:$symlink_count"
}

# Function to compare two fingerprints
compare_fingerprints() {
    local original_fingerprint="$1"
    local current_fingerprint="$2"
    local issues=""
    local missing_count=0
    local changed_count=0
    local new_count=0

    local original_paths=$(echo "$original_fingerprint" | jq -r 'keys[]')
    local current_paths=$(echo "$current_fingerprint" | jq -r 'keys[]')

    while read -r path; do
        if ! echo "$current_paths" | grep -q "^$path$"; then
            issues+="Missing: $path\n"
            ((missing_count++))
        else
            local original_type=$(echo "$original_fingerprint" | jq -r ".[\"$path\"].type")
            local current_type=$(echo "$current_fingerprint" | jq -r ".[\"$path\"].type")
            if [[ "$original_type" != "$current_type" ]]; then
                issues+="Changed type: $path\n"
                ((changed_count++))
            elif [[ "$original_type" == "file" ]]; then
                local original_hash=$(echo "$original_fingerprint" | jq -r ".[\"$path\"].hash")
                local current_hash=$(echo "$current_fingerprint" | jq -r ".[\"$path\"].hash")
                if [[ "$original_hash" != "$current_hash" ]]; then
                    issues+="Changed content: $path\n"
                    ((changed_count++))
                fi
            elif [[ "$original_type" == "symlink" ]]; then
                local original_target=$(echo "$original_fingerprint" | jq -r ".[\"$path\"].target")
                local current_target=$(echo "$current_fingerprint" | jq -r ".[\"$path\"].target")
                if [[ "$original_target" != "$current_target" ]]; then
                    issues+="Changed symlink target: $path\n"
                    ((changed_count++))
                fi
            fi
        fi
    done <<< "$original_paths"

    while read -r path; do
        if ! echo "$original_paths" | grep -q "^$path$"; then
            issues+="New: $path\n"
            ((new_count++))
        fi
    done <<< "$current_paths"

    echo "Items missing: $missing_count"
    echo "Items changed: $changed_count"
    echo "New items: $new_count"
    if [[ $missing_count -gt 0 || $changed_count -gt 0 || $new_count -gt 0 ]]; then
        echo -e "Do you want to see a list of all issues? (Y/N)"
        read -r show_issues
        if [[ "$show_issues" =~ ^[Yy]$ ]]; then
            echo -e "$issues"
        fi
        echo "The new workspace does not match the original environment. Review required before work can begin."
    else
        echo "No issues found. The new workspace matches the original environment and is ready for work."
    fi
}

# Function to show a detailed list of files and folders
show_detailed_list() {
    local fingerprint="$1"
    echo "Detailed list of files and folders:"
    echo "$fingerprint" | jq -r 'to_entries | sort_by(.key) | .[] | "\(.value.type): \(.key)"'
}

# Main function to control the script's flow
main() {
    # Ensure cursor is shown on script exit
    trap show_cursor EXIT

    if [[ -f "$FINGERPRINT_FILE" ]]; then
        echo "Existing thumbprint found."
        echo "Compare Thumbprint (C) / Build New Thumbprint (B) / Show Detailed List (L) (default: C)"
        read -r action

        if [[ "$action" =~ ^[Bb]$ ]]; then
            echo "Generating new thumbprint..."
            hide_cursor
            show_spinner &
            SPINNER_PID=$!
            fingerprint=$(generate_fingerprint)
            kill $SPINNER_PID
            wait $SPINNER_PID 2>/dev/null
            show_cursor
            echo "${fingerprint%%FILES_FOUND*}" > "$FINGERPRINT_FILE"
            folders=$(echo "$fingerprint" | grep "FOLDERS_FOUND:" | cut -d':' -f2)
            symlinks=$(echo "$fingerprint" | grep "SYMLINKS_FOUND:" | cut -d':' -f2)
            files=$(echo "$fingerprint" | grep "FILES_FOUND:" | cut -d':' -f2)
            echo "New thumbprint created."
            echo "$folders Folders"
            echo "$symlinks Symlinks"
            echo "$files Files"
        elif [[ "$action" =~ ^[Ll]$ ]]; then
            fingerprint=$(cat "$FINGERPRINT_FILE")
            show_detailed_list "$fingerprint"
        else
            echo "Comparing thumbprints..."
            hide_cursor
            show_spinner &
            SPINNER_PID=$!
            current_fingerprint=$(generate_fingerprint)
            kill $SPINNER_PID
            wait $SPINNER_PID 2>/dev/null
            show_cursor
            original_fingerprint=$(cat "$FINGERPRINT_FILE")
            compare_fingerprints "$original_fingerprint" "${current_fingerprint%%FILES_FOUND*}"
        fi
    else
        echo "No existing thumbprint found. Creating new thumbprint..."
        hide_cursor
        show_spinner &
        SPINNER_PID=$!
        fingerprint=$(generate_fingerprint)
        kill $SPINNER_PID
        wait $SPINNER_PID 2>/dev/null
        show_cursor
        echo "${fingerprint%%FILES_FOUND*}" > "$FINGERPRINT_FILE"
        folders=$(echo "$fingerprint" | grep "FOLDERS_FOUND:" | cut -d':' -f2)
        symlinks=$(echo "$fingerprint" | grep "SYMLINKS_FOUND:" | cut -d':' -f2)
        files=$(echo "$fingerprint" | grep "FILES_FOUND:" | cut -d':' -f2)
        echo "New thumbprint created."
        echo "$folders Folders"
        echo "$symlinks Symlinks"
        echo "$files Files"
    fi
}

main
