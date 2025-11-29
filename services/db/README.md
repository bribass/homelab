# db

| | |
|-|-|
| **Proxmox ID** | CT 102 |
| **LXC Base Template** | `debian-13-standard` |
| **IP Address** | 10.1.1.11 |

This container is a database server (specifically, [PostgreSQL](https://www.postgresql.org/)).  Users are not expected to log into this container, nor access Postgres from a shell on the system.

## Procedures

### Synchronize Postgres with LDAP

Because all user accounts in Postgres (with the exception of the default `postgres` system account) are backed by LDAP, any changes to LDAP must be manually replicated into Postgres:
1. In LDAP, make sure that the new accounts are either object class `posixAccount` (for accounts with shells) or `account`/`simplesecurityobject` (for service accounts without shells).  Add them to the `cn=Postgres Users,ou=Groups,dc=h,dc=bbassett,dc=net` group's `member` attribute.
2. As `root` in the container, run:
   ```shell
   pg_ldap_sync -vvv
   ```

## References

- https://wiki.debian.org/PostgreSql: Debian's Postgres infrastructure.
- https://medium.com/@yeyangg/configuring-postgresql-for-lan-network-access-2023-fcbd2df4a157: Network configuration for Postgres.
- https://www.postgresql.org/docs/17/auth-ldap.html: LDAP authentication configuration.
- https://docs.redhat.com/en/documentation/red_hat_directory_server/11/html/administration_guide/advanced_entry_management#groups-cmd-memberof: LDAP server plugin for determining if a user is in a group entry.
- https://wiki.debian.org/PhpPgAdmin: Debian's phpPgAdmin documentation.

