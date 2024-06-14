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
x"00000093",
x"00000193",
x"00000213",
x"00000293",
x"00000313",
x"00000393",
x"00000413",
x"00000493",
x"00000513",
x"00000593",
x"00000613",
x"00000693",
x"00000713",
x"00000793",
x"00000813",
x"00000893",
x"00000913",
x"00000993",
x"00000a13",
x"00000a93",
x"00000b13",
x"00000b93",
x"00000c13",
x"00000c93",
x"00000d13",
x"00000d93",
x"00000e13",
x"00000e93",
x"00000f13",
x"00000f93",
x"04c000ef",
x"0000006f",
x"fe010113",
x"00812e23",
x"02010413",
x"fe042623",
x"0100006f",
x"fec42783",
x"00178793",
x"fef42623",
x"fec42703",
x"000027b7",
x"70f78793",
x"fee7d4e3",
x"00000013",
x"00000013",
x"01c12403",
x"02010113",
x"00008067",
x"ff010113",
x"00112623",
x"00812423",
x"01010413",
x"000107b7",
x"00100713",
x"00e7a023",
x"fa1ff0ef",
x"000107b7",
x"0007a023",
x"f95ff0ef",
x"fe5ff06f",
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
