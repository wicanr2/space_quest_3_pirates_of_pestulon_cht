# 宇宙傳奇 III：Pestulon 的海盜 — CONTEXT

Space Quest III: The Pirates of Pestulon（SCI0 EGA）ScummVM 繁體中文化。

## 引擎軌 / 關鍵事實（M0 盤點 2026-07-12）

| 項目 | 值 |
|---|---|
| 引擎 | **SCI0**（ScummVM `sci` 引擎），game id `sci:sq3` |
| 偵測全名 | Space Quest III: The Pirates of Pestulon (DOS/English) |
| 文字資源 | **只有 `text.*`（96 個），無 `message.*`**（SCI0 特徵，同 kq4/qfg EGA 軌） |
| 資源規模 | 96 text / 123 script / 186 view / 115 pic / 10 font |
| 翻譯量 | text **1201 則** + script 內嵌 **195 則** = full_skeleton **1396 則**（~95k 英文字元） |
| 姊妹專案預填 | 對 kq4/qfg-1/qfg2/larry 譯文正規化比對命中 **91 則(6%)**（系統 UI/parser 回應）→ SQ3 科幻喜劇劇情獨立，94% 需新譯 |
| 同劇情他版 | **無**（SQ3 從未出過 VGA remake）→ 無同劇情譯本可複用 |
| 中文啟用 | config `language=tw` 或 CLI `--language=tw`（引擎判 `getLanguage()==ZH_TWN`） |
| 引擎讀取檔名（寫死） | `translation.tsv`、`qfg1_big5.fnt`、`qfg1_big5_hi.fnt`、`sq3_title.ovl`（沿用 qfg-1 檔名，放 game path） |
| MT-32 | `mt32.drv` 原盤內附 → enable MT-32（configure 不帶 `--disable-mt32emu`） |
| **標題 pic** | **pic 926**（SPACE QUEST logo）。`paint16.cpp drawPicture` hook：`pictureId==926 && ZH_TWN` blit `sq3_title.ovl`。**SQ3 標題是動畫繪製（logo 以 view 疊在 pic 上）→ 頂部疊圖被覆蓋，中文副標放底部 plaque（grid 上、copyright 上方，y=352）才存活** |
| 覆蓋率 | **1384/1415（97%）**；其餘刻意保留英文（parser 指令/除錯變數/專名/反轉文字 gag/credits 角色標籤） |
| **過場 crawl 補譯（2026-07-12 promo 擷取時揪出）** | 開場旁白、逃生艙漂流、黑洞穿越、次光速、星球掃描讀數、片尾致謝等 **script 內嵌硬 `\n` 多行 crawl**，抽字時被 skeleton 拆成碎片、build 因無 tab 丟棄 → 從未進 translation.tsv → 實機全顯英文（WORKLIST 曾誤記「開場旁白中文 ✅」）。修：`tools/build_crawl_fixups.py` 從 script dump 定位確切原文 → `\s+→單空格+trim` 算正規化 key（與引擎 `sciChtNormKey` 一致，sci.cpp:886）→ 配台式在地化譯文共 18 筆，append 進 skeleton（zz_crawls.done batch）。headless 實測開場旁白 hi-res 中文渲染 OK。**教訓：script 內嵌多行資源（\n 分行）易被逐行工具拆裂漏掉；playtest 實機才揪得出（CLAUDE.md ⑨）** |
| **字型尺寸** | 採 LSL2 方案：`kBig5Width=10`（advance）、hi-res `kHiW/kHiH=20`（20px=10px logical，密集但夠大）；bake `--size 18 --height 20 --width 20`（bake_hires 用 ceil stride 支援非 8 倍數）；build_cht `--size 14`（對齊建構子 _big5Height init，低解析僅 fallback）。**狀態列/選單走 hi-res（menuBar=false），offTop=10 不下推畫面**——kBig5Width=10 下 16px 低解析會裁，hi-res 10px logical 正好塞標準 10px 列 |
| **選單/狀態列** | 選單列標題（動作/速度/音效）走 GfxText16 已中文；`ports.cpp` ZH_TWN 選單列加高 9→15px 防中文溢出殘影；`text16.cpp DrawStatus` 修雙位元組合併（原逐 byte 繪 → Big5 lead byte 洩漏 font.0「missing glyph」亂碼）→ 狀態列「分數」中文、missing glyph 歸零 |
| **F1 新手說明** | SQ3 無內建指令教學 → `event.cpp` 攔 F1（ZH_TWN）呼叫 `SciEngine::showChtHelp()`（sci.cpp）：`bitsSave`+白框+**逐行 `GfxText16::Draw` hi-res 銳利繪製（行距 13px 密集、白框依 StringWidth 收緊置中）**（文字在 translation key `SQ3_CHT_HELP`）+等按鍵+`bitsRestore`。`_inChtHelp` 防重入 |
| patch | 0001-sci-cht-zh_twn.patch **14 檔 819 行**（+ fontchinese.{h,cpp} 整檔）；`tools/regen_patch.sh` 對 pristine 3d408ec 重生驗證通過 |

## 範本複用（kq4 = 同軌 SCI0 EGA 最新範本）

`~/scummvm/kq4/workplace` 是最近的 SCI0 EGA 成熟範本，SQ3 同為 SCI0：

- **引擎 patch 不綁遊戲 → 直接複用**：`patches/0001-sci-cht-zh_twn.patch` + `fontchinese.{h,cpp}`（pinned upstream `3d408ec`）。含 ZH_TWN 啟用、Big5 繪字、hi-res 640×400 live 文字、kFormat 動態句 hook、GetLongest 日文 kinsoku 誤傷 Big5 修正、空白正規化 key、drawPicture 標題疊圖 hook。**預期一行引擎碼都不用改**即讓 SQ3 顯中文。
- **工具鏈全 game-agnostic 複用**：`extract_strings.py`、`extract_ega_scripts.py`、`build_cht.py`、`bake_hires_font.py`、`sci0_view.py`/`sci_view.py`、`merge_translations.py`、打包 `package_*.sh`、`build_title_overlay.py`。
- **現成 patched binary**：`~/scummvm/kq4/workplace/scummvm-src/scummvm`（含 SCI ZH_TWN + fontchinese）→ M0/M1 dump/驗證直接借用。

## 環境

- docker image `qfg1-build:latest`（SCI-only build）、`qfg1-capture:latest`（+Xvfb/imagemagick/xdotool 截圖）、`qfg1-mingw`/`kq4-mingw`（Windows 交叉編譯）。
- dump 資源：`SCI_DUMP_RES=<dir>` env hook（**dump 完不自退，docker run 一律 `timeout` 包**）。
- 本機缺 `libjpeg.so.62`，binary 必須在 `qfg1-build` docker 內跑。

## 交付原則（硬）

- 中文化**僅放 ScummVM patch**：引擎 patch + `dist-cht/`（translation.tsv + 字型 + 標題 .ovl）+ view/pic patch。原遊戲資源不入庫。
- 完整包（含遊戲 + MT-32 ROM）只在本機 `dist-all/`（gitignore）。
- MT-32 一律 enable。ROM 不入 GitHub（`*.ROM` gitignore）。

## GitHub repo

https://github.com/wicanr2/space_quest_3_pirates_of_pestulon_cht.git （patch-only）
