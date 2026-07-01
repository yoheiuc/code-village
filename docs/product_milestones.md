# Product Milestones

Code Village の商品判断は、価格そのものではなく「無料で使える水準」と「有料で渡せる水準」を分けて進める。価格は配布直前に実際のストア、同カテゴリ、為替、手数料を確認して決めるため、この文書では具体額を書かない。

## Reference Categories

参照するのは個別アプリの価格ではなく、期待される完成度のカテゴリ。

- Cozy / ambient indie game: 小さな日課、静かな成長、短時間で意味が伝わる画面。
- Developer companion / local utility: 作業の邪魔をせず、ローカル保存と明確な設定を持つ。
- Journaling / reflection app: 責めない記録、振り返り、削除導線、プライバシー説明。
- Desktop toy / idle growth app: 起動して眺められる変化、軽い達成感、低い学習コスト。
- Privacy-first offline app: 外部送信なし、読まないデータの明示、ユーザー管理の保存データ。

既存ゲームや Claude / Anthropic 公式 UI の見た目、素材、ブランド表現は参照対象にしない。

## Reference Apps Reviewed

2026-07-01 時点の公開ページを参考にした。価格やセール状況は変わるため、この文書では価格を固定しない。

- WakaTime: coding activity を扱う developer utility。free plan と paid plan の境界、履歴/分析/チーム機能の期待値を参考にする。Code Village は分析課金やランキングには寄せない。
  - `https://wakatime.com/pricing`
- ActivityWatch: local data と privacy-first の time/activity tracking。ローカル保存、ユーザー所有、外部送信しない姿勢を参考にする。
  - `https://github.com/activitywatch/activitywatch`
  - `https://activitywatch.net/blog/`
- Spirit City: Lofi Sessions: gamified focus tool。集中支援、収集、カスタマイズ、cozy desktop companion の完成度を paid-use 側の参考にする。
  - `https://store.steampowered.com/app/2113850/Spirit_City_Lofi_Sessions/`
- Rusty's Retirement: 作業中に画面下で進む idle farming simulator。邪魔しない常駐感、短い成長ループ、眺められる進行を参考にする。
  - `https://store.steampowered.com/app/2666510/Rustys_Retirement/`

## Free-use Threshold

無料配布、dogfood、限定共有で「使える」と言える最低ライン。

- Functional MVP が documented command で再現できる。
- Claude Code activity inbox から Git なしで村が育つ。
- prompt、response、source body、diff、secret、raw session id を読まないことがテストで確認できる。
- ローカル save、削除導線、破損 save フォールバックが動く。
- 初回ガイドと Settings が Local only / No sync / Git optional を説明する。
- placeholder art であることを明示し、完成アートとは呼ばない。
- headless load、unit tests、asset manifest、hook self-test/status、debug export smoke が通る。
- 休んだ日を責めず、生産性スコアやランキングを出さない。
- placeholder でも最低 1 種の小さな生き物または resident の気配があり、空 inbox / rest day でも責めない。

この段階では「遊べる完成品」ではなく、コンセプト、安全性、成長ループを検証できる状態とする。

## Paid-use Threshold

有料配布を検討できる最低ライン。

- Production art と icon が `assets/production/` に入り、manifest が production 参照へ切り替わる。
- 最初の 3 秒で「Claude Code の活動が村になる」ことが画面から伝わる。
- onboarding、Settings、privacy page、save delete、error state が実利用に耐える。
- macOS release export、code signing、notarization、Gatekeeper 確認が完了する。
- 実 Claude Code session dogfood で hook、inbox、import、growth、save の流れを確認する。
- screenshot、store text、CHANGELOG、known gaps が placeholder や未完成点を誤魔化さない。
- 外部通信なし、telemetry なし、analytics なし、crash report なしを維持する。
- 小さな買い切りゲームとして、1 回の起動後も戻ってきたくなる変化と記録がある。
- 3-5 種のオリジナル companion、idle animation、habitat、静かな ambient feedback がある。

有料化は「価格を付けられるか」ではなく、ユーザーが支払った後に期待を裏切らないかで判定する。

## Milestone Gates

| Milestone | Goal | Gate |
|---|---|---|
| M0 Functional MVP | ローカル成長ループを確認する | headless、unit、asset、privacy、debug checks が通る |
| M1 Free-use | 限定 dogfood / 無料共有に耐える | Git-free Claude Code flow、保存、削除、説明、回帰確認が揃う |
| M2 Visual MVP | 意図がすぐ伝わる | production 候補素材、HUD 整理、スクリーンショット確認が揃う |
| M3 Release Candidate | Mac アプリとして配れる | signing、notarization、Gatekeeper、privacy page、CHANGELOG が揃う |
| M4 Paid-use | 有料配布を判断する | reference categories と実ストア調査を更新し、価格以外の期待値を満たす |

## Scope Governance

- Now: `docs/development_scope.md` の Now にある debug、dogfood、diagnostics、triage、regression を優先する。
- Later: production art、visual polish、Git 補助入力拡張、release packaging、販売準備は Now gate 後に進める。
- Won't Do: 生産性監視、ランキング、外部送信、secret 読み取り、既存ゲームや公式ブランドのコピーは商品判断のためにも行わない。
