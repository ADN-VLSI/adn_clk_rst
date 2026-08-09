# adn_clk_rst_dual_edge_register (module)

### Author: Mohiuddin Reyad (mreyad30207@gmail.com)

### Source: adn_clk_rst_dual_edge_register.sv

## Top IO

<img src="./adn_clk_rst_dual_edge_register_top.svg">

## Parameters

|Name|Type|Dimension|Default|Description|
|-|-|-|-|-|
|WIDTH|int||8|Width of the register|


## Ports

|Name|Direction|Type|Dimension|Description|
|-|-|-|-|-|
|arst_ni|input|logic|||
|clk_i|input|logic|||
|data_i|input|logic [WIDTH-1:0]|||
|en_i|input|logic|||
|data_o|output|logic [WIDTH-1:0]|||


## Description

### PURPOSE:
Captures input data (`data_i`) on BOTH the rising (`posedge`) and falling
(`negedge`) edges of `clk_i` when enabled (`en_i`). It allows internal
sequential logic to run at twice the effective clock rate without requiring
a doubled clock frequency.

### HOW IT WORKS:
1. Simulation Bypass (`SIMULATION` defined):
- Uses a simple behavioral `always` block sensitive to any `clk_i` transition
to update `data_o` directly for faster simulation runtimes.
2. Synthesis Path (`SIMULATION` not defined):
- Rising-Edge Flop (`reg_pos`): Updates on `posedge clk_i` when `en_i` is high.
If `en_i` is low, it mirrors `reg_neg` to maintain cross-edge coherence.
- Falling-Edge Flop (`reg_neg`): Updates on `negedge clk_i` when `en_i` is high.
If `en_i` is low, it mirrors `reg_pos`.
- Clock-Level Mux: A combinational mux selects `reg_pos` while `clk_i` is high
and `reg_neg` while `clk_i` is low, producing a continuous dual-edge output on `data_o`.
3. Asynchronous Reset:
- Driving `arst_ni` low asynchronously zeroes all storage elements.

### USE CASE:
This module is ideal for high-throughput data interfaces (e.g., DDR memory controllers, source-synchronous serial links) where data must be sampled on both clock edges to maximize bandwidth without increasing the physical clock frequency, thereby saving power and simplifying clock tree distribution.

| REVISION | DATE       | AUTHOR          | DESCRIPTION                                            |
|----------|------------|-----------------|--------------------------------------------------------|
| 0.1      | 2026-08-09 | Mohiuddin Reyad | Initial version                                        |
| 1.0      | 2026-08-09 | Mohiuddin Reyad | Stable release                                         |

Author : Mohiuddin Reyad (mreyad30207@gmail.com)
