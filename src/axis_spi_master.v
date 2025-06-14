//******************************************************************************
// file:    axis_spi_master.v
//
// author:  JAY CONVERTINO
//
// date:    2025/04/22
//
// about:   Brief
// Stream SPI input/output data over AXIS bus in master mode.
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

`resetall
`default_nettype none

`timescale 1ns/100ps

/*
 * Module: axis_spi_master
 *
 * SPI core with axis input/output data. Read/Write is size of BUS_WIDTH bytes. Write activates core for read.
 *
 * Parameters:
 *
 *   CLOCK_SPEED      - This is the aclk frequency in Hz, this is the the frequency used for the bus and is divided by the rate.
 *   BUS_WIDTH        - AXIS data width in bytes.
 *   SELECT_WIDTH     - Bit width of the slave select.
 *
 * Ports:
 *
 *   aclk           - Clock for AXIS
 *   arstn          - Negative reset for AXIS
 *   s_axis_tdata   - Input data for SPI MOSI.
 *   s_axis_tvalid  - When set active high the input data is valid
 *   s_axis_tready  - When active high the device is ready for input data.
 *   m_axis_tdata   - Output data from SPI MISO
 *   m_axis_tvalid  - When active high the output data is valid
 *   m_axis_tready  - When set active high the output device is ready for data.
 *   sclk           - spi clock, should only drive output pins to devices.
 *   mosi           - transmit for master output
 *   miso           - receive for master input
 *   ssn_i          - slave select input
 *   ssn_o          - slave select output
 *   rate           - output rate of spi core.
 *   cpol           - clock polarity of sclk
 *   cpha           - clock phase of sclk
 *   miso_dcount    - Current number of input bits available from parallel register.
 *   mosi_dcount    - current number of output bits available to serial shift output.
 */
module axis_spi_master #(
    parameter CLOCK_SPEED   = 2000000,
    parameter BUS_WIDTH     = 4,
    parameter SELECT_WIDTH  = 8
  ) 
  (
    input  wire                    aclk,
    input  wire                    arstn,
    input  wire [BUS_WIDTH*8-1:0]  s_axis_tdata,
    input  wire                    s_axis_tvalid,
    output wire                    s_axis_tready,
    output wire [BUS_WIDTH*8-1:0]  m_axis_tdata,
    output wire                    m_axis_tvalid,
    input  wire                    m_axis_tready,
    output wire                    sclk,
    output wire                    mosi,
    input  wire                    miso,
    input  wire [SELECT_WIDTH-1:0] ssn_i,
    output wire [SELECT_WIDTH-1:0] ssn_o,
    input  wire [31:0]             rate,
    input  wire                    cpol,
    input  wire                    cpha,
    output wire [ 7:0]             miso_dcount,
    output wire [ 7:0]             mosi_dcount
  );

  // Group: State Machine
  // Constants that makeup the data_state machine.

  // var: ready
  // ready and waiting for data
  localparam ready      = 3'd1;
  // var: processing
  // data is being processed
  localparam processing = 3'd3;
  // var: error
  // someone made a whoops
  localparam error      = 3'd2;
  
  // wires
  wire spi_ena_mosi;
  wire spi_ena_miso;

  wire spi_mosi_load;
  wire spi_mosi_hold;
  wire spi_miso_load;
  wire spi_ena_clr;

  wire spi_mosi;

  wire move_to_process;

  wire [7:0]  spi_mosi_dcount;
  wire [7:0]  spi_miso_dcount;

  wire [BUS_WIDTH*8-1:0]  miso_pdata;

  // registers
  reg r_clk_o;

  reg r_ssn;

  reg [BUS_WIDTH*8-1:0] r_m_axis_tdata;
  reg                   r_m_axis_tvalid;

  reg [1:0] data_state = error;

  // spi clock generated from mod counters. Should only be used for output pins.
  assign sclk = r_clk_o;

  // we are not ready when holding the clock gens and in reset
  assign s_axis_tready = (spi_mosi_dcount == 0 && r_ssn == 1'b1 ? 1'b1 : spi_mosi_load) & arstn;

  // data is valid when the serial input counter has hit full
  assign m_axis_tdata = r_m_axis_tdata;

  assign m_axis_tvalid = r_m_axis_tvalid;

  // data is valid when the serial input counter has hit full
  assign spi_miso_load = (spi_miso_dcount == BUS_WIDTH*8 && spi_ena_mosi == 1'b1 ? 1'b1 : 1'b0);

  // we hold if the output counter is zero.
  assign spi_mosi_load = (spi_mosi_dcount == 0 && (spi_ena_miso == 1'b1 || spi_miso_dcount == 0) ? 1'b1 : 1'b0) & s_axis_tvalid;

  assign spi_ena_clr = (spi_mosi_dcount == 0 && spi_miso_dcount == 0 ? 1'b1 : 1'b0) & r_ssn;

  // select device if we are not holding (hold is used to show we are ready for a beat, but if there is valid data we mask it to gain a clock cycle).
  assign ssn_o = ssn_i | {SELECT_WIDTH{r_ssn}};

  assign mosi = spi_mosi;

  assign move_to_process = (cpha == 1'b1 ? spi_mosi_load : spi_ena_mosi);

  assign miso_dcount = spi_miso_dcount;

  assign mosi_dcount = spi_mosi_dcount;

  //Group: Instantiated Modules
  /*
  * Module: inst_spi_output_clk
  *
  * Generates enable at rate for spi output data.
  */
  mod_clock_ena_gen #(
    .CLOCK_SPEED(CLOCK_SPEED)
  ) inst_spi_output_clk (
    .clk(aclk),
    .rstn(arstn),
    .start0(1'b0),
    .clr(spi_ena_clr),
    .hold(1'b0),
    .rate(rate),
    .ena(spi_ena_mosi)
  );

  /*
  * Module: inst_spi_input_clk
  *
  * Generates enable at rate for spi input data.
  */
  mod_clock_ena_gen #(
    .CLOCK_SPEED(CLOCK_SPEED)
  ) inst_spi_input_clk (
    .clk(aclk),
    .rstn(arstn),
    .start0(1'b1),
    .clr(spi_ena_clr),
    .hold(1'b0),
    .rate(rate),
    .ena(spi_ena_miso)
  );

  /*
   * Module: inst_piso
   *
   * take axis input parallel data at bus size, and output the word to the spi bus.
   */

  piso #(
    .BUS_WIDTH(BUS_WIDTH)
  ) inst_piso (
    .clk(aclk),
    .rstn(arstn),
    .ena(spi_ena_mosi),
    .rev(1'b0),
    .load(spi_mosi_load),
    .pdata(s_axis_tdata),
    .reg_count_amount(0),
    .sdata(spi_mosi),
    .dcount(spi_mosi_dcount)
  );

  /*
   * Module: inst_sipo
   *
   * take serial input data, and output the world to the parallel data bus.
   */
  sipo #(
    .BUS_WIDTH(BUS_WIDTH)
  ) inst_sipo (
    .clk(aclk),
    .rstn(arstn),
    .ena(spi_ena_miso),
    .rev(1'b0),
    .load(spi_miso_load),
    .pdata(miso_pdata),
    .reg_count_amount(0),
    .sdata(miso),
    .dcount(spi_miso_dcount)
  );

  /*
   * register input data from SIPO for release only when load is activated.
   */
  always @(posedge aclk)
  begin
    if(arstn == 1'b0)
    begin
      r_m_axis_tdata <= 0;
      r_m_axis_tvalid <= 1'b0;
    end else begin
      if(m_axis_tready == 1'b1)
      begin
        r_m_axis_tdata <= 0;
        r_m_axis_tvalid <= 1'b0;
      end

      if(spi_miso_load == 1'b1)
      begin
        r_m_axis_tdata <= miso_pdata;
        r_m_axis_tvalid <= 1'b1;
      end
    end
  end

  /*
   * Use a state machine to activate processing state for selection
   */
  always @(posedge aclk)
  begin
    if(arstn == 1'b0)
    begin
      r_ssn <= 1'b1;
      data_state <= ready;
    end else begin
      r_ssn <= r_ssn;

      case(data_state)
        ready:
        begin
          data_state <= ready;
          r_ssn <= 1'b1;

          if(move_to_process == 1'b1)
          begin
            r_ssn <= 1'b0;
            data_state <= processing;
          end
        end
        processing:
        begin
          data_state <= processing;
          r_ssn <= 1'b0;

          if(spi_mosi_dcount == 0 && spi_miso_load == 1'b1)
          begin
            r_ssn <= 1'b1;

            data_state <= ready;
          end
        end
        default:
        begin
          data_state <= ready;
        end
      endcase
    end
  end

  /*
   * Generate a 50% duty cycle clock based on mod_clock gen enables that are offset to the positive edge and negative edge of the rate clock.
   */
  always @(posedge aclk)
  begin
    if(arstn == 1'b0)
    begin
      r_clk_o <= cpol;
    end else begin
      case(data_state)
        processing:
        begin
          r_clk_o <= r_clk_o;

          if(spi_ena_mosi == 1'b1)
          begin
            r_clk_o <= (cpol ? ~cpha : cpha);
          end

          if(spi_ena_miso == 1'b1)
          begin
            r_clk_o <= (cpol ? cpha : ~cpha);
          end

          if(spi_mosi_dcount == 0 && spi_miso_load == 1'b1)
          begin
            r_clk_o <= cpol;
          end
        end
        default:
        begin
          r_clk_o <= cpol;

          if(cpha == 1'b1 && spi_ena_mosi == 1'b1)
          begin
            r_clk_o <= (cpol ? ~cpha : cpha);
          end
        end
      endcase
    end
  end
endmodule

`resetall
