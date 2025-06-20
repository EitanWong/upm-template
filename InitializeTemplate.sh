#!/bin/bash
# Copyright (c) Eitan. All rights reserved.
# Licensed under the MIT License. See LICENSE in the project root for license information.

# Ensure script is executable
if [[ ! -x "$0" ]]; then
  chmod +x "$0"
fi

# Collect user input
read -p "Set Author name: (i.e. your GitHub username) " InputAuthor
ProjectAuthor="ProjectAuthor"
read -p "Enter a name for your new project " InputName
ProjectName="ProjectName"
read -p "Enter a scope for your new project (optional) " InputScope

# Handle optional scope
if [ -n "$InputScope" ]; then
  InputScope="$InputScope."
fi

ProjectScope="ProjectScope."

# Function to convert string to lowercase (compatible with both BSD and GNU)
to_lower() {
  echo "$1" | tr '[:upper:]' '[:lower:]'
}

echo "Your new com.$(to_lower "$InputScope")$(to_lower "$InputName") project is being created..."
rm -f "./README.md"
rm -rf "./$ProjectScope$ProjectName/Assets/Samples"
oldPackageRoot="./$ProjectScope$ProjectName/Packages/com.$(to_lower "$ProjectScope")$(to_lower "$ProjectName")"
cp "$oldPackageRoot/Documentation~/README.md" "./README.md"
mv "$oldPackageRoot/Runtime/$ProjectScope$ProjectName.asmdef" "$oldPackageRoot/Runtime/$InputScope$InputName.asmdef"
mv "$oldPackageRoot/Editor/$ProjectScope$ProjectName.Editor.asmdef" "$oldPackageRoot/Editor/$InputScope$InputName.Editor.asmdef"
mv "$oldPackageRoot/Tests/$ProjectScope$ProjectName.Tests.asmdef" "$oldPackageRoot/Tests/$InputScope$InputName.Tests.asmdef"
mv "$oldPackageRoot/Samples~/Demo/$ProjectScope$ProjectName.Demo.asmdef" "$oldPackageRoot/Samples~/Demo/$InputScope$InputName.Demo.asmdef"
mv "$oldPackageRoot" "./$ProjectScope$ProjectName/Packages/com.$(to_lower "$InputScope")$(to_lower "$InputName")"
mv "./$ProjectScope$ProjectName" "./$InputScope$InputName"

# Process files to replace content
excludes=("*Library*" "*Obj*" "*InitializeTemplate*")

# Function to perform sed replacement that works on both macOS and Linux
safe_sed() {
  local pattern="$1"
  local replacement="$2"
  local file="$3"
  
  # Try macOS/BSD sed syntax first, fall back to GNU sed if it fails
  sed -i '' "s/$pattern/$replacement/g" "$file" 2>/dev/null || sed -i "s/$pattern/$replacement/g" "$file"
}

# Function to generate a UUID
generate_uuid() {
  # Try multiple methods to generate UUID
  if command -v uuidgen &>/dev/null; then
    uuidgen
  elif command -v python &>/dev/null; then
    python -c 'import uuid; print(uuid.uuid4())'
  elif command -v python3 &>/dev/null; then
    python3 -c 'import uuid; print(uuid.uuid4())'
  else
    # Fallback method if no tools are available
    od -x /dev/urandom | head -1 | awk '{OFS="-"; print $2$3,$4,$5,$6,$7$8$9}'
  fi
}

find . -type f | while read -r file; do
  # Check if file should be excluded
  valid=true
  for exclude in "${excludes[@]}"; do
    if [[ $(dirname "$file") == $exclude || $(dirname "$file") =~ $exclude ]]; then
      valid=false
      break
    fi
  done

  if [ "$valid" = true ]; then
    updated=false

    # Rename all PascalCase instances
    if grep -q "$ProjectName" "$file" 2>/dev/null; then
      safe_sed "$ProjectName" "$InputName" "$file"
      updated=true
    fi

    if grep -q "$ProjectScope" "$file" 2>/dev/null; then
      safe_sed "$ProjectScope" "$InputScope" "$file"
      updated=true
    fi

    if grep -q "$ProjectAuthor" "$file" 2>/dev/null; then
      safe_sed "$ProjectAuthor" "$InputAuthor" "$file"
      updated=true
    fi

    Eitan="Eitan"
    if grep -q "$Eitan" "$file" 2>/dev/null; then
      safe_sed "$Eitan" "$InputAuthor" "$file"
      updated=true
    fi

    # Rename all lowercase instances
    ProjectNameLower=$(to_lower "$ProjectName")
    InputNameLower=$(to_lower "$InputName")
    if grep -q "$ProjectNameLower" "$file" 2>/dev/null; then
      safe_sed "$ProjectNameLower" "$InputNameLower" "$file"
      updated=true
    fi

    ProjectScopeLower=$(to_lower "$ProjectScope")
    InputScopeLower=$(to_lower "$InputScope")
    if grep -q "$ProjectScopeLower" "$file" 2>/dev/null; then
      safe_sed "$ProjectScopeLower" "$InputScopeLower" "$file"
      updated=true
    fi

    # Rename all UPPERCASE instances
    ProjectNameUpper=$(echo "$ProjectName" | tr '[:lower:]' '[:upper:]')
    InputNameUpper=$(echo "$InputName" | tr '[:lower:]' '[:upper:]')
    if grep -q "$ProjectNameUpper" "$file" 2>/dev/null; then
      safe_sed "$ProjectNameUpper" "$InputNameUpper" "$file"
      updated=true
    fi

    ProjectScopeUpper=$(echo "$ProjectScope" | tr '[:lower:]' '[:upper:]')
    InputScopeUpper=$(echo "$InputScope" | tr '[:lower:]' '[:upper:]')
    if grep -q "$ProjectScopeUpper" "$file" 2>/dev/null; then
      safe_sed "$ProjectScopeUpper" "$InputScopeUpper" "$file"
      updated=true
    fi

    # Update guids
    if grep -q "#INSERT_GUID_HERE#" "$file" 2>/dev/null; then
      uuid=$(generate_uuid)
      safe_sed "#INSERT_GUID_HERE#" "$uuid" "$file"
      updated=true
    fi

    # Update year
    current_year=$(date +"%Y")
    if grep -q "#CURRENT_YEAR#" "$file" 2>/dev/null; then
      safe_sed "#CURRENT_YEAR#" "$current_year" "$file"
      updated=true
    fi

    # Rename files
    filename=$(basename "$file")
    if [[ "$filename" == *"$ProjectName"* ]]; then
      newname="${filename//$ProjectName/$InputName}"
      mv "$file" "$(dirname "$file")/$newname"
      updated=true
    fi

    if [ "$updated" = true ]; then
      echo "$filename"
    fi
  fi
done

# Create symbolic link for Samples
cd "./$InputScope$InputName/Assets" || exit
ln -s "../../$InputScope$InputName/Packages/com.$(to_lower "$InputScope")$(to_lower "$InputName")/Samples~" "Samples"
cd "../.." || exit

# Make the script executable before removing it
chmod +x InitializeTemplate.sh

# Clean up initialization scripts
rm -f "InitializeTemplate.ps1"
rm -f "InitializeTemplate.sh" 