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
        BRAM_COUNT: integer := 4;
        BRAM_WIDTH: integer := integer(ceil(log2(real(BRAM_COUNT))));

        INIT_VALUE : std_logic_vector(0 to 32768 * BRAM_COUNT - 1) := (others => '0')
    );
    Port (
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
        gpio_in : in STD_LOGIC_VECTOR (255 downto 0);
        gpio_out : out STD_LOGIC_VECTOR (255 downto 0) := (others => '0')
    );
end mem_controller;


-- RAM Mapping:
-- FPGA has 50 36kb RAM blocks
-- We will need some for other stuff, so only a part will be used for general purpose RAM / Instruction Memory
-- Other RAM Mapped devices are added later.
--
-- Current Memory Map:
-- 0x0000_0000 - 0x0000_FFFF: Instruction Memory (up to 16 x 32kb BRAMs, depending on BRAM_COUNT)
-- 0x0001_0000 - 0x0001_000F: GPIO_OUT (8 * 32bit GPIO Banks)
-- 0x0001_0020 - 0x0001_002F: GPIO_IN (8 * 32bit GPIO Banks)
-- 0x0001_0030 - 0x0001_FFFF: Reserved for GPIO Memory Expansion
-- 0x0002_0000 - 0xFFFF_FFFF: Unused

architecture Behavioral of mem_controller is
    signal read_enable : std_logic;
    signal ram_rd_internal : std_logic_vector(31 downto 0);

    signal ins_en : std_logic;
    signal gpio_en : std_logic;
    signal ram_rd_instruction : std_logic_vector(31 downto 0) := (others => '0');
    signal ram_rd_gpio : std_logic_vector(31 downto 0) := (others => '0');

    signal write_enable : std_logic_vector(3 downto 0);
    signal ram_wd_internal : std_logic_vector(31 downto 0);

begin
    --------------------------------
    --       Memory Devices       --
    --------------------------------

    -- Instruction Memory Bank
    bram_instruction : entity work.bram_instruction
    generic map (
        BRAM_COUNT => BRAM_COUNT,
        INIT_VALUE => INIT_VALUE
    ) port map (
        data_clk => clk,
        data_en => ins_en,

        data_wr => write_enable,
        data_adr => mem_adr(11 + BRAM_WIDTH downto 0),

        data_out => ram_rd_instruction,
        data_in => ram_wd_internal,

        instruction_clk => clk,
        instruction_adr => pc(11 + BRAM_WIDTH downto 0),
        instruction_out => instruction
    );

    -- GPIO Memory Interface
    vram_gpio : entity work.vram_gpio
    port map (
        data_clk => clk,
        res_n => res_n,
        data_en => gpio_en,

        data_wr => write_enable,
        data_adr => mem_adr(5 downto 0),

        data_out => ram_rd_gpio,
        data_in => ram_wd_internal,

        gpio_in => gpio_in,
        gpio_out => gpio_out
    );

    --------------------------------
    --       Memory Mapping       --
    --------------------------------

    -- Memory Map Control Signals
    process(all) begin
        ins_en <= '0';
        gpio_en <= '0';

        -- Instruction Memory
        if mem_adr(31 downto 16) = x"0000" then
            ins_en <= read_enable or write_enable(3) or write_enable(2) or write_enable(1) or write_enable(0);

        -- GPIO Memory
        elsif mem_adr(31 downto 16) = x"0001" then
            gpio_en <= read_enable or write_enable(3) or write_enable(2) or write_enable(1) or write_enable(0);

        end if;
    end process;

    -- Memory Map Read Multiplexer
    process(all) begin
        case (mem_adr(31 downto 16)) is
        when x"0000" => -- Instruction Memory
            ram_rd_internal <= ram_rd_instruction;
        when x"0001" => -- GPIO Memory
            ram_rd_internal <= ram_rd_gpio;
        when others =>
            ram_rd_internal <= (others => '0');
        end case;
    end process;

    --------------------------------
    --        Byte Masking        --
    --------------------------------

    -- Data Read Byte Masking
    process(all) begin -- Temporarily disabled
        read_enable <= '0';
        mem_read_data <= (others => '0');
    end process;

    -- Data Write Byte Masking
    process(all) begin -- Temporarily disabled
        write_enable <= "0000";
        ram_wd_internal <= (others => '0');
    end process;
end Behavioral;

--        case (opcode) is
--        when "0000011" => -- L-Type (Load, res = address)
--            case (funct3) is
--            when "000" => -- LB
--                case (mem_adr(1 downto 0)) is
--                when "00" => -- 0-7
--                    read_enable <= '1';
--                    mem_read_data <= ( 31 downto 8 => ram_rd_internal(7),
--                                7 downto 0 => ram_rd_internal(7 downto 0));
--                when "01" => -- 8-15
--                    read_enable <= '1';
--                    mem_read_data <= ( 31 downto 8 => ram_rd_internal(15),
--                                7 downto 0 => ram_rd_internal(15 downto 8));
--                when "10" => -- 16-23
--                    read_enable <= '1';
--                    mem_read_data <= ( 31 downto 8 => ram_rd_internal(23),
--                                7 downto 0 => ram_rd_internal(23 downto 16));
--                when "11" => -- 24-31
--                    read_enable <= '1';
--                    mem_read_data <= ( 31 downto 8 => ram_rd_internal(31),
--                                7 downto 0 => ram_rd_internal(31 downto 24));
--
--                when others => -- Misaligned Access (Exception)
--                    read_enable <= '0';
--                    mem_read_data <= (others => '0');
--                end case;
--            when "001" => -- LH
--                case(mem_adr(1 downto 0)) is
--                when "00" => -- 0-15
--                    read_enable <= '1';
--                    mem_read_data <= ( 31 downto 16 => ram_rd_internal(15),
--                                15 downto 0 => ram_rd_internal(15 downto 0));
--                when "10" => -- 16-31
--                    read_enable <= '1';
--                    mem_read_data <= ( 31 downto 16 => ram_rd_internal(31),
--                                15 downto 0 => ram_rd_internal(31 downto 16));
--
--                when others => -- Misaligned Access (Exception)
--                    read_enable <= '0';
--                    mem_read_data <= (others => '0');
--                end case;
--            when "010" => -- LW
--                case (mem_adr(1 downto 0)) is
--                when "00" => -- 0-31
--                    read_enable <= '1';
--                    mem_read_data <= ram_rd_internal;
--
--                when others => -- Misaligned Access (Exception)
--                    read_enable <= '0';
--                    mem_read_data <= (others => '0');
--                end case;
--            when "100" => -- LBU
--                case (mem_adr(1 downto 0)) is
--                when "00" => -- 0-7
--                    read_enable <= '1';
--                    mem_read_data <= ( 31 downto 8 => '0',
--                                7 downto 0 => ram_rd_internal(7 downto 0));
--                when "01" => -- 8-15
--                    read_enable <= '1';
--                    mem_read_data <= ( 31 downto 8 => '0',
--                                7 downto 0 => ram_rd_internal(15 downto 8));
--                when "10" => -- 16-23
--                    read_enable <= '1';
--                    mem_read_data <= ( 31 downto 8 => '0',
--                                7 downto 0 => ram_rd_internal(23 downto 16));
--                when "11" => -- 24-31
--                    read_enable <= '1';
--                    mem_read_data <= ( 31 downto 8 => '0',
--                                7 downto 0 => ram_rd_internal(31 downto 24));
--
--                when others => -- Misaligned Access (Exception)
--                    read_enable <= '0';
--                    mem_read_data <= (others => '0');
--                end case;
--            when "101" => -- LHU
--                case(mem_adr(1 downto 0)) is
--                when "00" => -- 0-15
--                    read_enable <= '1';
--                    mem_read_data <= ( 31 downto 16 => '0',
--                                15 downto 0 => ram_rd_internal(15 downto 0));
--                when "10" => -- 16-31
--                    read_enable <= '1';
--                    mem_read_data <= ( 31 downto 16 => '0',
--                                15 downto 0 => ram_rd_internal(31 downto 16));
--
--                when others => -- Misaligned Access (Exception)
--                    read_enable <= '0';
--                    mem_read_data <= (others => '0');
--                end case;
--
--            when others =>
--                read_enable <= '0';
--                mem_read_data <= (others => '0');
--            end case;
--        when others =>
--            read_enable <= '0';
--            mem_read_data <= (others => '0');
--        end case;


--        case (opcode) is
--        when "0100011" => -- S-Type (Store, res = address)
--            case (funct3) is
--            when "000" => -- SB
--                case (mem_adr(1 downto 0)) is
--                when "00" => -- 0-7
--                    write_enable <= "1000";
--                    ram_wd_internal <= (31 downto 24 => rd2(7 downto 0),
--                                        23 downto 0 => '0');
--                when "01" => -- 8-15
--                    write_enable <= "0100";
--                    ram_wd_internal <= (31 downto 24 => '0',
--                                        23 downto 16 => rd2(7 downto 0),
--                                        15 downto 0 => '0');
--                when "10" => -- 16-23
--                    write_enable <= "0010";
--                    ram_wd_internal <= (31 downto 16 => '0',
--                                        15 downto 8 => rd2(7 downto 0),
--                                        7 downto 0 => '0');
--                when "11" => -- 24-31
--                    write_enable <= "0001";
--                    ram_wd_internal <= (31 downto 8 => '0',
--                                        7 downto 0 => rd2(7 downto 0));
--
--                when others => -- Misaligned Access (Exception)
--                    write_enable <= "0000";
--                    ram_wd_internal <= (others => '0');
--                end case;
--            when "001" => -- SH
--                case(mem_adr(1 downto 0)) is
--                when "00" => -- 0-15
--                    write_enable <= "0011";
--                    ram_wd_internal <= (31 downto 16 => '0',
--                                        15 downto 0 => rd2(15 downto 0));
--                when "10" => -- 16-31
--                    write_enable <= "1100";
--                    ram_wd_internal <= (31 downto 16 => rd2(15 downto 0),
--                                        15 downto 0 => '0');
--
--                when others => -- Misaligned Access (Exception)
--                    write_enable <= "0000";
--                    ram_wd_internal <= (others => '0');
--                end case;
--            when "010" => -- SW
--                case (mem_adr(1 downto 0)) is
--                when "00" => -- 0-31
--                    write_enable <= "1111";
--                    ram_wd_internal <= rd2;
--
--                when others => -- Misaligned Access (Exception)
--                    write_enable <= "0000";
--                    ram_wd_internal <= (others => '0');
--                end case;
--            when
--
--            others =>
--                write_enable <= "0000";
--                ram_wd_internal <= (others => '0');
--            end case;
--        when others =>
--            write_enable <= "0000";
--            ram_wd_internal <= (others => '0');
--        end case;
--    end process;