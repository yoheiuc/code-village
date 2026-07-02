# 外部アセット セットアップ手順（ビジュアルプロトタイプ用）

外部アセットパックを使ったビジュアル検証（プロトタイプ）のローカルセットアップ手順。
アセットファイル本体は再配布禁止ライセンスのため **リポジトリにコミットしない**（`.gitignore` で除外済み）。
出典・ライセンスの一覧は `docs/asset_attribution.md` を参照。

## 前提条件

- このリポジトリを clone 済みで、デフォルト状態の起動・テストが通ること
- `godot`（4.x）と `ffmpeg` がインストール済みであること（スクリーンショット取得時のみ）

## 手順

1. アセットパックを各配布ページからダウンロードする。

   | パック | URL | ライセンス | 用途 |
   |--------|-----|-----------|------|
   | Kenney Tiny Town | https://kenney.nl/assets/tiny-town | CC0 | タイル・建物・小物 |
   | Kenney RPG Urban Pack | https://kenney.nl/assets/rpg-urban-pack | CC0 | タイル・小物の補完 |
   | Cute Fantasy RPG（無料版） | https://kenmi-art.itch.io/cute-fantasy-rpg | 独自（非商用限定・クレジット必須・再配布禁止） | 建物・住民・自然物 |

   無料版は非商用限定のため、本手順の用途は「ビジュアル検証」に限る。商用リリースに採用する場合は Premium 版（商用可）を購入し、`docs/asset_backlog.md` のライセンス管理に記録すること。

2. スプライトシート形式のパックは、下記の対応表のキー単位で個別 PNG に切り出す（例: macOS プレビュー、GIMP、`magick crop` 等）。タイルは 16x16 を維持する。

3. 切り出した PNG を以下のファイル名で配置する（`assets/asset_manifest_prototype.json` の参照先）。

   | 配置先 | ファイル名 |
   |--------|-----------|
   | `assets/production/tiles/` | `grass.png` `lower_grass.png` `path.png` `repaired_path.png` `water.png` `plaza.png` `commit_flower.png` |
   | `assets/production/buildings/` | `workshop.png` `library.png` `issue_board.png` `debug_bridge.png` `test_lantern.png` `release_bell.png` `branch_tree.png` |
   | `assets/production/environment/` | `tree.png` `plaza_core.png` |
   | `assets/production/characters/` | `resident_a.png` `resident_b.png` |

   一部だけ配置しても動作する。未配置分はタイルが単色プレースホルダーに、スプライトが読み込みスキップになる。

4. 配置後、gitに追跡されていないことを確認する。

   ```bash
   git status --porcelain assets/production/
   # 何も出力されなければ正しく除外されている
   ```

## 確認方法

```bash
# manifest 検証（未配置ファイルは "does not exist" エラーとして列挙される。配置済みなら errors=0）
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

## 調整メモ

- 16x16 系パックの建物・住民は placeholder の実寸（建物 128x96 等、住民 48x64）より小さい。`asset_manifest_prototype.json` の `sprite_layout` の `scale` を整数倍（3.0 / 4.0 など）で調整する。非整数倍はドット幅が不均一になるため避ける
- オートタイル（terrain set）・水面アニメーション・住民の歩行アニメーションは本プロトタイプの対象外（静止タイルの差し替えのみ）
