-- Jan Ziegler

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity vram_gpio is
    port (
        data_clk : in std_logic;
        res_n : in std_logic;
        data_en : in std_logic;

        data_wr : in std_logic_vector(3 downto 0);
        data_adr : in std_logic_vector(8 downto 0);

        data_out : out std_logic_vector(31 downto 0);
        data_in : in std_logic_vector(31 downto 0);

        gpio_in : in STD_LOGIC_VECTOR (255 downto 0);
        gpio_out : out STD_LOGIC_VECTOR (255 downto 0)
    );
end vram_gpio;

-- Memory maps input and output GPIOs to the data bus.

architecture Behavioral of vram_gpio is
    signal trunc_addr : unsigned(3 downto 0);
begin
    trunc_addr <= unsigned(data_adr(8 downto 5));

    -- Read data onto the data bus
    process(data_clk, res_n) begin
        if (res_n = '0') then
            data_out <= (others => '0');
        elsif (rising_edge(data_clk)) then
            if data_en = '1' then
                 -- Low Addresses -> Output GPIOs are read
                if trunc_addr(3) = '0' then
                    data_out <= gpio_out(
                        to_integer(unsigned(trunc_addr(2 downto 0))) * 32 + 31 downto
                        to_integer(unsigned(trunc_addr(2 downto 0))) * 32)
                    ;

                -- High Addresses -> Input GPIOs are read
                else
                    data_out <= gpio_in(
                        to_integer(unsigned(trunc_addr(2 downto 0))) * 32 + 31 downto
                        to_integer(unsigned(trunc_addr(2 downto 0))) * 32)
                    ;
                end if;
            else 
                data_out <= (others => '0');
            end if;
        end if;
    end process;

    -- Write data from the data bus
    process(data_clk, res_n) begin
        if (res_n = '0') then
            gpio_out <= (others => '0');
        elsif (rising_edge(data_clk)) then
            if (data_en = '1') then
                -- Low Addresses -> Output GPIOs are written
                if trunc_addr(3) = '0' then
                    if (data_wr(0) = '1') then
                        gpio_out(
                            to_integer(unsigned(trunc_addr(2 downto 0))) * 32 + 7 downto
                            to_integer(unsigned(trunc_addr(2 downto 0))) * 32)
                        <= data_in(7 downto 0);
                    end if;
    
                    if (data_wr(1) = '1') then
                        gpio_out(
                            to_integer(unsigned(trunc_addr(2 downto 0))) * 32 + 15 downto
                            to_integer(unsigned(trunc_addr(2 downto 0))) * 32 + 8)
                        <= data_in(15 downto 8);
                    end if;
    
                    if (data_wr(2) = '1') then
                        gpio_out(
                            to_integer(unsigned(trunc_addr(2 downto 0))) * 32 + 23 downto
                            to_integer(unsigned(trunc_addr(2 downto 0))) * 32 + 16)
                        <= data_in(23 downto 16);
                    end if;
    
                    if (data_wr(3) = '1') then
                        gpio_out(
                            to_integer(unsigned(trunc_addr(2 downto 0))) * 32 + 31 downto
                            to_integer(unsigned(trunc_addr(2 downto 0))) * 32 + 24)
                        <= data_in(31 downto 24);
                    end if;
                end if;
            end if; 
        end if;
    end process;
end Behavioral;