# Testing

To run a playbook against a local container:

1. Make sure that the appropriate container image has been built on the local system: 
    ```bash
    $ podman build -t ansible-test-debian-13 ansible/test/images/debian-13
    ```
2. In the playbook to test, update the `hosts:` entry to include `test` (e.g., change `hosts: box` to `hosts: box, test`).
3. Start the container by running: 
    ```bash
    $ ansible/test/scripts/start-test.sh -p 8080 ansible-test-debian-13
    ```
   Since playbooks generally interact with systemd, appropriate container images will not start a shell, but will start systemd.  As a result, the `start-test.sh` script will display the command to connect to the container environment. 
4. When running the playbook, make sure to limit the run to the test system:
    ```bash
    $ ansible-playbook -l test services/box/ansible.yaml
    ```
