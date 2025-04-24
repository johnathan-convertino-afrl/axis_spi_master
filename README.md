# AXIS SPI
### SPI TO AXIS

![image](docs/manual/img/AFRL.png)

---

   author: Jay Convertino   
   
   date: 2025.04.17
   
   details: Interface SPI data at some baud to a axi streaming 8 bit interface.
   
   license: MIT   
   
---

### Version
#### Current
  - V1.0.0 - initial release

#### Previous
  - none

### DOCUMENTATION
  For detailed usage information, please navigate to one of the following sources. They are the same, just in a different format.

  - [axis_spi.pdf](docs/manual/axis_spi.pdf)
  - [github page](https://johnathan-convertino-afrl.github.io/axis_spi/)

### DEPENDENCIES
#### Build
  - AFRL:utility:helper:1.0.0
  
#### Simulation

  - AFRL:simulation:axis_stimulator
  - cocotb

### PARAMETERS

  * BAUD_CLOCK_SPEED  - Clock speed of the baud clock. Best if it is a integer multiple of the baud rate, but does not have to be.
  * BAUD_RATE         - Baud rate of the input/output data for the core.
  * PARITY_ENA        - Enable parity check and generate.
  * PARITY_TYPE       - Set the parity type, 0 = even, 1 = odd, 2 = mark, 3 = space.
  * STOP_BITS         - Number of stop bits, 0 to crazy non-standard amounts.
  * DATA_BITS         - Number of data bits, 1 to crazy non-standard amounts.
  * RX_DELAY          - Delay in rx data input.
  * RX_BAUD_DELAY     - Delay in rx baud enable. This will delay when we sample a bit (default is midpoint when rx delay is 0).
  * TX_DELAY          - Delay in tx data output. Delays the time to output of the data.
  * TX_BAUD_DELAY     - Delay in tx baud enable. This will delay the time the bit output starts.

### COMPONENTS
#### SRC

* axis_spi.v
* spi_clk_gen.v
  
#### TB

* tb_spi.v
* tb_cocotb.py
* tb_cocotb.v
* tb_cocotb_clk_gen.py
* tb_cocotb_clk_gen.v
  
### FUSESOC

* fusesoc_info.core created.
* Simulation uses icarus to run data through the core.

#### targets

* RUN WITH: (fusesoc run --target=sim VENDER:CORE:NAME:VERSION)
  - default (for IP integration builds)
  - sim
  - sim_rand_data
  - sim_rand_ready_rand_data
  - sim_8bit_count_data
  - sim_rand_ready_8bit_count_data
  - sim_baud
  - sim_cocotb
  - sim_cocotb_clk_gen
