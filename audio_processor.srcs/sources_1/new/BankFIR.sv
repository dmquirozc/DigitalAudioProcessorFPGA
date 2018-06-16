`timescale 1ns / 1ps


module BankFIR(
	input clk,rst,ready,
	input [1:0] regSelect,
	input [1:0] sourceSelect,
	input allPass,
	input btnU,btnD,
	input [15:0]dataADC,
	output logic[15:0]FIROut,
	output logic[15:0] gain
    );
	localparam PWMWIDTH = 16;
	localparam GAINLENGTH = 4;
	localparam MULT = 16;
	localparam TAP = 61;
	localparam FIROUTWIDTH = 16;

	localparam INIT = 2'b00;
	localparam LP = 2'b01;
	localparam MP = 2'b10;
	localparam HP = 2'b11;
	

	/* Senhales necesarias para el funcionamiento de los filtros*/
	logic outDataValid,inDataReady;
  	//logic[2*FIROUTWIDTH+TAP-1:0]LPoutDataVector,HPoutDataVector,MPoutDataVector;
  	logic[15:0]APoutDataVector;
  	logic[15:0]LPoutDataVector,HPoutDataVector;
  	logic[15:0]MPoutDataVector;
  	logic islValid,ismValid,ishValid,isaValid;



    
	// lowpassFIR lowpass (
	// .Clk(clk),
	// .reset(rst),
	// .Din(dataADC[PWMWIDTH-1:0]),
	// .Dout(LPoutDataVector)
	// );
	
 //    midpassFIR midpass (
 //    .Clk(clk),
 //    .reset(rst),
 //    .Din(dataADC[PWMWIDTH-1:0]),
 //    .Dout(MPoutDataVector)
 //    );
    

 //    highpassFIR highpass (
 //    .Clk(clk),
 //    .reset(rst),
 //    .Din(dataADC[PWMWIDTH-1:0]),
 //    .Dout(HPoutDataVector)
 //    );
	// always_comb begin
	// 	LPdataNext = (ready)? LPoutDataVector[2*FIROUTWIDTH+TAP-1:2*FIROUTWIDTH+TAP-1-MULT]*(lpReg+1):LPdata;//  //isValid changed for ready
	// 	MPdataNext = (ready)? MPoutDataVector[2*FIROUTWIDTH+TAP-1:2*FIROUTWIDTH+TAP-1-MULT]*(mpReg+1):MPdata;//
	// 	HPdataNext = (ready)? HPoutDataVector[2*FIROUTWIDTH+TAP-1:2*FIROUTWIDTH+TAP-1-MULT]*(hpReg+1):HPdata;//	
	// end



	/* Filtro FIR pasa bajos de orden 60  freq = 10hz - 1khz*/

  	  fir_compiler_0 lopass 
        (.aclk(clk),
          .s_axis_data_tvalid(ready),			
          .s_axis_data_tready(),				
          .s_axis_data_tdata(dataADC[PWMWIDTH-1:0]),
          .m_axis_data_tvalid(islValid),		
          .m_axis_data_tdata(LPoutDataVector)	
	);

	/* Filtro FIR pasa medios de orden 60  freq = 1kh - 2.4khz*/

	 fir_compiler_1 midpass 
        (.aclk(clk),
          .s_axis_data_tvalid(ready),			
          .s_axis_data_tready(),				
          .s_axis_data_tdata(dataADC[PWMWIDTH-1:0]),
          .m_axis_data_tvalid(ismValid),		
          .m_axis_data_tdata(MPoutDataVector)	
	);

   


    /* Filtro FIR pasa altos de orden 60 freq = 2.4khz - 4khz*/

     fir_compiler_2 highpass 
        (.aclk(clk),
          .s_axis_data_tvalid(ready),			
          .s_axis_data_tready(),				
          .s_axis_data_tdata(dataADC[PWMWIDTH-1:0]),
          .m_axis_data_tvalid(ishValid),		
          .m_axis_data_tdata(HPoutDataVector)	
	);

	Delay #(.DELAY(60),.CLOCK(1)) 
           delay(
            .clk(clk),
            .rst(rst),
            .active(1'b0), //si se activa el delay
            .dataready(ready),
            .delayIn(dataADC), //FIROut
            .delayFreq(), 
            .delayOut(APoutDataVector)
      );
/* filtro pasa todo.. generado con el IP core de filtros,no funciona xD*/
/*
    fir_compiler_3 allpass 
        (.aclk(clk),
          .s_axis_data_tvalid(ready),			
          .s_axis_data_tready(),				
          .s_axis_data_tdata(dataADC[PWMWIDTH-1:0]),
          .m_axis_data_tvalid(isaValid),		
          .m_axis_data_tdata(APoutDataVector)	
	);

*/
	/*Gain Registers control*/
	logic signed [MULT+2:0]sumData;
	logic signed [MULT-1:0]multFir,multFirNext;
	logic signed[MULT-1:0]LPdata,MPdata,HPdata;
	logic signed [MULT-1:0]LPdataNext,MPdataNext,HPdataNext;
	logic[GAINLENGTH-1:0]lpReg,mpReg,hpReg;
	logic[PWMWIDTH-1:0]gainReg;
	
	logic[GAINLENGTH-1:0]lp,mp,hp;
	



	always_comb begin
		LPdataNext = 	(ready)? {LPoutDataVector[PWMWIDTH-1:4],4'd0}*(lpReg+1):
						//(ready && LPoutDataVector[15]==1'b1)? {LPoutDataVector[PWMWIDTH-1:4]}*(lpReg+1):
						LPdata;  //isValid changed for ready
		MPdataNext = 	(ready)? {MPoutDataVector[PWMWIDTH-1:4],4'd0}*(mpReg+1):
						//(ready && MPoutDataVector[15]==1'b1)? {MPoutDataVector[PWMWIDTH-1:4]}*(mpReg+1):
						MPdata;
		HPdataNext = 	(ready)? {HPoutDataVector[PWMWIDTH-1:4],4'd0}*(hpReg+1):
						//(ready && HPoutDataVector[15]==1'b1)? {HPoutDataVector[PWMWIDTH-1:4],4'd0}*(hpReg+1):
						HPdata;	
	end
	always_comb begin
		
		case(regSelect)
			LP: gain = lpReg;
			MP: gain = mpReg;
			HP:	gain = hpReg;
			default: gain = gainReg;
		endcase	
	end // always_comb


	always_comb begin
		multFirNext = sumData[MULT+2:MULT+2-PWMWIDTH];
		case(sourceSelect)
			2'b00:	multFirNext = sumData[MULT+2:MULT+2-PWMWIDTH];
			2'b01:	multFirNext = LPdata;
			2'b10:	multFirNext = MPdata;
			2'b11: 	multFirNext = HPdata;
		endcase
	end // always_comb
	
	always_ff @(posedge clk) begin	
		if(rst) begin
			 sumData <= 'd0;
			 multFir <= 'd0;
		end else begin
			 sumData <= LPdata + MPdata + HPdata;
			 multFir <= multFirNext;
		end
	end


	/* Modulo para controlar la ganancia de los filtros */
	
	regControl #(
			.GLENGTH(GAINLENGTH)
			)GainControl(
			.clk(clk),
			.rst(rst),
			.btnU(btnU),
			.btnD(btnD),
			.regSelect(regSelect),
			.lowPReg(lp),
			.midPReg(mp),
			.highPReg(hp)
		);
		
	
	always_ff@(posedge clk) begin
		lpReg <= lp;
		mpReg <= mp;
		hpReg <= hp;
		LPdata <= LPdataNext;
		MPdata <= MPdataNext;
		HPdata <= HPdataNext;
		gainReg <= multFir[MULT-1:MULT-PWMWIDTH];
		FIROut <= (allPass==1'b1)? APoutDataVector:gainReg;
	end


endmodule
