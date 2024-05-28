-- Jan Ziegler

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
    Port (
        CLK100MHZ : in std_logic;
        btnC : in std_logic;

        sw : in std_logic_vector(15 downto 0);
        LED : out std_logic_vector(15 downto 0)
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