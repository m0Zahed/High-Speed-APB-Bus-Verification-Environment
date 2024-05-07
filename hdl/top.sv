module top;
  parameter simulation_cycle = 100;
  
  bit clk = 1;
  always #(simulation_cycle/2) 
    clk = ~clk;
  
  calc_if intf(clk);
  test   t1(intf);  // Testbench program
  calc2_top u_calc2_top (
      .a_clk(clk), 
	      .scan_out(scan_out), // Assuming scan_out is an output signal in top module
    .b_clk(clk), // Assuming b_clk is connected
    .c_clk(clk), // Assuming c_clk is connected
    .scan_in(scan_in), // Assuming scan_in is connected
      .reset(intf.reset),
      // Connect calc_if interfaces to calc2_top ports
      .req1_cmd_in(intf.port[0].cmd_in), .req1_data_in(intf.port[0].data_in), .req1_tag_in(intf.port[0].tag_in),
      .req2_cmd_in(intf.port[1].cmd_in), .req2_data_in(intf.port[1].data_in), .req2_tag_in(intf.port[1].tag_in),
      .req3_cmd_in(intf.port[2].cmd_in), .req3_data_in(intf.port[2].data_in), .req3_tag_in(intf.port[2].tag_in),
      .req4_cmd_in(intf.port[3].cmd_in), .req4_data_in(intf.port[3].data_in), .req4_tag_in(intf.port[3].tag_in),
      // calc2_top has output ports to connect to intf.port outputs
      .out_data1(intf.port[0].data_out), .out_resp1(intf.port[0].resp_out), .out_tag1(intf.port[0].tag_out),
      .out_data2(intf.port[1].data_out), .out_resp2(intf.port[1].resp_out), .out_tag2(intf.port[1].tag_out),
      .out_data3(intf.port[2].data_out), .out_resp3(intf.port[2].resp_out), .out_tag3(intf.port[2].tag_out),
      .out_data4(intf.port[3].data_out), .out_resp4(intf.port[3].resp_out), .out_tag4(intf.port[3].tag_out)
    );
endmodule  
