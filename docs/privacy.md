# Privacy

## 基本方針

Code Village はローカルファーストなアンビエントゲームであり、生産性監視ツールではない。MVP では外部送信、テレメトリ、クラッシュレポート、分析を実装しない。

## 読むデータ

- Claude Code hook / 手動コマンドが明示的に書いたローカル activity inbox
- `.claude/settings.json` の repo-local hook が書いた activity inbox
- Claude Code activity event type
- event timestamp
- raw path を basename に丸めた短い project label
- hook event name
- hash化された session id
- ユーザーが明示的に登録したローカル Git リポジトリのパス
- 現在ブランチ名
- 直近 24 時間のコミット数
- コミットハッシュの件数集計
- 変更ファイル数
- ファイル拡張子の概要
- タグ数
- ブランチ変更の有無
- ユーザーが手動入力した短い作業メモ

## 読まないデータ

- ソースコード本文
- `git diff`
- `.env` の中身
- 秘密情報ファイルの中身
- API キー
- 認証情報
- 外部サービスの Issue / PR 本文
- Claude Code の非公開ログや非公開 API
- Claude Code の prompt / response 本文
- Claude Code の raw session id
- Claude / Anthropic の認証情報
- コミットメッセージ
- clipboard
- window title
- screen contents
- keyboard input
- microphone input
- system audio

## 保存するデータ

- Claude Code activity event id
- Claude Code project label。raw path は basename に丸める
- Claude Code hook event name
- Claude Code session hash
- repo path と表示名
- repo enabled flag
- last scanned time
- branch 名
- commit count
- changed file count
- extension summary
- tag count
- ActivityEvent
- GrowthEvent
- VillageState
- diary entries
- resident messages
- user settings
- Claude Code auto import setting

repo path は個人情報になり得る。設定画面とこの文書で説明し、削除できるようにする。

初回ガイドと Settings では、Claude Code のローカルイベントが主入力で Git は任意であること、Local only / No sync、prompt / response / source / diff / secrets を読まないことを画面上でも明示する。

## 保存しないデータ

- ソース本文
- diff
- commit message
- file name
- file path list
- secret file body
- credentials
- raw session id
- prompt / response

MVP 実装では `store_commit_messages=false`, `store_file_names=false`, `enable_external_network=false`, `auto_import_claude_events=true` を既定値にする。auto import はローカル inbox の読み取りのみで、外部送信ではない。Settings の `Auto import local Claude events` で off にすると、起動時と定期タイマーの自動取り込みを止める。手動 import は残す。

`tests/test_code_village_event.py` は `.claude/settings.json` の hook command 文字列を一時 inbox で実行し、prompt / response / raw path / raw session id が保存されないことを検証する。auto import off の保存データでは、起動時に inbox event が取り込まれないことも検証する。

## 外部送信

MVP では外部送信しない。外部ネットワーク API、クラッシュレポート、分析 SDK、テレメトリ SDK を入れない。

## 削除方法

Settings の `Delete Local Save` から、Godot の user data に保存される `code_village_save.json` を削除できる。

Settings の `Remove Current Repo` から、保存データ内の登録 repo path を削除できる。

Claude Code activity inbox 自体は `tools/code_village_event.py --print-path` で場所を確認し、必要ならその JSONL ファイルを削除できる。

repo-local hook を止めたい場合は `.claude/settings.json` の hooks を削除またはリネームする。

## 常駐モードと音のプライバシー

将来の ambient desktop mode や BGM / SE は、読み取り対象を増やさない。小型常駐ウィンドウ、menu bar / Dock 連携、background audio を追加する場合でも、Claude Code activity inbox と明示登録された Git metadata の境界を維持する。

初期 audio 実装では bundled asset だけを使う。ユーザー任意の音源 path は個人情報になり得るため、扱う場合は別途 opt-in、削除導線、privacy docs 更新が必要。

Accessibility、Screen Recording、Input Monitoring、Microphone 権限は要求しない。必要になった場合は、実装前に目的、読むデータ、保存するデータ、削除方法、off にする方法をこの文書と Settings に追加する。

## リスクと対策

- repo path は個人情報になり得る
  - 対策: ローカル保存のみ。外部送信なし。登録 repo の削除導線を用意する。
- ファイル名には機密名が含まれ得る
  - 対策: 保存しない。拡張子集計だけ保存する。
- コミットメッセージに秘密が含まれ得る
  - 対策: 初期状態では読まず保存しない。将来も明示オプトインのみ。
- Git コマンド失敗でゲーム体験を壊す
  - 対策: scanner は失敗を結果オブジェクトに入れ、ゲームを落とさない。
- 常駐モードで画面共有中に project label などが見える
  - 対策: raw path を出さない。mini window は短い村の状態だけを出し、作業内容本文を表示しない。
- 音の実装で権限や path 保存が増える
  - 対策: 初期は bundled asset のみ。microphone / system audio capture は使わない。background audio は opt-in。
