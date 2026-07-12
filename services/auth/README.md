# auth

| | |
|-|-|
| **Proxmox ID** | CT 101 |
| **LXC Base Template** | `debian-13-standard` |
| **IP Address** | 10.1.1.9 |

This container hosts the homelab's authentication mechanisms.  LDAP (specifically, [389 Directory Server](https://www.port389.org)) provides the canonical storage for users and credentials.  Future authentication related features (e.g., an OpenID provider or a user password recovery page) will be deployed to this container.

## Procedures

### Create the Production Directory

Since the production LDAP directory contains user state, it is not conducive to the standard desired state configuration method of set up.
1. Generate the required documents to the top-level `ldif` directory by running:
   ```shell
   ansible-playbook services/auth/ldap-entries.yaml
   ```
   Copy the files to the `/tmp` directory of the container.
2. As `root` in the container, create the instance by running:
   ```shell
   mkdir -p /srv/dirsrv/prod/{etc,data}
   chown -R dirsrv:dirsrv /srv/dirsrv/prod
   ln -s /srv/dirsrv/prod/etc /etc/dirsrv/slapd-prod
   ln -s /srv/dirsrv/prod/data /var/lib/dirsrv/slapd-prod
   su -s /bin/bash dirsrv -c "dscreate from-file /tmp/instance.inf"
   ```
3. Import the homelab certificate authority and server keys to the instance by running:
   ```shell
   dsconf prod security ca-certificate add --file /path/to/ca/root/certs/ca.crt.pem  --name "HomelabRoot"
   dsconf prod security ca-certificate set-trust-flags "HomelabRoot" --flags "CT,,"
   dsconf prod security ca-certificate add --file /path/to/ca/intermediate/certs/intermediate1.crt.pem  --name "HomelabIntermediate1"
   dsconf prod security ca-certificate set-trust-flags "HomelabIntermediate1" --flags "CT,,"
   dsctl prod tls import-server-key-cert /path/to/ca/server/certs/auth.h.bbassett.net.crt.pem /path/to/ca/server/private/auth.h.bbassett.net.key.pem
   dsconf prod config replace nsslapd-securePort=636 nsslapd-security=on
   ```
4. Enable and configure the required plugins by running:
   ```shell
   dsconf prod plugin memberof enable
   dsconf prod plugin memberof set --scope dc=h,dc=bbassett,dc=net
   ```
5. Restart the directory service by running:
   ```shell
   systemctl restart dirsrv@prod.service
   ```
6. Load the directory structure to the directory service by running:
   ```shell
   mv /tmp/structure.ldif /srv/dirsrv/prod/data/ldif
   chown dirsrv /srv/dirsrv/prod/data/ldif/structure.ldif
   dsconf -D "cn=Directory Manager" prod backend import userRoot structure.ldif
   ```
7. For each remaining LDIF file, import it into the directory by running:
   ```shell
   for i in /tmp/*.ldif; do
     ldapmodify -H ldap://auth -D "cn=Directory Manager" -W -f $i
   done
   ```

## References

- https://www.suse.com/support/kb/doc/?id=000020983: Configuring TLS keys in 389

