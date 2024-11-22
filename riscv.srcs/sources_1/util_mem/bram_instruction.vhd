--------------------------------
--                            --
--         RISC-V CPU         --
--        Single Cycle        --
--                            --
--       by Jan Ziegler       --
--                            --
--------------------------------

--------------------------------
--   BRAM Instruction Memory  --
--------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity bram_instruction is
    generic (
        -- Number of 16kB blocks.
        BLOCK_COUNT: integer := 4;
        -- Number of 4kB BRAMs.
        BRAM_COUNT: integer := BLOCK_COUNT * 4;
        -- Number of bits to address the BRAMs.
        BRAM_WIDTH: integer := integer(ceil(log2(real(BRAM_COUNT))));
        -- Number of bits to address a byte.
        MEM_WIDTH : integer := 12 + BRAM_WIDTH;

        -- All initial values for the BRAMs.
        -- Size if the ammount of bits in all blocks.
        INIT_VALUE: std_logic_vector(0 to 32768 * BRAM_COUNT - 1) := (others => '0')
    );
    port (
        clk : in std_logic;

        -- Stage 1: Instruction Fetch
        pc : in std_logic_vector(MEM_WIDTH - 1 downto 0);
        instruction : out std_logic_vector(31 downto 0) := (others => '0');

        -- Stage 4: Memory Access
        mem_en : in std_logic;
        mem_write : in std_logic;
        mem_size : in std_logic_vector(1 downto 0);

        mem_adr : in std_logic_vector(MEM_WIDTH - 1 downto 0);

        mem_read_data : out std_logic_vector(31 downto 0) := (others => '0');
        mem_write_data : in std_logic_vector(31 downto 0)
    );
end bram_instruction;

-- BRAM Instruction Memory
-- RISCV reqires 32bit words but with byte addressing.
-- The BRAMS however can only read byte aligned words of the configuration width.
-- This means the BRAMs need to be configured to read 8 bit words.
-- 4 BRAMs in paralel are then used, to read 32 bit words.
-- One block of 4 BRAMs is called a memory block and has a total capacity of 4 * 32kb = 128kb = 16kB

architecture Behavioral of bram_instruction is
    -- This function untangles the initial values for the BRAMs.
    -- The values are given in order and need to be split up for the 4 BRAMs.
    -- The offset is used, to determine which BRAM in a block is being initialized.
    impure function untangle_init(
        init : in std_logic_vector(0 to 32768 * 4 - 1) := (others => '0');
        offset : in integer := 0
    ) return bit_vector is
        variable init_sel : bit_vector(0 to 32768 - 1);
        variable init_ut : bit_vector(0 to 32768 - 1);

        variable target : integer;
        variable source : integer;
    begin
        -- Select the correct BRAM values.
        for i in 0 to 4096 loop
            if (i mod 4 = offset) then
                target := integer(floor(real(i) / 4));

                init_sel(target * 8 to target * 8 + 7) := to_bitvector(init(i * 8 to i * 8 + 7));
            end if;
        end loop;

        -- Looping through the 128 init blocks and untangle them.
        for i in 0 to 127 loop
            -- Flipping byte order.
            for j in 0 to 31 loop
                source := 32 * i + j;
                target := 32 * i + (31 - j);

                init_ut(target * 8 to target * 8 + 7) := init_sel(source * 8 to source * 8 + 7);
            end loop;
        end loop;

        return init_ut;
    end function;

    -- Custom type to handle the output of all BRAMs.
    type std_logic_aoa is array (natural range <>) of std_logic_vector;

    -- Instruction Fetch Interface
    signal bram_ins_en : std_logic_vector(BRAM_COUNT - 1 downto 0) := (others => '0');
    signal ins_out : std_logic_aoa(0 to BRAM_COUNT - 1)(7 downto 0) := (others => "00000000");

    -- Address Decoder signals for all 4 active BRAMs.
    signal ins_addr_0 : integer := 0;
    signal ins_addr_1 : integer := 0;
    signal ins_addr_2 : integer := 0;
    signal ins_addr_3 : integer := 0;

    -- Memory Interface
    signal bram_mem_en : std_logic_vector(BRAM_COUNT - 1 downto 0) := (others => '0');
    signal mem_out : std_logic_aoa(0 to BRAM_COUNT - 1)(7 downto 0) := (others => "00000000");
    signal mem_in : std_logic_aoa(0 to BRAM_COUNT - 1)(7 downto 0) := (others => "00000000");

    -- Address Decoder signals for all 4 active BRAMs.
    signal mem_addr_0 : integer := 0;
    signal mem_addr_1 : integer := 0;
    signal mem_addr_2 : integer := 0;
    signal mem_addr_3 : integer := 0;
begin
    -- Generate the BRAMs
    gen_bram : for i in 0 to BRAM_COUNT - 1 generate
    begin
        bram : entity work.bram
        generic map (
            INIT_VALUE => untangle_init(
                init => INIT_VALUE(32768 * 4 * integer(floor(real(i) / 4)) to 32768 * 4 * (integer(floor(real(i) / 4)) + 1) - 1),
                offset => i mod 4
            )
        ) port map (
            -- Memory Access Interface
            A_clk => clk,
            A_Enable => bram_mem_en(i),

            -- 2 LSB and all MSB are encoded in bram_mem_en, since the memory is interleaved.
            A_Addr => mem_adr(13 downto 2),

            A_RData => mem_out(i),

            A_Write => mem_write,
            A_WData => mem_in(i),

            -- Instruction Fetch Interface
            B_clk => clk,
            B_Enable => bram_ins_en(i),

            -- 2 LSB and all MSB are encoded in bram_ins_en, since the memory is interleaved.
            B_Addr => pc(13 downto 2),
            B_RData => ins_out(i),

            -- Write is disabled for the instruction memory.
            B_Write => '0',
            B_WData => (others => '0')
        );
    end generate;

    -- Generate the 4 address signals for the BRAMs.
    --
    -- Now, The theory is that all 4 "active" brams have their own address.
    -- The address of the most significant Byte is taken from the MSB of the memory address.
    -- The other 3 words are addressed as +1, +2, +3 respectively.
    --
    -- When the address reaches the end of the block, it wraps around to the beginning.
    -- This is not a problem, since such an access is blocked in a higher level module.

    ins_addr_3 <= to_integer(unsigned(pc(MEM_WIDTH - 1 downto MEM_WIDTH - BRAM_WIDTH))) * 4 + to_integer(unsigned(pc(1 downto 0)));
    ins_addr_2 <= ins_addr_3 + 1;
    ins_addr_1 <= ins_addr_3 + 2;
    ins_addr_0 <= ins_addr_3 + 3;

    mem_addr_3 <= to_integer(unsigned(mem_adr(MEM_WIDTH - 1 downto MEM_WIDTH - BRAM_WIDTH))) * 4 + to_integer(unsigned(mem_adr(1 downto 0)));
    mem_addr_2 <= mem_addr_3 + 1;
    mem_addr_1 <= mem_addr_3 + 2;
    mem_addr_0 <= mem_addr_3 + 3;

    -- Generate the enable signals for the BRAMs.
    process(all)
        variable temp : std_logic_vector(BRAM_COUNT - 1 downto 0) := (others => '0');
    begin
        -- Instruction memory is always used with full width.
        temp := (others => '0');
        temp(ins_addr_3) := '1';
        temp(ins_addr_2) := '1';
        temp(ins_addr_1) := '1';
        temp(ins_addr_0) := '1';

        bram_ins_en <= temp;

        -- Always enable the first byte, when we are interacting with the memory.
        bram_mem_en <= (others => '0');
        bram_mem_en(mem_addr_3) <= mem_en;

        -- Only enable when a half word or word is written.
        if (mem_size = "01" or mem_size = "10") then
            bram_mem_en(mem_addr_2) <= mem_en;
        end if;

        -- Only enable when a word is written.
        if (mem_size = "10") then
            bram_mem_en(mem_addr_1) <= mem_en;
            bram_mem_en(mem_addr_0) <= mem_en;
        end if;
    end process;

    -- Generate the output signals.
    process(all)
    begin
        if (mem_en = '1') then
            mem_read_data <= mem_out(mem_addr_3) & mem_out(mem_addr_2) & mem_out(mem_addr_1) & mem_out(mem_addr_0);

            mem_in(mem_addr_3) <= mem_write_data(31 downto 24);
            mem_in(mem_addr_2) <= mem_write_data(23 downto 16);
            mem_in(mem_addr_1) <= mem_write_data(15 downto 8);
            mem_in(mem_addr_0) <= mem_write_data(7 downto 0);
        else
            mem_read_data <= (others => '0');

            mem_in <= (others => (others => '0'));
        end if;
    end process;

    instruction <= ins_out(ins_addr_3) & ins_out(ins_addr_2) & ins_out(ins_addr_1) & ins_out(ins_addr_0);
end Behavioral;


