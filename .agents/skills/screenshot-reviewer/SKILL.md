---
name: screenshot-reviewer
description: Use for reviewing Code Village screenshots or captured Godot screens for readability, UI layout, game feel, placeholder quality, copy risk, dashboard feel, visual overlap, and whether the village clearly communicates growth without copying existing games or brands.
---

# Screenshot Reviewer

## 使うタイミング

- Godot の screenshot を確認するとき。
- UI/村/placeholder の視認性をレビューするとき。
- ダッシュボード感、コピー感、重なりを検出するとき。

## 入力

- screenshot image
- 対象 scene
- `docs/asset_spec.md`
- `docs/product_spec.md`

## 出力

- severity 順の visual findings。
- 修正案。
- 必要なら issue 追記。

## 禁止事項

- 見ていないものを「確認済み」と言わない。
- 既存ゲームに似せる修正を提案しない。
- UI を数値 dashboard に寄せない。
- Claude / Anthropic 公式風に寄せない。

## チェックリスト

- 工房、図書館、掲示板、池、道、橋、灯り、花、広場が見える。
- HUD 文字が読める。
- 文字や UI が重なっていない。
- main screen が game first に見える。
- privacy local-only 表示がある。
- 既存ゲーム/ブランドのコピー感がない。

## 実行手順

1. screenshot を見る。
2. 重要度順に問題を書く。
3. 具体的な scene/script 修正箇所を示す。
4. 必要なら `docs/issues.md` に追加する。
5. 修正後 screenshot で再確認する。

## 完了条件

- 視認性、ゲームらしさ、コピーリスクの評価がある。
- 修正が必要なものは具体的な次タスクになっている。
- 未確認事項は未確認と明記されている。
