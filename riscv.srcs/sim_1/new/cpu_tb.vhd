-- Jan Ziegler

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cpu_tb is
end cpu_tb;

architecture Behavioral of cpu_tb is
    signal clk : std_logic := '0';
    signal res_n : std_logic := '0';
begin
    cpu : entity work.cpu
    port map (
        clk => clk,
        res_n => res_n
    );

    clk <= not clk after 100 ns;
    res_n <= '1' after 200 ns;
end Behavioral;
