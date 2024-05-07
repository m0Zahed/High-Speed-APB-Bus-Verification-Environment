
`include "top_env/env.sv"
`include "calc_env/calc_if.sv"

program automatic test(calc_if intf);

// Top level environment
env the_env;

initial begin

  // Instantiate the top level
  the_env = new(intf);

  // Kick off the test now
  $display("Running the test.");
  the_env.run();
  
  //Generate Report
  repeat(850) @(posedge intf.clk);
  the_env.scb.generate_coverage_report();

  $finish;
  
end 

endprogram
