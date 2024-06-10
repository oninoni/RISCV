-- Jan Ziegler

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bram_instruction_tb is
end bram_instruction_tb;

architecture Behavioral of bram_instruction_tb is
    constant BRAM_COUNT : integer := 1;

    constant INIT_VALUE : std_logic_vector(32767 downto 0) := (
        X"00000093",
        X"00000193",
        X"00000213",
        X"00000293",
        X"00000313",
        X"00000393",
        X"00000413",
        X"00000493",
        X"00000513",
        X"00000593",
        X"00000613",
        X"00000693",
        X"00000713",
        X"00000793",
        X"00000813",
        X"00000893",
        X"00000913",
        X"00000993",
        X"00000a13",
        X"00000a93",
        X"00000b13",
        X"00000b93",
        X"00000c13",
        X"00000c93",
        X"00000d13",
        X"00000d93",
        X"00000e13",
        X"00000e93",
        X"00000f13",
        X"00000f93",
        X"02000537",
        X"0aa00593",
        X"00b52023",
        X"0f0000ef",
        X"0000006f",
        X"fe010113",
        X"00112e23",
        X"00812c23",
        X"02010413",
        X"00050793",
        X"fef407a3",
        X"fef44703",
        X"00a00793",
        X"00f71663",
        X"00d00513",
        X"fd9ff0ef",
        X"020007b7",
        X"00878793",
        X"fef44703",
        X"00e7a023",
        X"00000013",
        X"01c12083",
        X"01812403",
        X"02010113",
        X"00008067",
        X"fe010113",
        X"00112e23",
        X"00812c23",
        X"02010413",
        X"fea42623",
        X"01c0006f",
        X"fec42783",
        X"00178713",
        X"fee42623",
        X"0007c783",
        X"00078513",
        X"f85ff0ef",
        X"fec42783",
        X"0007c783",
        X"fe0790e3",
        X"00000013",
        X"00000013",
        X"01c12083",
        X"01812403",
        X"02010113",
        X"00008067",
        X"fe010113",
        X"00812e23",
        X"02010413",
        X"fe042623",
        X"0100006f",
        X"fec42783",
        X"00178793",
        X"fef42623",
        X"fec42703",
        X"0003d7b7",
        X"08f78793",
        X"fee7d4e3",
        X"00000013",
        X"00000013",
        X"01c12403",
        X"02010113",
        X"00008067",
        X"ff010113",
        X"00112623",
        X"00812423",
        X"01010413",
        X"020007b7",
        X"00478793",
        X"00001737",
        X"45870713",
        X"00e7a023",
        X"1a800513",
        X"f41ff0ef",
        X"f91ff0ef",
        X"ff5ff06f",
        X"6c6c6568",
        X"6f77206f",
        X"0a646c72",
        X"00000000",
        others => '0'
    );

    signal data_clk : std_logic := '0';
    signal data_en : std_logic := '0';

    signal data_wr : std_logic_vector(3 downto 0) := "0000";
    signal data_adr : std_logic_vector((11 + BRAM_WIDTH) downto 0) := "000000000000";

    signal data_out : std_logic_vector(31 downto 0);
    signal data_in : std_logic_vector(31 downto 0) := (others => '0');
begin
    bram_instruction : entity work.bram_instruction
    generic map (
        BRAM_COUNT => BRAM_COUNT,

        INIT_VALUE => (INIT_VALUE, others => '0')
    ) port map (
        data_clk => data_clk,
        data_en => data_en,

        data_wr => data_wr,
        data_adr => data_adr,

        data_out => data_out,
        data_in => data_in
    );

    data_clk <= not data_clk after 200 ns;
end Behavioral;