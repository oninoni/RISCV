-- Jan Ziegler

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
    Port (
        CLK100MHZ : in std_logic;
        btnC : in std_logic;
    );
end top;

architecture Behavioral of top is
begin
    cpu : entity work.cpu
    port map (
        clk => CLK100MHZ,
        res_n => btnC
    );
end Behavioral;