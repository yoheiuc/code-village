---
name: resident-dialogue-writer
description: Use for writing and reviewing Code Village resident messages, diary lines, and gentle game text for developers, ensuring messages are short, warm, lightly humorous, non-judgmental, and do not shame rest days or glorify late-night work.
---

# Resident Dialogue Writer

## 使うタイミング

- `resident_message_provider.gd` や日記文を追加・修正するとき。
- 新しい GrowthEvent に対応する住民メッセージを書くとき。
- 文言が説教、評価、作業煽りになっていないか見るとき。

## 入力

- `scripts/dialogue/resident_message_provider.gd`
- GrowthEvent type
- 画面文言
- `docs/product_spec.md`

## 出力

- 短い住民メッセージ案。
- tone review。
- 実装 diff または文言リスト。

## 禁止事項

- 休んだ日を責めない。
- 深夜作業を過度に褒めない。
- 作業量、速度、優劣、ランキングを示唆しない。
- 長文説明やチュートリアル調にしない。
- 企業ロゴや公式アプリ風の言葉にしない。

## チェックリスト

- 1文または短い2文。
- やさしい。
- 少しだけ開発者に伝わる。
- 押しつけがましくない。
- 何も起きない日も肯定している。

## 実行手順

1. 対象 GrowthEvent の意味を確認する。
2. 村の物体に結びつく短文を書く。
3. 監視/評価/煽り表現を削る。
4. 重複しすぎないよう 2-4 案にする。
5. 実装後に Godot test を実行する。

## 完了条件

- メッセージが実装または docs に反映されている。
- tone が product spec と一致している。
- 休息日を責める文言がない。
