`ifndef CALC_PORT_IF_DEFINE
`define CALC_PORT_IF_DEFINE

`include "utilities/logger.sv"

interface ports_if #(
    parameter DATA_WIDTH = 32, 
    parameter CMD_WIDTH = 4, 
    parameter TAG_WIDTH = 2
  ) 
  (
    input logic clk
  );

  // Command, Data, and Tag Inputs
  wire [CMD_WIDTH-1:0] cmd_in;
  wire [DATA_WIDTH-1:0] data_in;
  wire [TAG_WIDTH-1:0] tag_in;

  // Response, Data, and Tag Outputs
  wire [TAG_WIDTH-1:0] resp_out;
  wire [DATA_WIDTH-1:0] data_out;
  wire [TAG_WIDTH-1:0] tag_out;

  // Clocking block for the design
  clocking master_cb @(negedge clk);
    default output #1step;
    output cmd_in, data_in, tag_in;
    input resp_out, data_out, tag_out;
  endclocking
  
  //  Clocking block for the monitor
  clocking monitor_cb @(negedge clk);

    default input #1step; 
    default output #1step;
    input cmd_in, data_in, tag_in;
    inout resp_out, data_out, tag_out;
  endclocking

  // // Modports for input and output
  modport monitor_port (clocking monitor_cb, input clk);
  modport master_port (clocking master_cb);


  // Function to display signals based on mode
  // Call using display_signal(ports_if::MONITOR)
  function string display_signals(location mode);
    case (mode)

      MONITOR: begin
        log(
          MONITOR,
          $sformatf(
            "Monitor Mode - Inputs: cmd_in=%b, data_in=%h, tag_in=%b", 
            cmd_in, data_in, tag_in)
        );
      end

      MASTER: begin
        log(
          MASTER, 
          $sformatf(
            "Master Mode - Outputs: resp_out=%b, data_out=%h, tag_out=%b",
            resp_out, data_out, tag_out)
        );
      end

      INTF: begin
        log(
          MONITOR,
          $sformatf(
            "Both Modes - Inputs: cmd_in=%b, data_in=%h, tag_in=%b", 
            cmd_in, data_in, tag_in)
          );
        log(
          MASTER,
          $sformatf(
            "Outputs: resp_out=%b, data_out=%h, tag_out=%b", 
            resp_out, data_out, tag_out)
          );
      end

    endcase
  endfunction

endinterface

interface calc_if(
  input logic clk
);
  //Reset and other signals
  logic scan_in, scan_out;
  logic reset;
  //These ports cannot be accessed directly
  ports_if port[4](clk);
 
  modport rst (output reset, input clk );
  modport ports (inout port);
endinterface
`endif 

