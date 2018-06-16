
Library IEEE;  
 USE IEEE.Std_logic_1164.all;   
 USE IEEE.Std_logic_signed.all;   
 -- fpga4student.com: FPGA projects, VHDL projects, Verilog projects   
 -- LOW pass FIR filter for ECG Denoising
 -- VHDL project: VHDL code for FIR filter   
entity midpassFIR is  -- VHDL projects
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
end midpassFIR;
architecture Behavioral of midpassFIR is  
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
                                   X"3c90",
                                   X"b12c",
                                   X"dbfa",
                                   X"f495",
                                   X"026e",
                                   X"09e4",
                                   X"0d56",
                                   X"0df3",
                                   X"0c36",
                                   X"0867",
                                   X"02bb",
                                   X"fb59",
                                   X"f26b",
                                   X"e889",
                                   X"de92",
                                   X"d522",
                                   X"cd32",
                                   X"c806",
                                   X"c5e7",
                                   X"c7dd",
                                   X"cdea",
                                   X"d827",
                                   X"e61f",
                                   X"f707",
                                   X"09cd",
                                   X"1d18",
                                   X"2f82",
                                   X"3f87",
                                   X"4c05",
                                   X"53ec",
                                   X"5699",
                                   X"53ec",
                                   X"4c05",
                                   X"3f87",
                                   X"2f82",
                                   X"1d18",
                                   X"09cd",
                                   X"f707",
                                   X"e61f",
                                   X"d827",
                                   X"cdea",
                                   X"c7dd",
                                   X"c5e7",
                                   X"c806",
                                   X"cd32",
                                   X"d522",
                                   X"de92",
                                   X"e889",
                                   X"f26b",
                                   X"fb59",
                                   X"02bb",
                                   X"0867",
                                   X"0c36",
                                   X"0df3",
                                   X"0d56",
                                   X"09e4",
                                   X"026e",
                                   X"f495",
                                   X"dbfa",
                                   X"b12c",
                                   X"3c90");
                                    --   X"F1",  
                                      --  X"F3",  
                                     --  X"07",  
                                     --   X"26",  
                                     --   X"42",  
                                     --   X"4E",  
                                     --   X"42",  
                                     --   X"26",  
                                     --   X"07",  
                                     --   X"F3",  
                                     --   X"F1"                                     
                                    --    ); 
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
