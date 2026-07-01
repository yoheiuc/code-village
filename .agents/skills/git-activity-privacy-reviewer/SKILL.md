---
name: git-activity-privacy-reviewer
description: Use for reviewing Code Village Git activity scanning and storage for privacy and security, especially ensuring only registered local repositories are scanned and no source body, git diff, secrets, commit messages, or external service text are read or stored.
---

# Git Activity Privacy Reviewer

## 使うタイミング

- `GitActivityScanner`, save data, repository settings, privacy docs を変更するとき。
- Git metadata の読み取り範囲をレビューするとき。
- 新しい activity source を追加するとき。

## 入力

- `scripts/activity/git_activity_scanner.gd`
- `scripts/save/save_manager.gd`
- `scripts/config/user_settings.gd`
- `docs/privacy.md`
- `docs/technical_architecture.md`

## 出力

- privacy/security findings。
- 修正 diff または具体的な修正タスク。
- docs と実装の整合性確認。

## 禁止事項

- `git diff` を使わない。
- source body、`.env` body、secret file body を読まない。
- commit message を初期状態で読まない/保存しない。
- 外部 API、Claude Code private log、認証情報に触れない。
- repo path を外部送信しない。

## チェックリスト

- scanner は登録済み local path だけ扱う。
- Git は shell 文字列でなく引数配列で実行する。
- 保存データに file name / commit message / diff が入らない。
- `store_commit_messages=false`, `store_file_names=false`, `enable_external_network=false`。
- コマンド失敗で game が落ちない。

## 実行手順

1. scanner と save の変更差分を読む。
2. 実行コマンド一覧を確認する。
3. 保存される metadata keys を確認する。
4. `docs/privacy.md` と照合する。
5. 違反があれば P0 として修正する。

## 完了条件

- 読む/保存する/読まないデータが明確。
- 実装と privacy docs に矛盾がない。
- MVP で外部送信しないことが維持されている。
