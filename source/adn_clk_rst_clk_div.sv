//==============================================================================
// Module Name : adn_clk_rst_clk_div
// Description : Dual-Edge Triggered Configurable Clock Divider
//
// PURPOSE:
//   Generates a lower-frequency output clock (`clk_o`) by dividing an input
//   clock (`clk_i`) by a user-specified division factor (`div_i`). Because it
//   uses dual-edge registers internally, it captures transitions on BOTH the
//   rising and falling edges of `clk_i`, allowing it to support odd division
//   ratios while maintaining a ~50% duty cycle.
//
// HOW IT WORKS:
//   1. Asynchronous Reset:
//      - When `arst_ni` is driven low, internal counters and the output clock
//        `clk_o` reset asynchronously to 0.
//   2. Dual-Edge Counter (`u_counter_reg`):
//      - Increments `counter_q` on every edge (both rising and falling) of `clk_i`.
//      - Counts from 0 up to `(div_i - 1)`. When `counter_n` hits `div_i`,
//        it wraps back around to 0.
//      - If `div_i == 0`, division is disabled and the counter stays locked at 0.
//   3. Toggle Generation (`u_clk_o_reg`):
//      - Whenever `counter_q` equals 0 (`toggle_en` is high), the output clock
//        register toggles its state (`~clk_o`) on the next `clk_i` edge.
//      - One full toggle cycle of `clk_o` (high + low) completes after two
//        full counter reset periods, resulting in an effective frequency division
//        proportional to `div_i`.
//
// PARAMETERS:
//   DIV_WIDTH : Width in bits for the division factor input (default: 4).
//
// PORTS:
//   arst_ni   : Asynchronous active-low reset.
//   clk_i     : High-frequency input clock.
//   div_i     : Division factor input [DIV_WIDTH-1:0].
//   clk_o     : Divided output clock.
//==============================================================================

module adn_clk_rst_clk_div #(
    parameter int DIV_WIDTH = 4
) (
    input logic                 arst_ni,  // active low asynchronous reset
    input logic                 clk_i,    // input clock
    input logic [DIV_WIDTH-1:0] div_i,    // input clock divider

    output logic clk_o  // output clock
);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  logic [DIV_WIDTH-1:0] counter_q;  // Current value of the counter
  logic [DIV_WIDTH-1:0] counter_n;  // Next value of the counter
  logic                 toggle_en;  // Enable signal to toggle the output clock

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-COMBINATIONALS
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
  //-SEQUENTIALS
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
