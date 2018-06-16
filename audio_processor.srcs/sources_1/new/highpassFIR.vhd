Library IEEE;  
 USE IEEE.Std_logic_1164.all;   
 USE IEEE.Std_logic_signed.all;   
 -- fpga4student.com: FPGA projects, VHDL projects, Verilog projects   
 -- LOW pass FIR filter for ECG Denoising
 -- VHDL project: VHDL code for FIR filter   

 entity highpassFIR is -- VHDL projects
 generic (  
           input_width          : integer     := 16               ;-- set input width by user  
           output_width         : integer     := 93               ;-- set output width by user  
           coef_width           : integer     := 16               ;-- set coefficient width by user  
           tap                  : integer     := 61               ;-- set filter order  
           guard                : integer     := 0)               ;-- log2(tap)+1  
 port(  
      Din          : in      std_logic_vector(input_width-1 downto 0)     ;-- input data  
      Clk          : in      std_logic                                             ;-- input clk  
      reset     : in      std_logic                                             ;-- input reset  
      --doutSelect: in std_logic ; 
      Dout     : out      std_logic_vector(output_width-1 downto 0))     ;-- output data  
end highpassFIR;

architecture Behavioral of highpassFIR is
 
 -- N bit Register  
 component N_bit_Reg   
 generic (  
           input_width          : integer     :=8  
           );  
   port(  
    Q : out std_logic_vector(input_width-1 downto 0);     
    Clk :in std_logic;    
    reset :in std_logic;   
    D :in std_logic_vector(input_width-1 downto 0)    
   );  
 end component;
 -- fpga4student.com: FPGA projects, VHDL projects, Verilog projects  
 type Coeficient_type is array (1 to tap) of std_logic_vector(coef_width-1 downto 0);  
 -----------------------------------FIR filter coefficients----------------------------------------------------------------  
 constant coeficient: coeficient_type :=   
                               (    
                                   X"11f2",
                                   X"f755",
                                   X"f8d6",
                                   X"f9e5",
                                   X"faae",
                                   X"fb55",
                                   X"fbf1",
                                   X"fc95",
                                   X"fd49",
                                   X"fe14",
                                   X"feed",
                                   X"ffd3",
                                   X"00b4",
                                   X"0183",
                                   X"0230",
                                   X"02a2",
                                   X"02d1",
                                   X"02b0",
                                   X"0238",
                                   X"016c",
                                   X"004b",
                                   X"fedc",
                                   X"fd34",
                                   X"fb74",
                                   X"f995",
                                   X"f7d0",
                                   X"f630",
                                   X"f4cd",
                                   X"f3c2",
                                   X"f319",
                                   X"72e1",
                                   X"f319",
                                   X"f3c2",
                                   X"f4cd",
                                   X"f630",
                                   X"f7d0",
                                   X"f995",
                                   X"fb74",
                                   X"fd34",
                                   X"fedc",
                                   X"004b",
                                   X"016c",
                                   X"0238",
                                   X"02b0",
                                   X"02d1",
                                   X"02a2",
                                   X"0230",
                                   X"0183",
                                   X"00b4",
                                   X"ffd3",
                                   X"feed",
                                   X"fe14",
                                   X"fd49",
                                   X"fc95",
                                   X"fbf1",
                                   X"fb55",
                                   X"faae",
                                   X"f9e5",
                                   X"f8d6",
                                   X"f755",
                                   X"11f2");
 ----------------------------------------------------------------------------------------------                                     
 type shift_reg_type is array (0 to tap-1) of std_logic_vector(input_width-1 downto 0);  
 signal shift_reg : shift_reg_type;  
 
 type result_reg_type is array (0 to tap-1) of std_logic_vector(input_width+coef_width-1 downto 0);  
 signal result_reg  : result_reg_type;
 
 type mult_type is array (0 to tap-1) of std_logic_vector(input_width+coef_width-1 downto 0);  
 signal mult : mult_type;  
 
 type ADD_type is array (0 to tap-1) of std_logic_vector(input_width+coef_width+tap-1 downto 0);  
 signal ADD: ADD_type;  
 
 type ADD_reg_type is array (0 to tap-1) of std_logic_vector(input_width+coef_width+tap-1 downto 0);
 signal ADD_reg: ADD_reg_type;
 
 begin  
 -- fpga4student.com: FPGA projects, VHDL projects, Verilog projects
        shift_reg(0) <= Din;  
           mult(0)<= Din*coeficient(1);  
           result_reg(0)<= mult(0);
           ADD(0)<= Din*coeficient(1);  
           GEN_FIR:  
           for i in 0 to tap-2 generate  
           begin  
                 -- N-bit reg unit  
                 N_bit_Reg_unit : N_bit_Reg generic map (input_width => input_width)   
                 port map ( Clk => Clk,   
                                    reset => reset,  
                                    D => shift_reg(i),  
                                    Q => shift_reg(i+1)  
                                    );  
                 ADD_reg_unit : N_bit_Reg generic map (input_width => input_width+coef_width+tap)   
                 port map ( Clk => Clk,   
                                    reset => reset,  
                                    D => ADD(i),  
                                    Q => ADD_reg(i)  
                                    );            
                -- filter multiplication   
                Result_unit : N_bit_Reg generic map (input_width => input_width+coef_width)   
                 port map ( Clk => Clk,   
                                    reset => reset,  
                                    D => mult(i+1),  
                                    Q => result_reg(i+1)  
                                    ); 
                -- filter conbinational addition  
                mult(i+1) <= shift_reg(i+1)*coeficient(i+2); 

                ADD(i+1)<=ADD_reg(i)+result_reg(i+1);  
           end generate GEN_FIR;  
	        Dout <= ADD(tap-1);

 end Architecture;  
