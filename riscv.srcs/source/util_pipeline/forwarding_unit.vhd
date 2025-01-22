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
		-- Stage 3: Execute
		rs1 : in std_logic_vector (4 downto 0);
		rs2 : in std_logic_vector (4 downto 0);

		fwd1 : out std_logic_vector (1 downto 0);
		fwd2 : out std_logic_vector (1 downto 0);

		-- Stage 4: Memory
		mem_reg_write : in std_logic;
		mem_reg_wb_sel : in std_logic_vector (1 downto 0); -- 00: None, 01: ALU, 10: PC+4, 11: RAM
		mem_rd : in std_logic_vector (4 downto 0);

		-- Stage 5: Write Back
		wb_reg_write : in std_logic;
		wb_rd : in std_logic_vector (4 downto 0);
	);
end forwarding_unit;

architecture Behavioral of forwarding_unit is
begin
    process(all) is
    begin
		fwd1 <= "00";
		fwd2 <= "00";

		-- Allow forwarding the previous ALU result to the next ALU operation during the memory stage.
		-- An additional check is required, to ensure we are not forwarding an ALU result to the ALU operation itself.
		-- RAM Read operations require a stall or a NOP, before forwarding is possible since they are in a different state.
		if (mem_reg_write = '1') and (mem_rd /= "00000") and (mem_reg_wb_sel /= "01") then
			if (mem_rd = rs1) then
				fwd1 <= "10";
			elsif (mem_rd = rs2) then
				fwd2 <= "10";
			end if;
		end if;

		-- Allow forwarding the pc+4 value to the next ALU operation during the memory stage.
		if (mem_reg_write = '1') and (mem_rd /= "00000") and (mem_reg_wb_sel = "10") then
			if (mem_rd = rs1) then
				fwd1 <= "11";
			elsif (mem_rd = rs2) then
				fwd2 <= "11";
			end if;
		end if;

		-- Allow forwarding the data about to be written back to the next ALU operation during the write back stage.
		-- This does not need to be checked for the operation, since this value is always used for write back.
		if (wb_reg_write = '1') and (wb_rd /= "00000") then
			if (wb_rd = rs1) then
				fwd1 <= "01";
			elsif (wb_rd = rs2) then
				fwd2 <= "01";
			end if;
		end if;
end Behavioral;