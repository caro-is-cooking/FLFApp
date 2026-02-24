# FLF App Chat Backend

Small proxy so the iOS app can use the support chat **without each user entering an OpenAI API key**. The key lives only on this server.

## Run locally

```bash
cd backend
npm install
OPENAI_API_KEY=sk-your-key-here npm start
```

Server runs at `http://localhost:3000`. In the app’s **Chat settings**, set **Backend URL** to `http://localhost:3000` (or your machine’s LAN IP for a physical device).

## Deploy (so anyone can use the app)

1. **Railway** – [railway.app](https://railway.app): New Project → Deploy from GitHub (this repo, `backend` folder) or “Empty” and paste the code. Add variable `OPENAI_API_KEY`. Use the generated URL as Backend URL in the app (e.g. `https://your-app.up.railway.app`).

2. **Render** – [render.com](https://render.com): New → Web Service, connect repo, set **Root Directory** to `backend`, build `npm install`, start `npm start`. Add env var `OPENAI_API_KEY`. Use the service URL as Backend URL.

3. **Fly.io** – `fly launch` in the `backend` folder, set secret: `fly secrets set OPENAI_API_KEY=sk-...`. Use `https://your-app.fly.dev` as Backend URL.

In the app, set **Backend URL** to your deployed URL (no trailing slash). Leave **OpenAI API key** empty; all users will use your backend and your key.

## API

- **POST /chat**  
  Body: `{ "systemPrompt": "...", "messages": [ { "role": "user"|"assistant", "content": "..." } ] }`  
  Response: `{ "reply": "..." }` or `{ "error": "..." }`

- **GET /health**  
  Returns `{ "ok": true }` for health checks.

## Timeouts

- The **app** stops waiting after **25 seconds** and shows a “Request timed out” message so the UI never hangs.
- The **backend** stops waiting on OpenAI after **55 seconds** and returns a 504 so the app can show an error.

If chat often feels slow or times out: check that the backend URL is correct and reachable, that the host isn’t cold-starting (first request after idle can be slow on serverless), and that your OpenAI key has capacity. For local testing, run the backend on your machine and use `http://localhost:3000` or your LAN IP.
