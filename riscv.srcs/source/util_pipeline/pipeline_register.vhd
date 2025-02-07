--------------------------------
--                            --
--         RISC-V CPU         --
--          Pipelined         --
--                            --
--       by Jan Ziegler       --
--                            --
--------------------------------

--------------------------------
--         Main Module        --
--------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pipeline_register is
    generic (
		WIDTH : integer := 8
	);
	port (
        clk : in std_logic;
        res_n : in std_logic;

		stall : in std_logic;
		bubble : in std_logic;

		in_data : in std_logic_vector(WIDTH-1 downto 0);

		out_data : out std_logic_vector(WIDTH-1 downto 0) := (others => '0')
	);
end entity pipeline_register;

architecture Behavioral of pipeline_register is
begin

	process(clk, res_n)
	begin
		if res_n = '0' then
			out_data <= (others => '0');
		elsif rising_edge(clk) and stall = '0' then
			if bubble = '0' then
				out_data <= in_data;
			else
				out_data <= (others => '0');
			end if;
		end if;
	end process;

end architecture Behavioral;