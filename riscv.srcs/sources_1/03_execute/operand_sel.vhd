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

entity operand_sel is
	Port (
		rd1 : in STD_LOGIC_VECTOR (31 downto 0);
		rd2 : in STD_LOGIC_VECTOR (31 downto 0);

		pc : in STD_LOGIC_VECTOR (31 downto 0);
		imm : in STD_LOGIC_VECTOR (31 downto 0);

		op_sel : in STD_LOGIC_VECTOR (1 downto 0);

		op1 : out STD_LOGIC_VECTOR (31 downto 0) := (others => '0');
		op2 : out STD_LOGIC_VECTOR (31 downto 0) := (others => '0')
	);
end operand_sel;

architecture Behavioral of operand_sel is
begin

	-- Select operands
	process(all)
	begin
		case op_sel is
			when "00" => -- rd1, rd2
				op1 <= rd1;
				op2 <= rd2;
			when "01" => -- rd1, imm
				op1 <= rd1;
				op2 <= imm;
			when "11" => -- pc, imm
				op1 <= pc;
				op2 <= imm;

			when others =>
				op1 <= (others => '0');
				op2 <= (others => '0');
		end case;
	end process;

end Behavioral;