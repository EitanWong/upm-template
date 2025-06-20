#!/bin/bash

# Copyright (c) Stephen Hodgson. All rights reserved.
# Licensed under the MIT License. See LICENSE in the project root for license information.

# Make the script exit on error
set -e

# Get user input
read -p "Set Author name: (i.e. your GitHub username) " InputAuthor
ProjectAuthor="ProjectAuthor"
read -p "Enter a name for your new project " InputName
ProjectName="ProjectName"
read -p "Enter a scope for your new project (optional) " InputScope

# Add dot to scope if provided
if [ ! -z "$InputScope" ]; then
  InputScope="$InputScope."
fi

ProjectScope="ProjectScope."

# Convert to lowercase using tr instead of bash-specific ${var,,} for better compatibility
InputScopeLower=$(echo "$InputScope" | tr '[:upper:]' '[:lower:]')
InputNameLower=$(echo "$InputName" | tr '[:upper:]' '[:lower:]')
ProjectScopeLower=$(echo "$ProjectScope" | tr '[:upper:]' '[:lower:]')
ProjectNameLower=$(echo "$ProjectName" | tr '[:upper:]' '[:lower:]')

echo "Your new com.${InputScopeLower}${InputNameLower} project is being created..."

# Check if Linux system has uuid-runtime for uuidgen
if [[ "$(uname)" != "Darwin" ]]; then
  if ! command -v uuidgen &> /dev/null && ! [ -f /proc/sys/kernel/random/uuid ]; then
    echo "Warning: Neither uuidgen nor /proc/sys/kernel/random/uuid found. GUIDs may not be generated correctly."
  fi
fi

# Function to perform cross-platform sed replace with proper escaping
# Usage: sed_replace "pattern" "replacement" "file"
sed_replace() {
  local pattern=$1
  local replacement=$2
  local file=$3
  local temp_file="${file}.tmp"
  
  # Escape special characters in the pattern and replacement
  pattern=$(echo "$pattern" | sed 's/[\/&]/\\&/g')
  replacement=$(echo "$replacement" | sed 's/[\/&]/\\&/g')
  
  # Set LC_ALL=C to handle special characters correctly
  if [[ "$(uname)" == "Darwin" ]]; then
    # macOS version
    LC_ALL=C sed -e "s/${pattern}/${replacement}/g" "${file}" > "${temp_file}" && mv "${temp_file}" "${file}"
  else
    # Linux version
    LC_ALL=C sed -i "s/${pattern}/${replacement}/g" "${file}"
  fi
}

# Remove and rename files/directories
rm -f ./README.md
rm -rf ./$ProjectScope$ProjectName/Assets/Samples 2>/dev/null || true
oldPackageRoot="./$ProjectScope$ProjectName/Packages/com.${ProjectScopeLower}${ProjectNameLower}"

# Copy readme - use uppercase README.md
if [ -f "$oldPackageRoot/Documentation~/README.md" ]; then
  cp "$oldPackageRoot/Documentation~/README.md" ./README.md
else
  # Fall back to other possible filename variations
  if [ -f "$oldPackageRoot/Documentation~/Readme.md" ]; then
    cp "$oldPackageRoot/Documentation~/Readme.md" ./README.md
  fi
fi

# Explicitly update package.json to ensure all fields are correctly replaced
packageJsonFile="$oldPackageRoot/package.json"
if [ -f "$packageJsonFile" ]; then
  echo "Updating package.json..."
  
  # Update package name (lowercase)
  sed_replace "com.${ProjectScopeLower}${ProjectNameLower}" "com.${InputScopeLower}${InputNameLower}" "$packageJsonFile"
  
  # Update display name (PascalCase)
  sed_replace "${ProjectScope}${ProjectName}" "${InputScope}${InputName}" "$packageJsonFile"
  
  # Update author name
  sed_replace "$ProjectAuthor" "$InputAuthor" "$packageJsonFile"
  
  # Update GitHub URLs
  sed_replace "github.com/$ProjectAuthor/com.${ProjectScopeLower}${ProjectNameLower}" "github.com/$InputAuthor/com.${InputScopeLower}${InputNameLower}" "$packageJsonFile"
fi

# Rename assembly definition files
mv "$oldPackageRoot/Runtime/$ProjectScope$ProjectName.asmdef" \
   "$oldPackageRoot/Runtime/$InputScope$InputName.asmdef"
mv "$oldPackageRoot/Editor/$ProjectScope$ProjectName.Editor.asmdef" \
   "$oldPackageRoot/Editor/$InputScope$InputName.Editor.asmdef"
mv "$oldPackageRoot/Tests/$ProjectScope$ProjectName.Tests.asmdef" \
   "$oldPackageRoot/Tests/$InputScope$InputName.Tests.asmdef"
mv "$oldPackageRoot/Samples~/Demo/$ProjectScope$ProjectName.Demo.asmdef" \
   "$oldPackageRoot/Samples~/Demo/$InputScope$InputName.Demo.asmdef"

# Rename package directory
mv "$oldPackageRoot" "./$ProjectScope$ProjectName/Packages/com.${InputScopeLower}${InputNameLower}"

# Rename project directory
mv "./$ProjectScope$ProjectName" "./$InputScope$InputName"

# Process all files, skipping certain directories and files
find . -type f -not -path "*/\.*" | grep -v "/Library/" | grep -v "/Obj/" | grep -v "InitializeTemplate" | while read file; do
  # Process file content if it exists and is a regular file (not binary)
  if [ -f "$file" ] && file "$file" | grep -q text; then
    updated=0
    
    # Replace PascalCase instances
    if grep -q "$ProjectName" "$file" 2>/dev/null; then
      sed_replace "$ProjectName" "$InputName" "$file"
      updated=1
    fi
    
    if grep -q "$ProjectScope" "$file" 2>/dev/null; then
      sed_replace "$ProjectScope" "$InputScope" "$file"
      updated=1
    fi
    
    if grep -q "$ProjectAuthor" "$file" 2>/dev/null; then
      sed_replace "$ProjectAuthor" "$InputAuthor" "$file"
      updated=1
    fi
    
    StephenHodgson="StephenHodgson"
    if grep -q "$StephenHodgson" "$file" 2>/dev/null; then
      sed_replace "$StephenHodgson" "$InputAuthor" "$file"
      updated=1
    fi
    
    # Replace lowercase instances
    if grep -q "$ProjectNameLower" "$file" 2>/dev/null; then
      sed_replace "$ProjectNameLower" "$InputNameLower" "$file"
      updated=1
    fi
    
    if grep -q "$ProjectScopeLower" "$file" 2>/dev/null; then
      sed_replace "$ProjectScopeLower" "$InputScopeLower" "$file"
      updated=1
    fi
    
    # Replace UPPERCASE instances
    ProjectNameUpper=$(echo "$ProjectName" | tr '[:lower:]' '[:upper:]')
    InputNameUpper=$(echo "$InputName" | tr '[:lower:]' '[:upper:]')
    if grep -q "$ProjectNameUpper" "$file" 2>/dev/null; then
      sed_replace "$ProjectNameUpper" "$InputNameUpper" "$file"
      updated=1
    fi
    
    ProjectScopeUpper=$(echo "$ProjectScope" | tr '[:lower:]' '[:upper:]')
    InputScopeUpper=$(echo "$InputScope" | tr '[:lower:]' '[:upper:]')
    if grep -q "$ProjectScopeUpper" "$file" 2>/dev/null; then
      sed_replace "$ProjectScopeUpper" "$InputScopeUpper" "$file"
      updated=1
    fi
    
    # Update GUIDs
    if grep -q "#INSERT_GUID_HERE#" "$file" 2>/dev/null; then
      # Generate a UUID
      if [[ "$(uname)" == "Darwin" ]]; then
        # macOS has uuidgen
        uuid=$(uuidgen | tr -d '-')
      elif command -v uuidgen &> /dev/null; then
        # Linux with uuidgen
        uuid=$(uuidgen | tr -d '-')
      else
        # Linux alternative using /proc
        uuid=$(cat /proc/sys/kernel/random/uuid 2>/dev/null | tr -d '-' || echo "00000000000000000000000000000000")
      fi
      sed_replace "#INSERT_GUID_HERE#" "$uuid" "$file"
      updated=1
    fi
    
    # Update year
    current_year=$(date +"%Y")
    if grep -q "#CURRENT_YEAR#" "$file" 2>/dev/null; then
      sed_replace "#CURRENT_YEAR#" "$current_year" "$file"
      updated=1
    fi
    
    # Rename files if needed
    filename=$(basename "$file")
    if [[ $filename == *"$ProjectName"* ]]; then
      newname=$(echo "$filename" | sed "s/$ProjectName/$InputName/g")
      mv "$file" "$(dirname "$file")/$newname"
      updated=1
    fi
    
    if [ $updated -eq 1 ]; then
      echo "$file"
    fi
  fi
done

# Create symbolic link for Samples - match the PowerShell implementation
cd "./$InputScope$InputName/Assets" 2>/dev/null || mkdir -p "./$InputScope$InputName/Assets"
# Use the correct path to Samples~ directory and create a proper symbolic link
ln -sf "../../$InputScope$InputName/Packages/com.${InputScopeLower}${InputNameLower}/Samples~" "Samples"
cd ../..

# Remove this script
rm -f InitializeTemplate.sh 
rm -f InitializeTemplate.ps1 