#!/bin/bash
# ci_post_xcodebuild.sh
# Runs after xcodebuild completes
# Use for: Notifications, artifact processing, cleanup

set -e

echo "=== Post-Build Script ==="

# Check if build succeeded
if [ "${CI_XCODEBUILD_EXIT_CODE:-0}" -eq 0 ]; then
    echo "Build completed successfully!"

    # Log archive info if available
    if [ -n "${CI_ARCHIVE_PATH}" ]; then
        echo "Archive path: ${CI_ARCHIVE_PATH}"
    fi

    # Log product path if available
    if [ -n "${CI_PRODUCT_PATH}" ]; then
        echo "Product path: ${CI_PRODUCT_PATH}"
    fi
else
    echo "Build failed with exit code: ${CI_XCODEBUILD_EXIT_CODE}"
fi

echo "Build number: ${CI_BUILD_NUMBER:-local}"
echo "Workflow: ${CI_WORKFLOW:-manual}"
