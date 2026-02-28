---
name: task-local
description: ローカルタスクファイルによるタスク管理。タスクの実行・追加・一覧表示を行う。Triggers on "/task-local", "タスク実行", "次のタスク" or similar.
argument-hint: [<id> | ls | add <description>]
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task, AskUserQuestion, EnterPlanMode
---

# Task Local - ローカルタスク管理スキル

プロジェクトルートの `tasks.local/` ディレクトリにあるMarkdownファイルでタスクを管理し、実行する。

## タスクファイル形式

ファイル名: `<id>-<title>.md` (例: `001-setup-auth.md`)

```md
---
id: "001"
title: タスクのタイトル
status: todo|in_progress|done
session_id:
branch:
depends_on: []
completed_date:
---

タスクの本文（実行内容の詳細）
```

## コマンド

- `/task-local` — 次に実行可能なタスクを自動選択して実行
- `/task-local <id>` — 指定IDのタスクを実行
- `/task-local add <description>` — 新しいタスクを追加
- `/task-local ls` — 全タスクの一覧を表示

## 引数の解析

`$ARGUMENTS` を以下のルールで解析する:

1. **空の場合**: 次に実行可能なタスクを自動選択して実行（後述の「タスク自動選択」参照）
2. **`ls` の場合**: 全タスクの一覧を表示（後述の「タスク一覧」参照）
3. **`add` で始まる場合**: `add` 以降のテキストを説明として新しいタスクを追加（後述の「タスク追加」参照）
4. **数字の場合**: 該当IDのタスクを実行（後述の「タスク実行」参照）

---

## タスク一覧

このスキルの `scripts/list-tasks.sh` を `Bash` で実行し、出力されたMarkdownテーブルをそのままユーザーに表示する。

タスクが1件も存在しない場合は「タスクがありません」と表示する。

---

## タスク自動選択

このスキルの `scripts/next-task.sh` を `Bash` で実行し、着手可能なタスクIDを取得する。
実行時に環境変数 `CLAUDE_SESSION_ID` を渡すこと。スクリプトはタスクの `status` を `in_progress` に、`session_id` と `branch` を設定する。

- 正常終了（exit 0）: 出力されたIDのタスクを「タスク実行」フローで実行する（Step 1 はスキップ）
- 異常終了（exit 1）: 着手可能なタスクがない旨をユーザーに伝えて終了する

---

## タスク追加

### 手順

1. `tasks.local/` ディレクトリが存在しない場合は作成する
2. 既存タスクファイルを走査し、最大IDを取得する。タスクが存在しない場合は `000` を最大IDとする
3. 新しいID = 最大ID + 1（ゼロ埋め3桁）
4. ユーザーの説明から適切な `title` を決定する（英語のkebab-case、簡潔に）
5. `AskUserQuestion` で以下を確認する:
   - タイトルと本文の内容が適切か
   - 依存タスク (`depends_on`) があるか
6. 「タスクファイル形式」に従ってタスクファイルを作成する（`status: todo`、他のメタデータは空）

ファイル名: `<id>-<title>.md`

作成後、ファイルパスと内容をユーザーに表示して終了する。

---

## タスク実行

### 前提確認

> **注意**: タスク自動選択（`next-task.sh`）経由の場合、このステップはスキップする（スクリプトが確認済み）。

- 指定されたタスクの `status` が `todo` であることを確認する。`todo` でない場合はユーザーに状態を伝えて終了する。
- `depends_on` に未完了（`status` が `done` でない）タスクがある場合、その旨を伝えて終了する。

### 実行手順

#### Step 1: タスクの状態を更新

> **注意**: タスク自動選択（`next-task.sh`）経由の場合、このステップはスキップする（スクリプトが設定済み）。

タスクファイルのfrontmatterを更新する:

- `status` を `in_progress` に変更
- `session_id` に `${CLAUDE_SESSION_ID}` を設定
- `branch` にブランチ名を設定（形式: `task/<id>-<title>`）

#### Step 2: Worktreeを作成

名前は `branch` フィールドの値から `/` を `-` に置換したものを使う。

#### Step 3: プランモード

`EnterPlanMode` を使ってタスクの実装計画を立てる。タスクファイルの本文を基に、コードベースを調査し、実装方針を検討する。

ユーザーがプランを承認するまで待つ。

#### Step 4: タスクの実装

承認されたプランに基づいてタスクを実装する。通常のコーディングフローに従う。

**注意** 以降のStepはプランファイルに盛り込むこと。Step 7 のタスク完了更新にはタスクファイルの絶対パスを記載すること。

#### Step 5: 完了確認

実装が完了したら、`AskUserQuestion` でユーザーにタスク完了の承認を求める:

- 変更内容のサマリーを提示する
- 「タスクを完了としてマークしてよいか？」と確認する

ユーザーが承認しない場合は、フィードバックに基づいて修正を行い、再度確認する。

> **注意**: `TASK_LOCAL_MODE=auto` の場合、完了確認をスキップし、そのまま次のステップに進む。

#### Step 6: Worktreeの後処理

環境変数 `TASK_LOCAL_MERGE_MODE` に基づいてワークフローを切り替える。

> **注意**: `TASK_LOCAL_MODE=auto` の場合、マージおよびworktree削除のユーザー確認は不要。確認なしで自動的に実行する。

- `pr` — PRを作成する
- `merge`（デフォルト） — mainに直接マージする

##### `TASK_LOCAL_MERGE_MODE=merge`（デフォルト）

1. 変更をコミットし、mainブランチにマージする（ユーザーの指示に従う）
2. worktreeを削除する
3. mainブランチを最新にする

##### `TASK_LOCAL_MERGE_MODE=pr`

1. 変更をコミットし、リモートにプッシュする
2. `gh pr create` でPRを作成する（タイトルはタスクのtitle、本文は変更サマリー）
3. worktreeを削除する
4. PRのURLをユーザーに表示する

#### Step 7: タスクの完了

> **重要**: このステップは必ず実行すること。マージやworktree削除が完了しても、タスクファイルの更新を忘れないこと。

タスクファイルのfrontmatterを更新する:

- `status` を `done` に変更
- `completed_date` に今日の日付を設定（`yyyy-mm-dd` 形式）

完了した旨をユーザーに報告する。

---

## 注意事項

- **言語**: ユーザーの入力言語に合わせて応答する
- **エラー時**: `tasks.local/` が存在しない、タスクファイルが見つからない等のエラーは明確にユーザーに伝える
- **安全性**: worktreeの作成・削除、ブランチ操作は慎重に行い、ユーザーの確認を得る（`TASK_LOCAL_MODE=auto` の場合はマージ・worktree削除の確認を省略）
