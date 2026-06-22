# AutoPrint for Monday — Print Agent

Local print agent for AutoPrint for Monday. Runs silently in the background on your Windows, Linux, or Raspberry Pi machine, monitors your Monday.com boards, and prints automatically when item statuses change.

---

## How it works

1. Install the agent on any machine that has access to your printers
2. Connect it to your Monday.com account from the app settings
3. Define print rules on any board (when column X changes to Y, print on printer Z)
4. The agent polls your boards every 6 seconds and prints automatically — no browser tab needed

---

## Download

Go to Releases and download the installer for your platform:

| Platform | File |
|----------|------|
| Windows | `daruma-print-agent-setup.exe` |
| Linux x64 (PC / server) | Coming soon |
| Linux ARM64 (Raspberry Pi) | Coming soon |
| macOS | Coming soon |

---

## Installation

### Windows

1. Download `daruma-print-agent-setup.exe`
2. Right-click → **Run as administrator**
3. If Windows SmartScreen appears, click **More info → Run anyway** (the app is not yet code-signed)
4. Follow the installer wizard — the agent installs as a Windows service and starts automatically

The service is named **Daruma Print Agent** and starts with the system. After installation, open `http://localhost:9123/` to verify it is running.

---

### Linux x64 (PC, server, NUC)

**Requirements:** systemd, CUPS with printers already added

```bash
curl -LO https://github.com/NachDark/autoprint-agent/releases/latest/download/autoprint-agent-linux-x64.tar.xz
curl -LO https://github.com/NachDark/autoprint-agent/releases/latest/download/install.sh
sudo bash install.sh
```

---

### Linux ARM64 (Raspberry Pi, ARM server)

```bash
curl -LO https://github.com/NachDark/autoprint-agent/releases/latest/download/autoprint-agent-linux-arm64.tar.xz
curl -LO https://github.com/NachDark/autoprint-agent/releases/latest/download/install.sh
sudo bash install.sh
```

The installer will:
- Detect your architecture automatically
- Extract the binary
- Create a dedicated system user (`daruma-print`)
- Install the binary to `/opt/daruma-print-agent/`
- Register and start a systemd service

After installation, open `http://localhost:9123/` — or `http://<server-ip>:9123/` from another device on the network.

---

### macOS

Coming soon. The binary compiles correctly but requires code signing on a Mac before distribution.

---

## Configuration

The agent stores its configuration in `config.json`:

- **Windows:** `C:\ProgramData\DarumaTech\Daruma Print Agent\config.json`
- **Linux:** `/var/lib/daruma-print-agent/config.json`

After editing, restart the service:

```bash
# Linux
sudo systemctl restart daruma-print-agent

# Windows (PowerShell as admin)
Restart-Service DarumaPrintAgent
```

---

## Useful commands

### Linux

```bash
sudo systemctl status daruma-print-agent    # Check status
sudo journalctl -u daruma-print-agent -f    # Live logs
sudo systemctl restart daruma-print-agent   # Restart
sudo systemctl stop daruma-print-agent      # Stop
```

### Windows (PowerShell as admin)

```powershell
Get-Service DarumaPrintAgent                # Check status
Restart-Service DarumaPrintAgent            # Restart
Stop-Service DarumaPrintAgent               # Stop
```

---

## Uninstall

### Windows

Go to **Settings → Apps** and uninstall **Daruma Print Agent**. The service is stopped and removed automatically.

### Linux

```bash
sudo systemctl stop daruma-print-agent
sudo systemctl disable daruma-print-agent
sudo rm -rf /opt/daruma-print-agent /etc/systemd/system/daruma-print-agent.service
sudo systemctl daemon-reload
# Optional: remove data and config
sudo rm -rf /var/lib/daruma-print-agent
```

---

## Support

- Web panel: `http://localhost:9123/`
- Email: swdarumatech@gmail.com
