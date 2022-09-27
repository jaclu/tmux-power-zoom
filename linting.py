#!/usr/bin/env python3

"""  Lints Py and shell files
"""

#
#  Normally I keep the Linter classes in a separate package, to reduce
#  dependencies, they are included here
#

import glob
import os
# from whichcraft import which
from shutil import which
from subprocess import run, CalledProcessError  # nosec B404
import sys


class LinterCore:
    """Uses predefined linters to scan a group of files"""

    # list of defined linters self.usable_mthds[] will contain
    # all linters found to be usable at run-time
    linters = ()
    file_patterns = ()
    include_ext = ()
    exclude_patterns = ()

    def __init__(self, skip_linters=()):
        self.usable_linters = []
        self.skipped_linters = []
        self.fnames = []
        self.skipped_by_linter = {}
        self.only_use_linters_available(skip_linters)
        self.scan_for_files()

    def list(self):
        """List linters and files selected"""
        print('Defined linters')
        for linter in self.linters:
            if linter in self.usable_linters:
                print(f'  {linter}')
            else:
                if linter in self.skipped_linters:
                    msg = 'deselected'
                else:
                    msg = 'unavailable'
                print(f'  *{linter}* <- {msg}')

        print('Items being processed')
        for item in self.fnames:
            print(f'  {item}')
        return self  # to make chaining available

    def include(self, item):
        """Add one file to the queue"""
        self.fnames.append(self.item_with_prefix(item))
        return self  # to make chaining available

    def exclude(self, item, linter=''):
        """Exclude one file, if linter is given just for that combo"""
        itm = self.item_with_prefix(item)
        for fname in self.fnames:
            if fname == itm:
                if linter and linter not in self.usable_linters:
                    print()
                    print('ERROR: Attempt to exclude undefined linter: '
                          f'{linter} for file: {item}')
                    sys.exit(1)
                if linter:
                    if linter not in self.skipped_by_linter:
                        self.skipped_by_linter[linter] = []
                    self.skipped_by_linter[linter].append(itm)
                    print(f'Excluded from [{linter}] check: {fname}')
                else:
                    # completely remove the item from being linted
                    self.fnames.remove(fname)
                    print(f'Excluded from check: {fname}')
                break
        return self  # to make chaining available

    def run(self):
        """This does the actual linting"""
        for fname in self.fnames:
            for mthd in self.usable_linters:
                if mthd in self.skipped_by_linter and \
                        fname in self.skipped_by_linter[mthd]:
                    continue
                self.lint_one(mthd, fname)
        print('')  # LF after dot progress

    #
    #  Internals
    #
    def only_use_linters_available(self, skip_linters=()):
        """remove linters not found on local system"""
        for mthd in self.linters:
            cmd = mthd.split(' ')[0]
            if cmd in skip_linters:
                self.skipped_linters.append(cmd)
                continue
            if which(cmd) is not None:
                self.usable_linters.append(mthd)
        if not self.usable_linters:
            print(f'WARNING: none of {self.linters} found!')
            return
        print(f'Using:  {self.usable_linters}')

    def item_with_prefix(self, item):
        """adds a prefix if not already present"""
        if item[0] != '/':
            #  Silences bandit (py linter) from complaining
            #  about no qualified name
            item = './' + item
        return item

    def scan_for_files(self):
        """Recursively scan file-tree for matching files"""
        for fname in glob.iglob('**/*', recursive=True):
            if os.path.isdir(fname):
                continue
            dont_process = False
            for skip_it in self.exclude_patterns:
                if skip_it in fname:
                    dont_process = True
                    continue
            if dont_process:
                continue  # The agony of continue from nested for loops
            _, ext = os.path.splitext(fname)
            if ext in self.include_ext:
                self.include(fname)

    def lint_one(self, mthd, fname):
        """Process one file using specified linter"""
        args = mthd.split(' ')
        args.append(fname)
        do_exit = False
        try:
            res = run(args, check=True)  # nosec B603
        except CalledProcessError:
            do_exit = True
        else:
            if res.returncode != 0 or res.stdout or res.stderr:
                do_exit = True
        if do_exit:
            print(f'error found:  {mthd}  {fname}')
            sys.exit(1)
        print('.', end='')
        sys.stdout.flush()


#
#  Some sample file type classes, to give an idea of how the
#  abstract LinterCore class can be used
#

class ShellLinter(LinterCore):
    linters = (
        'shellcheck -x -a -o all -e SC2250,SC2312',
        '/usr/local/bin/checkbashisms -n -e -x',
    )
    include_ext = (
        '.sh',
        '.tmux',
    )


ShellLinter().run()
