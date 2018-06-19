`timescale 1ns / 1ps
module pwm #(
	parameter PWMWIDTH = 12,
	parameter SIGNED = 1
	)( 
	input clk,//ready,
	input [PWMWIDTH-1:0] PWM_in, 
	output reg PWM_out,
	output reg aud_sd
);
localparam MAXCOUNT = 2**PWMWIDTH-1;
	localparam SIGNADJUST = 1<<(PWMWIDTH-1);
reg [PWMWIDTH-1:0]new_pwm='d0;
reg [PWMWIDTH-1:0]PWM_ramp='d0; 
reg [PWMWIDTH-1:0]PWM_rampNext;

always_comb begin
	PWM_rampNext = PWM_ramp +'d1;
	if(PWM_ramp == MAXCOUNT-1) begin
		PWM_rampNext = 'd0;
	end
end
always @(posedge clk) 
begin
    if (PWM_ramp == 'd0 && SIGNED == 0) begin
    	 new_pwm <= PWM_in;
    	 //PWM_ramp <= 'd0;
    	 //aud_sd <= 1'b0;
   	end else if(PWM_ramp == 'd0 && SIGNED == 1) begin
   		new_pwm <= PWM_in + SIGNADJUST; // conversion de PWM con signo
    end
      PWM_ramp <= PWM_rampNext;
      PWM_out <=(new_pwm > PWM_ramp);
      //aud_sd <= (new_pwm > PWM_ramp);
end
	assign aud_sd = 1'b1;
endmodule
