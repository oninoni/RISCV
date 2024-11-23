--------------------------------
--                            --
--         RISC-V CPU         --
--        Single Cycle        --
--                            --
--       by Jan Ziegler       --
--                            --
--------------------------------

--------------------------------
--          ALU Logic         --
--------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity logic is
	Port (
		a : in STD_LOGIC_VECTOR (31 downto 0);
		b : in STD_LOGIC_VECTOR (31 downto 0);

		op : in STD_LOGIC_VECTOR (1 downto 0);

		c : out STD_LOGIC_VECTOR (31 downto 0) := (others => '0')
	);
end logic;

architecture Behavioral of logic is
begin

	process(all)
	begin
		case op is
		when "00" => -- XOR
			c <= a xor b;
		when "01" => -- OR
			c <= a or b;
		when "10" => -- AND
			c <= a and b;
		when "11" => -- Pass Through b
			c <= b;

		when others =>
			c <= (others => '0');
		end case;
	end process;

end Behavioral;