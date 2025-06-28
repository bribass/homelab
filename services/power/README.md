# power

| | |
|-|-|
| **Hardware** | Raspberry Pi 3B+ |
| **IP Address** | 10.1.1.4 |

XXX UPS

## Manual Steps Before Ansible

1. Prepare the filesystem SD card by using [directions](https://wiki.debian.org/RaspberryPiImages) and [image files](https://raspi.debian.net/tested-images/) from Debian.
2. Install the SD card into the RasPi and boot it.  Log in as `root` (no password as mentioned in directions above).
3. Edit `/etc/hostname` and change the hostname to `power`.
```
echo power > /etc/hostname
```
4. Set the root password.
```
passwd
```
5. Copy your SSH public key to the system.
```
scp me@workstation:~/.ssh/id_rsa.pub /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
```
6. Apply all available system updates.  Install the following packages:
   * `aptitude`
   * `python3-minimal`

## References

- https://youtu.be/dXSbURqdPfI: Video that inspired this system.
- https://techno-tim.github.io/posts/NUT-server-guide/: Non-`wolnut` walkthrough referenced in the avobe video.

