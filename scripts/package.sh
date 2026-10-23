#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LC="$ROOT/work/livecontainer"
SS="$ROOT/work/sidestore"
OUT="$ROOT/artifacts"
ARCHIVE="$OUT/LiveContainer.xcarchive"
APP_REL="Payload/LiveContainer.app"

command -v ldid >/dev/null 2>&1 || brew install ldid

mkdir -p "$ROOT/tools" "$OUT"
if [ ! -x "$ROOT/tools/dylibify" ]; then
  echo "==> downloading dylibify"
  curl -fL --retry 3 -o "$ROOT/tools/dylibify" \
    https://github.com/LiveContainer/dylibify/releases/download/1.0/dylibify
  chmod +x "$ROOT/tools/dylibify"
fi

rm -rf "$OUT/Payload" "$OUT/tmp" "$OUT/SideLive.ipa"
cp -R "$ARCHIVE/Products/Applications" "$OUT/Payload"
APP="$OUT/$APP_REL"

echo "==> adding SideStore-only Info.plist keys"
/usr/libexec/PlistBuddy -c 'Add :ALTAppGroups array' "$APP/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c 'Delete :ALTAppGroups' "$APP/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c 'Add :ALTAppGroups array' "$APP/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :ALTAppGroups: string group.com.SideStore.SideStore' "$APP/Info.plist"

/usr/libexec/PlistBuddy -c 'Delete :CFBundleURLTypes:1' "$APP/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c 'Add :CFBundleURLTypes:1 dict' "$APP/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleURLTypes:1:CFBundleURLName string com.kdt.livecontainer.sidestoreurlscheme' "$APP/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleURLTypes:1:CFBundleURLSchemes array' "$APP/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleURLTypes:1:CFBundleURLSchemes:0 string sidestore' "$APP/Info.plist"
/usr/libexec/PlistBuddy -c 'Delete :CFBundleURLTypes:2' "$APP/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c 'Add :CFBundleURLTypes:2 dict' "$APP/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleURLTypes:2:CFBundleURLName string com.kdt.livecontainer.sidestorebackupurlscheme' "$APP/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleURLTypes:2:CFBundleURLSchemes array' "$APP/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleURLTypes:2:CFBundleURLSchemes:0 string sidestore-com.kdt.livecontainer' "$APP/Info.plist"

/usr/libexec/PlistBuddy -c 'Add :INIntentsSupported array' "$APP/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c 'Add :INIntentsSupported:0 string RefreshAllIntent' "$APP/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c 'Add :INIntentsSupported:1 string ViewAppIntent' "$APP/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c 'Add :NSUserActivityTypes array' "$APP/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c 'Add :NSUserActivityTypes:0 string RefreshAllIntent' "$APP/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c 'Add :NSUserActivityTypes:1 string ViewAppIntent' "$APP/Info.plist" 2>/dev/null || true

ROOTPLIST="$APP/Settings.bundle/Root.plist"
if [ -f "$ROOTPLIST" ]; then
  echo "==> adding Settings toggle"
  /usr/libexec/PlistBuddy -c 'Delete :PreferenceSpecifiers:3' "$ROOTPLIST" 2>/dev/null || true
  /usr/libexec/PlistBuddy -c 'Add :PreferenceSpecifiers:3 dict' "$ROOTPLIST"
  /usr/libexec/PlistBuddy -c 'Add :PreferenceSpecifiers:3:Type string PSToggleSwitchSpecifier' "$ROOTPLIST"
  /usr/libexec/PlistBuddy -c 'Add :PreferenceSpecifiers:3:Title string Open SideStore' "$ROOTPLIST"
  /usr/libexec/PlistBuddy -c 'Add :PreferenceSpecifiers:3:Key string LCOpenSideStore' "$ROOTPLIST"
  /usr/libexec/PlistBuddy -c 'Add :PreferenceSpecifiers:3:DefaultValue bool false' "$ROOTPLIST"
fi

mkdir -p "$OUT/tmp"
echo "==> unpacking built SideStore"
unzip -q "$SS/SideStore.ipa" -d "$OUT/tmp/sidestore"
SIDE_APP="$OUT/tmp/sidestore/Payload/SideStore.app"
test -d "$SIDE_APP"
rm -rf "$APP/Frameworks/SideStoreApp.framework"
mv "$SIDE_APP" "$APP/Frameworks/SideStoreApp.framework"

echo "==> dylibifying SideStore"
"$ROOT/tools/dylibify" \
  "$APP/Frameworks/SideStoreApp.framework/SideStore" \
  "$APP/Frameworks/SideStoreApp.framework/SideStore.dylib"
rm -f "$APP/Frameworks/SideStoreApp.framework/SideStore"
mv "$APP/Frameworks/SideStoreApp.framework/SideStore.dylib" \
   "$APP/Frameworks/SideStoreApp.framework/SideStore"
ldid -S"" "$APP/Frameworks/SideStoreApp.framework/SideStore"
cp "$LC/.github/sidelc/LCAppInfo.plist" "$APP/Frameworks/SideStoreApp.framework/"

if [ -f "$APP/Frameworks/SideStoreApp.framework/Intents.intentdefinition" ]; then
  cp "$APP/Frameworks/SideStoreApp.framework/Intents.intentdefinition" "$APP/"
fi
if [ -f "$APP/Frameworks/SideStoreApp.framework/ViewApp.intentdefinition" ]; then
  cp "$APP/Frameworks/SideStoreApp.framework/ViewApp.intentdefinition" "$APP/"
fi
if [ -d "$APP/Frameworks/SideStoreApp.framework/Metadata.appintents" ]; then
  rm -rf "$APP/Metadata.appintents"
  cp -R "$APP/Frameworks/SideStoreApp.framework/Metadata.appintents" "$APP/Metadata.appintents"
  /usr/bin/sed -i '' 's/9SideStore20RefreshAllAppsIntentV/16SideStoreSupport20RefreshAllAppsIntentV/g' "$APP/Metadata.appintents/extract.actionsdata" || true
  /usr/bin/sed -i '' 's/9SideStore26RefreshAllAppsWidgetIntentV/16SideStoreSupport26RefreshAllAppsWidgetIntentV/g' "$APP/Metadata.appintents/extract.actionsdata" || true
fi

WIDGET_SRC="$APP/Frameworks/SideStoreApp.framework/PlugIns/AltWidgetExtension.appex"
if [ -d "$WIDGET_SRC" ]; then
  echo "==> repackaging widget extension"
  rm -rf "$APP/PlugIns/LiveWidgetExtension.appex"
  mv "$WIDGET_SRC" "$APP/PlugIns/LiveWidgetExtension.appex"
  WIDGET="$APP/PlugIns/LiveWidgetExtension.appex"
  /usr/libexec/PlistBuddy -c 'Set :CFBundleIdentifier com.kdt.livecontainer.LiveWidget' "$WIDGET/Info.plist"
  /usr/libexec/PlistBuddy -c 'Set :CFBundleExecutable LiveWidgetExtension' "$WIDGET/Info.plist"
  mv "$WIDGET/AltWidgetExtension" "$WIDGET/LiveWidgetExtension"
fi

echo "==> stripping signatures"
find "$OUT/Payload" -type d -name "_CodeSignature" -prune -exec rm -rf {} +

if [ -d "$APP/PlugIns/LiveWidgetExtension.appex" ]; then
  ldid -S"$LC/.github/sidelc/LiveWidgetExtension_adhoc.xml" \
    "$APP/PlugIns/LiveWidgetExtension.appex/LiveWidgetExtension"
fi

echo "==> zipping"
cd "$OUT"
zip -qr "SideLive.ipa" "Payload" -x "._*" -x ".DS_Store" -x "__MACOSX"

test -f "$OUT/SideLive.ipa"
echo "==> $OUT/SideLive.ipa"
unzip -l "$OUT/SideLive.ipa" | grep -E "SideStoreApp.framework/SideStore$|SideStoreApp.framework/LCAppInfo.plist|LiveWidgetExtension" | head
