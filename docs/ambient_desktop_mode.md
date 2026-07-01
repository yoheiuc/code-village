# Ambient Desktop Mode

## Goal

将来の Code Village は、普段は Mac の端に小さく居続け、Claude Code の安全な activity event が届いたときだけ短い反応を返す ambient companion になる。

この機能は現在の MVP には含めない。今は debug、dogfood、privacy regression を優先し、常駐化は Later の検証対象にする。

## Mac Presence Model

Mac で「タスクバーに常駐」に近い体験は複数ある。Code Village では段階的に扱う。

1. Main Village Window
   - 現在の Godot window。
   - 村の景色、HUD、Settings、日記を表示する主画面。
2. Ambient Mini Window
   - 最初に検証する候補。
   - 小さな borderless / always-on-top 風 window に、灯り、生き物、花、村の一部だけを表示する。
   - Godot 本体だけで始めやすいが、Spaces、fullscreen、multi-monitor、focus stealing、battery の検証が必要。
3. Dock / Menu Bar Presence
   - Later の技術検証。
   - 真の menu bar extra は Swift / AppKit helper、native plugin、または wrapper が必要になる可能性がある。
   - Godot 本体と helper が同じ save を同時に書かないよう、single-writer / read-only helper 方針を先に決める。

Launch at login、常時表示、background audio はすべて明示 opt-in にする。初期状態で勝手に常駐や音の継続再生を始めない。

## Event Reactions

常駐表示は `GrowthEvent` を入力にし、新しい監視対象を増やさない。

- `claude_code_session`: 工房の灯りが短く明るくなる
- `claude_code_turn_completed`: 花や小さな生き物が 1-3 秒だけ反応する
- `tests_passed`: Test Lantern が柔らかく灯る
- `docs_updated`: Docs Library のページが小さく揺れる
- `bugfix_detected`: Debug Bridge 付近に短い波紋が出る
- rest day / no event: 水辺や灯りのそばで静かな idle を続ける

連続 event は debounce / cooldown でまとめ、「村が少し賑わった」程度にする。Dock bounce、派手な badge、通知連打、点滅、作業量を煽る演出は使わない。

## Architecture Direction

将来追加する候補:

- `FeedbackController`: `GrowthEvent` から visual reaction、companion reaction、SE cue を作る。
- `AmbientModeController`: main window と mini window の表示状態、pause、quit、mute を管理する。
- `AudioManager`: BGM / SFX / Ambient の再生、volume、mute、fade、rate limit を管理する。
- `assets/audio_manifest.json`: 音源 path、loop、license、source、originality review status を管理する。

`ActivityEvent -> GrowthEvent -> VillageState` は現在のまま維持する。常駐や音のために prompt、response、source、diff、secret、clipboard、window title、screen、keyboard、system-wide app activity を読まない。

## QA Acceptance Criteria

Ambient Mini Window を作る前に、以下を issue の受け入れ条件にする。

- idle 10 分で CPU 使用率が低い。目標は 1-2% 以下。
- event が無いとき save 書き込みを繰り返さない。
- inbox が巨大化しても UI が止まらず、古い event を再成長させない。
- sleep / wake、minimize、window reopen 後に timer や audio が二重化しない。
- mute / pause / quit が常に分かる。
- 画面共有で raw path、session id、作業内容が見えない。
- Accessibility、Screen Recording、Input Monitoring、Microphone 権限を要求しない。必要になった場合は実装前に privacy docs と opt-in UI を更新する。

## Now / Later / Won't Do

Now:

- 実装しない。
- debug runner、Claude Code hook dogfood、privacy-safe diagnostics を優先する。
- この文書と issue で将来の境界だけ固定する。

Later:

- Ambient Mini Window spike。
- `FeedbackController` と event reaction debounce。
- companion idle / reaction animation。
- native macOS menu bar / Dock integration feasibility。
- idle performance harness。

Won't Do:

- system-wide activity monitoring。
- clipboard、window title、screen、keyboard、microphone 監視。
- manager dashboard、ランキング、作業量評価。
- 通知連打、streak、休みへの penalty。
- Animal Crossing / どうぶつの森、Stardew Valley、Claude / Anthropic 公式 UI の見た目や音のコピー。
