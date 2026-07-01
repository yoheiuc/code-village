# Debugging

## Goal

Code Village のデバッグは、実ユーザーの save / Claude Code inbox を汚さず、temporary path で再現できることを優先する。

最初に見る issue:

- [#1 開発/デバッグ環境の基礎を作る](https://github.com/yoheiuc/code-village/issues/1)
- [#2 Claude Code global hook を実機 dogfood する](https://github.com/yoheiuc/code-village/issues/2)

## One Command Debug

通常の開発確認:

```bash
python3 tools/dev_debug.py
```

この command は一時ディレクトリを作り、次を確認する。

- Python syntax
- asset manifest
- Python unit tests
- Claude hook self-test
- temporary inbox から Godot save への import
- Godot headless load
- Godot unit tests
- macOS debug export smoke
- `git diff --check`

実ユーザーの既定 save / inbox は使わない。内部で次の環境変数を temporary path に向ける。

- `CODE_VILLAGE_ACTIVITY_INBOX`
- `CODE_VILLAGE_SAVE_PATH`

## Fast Debug

macOS export は重いので、通常の編集ループでは省略できる。

```bash
python3 tools/dev_debug.py --fast
```

Godot が無い環境で Python / manifest / hook command だけ確認する。

```bash
python3 tools/dev_debug.py --skip-godot
```

実行される check 名だけを見る。

```bash
python3 tools/dev_debug.py --list
```

JSON report が必要な場合:

```bash
python3 tools/dev_debug.py --json
```

失敗時に temporary directory を残したい場合:

```bash
python3 tools/dev_debug.py --keep-temp
```

## Global Hook Dogfood

global Claude Code hook 設定を確認する。

```bash
python3 tools/claude_hook_status.py --settings ~/.claude/settings.json
```

別ディレクトリで Claude Code session を実行して終了したあと、inbox event を確認する。

```bash
python3 tools/claude_hook_status.py --settings ~/.claude/settings.json --require-events
```

Godot で Code Village を起動し、取り込み後に save import を確認する。

```bash
godot --path .
python3 tools/claude_hook_status.py --settings ~/.claude/settings.json --require-save-import
```

## Privacy Checks

debug command は以下を保存しないことを検査する。

- prompt
- response
- raw path
- raw session id

debug command も外部送信、telemetry、analytics を行わない。

## When A Check Fails

1. `tools/dev_debug.py --json --keep-temp` で失敗箇所と temporary path を見る。
2. Godot runtime の問題なら `CODE_VILLAGE_SAVE_PATH` と `CODE_VILLAGE_ACTIVITY_INBOX` を同じ temporary path に向けて再実行する。
3. hook の問題なら `tools/claude_hook_self_test.py` と `tools/claude_hook_status.py --settings ~/.claude/settings.json` を分けて実行する。
4. export の問題なら `python3 tools/verify_macos_export.py --skip-launch` と launch ありを分ける。

## Not In Scope

- 本番 player UI として debug overlay を出すこと
- 生産性スコア、ランキング、比較表示
- external sync や crash report
- prompt / response / source body / diff の保存
