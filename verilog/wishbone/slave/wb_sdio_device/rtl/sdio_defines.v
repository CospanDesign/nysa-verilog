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
`define SD_CMD_SWITCH_FUNC            (6'd6 )
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

//Relative Card Address
`define RELATIVE_CARD_ADDRESS       (16'h0001)

//Card Status
`define CMD_RSP_CMD                (45:40)
`define CMD_RSP_CRD_STS_START       (39)
`define CMD_RSP_CRD_STS_END         (8)

`define CARD_STS_OUT_OF_RANGE       (39)
`define CARD_STS_COM_CRC_ERROR      (38)
`define CARD_STS_ILLEGAL_COMMAND    (37)
`define CARD_STS_ERROR              (48 - 19)
`define CARD_CURRENT_STATE_START    (48 - 12)
`define CARD_CURRENT_STATE_END      (48 -  9)

//Not SD_CURRENT_STATE shall always return 0x0F

//COMMAND SEL DESEL CARD
`define CMD3_RSP_REL_ADDR_START     ()
`define CMD3_RSP_REL_ADDR_END       ()

//IO_SEND_OP_COND Response (R4 32 bits)
`define CMD5_ARG_S18R               (24)
`define CMD5_ARG_OCR_START          (23)
`define CMD5_ARG_OCR_END            (0)

`define CMD5_RSP_READY              (39)      /* Card is ready to operate */
`define CMD5_RSP_NUM_FUNCS          (38:35)   /* Number of functions */
`define CMD5_RSP_MEM_PRESENT        (34)      /* Memory is Also Availalbe */
`define CMD5_RSP_UHSII_AVAILABLE    (33)      /* Ultra HS Mode II Available */
`define CMD5_RSP_S18A               (32)      /* Accept switch to 1.8V */
`define CMD5_RSP_IO_OCR             (31:8)    /* Operating Condition Range */

`define VHS_DEFAULT_VALUE           (4'b0001)

`define CMD8_ARG_VHS_START          (15)
`define CMD8_ARG_VHS_END            (8)
`define CMD8_ARG_PATTERN            (7:0)

`define CMD8_RSP_VA                 (19:16)
`define CMD8_RSP_PATTERN            (15:8)


`define CMD52_ARG_RW_FLAG           (31)    /* 0 = Read 1 = Write */
`define CMD52_ARG_FNUM              (30:27)
`define CMD52_ARG_RAW_FLAG          (26)    /* Read the value of the register after a write RW_FLAG = 1*/
`define CMD52_ARG_REG_ADDR_START    (24:8)
`define CMD52_ARG_WR_DATA           (7:0)

`define CMD52_RST_ADDR              (6)
`define CMD52_RST_BIT               (3)

`define CMD52_RSP_FLAGS_RANGE       (31:16)
`define CMD52_RSP_DATA              (15:8)
`define CMD52_RSP_FLAG_CRC_ERROR    (15)
`define CMD52_RSP_INVALID_CMD       (14)
`define CMD52_RSP_FLAG_CURR_STATE   (13:12)
`define CMD52_RSP_FLAG_ERROR        (11)
`define CMD52_RSP_INVALID_FNUM      (9)
`define CMD52_RSP_OUT_OF_RANGE      (8)

`endif
