module sata_dma_interface (
  input               clk,
  input               rst,

  input               enable,

  //SATA Controller Interface
  output  reg [7:0]   sata_command,
  output  reg         sata_execute_command_stb, //Execute Command Strobe
  output  reg [47:0]  sata_lba,                 //SATA Sector Address
  output  reg [15:0]  sata_sector_count,        //512 Increment

  //Write Side
  input               write_enable,
  input       [63:0]  write_addr,
  output              write_finished,
  input       [23:0]  write_count,
  input               write_flush,

  input       [1:0]   write_activate,
  input               write_strobe,
  input               write_empty,

  //Read Side
  input               read_enable,
  input       [63:0]  read_addr,
  output              read_busy,
  output              read_error,
  input       [23:0]  read_count,
  input               read_flush,

  input               read_activate,
  input               read_strobe

);

//Local Parameters
//Registers/Wires
reg                   prev_write_enable;
wire                  posedge_write_enable;
reg                   prev_read_enable;
wire                  posedge_read_enable;
reg         [23:0]    sata_write_count;
reg         [23:0]    sata_read_count;

//Add a delay to allow the address and sector to be set up
reg                   begin_command_stb;


//Submodules
//Asynchronous Logic
assign  posedge_write_enable        = !prev_write_enable  && write_enable;
assign  posedge_read_enable         = !prev_read_enable   && read_enable;
assign  write_finished              = ((write_count > 0)  && (sata_write_count >= write_count) && write_empty);
assign  read_finished               = ((read_count > 0) && (sata_read_count >= read_count));
assign  read_busy                   = read_enable && !read_finished;
//XXX How to detect Errors?
assign  read_error                  = 0;

//Synchronous Logic
always @ (posedge clk) begin
  if (rst || !enable) begin
    prev_write_enable         <=  0;
    prev_read_enable          <=  0;

    sata_write_count          <=  0;
    sata_read_count           <=  0;

    sata_lba                  <=  0;
    sata_sector_count         <=  0;

    sata_execute_command_stb  <=  0;
    begin_command_stb         <=  0;
    sata_command              <=  0;
  end
  else begin
    //Strobes
    sata_execute_command_stb  <=  0;
    begin_command_stb         <=  0;


    if (posedge_write_enable && !read_enable) begin
      //Initiate a Write Transaction with the Hard Drive
      sata_lba                <=  write_addr[55:6];
      sata_sector_count       <=  write_count[23:7] + (write_count[6:0] > 0); //The extra '+' is to take care of overflow
      begin_command_stb       <=  1;
      sata_command            <=  8'h35;
      sata_write_count        <=  0;
    end
    else if (posedge_read_enable && !write_enable) begin
      //Initiate a Read Transaction with the hard Drive
      sata_lba                <=  read_addr[55:6];
      sata_sector_count       <=  read_count[23:7] + (read_count[6:0] > 0); //The extra '+' is to take care of overflow
      begin_command_stb       <=  1;
      sata_command            <=  8'h25;
      sata_read_count         <=  0;
    end

    if (begin_command_stb) begin
      sata_execute_command_stb<=  1;
    end

    if (write_enable) begin
      if ((write_activate > 0) && write_strobe) begin
        sata_write_count      <=  sata_write_count + 1;
      end
    end
    else if (read_enable) begin
      if (read_activate && read_strobe) begin
        sata_read_count       <=  sata_read_count + 1;
      end
    end


    prev_write_enable         <=  write_enable;
    prev_read_enable          <=  read_enable;
  end
end

endmodule
