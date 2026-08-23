/*

| TEST CASE | DATE       | AUTHOR          | DESCRIPTION                                                |
|-----------|------------|-----------------|------------------------------------------------------------|  
| TC_001    | 2026-08-20 | Shuparna Haque  | Apply reset, enable_o must read 0 immediately after        |
| TC_002    | 2026-08-20 | Shuparna Haque  | enable_o stays 0 until DELAY_CYCLES elapse, then asserts   |
| TC_003    | 2026-08-20 | Shuparna Haque  | enable_i dropped mid-count, enable_o must stay 0           |
| TC_004    | 2026-08-20 | Shuparna Haque  | enable_i dropped/reasserted after delay already expired    |
| TC_005    | 2026-08-20 | Shuparna Haque  | Mid-operation async reset clears and restarts the counter  |
| TC_006    | 2026-08-20 | Shuparna Haque  | Counter saturates at DELAY_CYCLES, does not wrap around    |

| REVISION | DATE       | AUTHOR          | DESCRIPTION                                            |
|----------|------------|-----------------|--------------------------------------------------------|
| 0.1      | 2026-08-20 | Shuparna Haque  | Initial version                                        |
| 1.0      | 2026-08-23 | Shuparna Haque  | Stable release                                         |

Author : Shuparna Haque (sheikhshuparna3108@gmail.com)
This file is part of ADN-VLSI/adn_clk_rst
Copyright (c) 2026 ADN Semiconductors
Licensed under the MIT License
See LICENSE file in the project root for full license information

*/

module adn_clk_rst_delay_generator_tb;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // IMPORTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // bring in the testbench essentials functions and macros
  `include "vip/adn_common_tb_headers.sv"

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // LOCALPARAMS
  //////////////////////////////////////////////////////////////////////////////////////////////////
  localparam int DELAY_CYCLES = 10; // Number of clock cycles to delay the enable signal
  localparam realtime RT_CLK_PERIOD = 1us;   // real_time_clk_i: 1 MHz
  localparam realtime CLK_PERIOD    = 10ns;  // clk_i: 100 MHz
 
  //////////////////////////////////////////////////////////////////////////////////////////////////
  // TYPEDEFS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////
     logic arst_ni;          // Asynchronous active-low reset

     logic clk_i;          // Primary system clock
     logic real_time_clk_i;  // Real-time clock for counter refer
     
     logic enable_i;         // Input enable signal to be del
     
     logic enable_o; 
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
  adn_clk_rst_delay_generator #(
   .DELAY_CYCLES (DELAY_CYCLES) // Number of clock cycles to delay the enable signal
  ) dut (
  .arst_ni          (arst_ni),          // Asynchronous active-low r
  .clk_i            (clk_i),            // Primary system clock
  .real_time_clk_i  (real_time_clk_i),  // Real-time clock for counter refer
  .enable_i         (enable_i),         // Input enable signal to be del
  .enable_o         (enable_o)         // Delayed and synchronized output enable
);
  //////////////////////////////////////////////////////////////////////////////////////////////////
  // METHODS
  //////////////////////////////////////////////////////////////////////////////////////////////////
  task automatic wait_clk(input int n = 1);
    repeat (n) @(posedge clk_i);
  endtask

  task automatic wait_rt_clk(input int n = 1);
    repeat (n) @(posedge real_time_clk_i);
  endtask

  task automatic apply_reset();
    arst_ni  = 0;
    enable_i = 0;
    wait_rt_clk(2);
    @(negedge real_time_clk_i);
    arst_ni = 1;
    @(posedge clk_i);
  endtask

  task automatic check_enable_o(input string test_name, input bit expected);
    bit pass;
    pass = (enable_o === expected);
    note_case(pass);
    if (pass) $display("PASS: %s enable_o=%0b as expected", test_name, enable_o);
    else
      $display("FAIL: %s expected enable_o=%0b, got %0b", test_name, expected, enable_o);
  endtask

  // TC_001: enable_o must read 0 right after reset release
  task automatic reset_test();
    apply_reset();
    wait_rt_clk(2);
    check_enable_o("TC_001", 1'b0);
  endtask
 
  // TC_002: enable_o asserts once DELAY_CYCLES real-time clock edges have elapsed
  task automatic full_delay_test();
    apply_reset();
    enable_i = 1;
    wait_rt_clk(DELAY_CYCLES - 1);
    wait_clk(2);
    check_enable_o("TC_002a", 1'b0);
 
    wait_rt_clk(2);  
    wait_clk(3);     
    check_enable_o("TC_002b", 1'b1); 
  endtask
 
  // TC_003: enable_i dropped before the delay expires, enable_o must stay low
  task automatic early_drop_test();
    apply_reset();
    enable_i = 1;
    wait_rt_clk(DELAY_CYCLES - 1);
    enable_i = 0;
    wait_rt_clk(4);
    wait_clk(3);
    check_enable_o("TC_003", 1'b0);
  endtask
 
  // TC_004: enable_i reasserted after delay already expired -> enable_o follows immediately
  task automatic late_reassert_test();
    apply_reset();
    enable_i = 1;
    wait_rt_clk(DELAY_CYCLES + 2);
    wait_clk(3);
    enable_i = 0;
    wait_clk(3);
    check_enable_o("TC_004a", 1'b0);
 
    enable_i = 1;
    wait_clk(3);
    check_enable_o("TC_004b", 1'b1);
  endtask
 
  // TC_005: mid-operation async reset must clear enable_o and restart the counter
  task automatic mid_op_reset_test();
    apply_reset();
    enable_i = 1;
    wait_rt_clk(DELAY_CYCLES + 2);
    wait_clk(3);
    check_enable_o("TC_005a", 1'b1);  
 
    apply_reset();
    wait_clk(3);
    check_enable_o("TC_005b", 1'b0);  
 
    enable_i = 1;
    wait_rt_clk(DELAY_CYCLES - 1);
    wait_clk(2);
    check_enable_o("TC_005c", 1'b0); 
 
    wait_rt_clk(2);
    wait_clk(3);
    check_enable_o("TC_005d", 1'b1); 
  endtask

 
  // TC_006: counter must saturate at DELAY_CYCLES, not wrap around, if left running
  task automatic saturation_test();
    apply_reset();
    enable_i = 1;
    wait_rt_clk(DELAY_CYCLES + 20); 
    wait_clk(3);
    check_enable_o("TC_006", 1'b1);
  endtask
  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SEQUENTIALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // PROCEDURALS
  //////////////////////////////////////////////////////////////////////////////////////////////////
  initial begin
    clk_i = 0;
    forever #(CLK_PERIOD / 2) clk_i = ~clk_i;
  end
 
  initial begin
    real_time_clk_i = 0;
    forever #(RT_CLK_PERIOD / 2) real_time_clk_i = ~real_time_clk_i;
  end
  initial begin  // main initial
    apply_reset();
 
    case (test_name)
      "TC_001": begin
        reset_test();
      end
 
      "TC_002": begin
        full_delay_test();
      end
 
      "TC_003": begin
        early_drop_test();
      end
 
      "TC_004": begin
        late_reassert_test();
      end
 
      "TC_005": begin
        mid_op_reset_test();
      end
 
 
      "TC_006": begin
        saturation_test();
      end
 
      "TC_ALL": begin
        reset_test();
        full_delay_test();
        early_drop_test();
        late_reassert_test();
        mid_op_reset_test();
        saturation_test();
      end
 
      default: begin
        $display("\033[1;31mError: Unknown test case '%s'\033[0m", test_name);
      end
 
    endcase

    $finish;

  end

endmodule
