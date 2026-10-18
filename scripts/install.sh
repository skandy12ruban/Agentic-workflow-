#!/usr/bin/env bash
# Install the agentic workflow library (agents, commands, skills, templates) into a project
# for a given AI coding tool, converting file formats where the tool needs it.
#
#   scripts/install.sh --tool claude  --target ../my-app
#   scripts/install.sh --tool gemini  --target ../my-app --only commands,skills
#   scripts/install.sh --tool claude  --scope user            # into ~/.claude for every repo
#
# No clone needed — run straight from GitHub (the library is cached in ~/.agentic-workflow):
#   curl -fsSL https://raw.githubusercontent.com/skandy12ruban/Agentic-workflow-/main/scripts/install.sh | bash -s -- --tool claude
#
# Guardrails (hooks, git hooks, protected-paths file) are installed by default; --no-guardrails skips them.
# Existing files are never overwritten unless --force is given.
set -euo pipefail

REPO_URL="${AGENTIC_WORKFLOW_REPO:-https://github.com/skandy12ruban/Agentic-workflow-.git}"
REPO_REF="${AGENTIC_WORKFLOW_REF:-main}"
LIB="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." 2>/dev/null && pwd || echo /nonexistent)"
if [[ ! -f "$LIB/agents/planner.md" || ! -f "$LIB/scripts/install.sh" ]]; then
  # Running via curl | bash (or copied alone): fetch the library.
  LIB="${AGENTIC_WORKFLOW_HOME:-$HOME/.agentic-workflow}"
  if [[ -d "$LIB/.git" ]]; then
    echo "Updating library in $LIB ($REPO_REF)"; git -C "$LIB" fetch -q --depth 1 origin "$REPO_REF" && git -C "$LIB" checkout -q FETCH_HEAD
  else
    echo "Fetching library $REPO_URL ($REPO_REF) into $LIB"; git clone -q --depth 1 --branch "$REPO_REF" "$REPO_URL" "$LIB"
  fi
fi
TOOL=""
TARGET="$PWD"
SCOPE="project"
ONLY="agents,commands,skills,templates"
FORCE=0
DRY=0
GUARDRAILS=1

usage() {
  sed -n '2,14p' "$LIB/scripts/install.sh" | sed 's/^# \{0,1\}//'
  cat <<'EOF'
Options:
  --tool    claude | gemini | codex | cursor | copilot | generic   (required)
  --target  project directory (default: current directory)
  --scope   project | user   (user = home-directory install where the tool supports it)
  --only    comma list of: agents,commands,skills,templates
  --force   overwrite existing files
  --no-guardrails  skip hooks / git hooks / protected-paths (not recommended)
  --dry-run print what would be done
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tool) TOOL="$2"; shift 2 ;;
    --target) TARGET="$2"; shift 2 ;;
    --scope) SCOPE="$2"; shift 2 ;;
    --only) ONLY="$2"; shift 2 ;;
    --force) FORCE=1; shift ;;
    --dry-run) DRY=1; shift ;;
    --no-guardrails) GUARDRAILS=0; shift ;;
    --with-guardrails) GUARDRAILS=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

[[ -n "$TOOL" ]] || { usage; exit 1; }
[[ -d "$TARGET" ]] || { echo "Target directory not found: $TARGET" >&2; exit 1; }
TARGET="$(cd "$TARGET" && pwd)"

want() { [[ ",$ONLY," == *",$1,"* ]]; }

INSTALLED=0
SKIPPED=0

# write_file <dest> : reads content from stdin
write_file() {
  local dest="$1"
  if [[ -e "$dest" && $FORCE -eq 0 ]]; then
    echo "  skip (exists)  $dest"; SKIPPED=$((SKIPPED + 1)); cat >/dev/null; return
  fi
  if [[ $DRY -eq 1 ]]; then
    echo "  would write    $dest"; cat >/dev/null; return
  fi
  mkdir -p "$(dirname "$dest")"
  cat >"$dest"
  echo "  wrote          $dest"; INSTALLED=$((INSTALLED + 1))
}

copy_file() { # preserves the executable bit
  write_file "$2" <"$1"
  [[ $DRY -eq 0 && -x "$1" && -f "$2" ]] && chmod +x "$2"
  return 0
}

copy_skills() {
  local dest_root="$1" skill
  for skill in "$LIB"/skills/*/; do
    skill="${skill%/}"
    local name; name="$(basename "$skill")"
    while IFS= read -r -d '' f; do
      copy_file "$f" "$dest_root/$name/${f#"$skill"/}"
    done < <(find "$skill" -type f -print0)
  done
}

# Markdown files in a library dir, excluding README.md
lib_md() { find "$LIB/$1" -maxdepth 1 -name '*.md' ! -name 'README.md' | sort; }

frontmatter_field() { # <file> <field>
  awk -v k="$2" 'NR==1 && $0=="---" {fm=1; next} fm && $0=="---" {exit}
                 fm && index($0, k": ")==1 {sub("^" k ": *", ""); print; exit}' "$1"
}

body() { # strip YAML frontmatter
  awk 'NR==1 && $0=="---" {fm=1; next} fm && $0=="---" {fm=0; next} !fm' "$1"
}

to_gemini_toml() { # <md file>
  local desc b
  desc="$(frontmatter_field "$1" description | sed 's/\\/\\\\/g; s/"/\\"/g')"
  b="$(body "$1" | sed 's/\$ARGUMENTS/{{args}}/g')"
  if [[ "$b" == *"'''"* ]]; then
    echo "Cannot convert $1: body contains ''' " >&2; return 1
  fi
  printf 'description = "%s"\nprompt = '"'''"'\n%s\n'"'''"'\n' "$desc" "$b"
}

to_copilot_prompt() { # <md file>
  local desc hint
  desc="$(frontmatter_field "$1" description)"
  hint="$(frontmatter_field "$1" argument-hint)"
  printf -- '---\ndescription: %s\nargument-hint: %s\nagent: agent\n---\n' "$desc" "$hint"
  body "$1" | sed 's/\$ARGUMENTS/${input:args}/g'
}

to_copilot_agent() { # <md file>
  printf -- '---\nname: %s\ndescription: %s\n---\n' \
    "$(frontmatter_field "$1" name)" "$(frontmatter_field "$1" description)"
  body "$1"
}

install_library_dir() { # generic .agentic/ layout used by tools without native agents/skills
  local base="$TARGET/.agentic" f
  if want agents; then
    echo "agents → $base/agents"
    for f in $(lib_md agents); do copy_file "$f" "$base/agents/$(basename "$f")"; done
  fi
  if want skills; then
    echo "skills → $base/skills"
    copy_skills "$base/skills"
  fi
}

install_templates() {
  want templates || return 0
  echo "templates → $TARGET/.agentic/templates"
  local f
  for f in "$LIB"/templates/*; do
    [[ "$(basename "$f")" == "README.md" ]] && continue
    copy_file "$f" "$TARGET/.agentic/templates/$(basename "$f")"
  done
}

install_guardrails() { # <tool>
  [[ $GUARDRAILS -eq 1 ]] || { echo "guardrails: skipped (--no-guardrails)"; return 0; }
  if [[ "$SCOPE" == "user" ]]; then
    echo "guardrails → Claude Code hooks + settings (user level)"
    [[ "$1" == claude ]] || { echo "  NOTE: user scope — run again with --scope project inside each repo to add git hooks."; return 0; }
    local u="$HOME/.claude"
    copy_file "$LIB/hooks/claude/guard-bash.sh"  "$u/hooks/guard-bash.sh"
    copy_file "$LIB/hooks/claude/guard-files.sh" "$u/hooks/guard-files.sh"
    local dest="$u/settings.json"; [[ -e "$dest" && $FORCE -eq 0 ]] && dest="$u/settings.agentic-guardrails.json"
    sed 's#\\"$CLAUDE_PROJECT_DIR\\"/.claude/hooks/#\\"$HOME\\"/.claude/hooks/#g' "$LIB/hooks/claude/settings.json" | write_file "$dest"
    [[ "$dest" == *agentic-guardrails* ]] && echo "  NOTE: merge 'permissions' and 'hooks' from $dest into $u/settings.json."
    return 0
  fi
  echo "guardrails → git hooks, protected paths$([[ "$1" == claude ]] && echo ", Claude Code hooks + settings")"
  copy_file "$LIB/hooks/git/pre-commit" "$TARGET/.agentic/git-hooks/pre-commit"
  copy_file "$LIB/hooks/git/pre-push"   "$TARGET/.agentic/git-hooks/pre-push"
  write_file "$TARGET/.agentic/protected-paths" <<'PP'
# Paths agents must never edit (one glob per line; '*' also matches '/'). Enforced by .claude/hooks/guard-files.sh.
# Examples — uncomment / adapt:
# src/generated/*
# vendor/*
# infra/*
# db/migrations/2023*
PP
  if [[ "$1" == claude ]]; then
    local root; root="$(home_or_target)/.claude"
    copy_file "$LIB/hooks/claude/guard-bash.sh"  "$root/hooks/guard-bash.sh"
    copy_file "$LIB/hooks/claude/guard-files.sh" "$root/hooks/guard-files.sh"
    if [[ -e "$root/settings.json" && $FORCE -eq 0 ]]; then
      copy_file "$LIB/hooks/claude/settings.json" "$root/settings.agentic-guardrails.json"
      echo "  NOTE: $root/settings.json exists — merge 'permissions' and 'hooks' from settings.agentic-guardrails.json into it."
    else
      copy_file "$LIB/hooks/claude/settings.json" "$root/settings.json"
    fi
  fi
  # Activate git hooks when it is safe to do so (don't clobber existing hooks or hook managers).
  if [[ $DRY -eq 0 ]] && git -C "$TARGET" rev-parse --git-dir >/dev/null 2>&1; then
    local gd hp h; gd="$(cd "$TARGET" && cd "$(git rev-parse --git-dir)" && pwd)"; hp="$(git -C "$TARGET" config --get core.hooksPath || true)"
    for h in pre-commit pre-push; do
      if [[ -n "$hp" ]]; then echo "  NOTE: core.hooksPath=$hp — call .agentic/git-hooks/$h from your hook manager."; break
      elif [[ -e "$gd/hooks/$h" ]]; then echo "  NOTE: $gd/hooks/$h exists — call .agentic/git-hooks/$h from it."
      else cp "$TARGET/.agentic/git-hooks/$h" "$gd/hooks/$h" && chmod +x "$gd/hooks/$h" && echo "  activated      $gd/hooks/$h"; fi
    done
  fi
}

home_or_target() { [[ "$SCOPE" == "user" ]] && echo "$HOME" || echo "$TARGET"; }

echo "Installing agentic workflow for '$TOOL' (scope: $SCOPE) into: $(home_or_target)"
case "$TOOL" in
  claude)
    root="$(home_or_target)/.claude"
    if want agents; then
      echo "agents → $root/agents"
      for f in $(lib_md agents); do copy_file "$f" "$root/agents/$(basename "$f")"; done
    fi
    if want commands; then
      echo "commands → $root/commands"
      for f in $(lib_md commands); do copy_file "$f" "$root/commands/$(basename "$f")"; done
    fi
    if want skills; then
      echo "skills → $root/skills"
      copy_skills "$root/skills"
    fi
    [[ "$SCOPE" == "project" ]] && install_templates
    ;;
  gemini)
    if want commands; then
      root="$(home_or_target)/.gemini/commands"
      echo "commands → $root (converted to TOML)"
      for f in $(lib_md commands); do
        to_gemini_toml "$f" | write_file "$root/$(basename "${f%.md}").toml"
      done
    fi
    install_library_dir; install_templates
    ;;
  codex)
    if want commands; then
      root="$HOME/.codex/prompts"
      echo "commands → $root (Codex custom prompts are user-level; invoke as /prompts:<name>)"
      for f in $(lib_md commands); do copy_file "$f" "$root/$(basename "$f")"; done
    fi
    install_library_dir; install_templates
    ;;
  cursor)
    if want commands; then
      echo "commands → $TARGET/.cursor/commands"
      for f in $(lib_md commands); do copy_file "$f" "$TARGET/.cursor/commands/$(basename "$f")"; done
    fi
    write_file "$TARGET/.cursor/rules/agentic-workflow.mdc" <<'EOF'
---
description: Agentic workflow library conventions
globs:
alwaysApply: true
---
- This repo uses the agentic workflow library in `.agentic/` (agents, skills, templates).
- When a command says "delegate to the `X` agent", read `.agentic/agents/X.md` and perform that role as a focused step, writing its output to the run directory before continuing.
- When a command says "apply the `Y` skill", read `.agentic/skills/Y/SKILL.md` first.
- Never write source code before the plan is approved (`.agentic/skills/approval-gate/SKILL.md`).
EOF
    install_library_dir; install_templates
    ;;
  copilot)
    if want commands; then
      echo "commands → $TARGET/.github/prompts (*.prompt.md)"
      for f in $(lib_md commands); do
        to_copilot_prompt "$f" | write_file "$TARGET/.github/prompts/$(basename "${f%.md}").prompt.md"
      done
    fi
    if want agents; then
      echo "agents → $TARGET/.github/agents (*.agent.md)"
      for f in $(lib_md agents); do
        to_copilot_agent "$f" | write_file "$TARGET/.github/agents/$(basename "${f%.md}").agent.md"
      done
    fi
    write_file "$TARGET/.github/copilot-instructions.md" <<'EOF'
# Copilot instructions
Follow `AGENTS.md` at the repository root for commands, conventions, and boundaries.
This repo uses the agentic workflow library: prompts in `.github/prompts/`, agents in `.github/agents/`,
skills in `.agentic/skills/<name>/SKILL.md` (read the relevant SKILL.md when a prompt says "apply the `<name>` skill").
EOF
    install_library_dir; install_templates
    ;;
  generic)
    install_library_dir
    if want commands; then
      echo "commands → $TARGET/.agentic/commands"
      for f in $(lib_md commands); do copy_file "$f" "$TARGET/.agentic/commands/$(basename "$f")"; done
    fi
    install_templates
    ;;
  *) echo "Unknown tool: $TOOL" >&2; usage; exit 1 ;;
esac
install_guardrails "$TOOL"

echo
echo "Done: $INSTALLED written, $SKIPPED skipped (use --force to overwrite)."
cat <<EOF
Next steps:
  1. Configure MCP servers (tracker, VCS, browser): see $LIB/docs/mcp-servers.md
  2. Create project memory: run /setup-project in your tool, or copy .agentic/templates/AGENTS.md to the repo root
  3. Append $LIB/templates/gitignore-snippet.txt to .gitignore
  4. Protect main on your Git host: required PR review + status checks + no force-push (the last line of defence)
  5. Try it: /plan <ticket>   then   /task <ticket>
EOF
