#!/bin/bash

# Script for renaming files and directories from Krepto to Krepto
# Case-sensitive replacements with exclusions

# Color output for better visibility
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Krepto File Renaming Script ===${NC}"
echo -e "${YELLOW}Starting safe file and directory renaming...${NC}"

# Create log file
LOG_FILE="rename_log_$(date +%Y%m%d_%H%M%S).txt"
echo "Rename operations log - $(date)" > "$LOG_FILE"

# Exclusion patterns
EXCLUDE_PATTERNS=(
    "node_modules"
    "package.json"
    "package-lock.json"
    ".git"
    "*.log"
    "rename_files.sh"
    "krepto-blockchain-memory-bank"
)

# Check if path should be excluded
is_excluded() {
    local path="$1"
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        if [[ "$path" == *"$pattern"* ]]; then
            return 0  # true - excluded
        fi
    done
    return 1  # false - not excluded
}

# Replacement mappings - ORDER MATTERS! Longer strings first
declare -A REPLACEMENTS=(
    ["Krepto"]="Krepto"
    ["krepto"]="krepto"
    ["BITCOIN"]="KREPTO"
    ["KREPTO"]="Krepto"
    ["KREPTO"]="KREPTO"
    ["KREPTO"]="krepto"
    ["Satoshi"]="Katoshi"
    ["satoshi"]="katoshi"
)

# Function to get new name based on replacements
get_new_name() {
    local old_name="$1"
    local new_name="$old_name"
    
    # Apply replacements in order
    for old_pattern in "Krepto" "BITCOIN" "krepto" "Satoshi" "satoshi" "KREPTO" "KREPTO" "KREPTO"; do
        if [[ -n "${REPLACEMENTS[$old_pattern]}" ]]; then
            new_name="${new_name//$old_pattern/${REPLACEMENTS[$old_pattern]}}"
        fi
    done
    
    echo "$new_name"
}

# Function to rename file or directory
rename_item() {
    local full_path="$1"
    local dir_path=$(dirname "$full_path")
    local old_name=$(basename "$full_path")
    local new_name=$(get_new_name "$old_name")
    
    if [[ "$old_name" != "$new_name" ]]; then
        local new_full_path="$dir_path/$new_name"
        
        if [[ -e "$new_full_path" ]]; then
            echo -e "${RED}WARNING: Target exists: $new_full_path${NC}"
            echo "WARNING: Target exists: $new_full_path" >> "$LOG_FILE"
            return 1
        fi
        
        echo -e "${GREEN}Renaming:${NC} $old_name -> $new_name"
        echo "RENAME: $full_path -> $new_full_path" >> "$LOG_FILE"
        
        # Actual rename operation
        if mv "$full_path" "$new_full_path"; then
            echo -e "${GREEN}✓ Success${NC}"
            echo "SUCCESS: Renamed $full_path to $new_full_path" >> "$LOG_FILE"
            return 0
        else
            echo -e "${RED}✗ Failed${NC}"
            echo "FAILED: Could not rename $full_path to $new_full_path" >> "$LOG_FILE"
            return 1
        fi
    fi
    return 2  # No rename needed
}

# Main renaming logic
rename_files_and_dirs() {
    local search_dir="${1:-.}"
    
    echo -e "${YELLOW}Scanning directory: $search_dir${NC}"
    
    # First pass: rename files (depth-first to avoid path issues)
    echo -e "${YELLOW}=== Renaming Files ===${NC}"
    while IFS= read -r -d '' file; do
        if is_excluded "$file"; then
            echo -e "${YELLOW}Skipping excluded: $file${NC}"
            continue
        fi
        
        if [[ -f "$file" ]]; then
            rename_item "$file"
        fi
    done < <(find "$search_dir" -type f -print0 | sort -rz)
    
    # Second pass: rename directories (bottom-up to avoid path issues)
    echo -e "${YELLOW}=== Renaming Directories ===${NC}"
    while IFS= read -r -d '' dir; do
        if is_excluded "$dir"; then
            echo -e "${YELLOW}Skipping excluded: $dir${NC}"
            continue
        fi
        
        if [[ -d "$dir" && "$dir" != "$search_dir" ]]; then
            rename_item "$dir"
        fi
    done < <(find "$search_dir" -type d -print0 | sort -rz)
}

# Dry run function
dry_run() {
    echo -e "${YELLOW}=== DRY RUN MODE ===${NC}"
    echo "The following renames would be performed:"
    
    # Check files
    while IFS= read -r -d '' file; do
        if is_excluded "$file"; then
            continue
        fi
        
        local old_name=$(basename "$file")
        local new_name=$(get_new_name "$old_name")
        
        if [[ "$old_name" != "$new_name" ]]; then
            echo -e "${GREEN}FILE:${NC} $old_name -> $new_name"
        fi
    done < <(find . -type f -print0)
    
    # Check directories
    while IFS= read -r -d '' dir; do
        if is_excluded "$dir" || [[ "$dir" == "." ]]; then
            continue
        fi
        
        local old_name=$(basename "$dir")
        local new_name=$(get_new_name "$old_name")
        
        if [[ "$old_name" != "$new_name" ]]; then
            echo -e "${GREEN}DIR:${NC} $old_name -> $new_name"
        fi
    done < <(find . -type d -print0)
}

# Main execution
case "${1:-}" in
    "--dry-run"|"-n")
        dry_run
        ;;
    "--help"|"-h")
        echo "Usage: $0 [--dry-run] [--help]"
        echo "  --dry-run, -n    Show what would be renamed without doing it"
        echo "  --help, -h       Show this help"
        ;;
    *)
        echo -e "${YELLOW}Starting actual rename operations...${NC}"
        echo -e "${RED}Press Ctrl+C within 5 seconds to cancel${NC}"
        sleep 5
        
        rename_files_and_dirs "."
        
        echo -e "${GREEN}=== Renaming Complete ===${NC}"
        echo -e "${YELLOW}Log saved to: $LOG_FILE${NC}"
        ;;
esac 