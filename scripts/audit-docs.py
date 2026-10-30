#!/usr/bin/env python3
"""Audits docs/ against the symbols libft.so actually exports.

Documenting a function that does not exist is worse than not documenting it: a
reader writes code that fails to link, or binds to NULL and crashes at runtime.
This has already happened once - the C API reference listed eight functions that
were either renamed or never existed:

    ft_window_grab_pointer / ft_window_ungrab_pointer
    ft_window_install_event_filter
    ft_window_get_native_window
    ft_widget_add_tick_callback / ft_widget_remove_tick_callback
    ft_window_get_egl_display / ft_window_get_egl_surface / ft_window_get_egl_context
    ft_window_is_modal

Run this after changing the exported API or editing the reference:

    python3 scripts/audit-docs.py            # check
    python3 scripts/audit-docs.py --coverage # also list undocumented exports

Exit status is non-zero if any documented name is missing, so it can gate CI.
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB = os.path.join(ROOT, 'target', 'libft.so')
DOCS = os.path.join(ROOT, 'docs')


def exported_symbols():
    out = subprocess.run(['nm', '-D', '--defined-only', LIB],
                         capture_output=True, text=True)
    if out.returncode != 0:
        sys.exit('cannot read %s (build it first): %s'
                 % (LIB, out.stderr.strip()))
    names = set()
    for line in out.stdout.splitlines():
        parts = line.split()
        if parts:
            names.add(parts[-1])
    return names


def main():
    coverage = '--coverage' in sys.argv

    exported = exported_symbols()

    # Only consider names that look like exported C entry points.
    pattern = re.compile(r'\b(ft_[a-z0-9_]+)\s*\(')
    mentioned = set()
    for name in sorted(os.listdir(DOCS)):
        if not name.endswith('.md'):
            continue
        with open(os.path.join(DOCS, name), encoding='utf-8') as f:
            mentioned |= set(pattern.findall(f.read()))

    missing = sorted(n for n in mentioned if n not in exported)

    print('mentioned in docs : %d' % len(mentioned))
    print('exported by libft : %d' % len(exported))
    print()

    if missing:
        print('DOCUMENTED BUT NOT EXPORTED (%d):' % len(missing))
        for n in missing:
            print('  %s' % n)
        print()
        print('Either the function was renamed (fix the docs) or removed '
              '(remove the row).')
    else:
        print('OK: every ft_* name in the docs is exported.')

    if coverage:
        undocumented = sorted(n for n in exported
                              if n.startswith('ft_') and n not in mentioned
                              and '$' not in n)
        print()
        print('exported but not documented (%d):' % len(undocumented))
        for n in undocumented:
            print('  %s' % n)

    return 1 if missing else 0


if __name__ == '__main__':
    sys.exit(main())
