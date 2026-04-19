DOCUMENTATION = """
    name: php_variables
    author: Brian Bassett
    short_description: Read a PHP file and report the contents of specific PHP variables.
    description:
      - Read a PHP file and report the contents of specific PHP variables.
    options:
       path:
         description: Remote absolute path of the PHP file to read variables from.
         type: path
         required: true
       variables:
         description: List of PHP variables to report.  Each variable should contain the initial '$' from PHP declarations.
         type: list
         elements: str
         required: true
       php_cli:
         description: Path the the PHP CLI executable.
         type: path
         default: php
"""

EXAMPLES = """
- name: Read variables from PHP file
  php_variables:
    path: /path/to/file.php
    variables:
      - "$var"
      - "$val"
  register: php
  
- name: Display results
  ansible.builtin.debug:
    msg: "Results: {{ php.variables.var }} = {{ php.variables.val }}"
"""

RETURN = """
variables:
    description: Dictionary containing the values of each requested variable.  Keys (the variable name) will have their initial '$' removed for easy access to the value.
    type: dict
    returned: always
"""

import json
import os

from ansible.module_utils.basic import AnsibleModule


def main():
    module_args = {
        "path": {"type": "path", "required": True},
        "variables": {"type": "list", "elements": "str", "required": True},
        "php_cli": {"type": "path", "default": "php"}
    }
    result = {
        "changed": False,
    }
    module = AnsibleModule(argument_spec=module_args, supports_check_mode=True)

    # Verify the path exists
    path = module.params['path']
    if not os.path.exists(path):
        module.fail_json(msg=f"Source {path} not found", **result)
    if not os.access(path, os.R_OK):
        module.fail_json(msg=f"Source {path} not readable", **result)

    # Create the script that extracts variable values
    php_script = f"""<?php
require_once('{path}');
print(json_encode((object) [
{''.join([f"'{var.lstrip('$')}' => {var},\n" for var in module.params['variables']])}
]));"""

    # Run the php CLI with the script
    (rc, stdout, stderr) = module.run_command([module.params['php_cli']], data=php_script)
    if rc != 0:
        result["script"] = php_script.split("\n")
        result["stdout"] = stdout
        result["stderr"] = stderr
        module.fail_json(msg="Error running PHP", **result)

    # Now parse the returned JSON and put it into the result
    try:
        result["variables"] = json.loads(stdout)
    except json.JSONDecodeError as e:
        module.fail_json(msg="Error with results returned from PHP", exception=e, **result)

    module.exit_json(**result)


if __name__ == '__main__':
    main()
