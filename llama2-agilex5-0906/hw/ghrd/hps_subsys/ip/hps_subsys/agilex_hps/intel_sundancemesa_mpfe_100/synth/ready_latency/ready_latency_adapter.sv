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


`timescale 1ns / 100ps

// this module has zero ready latency input and non zero latency output


module ready_latency_adapter # (
 parameter READY_LATENCY_OUT = 2,
 parameter PAYLOAD_WIDTH = 256,
 parameter LOG_DEPTH = 3


) (  
 output logic         in_ready,
 input  logic            in_valid,
 input  logic   [PAYLOAD_WIDTH-1: 0]  in_data,
 // Interface: out
 input  logic             out_ready,
 output logic          out_valid,
 output logic [PAYLOAD_WIDTH-1: 0] out_data,
  // Interface: clk
 input logic          clk,
 // Interface: reset
 input logic           reset

 /*AUTOARG*/);

   // ---------------------------------------------------------------------
   //| Signal Declarations
   // ---------------------------------------------------------------------
   
   logic [PAYLOAD_WIDTH-1:0]   in_payload;
   logic [PAYLOAD_WIDTH-1:0]   out_payload;
   logic            in_ready_wire;
   logic            out_valid_wire;
   logic [2:0]      fifo_fill;
   logic    rdreq;
   logic empty;   

   logic [READY_LATENCY_OUT-1:0] in_ready_dly_reg;
   logic in_ready_dly;
   assign in_ready_dly = (READY_LATENCY_OUT > 0) ? in_ready_dly_reg[0] : in_ready;

   logic fifo_wr_req;
   assign fifo_wr_req = (in_valid === 1'b1) && (in_ready_dly === 1'b1);
 
   localparam DEPTH = 2 ** LOG_DEPTH -1 ;

   // ---------------------------------------------------------------------
   //| Payload Mapping
   // ---------------------------------------------------------------------
   always @* begin
     in_payload = {in_data};
     {out_data} = out_payload;
   end

   // ---------------------------------------------------------------------
   //| FIFO
   // ---------------------------------------------------------------------                           
    scfifo_s # (
      .LOG_DEPTH (LOG_DEPTH),
      .WIDTH (PAYLOAD_WIDTH),
      .ALMOST_FULL_VALUE (DEPTH-1),
      .SHOW_AHEAD (1),
      .FAMILY ("Agilex")
    ) fifo_inst ( 
       .clock        (clk),
       .aclr       (reset),
       .sclr (1'b0),
       //.in_ready   (),
       .wrreq  (fifo_wr_req),      
       .data    (in_payload),
      //.out_ready  (out_ready),
       .rdreq      (rdreq),
       .q (out_payload),
       .usedw (fifo_fill),
       .empty (empty),
       .full (full),
       .almost_empty (),
       .almost_full ()
       );

   // ---------------------------------------------------------------------
   //| Ready & valid signals.
   // ---------------------------------------------------------------------
   always @* begin
      in_ready = ( DEPTH- fifo_fill > READY_LATENCY_OUT);
   end

    always @(posedge clk) begin
        in_ready_dly_reg[READY_LATENCY_OUT-1] <= in_ready;
        for (int i = 0; i < READY_LATENCY_OUT - 1; i++) begin
            in_ready_dly_reg[i] <= in_ready_dly_reg[i+1];
        end
    end

assign rdreq = out_ready && !empty;

assign out_valid = !empty;


endmodule


`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "vGGwV9/jjs6QnNBdvpbyE8DieIGVVENMsSoCIwKxtHzdYH+IzMxzuhJSfwjG6mrHB/ivPH4w577noKJF0xZrZhNKwzNCVJD3SXXj+N9WviHFcEMP9MZTPTDFT10J/ZKaS3Ief1cgzn1V+qynYlv/V7o8opAd9PtzcLtjSgKrfZTOjEmVIkpPtC+3RViQ4+khW+Z915hcic8JZUze9sUTsLwBCwU8S4KymDxnB7XfqtQSomGJ0h9DLe4slXcrq6efNhahN9WZM9arnBYItphuJW5zZiOGBR3xQm8aHwNDtSLbbpM4vzYQDEUsN3KEWWzKnfq+bZVjuKCHytuj5Fv8V5LYdimY5GOnvL8ZBxnnCVUpFQd9mElW+fQbDjRAXUpgae7EJ44D5v1dHCaggTOLJ4qY3oAM9yCcDuTSyHdTamd43NDvGWRVuyGi24taEwb/3ZWQq6XsrsPaXohzsxjotFYh206J0Wl6HKey4jwcJN3I1+Z/Q8IgADFMnX0cPMqa5tc/IIU7aIjhzRIrAHjLVrXVSDmpV+ljQoEYnSASOHCVUXWQKrlB18jDhGlcisiNykGGkuvnuUYGfORX0rNvGDEmwKjw2kw5EvePuM5UyUoDrcreB+H+nqsA+U/HoER5KK967OgHnUX+wFPMNqjMFr8oMyjnxwg6ctBaxmAwxRp+uIbVxB0E7g9wyU/suPXsZCMbeZ3sCvfJxW1Jol2OFS9wCsS5BGKOoXVzC1E0ZZLgZyWcykoj+S7qMB7F+DJ7P91x/4zK/4FXgSH0v2t6r1E3vLoUUw1nYnTjhwQm2zZsmi68KfKReXxueXsPkazMuLVdiaoNrQ7czZJjd/Qd6eann5pcGfpu/tu8xF1jiSAx5pxUmkMChThfNzwarwWrDyqhojkRvKRPa3AtLF794Lpyhrj+E/ygGnuT3SSgGrJNogBx0NkG8+GmpPVEp4GUn7V8tU3TB2xwq5t4y+HkWir8TB3DRFuUOb1H9pZzb0Mz3oNYuqNNL8DVF9Sy8VGg"
`endif