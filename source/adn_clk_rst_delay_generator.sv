/*

@foez-bhai, write the purpose of this module in markdown format here. This is already in multi-line comment, so don't add any additional comment syntax.

@foez-bhai, describe the use case of this module in markdown format here. This is already in multi-line comment, so don't add any additional comment syntax.

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

// @foez-bhai, add comments to the parameters, ports

module adn_clk_rst_delay_generator #(
    parameter int DELAY_CYCLES = 10
) (
    input logic arst_ni,

    input logic clk_i,
    input logic real_time_clk_i,

    input logic enable_i,

    output logic enable_o
);

  // @foez-bhai, add comments to the functional blocks, signals, and submodules

//////////////////////////////////////////////////////////////////////////////////////////////////
  // SIGNALS
//////////////////////////////////////////////////////////////////////////////////////////////////
  logic [$clog2(DELAY_CYCLES+1)-1:0] counter;
  logic counter_done;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////
  assign counter_done = (counter == DELAY_CYCLES);

//////////////////////////////////////////////////////////////////////////////////////////////////
  // SEQUENTIALS
//////////////////////////////////////////////////////////////////////////////////////////////////

  always_ff @(posedge real_time_clk_i or negedge arst_ni) begin
    if (!arst_ni) begin
      counter <= '0;
    end else begin
      if (!counter_done) begin
        counter <= counter + 1'b1;
      end
    end
  end

  // Forward the enable once the delay has completed, synchronized to the clk_i domain
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
endmodule
