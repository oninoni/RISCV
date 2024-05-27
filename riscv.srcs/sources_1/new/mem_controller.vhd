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
begin
    -- Single 36kb BRAM for now. Can be expanded later.
    ins_mem : entity work.bram
    generic map (
        INIT_FILE => "instruction.mem"
    )
    port map (
        -- Port A: Load / Store Instructions
        -- Executed on the falling edge of the clock
        A_clk => not clk,
        A_Enable => write_enable,
        A_addr => res(15 downto 0),

        A_Write => rd2,
        A_Read => ram_rd,

        -- Port B, Fetch Instructions
        -- Executed on the rising edge of the clock
        B_clk => clk,
        B_addr => pc(15 downto 0),

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