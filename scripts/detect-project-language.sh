#!/bin/bash

# Script to detect project language and return appropriate standards path
# Usage: detect-project-language.sh
# Outputs: PROJECT_LANGUAGE|CODE_STANDARDS_PATH

# Detect project language and set appropriate standards path
PROJECT_LANGUAGE=""
CODE_STANDARDS_PATH=""

# Check for Java project
if [ -f "pom.xml" ] || [ -f "build.gradle" ] || [ -f "build.gradle.kts" ] || find . -name "*.java" -type f | head -1 | grep -q .; then
  PROJECT_LANGUAGE="Java"
  CODE_STANDARDS_PATH="/Users/ccasey/dotfiles/ai/guides/java/best-practices.md"
  echo "☕ Detected Java project - using Java best practices standards" >&2
# Check for JavaScript/TypeScript project
elif [ -f "package.json" ] || find . -name "*.js" -o -name "*.ts" -o -name "*.jsx" -o -name "*.tsx" -type f | head -1 | grep -q .; then
  PROJECT_LANGUAGE="JavaScript"
  CODE_STANDARDS_PATH="/Users/ccasey/dotfiles/ai/guides/javascript/best-practices.md"
  echo "🟨 Detected JavaScript/TypeScript project - using JavaScript best practices standards" >&2
else
  PROJECT_LANGUAGE="Unknown"
  CODE_STANDARDS_PATH=""
  echo "ℹ️  Could not detect project language - proceeding with general review" >&2
fi

# Output the results (pipe-separated for easy parsing)
echo "${PROJECT_LANGUAGE}|${CODE_STANDARDS_PATH}"