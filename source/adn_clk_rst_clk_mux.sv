/*

@foez-bhai, write the purpose of this module in markdown format here. This is already in multi-line comment, so don't add any additional comment syntax.

@foez-bhai, describe the use case of this module in markdown format here. This is already in multi-line comment, so don't add any additional comment syntax.

| REVISION | DATE       | AUTHOR                     | DESCRIPTION                                            |
|----------|------------|----------------------------|--------------------------------------------------------|
| 0.1      | 2026-08-12 | MD Sakhawat Hossain Sabbir | Initial version                                        |
| 1.0      | 2026-08-12 | MD Sakhawat Hossain Sabbir | Stable release                                         |

Author : MD Sakhawat Hossain Sabbir (sabbirone939@gmail.com)
This file is part of ADN-VLSI/adn_clk_rst
Copyright (c) 2026 ADN Semiconductors
Licensed under the MIT License
See LICENSE file in the project root for full license information

*/

// @foez-bhai, add comments to the parameters, ports
module adn_clk_rst_clk_mux #(
    // PARAMETERS
    parameter int SYNC_STAGES = 2 // Depth of the synchronizer chain in EACH clock domain, forwarded to adn_common_synchronizer.STAGES. Must be >= 1; >= 2 recommended for metastability hardening.
    // LOCALPARAMS
) (
    // PORTS
    input logic clk1_i,  // Clock 1
    input logic clk2_i,  // Clock 2
    input logic sel_i,  // 1 = route clk1_i to clk_o, 0 = route clk2_i to clk_o
    input  logic arst_ni,  // Active-low asynchronous reset, applied independently in both clock domains

    output logic clk_o
);

  // @foez-bhai, add comments to the functional blocks, signals, and submodules

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // LOCALPARAMS GENERATED
  //////////////////////////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // TYPEDEFS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////
  logic sync1_o; // Settled output of the clk1_i-domain synchronizer ("clk1_i armed" bit, sync1_o in the diagram)
  logic sync2_o; // Settled output of the clk2_i-domain synchronizer ("clk2_i armed" bit, sync2_o in the diagram)

  logic i_and1;  // D input to the clk1_i-domain synchronizer: select clk1_i AND clk2_i domain currently not armed
  logic i_and2;  // D input to the clk2_i-domain synchronizer: select clk2_i AND clk1_i domain currently not armed

  logic o_and1;  // clk1_i gated by its own settled synchronizer output
  logic o_and2;  // clk2_i gated by its own settled synchronizer output

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////
  assign i_and1 = ~sync2_o & (sel_i | sync1_o);
  assign i_and2 = ~sync1_o & (~sel_i | sync2_o);

  assign o_and1 = sync1_o & clk1_i;
  assign o_and2 = sync2_o & clk2_i;

  assign clk_o  = o_and1 | o_and2;
  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SUBMODULES
  //////////////////////////////////////////////////////////////////////////////////////////////////
  adn_common_synchronizer #(
      .WIDTH      (1),
      .STAGES     (SYNC_STAGES),
      .RESET_VALUE('0)
  ) u_sync1 (
      .clk_i  (clk1_i),
      .arst_ni(arst_ni),
      .en_i   (1'b1),
      .data_i (i_and1),
      .data_o (sync1_o)
  );

  adn_common_synchronizer #(
      .WIDTH      (1),
      .STAGES     (SYNC_STAGES),
      .RESET_VALUE('0)
  ) u_sync2 (
      .clk_i  (clk2_i),
      .arst_ni(arst_ni),
      .en_i   (1'b1),
      .data_i (i_and2),
      .data_o (sync2_o)
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SEQUENTIALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // INITIAL CHECKS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // METHODS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // ASSERTIONS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // INITIAL CHECKS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // SIMULATION

endmodule

