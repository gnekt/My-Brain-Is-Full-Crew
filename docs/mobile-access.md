# Mobile Access

> A guide to accessing your vault from your phone or tablet using VS Code for the Web and Obsidian mobile sync.

---

## Overview

There are two complementary ways to use the Crew from your phone:

1. **VS Code for the Web** — opens your vault in a browser at [vscode.dev](https://vscode.dev) and gives you access to GitHub Copilot Chat on any device
2. **Obsidian mobile app** — read and write your vault notes directly, synced via iCloud, Dropbox, or Obsidian Sync

---

## Option 1: VS Code for the Web

GitHub Copilot works in the browser through [vscode.dev](https://vscode.dev) and [github.dev](https://github.dev). If your vault is in a GitHub repository, you can open it directly:

1. Navigate to your vault's GitHub repository
2. Press `.` (period) to open the VS Code for the Web editor, or go to `github.dev/your-username/your-vault-repo`
3. Open GitHub Copilot Chat (`Ctrl+Shift+I`)
4. The `.github/copilot-instructions.md` dispatcher is loaded automatically

> **Note**: VS Code for the Web has some limitations compared to the desktop app. Bash-dependent features (like the Postman agent's `gws` CLI) won't work in the browser editor. Use VS Code Desktop for full functionality.

---

## Option 2: Obsidian Mobile Sync

Keep your vault synced to your phone for reading and writing notes on the go:

### Using iCloud (macOS/iOS)

1. Create your Obsidian vault inside your iCloud Drive folder
2. Install [Obsidian](https://obsidian.md) on your iPhone/iPad
3. Open the vault from iCloud Drive — Obsidian automatically syncs

### Using Obsidian Sync (official, paid)

1. Enable Obsidian Sync in the Obsidian desktop app
2. Install Obsidian on your phone
3. Connect to the same sync vault

### Using Dropbox or Google Drive

1. Store your vault in a Dropbox/Google Drive folder
2. Install the cloud provider's app on your phone
3. Use the Obsidian mobile app to open the vault from the cloud folder

---

## Requirements

- **GitHub Copilot** (Pro, Business, or Enterprise subscription)
- A GitHub account with your vault in a repository (for VS Code for the Web)
- OR Obsidian Sync / iCloud / Dropbox (for Obsidian mobile)

---

## Tips

- Use Obsidian mobile to capture quick notes on the go — the Scribe agent will clean them up next time you open VS Code
- For AI-assisted tasks on mobile, VS Code for the Web with a keyboard-connected tablet works best
- The `.github/copilot-instructions.md` dispatcher is available in any VS Code environment that supports GitHub Copilot Chat

---

## Related

- [Getting Started](getting-started.md)
- [GitHub Copilot documentation](https://docs.github.com/en/copilot)
- [VS Code for the Web](https://code.visualstudio.com/docs/editor/vscode-web)
