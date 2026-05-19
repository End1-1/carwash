# migrate-html

Lightweight TV status page (plain HTML/CSS/JS) for old Smart TV browsers.

## Goals

- Low memory usage on continuous refresh
- No framework/runtime
- Reuse existing project palette and icons

## Files

- `index.html` - page markup
- `styles.css` - lightweight styles (green/blue palette)
- `app.js` - polling + minimal DOM updates

## Endpoint

By default it polls:

`/engine/carwash/status.php`

If needed, change `API_URL` in `app.js`.

## Session key placement

The page can read `./tvkey.txt` (same folder) and use its value as `sessionkey`.
If you pass `?sessionkey=...` in the URL, it overrides the file.

## Run

Serve project via any static web server so requests use same origin as your backend.
Do not open via `file://` if API calls are required.
