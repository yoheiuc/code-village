# AGENTS.md

Code Village は Godot 4.x / GDScript の Mac 向けローカルファーストゲームです。回答は日本語で簡潔にし、実装後は実コマンドで検証してから完了報告する。

## 作業開始時

1. `README.md` を読む。
2. 関連する `docs/*.md` と `CHANGELOG.md` を読む。
3. 使う repo-scoped skill があれば `.agents/skills/<name>/SKILL.md` を読む。

## サブエージェント運用

通常の開発、設計、QA、polish ではサブエージェントを使う。小さな typo 修正や単一コマンド確認を除き、最低 1 role を明示して並行レビューまたは作業分担する。

6 役割の責務と handoff は `docs/agent_operating_model.md` を正本にする。

- Game Architect Agent: 全体設計、状態管理、save、拡張性、privacy boundary
- Gameplay Agent: playable loop、ActivityEvent / GrowthEvent / VillageState、成長ルール
- UI/UX Agent: HUD、Settings、初回導線、メニュー、操作性
- Asset Pipeline Agent: placeholder / production 分離、manifest、素材仕様、差し替え口
- QA/Test Agent: tests、起動確認、save破損、privacy regression、debug/release gate
- Polish Agent: 画面のしょぼさ改善、animation、SFX差し込み、余白、色、演出

実装を分担する場合は、担当ファイルを明確に分け、他 agent の変更を巻き戻さない。

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
python3 tools/dev_debug.py --fast
godot --headless --path . --quit-after 1
godot --headless --path . --script res://tests/run_unit_tests.gd
python3 tools/validate_asset_manifest.py
python3 tools/claude_hook_status.py
python3 -m unittest tests/test_code_village_event.py tests/test_asset_manifest_tool.py tests/test_claude_hook_status.py tests/test_macos_export_tool.py tests/test_dev_debug_tool.py
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
- 商品判断は `docs/product_milestones.md` の Free-use / Paid-use threshold と矛盾しない
- 未実行の検証は未実行と明記する

## 禁止事項

- 既存ゲームの素材、UI、キャラ、マップ、配色、建物をコピーしない
- Stardew Valley 風の具体的な見た目に寄せない
- Animal Crossing / どうぶつの森は「安心感、日課感、生きた村」の参考に留め、キャラ、UI、住民構造、会話口癖、素材、配色、マップ構成をコピーしない
- Claude / Anthropic のロゴ、公式 UI、ブランド要素を使わない
- Claude / Anthropic 公式体験や既存ゲームを想起させる BGM / SE を使わない
- 外部送信、テレメトリ、クラッシュレポートを実装しない
- 生産性スコア、ランキング、時給換算、作業量評価を作らない
- 休んだ日を責める表現を入れない
- 深夜作業を過度に褒めない
- `git diff`、ソースコード本文、秘密情報ファイル本文を読む処理を入れない
- Claude Code の prompt / response / private log / token / 認証情報を読む処理を入れない
- コミットメッセージ保存を初期状態で有効化しない
- 明示 opt-in なしで launch at login、常時表示、background audio を有効化しない

## セキュリティ原則

- 主入力はユーザーが明示的に作成する Claude Code activity inbox。Git repo は任意の補助入力。
- Claude Code inbox は allowlist されたメタデータだけを読む。
- Claude Code inbox は起動時と定期タイマーで自動取り込みする。手動 import も残す。
- Git の読み取り対象はユーザーが登録したローカル Git repo のみ。
- Git コマンドは shell 文字列ではなく引数配列で実行する。
- 保存するのは集計済みメタデータ、成長イベント、村状態、設定のみ。
- repo path は個人情報になり得るため、設定と `docs/privacy.md` で説明する。
- `enable_external_network` は存在しても MVP では常に false として扱う。
- 常駐モードや音を追加しても、clipboard、window title、screen、keyboard、microphone、system audio を読まない。

## アート方針

- 初期実装の画像・アート素材はすべてダミーとして扱い、完成扱いしない。
- Codex は完成品質の画像生成や本番ピクセルアート制作を担当しない。
- 仮素材は自作の単純図形または `assets/placeholders/` の自作 SVG のみ。
- 本番素材は `assets/production/` に置き、`assets/asset_manifest.json` の参照を差し替える。
- 色、素材パス、growth visual path は可能な範囲で manifest に寄せる。
- かわいさよりも、静かで温かい「開発作業の記憶が残る村」を優先する。
- 生き物は作業量を評価するマスコットではなく、灯り、図書館、水辺、道端にいる小さな同居者として扱う。

## 音の方針

- BGM / SE / ambient sound は `docs/audio_spec.md` を正本にする。
- Codex は完成品質の音楽制作を担当しない。
- 音源は local bundled asset を前提にし、外部 streaming、microphone、system audio capture を使わない。
- mute、volume、play / pause、background audio opt-in を実装前の必須条件にする。
