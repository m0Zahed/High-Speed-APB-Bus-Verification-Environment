`ifndef __QUEUE__
`define __QUEUE__
`include "utilities/logger.sv"
class custom_queue;

    // class members
    int queue[$];
    int maxSize;
    semaphore access_sema;

    // Constructor to set the maximum size of the queue
    function new(int size);
        maxSize = size;
        access_sema = new(4);
    endfunction

    // Method to "push" a value into the queue
    task push(int value);
        access_sema.get(1);
        log(MASTER, "");
        if (queue.size() < maxSize) begin
            queue.push_back(value);
            $display("Pushed %0d into the queue. Queue size is now %0d.", value, queue.size());
        end else begin
            $display("Queue is full. Cannot push %0d.", value);
        end
        access_sema.put(1);
    endtask

    // Method to "pop" a value from the queue
    task pop(output int value);
        access_sema.get(1);
        log(MASTER, "");
        if (queue.size() > 0) begin
            value = queue.pop_front();
            
            $display("Popped %0d from the queue. Queue size is now %0d.", value, queue.size());
        end else begin
            $display("Queue is empty. Cannot pop.");
        end
        access_sema.put(1);
    endtask

    // Method to check the current size of the queue
    function int size();
        return queue.size();
    endfunction
endclass
`endif