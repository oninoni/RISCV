--------------------------------
--                            --
--         RISC-V CPU         --
--        Single Cycle        --
--                            --
--       by Jan Ziegler       --
--                            --
--------------------------------

--------------------------------
--    Arithmetic Logic Unit   --
--------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity alu is
    Port (
        alu_control : in STD_LOGIC_VECTOR (5 downto 0);

		rd1 : in STD_LOGIC_VECTOR (31 downto 0);
		rd2 : in STD_LOGIC_VECTOR (31 downto 0);

		pc : in STD_LOGIC_VECTOR (31 downto 0);
		imm : in STD_LOGIC_VECTOR (31 downto 0);

        res : out STD_LOGIC_VECTOR (31 downto 0) := (others => '0')
    );
end alu;

architecture Behavioral of alu is
    signal alu_op : std_logic_vector(1 downto 0);
    signal alu_mode : std_logic_vector(1 downto 0);
    signal op_sel : std_logic_vector(1 downto 0);

    signal op1 : std_logic_vector(31 downto 0);
    signal op2 : std_logic_vector(31 downto 0);

    signal com_a : std_logic_vector(31 downto 0);
    signal com_b : std_logic_vector(31 downto 0);

    signal com_eq : std_logic;
    signal com_lt : std_logic;
    signal com_ltu : std_logic;

    signal adder_res : std_logic_vector(31 downto 0);
    signal shift_res : std_logic_vector(31 downto 0);
    signal logic_res : std_logic_vector(31 downto 0);
    signal compare_res : std_logic;
begin
    alu_op <= alu_control(5 downto 4);
    alu_mode <= alu_control(3 downto 2);
    op_sel <= alu_control(1 downto 0);

    -- Operand Selector
    operand_sel: entity work.operand_sel
    port map (
        rd1 => rd1,
        rd2 => rd2,

        pc => pc,
        imm => imm,

        op_sel => op_sel,

        op1 => op1,
        op2 => op2
    );

    -- Select ALU Operation
    alu_sel_op: process(all)
    begin
        case (alu_op) is
        when "00" => -- Adder
            res <= adder_res;
        when "01" => -- Shift
            res <= shift_res;
        when "10" => -- Logic
            res <= logic_res;
        when "11" => -- Compare
            res <= (31 downto 1 => '0', 0 => compare_res);

        when others =>
            res <= (others => '0');
        end case;
    end process;

    adder: entity work.adder
    port map (
        a => op1,
        b => op2,

        sub => alu_mode(0),

        c => adder_res
    );

    shifter: entity work.shifter
    port map (
        a => op1,
        b => op2(4 downto 0),

        direction => alu_mode(1),
        arithmetic => alu_mode(0),

        c => shift_res
    );

    logic: entity work.logic
    port map (
        a => op1,
        b => op2,

        op => alu_mode,

        c => logic_res
    );

    comparator: entity work.comparator
    port map (
        a => com_a,
        b => com_b,

        eq => com_eq,
        lt => com_lt,
        ltu => com_ltu
    );

    -- TODO: Handle branching output.

    -- Switch the input for the compare operation when needed for branching.
    -- Branch Commands use pc + imm for the target address, which is calculated in the execute stage.
    -- This connects rd1 and rd2 to the compare operation when not in a compare operation.
    comparator_sel_in: process(all)
    begin
        if (alu_op = "11") then
            com_a <= op1;
            com_b <= op2;
        else
            com_a <= rd1;
            com_b <= rd2;
        end if;
    end process;

    -- Compare result is selected here so the comparator can be reused for branching.
    comparator_sel_out: process(all)
    begin
        case (alu_mode) is
        when "00" => -- SLT
            compare_res <= com_lt;
        when "01" => -- SLTU
            compare_res <= com_ltu;

        when others =>
            compare_res <= '0';
        end case;
    end process;
end Behavioral;