# macOS Export

## 現状

MVP には `export_presets.cfg` の `macOS` preset がある。現在の確認済み範囲は、署名なし debug export の生成と、zip 展開後の `.app` バイナリ headless 起動まで。

これは配布完成ではない。販売/配布前には本番アイコン、release export、code signing、notarization、Gatekeeper 確認が必要。

## 必要なもの

- Godot 4.7
- Godot 4.7 export templates

この環境では以下へ Godot 4.7 stable export templates を配置済み。

```text
~/Library/Application Support/Godot/export_templates/4.7.stable/
```

## Debug Export

推奨コマンド:

```bash
python3 tools/verify_macos_export.py
```

この tool は署名なし debug export を生成し、zip に `Code Village.app` の binary が含まれること、`docs/`, `tools/`, `tests/`, `.claude/`, `.ai/`, `.agents/`, `artifacts/`, `notes/` が zip entry として混入していないこと、展開後 `.app` が一時 save / inbox で headless 起動することを確認する。外部送信、署名、notarization、upload は行わない。

手動で export だけを行う場合:

```bash
mkdir -p builds/mac
godot --headless --path . --export-debug macOS builds/mac/CodeVillage.zip
```

生成物:

```text
builds/mac/CodeVillage.zip
```

zip には `Code Village.app` が入る。`builds/` は生成物なので git 管理しない。

## 起動確認

`tools/verify_macos_export.py` がこの確認を自動で行う。手動で確認する場合も、実ユーザー保存を触らないよう、一時保存先を指定する。

```bash
TMP_APP_DIR="$(mktemp -d)"
unzip -q builds/mac/CodeVillage.zip -d "$TMP_APP_DIR"
CODE_VILLAGE_ACTIVITY_INBOX="$TMP_APP_DIR/empty_inbox.jsonl" \
CODE_VILLAGE_SAVE_PATH="$TMP_APP_DIR/save.json" \
  "$TMP_APP_DIR/Code Village.app/Contents/MacOS/Code Village" --headless --quit-after 1
```

## 配布前に残る作業

- 本番アイコンを `.icns` として用意する
- release export を確認する
- `CHANGELOG.md` に release notes と既知の未完了項目を反映する
- Developer ID 証明書で code signing する
- notarization を通す
- 初回起動、保存、Claude Code inbox import、任意 Git 登録を `.app` 上で目視確認する
- `export_presets.cfg` に秘密情報を入れない。署名用credentialは `export_credentials.cfg` 側に分離し、git 管理しない。
