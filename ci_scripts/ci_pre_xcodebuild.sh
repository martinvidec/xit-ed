#!/bin/bash
# ci_pre_xcodebuild.sh
# Runs before xcodebuild starts
# Use for: Code generation, build number updates, pre-build checks

set -e

echo "=== Pre-Build Script ==="

# Navigate to workspace root (CI_WORKSPACE is set by Xcode Cloud)
cd "${CI_WORKSPACE:-$(dirname "$0")/..}"
echo "Working directory: $(pwd)"

# Log build configuration
echo "Scheme: ${CI_XCODEBUILD_SCHEME:-XitEditor}"
echo "Action: ${CI_XCODEBUILD_ACTION:-build}"

# Verify project structure
if [ -f "XitEditor.xcodeproj/project.pbxproj" ]; then
    echo "Project file found"
else
    echo "WARNING: Project file not found at expected location"
    echo "Contents of workspace:"
    ls -la
fi

echo "Pre-build checks passed"
