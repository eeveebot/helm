#!/bin/bash

# Check if a version argument is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <version>"
  exit 1
fi

# Get the version from the first argument
VERSION=$1

export VERSION

# Find all Chart.yaml files recursively and update the version
find . -name "Chart.yaml" | while IFS= read -r file; do
  echo "Updating $file to version $VERSION"
  yq e -i '(.version) = env(VERSION)' "$file"
done

echo "Updated version to $VERSION in all Chart.yaml files."
