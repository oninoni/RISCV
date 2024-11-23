--------------------------------
--                            --
--         RISC-V CPU         --
--        Single Cycle        --
--                            --
--       by Jan Ziegler       --
--                            --
--------------------------------

--------------------------------
--      Top Level Module      --
--------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;
use ieee.std_logic_textio.all;

entity top is
    Port (
        CLK100MHZ : in std_logic;
        CPU_RESETN: in std_logic;

        SW : in std_logic_vector(15 downto 0);
        BTNU : in std_logic;
        BTND : in std_logic;
        BTNL : in std_logic;
        BTNR : in std_logic;
        BTNC : in std_logic;

        LED : out std_logic_vector(15 downto 0) := (others => '0');
        SEG : out std_logic_vector(6 downto 0) := (others => '0');
        DP : out std_logic := '0';
        AN : out std_logic_vector(7 downto 0) := (others => '1')
    );
end top;

architecture Behavioral of top is
    constant BLOCK_COUNT : integer := 4;
    constant BRAM_COUNT : integer := BLOCK_COUNT * 4;

    -- Read the program from a hex file.
    type program_type is array (0 to ((BRAM_COUNT * 1024) - 1)) of std_logic_vector(31 downto 0);
    impure function load_memory return program_type is
        file mem_file : text open read_mode is "program.mem";
        variable program : program_type := (others => (others => '0'));

        variable rdline : line;
    begin
        for i in 0 to BRAM_COUNT * 1024 - 1 loop
            readline(mem_file, rdline);
            hread(rdline, program(i));
        end loop;

        return program;
    end function;

    constant program : program_type := load_memory;

    -- Convert the program into a signal std_logic_vector
    impure function convert_program(program : program_type) return std_logic_vector is
        variable program_vector : std_logic_vector((BRAM_COUNT * 32768) - 1 downto 0);
    begin
        for i in 0 to ((BRAM_COUNT * 1024) - 1) loop
            program_vector((i * 32) + 31 downto (i * 32)) := program((BRAM_COUNT * 1024) - 1 - i);
        end loop;

        return program_vector;
    end function;

    constant INIT_VALUE : std_logic_vector((BRAM_COUNT * 32768) - 1 downto 0) := convert_program(program);

    signal clk_divider : unsigned(23 downto 0) := (others => '0');
    signal clk_Segments : std_logic := '0';
    signal clk_Debounce : std_logic := '0';
    signal clk_CPU : std_logic := '0';

    signal res_n : std_logic := '0';

    signal gpio_in : std_logic_vector(255 downto 0) := (others => '0');
    signal gpio_out : std_logic_vector(255 downto 0) := (others => '0');

    signal gpio_in_debounce : std_logic_vector(20 downto 0) := (others => '1');
    signal gpio_out_debounce : std_logic_vector(20 downto 0) := (others => '1');
begin
    -- Clock divider
    process(CLK100MHZ)
    begin
        if rising_edge(CLK100MHZ) then
            clk_divider <= clk_divider + 1;
        end if;
    end process;

    clk_Segments <= clk_divider(17);
    clk_Debounce <= clk_divider(15);
    clk_CPU <= clk_divider(5);

    res_n <= CPU_RESETN;

    -- Debouncer
    debouncer : entity work.debouncer
    generic map (
        WIDTH => 21
    )
    port map (
        clk => clk_Debounce,
        res_n => res_n,

        btn_in => gpio_in_debounce,
        btn_out => gpio_out_debounce
    );

    gpio_in_debounce <= BTNC & BTNR & BTNL & BTND & BTNU & SW;

    -- Wire the GPIO to the device I/O
    gpio_in <= (20 downto 0 => gpio_out_debounce, others => '0' );
    LED <= gpio_out(15 downto 0);

    -- 7 Segment Display
    seven_segment : entity work.seven_segment
    port map (
        clk => clk_Segments,
        res_n => res_n,

        data => gpio_out(63 downto 32),
        seg => SEG,
        an => AN
    );

    -- Disable digit points on seven segment display
    DP <= '1';

    -- Pipelined CPU
    cpu_pipelined : entity work.cpu_pipelined
    generic map (
        BLOCK_COUNT => BLOCK_COUNT,

        INIT_VALUE => INIT_VALUE
    )
    port map (
        clk => clk_CPU,
        res_n => res_n,

        gpio_in => gpio_in,
        gpio_out => gpio_out
    );

end Behavioral;
