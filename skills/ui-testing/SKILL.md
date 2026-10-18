---
name: ui-testing
description: Verify web (and mobile-web) UI changes in a real browser through a browser-automation MCP such as Playwright MCP or Chrome DevTools MCP - starting the dev server, journey design from acceptance criteria, robust element targeting, console/network inspection, accessibility, responsive checks, visual evidence - and codify journeys as E2E specs. Use for /ui-test or any frontend change in /task.
---

# UI Testing

## 1. Start the app
| Framework | Command (prefer project script) | Default URL |
|---|---|---|
| Next.js | `npm run dev` | http://localhost:3000 |
| Vite (React/Vue/Svelte/Solid) | `npm run dev` | http://localhost:5173 |
| Angular | `npm start` / `ng serve` | http://localhost:4200 |
| Nuxt | `npm run dev` | http://localhost:3000 |
| SvelteKit | `npm run dev` | http://localhost:5173 |
| Astro | `npm run dev` | http://localhost:4321 |
| Remix / React Router | `npm run dev` | http://localhost:5173 or :3000 |
| Create React App | `npm start` | http://localhost:3000 |
| Django / Rails / Laravel / Phoenix (server-rendered) | `manage.py runserver` / `bin/dev` / `artisan serve` / `mix phx.server` | :8000 / :3000 / :8000 / :4000 |
| Storybook (component-level) | `npm run storybook` | http://localhost:6006 |

Run in the background, capture logs to `.agentic/runs/<RUN-ID>/artifacts/dev-server.log`, and poll the URL until it returns 200 (or the framework's "ready" log line). If the port is taken, check whether it's already the app (reuse) or pick the next port via the framework's flag. Use test env vars (`.env.test`, `.env.development.local`) — never production keys.

## 2. Browser MCP tool map
Different servers name tools differently; use whatever is available:

| Intent | Playwright MCP (typical) | Chrome DevTools MCP (typical) |
|---|---|---|
| Open URL | `browser_navigate` | `navigate_page` / `new_page` |
| Read page structure | `browser_snapshot` (accessibility tree with element refs) | `take_snapshot` |
| Click / type / select | `browser_click`, `browser_type`, `browser_fill_form`, `browser_select_option`, `browser_press_key` | `click`, `fill`, `fill_form`, `press_key` |
| Wait | `browser_wait_for` (text / time) | `wait_for` |
| Screenshot | `browser_take_screenshot` | `take_screenshot` |
| Console | `browser_console_messages` | `list_console_messages` |
| Network | `browser_network_requests` | `list_network_requests`, `get_network_request` |
| Viewport | `browser_resize` | `resize_page`, `emulate` |
| Evaluate JS | `browser_evaluate` | `evaluate_script` |
| Performance | – | `performance_start_trace` / `performance_stop_trace` |

Always **snapshot before acting** and target elements by role + accessible name / label / visible text from the snapshot. Avoid brittle CSS/XPath.

## 3. Journey design
From each acceptance criterion write a journey:
```
J1 (AC1): Customer cancels a pending order
  Pre: logged in as test customer; order #123 status=pending (seed)
  1. Go to /orders/123            → heading "Order #123", status "Pending"
  2. Click "Cancel order"         → confirmation dialog appears
  3. Click "Confirm"              → toast "Order cancelled"; status badge "Cancelled"
  4. Reload                       → status persists "Cancelled"
  Evidence: screenshot after 3; network POST /api/orders/123/cancel → 200
```
Add per form/action: invalid input, empty state, unauthorized user, slow/failed backend (if mockable via the app's dev tooling).

## 4. Checks on every journey
- **Functional:** expected text/state after each step, persisted after reload.
- **Console:** no uncaught errors or React/Vue warnings introduced by the change (compare to baseline on the base branch if noisy).
- **Network:** no 4xx/5xx from app APIs on the happy path; no requests to unexpected hosts; no duplicate submits.
- **Accessibility:** controls have accessible names; dialog traps focus and closes on Escape; keyboard-only completion possible (Tab/Shift+Tab/Enter/Space); visible focus indicator; images have alt; form errors are announced/associated (aria-describedby). If `@axe-core/playwright` or similar exists in the project, run it on the page.
- **Responsive:** primary journey at 375×812 (mobile) and 1440×900 (desktop); look for overflow, overlap, hidden controls, horizontal scroll.
- **States:** loading skeleton/spinner, empty state, error state.
- **Visual sanity:** compare against the design (Figma MCP / attached mock) if provided; otherwise against adjacent existing UI for consistency.

## 5. Evidence
Screenshots named `<journey>-<step>-<viewport>.png` in `artifacts/`. For failures include: steps to reproduce, expected vs actual, screenshot, relevant console/network entries.

## 6. Codify as E2E specs
If the project has an E2E framework, add specs mirroring the journeys:
- Follow existing structure (page objects/fixtures/auth setup, `data-testid` conventions if used).
- Use role/label locators; web-first assertions (auto-waiting) — no fixed sleeps.
- Seed data through the project's API/fixtures, not by clicking through setup.
- Run headless: `npx playwright test <spec>` / `npx cypress run --spec <spec>`; keep traces/screenshots on failure.

## 7. Mobile apps
For native/React Native/Flutter apps: use the project's tool (Detox, Maestro, Appium, Espresso, XCUITest, Flutter `integration_test`) and simulators/emulators if available; a mobile MCP (if configured) can drive them interactively. Otherwise, limit to component tests and report the gap.

## 8. Clean up
Stop servers you started (by PID), close browser contexts, remove temporary seed data if the project has a reset.
