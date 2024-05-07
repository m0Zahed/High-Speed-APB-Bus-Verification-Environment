`include "calc_env/calc_trans.sv"

class calc_monitor;
    bit verbose;

    //Other Stuff
    int resp_count = 0; 

    
    // Virtual Interface for ports_if, adjusted to match the interface definition
    virtual ports_if.monitor_port calc_monitor_if[4];

    // Monitor to scoreboard mailbox for each port
    mailbox#(calc_trans) mon2scb[4];

    // Constructor
    function new(virtual ports_if calc_monitor_if[], mailbox #(calc_trans) mon2scb[4], bit verbose = 0);
        this.calc_monitor_if = calc_monitor_if;
        this.verbose = verbose;
        this.mon2scb = mon2scb;
    endfunction

    // Task to monitor responses for a specific port
task monitor_port(int port);
    calc_trans tr_resp;
    int valid_resp_count = 0, overflow_resp_count = 0;

    $display("%s Port %d Started. ", add_prefix(MONITOR), port);

    forever begin

        tr_resp = new(); // Create a new instance of the calc_trans class
        // @(posedge calc_monitor_if[port].clk);
        @(calc_monitor_if[port].monitor_cb.resp_out);
        $display("%s -------------------- Port %d Recieved response no. %d -------------------- ", add_prefix(MONITOR), port, ++resp_count);

        // Store response status
        tr_resp.resp_out = calc_monitor_if[port].monitor_cb.resp_out; 
        tr_resp.data_out = calc_monitor_if[port].monitor_cb.data_out;
        tr_resp.tag_out = calc_monitor_if[port].monitor_cb.tag_out;
       
        case(tr_resp.resp_out)
            2'b00:
                log(MONITOR, "Response Out is 00");
            2'b01:
                begin
                    log(MONITOR, "Response Out is  01");
                    $display("%s Output is %h, Tag is %b" ,add_prefix(MONITOR), tr_resp.data_out, tr_resp.tag_out);
                    $display("%s Number of VALID Responses (local to port) - %d" , add_prefix(MONITOR), ++valid_resp_count);

                    // Send the captured response to the scoreboard
                    mon2scb[port].put(tr_resp);
                    $display("%s From port %d sent transaction with tag %d to SCOREBOARD." ,add_prefix(MONITOR), port, tr_resp.tag_out);
                    $display("%s -------------------- Port %d Response ended -------------------- ", add_prefix(MONITOR), port );

                end
            2'b10:
                begin
                    log(MONITOR, "Response out is 10");
                    $display("%s Output is %h, Tag is %b" ,add_prefix(MONITOR), tr_resp.data_out, tr_resp.tag_out);
                    $display("%s Number of OVERFLOW Responses (local to port) - %d" , add_prefix(MONITOR), ++overflow_resp_count );

                    // Send the captured response to the scoreboard
                    mon2scb[port].put(tr_resp);
                    $display("%s From port %d sent transaction with tag %d to SCOREBOARD." ,add_prefix(MONITOR), port, tr_resp.tag_out);
                    $display("%s -------------------- Port %d Response ended -------------------- ", add_prefix(MONITOR), port );

                end
            default:
                begin 
                    log(MONITOR, "Unknown Response");
                    $display("%s Recieved Response is %d ", add_prefix(MONITOR), tr_resp.resp_out);
                end    
        endcase
        // $display("%d <== ", calc_monitor_if[port].monitor_cb.resp_out);
        // tr_resp.data_out = calc_monitor_if[port].monitor_cb.data_out;
        // log(MONITOR, "Received Data");
        // $display("%d <== ", calc_monitor_if[port].monitor_cb.data_out);
        // tr_resp.tag = calc_monitor_if[port].monitor_cb.tag_out;

        // // Log the captured response
        // log(MONITOR, "Received Tag");
        // $display("%d <== ", calc_monitor_if[port].monitor_cb.tag_out);

        // $display("|||||||||||||||||||||||||||||||||||||||||||||Monitor Port %0d: Response captured and sent to scoreboard. cmd: %0b, Data: %0h, Tag: %0h",
            // port, tr_resp.cmd, tr_resp.data_out, tr_resp.tag);

        
            
    end
endtask


    // Main task to start monitoring all ports
    task main();
        log(MONITOR, "Started Monitor.");
        fork
            monitor_port(0);
            monitor_port(1);
            monitor_port(2);
            monitor_port(3);
        join_none
    endtask

endclass
