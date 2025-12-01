# Procedure: Move Data From LXC Container To ZFS Dataset

1. Determine the size of the new ZFS dataset by multiplying the desired size in GB by 1,048,576.  Append `k` so that the ZFS tools correctly scales the value.
2. On the Proxmox host, create the new ZFS dataset:
   ```
   zfs create -o acltype=posixacl -o xattr=sa -o refquota=${SIZE_FROM_STEP_1} tank/${CONTAINERNAME}-${VOLUMENAME}
   ```
3. Mount the new ZFS dataset to a temporary location (`/a`) on the LXC container:
   ```
   pct set ${CONTAINERID} -mp0 /tank/${CONTAINERNAME}-${VOLUMENAME},mp=/a
   ```
4. In the container, determine the ownership of the existing data root and set the new dataset to the same ownership:
   ```
   ls -ld ${CONTAINERDATAROOT}
   chown ${USER}:${GROUP} /a
   ```
5. Stop the service so that nothing is modifying the data to move to the new dataset.
6. Move the data to the new dataset:
   ```
   mv ${CONTAINERDATAROOT}/* /a
   ```
7. On the Proxmox host, remount the dataset to the correct location on the container:  This results in a pending operation, since the mount point already exists on the container.
   ```
   pct set ${CONTAINERID} -mp0 /tank/${CONTAINERNAME}-${VOLUMENAME},mp=${CONTAINERDATAROOT}
   ```
8. Reboot the container:
   ```
   pct reboot ${CONTAINERID}
   ```
9. In the container, remove the temporary directory:
   ```
   rm -f /a
   ```
