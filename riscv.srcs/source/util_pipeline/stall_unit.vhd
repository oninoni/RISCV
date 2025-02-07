--------------------------------
--                            --
--         RISC-V CPU         --
--        Single Cycle        --
--                            --
--       by Jan Ziegler       --
--                            --
--------------------------------

--------------------------------
--         Stall Unit         --
--------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity stall_unit is
	Port(
		-- TODO

		-- Output
		stall : out std_logic
	);
end stall_unit;

architecture Behavioral of stall_unit is
begin

end Behavioral;