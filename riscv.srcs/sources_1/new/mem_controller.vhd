-- Jan Ziegler

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mem_controller is
    Port (
        clk : in STD_LOGIC;

        opcode : in STD_LOGIC_VECTOR (6 downto 0);

        res : in STD_LOGIC_VECTOR (31 downto 0);
        rd2 : in STD_LOGIC_VECTOR (31 downto 0);
        ram_rd : out STD_LOGIC_VECTOR (31 downto 0);

        pc : in STD_LOGIC_VECTOR (31 downto 0);
        instruction : out STD_LOGIC_VECTOR (31 downto 0)
    );
end mem_controller;

-- RAM Mapping:
-- FPGA has 50 36kb RAM blocks
-- We will need some for other stuff, so only a part will be used for general purpose RAM / Instruction Memory
-- Other RAM Mapped devices are added later.

architecture Behavioral of mem_controller is
    signal write_enable : std_logic := '0';

    constant INIT_VALUE : std_logic_vector(0 to (1024 * 32) - 1) := (
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
begin


    -- Single 36kb BRAM for now. Can be expanded later.
    ins_mem : entity work.bram
    generic map (
        INIT_VALUE => to_bitvector(INIT_VALUE)
    )
    port map (
        -- Port A: Load / Store Instructions
        -- Executed on the falling edge of the clock
        A_clk => not clk,
        A_Enable => write_enable,
        A_addr => res(11 downto 2),

        A_Write => rd2,
        A_Read => ram_rd,

        -- Port B, Fetch Instructions
        -- Executed on the rising edge of the clock
        B_clk => clk,
        B_addr => pc(11 downto 2),

        B_Read => instruction
    );

    -- Write Enable Logic
    process(all) begin
        case (opcode) is
        when "0100011" => -- S-Type (Store, res = address)
            write_enable <= '1';
        when others =>
            write_enable <= '0';
        end case;
    end process;

end Behavioral;