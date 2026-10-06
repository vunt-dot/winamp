#!/bin/sh
# Build a .deb that runs the Windows build of Winamp under Wine.
# Works on Ubuntu 24.04 and 26.04 (the package is architecture "all").
#
# Usage: packaging/linux/build-deb.sh <winamp-build-dir> [version] [output-dir]
#   <winamp-build-dir>  output of the Windows build, e.g. Build/Winamp_x86_Release
#   [version]           Debian version (default: 5.9.2-1)
#   [output-dir]        where to write the .deb (default: current directory)

set -eu

if [ $# -lt 1 ]; then
	sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'
	exit 1
fi

BUILD_DIR=$(cd "$1" && pwd)
VERSION=${2:-5.9.2-1}
OUT_DIR=$(cd "${3:-.}" && pwd)
HERE=$(cd "$(dirname "$0")" && pwd)
REPO=$(cd "$HERE/../.." && pwd)

[ -f "$BUILD_DIR/winamp.exe" ] || { echo "error: $BUILD_DIR/winamp.exe not found" >&2; exit 1; }
command -v dpkg-deb >/dev/null || { echo "error: dpkg-deb is required (apt install dpkg-dev)" >&2; exit 1; }

# PE machine type tells us whether this is the x86 or x64 build.
pe_offset=$(od -An -tu4 -j60 -N4 "$BUILD_DIR/winamp.exe" | tr -d ' ')
machine=$(od -An -tx2 -j$((pe_offset + 4)) -N2 "$BUILD_DIR/winamp.exe" | tr -d ' ')
case "$machine" in
	014c) PE_ARCH=x86 ;;
	8664) PE_ARCH=x64 ;;
	*) echo "error: unknown PE machine type 0x$machine" >&2; exit 1 ;;
esac

STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT
APP="$STAGE/opt/winamp"

mkdir -p "$APP" "$STAGE/DEBIAN" "$STAGE/usr/bin" \
	"$STAGE/usr/share/applications" "$STAGE/usr/share/icons/hicolor/256x256/apps" \
	"$STAGE/usr/share/doc/winamp"

# Program files (debug symbols are not needed at runtime).
(cd "$BUILD_DIR" && find . -type f ! -iname '*.pdb' ! -iname '*.ilk' ! -iname '*.lib' ! -iname '*.exp' -print) |
	while IFS= read -r f; do
		mkdir -p "$APP/$(dirname "$f")"
		cp -p "$BUILD_DIR/$f" "$APP/$f"
	done

# Classic skins, in case the build output predates the post-build copy.
mkdir -p "$APP/Skins"
for skin in "$REPO"/Src/resources/skins/*.wsz; do
	[ -e "$skin" ] && [ ! -e "$APP/Skins/$(basename "$skin")" ] && cp "$skin" "$APP/Skins/"
done

# /opt is read-only for users: keep winamp.ini etc. in %APPDATA%\Winamp inside the prefix.
cp "$HERE/paths.ini" "$APP/paths.ini"
[ "$PE_ARCH" = x86 ] && touch "$APP/.arch-x86"

install -m 0755 "$HERE/winamp" "$STAGE/usr/bin/winamp"
install -m 0644 "$HERE/winamp.desktop" "$STAGE/usr/share/applications/winamp.desktop"
install -m 0644 "$HERE/winamp.png" "$STAGE/usr/share/icons/hicolor/256x256/apps/winamp.png"
install -m 0644 "$REPO/LICENSE.md" "$STAGE/usr/share/doc/winamp/copyright"

find "$STAGE" -type d -exec chmod 0755 {} +
find "$APP" -type f -exec chmod 0644 {} +

INSTALLED_SIZE=$(du -sk --exclude=DEBIAN "$STAGE" | cut -f1)

cat > "$STAGE/DEBIAN/control" <<EOF
Package: winamp
Version: $VERSION
Section: sound
Priority: optional
Architecture: all
Installed-Size: $INSTALLED_SIZE
Depends: wine (>= 9.0) | wine-stable | wine-staging | wine-devel
Recommends: zenity, x11-xserver-utils
Maintainer: Winamp community build <noreply@localhost>
Homepage: https://github.com/WinampDesktop/winamp
Description: Winamp media player (Windows build running under Wine)
 The Winamp desktop player built from source, packaged to run under Wine.
 Ships the classic base-2.91 skin as the default and picks up the desktop
 scaling factor so classic skins are shown in double size on 4K displays.
 .
 The $PE_ARCH build needs 32-bit Wine on 64-bit Ubuntu:
   sudo dpkg --add-architecture i386 && sudo apt update
   sudo apt install wine32:i386
EOF

cat > "$STAGE/DEBIAN/postinst" <<'EOF'
#!/bin/sh
set -e
if [ "$1" = configure ]; then
	command -v update-desktop-database >/dev/null && update-desktop-database -q /usr/share/applications || true
	command -v gtk-update-icon-cache >/dev/null && gtk-update-icon-cache -q -t /usr/share/icons/hicolor || true
fi
EOF
cp "$STAGE/DEBIAN/postinst" "$STAGE/DEBIAN/postrm"
sed -i 's/= configure/= remove/' "$STAGE/DEBIAN/postrm"
chmod 0755 "$STAGE/DEBIAN/postinst" "$STAGE/DEBIAN/postrm"

DEB="$OUT_DIR/winamp_${VERSION}_all.deb"
dpkg-deb --root-owner-group -Zxz --build "$STAGE" "$DEB"
echo "built $DEB ($PE_ARCH build)"
