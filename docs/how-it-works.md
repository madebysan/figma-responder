# How Figma Responder works

Setup, dashboard settings, menu bar use, development, file structure and known issues. The short version is the [README](../README.md).

## Setup

### Prerequisites

- macOS
- Node.js and npm
- A Figma personal access token (Settings → Personal Access Tokens)
- An Anthropic API key (console.anthropic.com → API Keys)

### Install

```bash
git clone https://github.com/madebysan/figma-responder.git
cd figma-responder
npm install
npm run build
```

Run in dev mode:

```bash
npm start
```

Or build a distributable DMG:

```bash
npm run dist
```

The packaged app lands in `release/`.

### First-time configuration

On first launch, a setup window asks for your Figma access token and Anthropic API key. Both are validated before saving.

Once configured, the dashboard lets you:

- Add Figma file URLs to monitor (paste any `figma.com/file/...` URL; the app extracts the file key)
- Customize the Claude model (default `claude-sonnet-5-5`)
- Edit the system prompt (defines AI persona and response style)
- Change the trigger phrase (default `@ai`, case-insensitive)
- Set the polling interval (default 30s; going lower can hit Figma rate limits on active files)
- Toggle desktop notifications

## Using it

The app lives in the menu bar. Filled icon = monitoring, outline icon = stopped. Right-click the icon for Start/Stop, Check Now (manual poll), Open dashboard, Update API keys, Quit.

Once the app is running and pointed at a file, post a comment in Figma containing your trigger phrase. For example: *"What do you think about this hierarchy? @ai"*. On the next polling cycle, the app grabs a screenshot of the pinned frame, sends it to Claude, and posts the reply into the same thread.

Multi-turn conversations work because the app builds the full thread history into each request. So you can ask follow-ups in the same Figma comment thread and Claude has the earlier context.

## Development

```bash
npm run build     # Build TypeScript + copy renderer files
npm start         # Build and run
npm run dev       # Build and run in dev mode
npm run dist      # Build distributable DMG
npm run icons     # Generate tray icons
```

## Tech stack

- **Framework:** Electron (Node.js + Chromium)
- **Language:** TypeScript
- **APIs:** Figma REST (comments, files, images) + Anthropic (vision + text)
- **Build:** electron-builder for macOS DMG
- **Storage:** electron-store for persistent settings

## File structure

```
src/
├── main/
│   ├── main.ts           # Electron main process, menu bar setup
│   ├── polling.ts        # Polling loop for new comments
│   ├── store.ts          # Persistent storage for settings and state
│   └── preload.js        # Bridge between main and renderer
├── services/
│   ├── figma-api.ts      # Figma REST API client
│   ├── figma-image.ts    # Screenshot capture
│   └── claude-api.ts     # Claude client with vision support
├── prompts/
│   └── system-prompt.ts  # Default AI persona and instructions
├── renderer/
│   ├── setup.html        # First-time API key UI
│   └── index.html        # Main dashboard UI
└── types.ts              # TypeScript type definitions
```

## Known issues

- **Figma API rate limits.** Polling intervals below ~30s on active files can hit Figma's REST API rate limits, which temporarily pauses monitoring. The default 30s interval is usually fine.
- **Deep-frame screenshots.** When a comment is pinned inside a deeply-nested frame or component, the captured image returns the bounding frame rather than the specific element. Claude sees more context than intended, or misses the element being discussed.
- **Comment pin drift.** Figma reports the pin coordinate at the time the comment was placed. If the underlying element is moved or resized afterwards, the captured screenshot can be off-center or no longer contain the element.
- **Polling, not webhooks.** Figma's comment API is poll-only for personal tokens, so there is a lag between posting a comment and receiving a reply (bounded by your polling interval).
