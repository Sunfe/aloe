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


`timescale 1 ps / 1 ps
module mux_data_synchronizer #(
    parameter DEPTH = 3,
    parameter DATA_WIDTH = 32
)
(
    input logic                     clk_dest
   ,input logic                     rst_dest
   ,input logic                     dvalid_in_src
   ,input logic [DATA_WIDTH-1 : 0]  data_in_src
   ,output logic [DATA_WIDTH-1 : 0] data_out_dest
);

   logic [1:0]  dvalid_sync;
   logic        dvalid_out_dest;
   logic [DATA_WIDTH-1 : 0]    data_in_src_reg;
   logic [DATA_WIDTH-1 : 0]    data_temp;
   
   altera_std_synchronizer_nocut 
      #(.depth(DEPTH)) 
      syncr ( 
            .clk(clk_dest),
            .reset_n(~rst_dest),
            .din(dvalid_in_src),
            .dout(dvalid_out_dest)
            );


    assign data_temp     = dvalid_out_dest ? data_in_src : data_out_dest ;
    // assign data_out_dest = data_temp ;

    always_ff@(posedge clk_dest) begin
        if (rst_dest)
            data_out_dest <= '0;
        else    
            data_out_dest <= data_temp;
    end
    
    
endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "Jv8lNbjFdP1RG6ZlRGDPQ18y9rK8xNjZPJSXRJP5QnPWfqyqNCZgAFckZeIKAKwNoSPIIpIipc8Lr+b9a/FWzIYgzMxpzrkpOByg+HoJBnaTRP9US7VEnPfzFsP4DZjz4ZfQo3AjGuPZdXoEPcUpMMVVVaUENWSiX6AT97YYkfX+YrBm5cVHUlgFZ8gk9eg+R0Z3hxyPZcAjv5lGd5X5M6DoA6WnB+Wn6k6+/EbGEiTv+oaHKx4c2J58t957U/re+gewNzNEVKgSvqMcqxxfE06IsefASe9Pcjj1IZBcm9U/odZGFQkLMo06fsHYhT5Bol0R8CDFP+zKp2usSOme3AU4lzh9EHYDNun7gh4v5v8xb1kiRYsj/U77MGOrFgHdzhETM2Y6ClXCmF01s0HSMZbtb3XVzyOnU6iSsVJJTA71W7Ul+k/2rEcgqKxQqAv7IVIni44zjpIrjopk8CxotNoi85W2OM4ckSPfyKonUYe+MKZdSuN0ykF2F8GOTXnFj37hRb1a5mcvdkG8gCtGsgCZ5362JC1QarZMBz22gM9vqbNoxmPoYZSG5KQgn8piORxt7Li4jvfPwHJZUbTwoBFkbPS5GEnKYSG1RCmVvzKUtPfS27hXe9H/z9y0QsM+YHgZ4naTWv1n37PNNRFTTNGO9QUTq2wesy4JzDe0KIkLO49i6EbTnU+hRPtFxMIan1FlagIi5tnevSBIIc5s3rWP1IgjdrYhfI1hslxNDpFz3sYKR8854oFGTD6XUL/RVuLC7LgEp55kjlY8TFTmtnroxCkUj2s/3YwflPczzyJCnBUqN3CGqQJuXpA8cgO74Berd52pRzpmCqUn9wXZlr727unpeKU6+4VRL6lruEqWO9FSLUGW3lEXjQWGJqq5+z/0RnJ0x6/X+n2WV7x7JNhRAxFPnfrUAt4fygtqUmXjpT8e5Kg+mZVECmKnc7trhKkgqhTJChAV/IL5qVWa0OplLHEQ0QOpHjp5KbfG7DGLT75JZequaLzp8i6TjVT4"
`endif