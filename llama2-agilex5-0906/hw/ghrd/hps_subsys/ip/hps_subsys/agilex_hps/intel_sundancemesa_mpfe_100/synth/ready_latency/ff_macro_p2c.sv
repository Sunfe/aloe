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


module ff_macro_p2c # (
 parameter DATA_WIDTH = 256,
 parameter NUM_FLOPS = 1 // based on number of flops you need in 1 dir 
 ) (
 input logic clk,

 input [DATA_WIDTH -1:0] in_data ,

 output [DATA_WIDTH -1:0] out_data

);


 (* altera_attribute = {"-name FORCE_HYPER_REGISTER_FOR_PERIPHERY_CORE_TRANSFER ON"} *)
    reg [DATA_WIDTH-1:0] in_data_reg [NUM_FLOPS:0];    

    assign in_data_reg[0] = in_data;


    genvar i;
    
    generate 
    for (i=0 ; i<NUM_FLOPS ; i=i+1 ) begin : hps_p2c_ff
      always @(posedge clk) begin
          in_data_reg[i+1] <= in_data_reg[i];
      end
    end
    endgenerate

    assign out_data = in_data_reg[NUM_FLOPS];



    
endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "vGGwV9/jjs6QnNBdvpbyE8DieIGVVENMsSoCIwKxtHzdYH+IzMxzuhJSfwjG6mrHB/ivPH4w577noKJF0xZrZhNKwzNCVJD3SXXj+N9WviHFcEMP9MZTPTDFT10J/ZKaS3Ief1cgzn1V+qynYlv/V7o8opAd9PtzcLtjSgKrfZTOjEmVIkpPtC+3RViQ4+khW+Z915hcic8JZUze9sUTsLwBCwU8S4KymDxnB7XfqtRYN+KbqlAztKrz8qQ3InsXwHyEjlK27GY/TBtqRsB0JNNx+CmNRdz6icR1DwJnHJ37lYoEHWnSUgT/f7DENIW9wlDSrxGdTfBS8EHvyCTV6l+WCQEYZLUn/RqVYiPY3vwmCkzX2aKh70lxiIN+AsWddI1+wxqQN59Lw7Eek90KMrHWykD7TG8U3MAfCjVj2/oZUIgixXXH1hSn7bmgDKLT7KRUsq8t2Tp7M5xRZUjdfQbmqnDei/Cizmvz6j8DcsE5XUh9CbT+IBGfmDvjQHh4S9mkkyNswrlxwsC7dvsQla5id9XhngMZ4GM939cxHXpCBNQBmf/pRfnetZygZcZ/3EapIy8alZ6jOBkk7wRrTrPn6EF93skVfZjPywqQiiQ8g3AP+6CQjL8OhF/vSyhodG+PWW8fFxVzX4zNaDsmTWEDk4Tk8YT0u4IQO+1cJpPRj9eLhCDUXhHQAwGjTWQL5qgF0Z+3XAsCLu+NuAAH8oR7T3HjPXVma3oHFq05xMCfyUPl4pa8Sbg1DHrSW56IcTS4gsi//ASVYMLo1PxTPDHGl40cxzGMibAt8/Arhxha3QfhzjDuG/dlf1xKDr4RPZPLtKlvY/1y0B3VsiayvntYM3Dn00keZ+nyK1BvubOYw9tHwjMkWMI6MARr2sIUDBP3yYgIFJpa4s9zVpn9h31lWQ29hR3nAw6HdeMmWfH9eXVvEf1KRJc3ZyVoDbXpEg1na/RRa7kdzg2wJ9azRFV9ofks38D4KS74L6uUkhQOAhyYpAMxdfMh5A+Or4x1"
`endif