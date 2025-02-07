--------------------------------
--                            --
--         RISC-V CPU         --
--        Single Cycle        --
--                            --
--       by Jan Ziegler       --
--                            --
--------------------------------

--------------------------------
--       Program Counter      --
--------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity program_counter is
    Port (
        clk : in STD_LOGIC;
        res_n : in STD_LOGIC;

        -- Stage 1: Instruction Fetch
        stall : in STD_LOGIC;

        pc : out STD_LOGIC_VECTOR (31 downto 0) := (others => '0');
        pc_4 : out STD_LOGIC_VECTOR (31 downto 0) := (others => '0');

        -- Stage ?: Branch
        branch : in STD_LOGIC;
        set : in STD_LOGIC_VECTOR (31 downto 0)
    );
end program_counter;

architecture Behavioral of program_counter is
    signal pc_internal : STD_LOGIC_VECTOR (31 downto 0) := (others => '0');
begin
    pc <= pc_internal;
    pc_4 <= std_logic_vector(unsigned(pc_internal) + 4);

    -- Clocked process
    process(clk, res_n)
    begin
        if res_n = '0' then
            pc_internal <= (others => '0');
        elsif rising_edge(clk) then
            if (stall = '0') then
                if (branch = '1') then
                    pc_internal <= set;
                else
                    pc_internal <= pc_4;
                end if;
            end if;
        end if;
    end process;
end Behavioral;