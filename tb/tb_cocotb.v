//******************************************************************************
// file:    tb_cocotb.v
//
// author:  JAY CONVERTINO
//
// date:    2025/04/24
//
// about:   Brief
// Test bench wrapper for cocotb
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

`timescale 1ns/100ps

/*
 * Module: tb_cocotb
 *
 * SPI core with axis input/output data. Read/Write is size of BUS_WIDTH bytes. Write activates core for read.
 *
 * Parameters:
 *
 *   CLOCK_SPEED      - This is the aclk frequency in Hz, this is the the frequency used for the bus and is divided by the rate.
 *   BUS_WIDTH        - AXIS data width in bytes.
 *   SELECT_WIDTH     - Bit width of the slave select.
 *   RATE             - Select the data rate of the spi core.
 *
 * Ports:
 *
 *   aclk           - Clock for AXIS
 *   arstn          - Negative reset for AXIS
 *   s_axis_tdata   - Input data for UART TX.
 *   s_axis_tvalid  - When set active high the input data is valid
 *   s_axis_tready  - When active high the device is ready for input data.
 *   m_axis_tdata   - Output data from UART RX
 *   m_axis_tvalid  - When active high the output data is valid
 *   m_axis_tready  - When set active high the output device is ready for data.
 *   sclk           - spi clock, should only drive output pins to devices.
 *   mosi           - transmit for master output
 *   miso           - receive for master input
 *   ssn_i          - slave select input
 *   ssn_o          - slave select output
 *   rate           - output rate of spi core.
 *   cpol           - clock polarity of spi_clk
 *   cpha           - clock phase of spi_clk
 *   miso_dcount    - Current number of input bits available from parallel register.
 *   mosi_dcount    - current number of output bits available to serial shift output.
 */
module tb_cocotb #(
    parameter CLOCK_SPEED   = 2000000,
    parameter BUS_WIDTH     = 4,
    parameter SELECT_WIDTH  = 1,
    parameter RATE          = 115200
  )
  (
    input                     aclk,
    input                     arstn,
    input  [BUS_WIDTH*8-1:0]  s_axis_tdata,
    input                     s_axis_tvalid,
    output                    s_axis_tready,
    output [BUS_WIDTH*8-1:0]  m_axis_tdata,
    output                    m_axis_tvalid,
    input                     m_axis_tready,
    output                    sclk,
    output                    mosi,
    input                     miso,
    input  [SELECT_WIDTH-1:0] ssn_i,
    output [SELECT_WIDTH-1:0] ssn_o,
    input  [31:0]             rate,
    input                     cpol,
    input                     cpha,
    output [ 7:0]             miso_dcount,
    output [ 7:0]             mosi_dcount
  );

  // wire loop;

  // fst dump command
  initial begin
    $dumpfile ("tb_cocotb.fst");
    $dumpvars (0, tb_cocotb);
    #1;
  end
  
  //Group: Instantiated Modules

  /*
   * Module: dut
   *
   * Device under test, axis_spi_master
   */
  axis_spi_master #(
    .CLOCK_SPEED(CLOCK_SPEED),
    .BUS_WIDTH(BUS_WIDTH),
    .SELECT_WIDTH(SELECT_WIDTH)
  ) dut (
    .aclk(aclk),
    .arstn(arstn),
    .s_axis_tdata(s_axis_tdata),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tready(s_axis_tready),
    .m_axis_tdata(m_axis_tdata),
    .m_axis_tvalid(m_axis_tvalid),
    .m_axis_tready(m_axis_tready),
    .sclk(sclk),
    .mosi(mosi),
    .miso(miso),
    .ssn_i(ssn_i),
    .ssn_o(ssn_o),
    .rate(rate),
    .cpol(cpol),
    .cpha(cpha),
    .miso_dcount(miso_dcount),
    .mosi_dcount(mosi_dcount)
  );
  

endmodule

