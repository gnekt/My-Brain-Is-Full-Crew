# STATUS_2026-04-09_install-check.md

## 本次變更
- 驗證 `scripts/launchme.sh` 是否可在目前環境直接安裝。
- 在臨時 vault 路徑進行一次完整安裝流程演練（不修改 repo 內容）。
- 測試後清除所有臨時檔案與臨時 vault。

## 驗證結果
- 直接執行失敗：
  - 指令：`bash scripts/launchme.sh`
  - 結果：失敗
  - 錯誤摘要：
    - `scripts/launchme.sh: line 12: $'\r': command not found`
    - `set: pipefail\r: invalid option name`
  - 判定：`launchme.sh` 含 CRLF 行尾，Bash 會中斷。
- 轉為 LF 後流程可成功：
  - 指令：`bash scripts/launchme_lf_tmp.sh`（臨時測試檔）
  - 輸入：指定 vault 為 `/mnt/e/AI Training/_install_check_vault`，MCP 選 `n`
  - 結果：成功完成安裝，輸出包含 `Setup complete!`
  - 安裝內容摘要：`.codex/agents`、`.codex/skills`、`.codex/hooks`、`.codex/references`、`AGENTS.md`

## 若仍失敗
- 目前阻塞點：原始 `scripts/launchme.sh` 的行尾格式（CRLF）會導致 Bash 失敗。
- 風險說明：
  - 在 Windows + Bash（含 WSL/Git Bash）環境下，使用者可能無法直接完成安裝。
  - 若使用者輸入 Windows 路徑（如 `E:/...`）到 WSL bash，可能被判定為不存在路徑，需改用 `/mnt/e/...`。

## 下一步
- 已執行修正與再驗證（2026-04-09）：
  - 已新增 `.gitattributes`：`*.sh text eol=lf`
  - 已將 `scripts/launchme.sh`、`scripts/updateme.sh` 轉為 LF
  - 已用原始腳本 `bash scripts/launchme.sh` 在臨時 vault (`/mnt/e/AI Training/_install_check_vault2`) 完整驗證，結果成功並顯示 `Setup complete!`
- 後續建議：
  - 提交本次修正，避免其他 Windows 使用者再次遇到 CRLF 安裝失敗。
  - 若要提升易用性，可在 README 額外補充：WSL 輸入 vault 路徑請使用 `/mnt/<drive>/...` 格式。

## 2026-04-09 實際安裝（PigoVault）
- 目標 Vault：`E:\obsidian\PigoVault`
- 執行指令：`bash scripts/launchme.sh`
- 互動選項：
  - 指定 Vault 路徑：`/mnt/e/obsidian/PigoVault`
  - 既有安裝偵測：選擇 `c`（覆蓋核心檔案，保留自訂 agents）
  - MCP 設定：選擇 `n`（先跳過）
- 結果：成功，輸出包含 `Setup complete!`
- 安裝後快速驗證：
  - `.codex/agents`、`.codex/skills`、`.codex/hooks`、`.codex/references`、`AGENTS.md` 均存在
  - `agents` 數量：8
  - `skills` 目錄數量：13
