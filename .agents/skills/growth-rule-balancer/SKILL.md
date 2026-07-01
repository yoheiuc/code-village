---
name: growth-rule-balancer
description: Use for designing and tuning Code Village ActivityEvent to GrowthEvent rules, balancing village growth, avoiding commit-count obsession, rankings, work pressure, streak pressure, or mechanics that shame rest days.
---

# Growth Rule Balancer

## 使うタイミング

- `GrowthRuleEngine` のルールを追加・調整するとき。
- 成長速度、intensity、日記、住民メッセージのバランスを変えるとき。
- 作業量煽りやコミット数偏重を避けたいとき。

## 入力

- `scripts/village/growth_rule_engine.gd`
- `scripts/village/village_state.gd`
- `scripts/activity/activity_event.gd`
- `scripts/village/growth_event.gd`
- `docs/product_spec.md`

## 出力

- 変換ルールの更新。
- バランス理由。
- 必要なテスト更新。

## 禁止事項

- productivity score を作らない。
- streak を罰や義務にしない。
- commit 数を過剰報酬化しない。
- 休んだ日をマイナスにしない。
- ranking / comparison を導入しない。

## チェックリスト

- ActivityEvent から GrowthEvent への対応が明確。
- intensity は小さく cap されている。
- 同じ活動の連続 scan で過剰成長しない設計がある。
- docs と実装が一致している。
- 住民メッセージが穏やか。

## 実行手順

1. 追加する ActivityEvent と GrowthEvent を定義する。
2. 成長の見た目と state 影響を決める。
3. intensity と重複抑制を確認する。
4. `tests/run_unit_tests.gd` を更新する。
5. Godot headless test を実行する。

## 完了条件

- 成長ルールが実装・テストされている。
- 作業煽りやランキング化がない。
- product spec と implementation が一致している。
