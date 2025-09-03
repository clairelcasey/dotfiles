---
description: Comprehensive Java style analysis workflow - scanner + AI analysis + comparison + examples, with timestamped output for backend developers.
argument-hint: [repo-path]
allowed-tools:
  - "Bash(bash:*)"
  - "Bash(cat:*)"
  - "Bash(jq:*)"
  - "Bash(date:*)"
  - "Bash(git status:*)"
  - "Bash(git rev-parse:*)"
  - "Bash(echo:*)"
  - "Bash(grep:*)"
  - "Bash(basename:*)"
  - "Bash(mkdir:*)"
  - "Write(./tmp/java-style-*)"
# Optionally pin a model:
# model: claude-3-5-sonnet-latest
---

## Context (auto-collected)

- Repo root (if provided): $1
- Current branch: !`git rev-parse --abbrev-ref HEAD || true`
- Git status (short): !`git status -s || true`

## Step 0 — Setup & Repository Confirmation

```bash
# Setup tmp directory and git exclusion
mkdir -p ./tmp
if [ -f .git/info/exclude ]; then
  if ! grep -q "^tmp/$\|^tmp/\*\|^/tmp/\|^tmp$" .git/info/exclude; then
    echo "tmp/" >> .git/info/exclude
  fi
else
  mkdir -p .git/info
  echo "tmp/" > .git/info/exclude
fi

# Repository analysis
repo_path="${1:-$(pwd)}"
echo "Repository: $repo_path"
echo "Repository name: $(basename "$repo_path")"
if [ -f "$repo_path/pom.xml" ]; then
  echo "Build system: Maven"
  grep -o '<artifactId>[^<]*</artifactId>' "$repo_path/pom.xml" | head -1 | sed 's/<[^>]*>//g' | xargs -I {} echo "Artifact: {}"
elif [ -f "$repo_path/build.gradle" ] || [ -f "$repo_path/build.gradle.kts" ]; then
  echo "Build system: Gradle"
elif [ -f "$repo_path/BUILD.bazel" ]; then
  echo "Build system: Bazel"
fi
echo ""
echo "Repository confirmed. To analyze a different repository, re-run with: @ai/prompts/java-style-compare.md /path/to/repo"
echo ""
```

## Step 1 — Run the Enhanced Scanner

```bash
# Generate timestamp and run scanner
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SCANNER_OUTPUT="./tmp/java-scan-${TIMESTAMP}.md"
/Users/ccasey/dotfiles/scripts/java-scan-style.sh --root ${1:-.} --out "$SCANNER_OUTPUT" || true
echo "Scanner output: $SCANNER_OUTPUT"

# Scanner summary
echo "=== SCANNER SUMMARY ==="
grep "^Detected areas:" "$SCANNER_OUTPUT" || echo "No summary found"
echo "=== TOP PATTERNS ==="
grep -A 1 "\*\*.*\*\* — .*hits" "$SCANNER_OUTPUT" | head -20 || echo "No patterns found"

# Full output for AI analysis
/bin/cat "$SCANNER_OUTPUT" | head -c 300000 || echo "Scanner output not found"
```

## Step 2 — AI-Enhanced Style Guide Generation

Use the `java-style-writer` subagent to produce a comprehensive style guide for repository: ${1:-.}

The subagent will create a guide covering framework analysis, code examples, testing strategy, database patterns, async best practices, anti-patterns, and PR checklist items.

Output saved to: `./tmp/java-style-ai-${TIMESTAMP}.md`

## Step 3 — Analysis & Comparison

### A. Coverage Analysis

**Framework Coverage:**
- Scanner detected: [list frameworks found by scanner]
- AI documented: [frameworks covered in AI guide]
- Gaps: [any important patterns missed by either]

**Pattern Completeness:**
- Quantitative: Scanner found X patterns across Y categories
- Qualitative: AI guide provides context for Z% of detected patterns
- Examples: AI guide includes concrete examples for [list categories]

**Database Analysis:**
- Database Technology: [JDBI/JPA/Plain JDBC identified]
- Transaction Patterns: [Transaction boundary analysis]
- Connection Pooling: [HikariCP configuration review]
- Query Patterns: [SQL best practices and anti-patterns]
- Database Testing: [Testcontainers and migration testing]

### B. Quality Assessment

**New Developer Readiness:**
- Has concrete code examples with file references
- Explains "why" behind each recommendation
- Provides actionable PR checklist
- Covers Spotify-specific patterns (Apollo, Dagger, etc.)
- Includes visual aids (tables and diagrams)
- Documents database patterns and transaction boundaries
- Provides connection pool configuration guidance

**Gaps to Address:**
- [List any areas where more examples would help]
- [Note any detected patterns lacking explanation]
- [Suggest additional context for complex patterns]

## Step 4 — Create Unified Developer Guide

Combine the best of both approaches into a comprehensive guide with enhanced visual elements:

### Structure for Merged Guide:
```markdown
# Java Style Guide: [Repository Name] - MERGED ANALYSIS

## Repository Analysis Summary
[Key metrics from scanner with comparison table]

##  Architecture Overview
[Framework analysis with Mermaid architecture diagram]

##  Developer Quick Start
[Essential patterns with examples]

##  Pattern Comparison Table
[Side-by-side comparison: Scanner vs AI Analysis]

##  Code Examples by Category
[Frameworks, Testing, Database, Async, etc. with pass/fail examples]

##  Database & Transaction Patterns
[JDBI usage, transaction boundaries, connection pooling, SQL best practices]

##  Visual Architecture Diagrams
[Mermaid diagrams showing service dependencies, transaction flows, and connection pools]

##  Common Anti-patterns
[File:line examples with fixes]

##  PR Review Checklist
[Actionable items for code reviews]

##  Additional Resources
[Links to internal docs, Apollo guides, etc.]
```

### Save Final Output

```bash
# Create final merged output
REPO_NAME=$(basename "$(pwd)")
MERGED_OUTPUT="./tmp/java-style-MERGED-${REPO_NAME}-${TIMESTAMP}.md"

echo "Final merged guide saved to: $MERGED_OUTPUT"
echo "Summary of outputs:"
echo "  1. Scanner: $SCANNER_OUTPUT"
echo "  2. AI Guide: ./tmp/java-style-ai-${TIMESTAMP}.md"
echo "  3. Merged: $MERGED_OUTPUT"
```
