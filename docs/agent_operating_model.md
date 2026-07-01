# Agent Operating Model

Code Village の作業は 6 つの役割で見る。これは人員固定ではなく、issue、docs、実装レビューの観点を分けるための運用モデル。

## Shared Rules

- `docs/development_scope.md` の Now / Later / Won't Do を作業判断の正本にする。
- すべての提案は Now、Later、Won't Do のどれかに置く。
- Now は acceptance、検証コマンド、privacy impact を持つ。
- Later は理由と着手条件を残し、今の実装に混ぜない。
- Won't Do は safety、privacy、brand、tone を守るための制約として扱う。
- 他 agent の担当ファイルや進行中変更を巻き戻さない。

## Roles

| Role | Responsibilities | Outputs | Handoff |
|---|---|---|---|
| Game Architect | コアループ、データモデル、privacy boundary、MVP gate を守る | architecture notes、scope decision、acceptance criteria | Gameplay と QA/Test に実装条件、UI/UX に体験意図を渡す |
| Gameplay | ActivityEvent、GrowthEvent、VillageState、成長ルール、保存の挙動を作る | gameplay implementation、unit tests、growth tuning notes | UI/UX に表示状態、QA/Test に再現手順と edge cases を渡す |
| UI/UX | 初回ガイド、Settings、村画面、今日の変化、日記、住民メッセージを整える | screen flow、copy、interaction notes、accessibility checks | Gameplay から状態を受け、Polish に tone と visual gaps を渡す |
| Asset Pipeline | placeholder / production asset の分離、manifest、検証、差し替え手順を守る | asset manifest updates、asset backlog、validation results | UI/UX と Polish に素材制約、QA/Test に manifest gate を渡す |
| QA/Test | headless、unit、privacy、asset、hook、debug export、regression を確認する | test results、bug reports、release blockers | 各 role に失敗条件と最小再現手順を返す |
| Polish | tone、feel、スクリーンショット、release notes、商品としての期待値を整える | polish checklist、screenshot review、CHANGELOG/release notes | Game Architect に release readiness、UI/UX と Asset Pipeline に不足を返す |

## Now Governance

Now に入れる条件。

- debug / dogfood / regression を前に進める。
- Git-free Claude Code inbox growth loop の安全性が上がる。
- privacy boundary を狭める、または検証可能にする。
- Functional MVP の再現性、保存、取り込み、表示の信頼性が上がる。
- 受け入れ条件を実コマンドで確認できる。

Now の output は、変更、検証結果、未解決 gap を短く残す。

## Later Governance

Later に置く条件。

- 価値はあるが、debug / dogfood / regression gate の後でよい。
- production art、visual polish、release packaging、販売準備に属する。
- 設計は必要だが、今の実装に混ぜると scope が広がる。
- privacy や tone の追加検討が必要。

Later の output は、着手条件と依存 gate を残す。

## Won't Do Governance

Won't Do に置く条件。

- 生産性スコア、ランキング、作業量比較につながる。
- 休んだ日を責める、深夜作業を過度に褒める。
- 外部 telemetry、analytics、crash report、自動送信を含む。
- Claude Code の非公開ログ、prompt、response、token、認証情報を読む。
- source body、git diff、secret file body、初期状態の commit message / file name 保存を含む。
- 既存ゲームや Claude / Anthropic 公式ブランドに見える素材、UI、表現を使う。

Won't Do は backlog に戻さない。方針違反を防ぐ lint、test、documentation は Now または Later として扱える。

## Handoff Format

各 role の引き渡しは短く揃える。

- Scope: Now / Later / Won't Do
- Changed: 触ったファイルと責務
- Verified: 実行した command と結果
- Risks: privacy、brand、tone、release の未解決点
- Next: 次の role が行う 1 つから 3 つの具体作業
