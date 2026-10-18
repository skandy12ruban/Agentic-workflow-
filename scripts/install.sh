#!/usr/bin/env bash
# Install the agentic workflow library (agents, commands, skills, templates) into a project
# for a given AI coding tool, converting file formats where the tool needs it.
#
#   scripts/install.sh --tool claude  --target ../my-app
#   scripts/install.sh --tool gemini  --target ../my-app --only commands,skills
#   scripts/install.sh --tool claude  --scope user            # into ~/.claude for every repo
#
# Existing files are never overwritten unless --force is given.
set -euo pipefail

LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOL=""
TARGET="$PWD"
SCOPE="project"
ONLY="agents,commands,skills,templates"
FORCE=0
DRY=0

usage() {
  sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'
  cat <<'EOF'
Options:
  --tool    claude | gemini | codex | cursor | copilot | generic   (required)
  --target  project directory (default: current directory)
  --scope   project | user   (user = home-directory install where the tool supports it)
  --only    comma list of: agents,commands,skills,templates
  --force   overwrite existing files
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

copy_file() { write_file "$2" <"$1"; }

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

echo
echo "Done: $INSTALLED written, $SKIPPED skipped (use --force to overwrite)."
cat <<EOF
Next steps:
  1. Configure MCP servers (tracker, VCS, browser): see $LIB/docs/mcp-servers.md
  2. Create project memory: run /setup-project in your tool, or copy .agentic/templates/AGENTS.md to the repo root
  3. Append $LIB/templates/gitignore-snippet.txt to .gitignore
  4. Try it: /plan <ticket>   then   /task <ticket>
EOF
