-- Jan Ziegler

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mem_controller is
    generic (
        -- Parameters for the Instruction Memory
        BRAM_COUNT : integer := 4;
        INIT_VALUE : std_logic_vector := (others => '0');

        -- Parameters for the GPIO Memory Interface
        GPIO_IN_COUNT : integer := 0;
        GPIO_OUT_COUNT : integer := 0
    );
    Port (
        clk : in STD_LOGIC;
        res_n : in STD_LOGIC;

        opcode : in STD_LOGIC_VECTOR (6 downto 0);
        funct3 : in STD_LOGIC_VECTOR (2 downto 0);

        res : in STD_LOGIC_VECTOR (31 downto 0);
        rd2 : in STD_LOGIC_VECTOR (31 downto 0);
        ram_rd : out STD_LOGIC_VECTOR (31 downto 0);

        pc : in STD_LOGIC_VECTOR (31 downto 0);
        instruction : out STD_LOGIC_VECTOR (31 downto 0);

        -- GPIO Memory Interface
        gpio_in : in STD_LOGIC_VECTOR (GPIO_IN_COUNT - 1 downto 0);
        gpio_out : out STD_LOGIC_VECTOR (GPIO_OUT_COUNT - 1 downto 0)
    );
end mem_controller;


-- RAM Mapping:
-- FPGA has 50 36kb RAM blocks
-- We will need some for other stuff, so only a part will be used for general purpose RAM / Instruction Memory
-- Other RAM Mapped devices are added later.

architecture Behavioral of mem_controller is
    signal write_enable : std_logic_vector(3 downto 0);
    signal ram_rd_internal : std_logic_vector(31 downto 0);
    signal ram_wd_internal : std_logic_vector(31 downto 0);

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
begin

    -- Initialize the Instruction Memory
    bram_instruction : entity work.bram_instruction
    generic map (
        BRAM_COUNT => 4,
        INIT_VALUE => (INIT_VALUE, others => '0')
    ) port map (
        data_clk => not clk,
        data_en => '1', -- TODO: Only enable when needed.

        data_wr => write_enable,
        data_adr => res(13 downto 0),

        data_out => ram_rd_internal,
        data_in => ram_wd_internal,

        instruction_clk => clk,
        instruction_adr => pc(13 downto 0),
        instruction_out => instruction
    );

    -- GPIO Memory Interface
    vram_gpio : entity work.vram_gpio
    generic map (
        GPIO_IN_COUNT => GPIO_IN_COUNT,
        GPIO_OUT_COUNT => GPIO_OUT_COUNT,
        GPIO_START_ADDRESS => GPIO_START_ADDRESS
    ) port map (
        data_clk => not clk,
        res_n => res_n,
        data_en => '1', -- TODO: Only enable when needed.

        data_wr => write_enable,
        data_adr => res(13 downto 0),

        data_out => ram_rd_internal,
        data_in => ram_wd_internal,

        gpio_in => gpio_in,
        gpio_out => gpio_out
    );

    -- Data Read Masking
    process(all) begin
        case (opcode) is
        when "0000011" => -- L-Type (Load, res = address)
            case (funct3) is
            when "000" => -- LB
                case (res(1 downto 0)) is
                when "00" => -- 0-7
                    ram_rd <= ( 31 downto 8 => ram_rd_internal(7),
                                7 downto 0 => ram_rd_internal(7 downto 0));
                when "01" => -- 8-15
                    ram_rd <= ( 31 downto 8 => ram_rd_internal(15),
                                7 downto 0 => ram_rd_internal(15 downto 8));
                when "10" => -- 16-23
                    ram_rd <= ( 31 downto 8 => ram_rd_internal(23),
                                7 downto 0 => ram_rd_internal(23 downto 16));
                when "11" => -- 24-31
                    ram_rd <= ( 31 downto 8 => ram_rd_internal(31),
                                7 downto 0 => ram_rd_internal(31 downto 24));

                when others => -- Misaligned Access (Exception)
                    ram_rd <= (others => '0');
                end case;
            when "001" => -- LH
                case(res(1 downto 0)) is
                when "00" => -- 0-15
                    ram_rd <= ( 31 downto 16 => ram_rd_internal(15),
                                15 downto 0 => ram_rd_internal(15 downto 0));
                when "10" => -- 16-31
                    ram_rd <= ( 31 downto 16 => ram_rd_internal(31),
                                15 downto 0 => ram_rd_internal(31 downto 16));

                when others => -- Misaligned Access (Exception)
                    ram_rd <= (others => '0');
                end case;
            when "010" => -- LW
                case (res(1 downto 0)) is
                when "00" => -- 0-31
                    ram_rd <= ram_rd_internal;

                when others => -- Misaligned Access (Exception)
                    ram_rd <= (others => '0');
                end case;
            when "100" => -- LBU
                case (res(1 downto 0)) is
                when "00" => -- 0-7
                    ram_rd <= ( 31 downto 8 => '0',
                                7 downto 0 => ram_rd_internal(7 downto 0));
                when "01" => -- 8-15
                    ram_rd <= ( 31 downto 8 => '0',
                                7 downto 0 => ram_rd_internal(15 downto 8));
                when "10" => -- 16-23
                    ram_rd <= ( 31 downto 8 => '0',
                                7 downto 0 => ram_rd_internal(23 downto 16));
                when "11" => -- 24-31
                    ram_rd <= ( 31 downto 8 => '0',
                                7 downto 0 => ram_rd_internal(31 downto 24));

                when others => -- Misaligned Access (Exception)
                    ram_rd <= (others => '0');
                end case;
            when "101" => -- LHU
                case(res(1 downto 0)) is
                when "00" => -- 0-15
                    ram_rd <= ( 31 downto 16 => '0',
                                15 downto 0 => ram_rd_internal(15 downto 0));
                when "10" => -- 16-31
                    ram_rd <= ( 31 downto 16 => '0',
                                15 downto 0 => ram_rd_internal(31 downto 16));

                when others => -- Misaligned Access (Exception)
                    ram_rd <= (others => '0');
                end case;

            when others =>
                ram_rd <= (others => '0');
            end case;
        when others =>
            ram_rd <= (others => '0');
        end case;
    end process;

    -- Data Write Masking
    process(all) begin
        case (opcode) is
        when "0100011" => -- S-Type (Store, res = address)
            case (funct3) is
            when "000" => -- SB
                case (res(1 downto 0)) is
                when "00" => -- 0-7
                    write_enable <= "1000";
                    ram_wd_internal <= (31 downto 24 => rd2(7 downto 0),
                                        23 downto 0 => '0');
                when "01" => -- 8-15
                    write_enable <= "0100";
                    ram_wd_internal <= (31 downto 24 => '0',
                                        23 downto 16 => rd2(7 downto 0),
                                        15 downto 0 => '0');
                when "10" => -- 16-23
                    write_enable <= "0010";
                    ram_wd_internal <= (31 downto 16 => '0',
                                        15 downto 8 => rd2(7 downto 0),
                                        7 downto 0 => '0');
                when "11" => -- 24-31
                    write_enable <= "0001";
                    ram_wd_internal <= (31 downto 8 => '0',
                                        7 downto 0 => rd2(7 downto 0));

                when others => -- Misaligned Access (Exception)
                    write_enable <= "0000";
                    ram_wd_internal <= (others => '0');
                end case;
            when "001" => -- SH
                case(res(1 downto 0)) is
                when "00" => -- 0-15
                    write_enable <= "1100";
                    ram_wd_internal <= (31 downto 16 => '0',
                                        15 downto 0 => rd2(15 downto 0));
                when "10" => -- 16-31
                    write_enable <= "0011";
                    ram_wd_internal <= (31 downto 16 => rd2(15 downto 0),
                                        15 downto 0 => '0');

                when others => -- Misaligned Access (Exception)
                    write_enable <= "0000";
                    ram_wd_internal <= (others => '0');
                end case;
            when "010" => -- SW
                case (res(1 downto 0)) is
                when "00" => -- 0-31
                    write_enable <= "1111";
                    ram_wd_internal <= rd2;

                when others => -- Misaligned Access (Exception)
                    write_enable <= "0000";
                    ram_wd_internal <= (others => '0');
                end case;
            when

            others =>
                write_enable <= "0000";
                ram_wd_internal <= (others => '0');
            end case;
        when others =>
            write_enable <= "0000";
            ram_wd_internal <= (others => '0');
        end case;
    end process;

end Behavioral;