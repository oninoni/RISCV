-- Jan Ziegler

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pc is
    Port (
        clk : in STD_LOGIC;
        res_n : in STD_LOGIC;
    
        opcode : in STD_LOGIC_VECTOR (6 downto 0);

        pc : out STD_LOGIC_VECTOR (31 downto 0);
        pc_4 : out STD_LOGIC_VECTOR (31 downto 0);
    
        branch : in STD_LOGIC;
        res : in STD_LOGIC_VECTOR (31 downto 0)
    );
end pc;

architecture Behavioral of pc is
    signal pc_next : STD_LOGIC_VECTOR (31 downto 0);
begin

pc_4 <= std_logic_vector(unsigned(pc) + 4);

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
        pc <= (others => '0');
    elsif rising_edge(clk) then
        pc <= pc_next;
    end if;
end process;

end Behavioral;