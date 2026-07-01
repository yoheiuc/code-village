# Claude Code Hook Setup

## 方針

Code Village の主入力は Claude Code hook が明示的に書くローカル activity inbox。Git は任意。hook は外部送信せず、`tools/code_village_event.py` が allowlist されたメタデータだけを JSONL に追記する。

公式 hook 仕様は Claude Code の hook documentation を確認する。設定形式は変わる可能性があるため、この repo の `.claude/settings.json` は MVP 用の最小構成として扱う。

- Official docs: `https://docs.anthropic.com/en/docs/claude-code/hooks`

## この repo の設定

`.claude/settings.json` は次のイベントを使う。

- `SessionStart`: `claude_code_session` を書く
- `Stop`: `claude_code_turn_completed` を書く

どちらも stdin JSON を `tools/code_village_event.py --stdin-json` に渡す。CLI は prompt / response / raw path / raw session id を保存しない。

## グローバル設定

他のディレクトリでも Code Village に Claude Code usage event を送りたい場合は、Claude Code の user settings に hook を入れる。user settings の場所は `~/.claude/settings.json`。

このリポジトリの `tools/code_village_event.py` を絶対パスで呼ぶ。下の JSON では `/path/to/code-village` を clone した Code Village の絶対パスに置き換える。`PROJECT_DIR` は Claude Code が渡す `CLAUDE_PROJECT_DIR` を優先し、無い場合は現在の working directory を使う。CLI 側で raw path は basename の `project_label` に丸める。

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "PROJECT_DIR=\"${CLAUDE_PROJECT_DIR:-$PWD}\"; python3 \"/path/to/code-village/tools/code_village_event.py\" --stdin-json --type claude_code_session --hook-event SessionStart --project-label \"$PROJECT_DIR\" >/dev/null 2>&1 || true"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "PROJECT_DIR=\"${CLAUDE_PROJECT_DIR:-$PWD}\"; python3 \"/path/to/code-village/tools/code_village_event.py\" --stdin-json --type claude_code_turn_completed --hook-event Stop --project-label \"$PROJECT_DIR\" >/dev/null 2>&1 || true"
          }
        ]
      }
    ]
  }
}
```

既存の `~/.claude/settings.json` がある場合は、上書きではなく既存 JSON の `hooks.SessionStart` / `hooks.Stop` 配列へ追加する。secret、token、認証情報、外部送信コマンドは入れない。

グローバル設定の一時検証は、実 inbox を触らず `CODE_VILLAGE_ACTIVITY_INBOX` を一時ファイルへ向けて hook command を実行する。

## 保存先

```bash
tools/code_village_event.py --print-path
```

既定では以下に JSONL が作られる。

```text
~/Library/Application Support/Code Village/activity_inbox/claude_code_events.jsonl
```

`CODE_VILLAGE_ACTIVITY_INBOX` で上書きできる。

## Smoke Test

hook 経由ではなく、同じ CLI を手動で確認する。

```bash
printf '{"session_id":"local-test","cwd":"/Users/example/private-project"}' \
  | tools/code_village_event.py --stdin-json --dry-run
```

期待:

- `metadata.project_label` は `private-project` のような basename
- `metadata.session_hash` は hash
- raw path / raw session id / prompt / response は出ない

実ファイルへ書く場合:

```bash
printf '{"session_id":"local-test","cwd":"%s"}' "$PWD" \
  | tools/code_village_event.py --stdin-json --type claude_code_turn_completed
```

Godot 側は起動時と約 10 秒ごとに inbox を自動取り込みする。自動取り込みは Settings の `Auto import local Claude events` で切り替えできる。off のときも、手動で確認する場合は `Import Claude Events` を押せる。

実際の Godot 起動で、実ユーザー保存を触らずに確認する場合は Python の smoke test を使う。

```bash
python3 -m unittest tests/test_code_village_event.py
```

このテストは一時 inbox に CLI で Claude Code event を書き、`CODE_VILLAGE_SAVE_PATH` で一時保存先を指定して Godot を起動する。期待値は、Git repo が未登録でも工房と花が増え、prompt / response / raw path / raw session id が保存されないこと。`auto_import_claude_events=false` の保存データでは、起動時に inbox event を自動取り込みしないことも確認する。

同じ test suite は `.claude/settings.json` の hook command 文字列も一時環境で実行する。`CLAUDE_PROJECT_DIR` と `CODE_VILLAGE_ACTIVITY_INBOX` を一時値に差し替え、`SessionStart` / `Stop` command が安全な inbox event を書き、その inbox から Godot 起動時に村が育つことを確認する。

この検証は Claude Code 本体の hook 発火そのものを代替しない。実機 dogfood では、Claude Code session を開始/終了したあとに inbox が増えることを別途確認する。

## Self-test CLI

unittest より短い導線として、repo-local hook 設定だけを確認する self-test がある。

```bash
python3 tools/claude_hook_self_test.py
```

この CLI は以下を一時ディレクトリだけで検査する。

- `.claude/settings.json` の `SessionStart` / `Stop` command を実行できる
- temporary inbox に `claude_code_session` / `claude_code_turn_completed` が書かれる
- prompt / response / raw path / raw session id が inbox に残らない
- Godot 起動時に temporary inbox から Git なしで村状態が育つ
- temporary save に prompt / response / raw path / raw session id が残らない

Godot を起動せず hook command だけ確認する場合:

```bash
python3 tools/claude_hook_self_test.py --skip-godot
```

これは実ユーザー保存や既定 inbox を触らない。実 Claude Code 本体が hook を発火するかどうかは、実 session での dogfood が必要。

## Status Check

実 dogfood 前後に、repo-local hook 設定、実 inbox、実 save の状態を確認する。

```bash
python3 tools/claude_hook_status.py
```

この CLI は以下だけを読む。

- `.claude/settings.json`
- Code Village activity inbox
- Code Village save file

表示するのは件数、event type、時刻、basename 化された project label、hook event、session hash の有無、村状態の集計だけ。prompt / response / raw path / raw session id の値は表示しない。

実 Claude Code session 後に、hook が inbox event を書いたかを exit code で確認する場合:

```bash
python3 tools/claude_hook_status.py --require-events
```

ゲーム起動後に save へ取り込まれたことまで確認する場合:

```bash
python3 tools/claude_hook_status.py --require-save-import
```

この status check は Claude Code 本体の hook 発火を代替しない。実 session の前後で `--require-events` と `--require-save-import` を使い、実 inbox と実 save の変化を見るための診断。

## 削除

- ゲーム内保存: Settings の `Delete Local Save`
- inbox: `tools/code_village_event.py --print-path` で場所を確認して JSONL を削除
- hook: `.claude/settings.json` の hooks を削除またはリネーム

## 禁止事項

- prompt / response を保存しない
- transcript / private log を読む処理を追加しない
- raw session id を保存しない
- raw path を保存しない
- 外部送信、telemetry、analytics を追加しない
