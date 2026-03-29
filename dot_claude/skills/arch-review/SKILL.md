---
name: arch-review
description: |
  Layered architecture reviewer. Reviews domain/application/infrastructure/presentation layer separation and internal rules.
  Triggers on "アーキテクチャレビュー", "arch review", "レイヤー分離チェック", "/arch-review".
user_invocable: true
argument-hint: "[review|init|sync]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Agent, AskUserQuestion
---

# Architecture Review Skill

Layered architecture (domain / application / infrastructure / presentation) のレビュー、設定ファイルの作成・更新を行うスキル。

## モード

引数に応じて3つのモードで動作する:

| 引数 | モード | 説明 |
|------|--------|------|
| (なし) / `review` | レビュー | アーキテクチャレビューを実行 |
| `init` | 初期設定 | 設定ファイルを新規作成 |
| `sync` | 同期 | 既存設定ファイルをディレクトリ構造と同期 |

---

## Mode: init

### 手順

1. 既存の設定ファイルがあるか確認（validate-config.jsを実行）
   - 既にある場合は「既に設定ファイルがあります。syncモードを使ってください」と案内して終了
2. プロジェクトのディレクトリ構造をスキャンする（`ls`, `Glob`でトップレベル構造を把握）
3. monorepoか単一プロジェクトか判定する
   - packages/, apps/, services/ 等のディレクトリがあればmonorepo候補
4. 各モジュール（またはプロジェクト全体）のレイヤーに該当するディレクトリを推定する
   - domain, application, infrastructure, presentation に該当しそうなディレクトリ名を探す
   - 一般的な別名も考慮: core→domain, usecase/service→application, adapter/external/gateway→infrastructure, controller/handler/api/web→presentation
5. AskUserQuestionで以下を確認:
   - 推定したレイヤーマッピングが正しいか
   - 出力設定（output配列）
6. 設定ファイルを生成する
   - 保存先: プロジェクトルートの `.arch-review.json`
   - AskUserQuestionで XDG_CONFIG_HOME に置くか確認してもよい

### 設定ファイルフォーマット

**フラット（単一プロジェクト）:**
```json
{
  "layers": {
    "domain": "src/domain",
    "application": "src/application",
    "infrastructure": "src/infrastructure",
    "presentation": "src/presentation"
  },
  "output": [
    { "type": "text" }
  ]
}
```

**monorepo:**
```json
{
  "modules": [
    {
      "name": "user-service",
      "root": "packages/user-service",
      "layers": {
        "domain": "src/domain",
        "application": "src/application",
        "infrastructure": "src/infrastructure",
        "presentation": "src/presentation"
      }
    }
  ],
  "output": [
    { "type": "file", "path": "review-result.md" }
  ]
}
```

**output の判別可能なユニオン型:**
- `{ "type": "file", "path": "<出力先パス>" }` — Markdownファイルに出力
- `{ "type": "text" }` — 会話内にテキスト出力
- `{ "type": "shell", "command": "<コマンド>" }` — レビュー結果をstdinに渡してシェルコマンド実行

---

## Mode: sync

### 手順

1. validate-config.jsを実行して既存設定を読み込む
   - 設定ファイルがない場合は「initモードで作成してください」と案内して終了
2. 現在のディレクトリ構造をスキャンする
3. 既存設定との差分を検出:
   - **追加**: 設定にないが存在する新しいモジュール/レイヤーディレクトリ
   - **変更**: パスが移動・リネームされたレイヤー
   - **削除**: 設定にあるが存在しないパス
4. 差分をAskUserQuestionで提示し、更新内容を確認
5. 確認後、設定ファイルを更新（Editツールで該当部分のみ変更）

---

## Mode: review（デフォルト）

### 手順

#### Step 1: 設定ファイルの検証

validate-config.js を実行して設定を取得する:

```bash
node ~/.claude/skills/arch-review/scripts/validate-config.js
```

**成功時（exit 0）**: stdoutにJSON出力。`config`と`mode`（flat/monorepo）を取得。

**失敗時**:
- exit 1（設定ファイルなし）: 「設定ファイルが見つかりません。`/arch-review init` で作成してください」と案内して終了
- exit 2（形式エラー）: stderrのエラー詳細を表示して終了

#### Step 2: レイヤーパスの実在確認

設定ファイルの各レイヤーパスが実際に存在するか確認する。
存在しないパスがあれば警告し、`/arch-review sync` を案内する。

#### Step 3: レビューターゲットの構築

**flatモード**: 1セットのレイヤーパス
**monorepoモード**: modules配列の各エントリ。パスはmodule.root + layers.xxx で解決。

#### Step 4: 5 subagent を並列起動

各ターゲット（flatなら1つ、monorepoならモジュール数分）に対して5つのagentを起動する。

**重要**: Agent toolの `subagent_type` ではなく、agentの `name` を使って起動する。各agentのプロンプトにレイヤーパスとプロジェクトルートを渡す。

各agentへのプロンプトテンプレート:

**arch-layer-separation:**
```
プロジェクトルート: {projectRoot}
レイヤー構成:
- domain: {domainPath}
- application: {applicationPath}
- infrastructure: {infrastructurePath}
- presentation: {presentationPath}

このプロジェクトのレイヤー分離をレビューしてください。依存方向の違反と配置ミスを検出してください。
結果はJSON配列で返してください。
```

**arch-domain-review:**
```
プロジェクトルート: {projectRoot}
ドメイン層パス: {domainPath}

このドメイン層をレビューしてください。集約、エンティティ、値オブジェクト、リポジトリ、ドメインサービス、ドメインイベントのルール遵守を確認してください。
特にリポジトリがsave/get程度に留まっているか（スマートリポジトリ禁止）を重点的にチェックしてください。
結果はJSON配列で返してください。
```

**arch-application-review:**
```
プロジェクトルート: {projectRoot}
アプリケーション層パス: {applicationPath}
ドメイン層パス: {domainPath}

このアプリケーション層をレビューしてください。オーケストレーションに徹しているか、業務ルールが漏出していないか、権限制御、ポート定義の適切性を確認してください。
結果はJSON配列で返してください。
```

**arch-infrastructure-review:**
```
プロジェクトルート: {projectRoot}
インフラストラクチャ層パス: {infrastructurePath}
ドメイン層パス: {domainPath}
アプリケーション層パス: {applicationPath}

このインフラストラクチャ層をレビューしてください。Adapter↔ポート対応、ドメイン知識混入禁止、外部ドライバの配置を確認してください。
結果はJSON配列で返してください。
```

**arch-presentation-review:**
```
プロジェクトルート: {projectRoot}
プレゼンテーション層パス: {presentationPath}
アプリケーション層パス: {applicationPath}

このプレゼンテーション層をレビューしてください。入力バリデーション、薄いController、DTO変換、エラーハンドリングを確認してください。
結果はJSON配列で返してください。
```

monorepoの場合、各モジュール名をプロンプトに含め、findingsのファイルパスがモジュール相対になるようにする。

#### Step 5: 結果の集約

各agentから返されたJSON配列を集約する。agentの出力テキストからJSON配列を抽出する（```json ... ``` ブロックまたはトップレベルの配列）。

集約後、severity順にソートする: critical > high > medium > low

#### Step 6: 出力

設定ファイルの `output` 配列を順に処理する:

**{ "type": "text" }:**
会話内にMarkdown形式で出力:

```markdown
# Architecture Review Result

## Summary
- 🔴 Critical: N件
- 🟠 High: N件
- 🟡 Medium: N件
- 🔵 Low: N件

## Findings

### 🔴 Critical

#### [rule名] file/path:line
message

**Suggestion:** suggestion

---
(繰り返し)
```

**{ "type": "file", "path": "..." }:**
上記と同じMarkdownフォーマットをWriteツールでファイルに出力する。

**{ "type": "shell", "command": "..." }:**
集約したJSON結果全体をstdinに渡してコマンドを実行する:

```bash
echo '<json_result>' | <command>
```

monorepoの場合、モジュール名ごとにセクションを分けて出力する。
