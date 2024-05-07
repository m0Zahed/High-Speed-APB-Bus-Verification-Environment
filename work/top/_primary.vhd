library verilog;
use verilog.vl_types.all;
entity top is
    generic(
        simulation_cycle: integer := 100
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of simulation_cycle : constant is 1;
end top;
