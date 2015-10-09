#! /usr/bin/python

# Copyright (c) 2015 Dave McCoy (dave.mccoy@cospandesign.com)
#
# Nysa is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# any later version.
#
# Nysa is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Nysa; If not, see <http://www.gnu.org/licenses/>.


import sys
import json
import os
import argparse
from distutils import dir_util
import zipfile
import tempfile
import shutil
from cookielib import CookieJar
import urllib
from urllib2 import build_opener, HTTPCookieProcessor

path = os.path.abspath(os.path.curdir)

NAME = os.path.basename(os.path.realpath(__file__))

DESCRIPTION = "\n" \
              "\n" \
              "usage: %s [options]\n" % NAME

EPILOG = "\n" \
         "\n" \
         "Examples:\n" \
         "\t%s \n" \
         "\n"

debug = False

REPO_CONFIG_FILE = "repo_raw_config.json"

def get_repo_zip_file(url, dest_path):
    print "Getting URL: %s" % url
    tempdir = tempfile.mkdtemp()
    temparchive = os.path.join(tempdir, "archive.zip")
    print "Temp path:%s" % temparchive
    urllib.urlretrieve(url, temparchive)
    zf = zipfile.ZipFile(temparchive, "a")
    #zf.extractall(dest_path)
    zf.extractall(tempdir)
    zf.close()
    src = os.path.join(tempdir, "sdio-device-master", "rtl")
    dst = os.path.join(dest_path, "sdio_device")
    dir_util.copy_tree(src, dst)
    shutil.rmtree(tempdir)


def main(argv):
    #Parse out the commandline arguments
    parser = argparse.ArgumentParser(
        formatter_class=argparse.RawDescriptionHelpFormatter,
        description=DESCRIPTION,
        epilog=EPILOG
    )

    parser.add_argument("-d", "--debug",
                        action="store_true",
                        help="Enable Debug Messages",
                        )
    parser.add_argument("url",
                        type = str,
                        nargs = '?',
                        default = None,
                        help="Specify the URL, if left blank, the script will attempt to read the URL from a file in the same directory with the name: %s" % REPO_CONFIG_FILE)
    parser.add_argument("-o", "--output",
                        type = str,
                        nargs = 1,
                        default = path,
                        help = "Specify the output path, if not the current directory will be the path")

    args = parser.parse_args()
    url_path = None
    dest_path = None

    try:
        f = open (REPO_CONFIG_FILE, "r")
        config_data = json.load(f)
        url_path = config_data["url"]
        dest_path = os.path.abspath(config_data["output"])
    except IOError as err:
        pass
        
    if url_path is None:
        if args.url is None:
            print "Error: URL Path was not found in %s and was not specified on command line" % REPO_CONFIG_FILE
            sys.exit(1)
        else:
            url_path = args.url

    if dest_path is None:
        if args.output is None:
            print "Error: Destination path cannot be None"
        else:
            dest_path = args.output

    if args.debug:
        print "URL Path: %s" % url_path
        print "Output: %s" % dest_path
    else:
        get_repo_zip_file(url_path, dest_path)


if __name__ == "__main__":
    main(sys.argv)


