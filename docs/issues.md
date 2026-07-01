# Issues

GitHub Issues を現在の作業単位にする。このファイルは完了済み証跡と優先度メモを残す補助文書。

## Issue Triage

- scope の正本: `docs/development_scope.md`
- 現在の最優先: デバッグ環境、Claude Code global hook dogfood、privacy-safe diagnostics
- issue label:
  - `priority:p0`: 次に着手する。壊れていると開発が止まる
  - `priority:p1`: P0 後に進める
  - `priority:p2`: 重要だが今すぐではない
  - `scope:now`: 現在の開発対象
  - `scope:later`: やるが今はやらない
  - `scope:wont-do`: 方針としてやらない
  - `area:debug`, `area:privacy`, `area:visual`, `area:audio`, `area:release`
  - `type:task`

## Open GitHub Issues

1. [#1 P0: 開発/デバッグ環境の基礎を作る](https://github.com/yoheiuc/code-village/issues/1)
   - Labels: `priority:p0`, `scope:now`, `area:debug`, `type:task`
   - Next: 最初に着手する。1 command debug runner と `docs/debugging.md` を作る。
2. [#2 P0: Claude Code global hook を実機 dogfood する](https://github.com/yoheiuc/code-village/issues/2)
   - Labels: `priority:p0`, `scope:now`, `area:debug`, `area:privacy`, `type:task`
   - Next: 実 Claude Code session から inbox/save import まで確認する。
3. [#3 P1: Godot debug overlay / dev panel を追加する](https://github.com/yoheiuc/code-village/issues/3)
   - Labels: `priority:p1`, `scope:now`, `area:debug`, `type:task`
   - Next: P0 debug runner 後に、ゲーム内診断表示を開発時限定で作る。
4. [#4 P1: GitHub Actions で headless regression を回す](https://github.com/yoheiuc/code-village/issues/4)
   - Labels: `priority:p1`, `scope:now`, `area:debug`, `type:task`
   - Next: Python / manifest CI を先に入れ、Godot headless CI は実現性を確認する。
5. [#5 P1: Visual MVP gap を production asset 差し替え前提で整理する](https://github.com/yoheiuc/code-village/issues/5)
   - Labels: `priority:p1`, `scope:later`, `area:visual`, `type:task`
   - Later: デバッグ環境と dogfood 後に進める。
6. [#6 P2: macOS signed release export と notarization を整備する](https://github.com/yoheiuc/code-village/issues/6)
   - Labels: `priority:p2`, `scope:later`, `area:release`, `type:task`
   - Later: Visual MVP と配布準備が近づいたら進める。
7. [#7 P0: 初回 free-user aha loop を作る](https://github.com/yoheiuc/code-village/issues/7)
   - Labels: `priority:p0`, `scope:now`, `area:debug`, `type:task`
   - Next: 空 inbox / Git 未登録でも 1 click で村が変わる導線を作る。
8. [#8 P0: Growth feedback contract を定義して主要イベントに適用する](https://github.com/yoheiuc/code-village/issues/8)
   - Labels: `priority:p0`, `scope:now`, `area:debug`, `area:visual`, `type:task`
   - Next: GrowthEvent ごとに村内変化、一時演出、diary/resident 文を保証する。
9. [#9 P1: Save削除と危険操作の確認UIを追加する](https://github.com/yoheiuc/code-village/issues/9)
   - Labels: `priority:p1`, `scope:now`, `area:privacy`, `type:task`
   - Next: Delete Local Save を 1 click で実行しない確認 UI にする。
10. [#10 P1: Production asset acceptance checklist と license tracking を作る](https://github.com/yoheiuc/code-village/issues/10)
    - Labels: `priority:p1`, `scope:later`, `area:visual`, `type:task`
    - Later: 有料配布前の production asset gate と権利確認を作る。
11. [#11 P1: Main orchestration を段階的に分離する](https://github.com/yoheiuc/code-village/issues/11)
    - Labels: `priority:p1`, `scope:later`, `area:debug`, `type:task`
    - Later: `main.gd` の責務集中を解消し、複数 agent 作業の衝突を減らす。
12. [#13 P0: Living-being gameplay contract を定義する](https://github.com/yoheiuc/code-village/issues/13)
    - Labels: `priority:p0`, `scope:now`, `area:visual`, `type:task`
    - Next: 小さな生き物の habitat、GrowthEvent 反応、rest-day 反応を定義する。
13. [#14 P0: Rest-day healing visitor を追加する](https://github.com/yoheiuc/code-village/issues/14)
    - Labels: `priority:p0`, `scope:now`, `area:visual`, `type:task`
    - Next: 空 inbox / no new event でも責めない生き物の気配を出す。
14. [#15 P1: 1種の placeholder companion を村に表示する](https://github.com/yoheiuc/code-village/issues/15)
    - Labels: `priority:p1`, `scope:now`, `area:visual`, `type:task`
    - Next: manifest と `VillageSpriteLayer` に 1 種の placeholder companion を接続する。
15. [#16 P1: Production companion asset backlog と originality gate を追加する](https://github.com/yoheiuc/code-village/issues/16)
    - Labels: `priority:p1`, `scope:later`, `area:visual`, `type:task`
    - Later: 有料配布前の companion production art と copy review gate を作る。
16. [#18 P1: Ambient Mac mini window spike を行う](https://github.com/yoheiuc/code-village/issues/18)
    - Labels: `priority:p1`, `scope:later`, `area:visual`, `area:debug`, `type:task`
    - Later: Godot-only の小型常駐ウィンドウで、低負荷かつ非侵入的な ambient presence を検証する。
17. [#19 P1: FeedbackController と event reaction debounce を実装する](https://github.com/yoheiuc/code-village/issues/19)
    - Labels: `priority:p1`, `scope:later`, `area:visual`, `type:task`
    - Later: `GrowthEvent` から visual reaction / companion reaction / SE cue を作る adapter を実装する。
18. [#20 P1: Healing audio controls と AudioManager contract を実装する](https://github.com/yoheiuc/code-village/issues/20)
    - Labels: `priority:p1`, `scope:later`, `area:audio`, `area:privacy`, `type:task`
    - Later: mute、volume、play/pause、background audio opt-in、SFX rate limit を実装する。
19. [#21 P1: inbox long-run dedupe / compaction を整備する](https://github.com/yoheiuc/code-village/issues/21)
    - Labels: `priority:p1`, `scope:later`, `area:debug`, `area:privacy`, `type:task`
    - Later: 長時間起動と巨大 inbox で重複成長や UI stall を起こさないようにする。
20. [#22 P2: native macOS menu bar / Dock integration feasibility を検証する](https://github.com/yoheiuc/code-village/issues/22)
    - Labels: `priority:p2`, `scope:later`, `area:release`, `area:privacy`, `type:task`
    - Later: Swift / AppKit helper、Godot native plugin、wrapper の実現性と signing 影響を比較する。
21. [#23 P1: audio asset license / originality gate を作る](https://github.com/yoheiuc/code-village/issues/23)
    - Labels: `priority:p1`, `scope:later`, `area:audio`, `area:privacy`, `type:task`
    - Later: BGM / SE / ambient sound の source、license、copy review を production gate にする。

`scope:wont-do` は、基本的には作業 issue ではなく `docs/development_scope.md` の Won't Do を正本にする。方針違反を防ぐための lint / test / documentation 作業が必要になった場合だけ issue 化する。

## Done

1. Claude Code activity inbox
   - Evidence: `ClaudeCodeActivityIngestor` and `tools/code_village_event.py`
2. Git非依存のClaude Code成長ルール
   - Evidence: `claude_code_session -> workshop_upgraded`, `claude_code_turn_completed -> flower_bloomed`
3. Claude Code inbox privacy sanitizer
   - Evidence: Godot unit test and `tests/test_code_village_event.py`
4. Git scanner の空 repo 対応
   - Evidence: `tests/run_unit_tests.gd` の `empty repo should not create events`
5. 保存データ削除 UI
   - Evidence: Settings の `Delete Local Save` と `SaveManager.delete_save()`
6. repo 登録削除 UI
   - Evidence: Settings の `Remove Current Repo`
7. テスト成功の手動入力
   - Evidence: Manual Notes の `Log Passing Tests` が `tests_passed -> lantern_lit` を発火
8. 成長イベントの重複抑制
   - Evidence: 前回 scan metadata と同じ activity window では GrowthEvent を出さない
9. Git scanner の detached HEAD / worktree 対応
   - Evidence: `tests/run_unit_tests.gd` の detached/worktree scanner tests
10. 手動振り返り入力の日記反映
   - Evidence: manual reflection note becomes `diary_entry_created.description`
11. runtime screenshot review
   - Evidence: `artifacts/screenshots/mvp-initial.png`
12. ダミー素材 manifest と production 差し替え口
   - Evidence: `assets/asset_manifest.json`, `scripts/assets/asset_catalog.gd`, `assets/placeholders/README.md`
13. Claude Code hook 設定と自動取り込み
   - Evidence: `.claude/settings.json`, startup/10秒 poll import, `docs/claude_code_hook_setup.md`
14. 初回ガイドの小型化と非表示保存
   - Evidence: `onboarding_guide_dismissed`, top guide strip, Settings 内 optional Git repo input
15. manifest-driven Sprite2D object layer
   - Evidence: `sprite_layout`, `VillageSpriteLayer`, Sprite2D load test
16. TileMapLayer terrain/path/water layer
   - Evidence: `VillageTileLayer`, Godot unit test for TileSet and painted cells
17. Growth-count flowers and lanterns as Sprite2D
   - Evidence: `VillageSpriteLayer.apply_village_state`, flower/lantern sprite-count tests
18. Git-free Claude Code inbox growth integration
   - Evidence: `tests/run_unit_tests.gd` imports Claude Code inbox events, generates GrowthEvents, and updates `VillageState` without a repo id
19. Godot startup smoke for Claude Code inbox auto-import
   - Evidence: `tests/test_code_village_event.py` writes temp inbox events, runs Godot with `CODE_VILLAGE_SAVE_PATH`, and checks saved `VillageState`
20. Unsigned macOS debug export
   - Evidence: `export_presets.cfg`, `builds/mac/CodeVillage.zip` export command succeeded, extracted `.app` binary started headless
21. Compact always-on HUD pass
   - Evidence: manual notes and optional Git input moved into Settings; initial screenshot refreshed at `artifacts/screenshots/mvp-initial.png`
22. Settings and registered-state screenshot review
   - Evidence: `artifacts/screenshots/mvp-settings.png`, `artifacts/screenshots/mvp-registered.png`, no prefilled local repo path test
23. Initial guide and village ribbon compression
   - Evidence: shorter onboarding sign, lower village ribbon height, refreshed screenshot set
24. Right action plate compression
   - Evidence: compact Today/Import/Git/Settings plate, refreshed `artifacts/screenshots/mvp-initial.png`, `artifacts/screenshots/mvp-settings.png`, `artifacts/screenshots/mvp-registered.png`
25. Manifest-driven state visual overlays
   - Evidence: `state_visual_rules`, `VillageSpriteLayer.state_sprite_count`, `release_bell_rings`, and `artifacts/screenshots/mvp-grown.png`
26. Manifest-driven environment sprites
   - Evidence: `environment` manifest section, `tree.svg`, `plaza_core.svg`, `VillageSpriteLayer` load test, refreshed screenshot set, exported `.app` screenshot check
27. Claude Code hook command contract test
   - Evidence: `tests/test_code_village_event.py` executes `.claude/settings.json` SessionStart/Stop commands with temp inbox/save and verifies Git-free village growth
28. Bottom village notices as separated plaques
   - Evidence: `MainHUD` bottom ribbon split into three plaque panels and refreshed `artifacts/screenshots/mvp-initial.png`, `artifacts/screenshots/mvp-settings.png`, `artifacts/screenshots/mvp-grown.png`
29. Today diary date tolerance
   - Evidence: `VillageState.get_today_entries()` accepts local/UTC date prefixes and GDScript test covers today diary display
30. Transient GrowthEvent effects
   - Evidence: `growth_effect_anchors`, `effects/growth_pulse.svg`, `VillageSpriteLayer.show_growth_events()`, unit texture test, and `artifacts/screenshots/mvp-growth-effect.png`
31. HUD plaques and Workshop Settings polish
   - Evidence: `VillageStatusSign`, `VillageToolShelf`, `WorkshopSettingsBoard`, HUD unit assertions, and refreshed `artifacts/screenshots/mvp-initial.png` / `artifacts/screenshots/mvp-settings.png`
32. Event-specific placeholder GrowthEvent effects
   - Evidence: `assets/placeholders/effects/*.svg`, per-target `growth_effect_anchors.path`, GDScript manifest tests, and refreshed `artifacts/screenshots/mvp-growth-effect.png`
33. Claude hook self-test CLI
   - Evidence: `tools/claude_hook_self_test.py`, `tests/test_code_village_event.py`, and docs for temp inbox/save verification
34. Reproducible MVP screenshot capture CLI
   - Evidence: `tools/capture_mvp_screenshots.py`, refreshed screenshot set, and bottom plaque line cap test
35. Asset manifest validator
   - Evidence: `tools/validate_asset_manifest.py`, `tests/test_asset_manifest_tool.py`, docs for placeholder validation and production gate
36. Claude hook real-inbox status check
   - Evidence: `tools/claude_hook_status.py`, `tests/test_claude_hook_status.py`, docs for `--require-events` and `--require-save-import`
37. Godot editor load smoke and screenshot review refresh
   - Evidence: `godot --editor --path . --quit-after 1` succeeded, latest screenshot review reflected in `docs/visual_mvp_gap.md`
38. Right tool shelf icon-button pass
   - Evidence: `MainHUD` uses placeholder UI SVG icons for Import/Git/Settings, GDScript HUD assertions, refreshed screenshot set
39. Workshop Settings compact pass
   - Evidence: Settings text and action labels shortened, panel height reduced, refreshed `artifacts/screenshots/mvp-settings.png`
40. Resident message speech bubble pass
   - Evidence: `ResidentSpeechBubble`, GDScript visibility assertions, refreshed screenshot set
41. Bottom board/book style pass
   - Evidence: `IssueBoardPlaque`, `VillageDiaryBook`, GDScript HUD assertions, refreshed screenshot set
42. Claude Code auto import setting toggle
   - Evidence: Settings checkbox, `UserSettings.auto_import_claude_events` save update, HUD assertions, startup auto-import-off smoke test
43. 初回ガイドのClaude Code/Privacy説明強化
   - Evidence: `FirstRunGuideBoard` shows Claude Code as the primary local input, keeps Git optional, names Local only / No sync and prompt/response/source/diff/secrets exclusions, and hides while Workshop Settings is open
44. 空/破損saveの安全フォールバック
   - Evidence: `SaveManager.load_game()` returns defaults for empty, malformed, or non-object save files without crashing; GDScript tests cover all three cases
45. save復旧の起動時smokeとHUD通知
   - Evidence: `Main` displays `Local save recovered. Using safe defaults.` when `SaveManager.last_load_warning` is set; Python startup smoke covers an existing empty save file without JSON parse errors
46. CHANGELOG の追加
   - Evidence: `CHANGELOG.md` records Functional MVP changes, privacy notes, verification, known gaps, and release notes policy
47. macOS debug export verifier
   - Evidence: `tools/verify_macos_export.py` builds the unsigned debug zip, checks forbidden repo paths are not zip entries, and launches the extracted app with temp save/inbox paths; `tests/test_macos_export_tool.py` covers zip policy
48. Claude Code global user hook setup
   - Evidence: `~/.claude/settings.json` can use SessionStart/Stop hooks that call `<CODE_VILLAGE_DIR>/tools/code_village_event.py`; temp inbox verification wrote sanitized `claude_code_session` and `claude_code_turn_completed` events without raw path/session/prompt/response
49. Claude Code inbox long-run checkpoint
   - Evidence: `claude_activity_import_checkpoint`, tail-read import, latest-ID cache, oversized/malformed line guard, GDScript checkpoint tests, and Python two-run startup smoke prevent duplicate growth after ID trim
50. First placeholder companion
   - Evidence: `assets/placeholders/characters/lamp_moth.svg`, `characters.lamp_moth`, manifest `sprite_layout`, manifest-driven idle motion, GrowthEvent reaction hook, refreshed screenshot set, and GDScript sprite assertions

## P0

1. Godot editor で MVP 画面を目視確認する
   - Acceptance: 村、HUD、repo 登録パネルが崩れず表示される
   - Note: runtime screenshot では主要要素は見える。`godot --editor --path . --quit-after 1` は成功。2026-07-01 に GUI Editor 起動ログ取得も成功したが、macOS `screencapture` は黒画面、Computer Use の app state 取得は timeout したため、Godot Editor 内での手動操作目視はまだ未実行。
2. Claude Code hook を実機でdogfoodする
   - Acceptance: 実際の Claude Code session で `.claude/settings.json` が呼ばれ、ゲーム起動中に自動取り込みで村が育つ
   - Note: CLI sanitization、Git-free inbox-to-village growth、Godot startup import、repo hook command contract、self-test CLI、実 inbox/save status check はテスト済み。Claude Code 本体から hook が発火する確認は未実行。

## P1

1. 成長一時演出の種類と品質を増やす
   - Acceptance: placeholder effects を production pixel art / animation に差し替え、花、灯り、図書館、工房、橋、鐘ごとに視認性を調整する
2. Visual MVP 用 P0 素材を作る
   - Acceptance: `docs/asset_backlog.md` の P0 素材が `assets/production/` に入り、manifest が production path を指す
3. HUD のゲームらしさをさらに改善する
   - Acceptance: Settings と下部掲示札をさらにゲーム内オブジェクト化し、仮UI感を下げる
   - Note: 右上Tool Shelfは文字ボタンからアイコンボタンへ変更済み。住民メッセージは吹き出し化済み。下部2枚は掲示板/日記帳風に分離済み。Settings と下部掲示物にはまだ本番アート不足が残る。

## P2

1. Signed macOS release export
   - Acceptance: release export, code signing, notarization, and Gatekeeper launch check are documented and verified
2. screenshot-reviewer skill で目視レビューを行う
    - Acceptance: 登録後画面と設定パネル表示を含め、コピー感、ダッシュボード感、視認性問題が issue 化される
    - Note: 初期画面、Settings 表示、登録後画面の目視レビューは `docs/visual_mvp_gap.md` に反映済み。将来は production art 適用後に再レビューする。
3. オプトインの commit message 表示を設計する
    - Acceptance: privacy.md の更新と明示 opt-in UI が揃うまで実装しない
4. Ambient desktop mode と healing audio の feasibility
    - Acceptance: mini window、FeedbackController、AudioManager、audio asset gate、native macOS integration の各 issue を順に進める
