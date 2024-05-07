`ifndef CALC_GENERATOR
`define CALC_GENERATOR

`include "calc_env/calc_trans.sv"
`include "utilities/global_utils.sv"

class calc_gen;

  // Random Calculator transaction
  rand calc_trans rand_tr;

  // Test terminates when the trans_cnt is greater
  // than max_trans_cnt member
  int max_trans_cnt;

  // event notifying that all transactions were sent
  event ended;

  // Counts the number of performed transactions
  int trans_cnt = 0;

  // Verbosity level
  bit verbose;

  // Calculator Transaction mailbox
  mailbox #(calc_trans) gen2driver;

  // Constructor
  function new(mailbox #(calc_trans) gen2driver, int max_trans_cnt, bit verbose=0);
    this.gen2driver     = gen2driver;
    this.verbose        = verbose;
    this.max_trans_cnt  = max_trans_cnt;
    rand_tr             = new;
    
  endfunction

  // Method aimed at generating transactions
  task main();
    if(verbose)
      $display($time, ": Starting calc_gen for %0d transactions", max_trans_cnt);

    // Start this daemon as long as there are transactions to be proceeded
    while(!end_of_test()) 
    begin
        calc_trans my_tr;

        // Generate a transaction
        my_tr = get_transaction();
        if(verbose) begin
          $display("%s Transaction Number = %0d", add_prefix(GENERATOR), ++trans_cnt);
        end

        if(verbose)
          my_tr.display(add_prefix(GENERATOR));

        // Put the transaction into the mailbox
        gen2driver.put(my_tr);

    end // while (!end_of_test())

    if(verbose) 
      $display($time, ": Ending calc_gen");
  endtask

  // Virtual function to determine if the test should stop
  virtual function bit end_of_test();
    return trans_cnt >= max_trans_cnt;
  endfunction

  // Returns a transaction (randomized instance of Transaction)
virtual function calc_trans get_transaction();
    calc_trans local_tr = new;  // Create a new instance for each transaction
    local_tr.randomize_transaction(add_prefix(GENERATOR));       // Randomize the new instance

    if (verbose) begin
        $display("%s Randomized Transaction: Command=%0h, Data1=%0h, Data2=%0h, Tag=%0h",
                 add_prefix(GENERATOR), local_tr.cmd, local_tr.operand1, local_tr.operand2, local_tr.tag);
    end

    return local_tr.copy();
endfunction

endclass
`endif
