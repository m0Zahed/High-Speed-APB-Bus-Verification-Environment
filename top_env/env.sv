`ifndef __ENV__
`define __ENV__
`include "calc_env/calc_trans.sv"
`include "calc_env/calc_if.sv"
`include "calc_env/calc_mst.sv"
`include "calc_env/calc_monitor.sv"
`include "calc_env/calc_gen.sv"
`include "top_env/calc_scb.sv"

////////////////////////////////////////////////////////////
class test_cfg;

  // Test terminates when the trans_cnt is greater than max_trans_cnt member
  rand int trans_cnt;

  constraint basic {
    (trans_cnt > 0) && (trans_cnt < 500);
  }
endclass: test_cfg



class env;

  // Test configurations
  test_cfg    tcfg;

  // Transactors
  calc_gen     gen;
  calc_mst  mst;
  calc_monitor mon;
  scoreboard  scb;

  // APB transaction mailbox. Used to pass transaction
  // from APB gen to APB master, master to scoreboard, and monitor to scoreboard
  mailbox #(calc_trans) gen2mas;
  mailbox #(calc_trans) mas2scb[4];
  mailbox #(calc_trans) mon2scb[4];

  virtual calc_if port[];


  function new(virtual calc_if port_intf);
    //Initialise ----------------------------------------
    //this.calc_interface  = calc_interface;
    gen2mas   = new();
    mas2scb[0]   = new();
    mas2scb[1]   = new();
    mas2scb[2]   = new();
    mas2scb[3]   = new();

    mon2scb[0]   = new();
    mon2scb[1]   = new();
    mon2scb[2]   = new();
    mon2scb[3]   = new();

    //Configure -----------------------------------------
    tcfg      = new();
    if (!tcfg.randomize()) 
      begin
        $display("test_cfg::randomize failed");
        $finish;
      end
    

    //Instantiate ----------------------------------------
    gen      = new(gen2mas, tcfg.trans_cnt, 1);
    mst      = new(gen2mas, mas2scb, 1, port_intf, tcfg.trans_cnt);
    mon      = new(port_intf.port, mon2scb);
    scb      = new(tcfg.trans_cnt, mas2scb, mon2scb, 1, port_intf);
   
  endfunction: new


  virtual task pre_test();
    // Make sure the same # of transactions are expected by the scoreboard
    //  scb.max_trans_cnt = gen.max_trans_cnt;
    $display("Pretest has started.");
     fork
      scb.main();
      mst.main();
      mon.main();
     join_none
  endtask: pre_test


  virtual task test();
    $display("Main test has started.");
    fork
      gen.main();
    join_none
  endtask: test


  virtual task post_test();
    $display("Running post-test.");
     
  endtask: post_test


  task run();
    pre_test();
    test();
    post_test();
  endtask: run

endclass: env


`endif
