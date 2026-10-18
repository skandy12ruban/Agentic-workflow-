---
name: stack-detection
description: Detect a repository's languages, frameworks, package manager, test frameworks, lint/format/typecheck/build commands, E2E tooling, and whether it has a UI and/or API surface - producing a Stack Profile used by planning, testing, CI and E2E phases. Use before planning, testing, or running CI checks in an unfamiliar repo or monorepo package.
---

# Stack Detection

Produce a **Stack Profile** from evidence in the repo. Never assume a stack from the repo name or from what's popular.

## Order of precedence
1. **Project memory** `Workflow Configuration` (explicit beats detected — always).
2. **CI config** (what CI actually runs is what "passing" means).
3. **Task runner scripts** (`package.json` scripts, `Makefile`, `justfile`, `Taskfile.yml`, `tox.ini`, `noxfile.py`, `composer.json` scripts, `mix.exs` aliases).
4. **Manifests and config files** (see [`stack-matrix.md`](stack-matrix.md)).
5. **Ecosystem defaults** (last resort; mark as `assumed`).

## Procedure
1. **List manifests** at the root and one/two levels down:
   `package.json, pnpm-workspace.yaml, turbo.json, nx.json, lerna.json, pyproject.toml, requirements*.txt, setup.py, Pipfile, go.mod, go.work, Cargo.toml, pom.xml, build.gradle(.kts), settings.gradle(.kts), *.csproj, *.sln, Gemfile, composer.json, mix.exs, pubspec.yaml, Package.swift, *.xcodeproj, CMakeLists.txt, deno.json, bun.lockb, build.sbt, project.clj, stack.yaml, *.cabal`.
2. **Monorepo?** If there's a workspace file or multiple manifests, build the profile **per package** touched by the task, not for the whole repo. Note the root-level orchestrator (turbo/nx/bazel/pants/gradle multi-project) and how to run a single package's tasks through it (`turbo run test --filter=web`, `nx test web`, `pnpm --filter web test`, `gradle :app:test`, `bazel test //app/...`).
3. **Package manager** from the lockfile — never mix: `pnpm-lock.yaml`→pnpm, `yarn.lock`→yarn, `package-lock.json`→npm, `bun.lockb`/`bun.lock`→bun, `poetry.lock`→poetry, `uv.lock`→uv, `Pipfile.lock`→pipenv, `pdm.lock`→pdm, `Gemfile.lock`→bundler, `composer.lock`→composer, `Cargo.lock`→cargo, `go.sum`→go modules. Check `packageManager` field in `package.json` and `.tool-versions`/`.nvmrc`/`.python-version`/`mise.toml` for versions.
4. **Frameworks and tools** — match dependencies and config files against [`stack-matrix.md`](stack-matrix.md).
5. **Commands** — for each of `install, format_check, lint, typecheck, build, test_unit, test_integration, test_e2e, dev_server`, take the first found from: project memory → CI → scripts → matrix default. Record *where* each came from.
6. **Surfaces:**
   - **UI** if any: frontend framework dependency; `pages/`, `app/`, `src/components/`, `templates/`, `views/`; mobile project; Storybook. Record `dev_server` command + default URL/port.
   - **API** if any: server framework dependency; routes/controllers/handlers dirs; OpenAPI/GraphQL/proto files. Record start command, port, health endpoint, contract path.
7. **Test infrastructure:** fixtures/factories dirs, test DB setup (docker compose services, testcontainers, sqlite in-memory), env file for tests (`.env.test`, `.env.example`), coverage config.
8. **Verify cheaply** (optional but recommended): run `--version` on detected tools or `<runner> --help` / list-tests (`npx vitest list`, `pytest --collect-only -q`, `go test -list . ./...`) to confirm commands work. Don't run full suites here.

## Output: Stack Profile
Append to `.agentic/runs/<RUN-ID>/context.md` (or return inline):

```markdown
## Stack Profile — <package or "root">
| Aspect | Value | Source |
|---|---|---|
| Language(s) | TypeScript 5.x, Node 20 | package.json, .nvmrc |
| Package manager | pnpm 9 | pnpm-lock.yaml, packageManager |
| Frameworks | Next.js 14 (UI+API routes), Prisma | deps |
| Unit tests | Vitest — `pnpm test` | package.json scripts |
| E2E | Playwright — `pnpm e2e` | playwright.config.ts |
| Lint / format | ESLint `pnpm lint` / Prettier `pnpm format:check` | CI workflow |
| Typecheck | `pnpm tsc --noEmit` | CI workflow |
| Build | `pnpm build` | scripts |
| Dev server | `pnpm dev` → http://localhost:3000 | scripts + Next default |
| API | Next route handlers `app/api/**`; no OpenAPI | dirs |
| Test infra | docker-compose `db` (postgres:16), `.env.test` | files |
| Surfaces | UI ✅ API ✅ | |
| Assumed (unverified) | – | |
```

## Pitfalls
- A `jest` dependency in a repo whose `test` script runs `vitest` → the script wins.
- Python: `pytest` may be configured in `pyproject.toml [tool.pytest.ini_options]`, `pytest.ini`, `setup.cfg`, or `tox.ini`. `manage.py test` means Django's runner unless `pytest-django` is configured.
- Java/Kotlin: prefer the wrapper (`./mvnw`, `./gradlew`) over a global install.
- .NET: tests are separate projects (`*.Tests.csproj`); run `dotnet test <sln or project>`.
- Don't run `install` with a different manager than the lockfile's — it rewrites lockfiles.
