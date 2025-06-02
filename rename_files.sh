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

# Function to get new name based on replacements
get_new_name() {
    local old_name="$1"
    local new_name="$old_name"
    
    # Apply replacements in order - longer strings first to avoid partial matches
    new_name="${new_name//bitcoin/krepto}"
    new_name="${new_name//Bitcoin/Krepto}"
    new_name="${new_name//BITCOIN/KREPTO}"
    new_name="${new_name//satoshi/katoshi}"
    new_name="${new_name//Satoshi/Katoshi}"
    new_name="${new_name//SATOSHI/KATOSHI}"
    new_name="${new_name//btc/krepto}"
    new_name="${new_name//BTC/KREPTO}"
    new_name="${new_name//Btc/Krepto}"
    new_name="${new_name//Sat/Kat}"
    new_name="${new_name//SAT/KAT}"
    new_name="${new_name//sat/kat}"
    
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

# Function to find files excluding node_modules and .git
find_files_safe() {
    find . -type f \
        -not -path "./node_modules/*" \
        -not -path "./.git/*" \
        -not -name "package.json" \
        -not -name "package-lock.json" \
        -not -name "*.log" \
        -not -name "rename_files.sh" \
        -not -path "./krepto-blockchain-memory-bank/*" \
        -print0 | sort -rz
}

# Function to find directories excluding node_modules and .git
find_dirs_safe() {
    find . -type d \
        -not -path "./node_modules" \
        -not -path "./node_modules/*" \
        -not -path "./.git" \
        -not -path "./.git/*" \
        -not -path "./krepto-blockchain-memory-bank" \
        -not -path "./krepto-blockchain-memory-bank/*" \
        -not -path "." \
        -print0 | sort -rz
}

# Main renaming logic
rename_files_and_dirs() {
    local search_dir="${1:-.}"
    
    echo -e "${YELLOW}Scanning directory: $search_dir${NC}"
    echo -e "${YELLOW}Excluding: node_modules, .git, and other protected files${NC}"
    
    # First pass: rename files (depth-first to avoid path issues)
    echo -e "${YELLOW}=== Renaming Files ===${NC}"
    while IFS= read -r -d '' file; do
        if [[ -f "$file" ]]; then
            rename_item "$file"
        fi
    done < <(find_files_safe)
    
    # Second pass: rename directories (bottom-up to avoid path issues)
    echo -e "${YELLOW}=== Renaming Directories ===${NC}"
    while IFS= read -r -d '' dir; do
        if [[ -d "$dir" ]]; then
            rename_item "$dir"
        fi
    done < <(find_dirs_safe)
}

# Dry run function
dry_run() {
    echo -e "${YELLOW}=== DRY RUN MODE ===${NC}"
    echo "The following renames would be performed:"
    echo -e "${YELLOW}Excluding: node_modules, .git, and other protected files${NC}"
    
    # Check files
    while IFS= read -r -d '' file; do
        local old_name=$(basename "$file")
        local new_name=$(get_new_name "$old_name")
        
        if [[ "$old_name" != "$new_name" ]]; then
            echo -e "${GREEN}FILE:${NC} $old_name -> $new_name (in $(dirname "$file"))"
        fi
    done < <(find_files_safe)
    
    # Check directories
    while IFS= read -r -d '' dir; do
        local old_name=$(basename "$dir")
        local new_name=$(get_new_name "$old_name")
        
        if [[ "$old_name" != "$new_name" ]]; then
            echo -e "${GREEN}DIR:${NC} $old_name -> $new_name (path: $dir)"
        fi
    done < <(find_dirs_safe)
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
        echo ""
        echo "Excluded from renaming:"
        echo "  - node_modules/ directory and all contents"
        echo "  - .git/ directory and all contents"
        echo "  - package.json, package-lock.json"
        echo "  - *.log files"
        echo "  - this script itself"
        ;;
    *)
        echo -e "${YELLOW}Starting actual rename operations...${NC}"
        echo -e "${YELLOW}Excluding: node_modules, .git, and other protected files${NC}"
        echo -e "${RED}Press Ctrl+C within 5 seconds to cancel${NC}"
        sleep 5
        
        rename_files_and_dirs "."
        
        echo -e "${GREEN}=== Renaming Complete ===${NC}"
        echo -e "${YELLOW}Log saved to: $LOG_FILE${NC}"
        ;;
esac 