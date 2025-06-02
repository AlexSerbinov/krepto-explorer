#!/bin/bash

# Script for renaming files and directories from Bitcoin to Krepto
# Case-sensitive replacements with exclusions
# Also replaces content inside files

# Color output for better visibility
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Trap Ctrl+C for clean exit
trap 'echo -e "\n${RED}Script interrupted by user${NC}"; exit 1' INT

echo -e "${GREEN}=== Krepto File Renaming & Content Replacement Script ===${NC}"
echo -e "${YELLOW}Starting safe file and directory renaming and content replacement...${NC}"
echo -e "${YELLOW}Press Ctrl+C to interrupt at any time${NC}"

# Create log file
LOG_FILE="rename_log_$(date +%Y%m%d_%H%M%S).txt"
echo "Rename and content replacement operations log - $(date)" > "$LOG_FILE"

# Function to check if string should be excluded from replacements
should_exclude_from_replacement() {
    local text="$1"
    
    # List of patterns that should NOT be replaced
    local exclude_patterns=(
        "bitcoinjs"
        "bitcoin-js"
        "bitcoinjs-lib"
        "node_modules"
        "package-lock"
        "npm-shrinkwrap"
    )
    
    for pattern in "${exclude_patterns[@]}"; do
        if [[ "$text" == *"$pattern"* ]]; then
            return 0  # true - exclude this
        fi
    done
    
    return 1  # false - proceed with replacement
}

# Function to apply safe replacements (avoiding bitcoinjs and similar)
apply_safe_replacements() {
    local input="$1"
    local output="$input"
    
    # If the line contains excluded patterns, don't modify it
    if should_exclude_from_replacement "$input"; then
        echo "$output"
        return
    fi
    
    # Apply case-sensitive replacements only if not excluded
    output="${output//bitcoin/krepto}"
    output="${output//Bitcoin/Krepto}"
    output="${output//BITCOIN/KREPTO}"
    output="${output//satoshi/katoshi}"
    output="${output//Satoshi/Katoshi}"
    output="${output//SATOSHI/KATOSHI}"
    output="${output//btc/krepto}"
    output="${output//BTC/KREPTO}"
    output="${output//Btc/Krepto}"
    output="${output//Sat/Kat}"
    output="${output//SAT/KAT}"
    output="${output//sat/kat}"
    
    echo "$output"
}

# Function to get new name based on replacements
get_new_name() {
    local old_name="$1"
    
    # Apply safe replacements that respect exclusion rules
    apply_safe_replacements "$old_name"
}

# Function to check if file is binary
is_binary_file() {
    local file="$1"
    
    # Check common binary extensions
    case "${file##*.}" in
        png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|otf|eot|mp3|wav|mp4|avi|mov|pdf|zip|tar|gz|exe|bin|so|dylib|dll|class|jar)
            return 0 ;;
        *)
            # Use file command as fallback
            if command -v file >/dev/null 2>&1; then
                if file "$file" | grep -q "text"; then
                    return 1  # It's text
                else
                    return 0  # It's binary
                fi
            else
                # If file command not available, assume text for common extensions
                case "${file##*.}" in
                    js|json|html|htm|css|scss|pug|md|txt|sh|py|php|rb|go|java|cpp|c|h|xml|yml|yaml|conf|config|log|env)
                        return 1 ;;
                    *)
                        return 0 ;;
                esac
            fi
            ;;
    esac
}

# Function to replace content in a file (case-sensitive)
replace_content_in_file() {
    local file_path="$1"
    
    # Skip if binary file
    if is_binary_file "$file_path"; then
        echo -e "${BLUE}Skipping binary file: $(basename "$file_path")${NC}"
        return 0
    fi
    
    # Check file size more thoroughly (skip files larger than 1MB for content replacement)
    local file_size
    if command -v stat >/dev/null 2>&1; then
        if [[ "$(uname)" == "Darwin" ]]; then
            file_size=$(stat -f%z "$file_path" 2>/dev/null || echo 0)
        else
            file_size=$(stat -c%s "$file_path" 2>/dev/null || echo 0)
        fi
    else
        file_size=$(wc -c < "$file_path" 2>/dev/null || echo 0)
    fi
    
    # Skip files larger than 1MB (1048576 bytes) - they're likely data files
    if [[ "$file_size" -gt 1048576 ]]; then
        echo -e "${YELLOW}Skipping large file ($(echo "scale=1; $file_size/1024/1024" | bc 2>/dev/null || echo ">1")MB): $(basename "$file_path")${NC}"
        echo "SKIPPED: Large file $file_path ($file_size bytes)" >> "$LOG_FILE"
        return 0
    fi
    
    # Skip specific file types that are likely to be large or problematic
    case "$(basename "$file_path")" in
        pnpm-lock.yaml|package-lock.json|npm-shrinkwrap.json|yarn.lock)
            echo -e "${YELLOW}Skipping lock file: $(basename "$file_path")${NC}"
            echo "SKIPPED: Lock file $file_path" >> "$LOG_FILE"
            return 0
            ;;
        *.min.js|*.min.css)
            echo -e "${YELLOW}Skipping minified file: $(basename "$file_path")${NC}"
            echo "SKIPPED: Minified file $file_path" >> "$LOG_FILE"
            return 0
            ;;
    esac
    
    # Create temporary file
    local temp_file=$(mktemp)
    local changes_made=false
    local line_count=0
    
    echo -e "${BLUE}Processing: $(basename "$file_path")${NC}"
    
    # Read file with timeout and line limit
    while IFS= read -r line || [[ -n "$line" ]]; do
        local original_line="$line"
        local new_line
        
        # Apply safe replacements that respect exclusion rules
        new_line=$(apply_safe_replacements "$line")
        
        # Check if any changes were made to this line
        if [[ "$original_line" != "$new_line" ]]; then
            changes_made=true
        fi
        
        echo "$new_line" >> "$temp_file"
        
        # Safety limit: don't process files with more than 50k lines
        ((line_count++))
        if [[ $line_count -gt 50000 ]]; then
            echo -e "${YELLOW}File too large (>50k lines), skipping: $(basename "$file_path")${NC}"
            echo "SKIPPED: Too many lines $file_path ($line_count lines)" >> "$LOG_FILE"
            rm -f "$temp_file"
            return 0
        fi
        
        # Show progress for very long files
        if [[ $((line_count % 5000)) -eq 0 ]]; then
            echo -e "${BLUE}  ... processed $line_count lines${NC}"
        fi
    done < "$file_path"
    
    # If changes were made, replace the original file
    if [[ "$changes_made" == true ]]; then
        if mv "$temp_file" "$file_path"; then
            echo -e "${GREEN}✓ Content updated: $(basename "$file_path") ($line_count lines)${NC}"
            echo "CONTENT_UPDATED: $file_path ($line_count lines)" >> "$LOG_FILE"
        else
            echo -e "${RED}✗ Failed to update content: $(basename "$file_path")${NC}"
            echo "CONTENT_FAILED: $file_path" >> "$LOG_FILE"
            rm -f "$temp_file"
            return 1
        fi
    else
        # No changes needed, remove temp file
        rm -f "$temp_file"
        echo -e "${BLUE}No changes needed: $(basename "$file_path")${NC}"
    fi
    
    return 0
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

# Function to find text files for content replacement
find_text_files_safe() {
    find . -type f \
        -not -path "./node_modules/*" \
        -not -path "./.git/*" \
        -not -name "package.json" \
        -not -name "package-lock.json" \
        -not -name "pnpm-lock.yaml" \
        -not -name "npm-shrinkwrap.json" \
        -not -name "yarn.lock" \
        -not -name "*.log" \
        -not -name "rename_files.sh" \
        -not -path "./krepto-blockchain-memory-bank/*" \
        -not -name "*.png" \
        -not -name "*.jpg" \
        -not -name "*.jpeg" \
        -not -name "*.gif" \
        -not -name "*.ico" \
        -not -name "*.svg" \
        -not -name "*.woff*" \
        -not -name "*.ttf" \
        -not -name "*.otf" \
        -not -name "*.eot" \
        -not -name "*.mp3" \
        -not -name "*.wav" \
        -not -name "*.mp4" \
        -not -name "*.pdf" \
        -not -name "*.zip" \
        -not -name "*.tar" \
        -not -name "*.gz" \
        -not -name "*.min.js" \
        -not -name "*.min.css" \
        -not -name "*.bundle.js" \
        -not -name "*.map" \
        -print0 | sort -z
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

# Main processing logic
process_files_and_dirs() {
    local search_dir="${1:-.}"
    
    echo -e "${YELLOW}Scanning directory: $search_dir${NC}"
    echo -e "${YELLOW}Excluding: node_modules, .git, and other protected files${NC}"
    
    # First pass: replace content in files
    echo -e "${YELLOW}=== Replacing Content in Files ===${NC}"
    while IFS= read -r -d '' file; do
        if [[ -f "$file" ]]; then
            replace_content_in_file "$file"
        fi
    done < <(find_text_files_safe)
    
    # Second pass: rename files (depth-first to avoid path issues)
    echo -e "${YELLOW}=== Renaming Files ===${NC}"
    while IFS= read -r -d '' file; do
        if [[ -f "$file" ]]; then
            rename_item "$file"
        fi
    done < <(find_files_safe)
    
    # Third pass: rename directories (bottom-up to avoid path issues)
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
    echo "The following operations would be performed:"
    echo -e "${YELLOW}Excluding: node_modules, .git, and other protected files${NC}"
    
    # Check content replacements
    echo -e "${BLUE}=== Content Replacements ===${NC}"
    local content_changes=0
    local files_checked=0
    
    while IFS= read -r -d '' file; do
        ((files_checked++))
        
        if [[ -f "$file" ]] && ! is_binary_file "$file"; then
            # Show progress
            if [[ $((files_checked % 50)) -eq 0 ]]; then
                echo -e "${BLUE}... checked $files_checked files${NC}"
            fi
            
            # Quick file size check
            local file_size=0
            if command -v stat >/dev/null 2>&1; then
                if [[ "$(uname)" == "Darwin" ]]; then
                    file_size=$(stat -f%z "$file" 2>/dev/null || echo 0)
                else
                    file_size=$(stat -c%s "$file" 2>/dev/null || echo 0)
                fi
            fi
            
            # Skip large files quickly
            if [[ "$file_size" -gt 1048576 ]]; then
                continue
            fi
            
            # Skip specific problematic files
            case "$(basename "$file")" in
                pnpm-lock.yaml|package-lock.json|npm-shrinkwrap.json|yarn.lock|*.min.js|*.min.css)
                    continue
                    ;;
            esac
            
            # Quick check - only read first 100 lines for dry run
            local changes_made=false
            local line_count=0
            
            while IFS= read -r line && [[ $line_count -lt 100 ]]; do
                local original_line="$line"
                local new_line
                
                # Apply safe replacements that respect exclusion rules
                new_line=$(apply_safe_replacements "$line")
                
                if [[ "$original_line" != "$new_line" ]]; then
                    changes_made=true
                    break
                fi
                
                ((line_count++))
            done < "$file"
            
            if [[ "$changes_made" == true ]]; then
                echo -e "${GREEN}CONTENT:${NC} $(basename "$file") (in $(dirname "$file"))"
                ((content_changes++))
            fi
        fi
    done < <(find_text_files_safe)
    
    if [[ $content_changes -eq 0 ]]; then
        echo -e "${YELLOW}No content changes needed${NC}"
    fi
    
    # Check file renames
    echo -e "${BLUE}=== File Renames ===${NC}"
    while IFS= read -r -d '' file; do
        local old_name=$(basename "$file")
        local new_name=$(get_new_name "$old_name")
        
        if [[ "$old_name" != "$new_name" ]]; then
            echo -e "${GREEN}FILE:${NC} $old_name -> $new_name (in $(dirname "$file"))"
        fi
    done < <(find_files_safe)
    
    # Check directory renames
    echo -e "${BLUE}=== Directory Renames ===${NC}"
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
        echo "  --dry-run, -n    Show what would be changed without doing it"
        echo "  --help, -h       Show this help"
        echo ""
        echo "This script performs case-sensitive replacements:"
        echo "  - Renames files and directories"
        echo "  - Replaces content inside text files"
        echo ""
        echo "Replacements:"
        echo "  bitcoin -> krepto, Bitcoin -> Krepto, BITCOIN -> KREPTO"
        echo "  satoshi -> katoshi, Satoshi -> Katoshi, SATOSHI -> KATOSHI"
        echo "  btc -> krepto, BTC -> KREPTO, Btc -> Krepto"
        echo "  sat -> kat, SAT -> KAT, Sat -> Kat"
        echo ""
        echo "Exclusions (will NOT be replaced):"
        echo "  - bitcoinjs, bitcoin-js, bitcoinjs-lib"
        echo "  - node_modules, package-lock, npm-shrinkwrap"
        echo ""
        echo "Excluded from processing:"
        echo "  - node_modules/ directory and all contents"
        echo "  - .git/ directory and all contents"
        echo "  - package.json, package-lock.json"
        echo "  - *.log files"
        echo "  - Binary files (images, fonts, archives, etc.)"
        echo "  - This script itself"
        ;;
    *)
        echo -e "${YELLOW}Starting actual rename and content replacement operations...${NC}"
        echo -e "${YELLOW}Excluding: node_modules, .git, binary files, and other protected files${NC}"
        echo -e "${RED}Press Ctrl+C within 5 seconds to cancel${NC}"
        sleep 5
        
        process_files_and_dirs "."
        
        echo -e "${GREEN}=== Processing Complete ===${NC}"
        echo -e "${YELLOW}Log saved to: $LOG_FILE${NC}"
        ;;
esac 