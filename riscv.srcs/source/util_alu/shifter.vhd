--------------------------------
--                            --
--         RISC-V CPU         --
--        Single Cycle        --
--                            --
--       by Jan Ziegler       --
--                            --
--------------------------------

--------------------------------
--         ALU Shifter        --
--------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity shifter is
	Port (
		a : in STD_LOGIC_VECTOR (31 downto 0);
		b : in STD_LOGIC_VECTOR (4 downto 0);

		direction : in STD_LOGIC;
		arithmetic : in STD_LOGIC;

		c : out STD_LOGIC_VECTOR (31 downto 0) := (others => '0')
	);
end shifter;

architecture Behavioral of shifter is
begin

	process(all)
	begin
		if direction = '0' then -- Shift Left
			-- Arithmetic shifting does not make sense for left shifting
			c <= std_logic_vector(shift_left(
                unsigned(a),
                to_integer(unsigned(b))
            ));

		else -- Shift Right
			if arithmetic = '0' then -- Logical Shift
				c <= std_logic_vector(shift_right(
					unsigned(a),
					to_integer(unsigned(b))
				));
			else -- Arithmetic Shift
				c <= std_logic_vector(shift_right(
					signed(a),
					to_integer(unsigned(b))
				));
			end if;
		end if;
	end process;

end Behavioral;