<p><img src="assets/app-icon.png" width="128" height="128" alt="Figma Responder app icon"></p>

<h1>Figma Responder</h1>

<p>Type @ai in a Figma comment and Claude replies with design feedback.<br>
Design review inside the file, from a Mac menu bar app.</p>

<p><strong>Version 2.0.2</strong> · macOS · Apple Silicon</p>

<p>
  <img src="https://img.shields.io/badge/Electron-47848f" alt="Electron">
  <img src="https://img.shields.io/badge/TypeScript-3178c6" alt="TypeScript">
  <img src="https://img.shields.io/badge/Node.js-339933" alt="Node.js">
  <img src="https://img.shields.io/badge/Claude%20API-d97757" alt="Claude API">
</p>

<p><a href="https://github.com/madebysan/figma-responder/releases/latest">Download Figma Responder</a></p>

https://github.com/user-attachments/assets/ba5d3899-d52f-4682-8fd2-998a7884dd4c

I use AI every day for copy rewrites, UX audits and accessibility checks, but switching apps and taking screenshots kept breaking the flow. So I built the feature I wished Figma had.

- Leave a comment with `@ai` and get a reply in the same thread.
- Claude sees a screenshot of the frame the comment is pinned to.
- Follow-ups keep the thread's history, so the conversation stays in context.

Figma's own AI agent works on the canvas and in a side panel; as far as I've found, it doesn't reply inside comment threads.

## How it works

Add a Figma file URL to the dashboard and the app checks it every 30 seconds. When a comment contains your trigger phrase (`@ai` by default, or any phrase you set), it captures the pinned frame, sends it with the thread to Claude (Sonnet 5.5 by default), and posts the reply. You can edit the system prompt to shape the feedback. It only comments; for changes to the file itself, use [figma-autopilot](https://github.com/madebysan/claude-figma-skills) in Claude Code.

## Privacy

You bring a Figma access token and an Anthropic API key, both encrypted with the macOS Keychain; if the Keychain isn't available, the app won't save them at all. It talks to Figma and Anthropic directly, and a request carries only the comment thread and the frame screenshot. No analytics or telemetry.

## Limits

Figma's comment API has no webhooks for personal tokens, so replies arrive on the next check, and intervals much under 30 seconds can hit rate limits. Comments inside deeply nested frames capture the whole outer frame, and a pin can drift if its element moves. Details are in [docs/how-it-works.md](docs/how-it-works.md).

## Install

Download the DMG from the [latest release](https://github.com/madebysan/figma-responder/releases/latest), or build it with Node.js: `npm install`, `npm run build`, then `npm start` to run it or `npm run dist` for a DMG.

---

[MIT](LICENSE). Third-party components and their licenses are listed in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

Made by [santiagoalonso.com](https://santiagoalonso.com)
