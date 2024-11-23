--------------------------------
--                            --
--         RISC-V CPU         --
--        Single Cycle        --
--                            --
--       by Jan Ziegler       --
--                            --
--------------------------------

--------------------------------
--   Write Back Multiplexer   --
--------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity wb_mux is
    Port (
		wb_sel : in STD_LOGIC_VECTOR (1 downto 0); -- 00: None, 01: ALU, 10: PC+4, 11: RAM

		res : in STD_LOGIC_VECTOR (31 downto 0);
		pc_4 : in STD_LOGIC_VECTOR (31 downto 0);
		ram_rd : in STD_LOGIC_VECTOR (31 downto 0);

		wb_data : out STD_LOGIC_VECTOR (31 downto 0) := (others => '0')
	);
end wb_mux;

architecture Behavioral of wb_mux is
begin
	process(all)
	begin
		case wb_sel is
			when "00" =>
				wb_data <= (others => '0');
			when "01" =>
				wb_data <= res;
			when "10" =>
				wb_data <= pc_4;
			when "11" =>
				wb_data <= ram_rd;
			when others =>
				wb_data <= (others => '0');
		end case;
	end process;
end Behavioral;