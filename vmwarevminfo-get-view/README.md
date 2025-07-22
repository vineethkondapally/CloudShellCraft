# Complete VM Info Using Get-View

This PowerShell script `Completevminfousinggetview.ps1` is designed to collect comprehensive information about virtual machines (VMs) in a VMware vSphere environment. It utilizes the `Get-View` cmdlet from PowerCLI to access low-level vSphere API objects, enabling high-performance and detailed data retrieval.

## Overview and Purpose

The script provides a detailed inventory of each VM, including:
- The ESXi host on which the VM is running
- CPU, memory, and storage configuration
- The storage LUN where the VM is deployed
- Guest operating system details
- Cluster and datacenter placement
- VMware Tools version
- Network port group configuration

This script is especially useful for administrators who need to audit or document their virtual infrastructure with precision and performance.

## About Get-View Cmdlet

`Get-View` is a powerful and advanced cmdlet in VMware PowerCLI that returns vSphere View objects based on specified criteria. Unlike high-level cmdlets like `Get-VM`, which return simplified PowerShell objects, `Get-View` provides direct access to the underlying vSphere API objects. This allows for:
- Faster data retrieval, especially in large environments
- Access to deeply nested and detailed properties
- Greater flexibility in automation and reporting

Because `Get-View` operates at a lower level, it is ideal for scenarios where performance and detail are critical.

