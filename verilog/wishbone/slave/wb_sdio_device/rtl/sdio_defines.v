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
`define SD_CMD_SEND_IF_COND           (6'd8 ) /* Optional */
//`define SD_CMD_SEND_CSD               (6'd9 )
//`define SD_CMD_SEND_CID               (6'd10)
`define SD_CMD_VOLTAGE_SWITCH         (6'd11)
//`define SD_CMD_STOP_TRANSMISSION      (6'd12)
//`define SD_CMD_SEND_STATUS            (6'd13)
`define SD_CMD_GO_INACTIVE_STATE      (6'd15)
//`define SD_CMD_SET_BLOCKLEN           (6'd16)
//`define SD_CMD_READ_SINGLE_BLOCK      (6'd17)
//`define SD_CMD_READ_MULTIPLE_BLOCK    (6'd18)
`define SD_CMD_SEND_TUNNING_BLOCK     (6'd19) /* Optional */
//`define SD_CMD_SET_BLOCK_COUNT        (6'd23) /* Optional, Needed for SD104 */
//`define SD_CMD_WRITE_BLOCK            (6'd24)
//`define SD_CMD_WRITE_MULTIPLE_BLOCK   (6'd25)
//`define SD_CMD_PROGRAM_CSD            (6'd27)
//`define SD_CMD_SET_WRITE_PROT         (6'd28) /* Optional */
//`define SD_CMD_CLR_WRITE_PRO          (6'd29) /* Optional */
//`define SD_CMD_SEND_WRITE_PROT        (6'd30) /* Optional */
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


//Card Status
`define SD_STS_OUT_OF_RANGE           31
`define SD_STS_COM_CRC_ERROR          23
`define SD_STS_ILLEGAL_COMMAND        22
`define SD_STS_ERROR                  19
`define SD_CURRENT_STATE_TOP          12
`define SD_CURRENT_STATE_BOT          9
//Not SD_CURRENT_STATE shall always return 0x0F

//IO_SEND_OP_COND Response (R4 32 bits)
`define CMD5_RSP_READY              (32 - 8)  /* Card is ready to operate */
`define CMD5_RSP_NUM_FUNCS_START    (32 - 9)  /* Number of functions */
`define CMD5_RSP_NUM_FUNCS_END      (32 - 11)
`define CMD5_RSP_MEM_PRESENT        (32 - 12) /* Memory is Also Availalbe */
`define CMD5_RSP_UHSII_AVAIABLE     (32 - 13) /* Ultra HS Mode II Available */
`define CMD5_RSP_S18A               (32 - 15) /* Accept switch to 1.8V */
`define CMD5_RSP_IO_OCR_TOP         (32 - 16) /* Operating Condition Range */
`define CMD5_RSP_IO_OCR_BOT         (32 - 32)

`endif
