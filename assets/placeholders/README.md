# Placeholder Assets

このディレクトリの素材はすべて Functional MVP 用のダミー素材です。

## 扱い

- 完成品質のアートではない
- 商用配布前の最終素材ではない
- 既存ゲームや Claude / Anthropic ブランドに似せない
- `assets/asset_manifest.json` から参照する
- 本番素材は `assets/production/` に置き、manifest のパスを差し替える

## 目的

- Godot 上で TileMapLayer / Sprite2D / UI icon に差し替えやすい構造を先に作る
- 工房、図書館、道、水辺、橋、灯り、花、掲示板、住民を最低限区別できるようにする
- 木や広場などの環境物も `environment` section から差し替えられるようにする
- `state_visual_rules` で、成長状態ごとの仮オーバーレイを本番素材へ差し替えやすくする
- `effects` と `growth_effect_anchors` で、GrowthEvent 発生直後の一時演出を本番素材へ差し替えやすくする
- `effects/*.svg` はイベント別の識別用ダミーで、完成アニメーションや商用品質のeffectではない
- `characters/*_walk_*.svg` は住民の歩行差し替え口を検証するダミーフレームで、本番歩行アニメーションではない
- Visual MVP に必要な不足素材を明確にする

## 本番差し替え手順

1. `assets/production/<category>/` に本番素材を追加する。
2. ファイル名は `docs/asset_spec.md` の命名規則に合わせる。
3. `assets/asset_manifest.json` の該当パスを `assets/production` 側へ変更する。
4. `python3 tools/validate_asset_manifest.py` で参照欠けがないことを確認する。
5. 本番切り替え完了時は `python3 tools/validate_asset_manifest.py --require-production` を通す。
6. Godot を起動し、拡大率、位置、UI と重なりがないか確認する。
7. `docs/visual_mvp_gap.md` の不足項目を更新する。
