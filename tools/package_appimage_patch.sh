#!/usr/bin/env bash
# 把 patched ScummVM + 中文化資料(translation.tsv + 兩個 .fnt + title .ovl)打包成
# **patch 版** AppImage——不含遊戲資源,玩家自備遊戲、AppRun 用第一參數當遊戲路徑。
# 上 GitHub Release(公開下載)。[HARD] 不得含 resource.*/.drv/sciv.exe。
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"          # /home/anr2/scummvm/space_quest3/workplace
REPO_ROOT="$(cd "$ROOT/.." && pwd)"                # /home/anr2/scummvm/space_quest3
# build/打包用的 docker image 可用環境變數覆蓋：原本寫死 qfg1-build:latest，
# 那是當初從 QFG1 專案沿用的建置 image，機器上不一定還在（清過就沒了）。
# 這幾步（strip / ldd 收集 .so / appimagetool）不挑 image，任何同世代的 Debian
# 建置 image 都能用，所以留一個出口而不是寫死。
BUILD_IMG="${BUILD_IMG:-qfg1-build:latest}"
source "$ROOT/tools/pkg_common.sh"

STAGE="$ROOT/build/appimg-patch"
DIST="$REPO_ROOT/dist-all"
APPDIR="$STAGE/AppDir"
OUT="$DIST/SQ3-CHT-patch-x86_64.AppImage"

mkdir -p "$DIST"
rm -rf "$APPDIR"; mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/lib" "$APPDIR/usr/share/scummvm-cht"

echo ">> 複製 scummvm + strip"
cp "$ROOT/scummvm-src/scummvm" "$APPDIR/usr/bin/scummvm"
docker run --rm --name sq3-pkg-patch-strip -v "$APPDIR/usr/bin:/b" "$BUILD_IMG" strip /b/scummvm 2>/dev/null || true

echo ">> 收集共享庫(qfg1-build 內 ldd,排除 glibc 核心)"
docker run --rm --name sq3-pkg-patch-libs \
  -v "$APPDIR/usr/bin/scummvm:/collect/bin:ro" \
  -v "$APPDIR/usr/lib:/collect/out" \
  -v "$ROOT/tools/pkg_collect_libs.py:/collect/collect.py:ro" \
  -w /collect "$BUILD_IMG" python3 collect.py bin out
echo "   $(ls "$APPDIR/usr/lib" | wc -l) 個 .so"

echo ">> 放入中文化資料(patch-only,不含遊戲)"
cp "$ROOT/dist-cht/translation.tsv" "$APPDIR/usr/share/scummvm-cht/"
cp "$ROOT/dist-cht/qfg1_big5.fnt" "$APPDIR/usr/share/scummvm-cht/"
cp "$ROOT/dist-cht/qfg1_big5_hi.fnt" "$APPDIR/usr/share/scummvm-cht/"
cp "$ROOT/dist-cht/sq3_title.ovl" "$APPDIR/usr/share/scummvm-cht/"

# AppRun:patch 版玩家自備遊戲——第一參數當遊戲夾路徑,--extrapath 指向中文化資料。
cat > "$APPDIR/AppRun" <<'APPRUN'
#!/bin/bash
HERE="$(dirname "$(readlink -f "$0")")"
export LD_LIBRARY_PATH="$HERE/usr/lib:${LD_LIBRARY_PATH:-}"
if [ -z "${1:-}" ]; then
  echo "用法: $(basename "$0") <SQ3 遊戲資料夾路徑> [其他 scummvm 參數...]"
  echo "  範例: ./SQ3-CHT-patch-x86_64.AppImage ~/games/sq3"
  exit 1
fi
GAME="$1"; shift
exec "$HERE/usr/bin/scummvm" --path="$GAME" --extrapath="$HERE/usr/share/scummvm-cht" --language=tw --auto-detect "$@"
APPRUN
chmod +x "$APPDIR/AppRun"

cat > "$APPDIR/sq3-cht.desktop" <<DESK
[Desktop Entry]
Type=Application
Name=宇宙傳奇III Pestulon的海盜（繁體中文版・patch）
Comment=Space Quest III: The Pirates of Pestulon 繁體中文化 — ScummVM patch(需自備遊戲)
Exec=AppRun
Icon=sq3-cht
Categories=Game;
Terminal=false
DESK
cp "$ROOT/tools/assets/sq3-cht.png" "$APPDIR/sq3-cht.png"
ln -sf sq3-cht.png "$APPDIR/.DirIcon"

rm -f "$OUT"
echo ">> appimagetool 打包(--appimage-extract-and-run 免 FUSE)"
docker run --rm --name sq3-pkg-patch-appimagetool -v "$STAGE:/stage" -v "$ROOT/tools/.cache:/cache:ro" -e ARCH=x86_64 -w /stage \
  "$BUILD_IMG" bash -c "apt-get update -qq >/dev/null && apt-get install -y -qq file >/dev/null && \
    /cache/appimagetool-x86_64.AppImage --appimage-extract-and-run 'AppDir' '/stage/$(basename "$OUT")'"
mv "$STAGE/$(basename "$OUT")" "$OUT"
chmod +x "$OUT"
echo ">> 完成: $OUT ($(du -h "$OUT" | cut -f1))"
