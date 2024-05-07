`ifndef GLOBAL_VARS
`define GLOBAL_VARS

//Operation Type
typedef enum {ADD, SUB, SHIFT} operation_t;

//Synchronisation primitives
event mms_sync; // Syncs master and monitor side in scoreboard.

event wait_scbd_to_finish; 
`endif