--------------------------------
--                            --
--         RISC-V CPU         --
--        Single Cycle        --
--                            --
--       by Jan Ziegler       --
--                            --
--------------------------------

--------------------------------
--    GPIO Memory Interface   --
--------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity vram_gpio is
    generic (
        -- Number of GPIO pins.
        GPIO_COUNT: integer := 256;
        -- Number of bits to address the GPIOs.
        GPIO_WIDTH : integer := integer(ceil(log2(real(GPIO_COUNT)))) + 1 -- +1 for the read/write selection
    );
    port (
        clk : in std_logic;
        res_n : in std_logic;

        -- Stage 4: Memory Access
        mem_en : in std_logic;
        mem_write : in std_logic;
        mem_size : in std_logic_vector(1 downto 0);

        mem_adr : in std_logic_vector(GPIO_WIDTH - 1 downto 0);

        mem_read_data : out std_logic_vector(31 downto 0) := (others => '0');
        mem_write_data : in std_logic_vector(31 downto 0);

        -- External GPIO Memory Interface
        gpio_in : in STD_LOGIC_VECTOR (GPIO_COUNT -1 downto 0);
        gpio_out : out STD_LOGIC_VECTOR (GPIO_COUNT -1 downto 0) := (others => '0')
    );
end vram_gpio;

-- GPIO Memory Map:
-- 1. Output GPIOs
-- 2. Input GPIOs
-- Mapped according to the GPIO_COUNT generic.

architecture Behavioral of vram_gpio is
    signal gpio_addr : integer range 0 to GPIO_COUNT - 1 := 0;
begin
    -- Convert Byte Address to Bit Address
    gpio_addr <= to_integer(unsigned(mem_adr)) * 8;

    -- Read data onto the data bus
    process(clk, res_n) begin
        if (res_n = '0') then
            mem_read_data <= (others => '0');
        elsif (rising_edge(clk)) then
            -- Enabled when enabled and not writing.
            if (mem_en = '1' and mem_write = '0') then
                -- MSB = 0 -> Output GPIOs are read
                if mem_adr(GPIO_WIDTH - 1) = '0' then
                    mem_read_data(7 downto 0) <= gpio_out(gpio_addr + 7 downto gpio_addr);

                    -- Only read when a half word or word is read.
                    if (mem_size = "01" or mem_size = "10") then
                        mem_read_data(15 downto 8) <= gpio_out(gpio_addr + 15 downto gpio_addr + 8);
                    end if;

                    -- Only read when a word is read.
                    if (mem_size = "10") then
                        mem_read_data(23 downto 16) <= gpio_out(gpio_addr + 23 downto gpio_addr + 16);
                        mem_read_data(31 downto 24) <= gpio_out(gpio_addr + 31 downto gpio_addr + 24);
                    end if;

                -- MSB = 1 -> Input GPIOs are read (Current state)
                else
                    mem_read_data(7 downto 0) <= gpio_in(gpio_addr + 7 downto gpio_addr);

                    -- Only read when a half word or word is read.
                    if (mem_size = "01" or mem_size = "10") then
                        mem_read_data(15 downto 8) <= gpio_in(gpio_addr + 15 downto gpio_addr + 8);
                    end if;

                    -- Only read when a word is read.
                    if (mem_size = "10") then
                        mem_read_data(23 downto 16) <= gpio_in(gpio_addr + 23 downto gpio_addr + 16);
                        mem_read_data(31 downto 24) <= gpio_in(gpio_addr + 31 downto gpio_addr + 24);
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- Write data from the data bus
    process(clk, res_n) begin
        if (res_n = '0') then
            gpio_out <= (others => '0');
        elsif (rising_edge(clk)) then
            -- Enabled when reading and writing.
            if (mem_en = '1' and mem_write = '1') then
                -- MSB = 0 -> Output GPIOs are written
                if mem_adr(GPIO_WIDTH - 1) = '0' then
                    gpio_out(gpio_addr + 7 downto gpio_addr) <= mem_write_data(7 downto 0);

                    -- Only write when a half word or word is written.
                    if (mem_size = "01" or mem_size = "10") then
                        gpio_out(gpio_addr + 15 downto gpio_addr + 8) <= mem_write_data(15 downto 8);
                    end if;

                    -- Only write when a word is written.
                    if (mem_size = "10") then
                        gpio_out(gpio_addr + 23 downto gpio_addr + 16) <= mem_write_data(23 downto 16);
                        gpio_out(gpio_addr + 31 downto gpio_addr + 24) <= mem_write_data(31 downto 24);
                    end if;
                end if;
            end if;
        end if;
    end process;
end architecture Behavioral;