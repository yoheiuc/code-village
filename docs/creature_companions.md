# Creature Companions

## Goal

Code Village には、小さな生き物たちが暮らしている。彼らは作業量を評価する存在ではなく、村にいる気配、休息、見守り、静かな生活感を作る存在。

Animal Crossing のような「安心感、日課感、生きた村にいる感じ」は感情面の参考にする。ただし、キャラクター、顔、体型、服、家具、UI、会話、配色、マップ構成、住民システム、口癖、素材はコピーしない。

## Design Principles

- 生き物は報酬装置ではなく、村の同居者。
- 休んだ日もいる。何も変わらない日でも責めない。
- 作業量に比例して増えすぎたり、忙しそうに働いたりしない。
- 収集圧、世話の義務、streak、ペナルティを作らない。
- 見た目は Code Village 固有の habitat companion にする。
- 癒しは、短い idle、眠る、座る、水辺を見る、灯りに寄る、掲示板を見る、紙を読むなどの静かな行動で出す。

## Initial Companion Concepts

MVP では 1 種から始める。Paid-use までに 3-5 種へ広げる。

1. `lamp_moth`
   - Habitat: Test Lantern / 工房の灯り
   - Behavior: 灯りのそばをゆっくり漂う。tests pass や Claude session 後に少し寄る
   - Tone: 「小さな灯りを見に来た」程度。作業量を褒めない
2. `page_sprout`
   - Habitat: Docs Library / Village Diary
   - Behavior: 本のそばで葉を揺らす。docs/reflection 後にページの影から顔を出す
   - Tone: 記録が残ることをやさしく示す
3. `pond_friend`
   - Habitat: 池 / 橋 / 水辺
   - Behavior: 休んだ日や変化が少ない日に水辺で眠る
   - Tone: 何も変わらない日も村があることを示す
4. `path_pebble`
   - Habitat: Refactor Path / Debug Bridge
   - Behavior: 道端で小さく跳ねる。refactor/bugfix 後に道を見る
   - Tone: 整った道の静かな気配

## Gameplay Contract

Free-use までに満たす最低条件:

- Git なし Claude Code activity で、最低 1 種の placeholder companion が見える。
- 空 inbox / rest day でも、責めない companion message または静かな visitor が出る。
- GrowthEvent ごとに、村内変化、短い生き物反応、diary/resident message のどれかがある。
- privacy boundary は変えない。prompt、response、source body、diff、secret、raw path、raw session id は読まない。

Paid-use までに満たす最低条件:

- 3-5 種の production companion sprites がある。
- idle animation、短い reaction、habitat がある。
- store screenshot で既存ゲームのコピーではない独自の村だと分かる。
- `docs/asset_backlog.md` と production asset checklist に source / license / originality review がある。

## Asset Contract

Placeholder:

- Path: `assets/placeholders/characters/`
- Format: self-made SVG
- Size target: 48x64 visual footprint
- Quality: dummy / functional placeholder。完成扱いしない

Production:

- Path: `assets/production/characters/`
- Format: PNG or sprite sheet
- Size target: 48x64 idle base
- Future animation: idle 2 frames, walk 4 directions x 2 frames
- Naming: lowercase snake_case
  - `lamp_moth_idle.png`
  - `page_sprout_idle.png`
  - `pond_friend_idle.png`
  - `path_pebble_idle.png`

Manifest:

- 短期は既存 `characters.resident_a` / `characters.resident_b` を互換維持する。
- 新規は `characters.lamp_moth`, `characters.page_sprout`, `characters.pond_friend` から始める。
- 将来、必要なら `creatures` section を追加し、`characters` は legacy alias にする。

## Voice

短く、やさしく、少しだけユーモアがある。作業量を評価しない。

Examples:

- 「灯りのそばに、小さなお客さんが来ています。」
- 「水辺で誰かが昼寝しています。今日はそれで十分です。」
- 「図書館のページの陰で、葉っぱが少し揺れました。」
- 「道端の小石が、いつもより丸く見えます。」
- 「何も変わらない日も、村には小さな息づかいがあります。」

## Won't Do

- Animal Crossing / Nintendo のキャラクター、UI、住民構造、会話口癖、素材、配色、マップ構成をコピーしない。
- 既存ゲーム名を画像生成 prompt に入れない。
- Claude / Anthropic のロゴ、公式色、公式 UI 風表現を使わない。
- 生き物に作業量を評価させない。
- 収集圧、餌やり義務、ログイン streak、休みへの罪悪感を作らない。
- 外部送信、telemetry、prompt/response/diff/source 読み取りを追加しない。
