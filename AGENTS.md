# AGENTS.md

Code Village は Godot 4.x / GDScript の Mac 向けローカルファーストゲームです。回答は日本語で簡潔にし、実装後は実コマンドで検証してから完了報告する。

## 作業開始時

1. `README.md` を読む。
2. 関連する `docs/*.md` と `CHANGELOG.md` を読む。
3. 使う repo-scoped skill があれば `.agents/skills/<name>/SKILL.md` を読む。

## リポジトリ構成

- `project.godot`: Godot プロジェクト定義
- `scenes/`: Godot シーン
- `scripts/`: GDScript 実装
- `assets/placeholders/`: 自作プレースホルダー素材
- `assets/production/`: 後工程で作る本番素材の配置先
- `assets/asset_manifest.json`: 素材パスと placeholder palette
- `data/`: 将来の初期データ置き場
- `docs/`: 仕様、設計、プライバシー、アート、計画
- `tests/`: Godot headless テスト
- `tools/`: Claude Code activity inbox へ安全なメタデータを書き込むローカルCLI
- `.claude/settings.json`: Claude Code hook からローカル CLI を呼ぶ repo-local 設定
- `.agents/skills/`: この repo 専用の Codex skill

## 実行方法

```bash
godot --path .
```

## テスト方法

```bash
godot --headless --path . --quit-after 1
godot --headless --path . --script res://tests/run_unit_tests.gd
python3 tools/validate_asset_manifest.py
python3 tools/claude_hook_status.py
python3 -m unittest tests/test_code_village_event.py tests/test_asset_manifest_tool.py tests/test_claude_hook_status.py tests/test_macos_export_tool.py
python3 "$HOME/.codex/skills/.system/skill-creator/scripts/quick_validate.py" .agents/skills/<skill-name>
git diff --check
```

macOS debug export を確認する場合:

```bash
python3 tools/verify_macos_export.py
```

## 完了条件

- Godot が起動または headless でロードできる
- 関連テストまたは実行チェックを通す
- docs と実装のプライバシー方針が矛盾しない
- 未実行の検証は未実行と明記する

## 禁止事項

- 既存ゲームの素材、UI、キャラ、マップ、配色、建物をコピーしない
- Stardew Valley 風の具体的な見た目に寄せない
- Claude / Anthropic のロゴ、公式 UI、ブランド要素を使わない
- 外部送信、テレメトリ、クラッシュレポートを実装しない
- 生産性スコア、ランキング、時給換算、作業量評価を作らない
- 休んだ日を責める表現を入れない
- 深夜作業を過度に褒めない
- `git diff`、ソースコード本文、秘密情報ファイル本文を読む処理を入れない
- Claude Code の prompt / response / private log / token / 認証情報を読む処理を入れない
- コミットメッセージ保存を初期状態で有効化しない

## セキュリティ原則

- 主入力はユーザーが明示的に作成する Claude Code activity inbox。Git repo は任意の補助入力。
- Claude Code inbox は allowlist されたメタデータだけを読む。
- Claude Code inbox は起動時と定期タイマーで自動取り込みする。手動 import も残す。
- Git の読み取り対象はユーザーが登録したローカル Git repo のみ。
- Git コマンドは shell 文字列ではなく引数配列で実行する。
- 保存するのは集計済みメタデータ、成長イベント、村状態、設定のみ。
- repo path は個人情報になり得るため、設定と `docs/privacy.md` で説明する。
- `enable_external_network` は存在しても MVP では常に false として扱う。

## アート方針

- 初期実装の画像・アート素材はすべてダミーとして扱い、完成扱いしない。
- Codex は完成品質の画像生成や本番ピクセルアート制作を担当しない。
- 仮素材は自作の単純図形または `assets/placeholders/` の自作 SVG のみ。
- 本番素材は `assets/production/` に置き、`assets/asset_manifest.json` の参照を差し替える。
- 色、素材パス、growth visual path は可能な範囲で manifest に寄せる。
- かわいさよりも、静かで温かい「開発作業の記憶が残る村」を優先する。
