/*
@foez-bhai, write the purpose of this module in markdown format here. This is already in multi-line comment, so don't add any additional comment syntax.
@foez-bhai, describe the use case of this module in markdown format here. This is already in multi-line comment, so don't add any additional comment syntax.
| REVISION | DATE       | AUTHOR                     | DESCRIPTION                                            |
|----------|------------|----------------------------|--------------------------------------------------------|
| 0.1      | 2026-08-11 | MD Sakhawat Hossain Sabbir | Initial version                                        |
| 1.0      | 2026-08-11 | MD Sakhawat Hossain Sabbir | Stable release                                         |
Author : MD Sakhawat Hossain Sabbir (sabbirone939@gmail.com)
This file is part of ADN-VLSI/adn_clk_rst
Copyright (c) 2026 ADN Semiconductors
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

// @foez-bhai, add comments to the parameters, ports
module adn_clk_rst_clk_mux #(
    // PARAMETERS
    parameter int NUM_CLOCKS = 4,
    parameter int SEL_WIDTH  = (NUM_CLOCKS <= 1) ? 1 : $clog2(NUM_CLOCKS)
    // LOCALPARAMS
) (
    // PORTS
    input  logic                  arst_ni,
    input  logic [NUM_CLOCKS-1:0] clk_i,
    input  logic [ SEL_WIDTH-1:0] sel_i,

    output logic                  clk_o
);

  // @foez-bhai, add comments to the functional blocks, signals, and submodules

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////
  logic [NUM_CLOCKS-1:0] clk_en;
  //////////////////////////////////////////////////////////////////////////////////////////////////
  // ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////
  assign clk_o = |(clk_i & clk_en);
  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SEQUENTIALS
  //////////////////////////////////////////////////////////////////////////////////////////////////
  genvar i;

  generate
    for (i = 0; i < NUM_CLOCKS; i++) begin : gen_clk
      always_ff @(posedge clk_i[i] or negedge arst_ni) begin
        if (!arst_ni) clk_en[i] <= 1'b0;
        else clk_en[i] <= (sel_i == i);
      end
    end
  endgenerate
  //////////////////////////////////////////////////////////////////////////////////////////////////
  // INITIAL CHECKS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // METHODS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // ASSERTIONS
  //////////////////////////////////////////////////////////////////////////////////////////////////
endmodule

