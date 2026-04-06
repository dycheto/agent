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

try {
    Write-Log 'Bootstrap started'

    Write-Log 'Downloading MSI'
    Invoke-WebRequest -UseBasicParsing -Uri $MsiUrl -OutFile $MsiPath

    Write-Log 'Downloading install-agent.ps1'
    Invoke-WebRequest -UseBasicParsing -Uri $InstallScriptUrl -OutFile $InstallScriptPath

    Write-Log 'Installing DX-CyberProtect silently'
    $msi = Start-Process -FilePath 'msiexec.exe' -ArgumentList "/i `"$MsiPath`" /qn /norestart" -Wait -PassThru
    Write-Log "DX-CyberProtect MSI exit code: $($msi.ExitCode)"

    Write-Log 'Running install-agent.ps1'
    $ps = Start-Process -FilePath 'powershell.exe' -ArgumentList "-ExecutionPolicy Bypass -File `"$InstallScriptPath`"" -WindowStyle Hidden -Wait -PassThru
    Write-Log "install-agent.ps1 exit code: $($ps.ExitCode)"

    Write-Log 'Cleaning up downloaded files'
    Remove-Item -Path $MsiPath -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $InstallScriptPath -Force -ErrorAction SilentlyContinue

    Write-Log 'Bootstrap completed'
}
catch {
    Write-Log "Bootstrap failed: $($_.Exception.Message)"
    exit 1
}