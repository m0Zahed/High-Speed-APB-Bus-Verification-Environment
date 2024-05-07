#########################################################################
## Purpose: Makefile for Chap_1_Verification_Guidelines/homework_solution
## Author: Chris Spear
##
## REVISION HISTORY:
## $Log: Makefile,v $
## Revision 1.1  2011/05/28 14:57:35  tumbush.tumbush
## Check into cloud repository
##
## Revision 1.2  2011/05/03 22:06:50  Greg
## Updated to common Makefile and to use Makefile_non_DPI
##
#########################################################################

FILES = top_env/env.sv tests/test.sv hdl/top.sv calc_env/calc_if.sv hdl/calc2_top.v
# utilities/global_utils.sv utilities/logger.sv calc_env/calc_gen.sv calc_env/calc_mst.sv calc_env/calc_trans.sv hdl/top.sv 
# calc_env/calc_if.sv 
TOPLEVEL = top

include ./Makefiles/non_DPI/Makefile_non_DPI
