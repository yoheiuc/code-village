# アセット出典・ライセンス一覧

外部アセットの出典と利用条件の記録。切り出し座標の詳細は `docs/external_asset_setup.md` を参照。

## 使用中（コミット済み、`assets/production/` 配下）

| パック | 作者 | URL | ライセンス | 利用形態 |
|--------|------|-----|-----------|---------|
| Tiny Town | Kenney | https://kenney.nl/assets/tiny-town | CC0（クレジット不要・商用可・改変自由） | タイル・建物合成・小物 |
| Tiny Farm | Kenney | https://kenney.nl/assets/tiny-farm | CC0（同上） | 住民キャラ・ひまわり・リンゴの木 |
| Tiny Battle | Kenney | https://kenney.nl/assets/tiny-battle | CC0（同上） | 水タイル |

コミット済み PNG は上記パックからの切り出し・合成による派生物。CC0 のためリポジトリへの同梱・再配布・改変に制限はない。

## ダウンロード済み・未使用（拡張候補）

| パック | URL | ライセンス | 想定用途 |
|--------|-----|-----------|---------|
| Tiny Dungeon | https://kenney.nl/assets/tiny-dungeon | CC0 | 住民・生き物のバリエーション |
| Tiny Ski | https://kenney.nl/assets/tiny-ski | CC0 | 冬・季節演出 |
| RPG Urban Pack | https://kenney.nl/assets/rpg-urban-pack | CC0 | 町の小物補完 |

## 検討済み・不採用（再配布不可のためコミット不可）

| パック | URL | ライセンス | 備考 |
|--------|-----|-----------|------|
| Cute Fantasy RPG（無料版） | https://kenmi-art.itch.io/cute-fantasy-rpg | 独自: 非商用限定・クレジット必須・再販/再配布禁止 | 試す場合は `assets/production/local/`（gitignore済み）に配置。商用採用時は Premium 版（$2.99以上、商用可）を購入 |

## 注意事項

- 本プロダクトの方針（`docs/development_scope.md` の Won't Do）に従い、特定の既存ゲームの見た目の再現を目的とした使い方はしない
- 新しい外部素材を追加する際は、この表に「パック名・作者・URL・ライセンス・利用形態」を追記する
