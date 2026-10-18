# Stack Matrix

Detection signals and default commands by ecosystem. Use when project memory, CI, and scripts don't say otherwise. Always prefer the project's wrapper/script over these defaults.

## JavaScript / TypeScript

| Aspect | Signal | Default command |
|---|---|---|
| Package manager | lockfile (see SKILL.md) | `npm ci` / `pnpm i --frozen-lockfile` / `yarn install --immutable` / `bun install --frozen-lockfile` |
| Unit: Vitest | `vitest` dep, `vitest.config.*` | `npx vitest run` |
| Unit: Jest | `jest` dep, `jest.config.*`, `"jest"` in package.json | `npx jest --ci` |
| Unit: Mocha | `mocha` dep, `.mocharc.*` | `npx mocha` |
| Unit: Node test runner | `node --test` in scripts | `node --test` |
| Unit: Bun / Deno | `bun test` / `deno.json` | `bun test` / `deno test` |
| Component | `@testing-library/*`, `@vue/test-utils`, Storybook `@storybook/test` | via unit runner |
| E2E: Playwright | `@playwright/test`, `playwright.config.*` | `npx playwright test` |
| E2E: Cypress | `cypress` dep, `cypress.config.*` | `npx cypress run` |
| E2E: WebdriverIO | `@wdio/*`, `wdio.conf.*` | `npx wdio run wdio.conf.ts` |
| Mobile E2E | `detox` / `.maestro/` / `appium` | `detox test` / `maestro test .maestro` |
| Lint | `eslint.config.*`, `.eslintrc*`, `biome.json`, `oxlint` | `npx eslint .` / `npx biome check .` |
| Format | `.prettierrc*`, `biome.json`, `dprint.json` | `npx prettier --check .` |
| Types | `tsconfig.json` | `npx tsc --noEmit` (or `vue-tsc`, `svelte-check`, `astro check`) |
| Build | `build` script | `npm run build` |
| UI frameworks (dev URL) | `next` (:3000), `vite` (:5173), `@angular/core` (`ng serve` :4200), `nuxt` (:3000), `@sveltejs/kit` (:5173), `astro` (:4321), `@remix-run/*`/`react-router` (:5173/:3000), `gatsby` (:8000), `react-scripts` (:3000), `expo`/`react-native` (mobile) | `npm run dev` |
| API frameworks | `express`, `fastify`, `@nestjs/core`, `koa`, `hono`, `@hapi/hapi`, `apollo-server`/`@apollo/server`, `graphql-yoga`, `trpc`, Next/Nuxt API routes | `npm run dev` / `npm start` |
| API test libs | `supertest`, `msw`, `nock`, `pactum`, `@nestjs/testing` | – |

## Python

| Aspect | Signal | Default command |
|---|---|---|
| Env/manager | `uv.lock`, `poetry.lock`, `Pipfile.lock`, `pdm.lock`, `requirements*.txt` | `uv sync` / `poetry install` / `pipenv install --dev` / `pip install -r requirements-dev.txt` |
| Runner prefix | manager | `uv run` / `poetry run` / `pipenv run` / none |
| Unit: pytest | `pytest` dep, `[tool.pytest.ini_options]`, `pytest.ini`, `conftest.py` | `pytest -q` |
| Unit: unittest | `test*.py` with `unittest.TestCase`, no pytest | `python -m unittest discover` |
| Django | `django` dep, `manage.py` | `python manage.py test` (or pytest-django) · dev `:8000` |
| Flask / FastAPI / Starlette / Litestar | deps | `flask run` (:5000) / `uvicorn app.main:app --reload` (:8000) |
| Multi-env | `tox.ini`, `noxfile.py` | `tox` / `nox` |
| Lint/format | `ruff` (in pyproject), `.flake8`, `black`, `isort`, `pylint` | `ruff check .` + `ruff format --check .` |
| Types | `mypy.ini`/`[tool.mypy]`, `pyrightconfig.json`/`[tool.pyright]` | `mypy .` / `pyright` |
| API test libs | `httpx`, `requests`, FastAPI `TestClient`, `pytest-django` client, `schemathesis` | – |
| E2E | `pytest-playwright`, `selenium` | `pytest --browser chromium` |

## Go
| Aspect | Signal | Default |
|---|---|---|
| Tests | `*_test.go` | `go test ./...` (add `-race` if CI does) |
| Lint | `.golangci.yml` | `golangci-lint run` |
| Format/vet | – | `gofmt -l .` (must be empty), `go vet ./...` |
| Build | `go.mod` | `go build ./...` |
| API | `net/http`, `gin`, `echo`, `chi`, `fiber`, `grpc` | `go run ./cmd/<svc>` |
| Test libs | `testify`, `httptest`, `gomock`/`mockery`, `testcontainers-go` | – |

## Java / Kotlin (JVM)
| Aspect | Signal | Default |
|---|---|---|
| Build | `pom.xml` / `build.gradle(.kts)` | `./mvnw -B verify` / `./gradlew build` |
| Tests | JUnit 5 (`junit-jupiter`), TestNG, Kotest, Spock | `./mvnw test` / `./gradlew test` |
| Lint/format | Checkstyle, SpotBugs, PMD, Spotless, ktlint, detekt | `./gradlew spotlessCheck detekt` / `./mvnw checkstyle:check` |
| API | Spring Boot (`:8080`, `/actuator/health`), Quarkus (`:8080`, `/q/health`), Micronaut, Ktor | `./mvnw spring-boot:run` / `./gradlew bootRun` / `quarkus dev` |
| API test libs | MockMvc, WebTestClient, REST Assured, `@SpringBootTest`, Testcontainers, WireMock | – |
| Android | `com.android.application` plugin | `./gradlew testDebugUnitTest`, `connectedAndroidTest`, Espresso |

## .NET (C#, F#)
| Aspect | Signal | Default |
|---|---|---|
| Build | `*.sln`, `*.csproj` | `dotnet build` |
| Tests | xUnit / NUnit / MSTest package refs in `*.Tests.csproj` | `dotnet test` |
| Format/analyzers | `.editorconfig` | `dotnet format --verify-no-changes` |
| API | ASP.NET Core (`Microsoft.AspNetCore`) — see `launchSettings.json` for port | `dotnet run --project <Api>` |
| API test libs | `WebApplicationFactory`, `FluentAssertions`, `Testcontainers`, `Verify` | – |
| UI | Blazor, MAUI | bUnit, Playwright for .NET |

## Ruby
| Aspect | Signal | Default |
|---|---|---|
| Tests | `spec/` + `rspec` / `test/` + `minitest` | `bundle exec rspec` / `bin/rails test` |
| Lint | `.rubocop.yml`, `standard` | `bundle exec rubocop` |
| API/UI | Rails (`:3000`), Sinatra, Hanami | `bin/rails server` / `bin/dev` |
| E2E | Capybara system tests, `cuprite`, `selenium-webdriver` | `bin/rails test:system` |

## PHP
| Aspect | Signal | Default |
|---|---|---|
| Tests | `phpunit.xml(.dist)` / Pest (`pestphp/pest`) | `vendor/bin/phpunit` / `vendor/bin/pest` |
| Lint/static | PHPStan, Psalm, PHP-CS-Fixer, PHP_CodeSniffer, Pint | `vendor/bin/phpstan analyse` / `vendor/bin/pint --test` |
| API/UI | Laravel (`php artisan serve` :8000), Symfony (`symfony serve`) | – |
| E2E | Laravel Dusk, Codeception | `php artisan dusk` |

## Rust
| Aspect | Signal | Default |
|---|---|---|
| Tests | `Cargo.toml` | `cargo test` (or `cargo nextest run` if configured) |
| Lint/format | – | `cargo clippy -- -D warnings`, `cargo fmt --check` |
| API | `axum`, `actix-web`, `rocket`, `warp`, `tonic` | `cargo run` |

## Others
| Ecosystem | Tests | Lint/format | Notes |
|---|---|---|---|
| Elixir | `mix test` | `mix format --check-formatted`, `mix credo` | Phoenix `:4000`, `mix phx.server` |
| Dart/Flutter | `flutter test` / `dart test`; `integration_test/` | `dart analyze`, `dart format --set-exit-if-changed .` | |
| Swift | `swift test` / `xcodebuild test -scheme <S>` | SwiftLint, swift-format | XCUITest for UI |
| Scala | `sbt test` | scalafmt (`sbt scalafmtCheckAll`) | Play `:9000` |
| C/C++ | `ctest` (CMake), GoogleTest, Catch2 | clang-format, clang-tidy | `cmake -B build && cmake --build build` |
| Haskell | `stack test` / `cabal test` | hlint, ormolu/fourmolu | |
| Terraform/IaC | `terraform validate`, `tflint`, `terratest`, `checkov` | `terraform fmt -check` | Never `apply` |
| Shell | `bats` | `shellcheck`, `shfmt -d` | |

## Defaults when NO test framework exists (ask before adding)
| Ecosystem | Recommend |
|---|---|
| JS/TS (Vite-based) | Vitest (+ Testing Library for UI) |
| JS/TS (other) | Vitest or Jest; Node's built-in runner for small libs |
| Python | pytest |
| Go / Rust | built-in |
| JVM | JUnit 5 (+ AssertJ, Mockito/MockK) |
| .NET | xUnit |
| Ruby | RSpec (or Minitest in Rails defaults) |
| PHP | Pest or PHPUnit |
| Web E2E (any) | Playwright |
