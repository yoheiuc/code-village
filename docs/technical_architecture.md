# Technical Architecture

## 方針

- Godot 4.x / GDScript
- macOS first
- Local JSON save
- 外部通信なし
- 主入力は Claude Code activity inbox
- Git 読み取りは任意で、ユーザー登録済み repo path に限定
- モデル、ルール、描画、HUD、保存、Claude inbox、Git スキャンを分離する

## シーン構成

- `scenes/main.tscn`: root `Node2D`, script `scripts/main.gd`
- `scenes/village.tscn`: root `Node2D`, script `scripts/village/village_view.gd`
- `scenes/ui/main_hud.tscn`: root `CanvasLayer`, script `scripts/ui/main_hud.gd`

## スクリプト構成

- `scripts/main.gd`: アプリ全体の調停
- `scripts/assets/asset_catalog.gd`: `asset_manifest.json` loader
- `scripts/activity/activity_event.gd`: ActivityEvent model
- `scripts/activity/claude_code_activity_ingestor.gd`: Claude Code activity inbox reader
- `scripts/activity/git_activity_scanner.gd`: Git metadata scanner
- `scripts/village/growth_event.gd`: GrowthEvent model
- `scripts/village/growth_rule_engine.gd`: ActivityEvent -> GrowthEvent
- `scripts/village/village_state.gd`: VillageState model
- `scripts/village/village_view.gd`: placeholder drawing
- `scripts/village/village_tile_layer.gd`: procedural TileMapLayer terrain/path/water layer
- `scripts/village/village_sprite_layer.gd`: manifest-driven Sprite2D object layer
- `scripts/save/save_manager.gd`: local JSON save
- `scripts/ui/main_hud.gd`: HUD and input
- `scripts/dialogue/resident_message_provider.gd`: resident messages
- `scripts/config/repository_config.gd`: RepositoryConfig model
- `scripts/config/user_settings.gd`: UserSettings model

将来追加する候補:

- `scripts/feedback/feedback_controller.gd`: `GrowthEvent` から visual reaction / companion reaction / SE cue を生成
- `scripts/ambient/ambient_mode_controller.gd`: main window と mini window の状態、pause、quit、mute を管理
- `scripts/audio/audio_manager.gd`: BGM / SFX / Ambient bus、volume、mute、fade、rate limit を管理

## アセット参照設計

素材参照は `assets/asset_manifest.json` にまとめる。MVP の `mode` は `placeholder`。

- `assets/placeholders/`: Functional MVP 用のダミー素材
- `assets/production/`: 本番素材の配置先
- `tiles`, `buildings`, `environment`, `characters`, `ui`: カテゴリ別素材パス
- `growth_visuals`: Activity / Growth に紐づく見た目の入口
- `sprite_layout`: Sprite2D placeholder / production object placement
- `state_visual_rules`: `VillageState` 値に応じて出す成長状態オーバーレイ
- `growth_effect_anchors`: `GrowthEvent` 発生時に短く出す一時演出の位置、scale、z-index、任意の effect path
- `placeholder_colors`: `_draw()` fallback 用 palette

`AssetCatalog` は manifest を読み、素材パス、growth visual path、sprite layout、state visual rules、placeholder color、reference resolution を返す。現在の `VillageView` は地形、道、水辺を `VillageTileLayer` の `TileMapLayer` で置く。工房、図書館、掲示板、橋、鐘、Branch Tree、住民、木、広場、花、灯り、状態差分オーバーレイは `VillageSpriteLayer` が manifest 経由の `Sprite2D` として置く。`VillageView._draw()` は素材欠落時の fallback を主目的に残す。

`GrowthEvent` 発生時は `Main` が状態更新後に `VillageView.show_growth_events()` を deferred call し、`VillageSpriteLayer` が最大 3 件の短い Sprite2D エフェクトを重ねる。通常の成長状態は `VillageState` に保存し、一時演出は保存しない。演出素材は `growth_effect_anchors` の `path` を優先し、未指定時は default anchor の `path`、それも無ければ `growth_visuals` に戻す。

`VillageSpriteLayer` の texture load は `ResourceLoader` を優先し、Godot export 後は import 済み `Texture2D` を読む。editor / 開発中に `.import` が未生成の SVG だけ、raw SVG を `Image.load_svg_from_buffer()` で読む fallback にする。

## Ambient Desktop / Audio 設計

常駐表示と音は MVP では実装しない。将来は `GrowthEvent` の後段に adapter を追加し、既存の `ActivityEvent -> GrowthEvent -> VillageState` を変えずに反応だけを差し込む。

想定構成:

- `FeedbackController` が `GrowthEvent` を受け、visual reaction、companion reaction、SE cue を作る。
- `AmbientModeController` は main window / ambient mini window の表示状態を管理する。
- true menu bar extra は Godot 単体で決め打ちせず、Swift / AppKit helper または native plugin の feasibility を issue で検証する。
- `AudioManager` は Godot Audio bus を使い、`Master`, `BGM`, `SFX`, `Ambient` を分ける。
- 将来の `assets/audio_manifest.json` は audio path、bus、loop、default volume、license、source、originality review status を持つ。

制約:

- 常駐表示のために読み取り対象を増やさない。
- clipboard、window title、screen、keyboard、microphone、system audio、Claude private log は読まない。
- Launch at login、常時表示、background audio は明示 opt-in。
- inbox が肥大化しても再取り込みや重複成長を起こさないよう、checkpoint / compaction を実装前に設計する。
- scene reload、sleep / wake、window reopen 後に timer や BGM が二重化しないことをテストする。

## データモデル

### ActivityEvent

- `id`
- `type`
- `occurred_at`
- `source`
- `repository_id`
- `metadata`
- `privacy_level`

### GrowthEvent

- `id`
- `type`
- `occurred_at`
- `activity_event_id`
- `title`
- `description`
- `visual_target`
- `intensity`

### VillageState

- `village_level`
- `flowers`
- `lanterns`
- `repaired_paths`
- `bridge_state`
- `library_level`
- `workshop_level`
- `branch_tree_level`
- `release_bell_rings`
- `diary_entries`
- `resident_messages`
- `last_updated_at`

### RepositoryConfig

- `id`
- `display_name`
- `local_path`
- `enabled`
- `created_at`
- `last_scanned_at`
- `privacy_mode`

### UserSettings

- `local_only`
- `store_commit_messages`
- `store_file_names`
- `enable_external_network`
- `show_rest_day_messages`
- `auto_import_claude_events`

## 保存設計

保存先は `user://code_village_save.json`。JSON は `schema_version`, `settings`, `repositories`, `onboarding_guide_dismissed`, `imported_activity_event_ids`, `village_state`, `activity_events`, `growth_events` を持つ。`settings.auto_import_claude_events` は true 既定で、ローカル inbox の起動時/定期取り込みだけを制御する。Settings の toggle から変更し、手動 import はこの設定が off でも使える。

検証や dogfood で実ユーザー保存を触らないため、`CODE_VILLAGE_SAVE_PATH` が指定されている場合だけ `SaveManager` は保存先をそのローカルパスへ上書きする。

保存ファイルが空、壊れた JSON、または JSON object 以外の場合は、ゲームを落とさず既定の保存データへ戻す。`SaveManager.last_load_warning` にローカル警告だけを残し、起動時 HUD には `Local save recovered. Using safe defaults.` と表示する。source body、diff、secret file body は読まない。

`SaveManager.delete_save()` はこのファイルを削除し、ゲーム内 Settings の `Delete Local Save` から呼び出す。テストでは `save_path` を一時ファイルへ差し替え、実ユーザー保存を消さない。

保存対象から除外するもの:

- Claude Code prompt / response
- Claude Code private log
- raw session id
- ソース本文
- diff
- コミットメッセージ
- ファイル名
- 秘密情報ファイル本文
- 外部サービス本文

## Claude Code Activity Inbox 設計

Claude Code hook や手動コマンドは `tools/code_village_event.py` を呼び、ローカル JSONL inbox にイベントを書く。

既定の inbox:

- `~/Library/Application Support/Code Village/activity_inbox/claude_code_events.jsonl`

環境変数 `CODE_VILLAGE_ACTIVITY_INBOX` で上書きできる。

保存する metadata:

- `type`
- `occurred_at`
- `project_label`。raw path が入った場合は basename に丸める
- `hook_event`
- `session_hash`

保存しないもの:

- prompt
- response
- source body
- diff
- raw path
- raw session id
- token / credential

この repo の `.claude/settings.json` は `SessionStart` と `Stop` hook から `tools/code_village_event.py` を呼ぶ。hook command は外部送信せず、失敗しても Claude Code の作業を止めないようにする。

Godot 側は `ClaudeCodeActivityIngestor` が未取り込み event id だけを読み、`ActivityEvent` に変換する。起動時と約 10 秒ごとに自動取り込みし、手動 `Import Claude Events` も残す。

`tests/run_unit_tests.gd` は Git repo id が空の Claude Code inbox event から `GrowthRuleEngine` を通して `VillageState` の工房と花が増えることを検証する。`tests/test_code_village_event.py` は一時 inbox / 一時 save path で Godot 起動時の自動取り込みも確認する。auto import off では起動時に取り込まないことも確認する。これは Claude Code usage が主入力で、Git は任意である境界を固定するためのテスト。

## Optional Git スキャン設計

Godot から `OS.execute()` を使い、shell を経由せず引数配列で `git` を実行する。

使うコマンド:

- `git -C <path> rev-parse --abbrev-ref HEAD`
- `git -C <path> symbolic-ref --short HEAD` (empty repo fallback)
- `git -C <path> log --since=24 hours ago --pretty=format:%H`
- `git -C <path> log --since=24 hours ago --name-only --pretty=format:`
- `git -C <path> tag --list`

制約:

- 登録済み repo path だけを読む
- `git diff` は実行しない
- source body は読まない
- commit message は読まない
- file names は保存せず、拡張子集計と変更ファイル数だけ保存する
- 前回 scan と commit count / changed file count / extension summary が同じ場合は growth event を出さない
- 空 repo の no-commit 状態はエラー扱いせず、イベントなしで返す
- コマンド失敗時にゲームを落とさない

## GrowthRuleEngine 設計

`ActivityEvent` を受け取り、活動種別ごとのルールで `GrowthEvent` を生成する。コミット数の多さを過剰に報酬化しないため、intensity は小さく丸める。

初期ルール:

- Claude Code session: workshop
- Claude Code turn: flower
- commit: flower
- tests: lantern
- docs: library
- refactor: path
- bugfix: bridge
- release tag: bell
- branch: branch tree
- manual session: resident message
- manual reflection: diary

## セキュリティ境界

- scanner は `GitActivityScanner` に閉じ込める
- 保存は `SaveManager` に閉じ込める
- network API は実装しない
- settings に `enable_external_network` があっても MVP では false 固定で扱う
- audio playback は microphone 権限を要求しない
- custom audio path は raw path 保存リスクがあるため、初期 audio 実装では bundled asset のみにする
