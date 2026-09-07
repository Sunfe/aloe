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


//
// Module : ready_latency_reset_synchronizer
// Description :
//     2-stage reset synchronizer used for ready latency reset. Takes an
//     asynchronous, active high reset input (rst_async) and synchronizes it
//     to the rising edge of the clock (clk). The output (rst_sync) is active
//     high and safe for use in the clk domain. 
//     This module is intended to be used for Agilex 5 HPS ready latency
//     adapters for the fabric-facing bridges. HPS IP generation should
//     automatically instantiate and connect the HPS reset output (h2f_reset)
//     to the synchronizer input and synchronizer output to each bridge ready
//     latency adapter. This ensures HPS reset and the bridge soft-logic
//     resets are synchronized to the bridge clocks.
//
module ready_latency_reset_synchronizer (
    input logic clk,
    input logic rst_async,    // asynchronous active high input reset
    output logic rst_sync     // synchronized active high output reset 
);

    // 2-stage synchronizer register
    logic [1:0] sync_reg;

    // asynchronous assertion, synchronous deassertion of reset
    always_ff @(posedge clk or posedge rst_async) begin
        if (rst_async) begin
            sync_reg <= 2'b11;    // assert reset synchronously
        end else begin
            sync_reg <= {sync_reg[0], 1'b0}; // Shift in '0' to release reset
        end
    end

    // Output is the last stage of the synchronizer
    assign rst_sync = sync_reg[1];

endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "vGGwV9/jjs6QnNBdvpbyE8DieIGVVENMsSoCIwKxtHzdYH+IzMxzuhJSfwjG6mrHB/ivPH4w577noKJF0xZrZhNKwzNCVJD3SXXj+N9WviHFcEMP9MZTPTDFT10J/ZKaS3Ief1cgzn1V+qynYlv/V7o8opAd9PtzcLtjSgKrfZTOjEmVIkpPtC+3RViQ4+khW+Z915hcic8JZUze9sUTsLwBCwU8S4KymDxnB7XfqtSKrOTQtsgOlGo57NwxEPtCqwU02Te3iDrngJwPjzsj7mDER3SRAXTWYaz4SHv9rMDP8Cwyxg4C5QonlhuQhoJBUJ1DHm9hX6ROgXO7FSqjoNjSjSAvy0Kxdw0/ArSp1rB4WmVbux7PSRg55gbSWMw6sZvBs0mOJ5zcJinYvtQeHiVmql2PqtcDoBUX0sFuJHI2DuPQXRcbbQh1kMWMN+IHoBvKBWWNxUhnC0Ttoph1gzm8OErMJ2ItDmAwE215KuRSOwCkDccIvw3JnXr9gAPyAMm8J0N2RA5RF2/pPSQ4bUdp2Pdz7QldPk1iXREx6l+TgO2+OEzZgJcL6LSzijMcftigY2cu6TG7ZNKaT4x0VOrEg6c/p1inKDJQXZBZwi7U7f8igGm296NscCu1fqMx28MlbIcvH6/lMTQyb95A4Hrk3z2qifjvoDh4193qjVYKw9O9ZQleZy7RGgGwlLKuCIL4gnlHgAi5I7Kz8+f4FfEY4T6s4tkCOtewqlaAk+9wHmYcTSwPw5z3quAi9OHfmUOctP5c6ebWlWVnIOKkzESdwWtIo3dlOSznPKIQuIXTnbLmlAY3YH/fFbJf3oqdk/HxSJ01A58As59Ml6n8u9CuvJTNSNvFSl1EiFBybmKmJ346zcRP5WFRc7KON9SoWI/QVmm5C4F2Y04I2OmVDKG7NlHyvX1091xkStj66pGpXgjZdbIA9fNlH3MRjiH8zjA4Nu/BOl9f1WkbeWuXJ+bAVbILG9zq/bZC/WBU5DMzPSzpI6S7SgOQ5zptdWvH"
`endif