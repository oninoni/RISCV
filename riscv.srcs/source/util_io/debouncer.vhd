--------------------------------
--                            --
--         RISC-V CPU         --
--        Single Cycle        --
--                            --
--       by Jan Ziegler       --
--                            --
--------------------------------

--------------------------------
--      Debouncer Module      --
--------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity debouncer is
    generic (
        WIDTH : integer := 4
    );
    Port (
        clk : in std_logic;
        res_n : in std_logic;

        btn_in : in std_logic_vector(WIDTH - 1 downto 0);
        btn_out : out std_logic_vector(WIDTH - 1 downto 0) := (others => '0')
    );
end debouncer;

architecture Behavioral of debouncer is
    signal btn_internal : std_logic_vector((WIDTH * 3) - 1 downto 0) := (others => '0');
begin
    -- Shift register
    process(clk, res_n)
    begin
        if res_n = '0' then
            btn_internal <= (others => '0');
        elsif rising_edge(clk) then
            btn_internal(WIDTH * 3 - 1 downto WIDTH * 2) <= btn_internal(WIDTH * 2 - 1 downto WIDTH);
            btn_internal(WIDTH * 2 - 1 downto WIDTH) <= btn_internal(WIDTH - 1 downto 0);
            btn_internal(WIDTH - 1 downto 0) <= btn_in;
        end if;
    end process;

    -- Output AND Gate of all stages
    btn_out <= btn_internal(WIDTH * 3 - 1 downto WIDTH * 2) and btn_internal(WIDTH * 2 - 1 downto WIDTH) and btn_internal(WIDTH - 1 downto 0);
end Behavioral;
