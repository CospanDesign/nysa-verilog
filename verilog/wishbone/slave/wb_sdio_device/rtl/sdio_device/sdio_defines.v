`ifndef SDIO_DEFINES
`define SDIO_DEFINES

`define SDIO_STATE_RESET        0
`define SDIO_STATE_ACTIVE       1

`define SDIO_C_BIT_TXRX_DIR     1
`define SDIO_C_BIT_CMD_START    2
`define SDIO_C_BIT_CMD_END      7
`define SDIO_C_BIT_ARG_START    8
`define SDIO_C_BIT_ARG_END      39
`define SDIO_C_BIT_CRC_START    40
`define SDIO_C_BIT_CRC_END      46
`define SDIO_C_BIT_FINISH       47

`define SDIO_R_BIT_START_BIT    0
`define SDIO_R_BIT_TXRX_DIR     1


`define SD_CMD_GO_IDLE_STATE          (6'd0 )
//`define SD_CMD_SEND_CID               (6'd2 )
`define SD_CMD_SEND_RELATIVE_ADDR     (6'd3 )
//`define SD_CMD_SET_DSR                (6'd4 )
`define SD_CMD_IO_SEND_OP_CMD         (6'd5 )
//`define SD_CMD_SWITCH_FUNC            (6'd6 )
`define SD_CMD_SEL_DESEL_CARD         (6'd7 )
`define SD_CMD_SEND_IF_COND           (6'd8 )
//`define SD_CMD_SEND_CSD               (6'd9 )
//`define SD_CMD_SEND_CID               (6'd10)
`define SD_CMD_VOLTAGE_SWITCH         (6'd11)
//`define SD_CMD_STOP_TRANSMISSION      (6'd12)
//`define SD_CMD_SEND_STATUS            (6'd13)
`define SD_CMD_GO_INACTIVE_STATE      (6'd15)
//`define SD_CMD_SET_BLOCKLEN           (6'd16)
//`define SD_CMD_READ_SINGLE_BLOCK      (6'd17)
//`define SD_CMD_READ_MULTIPLE_BLOCK    (6'd18)
`define SD_CMD_SEND_TUNNING_BLOCK     (6'd19)
//`define SD_CMD_SET_BLOCK_COUNT        (6'd23)
//`define SD_CMD_WRITE_BLOCK            (6'd24)
//`define SD_CMD_WRITE_MULTIPLE_BLOCK   (6'd25)
//`define SD_CMD_PROGRAM_CSD            (6'd27)
//`define SD_CMD_SET_WRITE_PROT         (6'd28)
//`define SD_CMD_CLR_WRITE_PRO          (6'd29)
//`define SD_CMD_SEND_WRITE_PROT        (6'd30)
//`define SD_CMD_ERASE_WR_BLK_START     (6'd32)
//`define SD_CMD_ERASE_WR_BLK_END       (6'd33)
//`define SD_CMD_ERASE                  (6'd38)
//`define SD_CMD_LOCK_UNLOCK            (6'd42)
`define SD_CMD_IO_RW_DIRECT           (6'd52)
`define SD_CMD_IO_RW_EXTENDED         (6'd53)
//`define SD_CMD_APP_CMD                (6'd55)
//`define SD_CMD_GEN_CMD                (6'd56)
//`define SD_ACMD_SET_BUS_WIDTH         (6'd6)
//`define SD_ACMD_SD_STATUS             (6'd13)
//`define SD_ACMD_SEND_NUM_WR_BLOCK     (6'd22)
//`define SD_ACMD_SET_WR_BLK_ERASE_CNT  (6'd23)
//`define SD_ACMD_SD_APP_OP_COND        (6'd41)
//`define SD_ACMD_SET_CLR_CARD_DETECT   (6'd42)
//`define SD_ACMD_SEND_SCR              (6'd51)

//Functions

//Relative Card Address
`define RELATIVE_CARD_ADDRESS       (16'h0001)

//Not SD_CURRENT_STATE shall always return 0x0F

//Card Status
`define CMD_RSP_CMD                 45:40
`define CMD_RSP_CRD_STS_START       (39)
`define CMD_RSP_CRD_STS_END         (8)

//IO_SEND_OP_COND Response (R4 32 bits)
`define CMD5_ARG_S18R               (24)
`define CMD5_ARG_OCR                23:0

`define VHS_DEFAULT_VALUE           (4'b0001)

`define CMD7_RCA                    31:16

`define CMD8_ARG_VHS_START          15
`define CMD8_ARG_VHS_END            8
`define CMD8_ARG_VHS                15:8
`define CMD8_ARG_PATTERN            7:0

`define CMD52_ARG_RW_FLAG           31    /* 0 = Read 1 = Write */
`define CMD52_ARG_FNUM              30:27
`define CMD52_ARG_RAW_FLAG          26    /* Read the value of the register after a write RW_FLAG = 1*/
`define CMD52_ARG_REG_ADDR          25:9
`define CMD52_ARG_WR_DATA           7:0

`define CMD52_RST_ADDR              6
`define CMD52_RST_BIT               3

//Extended
`define CMD53_ARG_RW_FLAG           31
`define CMD53_ARG_FNUM              30:28
`define CMD53_ARG_BLOCK_MODE        27
`define CMD53_ARG_INC_ADDR          26
`define CMD53_ARG_REG_ADDR          25:9
`define CMD53_ARG_DATA_COUNT        8:0


//COMMAND SEL DESEL CARD
//Response R1
`define R1_OUT_OF_RANGE             (39)
`define R1_COM_CRC_ERROR            (38)
`define R1_ILLEGAL_COMMAND          (37)
`define R1_ERROR                    (19)
`define R1_CURRENT_STATE            12:9

//Respone R4
`define R4_RSRVD                    45:40
`define R4_READY                    (39)      /* Card is ready to operate */
`define R4_NUM_FUNCS                38:36     /* Number of functions */
`define R4_MEM_PRESENT              (35)      /* Memory is Also Availalbe */
`define R4_UHSII_AVAILABLE          (34)      /* Ultra HS Mode II Available */
`define R4_S18A                     (32)      /* Accept switch to 1.8V */
`define R4_IO_OCR                   31:8      /* Operating Condition Range */

//Response R5
`define R5_FLAGS_RANGE              31:16
`define R5_DATA                     15:8
`define R5_FLAG_CRC_ERROR           (15)
`define R5_INVALID_CMD              (14)
`define R5_FLAG_CURR_STATE          13:12
`define R5_FLAG_ERROR               (11)
`define R5_INVALID_FNUM             (9)
`define R5_OUT_OF_RANGE             (8)

//Response R6
`define R6_REL_ADDR                 39:24
`define R6_STS_CRC_COMM_ERR         (23)
`define R6_STS_ILLEGAL_CMD          (22)
`define R6_STS_ERROR                (21)

//Response 7
`define R7_VHS                      19:16
`define R7_PATTERN                  15:8


//FBR
`define FBR_FUNC_ID_ADDR            0
`define FBR_FUNC_EXT_ID_ADDR        1
`define FBR_POWER_SUPPLY_ADDR       2 
`define FBR_ISDIO_FUNC_ID_ADDR      3
`define FBR_MANF_ID_LOW_ADDR        4
`define FBR_MANF_ID_HIGH_ADDR       5
`define FBR_PROD_ID_LOW_ADDR        6
`define FBR_PROD_ID_HIGH_ADDR       7
`define FBR_ISDIO_PROD_TYPE         8
`define FBR_CIS_LOW_ADDR            9
`define FBR_CIS_MID_ADDR            10
`define FBR_CIS_HIGH_ADDR           11
`define FBR_CSA_LOW_ADDR            12
`define FBR_CSA_MID_ADDR            13
`define FBR_CSA_HIGH_ADDR           14
`define FBR_DATA_ACC_ADDR           15
`define FBR_BLOCK_SIZE_LOW_ADDR     16
`define FBR_BLOCK_SIZE_HIGH_ADDR    17



`endif
