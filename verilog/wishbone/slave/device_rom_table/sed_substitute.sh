#! /bin/bash

echo "Fixing Wishbone Interface"
sed -i 's/wbs_we_i/i_wbs_we/g' *.v
sed -i 's/wbs_cyc_i/i_wbs_cyc/g' *.v
sed -i 's/wbs_sel_i/i_wbs_sel/g' *.v
sed -i 's/wbs_dat_i/i_wbs_dat/g' *.v
sed -i 's/wbs_stb_i/i_wbs_stb/g' *.v
sed -i 's/wbs_adr_i/i_wbs_adr/g' *.v
sed -i 's/wbs_ack_o/o_wbs_ack/g' *.v
sed -i 's/wbs_dat_o/o_wbs_dat/g' *.v
sed -i 's/wbs_int_o/o_wbs_int/g' *.v


