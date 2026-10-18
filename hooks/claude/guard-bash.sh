#!/usr/bin/env bash
# Claude Code PreToolUse hook for the Bash tool.
# Blocks destructive, irreversible, external, or guardrail-bypassing shell commands.
# Exit 2 = block (stderr is shown to the agent). Exit 0 = allow (normal permission rules still apply).
#
# Install: copy to .claude/hooks/guard-bash.sh, chmod +x, and register it in .claude/settings.json:
#   "PreToolUse": [{ "matcher": "Bash", "hooks": [{ "type": "command",
#                    "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/guard-bash.sh" }] }]
#
# Configure (optional, via environment or .agentic/guardrails.env):
#   AGENTIC_PROTECTED_BRANCHES="main|master|develop|release/.*"   extended regex, anchored
#   AGENTIC_ALLOW_DEPLOY_TOOLS=0                                  never set to 1 for agents
set -uo pipefail

input="$(cat)"
project_dir="${CLAUDE_PROJECT_DIR:-$PWD}"
[[ -f "$project_dir/.agentic/guardrails.env" ]] && source "$project_dir/.agentic/guardrails.env"

json_field() { # json_field <dot.path>  — jq, then python3, then node; fail closed if none
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$input" | jq -r ".$1 // empty"
  elif command -v python3 >/dev/null 2>&1; then
    printf '%s' "$input" | python3 -c 'import json,sys
d=json.load(sys.stdin)
for k in sys.argv[1].split("."): d=d.get(k) if isinstance(d,dict) else None
print(d if isinstance(d,str) else "")' "$1"
  elif command -v node >/dev/null 2>&1; then
    printf '%s' "$input" | node -e 'let s="";process.stdin.on("data",c=>s+=c).on("end",()=>{let d=JSON.parse(s);for(const k of process.argv[1].split("."))d=d&&d[k];console.log(typeof d==="string"?d:"")})' "$1"
  else
    echo "BLOCKED by guardrails: guard-bash needs jq, python3, or node to inspect commands." >&2; exit 2
  fi
}

block() {
  {
    echo "BLOCKED by guardrails: $1"
    echo "Do not try to work around this (different flags, scripts, aliases, or encodings)."
    echo "If the action is genuinely required, stop and ask the human to perform or explicitly approve it."
  } >&2
  exit 2
}

cmd="$(json_field tool_input.command)" || { echo "BLOCKED by guardrails: could not parse hook input (fail closed)." >&2; exit 2; }
[[ -z "$cmd" ]] && exit 0

# Kill switch: a human can create .agentic/STOP to halt all agent shell activity immediately.
[[ -e "$project_dir/.agentic/STOP" ]] && block "kill switch is active (.agentic/STOP exists). Stop work and report status to the human."

# c   = whole command on one line, single-spaced (used for cross-pipe patterns like curl | sh).
# seg = one simple command per line (split on ; && || | and newlines) so patterns can't
#       accidentally span two unrelated commands.
c=" $(printf '%s' "$cmd" | tr '\n\t' '  ' | tr -s ' ') "
seg="$(printf '%s\n' "$cmd" | sed -E 's/(&&|\|\||;|\|)/\n/g' | tr '\t' ' ' | tr -s ' ' | sed -E 's/^/ /; s/$/ /')"
m()  { printf '%s\n' "$seg" | grep -Eq  -- "$1"; }   # per-segment, case-sensitive
mi() { printf '%s\n' "$seg" | grep -Eiq -- "$1"; }   # per-segment, case-insensitive
mp() { printf '%s' "$c" | grep -Eq -- "$1"; }        # whole line (pipes)

PROTECTED="${AGENTIC_PROTECTED_BRANCHES:-main|master|develop|development|trunk|stable|prod|production|release/.*|releases/.*|hotfix/.*}"
S='(^|[[:space:];&|(`])'   # start of a command word

# ── Guardrail bypass ────────────────────────────────────────────────────────────
m '--no-verify'                                     && block "--no-verify bypasses git hooks. Fix the hook failure instead."
mi 'core\.hookspath|HUSKY=0|HUSKY_SKIP|SKIP_HOOKS|AGENTIC_ALLOW' && block "disabling hooks or guardrail overrides is not allowed for agents."
m  '\.claude/(hooks|settings)|\.agentic/(STOP|guardrails\.env|protected-paths|git-hooks)|\.git/hooks' \
  && mp '(^|[ ;&|])(rm|mv|cp|chmod|chown|ln|sed -i|tee|truncate|unlink|python3?|node|perl)( |$)|>' && block "agents may not modify guardrail files (.claude/hooks, settings, .agentic/STOP, git hooks)."
m  "${S}git config( --[a-z]+)* --(global|system)" && block "changing global/system git config affects the user's whole machine."

# ── Git: history, branches, remote ─────────────────────────────────────────────
if m "${S}git( -C [^ ]+)? push( |$)"; then
  m ' --force( |=|$)| -[a-zA-Z]*f[a-zA-Z]*( |$)| \+[^ ]+' && block "force-push rewrites remote history. Push new commits instead (use --force-with-lease only on your own unshared branch, after asking)."
  m ' --delete( |$)| -d( |$)| :[^ ]+'                     && block "deleting remote branches/tags is not allowed."
  m ' --mirror( |$)| --all( |$)| --tags( |$)'              && block "bulk pushes (--mirror/--all/--tags) are not allowed; push your feature branch only."
  # Work out the destination branch(es).
  rest="${cmd#*git*push}"; rest="${rest%%[;&|]*}"
  read -r -a words <<<"$rest"
  args=(); for w in "${words[@]:-}"; do [[ -n "$w" && "$w" != -* ]] && args+=("$w"); done
  targets=("${args[@]:1}")
  current="$(git -C "$project_dir" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
  [[ ${#targets[@]} -eq 0 ]] && targets=("$current")
  for t in "${targets[@]}"; do
    t="${t#+}"; t="${t##*:}"; t="${t#refs/heads/}"; [[ "$t" == "HEAD" ]] && t="$current"
    [[ "$t" =~ ^($PROTECTED)$ ]] && block "pushing to protected branch '$t'. Push a feature branch and open a PR."
  done
fi
m "${S}git( -C [^ ]+)? reset( [^ ]+)* --hard"             && block "git reset --hard discards work irreversibly. Use git stash or a new commit."
m "${S}git( -C [^ ]+)? clean( [^ ]+)* -[a-zA-Z]*f"        && block "git clean -f deletes untracked files irreversibly."
m "${S}git( -C [^ ]+)? checkout( --)? \.( |$)"             && block "git checkout . discards all uncommitted changes."
m "${S}git( -C [^ ]+)? restore( --worktree)? \.( |$)"      && block "git restore . discards all uncommitted changes."
m "${S}git( -C [^ ]+)? branch( [^ ]+)* -D( |$)"            && block "force-deleting branches can lose unmerged work."
m "${S}git( -C [^ ]+)? stash (drop|clear)"                 && block "dropping stashes loses work."
m "${S}git( -C [^ ]+)? (filter-branch|filter-repo|replace)( |$)" && block "history rewriting is not allowed."
m "${S}git( -C [^ ]+)? update-ref -d"                      && block "deleting refs is not allowed."

# ── VCS platform: merges, deletes, releases ────────────────────────────────────
m "${S}gh (pr merge|repo delete|repo archive|release (create|delete)|secret|variable (set|delete))"  && block "merging PRs, releases, repo/secret changes need a human."
m "${S}gh api( [^ ]+)* (-X|--method) ?(DELETE|PUT|PATCH)"   && block "mutating GitHub API calls via gh api are not allowed; use the scoped MCP tools."
m "${S}glab (mr merge|repo delete|release create)"          && block "merging MRs or releasing needs a human."
m "${S}az repos pr (update|complete)"                       && block "completing PRs needs a human."

# ── Filesystem destruction ─────────────────────────────────────────────────────
if m "${S}rm( [^ ]+)* -[a-zA-Z]*[rR]"; then
  rest="${cmd#*rm }"; rest="${rest%%[;&|]*}"
  read -r -a words <<<"$rest"
  for w in "${words[@]:-}"; do
    [[ -z "$w" || "$w" == -* ]] && continue
    w="${w%\"}"; w="${w#\"}"; w="${w%\'}"; w="${w#\'}"
    # shellcheck disable=SC2088  # '~' is matched literally (as typed by the agent), not expanded
    case "$w" in
      /tmp/*|/var/tmp/*|"${TMPDIR:-/tmp}"/*) ;;                          # temp dirs are fine
      /|/*|'~'|'~/'*|'$HOME'*|'${HOME}'*|\*|.|./|..|../*|.git|.git/*|./.git*) block "recursive delete of '$w' (root, home, parent, wildcard, absolute or .git path)." ;;
    esac
  done
fi
m "${S}sudo( |$)|${S}doas( |$)"                             && block "privilege escalation (sudo/doas) is not allowed."
m "${S}chmod( -R)? [0-7]*777|${S}chown -R"                  && block "broad permission/ownership changes are not allowed."
m "${S}(mkfs|fdisk|diskutil (erase|partition))|${S}dd [^ ]*of=/dev/" && block "disk-level operations are not allowed."
m "${S}(shutdown|reboot|halt|poweroff)( |$)|:\(\)\{"         && block "system power operations / fork bombs are not allowed."
m "${S}(crontab -r|launchctl (unload|remove)|systemctl (stop|disable|mask))" && block "changing system services is not allowed."

# ── Remote code execution ──────────────────────────────────────────────────────
mp '(curl|wget)[^|]*\| *(sudo +)?(ba|z|k|da|fi)?sh( |$)|(curl|wget)[^|]*\| *(python3?|node|perl|ruby)( |$)' && block "piping downloaded scripts into an interpreter executes unreviewed code."
mp '(ba|z)?sh +<\( *(curl|wget)|(eval|source) +"?\$\( *(curl|wget)'                                       && block "executing downloaded scripts is not allowed."

# ── Infrastructure, cloud, deploys ─────────────────────────────────────────────
if [[ "${AGENTIC_ALLOW_DEPLOY_TOOLS:-0}" != "1" ]]; then
  m "${S}terraform (apply|destroy|import|taint|untaint|state (rm|mv|push|replace-provider)|force-unlock)" && block "terraform state/infrastructure changes need a human (plan/validate are fine)."
  m "${S}(tofu|terragrunt) (apply|destroy|run-all (apply|destroy))" && block "infrastructure changes need a human."
  m "${S}pulumi (up|destroy|refresh|cancel|stack rm)"                 && block "infrastructure changes need a human (pulumi preview is fine)."
  m "${S}cdk (deploy|destroy)|${S}serverless (deploy|remove)|${S}sls (deploy|remove)" && block "deploys need a human."
  m "${S}kubectl( [^ ]+)* (apply|delete|create|replace|patch|scale|rollout|drain|cordon|uncordon|taint|edit|set|label|annotate|exec|cp)( |$)" && block "changing Kubernetes resources needs a human (get/describe/logs are fine)."
  m "${S}helm (install|upgrade|uninstall|delete|rollback)"            && block "Helm releases need a human."
  m "${S}aws( [^ ]+)* ((delete|terminate|remove|deregister|put|create|update|modify|attach|detach|stop|reboot)-[a-z-]+|s3 (rm|rb|mv|sync)|s3api (delete|put))" && block "mutating AWS calls need a human."
  m "${S}gcloud( [^ ]+)* (delete|deploy|create|update|set-iam-policy|add-iam-policy-binding)( |$)" && block "mutating Google Cloud calls need a human."
  m "${S}az( [^ ]+)* (delete|create|update|deploy|set|start|stop|restart)( |$)" && block "mutating Azure calls need a human."
  m "${S}(firebase deploy|vercel( [^ ]+)* --prod|netlify deploy( [^ ]+)* --prod|fly deploy|flyctl deploy|heroku |railway up|wrangler (deploy|publish))" && block "production deploys need a human."
  m "${S}docker (push|login|system prune|volume (rm|prune))|${S}docker compose( [^ ]+)* down( [^ ]+)* -v" && block "pushing images or deleting Docker volumes needs a human."
fi

# ── Databases ──────────────────────────────────────────────────────────────────
mi '(drop +(database|schema|table|user|role)|truncate +table|delete +from +[a-z_."]+ *(;|"|$)|alter +table +[^ ]+ +drop)' && block "destructive SQL (DROP/TRUNCATE/unbounded DELETE) needs a human, even locally."
m  "prisma (migrate reset|db push( [^ ]+)* --(force-reset|accept-data-loss))|${S}(rails|rake|bin/rails) db:(drop|reset|purge|schema:load)|manage\.py (flush|reset_db|sqlflush)|${S}dropdb |flyway( [^ ]+)* clean|liquibase( [^ ]+)* drop-all|mongo(sh)?( [^ ]+)* .*dropDatabase|knex migrate:rollback --all|sequelize db:(drop|migrate:undo:all)|typeorm schema:drop" && block "database reset/drop commands need a human."

mi "${S}redis-cli( [^ ]+)* flush(all|db)" && block "flushing Redis needs a human."

# ── Publishing / releases ──────────────────────────────────────────────────────
m "${S}((npm|pnpm|bun) publish|yarn( npm)? publish|cargo (publish|yank)|twine upload|gem (push|yank)|poetry publish|uv publish|flit publish|hatch publish|dotnet nuget (push|delete)|nuget push|mvn( [^ ]+)* deploy|flutter pub publish|dart pub publish|pod trunk push|vsce publish|ovsx publish)( |$)" && block "publishing packages needs a human."
m "${S}(\./)?gradlew?( [^ ]+)* publish" && block "publishing artifacts needs a human."

# ── Secrets & credentials ──────────────────────────────────────────────────────
for f in $(printf '%s' "$c" | grep -Eo '(^|[ /=<"'"'"'])\.env(\.[A-Za-z0-9_.-]+)?' | sed -E 's#^[ /=<"'"'"']##'); do
  case "$f" in .env.example|.env.sample|.env.template|.env.dist|.env.defaults) ;; *)
    m "${S}(cat|less|more|head|tail|bat|nl|strings|xxd|od|grep|rg|awk|sed|cut|sort|source|\.|cp|mv|curl|base64|python3?|node)( [^ ]+)* [^ ]*\.env" && block "reading or copying '$f' would expose secrets. Use .env.example for variable names." ;;
  esac
done
m "${S}printenv( |$)|${S}env *($|[|;&>])|${S}export -p|${S}set *($|[|;&])|${S}declare -[px]" && block "dumping the environment can expose secrets. Print specific non-secret variables instead."
m '(~|\$HOME|/home/[^/ ]+|/Users/[^/ ]+|/root)/\.(ssh|aws|gnupg|kube|docker/config|config/gcloud|azure|netrc|npmrc|pypirc)' && block "reading credential stores (~/.ssh, ~/.aws, ~/.kube, ...) is not allowed."
m "${S}(gh auth (token|status --show-token)|aws configure (get|export-credentials)|gcloud auth (print-access-token|print-identity-token)|az account get-access-token|security find-(generic|internet)-password|op (read|item get)|vault (read|kv get)|heroku auth:token|npm token)" && block "printing credentials or tokens is not allowed."
m 'id_(rsa|ed25519|ecdsa|dsa)( |$|\.)|\.(pem|p12|pfx|jks|keystore)( |$)' && m "${S}(cat|less|more|head|tail|cp|mv|scp|curl|base64)( |$)" && block "reading or moving private keys is not allowed."

# ── Exfiltration patterns ──────────────────────────────────────────────────────
m '(curl|wget|http|httpie|nc|ncat|socat)( [^ ]+)* (-d|--data[a-z-]*|-F|--form|-T|--upload-file|@)[ =]?@?[^ ]*(\.env|id_rsa|\.pem|credentials|\.npmrc|\.netrc)' && block "uploading secret files is not allowed."

exit 0
