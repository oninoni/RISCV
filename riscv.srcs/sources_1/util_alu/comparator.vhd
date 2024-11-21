--------------------------------
--                            --
--         RISC-V CPU         --
--        Single Cycle        --
--                            --
--       by Jan Ziegler       --
--                            --
--------------------------------

--------------------------------
--          ALU Comparator         --
--------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity comparator is
	port (
		a : in std_logic_vector(31 downto 0);
		b : in std_logic_vector(31 downto 0);

		eq : out std_logic := '0';
		lt : out std_logic := '0';
		ltu : out std_logic := '0'
	);
end entity comparator;

architecture rtl of comparator is
begin

	eq <= '1' when a = b else '0';
	lt <= '1' when signed(a) < signed(b) else '0';
	ltu <= '1' when unsigned(a) < unsigned(b) else '0';

end architecture rtl;