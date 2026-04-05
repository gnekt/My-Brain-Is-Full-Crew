# Using the Crew from Your Phone

> A guide to accessing your vault from your phone using GitHub Copilot and Obsidian mobile sync.

---

## How it works

You can access your vault from your phone in two ways: through **Obsidian mobile** (for reading and writing notes directly) and through **GitHub Copilot** on your phone or tablet (for AI-assisted tasks when you're away from your desk).

Nothing moves to the cloud. Your vault stays on your computer. Your phone just sends messages and receives responses.

```
Phone (browser or Claude app)
    ↓ sends messages via Anthropic servers
Your computer (GitHub Copilot running locally)
    ↓ executes agents, reads/writes vault
Your Obsidian vault (local files)
```

### A real-world example

I use this on the go. Before leaving, I start a Remote Control session on my laptop. Out and about, I open the session on my phone and ask: "What's on my calendar today?" or "Save this: just had an idea about reorganizing the team standup." I can even search my vault with "What do I know about the Henderson project?" and get a full answer with sources, right from my phone.

The vault, the agents, the MCP servers: everything works exactly as if I were sitting at my computer.

---

## Requirements

- **GitHub Copilot v2.1.51 or later** (check with `code --version`)
- **Claude Pro, Max, or Team subscription** (not API keys)
- Your computer must stay **on and connected to the internet** during the session
- A phone with a browser or the Claude mobile app (iOS/Android)

> **Team/Enterprise users:** your admin must enable Remote Control at `claude.ai/admin-settings/claude-code`.

---

## Setup (one time)

If you haven't already, make sure GitHub Copilot is authenticated and your vault is trusted:

```bash
cd /path/to/your-vault
claude
```

If this is your first time, GitHub Copilot will ask you to log in (`/login`) and accept the workspace trust dialog. Once that's done, you're set.

---

## Starting a session

On your computer, open a terminal and run:

```bash
cd /path/to/your-vault
claude remote-control --name "My Brain"
```

This starts a local GitHub Copilot session and displays:
- A **session URL** you can open on your phone
- A **QR code** you can scan (press spacebar to toggle it)

The session stays running, waiting for connections. Keep this terminal open.

### Alternative: enable on an existing session

If you already have GitHub Copilot running, type this inside the session:

```
/remote-control My Brain
```

This makes your current session accessible remotely without starting a new one.

---

## Connecting from your phone

You have three options:

### Option 1: QR code (fastest)
Press spacebar in the terminal to show the QR code. Scan it with your phone's camera or the Claude mobile app.

### Option 2: Session URL
Copy the URL shown in the terminal and open it in your phone's browser.

### Option 3: Session list
Go to [claude.ai/code](https://claude.ai/code) on your phone. Your session will appear in the list with a green indicator. Tap it to connect.

---

## Using the Crew from your phone

Once connected, you use the Crew exactly as you would on your computer. Just type (or use voice input) and the agents respond:

- "Save this: had a great idea about reorganizing the team standup" (Scribe captures it)
- "Check my email for anything urgent" (Postman scans Gmail)
- "What's on my calendar tomorrow?" (Postman checks Google Calendar)
- "Find my notes about the Henderson project" (Seeker searches your vault)

Everything runs on your computer. Your phone is just the interface.

---

## Tips for mobile use

- **Use voice input.** Most phones have built-in speech-to-text on the keyboard. Talking is faster than typing on a phone, and the Scribe handles messy voice input perfectly.
- **Keep sessions short and focused.** Mobile is great for quick captures, grocery runs, and check-ins. Save deep work for your computer.
- **Name your sessions.** The `--name` flag makes it easy to find the right session on `claude.ai/code` if you have multiple projects.
- **Your computer must stay awake.** If it goes to sleep or loses internet for more than ~10 minutes, the session ends. Adjust your sleep settings before leaving.
- **Works on mobile data.** WiFi is smoother, but cellular works fine for text-based interactions.

---

## Troubleshooting

### "Remote Control is not yet enabled"

Make sure these environment variables are NOT set in your shell:

```bash
unset CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC
unset DISABLE_TELEMETRY
```

For Team/Enterprise accounts, ask your admin to enable Remote Control in the admin settings.

### Session disappears from the list

Your computer probably went to sleep or lost internet. Go back to your computer, check the terminal, and restart the session if needed.

### Agents don't seem to activate

Make sure the terminal on your computer is running GitHub Copilot **inside your vault folder**. If you started it in a different directory, the agents won't be loaded.

### QR code won't scan

Press spacebar to toggle the QR code display. If your terminal font is too small, try zooming in, or just copy the URL instead.

---

## What this is NOT

To be clear about limitations:

- This is **not a standalone mobile app.** Your computer must be running GitHub Copilot for it to work.
- This does **not** sync your vault to the cloud. Everything stays local on your computer.
- You **cannot** use this with terminal SSH apps (Termius, Blink, etc.). Remote Control works through the browser or Claude mobile app only.
- If your computer is off, there is no session to connect to.

---

## Further reading

- [GitHub Copilot Remote Control documentation](https://docs.anthropic.com/en/docs/claude-code/remote-control)
- [Getting Started with the Crew](getting-started.md)
- [Examples of daily usage](examples.md)
