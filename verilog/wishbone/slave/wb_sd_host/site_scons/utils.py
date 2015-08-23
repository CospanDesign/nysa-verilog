#Distributed under the MIT licesnse.
#Copyright (c) 2013 Cospan Design (dave.mccoy@cospandesign.com)

#Permission is hereby granted, free of charge, to any person obtaining a copy of
#this software and associated documentation files (the "Software"), to deal in
#the Software without restriction, including without limitation the rights to
#use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
#of the Software, and to permit persons to whom the Software is furnished to do
#so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.


import os
import json
import platform
import glob
import re


PROJECT_BASE = os.path.abspath(
                    os.path.join(os.path.dirname(__file__), os.pardir))

DEFAULT_CONFIG_FILE = "config.json"
DEFAULT_BUILD_DIR = "build"
TOOL_TYPES=("ise",
            "planahead",
            "vivado")

LINUX_XILINX_DEFAULT_BASE = "/opt/Xilinx"
WINDOWS_XILINX_DEFAULT_BASE = "Xilinx"

class ConfigurationError(Exception):
    """
    Errors associated with configuration:
        getting the configuration file for the project
        getting the default xilinx toolchain
    """
    pass

def get_project_base():
    """
    Returns the project base directory

    Args:
        Nothing

    Returns:
        Path (String) to base directory

    Raises:
        Nothing
    """
    return PROJECT_BASE

def get_window_drives():
    """
    Returns a list of drives for a windows box

    Args:
        Nothing

    Return:
        Returns a list of drives in a list
    """
    if os.name != "nt":
        raise ConfigurationError("Not a windows box")

    import string
    from ctypes import windll

    drives = []
    bitmask = windll.kernel32.GetLogicalDrives()
    for letter in string.uppercase:
        #For every letter of the alphabet (string.uppercase)
        if bitmask & 1:
            #if the associated bit for that letter is set
            drives.append(letter)
        bitmaks >>= 1

    return drives

def find_license_dir(path = ""):
    """
    Based on the operating system attempt to find the license in the default
    locations

    Args:
        path (string): a path to the license, or a path to start searching
            for the license

    Returns:
        (string) A path to where the license files are

    Raises:
        Configuration Error when a license cannot be found
    """
    if len (path) > 0:
        if os.path.exists(path):
            return path

    if os.name == "posix":
        #First attemp to find the file in the default location

        home = os.environ["HOME"]
        xilinx_dir = os.path.join(home, ".Xilinx")
        if os.path.exists(xilinx_dir):
            search_path = os.path.join(xilinx_dir, "*.lic")
            results = glob.glob(search_path)
            if len(search_path) > 0:
                #print "Found directory: %s, results: %s" % (xilinx_dir, str(results[0]))
                return search_path

        raise ConfiugrationError("Error unable to find Xilinx Lincense File")

    elif os.name == "nt":

        print "Windows box... TODO :("
        raise ConfiugrationError("Error unable to find Xilinx Lincense File on Windows box")


def find_xilinx_path(path = "", build_tool = "ISE", version_number = ""):
    """
    Finds the path of the xilinx build tool specified by the user

    Args:
        path (string): a path to the base directory of xilinx
            (leave empty to use the default location)
        build_type (string): to use, valid build types are found with
            get_xilinx_tool_types
            (leave empty for "ISE")
        version_number (string): specify a version number to use
            for one of the tool chain: EG
                build_tool = ISE version_number     = 13.2
                build_tool = Vivado version_number  = 2013.1
            (leave empty for the latest version)


    Returns:
        A path to the build tool, None if not found

    Raises:
        Configuration Error
    """

    #Searches for the xilinx tool in the default locations in Linux and windows
    if build_tool.lower() not in TOOL_TYPES:
        raise ConfigurationError("Build tool: (%s) not recognized \
                                  the following build tools are valid: %s" %
                                  (build_tool, str(TOOL_TYPES)))

    xilinx_base = ""
    if os.name == "posix":
        #Linux
        if len(path) > 0:
            xilinx_base = path
        else:
            xilinx_base = LINUX_XILINX_DEFAULT_BASE
            #print "linux base: %s" % xilinx_base

        #if not os.path.exists(xilinx_base):
        if not os.path.exists(xilinx_base):
            #print "path (%s) does not exists" % LINUX_XILINX_DEFAULT_BASE
            return None

    elif os.name == "nt":
        if path is not None or len(path) > 0:
            xilinx_base = path
        else:
            #Windows
            drives = get_window_drives()
            for drive in drives:
                #Check each base directory
                try:
                    dirnames = os.listdir("%s:" % drive)
                    if WINDOWS_XLINX_DEFAULT_BASE in dirnames:
                        xilinx_base = os.path.join("%s:" % drive,
                                WINDOWS_XILINX_DEFUALT_BASE)
                        if os.path.exists(xilinx_base):
                            #this doesn't exists
                            continue
                        #Found the first occurance of Xilinx drop out
                        break

                except WindowsError, err:
                    #This drive is not usable
                    pass

        if len(xiilinx_base) == 0:
                return None

    #Found the Xilinx base
    dirnames = os.listdir(xilinx_base)

    if build_tool.lower() == "ise" or build_tool.lower() == "planahead":
        "ISE and Plan Ahead"
        if len(version_number) > 0:
            if version_number not in dirnames:
                raise ConfigurationError(
                        "Version number: %s not found in %s" %
                        (version_number, xilinx_base))
            return os.path.join(xilinx_base, version_number, "ISE_DS")

        #get the ISE/planahead base
        f = -1.0
        max_float_dir = ""
        for fdir in os.listdir(xilinx_base):
            #print "fdir: %s" % fdir
            try:
                if f < float(fdir):
                    f = float(fdir)
                    #print "Found a float: %f" % f
                    max_float_dir = fdir
            except ValueError, err:
                #Not a valid numeric directory
                pass
        return os.path.join(xilinx_base, max_float_dir, "ISE_DS")

    else:
        if "Vivado" not in dirnames:
            raise ConfigurationError(
                    "Vivado is not in the xilinx directory")

        xilinx_base = os.path.join(xilinx_base, "Vivado")

        if len(os.listdir(xilinx_base)) == 0:
            raise ConfigurationError(
                    "Vivado directory is empty!")

        if len(version_number) > 0:
            if version_number in os.listdir(xilinx_base):
                xilinx_base = os.path.join(xilinx_base, version_number)
                return xilinx_base

        float_max = float(os.listdir(xilinx_base)[0])
        for f in os.listdir(xilinx_base):
            if float(f) > float_max:
                float_max = float(f)

        xilinx_base = os.path.join(xilinx_base, str(float_max))
        return xilinx_base


