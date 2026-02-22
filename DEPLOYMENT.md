# App Store Deployment Guide

This guide covers deploying xit!ed to the Mac App Store.

## Prerequisites

- [ ] Apple Developer Program membership ($99/year)
- [ ] App created in App Store Connect
- [ ] Bundle ID registered (currently using `net.jotaen.xit`)

## Deployment Options

### Option A: Xcode Cloud (Recommended)

**Cost:** 25 hours/month FREE with Apple Developer Program

Xcode Cloud provides native CI/CD integration with automatic code signing and direct TestFlight/App Store deployment.

#### Setup

1. Open `XitEditor.xcodeproj` in Xcode
2. Product → Xcode Cloud → Create Workflow
3. Connect your GitHub repository
4. Configure workflow:
   - **Start Condition:** Push to `main` or Git Tag (e.g., `v*`)
   - **Actions:** Build, Archive
   - **Post-Actions:** TestFlight or App Store

Code signing is managed automatically when "Automatically manage signing" is enabled in Xcode.

#### Custom Scripts

The `ci_scripts/` folder contains hooks for the Xcode Cloud build process:

- `ci_post_clone.sh` - Runs after repository clone
- `ci_pre_xcodebuild.sh` - Runs before build starts
- `ci_post_xcodebuild.sh` - Runs after build completes

### Option B: Manual via Xcode

For occasional releases:

1. Product → Archive
2. Window → Organizer
3. Select archive → Distribute App → App Store Connect
4. Follow the wizard to upload

### Option C: Command Line

```bash
# Archive
xcodebuild -project XitEditor.xcodeproj \
  -scheme XitEditor \
  -archivePath build/XitEditor.xcarchive \
  archive

# Export for App Store
xcodebuild -exportArchive \
  -archivePath build/XitEditor.xcarchive \
  -exportPath build/ \
  -exportOptionsPlist ExportOptions.plist

# Upload to App Store Connect
xcrun altool --upload-package build/XitEditor.pkg \
  -u "YOUR_APPLE_ID" \
  -p "@keychain:AC_PASSWORD" \
  --type osx \
  --apple-id "APP_APPLE_ID" \
  --bundle-id "net.jotaen.xit"
```

Store your App Store Connect password in Keychain:
```bash
xcrun altool --store-password-in-keychain-item "AC_PASSWORD" \
  -u "YOUR_APPLE_ID" -p "APP_SPECIFIC_PASSWORD"
```

### Option D: Fastlane

Install and initialize:
```bash
brew install fastlane
cd /path/to/xit-ed
fastlane init
```

Example `Fastfile`:
```ruby
default_platform(:mac)

platform :mac do
  lane :release do
    build_mac_app(
      scheme: "XitEditor",
      export_method: "app-store"
    )
    upload_to_app_store
  end

  lane :beta do
    build_mac_app(
      scheme: "XitEditor",
      export_method: "app-store"
    )
    upload_to_testflight
  end
end
```

Run with: `fastlane release`

## App Store Connect Setup

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. My Apps → "+" → New App
3. Fill in:
   - **Platform:** macOS
   - **Name:** xit!ed
   - **Primary Language:** English
   - **Bundle ID:** Select or register `net.jotaen.xit`
   - **SKU:** `xited` (unique identifier)

## Required App Store Assets

### App Information
- App name and subtitle
- Privacy policy URL
- Category: Productivity or Utilities

### Screenshots
macOS App Store requires screenshots at specific resolutions:
- 1280 x 800 pixels (minimum)
- 1440 x 900 pixels
- 2560 x 1600 pixels (Retina)
- 2880 x 1800 pixels (Retina)

### App Icon
- 1024 x 1024 pixels PNG (no transparency, no rounded corners)

### Description
- Up to 4000 characters
- Keywords (up to 100 characters, comma-separated)
- What's New text for updates

## Versioning

Before each release, update the version in Xcode:
- **Version:** Semantic version (e.g., 1.0.0)
- **Build:** Incrementing number (e.g., 1, 2, 3...)

Each build number must be unique per version when uploading to App Store Connect.

## Testing with TestFlight

1. Upload build via any method above
2. In App Store Connect → TestFlight
3. Add internal testers (up to 100, instant access)
4. Add external testers (up to 10,000, requires review)

## Submitting for Review

1. Complete all App Store Connect metadata
2. Select a build from TestFlight
3. Submit for Review
4. Review typically takes 24-48 hours

## Resources

- [App Store Connect Help](https://developer.apple.com/help/app-store-connect/)
- [Xcode Cloud Documentation](https://developer.apple.com/documentation/xcode/xcode-cloud)
- [Fastlane for macOS](https://docs.fastlane.tools/actions/build_mac_app/)
- [Human Interface Guidelines - macOS](https://developer.apple.com/design/human-interface-guidelines/macos)
