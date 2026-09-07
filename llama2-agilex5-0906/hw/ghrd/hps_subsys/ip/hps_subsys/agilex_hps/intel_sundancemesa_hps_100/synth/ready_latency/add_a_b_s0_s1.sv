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

module add_a_b_s0_s1 #(
    parameter SIZE = 5
)(
    input [SIZE-1:0] a,
    input [SIZE-1:0] b,
    input s0,
    input s1,
    output [SIZE-1:0] out
);
    wire [SIZE:0] left;
    wire [SIZE:0] right;
    wire temp;
    
    assign left = {a ^ b, s0};
    assign right = {a[SIZE-2:0] & b[SIZE-2:0], s1, s0};
    assign {out, temp} = left + right;
    
endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "vGGwV9/jjs6QnNBdvpbyE8DieIGVVENMsSoCIwKxtHzdYH+IzMxzuhJSfwjG6mrHB/ivPH4w577noKJF0xZrZhNKwzNCVJD3SXXj+N9WviHFcEMP9MZTPTDFT10J/ZKaS3Ief1cgzn1V+qynYlv/V7o8opAd9PtzcLtjSgKrfZTOjEmVIkpPtC+3RViQ4+khW+Z915hcic8JZUze9sUTsLwBCwU8S4KymDxnB7XfqtQ506guLY43QiASydISLOLkk2Of6ed+hl40UW1zlyCl4Jmwiz9cCGma8TrYC2aGSY2ZqZQVaMK00QqY0xizObM5QnbZAjCNhTLBmHUgu9LYbYpjAM+HINC8LB6A9TEkW7Z8oxpKpEC0oG9VGFT1U2JuPotLjCq3/V+nI0L+/HP4XfbNPo4ALp2FMecw+NQLmABOJSgaksjCbIBsQI5ka3BIWLsS8eZRm0AaXWZvQC+zQlbkjfIxTLQUnhtWKFj+rPvsmcvKLAesvLI5H9tU302gnWCiLKh4h+YdkdyBWLWe7PIEy28VI7Qu0781Rycp+2ERSPvPimSZPQhxLivtsSBYZZQgJITLmnAhZy1i3MhQh5P7hX0eskhXCNNw77HWWp1wj6GErC+P1wf6SV8aEqVWG9Ppi+j8YCK/hKVG4dItqgcY5+uVDpmwz6Cm3CiiYP67yJx60LvksBo29qmPmA2MRdSH339VYfIrPsaYgsy/cVf+L7sg6r9AACrDjGKzLo9cyDGZyXqey00Y1SYG3LyWqBO2c2tiS9aAZ1/vsxtBomkJaBGl+et38R3Pqi/R1JuVduKAvvxpvSspQb71mar1FM7xOrzYtrNTzsaM4VfaSXz9a353fvyWyS3rV/3cNYb0AmE/PttKV4NT9dug2PHU2FRf6MRI68m8INvfsGC+GFIv1xghWNMeTLDe/QjEsXm3wx3uXfzrEV/BSd7Ugisk42NhB3PHNfmbWoZgn1RKXnVT1/EjXkGEclSu3rFjU/U4aa3p7Bk+ys/tkAuzCjll"
`endif