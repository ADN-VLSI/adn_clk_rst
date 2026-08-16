/*

### Purpose
This module generates a programmable delay for an enable signal. It utilizes a real-time clock to count a specified number of cycles before asserting the output enable signal, which is then synchronized to the primary system clock domain.

### Use Case
This module is primarily used in clock and reset management subsystems where a specific delay is required before enabling downstream logic. It is particularly useful for:
- **Power-up Sequencing:** Ensuring that certain blocks remain disabled until the system clock has stabilized.
- **Reset De-assertion:** Providing a controlled delay after a reset release to allow internal registers to settle.
- **Synchronization:** Bridging an enable signal from a slow real-time clock domain to a high-speed system clock domain with a deterministic latency.

| REVISION | DATE       | AUTHOR          | DESCRIPTION                                            |
|----------|------------|-----------------|--------------------------------------------------------|
| 0.1      | 2026-08-13 | Adnan Sami Anirban | Initial version                                        |
| 1.0      | 2026-08-13 | Adnan Sami Anirban | Stable release                                         |

Author : Adnan Sami Anirban (adnananirban259@gmail.com)
This file is part of ADN-VLSI/adn_clk_rst
Copyright (c) 2026 ADN Semiconductors
Licensed under the MIT License
See LICENSE file in the project root for full license information

*/

module adn_clk_rst_delay_generator #(
    parameter int DELAY_CYCLES = 10 // Number of clock cycles to delay the enable signal
) (
    input logic arst_ni,          // Asynchronous active-low reset

    input logic clk_i,            // Primary system clock
    input logic real_time_clk_i,  // Real-time clock for counter reference

    input logic enable_i,         // Input enable signal to be delayed

    output logic enable_o         // Delayed and synchronized output enable
);

//////////////////////////////////////////////////////////////////////////////////////////////////
  // SIGNALS
//////////////////////////////////////////////////////////////////////////////////////////////////
  // Counter register to track elapsed cycles in the real-time clock domain
  logic [$clog2(DELAY_CYCLES+1)-1:0] counter;
  // Flag indicating the delay period has elapsed
  logic counter_done;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////
  // Combinational logic to detect when the counter reaches the target delay
  assign counter_done = (counter == DELAY_CYCLES);

//////////////////////////////////////////////////////////////////////////////////////////////////
  // SEQUENTIALS
//////////////////////////////////////////////////////////////////////////////////////////////////

  // Counter logic: Increments on the real-time clock until DELAY_CYCLES is reached
  always_ff @(posedge real_time_clk_i or negedge arst_ni) begin
    if (!arst_ni) begin
      counter <= '0;
    end else begin
      if (!counter_done) begin
        counter <= counter + 1'b1;
      end
    end
  end

  // Output synchronization: Samples the counter_done status into the primary system clock domain
  always_ff @(posedge clk_i or negedge arst_ni) begin
    if (!arst_ni) begin
      enable_o <= 1'b0;
    end else begin
      if (enable_i) begin
        enable_o <= counter_done;
      end else begin
        enable_o <= 1'b0;  // If enable_i goes low, reset the output immediately
      end
    end
  end

`ifdef SIMULATION
  initial begin
    if (DELAY_CYCLES < 0) begin
      $display("\033[1;31m%m Error: DELAY_CYCLES must be greater than or equal to 0\033[0m");
    end
  end
`endif  // SIMULATION
endmodule
