#!/usr/bin/env bash
# Masterix Plus rebrand v2. Repo ke root se chalao: bash rebrand.sh
# Idempotent hai: kitni bhi baar chalao, nuksan nahi. Upstream merge ke baad dobara chalao.
set -u

NAME="Masterix Plus"          # app ka poora naam
SHORT="Masterix"              # "CS", "CS Launcher", "CS Friends"... ki jagah
SHORT_UP="MASTERIX"
NAME_UP="MASTERIX PLUS"
VERSION_TEXT="v2.7"           # screen par dikhne wala version
VERSION_NAME="2.7"            # build.gradle ka versionName
OWNER="AbhayTheMaster"        # "Craft Studio" ki jagah
OWNER_UP="ABHAYTHEMASTER"
OLDID="com.craftstudio.cslauncher"
NEWID="com.abhaythemaster.masterixplus"
UPDATE_REPO="minecraftplayer90909090-lang/huhh"

[ -d app_cs ] || { echo "ERROR: app_cs folder nahi mila. Repo ke root me chalao."; exit 1; }

RES=app_cs/src/main/res
ASSETS=app_cs/src/main/assets
JAVA=app_cs/src/main/java
GRADLE=app_cs/build.gradle
MANIFEST=app_cs/src/main/AndroidManifest.xml
CHECKER=$JAVA/com/craftstudio/cslauncher/update/UpdateChecker.java
APIH=$JAVA/com/craftstudio/cslauncher/modding/modpacks/api/ApiHandler.java
NBSP=$(printf '\xc2\xa0')   # NBSP wali line dobara chalane par nahi badalti (original credit safe rehta hai)
NL='\\n'                    # sed ke liye literal \n

TMP=$(mktemp)
rm -f .github/workflows/android.yml

echo "[1/6] Phrases: CS Launcher / Engine / Friends / Craft Studio (res + assets)..."
cat > "$TMP" <<SED
/name="about_footer"/b
s/CS Launcher Plus 1\.4/$NAME $VERSION_TEXT/g
s/CS Launcher Plus/$NAME/g
s/CS LAUNCHER PLUS/$NAME_UP/g
s/CS Launcher/$SHORT/g
s/CS LAUNCHER/$SHORT_UP/g
s/CS Friends/$SHORT Friends/g
s/CS FRIENDS/$SHORT_UP FRIENDS/g
s/CS Engine/$SHORT Engine/g
s/CS ENGINE/$SHORT_UP ENGINE/g
s/CS Skins/$SHORT Skins/g
s/CS CONTROLS/$SHORT_UP CONTROLS/g
s/CS controls/$SHORT controls/g
/name="policy_[^"]*"/b
s/Craft Studio/$OWNER/g
s/CRAFT STUDIO/$OWNER/g
/name="brand_by_studio"/s/$OWNER/$OWNER_UP/g
SED
find "$RES" "$ASSETS" -type f \( -name '*.xml' -o -name '*.txt' -o -name '*.json' \) -print0 | xargs -0 sed -i -f "$TMP"

echo "[2/6] Akela 'CS' word (sirf strings*.xml ke text me)..."
cat > "$TMP" <<SED
/name="about_footer"/b
/parent=/b
/<style/b
s/\bCS\b/$SHORT/g
SED
find "$RES" -type f -name 'strings*.xml' -print0 | xargs -0 sed -i -f "$TMP"

echo "[3/6] Corner ka TEST, app label, version, About credit..."
cat > "$TMP" <<SED
s#(name="brand_full_name"[^>]*>)[^<]*(<)#\1$NAME\2#
s#(name="brand_short_name"[^>]*>)[^<]*(<)#\1$SHORT\2#
s#(name="app_short_name"[^>]*>)[^<]*(<)#\1$NAME\2#
s#(name="brand_version"[^>]*>)[^<]*(<)#\1$VERSION_TEXT\2#
s#(name="about_footer"[^>]*>).*(</string>)#\1Made with ❤ by $OWNER. Based on CS${NBSP}Launcher Plus by CRAFT${NBSP}STUDIO and the open source community.${NL}Thank you for playing.\2#
SED
find "$RES" -type f -name 'strings*.xml' -print0 | xargs -0 sed -i -E -f "$TMP"

echo "[4/6] Java ke text literals (comments nahi chhute)..."
cat > "$TMP" <<SED
/^[[:space:]]*(\*|\/\/|\/\*)/!{
s/CS Launcher Plus/$NAME/g
s/CS-Launcher-Plus/Masterix-Plus/g
s/CS Launcher/$SHORT/g
s/CS Engine/$SHORT Engine/g
s/CS Friends/$SHORT Friends/g
s/CS Skins/$SHORT Skins/g
s/CS controls/$SHORT controls/g
/new Credit\(/b
s/Craft Studio/$OWNER/g
}
SED
find "$JAVA" -type f -name '*.java' ! -name 'UpdateManager.java' -print0 | xargs -0 sed -i -E -f "$TMP"
[ -f "$APIH" ] && sed -i "s#CSLauncherPlus/1\.4 (by Craft Studio)#MasterixPlus/$VERSION_NAME (by $OWNER)#; s#CSLauncherPlus/1\.4 (by AbhayTheMaster)#MasterixPlus/$VERSION_NAME (by $OWNER)#" "$APIH"

echo "[5/6] Package id + update checker..."
sed -i -E \
  -e "s/(applicationId \")$OLDID(\")/\1$NEWID\2/" \
  -e "/resValue 'string', '(application_package|storageProviderAuthorities)'/s/$OLDID/$NEWID/" \
  -e "s/(versionName \")[^\"]*(\")/\1$VERSION_NAME\2/" \
  "$GRADLE"
sed -i "/<package android:name=\"$OLDID/s/$OLDID/$NEWID/" "$MANIFEST"
[ -f "$CHECKER" ] && sed -i "s#\"JoooaoooDVD/CSL2\"#\"$UPDATE_REPO\"#" "$CHECKER"
rm -f "$TMP"

echo "[6/6] Report"
echo "  applicationId  : $(grep -m1 'applicationId "' $GRADLE | xargs)"
echo "  versionName    : $(grep -m1 'versionName "' $GRADLE | xargs)"
echo "  update repo    : $(grep -m1 'String REPO' $CHECKER | xargs)"
echo "  corner/brand   : $(grep -m2 -E 'name="brand_(full|short)_name"' $RES/values/strings.xml | sed -E 's/ *<string name="([^"]*)"[^>]*>([^<]*)<.*/\1=\2/' | tr '\n' ' ')"
echo "  bacha TEST     : $(grep -rn '>TEST<' $RES | wc -l)"
echo "  bacha CS Launcher/Engine/Friends (res+assets): $(grep -rIE 'CS (Launcher|Engine|Friends|Skins)|Craft Studio|CRAFT STUDIO' $RES $ASSETS | grep -vE 'name="(about_footer|policy_[^"]*)"' | wc -l)"
echo "  bacha akela CS (strings): $(grep -rhE '\bCS\b' $RES --include='strings*.xml' | grep -vE 'name="about_footer"' | wc -l)"
echo "  bacha (java text): $(grep -rInE 'CS (Launcher|Engine|Friends|Skins)|Craft Studio' $JAVA | grep -vE '^[^:]*:[0-9]*:[[:space:]]*(\*|//|/\*)' | wc -l)"
git diff --stat 2>/dev/null | tail -1
echo "Ho gaya. Ab: git diff --stat dekho, phir commit + push."
