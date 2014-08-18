#! /usr/bin/python
import os
import json
import site

PATH = os.path.abspath(os.path.dirname(__file__))
NYSA_NAME = "nysa"
PATH_DICT_NAME = "paths.json"
PATH_ENTRY_NAME = "nysa-verilog"

SITE_NYSA = os.path.abspath(os.path.join(site.getuserbase(), NYSA_NAME))
SITE_PATH = os.path.join(SITE_NYSA, PATH_DICT_NAME)

if __name__ == "__main__":
    if not os.path.exists(SITE_NYSA):
        os.makedirs(SITE_NYSA)

    if not os.path.exists(SITE_PATH):
        f = open(SITE_PATH, "w")
        f.write("{}")
        f.close()

    print "Openning %s" % SITE_PATH
    f = open(SITE_PATH, "r")
    path_dict = json.load(f)
    f.close()

    pentry = PATH
    if "nysa-verilog" in path_dict and type(path_dict["nysa-verilog"]) is list:
        if pentry not in path_dict["nysa-verilog"]:
            path_dict["nysa-verilog"].insert(0, pentry)
    else:
        path_dict["nysa-verilog"] = [PATH]

    f = open(SITE_PATH, "w")
    f.write(json.dumps(path_dict))
    f.close()
