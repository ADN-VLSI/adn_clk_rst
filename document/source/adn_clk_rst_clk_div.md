# adn_clk_rst_clk_div (module)

### Author: Mohiuddin Reyad (mreyad30207@gmail.com)

### Source: adn_clk_rst_clk_div.sv

## Top IO

<img src="./adn_clk_rst_clk_div_top.svg">

## Parameters

|Name|Type|Dimension|Default|Description|
|-|-|-|-|-|
|DIV_WIDTH|int||4|Width of the division factor register|


## Ports

|Name|Direction|Type|Dimension|Description|
|-|-|-|-|-|
|arst_ni|input|logic|||
|clk_i|input|logic|||
|div_i|input|logic [DIV_WIDTH-1:0]|||
|clk_o|output|logic|||


## Description

### PURPOSE:
Generates a lower-frequency output clock (`clk_o`) by dividing an input
clock (`clk_i`) by a user-specified division factor (`div_i`). Because it
uses dual-edge registers internally, it captures transitions on BOTH the
rising and falling edges of `clk_i`, allowing it to support odd division
ratios while maintaining a ~50% duty cycle.

### HOW IT WORKS:
1. Asynchronous Reset:
- When `arst_ni` is driven low, internal counters and the output clock
`clk_o` reset asynchronously to 0.
2. Dual-Edge Counter (`u_counter_reg`):
- Increments `counter_q` on every edge (both rising and falling) of `clk_i`.
- Counts from 0 up to `(div_i - 1)`. When `counter_n` hits `div_i`,
it wraps back around to 0.
- If `div_i == 0`, division is disabled and the counter stays locked at 0.
3. Toggle Generation (`u_clk_o_reg`):
- Whenever `counter_q` equals 0 (`toggle_en` is high), the output clock
register toggles its state (`~clk_o`) on the next `clk_i` edge.
- One full toggle cycle of `clk_o` (high + low) completes after two
full counter reset periods, resulting in an effective frequency division
proportional to `div_i`.

### USE CASE:
This module is ideal for clock tree synthesis where a stable, 50% duty cycle clock is required from a high-frequency source, especially when odd-integer division ratios are necessary. It is commonly used in:
- **Communication Interfaces:** Generating baud rate clocks for UART or SPI.
- **Power Management:** Reducing clock frequency to save dynamic power in idle states.
- **System Synchronization:** Providing reference clocks to peripherals that operate at sub-multiples of the main system clock.

| REVISION | DATE       | AUTHOR          | DESCRIPTION                                            |
|----------|------------|-----------------|--------------------------------------------------------|
| 0.1      | 2026-08-09 | Mohiuddin Reyad | Initial version                                        |
| 1.0      | 2026-08-09 | Mohiuddin Reyad | Stable release                                         |

Author : Mohiuddin Reyad (mreyad30207@gmail.com)
