#!/bin/bash
# ci_pre_xcodebuild.sh
# Runs before xcodebuild starts
# Use for: Code generation, build number updates, pre-build checks

set -e

echo "=== Pre-Build Script ==="

# Log build configuration
echo "Scheme: ${CI_XCODEBUILD_SCHEME:-XitEditor}"
echo "Action: ${CI_XCODEBUILD_ACTION:-build}"

# Verify project structure
if [ -f "XitEditor.xcodeproj/project.pbxproj" ]; then
    echo "Project file found"
else
    echo "ERROR: Project file not found!"
    exit 1
fi

echo "Pre-build checks passed"
