# Homelab Certificate Authority

This directory contains scripting for maintaining a local certificate authority for applications that require TLS connections within the homelab.  Using a publicly available solution such as [Let's Encrypt](https://letsencrypt.org) is contraindicated, since the homelab uses DNS domains (e.g., `h.bbassett.net`) and RFC 1918 private addresses (10.1.1.x) that are not accessible outside the lab.

Note that the state files used for managing the CA are not checked in (and are excluded in the `.gitignore` file), with the exception of the root CA certificate (which can be deployed to trust databases in various Ansible playbooks).

## References

- https://jamielinux.com/docs/openssl-certificate-authority/

