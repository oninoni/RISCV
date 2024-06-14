-- Jan Ziegler

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity bram_instruction is
    generic (
        BRAM_COUNT: integer := 1;
        BRAM_WIDTH: integer := integer(ceil(log2(real(BRAM_COUNT))));

        INIT_VALUE: std_logic_vector(0 to 32768 * BRAM_COUNT - 1) := (others => '0')
    );
    port (
        -- Data Interface
        data_clk : in std_logic;
        data_en : in std_logic;

        data_wr : in std_logic_vector(3 downto 0);
        data_adr : in std_logic_vector((11 + BRAM_WIDTH) downto 0);

        data_out : out std_logic_vector(31 downto 0);
        data_in : in std_logic_vector(31 downto 0);

        -- Instruction Fetch Interface
        instruction_clk : in std_logic;
        instruction_adr : in std_logic_vector((11 + BRAM_WIDTH) downto 0);
        instruction_out : out std_logic_vector(31 downto 0)
    );
end bram_instruction;

architecture Behavioral of bram_instruction is
    -- Convert the init value to the correct format for a single BRAM.
    impure function untangle_init(
        init : in std_logic_vector(0 to 32767)
    ) return bit_vector is
        variable init_ut : bit_vector(0 to 32767);

        variable target : integer;
        variable source : integer;
    begin
        -- Swap the order of the words in groups of 8
        for i in 0 to 127 loop
            for j in 0 to 7 loop
                target := i * 8 + j;
                source := i * 8 + (7 - j);

                init_ut(target * 32 to target * 32 + 31) := to_bitvector(init(source * 32 to source * 32 + 31));
            end loop;
        end loop;

        return init_ut;
    end function;

    signal bram_data_en : std_logic_vector(BRAM_COUNT - 1 downto 0);
    signal bram_instruction_en : std_logic_vector(BRAM_COUNT - 1 downto 0);

    type std_logic_aoa is array (natural range <>) of std_logic_vector;

    signal bram_data_out : std_logic_aoa(0 to BRAM_COUNT - 1)(31 downto 0);
    signal bram_instruction_out : std_logic_aoa(0 to BRAM_COUNT - 1)(31 downto 0);
begin
    -- Generate the BRAMs with the correct enable signals.
    gen_bram : for i in 0 to BRAM_COUNT - 1 generate
    begin
        -- Instantiate the BRAMs
        bram : entity work.bram
        generic map (
            INIT_VALUE => untangle_init(INIT_VALUE(32768 * i to 32768 * (i + 1) - 1))
        ) port map (
            A_clk => data_clk,
            A_Enable => bram_data_en(i),

            A_Write => data_wr,
            A_Addr => data_adr(11 downto 2),

            A_RData => bram_data_out(i),
            A_WData => data_in,

            B_clk => instruction_clk,
            B_Enable => bram_instruction_en(i),

            B_Write => "0000",
            B_Addr => instruction_adr(11 downto 2),

            B_RData => bram_instruction_out(i),
            B_WData => (others => '0')
        );
    end generate;

    -- Generate the enable signals for the BRAMs.
    process(all)
    begin
        bram_data_en <= (others => '0');
        bram_instruction_en <= (others => '0');

        bram_data_en(to_integer(unsigned(data_adr(11 + BRAM_WIDTH downto 12)))) <= data_en;
        bram_instruction_en(to_integer(unsigned(instruction_adr(11 + BRAM_WIDTH downto 12)))) <= '1';
    end process;

    -- Multiplex the output of the BRAMs.
    process(all)
    begin
        if (data_en = '1') then
            data_out <= bram_data_out(to_integer(unsigned(data_adr(11 + BRAM_WIDTH downto 12))));
        else
            data_out <= (others => '0');
        end if;

        instruction_out <= bram_instruction_out(to_integer(unsigned(instruction_adr(11 + BRAM_WIDTH downto 12))));
    end process;
end Behavioral;