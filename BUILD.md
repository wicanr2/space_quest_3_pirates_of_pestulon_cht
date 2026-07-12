# 宇宙傳奇 III 繁中化 — Build 手冊

拿到 `patches/` + `docker/` + `tools/apply_patches.sh` + `dist-cht/` 後，照本檔即可重建 patched ScummVM。

## 0. 前置

1. 取乾淨 ScummVM 原始碼，版本對齊 `patches/UPSTREAM_COMMIT.txt` 記的 pinned commit。
2. 套用中文化引擎改動：
   ```bash
   tools/apply_patches.sh <scummvm-src-dir>
   ```
   會複製新檔 `engines/sci/graphics/fontchinese.{h,cpp}`（`GfxFontChinese`：Big5 繪字 + hi-res 32×28 loader），
   並套 `patches/0001-sci-cht-zh_twn.patch`（ZH_TWN 啟用、Big5 繪字、hi-res 640×400 live 文字、
   kFormat 動態句模板 hook + %s 參數翻譯 hook、GetLongest Big5 斷行修正、空白正規化 key、
   `SCI_DUMP_RES`、以及 **SQ3 標題 pic 926 中文副標疊圖 hook**）。

## 1. Linux（x86_64, native）

```bash
docker build -t sq3-build -f docker/Dockerfile.build .
docker run --rm --name sq3-build -v "$PWD/<scummvm-src>:/src" -w /src sq3-build bash -c \
  "./configure --disable-all-engines --enable-engine=sci --disable-detection-full && make -j\$(nproc)"
```

**[HARD] configure 順序**：`--disable-all-engines` 必須在 `--enable-engine=sci` **之前**。

**必加 flag**：
- `--disable-detection-full`：否則編全引擎 detection，`testbed` 缺 config.h 中斷。
- **不要帶 `--disable-mt32emu`**：本專案一律啟用 MT-32（Munt 編入，音色遠勝 AdLib）。

**[雷] 啟用 mt32emu 首編缺檔**：若報 `MT32EMU_VERSION_MAJOR/MINOR/PATCH was not declared`，是 Munt 版本標頭
`audio/softsynth/mt32/config.h` 缺席。從 pinned commit 補回：
```bash
curl -sfL "https://raw.githubusercontent.com/scummvm/scummvm/$(cat patches/UPSTREAM_COMMIT.txt)/audio/softsynth/mt32/config.h" \
  -o <scummvm-src>/audio/softsynth/mt32/config.h
```

## 2. 放中文資料 + 執行

把 `dist-cht/` 四個檔複製進遊戲資料夾（引擎讀取的寫死檔名）：
```
translation.tsv  qfg1_big5.fnt  qfg1_big5_hi.fnt  sq3_title.ovl
```
啟動（語言 = Traditional Chinese）：
```bash
./scummvm --path=<game-dir> --auto-detect --language=tw
```

## 3. 完整可玩包（Linux AppImage full，本機）

```bash
tools/package_appimage.sh
```
把 patched scummvm + `game/`（含中文資料）+ MT-32 ROM（`MT32_ROM_SRC`，預設 `/home/anr2/cht/mt32`）
打包成雙擊即玩的 `dist-all/SQ3-CHT-full-x86_64.AppImage`。**含遊戲資源與 ROM，只在本機、不上 GitHub。**

驗證 MT-32 載入成功：執行 log 出現 `Falling back to MT32`（Munt 先找 CM32L 才回退）即 OK。

## 4. 重生 patch（改了引擎後）

改完引擎 `git diff HEAD -- engines/sci > patches/0001-sci-cht-zh_twn.patch`（scummvm-src 為 pinned commit 的 git checkout），
或用 `tools/regen_patch.sh` 從 pristine upstream 逐檔 diff 重生並 `patch -p1 --dry-run` 驗證可套。

## 5. Windows / macOS（後續輪次）

- Windows：mingw 交叉編譯（`docker/Dockerfile.mingw`），configure 去 `--disable-mt32emu`，附 SDL2.dll + libwinpthread-1.dll。
- macOS：只能在 macOS host build（codesign/hdiutil），走 GitHub Actions `macos-14`。自源碼編 pinned 真 SDL2
  （**別 brew sdl2**，已是 sdl2-compat shim）。詳見 qfg-1 / kq4 專案的 macOS CI 經驗。

## 引擎改動摘要（技術）

核心：SCI0 EGA 在 `ZH_TWN` 時強制 640×400 upscale，Chinese 字型以 hi-res Big5 字模直繪 display buffer；
內容為 key 的 translation.tsv 查表替換（空白正規化命中硬換行句）；kFormat 模板 + %s 參數雙重 hook 讓動態句與插入詞也中文化；
標題 pic 926 在 `paint16.cpp drawPicture()` 末尾 blit `sq3_title.ovl` 中文副標到 640×400 display buffer
（**SQ3 標題是動畫繪製，中文副標放底部 plaque 才不被 logo 動畫覆蓋**）。
