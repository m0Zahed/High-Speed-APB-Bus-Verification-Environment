`ifndef CALC_TRANS 
`define CALC_TRANS
`include "utilities/global_utils.sv"
`include "utilities/logger.sv"

class calc_trans;
  
  // Transaction properties
  rand bit [3:0] cmd;      // Command field
  rand bit [31:0] operand1;    // Data field
  rand bit [31:0] operand2;
  bit [1:0] tag;      // Tag field
  operation_t operation; // Type of operation
  
  //Syncrhonisation Primitives
  semaphore copy_sema;

  //Monitor Stuff
  bit [31:0] data_out;
  bit [1:0] resp_out;
  bit [1:0] tag_out;      // Tag field
  
  //Scoreboard Stuff
  bit [31:0] exp_val=0;

  //Other properties
  bit has_been_randomised = 0;
  static int count = 0;
  int id;

  // Constructor
  function new();
    id = count++;
    copy_sema = new(1);
  endfunction

  // Randomize the transaction with some constraints if needed
  function void randomize_transaction(string prefix);
    // Call the built-in randomize function with constraints
    if (!randomize() with {
        cmd inside {4'b0001, 4'b0010, 4'b0110, 4'b0101};
        // operand1 inside {32'h00000010};
        // operand2 inside {32'h00000001};
    }) begin
        $error("Randomization of calc_trans failed");
    end
    
    case(cmd)
      4'b0001:
        operation = ADD;
      4'b0010:
        operation = SUB;
      4'b0101:
        operation = SHIFT;
      4'b0110:
        operation = SHIFT;
      default:
      log(GENERATOR, "--------------- error in trans_calc_randomize_transaction() unknown command ----------------");
    endcase

    $display("%s Randomised", prefix); // Debug print to see the randomized value

    has_been_randomised = 1;
  endfunction

  // Display function for the transaction details
  function void display(string prefix = "");
    if(this.has_been_randomised == 1) begin 
      $display(
        "%s Transaction Details: Type: %s, Command = %0d,  Op1 = %0h, Op2 = %0h,Tag = %0d",
        prefix, get_type(), cmd, operand1, operand2, tag
        );
    end else begin
      $display("%s In trans_calc, transaction has not been Randomised! Try again." ,prefix);
    end
    $display(
        "%s Transaction Details: Type: %s, Data = %0d,  Resp = %0h, Tag = %0d",
        prefix, get_type(), data_out, resp_out, tag_out
        );
  endfunction
  
  function string get_type();
   case(this.operation)
     ADD: 
      return "ADD";
     SUB: 
      return "SUB";
     SHIFT: 
      return "SHIFT";
     default: 
      return "UNKNOWN";
   endcase 
  endfunction

  function calc_trans copy();
    calc_trans to = new(); 
    to.cmd = this.cmd;      // Command field
    to.operand1 = this.operand1;    // Data field
    to.operand2 = this.operand2;    // Data field
    to.operation = this.operation;      // Tag field
    to.has_been_randomised = has_been_randomised;
    to.tag = this.tag;

    to.resp_out = this.resp_out;
    to.data_out = this.data_out;
    to.tag_out = this.tag_out;
    return to;
  endfunction: copy
endclass: calc_trans

`endif 
