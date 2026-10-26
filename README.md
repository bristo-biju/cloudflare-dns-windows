<div align="center">

# ⚡ Cloudflare 1.1.1.1 DNS Manager for Windows 11 & 10

[![Windows](https://img.shields.io/badge/Windows-11%20%7C%2010-0078D6?logo=windows&logoColor=white)](https://microsoft.com/windows)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%20%7C%207%2B-5391FE?logo=powershell&logoColor=white)](https://github.com/PowerShell/PowerShell)
[![Cloudflare](https://img.shields.io/badge/DNS-Cloudflare%201.1.1.1-F38020?logo=cloudflare&logoColor=white)](https://1.1.1.1)
[![Protocol](https://img.shields.io/badge/Protocols-Do53%20%7C%20DoH-success)](#-features)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**An ultra-fast, safe, and universal 1-click script to toggle Cloudflare 1.1.1.1 DNS on Windows 11 and Windows 10.**  
Supports both standard unencrypted **Do53** (default) and encrypted **DoH (DNS-over-HTTPS)** with automatic physical network adapter detection.

[Quick Start](#-quick-start-run-instantly) • [Features](#-features) • [How It Works](#-how-it-works) • [Manual Installation](#-manual-download--offline-use) • [Verification](#-verification) • [FAQ](#-frequently-asked-questions)

</div>

---

## 🚀 Quick Start (Run Instantly)

You do **not** need to clone or download anything. Just copy and paste one of the commands below into your terminal:

### 🔹 Option 1: PowerShell (Windows PowerShell 5.1 & PowerShell 7+)
Open **PowerShell** and paste:

```powershell
irm https://raw.githubusercontent.com/bristo-biju/cloudflare-dns-windows/main/Cloudflare-DNS.ps1 | iex
```

### 🔹 Option 2: Command Prompt (CMD)
Open **Command Prompt** (`cmd.exe`) and paste:

```cmd
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/bristo-biju/cloudflare-dns-windows/main/Cloudflare-DNS.ps1 | iex"
```

> [!NOTE]  
> If your terminal is not running as Administrator, the script will automatically prompt for UAC elevation and open the menu seamlessly.

---

## 🖥️ Interactive Console Preview

```text
=====================================================
           Cloudflare 1.1.1.1 DNS Manager            
=====================================================

Active Network Adapters:
 - WiFi (Realtek RTL8821CE 802.11ac PCIe Adapter)
   Current DNS: 192.168.1.1, fe80::26de:8aff:febb:5941

Current DNS Status: [ OFF ] (Default / Automatic DHCP)

Options:
  [Enter] -> Turn Cloudflare DNS ON (Standard Do53 - Default)
  'doh'   -> Turn Cloudflare DNS ON with DoH (Encrypted DNS-over-HTTPS)
  'exit'  -> Quit without making changes

> :
```

* **Press <kbd>Enter</kbd>**: Instantly toggles Cloudflare DNS **ON** (Standard Do53) or **OFF** (Restores DHCP).
* **Type `doh` + <kbd>Enter</kbd>**: Enables Cloudflare **DNS-over-HTTPS** (Encrypted).
* **Type `do53` + <kbd>Enter</kbd>**: Switches back to standard unencrypted DNS (Port 53).
* **Type `exit` + <kbd>Enter</kbd>**: Exits without making any changes.

---

## ✨ Features

- **⚡ 1-Key Toggle**: Press <kbd>Enter</kbd> to turn Cloudflare DNS on; press <kbd>Enter</kbd> again to restore your original DHCP settings.
- **🔒 Do53 & DoH Dual-Support**: Choose between standard DNS over port 53 or encrypted DNS-over-HTTPS templates (`https://cloudflare-dns.com/dns-query`).
- **🛡️ Hardware-Safe Adapter Targeting**: Uses `Get-NetAdapter -Physical` to only configure active physical Wi-Fi and Ethernet adapters. **Never touches or breaks virtual network adapters** (WSL2, Hyper-V, VirtualBox, VMware, Docker, or active VPN tunnels).
- **🧹 Instant DNS Cache Flush**: Automatically executes `Clear-DnsClientCache` after toggling so domain resolutions update immediately without restarting your browser.
- **🌐 IPv4 & IPv6 Ready**: Simultaneously configures both IPv4 (`1.1.1.1`, `1.0.0.1`) and IPv6 (`2606:4700:4700::1111`, `2606:4700:4700::1001`).
- **🪶 Zero Dependencies & Clutter-Free**: Pure PowerShell cmdlets (`Set-DnsClientServerAddress`). No fragile `netsh` parsing, no third-party software to install. When run via the 1-liner, temporary files are automatically cleaned up upon exit.

---

## 📥 Manual Download & Offline Use

If you prefer to keep a local shortcut or run the script offline:

1. Download or clone this repository:
   ```cmd
   git clone https://github.com/bristo-biju/cloudflare-dns-windows.git
   ```
2. Navigate to the folder.
3. Simply **double-click [`Cloudflare-DNS.bat`](Cloudflare-DNS.bat)**.
   *(Or right-click [`Cloudflare-DNS.ps1`](Cloudflare-DNS.ps1) and choose **Run with PowerShell**)*.

---

## 🔍 Verification

### 1. Online Browser Verification (Cloudflare Diagnostic)
Visit Cloudflare's official diagnostic test page:
👉 **[https://one.one.one.one/help/](https://one.one.one.one/help/)**

When DoH is active, you will see:
* **Using DNS over HTTPS (DoH):** `Yes`
* **Connected to 1.1.1.1:** `Yes`

### 2. PowerShell Command Line Verification
To check your active DNS servers:
```powershell
Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object { $_.ServerAddresses }
```

To verify Windows 11 DoH encryption status:
```powershell
Get-DnsClientDohServerAddress | Where-Object { $_.ServerAddress -like "1.*" }
```

---

## ❓ Frequently Asked Questions

### Does this script require Administrator privileges?
Yes. Changing system network DNS server assignments and configuring Windows 11 DNS-over-HTTPS policies requires administrative rights. The script contains built-in self-elevation logic that automatically triggers the Windows UAC prompt.

### Will this script break my VPN or VirtualBox / WSL?
**No.** Many basic scripts blindly modify every interface with `Where-Object { $_.Status -eq 'Up' }`, which accidentally corrupts VirtualBox Host-Only adapters, WSL virtual switches, and VPN split-tunnels. This script filters exclusively for physical network cards (`Get-NetAdapter -Physical`), leaving all virtual adapters completely untouched.

### What is the difference between Do53 and DoH?
- **Do53 (Standard DNS)**: DNS queries are sent via UDP/TCP port 53 in plain text. It is fast, compatible with all networks, and the universal default.
- **DoH (DNS-over-HTTPS)**: Encrypts DNS queries inside an HTTPS session over port 443, preventing local network eavesdropping, ISP DNS hijacking, and snooping.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE) - free to use, modify, and distribute.
