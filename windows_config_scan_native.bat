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
    echo [FALLBACK] 01_wmic_acc_all.html - trying wmic useraccount list >> %errlog%
    wmic useraccount list full > 01_wmic_acc_all.html 2>> %errlog%
)
net user > 01_ac_net_user.txt 2>> %errlog%
net localgroup administrators > 01_ac_localgroup.txt 2>> %errlog%

:: ============================================================
echo [+] Collect Windows Services
:: ============================================================
echo [+] Collect Windows Services >> %errlog%
wmic /output:02_wmic_service_all.html service get DisplayName,Description,PathName,State,StartName /format:htable 2>> %errlog%
if not exist 02_wmic_service_all.html (
    echo [FALLBACK] 02_wmic_service_all.html - trying sc query >> %errlog%
    sc query type= all state= all > 02_wmic_service_all.html 2>> %errlog%
)
wmic /output:02_wmic_service_run.html service where state="Running" get DisplayName,Description,PathName,StartName /format:htable 2>> %errlog%
if not exist 02_wmic_service_run.html (
    echo [FALLBACK] 02_wmic_service_run.html - trying sc query running >> %errlog%
    sc query type= all state= running > 02_wmic_service_run.html 2>> %errlog%
)
reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services" > 02_reg_services.txt 2>> %errlog%
if not exist 02_reg_services.txt (
    echo [FALLBACK] 02_reg_services.txt - trying sc query >> %errlog%
    sc query type= all state= all > 02_reg_services.txt 2>> %errlog%
)

:: ============================================================
echo [+] Collect Features listing for package
:: ============================================================
echo [+] Collect Features listing for package >> %errlog%
dism /online /Get-Features > 03_dism_features.txt 2>> %errlog%
if not exist 03_dism_features.txt (
    echo [FALLBACK] 03_dism_features.txt - trying reg query CBS >> %errlog%
    reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" > 03_dism_features.txt 2>> %errlog%
)

:: ============================================================
echo [+] Collect a List of Installed Software
:: ============================================================
echo [+] Collect a List of Installed Software >> %errlog%
wmic /output:04_wmic_software_all.html product get name,version,Installsource,InstallDate,InstallDate2,LocalPackage /format:htable 2>> %errlog%
if not exist 04_wmic_software_all.html (
    echo [FALLBACK] 04_wmic_software_all.html - trying reg query uninstall hive >> %errlog%
    reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s > 04_wmic_software_all.html 2>> %errlog%
    reg query "HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" /s >> 04_wmic_software_all.html 2>> %errlog%
)

:: ============================================================
echo [+] Collect System Information
:: ============================================================
echo [+] Collect System Information >> %errlog%
systeminfo > 05_system.txt 2>> %errlog%
if not exist 05_system.txt (
    echo [FALLBACK] 05_system.txt - trying wmic os and computersystem >> %errlog%
    wmic os get Caption,Version,BuildNumber,OSArchitecture,LastBootUpTime,RegisteredUser,SerialNumber /format:list > 05_system.txt 2>> %errlog%
    wmic computersystem get Name,Manufacturer,Model,TotalPhysicalMemory /format:list >> 05_system.txt 2>> %errlog%
)
w32tm /query /configuration > 05_w32tm.txt 2>> %errlog%
w32tm /query /status >> 05_w32tm.txt 2>> %errlog%
if not exist 05_w32tm.txt (
    echo [FALLBACK] 05_w32tm.txt - trying reg query W32Time >> %errlog%
    reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\W32Time\Parameters" > 05_w32tm.txt 2>> %errlog%
    reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\W32Time\Config" >> 05_w32tm.txt 2>> %errlog%
)

:: ============================================================
echo [+] Collect Network Information
:: ============================================================
echo [+] Collect Network Information >> %errlog%
wmic /output:06_wmic_nicconfig_all.html nicconfig get /format:htable 2>> %errlog%
if not exist 06_wmic_nicconfig_all.html (
    echo [FALLBACK] 06_wmic_nicconfig_all.html - trying ipconfig /all >> %errlog%
    ipconfig /all > 06_wmic_nicconfig_all.html 2>> %errlog%
)
ipconfig /all > 06_ipconfig.txt 2>> %errlog%
if not exist 06_ipconfig.txt (
    echo [FALLBACK] 06_ipconfig.txt - trying wmic nicconfig >> %errlog%
    wmic nicconfig get IPAddress,MACAddress,Description /format:list > 06_ipconfig.txt 2>> %errlog%
)
netstat -aon > 06_netstat.txt 2>> %errlog%
if not exist 06_netstat.txt (
    echo [FALLBACK] 06_netstat.txt - trying netstat -an >> %errlog%
    netstat -an > 06_netstat.txt 2>> %errlog%
)
tasklist > 06_tasklist.txt 2>> %errlog%
if not exist 06_tasklist.txt (
    echo [FALLBACK] 06_tasklist.txt - trying wmic process >> %errlog%
    wmic process get ProcessID,Name,ExecutablePath /format:list > 06_tasklist.txt 2>> %errlog%
)
wmic process get ProcessID,ExecutablePath > 06_process.txt 2>> %errlog%
if not exist 06_process.txt (
    echo [FALLBACK] 06_process.txt - trying tasklist /v >> %errlog%
    tasklist /v > 06_process.txt 2>> %errlog%
)

:: ============================================================
echo [+] Collect a List of Hotfix
:: ============================================================
echo [+] Collect a List of Hotfix >> %errlog%
wmic /output:07_hotfix_all.html qfe list full /format:htable 2>> %errlog%
if not exist 07_hotfix_all.html (
    echo [FALLBACK] 07_hotfix_all.html - trying systeminfo findstr KB >> %errlog%
    systeminfo | findstr /C:"KB" > 07_hotfix_all.html 2>> %errlog%
)

:: ============================================================
echo [+] Collect System Security Settings
:: ============================================================
echo [+] Collect System Security Settings >> %errlog%
secedit /export /cfg 08_cfg.ini 2>> %errlog%
if not exist 08_cfg.ini (
    echo [FALLBACK] 08_cfg.ini - trying net accounts and auditpol >> %errlog%
    net accounts > 08_cfg.ini 2>> %errlog%
    auditpol /get /category:* >> 08_cfg.ini 2>> %errlog%
)

:: ============================================================
echo [+] Collect Windows Firewall Settings
:: ============================================================
echo [+] Collect Windows Firewall Settings >> %errlog%
netsh advfirewall show allprofiles > 09_firewall.txt 2>> %errlog%
if not exist 09_firewall.txt (
    echo [FALLBACK] 09_firewall.txt - trying netsh firewall show >> %errlog%
    netsh firewall show state > 09_firewall.txt 2>> %errlog%
    netsh firewall show config >> 09_firewall.txt 2>> %errlog%
)

:: ============================================================
echo [+] Collect AutoPlay Policies / Whitelist Application
:: ============================================================
echo [+] Collect AutoPlay Policies / Whitelist Application >> %errlog%
reg query "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" > 10_reg_explorer.txt 2>> %errlog%
if not exist 10_reg_explorer.txt (
    echo [FALLBACK] 10_reg_explorer.txt - trying HKLM equivalent >> %errlog%
    reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" > 10_reg_explorer.txt 2>> %errlog%
)

:: ============================================================
echo [+] Collect USB Port Status
:: ============================================================
echo [+] Collect USB Port Status >> %errlog%
reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\USBSTOR" > 11_reg_USBSTOR.txt 2>> %errlog%
if not exist 11_reg_USBSTOR.txt (
    echo [FALLBACK] 11_reg_USBSTOR.txt - trying device class USB registry key >> %errlog%
    reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{36FC9E60-C465-11CF-8056-444553540000}" > 11_reg_USBSTOR.txt 2>> %errlog%
)
reg query "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows" > 11_reg_Windows.txt 2>> %errlog%
reg query "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\RemovableStorageDevices" > 11_reg_Windows_RemovableStorageDevices.txt 2>> %errlog%

:: ============================================================
echo [+] Collect SMB Signing Settings
:: ============================================================
echo [+] Collect SMB Signing Settings >> %errlog%
reg query "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\LanManWorkstation\Parameters" > 12_reg_LanManWorkstation.txt 2>> %errlog%
if not exist 12_reg_LanManWorkstation.txt (
    echo [FALLBACK] 12_reg_LanManWorkstation.txt - trying net use and netsh >> %errlog%
    net use > 12_reg_LanManWorkstation.txt 2>> %errlog%
    netsh smb show global >> 12_reg_LanManWorkstation.txt 2>> %errlog%
)
reg query "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\LanManServer\Parameters" > 12_reg_LanManServer.txt 2>> %errlog%
if not exist 12_reg_LanManServer.txt (
    echo [FALLBACK] 12_reg_LanManServer.txt - trying net share >> %errlog%
    net share > 12_reg_LanManServer.txt 2>> %errlog%
)

:: ============================================================
echo [+] Collect Event Logs Settings
:: ============================================================
echo [+] Collect Event Logs Settings >> %errlog%
reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Eventlog\Security" > 13_reg_event_security.txt 2>> %errlog%
if not exist 13_reg_event_security.txt (
    echo [FALLBACK] 13_reg_event_security.txt - trying wevtutil >> %errlog%
    wevtutil gl Security > 13_reg_event_security.txt 2>> %errlog%
)
reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Eventlog\Application" > 13_reg_event_application.txt 2>> %errlog%
if not exist 13_reg_event_application.txt (
    echo [FALLBACK] 13_reg_event_application.txt - trying wevtutil >> %errlog%
    wevtutil gl Application > 13_reg_event_application.txt 2>> %errlog%
)
reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Eventlog\System" > 13_reg_event_system.txt 2>> %errlog%
if not exist 13_reg_event_system.txt (
    echo [FALLBACK] 13_reg_event_system.txt - trying wevtutil >> %errlog%
    wevtutil gl System > 13_reg_event_system.txt 2>> %errlog%
)
wevtutil gl Security > 13_wevtutil_event_security.txt 2>> %errlog%
if not exist 13_wevtutil_event_security.txt (
    echo [FALLBACK] 13_wevtutil_event_security.txt - trying reg query >> %errlog%
    reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Eventlog\Security" > 13_wevtutil_event_security.txt 2>> %errlog%
)
wevtutil gl Application > 13_wevtutil_event_application.txt 2>> %errlog%
if not exist 13_wevtutil_event_application.txt (
    echo [FALLBACK] 13_wevtutil_event_application.txt - trying reg query >> %errlog%
    reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Eventlog\Application" > 13_wevtutil_event_application.txt 2>> %errlog%
)
wevtutil gl System > 13_wevtutil_event_system.txt 2>> %errlog%
if not exist 13_wevtutil_event_system.txt (
    echo [FALLBACK] 13_wevtutil_event_system.txt - trying reg query >> %errlog%
    reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Eventlog\System" > 13_wevtutil_event_system.txt 2>> %errlog%
)

:: ============================================================
echo [+] Customised Items
:: ============================================================
echo [+] Customised Items >> %errlog%
reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\HarlequinLicenceServer" > 14_reg_service_HarlequinLicenceServer.txt 2>> %errlog%
if not exist 14_reg_service_HarlequinLicenceServer.txt (
    echo [FALLBACK] 14_reg_service_HarlequinLicenceServer.txt - trying sc query >> %errlog%
    sc query HarlequinLicenceServer > 14_reg_service_HarlequinLicenceServer.txt 2>> %errlog%
)
reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\xLicenseService" > 14_reg_service_xLicenseService.txt 2>> %errlog%
if not exist 14_reg_service_xLicenseService.txt (
    echo [FALLBACK] 14_reg_service_xLicenseService.txt - trying sc query >> %errlog%
    sc query xLicenseService > 14_reg_service_xLicenseService.txt 2>> %errlog%
)

del C:\Windows\system32\wbem\htable.xsl
echo [+] Reports are generated at %~dp0%folder%
echo [+] Error log saved to %folder%\%errlog%
pause
