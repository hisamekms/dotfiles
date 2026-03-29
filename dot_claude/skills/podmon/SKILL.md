---
name: podmon
description: podmon（Podmanリソースモニター）の状況確認と問題への対応提案。「podmonどう？」「podmanの状態」「コンテナの調子は？」「podmon確認」などでトリガー。
allowed-tools: Bash, Read, Grep, Glob, AskUserQuestion
---

# podmon Status Check & Troubleshooting Skill

podmonのログとPodman環境の現在の状態を確認し、問題があれば対応策を提案する。

## podmonの概要

podmonは60秒間隔で実行されるLaunchAgentベースのPodmanリソースモニター。

- **スクリプト**: `~/.local/bin/podmon`
- **LaunchAgent**: `~/Library/LaunchAgents/dev.podmon.plist`
- **設定**: `~/.config/podmon/config`
- **ログ**: `~/.local/state/podmon/podmon.log`
- **クールダウン状態**: `~/.local/state/podmon/cooldown_*`

### 監視項目と閾値（デフォルト）

| 項目 | 閾値 | 内容 |
|------|------|------|
| Memory | 70% | 全コンテナ合計のメモリ使用率（マシン割当比） |
| CPU | 80% x コア数 | 全コンテナ合計のCPU使用率 |
| Disk | 80% | podman machineのディスク使用率（graphRoot） |
| Containers | - | exitedコンテナの存在 |

## ワークフロー

### Step 1: サービス状態の確認

以下を並列で実行する:

1. `launchctl list | grep podmon` — サービスのロード状態と終了コードを確認
2. `tail -30 ~/.local/state/podmon/podmon.log` — 直近のログを確認
3. `cat ~/.config/podmon/config` — 現在の閾値設定を確認

### Step 2: 現在のPodman状態をリアルタイム確認

ログの情報を補完するため、以下を並列で実行する:

1. `podman ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Size}}'` — 全コンテナの状態
2. `podman stats --no-stream --format 'table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}'` — リソース使用状況
3. `podman system info --format '{{.Store.GraphRootAllocated}} {{.Store.GraphRootUsed}} {{.Host.MemTotal}} {{.Host.CPUs}}'` — マシンリソース割当

### Step 3: ステータスサマリを提示

以下の形式でユーザーに報告する:

```
## podmon ステータス

**サービス**: [Running/Not loaded/Error]
**最終実行**: [timestamp]

| 項目 | 現在値 | 閾値 | 状態 |
|------|--------|------|------|
| Memory | XX% (X.XGB / X.XGB) | 70% | OK/ALERT |
| CPU | XX% / XX% | 80% x Ncores | OK/ALERT |
| Disk | XX% (X.XGB / X.XGB) | 80% | OK/ALERT |
| Containers | N running, N exited | - | OK/ALERT |
```

### Step 4: 問題の検出と対応提案

以下の問題を検出したら、具体的な対応コマンドを提案する:

#### サービスが停止している場合
- `launchctl load ~/Library/LaunchAgents/dev.podmon.plist` を提案

#### Memory ALERT
- `podman stats --no-stream` でどのコンテナがメモリを消費しているか特定
- コンテナの再起動やメモリ制限の設定を提案

#### CPU ALERT
- `podman stats --no-stream` でCPU消費の大きいコンテナを特定
- CPU制限の設定やコンテナの再起動を提案

#### Disk ALERT
- `podman system df` で何がディスクを消費しているか確認
- `podman system prune` や `podman image prune -a` を提案
- 不要なボリュームがあれば `podman volume prune` を提案

#### Exited Containers
- exitedコンテナの一覧と停止理由を確認
- 意図しない停止なら `podman logs <container>` でログ確認を提案
- 不要なら `podman container prune` を提案

#### ログにエラーがある場合
- `podman not found in PATH` → PATHの問題を調査
- `podman machine is not running` → `podman machine start` を提案

### Step 5: 対応の実行

ユーザーが対応を承認したら、コマンドを実行する。
破壊的な操作（prune、rm等）は実行前に必ずユーザーに確認すること。
