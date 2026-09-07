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

(* altera_attribute = "-name SYNCHRONIZER_IDENTIFICATION OFF" *)
module generic_mlab_sc #(
    parameter WIDTH = 8,
    parameter ADDR_WIDTH = 5,
    parameter FAMILY = "Other" // Agilex, S10, or Other
)(
    input clk,
    input [WIDTH-1:0] din,
    input [ADDR_WIDTH-1:0] waddr,
    input we,
    input re,
    input [ADDR_WIDTH-1:0] raddr,
    output [WIDTH-1:0] dout
);

genvar i;
generate
if (FAMILY == "S10") begin    
    reg [WIDTH-1:0] wdata_hipi;
    always @(posedge clk) wdata_hipi <= din;
        
    for (i=0; i<WIDTH; i=i+1)  begin : ml
        wire wclk_w = clk; // fix strange tristate warning
        wire rclk_w = clk; // fix strange tristate warning
        fourteennm_mlab_cell lrm (
            .clk0(wclk_w),
            .ena0(we),
            .clk1(rclk_w),
            .ena1(re),
                
            // synthesis translate off
            .clr(1'b0),
            .devclrn(1'b1),
            .devpor(1'b1),
            // synthesis translate on           

            .portabyteenamasks(1'b1),
            .portadatain(wdata_hipi[i]),
            .portaaddr(waddr),
            .portbaddr(raddr),
            .portbdataout(dout[i])          
        );

        defparam lrm .mixed_port_feed_through_mode = "dont_care";
        defparam lrm .logical_ram_name = "lrm";
        defparam lrm .logical_ram_depth = 1 << ADDR_WIDTH;
        defparam lrm .logical_ram_width = WIDTH;
        defparam lrm .first_address = 0;
        defparam lrm .last_address = (1 << ADDR_WIDTH)-1;
        defparam lrm .first_bit_number = i;
        defparam lrm .data_width = 1;
        defparam lrm .address_width = ADDR_WIDTH;
        defparam lrm .port_b_data_out_clock = "clock1";
    end
    
end else if (FAMILY == "Agilex") begin    
        
    for (i=0; i<WIDTH; i=i+1)  begin : ml
        wire wclk_w = clk; // fix strange tristate warning
        wire rclk_w = clk; // fix strange tristate warning
        tennm_mlab_cell lrm (
            .clk0(wclk_w),
            .ena0(we),
            .clk1(rclk_w),
            .ena1(re),
                
            // synthesis translate off
            .clr(1'b0),
            .devclrn(1'b1),
            .devpor(1'b1),
            // synthesis translate on           

            .portabyteenamasks(1'b1),
            .portadatain(din[i]),
            .portaaddr(waddr),
            .portbaddr(raddr),
            .portbdataout(dout[i])          
        );

        defparam lrm .mixed_port_feed_through_mode = "dont_care";
        defparam lrm .logical_ram_name = "lrm";
        defparam lrm .logical_ram_depth = 1 << ADDR_WIDTH;
        defparam lrm .logical_ram_width = WIDTH;
        defparam lrm .first_address = 0;
        defparam lrm .last_address = (1 << ADDR_WIDTH)-1;
        defparam lrm .first_bit_number = i;
        defparam lrm .data_width = 1;
        defparam lrm .address_width = ADDR_WIDTH;
        defparam lrm .port_b_data_out_clock = "clock1";
    end
    
    
end else begin

    localparam DEPTH = 1 << ADDR_WIDTH;
    (* ramstyle = "mlab" *) reg [WIDTH-1:0] mem[0:DEPTH-1];

    reg [WIDTH-1:0] dout_r;
    always @(posedge clk) begin
        if (we)
            mem[waddr] <= din;
        if (re)
            dout_r <= mem[raddr];
    end
    assign dout = dout_r;

end
endgenerate    

endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "vGGwV9/jjs6QnNBdvpbyE8DieIGVVENMsSoCIwKxtHzdYH+IzMxzuhJSfwjG6mrHB/ivPH4w577noKJF0xZrZhNKwzNCVJD3SXXj+N9WviHFcEMP9MZTPTDFT10J/ZKaS3Ief1cgzn1V+qynYlv/V7o8opAd9PtzcLtjSgKrfZTOjEmVIkpPtC+3RViQ4+khW+Z915hcic8JZUze9sUTsLwBCwU8S4KymDxnB7XfqtTPFXv9KgNn/O/CgjSZQG3ulcAp+tBmS8RgOaRBlBJUIXzXwRDlQXifjs3B+vb7yBoL17oddFRBb1Lh2DYCL5AQFmyiLMj+YYYDMotdv82WLSShf+mSq8rKhJpROQIbnu8bv5lFGyB5WhNs9vZtUvcB/yNx/A/sXebyf+jXl7kDjr8Nf2QZaYhrypI7Tc8/VgJAjYaa8oh4yg0G36vrvxh6nnrBsx27j+A/z2KqI2U7DFjcwWiMrJJMtnnP3L8GFJceiGOdJ+Fl5wvgHvmIwT8pjayaLdqz7VWy1KevhMg2l+jMZUFefrFWrz5SSPpTkAoa91MktGnn/TfKheO88bljn+I4IFQXXUJzz55mwPka+bsXx/IRLsgPtn3lmBEaTUdPSaONU83Fw05UjPz1Kivt7rAdF7FCczQOQvLimRihwpTGWWNXtWUwsBPAzK5PS7LCwjLCkqrZ7keWDun8xfZald7g10lHrXG5tvGf1fGKTG76b9I7+/NmajkMf64hGNMMgK/fvW4FJSHGa75fL8d9AGbVzDcuLNCx6TqFA3zteAu2chLTVw1jdfuebaILb8jCVww49k8tSnHkpRbtAyUSDUt15ZDLxbEBvShBTAS0PYT2XY2pRros930FChphiN9W/XzpYcCIttiEwLveh9lqqtTVKwXTpU9j9AI4GVmM7BFdm9rECmewztqzVsfcSn/FkPzHkuqd+fYj1aPc6JG9VM6OLh1d53OMcX8Ei2rlUNFJ+c/SBt57mFd6+yDmnEmvthi/XQlhiNhnQEIddJov"
`endif