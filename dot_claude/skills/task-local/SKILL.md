---
name: task-local
description: ローカルタスクファイルによるタスク管理。タスクの実行・追加・一覧表示を行う。Triggers on "/task-local", "タスク実行", "次のタスク" or similar.
argument-hint: [<id> | add <description>]
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task, AskUserQuestion, EnterPlanMode
---

# Task Local - ローカルタスク管理スキル

プロジェクトルートの `tasks.local/` ディレクトリにあるMarkdownファイルでタスクを管理し、実行する。

## タスクファイル形式

ファイル名: `<id>-<title>.md` (例: `001-setup-auth.md`)

テンプレート: `templates/task.template.md`

`started_at` / `completed_at` は ISO 8601 datetime 文字列（例: `2026-03-02T13:03:33Z`）。

## コマンド

- `/task-local` — 次に実行可能なタスクを自動選択して実行
- `/task-local <id>` — 指定IDのタスクを実行
- `/task-local add <description>` — 新しいタスクを追加（対話で詳細を詰める）
- `/task-local add --simple <description>` — 新しいタスクを簡易追加（計画モードを使わない）

## 引数の解析

`$ARGUMENTS` を以下のルールで解析する:

1. **空の場合**: 次に実行可能なタスクを自動選択して実行（後述の「タスク自動選択」参照）
2. **`add` で始まる場合**: `add` 以降のテキストを説明として新しいタスクを追加（後述の「タスク追加」参照）
   - `--simple` フラグが含まれる場合は **簡易モード** で追加する（`--simple` を除いた残りを説明とする）
3. **数字の場合**: 該当IDのタスクを実行（後述の「タスク実行」参照）

---

## タスク自動選択

以下を `Bash` で実行して、着手可能なタスクIDを取得する。

```bash
CLAUDE_SESSION_ID="${CLAUDE_SESSION_ID:-}" ./scripts/next-task.sh
```

- exit 0: 出力されたIDのタスクを実行する
- exit 1: 着手可能なタスクなしとして終了する

---

## タスク追加

### 通常モードと簡易モード

- **通常モード**（`add <description>`）: Phase 1 → Phase 2 → Phase 3 → Phase 4 の全手順を実行する
- **簡易モード**（`add --simple <description>`）: Phase 1 → Phase 3 → Phase 4（簡易）を実行する。Phase 2（計画）をスキップする

### 手順

#### Phase 1: ドラフト作成（ID確保）

以下を `Bash` で実行する。

```bash
./scripts/create-draft-task.sh "<description>"
```

`id` / `title` / `path` の出力を後続フェーズで使う。

#### Phase 2: 計画（不明点の解消ループ）

> **簡易モードの場合はこの Phase をスキップし、Phase 3 へ進む。**

プランモードには入らず、通常の対話でタスクの計画を立てる。以下のループを不明点がなくなるまで繰り返す:

1. タスクの説明とコードベースの調査結果を基に、**不明瞭な点・意思決定が必要な点**をリストアップする
2. リストが空であれば Phase 3 へ進む
3. リストの各項目について、1つずつ `AskUserQuestion` でユーザーに質問する:
   - 各質問には選択肢を提示する
   - 可能であれば最低1つの選択肢に「(Recommended)」を付けて推奨を示す
4. 全ての質問が解消されたら、手順 1 に戻り、再度リストアップを試みる
   - 前回の回答を踏まえて新たな不明点が生じることがあるため

このループは **リストアップで不明点が1つも出なくなるまで** 繰り返す。

#### Phase 3: 依存タスクの探索

以下を `Bash` で実行して、`todo` / `in_progress` のタスク一覧を取得する。

```bash
./scripts/list-active-tasks.sh
./scripts/list-active-tasks.sh --tag auth --tag backend
```

- `--tag` は複数指定可能
- 複数指定時は OR 条件で検索する
- 一覧と本文抜粋を確認し、依存タスク候補を洗い出す

#### Phase 4: タスクファイルの確定

**通常モードの場合:**

1. 計画の結果をタスクファイルの本文に記載する
2. `AskUserQuestion` で以下を確認する:
   - タイトルと本文の内容が適切か
   - 依存タスク (`depends_on`) があるか
   - 検索に使うタグ (`tags`) を設定するか
3. タスクファイル本文を記載する
4. 以下を `Bash` で実行して、`depends_on` と `status: todo`（必要なら `tags`）を更新する:

```bash
./scripts/finalize-task-metadata.sh "<path>" --depends 001 --depends 004 --tag auth --tag backend
```

**簡易モードの場合:**

1. ユーザーの説明をそのままタスクファイルの本文に記載する
2. 以下を `Bash` で実行して、`depends_on` と `status: todo`（必要なら `tags`）を更新する:

```bash
./scripts/finalize-task-metadata.sh "<path>" --depends 001 --tag auth
```

ファイル名: `<id>-<title>.md`

作成後、ファイルパスと内容をユーザーに表示して終了する。

---

## タスク実行

### 前提確認

> タスク自動選択（`next-task.sh`）経由の場合、このステップはスキップする（スクリプトが確認済み）。

- 指定されたタスクの `status` が `todo` であることを確認する。`todo` でない場合はユーザーに状態を伝えて終了する。
- `depends_on` に未完了（`status` が `done` でない）タスクがある場合、その旨を伝えて終了する。

### 実行手順

#### Step 1: タスクの状態を更新

> タスク自動選択（`next-task.sh`）経由の場合、このステップはスキップする（スクリプトが設定済み）。

以下を `Bash` で実行する。

```bash
CLAUDE_SESSION_ID="${CLAUDE_SESSION_ID:-}" ./scripts/start-task.sh "<task-file-path>"
```

#### Step 2: Worktreeを作成

名前は `branch` フィールドの値から `/` を `-` に置換したものを使う。

#### Step 3: プランモード

`EnterPlanMode` を使ってタスクの実装計画を立てる。タスクファイルの本文を基に、コードベースを調査し、実装方針を検討する。

ユーザーがプランを承認するまで待つ。

プランファイルには次の内容を盛り込むこと。

```
# 完了後処理
- 実装が完了したら、`AskUserQuestion` でユーザーにタスク完了の承認を求める
- `TASK_LOCAL_MERGE_MODE` に基づいてマージ方法を決定する（`merge` または `pr`）
- タスクファイル更新（status, completed_at）
    - path: `<タスクファイルの絶対パス>` 
- worktreeの削除
```

#### Step 4: タスクの実装

承認されたプランに基づいてタスクを実装する。通常のコーディングフローに従う。

---

## 注意事項

- **言語**: ユーザーの入力言語に合わせて応答する
- **エラー時**: `tasks.local/` が存在しない、タスクファイルが見つからない等のエラーは明確にユーザーに伝える
- **安全性**: worktreeの作成・削除、ブランチ操作は慎重に行う
