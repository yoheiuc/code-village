# Visual Direction

## 目標

3 秒以内に「Claude Code を使うと村が育つゲーム」だと分かる、ローカルファーストな開発者向けアンビエント村画面にする。

## 避けるもの

- 既存ゲームの見た目、建物、UI、配色、地形構成のコピー
- Claude / Anthropic のロゴ、公式カラー、公式 UI 風の表現
- 管理画面、BI ダッシュボード、生産性スコア画面に見える構成
- 深夜作業や作業量を称賛する視覚表現

## 画面構成

- 村景色を主役にする
- HUD は薄く、短い言葉だけにする
- 工房、図書館、道、橋、灯り、花、掲示板、木、水辺を視覚的に分ける
- 成長イベントはテキストだけでなく、村内オブジェクトの状態変化として表す

## モチーフ

- Build Workshop: Claude Code 使用の記憶が集まる作業小屋
- Docs Library: docs / reflection の蓄積
- Commit Flower: 小さな一歩の印
- Test Lantern: テストが通った日の灯り
- Debug Bridge: バグ修正で渡りやすくなる橋
- Branch Tree: 探索や分岐の記憶
- Issue Board: 今日の変化を貼る掲示板
- Release Bell: release tag の小さな鐘
- Creature Companions: 灯り、図書館、水辺、道端にいる小さな同居者。作業量を評価せず、村の息づかいを作る

## 色の方向

単色テーマに寄せすぎない。草、水、木、石、灯り、建物で素材差を出す。濃い紫や青系グラデーション、砂色一色、管理画面風の暗色 UI に寄せない。

## 癒しの方向

- 生き物は 2-3 種から始め、増やしすぎない。
- 眠る、座る、水辺を見る、灯りに寄る、掲示板を見るなど、静かな idle を中心にする。
- 既存ゲームのキャラ比率、顔、服、家具、UI、会話口癖、マップ構成をコピーしない。
- 収集圧、世話の義務、休みへのペナルティを作らない。

## Motion / Ambient Feedback

- 成長イベントの反応は 1-3 秒程度にする。
- 連続イベントは debounce / cooldown でまとめる。
- Dock bounce、通知連打、派手な点滅、作業量を煽る badge は使わない。
- Ambient mini window では村全体ではなく、灯り、生き物、花、水辺など小さな景色を見せる。
- 休んだ日や空 inbox では、静かな idle を続ける。

## Audio Direction

- BGM / SE は低刺激で、作業を褒める報酬音にしない。
- 最初に音を出すときはユーザーの明示操作を必要にする。
- 既存ゲーム、公式アプリ、Claude / Anthropic brand を連想させる音は使わない。
- 音の詳細仕様は `docs/audio_spec.md` に置く。

## アート制作フロー

1. 画像生成AIで構図や建物 silhouette の候補を作る。
2. Aseprite 等で 16x16 / 32x32 / 64x64 の実ゲーム素材に整理する。
3. `assets/production/` に配置する。
4. `assets/asset_manifest.json` を production path に差し替える。
5. Godot screenshot を確認し、`docs/visual_mvp_gap.md` を更新する。
