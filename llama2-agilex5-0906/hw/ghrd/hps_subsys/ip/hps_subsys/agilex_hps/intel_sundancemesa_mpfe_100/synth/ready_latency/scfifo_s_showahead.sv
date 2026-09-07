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

module scfifo_s_showahead #(
    parameter LOG_DEPTH      = 5,
    parameter WIDTH          = 20,
    parameter ALMOST_FULL_VALUE = 30,
    parameter ALMOST_EMPTY_VALUE = 2,
    parameter FAMILY = "Other", // Agilex, S10 or Other
    parameter OVERFLOW_CHECKING = 0, // Overflow checking circuitry is using extra area. Use only if you need it
    parameter UNDERFLOW_CHECKING = 0 // Underflow checking circuitry is using extra area. Use only if you need it
)(
    input clock,
    input aclr,
    input sclr,
    input [WIDTH-1:0] data,
    input wrreq,
    input rdreq,
    output reg [WIDTH-1:0] q,
    output reg [LOG_DEPTH-1:0] usedw,
    output reg empty,
    output full,
    output reg almost_empty,
    output reg almost_full    
);

initial begin
    if ((LOG_DEPTH > 5) || (LOG_DEPTH < 3))
        $error("Invalid parameter value: LOG_DEPTH = %0d; valid range is 2 < LOG_DEPTH < 6", LOG_DEPTH);
        
    if ((ALMOST_FULL_VALUE > 2 ** LOG_DEPTH - 1) || (ALMOST_FULL_VALUE < 1))
        $error("Incorrect parameter value: ALMOST_FULL_VALUE = %0d; valid range is 0 < ALMOST_FULL_VALUE < %0d", 
            ALMOST_FULL_VALUE, 2 ** LOG_DEPTH);     

    if ((ALMOST_EMPTY_VALUE > 2 ** LOG_DEPTH - 1) || (ALMOST_EMPTY_VALUE < 1))
        $error("Incorrect parameter value: ALMOST_EMPTY_VALUE = %0d; valid range is 0 < ALMOST_EMPTY_VALUE < %0d", 
            ALMOST_EMPTY_VALUE, 2 ** LOG_DEPTH);     
end

wire wrreq_safe;
wire rdreq_safe;
assign wrreq_safe = OVERFLOW_CHECKING ? wrreq & ~full : wrreq;
assign rdreq_safe = UNDERFLOW_CHECKING ? rdreq & ~empty : rdreq;

wire [WIDTH-1:0] w_q;

wire w_empty;
wire w_full;
wire w_almost_empty;
wire w_almost_full;    

wire [LOG_DEPTH-1:0] w_usedw;

reg read_fifo;
reg read_fifo_r; // 1 means that there is a value at fifo output

reg [WIDTH-1:0] r_q2;
reg r_q2_ready;

scfifo_s_normal #(
    .LOG_DEPTH(LOG_DEPTH), 
    .WIDTH(WIDTH), 
    .ALMOST_FULL_VALUE(2**LOG_DEPTH - 5), 
    .ALMOST_EMPTY_VALUE(ALMOST_EMPTY_VALUE),
    .NUM_WORDS(2**LOG_DEPTH - 4),
    .MLAB_ALWAYS_READ(0),
    .FAMILY(FAMILY)
    
) fifo_inst(
    .clock(clock),
    .aclr(aclr),
    .sclr(sclr),
    .data(data),
    .wrreq(wrreq_safe),
    .rdreq(read_fifo),
    .q(w_q),
    .usedw(w_usedw),
    .empty(w_empty),
    .full(full)   
);

wire next_empty;

assign next_empty = (w_usedw == 0) && (wrreq == 0) || (w_usedw == 1) && (read_fifo == 1) && (wrreq == 0);

reg tmp;

always @(posedge clock or posedge aclr) begin

    if (aclr) begin
        q <= 0;
        empty <= 1;
        read_fifo <= 0;
        read_fifo_r <= 0;        
        r_q2 <= 0;
        r_q2_ready <= 0;
        usedw <= 0;
        almost_full <= 0;
        almost_empty <= 1;
    end else if (sclr) begin
        q <= 0;
        empty <= 1;
        read_fifo <= 0;
        read_fifo_r <= 0;        
        r_q2 <= 0;
        r_q2_ready <= 0;
        usedw <= 0;
        almost_full <= 0;
        almost_empty <= 1;
    end else begin

        if (rdreq_safe || empty) begin
            if (r_q2_ready)
                q <= r_q2;
            else
                q <= w_q;
        end
        
        if (rdreq_safe || empty) begin
            empty <= !(r_q2_ready || read_fifo_r); 
        end
        
        if (r_q2_ready) begin
            if (rdreq_safe || empty)
                r_q2 <= w_q;
        end else begin
            r_q2 <= w_q;
        end

        if (r_q2_ready) begin
            if (rdreq_safe || empty)
                r_q2_ready <= read_fifo_r;
        end else begin
            if (rdreq_safe || empty)
                r_q2_ready <= 0;
            else
                r_q2_ready <= read_fifo_r;
        end
                    
        read_fifo_r <= read_fifo || read_fifo_r && !(rdreq_safe || empty || !r_q2_ready);
        
        read_fifo <= !next_empty && (
            rdreq_safe && (!empty + r_q2_ready + read_fifo + read_fifo_r < 4) || 
           !rdreq_safe && (!empty + r_q2_ready + read_fifo + read_fifo_r < 3)
        ); 
        
        //usedw <= w_usedw + read_fifo_r + r_q2_ready + wrreq_safe + (!empty & !rdreq_safe);
        {usedw, tmp} <= {w_usedw, !empty & !rdreq_safe} + {
            read_fifo_r & r_q2_ready | read_fifo_r & wrreq_safe | r_q2_ready & wrreq_safe, 
            read_fifo_r ^ r_q2_ready ^ wrreq_safe, 
            !empty & !rdreq_safe};
                
        almost_empty <=
            (usedw < (ALMOST_EMPTY_VALUE-1)) || 
            (usedw == (ALMOST_EMPTY_VALUE-1)) && ((wrreq == 0) || (rdreq_safe == 1)) || 
            (usedw == ALMOST_EMPTY_VALUE) && (rdreq_safe == 1) && (wrreq == 0);
            
        almost_full <= 
            (usedw > ALMOST_FULL_VALUE) ||
            (usedw == ALMOST_FULL_VALUE) && ((rdreq == 0) || (wrreq_safe == 1)) ||
            (usedw == ALMOST_FULL_VALUE - 1) && (rdreq == 0) && (wrreq_safe == 1);    

    end
end
endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "vGGwV9/jjs6QnNBdvpbyE8DieIGVVENMsSoCIwKxtHzdYH+IzMxzuhJSfwjG6mrHB/ivPH4w577noKJF0xZrZhNKwzNCVJD3SXXj+N9WviHFcEMP9MZTPTDFT10J/ZKaS3Ief1cgzn1V+qynYlv/V7o8opAd9PtzcLtjSgKrfZTOjEmVIkpPtC+3RViQ4+khW+Z915hcic8JZUze9sUTsLwBCwU8S4KymDxnB7XfqtS7Wdwu+Ln4EBIURcSWrJ7RhX4KOHHpvKLY15bLW2+lXolBC9Ea4s2RIvF65leiGNbLtA7BdGa8452r4JJv5KQQQVsn7x1UpHfekKD6oeo/jcGgQfIZEuyZSeIKs94Qq5oreWlkHOeiqKMSzMdji7Ka0aIKlnr+SMn18uUkOEiqxQMiieYeQHgh30Icury7vMFherg0CFSdpY1EU3UPTmoLLvs4/lNEaOaQbSDO0zhu5W6R2fbwO8g4LAzwIGV6cjJasjJWAaiuAr/j4adO2LUbH8tgMIfR5zb2XFjT4b3IHKIMk9D3f16l7EHP/uKe06YsNjILMWEFRBVE+iumhG7NJ5pelmiwKDle+83jRqKsea/f9c1oXoUKwG9LvRUJ3d+urk5CFhNm1EhmnVqBXOrGLF0Bd1VWNVYDKFmI1STSYP1qZcYBN3MICpY1s5GiJYownJZHH46fh3an0uj6RJgcJ4l/Oy/EqDA5GsEOqkLv+7xaHxVVHSKLSEsn2fx7oLxLndhFbCqiNnLGiTMAxDF1UgxzdhljpnTzXBNSX/yMK5dMn5pZD4urwIkn67zwpwytcZBgHON7taJUt7IkMNViLeLsxeJvrL6j5ZpQZh9HGjadYAGsXdRo7Z/xgUS61xkIPu9TF+I9ifZNMMtXFsHm0FDxETRAVhR7D8rjKYH9GhEUb5c4M84E9CgIxQdEXqR4Y0ctV/X8HHTvgv8WYj3IJS+xlKy/ORZ4OT0Xl1Uh5BcI4dKCyneMUexP9N9sHA5SHzmucxPma6BlXOL/wV3y"
`endif