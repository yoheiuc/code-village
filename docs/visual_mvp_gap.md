# Visual MVP Gap

## 現在の状態

現在の画面は Functional MVP。`VillageView._draw()` の簡易図形と `assets/placeholders/` のラベル付き SVG だけで構成している。これはビジュアル完成ではない。

## 不足点

- 建物が完成品質のピクセルアートではない
- 地形、道、水辺は TileMapLayer 化済み
- 主要オブジェクト、木、広場、花、灯り、橋/小道/工房/図書館/Branch Tree/Release Bell の状態差分は Sprite2D 化済み
- `VillageView._draw()` の簡易図形は主に fallback として残っている
- 成長イベントの一時演出は `growth_effect_anchors` と `assets/placeholders/effects/` のイベント別ダミーSVGで最低限入ったが、仮の強調表示であり完成品質ではない
- 常時HUDは小型化し、手動メモと任意Git登録は Workshop Settings 内へ移動済み。初回ガイドは `FirstRunGuideBoard` として Claude Code 主入力、Git 任意、Local only / No sync、読まないデータを明示するよう強化済み。ただし、情報パネル感はまだ少し残る
- UI アイコンは仮で、ゲームらしい手触りは弱い
- 住民と `lamp_moth` companion は簡易SVGで、キャラクター性はまだ弱い
- 住民2人は短い往復モーション、`lamp_moth` は漂うモーションを持つが、歩行アニメーションのフレーム差分はまだない
- 画面を見ただけで Claude Code との関係が分かる視覚モチーフは不足している

## 直近のスクリーンショット確認

対象: `artifacts/screenshots/mvp-initial.png`, `artifacts/screenshots/mvp-settings.png`, `artifacts/screenshots/mvp-registered.png`, `artifacts/screenshots/mvp-grown.png`, `artifacts/screenshots/mvp-growth-effect.png`

再生成方法: `python3 tools/capture_mvp_screenshots.py`

最新確認: 2026-07-01 に `screenshot-reviewer` skill の観点で5枚を目視。加えて `godot --editor --path . --quit-after 1` は成功し、Editor起動モードでもプロジェクトはロードできた。Editor内での手動操作目視は未実行。

- 改善: HUD が小さくなり、村、工房、図書館、橋、水辺、道、花、住民が以前より見えやすい
- 改善: 手動入力フォームが常時表示から Settings 内に移り、ダッシュボード感が減った
- 改善: 初回ガイドは小さな掲示札のまま、Claude Code のローカルイベントで村が育つこと、Git は任意であること、prompt/response/source/diff/secrets を読まないことを画面内で示す
- 改善: 下部の村だよりは横一枚の情報帯ではなく、3つの小さな掲示札になり、草地の余白が見える
- 改善: 右上操作札は Village Tools として日付、Import、Git、Gear、短い状態表示だけに圧縮され、村景色を大きく隠さない
- 改善: 左上状態札と右上Tool Shelfは木製掲示札寄りの見た目になり、Workshop Settings は閉じられる村内掲示板として表示される
- 改善: 右上Tool Shelfの Import / Git / Gear 文字ボタンを、既存placeholder UI SVGを使う小さなアイコンボタンへ変更した
- 改善: Workshop Settings は説明文と操作ラベルを短くし、高さを下げて下部掲示札とより離した
- 改善: Workshop Settings から `Auto import local Claude events` を切り替えられるようにし、ローカル inbox 読み取りの制御を見える化した
- 改善: Resident Message を下部の3枚目の札から村内の小さな吹き出しへ移し、Settings 表示中は重なりを避けるため非表示にした
- 改善: Recent Growth は木製の掲示板風、Village Diary は紙色の日記帳風に分け、下部2枚の用途差を出した
- 改善: 木と広場も manifest の `environment` section から Sprite2D として配置される
- 改善: Claude Code の session / turn event から、工房glowと花pulseが村内に出る。画像はAVIの中間フレームから抽出した実行時キャプチャ
- 改善: 花、灯り、図書館、工房、橋、道、枝、鐘、住民メモ、日記向けに個別のplaceholder effect pathができた
- 改善: 工房の灯り近くに `lamp_moth` placeholder companion を追加し、manifest-driven idle motion と GrowthEvent 反応の入口を作った
- 改善: `resident_a` / `resident_b` に manifest-driven の短い pacing motion を追加し、画面の棒立ち感を下げた
- 確認: 初期画面で工房、図書館、掲示板、水辺、橋、道、花、木、住民、広場は識別できる
- 確認: 初期画面で工房横に小さな companion が見える
- 確認: 成長状態では花、灯り、橋、小物、日記/Recent Growth の変化が見える
- 確認: 一時エフェクト画面では花pulseと工房glowが村内位置に出る
- 残課題: 右上操作札は改善したが、まだ完全なゲーム内オブジェクトではなくUIパネルに見える
- 残課題: 下部の村だよりは2枚に減り用途差も出たが、まだ本番アートの掲示物ではない
- 残課題: 上部3つと下部2つの札がまだUIとして画面を囲み、ゲーム世界から浮いて見える。初回ガイドは説明力が上がった分、初期スクリーンショットでは以前より少し情報量が増えた
- 残課題: Settings は小型化したが、工房内の掲示板というより設定パネルに見える
- 残課題: Claude Code との関係はテキスト依存で、工房や村内オブジェクトだけではまだ伝わりにくい
- 残課題: 成長effectは仮素材で、イベント別の本番ピクセルアート、アニメーション、粒度調整にはなっていない
- 残課題: companion は1種だけで、行動、habitat、rest-day visitor としての説得力はまだ弱い
- 残課題: 住民モーションは Sprite2D の位置 tween だけで、上下左右の歩行フレームや目的地を持つ gameplay にはなっていない

追加確認:

- `artifacts/screenshots/mvp-settings.png`: Settings は右側に収まり、下部リボンと重ならない。Git repo input は空欄で、実ローカルパスを表示しない。説明文とボタン文言は短縮済み
- `artifacts/screenshots/mvp-settings.png`: Workshop Settings は Close ボタン付きになり、Privacy / Claude Code Notes / Optional Git が分かれる
- `artifacts/screenshots/mvp-initial.png`: Resident Message は右下の札ではなく、住民付近の紙色の吹き出しとして表示される
- `artifacts/screenshots/mvp-initial.png`: 工房横の灯り付近に `lamp_moth` placeholder companion が表示される。素材はダミーで完成アートではない
- `artifacts/screenshots/mvp-initial.png`: 実行中は住民2人が広場付近を小さく往復する。静止スクリーンショットでは動き自体は読み取りにくい
- `artifacts/screenshots/mvp-initial.png`: Recent Growth と Village Diary は別スタイルの仮掲示物として表示される
- `artifacts/screenshots/mvp-registered.png`: 任意 Git 登録後も上部HUDは短い repo 表示だけで、村景色を大きく隠さない
- `artifacts/screenshots/mvp-grown.png`: 合成成長状態で、manifest の `state_visual_rules` から状態オーバーレイが表示される。素材はすべてダミー
- `artifacts/screenshots/mvp-grown.png`: `Village Diary` がローカル/UTC日付の揺れで空にならず、今日の成長を表示する
- `artifacts/screenshots/mvp-grown.png`: Recent Growth / Village Diary は3件表示に絞り、下部掲示札内で文字が切れない
- 4枚とも、木と広場はダミーSVGのSprite2Dとして表示される
- Settings はまだ情報密度が高く、将来はタブ/折りたたみ/ゲーム内掲示板風の表現へ寄せる余地がある

## Visual MVP 成功条件

- スクリーンショットを見て、3 秒以内に「Claude Code を使うと村が育つゲーム」だと分かる
- 画面の 80% 以上が村の景色
- HUD が主役になりすぎていない
- 工房、図書館、道、橋、灯り、花、掲示板、木、水辺が視覚的に区別できる
- 成長イベントがテキストだけでなく村の見た目として表現される
- ダッシュボードではなくゲーム画面に見える
- 既存ゲームのコピーに見えない
- 本番素材に差し替えられる構造になっている

## 次に画像生成AIへ依頼する素材

1. 1280x720 の村構図ラフ
2. Build Workshop の建物コンセプト
3. Docs Library の建物コンセプト
4. 水辺、橋、広場を含む小さな村の mood board

既存ゲーム名や企業ロゴをプロンプトに含めない。

## 次に Aseprite 等で調整する素材

1. 16x16 tileset: grass / path / water / plaza
2. 128x96 workshop sprite
3. 128x104 library sprite
4. bridge worn / repaired
5. lantern off / on
6. resident A / B idle
7. commit flower variants
8. growth pulse / event-specific effect sprites

## 差し替え時の確認

- `assets/asset_manifest.json` が production path を指す
- Godot headless test が通る
- 起動画面で素材欠落がない
- screenshot-reviewer skill で視認性、コピー感、ダッシュボード感を確認する
