--------------------------------
--                            --
--         RISC-V CPU         --
--        Single Cycle        --
--                            --
--       by Jan Ziegler       --
--                            --
--------------------------------

--------------------------------
--        Register File       --
--------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reg_file is
    generic (
        STACK_POINTER_INIT : std_logic_vector(31 downto 0) := x"00000000"
    );
    Port (
        clk : in STD_LOGIC;
        res_n : in STD_LOGIC;

        -- Stage 2: Instruction Decode
        rs1 : in STD_LOGIC_VECTOR (4 downto 0);
        rs2 : in STD_LOGIC_VECTOR (4 downto 0);

        rd1 : out STD_LOGIC_VECTOR (31 downto 0) := (others => '0');
        rd2 : out STD_LOGIC_VECTOR (31 downto 0) := (others => '0');

        -- Stage 5: Write Back
        reg_write : in STD_LOGIC;
        rd : in STD_LOGIC_VECTOR (4 downto 0);

        wd : in STD_LOGIC_VECTOR (31 downto 0)
    );
end reg_file;

-- RISC V Register File:
-- x0 / zero: Hardwired zero
-- x1 / ra: Return address
-- x2 / sp: Stack pointer
-- x3 / gp: Global pointer
-- x4 / tp: Thread pointer
-- x5-7 / t0-2: Temporaries
-- x8 / s0 / fp: Saved register / frame pointer
-- x9 / s1: Saved register
-- x10-11 / a0-1: Function arguments / return values
-- x12-17 / a2-7: Function arguments
-- x18-27 / s2-11: Saved registers
-- x28-31 / t3-6: Temporaries

architecture Behavioral of reg_file is
    type reg_array is array (1 to 31) of std_logic_vector(31 downto 0);
    signal regs : reg_array := (others => (others => '0'));
begin

    -- Read register file (Instruction Decode)
    process(all)
    begin
        if (rs1 = "00000") then -- Hard Zero
            rd1 <= (others => '0');
        else
            rd1 <= regs(to_integer(unsigned(rs1)));
        end if;

        if (rs2 = "00000") then -- Hard Zero
            rd2 <= (others => '0');
        else
            rd2 <= regs(to_integer(unsigned(rs2)));
        end if;
    end process;

    -- Write register file (Write Back)
    process(clk, res_n)
    begin
        if (res_n = '0') then -- Reset
            regs <= (others => (others => '0'));

            -- Reset Stack Pointer
            regs(2) <= STACK_POINTER_INIT;
        elsif (rising_edge(clk)) then
            if (reg_write = '1' and rd /= "00000") then
                regs(to_integer(unsigned(rd))) <= wd;
            end if;
        end if;
    end process;
end Behavioral;


