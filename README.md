# Code Village

Code Village は「Claude Code を使うと村が育つ」をコンセプトにした、Mac 向けのローカルファーストな 2D トップダウン村育成ゲームです。

Claude Code の利用を、ユーザーが明示的に設定したローカル hook / 手動入力から安全なメタデータとして受け取り、開発作業の痕跡を花、道、灯り、橋、図書館、工房、掲示板、村の日記、住民メッセージとして反映します。Git は任意の補助入力です。

このプロジェクトは非公式です。Claude、Claude Code、Anthropic の公式アプリ、公式ゲーム、公式ブランド素材ではありません。

## MVP 範囲

- Godot 4.x / GDScript の Mac first 2D ゲームとして起動する
- 小さな村のメイン画面を表示する
- 工房、図書館、掲示板、池、木、道、橋、灯り、花、広場を仮素材で描画する
- `ActivityEvent -> GrowthEvent -> VillageState` のモデルを持つ
- 活動に応じて村の成長イベントを発生させる
- ローカル JSON 保存を行う
- Git に関係なく Claude Code activity inbox から安全なイベントを取り込む
- ユーザーが登録したローカル Git リポジトリも任意で安全に読む
- 今日の変化ログ、村の日記、住民メッセージの土台を持つ
- `asset_manifest.json` でダミー素材と将来の本番素材差し替え口を管理する
- 外部送信、テレメトリ、ランキング、生産性スコアを実装しない

## 技術スタック

- Godot 4.x
- GDScript
- macOS first
- Local JSON save (`user://code_village_save.json`)
- 外部通信なし
- 仮素材は Godot の描画 API と `assets/placeholders/` の自作 SVG のみ
- 地形、道、水辺は `TileMapLayer`、主要オブジェクト、花、灯りは manifest-driven `Sprite2D` で配置

## アセット方針

現在の画像・アート素材はすべてダミーです。完成品質のピクセルアートではなく、Functional MVP と差し替え口の検証用です。

- manifest: `assets/asset_manifest.json`
- ダミー素材: `assets/placeholders/`
- 本番素材の配置先: `assets/production/`
- 本番仕様: [docs/asset_spec.md](docs/asset_spec.md)
- 必要素材一覧: [docs/asset_backlog.md](docs/asset_backlog.md)
- 方向性: [docs/visual_direction.md](docs/visual_direction.md)
- Visual MVP の不足点: [docs/visual_mvp_gap.md](docs/visual_mvp_gap.md)

本番素材を追加するときは `assets/production/<category>/` に置き、manifest の該当パスを production 側へ差し替えます。

manifest の参照欠けを確認する場合:

```bash
python3 tools/validate_asset_manifest.py
```

本番素材へ切り替える前の gate として、placeholder 参照が残っていないか確認する場合:

```bash
python3 tools/validate_asset_manifest.py --require-production
```

現在の Functional MVP は placeholder mode のため、`--require-production` は失敗するのが正常です。

## セットアップ

```bash
git clone https://github.com/yoheiuc/code-village.git
cd code-village
godot --version
```

Godot が無い場合:

```bash
brew install --cask godot
```

## 起動方法

```bash
godot --path .
```

headless で構文/起動確認する場合:

```bash
godot --headless --path . --quit-after 1
godot --headless --path . --script res://tests/run_unit_tests.gd
python3 tools/validate_asset_manifest.py
python3 -m unittest tests/test_code_village_event.py tests/test_asset_manifest_tool.py
```

MVPスクリーンショットを一括更新する場合:

```bash
python3 tools/capture_mvp_screenshots.py
```

このコマンドは一時保存データだけを使い、`artifacts/screenshots/` の Functional MVP 証跡を再生成します。

任意のローカル Git repo path は Settings から登録できます。Settings から登録 repo の削除とローカル保存データ削除もできます。初回ガイドは、Claude Code が主入力で Git は任意であること、Local only / No sync、prompt / response / source / diff / secrets を読まないことを短く表示します。`Start Village` で非表示にできます。

## Claude Code 連携

MVP の主入力はローカルの Claude Code activity inbox です。外部送信はありません。

手動で Claude Code 使用イベントを記録する例:

```bash
tools/code_village_event.py --project-label code-village
```

Claude Code hook から stdin JSON を渡す例:

```bash
tools/code_village_event.py --stdin-json
```

既定の保存先:

```bash
tools/code_village_event.py --print-path
```

この repo には `.claude/settings.json` があり、Claude Code の `SessionStart` と `Stop` hook から同じ CLI を呼ぶ最小構成を入れています。Godot 側は起動時と約 10 秒ごとに inbox を自動取り込みします。自動取り込みは Settings の `Auto import local Claude events` で切り替えできます。手動で確認する場合は `Import Claude Events` を押してください。

他ディレクトリでも使う場合は `~/.claude/settings.json` に同じ hook を、clone した Code Village の絶対パスで設定します。最短の手順は [docs/claude_code_hook_setup.md](docs/claude_code_hook_setup.md) の「最短セットアップ」を参照してください。

repo-local hook 設定、temporary inbox、Godot 取り込み、privacy sanitizer をまとめて確認する場合:

```bash
python3 tools/claude_hook_self_test.py
```

この self-test は一時ファイルだけを使い、実ユーザー保存や実 inbox を変更しません。Claude Code 本体の hook 発火そのものは、実際の Claude Code session で別途 dogfood してください。

実 dogfood 前後に、repo-local hook 設定、実 inbox、実 save の状態を安全に確認する場合:

```bash
python3 tools/claude_hook_status.py
python3 tools/claude_hook_status.py --require-events
```

この status check は許可されたメタデータだけを集計し、prompt、response、raw path、raw session id の値は表示しません。`--require-events` は実 Claude Code session 後に inbox event が存在するかを exit code で確認するためのコマンドです。

保存されるのはイベント種別、時刻、raw path を basename に丸めた短い project label、hook event 名、ハッシュ化された session id だけです。prompt、response、source body、diff、認証情報は保存しません。

`tests/test_code_village_event.py` は一時 inbox と一時 save path を使い、Godot 起動時に Claude Code event が Git なしで村状態へ反映されることを確認します。検証用の保存先上書きには `CODE_VILLAGE_SAVE_PATH` を使います。

詳細は [docs/claude_code_hook_setup.md](docs/claude_code_hook_setup.md) を参照してください。

## プライバシー方針

MVP はローカル専用です。外部送信、分析、クラッシュレポート、テレメトリはありません。

読むデータ:

- Claude Code hook / 手動コマンドが明示的に書いたローカル activity inbox
- Claude Code event type
- event timestamp
- project label
- hook event name
- hash化された session id
- ユーザーが明示的に登録したローカル Git リポジトリのパス
- 現在ブランチ名
- 直近 24 時間のコミット数とコミット日時相当の集計
- 変更ファイル数
- ファイル拡張子の概要
- タグ数
- ブランチ変更の有無
- ユーザーが手動入力した短い作業メモ

読まないデータ:

- ソースコード本文
- `git diff` の中身
- `.env` や秘密情報ファイルの中身
- API キー、認証情報
- 外部サービスの Issue / PR 本文
- Claude Code の非公開ログや非公開 API
- Claude Code の prompt / response 本文
- Claude / Anthropic の認証情報
- コミットメッセージ

コミットメッセージとファイル名保存は初期状態では無効です。MVP の実装はファイル名を保存せず、拡張子集計だけを保存します。

## ロードマップ

1. Phase 0: リポジトリ整理と設計文書
2. Phase 1: 最小村画面
3. Phase 2: 保存
4. Phase 3: Claude Code activity inbox と任意 Git スキャン
5. Phase 4: 成長イベント
6. Phase 5: 日記と住民メッセージ
7. Phase 6: Mac アプリ化
8. Phase 7: 小さな買い切りゲームとしての配布準備

詳細は [docs/development_plan.md](docs/development_plan.md) と [docs/issues.md](docs/issues.md) を参照してください。
今やること、後でやること、やらないことの判断基準は [docs/development_scope.md](docs/development_scope.md) に整理しています。

変更履歴とリリース準備状況は [CHANGELOG.md](CHANGELOG.md) に記録します。現時点は Functional MVP であり、本番アート、署名、notarization、実 Claude Code session dogfood は未完了です。

## macOS Export

署名なし debug export は生成確認済みです。

```bash
python3 tools/verify_macos_export.py
```

詳細は [docs/macos_export.md](docs/macos_export.md) を参照してください。配布前には本番アイコン、release export、code signing、notarization が必要です。
