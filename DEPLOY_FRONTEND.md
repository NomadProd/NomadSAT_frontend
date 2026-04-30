# Frontend Deployment

The production frontend talks to:

```text
https://api.turansat.com
```

## Build locally

```bash
flutter pub get
flutter build web --release --dart-define=API_BASE_URL=https://api.turansat.com
```

Deploy this folder:

```text
build/web
```

## Vercel

Use `flutter_web` as the project root. `vercel.json` contains the build command, output directory, SPA rewrite, and cache headers.

## Netlify

Use `flutter_web` as the site base directory. `netlify.toml` contains the build command, publish directory, SPA rewrite, and cache headers.

## Other Static Hosts

Set the publish/output directory to:

```text
flutter_web/build/web
```

Add a rewrite/fallback rule:

```text
/* -> /index.html
```

That fallback is important so refreshing pages inside the Flutter app does not return 404.
