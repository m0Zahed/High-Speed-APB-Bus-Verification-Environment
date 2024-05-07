`ifndef CALC_MST
`define CALC_MST

`include "calc_env/calc_trans.sv"
`include "utilities/global_utils.sv"
`include "calc_env/calc_if.sv" 
`include "utilities/logger.sv"
`include "utilities/custom_queue.sv"

class mst_cnfg;

  //Debugging verbosity -- Set to one whenevr you want in
  bit get_trns = 1, 
  drv_inp = 1,
  rst = 1,
  exe = 1,
  evnt = 1;

endclass

class calc_mst;
    //Configuration for debugging
    mst_cnfg master_config;

    // Array to store transactions
    calc_trans tr_array[4][4];
    //Events
    event inputs_recieved, // For get_transaction()
          reset_completed; // for reset() 
    
    // Transaction Mailbox
    mailbox #(calc_trans) gen2mas;
    mailbox #(calc_trans) mas2scb[4]; // Mailbox to send transactions to the scoreboard

    // Verbosity level
    bit verbose;

    //Interfaces
    virtual ports_if.master_port ports[4];
    virtual calc_if.rst intf;

    //Atomic Queue
    custom_queue port_list;

    //Other Stuff  
    calc_trans tr;
    int total_count, // live count
    max_count; // total amount fo transaction generated
    bit back_to_back = 1; // send input back to back i.e. re-initialises input to 0 before sending next one.

    // For get_transaction()
    int recieved_count; // recieved count for tracking batch size in get_transaction() 
    int k;
    int l;

    // Constructor
    function new(mailbox #(calc_trans) gen2mas, 
                 mailbox #(calc_trans) mas2scb[4], 
                 bit verbose=0,
                 virtual calc_if intf,
                 int max_count
                 );
      this.gen2mas       = gen2mas;
      this.mas2scb       = mas2scb;
      this.verbose       = verbose;
      this.ports = intf.port; 
      this.intf = intf;
      this.max_count = max_count;
      //Initialise base values
      master_config = new;
      foreach (tr_array[i, j]) begin
        tr_array[i][j] = new(); 
      end
      tr = new();
      recieved_count = 0;
      total_count = 0;
      k = 0;
      l = 0;
    endfunction: new
    
    function nullify_array();
      foreach (tr_array[i, j]) begin
        tr_array[i][j] = null; 
      end
    endfunction

    task get_transactions();

      // nullify_array();

      while((recieved_count < 16)) begin
        l = recieved_count%4;
        k = recieved_count/4;

        //If mailbox is not empty fetch the transaction
        if(gen2mas.num() == 0)
          break;
        gen2mas.get(tr);
        if(master_config.get_trns) begin 
          if(tr != null)
            tr.display(add_prefix(MASTER));
        end 

        // this.tr_array[k][l] = new();
        this.tr_array[k][l] = tr.copy();
        if(master_config.get_trns ) begin 
          if(tr_array[k][l] != null)
            tr.display(add_prefix(MASTER));
        end 

        if(master_config.get_trns ) begin
          $display("%s In get_transactions() recieved_count = %d", add_prefix(MASTER), ++recieved_count);
        end

        total_count++;
      end
      recieved_count = 0;

      -> inputs_recieved;
    endtask
    
    //Drives all the inputs 
    task drive_inputs();
      // Wait & get transactions, accumulate them in tr_array
      wait(inputs_recieved.triggered());
      if(master_config.evnt) 
        log(MASTER, "------------------- drive_inputs() EVENT Triggerred Inputs Receive. -------------------");

      for (int i = 0; i < 4; i++) begin
        
        // INFO: it takes approximately 9~13 clock cycles for execute to complete and the response to be gotten in the Monitor for the loop below. 
        for (int j = 0; j < 4; j++) begin 

          if(tr_array[i][j] != null) begin
            this.tr_array[i][j].tag = i; // Set the tag as the order in which it was sent
            this.tr_array[i][j].display(add_prefix(MASTER));
            this.execute(this.tr_array[i][j].copy(),j); 

            if(master_config.drv_inp) begin
              log(MASTER, "transaction successfully driven.");
              if(tr_array[k][l] != null) begin
                tr.display(add_prefix(MASTER)); 
              end  else begin
                log(MASTER, "!!!!!!!!!!!!!!!!!!!!! Uninitialised transaction error. !!!!!!!!!!!!!!!!!!!!!!!!");
              end
            end
          end // end of if statement
        end //End of for loop j

        if(master_config.drv_inp) begin 
          log(MASTER, "4 inputs have been sent!");
        end
        repeat( (back_to_back) ? 2 : 4 ) @(posedge intf.clk); // 2 if inputs are back to back else 4 
      end
      
      //After Four inputs have been send trigger to scoreboard to pop values and clear the remain garbage values
      repeat(20) @(posedge intf.clk); // Wait sufficently for all the monitors to send to scoreboard 
      -> mms_sync; // Signal scoreboard to discard 
      log(MASTER, "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! Synchronise MASTER_SCOREBOARD CALLED !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");


      // Wait for signal from scoreboard to arrive to continue
      log(MASTER, "Waiting for signal from scoreboard to finsih up evaluating transactions! ");
      wait(wait_scbd_to_finish.triggered()); 
      log(MASTER, "wait_scbd_to_finish triggerred continuing with driver! ");
    endtask


    // Main daemon. Runs forever to switch  transaction to
    task main();   
      if(verbose)
        log(MASTER, "Starting Master!");

      reset();
      wait(reset_completed.triggered());
      log(MASTER, "Reset EVENT observed.");

      forever begin
        if(verbose)
          log(MASTER, " ----------------------------- Master Looping --------------------------");
        
        get_transactions();
        
        // Drive the inputs
        // -----WAIT FOR SCOREBOARD TO COMPLETE
        drive_inputs();

        log(MASTER, "In main() -- 16 inputs sent");
        if(master_config.exe)
          $display(add_prefix(MASTER), "In main() -- Waiting for 50 clock cycles, to CAPTURE OUTPUTS");
        repeat(50) @ (posedge this.intf.clk);
        if(master_config.exe)
          $display(add_prefix(MASTER), "In main() -- Done waiting."); 

        reset();
        wait(reset_completed.triggered());
        log(MASTER, "Reset EVENT observed.");

        if(verbose)
          $display( "%s ----------------------------- Master Loop ended  Current Total Responses %d  --------------------------", add_prefix(MASTER), total_count);

        if(total_count >= max_count ) begin
          repeat(50) @(posedge this.intf.clk); 
          $display( "%s ----------------------------- MAX COUNT REACHED EXITING MASTER ---- Current Total Responses %d  --------------------------", add_prefix(MASTER), total_count);
          break;
        end 
      end

    endtask: main

    // Reset the DUT then go to active mode
    task reset();
      if(master_config.rst) begin
        log(MASTER, "Reset Called!");
      end 

      foreach (this.ports[i]) begin
        ports[i].master_cb.cmd_in <= '0;
        ports[i].master_cb.data_in <= '0;
        ports[i].master_cb.tag_in <= '0;
        repeat(10) @(posedge this.intf.clk);
      end
      
      if(master_config.rst) begin
        log(MASTER, "Asserting Reset to 1, for 3 Clock Cycles");
      end 

      this.intf.reset <= 1'b1;
      repeat(3) @(posedge this.intf.clk);
      
      if(master_config.rst) begin
        log(MASTER, "Deasserting Reset to 0, for 5 Clock Cycles");
      end 

      this.intf.reset <= 1'b0;
      repeat(5) @(posedge this.intf.clk);

      if(master_config.rst) begin
        foreach (this.ports[i]) begin
          log(MASTER,
            $sformatf(" Output from port %0d: data_out=%0h, tag_out=%0h",
            i, ports[i].master_cb.data_out, ports[i].master_cb.tag_out)
            );
        end
      end
      /*this.intf.reset <= 1'b1;
        @this.intf.clk;
      @this.intf.clk;
      @this.intf.clk;
        this.intf.reset <= 1'b0;*/

     //Trigger reset completed event 
      -> reset_completed;
      if(master_config.rst) begin
        log(MASTER, "reset EVENT triggered");
      end
    endtask: reset
    
    // Addition task -- is thread and takes 5 clock cylces to complete 
task execute(calc_trans trans, int i);
  fork 
  begin
    // Intialise inputs for driving.
    if(!back_to_back) begin
      ports[i].master_cb.cmd_in <= '0;
      ports[i].master_cb.data_in <= '0;
      ports[i].master_cb.tag_in <= '0;
      repeat(2) @(posedge this.intf.clk);
      if(master_config.exe)
        $display(add_prefix(MASTER), "execute() inputs initialised.");
    end

    // operand 1 is inputted. 

    ports[i].master_cb.cmd_in <= trans.cmd;
    ports[i].master_cb.data_in <= trans.operand1;
    ports[i].master_cb.tag_in <= trans.tag;
    @(posedge this.intf.clk);
    if(master_config.exe)
      $display(add_prefix(MASTER), "execute() input 1 driven.");
    
    // operand 2 is inputted. 

    ports[i].master_cb.cmd_in <= 4'b0000;
    ports[i].master_cb.data_in <= trans.operand2;
    ports[i].master_cb.tag_in <= 2'b00;
    @(posedge this.intf.clk);
    if(master_config.exe)
      $display(add_prefix(MASTER), "execute() input 2 driven.");

    // Send executed transaction to scoreboard

    mas2scb[i].put(trans);
    
    // Print statement after pushing the transaction
    $display("[%0t] Transaction pushed to scoreboard on port %0d: cmd=%0h, operand1=%0h, operand2=%0h, tag=%0h", 
             $time, i, trans.cmd, trans.operand1, trans.operand2, trans.tag);

    //send to scoreboard here and then call the next 
    if(verbose) begin
        case (trans.operation)
          ADD:
              log(MASTER, "Addition Called.");
          SUB:
              log(MASTER, "Subtraction Called.");
          SHIFT:
              log(MASTER, "Shift Called.");
          default:
              log(MASTER, "Improper Command"); 
        endcase
    end

    //

    // ports[i].master_cb.cmd_in <= '0;
    // ports[i].master_cb.data_in <= '0;
    // ports[i].master_cb.tag_in <= '0;
    // repeat(2) @(posedge this.intf.clk);

  end
  join_none
endtask: execute

    

endclass: calc_mst 


`endif
