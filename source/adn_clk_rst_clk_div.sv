/*
 * Module: adn_clk_rst_clk_div
 * Author: Foez Ahmed
 * Brief: One-line summary.
 * Details: Optional multi-line behavior notes.
 */

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
  s1_dual_edge_register #(
      .WIDTH(DIV_WIDTH)
  ) u_counter_reg (
      .arst_ni(arst_ni),
      .clk_i(clk_i),
      .data_i(counter_n),
      .en_i(1'b1),
      .data_o(counter_q)
  );

  // Dual-edge register for clk_o; toggles based on computed next-state.
  s1_dual_edge_register #(
      .WIDTH(1)
  ) u_clk_o_reg (
      .arst_ni(arst_ni),
      .clk_i(clk_i),
      .data_i(~clk_o),
      .en_i(toggle_en),
      .data_o(clk_o)
  );

endmodule
