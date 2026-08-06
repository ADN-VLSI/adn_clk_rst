//==============================================================================
// Module Name : adn_clk_rst_dual_edge_register
// Description : Dual-Edge Triggered Register (Pos/Neg Edge Flip-Flop Pair)
//
// PURPOSE:
//   Captures input data (`data_i`) on BOTH the rising (`posedge`) and falling
//   (`negedge`) edges of `clk_i` when enabled (`en_i`). It allows internal
//   sequential logic to run at twice the effective clock rate without requiring
//   a doubled clock frequency.
//
// HOW IT WORKS:
//   1. Simulation Bypass (`SIMULATION` defined):
//      - Uses a simple behavioral `always` block sensitive to any `clk_i` transition
//        to update `data_o` directly for faster simulation runtimes.
//   2. Synthesis Path (`SIMULATION` not defined):
//      - Rising-Edge Flop (`reg_pos`): Updates on `posedge clk_i` when `en_i` is high.
//        If `en_i` is low, it mirrors `reg_neg` to maintain cross-edge coherence.
//      - Falling-Edge Flop (`reg_neg`): Updates on `negedge clk_i` when `en_i` is high.
//        If `en_i` is low, it mirrors `reg_pos`.
//      - Clock-Level Mux: A combinational mux selects `reg_pos` while `clk_i` is high
//        and `reg_neg` while `clk_i` is low, producing a continuous dual-edge output on `data_o`.
//   3. Asynchronous Reset:
//      - Driving `arst_ni` low asynchronously zeroes all storage elements.
//
// PARAMETERS:
//   WIDTH   : Data bus width in bits (default: 8).
//
// PORTS:
//   arst_ni : Asynchronous active-low reset.
//   clk_i   : Input clock.
//   data_i  : Parallel data input bus [WIDTH-1:0].
//   en_i    : Capture enable signal.
//   data_o  : Dual-edge registered data output bus [WIDTH-1:0].
//==============================================================================

// Dual-edge storage using two edge flops and a clock-level mux on the output.
module adn_clk_rst_dual_edge_register #(
    parameter int WIDTH = 8  // Width of the register
) (
    input logic arst_ni,  // active low asynchronous reset
    input logic clk_i,    // input clock

    input logic [WIDTH-1:0] data_i,  // data input
    input logic             en_i,    // enable signal for capturing data

    output logic [WIDTH-1:0] data_o  // data output
);

`ifdef SIMULATION

  always @(clk_i or negedge arst_ni) begin
    if (!arst_ni) begin
      data_o <= '0;
    end else if (en_i) begin
      data_o <= data_i;
    end
  end

`else

  logic [WIDTH-1:0] reg_pos;  // Register capturing data on the positive edge
  logic [WIDTH-1:0] reg_neg;  // Register capturing data on the negative edge

  // Combinational mux selects edge-captured data; note this lets clk_i level toggle data_o.
  always_comb begin
    data_o = clk_i ? reg_pos : reg_neg;
  end

  // Capture on rising edge; when disabled, mirror the opposite-edge sample.
  always_ff @(posedge clk_i or negedge arst_ni) begin
    if (!arst_ni) begin
      reg_pos <= '0;
    end else if (en_i) begin
      reg_pos <= data_i;
    end else begin
      reg_pos <= reg_neg;
    end
  end

  // Capture on falling edge; when disabled, mirror the opposite-edge sample.
  always_ff @(negedge clk_i or negedge arst_ni) begin
    if (!arst_ni) begin
      reg_neg <= '0;
    end else if (en_i) begin
      reg_neg <= data_i;
    end else begin
      reg_neg <= reg_pos;
    end
  end

`endif

endmodule
