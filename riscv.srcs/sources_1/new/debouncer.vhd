-- Jan Ziegler

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity debouncer is
    Port (
        clk : in std_logic;
        res_n : in std_logic;

        btn_in : in std_logic;
        btn_out : out std_logic
    );
end debouncer;

architecture Behavioral of debouncer is
    signal btn_internal : std_logic_vector(3 downto 0) := (others => '0');
begin
    -- Shift register
    process(clk, res_n)
    begin
        if res_n = '0' then
            btn_internal <= (others => '0');
        elsif rising_edge(clk) then
            btn_internal <= btn_internal(2 downto 0) & btn_in;
        end if;
    end process;

    -- Output AND Gate of all stages
    btn_out <= btn_internal(0) and btn_internal(1) and btn_internal(2) and btn_internal(3);
end Behavioral;
