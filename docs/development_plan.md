# Development Plan

## Phase 0: リポジトリ整理

- Godot 4.x project scaffold
- README / AGENTS / docs
- repo-scoped skills
- local-first privacy rules
- acceptance: headless load check が通る

## Phase 1: 最小村画面

- `main.tscn`, `village.tscn`, `main_hud.tscn`
- placeholder village drawing
- `asset_manifest.json`
- `AssetCatalog`
- `assets/placeholders/` と `assets/production/` の分離
- procedural `VillageTileLayer`
- manifest-driven `VillageSpriteLayer`
- HUD: Village Level, Today, Current Project, Recent Growth, Resident Message, Local only
- acceptance: Godot で村画面が表示される

## Phase 2: 保存

- `SaveManager`
- `VillageState` serialize / deserialize
- repository configs
- settings defaults
- acceptance: 起動後も村状態が JSON 保存される

## Phase 3: Claude Code activity inbox

- `tools/code_village_event.py`
- `.claude/settings.json`
- `ClaudeCodeActivityIngestor`
- startup / periodic auto import
- no prompt / no response / no private log / no raw session id
- acceptance: Git に関係なく Claude Code activity event から GrowthEvent が生成され、VillageState に反映される

## Phase 3b: Optional Git 活動スキャン

- `GitActivityScanner`
- registered repo path only
- no diff / no source body / no commit message
- extension summary only
- acceptance: ローカル Git repo から ActivityEvent が生成される

## Phase 4: 成長イベント

- `GrowthRuleEngine`
- ActivityEvent -> GrowthEvent
- intensity cap
- VillageState update
- acceptance: commit/docs/tag/manual event が村状態に反映される

## Phase 5: 日記と住民メッセージ

- diary entries
- resident messages
- rest day message
- tone review
- acceptance: 休んだ日も責めないメッセージだけが出る

## Phase 6: Mac アプリ化

- export preset
- app icon
- production art manifest switch
- save data delete UI
- notarization 調査
- acceptance: Mac app として起動できる
- current: 署名なし debug export の zip 生成と、展開後 `.app` バイナリの headless 起動は確認済み

## Phase 7: 販売準備

- title polish
- screenshot review
- privacy page
- small changelog
- 100 円から 500 円程度の買い切り価値の確認
- acceptance: 体験、プライバシー、配布物の最小セットが揃う
