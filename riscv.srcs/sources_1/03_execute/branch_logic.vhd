--------------------------------
--                            --
--         RISC-V CPU         --
--        Single Cycle        --
--                            --
--       by Jan Ziegler       --
--                            --
--------------------------------

--------------------------------
--        Branch Logic        --
--------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity branch_logic is
    Port (
        bra_sel : in STD_LOGIC_VECTOR (2 downto 0);

        eq : in STD_LOGIC;
        lt : in STD_LOGIC;
        ltu : in STD_LOGIC;

        branch : out STD_LOGIC
    );
end branch_logic;

architecture Behavioral of branch_logic is
begin
    process(all) is
    begin
        case bra_sel is
            when "001" => -- JAL JALR
                branch <= '1';
            when "010" => -- BEQ
                branch <= eq;
            when "011" => -- BNE
                branch <= not eq;
            when "100" => -- BLT
                branch <= lt;
            when "101" => -- BGE
                branch <= not lt or eq;
            when "110" => -- BLTU
                branch <= ltu;
            when "111" => -- BGEU
                branch <= not ltu or eq;

            when others =>
                branch <= '0';
        end case;
    end process;
end Behavioral;