library verilog;
use verilog.vl_types.all;
entity ports_if is
    generic(
        DATA_WIDTH      : integer := 32;
        CMD_WIDTH       : integer := 4;
        TAG_WIDTH       : integer := 2
    );
    port(
        clk             : in     vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of DATA_WIDTH : constant is 1;
    attribute mti_svvh_generic_type of CMD_WIDTH : constant is 1;
    attribute mti_svvh_generic_type of TAG_WIDTH : constant is 1;
end ports_if;
