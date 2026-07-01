# Development Scope

## Purpose

Code Village は「Claude Code を使うと村が育つ」ローカルファーストな Mac 向け Godot ゲームとして進める。Git は任意の補助入力であり、主入力は Claude Code activity inbox。

この文書は、開発中に issue の優先順位がぶれないように、今やること、後でやること、やらないことを分ける。

## Now

次に進める範囲。まずは開発と dogfood を速くする。

1. デバッグ環境を作る
   - 1 コマンドで headless test、Python test、asset manifest、hook self-test、macOS debug export smoke を走らせる。
   - 実ユーザー save / inbox を汚さず、temporary save / inbox で再現できる。
   - Godot 起動時の save path、inbox path、import count、latest event を確認できる。
2. Claude Code global hook の実 dogfood
   - 任意の別ディレクトリで Claude Code を使い、`~/.claude/settings.json` から event が書かれることを確認する。
   - prompt、response、raw path、raw session id が保存されないことを確認する。
3. 開発者向けの診断 UI / overlay
   - debug build または環境変数でだけ表示する。
   - event count、save status、auto import status、latest growth を見る。
   - production 向け UI にはしない。
4. issue triage の整備
   - GitHub issue を `priority:*`, `scope:*`, `area:*` label で整理する。
   - GitHub issue が作業単位、docs は判断基準と設計記録として使う。
5. Functional MVP の回帰検証
   - screenshot capture、Godot headless、Python tests、privacy checks を継続的に回す。

## Later

やるが、今はデバッグ環境と dogfood の後に回す。

1. Production pixel art
   - `assets/production/` に本番素材を配置し、manifest を差し替える。
   - Codex は本番アート制作を担当しない。差し替え口、仕様、検証を担当する。
2. Visual MVP polish
   - HUD と村オブジェクトをさらにゲーム内オブジェクト化する。
   - ダッシュボード感を下げ、スクリーンショットで 3 秒以内に意図が伝わる状態を目指す。
3. Git 補助入力の拡張
   - Git は任意のままにする。
   - 読み取り対象は安全な metadata だけに限定する。
4. macOS release packaging
   - 本番 icon、signed export、notarization、Gatekeeper 確認を行う。
5. Opt-in commit message display
   - 明示 opt-in、privacy 文書、削除導線、UI を揃えてから設計する。
   - 初期状態では保存も表示もしない。
6. 小さな買い切りゲームとしての販売準備
   - release 品質、store page、スクリーンショット、privacy page、CHANGELOG を揃える。

## Won't Do

Code Village の安全性とコンセプトを守るため、やらない。

1. 生産性スコア、ランキング、作業量比較
2. 休んだ日を責める streak / penalty
3. 深夜作業を過度に称賛する演出
4. 外部 telemetry、analytics、crash report の自動送信
5. Claude Code の非公開ログ、transcript、private API の読み取り
6. Claude / Anthropic の認証情報、token、Keychain 値の読み取り
7. prompt、response、source body、git diff、secret file body の保存
8. 初期状態での commit message / file name 保存
9. Stardew Valley や既存ゲームの素材、UI、キャラクター、配色、マップのコピー
10. Claude / Anthropic 公式アプリに見える branding
11. Codex による完成品質の本番アート制作
12. cloud sync、team dashboard、manager view

## Debug Environment Definition

デバッグ環境が「使える」と言える最低条件:

- clean clone 直後に documented command で検証できる
- 実ユーザー save / inbox を触らず再現できる
- hook event、save import、growth event、VillageState を一連で追える
- 失敗時に何が壊れたかが command output から分かる
- privacy boundary を同時に検査する
- macOS debug export の起動 smoke まで確認できる

## Issue Labels

- `priority:p0`: 次に着手する。壊れていると開発が止まる。
- `priority:p1`: P0 の後に進める。MVP 品質を上げる。
- `priority:p2`: 重要だが今すぐではない。
- `scope:now`: 現在の開発対象。
- `scope:later`: やるが今はやらない。
- `scope:wont-do`: 方針としてやらない。
- `area:debug`: 開発、検証、診断、dogfood。
- `area:privacy`: privacy boundary、保存、sanitize。
- `area:visual`: 見た目、asset、screenshot。
- `area:release`: macOS export、配布、販売準備。
- `type:task`: 実装やドキュメントの作業単位。
