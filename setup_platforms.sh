#!/bin/bash
# Chạy MỘT LẦN sau khi đã có thư mục ios/ và android/ (sau "flutter create").
# Thêm các quyền cần cho: chơi online qua Wi-Fi, quét mã QR.
#   ./setup_platforms.sh
set -e

PLIST="ios/Runner/Info.plist"
MANIFEST="android/app/src/main/AndroidManifest.xml"

if [ -f "$PLIST" ]; then
  P=/usr/libexec/PlistBuddy
  $P -c "Delete :NSCameraUsageDescription" "$PLIST" 2>/dev/null || true
  $P -c "Add :NSCameraUsageDescription string Quét mã QR để kết bạn và vào bàn" "$PLIST"
  $P -c "Delete :NSLocalNetworkUsageDescription" "$PLIST" 2>/dev/null || true
  $P -c "Add :NSLocalNetworkUsageDescription string Playtime dùng mạng Wi-Fi để chơi cùng bạn bè" "$PLIST"
  echo "✔ iOS: đã thêm quyền Camera và Mạng cục bộ"
else
  echo "⚠ Không thấy $PLIST (bỏ qua iOS)"
fi

if [ -f "$MANIFEST" ]; then
  if ! grep -q "android.permission.INTERNET" "$MANIFEST"; then
    perl -0pi -e 's#<application#<uses-permission android:name="android.permission.INTERNET"/>\n    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>\n    <uses-permission android:name="android.permission.CAMERA"/>\n    <application#' "$MANIFEST"
    echo "✔ Android: đã thêm quyền Internet/Camera"
  else
    echo "✔ Android: quyền đã có sẵn"
  fi
else
  echo "⚠ Không thấy $MANIFEST (bỏ qua Android)"
fi
