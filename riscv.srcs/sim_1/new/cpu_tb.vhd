-- Jan Ziegler

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cpu_tb is
end cpu_tb;

architecture Behavioral of cpu_tb is
    signal clk : std_logic := '0';
    signal res_n : std_logic := '1';

    signal sw : std_logic_vector(15 downto 0) := (others => '0');
    signal LED : std_logic_vector(15 downto 0);
begin
    top : entity work.top
    port map (
        CLK100MHZ => clk,
        btnC => res_n,

        sw => sw,
        LED => LED
    );

    clk <= not clk after 200 ns;
    res_n <= '0' after 500 ns;
end Behavioral;
