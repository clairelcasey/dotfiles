#!/usr/bin/env bash
# Java service style scanner — pure Bash/grep
# Writes a repo-specific style guide draft to /tmp/java-service-style.md
# Optional: set OUT=/custom/path.md
# Compatible with bash 3.2+ (macOS default)
#
# Usage:
#   bash java_style_scan.sh [--root PATH] [--out /tmp/java-service-style.md]
# Examples:
#   bash java_style_scan.sh --root . --out /tmp/java-service-style.md

set -euo pipefail

# Check for bash 4+ for better features but don't require it
BASH_MAJOR="${BASH_VERSINFO[0]:-3}"
USE_ENHANCED="false"
if [[ "$BASH_MAJOR" -ge 4 ]]; then
  USE_ENHANCED="true"
fi

ROOT="."
# Generate timestamp for output file
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUT="${OUT:-./tmp/java-scan-${TIMESTAMP}.md}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root) ROOT="$2"; shift 2;;
    --out) OUT="$2"; shift 2;;
    *) echo "Unknown arg: $1" >&2; exit 2;;
  esac
done

if ! command -v awk >/dev/null 2>&1; then
  echo "awk is required" >&2; exit 1
fi

# Prefer ripgrep if available
if command -v rg >/dev/null 2>&1; then
  SEARCHER="rg"
  SRCH_FLAGS=(-n --no-heading --hidden --follow)
else
  SEARCHER="grep"
  SRCH_FLAGS=(-R -n --line-number --no-color)
fi

# File globs / extensions to include
EXT_REGEX='(\.java|\.kt|\.xml|\.yml|\.yaml|\.properties|\.gradle|\.kts|\.toml)$'

# Declare patterns (extended regex)
# group:key=pattern
declare -a PATTERNS=(
  # Frameworks & DI
  "Frameworks & Dependency Injection:spring_boot=@SpringBootApplication|spring-boot[-.]"
  "Frameworks & Dependency Injection:micronaut=@MicronautTest|io\\.micronaut"
  "Frameworks & Dependency Injection:dropwizard=io\\.dropwizard|DropwizardAppRule"
  "Frameworks & Dependency Injection:component=@(Component|Service|Repository|Controller|RestController)\\b"
  "Frameworks & Dependency Injection:di_autowired=@(Autowired|Inject)\\b"
  "Frameworks & Dependency Injection:di_constructor=public\\s+\\w+\\s*\\([^\\{;]*@(Autowired|Inject)?[^\\{;]*\\)\\s*\\{"
  "Frameworks & Dependency Injection:di_field=@(Autowired|Inject)\\s+private"
  "Frameworks & Dependency Injection:configuration_props=@ConfigurationProperties|application\\.ya?ml|application\\.properties"
  # Apollo Framework (Spotify)
  "Frameworks & Dependency Injection:apollo=com\\.spotify\\.apollo|@Route\\b|AppInit|Application\\.start"
  "Frameworks & Dependency Injection:apollo_config=com\\.spotify\\.apollo\\.Environment|apollo\\.config"
  # Dagger DI (common at Spotify)
  "Frameworks & Dependency Injection:dagger=@(Module|Component|Provides|Binds)\\b|com\\.google\\.dagger"
  "Frameworks & Dependency Injection:di_inject=@Inject\\b"

  # Testing
  "Testing:junit5=org\\.junit\\.jupiter|@TestFactory|@ParameterizedTest"
  "Testing:junit4=org\\.junit\\.|@RunWith\\b"
  "Testing:testng=org\\.testng|@Test\\b"
  "Testing:mockito=org\\.mockito|Mockito|@Mock|@ExtendWith\\(MockitoExtension"
  "Testing:testcontainers=org\\.testcontainers|@Testcontainers"
  "Testing:springboottest=@SpringBootTest\\b"
  "Testing:archunit=com\\.tngtech\\.archunit"

  # Async & Concurrency
  "Async & Concurrency:async=CompletableFuture<|ExecutorService|@Async\\b"
  "Async & Concurrency:cf_blocking=\\.get\\(\\)|\\.join\\(\\)"
  "Async & Concurrency:cf_composition=\\.thenCompose\\(|\\.thenCombine\\(|\\.thenApply\\(|\\.thenAccept\\("
  "Async & Concurrency:cf_error_handling=\\.exceptionally\\(|\\.handle\\("
  "Async & Concurrency:cf_executors=\\.thenApplyAsync\\(|\\.thenComposeAsync\\(|Executors\\."
  "Async & Concurrency:cf_completion_stage=CompletionStage<"
  "Async & Concurrency:reactor=reactor\\.core\\.publisher\\.(Mono|Flux)|\\bMono<|\\bFlux<"
  "Async & Concurrency:rxjava=io\\.reactivex|Observable<|Single<|Flowable<"
  "Async & Concurrency:timeouts=\\.timeout\\(|@Timeout|readTimeout|connectTimeout|orTimeout\\(|completeOnTimeout\\("
  "Async & Concurrency:resilience=resilience4j|\\bCircuitBreaker\\b|\\bRetry\\b|\\bBulkhead\\b"
  "Async & Concurrency:http_client=\\bWebClient\\b|\\bRestTemplate\\b|\\bHttpClient\\b|\\bOkHttpClient\\b"
  "Async & Concurrency:db_pool=HikariDataSource|HikariCP"

  # REST & Errors
  "REST, Validation & Errors:rest_mapping=@(Get|Post|Put|Delete|Patch)Mapping|@RequestMapping"
  "REST, Validation & Errors:controller_advice=@ControllerAdvice|@ExceptionHandler"
  "REST, Validation & Errors:validation=@(Valid|NotNull|Nullable|NotBlank|Size)\\b"
  "REST, Validation & Errors:jackson=com\\.fasterxml\\.jackson|@Json|ObjectMapper"
  "REST, Validation & Errors:problem_json=application\\/problem\\+json|problem-spring-web"

  # Observability
  "Observability & Logging:logging_slf4j=LoggerFactory|getLogger|@Slf4j"
  "Observability & Logging:micrometer=io\\.micrometer|MeterRegistry|@Timed\\b"
  "Observability & Logging:opentelemetry=io\\.opentelemetry|OpenTelemetry|\\bTracer\\b"
  "Observability & Logging:apollo_metrics=apollo-metrics|RequestMetrics"
  "Observability & Logging:spotify_metrics=com\\.spotify\\.contentcontrol\\.metric"

  # Build & Quality
  "Build, Config & Quality Gates:maven=<project\\b|<dependencyManagement>|<dependencies>"
  "Build, Config & Quality Gates:gradle=plugins\\s*\\{|dependencies\\s*\\{|\\bgradle\\b"
  "Build, Config & Quality Gates:boms=<dependencyManagement>|platform\\("
  "Build, Config & Quality Gates:spotless=\\bspotless\\b"
  "Build, Config & Quality Gates:checkstyle=\\bcheckstyle\\b"
  "Build, Config & Quality Gates:pmd=\\bpmd\\b"
  "Build, Config & Quality Gates:spotbugs=spotbugs|findbugs"
  "Build, Config & Quality Gates:errorprone=errorprone"

  # Language & Reliability
  "Language Features & Libraries:lombok=\\blombok\\.|@Getter|@Setter|@Builder|@Value\\b"
  "Language Features & Libraries:records=\\brecord\\s+\\w+\\s*\\("
  "Language Features & Libraries:try_with_resources=\\btry\\s*\\(.*\\)\\s*\\{"
  "Language Features & Libraries:security=spring-boot-starter-security|@PreAuthorize|SecurityFilterChain"
  
  # Spotify Internal Libraries
  "Spotify Internal:bender=com\\.spotify\\.bender|pubsub-utils"
  "Spotify Internal:contentcontrol=com\\.spotify\\.contentcontrol"
  "Spotify Internal:pubsub_wrapper=com\\.spotify\\.pubsubwrapper"
  "Spotify Internal:apollo_error_mapping=GrpcStatusMapperUtil|statusFromException"
  "Spotify Internal:spotify_config=@Named.*Spotify|SPOTIFY_|spotify\\."
  "Spotify Internal:hermes_messaging=apolloRequestFromHermesMessage|HermesMessageUtil"
  
  # Security & Configuration
  "Security & Config:secrets_management=@Secret|SecretsClient|credential"
  "Security & Config:input_validation=@Valid|@NotNull|@NotBlank|validateInput|isRequestValid"
  "Security & Config:auth_patterns=@PreAuthorize|SecurityContext|Authentication"
  
  # gRPC & Protocol Buffers
  "RPC & Serialization:grpc=io\\.grpc|@GrpcService|apollo-grpc"
  "RPC & Serialization:protobuf=com\\.google\\.protobuf|\\.proto|\\.pb\\.java"
  
  # Database & Persistence
  "Database & Persistence:jpa=@(Entity|Repository|Table|Column)\\b|javax\\.persistence"
  "Database & Persistence:flyway=\\bflyway\\b|V[0-9]+.*\\.sql"
  "Database & Persistence:hikari=HikariDataSource|HikariCP"
  "Database & Persistence:jdbi=org\\.jdbi|@(SqlQuery|SqlUpdate|RegisterRowMapper|UseRowMapper)\\b"
  "Database & Persistence:transactions=executeInTransaction|@Transaction\\b|useTransaction|inTransaction"
  "Database & Persistence:liquibase=\\bliquibase\\b|changeset|JdbiLiquibase"
  "Database & Persistence:connection_pool=HikariConfig|maximumPoolSize|minimumIdle|connectionTimeout"
  "Database & Persistence:dao_patterns=\\bDao\\b.*interface|SqlObject"
  "Database & Persistence:row_mappers=RowMapper|ResultSetMapper|@RegisterRowMapper"
)

# Anti-patterns
declare -a ANTI_PATTERNS=(
  "@Autowired\\s+public\\s+\\w+\\(" ":: @Autowired on constructors is redundant in Spring >=4.3."
  "@Autowired\\s+private\\s+"        ":: Field injection detected; prefer constructor injection."
  "\\bRestTemplate\\b"               ":: RestTemplate is legacy for reactive stacks; prefer WebClient."
  "new\\s+ObjectMapper\\s*\\("       ":: Avoid raw ObjectMapper; use a shared, configured instance."
  "Thread\\s*\\.sleep\\s*\\("        ":: Avoid Thread.sleep in prod/tests; use Awaitility or proper synchronization."
  "System\\.out\\.print"             ":: Avoid System.out; use SLF4J logging."
  "SELECT\\s+\\*\\s+FROM"            ":: Avoid SELECT *; specify columns explicitly for better performance."
  "\\+.*\\+.*WHERE"                  ":: Potential SQL injection risk; use parameterized queries."
  "new\\s+.*Connection\\s*\\("       ":: Avoid manual connection management; use connection pools."
  "executeQuery\\s*\\(.*\\+.*\\)"    ":: SQL concatenation detected; use parameterized queries."
  "Statement\\s+.*=.*createStatement" ":: Use PreparedStatement instead of Statement for better security."
  "@SuppressWarnings\\s*\\("          ":: @SuppressWarnings without justification comment; add explanation."
  "catch\\s*\\(\\s*Exception\\s+\\w+\\)" ":: Overly broad exception handling; catch specific exception types."
)

# Helper: run search respecting file extensions
search() {
  local pattern="$1"
  if [[ "$SEARCHER" == "rg" ]]; then
    # ripgrep uses -e for pattern and file globs for filtering
    rg "${SRCH_FLAGS[@]}" -e "$pattern" --glob "*.java" --glob "*.kt" --glob "*.xml" \
      --glob "*.yml" --glob "*.yaml" --glob "*.properties" --glob "*.gradle" \
      --glob "*.kts" --glob "*.toml" "$ROOT" || true
  else
    # grep fallback: filter by ext via find
    find "$ROOT" -type f | awk -v ext="$EXT_REGEX" '$0 ~ ext {print}' | xargs -r grep -n -E -- "$pattern" || true
  fi
}

# Count unique matches
count_hits() {
  local pattern="$1"
  search "$pattern" | wc -l | awk '{print $1}'
}

# Emit examples (capped)
emit_examples() {
  local pattern="$1" cap="${2:-50}"
  search "$pattern" | head -n "$cap" | \
    awk -F: '{file=$1; line=$2;
      $1=""; $2=""; sub(/^::/, "", $0); sub(/^:/, "", $0);
      gsub(/\t/, "  ", $0);
      print "- `" file ":" line "` — " substr($0,1,240)}'
}

# Data storage (bash 3.2 compatible)
# Using indexed arrays with delimited strings
declare -a TOTAL_DATA
declare -a GROUP_DATA
declare -a KEY_DATA

# Build arrays from patterns
for entry in "${PATTERNS[@]}"; do
  group="${entry%%:*}"
  rest="${entry#*:}"
  key="${rest%%=*}"
  pat="${rest#*=}"
  
  # Store as "key|pattern" in KEY_DATA
  KEY_DATA[${#KEY_DATA[@]}]="${key}|${pat}"
  
  # Store as "group|key" in GROUP_DATA
  GROUP_DATA[${#GROUP_DATA[@]}]="${group}|${key}"
done

# Function to get pattern for a key
get_pattern() {
  local search_key="$1"
  for entry in "${KEY_DATA[@]}"; do
    local k="${entry%%|*}"
    local p="${entry#*|}"
    if [[ "$k" == "$search_key" ]]; then
      echo "$p"
      return
    fi
  done
}

# Function to get count for a key
get_count() {
  local search_key="$1"
  if [[ ${#TOTAL_DATA[@]} -gt 0 ]]; then
    for entry in "${TOTAL_DATA[@]}"; do
      local k="${entry%%|*}"
      local c="${entry#*|}"
      if [[ "$k" == "$search_key" ]]; then
        echo "$c"
        return
      fi
    done
  fi
  echo "0"
}

# Function to set count for a key
set_count() {
  local key="$1"
  local count="$2"
  # Remove existing entry if present
  local new_data=()
  if [[ ${#TOTAL_DATA[@]} -gt 0 ]]; then
    for entry in "${TOTAL_DATA[@]}"; do
      local k="${entry%%|*}"
      if [[ "$k" != "$key" ]]; then
        new_data[${#new_data[@]}]="$entry"
      fi
    done
  fi
  # Add new entry
  new_data[${#new_data[@]}]="${key}|${count}"
  TOTAL_DATA=("${new_data[@]}")
}

# Run counts for all keys
for entry in "${KEY_DATA[@]}"; do
  key="${entry%%|*}"
  pat="${entry#*|}"
  count="$(count_hits "$pat")"
  set_count "$key" "$count"
done

# Write Markdown - ensure ./tmp directory exists
mkdir -p "$(dirname "$OUT")"
{
  echo "# Java Services Code Style — Repository Scan"
  echo "_Root scanned: $(cd "$ROOT" && pwd)_"
  echo

  echo "## Summary"
  
  # Get unique groups and check if they have hits
  declare -a unique_groups
  declare -a present_groups
  
  # Extract unique groups
  for entry in "${GROUP_DATA[@]}"; do
    group="${entry%%|*}"
    # Check if already in unique_groups
    found=0
    if [[ ${#unique_groups[@]} -gt 0 ]]; then
      for ug in "${unique_groups[@]}"; do
        [[ "$ug" == "$group" ]] && found=1 && break
      done
    fi
    [[ $found -eq 0 ]] && unique_groups[${#unique_groups[@]}]="$group"
  done
  
  # Check which groups have hits
  for group in "${unique_groups[@]}"; do
    has_hits=0
    for entry in "${GROUP_DATA[@]}"; do
      g="${entry%%|*}"
      k="${entry#*|}"
      if [[ "$g" == "$group" ]]; then
        count="$(get_count "$k")"
        [[ "$count" -gt 0 ]] && has_hits=1 && break
      fi
    done
    [[ $has_hits -eq 1 ]] && present_groups[${#present_groups[@]}]="$group"
  done
  
  if [[ ${#present_groups[@]} -gt 0 ]]; then
    IFS=", " ; echo "Detected areas: ${present_groups[*]}"; unset IFS
  else
    echo "Detected areas: None"
  fi
  echo

  echo "## Recommendations"
  
  # Get counts for recommendations
  di_field_count="$(get_count "di_field")"
  di_constructor_count="$(get_count "di_constructor")"
  apollo_count="$(get_count "apollo")"
  dagger_count="$(get_count "dagger")"
  spring_boot_count="$(get_count "spring_boot")"
  
  # DI recommendations
  if [[ "$di_field_count" -gt 0 && "$di_constructor_count" -ge "$di_field_count" ]]; then
    echo "- **Frameworks & Dependency Injection:** Constructor injection appears common; some field injection remains."
  elif [[ "$di_field_count" -gt 0 ]]; then
    echo "- **Frameworks & Dependency Injection:** Field injection detected in multiple places; prefer constructor injection."
  fi
  
  # Framework-specific recommendations
  if [[ "$apollo_count" -gt 0 ]]; then
    echo "- **Apollo Framework:** Detected Apollo usage; ensure proper request/response handling and middleware."
  fi
  if [[ "$dagger_count" -gt 0 ]]; then
    echo "- **Dagger:** Consider component scoping and avoid circular dependencies."
  fi
  # Testing notes
  junit5_count="$(get_count "junit5")"
  junit4_count="$(get_count "junit4")"
  testcontainers_count="$(get_count "testcontainers")"
  
  if [[ "$junit5_count" -gt 0 && "$junit4_count" -gt 0 ]]; then
    echo "- **Testing:** Both JUnit 4 and 5 detected; align on JUnit 5."
  fi
  if [[ "$testcontainers_count" -gt 0 ]]; then
    echo "- **Testing:** Testcontainers in use; ensure CI supports Docker and parallelism constraints."
  fi
  # Async notes
  reactor_count="$(get_count "reactor")"
  async_count="$(get_count "async")"
  timeouts_count="$(get_count "timeouts")"
  http_client_count="$(get_count "http_client")"
  cf_blocking_count="$(get_count "cf_blocking")"
  cf_composition_count="$(get_count "cf_composition")"
  cf_error_handling_count="$(get_count "cf_error_handling")"
  cf_executors_count="$(get_count "cf_executors")"
  cf_completion_stage_count="$(get_count "cf_completion_stage")"
  
  if [[ "$reactor_count" -gt 0 && "$async_count" -gt 0 ]]; then
    echo "- **Async & Concurrency:** Mixed reactive and CompletableFuture APIs; document when to choose each."
  fi
  if [[ "$timeouts_count" -eq 0 && ( "$http_client_count" -gt 0 || "$reactor_count" -gt 0 ) ]]; then
    echo "- **Async & Concurrency:** HTTP/reactive usage without obvious timeouts; add timeout guidance."
  fi
  if [[ "$cf_blocking_count" -gt 0 ]]; then
    echo "- **CompletableFuture Anti-pattern:** Found $cf_blocking_count blocking calls (.get()/.join()); consider non-blocking composition instead."
  fi
  if [[ "$async_count" -gt 0 && "$cf_composition_count" -eq 0 ]]; then
    echo "- **CompletableFuture:** Using CompletableFuture but no composition methods detected; verify proper async patterns."
  fi
  if [[ "$async_count" -gt 0 && "$cf_error_handling_count" -eq 0 ]]; then
    echo "- **CompletableFuture:** Using CompletableFuture but no error handling (.exceptionally/.handle) detected."
  fi
  if [[ "$cf_executors_count" -eq 0 && "$async_count" -gt 0 ]]; then
    echo "- **CompletableFuture:** No custom executors detected; ensure thread pool isolation for blocking operations."
  fi
  if [[ "$async_count" -gt 0 && "$cf_completion_stage_count" -eq 0 ]]; then
    echo "- **CompletableFuture API Design:** Consider using CompletionStage in method parameters for safer API design."
  fi
  
  # Observability
  micrometer_count="$(get_count "micrometer")"
  apollo_metrics_count="$(get_count "apollo_metrics")"
  
  if [[ "$micrometer_count" -eq 0 && "$apollo_metrics_count" -eq 0 ]]; then
    echo "- **Observability & Logging:** No metrics framework detected; consider Apollo metrics or Micrometer."
  fi
  # Build/Quality
  spotless_count="$(get_count "spotless")"
  checkstyle_count="$(get_count "checkstyle")"
  pmd_count="$(get_count "pmd")"
  
  if [[ "$spotless_count" -eq 0 && "$checkstyle_count" -eq 0 && "$pmd_count" -eq 0 ]]; then
    echo "- **Build, Config & Quality Gates:** Formatting/static analysis not clearly configured; consider Spotless + Checkstyle/PMD."
  fi
  
  # Lombok vs records
  lombok_count="$(get_count "lombok")"
  records_count="$(get_count "records")"
  
  if [[ "$lombok_count" -gt 0 && "$records_count" -gt 0 ]]; then
    echo "- **Language Features & Libraries:** Both Lombok and records present; clarify when to use each."
  fi
  echo

  echo "## Detailed Findings"
  
  # Process each group
  for group in "Frameworks & Dependency Injection" "Testing" "Async & Concurrency" \
               "REST, Validation & Errors" "Observability & Logging" \
               "Build, Config & Quality Gates" "Language Features & Libraries" \
               "Spotify Internal" "Security & Config" "RPC & Serialization" "Database & Persistence"; do
    
    echo "### $group"
    
    # Find keys for this group
    group_has_content=0
    for entry in "${GROUP_DATA[@]}"; do
      g="${entry%%|*}"
      k="${entry#*|}"
      if [[ "$g" == "$group" ]]; then
        count="$(get_count "$k")"
        if [[ "$count" -gt 0 ]]; then
          group_has_content=1
          pattern="$(get_pattern "$k")"
          echo "**$k** — $count hits"
          emit_examples "$pattern" 50
          echo
        fi
      fi
    done
    
    # Only show group if it has content
    [[ $group_has_content -eq 1 ]] && echo
  done

  echo "## Potential Anti-patterns"
  for ((i=0; i<${#ANTI_PATTERNS[@]}; i+=2)); do
    pat="${ANTI_PATTERNS[$i]}"
    note="${ANTI_PATTERNS[$i+1]}"
    if search "$pat" >/dev/null; then
      search "$pat" | head -n 100 | while IFS= read -r line; do
        file="${line%%:*}"
        rest="${line#*:}"
        line_no="${rest%%:*}"
        snippet="${rest#*:}"
        snippet="${snippet//$'\t'/  }"
        echo "- \`$file:$line_no\` — ${snippet:0:220}  <--${note}"
      done
    fi
  done
  echo

  cat <<'EOF'
## Suggested Style Topics to Document
- Dependency Injection: constructor-first; component boundaries and visibility.
- Testing: JUnit 5 baseline; Mockito; integration testing with @SpringBootTest; Testcontainers; deterministic seeds.
- Async: prefer Reactor vs CompletableFuture; avoid .get()/.join() blocking; use composition (thenCompose/thenCombine); proper error handling; custom executors; CompletionStage in APIs.
- HTTP: WebClient vs RestTemplate; connection pooling; retries with jitter; idempotency; timeouts.
- Errors: exception taxonomy; problem+json; @ControllerAdvice mapping; avoid log-and-throw.
- Validation: @Valid on boundaries; nullability annotations; DTO boundaries.
- Observability: Micrometer metrics; OpenTelemetry tracing; structured logging with correlation IDs.
- Serialization: Jackson module registry; shared ObjectMapper; records/immutability.
- Security: Spring Security structure; method security; secret handling policy.
- Build: Maven/Gradle BOMs; dependency scopes; reproducible builds; Enforcer rules.
- Quality: Spotless formatting; Checkstyle/PMD; Error Prone; SpotBugs; CI gates.
- Packaging: package-by-feature; API vs implementation; module boundaries.
- Resource management: try-with-resources; thread pools; DB pool sizing; graceful shutdown.
EOF

} > "$OUT"

echo "Wrote $OUT"
