#!/bin/bash

# This script updates MDX files by:
# 1. Merging the frontmatter title and the first H1 heading
# 2. Removing the redundant H1 heading

# Process each MDX file
for file in docs/*.mdx docs/**/*.mdx; do
  if [ -f "$file" ]; then
    echo "Processing $file..."
    
    # Read the first few lines to extract title and H1
    frontmatter_title=$(grep -m 1 "^title: " "$file" | sed 's/^title: //')
    first_heading=$(grep -m 1 "^# " "$file" | sed 's/^# //')
    
    # Only process if there's both a frontmatter title and an H1 heading
    if [ -n "$frontmatter_title" ] && [ -n "$first_heading" ]; then
      echo "  Found title: $frontmatter_title"
      echo "  Found H1: $first_heading"
      
      # Create a temporary file
      temp_file=$(mktemp)
      
      # Extract content after the H1 line
      content_after_h1=$(sed -n '/^# /,$p' "$file" | tail -n +2)
      
      # Create the new file content
      echo "---" > "$temp_file"
      echo "title: $first_heading" >> "$temp_file"
      echo "---" >> "$temp_file"
      echo "" >> "$temp_file"
      echo "$content_after_h1" >> "$temp_file"
      
      # Replace the original file
      mv "$temp_file" "$file"
      echo "  Updated $file"
    else
      echo "  Skipping $file (no title or H1 heading found)"
    fi
  fi
done

echo "Done updating documentation files." 