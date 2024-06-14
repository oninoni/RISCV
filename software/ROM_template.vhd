-- Jan Ziegler

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
    Port (
        CLK100MHZ : in std_logic;
        btnC : in std_logic;

        sw : in std_logic_vector(15 downto 0);
        LED : out std_logic_vector(15 downto 0)
    );
end top;

architecture Behavioral of top is
    constant INIT_VALUE : std_logic_vector(32767 downto 0) := (

        --init_data

        others => '0'
    );

    signal gpio_in : std_logic_vector(255 downto 0) := (others => '0');
    signal gpio_out : std_logic_vector(255 downto 0) := (others => '0');

    signal clk_div : unsigned(7 downto 0) := (others => '0');
begin
    gpio_in <= (
        15 downto 0 => sw,
        others => '0'
    );

    LED <= gpio_out(15 downto 0);

    cpu : entity work.cpu
    generic map (
        BRAM_COUNT => 16,
        INIT_VALUE => (INIT_VALUE, others => '0')
    )
    port map (
        clk => clk_div(7),
        res_n => not btnC,

        gpio_in => gpio_in,
        gpio_out => gpio_out
    );

    process (CLK100MHZ)
    begin
        if rising_edge(CLK100MHZ) then
            clk_div <= clk_div + 1;
        end if;
    end process;
end Behavioral;
