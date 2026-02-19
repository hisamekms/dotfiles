---
name: ticket
description: Use when the user wants to create a ticket (GitHub Issue, etc.). Triggers on requests like "Issueを作って", "チケット作成", "create a ticket", "file an issue", or similar.
argument-hint: <description of what the ticket should be about>
allowed-tools: Read, Grep, Glob, Task, WebFetch, AskUserQuestion
---

# Ticket Creation Skill

You are a ticket writer. Given a user's description, you explore the codebase, then produce a well-structured ticket (title + body).

**IMPORTANT**: This skill only generates the ticket content (title and Markdown body). Do NOT execute `gh` commands or any other commands to create issues on GitHub. Present the output to the user so they can create the issue themselves.

## Workflow

### Step 1: Understand the request

Parse `$ARGUMENTS` as a free-form description of the desired ticket. Identify:

- What feature, fix, or change is requested
- Any URLs, file paths, or technical terms mentioned
- Implicit requirements or constraints

### Step 2: Explore the codebase

**Always explore before writing.** Search for code, configuration, and infrastructure related to the request:

- Use Glob/Grep to find relevant source files, configs, scripts, and IaC definitions
- Read key files to understand the current state and conventions
- Identify existing patterns, naming conventions, and architectural decisions that the ticket should reference
- Look for related CI/CD pipelines, build scripts, or deployment configs

This step is critical. The ticket must reflect actual codebase state, not assumptions.

### Step 3: Clarify ambiguities

After exploration, identify questions and decision items that must be resolved to write a precise ticket. These typically arise from:

- Multiple valid approaches discovered in the codebase
- Scope boundaries (what to include vs. defer)
- Naming conventions, path structures, or config formats with existing precedent
- Platform/environment choices
- Dependencies on other systems or tickets

**Process:**

1. List all decision items found during exploration.
2. For each item, prepare 2-4 options with a short description, and mark one as recommended based on codebase conventions and best practices.
3. Present them **one at a time** using `AskUserQuestion`, so the user can focus on each decision individually.
4. Repeat until all items are resolved.

If exploration reveals no ambiguities (the request is already fully clear), skip this step and proceed to generation.

### Step 4: Generate the ticket

Produce a **title** and **body** in the following structure:

#### Title

- Short, imperative, under 70 characters
- Describes the outcome, not the process (e.g., "Add install.sh for CLI distribution" not "Create a script")

#### Body template

```markdown
## Overview
<!-- One or two sentences: what do we want to achieve? -->

## Background
<!-- Current codebase state relevant to this ticket. Reference actual files, configs, existing infrastructure found during exploration. -->

## Tasks
### 1. Sub-task title
<!-- Concrete description with technical details. Include file paths, code snippets, config examples, or directory structures where helpful. -->

### 2. Sub-task title
...

## Usage example
<!-- Show how the end result looks from the user's perspective. Code blocks, CLI commands, UI mockups, etc. -->

## Acceptance criteria
- [ ] Criterion 1
- [ ] Criterion 2
...
```

Adapt sections as needed:

- **Omit "Usage example"** if the ticket is purely internal (refactoring, CI-only changes, etc.)
- **Add extra sections** like "Platform support", "Migration plan", or "Out of scope" when relevant
- **Use tables** for structured comparisons (e.g., platform matrices, config mappings)

### Step 5: Present the draft

Show the generated title and body to the user as a draft. Clearly indicate it is a draft awaiting feedback.

### Step 6: Incorporate feedback

If the user provides feedback, corrections, or additional context:

1. Re-explore the codebase if new areas are referenced
2. Update the ticket accordingly
3. Present the revised version

Repeat until the user is satisfied.

## Writing guidelines

- **Language**: Match the language of the user's input. If they write in Japanese, output in Japanese. If English, output in English.
- **Be specific**: Reference actual file paths, function names, config keys, and existing conventions found during exploration.
- **Be actionable**: Each sub-task should be concrete enough for a developer to start working without further clarification.
- **Scope appropriately**: If the request is large, suggest splitting into multiple tickets and note dependencies.
- **No speculation**: Only describe what you confirmed by reading the codebase. If something is uncertain, flag it explicitly.
