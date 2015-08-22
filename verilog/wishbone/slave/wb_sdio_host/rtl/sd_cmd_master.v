`include "sd_defines.v"

`define SMALL_RSP           7'b0101000
`define BIG_RSP             7'b1111111

module sd_cmd_master(
  input                 clk,

  input                 rst,
  input                 new_cmd,
  input                 data_write,
  input                 data_read,



  input      [31:0]     arg_reg,
  input      [13:0]     cmd_set_reg,
  input      [15:0]     timeout_reg,
  output reg [15:0]     status_reg,
  output reg [31:0]     resp_1_reg,

  output reg [4:0]      err_int_reg,
  output reg [15:0]     normal_int_reg,
  input                 err_int_rst,
  input                 normal_int_rst,

  output reg [15:0]     settings,
  output reg            go_idle_o,
  output reg  [39:0]    cmd_out,
  output reg            req_out,
  output reg            ack_out,
  input                 req_in,
  input                 ack_in,
  input [39:0]          cmd_in,
  input [7:0]           serial_status,
  input                 card_detect
);

`define CMDI            cmd_set_reg[13:8]
`define WORD_SELECT     cmd_set_reg[7:6]
`define CICE            cmd_set_reg[4]
`define CRCE            cmd_set_reg[3]
`define RTS             cmd_set_reg[1:0]
`define CTE             err_int_reg[0]
`define CCRCE           err_int_reg[1]
`define CIE             err_int_reg[3]
`define EI              normal_int_reg[15]
`define CC              normal_int_reg[0]
`define CICMD           status_reg[0]

//Local Parameters
localparam SIZE         =  3;
localparam IDLE         =  3'b001;
localparam SETUP        =  3'b010;
localparam EXECUTE      =  3'b100;

//Registers/Wires
reg             crc_check_enable;
reg             index_check_enable;
reg [6:0]       response_size;

reg             card_present;
reg [3:0]       debounce;
reg [15:0]      status;
reg [15:0]      watchdog_cnt;
reg             complete;

reg [SIZE-1:0]  state;
reg [SIZE-1:0]  next_state;

reg             ack_in_int;
reg             ack_q;
reg             req_q;
reg             req_in_int;
wire            dat_ava;
wire            crc_valid;

//Submodules
//Asynchronous Logic
assign  data_ava        =   status[6];
assign  crc_valid       =   status[5];

//Synchronous Logic
always @ (posedge clk or posedge rst   )
begin
  if (rst) begin
    req_q<=0;
    req_in_int<=0;
  end
  else begin
    req_q<=req_in;
    req_in_int<=req_q;
  end
end

always @ (posedge clk or posedge rst   )
begin
  if (rst) begin
    debounce<=0;
    card_present<=0;
  end
  else begin
    if (!card_detect) begin//Card present
      if (debounce!=4'b1111)
        debounce<=debounce+1'b1;
    end
    else
      debounce<=0;

    if (debounce==4'b1111)
      card_present<=1'b1;
    else
      card_present<=1'b0;
  end
end

always @ (posedge clk or posedge rst   )
begin
  if (rst) begin
    ack_q<=0;
    ack_in_int<=0;
  end
  else begin
    ack_q<=ack_in;
    ack_in_int<=ack_q;
  end
end



always @ ( state or new_cmd or complete or ack_in_int) begin : FSM_COMBO
  next_state = 0;
  case(state)
    IDLE:   begin
      if (new_cmd) begin
        next_state = SETUP;
      end
      else begin
        next_state = IDLE;
      end
    end
    SETUP:begin
      if (ack_in_int)
        next_state = EXECUTE;
      else
        next_state = SETUP;
    end
    EXECUTE:    begin
      if (complete) begin
        next_state = IDLE;
      end
      else begin
        next_state = EXECUTE;
      end
    end
    default : next_state  = IDLE;
  endcase
end

always @ (posedge clk or posedge rst) begin : FSM_SEQ
  if (rst ) begin
    state <= #1 IDLE;
  end
  else begin
    state <= #1 next_state;
  end
end

always @ (posedge clk or posedge rst)begin
  if (rst ) begin
    crc_check_enable=0;
    complete =0;
    resp_1_reg = 0;

    err_int_reg =0;
    normal_int_reg=0;
    status_reg=0;
    status=0;
    cmd_out =0 ;
    settings=0;
    response_size=0;
    req_out=0;
    index_check_enable=0;
    ack_out=0;
    watchdog_cnt=0;

    `CCRCE=0;
    `EI = 0;
    `CC = 0;
    go_idle_o=0;
  end
  else begin
    normal_int_reg[1] = card_present;
    normal_int_reg[2] = ~card_present;
    complete=0;
    case(state)
      IDLE: begin
        go_idle_o=0;
        req_out=0;
        ack_out =0;
        `CICMD =0;
        if ( req_in_int == 1) begin     //Status change
          status=serial_status;
          ack_out = 1;
        end
      end
      SETUP:  begin
        normal_int_reg=0;
        err_int_reg =0;

        index_check_enable = `CICE;
        crc_check_enable = `CRCE;

        if ( (`RTS  == 2'b10 ) || ( `RTS == 2'b11)) begin
          response_size =  7'b0101000;
        end
        else if (`RTS == 2'b01) begin
          response_size = 7'b1111111;
        end
        else begin
          response_size=0;
        end
        cmd_out[39:38]=2'b01;
        cmd_out[37:32]=`CMDI;  //CMD_INDEX
        cmd_out[31:0]= arg_reg;           //CMD_Argument
        settings[14:13]=`WORD_SELECT;             //Reserved
        settings[12] = data_read; //Type of command
        settings[11] = data_write;
        settings[10:8]=3'b111;            //Delay
        settings[7]=`CRCE;         //CRC-check
        settings[6:0]=response_size;   //response size
        watchdog_cnt = 0;
        `CICMD =1;
      end
      EXECUTE: begin
        watchdog_cnt = watchdog_cnt +1;
        if (watchdog_cnt>timeout_reg) begin
          `CTE=1;
          `EI = 1;
          if (ack_in == 1) begin
            complete=1;
          end
          go_idle_o=1;
        end
        //Default
        req_out=0;
        ack_out =0;
        //Start sending when serial module is ready
        if (ack_in_int == 1) begin
            req_out =1;
        end
        //Incoming New Status
        else if ( req_in_int == 1) begin
          status=serial_status;
          ack_out = 1;
          if (dat_ava) begin //Data avaible
            complete=1;
            `EI = 0;
            if (crc_check_enable & ~crc_valid) begin
              `CCRCE=1;
              `EI = 1;
            end
            if (index_check_enable &  (cmd_out[37:32] != cmd_in [37:32]) ) begin
              `CIE=1;
              `EI = 1;
            end
            `CC = 1;
            if (response_size !=0)
              resp_1_reg=cmd_in[31:0];
            // end
          end ////Data avaible
        end //Status change
      end //EXECUTE state
    endcase
    if (err_int_rst)
      err_int_reg=0;
    if (normal_int_rst)
      normal_int_reg=0;
  end
end

endmodule
