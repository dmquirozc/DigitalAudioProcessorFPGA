`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.03.2018 01:52:58
// Design Name: 
// Module Name: regControl
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


module regControl #(
		GLENGTH = 16
	)(
	input btnU,btnD, rst,clk,
	input[1:0] regSelect,
	output logic[GLENGTH-1:0] lowPReg,midPReg,highPReg
    );
		/*Finite state machine*/
	localparam INIT = 2'b00;
	localparam LP = 2'b01;
	localparam MP = 2'b10;
	localparam HP = 2'b11;

	localparam GAINLENGTH = GLENGTH;
	localparam MAXGAIN = 2**GAINLENGTH-1;
	logic [GAINLENGTH-1:0] lpRegNext,mpRegNext,hpRegNext;
	logic [1:0] state,stateNext;


	
	always_comb begin 
		stateNext = INIT;
		if(regSelect == LP) begin
			stateNext = LP;
		end else if(regSelect == MP) begin
			stateNext = MP; 
		end else if(regSelect == HP) begin
			stateNext = HP;
		end else begin
			stateNext = INIT; 
		end 
	end
	
	always_comb begin 
		lpRegNext = lowPReg;
        mpRegNext = midPReg;
        hpRegNext = highPReg;
	   	if(state == INIT) begin
              lpRegNext = lowPReg;
              mpRegNext = midPReg;
              hpRegNext = highPReg;
            
	   	end else if (state == LP) begin
			if(regSelect == LP) begin
				lpRegNext = (btnU == 1'b1 && lowPReg <  MAXGAIN)? lowPReg + 'd1: 
							(btnU == 1'b1 && lowPReg == MAXGAIN)? lowPReg:
							(btnD == 1'b1 && lowPReg >  'd0)? lowPReg -'d1:
							(btnD == 1'b1 && lowPReg == 'd0)? lowPReg: lowPReg;  

				mpRegNext = midPReg;
              	hpRegNext = highPReg;
			end
		end else if (state == MP) begin
			if(regSelect == MP) begin
				mpRegNext = (btnU == 1'b1 && midPReg <  MAXGAIN)? midPReg + 'd1: 
							(btnU == 1'b1 && midPReg == MAXGAIN)? midPReg:
							(btnD == 1'b1 && midPReg >  'd0)? midPReg -'d1:
							(btnD == 1'b1 && midPReg == 'd0)? midPReg: midPReg;  

				lpRegNext = lowPReg;
				hpRegNext = highPReg;
			end
		end else if (state == HP) begin
			if(regSelect == HP) begin
				hpRegNext = (btnU == 1'b1 && highPReg <  MAXGAIN)? highPReg + 'd1: 
							(btnU == 1'b1 && highPReg == MAXGAIN)? highPReg:
							(btnD == 1'b1 && highPReg >  'd0)? highPReg -'d1:
							(btnD == 1'b1 && highPReg == 'd0)? highPReg: highPReg; 

				lpRegNext = lowPReg;
              	mpRegNext = midPReg;
			end
		end 
	end

	always_ff@(posedge clk) begin
		if(rst == 1'b1) begin
			lowPReg <= 'd1;
			midPReg <= 'd1;
			highPReg <= 'd1;
			state <= INIT;
		end else begin

			lowPReg <= lpRegNext;
			midPReg <= mpRegNext;
			highPReg <= hpRegNext;
			state <= stateNext;
		end
	end
endmodule
