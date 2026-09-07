// (C) 2001-2025 Altera Corporation. All rights reserved.
// Your use of Altera Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files from any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Altera Program License Subscription 
// Agreement, Altera IP License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Altera and sold by 
// Altera or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


// Copyright 2021 Intel Corporation. 
//
// This reference design file is subject licensed to you by the terms and 
// conditions of the applicable License Terms and Conditions for Hardware 
// Reference Designs and/or Design Examples (either as signed by you or 
// found at https://www.altera.com/common/legal/leg-license_agreement.html ).  
//
// As stated in the license, you agree to only use this reference design 
// solely in conjunction with Intel FPGAs or Intel CPLDs.  
//
// THE REFERENCE DESIGN IS PROVIDED "AS IS" WITHOUT ANY EXPRESS OR IMPLIED
// WARRANTY OF ANY KIND INCLUDING WARRANTIES OF MERCHANTABILITY, 
// NONINFRINGEMENT, OR FITNESS FOR A PARTICULAR PURPOSE. Intel does not 
// warrant or assume responsibility for the accuracy or completeness of any
// information, links or other items within the Reference Design and any 
// accompanying materials.
//
// In the event that you do not agree with such terms and conditions, do not
// use the reference design file.
/////////////////////////////////////////////////////////////////////////////

module scfifo_s_normal #(
    parameter LOG_DEPTH      = 5,
    parameter WIDTH          = 20,
    parameter ALMOST_FULL_VALUE = 30,
    parameter ALMOST_EMPTY_VALUE = 2,
    parameter FAMILY = "S10", // Agilex, S10, or Other
    parameter NUM_WORDS = 2**LOG_DEPTH - 1,
    parameter MLAB_ALWAYS_READ = 1, // 1 to reduce amount of routing; 0 to reduce power consumption 
    parameter OVERFLOW_CHECKING = 0, // Overflow checking circuitry is using extra area. Use only if you need it
    parameter UNDERFLOW_CHECKING = 0 // Underflow checking circuitry is using extra area. Use only if you need it
)(
    input clock,
    input aclr,
    input sclr,
    input [WIDTH-1:0] data,
    input wrreq,
    input rdreq,
    output [WIDTH-1:0] q,
    output [LOG_DEPTH-1:0] usedw,
    output reg empty,
    output reg full,
    output reg almost_empty,
    output reg almost_full    
);

initial begin
    if ((LOG_DEPTH > 5) || (LOG_DEPTH < 3))
        $error("Invalid parameter value: LOG_DEPTH = %0d; valid range is 2 < LOG_DEPTH < 6", LOG_DEPTH);
        
    if ((ALMOST_FULL_VALUE >= NUM_WORDS) || (ALMOST_FULL_VALUE < 1))
        $error("Incorrect parameter value: ALMOST_FULL_VALUE = %0d; valid range is 0 < ALMOST_FULL_VALUE < %0d", 
            ALMOST_FULL_VALUE, NUM_WORDS);     

    if ((ALMOST_EMPTY_VALUE >= NUM_WORDS) || (ALMOST_EMPTY_VALUE < 1))
        $error("Incorrect parameter value: ALMOST_EMPTY_VALUE = %0d; valid range is 0 < ALMOST_EMPTY_VALUE < %0d", 
            ALMOST_EMPTY_VALUE, NUM_WORDS);  

    if ((NUM_WORDS > 2 ** LOG_DEPTH - 1) || (NUM_WORDS < 1))
        $error("Incorrect parameter value: NUM_WORDS = %0d; valid range is 0 < NUM_WORDS < %0d", 
            NUM_WORDS, 2 ** LOG_DEPTH);  
end

(* altera_attribute = "-name AUTO_CLOCK_ENABLE_RECOGNITION OFF" *) reg [LOG_DEPTH-1:0] write_addr = 0;
(* altera_attribute = "-name AUTO_CLOCK_ENABLE_RECOGNITION OFF" *) reg [LOG_DEPTH-1:0] read_addr = 0;
reg [LOG_DEPTH-1:0] capacity = 0;
wire [LOG_DEPTH-1:0] capacity_w;

wire wrreq_safe;
wire rdreq_safe;
assign wrreq_safe = OVERFLOW_CHECKING ? wrreq & ~full : wrreq;
assign rdreq_safe = UNDERFLOW_CHECKING ? rdreq & ~empty : rdreq;

initial begin 
    empty = 1;
    full = 0;
    almost_empty = 1;
    almost_full = 0;
end

add_a_b_s0_s1 #(LOG_DEPTH) adder(
    .a(write_addr),
    .b(~read_addr),
    .s0(wrreq_safe),
    .s1(~rdreq_safe),
    .out(capacity_w)
);

always @(posedge clock or posedge aclr) begin
    if (aclr) begin
        write_addr <= 0;
        read_addr <= 0;
        capacity <= 0;
        empty <= 1;
        full <= 0;
        almost_empty <= 1;
        almost_full <= 0;  
    
    end else if (sclr) begin
        write_addr <= 0;
        read_addr <= 0;
        capacity <= 0;
        empty <= 1;
        full <= 0;
        almost_empty <= 1;
        almost_full <= 0;  

    end else begin
    
        write_addr <= write_addr + wrreq_safe;
        read_addr <= read_addr + rdreq_safe;

        capacity <= capacity_w;
        
        empty <= (capacity == 0) && (wrreq == 0) || (capacity == 1) && (rdreq == 1) && (wrreq == 0);
            
        full <= (capacity == NUM_WORDS) && (rdreq == 0) || (capacity == NUM_WORDS - 1) && (rdreq == 0) && (wrreq == 1);
        
        almost_empty <=
            (capacity < (ALMOST_EMPTY_VALUE-1)) || 
            (capacity == (ALMOST_EMPTY_VALUE-1)) && ((wrreq == 0) || (rdreq == 1)) || 
            (capacity == ALMOST_EMPTY_VALUE) && (rdreq == 1) && (wrreq == 0);
            
        almost_full <= 
            (capacity > ALMOST_FULL_VALUE) ||
            (capacity == ALMOST_FULL_VALUE) && ((rdreq == 0) || (wrreq == 1)) ||
            (capacity == ALMOST_FULL_VALUE - 1) && (rdreq == 0) && (wrreq == 1);    
    end
end

assign usedw = capacity;

generic_mlab_sc #(.WIDTH(WIDTH), .ADDR_WIDTH(LOG_DEPTH), .FAMILY(FAMILY)) mlab_inst (
    .clk(clock),
    .din(data),
    .waddr(write_addr),
    .we(1'b1),
    .re(MLAB_ALWAYS_READ ? 1'b1 : rdreq_safe),
    .raddr(read_addr),
    .dout(q)
);

endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "vGGwV9/jjs6QnNBdvpbyE8DieIGVVENMsSoCIwKxtHzdYH+IzMxzuhJSfwjG6mrHB/ivPH4w577noKJF0xZrZhNKwzNCVJD3SXXj+N9WviHFcEMP9MZTPTDFT10J/ZKaS3Ief1cgzn1V+qynYlv/V7o8opAd9PtzcLtjSgKrfZTOjEmVIkpPtC+3RViQ4+khW+Z915hcic8JZUze9sUTsLwBCwU8S4KymDxnB7XfqtR0KAPv3MG1PbNHnZHtP2Mph5pHC14I3LQAsFeoQcTItAc5P/oMm4fbgAVwTTs6oIsu4DTL+7YBV+VI1o45gL75GAKjQWGX5S0NpyLAsMY/bg5mNXPAQ+ux/qtlrYCzIIima7q9PTk/GQQ7acCN3oV9WSQv/rEuhgd5ODi85+aBT2CwgYuOJyRG+afEgZML9NHWNu2LnL/ytTNnwnzVZRwjp5z6wAF3z0S00JYlSYyHi4TXkcKM+WKvQatvC8cXmiLgk+NX8ok591q0Dxpmn7sUtLfjDMXczecS4UPmZIB14trfESHXZrp+wGnQg/H6AeNFL59q9chCoDzIs+OAkMZrA3PqCkVvGYMgR/UIDcT3QW3kAI4wK9p5MsClbHCSblJ2wOV1evx1kTgkrKS5UFKtTqsg+v6bj3hBtz3lQIPwjLMiU/rMKbfeaU36kxn8oZJKlx9/9eRrL4BZo1SOCse/sWUz1XWSSHNhKxaFNDu5Xg6i945BQk7ip40i0bVEYeGkcfTci8YMZHgVVyZ09YyiMYAiFkK3FAB8vtQS1yz7sf+xFenTLP6WQd/vn2ZBPNO1J1F1DBBQ4jSACm60lkvfZ1eVSvGui6+EK8W9UhOYzVrgzgZumGwxKynCaq+VdDE6+KotmFB8/BSCOI6s9C9FSviG9gn2XATOb8NVetvT3AJ28t/rpn9fdcq6911Bm315r3WXBnfIk7iEaNlSPcLpJnwKIk82MtSysQEcLqZOV+X0Tm9ihgAbvFupF7FMvhsJgv6uiVdam9NlSMDjfsVe"
`endif