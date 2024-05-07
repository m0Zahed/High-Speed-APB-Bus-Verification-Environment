`include "calc_env/calc_trans.sv"
class calc_scoreboard;

    bit verbose;
    // Mailboxes for transactions from master and monitor for each port
    mailbox#(calc_trans) mst2scb[4], mon2scb[4];

    // Queues to store and match the expected sequence of transactions for each port
    calc_trans expected_reqs[4][$];
    calc_trans received_resps[4][$];

    // Associative array to count occurrences of each transaction ID
    int id_count[string];
    
    // Constructor
    function new(mailbox#(calc_trans) mst2scb[4], mailbox#(calc_trans) mon2scb[4], bit verbose = 0);
        this.mst2scb = mst2scb;
        this.mon2scb = mon2scb;
        this.verbose = verbose;
    endfunction

    // Method to process and verify transactions
    task main();
        int idx;
        calc_trans mst_tr, mon_tr;
        string tr_id;

        forever begin
            for (idx = 0; idx < $size(mst2scb); idx++) begin
                if (mst2scb[idx].try_get(mst_tr)) begin // Get mst on right port
                    tr_id = $sformatf("%0d", mst_tr.id); // Convert the ID to string for the associative array key
                    id_count[tr_id]++;
                    if (id_count[tr_id] > 1) begin // Check if two transactions of same ID has been received
                        $display("@%0d: ERROR: More than two transactions with ID %0d detected for port %0d", $time, mst_tr.id, idx);
                        id_count[tr_id] = 1; // Prevent overflow of the count
                    end else begin
                        expected_reqs[idx].push_back(mst_tr); // Queue mst transaction
                        if (verbose) begin
                            $display("@%0d: INFO: Queued master transaction with ID %0d for port %0d", $time, mst_tr.id, idx);
                        end
                    end
                end

                if (mon2scb[idx].try_get(mon_tr)) begin //Get mon on same port
                    tr_id = $sformatf("%0d", mon_tr.id);
                    id_count[tr_id]++;
                    if (id_count[tr_id] > 1) begin //Check if two received with same ID
                        $display("@%0d: ERROR: More than two transactions with ID %0d detected for port %0d", $time, mon_tr.id, idx);
                        id_count[tr_id] = 1; // Prevent overflow of the count
                    end else begin
                        received_resps[idx].push_back(mon_tr); // Queue mon transaction
                        if (verbose) begin
                            $display("@%0d: INFO: Queued monitor transaction with ID %0d for port %0d", $time, mon_tr.id, idx);
                        end
                    end
                end

                process_transactions(idx);
            end
        end
    endtask

    // Process and verify the transactions for a specific port
protected task process_transactions(int port);
    calc_trans exp_req, mon_resp;
    int op1, op2, expected_result;

    while (expected_reqs[port].size() > 0 && received_resps[port].size() > 0) begin
        exp_req = expected_reqs[port][0]; // Accessing the first element
        mon_resp = received_resps[port][0]; // Accessing the first element

        if (exp_req.tag == mon_resp.tag) begin
            // Removing the first element after processing
            delete(expected_reqs[port], 0);
            delete(received_resps[port], 0);

            op1 = exp_req.data[31:0];
            op2 = exp_req.data[63:32];
            expected_result = perform_calculation(exp_req.cmd, op1, op2);

            if (expected_result == mon_resp.data) begin
                if (verbose) begin
                    $display("@%0d: SUCCESS: Correct result for port %0d, tag %0h, result %0h",
                             $time, port, mon_resp.tag, mon_resp.data);
                end
            end else begin
                $display("@%0d: ERROR: Incorrect result for port %0d, tag %0h, expected %0h, received %0h",
                         $time, port, exp_req.tag, expected_result, mon_resp.data);
            end
        end else begin
            // If tags do not match, only remove the transaction from the response queue
            delete(received_resps[port], 0);
            if (verbose) begin
                $display("@%0d: INFO: Waiting for matching tag for port %0d, current tag %0h",
                         $time, port, exp_req.tag);
            end
        end
    end
endtask

    protected function int perform_calculation(int cmd, int op1, int op2);
        begin
            case (cmd)
                4'b0001: return op1 + op2;
                4'b0010: return op1 - op2;
                4'b0101: return op1 << op2[4:0];
                4'b0110: return op1 >> op2[4:0];
                default: return 0;
            endcase
        end
    endfunction

endclass
