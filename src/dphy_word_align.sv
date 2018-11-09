// This module performs word aligning from other byte aligners
// There can be a situation when bytes from one or several lines
// are delayed to others:
//
//   <DATA_4><DATA_2><DATA_0>
//   <DATA_3><DATA_1><XXXXXX>
//   ___     ___     ___
//  |   |___|   |___|   |___
//
// This module perform following transformation by delaying
// advancing data lanes up to 2 clock cycles;
//
//  <DATA_4><DATA_2><DATA_0>
//  <DATA_5><DATA_3><DATA_1>
//   ___     ___     ___
//  |   |___|   |___|   |___
//
module dphy_word_align #(
  parameter DATA_LANES = 4
)(
  input                              byte_clk_i,
  input                              rst_i,
  input                              pkt_done_i,
  input        [DATA_LANES-1:0][7:0] byte_data_i,
  input        [DATA_LANES-1:0]      valid_i,
  output logic                       reset_sync_o,
  output logic [DATA_LANES-1:0][7:0] word_o,
  output logic                       valid_o
);

logic [DATA_LANES-1:0][7:0] word_d1;
logic [DATA_LANES-1:0][7:0] word_d2;
logic [DATA_LANES-1:0][7:0] word_d3;
logic [DATA_LANES-1:0]      valid_d1;
logic [DATA_LANES-1:0]      valid_d2;
logic [DATA_LANES-1:0]      valid_d3;
logic [DATA_LANES-1:0][1:0] sel_delay;
logic [DATA_LANES-1:0][1:0] sel_delay_reg;
logic                       one_lane_sync;
logic                       all_lanes_valid;

// This signal is indicating that all data lanes have valid data
// regardless of their mutual delay.
assign all_lanes_valid = &valid_d1;
// False alarm. If one lane is being valid for 3 clock cycles
// and at least one never was.
assign invalid_start   = one_lane_sync && ~all_lanes_valid;
// We reset data PHYs due to invalid start or if upper protocol level asks us to.
assign reset_sync_o    = pkt_done_i || invalid_start;

always_ff @( posedge byte_clk_i )
  if( rst_i )
    begin
      word_d1  <= '0;
      word_d2  <= '0;
      word_d3  <= '0;
      valid_d1 <= '0;
      valid_d2 <= '0;
      valid_d3 <= '0;
    end
  else
    begin
      word_d1  <= byte_data_i;
      word_d2  <= word_d1;
      word_d3  <= word_d2;
      valid_d1 <= valid_i;
      valid_d2 <= valid_d1;
      valid_d3 <= valid_d2;
    end

// We assert valid_o as long as upper level protocol
// won't ask us to deassert it
always_ff @( posedge byte_clk_i )
  if( rst_i )
    valid_o <= 1'b0;
  else
    if( pkt_done_i )
      valid_o <= 1'b0;
    else
      if( all_lanes_valid && &valid_i )
        valid_o <= 1'b1;

// Shows if at least one data lane is valid for 3 clock cycles
always_comb
  begin
    one_lane_sync = 1'b0;
    for( int i = 0; i < DATA_LANES; i++ )
      if( valid_d1[i] && valid_d2[i] && valid_d3[i] )
        one_lane_sync = 1'b1;
  end

// Here we decide which of delayed data samples we should use
// as output.
always_ff @( posedge byte_clk_i )
  if( rst_i )
    sel_delay_reg <= '0;
  else
    sel_delay_reg <= sel_delay;

always_comb
  begin
    sel_delay = sel_delay_reg;
    if( all_lanes_valid && ~valid_o )
      for( int i = 0; i < DATA_LANES; i++ )
        if( valid_d3[i] )
          sel_delay[i] = 2'd2;
        else
          if( valid_d2[i] )
            sel_delay[i] = 2'd1;
          else
            sel_delay[i] = 2'd0;
  end

always_ff @( posedge byte_clk_i )
  if( rst_i )
    word_o <= '0;
  else
    for( int i = 0; i < DATA_LANES; i++ )
      if( sel_delay[i] == 2'd2 )
        word_o[i] <= word_d3[i];
      else
        if( sel_delay[i] == 2'd1 )
          word_o[i] <= word_d2[i];
        else
          word_o[i] <= word_d1[i];

endmodule
