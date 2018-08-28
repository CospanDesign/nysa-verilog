`ifndef SDIO_DEVICE_CIA_DEFINES
`define SDIO_DEVICE_CIA_DEFINES

`include "sdio_defines.v"

//Addresses
`define CCCR_SDIO_REV_ADDR    18'h000
`define SD_SPEC_ADDR          18'h001
`define IO_FUNC_ENABLE_ADDR   18'h002
`define IO_FUNC_READY_ADDR    18'h003
`define INT_ENABLE_ADDR       18'h004
`define INT_PENDING_ADDR      18'h005
`define IO_ABORT_ADDR         18'h006
`define BUS_IF_CONTROL_ADDR   18'h007
`define CARD_COMPAT_ADDR      18'h008
`define CARD_CIS_LOW_ADDR     18'h009
`define CARD_CIS_MID_ADDR     18'h00A
`define CARD_CIS_HIGH_ADDR    18'h00B
`define BUS_SUSPEND_ADDR      18'h00C
`define FUNC_SELECT_ADDR      18'h00D
`define EXEC_SELECT_ADDR      18'h00E
`define READY_SELECT_ADDR     18'h00F
`define FN0_BLOCK_SIZE_0_ADDR 18'h010
`define FN0_BLOCK_SIZE_1_ADDR 18'h011
`define POWER_CONTROL_ADDR    18'h012
`define BUS_SPD_SELECT_ADDR   18'h013
`define UHS_I_SUPPORT_ADDR    18'h014
`define DRIVE_STRENGTH_ADDR   18'h015
`define INTERRUPT_EXT_ADDR    18'h016

//Values
`define CCCR_FORMAT           4'h3    /* CCCR/FBR Version 3.0 (is this right?)  */
`define SDIO_VERSION          4'h4    /* SDIO Version 3.0     (is this right?)  */
`define SD_PHY_VERSION        4'h3    /* SD PHY Version 3.01  (is this right?)  */
`define ECSI                  1'b0    /* Enable Continuous SPI Interrupt */
`define SCSI                  ${SCSI}    /* Support Continuous SPI Interrupt */
`define SDC                   ${SDC}    /* Support Command 52 While Data Transfer In progress */
`define SMB                   ${SMB}    /* Support Multiple Block Transfer CMD 53 */
`define SRW                   ${SRW}    /* Support Read Wait */
`define SBS                   ${SBS}    /* Support Suspend/Resume */
`define S4MI                  ${S4MI}    /* Support Interrupts ine 4-bit data transfer mode */
`define LSC                   ${LSC}    /* Card is a low speed card only */
`define S4BLS                 ${S4BL}    /* Support 4-bit mode in low speed mode */
`define SMPC                  ${SMPC}    /* Master Power Control Support (don't let the process control power)*/
`define TPC                   ${TPC} /* No Total Power Control */
`define EMPC                  ${EMPC}   /* Enable Main Power Control */
`define SHS                   ${SHS}    /* Support High Speed */
`define SSDR50                ${SSDR50}    /* Support SDR50 */
`define SSDR104               ${SSDR104}    /* Support SDR104 */
`define SDDR50                ${SDDR50}    /* Support DDR50 */
`define SDTA                  ${SDTA}    /* Support Driver Type A */
`define SDTC                  ${SDTC}    /* Support Driver Type C */
`define SDTD                  ${SDTD}    /* Support Driver Type D */
`define SAI                   ${SAI}    /* Support Asynchronous Interrupts */
`define S8B                   ${S8B}    /* Enable 8-bit Bus Mode */
`define OCR_VALUE             ${OCR}    /* Operating Voltage Range */

`define D1_BIT_MODE           2'b00
`define D4_BIT_MODE           2'b10
`define D8_BIT_MODE           2'b11

`define DRIVER_TYPE_B         2'b00
`define DRIVER_TYPE_A         2'b01
`define DRIVER_TYPE_C         2'b10
`define DRIVER_TYPE_D         2'b11

`define SDR12                 3'b000  /* Single Data Rate 12 MHz */
`define SDR25                 3'b001  /* Single Data Rate 25 MHz */
`define SDR50                 3'b010  /* Single Data Rate 50 MHz */
`define SDR104                3'b011  /* Single Data Rate 104 MHz */
`define DDR50                 3'b100  /* Double Data Rate 50MHz */

//Address of Functions
`define CCCR_FUNC_START_ADDR        (18'h00000)
`define CCCR_FUNC_END_ADDR          (18'h000FF)
`define CCCR_INDEX                  0
                                    
`define FUNC1_START_ADDR            (18'h00100)
`define FUNC1_END_ADDR              (18'h001FF)
`define FUNC1_INDEX                 1
                                    
`define FUNC2_START_ADDR            (18'h00200)
`define FUNC2_END_ADDR              (18'h002FF)
`define FUNC2_INDEX                 2
                                    
`define FUNC3_START_ADDR            (18'h00300)
`define FUNC3_END_ADDR              (18'h003FF)
`define FUNC3_INDEX                 3
                                    
`define FUNC4_START_ADDR            (18'h00400)
`define FUNC4_END_ADDR              (18'h004FF)
`define FUNC4_INDEX                 4
                                    
`define FUNC5_START_ADDR            (18'h00500)
`define FUNC5_END_ADDR              (18'h005FF)
`define FUNC5_INDEX                 5
                                    
`define FUNC6_START_ADDR            (18'h00600)
`define FUNC6_END_ADDR              (18'h006FF)
`define FUNC6_INDEX                 6
                                    
`define FUNC7_START_ADDR            (18'h00700)
`define FUNC7_END_ADDR              (18'h007FF)
`define FUNC7_INDEX                 7
 
`define MAIN_CIS_START_ADDR         (18'h01000)
`define MAIN_CIS_END_ADDR           (18'h17FFF)
`define CIS_INDEX                   8

`define NO_SELECT_INDEX             9


`define FUNC1_CIS_OFFSET            ${FUNC1_CIS_OFFSET}
`define FUNC2_CIS_OFFSET            ${FUNC2_CIS_OFFSET}
`define FUNC3_CIS_OFFSET            ${FUNC3_CIS_OFFSET}
`define FUNC4_CIS_OFFSET            ${FUNC4_CIS_OFFSET}
`define FUNC5_CIS_OFFSET            ${FUNC5_CIS_OFFSET}
`define FUNC6_CIS_OFFSET            ${FUNC6_CIS_OFFSET}
`define FUNC7_CIS_OFFSET            ${FUNC7_CIS_OFFSET}

`define CIS_FILENAME                "${CIS_FILE_NAME}"
`define CIS_FILE_LENGTH             ${CIS_FILE_LENGTH}

`define NUM_FUNCS                   ${NUM_FUNCS}

`define FUNC1_EN                    ${FUNC1_EN}
`define FUNC2_EN                    ${FUNC2_EN}
`define FUNC3_EN                    ${FUNC3_EN}
`define FUNC4_EN                    ${FUNC4_EN}
`define FUNC5_EN                    ${FUNC5_EN}
`define FUNC6_EN                    ${FUNC6_EN}
`define FUNC7_EN                    ${FUNC7_EN}

`define FUNC1_TYPE                  ${FUNC1_TYPE}
`define FUNC2_TYPE                  ${FUNC2_TYPE}
`define FUNC3_TYPE                  ${FUNC3_TYPE}
`define FUNC4_TYPE                  ${FUNC4_TYPE}
`define FUNC5_TYPE                  ${FUNC5_TYPE}
`define FUNC6_TYPE                  ${FUNC6_TYPE}
`define FUNC7_TYPE                  ${FUNC7_TYPE}

`define FUNC1_BLOCK_SIZE            ${FUNC1_BLOCK_SIZE}
`define FUNC2_BLOCK_SIZE            ${FUNC2_BLOCK_SIZE}
`define FUNC3_BLOCK_SIZE            ${FUNC3_BLOCK_SIZE}
`define FUNC4_BLOCK_SIZE            ${FUNC4_BLOCK_SIZE}
`define FUNC5_BLOCK_SIZE            ${FUNC5_BLOCK_SIZE}
`define FUNC6_BLOCK_SIZE            ${FUNC6_BLOCK_SIZE}
`define FUNC7_BLOCK_SIZE            ${FUNC7_BLOCK_SIZE}

`define VENDOR_ID                   ${VENDOR_ID}
`define PRODUCT_ID                  ${PRODUCT_ID}

//TODO Memory
`define MEM_PRESENT                 0
//TODO UHS II Support
`define UHSII_AVAILABLE             0

`endif /* SDIO_DEVICE_CIA_DEFINES */
