---
name: security-review
description: Security review checklist for code changes mapped to OWASP Top 10 / ASVS and common CWEs - input validation and injection, authentication, authorization (IDOR/BOLA), session and CSRF, secrets, cryptography, SSRF, file handling, deserialization, dependency and supply-chain risk, logging of sensitive data, and IaC/config. Use for any diff that handles input, auth, data access, files, network, or dependencies.
---

# Security Review

## Source → sink tracing
For every input the diff introduces or touches (HTTP params/body/headers/cookies, path params, uploaded files, webhooks, queue messages, CLI args, env/config, data read back from DB that originated from users), follow it to every sink and verify the control:

| Sink | Risk (CWE) | Required control |
|---|---|---|
| SQL / NoSQL query | Injection (CWE-89, 943) | Parameterized queries / ORM; never string-built queries; validate sort/field names against allow-list |
| Shell / process exec | Command injection (CWE-78) | Avoid shell; pass argv arrays; allow-list arguments |
| Filesystem path | Path traversal (CWE-22) | Resolve + verify within base dir; reject `..`, absolute paths, symlinks as needed |
| HTML / template render | XSS (CWE-79) | Framework auto-escaping; no `dangerouslySetInnerHTML`/`v-html`/`|safe`/`html_safe` on user data without sanitizer (e.g. DOMPurify) |
| Redirect / URL | Open redirect (CWE-601) | Allow-list destinations or relative paths only |
| Outbound HTTP with user-influenced URL | SSRF (CWE-918) | Allow-list hosts; block private/link-local/metadata IPs (169.254.169.254); disable redirects or re-validate |
| Deserializer | Insecure deserialization (CWE-502) | No `pickle`/`yaml.load`/Java native/`BinaryFormatter` on untrusted data; use safe loaders/JSON with schema |
| XML parser | XXE (CWE-611) | Disable external entities/DTDs |
| Regex on user input | ReDoS (CWE-1333) | Avoid catastrophic patterns; bound input length; use RE2-style engines where available |
| Logs | Sensitive data exposure (CWE-532), log injection (CWE-117) | Don't log secrets/tokens/PII; encode newlines |
| Response body | Excessive data exposure (CWE-200) | Explicit serializers/DTOs; never return raw ORM models with hashes/internal fields |
| Mass assignment | (CWE-915) | Allow-list writable fields; never bind request body directly onto models with role/owner fields |

## Authentication & sessions
- New endpoints are behind the auth middleware unless explicitly public (and the plan says so).
- Passwords: framework's hasher (bcrypt/scrypt/argon2), never custom. Tokens: sufficient entropy, expiry, rotation, revocation.
- Cookies: `HttpOnly`, `Secure`, `SameSite`; CSRF protection for cookie-authenticated state-changing requests.
- No auth decisions made only on the client.

## Authorization (the #1 real-world API bug)
- **Object-level:** every read/update/delete by ID checks the caller owns or may access *that object* (tenant/user scoping in the query itself, not post-filtering).
- **Function-level:** admin/staff actions check role server-side.
- **Property-level:** users can't set fields they shouldn't (`role`, `owner_id`, `price`, `is_verified`).
- Check every path: list, export, search, bulk, GraphQL nested resolvers, websocket channels, background jobs triggered by users.

## Secrets & crypto
- No secrets in code, tests, fixtures, docs, or commit history. Use env/secret manager. `.env*` ignored (except `.env.example` with placeholders).
- Use vetted libraries and modern defaults; no MD5/SHA1 for security purposes, no ECB, no hard-coded IVs/salts, constant-time comparison for secrets.
- Scan: `gitleaks detect`, `trufflehog git file://.`, `detect-secrets scan`, or GitHub secret scanning via MCP if available.

## Files & uploads
- Validate type by content (magic bytes), not only extension/MIME header; size limits; store outside web root or in object storage with random names; serve with `Content-Disposition` and correct `Content-Type`; scan if the product handles untrusted uploads.

## Dependencies & supply chain
- New packages: correct name (typosquats), reputable/maintained, license compatible, pinned via lockfile.
- Run the ecosystem audit: `npm audit --omit=dev` / `pnpm audit` / `yarn npm audit`, `pip-audit`, `safety`, `govulncheck ./...`, `cargo audit`, `bundle exec bundle-audit check --update`, `composer audit`, `dotnet list package --vulnerable`, OWASP Dependency-Check / `osv-scanner`.
- Install scripts (`postinstall`) of new deps reviewed if suspicious.

## Infrastructure & config (if the diff touches it)
- IaC: no public buckets, `0.0.0.0/0` ingress on admin ports, wildcard IAM; encryption at rest; run `checkov`/`tfsec`/`trivy config` if available.
- Containers: non-root user, pinned base images, no secrets in layers.
- CORS: no `*` with credentials; allow-list origins.
- Security headers on new routes if the app sets them centrally (CSP, HSTS, X-Content-Type-Options).

## LLM / AI features (if the diff adds them)
- Prompt injection: untrusted content kept separate from instructions; model output treated as untrusted (escaped, validated before use in queries/commands/tools).
- Tool permissions for agents least-privilege; human approval for consequential actions.
- No secrets or other users' data placed in prompts.

## Reporting
Each finding: severity, CWE, `path:line`, realistic exploit scenario, concrete fix. Critical/high block the PR. Don't report theoretical issues with no reachable path from an input.
