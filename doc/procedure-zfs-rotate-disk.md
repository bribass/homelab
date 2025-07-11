# Procedure: Rotate Disk in ZFS Volume

1. Identify the old disk to replace.  Locate the disk pysically, and read off the serial number from the affixed label.  Verify that this identifier is present in the `zpool status tank` output.
2. Take the old disk offline.  Run `zpool offline tank old-disk-id`.  Remove the old disk from the system; the Jonsbo N3 case contains a hot-swap backplane, so system downtime is not required.
3. Install the new disk into the system.  Identify the full id based on the new disk's serial number (`basename /dev/disk/by-id/*new-serial-number`).
4. Replace the old with the new in ZFS by running `zpool replace tank old-disk-id /dev/disk/by-id/new-disk-id` (the old is a disk id, but the new is the device file for the disk).
5. ZFS will then begin the resilvering process.  Monitor the process by running `watch -n 5 zpool status tank`.  Wait until resilvering is complete.

## References

- https://aaronweiss.me/proxmox-zfs-disk-replacement-and-drive-expansion/

