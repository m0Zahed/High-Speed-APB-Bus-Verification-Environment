`ifndef _LOGGER_
`define _LOGGER_
typedef enum {GENERATOR, MASTER, MONITOR, SCOREBOARD, ENVIRONMENT, TEST, TOP, TRANSACTION, INTF} location;

// Declare a function
// Function to convert location enum to string
function automatic string location_to_string(location loc);
    case (loc)
        GENERATOR: return "  GENERATOR";
        MASTER: return "     MASTER";
        MONITOR: return "    MONITOR";
        SCOREBOARD: return " SCOREBOARD";
        ENVIRONMENT: return "ENVIRONMENT";
        TEST: return "       TEST";
        TOP: return "        TOP";
        INTF: return "  INTERFACE";
        default: return "UNKNOWN   ";
    endcase
endfunction

function automatic void log(location loc, string post_fix);
    
    if(location_to_string(loc) != "UNKNOWN   ")
    begin
        $display("At time %0t: %s | %s", $time, location_to_string(loc), post_fix);    
    end else begin
        $display("Log error -");
    end 

endfunction

function automatic string add_prefix (location loc);
  return $sformatf("At time %0t: %s | ", $time, location_to_string(loc)); 
endfunction

`endif
