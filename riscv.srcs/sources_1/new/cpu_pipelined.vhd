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

entity cpu_pipelined is
    generic (
        BRAM_COUNT : integer := 4;
        STACK_POINTER_INIT : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(BRAM_COUNT * 1024 * 4, 32));

        INIT_VALUE : std_logic_vector(0 to 32768 * BRAM_COUNT - 1) := (others => '0')
    );
    port (
        clk : in std_logic;
        res_n : in std_logic;

        gpio_in : in STD_LOGIC_VECTOR (255 downto 0);
        gpio_out : out STD_LOGIC_VECTOR (255 downto 0) := (others => '0')
    );
end entity cpu_pipelined;

--------------------------------
--     CPU Pipeline Stages    --
--------------------------------
-- 1. Instruction Fetch
-- 2. Instruction Decode
--    / Register Read
-- 3. Execution
--    / Address Calculation
-- 4. Memory Read / Write
-- 5. Write Back
--------------------------------

architecture Behavioral of cpu_pipelined is
    -- Stage 1: Instruction Fetch Signals

    -- Program Counter Signals
    signal pc : std_logic_vector(31 downto 0) := (others => '0');
    signal pc_4 : std_logic_vector(31 downto 0) := (others => '0');

    -- Instruction Memory Signals
    signal instruction : std_logic_vector(31 downto 0) := (others => '0');

    -- Stage 2: Instruction Decode Signals

    -- Pipeline Stage Registers
    signal pipe_id_pc : std_logic_vector(31 downto 0) := (others => '0');
    signal pipe_id_pc_4 : std_logic_vector(31 downto 0) := (others => '0');

    signal pipe_id_instruction : std_logic_vector(31 downto 0) := (others => '0');

    -- All pipeline signals combined into one vector, so it can be attached to the pipeline register.
    signal pipe_id_in : std_logic_vector(95 downto 0) := (others => '0');
    signal pipe_id_out : std_logic_vector(95 downto 0) := (others => '0');

    -- Register Addresses
    signal rs1 : std_logic_vector(4 downto 0) := "00000";
    signal rs2 : std_logic_vector(4 downto 0) := "00000";
    signal rd : std_logic_vector(4 downto 0) := "00000";

    -- Immediate Value
    signal imm : std_logic_vector(31 downto 0) := (others => '0');

    -- Control Signals
    signal ex_control : std_logic_vector(5 downto 0) := "000000";
    signal mem_control : std_logic_vector(4 downto 0) := "00000";
    signal wb_control : std_logic_vector(2 downto 0) := "000";

    -- Register File Signals
    signal rd1 : std_logic_vector(31 downto 0) := (others => '0');
    signal rd2 : std_logic_vector(31 downto 0) := (others => '0');

    -- Stage 3: Execution Signals

    -- Pipeline Stage Registers
    signal pipe_ex_pc : std_logic_vector(31 downto 0) := (others => '0');
    signal pipe_ex_pc_4 : std_logic_vector(31 downto 0) := (others => '0');

    signal pipe_ex_rd : std_logic_vector(4 downto 0) := "00000";

    signal pipe_ex_rd1 : std_logic_vector(31 downto 0) := (others => '0');
    signal pipe_ex_rd2 : std_logic_vector(31 downto 0) := (others => '0');

    signal pipe_ex_imm : std_logic_vector(31 downto 0) := (others => '0');

    signal pipe_ex_ex_control : std_logic_vector(5 downto 0) := "000000";
    signal pipe_ex_mem_control : std_logic_vector(4 downto 0) := "00000";
    signal pipe_ex_wb_control : std_logic_vector(2 downto 0) := "000";

    -- All pipeline signals combined into one vector, so it can be attached to the pipeline register.
    signal pipe_ex_in : std_logic_vector(178 downto 0) := (others => '0');
    signal pipe_ex_out : std_logic_vector(178 downto 0) := (others => '0');

    -- ALU Signals
    signal res : std_logic_vector(31 downto 0) := (others => '0');

    -- Branch Logic Signals
    -- TODO

    -- Stage 4: Memory Read / Write Signals

    -- Pipeline Stage Registers
    signal pipe_mem_pc_4 : std_logic_vector(31 downto 0) := (others => '0');

    signal pipe_mem_rd : std_logic_vector(4 downto 0) := "00000";

    signal pipe_mem_rd2 : std_logic_vector(31 downto 0) := (others => '0');
    signal pipe_mem_res : std_logic_vector(31 downto 0) := (others => '0');

    signal pipe_mem_mem_control : std_logic_vector(4 downto 0) := "00000";
    signal pipe_mem_wb_control : std_logic_vector(2 downto 0) := "000";

    -- All pipeline signals combined into one vector, so it can be attached to the pipeline register.
    signal pipe_mem_in : std_logic_vector(108 downto 0) := (others => '0');
    signal pipe_mem_out : std_logic_vector(108 downto 0) := (others => '0');

    -- Memory Controller Signals
    signal ram_rd : std_logic_vector(31 downto 0) := (others => '0');

    -- Stage 5: Write Back Signals

    -- Pipeline Stage Registers
    signal pipe_wb_pc_4 : std_logic_vector(31 downto 0) := (others => '0');

    signal pipe_wb_rd : std_logic_vector(4 downto 0) := "00000";

    signal pipe_wb_res : std_logic_vector(31 downto 0) := (others => '0');
    signal pipe_wb_ram_rd : std_logic_vector(31 downto 0) := (others => '0');

    signal pipe_wb_wb_control : std_logic_vector(2 downto 0) := "000";

    -- All pipeline signals combined into one vector, so it can be attached to the pipeline register.
    signal pipe_wb_in : std_logic_vector(103 downto 0) := (others => '0');
    signal pipe_wb_out : std_logic_vector(103 downto 0) := (others => '0');

    -- Write Back Multiplexer Signals
    signal wb_data : std_logic_vector(31 downto 0) := (others => '0');
begin
    -- The Pipeline stages are triggered by the rising edge of the clock signal.
    -- Other signals are updated on the falling edge of the clock signal.

    -- Stage 1: Instruction Fetch
    -- The memory controller reads the instruction from the instruction memory.
    -- The program counter is incremented by 4 or set to the branch target.

    -- Program Counter
    program_counter: entity work.program_counter
    port map ( -- TODO: Redo
        clk => not clk, -- TODO: Check edge
        res_n => res_n,

        -- Stage 1: Instruction Fetch
        pc => pc,
        pc_4 => pc_4,

        -- Stage ?: Branch
        branch => '0',
        set => (others => '0')
    );

    -- Pipeline Register: Instruction Fetch -> Instruction Decode
    pipeline_register_id: entity work.pipeline_register
    generic map (
        WIDTH => pc'length + pc_4'length + instruction'length
    )
    port map (
        clk => clk,
        res_n => res_n,

        in_data => pipe_id_in,
        out_data => pipe_id_out
    );

    pipe_id_in <= pc & pc_4 & instruction;

    pipe_id_pc <= pipe_id_out(95 downto 64);
    pipe_id_pc_4 <= pipe_id_out(63 downto 32);
    pipe_id_instruction <= pipe_id_out(31 downto 0);



    -- Stage 2: Instruction Decode
    -- The instruction is decoded and the immediate value is sign-extended.
    -- The register file reads the register values.

    -- Instruction Decoder
    ins_decode: entity work.ins_decode
    port map (
        -- Input signals
        instruction => pipe_id_instruction,

        -- Stage 2: Decode / Register Read
        rs1 => rs1,
        rs2 => rs2,

        -- Stage 3: Execute
        imm => imm,

        -- Execution Control Signals
        alu_op => ex_control(5 downto 4),
        alu_mode => ex_control(3 downto 2),
        op_sel => ex_control(1 downto 0),

        -- Stage 4: Memory Read / Write

        -- Memory Control Signals
        mem_read => mem_control(0),
        mem_write => mem_control(1),
        mem_size => mem_control(3 downto 2),
        mem_signed => mem_control(4),

        -- Stage 5: Write Back

        rd => rd,

        -- Write Back Control Signals
        wb_sel => wb_control(1 downto 0),
        wb_write => wb_control(2)
    );

    -- Register File
    reg_file: entity work.reg_file
    generic map (
        STACK_POINTER_INIT => STACK_POINTER_INIT
    )
    port map (
        clk => not clk, -- TODO: Check edge
        res_n => res_n,

        -- Stage 2: Instruction Decode
        rs1 => rs1,
        rs2 => rs2,

        rd1 => rd1,
        rd2 => rd2,

        -- Stage 5: Write Back
        reg_write => pipe_wb_wb_control(2),
        rd => pipe_wb_rd,

        wd => wb_data
    );

    -- Pipeline Register: Instruction Decode -> Execution
    pipeline_register_ex: entity work.pipeline_register
    generic map (
        WIDTH => pipe_id_pc'length + pipe_id_pc_4'length + rd'length + rd1'length + rd2'length + imm'length + ex_control'length + mem_control'length + wb_control'length
    )
    port map (
        clk => clk,
        res_n => res_n,

        in_data => pipe_ex_in,
        out_data => pipe_ex_out
    );

    pipe_ex_in <= pipe_id_pc & pipe_id_pc_4 & rd & rd1 & rd2 & imm & ex_control & mem_control & wb_control;

    pipe_ex_pc <= pipe_ex_out(178 downto 147);
    pipe_ex_pc_4 <= pipe_ex_out(146 downto 115);
    pipe_ex_rd <= pipe_ex_out(114 downto 110);
    pipe_ex_rd1 <= pipe_ex_out(109 downto 78);
    pipe_ex_rd2 <= pipe_ex_out(77 downto 46);
    pipe_ex_imm <= pipe_ex_out(45 downto 14);
    pipe_ex_ex_control <= pipe_ex_out(13 downto 8);
    pipe_ex_mem_control <= pipe_ex_out(7 downto 3);
    pipe_ex_wb_control <= pipe_ex_out(2 downto 0);



    -- Stage 3: Execution
    -- The ALU calculates the result of the operation.
    -- The branch logic calculates the branch condition.

    -- ALU
    alu: entity work.alu
    port map (
        alu_control => pipe_ex_ex_control,

        -- Input signals
        rd1 => pipe_ex_rd1,
        rd2 => pipe_ex_rd2,

        pc => pipe_ex_pc,
        imm => pipe_ex_imm,

        -- Output signals
        res => res
    );

    -- TODO: Implement branching
--    -- Branch Logic
--    branch_logic: entity work.branch_logic
--    port map (
--        -- Instruction signals
--        opcode => pipe_ex_opcode,
--        funct3 => pipe_ex_funct3,
--
--        -- Input signals
--        rd1 => pipe_ex_rd1,
--        rd2 => pipe_ex_rd2,
--
--        -- Output signals
--        branch => branch
--    );

    -- Pipeline Register
    pipeline_register_mem: entity work.pipeline_register
    generic map (
        WIDTH => pipe_ex_pc_4'length + pipe_ex_rd'length + pipe_ex_rd2'length + res'length + pipe_ex_mem_control'length + pipe_ex_wb_control'length
    )
    port map (
        clk => clk,
        res_n => res_n,

        in_data => pipe_mem_in,
        out_data => pipe_mem_out
    );

    pipe_mem_in <= pipe_ex_pc_4 & pipe_ex_rd & pipe_ex_rd2 & res & pipe_ex_mem_control & pipe_ex_wb_control;

    pipe_mem_pc_4 <= pipe_mem_out(108 downto 77);
    pipe_mem_rd <= pipe_mem_out(76 downto 72);
    pipe_mem_rd2 <= pipe_mem_out(71 downto 40);
    pipe_mem_res <= pipe_mem_out(39 downto 8);
    pipe_mem_mem_control <= pipe_mem_out(7 downto 3);
    pipe_mem_wb_control <= pipe_mem_out(2 downto 0);



    -- Stage 4: Memory Read / Write
    -- Read and write data from and to the memory.

    -- Memory Controller
    mem_controller: entity work.mem_controller
    generic map (
        BRAM_COUNT => BRAM_COUNT,
        INIT_VALUE => INIT_VALUE
    )
    port map (
        clk => not clk, -- TODO: Check edge
        res_n => res_n,

        -- Stage 1: Instruction Fetch
        pc => pc,
        instruction => instruction,

        -- Stage 4: Memory Access
        mem_read => pipe_mem_mem_control(0),
        mem_write => pipe_mem_mem_control(1),
        mem_size => pipe_mem_mem_control(3 downto 2),
        mem_signed => pipe_mem_mem_control(4),

        mem_adr => pipe_mem_res,

        mem_read_data => ram_rd,
        mem_write_data => pipe_mem_rd2,

        -- External GPIO Memory Interface
        gpio_in => gpio_in,
        gpio_out => gpio_out
    );

    -- Pipeline Register
    pipeline_register_wb: entity work.pipeline_register
    generic map (
        WIDTH => pipe_mem_pc_4'length + pipe_mem_rd'length + pipe_mem_res'length + ram_rd'length + pipe_mem_wb_control'length
    )
    port map (
        clk => clk,
        res_n => res_n,

        in_data => pipe_wb_in,
        out_data => pipe_wb_out
    );

    pipe_wb_in <= pipe_mem_pc_4 & pipe_mem_rd & pipe_mem_res & ram_rd & pipe_mem_wb_control;

    pipe_wb_pc_4 <= pipe_wb_out(103 downto 72);
    pipe_wb_rd <= pipe_wb_out(71 downto 67);
    pipe_wb_res <= pipe_wb_out(66 downto 35);
    pipe_wb_ram_rd <= pipe_wb_out(34 downto 3);
    pipe_wb_wb_control <= pipe_wb_out(2 downto 0);



    -- Stage 5: Write Back
    -- Select the data to be written back to the register file.
    -- Write the data back to the register file.

    -- Write Back Multiplexer
    wb_mux: entity work.wb_mux
    port map (
        wb_sel => pipe_wb_wb_control(1 downto 0),

        res => pipe_wb_res,
        pc_4 => pipe_wb_pc_4,
        ram_rd => pipe_wb_ram_rd,

        wb_data => wb_data
    );
end Behavioral;