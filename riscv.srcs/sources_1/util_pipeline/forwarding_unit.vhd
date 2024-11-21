--------------------------------
--                            --
--         RISC-V CPU         --
--        Single Cycle        --
--                            --
--       by Jan Ziegler       --
--                            --
--------------------------------

--------------------------------
--       Forwarding Unit      --
--------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity forwarding_unit is
	Port (
		clk : in std_logic;
		reset : in std_logic;

		rs1 : in std_logic_vector(4 downto 0);
		rs2 : in std_logic_vector(4 downto 0);

		rd1 : in std_logic_vector(31 downto 0);
		rd2 : in std_logic_vector(31 downto 0);
	);
end forwarding_unit;