// This is Xilinx 7 series specific module and it is designed to create 
// necessary clocks from input D-PHY differential clock.
module xil_7s_dphy_hs_clk_rx 
(
  input        dphy_clk_p_i,
  input        dphy_clk_n_i,
  input        rst_i,
  output logic bit_clk_o,
  output logic bit_clk_inv_o,
  output logic byte_clk_o
);

logic bit_clk;

// Convert input differnetial D-PHY clock to single-ended bit clock.
IBUFDS #(
  .DIFF_TERM    ( 1            ),
  .IBUF_LOW_PWR ( 0            ),
  .IOSTANDARD   ( "DEFAULT"    )
) clk_diff_input (
  .O            ( bit_clk      ),
  .I            ( dphy_clk_p_i ),
  .IB           ( dphy_clk_n_i )
);

// Passes our single-ended bit clock to clock distribution network.
BUFIO clk_buf (
  .O ( bit_clk_o ),
  .I ( bit_clk   )
);

// Create another clock divided by 4, which is byte clock
BUFR #(
  .BUFR_DIVIDE ( "4"        ),
  .SIM_DEVICE  ( "7SERIES"  )
) clk_divider (
  .O           ( byte_clk_o ),
  .CE          ( 1'b1       ),
  .CLR         ( rst_i      ),
  .I           ( bit_clk_o  )
);

// Is needed by ISERDESE2 in data lane PHY
assign bit_clk_inv_o = ~bit_clk_o;

endmodule
