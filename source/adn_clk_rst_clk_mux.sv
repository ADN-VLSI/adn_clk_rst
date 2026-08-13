/*

# Purpose
This module implements a glitch-free clock multiplexer designed to switch between two asynchronous clock sources. It utilizes a handshaking mechanism with synchronizers to ensure that the output clock is safely gated before switching, preventing runt pulses or metastability during the transition.

### Use Case
This module is intended for systems requiring dynamic clock switching, such as:
- **Power Management:** Switching between a high-frequency clock for performance and a low-frequency clock for power saving.
- **Clock Failover:** Transitioning to a backup clock source if the primary clock source is detected as unstable or failed.
- **Dynamic Frequency Scaling:** Safely changing clock frequencies without stopping the entire system or causing glitches that could violate timing constraints in downstream logic.

| REVISION | DATE       | AUTHOR                     | DESCRIPTION                                            |
|----------|------------|----------------------------|--------------------------------------------------------|
| 0.1      | 2026-08-12 | Md Sakhawat Hossain Sabbir | Initial version                                        |
| 1.0      | 2026-08-12 | Md Sakhawat Hossain Sabbir | Stable release                                         |

Author : Md Sakhawat Hossain Sabbir (sabbirone939@gmail.com)
This file is part of ADN-VLSI/adn_clk_rst
Copyright (c) 2026 ADN Semiconductors
Licensed under the MIT License
See LICENSE file in the project root for full license information

*/

module adn_clk_rst_clk_mux #(
    // PARAMETERS
    parameter int SYNC_STAGES = 2 // Depth of the synchronizer chain in EACH clock domain, forwarded to adn_common_synchronizer.STAGES. Must be >= 1; >= 2 recommended for metastability hardening.
) (
    // PORTS
    input  logic clk1_i,  // Primary clock input 1
    input  logic clk2_i,  // Secondary clock input 2
    input  logic sel_i,   // Selection signal: 1 selects clk1_i, 0 selects clk2_i
    input  logic arst_ni, // Active-low asynchronous reset, applied to synchronizers
    output logic clk_o    // Glitch-free multiplexed clock output
);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // LOCALPARAMS GENERATED
  //////////////////////////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // TYPEDEFS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////
  logic sync1_o; // Synchronized enable request for clock 1
  logic sync2_o; // Synchronized enable request for clock 2

  logic clk1_en_req; // Request to enable clock 1 path
  logic clk2_en_req; // Request to enable clock 2 path

  logic clk1_gated; // Clock 1 gated by its synchronization signal
  logic clk2_gated; // Clock 2 gated by its synchronization signal

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////
  // Handshake logic: Only enable one clock if the other is fully disabled
  assign clk1_en_req = sel_i & ~sync2_o;
  assign clk2_en_req = ~sel_i & ~sync1_o;

  // Gating logic: AND the clock with the synchronized enable signal
  assign clk1_gated = sync1_o & clk1_i;
  assign clk2_gated = sync2_o & clk2_i;

  // Final output: OR the gated clocks together
  assign clk_o  = clk1_gated | clk2_gated;
  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SUBMODULES
  //////////////////////////////////////////////////////////////////////////////////////////////////
  // Synchronizer for clock 1 domain
  adn_common_synchronizer #(
      .WIDTH      (1),
      .STAGES     (SYNC_STAGES),
      .RESET_VALUE('0)
  ) u_sync1 (
      .clk_i  (clk1_i),
      .arst_ni(arst_ni),
      .en_i   (1'b1),
      .data_i (clk1_en_req),
      .data_o (sync1_o)
  );

  // Synchronizer for clock 2 domain
  adn_common_synchronizer #(
      .WIDTH      (1),
      .STAGES     (SYNC_STAGES),
      .RESET_VALUE('0)
  ) u_sync2 (
      .clk_i  (clk2_i),
      .arst_ni(arst_ni),
      .en_i   (1'b1),
      .data_i (clk2_en_req),
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
