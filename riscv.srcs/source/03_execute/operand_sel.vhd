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
		op2 : out STD_LOGIC_VECTOR (31 downto 0) := (others => '0');

		-- Forwarding signals
		fwd1 : in STD_LOGIC_VECTOR (1 downto 0);
		fwd2 : in STD_LOGIC_VECTOR (1 downto 0);

		pipe_mem_res : in STD_LOGIC_VECTOR (31 downto 0);
		pipe_mem_pc_4 : in STD_LOGIC_VECTOR (31 downto 0);
		wb_data : in STD_LOGIC_VECTOR (31 downto 0)
	);
end operand_sel;

architecture Behavioral of operand_sel is
	signal rd1_internal : STD_LOGIC_VECTOR (31 downto 0) := (others => '0');
	signal rd2_internal : STD_LOGIC_VECTOR (31 downto 0) := (others => '0');
begin
	-- Pre-select forwarding values
	process(all)
	begin
		if (fwd1 = "01") then
			rd1_internal <= wb_data;
		elsif (fwd1 = "10") then
			rd1_internal <= pipe_mem_res;
		elsif (fwd1 = "11") then
			rd1_internal <= pipe_mem_pc_4;
		else
			rd1_internal <= rd1;
		end if;

		if (fwd2 = "01") then
			rd2_internal <= wb_data;
		elsif (fwd2 = "10") then
			rd2_internal <= pipe_mem_res;
		elsif (fwd2 = "11") then
			rd2_internal <= pipe_mem_pc_4;
		else
			rd2_internal <= rd2;
		end if;
	end process;


	-- Select operands
	process(all)
	begin
		case op_sel is
			when "00" => -- rd1, rd2
				op1 <= rd1_internal;
				op2 <= rd2_internal;
			when "01" => -- rd1, imm
				op1 <= rd1_internal;
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