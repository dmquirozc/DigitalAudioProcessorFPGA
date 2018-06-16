Library IEEE;  
 USE IEEE.Std_logic_1164.all;   
 USE IEEE.Std_logic_signed.all;   
 -- fpga4student.com: FPGA projects, VHDL projects, Verilog projects   
 -- LOW pass FIR filter for ECG Denoising
 -- VHDL project: VHDL code for FIR filter 
 -- modified by: Damian Quiroz  
 entity lowpassFIR is  -- VHDL projects
 generic (  
           input_width          : integer     := 16               ;-- set input width by user  
           output_width         : integer     := 93              ;-- set output width by user  
           coef_width           : integer     := 16               ;-- set coefficient width by user  
           tap                  : integer     := 61               ;-- set filter order  
           guard                : integer     := 0)               ;-- log2(tap)+1  
 port(  
      Din          : in      std_logic_vector(input_width-1 downto 0)     ;-- input data  
      Clk          : in      std_logic                                             ;-- input clk  
      reset        : in      std_logic                                             ;-- input reset  
      --doutSelect: in std_logic ; 
      Dout         : out      std_logic_vector(output_width-1 downto 0))     ;-- output data  
 end lowpassFIR;  
 architecture behaivioral of lowpassFIR is  
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
 
-- 60 tap FIR coefficients 
 type Coeficient_type is array (1 to tap) of std_logic_vector(coef_width-1 downto 0);  
 -----------------------------------FIR filter coefficients----------------------------------------------------------------  
 constant coeficient: coeficient_type :=   
                               (    
                                   X"fe89",
                                   X"c3be",
                                   X"ed7b",
                                   X"e9de",
                                   X"e79b",
                                   X"e5b4",
                                   X"e43d",
                                   X"e35b",
                                   X"e318",
                                   X"e390",
                                   X"e4c2",
                                   X"e6c3",
                                   X"e98d",
                                   X"ed2e",
                                   X"f192",
                                   X"f6b4",
                                   X"fc70",
                                   X"02b2",
                                   X"0966",
                                   X"106c",
                                   X"1783",
                                   X"1e93",
                                   X"2587",
                                   X"2c0c",
                                   X"321f",
                                   X"3789",
                                   X"3c26",
                                   X"3fe2",
                                   X"429b",
                                   X"4449",
                                   X"44d6",
                                   X"4449",
                                   X"429b",
                                   X"3fe2",
                                   X"3c26",
                                   X"3789",
                                   X"321f",
                                   X"2c0c",
                                   X"2587",
                                   X"1e93",
                                   X"1783",
                                   X"106c",
                                   X"0966",
                                   X"02b2",
                                   X"fc70",
                                   X"f6b4",
                                   X"f192",
                                   X"ed2e",
                                   X"e98d",
                                   X"e6c3",
                                   X"e4c2",
                                   X"e390",
                                   X"e318",
                                   X"e35b",
                                   X"e43d",
                                   X"e5b4",
                                   X"e79b",
                                   X"e9de",
                                   X"ed7b",
                                   X"c3be",
                                   X"fe89");
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
                -- filter combinational addition  
                mult(i+1) <= shift_reg(i+1)*coeficient(i+2); 

                ADD(i+1)<=ADD_reg(i)+result_reg(i+1);  
           end generate GEN_FIR;  
	        Dout <= ADD(tap-1);

 end Architecture;  

 Library IEEE;  
 USE IEEE.Std_logic_1164.all;  
 -- N-bit Register in VHDL 
 entity N_bit_Reg is   
 generic (  
           input_width          : integer     :=8  
           );  
   port(  
    Q : out std_logic_vector(input_width-1 downto 0);    
    Clk :in std_logic;    
    reset :in std_logic;  
    D :in std_logic_vector(input_width-1 downto 0)    
   );  
 end N_bit_Reg;  
 
 architecture Behavioral of N_bit_Reg is   
 begin   
      process(Clk,reset)  
      begin   
           if (reset = '1') then  
                Q <= (others => '0');  
        elsif ( rising_edge(Clk) ) then  
                Q <= D;   
       end if;      
      end process;   
 end Behavioral;