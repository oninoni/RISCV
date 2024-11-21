--------------------------------
--                            --
--         RISC-V CPU         --
--        Single Cycle        --
--                            --
--       by Jan Ziegler       --
--                            --
--------------------------------

--------------------------------
--          ALU Adder         --
--------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity adder is
	Port (
		a : in STD_LOGIC_VECTOR (31 downto 0);
		b : in STD_LOGIC_VECTOR (31 downto 0);

		sub : in STD_LOGIC;

		c : out STD_LOGIC_VECTOR (31 downto 0) := (others => '0')
	);
end adder;

architecture Behavioral of adder is
begin

	process(all)
	begin
		case sub is
			when '0' =>
				c <= std_logic_vector(unsigned(a) + unsigned(b));
			when '1' =>
				c <= std_logic_vector(unsigned(a) - unsigned(b));

			when others =>
				c <= (others => '0');
		end case;
	end process;

end Behavioral;