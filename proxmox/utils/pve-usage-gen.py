from collections import namedtuple

Option = namedtuple('Option', ['short_opt', 'long_opt', 'metavar', 'long_desc', 'short_desc', 'var', 'default'])
Positional = namedtuple('Positional', ['metavar', 'long_desc', 'short_desc', 'var'])
OPTIONS: dict[str, tuple[str, list[Option], list[Positional]]] = {
    "login": ("Log in to a Proxmox PVE server and print curl options for authenticating with that session.", [
        Option('H', 'host', 'HOST', 'Hostname of PVE server to log in to', 'host', 'PVE_HOST', None),
        Option('P', 'port', 'PORT', 'Port of PVE server to log in to', 'port', 'PVE_PORT', '8006'),
        Option('u', 'user', 'USER', 'Username and realm (name@realm) to log in as', 'user', 'PVE_USER', None),
        Option('l', 'line', None, 'Output curl options in a line-oriented way', None, 'LINE_ORIENTED', False),
    ], []),
    "oci-pull": ("Download an OCI image from a registry to a PVE storage pool.", [
        Option('H', 'host', 'HOST', 'Hostname of PVE server to log in to', 'host', 'PVE_HOST', None),
        Option('P', 'port', 'PORT', 'Port of PVE server to log in to', 'port', 'PVE_PORT', '8006'),
        Option('u', 'user', 'USER', 'Username and realm (name@realm) to log in as', 'user', 'PVE_USER', None),
        Option('s', 'storage', 'POOL', 'PVE storage pool name to download image to', 'storage pool', 'PVE_STORAGE', None),
        Option('f', 'filename', 'NAME', 'Set the filename (sans extension) of the template file on the PVE server', None, 'PVE_FILENAME', None)
    ], [
        Positional('oci-image-ref', 'OCI image reference to download', 'OCI image reference', 'OCI_IMAGE'),
    ]),
}


def bool_yesno(val: bool) -> str:
    return '"yes"' if val else '"no"'


def getopt_short(options: list[Option]) -> str:
    return "".join([f"{opt.short_opt}{'' if isinstance(opt.default, bool) else ':'}" for opt in options])


def getopt_long(options: list[Option]) -> str:
    return ",".join([f"{opt.long_opt}{'' if isinstance(opt.default, bool) else ':'}" for opt in options])


def getopt_defaults(options: list[Option]) -> str:
    return "\n".join([f"{opt.var}={default_value(opt)}" for opt in options])


def default_value(opt: Option) -> str:
    if isinstance(opt.default, str):
        return f'"{opt.default}"'
    if isinstance(opt.default, bool):
        return f'{bool_yesno(opt.default)}'
    return '""'


def getopt_process(options: list[Option]) -> str:
    return "\n".join([f"""    -{opt.short_opt} | --{opt.long_opt})
      {opt.var}={bool_yesno(not opt.default) if isinstance(opt.default, bool) else '"$2"'}
      shift {1 if isinstance(opt.default, bool) else 2}
      ;;""" for opt in options])


def long_opt_and_metavar(opt: Option) -> str:
    return f"{opt.long_opt}{'' if opt.metavar is None else f' {opt.metavar}'}"


def getopt_usage(main_desc: str, options: list[Option], positional: list[Positional]) -> str:
    options_indent = max([len(long_opt_and_metavar(opt)) for opt in options])
    return f"""    -h | --help)
      echo "Usage: $0 {' '.join([f"[-{opt.short_opt}|--{long_opt_and_metavar(opt)}]" for opt in options])} [-h|--help]{''.join([f' {pos.metavar}' for pos in positional])}"
      echo "{main_desc}"
      echo ""
      echo "Options:"
{'\n'.join([f"      echo \"  -{opt.short_opt}, --{long_opt_and_metavar(opt)}{' '*(options_indent-len(long_opt_and_metavar(opt)))}  {opt.long_desc}{f' (default {opt.default})' if opt.default is not None else ''}\"" for opt in options])}
      echo "  -h, --help{' '*(options_indent-4)}  Display this help message"
      exit 0
      ;;"""


def getopt_positional(positional: list[Positional]) -> str:
    buf = ""
    for i, pos in enumerate(positional):
        buf += f"{pos.var}=${i + 1}\n"
    return buf


def getopt_nondefaults(options: list[Option], positional: list[Positional]) -> str:
    all = []
    all.extend([opt for opt in options if opt.default is None and opt.short_desc is not None])
    all.extend(positional)
    return "\n".join([f"""if [ -z "${opt.var}" ]; then
  echo "$0: no {opt.short_desc} specified; aborting" >&2
  exit 1
fi""" for opt in all])


def main():
    for prog, (desc, opts, pos) in OPTIONS.items():
        print(f"""## pve-{prog}.sh

# Process command line options
if ! OPTS=$(getopt -o {getopt_short(opts)}h -l {getopt_long(opts)},help -n "$0" -- "$@"); then
  exit 1
fi
eval set -- "$OPTS"
{getopt_defaults(opts)}
while true; do
  case "$1" in
{getopt_process(opts)}
{getopt_usage(desc, opts, pos)}
    --)
      shift 
      break
      ;;
    *)
      echo "$0: internal error while processing command line" >&2
      exit 1
      ;;
  esac
done
{getopt_positional(pos)}
{getopt_nondefaults(opts, pos)}
""")




if __name__ == '__main__':
    main()
