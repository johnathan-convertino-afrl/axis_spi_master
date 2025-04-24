//******************************************************************************
// file:    tb_spi.v
//
// author:  JAY CONVERTINO
//
// date:    2025/04/22
//
// about:   Brief
// Test bench for AXIS SPI
//
// license: License MIT
// Copyright 2025 Jay Convertino
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.
//
//******************************************************************************

`timescale 1 ns/10 ps

module tb_spi #
  (
  parameter IN_FILE_NAME = "in.bin",
  parameter OUT_FILE_NAME = "out.bin",
  parameter RAND_READY = 0
  );

  localparam CLOCK_BASE   = 200000000;
  /// scale clock base to a clock period in MHz. Good up to 1 GHz.
  localparam CLK_PERIOD   = 1000000000/CLOCK_BASE;
  localparam RST_PERIOD   = CLK_PERIOD * 10;
  localparam BUS_WIDTH    = 4;
  localparam SELECT_WIDTH = 8;

  wire                    tb_m_axis_tvalid;
  wire                    tb_m_axis_tready;
  wire [BUS_WIDTH*8-1:0]  tb_m_axis_tdata;

  wire                    tb_s_axis_tvalid;
  wire                    tb_s_axis_tready;
  wire [BUS_WIDTH*8-1:0]  tb_s_axis_tdata;

  wire                    tb_spi_clk;
  wire                    tb_spi_loop;
  wire [SELECT_WIDTH-1:0] tb_ssn;

  wire tb_eof;

  reg tb_clk    = 1'b0;
  reg tb_rstn   = 1'b0;
  reg tb_r_eof  = 1'b0;
  reg tb_rr_eof = 1'b0;
  reg [127:0] tb_delay_eof = 0;

  slave_axis_stimulus #(
    .BUS_WIDTH(BUS_WIDTH),
    .USER_WIDTH(1),
    .DEST_WIDTH(1),
    .FILE(IN_FILE_NAME)
  ) slave_axis_stim (
    // output to slave
    .m_axis_aclk(tb_clk),
    .m_axis_arstn(tb_rstn),
    .m_axis_tvalid(tb_m_axis_tvalid),
    .m_axis_tready(tb_m_axis_tready),
    .m_axis_tdata(tb_m_axis_tdata),
    .m_axis_tkeep(),
    .m_axis_tlast(),
    .m_axis_tuser(),
    .m_axis_tdest(),
    .eof(tb_eof)
  );

    //device under test
  axis_spi #(
    .CLOCK_SPEED(CLOCK_BASE),
    .BUS_WIDTH(BUS_WIDTH),
    .SELECT_WIDTH(SELECT_WIDTH)
  ) dut (
    .aclk(tb_clk),
    .arstn(tb_rstn),
    .s_axis_tdata(tb_m_axis_tdata),
    .s_axis_tvalid(tb_m_axis_tvalid),
    .s_axis_tready(tb_m_axis_tready),
    .m_axis_tdata(tb_s_axis_tdata),
    .m_axis_tvalid(tb_s_axis_tvalid),
    .m_axis_tready(tb_s_axis_tready),
    .sclk(tb_spi_clk),
    .mosi(tb_spi_loop),
    .miso(tb_spi_loop),
    .ssn_i({SELECT_WIDTH/2{2'b10}}),
    .ssn_o(tb_ssn),
    .rate(CLOCK_BASE/10),
    .cpol(1'b0),
    .cpha(1'b0)
  );
  
  master_axis_stimulus #(
    .BUS_WIDTH(BUS_WIDTH),
    .USER_WIDTH(1),
    .DEST_WIDTH(1),
    .RAND_READY(RAND_READY),
    .FILE(OUT_FILE_NAME)
  ) master_axis_stim (
    // write
    .s_axis_aclk(tb_clk),
    .s_axis_arstn(tb_rstn),
    .s_axis_tvalid(tb_s_axis_tvalid),
    .s_axis_tready(tb_s_axis_tready),
    .s_axis_tdata(tb_s_axis_tdata),
    .s_axis_tkeep(~0),
    .s_axis_tlast(1'b0),
    .s_axis_tuser(1'b0),
    .s_axis_tdest(1'b0),
    .eof(tb_delay_eof[127])
  );
  
  //reset
  initial
  begin
    tb_rstn <= 1'b0;
    
    #RST_PERIOD;
    
    tb_rstn <= 1'b1;
  end
  
  //axis clock
  always
  begin
    tb_clk <= ~tb_clk;
    
    #(CLK_PERIOD/2);
  end
  
  //copy pasta, fst generation
  initial
  begin
    $dumpfile("tb_spi.fst");
    $dumpvars(0,tb_spi);
  end

  always @(posedge tb_clk)
  begin
    if(tb_rstn == 1'b0)
    begin
      tb_r_eof  <= 1'b0;
      tb_rr_eof <= 1'b0;
      tb_delay_eof <= 0;
    end else begin
      if(tb_m_axis_tready)
      begin
        tb_r_eof <= tb_eof;
      end

      if(tb_s_axis_tvalid)
      begin
        tb_rr_eof <= tb_r_eof;
      end

      tb_delay_eof <= {tb_delay_eof[126:0], tb_rr_eof & tb_ssn[0]};
    end
  end
  
endmodule

