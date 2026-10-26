# -----------------------------------------------------------------------------
# Cloudflare 1.1.1.1 DNS Manager for Windows 11 & 10
# Repository: https://github.com/bristo-biju/cloudflare-dns-windows
# License: MIT
# -----------------------------------------------------------------------------

# Ensure modern TLS protocols for downloads
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Self-elevate to Administrator if not already elevated
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

if (-not $isAdmin) {
    if ($PSCommandPath) {
        # Running from a local script file
        Start-Process powershell.exe `
            -Verb RunAs `
            -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
        exit
    }
    else {
        # Running via one-liner in memory (e.g. irm ... | iex)
        $tempScript = Join-Path $env:TEMP "Cloudflare-DNS-Temp.ps1"
        $scriptContent = $MyInvocation.MyCommand.Definition
        if (-not $scriptContent) {
            $rawUrl = "https://raw.githubusercontent.com/bristo-biju/cloudflare-dns-windows/main/Cloudflare-DNS.ps1"
            Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-Expression (Invoke-RestMethod -Uri '$rawUrl') }`""
            exit
        }
        Set-Content -Path $tempScript -Value $scriptContent -Encoding UTF8 -Force
        Start-Process powershell.exe `
            -Verb RunAs `
            -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$tempScript`""
        exit
    }
}

$ErrorActionPreference = "Stop"

Clear-Host
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "           Cloudflare 1.1.1.1 DNS Manager            " -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host ""

function Set-CloudflareDoH {
    param([bool]$Enable)

    $cfConfigs = @(
        @{ IP = "1.1.1.1"; Template = "https://cloudflare-dns.com/dns-query" },
        @{ IP = "1.0.0.1"; Template = "https://cloudflare-dns.com/dns-query" },
        @{ IP = "2606:4700:4700::1111"; Template = "https://cloudflare-dns.com/dns-query" },
        @{ IP = "2606:4700:4700::1001"; Template = "https://cloudflare-dns.com/dns-query" }
    )

    foreach ($item in $cfConfigs) {
        $existing = Get-DnsClientDohServerAddress -ServerAddress $item.IP -ErrorAction SilentlyContinue
        if ($existing) {
            Set-DnsClientDohServerAddress -ServerAddress $item.IP -AutoUpgrade $Enable -AllowFallbackToUdp $true -ErrorAction SilentlyContinue
        } elseif ($Enable) {
            Add-DnsClientDohServerAddress -ServerAddress $item.IP -DohTemplate $item.Template -AllowFallbackToUdp $true -AutoUpgrade $true -ErrorAction SilentlyContinue
        }
    }
}

try {
    # Only target physical, connected adapters (excludes VirtualBox, WSL, VPNs)
    $adapters = Get-NetAdapter -Physical -ErrorAction Stop | Where-Object { $_.Status -eq "Up" }

    if (-not $adapters) {
        Write-Host "No active physical network adapters (Wi-Fi/Ethernet) found." -ForegroundColor Red
        Write-Host "Please ensure your network connection is active and try again."
        Read-Host "`nPress Enter to exit"
        exit
    }

    $cfServers = @(
        "1.1.1.1",
        "1.0.0.1",
        "2606:4700:4700::1111",
        "2606:4700:4700::1001"
    )

    $adapterDetails = @()
    $isCloudflareEnabled = $false

    Write-Host "Active Network Adapters:" -ForegroundColor White
    foreach ($adapter in $adapters) {
        $dnsAddresses = (Get-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ErrorAction SilentlyContinue).ServerAddresses
        $hasCf = ($dnsAddresses -contains "1.1.1.1")
        if ($hasCf) {
            $isCloudflareEnabled = $true
        }

        $dnsText = if ($dnsAddresses) { $dnsAddresses -join ", " } else { "Automatic (DHCP)" }
        Write-Host " - $($adapter.Name) ($($adapter.InterfaceDescription))" -ForegroundColor Gray
        Write-Host "   Current DNS: $dnsText" -ForegroundColor DarkGray

        $adapterDetails += [PSCustomObject]@{
            Name  = $adapter.Name
            Index = $adapter.ifIndex
            HasCf = $hasCf
        }
    }

    # Check if DoH is currently active
    $isDohActive = $false
    $v4Doh = Get-DnsClientDohServerAddress -ServerAddress "1.1.1.1" -ErrorAction SilentlyContinue
    if ($v4Doh -and $v4Doh.AutoUpgrade -eq $true) {
        $isDohActive = $true
    }

    Write-Host ""
    if (-not $isCloudflareEnabled) {
        Write-Host "Current DNS Status: " -NoNewline
        Write-Host "[ OFF ] (Default / Automatic DHCP)" -ForegroundColor Yellow
    }
    elseif ($isDohActive) {
        Write-Host "Current DNS Status: " -NoNewline
        Write-Host "[ ON ] (Cloudflare 1.1.1.1 - Encrypted DoH)" -ForegroundColor Green
    }
    else {
        Write-Host "Current DNS Status: " -NoNewline
        Write-Host "[ ON ] (Cloudflare 1.1.1.1 - Standard Do53)" -ForegroundColor Green
    }

    Write-Host ""

    # Prompt user
    $selectedAction = ""
    while ($true) {
        Write-Host "Options:" -ForegroundColor White
        if (-not $isCloudflareEnabled) {
            Write-Host "  " -NoNewline
            Write-Host "[Enter]" -ForegroundColor Cyan -NoNewline
            Write-Host " -> Turn Cloudflare DNS " -NoNewline
            Write-Host "ON" -ForegroundColor Green -NoNewline
            Write-Host " (Standard Do53 - Default)"

            Write-Host "  " -NoNewline
            Write-Host "'doh'" -ForegroundColor Magenta -NoNewline
            Write-Host "   -> Turn Cloudflare DNS " -NoNewline
            Write-Host "ON" -ForegroundColor Green -NoNewline
            Write-Host " with " -NoNewline
            Write-Host "DoH" -ForegroundColor Magenta -NoNewline
            Write-Host " (Encrypted DNS-over-HTTPS)"

            Write-Host "  " -NoNewline
            Write-Host "'exit'" -ForegroundColor Red -NoNewline
            Write-Host "  -> Quit without making changes"
        }
        elseif ($isDohActive) {
            Write-Host "  " -NoNewline
            Write-Host "[Enter]" -ForegroundColor Cyan -NoNewline
            Write-Host " -> Turn Cloudflare DNS " -NoNewline
            Write-Host "OFF" -ForegroundColor Yellow -NoNewline
            Write-Host " (Restore Automatic DHCP)"

            Write-Host "  " -NoNewline
            Write-Host "'do53'" -ForegroundColor Blue -NoNewline
            Write-Host "  -> Switch to Standard " -NoNewline
            Write-Host "Do53" -ForegroundColor Blue -NoNewline
            Write-Host " (Unencrypted)"

            Write-Host "  " -NoNewline
            Write-Host "'exit'" -ForegroundColor Red -NoNewline
            Write-Host "  -> Quit without making changes"
        }
        else {
            Write-Host "  " -NoNewline
            Write-Host "[Enter]" -ForegroundColor Cyan -NoNewline
            Write-Host " -> Turn Cloudflare DNS " -NoNewline
            Write-Host "OFF" -ForegroundColor Yellow -NoNewline
            Write-Host " (Restore Automatic DHCP)"

            Write-Host "  " -NoNewline
            Write-Host "'doh'" -ForegroundColor Magenta -NoNewline
            Write-Host "   -> Switch to Encrypted " -NoNewline
            Write-Host "DoH" -ForegroundColor Magenta -NoNewline
            Write-Host " (DNS-over-HTTPS)"

            Write-Host "  " -NoNewline
            Write-Host "'exit'" -ForegroundColor Red -NoNewline
            Write-Host "  -> Quit without making changes"
        }

        Write-Host ""
        $inputChoice = (Read-Host "> ").Trim().ToLower()

        if ($inputChoice -match '^(exit|quit|q|close)$') {
            Write-Host "`nExiting without making changes." -ForegroundColor Yellow
            Start-Sleep -Milliseconds 700
            exit
        }
        elseif ($inputChoice -eq "" -or $inputChoice -eq "y" -or $inputChoice -eq "yes") {
            if (-not $isCloudflareEnabled) {
                $selectedAction = "ENABLE_DO53"
            } else {
                $selectedAction = "DISABLE"
            }
            break
        }
        elseif ($inputChoice -eq "doh" -or $inputChoice -eq "2") {
            $selectedAction = "ENABLE_DOH"
            break
        }
        elseif ($inputChoice -eq "do53" -or $inputChoice -eq "1") {
            $selectedAction = "ENABLE_DO53"
            break
        }
        else {
            Write-Host "`nUnrecognized option '$inputChoice'. Please press Enter, type 'doh', 'do53', or 'exit'.`n" -ForegroundColor DarkYellow
        }
    }

    # Perform Selected Action
    Write-Host ""
    if ($selectedAction -eq "DISABLE") {
        Write-Host "Restoring automatic DNS (DHCP)..." -ForegroundColor Cyan
        foreach ($item in $adapterDetails) {
            Set-DnsClientServerAddress -InterfaceIndex $item.Index -ResetServerAddresses
        }
        Set-CloudflareDoH -Enable $false
        Clear-DnsClientCache
        Write-Host "`nCloudflare DNS has been turned OFF." -ForegroundColor Green
        Write-Host "DNS settings restored to automatic DHCP and cache flushed." -ForegroundColor Gray
    }
    elseif ($selectedAction -eq "ENABLE_DO53") {
        Write-Host "Configuring Cloudflare DNS (1.1.1.1 / 1.0.0.1) in Standard Do53 mode..." -ForegroundColor Cyan
        foreach ($item in $adapterDetails) {
            Set-DnsClientServerAddress -InterfaceIndex $item.Index -ServerAddresses $cfServers
        }
        Set-CloudflareDoH -Enable $false
        Clear-DnsClientCache
        Write-Host "`nCloudflare DNS is now ON (Standard Do53 mode)." -ForegroundColor Green
        Write-Host "Standard unencrypted DNS (Port 53) configured and cache flushed." -ForegroundColor Gray
    }
    elseif ($selectedAction -eq "ENABLE_DOH") {
        Write-Host "Configuring Cloudflare DNS (1.1.1.1 / 1.0.0.1) in Encrypted DoH mode..." -ForegroundColor Cyan
        foreach ($item in $adapterDetails) {
            Set-DnsClientServerAddress -InterfaceIndex $item.Index -ServerAddresses $cfServers
        }
        Set-CloudflareDoH -Enable $true
        Clear-DnsClientCache
        Write-Host "`nCloudflare DNS is now ON (Encrypted DoH mode)." -ForegroundColor Green
        Write-Host "Encrypted DNS-over-HTTPS configured and cache flushed." -ForegroundColor Gray
    }
}
catch {
    Write-Host "`nERROR: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    # Clean up temporary script file if invoked via one-liner in memory
    if ($PSCommandPath -and ($PSCommandPath -like "*Cloudflare-DNS-Temp.ps1")) {
        Remove-Item -Path $PSCommandPath -Force -ErrorAction SilentlyContinue
    }
}

Write-Host ""
Read-Host "Press Enter to close"
