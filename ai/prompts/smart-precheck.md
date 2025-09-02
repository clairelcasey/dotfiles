---
description: Intelligent code review that ensures appropriate standards exist before reviewing. Auto-detects Java projects and suggests generating standards when needed.
argument-hint: [code-standards-path]
allowed-tools: Bash(find:*), Bash(ls:*), Bash(stat:*), Bash(date:*), Bash(echo:*), Bash(grep:*), Bash(basename:*), Task, Read
---

# 🔍 Smart Precheck Workflow

Intelligent orchestration of code review that:
- Auto-detects project type (Java vs other)
- Checks for existing code standards
- Suggests appropriate next steps
- Runs comprehensive review with best available standards

---

## Step 1: Project Type Detection

**🔍 Detecting project characteristics:**
```bash
echo "🔍 Analyzing project type..."

# Check for Java project indicators
IS_JAVA_PROJECT=false
if [ -f "pom.xml" ] || [ -f "build.gradle" ] || [ -f "build.gradle.kts" ] || [ -n "$(find . -name "*.java" -type f | head -1)" ]; then
  IS_JAVA_PROJECT=true
  echo "☕ Java project detected"
  
  # Identify build system
  if [ -f "pom.xml" ]; then
    echo "🔧 Build system: Maven"
  elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
    echo "🔧 Build system: Gradle"
  else
    echo "🔧 Build system: Java files found"
  fi
else
  echo "📝 Non-Java project detected"
fi

echo "Project type: $([ "$IS_JAVA_PROJECT" = "true" ] && echo "Java" || echo "General")"
echo ""
```

## Step 2: Code Standards Discovery

**📋 Searching for existing code standards:**
```bash
echo "📋 Checking for existing code standards..."

# Search for standards (docs first, then tmp)
CODE_STANDARDS_PATH="$1"

if [ -z "$CODE_STANDARDS_PATH" ]; then
  # Look for persistent standards in docs/ first (preferred)
  CODE_STANDARDS_PATH=$(find ./docs -name "*style*" -o -name "*standard*" -o -name "*guideline*" | grep -i "\.md$" | head -1 2>/dev/null)
  
  if [ -n "$CODE_STANDARDS_PATH" ]; then
    echo "📚 Found persistent standards: $CODE_STANDARDS_PATH"
    STANDARDS_SOURCE="docs"
  else
    # Look for recent analysis in tmp/
    CODE_STANDARDS_PATH=$(ls -t ./tmp/java-style-MERGED-*.md 2>/dev/null | head -1)
    
    if [ -n "$CODE_STANDARDS_PATH" ]; then
      echo "🔄 Found recent analysis: $CODE_STANDARDS_PATH"
      STANDARDS_SOURCE="tmp"
    else
      # Look for any java-style analysis
      CODE_STANDARDS_PATH=$(ls -t ./tmp/java-style-*.md 2>/dev/null | head -1)
      
      if [ -n "$CODE_STANDARDS_PATH" ]; then
        echo "📄 Found code analysis: $CODE_STANDARDS_PATH"
        STANDARDS_SOURCE="tmp"
      else
        echo "❌ No code standards found"
        CODE_STANDARDS_PATH=""
        STANDARDS_SOURCE="none"
      fi
    fi
  fi
else
  echo "📋 Using provided standards: $CODE_STANDARDS_PATH"
  STANDARDS_SOURCE="provided"
fi

echo ""
```

## Step 3: Standards Freshness Check

**⏰ Checking standards age:**
```bash
if [ -n "$CODE_STANDARDS_PATH" ] && [ -f "$CODE_STANDARDS_PATH" ]; then
  echo "⏰ Checking standards freshness..."
  
  # Get file modification time
  if command -v stat >/dev/null 2>&1; then
    # Check if we're on macOS or Linux
    if [[ "$OSTYPE" == "darwin"* ]]; then
      FILE_TIME=$(stat -f %m "$CODE_STANDARDS_PATH" 2>/dev/null)
    else
      FILE_TIME=$(stat -c %Y "$CODE_STANDARDS_PATH" 2>/dev/null)
    fi
    
    if [ -n "$FILE_TIME" ]; then
      CURRENT_TIME=$(date +%s)
      AGE_SECONDS=$((CURRENT_TIME - FILE_TIME))
      AGE_DAYS=$((AGE_SECONDS / 86400))
      
      echo "📅 Standards age: $AGE_DAYS days old"
      
      # Consider standards stale after 7 days
      if [ $AGE_DAYS -gt 7 ]; then
        STANDARDS_STALE=true
        echo "⚠️  Standards are getting stale (>7 days old)"
      else
        STANDARDS_STALE=false
        echo "✅ Standards are fresh (<7 days old)"
      fi
    else
      echo "❓ Could not determine file age"
      STANDARDS_STALE=false
    fi
  else
    echo "❓ stat command not available - assuming standards are fresh"
    STANDARDS_STALE=false
  fi
else
  STANDARDS_STALE=false
fi

echo ""
```

## Step 4: Decision Tree & Action

**🎯 Determining appropriate action:**
```bash
echo "🎯 Determining next steps..."

if [ "$IS_JAVA_PROJECT" = "true" ] && { [ "$STANDARDS_SOURCE" = "none" ] || [ "$STANDARDS_STALE" = "true" ]; }; then
  # Java project without fresh standards
  echo ""
  echo "🔍 Java project detected without fresh code standards"
  echo ""
  echo "📋 Recommended workflow:"
  echo "   1. Run: @ai/prompts/java-style-compare.md"
  echo "      → This generates comprehensive Java standards for your project"
  echo ""
  echo "   2. Then run: @ai/prompts/smart-precheck.md"
  echo "      → This will perform standards-aware code review"
  echo ""
  echo "💡 Alternative: Run @ai/subagents/precheck-reviewer for general review now"
  echo ""
  
  if [ "$STANDARDS_STALE" = "true" ]; then
    echo "⚠️  Note: Found stale standards ($AGE_DAYS days old): $CODE_STANDARDS_PATH"
    echo "   Consider refreshing for most accurate review"
  fi
  
  exit 0
else
  # Either non-Java project or has fresh standards
  echo "✅ Proceeding with comprehensive code review"
  
  if [ -n "$CODE_STANDARDS_PATH" ]; then
    echo "📋 Using standards: $CODE_STANDARDS_PATH ($STANDARDS_SOURCE)"
    REVIEWER_ARGS="$CODE_STANDARDS_PATH"
  else
    echo "📋 Performing general review (no standards available)"
    REVIEWER_ARGS=""
  fi
  
  echo ""
  echo "🔄 Launching precheck-reviewer..."
  echo ""
fi
```

## Step 5: Execute Code Review

Now I'll invoke the precheck-reviewer subagent to perform the comprehensive code review.

**Task Context:**
- Repository: Current working directory  
- Project type: $([ "$IS_JAVA_PROJECT" = "true" ] && echo "Java" || echo "General")
- Standards available: $([ -n "$CODE_STANDARDS_PATH" ] && echo "Yes ($STANDARDS_SOURCE)" || echo "No")
- Standards path: $CODE_STANDARDS_PATH

**Invoking precheck-reviewer with Task tool...**

The precheck-reviewer will:
1. Perform full diff analysis against default branch
2. Run build and tests  
3. Check code standards compliance (if standards available)
4. Generate detailed review report in ./tmp/
5. Flag any quality, test-coverage, or documentation issues
6. Provide actionable recommendations

**After completion, you'll receive:**
- Detailed code review report location
- Summary of findings and recommendations
- Information about standards compliance (if applicable)