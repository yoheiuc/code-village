# Changelog

このファイルは Code Village の主要な変更とリリース準備状況を記録する。

Code Village は非公式のローカルファーストな開発者向けアンビエントゲームであり、Claude、Claude Code、Anthropic の公式プロダクトではない。

## Unreleased

### Added

- Godot 4.x / GDScript の Mac 向け 2D top-down Functional MVP。
- Claude Code activity inbox を主入力にした Git-free growth loop。
- repo-local `.claude/settings.json` と `tools/code_village_event.py` による privacy-safe hook command。
- `ActivityEvent -> GrowthEvent -> VillageState` のモデルと `GrowthRuleEngine`。
- 工房、図書館、掲示板、水辺、道、橋、灯り、花、広場、住民の placeholder village。
- `assets/asset_manifest.json`、`assets/placeholders/`、`assets/production/` による素材差し替え口。
- manifest-driven `TileMapLayer` terrain と `Sprite2D` object/growth/effect layer。
- resident A/B の placeholder walk frames、左右反転、GrowthEvent route reaction。
- rest-day `pond_friend` placeholder visitor and no-new-event rest message.
- first-run `Start Village` onboarding event that decorates the plaza without pretending to be coding activity.
- 今日の変化、村の日記、住民メッセージ、初回ガイド、Workshop Settings。
- ローカル JSON save、save 削除 UI、空/破損 save の安全フォールバック。
- Claude Code auto import toggle と manual import。
- 任意のローカル Git metadata scan。Git は補助入力であり必須ではない。
- Git scanner の empty repo / detached HEAD / worktree 対応。
- 署名なし macOS debug export preset。
- MVP screenshot capture tool、asset manifest validator、Claude hook self-test/status tools、macOS debug export verifier。
- repo-scoped Codex skills under `.agents/skills/`。

### Privacy

- 外部送信、telemetry、analytics、crash reporting は未実装。
- Claude Code prompt / response / private log / raw session id は読まない。
- source body、`git diff`、secret file body、credentials、commit message は読まない。
- file names は保存せず、拡張子集計だけを扱う。
- 実ユーザー save / inbox を触らない検証用に `CODE_VILLAGE_SAVE_PATH` と `CODE_VILLAGE_ACTIVITY_INBOX` を用意。

### Verification

- `godot --headless --path . --quit-after 1`
- `godot --headless --path . --script res://tests/run_unit_tests.gd`
- `python3 -m unittest tests/test_code_village_event.py tests/test_asset_manifest_tool.py tests/test_claude_hook_status.py`
- `python3 tools/validate_asset_manifest.py`
- `python3 tools/claude_hook_status.py`
- `python3 tools/capture_mvp_screenshots.py`
- `python3 tools/verify_macos_export.py`

### Known Gaps

- Current visuals are dummy placeholder assets, not production art.
- Visual MVP is not complete; production assets must be added under `assets/production/` and wired through `assets/asset_manifest.json`.
- macOS release signing, notarization, Gatekeeper verification, and production icon are not complete.
- Actual Claude Code app/session hook dogfood is not complete; local CLI, hook command contract, self-test, status checks, and Godot import are tested.
- Godot Editor GUI manual inspection is not complete. Editor load smoke passes, but usable GUI screenshot evidence has not been captured in this environment.

## Release Notes Policy

- Add a new dated section before any tagged release.
- Do not describe placeholder art as final art.
- Do not imply official Claude / Anthropic affiliation.
- Note privacy-impacting changes explicitly.
- Keep external publish, store submission, signing credentials, and notarization steps out of automation unless explicitly approved.
