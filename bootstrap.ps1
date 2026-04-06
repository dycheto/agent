$ErrorActionPreference = 'Stop'

$TempPath = 'C:\Windows\Temp'
$LogFile = Join-Path $TempPath 'deploy.log'

$MsiUrl = 'https://raw.githubusercontent.com/dycheto/agent/main/DX-CyberProtect_v1.0.0.msi'
$MsiPath = Join-Path $TempPath 'DX-CyberProtect_v1.0.0.msi'

$InstallScriptUrl = 'https://raw.githubusercontent.com/dycheto/agent/main/install-agent.ps1'
$InstallScriptPath = Join-Path $TempPath 'install-agent.ps1'

function Write-Log {
    param([string]$Message)
    Add-Content -Path $LogFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
}

function Test-InstalledSoftware {
    param(
        [string]$DisplayName
    )

    $Paths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )

    foreach ($Path in $Paths) {
        $Item = Get-ItemProperty $Path -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -eq $DisplayName }

        if ($Item) {
            return $true
        }
    }

    return $false
}

try {
    Write-Log 'Bootstrap started'

    $DxInstalled = Test-InstalledSoftware -DisplayName 'DX CyberProtect'
    $WazuhInstalled = Test-InstalledSoftware -DisplayName 'Wazuh Agent'

    Write-Log "DX CyberProtect installed: $DxInstalled"
    Write-Log "Shield Agent installed: $WazuhInstalled"

    if (-not $DxInstalled) {
        Write-Log 'DX CyberProtect is missing. Downloading MSI.'
        Invoke-WebRequest -UseBasicParsing -Uri $MsiUrl -OutFile $MsiPath

        Write-Log 'Installing DX CyberProtect silently.'
        $msi = Start-Process -FilePath 'msiexec.exe' -ArgumentList "/i `"$MsiPath`" /qn /norestart" -Wait -PassThru
        Write-Log "DX CyberProtect MSI exit code: $($msi.ExitCode)"
    }
    else {
        Write-Log 'DX CyberProtect already installed. Skipping MSI.'
    }

    if (-not $WazuhInstalled) {
        Write-Log 'Shield Agent is missing. Downloading install-agent.ps1.'
        Invoke-WebRequest -UseBasicParsing -Uri $InstallScriptUrl -OutFile $InstallScriptPath

        Write-Log 'Running install-agent.ps1.'
        $ps = Start-Process -FilePath 'powershell.exe' -ArgumentList "-ExecutionPolicy Bypass -File `"$InstallScriptPath`"" -WindowStyle Hidden -Wait -PassThru
        Write-Log "install-agent.ps1 exit code: $($ps.ExitCode)"
    }
    else {
        Write-Log 'Shield Agent already installed. Skipping install-agent.ps1.'
    }

    Write-Log 'Cleaning up downloaded files.'
    Remove-Item -Path $MsiPath -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $InstallScriptPath -Force -ErrorAction SilentlyContinue

    Write-Log 'Bootstrap completed'
}
catch {
    Write-Log "Bootstrap failed: $($_.Exception.Message)"
    exit 1
}