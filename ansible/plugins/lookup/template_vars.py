DOCUMENTATION = """
    name: template_vars
    author: Brian Bassett
    short_description: determine the variables used by a Jinja2 template
    description:
      - Returns a list of strings; returns the names of all variables used by that template.
    options:
      _terms:
        description: list of files to template
      ignore_missing:
        description: ignore a template file name if it cannot be found on disk
        type: bool
        default: false
"""

EXAMPLES = """
- name: show template variables
  ansible.builtin.debug:
    msg: "{{ lookup('template_vars', './some_template.j2') }}"
"""

RETURN = """
_raw:
   description: variable(s) used in templates
   type: list
   elements: string
"""

import os

from ansible.errors import AnsibleError
from ansible.plugins.lookup import LookupBase
from ansible.template import trust_as_template
from ansible.utils.display import Display
import jinja2, jinja2.meta
import traceback


display = Display()


class LookupModule(LookupBase):

    def run(self, terms, variables=None, **kwargs):
        ret = []
        self.set_options(var_options=variables, direct=kwargs)

        ignore_missing = False
        if self.has_option('ignore_missing'):
            ignore_missing = self.get_option('ignore_missing')
        display.vvvv("ignore_missing: %s" % ignore_missing)

        for term in terms:
            display.debug("File lookup term: %s" % term)

            lookupfile = self.find_file_in_search_path(variables, 'templates', term, ignore_missing=ignore_missing)
            display.vvvv("File lookup using %s as file" % lookupfile)
            if lookupfile:
                template_data = trust_as_template(self._loader.get_text_file_contents(lookupfile))

                # Set jinja2 internal search path for includes
                searchpath = variables.get('ansible_search_path', [])
                if searchpath:
                    # Our search paths aren't actually the proper ones for jinja includes.
                    # We want to search into the 'templates' subdir of each search path in
                    # addition to our original search paths.
                    newsearchpath = []
                    for p in searchpath:
                        newsearchpath.append(os.path.join(p, 'templates'))
                        newsearchpath.append(p)
                    searchpath = newsearchpath
                searchpath.insert(0, os.path.dirname(lookupfile))

                # Directly use jinja instead of the templar because the templar will not give
                # us the raw template AST.  Note that directly accessing the templar's
                # environment is deprecated, and a better solution will be needed before
                # Ansible removes access.
                env = jinja2.Environment(loader=jinja2.FileSystemLoader(searchpath))
                env.filters = self._templar.environment.filters
                parsed = env.parse(template_data)
                ret.extend(jinja2.meta.find_undeclared_variables(parsed))
            else:
                if not ignore_missing:
                    raise AnsibleError("the template file %s could not be found for the lookup" % term)

        return ret
