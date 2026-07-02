# 外部アセット セットアップ・管理（ビジュアルプロトタイプ用）

外部アセットパックを使ったビジュアル検証（プロトタイプ）のアセット管理ルールと再生成手順。
出典・ライセンスの一覧は `docs/asset_attribution.md` を参照。

## 方針

- **CC0 素材（Kenney 等）はコミットする**: `assets/production/<category>/` 直下に配置。clone 直後にプロトタイプの見た目が再現できる
- **再配布不可の素材はコミットしない**: `assets/production/local/` に置く（`.gitignore` で除外済み）。Cute Fantasy RPG 無料版などを試す場合はこちらへ
- プロトタイプの見た目は `assets/asset_manifest_prototype.json` が定義する。デフォルトの `asset_manifest.json`（placeholder mode）は変更しない

## コミット済みアセットの構成（すべて CC0 / Kenney）

各 PNG は Kenney パックの `Tilemap/tilemap_packed.png` から 16x16 タイル単位で切り出し・合成したもの。
座標は (col, row) のゼロ始まり。

| ファイル | 元パック | 元タイル座標 |
|---------|---------|-------------|
| tiles/grass.png | Tiny Town | (1,0) |
| tiles/lower_grass.png | Tiny Town | (0,0) |
| tiles/path.png | Tiny Town | (1,2) |
| tiles/repaired_path.png | Tiny Town | (5,3) |
| tiles/plaza.png | Tiny Town | (7,3) |
| tiles/water.png | Tiny Battle | (1,2) |
| tiles/commit_flower.png | Tiny Farm | (11,6) |
| buildings/workshop.png | Tiny Town | 屋根(4-6,4)(4-6,5) + 壁(0,6) + 扉(2,7) + 窓(0,7) の3x3合成 |
| buildings/library.png | Tiny Town | 屋根(0-2,4)(0-2,5) + 壁(4,6) + 扉(5,7) + 窓(4,7) の4x3合成 |
| buildings/issue_board.png | Tiny Town | (11,6) |
| buildings/debug_bridge.png | Tiny Town | (8,6)(9,6)(10,6) の3x1合成 |
| buildings/test_lantern.png | Tiny Town | (10,7)+(11,4) の1x2合成 |
| buildings/release_bell.png | Tiny Town | (10,7) |
| buildings/branch_tree.png | Tiny Town | (3,0)+(3,1) の1x2合成 |
| environment/tree.png | Tiny Town | (4,0)+(4,1) の1x2合成 |
| environment/plaza_core.png | Tiny Farm | (6,6) |
| characters/resident_a.png | Tiny Farm | (0,9) |
| characters/resident_b.png | Tiny Farm | (1,9) |

ダウンロード済みだが未使用のパック: Tiny Dungeon / Tiny Ski / RPG Urban Pack（住民バリエーションや季節演出の拡張候補）。

## 確認方法

```bash
# manifest 検証（コミット済みアセットが揃っていれば errors=0、warning は placeholder 混在の想定内通知）
python3 tools/validate_asset_manifest.py --manifest assets/asset_manifest_prototype.json

# プロトタイプmanifestで起動（目視確認）
CODE_VILLAGE_ASSET_MANIFEST=res://assets/asset_manifest_prototype.json godot --path .

# スクリーンショット取得（proto-*.png を出力。既存の mvp-*.png は上書きしない）
python3 tools/capture_mvp_screenshots.py \
  --asset-manifest res://assets/asset_manifest_prototype.json \
  --output-prefix proto

# デフォルト状態が壊れていないことの確認（env 未設定で実行すること）
godot --headless --path . --quit-after 1
godot --headless --path . --script res://tests/run_unit_tests.gd
python3 tools/validate_asset_manifest.py
```

## 制約・調整メモ

- `sprite_layout` の `scale` は整数倍（2.0 / 3.0 / 4.0）を使う。非整数倍はドット幅が不均一になる
- オートタイル（terrain set）・水面アニメーション・住民の歩行アニメーションは対象外（静止タイルの差し替えのみ）。池や道の境界が硬く見えるのは既知の制約
- 再配布不可素材を使う場合は `assets/production/local/` に置き、manifest のパスをそちらへ向けたローカル専用manifestを別途作る（コミットしない）
