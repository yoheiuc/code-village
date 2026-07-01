# Product Spec

## 概要

Code Village は、Claude Code を使ったローカル開発の小さな積み重ねが村の景色として残るアンビエントゲーム。プレイヤーは Claude Code activity inbox を使って安全なメタデータだけをローカルに記録し、ゲームはそれを村の成長に変換する。Git は任意の補助入力に留める。

これは生産性監視ツールではない。休んだ日を責めず、作業量を比較せず、プレイヤーのペースを尊重する。

## コンセプト

「Claude Code を使うと村が育つ」

Claude Code そのものを監視したり、非公開ログや認証情報を読んだりしない。MVP では、プレイヤーが明示的に設定したローカル hook / 手動コマンドが書く安全な Claude Code activity metadata を使い、Git に関係なく開発作業の記憶を村に反映する。

## コアループ

1. Claude Code hook または手動コマンドがローカル activity inbox に安全なイベントを書く
2. ゲームが inbox から未取り込みの安全なメタデータだけを読む
3. `ActivityEvent` に正規化する
4. `GrowthRuleEngine` が `GrowthEvent` へ変換する
5. `VillageState` が更新される
6. 村画面に小さな変化が出る
7. 住民や小さな生き物が短いメッセージや気配を残す
8. 村の日記に今日の変化が記録される

任意でローカル Git repo を登録すると、commit / docs / tag などの安全な集計も補助イベントとして取り込む。

## 生き物と癒し

Code Village には、作業の記憶に寄ってくる小さな生き物たちがいる。彼らは作業量を評価せず、村にいる気配、休息、見守り、静かな生活感を作る。

Animal Crossing のような安心感や日課感は感情面の参考にするが、キャラクター、UI、会話、配色、素材、住民システムはコピーしない。詳細は `docs/creature_companions.md`。

## Ambient Desktop Presence

将来は、通常の村 window とは別に、小型の ambient mini window や native macOS menu bar / Dock 連携を検討する。普段は小さな灯り、生き物、村の一部だけが静かに動き、Claude Code event が届いたときだけ短く反応する。

この機能は MVP には含めない。まずは Godot-only の mini window spike を行い、真の menu bar extra は Swift / AppKit helper や native plugin の実現性を検証してから判断する。詳細は `docs/ambient_desktop_mode.md`。

## Healing Audio

将来の BGM / SE は、作業量を褒める報酬音ではなく、村を開いたままにできる低刺激の healing audio として設計する。初回起動で勝手に鳴らさず、mute、volume、play / pause、background audio opt-in を必須にする。

音源は local bundled asset のみとし、外部 streaming、microphone、system audio capture は使わない。詳細は `docs/audio_spec.md`。

## 画面一覧

- 起動画面: Code Village のタイトルとローカル専用の説明
- 初回説明画面: 小さな上部ガイドで、Claude Code のローカルイベントが村になること、Git は任意であることを説明。非表示状態はローカル保存する
- プライバシー説明画面: 初回ガイドと Settings で、Local only / No sync、prompt / response / source / diff / secrets を読まないことを明示
- Claude Code activity import: ローカル inbox から Claude Code usage event を取り込む
- リポジトリ登録画面: Settings 内で任意のローカル Git repo path を登録
- 村メイン画面: 工房、図書館、掲示板、池、道、橋、灯り、花、木、広場
- 今日の変化パネル: 今日発生した GrowthEvent
- 村の日記: 保存された diary entries
- 設定画面: local only、commit message 保存無効、file name 保存無効、外部通信無効、Claude Code auto import のON/OFFを表示

## MVP スコープ

- Godot 4.x で起動する
- プレースホルダー村を描画する。これは Visual MVP 完成ではなく、Functional MVP として扱う
- `asset_manifest.json` でダミー素材と本番素材差し替え口を管理する
- Claude Code activity inbox の土台を持つ
- Git メタデータも任意で安全に集計する
- `ActivityEvent`, `GrowthEvent`, `VillageState` を実装する
- 初期変換ルールを実装する
- ローカル JSON 保存を実装する
- 今日の変化ログ、日記、住民メッセージを表示する
- 外部通信なし

## ActivityEvent 候補

- `commit_created`
- `claude_code_session`
- `claude_code_turn_completed`
- `tests_passed`
- `docs_updated`
- `refactor_detected`
- `bugfix_detected`
- `release_tag_created`
- `branch_created`
- `project_added`
- `manual_coding_session`
- `manual_reflection_added`

## GrowthEvent 候補

- `flower_bloomed`
- `path_repaired`
- `lantern_lit`
- `bridge_repaired`
- `library_expanded`
- `workshop_upgraded`
- `branch_tree_grew`
- `issue_board_updated`
- `resident_message_added`
- `diary_entry_created`
- `plaza_decorated`
- `bell_rang`

## 初期変換ルール

- `commit_created -> flower_bloomed`
- `claude_code_session -> workshop_upgraded`
- `claude_code_turn_completed -> flower_bloomed`
- `tests_passed -> lantern_lit`
- `docs_updated -> library_expanded`
- `refactor_detected -> path_repaired`
- `bugfix_detected -> bridge_repaired`
- `release_tag_created -> bell_rang`
- `branch_created -> branch_tree_grew`
- `manual_coding_session -> resident_message_added`
- `manual_reflection_added -> diary_entry_created`

## 将来機能

- ファイル拡張子別の村オブジェクト演出
- repo ごとの村区画
- Mac app export と notarization
- オプトインのコミットメッセージ表示
- 手動テスト成功入力の改善
- 季節/天気/休息日メッセージ
- 小さな生き物の habitat、idle animation、静かな visitor
- 買い切りゲーム向けの小さなチュートリアル
- 小型常駐ウィンドウと event reaction
- native macOS menu bar / Dock integration の feasibility
- BGM / SE / ambient sound と audio settings

## Visual MVP の扱い

今回の初期実装では完成品質の画像・ピクセルアートを作らない。Visual MVP の成功条件と不足点は `docs/visual_mvp_gap.md`、必要素材は `docs/asset_backlog.md`、本番仕様は `docs/asset_spec.md` に置く。
