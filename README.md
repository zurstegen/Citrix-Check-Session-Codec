# Citrix-Check-Session-Codec

A Powershell Script to monitor the Hardware Encoding and Session Codecs in a Citrix Virtual Apps and Desktop environments with NVIDIA vGPU.

## Requirements:
- Citrix Virtual Apps and Desktops SDK - Powershell Snapins
- Allow Remote WMI requests on the VDAs

## Usage:
	Add-PSSnapin citrix*
	Import-Module "C:\Test\Check-CVADSessionCodec.psm1" -Force
	Check-CVADSessionCodec -deliverygroup "Test_Delivery_Group"
	
## Disclaimer:
Only with the following versions are tested:
- NVIDIA vGPU 6.4
- NVIDIA vGPU 7.0
- Citrix XenDesktop 7.15.2
- Citrix XenDesktop 7.17
- Citrix XenDesktop 7.18
- Citrix XenApp 7.18
- Citrix XenApp 1808
- Citrix XenApp 1811

This soucre and the whole package comes without warranty. It ma or may not ham your computer. Please use with care. Any damage cannot be related back to the author. The source has been tested on a virtual environment.
