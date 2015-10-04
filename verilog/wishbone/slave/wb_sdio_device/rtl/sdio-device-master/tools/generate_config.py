#! /usr/bin/python

import sys
import os
import argparse
import json
from array import array as Array
from string import Template

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir)))
BASE_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir))
#BASE_PATH = os.path.join(os.path.dirname(__file__), os.pardir)

CIS_BASE_ADDR = 0x01000

DEFAULT_CONFIG_FILE = "sdio_configuration.json"
DEFAULT_CONFIG_PATH = os.path.join(BASE_PATH, DEFAULT_CONFIG_FILE)

DEFAULT_CIA_TEMPLATE_FILE = "sdio_cia_defines_template.v"
DEFAULT_CIA_TEMPLATE_PATH = os.path.join(BASE_PATH, "rtl", "cia", DEFAULT_CIA_TEMPLATE_FILE)

DEFAULT_CIA_OUTPUT_FILE = "sdio_cia_defines.v"
DEFAULT_CIA_OUTPUT_PATH = os.path.join(BASE_PATH, "rtl", "cia", DEFAULT_CIA_OUTPUT_FILE)

DEFAULT_CIS_OUTPUT = "sdio_cis_rom.rom"
DEFAULT_CIS_OUTPUT_PATH = os.path.join(BASE_PATH, "rtl", "cia", DEFAULT_CIS_OUTPUT)

DEFAULT_MIN_CURRENT = 10
DEFAULT_AVG_CURRENT = 10
DEFAULT_MAX_CURRENT = 10

DEFAULT_SB_MIN_CURRENT = 10
DEFAULT_SB_AVG_CURRENT = 10
DEFAULT_SB_MAX_CURRENT = 10

DEFAULT_HP_AVG_CURRENT = 50
DEFAULT_HP_MAX_CURRENT = 50

DEFAULT_LP_AVG_CURRENT = 20
DEFAULT_LP_MAX_CURRENT = 20



#XXX: Add support for specifying current in both normal and standby mode


CIS_TYPE = {
    "NULL":{
        "note":"not supported",
        "code":0x00,
        "length":1
    },
    "CHECKSUM":{
        "note":"not supported",
        "code":0x10,
        "length":1
    },
    "VERSION":{
        "note":"not supported",
        "code":0x15,
        "length":1
    },
    "ALTERNATE_LANGUAGE":{
        "note":"not supported",
        "code":0x16,
        "length":1
    },
    "MANUFACTURER_ID":{
        "code":0x20,
        "length":4
    },
    "FUNCTION_ID":{
        "code":0x21,
        "value":[0x0C, 0x00],
        "length":2
    },
    "FUNCTION_EXT":{
        "code":0x22,
        "length":-1
    },
    "SDIO_STD":{
        "code":0x91,
        "length":1
    },
    "END":{
        "code":0xFF,
        "length":1
    }
}



DESCRIPTION = "\n" \
              "\n" \
              "Read in the configuration file in the above directory and generate the appropriate configuration for the project\n"

EPILOG = "\n" \
         "\n" \
         "Examples:\n" \
         "\tSomething\n" \
         "\n"

def boolean_verilog_map(test):
    if test:
        return "1'b1"
    return "1'b0"

def generate_ocr(config):
    value = 0
    if config["support voltage 2p0 2p1"]:
        value |= 0x000100
    if config["support voltage 2p1 2p2"]:
        value |= 0x000200
    if config["support voltage 2p2 2p3"]:
        value |= 0x000400
    if config["support voltage 2p3 2p4"]:
        value |= 0x000800
    if config["support voltage 2p4 2p5"]:
        value |= 0x001000
    if config["support voltage 2p5 2p6"]:
        value |= 0x002000
    if config["support voltage 2p6 2p7"]:
        value |= 0x004000
    if config["support voltage 2p7 2p8"]:
        value |= 0x008000
    if config["support voltage 2p8 2p9"]:
        value |= 0x010000
    if config["support voltage 2p9 3p0"]:
        value |= 0x020000
    if config["support voltage 3p0 3p1"]:
        value |= 0x040000
    if config["support voltage 3p1 3p2"]:
        value |= 0x080000
    if config["support voltage 3p2 3p3"]:
        value |= 0x100000
    if config["support voltage 3p3 3p4"]:
        value |= 0x200000
    if config["support voltage 3p4 3p5"]:
        value |= 0x400000
    if config["support voltage 3p5 3p6"]:
        value |= 0x800000

    return value

def generate_cia(config, cia_in_path, cia_out_path):
    cia_template = None
    cia_dict = {}
    func_en_list = [0, 0, 0, 0, 0, 0, 0]

    #Translate all user friendly inputs to readable versions
    cia_dict["SCSI"]        =   boolean_verilog_map(config["continuous spi interrupt"])
    cia_dict["SDC"]         =   boolean_verilog_map(config["cmd52 while transfer"])
    cia_dict["SMB"]         =   boolean_verilog_map(config["support multiple block transfer"])
    cia_dict["SRW"]         =   boolean_verilog_map(config["support read wait"])
    cia_dict["SBS"]         =   boolean_verilog_map(config["support suspend resume"])
    cia_dict["S4MI"]        =   boolean_verilog_map(config["support 4 bit interrupt mode"])
    cia_dict["LSC"]         =   boolean_verilog_map(not config["support high speed"])
    cia_dict["S4BL"]        =   boolean_verilog_map(config["support 4 bit in low speed"])
                            
    #cia_dict["SMPC"]        =   boolean_verilog_map(config["support master power control"])
    cia_dict["SMPC"]        =   "1'b0" #Not Supported Yet
    #cia_dict["TPC"]         =   boolean_verilog_map(config["total power control"])
    cia_dict["TPC"]         =   "3'b000"
    #cia_dict["EMPC"]        =   1'b0
    cia_dict["EMPC"]        =   "1'b0"
    cia_dict["SHS"]         =   boolean_verilog_map(config["support high speed"])
    cia_dict["SSDR50"]      =   boolean_verilog_map(config["support sdr50"])
    cia_dict["SSDR104"]     =   boolean_verilog_map(config["support sdr104"])
    cia_dict["SDDR50"]      =   boolean_verilog_map(config["support ddr50"])
    cia_dict["SDTA"]        =   boolean_verilog_map(config["support driver type a"])
    cia_dict["SDTC"]        =   boolean_verilog_map(config["support driver type c"])
    cia_dict["SDTD"]        =   boolean_verilog_map(config["support driver type d"])
    cia_dict["SAI"]         =   boolean_verilog_map(config["support async interrupts"])
    cia_dict["S8B"]         =   boolean_verilog_map(config["support sd 8 bit data"])
    cia_dict["OCR"]         =   "24'h%06X" % generate_ocr(config)
    cia_dict["VENDOR_ID"]   =   config["vendor id"]
    cia_dict["PRODUCT_ID"]  =   config["product id"]

    #Create a template of the CIA defines
    with open(cia_in_path, 'r') as f:
        cia_template = Template(f.read())
        f.close()

    for i in range (1, 8):
        if is_valid_func(i, config):
            func_en_list[i - 1] = 1

    cia_buffer              = cia_template.safe_substitute(
        SCSI                =   cia_dict["SCSI"],
        SDC                 =   cia_dict["SDC"],
        SMB                 =   cia_dict["SMB"],
        SRW                 =   cia_dict["SRW"],
        SBS                 =   cia_dict["SBS"],
        S4MI                =   cia_dict["S4MI"],
        LSC                 =   cia_dict["LSC"],
        S4BL                =   cia_dict["S4BL"],
        SMPC                =   cia_dict["SMPC"],
        TPC                 =   cia_dict["TPC"],
        EMPC                =   cia_dict["EMPC"],
        SHS                 =   cia_dict["SHS"],
        SSDR50              =   cia_dict["SSDR50"],
        SSDR104             =   cia_dict["SSDR104"],
        SDDR50              =   cia_dict["SDDR50"],
        SDTA                =   cia_dict["SDTA"],
        SDTC                =   cia_dict["SDTC"],
        SDTD                =   cia_dict["SDTD"],
        SAI                 =   cia_dict["SAI"],
        S8B                 =   cia_dict["S8B"],
        OCR                 =   cia_dict["OCR"],
        NUM_FUNCS           =   num_functions(config),
        FUNC1_EN            =   func_en_list[0],
        FUNC2_EN            =   func_en_list[1],
        FUNC3_EN            =   func_en_list[2],
        FUNC4_EN            =   func_en_list[3],
        FUNC5_EN            =   func_en_list[4],
        FUNC6_EN            =   func_en_list[5],
        FUNC7_EN            =   func_en_list[6],
        FUNC1_TYPE          =   "4'h%X" % func_type(1, config),
        FUNC2_TYPE          =   "4'h%X" % func_type(2, config),
        FUNC3_TYPE          =   "4'h%X" % func_type(3, config),
        FUNC4_TYPE          =   "4'h%X" % func_type(4, config),
        FUNC5_TYPE          =   "4'h%X" % func_type(5, config),
        FUNC6_TYPE          =   "4'h%X" % func_type(6, config),
        FUNC7_TYPE          =   "4'h%X" % func_type(7, config),
        FUNC1_BLOCK_SIZE    =   "16'h%04X" % func_block_size(1, config),
        FUNC2_BLOCK_SIZE    =   "16'h%04X" % func_block_size(2, config),
        FUNC3_BLOCK_SIZE    =   "16'h%04X" % func_block_size(3, config),
        FUNC4_BLOCK_SIZE    =   "16'h%04X" % func_block_size(4, config),
        FUNC5_BLOCK_SIZE    =   "16'h%04X" % func_block_size(5, config),
        FUNC6_BLOCK_SIZE    =   "16'h%04X" % func_block_size(6, config),
        FUNC7_BLOCK_SIZE    =   "16'h%04X" % func_block_size(7, config),
        VENDOR_ID           =   cia_dict["VENDOR_ID"],
        PRODUCT_ID          =   cia_dict["PRODUCT_ID"]
    )
    #print "cia buffer: %s" % cia_buffer
    with open(cia_out_path, "w") as f:
        f.write(cia_buffer)


def num_functions(config):
    count = 0
    for i in range(1, 8):
        if is_valid_func(i, config):
            count += 1
    return count

def func_type(i, config):
    if not is_valid_func(i, config):
        return 0

    return config["functions"][i - 1]["type"]

def func_block_size(i, config):
    if not is_valid_func(i, config):
        return 0
    return config["functions"][i - 1]["max byte transfer size"]

def is_valid_func(index, config):
    for i in range(len(config["functions"])):
        if config["functions"][i]["index"] != index:
            continue
        if "filename" not in config["functions"][i]:
            return False
        if len(config["functions"][i]["filename"]) == 0:
            return False
        if "type" not in config["functions"][i]:
            return False
        return True

    return False


def generate_speed_byte(config):
    clock_rate_khz = config["max sdio clock khz"]
    cr = clock_rate_khz
    mult = 0x00
    mod = 0x00
    if clock_rate_khz   < 1000:
        mult = 0x00
        cr = (clock_rate_khz * 1.0) % 100.0
    elif clock_rate_khz < 10000:
        cr = (clock_rate_khz * 1.0) % 1000.0
        mult = 0x01
    elif clock_rate_khz < 100000:
        cr = (clock_rate_khz * 1.0) % 10000.0
        mult = 0x02
    else:
        cr = (clock_rate_khz * 1.0) % 100000.0
        mult = 0x03

    if   cr >= 8.0:
        mod = 0xF
    elif cr >= 7.0:
        mod = 0xE
    elif cr >= 6.0:
        mod = 0xD
    elif cr >= 5.5:
        mod = 0xC
    elif cr >= 5.0:
        mod = 0xB
    elif cr >= 4.5:
        mod = 0xA
    elif cr >= 4.0:
        mod = 0x9
    elif cr >= 3.5:
        mod = 0x8
    elif cr >= 3.0:
        mod = 0x7
    elif cr >= 2.5:
        mod = 0x6
    elif cr >= 2.0:
        mod = 0x5
    elif cr >= 1.5:
        mod = 0x4
    elif cr >= 1.3:
        mod = 0x3
    elif cr >= 1.2:
        mod = 0x2
    elif cr >= 1.0:
        mod = 0x1

    value = (mod << 3) | mult
    return value


def generate_cis(config, cis_output_path, cia_output_path):
    #Return a list of addresses of where the offsets for the FBR will be
    main_cis = Array('B')
    address_list = []
    cia_template = None
    with open(cia_output_path, 'r') as f:
        cia_template = Template(f.read())
        f.close()

    #Main CIS
    main_cis.append(CIS_TYPE["MANUFACTURER_ID"]["code"])
    main_cis.append(CIS_TYPE["MANUFACTURER_ID"]["length"])
    vendor  = int(str(config["vendor id"]), 0)
    product = int(str(config["product id"]), 0)
    main_cis.append((vendor >> 8) & 0xFF)
    main_cis.append((vendor     ) & 0xFF)

    main_cis.append((product >> 8) & 0xFF)
    main_cis.append((product     ) & 0xFF)

    #Main CIS Function ID
    main_cis.append(CIS_TYPE["FUNCTION_ID"]["code"])
    main_cis.append(CIS_TYPE["FUNCTION_ID"]["length"])
    main_cis.append(0x0C)
    main_cis.append(0x00)

    #Main CIS Function Extension
    main_cis.append(CIS_TYPE["FUNCTION_EXT"]["code"])
    main_cis.append(0x06)
    main_cis.append(0x00)   #Extension Type (0x00)
    main_cis.append((config["max byte transfer size"] >> 8) & 0xFF)   #Maximum num of bytes to be transfered in block
    main_cis.append((config["max byte transfer size"]     ) & 0xFF)   #Maximum num of bytes to be transfered in block
   #Max Transfer Speed
    main_cis.append(generate_speed_byte(config))
    #Temperature constraints
    main_cis.append(0x00)
    main_cis.append(0x00)


    #Last Entry
    main_cis.append(CIS_TYPE["END"]["code"])


    #FBRs
    for i in range(1, 8):
        address_list.append(len(main_cis) - 1)

        if not is_valid_func(i, config):
            main_cis.append(CIS_TYPE["END"]["code"])
            continue

        f = config["functions"][i - 1]
        print "f: %s" % str(f)
        #Add Function ID
        main_cis.append(CIS_TYPE["FUNCTION_ID"]["code"])
        main_cis.append(CIS_TYPE["FUNCTION_ID"]["length"])
        main_cis.append(0x0C)
        main_cis.append(0x00)

        #Add Function ID Extension
        main_cis.append(CIS_TYPE["FUNCTION_ID"]["code"])
        main_cis.append(CIS_TYPE["FUNCTION_ID"]["length"])
        main_cis.append(f["type"])
        main_cis.append(0x00)
        if f["support wakeup"]:
            main_cis.append(0x01)
        else:
            main_cis.append(0x00)
        major = f["version"].partition(".")[0]
        minor = f["version"].partition(".")[2]
        major = int(major)
        minor = int(minor)
        main_cis.append((major << 4) | minor)
        main_cis.append((f["serial number"] >> 24) & 0xFF)
        main_cis.append((f["serial number"] >> 16) & 0xFF)
        main_cis.append((f["serial number"] >>  8) & 0xFF)
        main_cis.append((f["serial number"]      ) & 0xFF)

        #Size
        main_cis.append((f["size"] >> 24) & 0xFF)
        main_cis.append((f["size"] >> 16) & 0xFF)
        main_cis.append((f["size"] >>  8) & 0xFF)
        main_cis.append((f["size"]      ) & 0xFF)

        #Flags
        flags = 0x00
        if f["read only"]:
            flags |= 0x1
        if f["do not format"]:
            flags |= 0x2
        main_cis.append(flags)

        #Max Block Transfer Size
        main_cis.append((f["max byte transfer size"] >> 8) & 0xFF)   #Maximum num of bytes to be transfered in block
        main_cis.append((f["max byte transfer size"]     ) & 0xFF)   #Maximum num of bytes to be transfered in block

        #Main CIS Function Extension
        main_cis.append(CIS_TYPE["FUNCTION_EXT"]["code"])
        main_cis.append(0x2A)
        main_cis.append(0x01)   #Extension Type (0x01)
        main_cis.append((config["max byte transfer size"] >> 8) & 0xFF)   #Maximum num of bytes to be transfered in block
        main_cis.append((config["max byte transfer size"]     ) & 0xFF)   #Maximum num of bytes to be transfered in block
        #Max Transfer Speed
        main_cis.append(generate_speed_byte(config))
        #OCR
        ocr = generate_ocr(config)

        main_cis.append((ocr >> 8) & 0xFF)
        main_cis.append((ocr     ) & 0xFF)
        #Temperature constraints
        main_cis.append(DEFAULT_MIN_CURRENT)
        main_cis.append(DEFAULT_AVG_CURRENT)
        main_cis.append(DEFAULT_MAX_CURRENT)

        main_cis.append(DEFAULT_SB_MIN_CURRENT)
        main_cis.append(DEFAULT_SB_AVG_CURRENT)
        main_cis.append(DEFAULT_SB_MAX_CURRENT)

        #Min Bandwidth
        main_cis.append((f["min bandwidth"] >> 8) & 0xFF)
        main_cis.append((f["min bandwidth"]     ) & 0xFF)
        #Optimal Bandwidth
        main_cis.append((f["optimal bandwidth"] >> 8) & 0xFF)
        main_cis.append((f["optimal bandwidth"]     ) & 0xFF)
        #Timeout in 10mS
        main_cis.append((f["timeout"] >> 8) & 0xFF)
        main_cis.append((f["timeout"]     ) & 0xFF)

        #AVG Power @ 3.3V
        main_cis.append(DEFAULT_AVG_CURRENT)
        #MAX Power @ 3.3V
        main_cis.append(DEFAULT_MAX_CURRENT)

        #HP AVG Power @ 3.3V
        main_cis.append((DEFAULT_HP_AVG_CURRENT >> 8) & 0xFF)
        main_cis.append((DEFAULT_HP_AVG_CURRENT     ) & 0xFF)
        #HP MAX Power @ 3.3V
        main_cis.append((DEFAULT_HP_MAX_CURRENT >> 8) & 0xFF)
        main_cis.append((DEFAULT_HP_MAX_CURRENT     ) & 0xFF)

        #LP AVG Power @ 3.3V
        main_cis.append((DEFAULT_LP_AVG_CURRENT >> 8) & 0xFF)
        main_cis.append((DEFAULT_LP_AVG_CURRENT     ) & 0xFF)
        #LP MAX Power @ 3.3V
        main_cis.append((DEFAULT_LP_MAX_CURRENT >> 8) & 0xFF)
        main_cis.append((DEFAULT_LP_MAX_CURRENT     ) & 0xFF)

        #Add SDIO Standard Extension
        if f["type"] > 0:
            print "Standard SDIO CIS is Not Supported at this time!"
        #Add End
        main_cis.append(CIS_TYPE["END"]["code"])
        address_list.append(len(main_cis) - 1)

    print "test :%s" % str(main_cis)
    #Tuple returnning the offsets for each of the address for main CIS, and function CIS as well as the length of the
    # Total CIS
    with open(cis_output_path, 'w') as f:
        main_cis.tofile(f)
    print "Substituting..."
    cia_output_buf = cia_template.safe_substitute(
        FUNC1_CIS_OFFSET =   address_list[0],
        FUNC2_CIS_OFFSET =   address_list[1],
        FUNC3_CIS_OFFSET =   address_list[2],
        FUNC4_CIS_OFFSET =   address_list[3],
        FUNC5_CIS_OFFSET =   address_list[4],
        FUNC6_CIS_OFFSET =   address_list[5],
        FUNC7_CIS_OFFSET =   address_list[6],
        CIS_FILE_LENGTH  =   len(main_cis)
    )
    with open(cia_output_path, 'w') as f:
        f.write(cia_output_buf)

    return address_list

def main(argv):
    parser = argparse.ArgumentParser(
        formatter_class=argparse.RawDescriptionHelpFormatter,
        description=DESCRIPTION,
        epilog=EPILOG
    )

    parser.add_argument("-d", "--debug",
                        action="store_true",
                        help="Enable Debug Messages")

    parser.add_argument("-c", "--config",
                        type=str,
                        nargs = 1,
                        default=DEFAULT_CONFIG_PATH,
                        help = "Specify an alternate configuration file, Default: %s" % DEFAULT_CONFIG_PATH)
    parser.add_argument("--cia",
                        nargs = 1,
                        default=DEFAULT_CIA_TEMPLATE_PATH,
                        help = "Specify an alternate cia template file, Default: %s" % DEFAULT_CIA_TEMPLATE_PATH)
    parser.add_argument("--ciao",
                        nargs = 1,
                        default=DEFAULT_CIA_OUTPUT_PATH,
                        help = "Specify an alternate cia output file, Default: %s" % DEFAULT_CIA_OUTPUT_PATH)
    parser.add_argument("--cis",
                        nargs = 1,
                        default=DEFAULT_CIS_OUTPUT_PATH,
                        help = "Specific an alternate cis output file, Default: %s" % DEFAULT_CIS_OUTPUT_PATH)

    args = parser.parse_args()

    config = None
    print "config path: %s" % args.config
    with open(args.config, 'r') as f:
        config = json.load(f)

    config["vendor id"] = int(config["vendor id"], 0)
    config["product id"] = int(config["product id"], 0)

    if args.debug:
        print "Configuration :%s" % str(config)

    print "Generate Card Configuration Information"
    for f in config["functions"]:
        #print "Function Index: %d" % f["index"]
        if "filename" not in f:
            #print "\tNo Function Defined"
            continue
        #print "\tUsing Function: %s" % f["filename"]
    cis_length = None
    address_list = None
    generate_cia(config, args.cia, args.ciao)
    generate_cis(config, args.cis, args.ciao)

if __name__ == "__main__":
    main(sys.argv)


