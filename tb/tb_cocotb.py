#******************************************************************************
# file:    tb_cocotb.py
#
# author:  JAY CONVERTINO
#
# date:    2024/12/09
#
# about:   Brief
# Cocotb test bench
#
# license: License MIT
# Copyright 2024 Jay Convertino
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.
#
#******************************************************************************

import random
import itertools

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge, Timer, Event
from cocotb.binary import BinaryValue
from cocotbext.axi import AxiStreamBus, AxiStreamSource, AxiStreamSink, AxiStreamMonitor, AxiStreamFrame
from cocotbext.spi import SpiBus, SpiConfig
from cocotbext.spi.devices.generic import SpiSlaveLoopback

# Function: random_bool
# Return a infinte cycle of random bools
#
# Returns: List
def random_bool():
  temp = []

  for x in range(0, 256):
    temp.append(bool(random.getrandbits(1)))

  return itertools.cycle(temp)

# Function: start_clock
# Start the simulation clock generator.
#
# Parameters:
#   dut - Device under test passed from cocotb test function
def start_clock(dut):
  cocotb.start_soon(Clock(dut.aclk, int(1000000000/dut.CLOCK_SPEED.value), units="ns").start())

# Function: reset_dut
# Cocotb coroutine for resets, used with await to make sure system is reset.
async def reset_dut(dut):
  dut.arstn.value = 0
  await Timer(1000, units="ns")
  dut.arstn.value = 1

# Function: stream_ff_word_00
# Coroutine that is identified as a test routine. This routine tests for writing a single word, and
# then reading a single word for cpol == 0 and cpha == 0.
#
# Parameters:
#   dut - Device under test passed from cocotb.
@cocotb.test()
async def stream_ff_word_00(dut):

    recv = []
    send = []

    dut.rate.value = int(dut.RATE.value)

    spi_bus = SpiBus.from_entity(dut, cs_name="ssn_o")

    spi_config = SpiConfig(
        word_width=int(dut.BUS_WIDTH.value*8),
        sclk_freq=int(dut.RATE.value),
        cpol=False,
        cpha=False,
        msb_first=True,
        data_output_idle=0,
        frame_spacing_ns=0,
        ignore_rx_value=None,
        cs_active_low=True,
    )

    dut.ssn_i.value = 0

    dut.cpol.value = 0

    dut.cpha.value = 0

    start_clock(dut)

    await reset_dut(dut)

    axis_source = AxiStreamSource(AxiStreamBus.from_prefix(dut, "s_axis"), dut.aclk, dut.arstn, False)
    axis_sink = AxiStreamSink(AxiStreamBus.from_prefix(dut, "m_axis"), dut.aclk, dut.arstn, False)

    spi_loop = SpiSlaveLoopback(spi_bus, spi_config)

    for x in range(0, 256):
      data = int(0xFE).to_bytes(length = 1, byteorder='little') * int(dut.BUS_WIDTH.value)
      tx_frame = AxiStreamFrame(data, tx_complete=Event())

      send.append(tx_frame)

      await axis_source.send(tx_frame)
      await tx_frame.tx_complete.wait()
      
      # await Timer(100, units="us")

    #   recv.append(await axis_sink.recv())
    # 
    # #flush and last word out of spi echo slave
    # data = int(0).to_bytes(length = 1, byteorder='little') * int(dut.BUS_WIDTH.value)
    # tx_frame = AxiStreamFrame(data, tx_complete=Event())
    # 
    # await axis_source.send(tx_frame)
    # await tx_frame.tx_complete.wait()
    # 
    # recv.append(await axis_sink.recv())
    # 
    # #remove first element as its the contents of the SPI core at reset, NOT a valid echo value.
    # recv.pop(0)
    # 
    # for r, s in zip(recv, send):
      # assert r.tdata == s.tdata, "DATA SENT DOES NOT EQUAL DATA RECEIVED"

# Function: single_word_00
# Coroutine that is identified as a test routine. This routine tests for writing a single word, and
# then reading a single word for cpol == 0 and cpha == 0.
#
# Parameters:
#   dut - Device under test passed from cocotb.
@cocotb.test()
async def single_word_00(dut):

    recv = []
    send = []

    dut.rate.value = int(dut.RATE.value)

    spi_bus = SpiBus.from_entity(dut, cs_name="ssn_o")

    spi_config = SpiConfig(
        word_width=int(dut.BUS_WIDTH.value*8),
        sclk_freq=int(dut.RATE.value),
        cpol=False,
        cpha=False,
        msb_first=True,
        frame_spacing_ns=0,
        ignore_rx_value=None,
        cs_active_low=True,
    )

    dut.ssn_i.value = 0

    dut.cpol.value = 0

    dut.cpha.value = 0

    start_clock(dut)

    await reset_dut(dut)

    axis_source = AxiStreamSource(AxiStreamBus.from_prefix(dut, "s_axis"), dut.aclk, dut.arstn, False)
    axis_sink = AxiStreamSink(AxiStreamBus.from_prefix(dut, "m_axis"), dut.aclk, dut.arstn, False)

    spi_loop = SpiSlaveLoopback(spi_bus, spi_config)

    for x in range(0, 256):
      data = x.to_bytes(length = 1, byteorder='little') * int(dut.BUS_WIDTH.value)
      tx_frame = AxiStreamFrame(data, tx_complete=Event())

      send.append(tx_frame)

      await axis_source.send(tx_frame)
      await tx_frame.tx_complete.wait()

      recv.append(await axis_sink.recv())

    #flush and last word out of spi echo slave
    data = int(0).to_bytes(length = 1, byteorder='little') * int(dut.BUS_WIDTH.value)
    tx_frame = AxiStreamFrame(data, tx_complete=Event())

    await axis_source.send(tx_frame)
    await tx_frame.tx_complete.wait()

    recv.append(await axis_sink.recv())

    #remove first element as its the contents of the SPI core at reset, NOT a valid echo value.
    recv.pop(0)

    for r, s in zip(recv, send):
      assert r.tdata == s.tdata, "DATA SENT DOES NOT EQUAL DATA RECEIVED"

# Function: single_word_10
# Coroutine that is identified as a test routine. This routine tests for writing a single word, and
# then reading a single word for cpol == 1 and cpha == 0.
#
# Parameters:
#   dut - Device under test passed from cocotb.
@cocotb.test()
async def single_word_10(dut):

    recv = []
    send = []

    dut.rate.value = int(dut.RATE.value)

    spi_bus = SpiBus.from_entity(dut, cs_name="ssn_o")

    spi_config = SpiConfig(
        word_width=int(dut.BUS_WIDTH.value*8),
        sclk_freq=int(dut.RATE.value),
        cpol=True,
        cpha=False,
        msb_first=True,
        frame_spacing_ns=0,
        ignore_rx_value=None,
        cs_active_low=True,
    )

    dut.ssn_i.value = 0

    dut.cpol.value = 1

    dut.cpha.value = 0

    start_clock(dut)

    await reset_dut(dut)

    axis_source = AxiStreamSource(AxiStreamBus.from_prefix(dut, "s_axis"), dut.aclk, dut.arstn, False)
    axis_sink = AxiStreamSink(AxiStreamBus.from_prefix(dut, "m_axis"), dut.aclk, dut.arstn, False)

    spi_loop = SpiSlaveLoopback(spi_bus, spi_config)

    for x in range(0, 256):
      data = x.to_bytes(length = 1, byteorder='little') * int(dut.BUS_WIDTH.value)
      tx_frame = AxiStreamFrame(data, tx_complete=Event())

      send.append(tx_frame)

      await axis_source.send(tx_frame)
      await tx_frame.tx_complete.wait()

      recv.append(await axis_sink.recv())

    #flush and last word out of spi echo slave
    data = int(0).to_bytes(length = 1, byteorder='little') * int(dut.BUS_WIDTH.value)
    tx_frame = AxiStreamFrame(data, tx_complete=Event())

    await axis_source.send(tx_frame)
    await tx_frame.tx_complete.wait()

    recv.append(await axis_sink.recv())

    #remove first element as its the contents of the SPI core at reset, NOT a valid echo value.
    recv.pop(0)

    for r, s in zip(recv, send):
      assert r.tdata == s.tdata, "DATA SENT DOES NOT EQUAL DATA RECEIVED"

# Function: single_word_01
# Coroutine that is identified as a test routine. This routine tests for writing a single word, and
# then reading a single word for cpol == 0 and cpha == 1.
#
# Parameters:
#   dut - Device under test passed from cocotb.
@cocotb.test()
async def single_word_01(dut):

    recv = []
    send = []

    dut.rate.value = int(dut.RATE.value)

    spi_bus = SpiBus.from_entity(dut, cs_name="ssn_o")

    spi_config = SpiConfig(
        word_width=int(dut.BUS_WIDTH.value*8),
        sclk_freq=int(dut.RATE.value),
        cpol=False,
        cpha=True,
        msb_first=True,
        frame_spacing_ns=0,
        ignore_rx_value=None,
        cs_active_low=True,
    )

    dut.ssn_i.value = 0

    dut.cpol.value = 0

    dut.cpha.value = 1

    start_clock(dut)

    await reset_dut(dut)

    axis_source = AxiStreamSource(AxiStreamBus.from_prefix(dut, "s_axis"), dut.aclk, dut.arstn, False)
    axis_sink = AxiStreamSink(AxiStreamBus.from_prefix(dut, "m_axis"), dut.aclk, dut.arstn, False)

    spi_loop = SpiSlaveLoopback(spi_bus, spi_config)

    for x in range(0, 256):
      data = x.to_bytes(length = 1, byteorder='little') * int(dut.BUS_WIDTH.value)
      tx_frame = AxiStreamFrame(data, tx_complete=Event())

      send.append(tx_frame)

      await axis_source.send(tx_frame)
      await tx_frame.tx_complete.wait()

      recv.append(await axis_sink.recv())

    #flush and last word out of spi echo slave
    data = int(0).to_bytes(length = 1, byteorder='little') * int(dut.BUS_WIDTH.value)
    tx_frame = AxiStreamFrame(data, tx_complete=Event())

    await axis_source.send(tx_frame)
    await tx_frame.tx_complete.wait()

    recv.append(await axis_sink.recv())

    #remove first element as its the contents of the SPI core at reset, NOT a valid echo value.
    recv.pop(0)

    for r, s in zip(recv, send):
      assert r.tdata == s.tdata, "DATA SENT DOES NOT EQUAL DATA RECEIVED"

# Function: single_word_11
# Coroutine that is identified as a test routine. This routine tests for writing a single word, and
# then reading a single word for cpol == 1 and cpha == 1.
#
# Parameters:
#   dut - Device under test passed from cocotb.
@cocotb.test()
async def single_word_11(dut):

    recv = []
    send = []

    dut.rate.value = int(dut.RATE.value)

    spi_bus = SpiBus.from_entity(dut, cs_name="ssn_o")

    spi_config = SpiConfig(
        word_width=int(dut.BUS_WIDTH.value*8),
        sclk_freq=int(dut.RATE.value),
        cpol=True,
        cpha=True,
        msb_first=True,
        frame_spacing_ns=0,
        ignore_rx_value=None,
        cs_active_low=True,
    )

    dut.ssn_i.value = 0

    dut.cpol.value = 1

    dut.cpha.value = 1

    start_clock(dut)

    await reset_dut(dut)

    axis_source = AxiStreamSource(AxiStreamBus.from_prefix(dut, "s_axis"), dut.aclk, dut.arstn, False)
    axis_sink = AxiStreamSink(AxiStreamBus.from_prefix(dut, "m_axis"), dut.aclk, dut.arstn, False)

    spi_loop = SpiSlaveLoopback(spi_bus, spi_config)

    for x in range(0, 256):
      data = x.to_bytes(length = 1, byteorder='little') * int(dut.BUS_WIDTH.value)
      tx_frame = AxiStreamFrame(data, tx_complete=Event())

      send.append(tx_frame)

      await axis_source.send(tx_frame)
      await tx_frame.tx_complete.wait()

      recv.append(await axis_sink.recv())

    #flush and last word out of spi echo slave
    data = int(0).to_bytes(length = 1, byteorder='little') * int(dut.BUS_WIDTH.value)
    tx_frame = AxiStreamFrame(data, tx_complete=Event())

    await axis_source.send(tx_frame)
    await tx_frame.tx_complete.wait()

    recv.append(await axis_sink.recv())

    #remove first element as its the contents of the SPI core at reset, NOT a valid echo value.
    recv.pop(0)

    for r, s in zip(recv, send):
      assert r.tdata == s.tdata, "DATA SENT DOES NOT EQUAL DATA RECEIVED"

# Function: in_reset
# Coroutine that is identified as a test routine. This routine tests if device stays
# in unready state when in reset.
#
# Parameters:
#   dut - Device under test passed from cocotb.
@cocotb.test()
async def in_reset(dut):

    start_clock(dut)

    dut.m_axis_tready.value = 0

    dut.arstn.value = 0

    await Timer(10, units="ns")

    assert dut.s_axis_tready.value.integer == 0, "tready is 1!"

# Function: no_clock
# Coroutine that is identified as a test routine. This routine tests if no ready when clock is lost
# and device is left in reset.
#
# Parameters:
#   dut - Device under test passed from cocotb.
@cocotb.test()
async def no_clock(dut):

    dut.m_axis_tready.value = 0

    dut.arstn.value = 0

    dut.aclk.value = 0

    await Timer(5, units="ns")

    assert dut.s_axis_tready.value.integer == 0, "tready is 1!"
