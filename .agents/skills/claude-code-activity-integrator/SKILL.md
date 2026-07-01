---
name: claude-code-activity-integrator
description: Use for Code Village Claude Code activity integration work, including local hook/inbox ingestion, privacy-safe metadata sanitization, CLI event writer behavior, ActivityEvent mapping, and keeping Claude Code usage as the primary input while Git remains optional.
---

# Claude Code Activity Integrator

## 使うタイミング

- Claude Code hook / local inbox / `tools/code_village_event.py` を変更するとき。
- Git に依存しない活動イベントを追加するとき。
- Claude Code の prompt、response、private log、認証情報を読まない設計を確認するとき。

## 入力

- `tools/code_village_event.py`
- `scripts/activity/claude_code_activity_ingestor.gd`
- `scripts/activity/activity_event.gd`
- `scripts/village/growth_rule_engine.gd`
- `docs/privacy.md`
- `docs/technical_architecture.md`

## 出力

- privacy-safe Claude Code activity ingestion。
- ActivityEvent / GrowthEvent mapping。
- テストと docs 更新。

## 禁止事項

- Claude Code の prompt / response / private log / token / 認証情報を読まない。
- raw session id を保存しない。必要なら hash のみ。
- raw cwd / full path を保存しない。必要なら短い project label のみ。
- 外部送信、telemetry、analytics を追加しない。
- Git repo 登録を必須にしない。

## チェックリスト

- Claude Code activity は Git なしで村の成長に変換される。
- inbox reader は allowlist metadata だけを受け入れる。
- CLI は stdin JSON を sanitize して JSONL に追記する。
- duplicate event id は再取り込みしない。
- privacy.md と technical_architecture.md が実装と一致している。
- `python3 -m unittest tests/test_code_village_event.py` が通る。
- `godot --headless --path . --script res://tests/run_unit_tests.gd` が通る。

## 実行手順

1. Claude Code activity を `ActivityEvent` として表せるか確認する。
2. CLI / ingestor / rule engine の責務を分ける。
3. 保存する metadata を allowlist に限定する。
4. prompt、response、raw path、raw session id が保存されないテストを追加する。
5. docs と UI で Git が optional であることを確認する。

## 完了条件

- Claude Code usage が主入力として動く。
- Git 非依存のテストがある。
- privacy 原則に反するデータが保存されない。
