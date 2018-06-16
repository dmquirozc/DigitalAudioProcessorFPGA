
module Top(
   input CLK100MHZ,
   input cpu_rstn,BTNU,BTND,
   input vp_in,   //voltajes de referencia positivo interno del ADC
   input vn_in,   // voltaje de referencia negativo interno del ADC
   input vauxp11, // conexion directa al pin vauxp11 de la tarjeta
   input vauxn11, // conexion directa al pin vauxn11 de la tarjeta
   input logic [8:0] sw,
   input logic FIR,OVER,DELAY,
   output logic [2:1] JA,
   output logic [15:0] LED,
   output [7:0] an,
   output dp,
   output [6:0] seg, 
   output AUD_PWM,AUD_SD
 );
   localparam PWMFREQ = 44_000;
   localparam PWMWIDTH = 16;
   localparam PWMCLK = PWMFREQ*PWMWIDTH;
   localparam BITSPWM = PWMWIDTH - 1-3;
   localparam FIRORDER = 11;
   localparam GUARDORDER = CLogB2(FIRORDER)+1;
   logic enable;    
   logic ready;
   logic [15:0] data;   
   //logic[6:0] Address_in;
   logic rst;
   logic[15:0] dataADC;
   assign rst = ~cpu_rstn;
    
   logic clkGeneral,clkPWM;
   clk_wiz_0 generalClock
  (
  // Clock out ports  
  .clkGeneral(clkGeneral),
  .clkPWM(clkPWM),
 // Clock in ports
  .clk_in1(CLK100MHZ)
  );

  //logic[6:0] Address_in;

  // always_ff@(posedge(CLK100MHZ))
  //     begin
  //       case(sw[8:7])
  //       0: Address_in <= 8'h12;
  //       1: Address_in <= 8'h13;
  //       2: Address_in <= 8'h1a;
  //       3: Address_in <= 8'h1b;
  //       endcase     
  // end
  //xadc instantiation connect the eoc_out .den_in to get continuous conversion
   xadc_wiz_0  XLXI_7 (
     .daddr_in(8'h1b), //direccion que dice que se usaran los puertos vaux11
     .dclk_in(clkGeneral), 
     .den_in(enable), 
     .di_in(0), 
     .dwe_in(0), 
     .busy_out(),
     // .vauxp2(vauxp2),
     // .vauxn2(vauxn2),
     // .vauxp3(vauxp3),
     // .vauxn3(vauxn3),
     // .vauxp10(vauxp10),
     // .vauxn10(vauxn10),                    
     .vauxp11(vauxp11),
     .vauxn11(vauxn11),
     .vn_in(vn_in), 
     .vp_in(vp_in), 
     .alarm_out(), 
     .do_out(data), 
     .reset_in(rst),
     .eoc_out(enable),
     .eos_out(),
     .channel_out(),
     //.user_temp_alarm_out(),
     .drdy_out(ready)
      );
      
    logic rdy;
    always_ff@(posedge clkGeneral) begin
      dataADC <= data;
      rdy <= ready;
      JA[1] <= rdy; // para ver la señal de reloj del ADC
    end
    
    
//////////////////////////////////////////////////////////////
  
    logic uButton,dButton;

    Debouncer Deb (
      .clk(clkGeneral),
      .rst(rst),
      .btnU(BTNU),
      .btnD(BTND),
      .upButton(uButton),
      .downButton(dButton)
      );

/////////////////////////////////////////////////////////////
    logic[15:0]FIROut;
    logic[PWMWIDTH-1:0] DelayOut;
    logic[PWMWIDTH-1:0] OverOut;
    logic[15:0]gainIndicator;
    BankFIR filterBank (
        .clk(clkGeneral),
        .rst(rst),
        .ready(rdy),
        .regSelect(sw[4:3]), // seleccion de registros de ganancia
        .sourceSelect(sw[2:1]), // seleccion del filtro que se utiliza
        .allPass(sw[0]),
        .btnU(uButton),
        .btnD(dButton),
        .dataADC(dataADC[PWMWIDTH-1:0]),
        .FIROut(FIROut),
        .gain(gainIndicator)
      );

      
      Overdrive over(
        .clk(clkGeneral),
        .rst(rst),
        .dataready(rdy),
        .active(sw[5]), // si se activa el OVERDRIVe
        .FIRin(DelayOut), //DelayOut
        .OverOut(OverOut)
        );
        
      
      Delay #(.DELAY(120),.CLOCK(50)) 
           delay(
            .clk(clkGeneral),
            .rst(rst),
            .active(sw[6]), //si se activa el delay
            .dataready(rdy),
            .delayIn(FIROut), //FIROut
            .delayFreq(JA[2]), 
            .delayOut(DelayOut)
      );
      
      logic[BITSPWM-1:0] lpFirOutGeneral;
      logic[BITSPWM-1:0] FirOut,OverdriveOut,delayOut;
      logic[BITSPWM-1:0] lpFirOutPWM,FirOutPWM,OverdriveOutPWM,delayOutPWM;
      logic[BITSPWM-1:0] pwmIn;
      always@(posedge clkGeneral) begin
          lpFirOutGeneral <= OverOut[15:4]; // 12 bits PWM out
          FirOut <=FIROut[15:4];
          OverdriveOut<=OverOut[15:4];
          delayOut <=DelayOut[15:4];
      end

      /* Cambio de dominio de reloj de la senhal*/
      always_ff@(posedge clkPWM ) begin 
          lpFirOutPWM <= lpFirOutGeneral;
          FirOutPWM <=FirOut;
          OverdriveOutPWM<=OverdriveOut;
          delayOutPWM <=delayOut;
      end


      always_ff@(posedge clkPWM) begin
         pwmIn <= (FIR)? FirOutPWM:
                  (OVER)? OverdriveOutPWM:
                  (DELAY)? delayOutPWM:lpFirOutPWM; 
      end 

  /* Modulo generador de senhales PWM*/
  pwm #(
      .PWMWIDTH(BITSPWM),
      .SIGNED(1)
      ) pwm_gen (
      .clk(clkPWM),
      //.ready(ready),
      .PWM_in(pwmIn),
      .PWM_out(AUD_PWM),
      .aud_sd(AUD_SD)
    );
    //assign chGain = dButton | uButton;
      //led visual dmm              
    always @( posedge(clkGeneral))
      begin            
        if(ready == 1'b1)
        begin
          case (data[15:12])
            1:  LED <= 16'b11;
            2:  LED <= 16'b111;
            3:  LED <= 16'b1111;
            4:  LED <= 16'b11111;
            5:  LED <= 16'b111111;
            6:  LED <= 16'b1111111; 
            7:  LED <= 16'b11111111;
            8:  LED <= 16'b111111111;
            9:  LED <= 16'b1111111111;
            10: LED <= 16'b11111111111;
            11: LED <= 16'b111111111111;
            12: LED <= 16'b1111111111111;
            13: LED <= 16'b11111111111111;
            14: LED <= 16'b111111111111111;
            15: LED <= 16'b1111111111111111;                        
           default: LED <= 16'b1; 
           endcase
        end    
      end
    
      

    logic[31:0] bcd;
    logic[31:0]uint32_in ;

    always_comb begin
      case(sw[7])
          1'b0:    uint32_in = {16'd0,dataADC};
          default:  uint32_in = bcd;
      endcase // sw[5:4]
    end // always_comb

    unsigned_to_bcd u32_to_bcd_inst (
        .clk(clkGeneral),
        .trigger(1'b1),
        .in({16'd0,gainIndicator}),
        .idle(),
        .bcd(bcd)
    );

    logic clk_ss;
    clk_divider #(.O_CLK_FREQ(480)
      ) clk_div_ss_display (
      .clk_in(CLK100MHZ),
      .reset(rst),
      .clk_out(clk_ss)
    );

    /* Multiplexor para display de 7 segmentos */
    display_mux display_mux_inst (
      .clk(clk_ss),
      .clk_enable(1'b1),
      .bcd(uint32_in),
      .dots({8'd0}),
      .is_negative(1'b0),
      .turn_off(1'b0),
      .ss_value({dp,seg}),
      .ss_select(an)
  );
  
  
  function integer CLogB2;
      input [31:0] Depth;
      integer i;
      begin
          i = Depth;        
          for(CLogB2 = 0; i > 0; CLogB2 = CLogB2 + 1)
              i = i >> 1;
      end
  endfunction


endmodule
