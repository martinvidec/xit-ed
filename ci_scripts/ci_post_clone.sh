#!/bin/bash
# ci_post_clone.sh
# Runs after Xcode Cloud clones the repository
# Use for: Installing dependencies, setting up environment

set -e

echo "=== Post Clone Script ==="
echo "Repository cloned successfully"
echo "Xcode version: $(xcodebuild -version | head -1)"
echo "macOS version: $(sw_vers -productVersion)"
echo "Build number: ${CI_BUILD_NUMBER:-local}"
echo "Branch: ${CI_BRANCH:-$(git branch --show-current)}"
echo "Commit: ${CI_COMMIT:-$(git rev-parse --short HEAD)}"
