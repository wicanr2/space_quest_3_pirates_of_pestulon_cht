# SQ3 中文化 WORKLIST

## M0 — scaffold + 盤點 ✅（2026-07-12）
- [x] workplace 骨架（複用 kq4 tools/patches/docker）
- [x] 遊戲資源轉小寫 → `game/`（sci:sq3 偵測成功）
- [x] `SCI_DUMP_RES` dump：96 text / 123 script / 186 view / 115 pic / 10 font
- [x] 抽字：text 1201 + script 195 = **1396 則 / 95k 英文字元** → `full_skeleton.tsv`
- [x] 姊妹專案預填命中 91 則(6%) → `prefill.tsv`（SQ3 劇情獨立）
- [x] 烘字型 smoke test：引擎以 `--language=tw` 啟動全程無 crash，字型載入 OK

## M1 — 抽字 + skeleton + 複用 ✅（併入 M0）
- [x] full_skeleton 1396 則、prefill 91 則
- [ ] （選）清理預填殘留雜字（`�`×8、`ա`×1）

## M2 — 批次翻譯 + 烘字型 ✅（2026-07-12）
- [x] 拆批（1305 未譯 → 19 批 ~70 則）
- [x] 統一譯名表（INSTRUCTIONS.md：羅傑·威爾科/佩斯圖倫/廢渣軟體/仙女座雙傑…）
- [x] 試作批定調（台式在地化重）→ 18 批 sonnet 並行翻譯
- [x] 逐行驗證全 19 批：1305 行、col1 byte-exact、佔位符完整、無雜訊
- [x] parser 指令/除錯字串保留英文（agent 判別）
- [x] 專名漂移掃描：無漂移（統一表生效）
- [x] merge → build_cht 16px（1797 字）+ hi-res 32px
- [x] 修預填殘留雜字（Be more specific.）；無非 Big5 字
- [x] **覆蓋 1365/1396（97%）；實機截圖驗證中文對白正常渲染 ✅**

## M3 — 標題疊圖 + baked-art + 驗證（大部分完成）
- [x] 標題 pic id = **926**（SCI_LOG_GFX）
- [x] Designer subagent 中文副標 `.ovl`（宇宙傳奇III．佩斯圖倫的海盜）
- [x] drawPicture hook 改 96→926 + sq3_title.ovl，增量重編引擎
- [x] **底部 plaque 版實機驗證**：頂部被 logo 動畫覆蓋 → 改底部（grid 上、copyright 上方 y=352），金字清晰可讀、不蓋 logo/紅副標 ✅
- [x] patch 0001 同步 SQ3 title hook（409 行）
- [x] headless 實機驗證中文對白（開場旁白）✅
- [ ] 選單列/狀態列中文驗證（text-based，已譯，待截圖確認）
- [ ] baked-art view 檢查（SQ3 text-parser 介面，預期無需重繪 view cel）

## M4 — 打包 + 文件 ⏳（本輪聚焦 Linux 可玩版 + 文件）
- [x] **Linux AppImage full 版**（14MB，內嵌遊戲+MT-32 ROM）→ dist-all
- [x] 實機驗證：自動偵測 sq3、中文渲染、`Falling back to MT32`（ROM 載入成功）、含全 RESOURCE.*
- [x] dist-cht/ patch-only 資料（translation.tsv + 雙字型 + sq3_title.ovl，無遊戲資源）
- [x] README 圖文並茂（故事/截圖/特色/安裝/手冊索引/致敬）
- [x] 英文手冊翻中文 markdown（19 頁 → manual_cht/宇宙傳奇III手冊.md）
- [x] BUILD.md（重建說明）
- [x] .gitignore（patch-only 合規：game/ROM/dist-all 不入庫，保留 dist-cht/manual_cht）
- [ ] Windows/macOS 雙軌 + patch 版 Release（後續輪次，使用者選先出 Linux）
- [ ] promo 影片（使用者暫緩）

## M5 — 字型縮小 + 選單/狀態列中文 + F1 新手說明 ✅（2026-07-12，實測回饋）
- [x] 字型太大 → 採 LSL2 fontchinese（kBig5Width 16→14、hi-res 32/28→24/24），build_translation bake 參數同步
- [x] 選單列加高（ports.cpp ZH_TWN 9→15px）防中文殘影；選單標題（動作/速度/音效）已中文
- [x] **狀態列 DrawStatus 雙位元組修正**：原逐 byte 繪→Big5 lead byte 洩漏 font.0「missing glyph」→ 修合併後狀態列「分數」中文、**missing glyph 歸零**
- [x] **F1 新手操作說明框**（event.cpp 攔 F1→SciEngine::showChtHelp bitsSave+Box+bitsRestore，文字在 translation key SQ3_CHT_HELP）；實測顯示完整、關閉還原正常
- [x] patch 0001 重生（13 檔 754 行，dry-run 通過）；regen_patch.sh 持久化為 SQ3 版
- [x] dist-cht 更新 + AppImage 重建（14MB）

## M5.1 — 狀態列分數字型修正（實測回饋）✅
- [x] 低解析字型烘 15→**14px**（build_cht --size 14），符合「14px 更好看」
- [x] 狀態/選單列 ZH_TWN 加高 15→17px + 文字下移 y1→y2（menu.cpp kernelDrawStatus/drawBar）→ 14px 字上留 2px、下留 1px，**分數不再被切**
- [x] patch 0001 重生（14 檔 784 行，+menu.cpp，dry-run 通過）；dist-cht + AppImage 重建驗證

## M5.2 — 狀態列分數底部被切「真因」修正 ✅
- [x] 真因：SCI0 遊戲畫面固定從 y10 開始畫（`ports.cpp offTop=10`），只留 10px 給狀態列 → 17px 狀態列的中文字底部被 room 覆蓋（選單是 modal 疊上去所以沒事）
- [x] 修：ZH_TWN 時 `offTop 10→17`（畫面原點下推），room 不再蓋狀態列 → 14px 分數上下完整。畫面下移 7px（底部地板）實測無感
- [x] patch 重生（14 檔 797 行，dry-run 通過）；AppImage 重建驗證「分數：0 / 738」完整

## M5.3 — F1 HELP 改 hi-res 密集置中版（實測回饋）✅
- [x] 確認原 F1 help 已是 hi-res，但排版鬆散（Box 用 fontHeight=14 行距 + 大框）
- [x] 重寫 showChtHelp：逐行自繪（`GfxText16::Draw`）、**行距收緊 13px**、白框依內容 `StringWidth` 自動收緊 + 置中；hi-res 銳利維持（top≥8 走 hi-res 路徑）
- [x] help 內容改短行密集版（look看/get拿… 一行、F5存檔 F7讀檔…）
- [x] patch 重生（14 檔 832 行，dry-run 通過）；AppImage 重建驗證 hi-res 密集置中、關閉還原正常、missing glyph 歸零

## M5.4 — 中文字距再收緊（實測回饋）✅
- [x] `kBig5Width` 14→13（字 advance，hi-res 字實寬 12px → 字距從 2px 收到 1px）；約束 kHiW(24)≤kBig5Width×2 仍成立
- [x] help 更密集、狀態列低解析仍可讀；patch/fontchinese.cpp 同步、AppImage 重建
- 備註：可再到 12（字距 0/貼齊）但低解析狀態列會開始被切，需再處理，暫留 13

## M5.5 — 採 LSL2 字型方案（advance 10 / glyph 20）+ 狀態列走 hi-res（實測回饋）✅
- [x] 採 LSL2 fontchinese：kBig5Width=10（advance）、kHiW/kHiH=20（glyph 20px=10px logical）；密集但夠大好讀
- [x] 補漏的 LSL2 bake_hires_font.py（ceil stride，支援 width 非 8 倍數）——先前漏複製導致 hi-res 只烘 710 字壞掉
- [x] bake_hires --size 18 --height 20 --width 20；build_cht --size 14（對齊建構子 _big5Height init，低解析當 fallback）
- [x] **還原 offTop=10（不下推畫面，撤銷「延長命令列」做法）**；menuBarH 17→12
- [x] **狀態列/選單走 hi-res（menuBar=false）**：kBig5Width=10 會裁 16px 低解析字模；hi-res 20px=10px logical 正好塞標準 10px 列、銳利不切。狀態/選單列 fillRect+bitsShow 重繪 display，不殘影
- [x] 根因記錄：Big5Font `loadPrefixedRaw(height)` 用建構子寫死 _big5Height，與 build_cht --size 不符會讀錯位→字沒 index→'?'；低解析 Big5Font 固定 16px 寬，kBig5Width<16 會裁
- [x] AppImage 重建驗證：分數 hi-res 不切、對白/F1 密集、missing glyph 歸零
