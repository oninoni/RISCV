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

        opcode : in STD_LOGIC_VECTOR (6 downto 0);

        branch : in STD_LOGIC;
        res : in STD_LOGIC_VECTOR (31 downto 0);

        pc : out STD_LOGIC_VECTOR (31 downto 0);
        pc_4 : out STD_LOGIC_VECTOR (31 downto 0)
    );
end program_counter;

architecture Behavioral of program_counter is
    signal pc_internal : STD_LOGIC_VECTOR (31 downto 0) := (others => '0');

    signal pc_next : STD_LOGIC_VECTOR (31 downto 0);
begin

pc <= pc_internal;
pc_4 <= std_logic_vector(unsigned(pc_internal) + 4);

-- Combinational process
process(all)
begin
    case (opcode) is
    when "1100011" => -- B-Type (Branch) "br"
        if branch = '1' then
            pc_next <= res;
        else -- "pc + 4"
            pc_next <= pc_4;
        end if;

    when "1101111" => -- J-Type (Jump) "jabs"
        pc_next <= res;
    when "1100111" => -- I-Type (JALR) "rind"
        pc_next <= res;

    when others => -- "pc + 4"
        pc_next <= pc_4;
    end case;
end process;

-- Clocked process
process(clk, res_n)
begin
    if res_n = '0' then
        pc_internal <= (others => '0');
    elsif falling_edge(clk) then
        pc_internal <= pc_next;
    end if;
end process;

end Behavioral;