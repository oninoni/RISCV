-- Jan Ziegler

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mem_controller is
    Port ( 
        clk : in STD_LOGIC;
        res_n : in STD_LOGIC;
        
        operation : in STD_LOGIC_VECTOR (6 downto 0);

        ram_wd : in STD_LOGIC_VECTOR (31 downto 0);
        ram_rd : out STD_LOGIC_VECTOR (31 downto 0);

        pc : in STD_LOGIC_VECTOR (31 downto 0);
        instruction : out STD_LOGIC_VECTOR (31 downto 0)
    );
end mem_controller;

-- RAM Mapping:
-- FPGA has 50 36kb RAM blocks
-- We will need some for other stuff, so only a part wlll be used for general purpose RAM / Instruction Memory
-- Other RAM Mapped devices are added later.

architecture Behavioral of mem_controller is
        

begin

end Behavioral;
