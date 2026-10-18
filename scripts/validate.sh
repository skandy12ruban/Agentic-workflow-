#!/usr/bin/env bash
# Validate the library itself. Run before every PR: scripts/validate.sh
# Checks: frontmatter, skill names, internal links + anchors, placeholders, installer for every tool,
# guardrail hook regression tests, shell syntax (and shellcheck if installed).
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; cd "$ROOT" || exit 1
fail=0; step() { printf '\n▶ %s\n' "$1"; }; bad() { echo "  ✗ $1"; fail=1; }

step "Frontmatter (agents, commands, skills)"
python3 - <<'EOF' || fail=1
import glob, sys, yaml
files = [f for f in glob.glob('agents/*.md') + glob.glob('commands/*.md') + glob.glob('skills/*/SKILL.md') if not f.endswith('README.md')]
errors = 0
for f in files:
    text = open(f).read()
    if not text.startswith('---\n'):
        print(f'  ✗ {f}: missing frontmatter'); errors += 1; continue
    meta = yaml.safe_load(text.split('---\n')[1])
    if not meta.get('description'): print(f'  ✗ {f}: no description'); errors += 1
    if f.startswith('agents/') and meta.get('name') != f[7:-3]: print(f'  ✗ {f}: name must equal filename'); errors += 1
    if f.endswith('SKILL.md') and meta.get('name') != f.split('/')[-2]: print(f'  ✗ {f}: name must equal folder'); errors += 1
    if f.startswith('commands/') and '$ARGUMENTS' not in text: print(f'  ✗ {f}: body never uses $ARGUMENTS'); errors += 1
    if not f.startswith('skills/') and 'guardrails' not in text: print(f'  ✗ {f}: does not reference the guardrails skill'); errors += 1
print(f'  {len(files)} files checked'); sys.exit(1 if errors else 0)
EOF

step "Internal links and anchors (markdown + llms.txt)"
python3 - <<'EOF' || fail=1
import glob, os, re, sys
def slug(h): return re.sub(r'[^\w\- ]', '', h.strip().lower()).replace(' ', '-')
docs = glob.glob('**/*.md', recursive=True) + ['llms.txt']
heads = {f: {slug(h) for h in re.findall(r'^#+\s+(.*)$', re.sub(r'```.*?```', '', open(f).read(), flags=re.S), re.M)} for f in docs}
errors = 0
for f in docs:
    for link in re.findall(r'\]\(([^)\s]+)\)', re.sub(r'```.*?```', '', open(f).read(), flags=re.S)):
        if link.startswith(('http://', 'https://', 'mailto:', 'vscode:', 'cursor:')): continue
        path, _, anchor = link.partition('#')
        target = os.path.normpath(os.path.join(os.path.dirname(f), path)) if path else f
        if not os.path.exists(target): print(f'  ✗ {f}: broken link {link}'); errors += 1
        elif anchor and target.endswith('.md') and anchor not in heads.get(target, set()): print(f'  ✗ {f}: missing anchor {link}'); errors += 1
print(f'  {len(docs)} files checked'); sys.exit(1 if errors else 0)
EOF

step "No unfilled repo placeholders"
if grep -rnE '<you>/|<github-user>/' --include='*.md' --include='*.sh' . | grep -v 'scripts/validate.sh'; then bad "placeholder repo URLs found"; else echo "  ok"; fi

step "Shell scripts"
for s in scripts/*.sh hooks/claude/*.sh hooks/git/*; do bash -n "$s" || bad "syntax error in $s"; [[ -x "$s" ]] || bad "$s is not executable"; done
if command -v shellcheck >/dev/null 2>&1; then shellcheck -S warning scripts/*.sh hooks/claude/*.sh hooks/git/* || bad "shellcheck warnings"; else echo "  (shellcheck not installed — skipped)"; fi
echo "  syntax ok"

step "Installer (every tool, isolated HOME)"
for t in claude gemini codex cursor copilot generic; do
  d="$(mktemp -d)"; git -C "$d" init -q
  if HOME="$d/home" ./scripts/install.sh --tool "$t" --target "$d" >"$d/log" 2>&1; then
    case "$t" in
      claude)  [[ -x "$d/.claude/hooks/guard-bash.sh" && -f "$d/.claude/settings.json" && -f "$d/.claude/skills/guardrails/SKILL.md" ]] || bad "claude: missing hooks/settings/guardrails" ;;
      gemini)  python3 -c "import tomllib,glob,sys; [tomllib.load(open(f,'rb')) for f in glob.glob('$d/.gemini/commands/*.toml')]" || bad "gemini: invalid TOML" ;;
      codex)   [[ -f "$d/home/.codex/prompts/task.md" ]] || bad "codex: prompts missing" ;;
      cursor)  [[ -f "$d/.cursor/rules/agentic-workflow.mdc" ]] || bad "cursor: rule missing" ;;
      copilot) [[ -f "$d/.github/prompts/task.prompt.md" && -f "$d/.github/agents/planner.agent.md" ]] || bad "copilot: prompts/agents missing" ;;
      generic) [[ -f "$d/.agentic/commands/task.md" ]] || bad "generic: commands missing" ;;
    esac
    [[ -x "$d/.git/hooks/pre-push" ]] || bad "$t: git pre-push hook not activated"
    echo "  $t ok"
  else bad "$t: installer failed"; tail -5 "$d/log"; fi
  rm -rf "$d"
done

step "Guardrail hook regression tests"
out="$(scripts/test-guardrails.sh 2>&1)" || fail=1; printf '%s\n' "$out" | tail -3

echo; if [[ $fail -eq 0 ]]; then echo "✅ all checks passed"; else echo "❌ validation failed"; fi
exit $fail
