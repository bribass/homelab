# certs

| | |
|-|-|
| **Proxmox ID** | CT 104 |
| **LXC Base Template** | `debian-13-standard` |
| **IP Address** | 10.1.1.13 |

This container is a full certificate authority capable of issuing certificates both manually (via CSR requests) and automatically (via a Let's Encrypt style ACME directory).

## Procedures

### Initial Configuration of UCM

1. Log into the UCM frontend using the default `admin` user.  The initial password is output to the system log (which can be viewed by running `journalctl -xeu ucm.service`).
2. Configure LDAP authentication.  Select "Settings" in the left navigation bar, and then open "SSO" in the "Security" section.  Configure "LDAP/Active Directory".  Set the following settings:
   * Provider name: `prod`
   * Display name: Homelab Auth
   * Enable provider: yes
   * Default login provider: yes
   * Enforce 2FA: no
   * Connection:
     * Directory type: Custom
     * LDAP Server: `auth.h.bbassett.net`
     * Port: 389
     * Use SSL/TLS: no
     * Use StartTLS: yes
     * Verify SSL Certificate: no
     * Bind DN: `uid=LDAP Bind,ou=Service Accounts,dc=h,dc=bbassett,dc=net`
     * Bind Password: See value encrypted in Ansible Vault configuration (`yq -r '.passwd.auth.bind' ansible/inventory/group_vars/all.yaml | ansible-vault decrypt`)
     * Base DN: `dc=h,dc=bbassett,dc=net`
   * Groups & Role Mapping:
     * Group membership attribute: member (OpenLDAP/RFC 2307)
     * Default role: Viewer
     * Role mapping:
       * External group: UCM Admins
       * Base role: Admin
       * Custom role: None

### Create the Production CA

1. Log into the UCM frontend using your username.
2. Select "Certificate Authorities" from the "PKI" section of the left navigation bar.  Click the "Import" button, and drag and drop the files `conf/ca-root/ca.crt` and `conf/ca-root/ca.key` into the smart import dialog box.  Use the value encrypted in Ansible Vault configuration (`yq -r '.passwd.ca.root_ca' ansible/inventory/group_vars/all.yaml | ansible-vault decrypt`) for the key's decryption password.  Accept all subsequent dialogs.
3. Create the intermediate CA by clicking the "Create" button.  Use the following values where noted:
    * Common name: BBassett Homelab CA Intermediate *n*
    * Country: US
    * State/Province: Washington
    * City: Kenmore
    * Organization: BBassett
    * Org Unit: Homelab
    * Key size: 4096 bits
    * Validity period: 10 years
    * CA type: Intermediate CA (signed by parent)
    * Parent CA: BBassett Homelab CA Root
4. Take the root CA offline by selecting the root CA in the main view.  In the popup select "Take Offline" from the bar underneath the title bar.  Confirm that taking the CA offline is desired.  Enter a sufficient password, download the generated key file, and delete both (the original is still available in the repository).

## References

- 
