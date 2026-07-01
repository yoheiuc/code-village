---
name: pixel-art-director
description: Use for Code Village visual direction, placeholder-to-pixel-art planning, asset specs, palette and tile guidance, and screenshot art review while avoiding Stardew Valley or other existing game copies and avoiding Claude/Anthropic brand elements.
---

# Pixel Art Director

## 使うタイミング

- `docs/asset_spec.md` を更新するとき。
- placeholder art を本番 pixel art へ置き換えるとき。
- 画面が既存ゲームや公式ブランドに似すぎていないか確認するとき。

## 入力

- `docs/asset_spec.md`
- `scripts/village/village_view.gd`
- screenshot または scene description
- 最新の game design docs

## 出力

- asset list / tile spec / palette direction。
- コピーリスク指摘。
- 差し替えしやすい素材単位の提案。

## 禁止事項

- Stardew Valley や既存ゲームの素材、配色、建物、UI、キャラをコピーしない。
- Claude / Anthropic のロゴ、色、公式 UI を使わない。
- 有料/外部アセットを前提にしない。
- 生成画像で既存ゲーム名や企業ロゴを参照しない。

## チェックリスト

- 16px tile 基準に整理されている。
- 建物やオブジェクトが silhouette で識別できる。
- 色が一色相に偏りすぎていない。
- dashboard ではなく game scene に見える。
- placeholder と本番 asset の差し替え境界が明確。

## 実行手順

1. 現在の village view と asset spec を読む。
2. 必要素材を object / tile / UI icon に分類する。
3. コピー感とブランド誤認を確認する。
4. asset spec または issue を更新する。
5. Godot で表示確認できる変更なら headless/目視確認を行う。

## 完了条件

- オリジナルの 2D 村として説明できる。
- 既存ゲームや公式ブランドのコピーに見えない。
- 次に描く asset の単位と条件が明確。
