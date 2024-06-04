-- Jan Ziegler

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity vram_gpio is
    generic (
        GPIO_IN_COUNT : integer := 16;
        GPIO_OUT_COUNT : integer := 16;

        -- Ammount of GPIOs in 32 bit words
        GPIO_IN_COUNT_WORDS : integer := integer(ceil(real(GPIO_IN_COUNT) / 32));
        GPIO_OUT_COUNT_WORDS : integer := integer(ceil(real(GPIO_OUT_COUNT) / 32));

        GPIO_ADDR_WIDTH : integer := integer(ceil(log2(real((GPIO_IN_COUNT_WORDS + GPIO_OUT_COUNT_WORDS) * 32))))
    );
    port (
        data_clk : in std_logic;
        res_n : in std_logic;
        data_en : in std_logic;

        data_wr : in std_logic_vector(3 downto 0);
        data_adr : in std_logic_vector((GPIO_ADDR_WIDTH - 1) downto 0);

        data_out : out std_logic_vector(31 downto 0);
        data_in : in std_logic_vector(31 downto 0);
        
        gpio_in : in STD_LOGIC_VECTOR (GPIO_IN_COUNT - 1 downto 0);
        gpio_out : out STD_LOGIC_VECTOR (GPIO_OUT_COUNT - 1 downto 0)
    );
end vram_gpio;

-- Memory maps input and output GPIOs to the data bus
-- Input and output are aligned to 32 bit words, to keep the data bus aligned

architecture Behavioral of vram_gpio is
    constant IN_WORD_COUNT : integer := integer(ceil(real(GPIO_IN_COUNT) / 32));
    constant OUT_WORD_COUNT : integer := integer(ceil(real(GPIO_OUT_COUNT) / 32));

    constant addr_word_align : std_logic_vector((GPIO_ADDR_WIDTH - 4) downto 0);
begin
    addr_word_align <= data_adr((GPIO_ADDR_WIDTH - 1) downto 4);

    -- Read data onto the data bus
    process(data_clk, res_n) begin
        if (res_n = '0') then
            data_out <= (others => '0');
        elsif (rising_edge(data_clk) and data_en = '1') then
            if (addr_word_align < IN_WORD_COUNT) then
                data_out <= gpio_in(to_integer(unsigned(addr_word_align)));
            elsif (addr_word_align < (IN_WORD_COUNT + OUT_WORD_COUNT)) then
                data_out <= gpio_out(to_integer(unsigned(addr_word_align - IN_WORD_COUNT)));
            else
                data_out <= (others => '0');
            end if;
        end if;
    end process;

    -- Write data from the data bus
    process(data_clk, res_n) begin
        if (res_n = '0') then
            gpio_out <= (others => '0');
        elsif (rising_edge(data_clk) and data_en = '1') then
            if (addr_word_align >= IN_WORD_COUNT and addr_word_align < (IN_WORD_COUNT + OUT_WORD_COUNT)) then
                if (data_wr(0) = '1') then
                    gpio_out(to_integer(unsigned(addr_word_align - IN_WORD_COUNT))) <= data_in(7 downto 0);
                end if;

                if (data_wr(1) = '1') then
                    gpio_out(to_integer(unsigned(addr_word_align - IN_WORD_COUNT))) <= data_in(15 downto 8);
                end if;

                if (data_wr(2) = '1') then
                    gpio_out(to_integer(unsigned(addr_word_align - IN_WORD_COUNT))) <= data_in(23 downto 16);
                end if;

                if (data_wr(3) = '1') then
                    gpio_out(to_integer(unsigned(addr_word_align - IN_WORD_COUNT))) <= data_in(31 downto 24);
                end if;
            end if;
        end if;
    end process;
end Behavioral;