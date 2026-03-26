# Setting Up Google Workspace CLI for the Postman Agent

The Postman agent uses the [Google Workspace CLI](https://github.com/googleworkspace/cli) (`gws`) to interact with Gmail and Google Calendar. This gives the agent full read/write access — searching, reading, archiving, deleting, labelling emails, and creating/modifying calendar events.

## Why gws instead of MCP?

The Anthropic-hosted MCP servers for Gmail and Calendar are read-only (plus draft creation). They cannot archive, delete, label, or send emails. The Google Workspace CLI wraps the full Google API surface, giving the Postman agent the ability to actually manage your inbox — not just read it.

## Prerequisites

- **Node.js** (v18+) and **npm**
- Optional: **Google Cloud SDK** (`gcloud`) — only needed if you prefer CLI-based project setup instead of the Cloud Console UI
- A **Google account** (personal Gmail works fine)

## Step 1: Install the Google Workspace CLI

```bash
npm install -g @googleworkspace/cli
```

Verify:

```bash
gws --version
```

## Step 2: Install Google Cloud SDK (if not already installed)

### macOS (Apple Silicon)

```bash
curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-darwin-arm.tar.gz
tar -xf google-cloud-cli-darwin-arm.tar.gz
./google-cloud-sdk/install.sh
```

### macOS (Intel)

```bash
curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-darwin-x86_64.tar.gz
tar -xf google-cloud-cli-darwin-x86_64.tar.gz
./google-cloud-sdk/install.sh
```

### Other platforms

See https://cloud.google.com/sdk/docs/install

After installation, restart your terminal so the new PATH takes effect. If you don't want to restart, you can source your profile manually:

```bash
source ~/.zshrc   # or ~/.bashrc
```

Verify:

```bash
gcloud --version
```

## Step 3: Create a Google Cloud project

1. Go to https://console.cloud.google.com/
2. Create a new project (e.g., `my-vault`)
3. Note the project ID — you'll need it below

## Step 4: Configure the OAuth consent screen

1. Go to **APIs & Services > OAuth consent screen** in your project:
   `https://console.cloud.google.com/apis/credentials/consent?project=YOUR_PROJECT_ID`
2. Choose **External** as User Type (the only option for personal Gmail accounts)
3. Fill in the required fields:
   - App name: anything (e.g., "Vault CLI")
   - User support email: your email
   - Developer contact: your email
4. Click through the remaining screens (scopes, test users) and save

**Important — Add yourself as a test user:**

5. Back on the OAuth consent screen, find the **Audience** section
6. Under **Test users**, click **Add users**
7. Enter your Gmail address and save

This step is easy to miss and you will get an "Access blocked" error without it. Unverified apps can only be used by explicitly listed test users.

## Step 5: Create OAuth credentials

1. Go to **APIs & Services > Credentials**:
   `https://console.cloud.google.com/apis/credentials?project=YOUR_PROJECT_ID`
2. Click **Create Credentials > OAuth client ID**
3. Application type: **Desktop app**
4. Name: anything (e.g., "gws-cli")
5. Click **Create**
6. Copy the **Client ID** and **Client Secret**

## Step 6: Set up gws authentication

```bash
gws auth setup
```

When prompted, paste your Client ID and Client Secret.

## Step 7: Log in and select scopes

```bash
gws auth login
```

This opens an interactive scope selector. **Deselect everything** and only keep:

- `https://www.googleapis.com/auth/gmail.modify` — read/write/archive/delete emails
- `https://www.googleapis.com/auth/gmail.send` — send emails and drafts
- `https://www.googleapis.com/auth/calendar.events` — create/update/delete calendar events
- `https://www.googleapis.com/auth/calendar.calendarlist.readonly` — list available calendars

Optionally also keep:

- `https://www.googleapis.com/auth/drive` — if you want Drive access
- `https://www.googleapis.com/auth/tasks` — if you want Tasks access
- `openid`, `userinfo.email`, `userinfo.profile` — for profile info

**Do not select all 85+ scopes.** Google will reject the auth request for unverified apps with too many scopes, especially admin/workspace scopes that aren't available to personal accounts.

After selecting scopes, a browser window opens. Sign in with your Google account. You may see a "This app isn't verified" warning — click **Continue** (this is expected for personal-use OAuth apps).

On success you'll see:

```
Authentication successful. Encrypted credentials saved.
```

## Step 8: Verify it works

Test Gmail access:

```bash
gws gmail users messages list --params '{"userId": "me", "maxResults": 3}'
```

Test Calendar access:

```bash
gws calendar events list --params '{"calendarId": "primary", "timeMin": "2026-03-01T00:00:00Z", "maxResults": 3}'
```

Both should return JSON results.

## Step 9: Remove MCP servers (optional)

If your `.mcp.json` still has the Anthropic-hosted Gmail/Calendar servers, you can remove them. Remove only the `gmail` and `google-calendar` entries from your `.mcp.json`, leaving any other MCP servers intact.

If `.mcp.json` contained only those two servers, you can delete the file entirely.

## Troubleshooting

### "Access blocked" / Error 403

You haven't added yourself as a test user. Go back to Step 4, point 5-7.

### "invalid_scope" / Error 400

You selected too many scopes, including ones not available to personal Gmail accounts (e.g., admin, classroom, chat). Re-run `gws auth login` and select only the scopes listed in Step 7.

### "gcloud CLI not found"

The Google Cloud SDK isn't on your PATH. Restart your terminal. If you don't want to restart, run:

```bash
source ~/google-cloud-sdk/path.zsh.inc   # adjust path if installed elsewhere
```

### gws command not found

Restart your terminal first — this resolves most cases. If it still fails, the npm global bin directory may not be on your PATH. Check with:

```bash
npm config get prefix
```

And ensure `<prefix>/bin` is in your PATH.

### "Using keyring backend: keyring" warning

This is normal — gws stores encrypted credentials in your OS keyring. Not an error.

## How it works in the Postman agent

The Postman agent calls `gws` commands via the Bash tool. Key operations:

| Operation | Command |
|-----------|---------|
| Search inbox | `gws gmail users messages list --params '{"userId": "me", "q": "..."}'` |
| Read email | `gws gmail users messages get --params '{"userId": "me", "id": "ID", "format": "full"}'` |
| Read thread | `gws gmail users threads get --params '{"userId": "me", "id": "ID"}'` |
| Mark as read | `gws gmail users messages modify --params '{"userId": "me", "id": "ID"}' --json '{"removeLabelIds": ["UNREAD"]}'` |
| Archive | `gws gmail users messages modify --params '{"userId": "me", "id": "ID"}' --json '{"removeLabelIds": ["INBOX"]}'` |
| Trash | `gws gmail users messages trash --params '{"userId": "me", "id": "ID"}'` |
| List events | `gws calendar events list --params '{"calendarId": "primary", "timeMin": "...", "timeMax": "..."}'` |
| Create event | `gws calendar events insert --params '{"calendarId": "primary"}' --json '{"summary": "...", ...}'` |
| Create draft | `gws gmail users drafts create --params '{"userId": "me"}' --json '{"message": {"raw": "BASE64"}}'` |

All commands return JSON. The `--params` flag is for URL/query parameters; `--json` is for the request body.
