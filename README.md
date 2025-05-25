# Homelab

This repository contains configuration and maintenance scripts for my homelab.

## Hardware

The lab system is centralized on a single host, with the following components:

|  | Component |
| --------- | -----|
| Motherboard/CPU | [Minisforum BD795i SE](https://www.amazon.com/dp/B0DQ8WXMKP) with AMD Ryzen 9 7945HX |
| RAM | 64GB |
| Case | [Jonsbo N3](https://www.amazon.com/dp/B0CMVBMVHT) |
| Storage Controller | [LSI SAS2308 HBA](https://www.amazon.com/dp/B0BXPWJLM6) |
| Storage | 8x various SATA NAS drives (4x WD Red, 4x Seagate IronWolf) |
|         | 512 GB NVMe SSD (for operating system) |
| Operating System | [Proxmox VE](https://proxmox.com) 8.4 |

The system was inspired by [Alex](https://github.com/IronicBadger/pms-wiki)'s [Perfect Media Server](https://perfectmediaserver.com) project, and component selection included influences from various PC hardware YouTubers ([NASCompares](https://www.youtube.com/@nascompares), [Wendell of Level 1 Techs](https://youtu.be/M0p8HMeO_WI), and [Hardware Haven](https://youtu.be/i3G_LvowBkI)).
