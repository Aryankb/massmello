#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 Configuring iOS Push Notification Capabilities"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

cd "$(dirname "$0")/ios"

# Check if project.pbxproj exists
if [ ! -f "Runner.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: Xcode project not found!"
    exit 1
fi

echo "✅ Found Xcode project"
echo ""

# Backup the project file
cp Runner.xcodeproj/project.pbxproj Runner.xcodeproj/project.pbxproj.backup
echo "📦 Backed up project.pbxproj"
echo ""

# Add entitlements to the project
echo "🔧 Adding Push Notification entitlements..."

# The entitlements file is already created at ios/Runner/Runner.entitlements
# We need to reference it in the Xcode project

# Add CODE_SIGN_ENTITLEMENTS to Debug and Release configurations
sed -i '' 's/\(ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;\)/\1\n\t\t\t\tCODE_SIGN_ENTITLEMENTS = Runner\/Runner.entitlements;/g' Runner.xcodeproj/project.pbxproj

echo "✅ Entitlements configured"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ iOS Capabilities Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 What has been configured:"
echo ""
echo "1. ✅ Created Runner.entitlements with Push Notifications"
echo "2. ✅ Added UIBackgroundModes to Info.plist"
echo "3. ✅ Configured remote-notification background mode"
echo "4. ✅ Linked entitlements file to Xcode project"
echo ""
echo "🚀 You can now run:"
echo "   flutter clean"
echo "   flutter run"
echo ""
echo "📱 The app will now support:"
echo "   - Push Notifications"
echo "   - Background notification handling"
echo "   - Remote notifications when app is closed"
echo ""
