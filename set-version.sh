#!/bin/bash

# Check if a version argument is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <version>"
  exit 1
fi

# Get the version from the first argument
VERSION=$1

export VERSION

# Use find to locate all Chart.yaml files recursively
find . -name "Chart.yaml" | while IFS= read -r file; do
  echo "Updating $file to version $VERSION"

  # Update the version field and dependencies in each document
  yq e -i '(.. | select(tag == "!!map" and has("version"))).version = env(VERSION)' "$file"
  yq e -i '(.. | select(tag == "!!map" and has("dependencies"))).dependencies[] |= select(has("version")).version = env(VERSION)' "$file"
done

echo "Updated version to $VERSION in all Chart.yaml files."
