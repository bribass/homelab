# auth

| | |
|-|-|
| **Proxmox ID** | CT 101 |
| **LXC Base Template** | `debian-12-standard` |
| **IP Address** | 10.1.1.9 |

This container hosts the homelab's authentication mechanisms.  LDAP (specifically, [389 Directory Server](https://www.port389.org)) provides the canonical storage for users and credentials.  Future authentication related features (e.g., an OpenID provider or a user password recovery page) will be deployed to this container.

