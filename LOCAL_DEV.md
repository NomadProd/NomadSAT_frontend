# Local development setup

This guide explains how to run the TuranSAT frontend and backend together after cloning the repositories.

You need **both** repositories:

- `NomadSAT_backend` — FastAPI API on port **8000**
- `NomadSAT_frontend` (this repo) — Flutter web app (any localhost port)

```
Flutter web (localhost)  →  FastAPI (localhost:8000)  →  Supabase Postgres
```

---

## Prerequisites

| Tool | Purpose |
|------|---------|
| **Python 3.11+** | Backend runtime |
| **Flutter SDK** (web enabled) | Frontend (`flutter config --enable-web`) |
| **Supabase project** | Hosted Postgres database |
| **Cloudinary account** | Optional; only needed for homework photo uploads |

---

## 1. Backend setup

```bash
git clone https://github.com/NomadProd/NomadSAT_backend.git
cd NomadSAT_backend

python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

cp .env.example .env
# Edit .env — see "Environment variables" below

uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Or: `./scripts/dev-backend.sh`

Verify: [http://localhost:8000/docs](http://localhost:8000/docs)

### Backend environment variables

Copy `.env.example` to `.env` and fill in:

| Variable | Where to get it |
|----------|-----------------|
| `DATABASE_URL` | Supabase → Project Settings → Database → **Session pooler** URI (port 5432) |
| `JWT_SECRET_KEY` | `openssl rand -hex 32` |
| `CLOUDINARY_*` | Cloudinary dashboard (optional locally) |

**Database URL:** use the pooler, not the direct host (`db.xxx.supabase.co`):

```
postgresql://postgres.PROJECT_REF:PASSWORD@aws-0-REGION.pooler.supabase.com:5432/postgres?sslmode=require
```

**Local dev cookie settings:**

```env
AUTH_COOKIE_SECURE=false
AUTH_COOKIE_DOMAIN=
```

---

## 2. Frontend setup

```bash
git clone https://github.com/NomadProd/NomadSAT_frontend.git
cd NomadSAT_frontend

flutter pub get
flutter run -d chrome
```

Or: `./scripts/dev-frontend.sh` (uses port 55555)

### API URL

On `localhost`, the app automatically calls `http://localhost:8000`. No `--dart-define` needed.

Override for staging/production API:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=https://api.turansat.com
```

### Auth

Login uses **HTTP-only cookies** sent to the backend. Start the backend before logging in.

---

## 3. Smoke test

1. `http://localhost:8000/docs` loads (backend)
2. Login page loads on `http://localhost:<port>/#/login` (frontend)
3. Log in with an existing Supabase user
4. DevTools → login response has `Set-Cookie: access_token=...`
5. `/auth/me` returns 200 after login

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `Failed to fetch, uri=https://api.turansat.com/...` | Not running on localhost, or production `API_BASE_URL` was set. Localhost auto-detects port 8000. |
| CORS error | Restart backend. Any `http://localhost:<port>` is allowed. |
| Login OK, `/auth/me` fails | Backend needs `AUTH_COOKIE_SECURE=false` for HTTP localhost. |
| `Failed to fetch, uri=http://localhost:8000/...` | Backend not running, or DB connection failed. Check terminal logs. |
| `401 Wrong credentials` | User missing from database or wrong password. |

---

## Production

- Build with: `flutter build web --release --dart-define=API_BASE_URL=https://api.turansat.com`
- See `DEPLOY_FRONTEND.md` for deployment steps

Full backend details: `NomadSAT_backend/LOCAL_DEV.md`
