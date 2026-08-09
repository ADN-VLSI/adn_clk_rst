/*

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
This file is part of ADN-VLSI/adn_clk_rst
Copyright (c) 2026 ADN Semiconductors
Licensed under the MIT License
See LICENSE file in the project root for full license information

*/

module adn_clk_rst_clk_div #(
    parameter int DIV_WIDTH = 4 // Width of the division factor register
) (
    input logic                 arst_ni,  // Active-low asynchronous reset
    input logic                 clk_i,    // Input reference clock
    input logic [DIV_WIDTH-1:0] div_i,    // Division factor input

    output logic clk_o  // Divided output clock
);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  logic [DIV_WIDTH-1:0] counter_q;  // Current value of the counter
  logic [DIV_WIDTH-1:0] counter_n;  // Next value of the counter
  logic                 toggle_en;  // Enable signal to toggle the output clock

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // COMBINATIONALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // This block determines when to toggle the output clock.  The output clock is toggled when the counter reaches 0.
  always_comb toggle_en = (counter_q == '0);

  // This block implements the counter logic.
  always_comb begin
    // If the divisor is 0, reset the counter to 0. This handles the case where no clock division is desired.
    if (div_i == '0) begin
      counter_n = '0;
    end else begin
      // Increment the counter.
      counter_n = counter_q + 1;
      // If the counter reaches the divisor value, reset it to 0.
      if (counter_n == div_i) begin
        counter_n = '0;
      end
    end
  end

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SUBMODULES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Dual-edge register for counter; captures next count every clock transition.
  adn_clk_rst_dual_edge_register #(
      .WIDTH(DIV_WIDTH)
  ) u_counter_reg (
      .arst_ni(arst_ni),
      .clk_i(clk_i),
      .data_i(counter_n),
      .en_i(1'b1),
      .data_o(counter_q)
  );

  // Dual-edge register for clk_o; toggles based on computed next-state.
  adn_clk_rst_dual_edge_register #(
      .WIDTH(1)
  ) u_clk_o_reg (
      .arst_ni(arst_ni),
      .clk_i(clk_i),
      .data_i(~clk_o),
      .en_i(toggle_en),
      .data_o(clk_o)
  );

endmodule
