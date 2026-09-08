/*

| TEST CASE | TEST NAME                  | DATE       | AUTHOR                       | DESCRIPTION                                                                            |
|-----------|----------------------------|------------|------------------------------|----------------------------------------------------------------------------------------|
| TC_001    | `reset_idle`               | 2026-09-07 | Md. Sakib Hasan Shawon       | Verifies reset behavior and confirms that CLK2 is active after reset.                  |
| TC_002    | `select_clk1`              | 2026-09-07 | Md. Sakib Hasan Shawon       | Verifies CLK1 selection and confirms that clk_o follows CLK1 correctly.                |
| TC_003    | `select_clk2`              | 2026-09-07 | Md. Sakib Hasan Shawon       | Verifies CLK2 selection and confirms that clk_o follows CLK2 correctly.                |
| TC_004    | `switch_clk1_to_clk2`      | 2026-09-07 | Md. Sakib Hasan Shawon       | Verifies clean and glitch-free switching from CLK1 to CLK2.                            |
| TC_005    | `switch_clk2_to_clk1`      | 2026-09-07 | Md. Sakib Hasan Shawon       | Verifies clean and glitch-free switching from CLK2 to CLK1.                            |
| TC_006    | `repeated_switching`       | 2026-09-07 | Md. Sakib Hasan Shawon       | Verifies repeated switching between CLK1 and CLK2 over multiple iterations.            |
| TC_007    | `edge_aligned_switching`   | 2026-09-07 | Md. Sakib Hasan Shawon       | Verifies clock switching behavior when the selection changes near clock edges.         |
| TC_008    | `glitch_detection`         | 2026-09-07 | Md. Sakib Hasan Shawon       | Verifies glitch-free clock switching by detecting runt HIGH pulses on clk_o.           |
| TC_009    | `randomized_switching`     | 2026-09-07 | Md. Sakib Hasan Shawon       | Verifies clock mux behavior during randomized clock selection transitions.             |
| TC_010    | `source_tracking`          | 2026-09-07 | Md. Sakib Hasan Shawon       | Verifies that clk_o correctly tracks the selected CLK1 and CLK2 sources.               |
| TC_011    | `reset_during_operation`   | 2026-09-07 | Md. Sakib Hasan Shawon       | Verifies reset behavior during active operation and confirms CLK2 recovery after reset.|
| --------- | `all`                      | 2026-09-07 | Md. Sakib Hasan Shawon       | Runs the complete clock mux regression test suite.                                     |

| REVISION | DATE       | AUTHOR          | DESCRIPTION                                            |
|----------|------------|-----------------|--------------------------------------------------------|
| 0.1      | 2026-09-07 | Md. Sakib Hasan Shawon | Initial version                                 |
| 1.0      | 2026-09-07 | Md. Sakib Hasan Shawon | Stable release                                  |

Author : Md. Sakib Hasan Shawon (mdsakibhasanshawon20@gmail.com)
This file is part of ADN-VLSI/adn_clk_rst
Copyright (c) 2026 ADN Semiconductors
Licensed under the MIT License
See LICENSE file in the project root for full license information

*/

module adn_clk_rst_clk_mux_tb;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // IMPORTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // bring in the testbench essentials functions and macros
  `include "vip/adn_common_tb_headers.sv"

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // LOCALPARAMS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Clock periods used to create two asynchronous clock domains.
  localparam time CLK1_PERIOD = 10ns;
  localparam time CLK2_PERIOD = 14ns;

  // Number of synchronizer stages configured in the DUT.
  localparam int SYNC_STAGES = 2;

  // Number of clock cycles allowed for the clock selection logic to settle.
  localparam int SETTLE_CYCLES = (SYNC_STAGES * 3) + 4;

  // Minimum legal HIGH-pulse width used by the glitch monitor.
  localparam time MIN_HIGH_PULSE = 2ns;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  logic clk1_i;
  logic clk2_i;
  logic sel_i;
  logic arst_ni;
  logic clk_o;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // VARIABLES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Used to detect changes in the clock selection input.
  logic prev_sel;
  logic switch_event;

  // Used by the output pulse-width monitor.
  time high_start_time;
  time high_width;

  // Number of detected runt HIGH pulses.
  int high_pulse_errors;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Instantiate the clock mux DUT.
  adn_clk_rst_clk_mux #(
      .SYNC_STAGES(SYNC_STAGES)
  ) dut (
      .clk1_i (clk1_i),
      .clk2_i (clk2_i),
      .sel_i  (sel_i),
      .arst_ni(arst_ni),
      .clk_o  (clk_o)
  );
  
  //////////////////////////////////////////////////////////////////////////////////////////////////
  // COVERGROUPS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Functional coverage for clock selection, reset state, output state, and switch activity.
  covergroup cg_clk_mux with function sample (
      input logic sel,
      input logic rst_n,
      input logic clk_out,
      input logic switched
  );

    // Verify that both clock selections are exercised.
    sel_cp: coverpoint sel {
      bins clk2 = {1'b0};
      bins clk1 = {1'b1};
    }

    // Verify both reset states are exercised.
    reset_cp: coverpoint rst_n {
      bins reset_active   = {1'b0};
      bins reset_inactive = {1'b1};
    }

    // Verify both output states are observed.
    output_cp: coverpoint clk_out {
      bins low  = {1'b0};
      bins high = {1'b1};
    }

    // Track whether a clock-selection transition occurred.
    switch_cp: coverpoint switched {
      bins no_switch = {1'b0};
      bins switch    = {1'b1};
    }

    // Cross clock selection with reset state.
    sel_reset_cross: cross sel_cp, reset_cp;

    // Cross clock selection with switch activity.
    sel_switch_cross: cross sel_cp, switch_cp;

  endgroup

  // Functional coverage for both possible clock-switch directions.
  covergroup cg_switch_direction with function sample (
      input logic old_sel,
      input logic new_sel
  );

    direction_cp: coverpoint {
      old_sel, new_sel
    } {

      // CLK2 -> CLK1.
      bins clk2_to_clk1 = {2'b01};

      // CLK1 -> CLK2.
      bins clk1_to_clk2 = {2'b10};

      // Ignore cases where the selection does not change.
      ignore_bins no_switch_clk2 = {2'b00};
      ignore_bins no_switch_clk1 = {2'b11};
    }

  endgroup

  // Instantiate coverage objects.
  cg_clk_mux          clk_mux_cov = new();
  cg_switch_direction switch_cov  = new();

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // METHODS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Generate CLK1 with a 10 ns period.
  initial begin
    clk1_i = 1'b0;

    forever begin
      #(CLK1_PERIOD / 2);
      clk1_i = ~clk1_i;
    end
  end

  // Generate CLK2 with a 14 ns period and a 3 ns initial phase offset.
  initial begin
    clk2_i = 1'b0;

    #3ns;

    forever begin
      #(CLK2_PERIOD / 2);
      clk2_i = ~clk2_i;
    end
  end

  // Detect changes on the clock-selection input and sample switch-direction coverage.
  initial begin
    prev_sel = 1'b0;

    forever begin
      @(sel_i);

      if (sel_i !== prev_sel) begin
        switch_event = 1'b1;

        switch_cov.sample(prev_sel, sel_i);

        prev_sel = sel_i;
      end
    end
  end

  // Sample general functional coverage on CLK1 rising edges.
  initial begin
    forever begin
      @(posedge clk1_i);

      clk_mux_cov.sample(
          sel_i,
          arst_ni,
          clk_o,
          switch_event
      );

      switch_event = 1'b0;
    end
  end

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // RESET / UTILITY TASKS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Apply reset and allow the DUT synchronizer logic to initialize.
  task automatic reset_dut();

    begin
      sel_i   = 1'b0;
      arst_ni = 1'b0;

      // Hold reset for three CLK1 cycles.
      repeat (3) @(posedge clk1_i);

      arst_ni = 1'b1;

      // Allow synchronization and clock-selection logic to settle.
      repeat (SYNC_STAGES + 2) @(posedge clk1_i);

      #1;
    end

  endtask

  // Wait until the clock-selection logic has had sufficient time to settle.
  task automatic wait_for_settle();

    begin
      repeat (SETTLE_CYCLES) begin
        @(posedge clk1_i);
        @(posedge clk2_i);
      end

      #1;
    end

  endtask

  // Check that the clock output is LOW.
  task automatic check_output_low(input string case_name);

    begin
      #1;

      if (clk_o === 1'b0) begin
        $display(
            "PASS: %-45s | clk_o=%b",
            case_name,
            clk_o
        );

        note_case(1'b1);
      end else begin
        $display(
            "FAIL: %-45s | clk_o=%b",
            case_name,
            clk_o
        );

        note_case(1'b0);
      end
    end

  endtask

  // Verify that CLK1 is correctly propagated to the output.
  task automatic verify_clk1_active(input string case_name);

    int errors;

    begin
      errors = 0;

      repeat (8) begin

        @(posedge clk1_i);
        #1;

        if (clk_o !== 1'b1)
          errors++;

        @(negedge clk1_i);
        #1;

        if (clk_o !== 1'b0)
          errors++;

      end

      if (errors == 0) begin
        $display(
            "PASS: %-45s | clk_o follows clk1",
            case_name
        );

        note_case(1'b1);
      end else begin
        $display(
            "FAIL: %-45s | clk1 tracking errors=%0d",
            case_name,
            errors
        );

        note_case(1'b0);
      end
    end

  endtask

  // Verify that CLK2 is correctly propagated to the output.
  task automatic verify_clk2_active(input string case_name);

    int errors;

    begin
      errors = 0;

      repeat (8) begin

        @(posedge clk2_i);
        #1;

        if (clk_o !== 1'b1)
          errors++;

        @(negedge clk2_i);
        #1;

        if (clk_o !== 1'b0)
          errors++;

      end

      if (errors == 0) begin
        $display(
            "PASS: %-45s | clk_o follows clk2",
            case_name
        );

        note_case(1'b1);
      end else begin
        $display(
            "FAIL: %-45s | clk2 tracking errors=%0d",
            case_name,
            errors
        );

        note_case(1'b0);
      end
    end

  endtask

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // GLITCH MONITOR
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Monitor every HIGH pulse on clk_o and flag pulses shorter than the minimum width.
  initial begin
    high_start_time   = 0;
    high_width        = 0;
    high_pulse_errors = 0;

    forever begin
      @(posedge clk_o);

      high_start_time = $time;

      @(negedge clk_o);

      high_width = $time - high_start_time;

      if (high_width > 0 && high_width < MIN_HIGH_PULSE) begin

        high_pulse_errors++;

        $display(
            "ERROR: RUNT HIGH PULSE | width=%0t | time=%0t",
            high_width,
            $time
        );

      end
    end
  end

  // Report the result of the glitch monitor.
  task automatic check_glitch_monitor(input string case_name);

    begin
      #1;

      if (high_pulse_errors == 0) begin
        $display(
            "PASS: %-45s | no runt HIGH pulses",
            case_name
        );

        note_case(1'b1);
      end else begin
        $display(
            "FAIL: %-45s | runt HIGH pulses=%0d",
            case_name,
            high_pulse_errors
        );

        note_case(1'b0);
      end
    end

  endtask

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // TEST CASES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // TC_001: Verify reset behavior and default CLK2 operation.
  task automatic test_1_reset_idle();

    $display("\n========== TEST 1: RESET / IDLE ==========");

    arst_ni = 1'b0;
    sel_i   = 1'b0;

    #1;

    if (clk_o === 1'b0) begin
      $display(
          "PASS: TEST 1.1: output disabled during reset | clk_o=%b",
          clk_o
      );

      note_case(1'b1);
    end else begin
      $display(
          "FAIL: TEST 1.1: output not disabled during reset | clk_o=%b",
          clk_o
      );

      note_case(1'b0);
    end

    arst_ni = 1'b1;

    wait_for_settle();

    verify_clk2_active("TEST 1.2: CLK2 active after reset");

  endtask

  // TC_002: Verify CLK1 can be selected and propagated.
  task automatic test_2_select_clk1();

    $display("\n========== TEST 2: SELECT CLK1 ==========");

    reset_dut();

    sel_i = 1'b1;

    wait_for_settle();

    verify_clk1_active("TEST 2: CLK1 selected");

  endtask

  // TC_003: Verify CLK2 can be selected and propagated.
  task automatic test_3_select_clk2();

    $display("\n========== TEST 3: SELECT CLK2 ==========");

    reset_dut();

    sel_i = 1'b0;

    wait_for_settle();

    verify_clk2_active("TEST 3: CLK2 selected");

  endtask

  // TC_004: Verify a clean transition from CLK1 to CLK2.
  task automatic test_4_switch_clk1_to_clk2();

    $display("\n========== TEST 4: CLK1 -> CLK2 ==========");

    reset_dut();

    sel_i = 1'b1;

    wait_for_settle();

    verify_clk1_active("TEST 4.1: CLK1 before switch");

    #2.3ns;

    sel_i = 1'b0;

    wait_for_settle();

    verify_clk2_active("TEST 4.2: CLK2 after switch");

  endtask

  // TC_005: Verify a clean transition from CLK2 to CLK1.
  task automatic test_5_switch_clk2_to_clk1();

    $display("\n========== TEST 5: CLK2 -> CLK1 ==========");

    reset_dut();

    sel_i = 1'b0;

    wait_for_settle();

    verify_clk2_active("TEST 5.1: CLK2 before switch");

    #4.7ns;

    sel_i = 1'b1;

    wait_for_settle();

    verify_clk1_active("TEST 5.2: CLK1 after switch");

  endtask

  // TC_006: Repeatedly switch between CLK1 and CLK2.
  task automatic test_6_repeated_switching();

    $display("\n========== TEST 6: REPEATED SWITCHING ==========");

    reset_dut();

    for (int i = 0; i < 6; i++) begin

      if ((i % 2) == 0) begin

        sel_i = 1'b1;

        wait_for_settle();

        verify_clk1_active(
            $sformatf(
                "TEST 6.%0d: iteration %0d CLK1",
                i + 1,
                i + 1
            )
        );

      end else begin

        sel_i = 1'b0;

        wait_for_settle();

        verify_clk2_active(
            $sformatf(
                "TEST 6.%0d: iteration %0d CLK2",
                i + 1,
                i + 1
            )
        );

      end

    end

  endtask

  // TC_007: Change clock selection immediately after source-clock rising edges.
  task automatic test_7_edge_aligned_switching();

    $display("\n========== TEST 7: EDGE-ALIGNED SWITCHING ==========");

    reset_dut();

    sel_i = 1'b1;

    wait_for_settle();

    // Switch shortly after CLK1 rising edge.
    @(posedge clk1_i);
    #1ps;

    sel_i = 1'b0;

    wait_for_settle();

    verify_clk2_active(
        "TEST 7.1: switch near CLK1 rising edge"
    );

    // Switch shortly after CLK2 rising edge.
    @(posedge clk2_i);
    #1ps;

    sel_i = 1'b1;

    wait_for_settle();

    verify_clk1_active(
        "TEST 7.2: switch near CLK2 rising edge"
    );

  endtask

  // TC_008: Perform multiple switches and verify that no runt HIGH pulses occur.
  task automatic test_8_glitch_detection();

    $display("\n========== TEST 8: GLITCH DETECTION ==========");

    reset_dut();

    high_pulse_errors = 0;

    sel_i = 1'b1;

    wait_for_settle();

    #1.7ns;

    sel_i = 1'b0;

    wait_for_settle();

    #3.1ns;

    sel_i = 1'b1;

    wait_for_settle();

    #2.2ns;

    sel_i = 1'b0;

    wait_for_settle();

    check_glitch_monitor(
        "TEST 8: glitch-free switching"
    );

  endtask

  // TC_009: Randomly change the selected clock and monitor for runt pulses.
  task automatic test_9_randomized_switching();

    int random_delay;

    $display("\n========== TEST 9: RANDOMIZED SWITCHING ==========");

    reset_dut();

    high_pulse_errors = 0;

    for (int i = 0; i < 20; i++) begin

      random_delay = $urandom_range(1, 17);

      #(random_delay * 1ns);

      sel_i = $urandom_range(0, 1);

      $display(
          "INFO: TEST 9.%0d | sel_i=%b | delay=%0dns",
          i + 1,
          sel_i,
          random_delay
      );

      wait_for_settle();

    end

    check_glitch_monitor(
        "TEST 9: randomized switching"
    );

  endtask

  // TC_010: Verify output tracking for both clock sources.
  task automatic test_10_source_tracking();

    int errors;

    $display("\n========== TEST 10: SOURCE TRACKING ==========");

    reset_dut();

    errors = 0;

    // Verify CLK1 tracking.
    sel_i = 1'b1;

    wait_for_settle();

    repeat (10) begin

      @(posedge clk1_i);
      #1;

      if (clk_o !== 1'b1)
        errors++;

      @(negedge clk1_i);
      #1;

      if (clk_o !== 1'b0)
        errors++;

    end

    // Verify CLK2 tracking.
    sel_i = 1'b0;

    wait_for_settle();

    repeat (10) begin

      @(posedge clk2_i);
      #1;

      if (clk_o !== 1'b1)
        errors++;

      @(negedge clk2_i);
      #1;

      if (clk_o !== 1'b0)
        errors++;

    end

    if (errors == 0) begin
      $display("PASS: TEST 10: source tracking");
      note_case(1'b1);
    end else begin
      $display(
          "FAIL: TEST 10: source tracking errors=%0d",
          errors
      );

      note_case(1'b0);
    end

  endtask

  // TC_011: Assert reset while CLK1 is active and verify recovery to CLK2.
  task automatic test_11_reset_during_operation();

    $display("\n========== TEST 11: RESET DURING OPERATION ==========");

    reset_dut();

    sel_i = 1'b1;

    wait_for_settle();

    verify_clk1_active(
        "TEST 11.1: CLK1 active before reset"
    );

    #2.5ns;

    // Assert asynchronous reset while the mux is operating.
    arst_ni = 1'b0;

    #1;

    repeat (3) @(posedge clk1_i);

    #1;

    if (clk_o === 1'b0) begin
      $display(
          "PASS: TEST 11.2: output disabled by reset"
      );

      note_case(1'b1);
    end else begin
      $display(
          "FAIL: TEST 11.2: output still active during reset | clk_o=%b",
          clk_o
      );

      note_case(1'b0);
    end

    // Release reset and select CLK2.
    arst_ni = 1'b1;
    sel_i   = 1'b0;

    wait_for_settle();

    verify_clk2_active(
        "TEST 11.3: CLK2 resumes after reset"
    );

  endtask

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // PROCEDURALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Main testbench procedure.
  initial begin

    // Initialize testbench inputs and monitor state.
    sel_i       = 1'b0;
    arst_ni     = 1'b0;
    switch_event = 1'b0;

    $display("\n");
    $display("============================================================");
    $display("             ADN CLOCK MUX TESTBENCH");
    $display("============================================================");
    $display("CLK1_PERIOD  = %0t", CLK1_PERIOD);
    $display("CLK2_PERIOD  = %0t", CLK2_PERIOD);
    $display("SYNC_STAGES  = %0d", SYNC_STAGES);
    $display("SETTLE_CYCLES = %0d", SETTLE_CYCLES);
    $display("============================================================");

    // Execute the requested test case.
    case (test_name)

      "TC_001", "reset_idle":
        test_1_reset_idle();

      "TC_002", "select_clk1":
        test_2_select_clk1();

      "TC_003", "select_clk2":
        test_3_select_clk2();

      "TC_004", "switch_clk1_to_clk2":
        test_4_switch_clk1_to_clk2();

      "TC_005", "switch_clk2_to_clk1":
        test_5_switch_clk2_to_clk1();

      "TC_006", "repeated_switching":
        test_6_repeated_switching();

      "TC_007", "edge_aligned_switching":
        test_7_edge_aligned_switching();

      "TC_008", "glitch_detection":
        test_8_glitch_detection();

      "TC_009", "randomized_switching":
        test_9_randomized_switching();

      "TC_010", "source_tracking":
        test_10_source_tracking();

      "TC_011", "reset_during_operation":
        test_11_reset_during_operation();

      // TC_012 runs the complete regression.
      "TC_012", "TC_ALL", "all", "default": begin

        test_1_reset_idle();
        test_2_select_clk1();
        test_3_select_clk2();
        test_4_switch_clk1_to_clk2();
        test_5_switch_clk2_to_clk1();
        test_6_repeated_switching();
        test_7_edge_aligned_switching();
        test_8_glitch_detection();
        test_9_randomized_switching();
        test_10_source_tracking();
        test_11_reset_during_operation();

      end

    endcase

    // Print final test and coverage summary.
    $display("\n");
    $display("============================================================");
    $display("              CLOCK MUX TEST COMPLETE");
    $display("============================================================");

    $display(
        "FUNCTIONAL COVERAGE: clk_mux=%0.2f%%, switch_direction=%0.2f%%",
        clk_mux_cov.get_inst_coverage(),
        switch_cov.get_inst_coverage()
    );

    if (clk_mux_cov.get_inst_coverage() < 100.0 ||
        switch_cov.get_inst_coverage() < 100.0) begin

      $display("WARNING: Functional coverage is below 100%%");

    end else begin

      $display("FUNCTIONAL COVERAGE: 100%%");

    end

    // End simulation.
    $finish;

  end

endmodule
