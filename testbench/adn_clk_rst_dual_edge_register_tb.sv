/*

| TEST CASE | DATE       | AUTHOR     | DESCRIPTION                                            |
|-----------|------------|------------|--------------------------------------------------------|
| TC_001    | 2026-09-07 | Md Sakhawat Hossain Sabbir | Asynchronous reset                     |
| TC_002    | 2026-09-07 | Md Sakhawat Hossain Sabbir | Positive-edge capture                  |
| TC_003    | 2026-09-07 | Md Sakhawat Hossain Sabbir | Negative-edge capture                  |
| TC_004    | 2026-09-07 | Md Sakhawat Hossain Sabbir | Hold output when enable is low         |
| TC_005    | 2026-09-07 | Md Sakhawat Hossain Sabbir | Consecutive dual-edge captures         |
| TC_006    | 2026-09-07 | Md Sakhawat Hossain Sabbir | Enable low-to-high transition          |
| TC_007    | 2026-09-07 | Md Sakhawat Hossain Sabbir | Enable high-to-low transition          |
| TC_008    | 2026-09-07 | Md Sakhawat Hossain Sabbir | Data changes while disabled            |
| TC_009    | 2026-09-07 | Md Sakhawat Hossain Sabbir | Reset during active operation          |
| TC_010    | 2026-09-07 | Md Sakhawat Hossain Sabbir | Async reset between clock edges        |
| TC_011    | 2026-09-07 | Md Sakhawat Hossain Sabbir | Repeated positive/negative captures    |
| TC_012    | 2026-09-07 | Md Sakhawat Hossain Sabbir | Boundary data values                   |
| TC_013    | 2026-09-07 | Md Sakhawat Hossain Sabbir | Directed pseudo-random dual-edge test  |

| REVISION | DATE       | AUTHOR                     | DESCRIPTION                            |
|----------|------------|----------------------------|----------------------------------------|
| 0.1      | 2026-09-07 | Md Sakhawat Hossain Sabbir | Initial version                        |
| 1.0      | 2026-09-07 | Md Sakhawat Hossain Sabbir | Stable release                         |

Author : Md Sakhawat Hossain Sabbir (sabbirone939@gmail.com)
This file is part of ADN-VLSI/adn_clk_rst
Copyright (c) 2026 ADN Semiconductors
Licensed under the MIT License
See LICENSE file in the project root for full license information

*/

module adn_clk_rst_dual_edge_register_tb;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // IMPORTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // bring in the testbench essentials functions and macros
  `include "vip/adn_common_tb_headers.sv"

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // LOCALPARAMS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  localparam int WIDTH = 8;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // TYPEDEFS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  logic clk_i;
  logic arst_ni;
  logic [WIDTH-1:0] data_i;
  logic en_i;
  logic [WIDTH-1:0] data_o;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // VARIABLES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // INTERFACES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // CLASSES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  adn_clk_rst_dual_edge_register #(.WIDTH(WIDTH)) dut (
    .arst_ni(arst_ni),
    .clk_i(clk_i),
    .data_i(data_i),
    .en_i(en_i),
    .data_o(data_o)
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // METHODS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  task automatic init_signals();
    arst_ni = 1'b0;
    data_i = '0;
    en_i = 1'b0;
  endtask

  task automatic apply_reset();
    arst_ni = 1'b0;
    data_i = '0;
    en_i = 1'b0;
    #1ns;

    if (data_o == '0)
      note_case(1);
    else begin
      note_case(0);
      if (debug)
        $display("[%0t] FAIL: Reset data_o=%h expected=00",
                 $time, data_o);
    end

    repeat (2) @(posedge clk_i);
    @(negedge clk_i);
    arst_ni = 1'b1;
    #1ns;
  endtask

  task automatic check_data(input logic [WIDTH-1:0] expected);
    #1ns;

    if (data_o == expected)
      note_case(1);
    else begin
      note_case(0);
      if (debug)
        $display("[%0t] FAIL: data_o=%h expected=%h",
                 $time, data_o, expected);
    end
  endtask

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SEQUENTIALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // PROCEDURALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  initial clk_i = 1'b0;

  always #5ns clk_i = ~clk_i;

  /////////////////////////////////////////////////////////////////////////////////////////////////
  // TEST CASES
  /////////////////////////////////////////////////////////////////////////////////////////////////

  // TC_001: asynchronous reset
  task automatic tc_001_async_reset();
    init_signals();

    arst_ni = 1'b0;
    data_i = 8'hAA;
    en_i = 1'b1;
    #1ns;

    if (data_o == 8'h00)
      note_case(1);
    else begin
      note_case(0);
      if (debug)
        $display("[%0t] FAIL: TC_001 reset data_o=%h expected=00",
                 $time, data_o);
    end

    data_i = 8'h55;
    en_i = 1'b1;
    #1ns;

    if (data_o == 8'h00)
      note_case(1);
    else begin
      note_case(0);
      if (debug)
        $display("[%0t] FAIL: TC_001 output changed during reset data_o=%h",
                 $time, data_o);
    end

    arst_ni = 1'b1;
    #1ns;

    if (data_o == 8'h00)
      note_case(1);
    else begin
      note_case(0);
      if (debug)
        $display("[%0t] FAIL: TC_001 output changed on reset release data_o=%h",
                 $time, data_o);
    end
  endtask

  // TC_002: positive-edge capture
  task automatic tc_002_posedge_capture();
    apply_reset();

    en_i = 1'b1;
    data_i = 8'hA5;

    @(posedge clk_i);
    check_data(8'hA5);
  endtask

  // TC_003: negative-edge capture
  task automatic tc_003_negedge_capture();
    apply_reset();

    en_i = 1'b1;
    data_i = 8'h5A;

    @(negedge clk_i);
    check_data(8'h5A);
  endtask

  // TC_004: hold output when enable is low
  task automatic tc_004_enable_low_hold();
    apply_reset();

    en_i = 1'b1;
    data_i = 8'h3C;

    @(posedge clk_i);
    check_data(8'h3C);

    en_i = 1'b0;
    data_i = 8'hC3;

    @(negedge clk_i);
    check_data(8'h3C);

    @(posedge clk_i);
    check_data(8'h3C);

    data_i = 8'h55;

    @(negedge clk_i);
    check_data(8'h3C);
  endtask

  // TC_005: consecutive dual-edge captures
  task automatic tc_005_consecutive_dual_edge_capture();
    apply_reset();

    en_i = 1'b1;

    @(negedge clk_i);
    data_i = 8'h11;

    @(posedge clk_i);
    check_data(8'h11);

    data_i = 8'h22;

    @(negedge clk_i);
    check_data(8'h22);

    data_i = 8'h33;

    @(posedge clk_i);
    check_data(8'h33);

    data_i = 8'h44;

    @(negedge clk_i);
    check_data(8'h44);
  endtask

  // TC_006: enable low-to-high transition
  task automatic tc_006_enable_low_to_high();
    apply_reset();

    en_i = 1'b0;
    data_i = 8'h12;

    @(posedge clk_i);
    check_data(8'h00);

    @(negedge clk_i);
    check_data(8'h00);

    en_i = 1'b1;
    data_i = 8'h34;

    @(posedge clk_i);
    check_data(8'h34);

    data_i = 8'h56;

    @(negedge clk_i);
    check_data(8'h56);
  endtask

  // TC_007: enable high-to-low transition
  task automatic tc_007_enable_high_to_low();
    apply_reset();

    en_i = 1'b1;
    data_i = 8'hAA;

    @(posedge clk_i);
    check_data(8'hAA);

    en_i = 1'b0;
    data_i = 8'h55;

    @(negedge clk_i);
    check_data(8'hAA);

    @(posedge clk_i);
    check_data(8'hAA);
  endtask

  // TC_008: data changes while disabled
  task automatic tc_008_data_change_while_disabled();
    apply_reset();

    en_i = 1'b1;
    data_i = 8'hF0;

    @(posedge clk_i);
    check_data(8'hF0);

    en_i = 1'b0;
    data_i = 8'h01;

    @(negedge clk_i);
    check_data(8'hF0);

    data_i = 8'h02;

    @(posedge clk_i);
    check_data(8'hF0);

    data_i = 8'h03;

    @(negedge clk_i);
    check_data(8'hF0);

    data_i = 8'h04;

    @(posedge clk_i);
    check_data(8'hF0);
  endtask

  // TC_009: asynchronous reset during active operation
  task automatic tc_009_reset_during_operation();
    apply_reset();

    en_i = 1'b1;
    data_i = 8'hDE;

    @(posedge clk_i);
    check_data(8'hDE);

    #2ns;
    arst_ni = 1'b0;
    #1ns;

    if (data_o == 8'h00)
      note_case(1);
    else begin
      note_case(0);
      if (debug)
        $display("[%0t] FAIL: TC_009 async reset data_o=%h expected=00",
                 $time, data_o);
    end

    repeat (2) @(posedge clk_i);
    #1ns;

    if (data_o == 8'h00)
      note_case(1);
    else begin
      note_case(0);
      if (debug)
        $display("[%0t] FAIL: TC_009 reset held data_o=%h expected=00",
                 $time, data_o);
    end

    arst_ni = 1'b1;
  endtask

  // TC_010: asynchronous reset between clock edges
  task automatic tc_010_async_reset_between_edges();
    apply_reset();

    en_i = 1'b1;
    data_i = 8'h7E;

    @(posedge clk_i);
    check_data(8'h7E);

    #2ns;
    arst_ni = 1'b0;
    #1ns;

    if (data_o == 8'h00)
      note_case(1);
    else begin
      note_case(0);
      if (debug)
        $display("[%0t] FAIL: TC_010 reset data_o=%h expected=00",
                 $time, data_o);
    end

    #2ns;
    arst_ni = 1'b1;
  endtask

  // TC_011: repeated positive/negative captures
  task automatic tc_011_repeated_dual_edge_capture();
    apply_reset();

    en_i = 1'b1;

    @(negedge clk_i);
    data_i = 8'h10;

    @(posedge clk_i);
    check_data(8'h10);

    data_i = 8'h20;

    @(negedge clk_i);
    check_data(8'h20);

    data_i = 8'h30;

    @(posedge clk_i);
    check_data(8'h30);

    data_i = 8'h40;

    @(negedge clk_i);
    check_data(8'h40);

    data_i = 8'h50;

    @(posedge clk_i);
    check_data(8'h50);

    data_i = 8'h60;

    @(negedge clk_i);
    check_data(8'h60);

    data_i = 8'h70;

    @(posedge clk_i);
    check_data(8'h70);

    data_i = 8'h80;

    @(negedge clk_i);
    check_data(8'h80);
  endtask

  // TC_012: boundary data values
  task automatic tc_012_boundary_values();
    apply_reset();

    en_i = 1'b1;

    data_i = 8'h00;
    @(posedge clk_i);
    check_data(8'h00);

    data_i = 8'hFF;
    @(negedge clk_i);
    check_data(8'hFF);

    data_i = 8'h80;
    @(posedge clk_i);
    check_data(8'h80);

    data_i = 8'h01;
    @(negedge clk_i);
    check_data(8'h01);

    data_i = 8'hAA;
    @(posedge clk_i);
    check_data(8'hAA);

    data_i = 8'h55;
    @(negedge clk_i);
    check_data(8'h55);
  endtask

  // TC_013: directed pseudo-random dual-edge sequence
  task automatic tc_013_random_sequence();
    logic [WIDTH-1:0] expected_data;

    apply_reset();
    expected_data = 8'h00;

    for (int i = 0; i < 20; i++) begin

      @(negedge clk_i);

      data_i = $urandom();
      en_i = $urandom_range(0, 1);

      if (en_i)
        expected_data = data_i;

      @(posedge clk_i);

      if (data_o == expected_data)
        note_case(1);
      else begin
        note_case(0);
        if (debug)
          $display("[%0t] FAIL: TC_013 POS[%0d] en=%0b data_i=%h data_o=%h expected=%h",
                   $time, i, en_i, data_i, data_o, expected_data);
      end

      data_i = $urandom();
      en_i = $urandom_range(0, 1);

      if (en_i)
        expected_data = data_i;

      @(negedge clk_i);

      if (data_o == expected_data)
        note_case(1);
      else begin
        note_case(0);
        if (debug)
          $display("[%0t] FAIL: TC_013 NEG[%0d] en=%0b data_i=%h data_o=%h expected=%h",
                   $time, i, en_i, data_i, data_o, expected_data);
      end
    end
  endtask

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // FUNCTIONAL COVERAGE
  //////////////////////////////////////////////////////////////////////////////////////////////////

  covergroup cg_dual_edge_register;

    cp_reset: coverpoint arst_ni {
      bins reset_asserted = {1'b0};
      bins reset_released = {1'b1};
    }

    cp_enable: coverpoint en_i {
      bins disabled = {1'b0};
      bins enabled  = {1'b1};
    }

    cp_data: coverpoint data_i {
      bins zero  = {8'h00};
      bins ff    = {8'hFF};
      bins msb   = {8'h80};
      bins lsb   = {8'h01};
      bins aa    = {8'hAA};
      bins bb    = {8'h55};
      bins other = default;
    }

    cp_reset_enable: cross cp_reset, cp_enable;

    cp_enable_data: cross cp_enable, cp_data {
      ignore_bins disabled_ff =
        binsof(cp_enable.disabled) && binsof(cp_data.ff);

      ignore_bins disabled_msb =
        binsof(cp_enable.disabled) && binsof(cp_data.msb);

      ignore_bins disabled_aa =
        binsof(cp_enable.disabled) && binsof(cp_data.aa);
    }

  endgroup

  cg_dual_edge_register cov = new();

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // COVERAGE SAMPLING
  //////////////////////////////////////////////////////////////////////////////////////////////////

  always @(posedge clk_i or negedge clk_i or negedge arst_ni or posedge arst_ni) begin
    cov.sample();
  end

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // TEST SELECTION
  //////////////////////////////////////////////////////////////////////////////////////////////////

  initial begin

    case (test_name)

      "TC_001":
        tc_001_async_reset();

      "TC_002":
        tc_002_posedge_capture();

      "TC_003":
        tc_003_negedge_capture();

      "TC_004":
        tc_004_enable_low_hold();

      "TC_005":
        tc_005_consecutive_dual_edge_capture();

      "TC_006":
        tc_006_enable_low_to_high();

      "TC_007":
        tc_007_enable_high_to_low();

      "TC_008":
        tc_008_data_change_while_disabled();

      "TC_009":
        tc_009_reset_during_operation();

      "TC_010":
        tc_010_async_reset_between_edges();

      "TC_011":
        tc_011_repeated_dual_edge_capture();

      "TC_012":
        tc_012_boundary_values();

      "TC_013":
        tc_013_random_sequence();

      "TC_ALL": begin
        tc_001_async_reset();
        tc_002_posedge_capture();
        tc_003_negedge_capture();
        tc_004_enable_low_hold();
        tc_005_consecutive_dual_edge_capture();
        tc_006_enable_low_to_high();
        tc_007_enable_high_to_low();
        tc_008_data_change_while_disabled();
        tc_009_reset_during_operation();
        tc_010_async_reset_between_edges();
        tc_011_repeated_dual_edge_capture();
        tc_012_boundary_values();
        tc_013_random_sequence();
      end

      default:
        $fatal(1, "\033[1;31mUNKNOWN TEST NAME: %s\033[0m", test_name);

    endcase

    #1ns;

    $display("FUNCTIONAL COVERAGE = %0.2f%%", cov.get_coverage());

    $finish;

  end

endmodule
