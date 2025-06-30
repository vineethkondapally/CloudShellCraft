
# PowerShell Automation Scripts for VMware & Azure

Welcome to the PowerShell Automation repository!  
This repository contains a collection of PowerShell scripts that I actively develop and maintain for automating infrastructure tasks in both **VMware vSphere environments** and **Microsoft Azure cloud**.

## 🔧 Purpose

These scripts help streamline and automate a range of tasks, including:

- VMware VM lifecycle management (create, modify, delete, snapshot)
- Azure resource provisioning and configuration
- Automation of routine administrative tasks across hybrid environments
- Reporting and compliance checks

This repository serves as both a toolkit and a personal development space for infrastructure automation.

---

## 🧰 Prerequisites

To get started with these scripts, you'll need to install the following PowerShell modules:

### ✅ Install Azure Modules

To install the **Azure PowerShell module** from the PowerShell Gallery, run:

```powershell
Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
```

> 💡 You may be prompted to trust the repository if this is your first time.

### ✅ Install VMware PowerCLI

To install **VMware PowerCLI**, run the following:

```powershell
Install-Module -Name VMware.PowerCLI -Scope CurrentUser -Repository PSGallery -Force
```

> 🔐 PowerCLI may prompt you to change the PowerShell execution policy. You can temporarily bypass this with:
>
> ```powershell
> Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
> ```

---

## 📂 Repository Structure

```
/VMware-Scripts/
    - Connect-vCenter.ps1
    - Create-VM.ps1
    - Snapshot-Cleanup.ps1

/Azure-Scripts/
    - Login-AzAccount.ps1
    - Create-ResourceGroup.ps1
    - Deploy-VM.ps1
```

---

## 📌 Notes

- Ensure you are running PowerShell 7.x or later for better performance and compatibility.
- These scripts are regularly updated as part of ongoing improvements and automation requirements.
- Contributions or suggestions are welcome — feel free to open issues or submit PRs!

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

---

## 🤝 Connect

If you'd like to collaborate or have questions, reach out via GitHub Issues or Discussions.
