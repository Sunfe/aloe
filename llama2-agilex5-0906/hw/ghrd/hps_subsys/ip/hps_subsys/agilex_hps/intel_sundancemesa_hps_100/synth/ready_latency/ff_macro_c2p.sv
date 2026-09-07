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


module ff_macro_c2p # (
 parameter DATA_WIDTH = 256,
 parameter NUM_FLOPS = 1 // based on number of flops you need in 1 dir 
 ) (
 input logic clk,

 input [DATA_WIDTH -1:0] in_data ,

 output [DATA_WIDTH -1:0] out_data

);


 (* altera_attribute = {"-name FORCE_HYPER_REGISTER_FOR_CORE_PERIPHERY_TRANSFER ON; -name HYPER_REGISTER_DELAY_CHAIN 350"} *)
    reg [DATA_WIDTH-1:0] in_data_reg [NUM_FLOPS:0];    

    assign in_data_reg[0] = in_data;


    genvar i;
    
    generate 
    for (i=0 ; i<NUM_FLOPS ; i=i+1 ) begin : hps_c2p_ff
      always @(posedge clk) begin
          in_data_reg[i+1] <= in_data_reg[i];
      end
    end
    endgenerate

    assign out_data = in_data_reg[NUM_FLOPS];



    
endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "vGGwV9/jjs6QnNBdvpbyE8DieIGVVENMsSoCIwKxtHzdYH+IzMxzuhJSfwjG6mrHB/ivPH4w577noKJF0xZrZhNKwzNCVJD3SXXj+N9WviHFcEMP9MZTPTDFT10J/ZKaS3Ief1cgzn1V+qynYlv/V7o8opAd9PtzcLtjSgKrfZTOjEmVIkpPtC+3RViQ4+khW+Z915hcic8JZUze9sUTsLwBCwU8S4KymDxnB7XfqtSF/thj216ZUrQQfWUtcRqbvk+bTnYjTs5r++x+IlHSfOPNKnNIVoEzIYk2vfLKSdBdSALodSGjwhyaVOrmq4pEqd0fclesYYURYxVof9lhUCOD7SomXTQxAA5tDoaA3NcJMmqQvY/w/PfzY3QAynGSY/YY0voWAOvTyf70wPyNAP5h8a1jz+TgMJ53bCoB9ztLlORZrGMDAHcZteR5btkpBkU2y9R0mssnynGJUiIoOdZnwMA8Bo6Di6Gx5B9HFSJrCCKVU02/p0NJBdX1pLiXVCCW72/eE8eB2QRN4eRxgY0LYcO9W9071ua8B2BRnSkcNu4qPUrGRCtAnnakvx9BQ1Acy2hlACNAhVDHF8yhNpGisjogj88EXvu0KEYoHs0Lr9Kf/Snk25Rw4LuzSvJ1vOqiuyt2NLdV1nLbBc+tPThgGAFKj2cFhxOMwd/SaXhh1I9Gltn5uxc7u4GMImS0qNdwXBmLAsRkUXcZynljTrfHVPLJcvoJuOkNYKB/iC4wavYHvAQM1TNAVH7870ixtzroQFBNkNTbVs5EPljDpzASTukhEeC4oJ+KshPF1/bQ+m+m3QB2aPPDkJF2sifXBUmImZXTO0gjG52lh+vmWDUc6S0bMnb4oSZcJJkkG0HfghEzIppXPY/T+0DJ0Y1//bYgBOBZuXDDJjV4tYRu9RWUQggTH5AOxxSJZ8q03FNKhA8wSCcd9yRjxXNvL/J93PumTyDvNrDzl9Wmlo7Dlk0KMyvbYpaP0e927IF2mzbLayJJM/ZvNVr4soJYz0u9"
`endif