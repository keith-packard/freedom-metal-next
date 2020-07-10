#!/usr/bin/env python3
# Copyright (c) 2020 SiFive Inc.
# SPDX-License-Identifier: Apache-2.0

"""Functions for finding freedom-metal sources in a Device Tree"""

import os

def has_compat(node) -> bool:
    """ Checks whether the given node has a "compatible" value"""
    return node.get_fields("compatible") is not None

# Watchdog and RTC live in AON block

COMPATIBLE_MAP = {
    "sifive,aon0": ("sifive,wdog0", "sifive,rtc0"),
}

def get_compatibles(tree):
    """Given a Devicetree, get the list of 'compatible' values"""

    compatibles = tree.filter(has_compat)

    return compatibles

EXTENSIONS = ('.c', '.S')

def make_filename(compatible):
    """Convert a compatible value into a freedom-metal style filename"""
    return compatible.replace(',', '_')

def find_source(basename, dirs):
    """Locate the named file in one of the listed directories"""
    for direc in dirs:
        path = os.path.join(direc, basename)
        if os.path.exists(path):
            return path
    return None

def find_paths(compat, dirs):
    """Given a compatible string, find matching files"""
    file = make_filename(compat)
    for ext in EXTENSIONS:
        path = find_source(file + ext, dirs)
        if path:
            return [path]
    if compat in COMPATIBLE_MAP:
        paths = []
        for p in COMPATIBLE_MAP[compat]:
            paths += find_paths(p, dirs)
        return paths
    return []

def get_sources(tree, dirs):
    """Given a Devicetree, get the list of source files available"""

    compatibles = get_compatibles(tree)
    sources_c = []
    sources_s = []
    for compatible in compatibles:
        device_types = compatible.get_fields("device_type")
        if device_types is None:
            device_types = [None]
        else:
            # pylint: disable=R1721
            # this comprehension converts device_types into a list
            device_types = [None] + [d for d in device_types]
        for compat in compatible.get_fields("compatible"):
            for device_type in device_types:
                if device_type is not None:
                    compat += '_' + device_type
                paths = find_paths(compat, dirs)
                for path in paths:
                    if path not in sources_c and path not in sources_s:
                        if path.endswith('.c'):
                            sources_c += [path]
                        else:
                            sources_s += [path]

    return (sources_c, sources_s)
