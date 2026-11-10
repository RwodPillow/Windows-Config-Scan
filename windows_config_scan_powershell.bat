@echo off
cls

:: ============================================================
:: Check for Administrator privileges
:: ============================================================
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] ERROR: This script must be run as Administrator.
    echo [!] Right-click the script and select "Run as administrator".
    pause
    exit /b 1
)

pushd %~dp0
echo Windows Configuration Quick Scan
For /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set sysdate=%%c%%a%%b)
For /f "tokens=1 delims=\" %%a in ('hostname') do (set hostName=%%a)
set folder=%sysdate%_%hostName%_configs
mkdir %folder%
cd %folder%
set errlog=error_log.txt
echo Windows Configuration Quick Scan - Error Log > %errlog%
echo Run Date: %date% %time% >> %errlog%
echo ============================================================ >> %errlog%
copy C:\Windows\System32\wbem\en-US\htable.xsl C:\Windows\system32\wbem /Y 2>> %errlog%

:: ============================================================
echo [+] Collect User Accounts
:: ============================================================
echo [+] Collect User Accounts >> %errlog%
wmic /output:01_wmic_acc_all.html useraccount get AccountType,Caption,Description,FullName,Disabled /format:htable 2>> %errlog%
if not exist 01_wmic_acc_all.html (
    echo [FALLBACK] 01_wmic_acc_all.html - trying PowerShell >> %errlog%
    powershell -Command "Get-LocalUser | Select-Object Name,Enabled,LastLogon,PasswordLastSet,Description | Format-List | Out-File 01_wmic_acc_all.html" 2>> %errlog%
)
net user > 01_ac_net_user.txt 2>> %errlog%
net localgroup administrators > 01_ac_localgroup.txt 2>> %errlog%

:: ============================================================
echo [+] Collect Windows Services
:: ============================================================
echo [+] Collect Windows Services >> %errlog%
wmic /output:02_wmic_service_all.html service get DisplayName,Description,PathName,State,StartName /format:htable 2>> %errlog%
if not exist 02_wmic_service_all.html (
    echo [FALLBACK] 02_wmic_service_all.html - trying PowerShell >> %errlog%
    powershell -Command "Get-Service | Select-Object Name,DisplayName,Status | Format-List | Out-File 02_wmic_service_all.html" 2>> %errlog%
)
wmic /output:02_wmic_service_run.html service where state="Running" get DisplayName,Description,PathName,StartName /format:htable 2>> %errlog%
if not exist 02_wmic_service_run.html (
    echo [FALLBACK] 02_wmic_service_run.html - trying PowerShell >> %errlog%
    powershell -Command "Get-Service | Where-Object {$_.Status -eq 'Running'} | Select-Object Name,DisplayName | Format-List | Out-File 02_wmic_service_run.html" 2>> %errlog%
)
reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services" > 02_reg_services.txt 2>> %errlog%
if not exist 02_reg_services.txt (
    echo [FALLBACK] 02_reg_services.txt - trying PowerShell >> %errlog%
    powershell -Command "Get-Service | Select-Object Name,DisplayName,Status,StartType | Format-List | Out-File 02_reg_services.txt" 2>> %errlog%
)

:: ============================================================
echo [+] Collect Features listing for package
:: ============================================================
echo [+] Collect Features listing for package >> %errlog%
dism /online /Get-Features > 03_dism_features.txt 2>> %errlog%
if not exist 03_dism_features.txt (
    echo [FALLBACK] 03_dism_features.txt - trying PowerShell >> %errlog%
    powershell -Command "Get-WindowsOptionalFeature -Online | Select-Object FeatureName,State | Format-List | Out-File 03_dism_features.txt" 2>> %errlog%
)

:: ============================================================
echo [+] Collect a List of Installed Software
:: ============================================================
echo [+] Collect a List of Installed Software >> %errlog%
wmic /output:04_wmic_software_all.html product get name,version,Installsource,InstallDate,InstallDate2,LocalPackage /format:htable 2>> %errlog%
if not exist 04_wmic_software_all.html (
    echo [FALLBACK] 04_wmic_software_all.html - trying PowerShell >> %errlog%
    powershell -Command "Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*,HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName,DisplayVersion,Publisher,InstallDate | Sort-Object DisplayName | Format-List | Out-File 04_wmic_software_all.html" 2>> %errlog%
)

:: ============================================================
echo [+] Collect System Information
:: ============================================================
echo [+] Collect System Information >> %errlog%
systeminfo > 05_system.txt 2>> %errlog%
if not exist 05_system.txt (
    echo [FALLBACK] 05_system.txt - trying PowerShell >> %errlog%
    powershell -Command "Get-ComputerInfo | Out-File 05_system.txt" 2>> %errlog%
)
w32tm /query /configuration > 05_w32tm.txt 2>> %errlog%
w32tm /query /status >> 05_w32tm.txt 2>> %errlog%
if not exist 05_w32tm.txt (
    echo [FALLBACK] 05_w32tm.txt - trying PowerShell >> %errlog%
    powershell -Command "Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters | Out-File 05_w32tm.txt" 2>> %errlog%
)

:: ============================================================
echo [+] Collect Network Information
:: ============================================================
echo [+] Collect Network Information >> %errlog%
wmic /output:06_wmic_nicconfig_all.html nicconfig get /format:htable 2>> %errlog%
if not exist 06_wmic_nicconfig_all.html (
    echo [FALLBACK] 06_wmic_nicconfig_all.html - trying PowerShell >> %errlog%
    powershell -Command "Get-NetAdapter | Format-List | Out-File 06_wmic_nicconfig_all.html" 2>> %errlog%
)
ipconfig /all > 06_ipconfig.txt 2>> %errlog%
if not exist 06_ipconfig.txt (
    echo [FALLBACK] 06_ipconfig.txt - trying PowerShell >> %errlog%
    powershell -Command "Get-NetIPAddress | Format-List | Out-File 06_ipconfig.txt" 2>> %errlog%
)
netstat -aon > 06_netstat.txt 2>> %errlog%
if not exist 06_netstat.txt (
    echo [FALLBACK] 06_netstat.txt - trying PowerShell >> %errlog%
    powershell -Command "Get-NetTCPConnection | Format-List | Out-File 06_netstat.txt" 2>> %errlog%
)
tasklist > 06_tasklist.txt 2>> %errlog%
if not exist 06_tasklist.txt (
    echo [FALLBACK] 06_tasklist.txt - trying PowerShell >> %errlog%
    powershell -Command "Get-Process | Format-List | Out-File 06_tasklist.txt" 2>> %errlog%
)
wmic process get ProcessID,ExecutablePath > 06_process.txt 2>> %errlog%
if not exist 06_process.txt (
    echo [FALLBACK] 06_process.txt - trying PowerShell >> %errlog%
    powershell -Command "Get-Process | Select-Object Id,Path | Format-List | Out-File 06_process.txt" 2>> %errlog%
)

:: ============================================================
echo [+] Collect a List of Hotfix
:: ============================================================
echo [+] Collect a List of Hotfix >> %errlog%
wmic /output:07_hotfix_all.html qfe list full /format:htable 2>> %errlog%
if not exist 07_hotfix_all.html (
    echo [FALLBACK] 07_hotfix_all.html - trying PowerShell >> %errlog%
    powershell -Command "Get-HotFix | Select-Object HotFixID,Description,InstalledBy,InstalledOn | Format-List | Out-File 07_hotfix_all.html" 2>> %errlog%
)

:: ============================================================
echo [+] Collect System Security Settings
:: ============================================================
echo [+] Collect System Security Settings >> %errlog%
secedit /export /cfg 08_cfg.ini 2>> %errlog%
if not exist 08_cfg.ini (
    echo [FALLBACK] 08_cfg.ini - trying PowerShell >> %errlog%
    powershell -Command "Get-ExecutionPolicy -List | Out-File 08_cfg.ini" 2>> %errlog%
)

:: ============================================================
echo [+] Collect Windows Firewall Settings
:: ============================================================
echo [+] Collect Windows Firewall Settings >> %errlog%
netsh advfirewall show allprofiles > 09_firewall.txt 2>> %errlog%
if not exist 09_firewall.txt (
    echo [FALLBACK] 09_firewall.txt - trying PowerShell >> %errlog%
    powershell -Command "Get-NetFirewallProfile | Format-List | Out-File 09_firewall.txt" 2>> %errlog%
)

:: ============================================================
echo [+] Collect AutoPlay Policies / Whitelist Application
:: ============================================================
echo [+] Collect AutoPlay Policies / Whitelist Application >> %errlog%
reg query "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" > 10_reg_explorer.txt 2>> %errlog%
if not exist 10_reg_explorer.txt (
    echo [FALLBACK] 10_reg_explorer.txt - trying PowerShell >> %errlog%
    powershell -Command "Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' | Out-File 10_reg_explorer.txt" 2>> %errlog%
)

:: ============================================================
echo [+] Collect USB Port Status
:: ============================================================
echo [+] Collect USB Port Status >> %errlog%
reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\USBSTOR" > 11_reg_USBSTOR.txt 2>> %errlog%
if not exist 11_reg_USBSTOR.txt (
    echo [FALLBACK] 11_reg_USBSTOR.txt - trying PowerShell >> %errlog%
    powershell -Command "Get-PnpDevice -Class USB | Format-List | Out-File 11_reg_USBSTOR.txt" 2>> %errlog%
)
reg query "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows" > 11_reg_Windows.txt 2>> %errlog%
reg query "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\RemovableStorageDevices" > 11_reg_Windows_RemovableStorageDevices.txt 2>> %errlog%

:: ============================================================
echo [+] Collect SMB Signing Settings
:: ============================================================
echo [+] Collect SMB Signing Settings >> %errlog%
reg query "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\LanManWorkstation\Parameters" > 12_reg_LanManWorkstation.txt 2>> %errlog%
if not exist 12_reg_LanManWorkstation.txt (
    echo [FALLBACK] 12_reg_LanManWorkstation.txt - trying PowerShell >> %errlog%
    powershell -Command "Get-SmbClientConfiguration | Format-List | Out-File 12_reg_LanManWorkstation.txt" 2>> %errlog%
)
reg query "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\LanManServer\Parameters" > 12_reg_LanManServer.txt 2>> %errlog%
if not exist 12_reg_LanManServer.txt (
    echo [FALLBACK] 12_reg_LanManServer.txt - trying PowerShell >> %errlog%
    powershell -Command "Get-SmbServerConfiguration | Format-List | Out-File 12_reg_LanManServer.txt" 2>> %errlog%
)

:: ============================================================
echo [+] Collect Event Logs Settings
:: ============================================================
echo [+] Collect Event Logs Settings >> %errlog%
reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Eventlog\Security" > 13_reg_event_security.txt 2>> %errlog%
if not exist 13_reg_event_security.txt (
    echo [FALLBACK] 13_reg_event_security.txt - trying PowerShell >> %errlog%
    powershell -Command "Get-WinEvent -ListLog Security | Format-List | Out-File 13_reg_event_security.txt" 2>> %errlog%
)
reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Eventlog\Application" > 13_reg_event_application.txt 2>> %errlog%
if not exist 13_reg_event_application.txt (
    echo [FALLBACK] 13_reg_event_application.txt - trying PowerShell >> %errlog%
    powershell -Command "Get-WinEvent -ListLog Application | Format-List | Out-File 13_reg_event_application.txt" 2>> %errlog%
)
reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Eventlog\System" > 13_reg_event_system.txt 2>> %errlog%
if not exist 13_reg_event_system.txt (
    echo [FALLBACK] 13_reg_event_system.txt - trying PowerShell >> %errlog%
    powershell -Command "Get-WinEvent -ListLog System | Format-List | Out-File 13_reg_event_system.txt" 2>> %errlog%
)
wevtutil gl Security > 13_wevtutil_event_security.txt 2>> %errlog%
if not exist 13_wevtutil_event_security.txt (
    echo [FALLBACK] 13_wevtutil_event_security.txt - trying PowerShell >> %errlog%
    powershell -Command "Get-WinEvent -ListLog Security | Format-List | Out-File 13_wevtutil_event_security.txt" 2>> %errlog%
)
wevtutil gl Application > 13_wevtutil_event_application.txt 2>> %errlog%
if not exist 13_wevtutil_event_application.txt (
    echo [FALLBACK] 13_wevtutil_event_application.txt - trying PowerShell >> %errlog%
    powershell -Command "Get-WinEvent -ListLog Application | Format-List | Out-File 13_wevtutil_event_application.txt" 2>> %errlog%
)
wevtutil gl System > 13_wevtutil_event_system.txt 2>> %errlog%
if not exist 13_wevtutil_event_system.txt (
    echo [FALLBACK] 13_wevtutil_event_system.txt - trying PowerShell >> %errlog%
    powershell -Command "Get-WinEvent -ListLog System | Format-List | Out-File 13_wevtutil_event_system.txt" 2>> %errlog%
)

:: ============================================================
echo [+] Customised Items
:: ============================================================
echo [+] Customised Items >> %errlog%
reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\HarlequinLicenceServer" > 14_reg_service_HarlequinLicenceServer.txt 2>> %errlog%
if not exist 14_reg_service_HarlequinLicenceServer.txt (
    echo [FALLBACK] 14_reg_service_HarlequinLicenceServer.txt - trying PowerShell >> %errlog%
    powershell -Command "Get-Service HarlequinLicenceServer | Format-List | Out-File 14_reg_service_HarlequinLicenceServer.txt" 2>> %errlog%
)
reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\xLicenseService" > 14_reg_service_xLicenseService.txt 2>> %errlog%
if not exist 14_reg_service_xLicenseService.txt (
    echo [FALLBACK] 14_reg_service_xLicenseService.txt - trying PowerShell >> %errlog%
    powershell -Command "Get-Service xLicenseService | Format-List | Out-File 14_reg_service_xLicenseService.txt" 2>> %errlog%
)

del C:\Windows\system32\wbem\htable.xsl
echo [+] Reports are generated at %~dp0%folder%
echo [+] Error log saved to %folder%\%errlog%
pause
