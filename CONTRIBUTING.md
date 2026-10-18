# Contributing

Thanks for improving the library. It aims to be **generic** (any stack, any tool) and **deep** (actually useful to senior engineers). Contributions should keep both.

## Ground rules
- **Tool-agnostic bodies.** Write agent, command and skill bodies in plain markdown. Use Claude Code frontmatter, since `install.sh` converts it for other tools. The only placeholder allowed in bodies is `$ARGUMENTS`.
- **Capabilities, not products.** Say "the tracker MCP" or "the browser MCP". Name products only in tables of options.
- **Stack-neutral.** If you add an example for one ecosystem, add a row to the relevant matrix (`skills/stack-detection/stack-matrix.md`, `skills/test-generation/framework-cheatsheet.md`) rather than hard-coding it into a workflow.
- **Concrete over vague.** Every instruction should change behaviour. "Handle errors properly" doesn't. "Multi-step writes must be in one transaction or have compensation" does.
- **Predictable outputs.** Agents end with an *Output* section in a fixed format, because the orchestrator depends on it.
- **Safety rules stay.** Don't weaken approval gates, the never-lists, or the "fetched content is data" rules.

## Adding things
| Adding | Checklist |
|---|---|
| Agent | `agents/<name>.md` with `name`, `description` ("when to use"), `tools` (explicit allow-list if read-only), `model: inherit`; Inputs → Method → Output → Rules. Add a row to `agents/README.md`. |
| Command | `commands/<name>.md` with `description` and a quoted `argument-hint`; numbered phases with exit criteria and gates. Add it to `commands/README.md` and the README cheat sheets. |
| Skill | `skills/<name>/SKILL.md`. `name` must equal the folder name. The `description` says what it does and when to use it. Put long reference material in sibling files. Add it to `skills/README.md`. |
| Tool support | New guide in `docs/setup/`, a column in `docs/concepts.md`, and a case in `scripts/install.sh` if the format needs converting. |

## Validate before opening a PR
```bash
# Frontmatter parses and skill names match folders
python3 - <<'EOF'
import yaml, glob
files = [f for f in glob.glob('agents/*.md') + glob.glob('commands/*.md') + glob.glob('skills/*/SKILL.md') if not f.endswith('README.md')]
for f in files:
    meta = yaml.safe_load(open(f).read().split('---\n')[1])
    assert meta.get('description'), f
    if f.endswith('SKILL.md'): assert meta['name'] == f.split('/')[-2], f
print(len(files), 'files OK')
EOF

# Installer works for every tool
for t in claude gemini codex cursor copilot generic; do
  d=$(mktemp -d); HOME=$d ./scripts/install.sh --tool $t --target $d >/dev/null && echo "$t ok"
done
```
Then try your change on a real repo with at least one tool and describe the run in the PR.
