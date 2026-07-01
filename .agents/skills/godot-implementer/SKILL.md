---
name: godot-implementer
description: Use for implementing Code Village in Godot 4.x and GDScript, including scenes, scripts, local save, UI, placeholder village rendering, model updates, and headless validation while keeping changes small and privacy-safe.
---

# Godot Implementer

## 使うタイミング

- Godot scene / GDScript / save / UI / placeholder rendering を実装するとき。
- Godot で起動・headless 検証するとき。
- 既存構成を壊さず小さく機能を足すとき。

## 入力

- `project.godot`
- `scenes/`
- `scripts/`
- `tests/run_unit_tests.gd`
- `docs/technical_architecture.md`

## 出力

- Godot 4.x で読み込める scene/script。
- 必要なテストまたは検証結果。
- 実行方法の更新。

## 禁止事項

- 外部通信、telemetry、analytics SDK を追加しない。
- source body、diff、secret file body を読む処理を追加しない。
- Godot 以外の大きなスタックへ勝手に移行しない。
- 既存ゲーム素材やブランド素材を追加しない。

## チェックリスト

- `godot --headless --path . --quit-after 1` が通る。
- `godot --headless --path . --script res://tests/run_unit_tests.gd` が通る。
- state / rendering / HUD の責務が分離されている。
- user data 保存は local JSON。
- UI 文言に作業煽りがない。

## 実行手順

1. `AGENTS.md` と architecture docs を読む。
2. 変更対象 scene/script を確認する。
3. モデル、ルール、描画、UI、保存の責務を分けて実装する。
4. Godot headless で構文とテストを確認する。
5. docs/commands が古ければ更新する。

## 完了条件

- Godot が project をロードできる。
- 実装した振る舞いに対する検証がある。
- privacy 原則に反する処理がない。
