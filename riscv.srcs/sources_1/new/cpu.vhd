--------------------------------
--                            --
--         RISC-V CPU         --
--        Single Cycle        --
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

entity cpu is
    generic (
        BRAM_COUNT : integer := 4;
        STACK_POINTER_INIT : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(BRAM_COUNT * 1024 * 4, 32));

        INIT_VALUE : std_logic_vector(0 to 32768 * BRAM_COUNT - 1) := (others => '0')
    );
    port (
        clk : in std_logic;
        res_n : in std_logic;

        gpio_in : in STD_LOGIC_VECTOR (255 downto 0);
        gpio_out : out STD_LOGIC_VECTOR (255 downto 0)
    );
end entity cpu;

architecture Behavioral of cpu is
    -- Instruction Decoder Signals
    signal opcode : std_logic_vector(6 downto 0);
    signal funct3 : std_logic_vector(2 downto 0);
    signal funct7 : std_logic_vector(6 downto 0);

    signal rs1 : std_logic_vector(4 downto 0);
    signal rs2 : std_logic_vector(4 downto 0);
    signal rd : std_logic_vector(4 downto 0);

    signal imm : std_logic_vector(31 downto 0);

    -- Program Counter Signals
    signal pc : std_logic_vector(31 downto 0);
    signal pc_4 : std_logic_vector(31 downto 0);

    -- Register File Signals
    signal rd1 : std_logic_vector(31 downto 0);
    signal rd2 : std_logic_vector(31 downto 0);

    -- ALU Signals
    signal res : std_logic_vector(31 downto 0);

    -- Branch Logic Signals
    signal branch : std_logic;

    -- Memory Controller Signals
    signal ram_rd : std_logic_vector(31 downto 0);
    signal instruction : std_logic_vector(31 downto 0);
begin
    -- Instruction Decoder
    ins_decode: entity work.ins_decode
    port map (
        -- Input signals
        instruction => instruction,

        -- Output signals
        opcode => opcode,
        funct3 => funct3,
        funct7 => funct7,

        rs1 => rs1,
        rs2 => rs2,
        rd => rd,

        imm => imm
    );

    -- Program Counter
    program_counter: entity work.program_counter
    port map (
        clk => clk,
        res_n => res_n,

        -- Instruction signals
        opcode => opcode,

        -- Input signals
        branch => branch,
        res => res,

        -- Output signals
        pc => pc,
        pc_4 => pc_4
    );

    -- Register File
    reg_file: entity work.reg_file
    generic map (
        STACK_POINTER_INIT => STACK_POINTER_INIT
    )
    port map (
        clk => clk,
        res_n => res_n,

        -- Instruction signals
        opcode => opcode,

        rs1 => rs1,
        rs2 => rs2,
        rd => rd,

        -- Input signals
        pc_4 => pc_4,

        res => res,
        ram_rd => ram_rd,

        -- Output signals
        rd1 => rd1,
        rd2 => rd2
    );

    -- ALU
    alu: entity work.alu
    port map (
        -- Instruction signals
        opcode => opcode,
        funct3 => funct3,
        funct7 => funct7,

        -- Input signals
        rd1 => rd1,
        rd2 => rd2,

        pc => pc,
        imm => imm,

        -- Output signals
        res => res
    );

    -- Branch Logic
    branch_logic: entity work.branch_logic
    port map (
        -- Instruction signals
        opcode => opcode,
        funct3 => funct3,

        -- Input signals
        rd1 => rd1,
        rd2 => rd2,

        -- Output signals
        branch => branch
    );

    -- Memory Controller
    mem_controller: entity work.mem_controller
    generic map (
        BRAM_COUNT => BRAM_COUNT,
        INIT_VALUE => INIT_VALUE
    )
    port map (
        clk => clk,
        res_n => res_n,

        -- Instruction signals
        opcode => opcode,
        funct3 => funct3,

        -- Input signals
        res => res,
        rd2 => rd2,

        -- Output signals
        ram_rd => ram_rd,

        -- Instruction Memory
        pc => pc,
        instruction => instruction,

        -- GPIO Memory Interface
        gpio_in => gpio_in,
        gpio_out => gpio_out
    );
end Behavioral;