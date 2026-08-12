
/*

## Purpose

Glitch-free 2:1 clock multiplexer using the classic cross-coupled
"safe clock switch" architecture. Selects between `clk1_i` and `clk2_i` and
drives the result on `clk_o`, guaranteeing no runt pulses during a
switch. The per-domain synchronizer chain is delegated to the shared
`adn_common_synchronizer` module rather than re-implemented locally.

## Use Case

Use this module to switch a downstream block between two asynchronous
clock sources (e.g. a functional clock and a test clock, or a primary and
backup oscillator) at runtime, without risking a short/glitched pulse on
`clk_o`. Each domain's enable is gated by the OTHER domain's
synchronized enable (the cross-coupled feedback), so only one domain can
ever be driving `clk_o` at a time — the switchover happens cleanly on a
clock edge of whichever domain is currently active/being armed, never
mid-pulse. `SYNC_STAGES` is forwarded straight into `adn_common_synchronizer`'s
`STAGES` parameter for each domain, so metastability hardening depth is
controlled in exactly one place.

| REVISION | DATE       | AUTHOR                     | DESCRIPTION                                            |
|----------|------------|----------------------------|--------------------------------------------------------|
| 0.1      | 2026-08-12 | MD Sakhawat Hossain Sabbir | Initial version                                        |
| 0.2      | 2026-08-12 | MD Sakhawat Hossain Sabbir | Rebuilt on adn_common_synchronizer                     |

Author : MD Sakhawat Hossain Sabbir (sabbirone939@gmail.com)
This file is part of ADN-VLSI/adn_clk_rst
Copyright (c) 2026 ADN Semiconductors
Licensed under the MIT License
See LICENSE file in the project root for full license information

*/

module adn_clk_rst_clkmux #(
// PARAMETERS
    parameter int SYNC_STAGES = 2 // Depth of the synchronizer chain in EACH clock domain, forwarded to adn_common_synchronizer.STAGES. Must be >= 1; >= 2 recommended for metastability hardening.
// LOCALPARAMS
) (
// PORTS
input  logic clk1_i,     // Clock candidate 1
input  logic clk2_i,     // Clock candidate 2
input  logic sel_i,   // 1 = route clk1_i to clk_o, 0 = route clk2_i to clk_o
input  logic arst_ni,  // Active-low asynchronous reset, applied independently in both clock domains

output logic clk_o    // Muxed output clock: glitch-free selection of clk1_i or clk2_i
);

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
// Mutual-exclusion gating: a domain is only allowed to arm itself if the
// OTHER domain's synchronizer has already settled to "not armed". The
// "| sync*_o" term lets an already-armed domain hold itself armed while
// sel_i is still asserted (the feedback loop implied by the D-Q chains
// in the diagram).
assign i_and1 = ~sync2_o & ( sel_i | sync1_o);
assign i_and2 = ~sync1_o & (~sel_i | sync2_o);

// Final per-domain clock gate: pass the raw clock through only while this
// domain's synchronizer has fully settled to "armed".
assign o_and1 = sync1_o & clk1_i;
assign o_and2 = sync2_o & clk2_i;

// At most one of o_and1/o_and2 can be toggling at any given time, so a
// simple OR is a safe, glitch-free combiner.
always_comb clk_o = o_and1 | o_and2;

//////////////////////////////////////////////////////////////////////////////////////////////////
// SUBMODULES
//////////////////////////////////////////////////////////////////////////////////////////////////
// clk1_i-domain 2FF (or deeper) synchronizer: always enabled, samples
// i_and1 every clk1_i edge and shifts it through SYNC_STAGES flops.
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

// clk2_i-domain mirror of u_sync1, clocked by clk2_i.
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
// INITIAL CHECKS
//////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////
// METHODS
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// ASSERTIONS
//////////////////////////////////////////////////////////////////////////////////////////////////

endmodule