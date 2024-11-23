-- Jan Ziegler

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cpu_tb is
end cpu_tb;

architecture Behavioral of cpu_tb is
    signal clk : std_logic := '0';
    signal res_n : std_logic := '0';

    signal SW : std_logic_vector(15 downto 0) := "0011001100110011";
    signal LED : std_logic_vector(15 downto 0);
    signal SEG : std_logic_vector(6 downto 0);
    signal DP : std_logic;
    signal AN : std_logic_vector(7 downto 0);
begin
    top : entity work.top
    port map (
        CLK100MHZ => clk,
        CPU_RESETN => res_n,

        SW => SW,
        BTNC => '0',
        BTNU => '0',
        BTND => '0',
        BTNL => '0',
        BTNR => '0',

        LED => LED,
        SEG => SEG,
        DP => DP,
        AN => AN
    );

    clk <= not clk after 5 ns;
    res_n <= '1' after 2 us;
end Behavioral;
