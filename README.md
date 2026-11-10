# Windows Config Scan

Windows configuration data collection scripts for security reviews and compliance assessments. Outputs structured text and HTML reports across 14 security-relevant areas.

Built for use in yearly configuration reviews and OT/IT security assessments.

---

## Scripts

| File | Fallback Method |
|---|---|
| `windows_config_scan_native.bat` | Falls back to native Windows commands (`sc query`, `reg query`, `netstat`, etc.) |
| `windows_config_scan_powershell.bat` | Falls back to PowerShell cmdlets (`Get-Service`, `Get-NetAdapter`, etc.) |

Use `_powershell` for modern Windows environments. Use `_native` for older or restricted systems where PowerShell execution policy may block scripts.

---

## Requirements

- Windows OS
- Must be run as Administrator
- No additional tools or dependencies required

---

## Usage

1. Right-click the `.bat` file → **Run as administrator**
2. Output folder is created automatically in the same directory: `YYYYMMDD_hostname_configs\`
3. An `error_log.txt` is generated alongside the output files

---

## Output Files

| File | Contents |
|---|---|
| `01_wmic_acc_all.html` | All local user accounts |
| `01_ac_net_user.txt` | Net user listing |
| `01_ac_localgroup.txt` | Local Administrators group members |
| `02_wmic_service_all.html` | All Windows services |
| `02_wmic_service_run.html` | Running services only |
| `02_reg_services.txt` | Services registry entries |
| `03_dism_features.txt` | Installed Windows features |
| `04_wmic_software_all.html` | Installed software list |
| `05_system.txt` | System info (OS, hardware, build) |
| `05_w32tm.txt` | NTP/time sync configuration |
| `06_wmic_nicconfig_all.html` | NIC configuration |
| `06_ipconfig.txt` | IP address info |
| `06_netstat.txt` | Active connections and listening ports |
| `06_tasklist.txt` | Running processes |
| `06_process.txt` | Process executable paths |
| `07_hotfix_all.html` | Installed patches and hotfixes |
| `08_cfg.ini` | Security policy export (secedit) |
| `09_firewall.txt` | Windows Firewall profile settings |
| `10_reg_explorer.txt` | AutoPlay and Explorer policies |
| `11_reg_USBSTOR.txt` | USB storage device status |
| `11_reg_Windows_RemovableStorageDevices.txt` | Removable storage device history |
| `12_reg_LanManWorkstation.txt` | SMB client signing settings |
| `12_reg_LanManServer.txt` | SMB server signing settings |
| `13_reg_event_*.txt` | Event log registry settings |
| `13_wevtutil_event_*.txt` | Event log configuration (wevtutil) |
| `14_reg_service_*.txt` | Custom service checks (see below) |
| `error_log.txt` | Errors and fallback actions taken |

---

## Customising Section 14

Section 14 is for environment-specific service checks. Edit the registry key paths in the script to match services relevant to your environment.

Example — replace the existing entries with your own:
```bat
reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\YourServiceName" > 14_reg_service_YourServiceName.txt
```

---

## Disclaimer

These scripts are intended for use by authorized security personnel on systems you have permission to assess. Do not run on systems without explicit authorization.
