//======================================================================
//
// tb_wb_sha256.v
// --------------
// Testbench for the SHA-256 top level Wishbone wrapper.
//
//
// Author: Joachim Strombergson
// Copyright (c) 2013, Secworks Sweden AB
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or 
// without modification, are permitted provided that the following 
// conditions are met: 
// 
// 1. Redistributions of source code must retain the above copyright 
//    notice, this list of conditions and the following disclaimer. 
// 
// 2. Redistributions in binary form must reproduce the above copyright 
//    notice, this list of conditions and the following disclaimer in 
//    the documentation and/or other materials provided with the 
//    distribution. 
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
// FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
// COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
// BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, 
// STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF 
// ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//======================================================================

//------------------------------------------------------------------
// Simulator directives.
//------------------------------------------------------------------
`timescale 1ns/10ps


//------------------------------------------------------------------
// Test module.
//------------------------------------------------------------------
module tb_wb_sha256();
  
  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  parameter DEBUG = 0;

  parameter CLK_HALF_PERIOD = 2;

  // The address map.
  parameter ADDR_CORE_NAME     = 8'h00;
  parameter CORE_NAME_VALUE    = "SHA2";
  parameter ADDR_CORE_VERSION  = 8'h01;
  parameter CORE_VERSION_VALUE = "v0.1";

  parameter ADDR_CTRL          = 8'h08;
  parameter CTRL_INIT_BIT      = 0;
  parameter CTRL_INIT_VALUE    = 8'h01;
  parameter CTRL_NEXT_BIT      = 1;
  parameter CTRL_NEXT_VALUE    = 8'h02;

  parameter ADDR_STATUS        = 8'h09;
  parameter STATUS_READY_BIT   = 0;
  parameter STATUS_VALID_BIT   = 1;
                             
  parameter ADDR_BLOCK0        = 8'h10;
  parameter ADDR_BLOCK1        = 8'h11;
  parameter ADDR_BLOCK2        = 8'h12;
  parameter ADDR_BLOCK3        = 8'h13;
  parameter ADDR_BLOCK4        = 8'h14;
  parameter ADDR_BLOCK5        = 8'h15;
  parameter ADDR_BLOCK6        = 8'h16;
  parameter ADDR_BLOCK7        = 8'h17;
  parameter ADDR_BLOCK8        = 8'h18;
  parameter ADDR_BLOCK9        = 8'h19;
  parameter ADDR_BLOCK10       = 8'h1a;
  parameter ADDR_BLOCK11       = 8'h1b;
  parameter ADDR_BLOCK12       = 8'h1c;
  parameter ADDR_BLOCK13       = 8'h1d;
  parameter ADDR_BLOCK14       = 8'h1e;
  parameter ADDR_BLOCK15       = 8'h1f;
                             
  parameter ADDR_DIGEST0       = 8'h20;
  parameter ADDR_DIGEST1       = 8'h21;
  parameter ADDR_DIGEST2       = 8'h22;
  parameter ADDR_DIGEST3       = 8'h23;
  parameter ADDR_DIGEST4       = 8'h24;
  parameter ADDR_DIGEST5       = 8'h25;
  parameter ADDR_DIGEST6       = 8'h26;
  parameter ADDR_DIGEST7       = 8'h27;

  
  //----------------------------------------------------------------
  // Register and Wire declarations.
  //----------------------------------------------------------------
  reg [31 : 0] cycle_ctr;
  reg [31 : 0] error_ctr;
  reg [31 : 0] tc_ctr;

  reg           tb_clk;
  reg           tb_reset_n;
  reg           tb_cs;
  reg           tb_write_read;
  reg [7 : 0]   tb_address;
  reg [31 : 0]  tb_data_in;
  wire [31 : 0] tb_data_out;

  reg [31 : 0]  read_data;
  reg [255 : 0] digest_data;
  
  
  //----------------------------------------------------------------
  // Device Under Test.
  //----------------------------------------------------------------
  wb_sha256 dut(
                .CLK_I(tb_clk),
                .RST_I(tb_reset_n),
                
                .SEL_I(tb_cs),
                .WE_I(tb_write_read),
                .STB_I(tb_stb),
                .CYC_I(tb_cyc),
                .ACK_O(tb_ack),
                .ERR_O(tb_err),
                
                .ADR_I(tb_address),
                .DAT_I(tb_data_in),              
                .DAT_O(tb_data_out)
               );
  

  //----------------------------------------------------------------
  // clk_gen
  //
  // Clock generator process. 
  //----------------------------------------------------------------
  always 
    begin : clk_gen
      #CLK_HALF_PERIOD tb_clk = !tb_clk;
    end // clk_gen
    

  //----------------------------------------------------------------
  // sys_monitor
  //
  // Generates a cycle counter and displays information about
  // the dut as needed.
  //----------------------------------------------------------------
  always
    begin : sys_monitor
      #(2 * CLK_HALF_PERIOD);
      cycle_ctr = cycle_ctr + 1;
    end

  
  //----------------------------------------------------------------
  // dump_dut_state()
  //
  // Dump the state of the dump when needed.
  //----------------------------------------------------------------
  task dump_dut_state();
    begin
      $display("State of DUT");
      $display("------------");
      $display("Inputs and outputs:");
      $display("SEL_I = 0x%01x, WE_I = 0x%01x", 
               dut.SEL_I, dut.WE_I);
      $display("ADR_I = 0x%02x", dut.ADR_I);
      $display("DAT_I = 0x%08x, DAT_O = 0x%08x", 
               dut.DAT_I, dut.DAT_O);
      $display("tmp_data_out = 0x%08x", dut.tmp_data_out);
      $display("");

      $display("Control and status:");
      $display("ctrl = 0x%02x, status = 0x%02x", 
               {dut.next_reg, dut.init_reg}, 
               {dut.digest_valid_reg, dut.ready_reg});
      $display("");
      
      $display("Message block:");
      $display("block0  = 0x%08x, block1  = 0x%08x, block2  = 0x%08x,  block3  = 0x%08x",
               dut.block0_reg, dut.block1_reg, dut.block2_reg, dut.block3_reg);
      $display("block4  = 0x%08x, block5  = 0x%08x, block6  = 0x%08x,  block7  = 0x%08x",
               dut.block4_reg, dut.block5_reg, dut.block6_reg, dut.block7_reg);

      $display("block8  = 0x%08x, block9  = 0x%08x, block10 = 0x%08x,  block11 = 0x%08x",
               dut.block8_reg, dut.block9_reg, dut.block10_reg, dut.block11_reg);
      $display("block12 = 0x%08x, block13 = 0x%08x, block14 = 0x%08x,  block15 = 0x%08x",
               dut.block12_reg, dut.block13_reg, dut.block14_reg, dut.block15_reg);
      $display("");
      
      $display("Digest:");
      $display("digest = 0x%064x", dut.digest_reg);
      $display("");
      
    end
  endtask // dump_dut_state
  
  
  //----------------------------------------------------------------
  // reset_dut()
  //
  // Toggles reset to force the DUT into a well defined state.
  //----------------------------------------------------------------
  task reset_dut();
    begin
      $display("*** Toggle reset.");
      tb_reset_n = 0;
      #(4 * CLK_HALF_PERIOD);
      tb_reset_n = 1;
    end
  endtask // reset_dut

  
  //----------------------------------------------------------------
  // init_sim()
  //
  // Initialize all counters and testbed functionality as well
  // as setting the DUT inputs to defined values.
  //----------------------------------------------------------------
  task init_sim();
    begin
      cycle_ctr = 32'h00000000;
      error_ctr = 32'h00000000;
      tc_ctr = 32'h00000000;
      
      tb_clk = 0;
      tb_reset_n = 0;
      tb_cs = 0;
      tb_write_read = 0;
      tb_address = 6'h00;
      tb_data_in = 32'h00000000;
    end
  endtask // init_dut

  
  //----------------------------------------------------------------
  // display_test_result()
  //
  // Display the accumulated test results.
  //----------------------------------------------------------------
  task display_test_result();
    begin
      if (error_ctr == 0)
        begin
          $display("*** All %02d test cases completed successfully.", tc_ctr);
        end
      else
        begin
          $display("*** %02d test cases completed.", tc_ctr);
          $display("*** %02d errors detected during testing.", error_ctr);
        end
    end
  endtask // display_test_result
  
  
  //----------------------------------------------------------------
  // wait_ready()
  //
  // Wait for the ready flag in the dut to be set.
  // (Actually we wait for either ready or valid to be set.)
  //
  // Note: It is the callers responsibility to call the function
  // when the dut is actively processing and will in fact at some
  // point set the flag.
  //----------------------------------------------------------------
  task wait_ready();
    begin
      read_data = 0;
      
      while (read_data == 0)
        begin
          read_word(ADDR_STATUS);
        end
    end
  endtask // wait_ready
  

  //----------------------------------------------------------------
  // write_word()
  //
  // Write the given word to the DUT using the DUT interface.
  //----------------------------------------------------------------
  task write_word(input [7 : 0]  address,
                  input [31 : 0] word);
    begin
      if (DEBUG)
        begin
          $display("*** Writing 0x%08x to 0x%02x.", word, address);
          $display("");
        end
         
      tb_address = address;
      tb_data_in = word;
      tb_cs = 1;
      tb_write_read = 1;
      #(2 * CLK_HALF_PERIOD);
      tb_cs = 0;
      tb_write_read = 0;
    end
  endtask // write_word


  //----------------------------------------------------------------
  // write_block()
  //
  // Write the given block to the dut.
  //----------------------------------------------------------------
  task write_block(input [511 : 0] block);
    begin
      write_word(ADDR_BLOCK0,  block[511 : 480]);
      write_word(ADDR_BLOCK1,  block[479 : 448]);
      write_word(ADDR_BLOCK2,  block[447 : 416]);
      write_word(ADDR_BLOCK3,  block[415 : 384]);
      write_word(ADDR_BLOCK4,  block[383 : 352]);
      write_word(ADDR_BLOCK5,  block[351 : 320]);
      write_word(ADDR_BLOCK6,  block[319 : 288]);
      write_word(ADDR_BLOCK7,  block[287 : 256]);
      write_word(ADDR_BLOCK8,  block[255 : 224]);
      write_word(ADDR_BLOCK9,  block[223 : 192]);
      write_word(ADDR_BLOCK10, block[191 : 160]);
      write_word(ADDR_BLOCK11, block[159 : 128]);
      write_word(ADDR_BLOCK12, block[127 :  96]);
      write_word(ADDR_BLOCK13, block[95  :  64]);
      write_word(ADDR_BLOCK14, block[63  :  32]);
      write_word(ADDR_BLOCK15, block[31  :   0]);
    end
  endtask // write_block
  

  //----------------------------------------------------------------
  // read_word()
  //
  // Read a data word from the given address in the DUT.
  // the word read will be available in the global variable
  // read_data.
  //----------------------------------------------------------------
  task read_word(input [7 : 0]  address);
    begin
      tb_address = address;
      tb_cs = 1;
      tb_write_read = 0;
      #(2 * CLK_HALF_PERIOD);
      read_data = tb_data_out;
      tb_cs = 0;

      if (DEBUG)
        begin
          $display("*** Reading 0x%08x from 0x%02x.", read_data, address);
          $display("");
        end
    end
  endtask // read_word


  //----------------------------------------------------------------
  // read_digest()
  //
  // Read the digest in the dut. The resulting digest will be
  // available in the global variable digest_data.
  //----------------------------------------------------------------
  task read_digest();
    begin
      read_word(ADDR_DIGEST0);
      digest_data[255 : 224] = read_data;
      read_word(ADDR_DIGEST1);
      digest_data[223 : 192] = read_data;
      read_word(ADDR_DIGEST2);
      digest_data[191 : 160] = read_data;
      read_word(ADDR_DIGEST3);
      digest_data[159 : 128] = read_data;
      read_word(ADDR_DIGEST4);
      digest_data[127 :  96] = read_data;
      read_word(ADDR_DIGEST5);
      digest_data[95  :  64] = read_data;
      read_word(ADDR_DIGEST6);
      digest_data[63  :  32] = read_data;
      read_word(ADDR_DIGEST7);
      digest_data[31  :   0] = read_data;
    end
  endtask // read_digest
    
  
  //----------------------------------------------------------------
  // single_block_test()
  //
  //
  // Perform test of a single block digest.
  //----------------------------------------------------------------
  task single_block_test([511 : 0] block,
                         [255 : 0] expected);
    begin
      $display("*** TC%01d - Single block test started.", tc_ctr); 
     
      write_block(block);
      write_word(ADDR_CTRL, CTRL_INIT_VALUE);
      write_word(ADDR_CTRL, 8'h00);
      wait_ready();
      read_digest();

      if (digest_data == expected)
        begin
          $display("TC%01d: OK.", tc_ctr);
        end
      else
        begin
          $display("TC%01d: ERROR.", tc_ctr);
          $display("TC%01d: Expected: 0x%064x", tc_ctr, expected);
          $display("TC%01d: Got:      0x%064x", tc_ctr, digest_data);
          error_ctr = error_ctr + 1;
        end
      $display("*** TC%01d - Single block test done.", tc_ctr); 
      tc_ctr = tc_ctr + 1;
    end
  endtask // single_block_test
    
  
  //----------------------------------------------------------------
  // double_block_test()
  //
  //
  // Perform test of a double block digest. Note that we check
  // the digests for both the first and final block.
  //----------------------------------------------------------------
  task double_block_test([511 : 0] block0,
                         [255 : 0] expected0,
                         [511 : 0] block1,
                         [255 : 0] expected1
                        );
    begin
      $display("*** TC%01d - Double block test started.", tc_ctr); 

      // First block
      write_block(block0);
      write_word(ADDR_CTRL, CTRL_INIT_VALUE);
      write_word(ADDR_CTRL, 8'h00);
      wait_ready();
      read_digest();

      if (digest_data == expected0)
        begin
          $display("TC%01d first block: OK.", tc_ctr);
        end
      else
        begin
          $display("TC%01d: ERROR in first digest", tc_ctr);
          $display("TC%01d: Expected: 0x%064x", tc_ctr, expected0);
          $display("TC%01d: Got:      0x%064x", tc_ctr, digest_data);
          error_ctr = error_ctr + 1;
        end

      // Final block
      write_block(block1);
      write_word(ADDR_CTRL, CTRL_NEXT_VALUE);
      write_word(ADDR_CTRL, 8'h00);
      wait_ready();
      read_digest();
      
      if (digest_data == expected1)
        begin
          $display("TC%01d final block: OK.", tc_ctr);
        end
      else
        begin
          $display("TC%01d: ERROR in final digest", tc_ctr);
          $display("TC%01d: Expected: 0x%064x", tc_ctr, expected1);
          $display("TC%01d: Got:      0x%064x", tc_ctr, digest_data);
          error_ctr = error_ctr + 1;
        end

      $display("*** TC%01d - Double block test done.", tc_ctr); 
      tc_ctr = tc_ctr + 1;
    end
  endtask // double_block_test

    
  //----------------------------------------------------------------
  // wb_sha256_test
  // The main test functionality. 
  //
  // Test cases taken from:
  // http://csrc.nist.gov/groups/ST/toolkit/documents/Examples/SHA256.pdf
  //----------------------------------------------------------------
  initial
    begin : wb_sha256_test
      reg [511 : 0] tc0;
      reg [255 : 0] res0;

      reg [511 : 0] tc1_0;
      reg [255 : 0] res1_0;
      reg [511 : 0] tc1_1;
      reg [255 : 0] res1_1;
      
      $display("   -- Testbench for wb_sha256 started --");

      init_sim();
      reset_dut();

      // dump_dut_state();
      // write_word(ADDR_BLOCK0, 32'hdeadbeef);
      // dump_dut_state();
      // read_word(ADDR_BLOCK0);
      // dump_dut_state();

      tc0 = 512'h61626380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018;
      res0 = 256'hBA7816BF8F01CFEA414140DE5DAE2223B00361A396177A9CB410FF61F20015AD;
      single_block_test(tc0, res0);

      tc1_0 = 512'h6162636462636465636465666465666765666768666768696768696A68696A6B696A6B6C6A6B6C6D6B6C6D6E6C6D6E6F6D6E6F706E6F70718000000000000000;
      res1_0 = 256'h85E655D6417A17953363376A624CDE5C76E09589CAC5F811CC4B32C1F20E533A;
      tc1_1 = 512'h000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001C0;
      res1_1 = 256'h248D6A61D20638B8E5C026930C3E6039A33CE45964FF2167F6ECEDD419DB06C1;
      double_block_test(tc1_0, res1_0, tc1_1, res1_1);
      
      display_test_result();
      
      $display("   -- Testbench for wb_sha256 done. --");
      $finish;
    end // wb_sha256_test
endmodule // tb_wb_sha256

//======================================================================
// EOF tb_wb_sha256.v
//======================================================================
