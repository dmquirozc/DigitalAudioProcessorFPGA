`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.03.2018 13:26:15
// Design Name: 
// Module Name: Overdrive
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


module Overdrive(
	input signed[15:0]FIRin,
	input clk,rst,active,dataready,
	output logic signed[15:0]OverOut
    );
    /* */
    
	localparam OVERIN = 16'd16383; //250mV -> en modo bipolar
	localparam NOVERIN =-16'sd16383;//-250mV en modo bipolar
	
	logic OverNext;
	
	always_comb begin
	   	if((active == 1'b1)) begin
	   		OverNext = ((FIRin> OVERIN) && (dataready == 1'b1))? {OVERIN}:
	   					(FIRin< NOVERIN) && (dataready == 1'b1)? {NOVERIN}:FIRin;
        end else begin
            OverNext = FIRin;
        end
	end
	
	always_ff@(posedge clk) begin
		if(rst) begin
		  OverOut <= 16'd0;
		end else begin
	       OverOut <= OverNext;   
		end
	end

endmodule
