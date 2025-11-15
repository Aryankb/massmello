#!/bin/bash

# FCM Integration Quick Start Script
# This script helps you choose and apply a solution for the dependency conflict

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔥 Firebase Cloud Messaging (FCM) Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Choose a solution for the dependency conflict:"
echo ""
echo "1) Temporarily disable Google ML Kit (Quick - for FCM testing)"
echo "2) Keep both (requires manual package version adjustments)"
echo "3) Cancel (I'll fix it manually)"
echo ""
read -p "Enter your choice (1-3): " choice

case $choice in
  1)
    echo ""
    echo "✅ Option 1: Temporarily disabling Google ML Kit..."
    echo ""
    
    # Backup pubspec.yaml
    cp pubspec.yaml pubspec.yaml.backup
    echo "📦 Backed up pubspec.yaml to pubspec.yaml.backup"
    
    # Comment out google_ml_kit
    sed -i.bak 's/^  google_ml_kit:/#  google_ml_kit:/' pubspec.yaml
    sed -i.bak 's/^  camera:/#  camera:/' pubspec.yaml
    
    echo "🔧 Commented out google_ml_kit and camera in pubspec.yaml"
    echo ""
    
    # Clean and get dependencies
    echo "🧹 Running flutter clean..."
    flutter clean
    
    echo "📥 Running flutter pub get..."
    flutter pub get
    
    # iOS pods
    echo "🍎 Installing iOS pods..."
    cd ios
    rm -rf Pods Podfile.lock
    pod install
    cd ..
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ Setup Complete!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📋 Next Steps:"
    echo ""
    echo "1. Add your Firebase config files:"
    echo "   - android/app/google-services.json (from Firebase Console)"
    echo "   - ios/Runner/GoogleService-Info.plist (from Firebase Console)"
    echo ""
    echo "2. Add iOS capabilities in Xcode:"
    echo "   - Open ios/Runner.xcworkspace"
    echo "   - Add 'Push Notifications' capability"
    echo "   - Add 'Background Modes' → Enable 'Remote notifications'"
    echo ""
    echo "3. Run the app:"
    echo "   flutter run"
    echo ""
    echo "4. Check console for your FCM token!"
    echo ""
    echo "⚠️  To restore Google ML Kit later:"
    echo "   cp pubspec.yaml.backup pubspec.yaml"
    echo ""
    ;;
    
  2)
    echo ""
    echo "ℹ️  Option 2: Manual Configuration"
    echo ""
    echo "You'll need to manually adjust package versions in pubspec.yaml"
    echo "to find compatible versions of Firebase and Google ML Kit."
    echo ""
    echo "See DEPENDENCY_CONFLICT_SOLUTION.md for details."
    echo ""
    ;;
    
  3)
    echo ""
    echo "👍 No problem! Check DEPENDENCY_CONFLICT_SOLUTION.md for options."
    echo ""
    ;;
    
  *)
    echo ""
    echo "❌ Invalid choice. Please run the script again."
    echo ""
    ;;
esac
