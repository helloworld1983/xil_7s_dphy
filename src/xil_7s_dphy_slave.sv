module xil_7s_dphy_slave #(
  parameter     DATA_LANES = 2,
  parameter int DELAY [4]  = '{0,0,0,0}
)(
  input                   dphy_clk_p_i,
  input                   dphy_clk_n_i,
  input  [DATA_LANES-1:0] dphy_data_p_i,
  input  [DATA_LANES-1:0] dphy_data_n_i,
  input                   ref_clk_i,
  input                   rst_i,
  input                   restart_phy_i
  output                  no_clock_rst_o,
  output [31:0]           data_o,
  output                  clk_o,
  output                  valid_o
);

logic                       bit_clk;
logic                       bit_clk_inv;
logic                       byte_clk;
logic                       byte_clk_present;
logic [DATA_LANES-1:0][7:0] byte_data;
logic [DATA_LANES-1:0][7:0] aligned_byte_data;
logic                       reset_aligner;
logic [DATA_LANES-1:0]      byte_valid;
logic [DATA_LANES-1:0][7:0] word_data;
logic                       word_valid;

assign no_clk_rst_o = ~byte_clk_present;
assign clk_o = byte_clk;

xil_7s_dphy_hs_clk_rx clk_phy
(
  .dphy_clk_p_i  ( dphy_clk_p_i ),
  .dphy_clk_n_i  ( dphy_clk_n_i ),
  .rst_i         ( rst_i        ),
  .bit_clk_o     ( bit_clk      ),
  .bit_clk_inv_o ( bit_clk_inv  ),
  .byte_clk_o    ( byte_clk     )
);

clk_detect dphy_clk_detect
(
  .ref_clk_i     ( ref_clk_i        ),
  .obs_clk_i     ( byte_clk         ),
  .rst_i         ( rst_i            ),
  .clk_present_o ( byte_clk_present )
);

generate
  begin : data_lane
    for( genvar i = 0; i < DATA_LANES; i++ )
      xil_7s_dphy_hs_data_rx #(
        .DELAY         ( DELAY[i]          ) 
      ) data_phy (
        .bit_clk_i     ( bit_clk           ),
        .bit_clk_inv_i ( bit_clk_inv       ),
        .byte_clk_i    ( byte_clk          ),
        .ref_clk_i     ( ref_clk_i         ),
        .rst_i         ( ~byte_clk_present ),
        .dphy_data_p_i ( dphy_data_p_i[i]  ),
        .dphy_data_n_i ( dphy_data_n_i[i]  ),
        .byte_data_o   ( byte_data[i]      )
      ); 
  end
endgenerate

generate
  begin : byte_sync
    for( genvar i = 0; i < DATA_LANES; i++ )
      dphy_byte_sync flow_synchronizer
      (
        .clk_i            ( byte_clk             ),
        .rst_i            ( ~byte_clk_present    ),
        .unaligned_byte_i ( byte_data[i]         ),
        .sync_reset_i     ( reset_sync           ),
        .valid_o          ( byte_valid[i]        ),
        .aligned_byte_o   ( aligned_byte_data[i] )
      );
  end
endgenerate

dphy_word_align #(
  .DATA_LANES      ( DATA_LANES        )
) word_aligner (
  .byte_clk_i      ( byte_clk          ),
  .rst_i           ( serdes_rst        ),
  .pkt_done_i      ( pkt_done_i        ),
  .byte_data_i     ( aligned_byte_data ),
  .valid_i         ( byte_valid        ),
  .reset_sync_o    ( reset_sync        ),
  .word_o          ( word_data         ),
  .valid_o         ( word_valid        )
);

dphy_32b_map #(
  .DATA_LANES   ( DATA_LANES )
) mapper (
  .byte_clk_i   ( byte_clk   ),
  .rst_i        ( serdes_rst ),
  .word_data_i  ( word_data  ),
  .valid_i      ( word_valid ),
  .maped_data_o ( data_o     ),
  .valid_o      ( valid_o    )
);

endmodule
