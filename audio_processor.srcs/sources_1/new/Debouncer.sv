`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.06.2018 14:56:35
// Design Name: 
// Module Name: Debouncer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Debouncer(
	input clk,
	input rst,
	input btnU,
	input btnD,
	output upButton,
	output downButton

    );
	
	 pb_debouncer upButt (
      .clk(clk),
      .rst(rst),
      .pb(btnU),
      .pb_state(),
      .pb_negedge(),
      .pb_posedge(upButton)
      );
    pb_debouncer downButt (
      .clk(clk),
      .rst(rst),
      .pb(btnD),
      .pb_state(),
      .pb_negedge(),
      .pb_posedge(downButton)
      );

endmodule
