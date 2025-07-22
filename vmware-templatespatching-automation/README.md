# Windows Template Patching Automation Script

This PowerShell script automates the patching of Windows templates hosted on vCenter. It streamlines the process of converting templates to virtual machines, applying Windows updates, and converting them back to templates. It is especially useful in lab or enterprise environments where consistent patching of Windows templates is essential.

## 📜 What This Script Does

When executed, the script performs the following actions:

1. Converts a Windows template to a virtual machine (VM).
2. Assigns a DHCP VLAN network (via a specified dvPortGroup).
3. Powers on the VM and waits for it to receive an IP configuration.
4. Uses `Invoke-VMScript` to run a Windows Update script inside the VM.
5. Waits for the update process to complete and ensures all updates are applied.
6. Reboots the VM as required.
7. After updates, converts the VM back to a template.
8. Exports a status report for each processed template.

---

## ✅ Prerequisites

Before running this script, ensure the following requirements are met:

- ✅ **DHCP VLAN Propagation**: DHCP VLAN must be passed to **all ESXi hosts** in the vCenter cluster.
- ✅ **dvPortGroup Configuration**: A **Distributed Virtual Port Group (dvPortGroup)** with DHCP access must be **created and configured** in vCenter.
- ✅ **PowerCLI**: Ensure **VMware PowerCLI** is installed on the machine running the script.
- ✅ **Windows Update Script**: The update script referenced in `Invoke-VMScript` should be accessible or embedded appropriately.
- ✅ **Administrator Credentials**: You must know the **Administrator password** of the Windows templates to execute commands via `Invoke-VMScript`.

---

## 🚀 How to Use

1. Clone or download this repository to your local machine.
2. Open PowerShell as Administrator.
3. Connect to your vCenter using:
   ```powershell
   Connect-VIServer -Server <vcenter-server-name>
   ```
4. Execute the script:
   ```powershell
   .\windowstemplatepatchingfinalworkingscript_whichneedtouploadtogit.ps1
   ```
5. Monitor the console or refer to the **status report** exported after execution for template update results.

---

## 📁 Output

- A status report will be generated summarizing:
  - Success/failure of each update process.
  - Any issues during conversion, update, or reboot.

---

## ⚠️ Notes

- Ensure the VMTools are installed and up-to-date on the templates for `Invoke-VMScript` to work properly.
- The script requires internet access from the VMs to fetch Windows Updates unless using an internal WSUS.
