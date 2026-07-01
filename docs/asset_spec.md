# Asset Spec

## 前提

初期実装の画像・アート素材はすべてダミー素材として扱う。Codex は完成品質の画像生成や本番ピクセルアート制作を担当しない。担当範囲は、Godot 上の構造、データモデル、画面配置、素材差し替え口、プレースホルダー配置、仕様整理まで。

現在の `VillageView` は Functional MVP 用であり、Visual MVP 完成ではない。地形、道、水辺は `VillageTileLayer` の `TileMapLayer`、主要オブジェクト、木、広場、花、灯り、状態差分オーバーレイは `VillageSpriteLayer` の `Sprite2D` で配置している。`VillageView._draw()` の簡易図形は主に素材欠落時の fallback。本番素材は `assets/production/` に置き、`assets/asset_manifest.json` の参照を差し替える。

## 1. タイルサイズ

- 基準タイル: 16x16 px
- 地形タイル: 16x16 px
- 小物: 16x16 から 32x32 px
- 建物: 64x64 から 128x128 px を基本単位にする
- Godot 表示では nearest filtering 前提で整数倍に近い拡大を優先する

## 2. 画面解像度

- reference resolution: 1280x720
- UI は 16:9 を基準に配置する
- 将来の Mac window resize に備え、村描画は reference resolution からスケールする

## 3. カメラ範囲

- MVP: 固定カメラ
- reference world: 1280x720
- 村景色が画面の 80% 以上を占めることを Visual MVP の目標にする
- HUD は主役にしない

## 4. スプライト基準サイズ

- 花 / 小石 / 小さな草: 16x16
- 灯り / 看板小物: 32x48 または 48x80
- 住民: 32x48 または 48x64
- 木: 48x64 から 96x112

## 5. 建物サイズ

- Build Workshop: 128x96 以上
- Docs Library: 128x104 以上
- Issue Board: 96x64
- Debug Bridge: 128x48
- Terminal Well / Pond edge object: 48x48 から 96x64
- Release Bell: 64x80

## 6. キャラクターサイズ

- 住民基本: 48x64
- 将来 animation: idle 2 frames, walk 4 directions x 2 frames
- 顔差分は MVP 後。初期は silhouette と服色で区別する

## 7. UI アイコンサイズ

- toolbar / button icon: 32x32
- small inline icon: 16x16
- panel header icon: 24x24
- 色と形で意味が分かるが、最終 UI はテキストに頼りすぎない

## 7.5. 成長エフェクト素材サイズ

- 一時エフェクト: 96x96 から 128x128
- `assets/production/effects/` に配置する
- 表示位置、scale、z-index は `assets/asset_manifest.json` の `growth_effect_anchors` で管理する
- 一時エフェクトは保存対象ではなく、`GrowthEvent` 発生直後の短い視覚フィードバックとして扱う

## 8. TileMapLayer 構成

将来の置き換え先は以下。

- `GroundLayer`: grass, lower grass, plaza base
- `PathLayer`: path, repaired path, plaza stones
- `WaterLayer`: pond / river, water edge
- `ObjectLayer`: flower, lantern, sign, small props
- `BuildingLayer`: workshop, library, board, bridge, bell
- `CharacterLayer`: residents
- `GrowthOverlayLayer`: growth event の一時演出

MVP では地形、道、水辺を `VillageTileLayer` が `TileMapLayer` で置き、主要オブジェクト、木、広場、花、灯り、成長状態オーバーレイは `VillageSpriteLayer` が `Sprite2D` で置く。環境物は `environment` section、状態オーバーレイは `assets/asset_manifest.json` の `state_visual_rules` に定義し、`VillageState` の値だけを読む。ゲーム状態は `VillageState` に閉じ、表示側から状態を読むだけにする。

`GrowthOverlayLayer` 相当の MVP 実装は `VillageSpriteLayer.show_growth_events()`。`growth_effect_anchors` でイベント別のアンカーを定義し、`effects/growth_pulse` のような専用仮素材を重ねる。本番化時は `effects/` の素材と anchor を差し替える。

Functional MVP では `assets/placeholders/effects/` にイベント別のダミー SVG を置く。これは完成品質ではなく、イベント差し替え口と表示位置の検証用。

## 9. 必要なタイル一覧

- `grass`
- `lower_grass`
- `path`
- `repaired_path`
- `water`
- `water_edge`
- `plaza`
- `plaza_stone`
- `commit_flower`
- `small_shadow`

## 10. 必要な建物素材一覧

- `workshop`
- `library`
- `issue_board`
- `debug_bridge_worn`
- `debug_bridge_repaired`
- `test_lantern_off`
- `test_lantern_on`
- `release_bell`
- `branch_tree_level_1`
- `branch_tree_level_2`
- `branch_tree_level_3`
- `terminal_well`
- `merge_gate`

## 10.5. 必要な環境素材一覧

- `environment/tree`
- `environment/plaza_core`
- `environment/small_shadow`
- `environment/pond_edge_prop`
- `environment/pathside_stone`

## 11. 必要な住民素材一覧

- `resident_a_idle`
- `resident_b_idle`
- `resident_a_walk`
- `resident_b_walk`
- `resident_message_marker`

## 12. 必要な UI 素材一覧

- `import_claude_events`
- `scan_optional_git`
- `settings`
- `delete_local_save`
- `privacy_local_only`
- `diary`
- `recent_growth`
- `repo_optional`

## 12.5. 必要なエフェクト素材一覧

- `growth_pulse`
- `flower_bloom_pulse`
- `lantern_light_pulse`
- `library_page_spark`
- `workshop_glow`
- `path_repair_pulse`
- `bridge_repair_spark`
- `branch_sprout_pulse`
- `bell_ring_wave`
- `resident_note_pulse`
- `diary_page_pulse`

## 13. 成長イベントごとの必要素材

- `claude_code_session`: workshop glow / workbench small upgrade
- `claude_code_turn_completed`: small commit flower
- `flower_bloomed`: commit flower variants
- `path_repaired`: repaired path tile
- `lantern_lit`: lit test lantern
- `bridge_repaired`: repaired bridge
- `library_expanded`: extra shelf / page banner
- `workshop_upgraded`: workshop roof/detail upgrade
- `branch_tree_grew`: branch tree level variants
- `issue_board_updated`: board paper marker
- `bell_rang`: release bell swing frame
- `resident_message_added`: resident speech marker
- `diary_entry_created`: diary/page icon
- `plaza_decorated`: plaza prop
- 一時演出: `growth_effect_anchors` の anchor と `assets/production/effects/*.png`

## 14. ファイル命名規則

- lowercase snake_case
- カテゴリ別に配置する
- growth state は suffix で表す
- 例:
  - `assets/production/tiles/repaired_path.png`
  - `assets/production/buildings/workshop_level_2.png`
  - `assets/production/characters/resident_a_idle.png`
  - `assets/production/ui/import_claude_events.png`
  - `assets/production/effects/growth_pulse.png`

## 15. 差し替え手順

1. 本番素材を `assets/production/<category>/` に置く。
2. `assets/asset_manifest.json` の該当パスを `res://assets/production/...` に変更する。
3. `python3 tools/validate_asset_manifest.py` で参照欠けがないことを確認する。
4. 本番素材切り替え gate では `python3 tools/validate_asset_manifest.py --require-production` を通す。
5. Godot で起動し、manifest が読み込まれることを `tests/run_unit_tests.gd` で確認する。
6. `VillageView` または将来の TileMapLayer / Sprite2D view が manifest のパスを参照する。
7. スクリーンショットを撮り、`docs/visual_mvp_gap.md` を更新する。

`tools/validate_asset_manifest.py` は manifest と参照先パスだけを読む。画像本文、source body、diff、secret、外部ネットワークは扱わない。

## コピー禁止

- Stardew Valley の素材、UI、建物、人物、マップ構成、色設計をコピーしない
- 既存ゲームのドット絵を参照トレースしない
- Claude / Anthropic のロゴ、公式 UI、ブランド要素を入れない
- 生成画像を使う場合も、既存ゲーム名や企業ロゴをプロンプトに入れない
