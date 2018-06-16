`timescale 1ns / 1ps

module Delay #(
       parameter DELAY = 60,    // delay en ms  
       parameter CLOCK = 50     //CLK en khz del adc
    )(
    input signed[15:0]delayIn,
	input clk,rst,active,dataready,
	output logic delayFreq,
	output logic signed [15:0]delayOut // senhal para ver la frecuencia de actualizacion de datos del efecto.
    );

    localparam DELAYMAX = CLOCK*DELAY; // asumiendo que el reloj es 50MHz 

    /* Arreglo que guarda los datos necesarios para un efecto delay de 60ms*/
    logic signed [15:0]delayArray[0:DELAYMAX-1];
    logic [15:0]delayMed,delayQua;

    /* Senhal que guarda la salida del modulo*/
    logic signed [17:0] delayNext;

    /* Logica de activacion del modulo */
    always_comb begin 

        if(active == 1'b1) begin
            /*multiplicacion por un decimal??  1 + 0.5 + 0.25*/
            /*operador >>> -> corriemiento con signo*/
            delayNext = (dataready)? delayArray[DELAYMAX-1] + (delayArray[DELAYMAX/2]>>>1)
                            +  (delayArray[0]>>>2):{delayOut,3'd0};
                        
        end else begin
            delayNext = (dataready)? {delayArray[DELAYMAX-1],3'd0}:{delayOut,3'd0};
        end
    end

    
    /* Actualizacion de los datos del arreglo */
    always_ff@(posedge clk) begin
        if(rst == 1'b1) begin
            delayArray[0] <= delayIn;

            for(int i = 1;i<DELAYMAX;i++) begin
                delayArray[i]<= 16'd0;
            end

            delayOut <= 16'd0;
            
        end else if(dataready == 1'b1) begin
            delayArray[0]<= delayIn;

            for(int i = 1;i < DELAYMAX;i++) begin
            delayArray[i]<= delayArray[i-1];
            end

            delayOut<= delayNext[17:2];
        end else begin
            for(int i = 0;i < DELAYMAX;i++) begin
                delayArray[i]<= delayArray[i];
            end
            delayOut<=delayOut;
        end
        
    end 
    
    logic[15:0] counter;
       
    always_ff@(posedge clk) begin
        if(rst) begin
            counter<= 'd0;
            delayFreq <= 1'b1;
        end else if(counter == DELAYMAX/2) begin
            delayFreq <= 1'b0;
        end else if(counter == DELAYMAX-1) begin
            delayFreq<=1'b1;
            counter<= 'd0;
        end else begin
            delayFreq<= delayFreq;
            counter<= counter+1;
        end
    end
    

        
endmodule
