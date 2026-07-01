# Asset Backlog

## 方針

この一覧は Visual MVP に必要な本番素材の作業キュー。現在の `assets/placeholders/` はダミーであり、完成扱いしない。

本番素材へ切り替える前に `python3 tools/validate_asset_manifest.py --require-production` を通す。現在の Functional MVP は placeholder mode のため、この production gate は失敗するのが正常。

## 画像生成AIに依頼する候補

1. Village visual mood board
   - 目的: 「開発作業の記憶が残る村」の方向性確認
   - 注意: 既存ゲーム名、Claude / Anthropic ロゴ、公式 UI をプロンプトに入れない
2. Workshop concept
   - 目的: Build Workshop の silhouette と素材感を決める
   - 出力: 128x96 以上の下絵
3. Docs Library concept
   - 目的: 図書館の視認性と差別化
   - 出力: 128x104 以上の下絵
4. Overall village composition
   - 目的: 工房、図書館、道、水辺、橋、広場の関係を確認
   - 出力: 1280x720 の構図ラフ

## Aseprite 等で手作業調整する候補

1. Tileset
   - `grass`, `lower_grass`, `path`, `repaired_path`, `water`, `water_edge`, `plaza`
   - 受け入れ条件: 16x16 で tiling しても破綻しない
2. Commit Flower variants
   - 受け入れ条件: 小さくても花として読める。色違い 3 種以上
3. Test Lantern states
   - 受け入れ条件: off / on / glow が区別できる
4. Debug Bridge states
   - 受け入れ条件: worn / repaired が一目で違う
5. Branch Tree levels
   - 受け入れ条件: level 1-3 で成長が分かる
6. Resident sprites
   - 受け入れ条件: 2 人が silhouette で区別できる
7. UI icons
   - 受け入れ条件: 32x32 で読みやすく、HUD を主役にしすぎない
8. Growth effect sprites
   - `growth_pulse`, `flower_bloom_pulse`, `lantern_light_pulse`, `library_page_spark`, `workshop_glow`, `path_repair_pulse`, `bridge_repair_spark`, `branch_sprout_pulse`, `bell_ring_wave`, `resident_note_pulse`, `diary_page_pulse`
   - 受け入れ条件: 96x96 から 128x128 で、短時間表示でも村の変化として読める
   - 現状: `assets/placeholders/effects/` にダミーSVGあり。本番PNGへの差し替えが残る

## 優先度 P0

- `tiles/grass.png`
- `tiles/path.png`
- `tiles/water.png`
- `tiles/plaza.png`
- `environment/tree.png`
- `environment/plaza_core.png`
- `buildings/workshop.png`
- `buildings/library.png`
- `buildings/debug_bridge_worn.png`
- `buildings/debug_bridge_repaired.png`
- `buildings/test_lantern_on.png`
- `buildings/issue_board.png`
- `buildings/branch_tree_level_1.png`
- `characters/resident_a_idle.png`
- `characters/resident_b_idle.png`
- `effects/growth_pulse.png`

## 優先度 P1

- `tiles/repaired_path.png`
- `tiles/commit_flower_red.png`
- `tiles/commit_flower_yellow.png`
- `tiles/commit_flower_pink.png`
- `buildings/workshop_level_2.png`
- `buildings/library_level_2.png`
- `buildings/release_bell.png`
- `buildings/terminal_well.png`
- `ui/import_claude_events.png`
- `ui/settings.png`
- `ui/diary.png`
- `effects/flower_bloom_pulse.png`
- `effects/lantern_light_pulse.png`
- `effects/library_page_spark.png`
- `effects/workshop_glow.png`
- `effects/path_repair_pulse.png`
- `effects/bridge_repair_spark.png`
- `effects/branch_sprout_pulse.png`
- `effects/bell_ring_wave.png`

## 優先度 P2

- 住民 walk animation
- 季節差分
- growth event 一時エフェクトのanimation/polish
- `effects/resident_note_pulse.png`
- `effects/diary_page_pulse.png`
- Mac app icon
- store / itch.io 用 capsule image

## Production 切り替え前チェック

- `assets/production/<category>/` に P0 素材を配置する
- `assets/asset_manifest.json` の `mode` を `production` にする
- 参照パスを `res://assets/production/...` へ差し替える
- `python3 tools/validate_asset_manifest.py` が成功する
- `python3 tools/validate_asset_manifest.py --require-production` が成功する
- Godot headless test と screenshot capture を実行する
