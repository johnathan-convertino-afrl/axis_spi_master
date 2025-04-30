# AXIS SPI MASTER
### SPI Master Only TO AXIS with CPOL/CPHA and rate selection.

![image](docs/manual/img/AFRL.png)

---

   author: Jay Convertino   
   
   date: 2025.04.17
   
   details: Interface SPI data at some baud to a axi streaming interface.
   
   license: MIT   
   
---

### Version
#### Current
  - V1.0.0 - initial release

#### Previous
  - none

### DOCUMENTATION
  For detailed usage information, please navigate to one of the following sources. They are the same, just in a different format.

  - [axis_spi_master.pdf](docs/manual/axis_spi_master.pdf)
  - [github page](https://johnathan-convertino-afrl.github.io/axis_spi_master/)

### DEPENDENCIES
#### Build
  - AFRL:utility:helper:1.0.0
  - AFRL:simple:piso:1.0.0
  - AFRL:simple:sipo:1.0.0
  
#### Simulation

  - AFRL:simulation:axis_stimulator
  - cocotb
  - cocotbext-axi
  - cocotbext-spi

### PARAMETERS

 *   CLOCK_SPEED      - This is the aclk frequency in Hz, this is the the frequency used for the bus and is divided by the rate.
 *   BUS_WIDTH        - AXIS data width in bytes.
 *   SELECT_WIDTH     - Bit width of the slave select.

### COMPONENTS
#### SRC

* axis_spi_master.v
  
#### TB

* tb_spi.v
* tb_cocotb.py
* tb_cocotb.v
  
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
  - sim_cocotb
