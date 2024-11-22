--------------------------------
--                            --
--         RISC-V CPU         --
--        Single Cycle        --
--                            --
--       by Jan Ziegler       --
--                            --
--------------------------------

--------------------------------
--      Memory Controller     --
--------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity mem_controller is
    generic (
        -- Base Address for instruction memory.
        INSTRUCTION_BASE: STD_LOGIC_VECTOR(15 downto 0) := x"0000";
        -- Base Address for GPIO memory.
        GPIO_BASE: STD_LOGIC_VECTOR(15 downto 0) := x"0001";

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
        INIT_VALUE: std_logic_vector(0 to 32768 * BRAM_COUNT - 1) := (others => '0');

        -- Ammount of GPIO Pins
        GPIO_COUNT: integer := 256;
        -- Number of bits to address the GPIOs.
        GPIO_WIDTH : integer := integer(ceil(log2(real(GPIO_COUNT)))) + 1 -- +1 for the read/write selection
    );
    port (
        clk : in STD_LOGIC;
        res_n : in STD_LOGIC;

        -- Stage 1: Instruction Fetch
        pc : in STD_LOGIC_VECTOR (31 downto 0);
        instruction : out STD_LOGIC_VECTOR (31 downto 0) := (others => '0');

        -- Stage 4: Memory Access
        mem_read : in STD_LOGIC;
        mem_write : in STD_LOGIC;
        mem_size : in STD_LOGIC_VECTOR (1 downto 0);
        mem_signed : in STD_LOGIC;

        mem_adr : in STD_LOGIC_VECTOR (31 downto 0);

        mem_read_data : out STD_LOGIC_VECTOR (31 downto 0) := (others => '0');
        mem_write_data : in STD_LOGIC_VECTOR (31 downto 0);

        -- External GPIO Memory Interface
        gpio_in : in STD_LOGIC_VECTOR (GPIO_COUNT - 1 downto 0) := (others => '0');
        gpio_out : out STD_LOGIC_VECTOR (GPIO_COUNT - 1 downto 0) := (others => '0')
    );
end mem_controller;

-- RAM Mapping:
-- FPGA has 135 32kb BRAM blocks totaling 4.86MB of BRAM.
-- We might need some for other stuff, so only a part will be used for general purpose RAM / Instruction Memory.
-- Other RAM Mapped devices are added later.
--
-- Default Memory Map:
-- 0x0000_0000 - 0x0000_FFFF: Instruction Memory (16 x 32kb BRAMs)
-- 0x0001_0000 - 0x0001_000F: GPIO_OUT (256b GPIO Banks)
-- 0x0001_0020 - 0x0001_002F: GPIO_IN (256b GPIO Banks)
-- 0x0001_0030 - 0x0001_FFFF: Reserved for GPIO Memory Expansion
-- 0x0002_0000 - 0xFFFF_FFFF: Unused
--
-- The Memory Controller uses 2 memory channels to access the memory devices.
-- The first general is general purpose and can be used for any memory device.
-- The second channel is used for the instruction memory and is only used for reading instructions.
-- If the instruction memory acceses a different memory device an exception should be thrown. TODO: Implement Exception Handling

-- If the memory acceses an unimplemented memory device, an exception should be thrown. TODO: Implement Exception Handling
-- Same for unsupported memory sizes for instruction fetches.

architecture Behavioral of mem_controller is
    -- Shared signals.
    signal mem_read_data_internal : std_logic_vector(31 downto 0) := (others => '0');

    -- Instruction Memory Bank
    signal ins_en : std_logic := '0'; -- Instruction Memory Enable
    signal ins_read_data : std_logic_vector(31 downto 0) := (others => '0'); -- Instruction Memory Read Data

    -- GPIO Memory Interface
    signal gpio_en : std_logic := '0'; -- GPIO Memory Enable
    signal gpio_read_data : std_logic_vector(31 downto 0) := (others => '0'); -- GPIO Memory Read Data
begin
    --------------------------------
    --       Memory Mapping       --
    --------------------------------

    -- Memory Map Control Signals / Read Data Multiplexer
    process(all) begin
        ins_en <= '0';
        gpio_en <= '0';

        case mem_adr(31 downto 16) is
        when INSTRUCTION_BASE =>
            ins_en <= mem_read or mem_write;
            mem_read_data_internal <= ins_read_data;

        when GPIO_BASE =>
            gpio_en <= mem_read or mem_write;
            mem_read_data_internal <= gpio_read_data;

        when others =>
            mem_read_data_internal <= (others => '0');
        end case;
    end process;

    --------------------------------
    --       Memory Devices       --
    --------------------------------

    -- Instruction Memory Bank
    bram_instruction : entity work.bram_instruction
    generic map (
        BLOCK_COUNT => BLOCK_COUNT,

        INIT_VALUE => INIT_VALUE
    ) port map (
        clk => clk,

        -- Stage 1: Instruction Fetch
        pc => pc(MEM_WIDTH - 1 downto 0),
        instruction => instruction,

        -- Stage 4: Memory Access
        mem_en => ins_en,
        mem_write => mem_write,
        mem_size => mem_size,

        mem_adr => mem_adr(MEM_WIDTH - 1 downto 0),

        mem_read_data => ins_read_data,
        mem_write_data => mem_write_data
    );

    -- GPIO Memory Interface
    vram_gpio : entity work.vram_gpio
    generic map (
        GPIO_COUNT => GPIO_COUNT
    ) port map (
        clk => clk,
        res_n => res_n,

        -- Stage 4: Memory Access
        mem_en => gpio_en,
        mem_write => mem_write,
        mem_size => mem_size,

        mem_adr => mem_adr(GPIO_WIDTH - 1 downto 0),

        mem_read_data => gpio_read_data,
        mem_write_data => mem_write_data,

        -- External GPIO Memory Interface
        gpio_in => gpio_in,
        gpio_out => gpio_out
    );

    --------------------------------
    --       Word Extension       --
    --------------------------------

    -- Memory reading needs to be masked depending on the size of the memory access.
    -- And it needs to be bit extended depending on if it is signed or unsigned.
    process(all) begin
        if (mem_read = '1') then
            case (mem_size) is
            when "00" => -- Byte
                mem_read_data(7 downto 0) <= mem_read_data_internal(7 downto 0);

                if (mem_signed = '1') then
                    mem_read_data(31 downto 8) <= (others => mem_read_data_internal(7));
                else
                    mem_read_data(31 downto 8) <= (others => '0');
                end if;
            when "01" => -- Halfword
                mem_read_data(15 downto 0) <= mem_read_data_internal(15 downto 0);

                if (mem_signed = '1') then
                    mem_read_data(31 downto 16) <= (others => mem_read_data_internal(15));
                else
                    mem_read_data(31 downto 16) <= (others => '0');

                end if;
            when "10" => -- Word (Does not need sign extension, since it is already 32bit)
                mem_read_data <= mem_read_data_internal;

            when others =>
                mem_read_data <= (others => '0');
            end case;
        else
            mem_read_data <= (others => '0');
        end if;
    end process;
end Behavioral;