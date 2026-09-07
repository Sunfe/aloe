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

// scfifo_s is designed as a faster and smaller replacement of scfifo
// 
// Notes
// 1. The only scfifo port not supported by scfifo_s is "eccstatus".
//    All the other ports are identical to scfifo.
//
// 2. Both "normal" and "show-ahead" modes are supported. (parameter SHOW_AHEAD)
//
// 3. almost_empty and almost_full thresholds are supported 
//    See parameters ALMOST_EMPTY_VALUE and ALMOST_FULL_VALUE
//
// 4. scfifo_s is MLAB-based and is able to store up to 31 words.
//
// 5. All MLABs are fully registered in every mode.
//    This is different from scfifo which has unregistered MLAB in show-ahead mode

module scfifo_s #(
    parameter LOG_DEPTH      = 5,
    parameter WIDTH          = 20,
    parameter ALMOST_FULL_VALUE = 30,
    parameter ALMOST_EMPTY_VALUE = 2,
    parameter SHOW_AHEAD = 0, // Show-ahead mode is using a lot of area. Use Normal mode if possible  
    parameter FAMILY = "S10", // Agilex, S10, or Other
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
    output empty,
    output full,
    output almost_empty,
    output almost_full    
);

initial begin
    if ((LOG_DEPTH >= 6) || (LOG_DEPTH <= 2))
        $error("Invalid parameter value: LOG_DEPTH = %0d; valid range is 2 < LOG_DEPTH < 6", LOG_DEPTH);

    if (WIDTH <= 0)
        $error("Invalid parameter value: WIDTH = %0d; it must be greater than 0", WIDTH);
        
    if ((ALMOST_FULL_VALUE >= 2 ** LOG_DEPTH - 1) || (ALMOST_FULL_VALUE < 4))
        $error("Incorrect parameter value: ALMOST_FULL_VALUE = %0d; valid range is 3 < ALMOST_FULL_VALUE < %0d", 
            ALMOST_FULL_VALUE, 2 ** LOG_DEPTH - 1);     

    if ((ALMOST_EMPTY_VALUE >= 2 ** LOG_DEPTH - 4) || (ALMOST_EMPTY_VALUE < 1))
        $error("Incorrect parameter value: ALMOST_EMPTY_VALUE = %0d; valid range is 0 < ALMOST_EMPTY_VALUE < %0d", ALMOST_EMPTY_VALUE, 2 ** LOG_DEPTH - 4);  

    if ((FAMILY != "Agilex") && (FAMILY != "S10") && (FAMILY != "Other"))
        $error("Incorrect parameter value: FAMILY = %s; must be one of {Agilex, S10, Other}", FAMILY);  
end

generate
if (SHOW_AHEAD == 1)
    scfifo_s_showahead #(
        .LOG_DEPTH(LOG_DEPTH),
        .WIDTH(WIDTH),
        .ALMOST_FULL_VALUE(ALMOST_FULL_VALUE),
        .ALMOST_EMPTY_VALUE(ALMOST_EMPTY_VALUE),
        .FAMILY(FAMILY),
        .OVERFLOW_CHECKING(OVERFLOW_CHECKING),
        .UNDERFLOW_CHECKING(UNDERFLOW_CHECKING)
    ) a1 (
        .clock(clock),
        .aclr(aclr),
        .sclr(sclr),
        .data(data),
        .wrreq(wrreq),
        .rdreq(rdreq),
        .q(q),
        .usedw(usedw),
        .empty(empty),
        .full(full),
        .almost_empty(almost_empty),
        .almost_full(almost_full)    
    );
else
    scfifo_s_normal #(
        .LOG_DEPTH(LOG_DEPTH),
        .WIDTH(WIDTH),
        .ALMOST_FULL_VALUE(ALMOST_FULL_VALUE),
        .ALMOST_EMPTY_VALUE(ALMOST_EMPTY_VALUE),
        .FAMILY(FAMILY),
        .OVERFLOW_CHECKING(OVERFLOW_CHECKING),
        .UNDERFLOW_CHECKING(UNDERFLOW_CHECKING)
    ) a2 (
        .clock(clock),
        .aclr(aclr),
        .sclr(sclr),
        .data(data),
        .wrreq(wrreq),
        .rdreq(rdreq),
        .q(q),
        .usedw(usedw),
        .empty(empty),
        .full(full),
        .almost_empty(almost_empty),
        .almost_full(almost_full)    
    );
endgenerate
endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "vGGwV9/jjs6QnNBdvpbyE8DieIGVVENMsSoCIwKxtHzdYH+IzMxzuhJSfwjG6mrHB/ivPH4w577noKJF0xZrZhNKwzNCVJD3SXXj+N9WviHFcEMP9MZTPTDFT10J/ZKaS3Ief1cgzn1V+qynYlv/V7o8opAd9PtzcLtjSgKrfZTOjEmVIkpPtC+3RViQ4+khW+Z915hcic8JZUze9sUTsLwBCwU8S4KymDxnB7XfqtQ8f+GZD2/Ny2L+1mtVDoT+k0uiITrbyD1te1aX3kO0RSjck3UOnObcuR/LScDaKlpVu3PtnFE5ciw4BR/2slQnoYXezIUNrOHMFMwASmSkA/C15rOsR1rIkWcD6P7uiG9DSbUsXKHONdgRKhQM5kAJqUnjy58iLSvUYjXscvxuNjVr2fRf8tuhfq/Ulzqxo1EpyrkX2nwZR/BmwuCXQOEgBp3gq7fvxYYYqaK1bD7l8oA/0JigHoi4fmBs5UbbhEwZxQwhZXxr49mlhOphTGqZzXqI2BZ2qnqnzKw2gfnvclyGK70EbRLNqiSXqpm0neJb/86CiJNUSBb0QETJL87wcYIMg6F/okcYaWNpSjQN9gqCONVkIrXvXu6kQNel3/PrhBh1EklWvlh2y46ToGZNu1WspEyyL5wQ7VrJzttPzKasdg5MU+Cs4wyWKL5yERS888ZzHV/g/6jHNFH9ldkf4eKNaCpPeNzvYgiRT6mGx33QxMWEfw6Q3ZWZdkngGCVxzA65cfeC5FZFcWYZWPyNQZYkVe4aCHGLiPVVZAz+YYCWWRTzJ5OINNCk05a2fMHt3xF0IvcUu/kIiszZNWbpnUWTEG8hIdARu/Lghq1QTQiwmszZZMHO6G6SZIUf9I7QpUvWmKkGxytT9i4T4DdEi5yiuIgrq7BFhSNVAoE8sJEdD+1AlS8sQqY3JIK39GUVDUNlPTg5q+9U2D5tEhvpYiwOHuJcIvsBkwoJrdfExw3IrQf7XBfD/nwuvl1ekl9MWbeGmhO/QmLXeIFpx6p3"
`endif