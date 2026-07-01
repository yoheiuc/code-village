# Healing Audio Spec

## Goal

Code Village の音は、作業を煽る報酬音ではなく、村を開いたままにしておける healing audio として設計する。

現時点では BGM / SE / ambient sound を実装しない。音源も同梱しない。まず仕様、差し替え先、ライセンス確認、操作条件を固定する。

## Current State

- Audio assets: none
- Audio playback: not implemented
- BGM / SE settings: not implemented
- Audio manifest: not implemented

現在の placeholder art と同じく、将来の音素材も完成扱いしない。production release 前に source、license、originality review を記録する。

## Audio Buses

将来の Godot audio bus は次を想定する。

- `Master`: 全体音量と mute。
- `BGM`: 低刺激の seamless loop。
- `SFX`: GrowthEvent に対する短い音。rate limit 必須。
- `Ambient`: 水辺、灯り、風などの環境音。BGM と分ける。

初期音量は低めにする。初回起動で突然音を出さず、ユーザーの明示操作後に再生する。

## User Settings

将来 `UserSettings` に追加する候補:

- `audio_enabled`
- `master_volume`
- `bgm_volume`
- `sfx_volume`
- `ambient_volume`
- `background_audio_enabled`
- `mute_on_focus_loss`

Settings には one-click mute、BGM on/off、SE on/off、volume を置く。menu bar / mini window を作る場合も、Play / Pause / Mute / Quit は見える場所に置く。

## Asset Locations

Placeholder:

- `assets/placeholders/audio/`

Production:

- `assets/production/audio/bgm/`
- `assets/production/audio/sfx/`
- `assets/production/audio/ambient/`

Recommended formats:

- BGM / Ambient loop: `.ogg`
- Short SFX: `.wav` or `.ogg`

将来 `assets/audio_manifest.json` を追加し、path、loop、bus、default volume、license、source、originality review status を管理する。

## Event SFX Direction

SE は短く、柔らかく、作業量を褒めない。

- `flower_bloomed`: 小さな葉擦れ
- `lantern_lit`: 柔らかい灯りの音
- `library_expanded`: 紙が軽くめくれる音
- `workshop_upgraded`: 木の小物が置かれる音
- `bridge_repaired`: 小さな木の響き
- `bell_rang`: 控えめな bell。release を大げさに祝わない
- rest day: 追加 SE なし、または水辺の ambient のみ

連続 event では SFX をまとめる。短時間に同じ音を何度も鳴らさない。

## Licensing And Originality

Allowed:

- 自作音源
- 明確に商用利用可能なライセンスの音源
- 生成音源を使う場合でも、既存ゲーム名、企業名、公式アプリ名、既存曲名を prompt / reference に入れないもの

Not allowed:

- 既存ゲームの BGM / SE / sound design のコピー
- Animal Crossing / どうぶつの森、Stardew Valley、Claude / Anthropic 公式体験を想起させる音の模倣
- 権利元、license、source が不明な音源
- 外部 streaming や remote audio fetch
- microphone input や system audio capture

## QA Acceptance Criteria

音を実装するときの最低条件:

- 初回起動で勝手に鳴らない。
- mute / volume が保存される。
- scene reload、sleep / wake、window reopen で BGM が多重再生しない。
- SFX に rate limit がある。
- background audio は明示 opt-in。
- 音源 path は bundled asset だけを指し、ユーザーの任意ファイル path を初期実装で保存しない。
- audio manifest validator で path、license、source、originality review status を検査する。
- privacy docs に microphone / system audio capture をしないことを明記する。
