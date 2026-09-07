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


// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

// turn off superfluous verilog processor warnings 
// altera message_level Level1 
// altera message_off 10034 10035 10036 10037 10230 10240 10030 

module altera_avalon_sysid_qsys #(
    parameter ID_VALUE   = 1,
    parameter TIMESTAMP  = 1
)(
    // inputs:
     address,
     clock,
     reset_n,
    
    // outputs:
     readdata
)
;

  output  [ 31: 0] readdata;
  input            address;
  input            clock;
  input            reset_n;

  wire    [ 31: 0] readdata;
  //control_slave, which is an e_avalon_slave
  assign readdata = address ? TIMESTAMP : ID_VALUE;

endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "SdgU9W/I3Un6mG6zxE4tpLSApCrsI97qN+aYYN4ywNrs4nnUSll4ckaRTU3FRIiEd9MllZ6mJdvi990RtsSB8FE2yrbcspPnDCWzh6v+WDKIcw2hM9759RKXg2QdHGMdjMF1upE6hGueC5zC1QyfItkC8S+1BIbhfbj5mNjROFu7aSecOjFmwUX8iIcYJFHDN4xQKpcAAy8AIHvTqsu/RqI9WBL/1cAlK7jqy9ZpuNURJWhAVxKNKnzfS4INibSKwIVQ001vWK88EbeVCkcGews7dGYlwp3p1rMyhnIbPZNx5WB7A4mAUYXtvZpdSmVGvdrrKvxPCNOD0CHVSiiOqP8q53KMrfHDgMbvcb9OiBDR+eS/KrSjIPAP3gNinTirXoBxerPch7tvjiNlWzmezaP8ZkUcmexYecxn9MZcNLAPzHqq3jDLj8nWqPjOCqt2j9VBLa2WLew75ZehJ+VSnGxu8IWl4ZBJFRuZruNpxLEeHHcx2C2urQNDL6KCMpfAQPwMHrfBYfcJ4I/wuFJR/OaJbnjSa0HTIsGvzY/11NSZsMYi+sMRZXsp1vBwTz7ocP7lOdcwT5rd9GkiQ7/e/I4/m6vnxweyGimkhTx/LkaMZsnfnzbANLhECJ238352HOzrDNe+Z+niKceHhbWvrHvRd3UcQgOdiBMOOpHJYMbj5utamKlXSupGhh6T/JUddyRYpe+0H+xsmDz7iOyTILa/lrZmTj+abwGVOf+Ss+S4MP8d7lrdePL9TvAX7jMNi/oxOv65C0bbSjTHf9m1Fksn4p4vd0cZj5DTFTz9w32b/63cyxbhAqTLoTpMYgnnA0XYBO2g1csSQH5DvfopC7QpiHzrHENA00Vv2mb6bKuksDPv3tSP59G6+o85m5NAny39uFQn+cuJYRqGy2/JfdCnoTo8evbUGPl2zKsZA6/ltE5ZVptmceEAaXsnDPxIfjlWbEXLnyRwW43ONS3z+USdsYGwvo1XUu3CKDaf2/WjGQiPwzLcyPdM3yGBe+Xd"
`endif