# taweel-website (React + Capacitor / Node + Express) analysis

## Summary for comparison

```
PROJECT: taweel-website | path: Chinaparts/New Projects/taweel-website | stack: React 18.2 (CRA react-scripts 5.0.1) + Capacitor 8 / Node (CI uses Node 20) + Express 4.18 + Mongoose 8 | last commit: 2026-09-16 | source files: 51 (frontend/src 36 + backend 15 JS; plus 11 aux Python/k6 files)
ARCH: layer-by-type SPA + flat Express MVC-lite. Frontend is organized by file type (pages/components/context/utils/config/i18n) with large page components (500-1200 lines) that hold inline sub-components. Backend has routes that also act as controllers and services, Mongoose models, a single auth middleware, and utils/services. There is no domain layer.
STATE: one React Context (frontend/src/context/AppContext.js: user, loading, theme, language, login/logout, updatePlan, checkAuth) plus local useState in pages. No redux/zustand/react-query and no server-state cache.
DI: none. Backend uses CommonJS require with module singletons. Frontend configures a global axios instance.
ROUTING: react-router-dom v6 in frontend/src/App.js. Guards are the <Protected>/<Public> wrappers (auth only). There is no admin role guard: /admin/dashboard relies on the API returning 403 and then redirects. Deep links: HashRouter on native, BrowserRouter on web, and a custom URL scheme handled in frontend/src/capacitorBridge.js.
NETWORK: frontend uses axios global defaults (baseURL from REACT_APP_API_URL, withCredentials) plus fetch+ReadableStream for chat streaming. Interceptors: one request interceptor that adds a Bearer token from localStorage (AppContext.js). Response interceptor: none. Token refresh: n. Retry: n. Error mapping: inline `err.response?.data?.message || t("error")` in every call. Backend calls the chatbot webhook, OpenAI, geo and FX APIs with axios. Files: frontend/src/context/AppContext.js, frontend/src/pages/Chat.jsx, backend/routes/chat.js
RESULT_TYPE: exceptions with try/catch. API errors are `{message}` JSON plus an HTTP status. There is a central Express error handler in backend/server.js (it maps Mongo 11000 duplicate keys to 400). No typed error hierarchy.
STORAGE: raw localStorage keys (auth_token, taweelai_theme, taweelai_lang, taweelai_fontsize, taweelai_notifications, taweel_app_zoom/pan, taweel_welcome_seen) and sessionStorage. No wrapper except frontend/src/utils/notifications.js. Server side is MongoDB via Mongoose plus in-memory Map caches.
L10N: i18next + react-i18next. Languages: en and ar (244 keys each). Default ar, fallback en. Translations are inline in frontend/src/i18n/index.js, with Arabic stored as \u escapes. 327 t() calls. Hardcoded UI strings: many (~130 inline `isAr ? "..." : "..."` ternaries, 67 of them in AdminDashboard; PaymentSuccess is English-only; all backend messages are English).
RTL: Directional=13 (CSS logical props 11 + JSX inline 2) vs LeftRight=70 (CSS 43 + JSX inline 27). RTL relies on 55 `[dir="rtl"]` override selectors in index.css. <html dir/lang> is set from the language.
THEME: frontend/src/index.css (2988 lines). Dark mode: y (data-theme on <html>, saved in localStorage and in server preferences, pre-paint script in public/index.html). Component themes: n/a (global CSS classes .btn-primary/.form-input/.modal-box/.spinner). Colors: 71 CSS custom properties under :root[data-theme], plus a `T` token object in AdminDashboard.jsx and 57 hex literals in JSX. Text styles class: none. Fonts: Google Fonts @import of Inter, IBM Plex Sans Arabic, Cairo, Nunito, Tajawal and Outfit. No Tailwind/MUI.
RESPONSIVE: plain CSS media queries. Breakpoints (width): 380 / 560 / 768-769 / 900 / 980 / 1024 / 1400px, plus (hover:none) and (pointer:coarse). frontend/src/viewportSync.js writes visualViewport values to CSS vars (--app-vh, --app-vw, kb-open class). frontend/src/appZoom.js adds custom pinch and ctrl-wheel zoom/pan.
TEXT_SCALING: user font-size setting in frontend/src/pages/Settings.jsx sets --site-font-size, clamped to 12-20px (default 14) and saved in localStorage. appZoom.js has zoom >= 1 with no maximum.
ENV/FLAVORS: CRA REACT_APP_* vars (API_URL, APPLE_CLIENT_ID, APPLE_REDIRECT_URI, APPLE_PRODUCT_HOUR/MONTHLY, USE_STREAM), with hardcoded fallbacks repeated in 3 files. Backend uses dotenv (backend/.env.example lists 21 keys, but the code reads about 40: EDFAPAY_*, APPLE_IAP_*, OPENAI_*, CHATBOT_STREAM_URL, EXTRA_CORS_ORIGINS...). No flavors. Deploy is GitHub Actions to a VPS over SSH (.github/workflows/deploy.yml). backend/vercel.json and frontend/railway.json are leftovers.
LOGGING: console.* only (frontend 13, backend 104, emoji-prefixed). Mongo PaymentLog collection is an immutable audit log.
ANALYTICS/CRASH: none
PUSH: none. In-app notifications are localStorage-only (frontend/src/utils/notifications.js + components/NotificationsPanel.jsx).
PAYMENTS/IAP: EdfaPay hosted checkout on web/Android (backend/routes/payment.js: md5/sha1 request hash, webhook hash, out-of-band status check, atomic idempotent claim). Apple IAP on iOS via @capgo/native-purchases on the client (frontend/src/utils/appleIAP.js) and @apple/app-store-server-library on the server (verify with production-then-sandbox fallback, App Store Server Notifications V2 webhook).
PERMISSIONS: none
DEEP_LINKS: custom scheme `<app-scheme>://callback?token=` (iOS Info.plist CFBundleURLSchemes) handled by @capacitor/app appUrlOpen and getLaunchUrl in frontend/src/capacitorBridge.js (OAuth return). Public share links /shared/:shareToken.
MEDIA/FILES: none (static SVG logos only)
TESTS: 0 automated unit/integration tests. backend/scripts/test-apple-iap.js is a manual script; loadtest/k6/*.js (5 scenarios + lib) and loadtest/security-probe.js cover load and security; TEST_PLAN.md is a manual plan. CI only builds the frontend and runs `node --check` on the backend and py_compile on the chatbot.
LINTS: CRA `eslintConfig: react-app` only. No prettier, no TypeScript, no backend linter.
BUILD: CRA (react-scripts 5.0.1, deprecated). `build:cap` builds with PUBLIC_URL=. for Capacitor. Sources have been run through esbuild (19 files end in `var stdin_default`; strip-comments in root package.json).
LANG: JavaScript/JSX only (TypeScript only in capacitor.config.ts). Backend is CommonJS.
BACKEND: Express 4.18 (backend/server.js) with helmet, cors (origin allowlist incl. capacitor://localhost), express-rate-limit (global 300/15min plus per-route limiters), cookie-parser and passport.
DB/ORM: MongoDB + Mongoose 8. backend/models/User.js; backend/models/index.js holds Chat, Order, Subscription, PaymentLog, SharedChat and PendingUser (TTL).
AUTH: JWT (7d) in an httpOnly cookie and also as a Bearer token from localStorage. Revocation through a `tokenVersion` claim. Email/password with bcrypt(12) and a 6-digit email code held in PendingUser. Google OAuth (passport-google-oauth20). Sign in with Apple (apple-signin-auth). Roles user/admin. No refresh token. Files: backend/middleware/auth.js, backend/routes/auth.js
VALIDATION: express-validator on the auth routes only (signup/signin/verify/change-password); manual checks elsewhere. Frontend uses an ad-hoc validate() per form.
CAPACITOR: yes. Capacitor 8 (frontend/capacitor.config.ts, gitignored, webDir=build). iOS project at frontend/ios (SPM, not yet committed). The @capacitor/android dependency is installed but there is no android/ folder. Plugins: app, browser, @capacitor-community/apple-sign-in (patched via patch-package, but there is no postinstall), @capgo/native-purchases. @capacitor/assets generates icons and splash.
FOLDERS: frontend/src/{pages,components,context,i18n,utils,config,legal} plus root helpers (capacitorBridge.js, viewportSync.js, appZoom.js). backend/{routes,models,middleware,services,utils,scripts} plus server.js. Repo extras: chatbot/ (Python FastAPI + LangChain + PGVector + Redis RAG service with SSE), face_id/ (Flask + insightface, retired), pgvector/docker-compose.yml, loadtest/.
RELATED: Chinaparts/New Projects/taweelai is a stale clone of the same git repo (same origin), with HEAD at d1a62e8 (2026-07-20), 20 commits behind taweel-website. Its whole working tree is deleted (109 tracked files show as deleted; only .git, .gitignore and .vscode remain). It has nothing to analyze and taweel-website supersedes it.
BEST_GENERIC_FILES (top ≤15 reusable infra files, best first):
- frontend/src/viewportSync.js — copies visualViewport height/width/top into CSS vars and toggles a `kb-open` class for the iOS overlay keyboard; locks body scroll on input focus — quality 4 — coupling: none
- backend/middleware/auth.js — `protect` (cookie or Bearer JWT, tokenVersion revocation, banned check), `signToken`, `sendToken` (httpOnly cookie + JSON) — quality 4 — coupling: low (User model, response user shape)
- frontend/src/utils/appleIAP.js — @capgo/native-purchases wrapper: getProducts (StoreKit priceString), purchase then server verify, restore — quality 4 — coupling: low (product IDs via env, endpoint path)
- frontend/src/components/SocialAuthButtons.jsx — Google (Capacitor in-app Browser on native, <a href> on web) and Apple sign-in buttons — quality 4 — coupling: low (useApp, endpoint paths)
- backend/utils/appleAuth.js — verifyAppleIdentityToken (audience check, email/emailVerified) — quality 4 — coupling: none
- frontend/src/capacitorBridge.js — Capacitor deep-link handler (appUrlOpen + getLaunchUrl): extracts the token, closes the in-app browser and routes to the callback — quality 3 — coupling: low (localStorage key, route)
- backend/server.js — Express bootstrap: CORS allowlist incl. Capacitor schemes + EXTRA_CORS_ORIGINS env, helmet, rate limit, no-store API headers, SPA static serving with immutable /static caching, 404 + central error handler — quality 3 — coupling: medium (hardcoded origin and alert recipient, mongoose connect inline, setInterval monitor)
- backend/utils/clientGeo.js — proxy-aware client IP (cf-connecting-ip/x-real-ip/XFF), private-IP detection, geo lookup with per-session TTL cache — quality 3 — coupling: low
- backend/utils/email.js — nodemailer SMTP transport from env + sendEmail + verification-code mail — quality 3 — coupling: medium (branded inline HTML, transporter rebuilt on every send)
- frontend/src/context/AppContext.js — auth/theme/language provider + axios defaults/interceptor + useApp() guard hook — quality 3 — coupling: high (mixes HTTP config, auth, theme and l10n; app-specific plan helpers)
- frontend/src/components/MarkdownMessage.jsx — dependency-free safe markdown renderer (h1-h3, bullet/numbered lists, bold/italic/code/links/URLs, no innerHTML) — quality 3 — coupling: none (CSS vars)
- backend/models/index.js (PendingUser + PaymentLog) — TTL pre-verification signup collection; immutable audit-log schema — quality 4 — coupling: low
- frontend/public/index.html (inline scripts) — pre-paint theme from localStorage (no flash) + viewport CSS vars before React mounts — quality 4 — coupling: none
- frontend/src/utils/platform.js — isApp/isWeb/isIOS/isAndroid via Capacitor — quality 4 — coupling: none (trivial)
- backend/routes/payment.js (Apple IAP section, ~L446-623) — App Store Server API client init (PEM/base64/path key), production-then-sandbox transaction lookup, idempotent order creation — quality 3 — coupling: high (inside a 967-line router; the notification webhook does not verify JWS signatures)
GENERIC_WIDGETS (every reusable widget):
- frontend/src/components/Logo.jsx — theme-aware logo image (MutationObserver on data-theme, onError fallback) — size, className, style, variant(full|mark), instanceId — quality 3 — generic? y (asset filenames hardcoded)
- frontend/src/components/IntroSplash.jsx — one-time-per-session animated splash (module flag + sessionStorage) — none — quality 3 — generic? y (word/asset hardcoded)
- frontend/src/components/MarkdownMessage.jsx — chat message markdown renderer — content, isUser — quality 3 — generic? y
- frontend/src/components/SocialAuthButtons.jsx — OAuth button row (Google/Apple) — onError, onLoadingChange — quality 4 — generic? y
- frontend/src/components/NotificationsPanel.jsx — notifications dropdown (read one/all, clear, click-outside close, relative time) — onClose, onUnreadChange — quality 3 — generic? partly (bilingual titleAr/titleEn fields)
- frontend/src/components/UpgradeModal.jsx — paywall modal (geo-priced plans, hour stepper, EdfaPay redirect or Apple IAP, restore) — onClose, onSuccess — quality 3 — generic? n
- frontend/src/components/SessionExpiredModal.jsx — "hour expired, renew" overlay — onRenewed — quality 2 — generic? n (the web path calls a non-existent endpoint)
- frontend/src/pages/AdminDashboard.jsx (inline: Icon, Avatar, Badge, SectionTitle, KpiCard, ChartCard, ChartLegend, DataTable, TR, TD, Btn, Toast) — admin UI kit with chart.js cards and tables — props such as icon/label/value/sub/color/trend, headers/emptyMsg — quality 3 — generic? y, but stuck inside a 1200-line file and styled with an inline `T` token object
- frontend/src/pages/SignIn.jsx, SignUp.jsx, ResetPassword.jsx, Settings.jsx (EyeIcon) — password visibility icon — open/show — quality 2 — generic? y (duplicated 4 times)
- frontend/src/pages/Chat.jsx (inline confirm-delete / rename modals, toast state) — modal markup reusing .modal-overlay/.modal-box CSS — n/a — quality 2 — generic? n (not extracted)
- frontend/src/index.css (CSS-class widgets: .btn-primary, .btn-ghost, .form-input/.form-err/.form-alert, .spinner, .modal-*, .oauth-btn) — style-only primitives — quality 3 — generic? y
NOTABLE_IDEAS: JWT `tokenVersion` revocation for logout-all, password change and ban without a blocklist (backend/middleware/auth.js, routes/auth.js, routes/admin.js); a PendingUser collection with a TTL index instead of an in-memory signup map (backend/models/index.js); an atomic `findOneAndUpdate({status:"pending"})` claim for idempotent webhooks (backend/routes/payment.js ~L385); immutable audit logs via a pre('findOneAndUpdate') throw (models/index.js); Apple IAP verification that falls back from production to sandbox for App Review (routes/payment.js fetchAppleTransaction) and shows StoreKit priceString (utils/appleIAP.js); native Google OAuth via @capacitor/browser that redirects back through a custom scheme with a short-lived `oauth_client=app` cookie (routes/auth.js + capacitorBridge.js); HashRouter on native vs BrowserRouter on web plus `build:cap` with PUBLIC_URL=. (App.js, package.json); a CORS allowlist covering capacitor://, ionic:// and https://localhost (server.js); a pre-paint theme script (public/index.html); visualViewport CSS vars for the iOS keyboard (viewportSync.js); an SSE proxy from the Python chatbot to the client that falls back to a non-stream webhook, with the client reading via fetch ReadableStream (routes/chat.js, pages/Chat.jsx); respond first, then do token accounting and gpt-4o-mini title generation off the request path (routes/chat.js); Express SPA serving with correct cache headers and no-store on /api (server.js); geo-based currency with an FX cache and fallback table (routes/payment.js); CI that builds and syntax-gates before the SSH deploy (.github/workflows/deploy.yml).
SMELLS: sources are esbuild output (19 files with `var stdin_default`, `1e3`/`void 0`/`/* @__PURE__ */`, Arabic as \uXXXX escapes in 11 files, comments stripped); god files: AdminDashboard.jsx 1200, Chat.jsx 744 (~20 useState), WelcomeScreen 662, Settings 519, index.css 2988 and routes/payment.js 967 (pricing+geo+EdfaPay+Apple in one router); duplicated free-limit gating and title generation in /message and /message-stream; free limit `10` hardcoded in 4 places; EyeIcon x4; API URL fallback x3; isNewUser 10-second heuristic x3; 469 inline style objects and 57 hex colors in JSX; ~130 inline isAr ternaries that bypass i18n; physical left/right CSS outnumbers logical properties; hardcoded payer contact defaults, a production origin and an alert recipient in source; security: Apple Server Notifications webhook decodes JWS without signature verification (forgeable renew/refund), HTML emails interpolate user name/reason without escaping, /api/auth/set-cookie accepts any token, admin search passes an unescaped $regex from the query, JWT also kept in localStorage, the 6-digit code is protected only by a rate limit, the raw chatbot webhook response is logged; SessionExpiredModal calls /api/payment/simulate-payment, which does not exist; unused dependencies: csurf (deprecated), multer, googleapis, passport-facebook, docx; Facebook env keys with no strategy; face_id fields left on User; a patch-package patch with no postinstall; no 401 response interceptor; appZoom.js hijacks Ctrl+wheel and Ctrl+/- browser zoom; CRA is deprecated and there is no TypeScript; setInterval monitor in server.js (breaks on serverless; vercel.json present); SignIn forces light theme on mount; .env files and other secret material are tracked in git (paths in final note).
```

---

## 1. Architecture pattern

**Monorepo layout** (root `package.json` only has `glob` and `strip-comments`, used for a one-off comment-stripping pass):

| Folder | What |
|---|---|
| `frontend/` | React 18 SPA built with Create React App. Also a Capacitor 8 shell (iOS project present; Android dependency only). |
| `backend/` | Node/Express 4 REST API with MongoDB through Mongoose. In production it also serves `frontend/build`. |
| `chatbot/` | Python FastAPI RAG service (LangChain + OpenAI + PGVector + Redis). It exposes `/chat` and `/chat/stream` (SSE), and the backend proxies it through `WEBHOOK_URL`. |
| `face_id/` | Python Flask + insightface face-recognition service for admin 2FA. It is retired: the code says "Face-ID has been removed". |
| `pgvector/` | docker-compose for Postgres 16 + pgvector. |
| `loadtest/` | k6 scenarios plus a Node security probe. |
| docs | `README.md`, `PROJECT_TECHNICAL_GUIDE.md`, `TEST_PLAN.md`, iOS/IAP guides. |

**Frontend** groups files by type, with no feature folders. `pages/` holds route screens and does the real work: each page holds its own state, calls axios directly and defines its own sub-components. There is no data, repository or service layer between the UI and HTTP, and no hooks folder. Shared state is a single `AppContext`.

**Backend** is MVC-lite without controllers or services. Each `routes/*.js` file is an Express router whose handlers contain validation, business rules, DB access and third-party calls. `models/` holds the Mongoose schemas, some with instance methods (`User.hasPaidAccess()` and similar). `middleware/auth.js` holds JWT auth. `utils/` and `services/` hold small helpers (email, Apple id-token, geo IP, OpenAI cost API).

**A feature, for example chat:**
- `frontend/src/pages/Chat.jsx` holds the sidebar, sessions, composer, streaming, modals and toasts.
- It calls `backend/routes/chat.js`.
- That router uses the `Chat`/`SharedChat` models from `backend/models/index.js`.
- It also calls the external chatbot webhook and OpenAI.

## 2. Folder tree

```
frontend/
├── capacitor.config.ts        # appId com.example.app, webDir build (gitignored)
├── package.json               # CRA scripts + build:cap + assets:icons
├── patches/                   # patch-package patch for @capacitor-community/apple-sign-in Package.swift
├── assets/ resources/         # source icon/splash for @capacitor/assets
├── ios/App/                   # Capacitor iOS (SPM) project — Info.plist URL scheme, entitlements (untracked)
├── public/                    # index.html (SEO meta, pre-paint theme script, viewport vars), SVG logos, robots/sitemap
└── src/
    ├── index.js               # boot: syncViewportHeight, setupAppZoom, registerCapacitorDeepLinks, render <App/>
    ├── App.js                 # Router (Hash on native / Browser on web), routes, Protected/Public guards, Loader
    ├── index.css              # entire design system: CSS vars (dark/light), layout, components, media queries, RTL overrides
    ├── capacitorBridge.js     # deep-link (custom scheme) OAuth token capture
    ├── viewportSync.js        # visualViewport → CSS vars, keyboard class, scroll lock
    ├── appZoom.js             # custom pinch / ctrl-wheel zoom & pan layer around #root
    ├── context/AppContext.js  # axios defaults + interceptor; user/theme/language provider; useApp()
    ├── i18n/index.js          # i18next init + inline en/ar resources (244 keys each)
    ├── config/logoSizes.js    # logo size constants, cache-bust, getPublicAssetUrl()
    ├── legal/privacyTexts.js  # privacy policy text (ar/en)
    ├── utils/
    │   ├── platform.js        # isApp/isWeb/isIOS/isAndroid
    │   ├── appleSignIn.js     # Sign in with Apple (Capacitor plugin) → POST /api/auth/apple
    │   ├── appleIAP.js        # StoreKit products / purchase / restore → server verify
    │   └── notifications.js   # localStorage in-app notification store
    ├── components/
    │   ├── Logo.jsx  IntroSplash.jsx  MarkdownMessage.jsx  SocialAuthButtons.jsx
    │   ├── NotificationsPanel.jsx  UpgradeModal.jsx  SessionExpiredModal.jsx
    └── pages/
        ├── SignIn.jsx SignUp.jsx VerifyEmail.jsx ForgotPassword.jsx ResetPassword.jsx AuthCallback.jsx
        ├── Chat.jsx (744)  Settings.jsx (519)  WelcomeScreen.jsx (662)  SharedChat.jsx
        ├── PaymentSuccess.jsx PaymentFailed.jsx PrivacyPolicy.jsx
        └── AdminLogin.jsx (redirect shim)  AdminDashboard.jsx (1200, chart.js)

backend/
├── server.js                  # express app bootstrap, CORS/helmet/rate-limit, mongoose connect, routes, SPA static, error handler, OpenAI cost monitor interval
├── middleware/auth.js         # protect / signToken / sendToken
├── models/User.js             # user schema + bcrypt pre-save + plan helpers + indexes
├── models/index.js            # Chat, Order, Subscription, PaymentLog (immutable), SharedChat, PendingUser (TTL)
├── routes/auth.js             # signup→email code, verify, signin, Google OAuth, Apple, me, preferences, change/forgot/reset password, deletion request
├── routes/chat.js             # shared chat (public), message, message-stream (SSE proxy), sessions CRUD, share
├── routes/payment.js          # plans (geo/FX), EdfaPay checkout + webhook, Apple IAP verify + server notifications
├── routes/admin.js            # adminOnly; stats, users, orders, revenue, token stats, OpenAI usage, deletion requests, live
├── services/openaiUsage.js    # OpenAI org Costs API with cache + spend alert
├── utils/email.js             # nodemailer transport + templates
├── utils/appleAuth.js         # Apple identity-token verification
├── utils/clientGeo.js         # client IP + geo lookup + cache
├── scripts/createReviewAccount.js  scripts/test-apple-iap.js  make_admin.js   # CLI ops scripts
└── vercel.json                # legacy serverless config
```

## 3. Infrastructure

### State management
- **React Context only** (`frontend/src/context/AppContext.js`). It holds `user`, `loading`, `theme`, `language`, `toggleTheme`, `toggleLanguage`, `login`, `logout`, `updateMessageCount`, `updatePlan` and `checkAuth`. `useApp()` throws when called outside the provider.
- On mount, `checkAuth()` calls `GET /api/auth/me` and applies the theme and language from server preferences, unless a theme is stored locally.
- Everything else is component-local `useState`; `Chat.jsx` alone has about 20 state variables. Nothing caches or dedupes requests.
- Quality: fine for a small app. The context mixes HTTP setup, auth, theming and l10n, so a template should split these.

### DI
None. Backend modules are required directly. The frontend mutates the global `axios` default instance as a side effect of importing `AppContext.js`.

### Routing
- `react-router-dom` v6 in `frontend/src/App.js`. On native it uses `HashRouter` (so `file://` and `capacitor://` reloads work); on the web it uses `BrowserRouter`.
- Guards:
  - `<Protected>` shows a Loader while auth loads, then either renders or redirects to `/signin`.
  - `<Public>` redirects a signed-in user to `/chat`.
- There is no role guard. `/admin/dashboard` is open on the client; the page calls `/api/admin/stats` and navigates to `/signin` on error.
- Catch-all `*` → `/chat`.
- Backend: Express routers mounted under `/api/auth`, `/api/chat`, `/api/payment` and `/api/admin`, plus `/health`. In production a `*` fallback serves `index.html`.

### Networking
- **Client:**
  - Global axios: `axios.defaults.baseURL = REACT_APP_API_URL || localhost`, `withCredentials = true`.
  - One request interceptor attaches `Authorization: Bearer <localStorage.auth_token>` unless a header is already set.
  - No response interceptor: a 401 is not handled globally. There is no token refresh (only one 7-day JWT) and no retry.
  - Errors are mapped inline in each call site with `err.response?.data?.message || t("error")`. 403 responses carrying `limitReached`/`sessionExpired` flags drive the paywall modals.
- **Streaming:** `pages/Chat.jsx` POSTs `/api/chat/message-stream` with `fetch`, attaching the Bearer token by hand because the iOS WKWebView blocks the cross-site cookie. It reads `body.getReader()` and strips a `[DONE]` sentinel. Setting `REACT_APP_USE_STREAM=0` falls back to the JSON endpoint.
- **Server outbound:** axios to:
  - the chatbot webhook (30 s timeout) and stream (60 s, `responseType:"stream"`, SSE frames parsed by hand);
  - OpenAI (SDK, title generation);
  - the OpenAI Costs API;
  - an IP-geo API;
  - an FX-rate API;
  - EdfaPay (form-data).
- **CORS** (`server.js`):
  - allowlist from env plus Capacitor origins (`capacitor://localhost`, `http(s)://localhost`, `ionic://localhost`);
  - a missing or `"null"` Origin is allowed;
  - rejected origins are logged.
- Quality: client networking is minimal. A template would want a dedicated `api/` client module with a 401 handler and typed endpoints.

### Local storage
- localStorage is used directly with no wrapper. Keys: `auth_token`, `taweelai_theme`, `taweelai_lang`, `taweelai_fontsize`, `taweelai_notifications`, `taweel_app_zoom`, `taweel_app_pan`, `taweel_welcome_seen`.
- sessionStorage keys: `taweelai_intro_shown`, `taweel_show_welcome`.
- `utils/notifications.js` is the only small store abstraction (JSON list, de-dupe within 30 s, capped at 20).
- Server side:
  - MongoDB.
  - In-memory Maps for the geo cache, FX cache and OpenAI usage cache. These are per-instance and not shared.

### Localization (+RTL)
- `i18next` 23 + `react-i18next` 14. Resources are inline in `src/i18n/index.js` (`en` and `ar`, 244 keys each, with Arabic stored as `\u` escapes because of the esbuild pass).
- `lng` comes from `localStorage.taweelai_lang || "ar"`, `fallbackLng: "en"`, `escapeValue:false`.
- An IIFE sets `<html dir/lang>` at import time. `AppContext.applyLanguage` changes the i18n language, `dir` and `lang`, and PATCHes the server preferences.
- About 130 inline `isAr ? "…" : "…"` ternaries bypass i18n, 67 of them in AdminDashboard. Notifications store separate `titleAr`/`titleEn` fields. Backend responses and emails are English only (except the hourly confirmation email).
- RTL relies on 55 `[dir="rtl"]` / `html[dir="rtl"]` override selectors in `index.css`. Only about 13 logical properties (`margin-inline-*`, `inset-inline-end`) against about 70 physical left/right declarations. Components also set `dir={isAr ? "rtl" : "ltr"}` locally.

### Theming
- `src/index.css` defines `:root, :root[data-theme="dark"]` and `:root[data-theme="light"]` variable sets (71 custom properties: backgrounds, accent, text-1..4, borders, shadows, radii `--r`, `--r-lg`, `--r-xl`, sidebar width `--sw`, chat bubble colors).
- Dark mode works through the `data-theme` attribute:
  - `public/index.html` applies the stored theme before first paint and syncs `meta[name=theme-color]`.
  - `AppContext` keeps the attribute in sync and saves the choice to the server.
  - `Logo.jsx` watches the attribute with a MutationObserver to swap the logo variant.
- No component theme system: there are global classes (`.btn-primary`, `.form-input`, `.modal-box`, `.spinner`...). AdminDashboard has its own JS token object `T` and its own inline-styled kit.
- Fonts: one Google Fonts `@import` of six families (Inter, IBM Plex Sans Arabic, Cairo, Nunito, Tajawal, Outfit), which is heavy.
- Quality: the CSS variables are reasonable. The ad-hoc inline styles (469 `style={{…}}`) and 57 hard-coded hex values undermine them.

### Responsive helpers
- Plain CSS media queries. Width breakpoints: 380, 560, 768/769, 900, 980, 1024 and 1400 px, plus `(hover:none) and (pointer:coarse)` and `prefers-reduced-motion`.
- `viewportSync.js` writes `--app-vh/--app-vw/--vv-top` from `visualViewport` and toggles `html.kb-open` when the iOS overlay keyboard shrinks the viewport by more than 120 px. It also re-locks body scroll on focus. `public/index.html` duplicates part of this before React mounts.
- `appZoom.js` wraps `#root` in a fixed pan layer and implements Ctrl/Cmd+wheel, Ctrl+/−/0 and two-finger pinch zoom with pan clamping, saved in localStorage. It is clever, but it hijacks native browser zoom and is app-specific.
- `index.html` viewport meta includes `viewport-fit=cover, interactive-widget=resizes-content`.

### Text scaling
`Settings.jsx` lets the user pick a base font size. It is clamped to 12–20 px (default 14), stored as `taweelai_fontsize`, and applied through the CSS var `--site-font-size`; `Chat.jsx` re-applies it on mount. Nothing respects OS-level text scaling beyond that.

### Env / flavors
- Frontend: CRA `REACT_APP_*` variables (`API_URL`, `APPLE_CLIENT_ID`, `APPLE_REDIRECT_URI`, `APPLE_PRODUCT_HOUR`, `APPLE_PRODUCT_MONTHLY`, `USE_STREAM`). The fallbacks are hardcoded in `AppContext.js`, `SocialAuthButtons.jsx` and `Chat.jsx`. `frontend/.env` and `.env.example` exist (not opened).
- Backend: `dotenv`. `backend/.env.example` lists 21 keys, but the code reads about 40. Undocumented ones include `EDFAPAY_*`, `APPLE_IAP_*`, `APPLE_BUNDLE_ID`, `OPENAI_API_KEY`, `OPENAI_ADMIN_KEY`, `CHATBOT_STREAM_URL`, `EXTRA_CORS_ORIGINS`, `PUBLIC_FRONTEND_URL`, `HOURLY_PRICE_USD`, `ADMIN_EMAIL` and `DEBUG_CHAT_GEO`.
- No flavors or staging configuration in code.
- Deploy: `.github/workflows/deploy.yml` (CI build plus a syntax gate, then an SSH pull-and-restart on a VPS). `backend/vercel.json` and `frontend/railway.json` are older targets.

### Logging
`console.log/warn/error` everywhere (frontend 13, backend 104), many with emoji prefixes. Notable lines:
- `[Webhook] raw response` logs the full AI reply.
- Stream failures log the upstream status and body.
- Payments get a structured, immutable Mongo audit trail (`PaymentLog` with action/status/step/ip/userAgent/request/response).

### Analytics / crash reporting
None on the frontend or backend.

### Push notifications
None. "Notifications" are local only: `utils/notifications.js` and `NotificationsPanel.jsx` keep events such as free-limit and plan-upgrade in localStorage.

### IAP / payments
- **EdfaPay** (web/Android), in `routes/payment.js`:
  - Checkout: `buy-hour`/`create-session` and `buy-monthly` create an `Order` with an idempotency key and a hosted-checkout redirect, signed with `sha1(md5(UPPER(...)))`.
  - `ALL /webhook`:
    - validates the gateway md5 hash;
    - for Apple Pay without a hash, confirms out-of-band through the gateway status API and fails closed if that is not configured;
    - atomically claims `pending→completed`;
    - activates the hourly or monthly plan;
    - logs every step.
  - Plans are geo-priced: IP → country → currency → FX rate (10-minute cache plus fallback table).
- **Apple IAP** (iOS app):
  - Client: `utils/appleIAP.js` uses `@capgo/native-purchases`. It fetches products for StoreKit price strings, purchases (consumable hours with quantity up to 10, plus a monthly subscription), then POSTs the transactionId to `/api/payment/apple/verify`, and offers restore.
  - Server: `@apple/app-store-server-library` with lazy client init (key from env PEM, base64 or file path). `getTransactionInfo` tries production first, then sandbox. It checks bundle ID, revocation, product and expiry, and creates an idempotent `apple_<txId>` order.
  - `/apple/webhook` handles App Store Server Notifications V2 (DID_RENEW/SUBSCRIBED/REFUND/REVOKE), but **it base64-decodes the JWS without verifying the signature**. The library's `SignedDataVerifier` should be used.
- Apple compliance notes in the code: App Review 3.1.1 (IAP on iOS) and guideline 4 (OAuth in an in-app browser).

### Permissions
None.

### Deep links
- iOS `Info.plist` registers a custom URL scheme. Google OAuth on native works like this:
  1. `SocialAuthButtons` opens `/api/auth/google?client=app` in `@capacitor/browser` (SFSafariViewController or Custom Tabs).
  2. The backend sets a 10-minute `oauth_client=app` cookie.
  3. The callback redirects to `<scheme>://callback?token=…`.
  4. `capacitorBridge.js` (`App.addListener("appUrlOpen")` + `getLaunchUrl()`) extracts the token, closes the browser, stores it and routes to `#/auth/callback`.
- On the web the callback goes to `${FRONTEND_URL}/auth/callback?token=…&isNew=`. `AuthCallback.jsx` stores the token and calls `/api/auth/set-cookie`.
- Shareable public chats live at `/shared/:shareToken`.

### Auth (backend)
- **Tokens:** JWT `{id, tv}` signed with `JWT_SECRET`, 7-day expiry, set as an httpOnly cookie (`sameSite=none` and `secure` in production) and also returned in the JSON body for Bearer use.
- **`protect` checks:**
  - cookie first, then Bearer;
  - user still exists;
  - `tokenVersion` matches (bumped on password change or reset and on ban);
  - account not banned.
- **Signup:**
  - validated by express-validator (name 2–50, email, password ≥ 8 with an uppercase letter and a digit, confirm);
  - the bcrypt hash and a 6-digit code are stored in `PendingUser` (15-minute TTL), then the code is emailed;
  - `verify-email` creates the `User` with `$locals.passwordAlreadyHashed`.
- **Other methods:** Google via passport (finds by googleId or email and links accounts), Apple via `apple-signin-auth`.
- **Rate limits:** auth 15 per 15 min, signup flow 35 per 15 min, payments 12 per hour, global API 300 per 15 min.
- **Forgot password:** random 32-byte token, 1-hour expiry, stored in plain text (not hashed).
- **Admin:** a `role` field plus an `adminOnly` middleware in `routes/admin.js`. `make_admin.js` is a CLI that promotes a user.

## 4. Services catalog

| File | Purpose | Public API | Dependencies | Generic / app-specific |
|---|---|---|---|---|
| backend/middleware/auth.js | JWT auth middleware + token issuing | `protect`, `signToken(userOrId)`, `sendToken(user, status, res, msg)` | jsonwebtoken, User model | generic (response shape app-specific) |
| backend/utils/email.js | SMTP mail | `generateVerificationCode()`, `sendVerificationEmail(email,name,code)`, `sendHourlyConfirmationEmail(email,name,endTime,lang)`, `sendEmail({to,subject,html})` | nodemailer, env EMAIL_* | transport generic; templates app-specific |
| backend/utils/appleAuth.js | Verify Sign in with Apple id token | `verifyAppleIdentityToken(token)` → `{appleId,email,emailVerified}` | apple-signin-auth | generic |
| backend/utils/clientGeo.js | Client IP + geo | `getClientIp(req)`, `lookupGeoData(ip)`, `resolveGeoForChat(req, sessionId)`, `buildClientLocationPayload(geo)` | axios, IP-geo API | generic |
| backend/services/openaiUsage.js | OpenAI org month-to-date cost with cache + alert threshold | `getOpenAIUsage()`, `BILLING_URL` | axios, OPENAI_ADMIN_KEY | generic for OpenAI users |
| backend/routes/admin.js `adminOnly` | role guard | middleware (not exported) | — | generic |
| backend/routes/payment.js (internal helpers) | pricing/FX/hash/plan activation/Apple | `normalizeCurrency`, `getExchangeRate`, `resolveClientLocale`, `formatMoney`, `createLog`, `buildInitHash`, `buildWebhookHash`, `verifyTransactionWithGateway`, `activateHourlyPlan`, `activateMonthlyPlan`, `getAppleClients`, `decodeJws`, `fetchAppleTransaction`, `applyAppleTransaction` (none exported) | axios, form-data, crypto, models, app-store-server-library | app-specific (Apple helpers extractable) |
| backend/models/User.js | user schema | `comparePassword`, `hasActiveHour`, `hasActiveMonthly`, `hasPaidAccess`, `getRemainingSeconds`, `hasFreeMessagesRemaining` | mongoose, bcryptjs | base user generic; plan fields app-specific |
| backend/models/index.js | other schemas | `Chat`, `Order`, `Subscription`, `PaymentLog`, `SharedChat`, `PendingUser` | mongoose | PendingUser/PaymentLog patterns generic |
| backend/make_admin.js, scripts/createReviewAccount.js, scripts/test-apple-iap.js | ops CLIs | run with node | mongoose, dotenv | semi-generic |
| frontend/src/context/AppContext.js | global app state + axios config | `AppProvider`, `useApp()` | axios, react-i18next | mixed |
| frontend/src/capacitorBridge.js | deep-link token capture | `registerCapacitorDeepLinks()` | @capacitor/app, @capacitor/browser | generic |
| frontend/src/viewportSync.js | viewport/keyboard CSS vars | `syncViewportHeight()` | DOM | generic |
| frontend/src/appZoom.js | custom zoom/pan | `setupAppZoom()` → cleanup | DOM | app-specific (questionable) |
| frontend/src/utils/platform.js | platform detection | `isApp`, `isWeb`, `isIOS`, `isAndroid` | @capacitor/core | generic |
| frontend/src/utils/appleSignIn.js | Apple sign-in | `isAppleSignInAvailable()`, `signInWithApple()` | @capacitor-community/apple-sign-in, axios | generic |
| frontend/src/utils/appleIAP.js | StoreKit IAP | `isIOSApp`, `IOS_MAX_HOURS`, `getAppleProducts()`, `purchaseApplePlan(type, hours)`, `restoreApplePurchases()` | @capgo/native-purchases, axios | generic pattern |
| frontend/src/utils/notifications.js | local notification store | `addNotification`, `getNotifications`, `markAllRead`, `markOneRead`, `unreadCount`, `clearNotifications` | localStorage | generic |
| frontend/src/config/logoSizes.js | logo sizes + asset URL helper | `LOGO_*` constants, `LOGO_PUBLIC_CACHE_BUST`, `getPublicAssetUrl(file)` | env PUBLIC_URL | `getPublicAssetUrl` generic |
| frontend/src/i18n/index.js | i18n init + resources | default i18n instance | i18next | pattern generic |
| frontend/src/legal/privacyTexts.js | privacy policy text | constants | — | app-specific |

## 5. Widgets catalog

| Path | Purpose | Props | Generic? |
|---|---|---|---|
| frontend/src/components/Logo.jsx | theme-aware logo `<img>` (dark variant, mark/full, onError fallback) | `size`, `className`, `style`, `variant`, `instanceId` | y (filenames hardcoded) |
| frontend/src/components/IntroSplash.jsx | once-per-session animated brand splash with fade | — | y (brand word hardcoded) |
| frontend/src/components/MarkdownMessage.jsx | safe mini-markdown renderer for chat bubbles | `content`, `isUser` | y |
| frontend/src/components/SocialAuthButtons.jsx | Google + Apple OAuth buttons, native in-app browser | `onError`, `onLoadingChange` | y |
| frontend/src/components/NotificationsPanel.jsx | notification dropdown with read/clear and click-outside | `onClose`, `onUnreadChange` | partly |
| frontend/src/components/UpgradeModal.jsx | paywall / plan purchase modal (web gateway + IAP + restore + legal sub-modal) | `onClose`, `onSuccess` | n |
| frontend/src/components/SessionExpiredModal.jsx | renew-hour overlay | `onRenewed` | n (broken web path) |
| frontend/src/pages/AdminDashboard.jsx: `Icon` | SVG icon by name from ICON_PATHS | `name`, `size`, `style`, `strokeWidth` | y |
| … `Avatar` | image or initial avatar | `src`, `name`, `size` | y |
| … `Badge` | tinted pill | `children`, `color` | y |
| … `SectionTitle` | section header with icon | `children`, `icon` | y |
| … `KpiCard` | stat tile with trend | `icon`, `label`, `value`, `sub`, `color`, `trend`, `onClick` | y |
| … `ChartCard` / `ChartLegend` | chart.js container + legend | `title`, `icon`, `height`, `children` / `items` | y |
| … `DataTable` / `TR` / `TD` | table with empty state, zebra rows | `headers`, `children`, `emptyMsg`, `emptyColSpan` / `i` / `style` | y |
| … `Btn` | small outline button | `children`, `color`, `border`, `onClick`, `disabled` | y |
| … `Toast` | fixed toast | `toast` | y |
| frontend/src/pages/SignIn.jsx (+SignUp, ResetPassword, Settings) `EyeIcon` | show/hide password icon | `open` / `show` | y (duplicated) |
| frontend/src/pages/UpgradeModal.jsx `Feature` | plan feature row | `icon`, `bold`, `label` | partly |
| frontend/src/pages/Chat.jsx (inline JSX) | confirm-delete modal, rename modal, toast, sidebar, composer | n/a | n (not extracted) |
| frontend/src/index.css classes | `.btn-primary`, `.btn-ghost`, `.form-group/.form-label/.form-input/.form-err/.form-alert`, `.spinner`, `.modal-overlay/.modal-box/.modal-title`, `.oauth-btn`, `.divider`, `.auth-card` | CSS | y |

## 6. Packages

**frontend/package.json**

| Role | Packages |
|---|---|
| Core/build | react ^18.2.0, react-dom ^18.2.0, react-scripts 5.0.1 (CRA) |
| Routing | react-router-dom ^6.21.1 |
| Network | axios ^1.6.0 |
| l10n | i18next ^23.7.6, react-i18next ^14.0.1 |
| Charts | chart.js ^4.5.1, react-chartjs-2 ^5.3.1 |
| Native (Capacitor) | @capacitor/core ^8.3.0, @capacitor/cli ^8.3.0 (should be a dev dependency), @capacitor/ios ^8.5.2, @capacitor/android ^8.3.0, @capacitor/app ^8.1.0, @capacitor/browser ^8.0.4, @capacitor-community/apple-sign-in ^7.1.0, @capgo/native-purchases ^8.7.0 |
| Utils (unused) | docx ^9.6.1 |
| Dev | @capacitor/assets ^3.0.5, cross-env ^7.0.3, esbuild ^0.28.0, patch-package ^8.0.1 |

**backend/package.json**

| Role | Packages |
|---|---|
| Server | express ^4.18.2, cors ^2.8.5, helmet ^7.1.0, express-rate-limit ^7.1.5, cookie-parser ^1.4.6 |
| Validation | express-validator ^7.0.1 |
| DB | mongoose ^8.0.3 |
| Auth | jsonwebtoken ^9.0.2, bcryptjs ^2.4.3, passport ^0.7.0, passport-google-oauth20 ^2.0.0, passport-facebook ^3.0.0 (unused), apple-signin-auth ^2.0.0 |
| Payments | @apple/app-store-server-library ^3.1.0, form-data ^4.0.0 |
| AI | openai ^4.67.0, js-tiktoken ^1.0.21 |
| Mail | nodemailer ^6.9.7 |
| Utils | axios ^1.6.0, uuid ^9.0.1, dotenv ^16.3.1 |
| Unused | csurf ^1.11.0 (deprecated), multer ^1.4.5-lts.1, googleapis ^171.4.0 |
| Dev | nodemon ^3.0.2 |

**Root package.json:** glob ^13.0.6, strip-comments ^2.0.1 (tooling only).
**chatbot/requirements.txt:** fastapi 0.115, uvicorn 0.30, pydantic 2.8, redis 5.0, langchain 0.3.1, langchain-openai, langchain-community, langchain-postgres, psycopg 3.2, openai 1.51, httpx, python-dotenv.

## 7. Quality notes

- **Language/typing:** plain JavaScript and no TypeScript, except `capacitor.config.ts`. There are no PropTypes. The backend is CommonJS.
- **Lints:** only CRA's built-in `react-app` ESLint config. No Prettier and no backend lint. CI gates only the frontend build, `node --check` on the backend and `py_compile` on the chatbot.
- **Tests:** no automated unit, integration or E2E tests. There are k6 load scenarios, a security probe script, a manual Apple IAP connectivity script and a long manual `TEST_PLAN.md`.
- **Machine-processed source:**
  - Many files are esbuild output: `var stdin_default = X; export { stdin_default as default }`, `1e3`/`5e3`/`11e3`, `void 0`, `/* @__PURE__ */`, `( new Date())`.
  - Arabic literals are `\uXXXX` escapes and original comments were stripped.
  - Later commits re-added comments to some files, so style is mixed. This hurts readability and should not be copied.
- **God files:**
  - `AdminDashboard.jsx` (1200 lines, its own UI kit, 67 inline language ternaries).
  - `Chat.jsx` (744 lines, about 20 `useState`).
  - `WelcomeScreen.jsx` (662), `Settings.jsx` (519).
  - `index.css` (2988 lines, single file).
  - `routes/payment.js` (967 lines: pricing, geo, FX, EdfaPay, Apple IAP, webhooks).
- **Duplication:**
  - the free-limit and expiry gate, plus the title-generation block, are duplicated in `/message` and `/message-stream`;
  - the free limit `10` is hardcoded in User.js, both chat routes and the response;
  - `EyeIcon` appears 4 times;
  - the API URL fallback appears 3 times;
  - the "is new user if created less than 10 s ago" heuristic appears 3 times (backend and frontend).
- **Hardcoded values:**
  - 469 inline style objects;
  - 57 hex colors in JSX;
  - `MONTHLY_PRICE = 25` in code;
  - payer contact defaults for EdfaPay in payment.js;
  - a production origin in the CORS list and the share-URL fallback;
  - the alert recipient email in server.js;
  - the support email fallback in routes/auth.js.
- **i18n/RTL:**
  - about 130 inline bilingual ternaries;
  - physical left/right CSS (about 70) against logical properties (about 13), with RTL patched through 55 `[dir=rtl]` overrides;
  - `textAlign:"right"` in SignIn.
- **Security findings:**
  1. The Apple Server Notifications webhook trusts unsigned JWS payloads, so renewals and refunds can be forged.
  2. HTML email templates interpolate `user.name` and the deletion `reason` without escaping.
  3. `POST /api/auth/set-cookie` sets any submitted token as the auth cookie. `protect` still verifies it, but the endpoint is unnecessary surface.
  4. Admin user search builds `$regex` from raw query text (ReDoS and regex injection).
  5. The JWT is stored in localStorage (XSS-exposed) in addition to the httpOnly cookie.
  6. Reset tokens are stored in plain text.
  7. The 6-digit verification code is compared directly and protected only by the 35-per-15-min limiter.
  8. The JSON body limit is 10 MB on all routes.
  9. Full AI responses are logged.
- **Broken or dead code:**
  - `SessionExpiredModal` (web) calls `/api/payment/simulate-payment`, which does not exist on the backend.
  - Unused dependencies: csurf, multer, googleapis, passport-facebook, docx.
  - Facebook OAuth env keys exist but there is no strategy.
  - `faceEmbedding`/`faceImageBase64` remain on the User schema after Face-ID was removed.
  - The `face_id/` service is still in the repo.
  - `patches/` exists but `package.json` has no `postinstall: patch-package`, so the patch is not applied on a fresh install.
- **Platform/infra:**
  - CRA is deprecated; a template should use Vite.
  - The `setInterval` OpenAI monitor in `server.js` does not suit serverless, yet `vercel.json` is still present.
  - `capacitor.config.ts` is gitignored, so the app ID config is not versioned.
  - The `@capacitor/android` dependency exists but there is no `android/` project.
- **UX oddities:**
  - `SignIn` forces the light theme on mount.
  - `appZoom.js` overrides native browser zoom (accessibility concern).
- **Secrets hygiene:** see the final note. Several secret-bearing files are tracked in git, and some sources contain credential-like connection strings.

### Related folder: `Chinaparts/New Projects/taweelai`

- It is an older clone of the **same** git repository (same origin remote), with HEAD at `d1a62e8` (2026-07-20). That commit is 20 commits behind taweel-website's HEAD.
- Its working tree is effectively empty: all 109 tracked files show as deleted, 14 iOS asset files are staged, and only `.git/`, `.gitignore` and `.vscode/settings.json` remain on disk.
- There is no code to analyze and taweel-website supersedes it. Its history, like the current repo's, contains committed `.env` files.
