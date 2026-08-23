/*

| TEST CASE                   | DATE       | AUTHOR       | DESCRIPTION                                                             |
|-----------------------------|------------|--------------|-------------------------------------------------------------------------|
| TC_RST_01                   | 2026-08-23 | Annim Jannat | Asynchronous reset assertion with div_i idle (no counting yet)          |
| TC_RST_02                   | 2026-08-23 | Annim Jannat | Asynchronous reset asserted mid-count (counter and clk_o mid-toggle)    |
| TC_RST_03                   | 2026-08-23 | Annim Jannat | Reset release timing swept across clk_i edge phases                     |
| TC_DIV_ZERO_01              | 2026-08-23 | Annim Jannat | div_i == 0: division disabled, counter locked at 0                      |
| TC_DIV_ONE_01               | 2026-08-23 | Annim Jannat | div_i == 1: minimum active division ratio                               |
| TC_DIV_TWO_01               | 2026-08-23 | Annim Jannat | div_i == 2: smallest even division ratio                                |
| TC_DIV_ODD_01               | 2026-08-23 | Annim Jannat | div_i == 3: odd ratio, duty-cycle correctness check                     |
| TC_DIV_ODD_02               | 2026-08-23 | Annim Jannat | div_i == 5: odd ratio, duty-cycle correctness check                     |
| TC_DIV_EVEN_01              | 2026-08-23 | Annim Jannat | div_i == 4: even ratio baseline sanity check                            |
| TC_DIV_MAX_01               | 2026-08-23 | Annim Jannat | div_i at max representable value: overflow/wraparound check             |
| TC_DIV_CHANGE_MIDCOUNT_01   | 2026-08-23 | Annim Jannat | div_i changed while counter is mid-count, glitch check                  |
| TC_DIV_CHANGE_TO_ZERO_01    | 2026-08-23 | Annim Jannat | div_i changed from nonzero to 0 and back, clean disable/re-enable       |
| TC_DIV_RAPID_TOGGLE_01      | 2026-08-23 | Annim Jannat | div_i changed on every edge, combinational glitch stress                |
| TC_DUTY_CYCLE_SWEEP_01      | 2026-08-23 | Annim Jannat | Sweep div_i (odd + even) and measure clk_o duty cycle vs 50% tolerance  |
| TC_GLITCH_CHECK_01          | 2026-08-23 | Annim Jannat | Check for runt pulses / unintended toggles on clk_o                     |
| TC_RANDOM_01                | 2026-08-23 | Annim Jannat | Fully randomized div_i + reset injection stress test vs reference model |
| TC_ALL                      | 2026-08-23 | Annim Jannat | Default regression suite executing all test scenarios sequentially      |

| REVISION   | DATE       | AUTHOR       | DESCRIPTION     |
|------------|------------|--------------|-----------------|
| 0.1        | 2026-08-23 | Annim Jannat | Initial version |

Author : Annim Jannat (jannatannim@gmail.com)
This file is part of ADN-VLSI/adn_clk_rst
Copyright (c) 2026 ADN Semiconductors
Licensed under the MIT License
See LICENSE file in the project root for full license information

*/

module adn_clk_rst_clk_div_tb;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // IMPORTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // bring in the testbench essentials functions and macros
  `include "vip/adn_common_tb_headers.sv"

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // LOCALPARAMS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  localparam time CLKPeriod = 10ns;
  localparam int  DIV_WIDTH = 4;
  localparam real DUTY_TOL_PCT = 5.0;  // allowed deviation from 50% duty, in percentage points

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  logic                  clk_i;
  logic                  arst_n;

  logic [DIV_WIDTH-1:0]  div_i;
  logic                  clk_o;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // VARIABLES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  bit                     is_clk_edge_aligned;

  // reference model state
  logic [DIV_WIDTH-1:0]  ref_counter_q;
  logic                   ref_clk_o;

  // bookkeeping
  int unsigned            toggle_check_count;
  int unsigned            div_change_count;

  // duty-cycle / glitch monitor state (driven off the DUT's own clk_o)
  real                    last_edge_time;
  real                    high_time_accum;
  real                    low_time_accum;
  int unsigned            edge_count;
  real                    min_pulse_width;
  logic                   monitor_last_val;
  bit                     monitor_active;

  // scratch variables used by the fork'd checking/monitor loops
  // (module-scope instead of inline "automatic" locals for simulator stability)
  real                    now_scratch_v;
  real                    width_scratch_v;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  adn_clk_rst_clk_div #(
      .DIV_WIDTH(DIV_WIDTH)
  ) u_dut (
      .arst_ni (arst_n),
      .clk_i   (clk_i),
      .div_i   (div_i),
      .clk_o   (clk_o)
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SEQUENTIALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  always @(posedge clk_i) begin
    is_clk_edge_aligned <= arst_n;
    #1ns;
    is_clk_edge_aligned <= '0;
  end

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // METHODS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Assert/deassert arst_n mid-test WITHOUT re-driving clk_i (clk_i is owned
  // exclusively by start_clock()'s free-running process)
  task automatic pulse_reset(input time low_time);
    arst_n <= '0;
    #(low_time);
    arst_n <= '1;
  endtask

  // Task to apply reset (does NOT drive clk_i)
  task automatic apply_reset();
    #100ns;
    arst_n              <= '0;
    div_i                <= '0;
    ref_counter_q        <= '0;
    ref_clk_o             <= '0;
    toggle_check_count    <= '0;
    div_change_count      <= '0;
    high_time_accum       <= 0.0;
    low_time_accum        <= 0.0;
    edge_count            <= '0;
    min_pulse_width        <= 1.0e9;
    monitor_last_val      <= '0;
    monitor_active        <= '0;
    // NOTE: low-period is deliberately NOT a multiple of CLKPeriod (10ns).
    // Releasing arst_n exactly on a clk_i edge boundary creates a
    // simulator event-ordering race between the DUT's and the reference
    // model's reset-release processing, which can leave them one edge
    // out of phase for that reset cycle. Using 97ns keeps the reset
    // comfortably longer than several clk_i periods while landing the
    // release mid-period, away from any clk_i edge.
    #97ns;
    arst_n              <= '1;
    #100ns;
  endtask

  task automatic start_clock();
    fork
      forever #(CLKPeriod / 2) clk_i <= ~clk_i;
    join_none
    @(posedge clk_i);
  endtask

  // Set div_i on a clean posedge-aligned window (control signal, sampled on
  // every clk_i edge internally, but we drive it from a stable point)
  task automatic set_div(input logic [DIV_WIDTH-1:0] val);
    wait (is_clk_edge_aligned);
    div_i <= val;
    div_change_count <= div_change_count + 1;
    @(posedge clk_i);
  endtask

  // Change div_i without waiting for edge alignment - used to intentionally
  // land the change mid-count / near an edge for corner-case tests
  task automatic set_div_async(input logic [DIV_WIDTH-1:0] val);
    div_i <= val;
    div_change_count <= div_change_count + 1;
  endtask

  // Hold current state for N full clk_i periods
  task automatic hold_cycles(input int n);
    repeat (n) @(posedge clk_i);
  endtask

  // Hold current state for N half-periods (edges), needed since the DUT
  // reacts on BOTH edges of clk_i
  task automatic hold_edges(input int n);
    repeat (n) @(clk_i);
  endtask

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // REFERENCE MODEL + CHECKING
  //////////////////////////////////////////////////////////////////////////////////////////////////

  task automatic start_checking();
    // -----------------------------------------------------------------
    // LOOP A - reference model state update. Reacts on BOTH edges of
    // clk_i (dual-edge design) plus async reset, mirroring the DUT's
    // own behavior. toggle_en is combinational from the CURRENT
    // ref_counter_q value, and ref_clk_o toggles on the SAME edge as
    // the counter update (standard synchronous flop timing - both
    // registers are clocked together off the same counter_q sample).
    // Previously this was split into two registered stages (capture
    // toggle_en on one edge, apply it on the next), which produced a
    // persistent one-edge phase inversion against the DUT. Collapsing
    // to a single process fixes that.
    // -----------------------------------------------------------------
    fork
      forever
      @(clk_i or negedge arst_n) begin
        if (~arst_n) begin
          ref_counter_q <= '0;
          ref_clk_o     <= '0;
        end else begin
          if (ref_counter_q == '0) begin
            ref_clk_o <= ~ref_clk_o;
          end

          if (div_i == '0) begin
            ref_counter_q <= '0;
          end else if (ref_counter_q == (div_i - 1'b1)) begin
            ref_counter_q <= '0;
          end else begin
            ref_counter_q <= ref_counter_q + 1'b1;
          end
        end
      end
    join_none

    // -----------------------------------------------------------------
    // LOOP B - comparison/checking, also on any clk_i change. A short
    // settle delay is safe here since LOOP A has already advanced its
    // state for this same edge by the time LOOP B wakes.
    // -----------------------------------------------------------------
    fork
      forever
      @(clk_i) begin
        #0.5ns;  // let DUT combinational/registered outputs settle after the edge

        if (arst_n) begin
          if (clk_o !== ref_clk_o) begin
            note_case(0);
            $display("[%s] FAIL [%0t] clk_o mismatch: exp=%b got=%b (ref_counter=%0d div_i=%0d)",
                      test_name, $realtime, ref_clk_o, clk_o, ref_counter_q, div_i);
          end else begin
            note_case(1);
          end
          toggle_check_count <= toggle_check_count + 1;
        end
      end
    join_none

    // -----------------------------------------------------------------
    // LOOP C - clk_o edge monitor for duty-cycle and glitch checks.
    // Independent of the reference model; purely measures the DUT's
    // own output transitions and timing. Uses pre-declared module-scope
    // scratch variables instead of inline "automatic" locals.
    // -----------------------------------------------------------------
    fork
      forever
      @(clk_o) begin
        now_scratch_v = $realtime;
        if (monitor_active) begin
          width_scratch_v = now_scratch_v - last_edge_time;
          if (width_scratch_v < min_pulse_width) begin
            min_pulse_width <= width_scratch_v;
          end
          if (monitor_last_val) begin
            high_time_accum <= high_time_accum + width_scratch_v;
          end else begin
            low_time_accum <= low_time_accum + width_scratch_v;
          end
          edge_count <= edge_count + 1;
        end
        monitor_last_val <= clk_o;
        last_edge_time   <= now_scratch_v;
        monitor_active   <= '1;
      end
    join_none
  endtask

  // Reset duty-cycle/glitch monitor accumulators before a fresh measurement window
  task automatic reset_monitor();
    high_time_accum  <= 0.0;
    low_time_accum   <= 0.0;
    edge_count        <= '0;
    min_pulse_width   <= 1.0e9;
    monitor_active    <= '0;
  endtask

  // Report duty cycle for the accumulated window; flags if outside tolerance
  task automatic report_duty_cycle(input logic [DIV_WIDTH-1:0] div_val);
    automatic real total = high_time_accum + low_time_accum;
    automatic real duty_pct;
    if (total <= 0.0 || edge_count < 4) begin
      $display("[%s] INFO [%0t] duty-cycle: insufficient edges captured for div_i=%0d", test_name, $realtime, div_val);
      return;
    end
    duty_pct = 100.0 * (high_time_accum / total);
    if ((duty_pct < (50.0 - DUTY_TOL_PCT)) || (duty_pct > (50.0 + DUTY_TOL_PCT))) begin
      note_case(0);
      $display("[%s] FAIL [%0t] duty-cycle out of tolerance for div_i=%0d: %0.2f%% (expected ~50%%)",
                test_name, $realtime, div_val, duty_pct);
    end else begin
      note_case(1);
      $display("[%s] INFO [%0t] duty-cycle OK for div_i=%0d: %0.2f%%", test_name, $realtime, div_val, duty_pct);
    end
  endtask

  // Report min observed clk_o pulse width; flags if shorter than one clk_i half-period
  task automatic report_min_pulse();
    automatic real half_period_ns = real'(CLKPeriod) / 2.0;
    if (edge_count < 2) begin
      $display("[%s] INFO [%0t] glitch-check: insufficient edges captured", test_name, $realtime);
      return;
    end
    if (min_pulse_width < half_period_ns) begin
      note_case(0);
      $display("[%s] FAIL [%0t] runt pulse detected on clk_o: width=%0.2fns < half-period=%0.2fns",
                test_name, $realtime, min_pulse_width, half_period_ns);
    end else begin
      note_case(1);
      $display("[%s] INFO [%0t] no runt pulses detected, min width=%0.2fns", test_name, $realtime, min_pulse_width);
    end
  endtask

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // TEST CASES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  task automatic run_tc_rst_01();
    apply_reset();
    set_div(8'd0);
    hold_cycles(3);
  endtask

  task automatic run_tc_rst_02();
    apply_reset();
    set_div(8'd3);
    hold_cycles(5);
    pulse_reset(CLKPeriod);
    hold_cycles(3);
  endtask

  task automatic run_tc_rst_03();
    apply_reset();
    set_div(8'd4);
    hold_cycles(2);
    // sweep reset release phase relative to clk_i edges
    pulse_reset(1ns);
    hold_cycles(2);
    pulse_reset(2ns);
    hold_cycles(2);
    pulse_reset(CLKPeriod / 2);
    hold_cycles(2);
    pulse_reset(CLKPeriod);
    hold_cycles(3);
  endtask

  task automatic run_tc_div_zero_01();
    apply_reset();
    set_div(8'd0);
    hold_cycles(8);
  endtask

  task automatic run_tc_div_one_01();
    apply_reset();
    reset_monitor();
    set_div(8'd1);
    hold_cycles(10);
    report_duty_cycle(8'd1);
  endtask

  task automatic run_tc_div_two_01();
    apply_reset();
    reset_monitor();
    set_div(8'd2);
    hold_cycles(10);
    report_duty_cycle(8'd2);
  endtask

  task automatic run_tc_div_odd_01();
    apply_reset();
    reset_monitor();
    set_div(8'd3);
    hold_cycles(12);
    report_duty_cycle(8'd3);
  endtask

  task automatic run_tc_div_odd_02();
    apply_reset();
    reset_monitor();
    set_div(8'd5);
    hold_cycles(16);
    report_duty_cycle(8'd5);
  endtask

  task automatic run_tc_div_even_01();
    apply_reset();
    reset_monitor();
    set_div(8'd4);
    hold_cycles(40);  // widened from 14: gives ~10 clk_o periods instead of ~3.5,
                       // so one boundary/partial pulse no longer dominates the ratio
    report_duty_cycle(8'd4);
  endtask

  task automatic run_tc_div_max_01();
    apply_reset();
    reset_monitor();
    set_div({DIV_WIDTH{1'b1}});
    hold_cycles(4 * (2 ** DIV_WIDTH < 400 ? 2 ** DIV_WIDTH : 400));
    report_duty_cycle({DIV_WIDTH{1'b1}});
  endtask

  task automatic run_tc_div_change_midcount_01();
    apply_reset();
    set_div(8'd6);
    hold_edges(5);            // land mid-count (not on an aligned boundary)
    set_div_async(8'd3);
    hold_cycles(3);
    @(posedge clk_i);
    set_div_async(8'd7);
    hold_cycles(4);
  endtask

  task automatic run_tc_div_change_to_zero_01();
    apply_reset();
    set_div(8'd4);
    hold_cycles(4);
    set_div(8'd0);
    hold_cycles(4);
    set_div(8'd4);
    hold_cycles(4);
  endtask

  task automatic run_tc_div_rapid_toggle_01();
    apply_reset();
    for (int i = 0; i < 20; i++) begin
      set_div_async($urandom_range(0, 7));
      @(posedge clk_i);
    end
    set_div(8'd4);
    hold_cycles(4);
  endtask

  task automatic run_tc_duty_cycle_sweep_01();
    apply_reset();
    begin
      automatic logic [DIV_WIDTH-1:0] sweep_vals[8] = '{1, 2, 3, 4, 5, 6, 7, 8};
      for (int i = 0; i < 8; i++) begin
        reset_monitor();
        set_div(sweep_vals[i]);
        // ~10 clk_o periods worth of clk_i cycles per bin (widened from ~4-5)
        // so a single boundary/partial pulse doesn't dominate the ratio
        hold_cycles(8 * sweep_vals[i] + 8);
        report_duty_cycle(sweep_vals[i]);
      end
    end
  endtask

  task automatic run_tc_glitch_check_01();
    apply_reset();
    reset_monitor();
    set_div(8'd3);
    hold_cycles(10);
    set_div(8'd6);
    hold_cycles(10);
    set_div(8'd1);
    hold_cycles(10);
    report_min_pulse();
  endtask

  task automatic run_tc_random_01();
    apply_reset();
    reset_monitor();
    for (int i = 0; i < 60; i++) begin
      if ($urandom_range(0, 9) == 0) begin
        pulse_reset($urandom_range(1, CLKPeriod));
      end else begin
        set_div($urandom_range(0, 15));
        hold_cycles($urandom_range(1, 4));
      end
    end
    hold_cycles(4);
  endtask

  task automatic run_tc_all();
    run_tc_rst_01();
    run_tc_rst_02();
    run_tc_rst_03();
    run_tc_div_zero_01();
    run_tc_div_one_01();
    run_tc_div_two_01();
    run_tc_div_odd_01();
    run_tc_div_odd_02();
    run_tc_div_even_01();
    run_tc_div_max_01();
    run_tc_div_change_midcount_01();
    run_tc_div_change_to_zero_01();
    run_tc_div_rapid_toggle_01();
    run_tc_duty_cycle_sweep_01();
    run_tc_glitch_check_01();
    run_tc_random_01();
  endtask

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // PROCEDURALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  initial begin

    // Initialize clk_i exactly once here - never assigned anywhere else.
    // start_clock()'s free-running process takes over from this point on.
    clk_i = '0;

    apply_reset();

    // NOTE: start_checking() (which arms the reference-model and checker
    // fork'd processes on @(clk_i ...)) must be called BEFORE
    // start_clock() begins toggling clk_i. start_clock() itself blocks
    // on the first posedge clk_i before returning; if start_checking()
    // were called after that, the checker's trigger wouldn't be armed
    // yet when the very first clk_i edge fires, causing the reference
    // model to permanently miss/lag that first edge relative to the DUT.
    start_checking();

    start_clock();

    case (test_name)
      "TC_RST_01":                  run_tc_rst_01();
      "TC_RST_02":                  run_tc_rst_02();
      "TC_RST_03":                  run_tc_rst_03();
      "TC_DIV_ZERO_01":             run_tc_div_zero_01();
      "TC_DIV_ONE_01":              run_tc_div_one_01();
      "TC_DIV_TWO_01":              run_tc_div_two_01();
      "TC_DIV_ODD_01":              run_tc_div_odd_01();
      "TC_DIV_ODD_02":              run_tc_div_odd_02();
      "TC_DIV_EVEN_01":             run_tc_div_even_01();
      "TC_DIV_MAX_01":              run_tc_div_max_01();
      "TC_DIV_CHANGE_MIDCOUNT_01":  run_tc_div_change_midcount_01();
      "TC_DIV_CHANGE_TO_ZERO_01":   run_tc_div_change_to_zero_01();
      "TC_DIV_RAPID_TOGGLE_01":     run_tc_div_rapid_toggle_01();
      "TC_DUTY_CYCLE_SWEEP_01":     run_tc_duty_cycle_sweep_01();
      "TC_GLITCH_CHECK_01":         run_tc_glitch_check_01();
      "TC_RANDOM_01":               run_tc_random_01();
      "TC_ALL":                     run_tc_all();

      default: begin
        $fatal(1, "Unrecognized test_name '%s'", test_name);
      end
    endcase

    #100ns;
    $display("[%s] SUMMARY: clk_o_checks=%0d div_changes=%0d",
              test_name, toggle_check_count, div_change_count);
    // Finish simulation
    $finish;
  end
endmodule
