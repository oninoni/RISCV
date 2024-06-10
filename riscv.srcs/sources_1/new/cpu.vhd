-- Jan Ziegler

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cpu is
    generic (
        BRAM_COUNT : integer := 4;
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
        instruction => instruction,

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

        opcode => opcode,

        pc => pc,
        pc_4 => pc_4,

        branch => branch,
        res => res
    );

    -- Register File
    reg_file: entity work.reg_file
    port map (
        clk => clk,
        res_n => res_n,

        opcode => opcode,

        rs1 => rs1,
        rs2 => rs2,

        imm => imm,
        pc_4 => pc_4,

        rd => rd,
        res => res,

        rd1 => rd1,
        rd2 => rd2,

        ram_rd => ram_rd
    );

    -- ALU
    alu: entity work.alu
    port map (
        opcode => opcode,
        funct3 => funct3,
        funct7 => funct7,

        pc => pc,
        imm => imm,

        rd1 => rd1,
        rd2 => rd2,
        res => res
    );

    -- Branch Logic
    branch_logic: entity work.branch_logic
    port map (
        opcode => opcode,
        funct3 => funct3,

        rd1 => rd1,
        rd2 => rd2,

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

        opcode => opcode,
        funct3 => funct3,

        res => res,
        rd2 => rd2,
        ram_rd => ram_rd,

        pc => pc,
        instruction => instruction,

        gpio_in => gpio_in,
        gpio_out => gpio_out
    );
end Behavioral;