DOCUMENTATION = """
    name: win_terminal_fragment_guid
    author: Brian Bassett
    short_description: generate the guid for a Windows Terminal config fragment
    description:
      - Returns a string; returns the GUID of a profile for 'settings.json'
      - https://learn.microsoft.com/en-us/windows/terminal/json-fragment-extensions#profile-guids
    options:
      _terms:
        description: application name and profile name of the profile
      builtin:
        description: whether or not the profile should be considered built-in
        type: bool
        default: false
      braces:
        description: whether or not to add the braces around the generated GUID
        type: bool
        default: true
"""

EXAMPLES = """
- name: show profile guid
  ansible.builtin.debug:
    msg: "{{ lookup('win_terminal_fragment_guid', 'Git', 'Git Bash') }}"
"""

RETURN = """
_raw:
  description: profile guid
  type: list
  elements: string
"""

import uuid

from ansible.plugins.lookup import LookupBase
from ansible.utils.display import Display


display = Display()


class LookupModule(LookupBase):

    def run(self, terms, variables=None, **kwargs):
        ret = ""
        self.set_options(var_options=variables, direct=kwargs)

        builtin = False
        if self.has_option('builtin'):
            builtin = self.get_option('builtin')
        display.vvvv("builtin: %s" % builtin)

        braces = True
        if self.has_option('braces'):
            braces = self.get_option('braces')
        display.vvvv("braces: %s" % braces)

        if builtin:
            guid = uuid.UUID("{2bde4a90-d05f-401c-9492-e40884ead1d8}")
        else:
            guid = uuid.UUID("{f65ddb7e-706b-4499-8a50-40313caf510a}")
        display.vvvv("starting guid: %s" % guid)

        if braces:
            brace_open = "{"
            brace_close = "}"
        else:
            brace_open = ""
            brace_close = ""

        for term in terms:
            display.debug("Adding term: %s" % term)

            guid = uuid.uuid5(guid, term.encode("utf-16le").decode("ascii"))
            display.vvvv("added term: %s, new guid: %s" % (term, guid))

        ret = [f"{brace_open}{guid}{brace_close}"]
        return ret

