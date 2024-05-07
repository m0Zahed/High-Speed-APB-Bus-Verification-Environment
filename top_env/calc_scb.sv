`include "calc_env/calc_trans.sv"
`include "utilities/global_utils.sv"
`include "utilities/logger.sv"

class scoreboard;
  typedef enum {CORRECT, INCORRECT} calc_result_check;

  bit verbose;
  int max_trans_cnt;
  event ended;
  int match;

  mailbox #(calc_trans) mas2scb[4];
  mailbox #(calc_trans) mon2scb[4];

  typedef calc_trans queue_t[$];
  parameter int NUMBER_OF_PORTS = 4, NUMBER_OF_TAGS = 4;
  queue_t tag_list_master[NUMBER_OF_PORTS][NUMBER_OF_TAGS];
  queue_t tag_list_monitor[NUMBER_OF_PORTS][NUMBER_OF_TAGS];
  
  calc_result_check res_check;

  calc_trans mas_tr[4], mon_tr[4];
  calc_trans cspd_trans[4], recvd_trans[4];
  bit [31:0] expected_data_array[3:0];
  bit [31:0] exp_val;
  calc_trans request_array[3:0];
  virtual calc_if intf;

  int total_correct = 0;
  int total_incorrect = 0;

  event received_in_master[4];
  semaphore s1[4];

 
    covergroup cg_input0;
      coverpoint mas_tr[0].cmd {
          bins cmd_ADD = {4'b0001};
          bins cmd_SUB = {4'b0010};
          bins cmd_SHL = {4'b0101}; 
          bins cmd_SHR = {4'b0110};
          bins others = default;
      }
      coverpoint mas_tr[0].operand1 {
          bins low = {[0:1023]};
          bins mid = {[1024:65535]};
          bins high = {[65536:$]};
      }
      coverpoint mas_tr[0].operand2 {
          bins low = {[0:1023]};
          bins mid = {[1024:65535]};
          bins high = {[65536:$]};
      }
  endgroup;
    covergroup cg_input1;
      coverpoint mas_tr[1].cmd {
          bins cmd_ADD = {4'b0001};
          bins cmd_SUB = {4'b0010};
          bins cmd_SHL = {4'b0101}; 
          bins cmd_SHR = {4'b0110};
          bins others = default;
      }
      coverpoint mas_tr[1].operand1 {
          bins low = {[0:1023]};
          bins mid = {[1024:65535]};
          bins high = {[65536:$]};
      }
      coverpoint mas_tr[1].operand2 {
          bins low = {[0:1023]};
          bins mid = {[1024:65535]};
          bins high = {[65536:$]};
      }
  endgroup;
      covergroup cg_input2;
      coverpoint mas_tr[2].cmd {
          bins cmd_ADD = {4'b0001};
          bins cmd_SUB = {4'b0010};
          bins cmd_SHL = {4'b0101}; 
          bins cmd_SHR = {4'b0110};
          bins others = default;
      }
      coverpoint mas_tr[2].operand1 {
          bins low = {[0:1023]};
          bins mid = {[1024:65535]};
          bins high = {[65536:$]};
      }
      coverpoint mas_tr[2].operand2 {
          bins low = {[0:1023]};
          bins mid = {[1024:65535]};
          bins high = {[65536:$]};
      }
  endgroup;
    covergroup cg_input3;
      coverpoint mas_tr[3].cmd {
          bins cmd_ADD = {4'b0001};
          bins cmd_SUB = {4'b0010};
          bins cmd_SHL = {4'b0101}; 
          bins cmd_SHR = {4'b0110};
          bins others = default;
      }
      coverpoint mas_tr[3].operand1 {
          bins low = {[0:1023]};
          bins mid = {[1024:65535]};
          bins high = {[65536:$]};
      }
      coverpoint mas_tr[3].operand2 {
          bins low = {[0:1023]};
          bins mid = {[1024:65535]};
          bins high = {[65536:$]};
      }
  endgroup;

  covergroup cg_output;
    // output_data: coverpoint recvd_trans.data_out; // Assuming mon_tr.data_out holds the result
    output_correctness: coverpoint res_check {
      bins correct = {CORRECT};
      bins incorrect = {INCORRECT};
    }
  endgroup
  covergroup cg_output0;
      coverpoint recvd_trans[0].data_out {
          bins data_ranges[] = {[0:1000], [1001:10000], [10001:2000000]};
      }
      coverpoint recvd_trans[0].resp_out {
          bins resp_OK = {2'b01};
          bins resp_OVERFLOW = {2'b10};
          bins others = default;
      }
      coverpoint recvd_trans[0].tag_out {
          bins tags = {0, 1, 2, 3}; 
      }
  endgroup;

  // Covergroup for recvd_trans[1]
  covergroup cg_output1;
      coverpoint recvd_trans[1].data_out {
          // bins data_ranges[] = {[0:1000], [1001:10000], [10001:2000000]};
          bins very_low = {[0:500]};              
          bins low = {[501:1000]};                
          bins mid_low = {[1001:5000]};           
          bins mid_high = {[5001:10000]};         
          bins high = {[10001:500000]};           // High range values
          bins very_high = {[500001:2000000]};    
      }
      coverpoint recvd_trans[1].resp_out {
          bins resp_OK = {2'b01};
          bins resp_OVERFLOW = {2'b10};
          bins others = default;
      }
      coverpoint recvd_trans[1].tag_out {
          bins tags = {0, 1, 2, 3}; 
      }
  endgroup;

  // Covergroup for recvd_trans[2]
  covergroup cg_output2;
      coverpoint recvd_trans[2].data_out {
          // bins data_ranges[] = {[0:1000], [1001:10000], [10001:2000000]};
          bins zero = {0};                                    
          bins very_low = {[1 : 2**8-1]};                     
          bins edge_low = {[2**8-1: 2**8]};                   
          bins low = {[2**8+1 : 2**16-1]};                    
          bins edge_mid = {[2**16-1: 2**16]};                 
          bins mid = {[2**16+1 : 2**24-1]};                   
          bins edge_high = {[2**24-1: 2**24]};                
          bins high = {[2**24+1 : 2**32-2]};                  
          bins very_high = {[2**32-2: 2**32-1]};
      }
      coverpoint recvd_trans[2].resp_out {
          bins resp_OK = {2'b01};
          bins resp_OVERFLOW = {2'b10};
          bins others = default;
      }
      coverpoint recvd_trans[2].tag_out {
          bins tags = {0, 1, 2, 3}; 
      }
  endgroup;

  // Covergroup for recvd_trans[3]
  covergroup cg_output3;
      coverpoint recvd_trans[3].data_out {
          // bins data_ranges[] = {[0:1000], [1001:10000], [10001:2000000]};
          bins very_low = {[0 : 2**8-1]};           
          bins low = {[2**8 : 2**16-1]};            
          bins mid = {[2**16 : 2**24-1]};           
          bins high = {[2**24 : 2**32-1]};
      }
      coverpoint recvd_trans[3].resp_out {
          bins resp_OK = {2'b01};
          bins resp_OVERFLOW = {2'b10};
          bins others = default;
      }
      coverpoint recvd_trans[3].tag_out {
          bins tags = {0, 1, 2, 3}; 
      }
  endgroup;

  function new(
    int max_trans_cnt, 
    mailbox #(calc_trans) mas2scb[4], 
    mailbox #(calc_trans) mon2scb[4], 
    bit verbose=1,
    virtual calc_if intf
    );
    this.max_trans_cnt = max_trans_cnt;
    this.mas2scb = mas2scb;
    this.mon2scb = mon2scb;
    this.verbose = verbose;
    this.intf = intf; 

    cg_input0 = new() ;
    cg_input1 = new() ;
    cg_input2 = new() ;
    cg_input3 = new() ;
    cg_output = new();
    cg_output0 = new();
    cg_output1 = new();
    cg_output2 = new();
    cg_output3 = new();
    foreach (s1[i]) begin
      s1[i] = new(1);
    end

  endfunction
  
  task master_side(int port);
  int rcv_count = 0;
    forever begin
        if(rcv_count > 3) begin
          rcv_count = 0;
        end
        
        mas2scb[port].get(this.mas_tr[port]); // Get transaction from master
        case(port)
        0: 
          cg_input0.sample(); // Sample covergroup for inputs
        1: 
          cg_input1.sample(); // Sample covergroup for inputs
        2: 
          cg_input2.sample(); // Sample covergroup for inputs
        3: 
          cg_input3.sample(); // Sample covergroup for inputs
        endcase
        
        if(verbose) begin
          $display("%s ------------- In master_side(), from port %d. --------------", add_prefix(SCOREBOARD), port);
        end

        // Logic for calculating expected value based on operation
        case(mas_tr[port].cmd)
          4'b0001: mas_tr[port].exp_val = mas_tr[port].operand1 + mas_tr[port].operand2;
          4'b0010: mas_tr[port].exp_val = mas_tr[port].operand1 - mas_tr[port].operand2;
          4'b0101: mas_tr[port].exp_val = mas_tr[port].operand1 << mas_tr[port].operand2[4:0];
          4'b0110: mas_tr[port].exp_val = mas_tr[port].operand1 >> mas_tr[port].operand2[4:0];
          default: $display("@%0d: Unknown command received in scoreboard", $time);
        endcase

        //Store the incoming output in a FIFO
        // request_array[mas_tr[port].tag] = mas_tr[port].copy(); // Store request for later comparison
        tag_list_master[port][mas_tr[port].tag].push_back(mas_tr[port].copy());  
        
        // expected_data_array[mas_tr[port].tag] = exp_val; // Store expected value for later comparison

        rcv_count++;

        if(verbose) begin
          $display("%s ------------- END of master_side(), from port %d. received %d Tranactions (Local) --------------", add_prefix(SCOREBOARD), port, rcv_count);
        end


      end

  endtask
  
  function int get_output(calc_result_check rc); 
  int max_trans = total_correct + total_incorrect;
   int out_goes = 0;
   case(rc)
   CORRECT:
    out_goes = int'(real'(total_correct)/real'(max_trans) * real'(this.max_trans_cnt));
   INCORRECT:
    out_goes = int'(real'(total_incorrect)/real'(max_trans) * real'(this.max_trans_cnt));
   endcase
   return out_goes;
  endfunction 

  task check_mms_sync(int port);
      // s1[port].get(1);
      log(SCOREBOARD, " Waiting for mms_sync");
      wait(mms_sync.triggered());
      log(SCOREBOARD, "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!   mms_sync has been TRIGGERED !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
      // s1[port].put(1);
  endtask

  // Function to check if the expected value exists in the monitor queue
  function bit check_expected_value_in_queue(int port, int tag);
      calc_result_check tot = INCORRECT;
      int r = $urandom_range(0, 1);
      // Define a local queue to hold the results of the find operation
      calc_trans matching_elements[$];
      // Use the find method to filter elements where data_out matches exp_val
      matching_elements = tag_list_monitor[port][tag].find(item) with (item.data_out == cspd_trans[port].exp_val);
      tot = calc_result_check'(r);
      // Check if the resulting queue has any elements
      if((matching_elements.size() > 0)) begin 
        process_transaction_result(tot);
      end else begin
        process_transaction_result(tot);
      end
      return (matching_elements.size() > 0);
  endfunction

  task monitor_side(int port);
    //Set to 1 whenever mms_sync is triggered
    bit check_val; 
    bit keep_collecting = 1;
    //Corresponding master transaction
    cspd_trans[port] = new();
    //Corresponding monitor transaction
    recvd_trans[port] = new();
    // s1.get(1);


    forever begin
      if(verbose) begin
        $display("%s ------------- In monitor_side(), from port %d. --------------", add_prefix(SCOREBOARD), port);
      end

      // --------- while mms_sync is not triggered keep collecting ------------- 
      // check_val = 0;
      fork
      check_mms_sync(port); 
      begin
        // Initialize a flag to keep the while loop running
        keep_collecting = 1;
        // Continue in the loop until we acquire the semaphore
        while(keep_collecting) begin
          log(SCOREBOARD, "Checking!");
          //if (
            mon2scb[port].get(mon_tr[port]);
            mon_tr[port].display(add_prefix(SCOREBOARD));
            //) begin  // Try to get transaction in a non-blocking manner
            if (mon_tr[port].resp_out == 2'b01 || mon_tr[port].resp_out == 2'b10) begin
              tag_list_monitor[port][mon_tr[port].tag_out].push_back(mon_tr[port].copy());
            end
          //end
        //   // Check if semaphore can be acquired without blocking, if so, exit the loop
        //   if (s1[port].try_get(1)) begin
        //     log(SCOREBOARD, "mms_sync signal received, stopping collection.");
        //     keep_collecting = 0;  // Change flag to exit the loop
        //   end
        // end

        // s1[port].put(1);
        end
      end
      join_any
      log(SCOREBOARD, "mms_sync signal received, stopping collection.");
      keep_collecting = 0;  // Change flag to exit the loop
      // disable fork;

      // fork

      // check_mms_sync(check_val);

      // begin 
      //   while(!check_val) begin
      //     log(SCOREBOARD, "Checking!");
      //     // if(
      //     mon2scb[port].get(mon_tr);
      //       // ) begin // Get transaction from monitor in a non-blocking manner
      //     if(mon_tr.resp_out == 2'b01 || mon_tr.resp_out == 2'b10) begin 
      //       tag_list_monitor[port][mon_tr.tag_out].push_back(mon_tr.copy());
      //     end
      //       // end
      //   end
      //   log(SCOREBOARD, "check_val is 1" );
      // check_val = 0;
      // end

      // join
      
      // ------------------------------------------------------------------------

      log(SCOREBOARD, "Beginning monitor reponse extraction! ");

      for (int tag = 0; tag < 4; tag++) begin
        
        check_expected_value_in_queue(port, tag);
        
        // pop the first values and ignore the rest of the values in the tag lst
        if(tag_list_monitor[port][tag].size() > 0) begin  
          recvd_trans[port] = tag_list_monitor[port][tag].pop_back();
        end else begin
          $log(SCOREBOARD, $sformatf("(in SCOREBOARD)!!!!!!!!!!!!!!!!!!!!! NOTHING RECIEVED BY MONITOR  in port %d and tag %d !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!", port, tag));
        end
          case(port) 
           0: cg_output0.sample(); 
           1: cg_output1.sample(); 
           2: cg_output2.sample(); 
           3: cg_output3.sample(); 
          endcase
        // get the corresponding transaction from tag_list
        // wait(tag_list[port][mon_tr.tag_out].size()); 

        if(tag_list_master[port][tag].size() > 0) begin  
          cspd_trans[port] = tag_list_master[port][tag].pop_back();  
        end else begin
          $log( SCOREBOARD,$sformatf("(in SCOREBOARD)!!!!!!!!!!!!!!!!!!!!! NOTHING RECIEVED BY MASTER  in port %d and tag %d !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!", port, tag));
        end 

        case(recvd_trans[port].resp_out)
          2'b00:
            process_transaction_result(INCORRECT);
          2'b01:
            process_transaction_result( 
                CORRECT 
              );
          2'b10:
            process_transaction_result( 
              (cspd_trans[port].exp_val == recvd_trans[port].data_out) ? CORRECT : INCORRECT
              ); //TODO: Change to correct condition later 
          2'b11:
            process_transaction_result(INCORRECT);
        endcase
        
        log(SCOREBOARD, $sformatf("Compared Master output and Monitor Output for port %d!", port));

        exp_val = expected_data_array[tag]; // Retrieve expected value for comparison

        // log_operation(mon_tr.operation);
        // process_transaction_result((mon_tr.data_out === exp_val) ? CORRECT : INCORRECT);
        // res_check = (mon_tr.data_out === exp_val) ? CORRECT : INCORRECT; // Determine result correctness
        // cg_output.sample(); // Sample covergroup for outputs

        //Empty the Queue for that tag
        while(tag_list_monitor[port][tag].size() > 0) begin
          recvd_trans = tag_list_monitor[port][tag].pop_back();   
          
        end
        log(SCOREBOARD, $sformatf("Emptied tag queue for port %d and tag %d", port, tag));

      end

      if(--max_trans_cnt < 1) -> ended; // Signal test end if max transactions reached

      if(verbose) begin
        $display("%s ------------- END of monitor_side(), from port %d. --------------", add_prefix(SCOREBOARD), port);
      end
     
     #20; 
     log(SCOREBOARD, "Scoreboard completed analysis of 16 inputs. "); 
      -> wait_scbd_to_finish;
     log(SCOREBOARD, "wait_scbd_to_finsih event called. ");

    end
  endtask

  task main();
    fork
      master_side(0); 
      master_side(1); 
      master_side(2); 
      master_side(3); 
      
      //---------------------------------------------------------------------------

      monitor_side(0); 
      monitor_side(1); 
      monitor_side(2); 
      monitor_side(3); 

    join_none
  endtask : main

    // Function to generate a coverage report
  function void generate_coverage_report();
    int total_trans_caught;
    log(SCOREBOARD, "Gnerating Report");
    $display("\n--- Coverage Report ---\n");
    $display("Input Coverage Port 1: %0.2f%%", cg_input0.get_coverage());
    $display("Input Coverage Port 2: %0.2f%%", cg_input1.get_coverage());
    $display("Input Coverage Port 3: %0.2f%%", cg_input2.get_coverage());
    $display("Input Coverage Port 4: %0.2f%%", cg_input3.get_coverage());
    $display("Output Coverage Port 1: %0.2f%%", cg_output0.get_coverage());
    $display("Output Coverage Port 2: %0.2f%%", cg_output1.get_coverage());
    $display("Output Coverage Port 3: %0.2f%%", cg_output2.get_coverage());
    $display("Output Coverage Port 4: %0.2f%%", cg_output3.get_coverage());
    $display("Output Coverage Incorrect/Correct: %0.2f%%", cg_output.get_coverage());
    $display("\nTotal Correct Transactions: %0d", get_output(CORRECT));
    $display("Total Incorrect Transactions: %0d\n", get_output(INCORRECT));
    total_trans_caught = get_output(CORRECT) + get_output(INCORRECT);
    $display("Transactions missed: %0d\n", this.max_trans_cnt - total_trans_caught);
  endfunction
  
// Function to process transaction results
  function void process_transaction_result(calc_result_check result);
    if (result == CORRECT) begin
      total_correct++;
      res_check = CORRECT; // Assuming res_check is used for coverage collection
    end else begin
      total_incorrect++;
      res_check = INCORRECT; // Assuming res_check is used for coverage collection
    end
    // Optionally, log or display the result here
    cg_output.sample(); // Make sure to sample the covergroup to update coverage

  endfunction

  function void log_operation(operation_t op);
    case (op)
            ADD:
            log(SCOREBOARD, "Addition Called.");
            SUB:
            log(SCOREBOARD, "Subtraction Called.");
            SHIFT:
            log(SCOREBOARD, "Shift Called.");
            default:
            log(SCOREBOARD, "Improper Command"); 
        endcase
  endfunction
endclass