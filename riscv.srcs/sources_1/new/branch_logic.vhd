-- Jan Ziegler

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity branch_logic is
    Port (
        opcode : in STD_LOGIC_VECTOR (6 downto 0);
        funct3 : in STD_LOGIC_VECTOR (2 downto 0);

        rd1 : in STD_LOGIC_VECTOR (31 downto 0);
        rd2 : in STD_LOGIC_VECTOR (31 downto 0);

        branch : out STD_LOGIC
    );
end branch_logic;

architecture Behavioral of branch_logic is
begin
    process(all)
    begin
        if (opcode = "1100011") then
            case (funct3) is
            when "000" => -- BEQ
                if (rd1 = rd2) then
                    branch <= '1';
                else
                    branch <= '0';
                end if;
            when "001" => -- BNE
                if (rd1 /= rd2) then
                    branch <= '1';
                else
                    branch <= '0';
                end if;

            when "100" => -- BLT
                if (signed(rd1) < signed(rd2)) then
                    branch <= '1';
                else
                    branch <= '0';
                end if;
            when "101" => -- BGE
                if (signed(rd1) >= signed(rd2)) then
                    branch <= '1';
                else
                    branch <= '0';
                end if;

            when "110" => -- BLTU
                if (unsigned(rd1) < unsigned(rd2)) then
                    branch <= '1';
                else
                    branch <= '0';
                end if;
            when "111" => -- BGEU
                if (unsigned(rd1) >= unsigned(rd2)) then
                    branch <= '1';
                else
                    branch <= '0';
                end if;

            when others =>
                branch <= '0';
            end case;
        else
            branch <= '0';
        end if;
    end process;

end Behavioral;