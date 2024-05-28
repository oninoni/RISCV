-- Jan Ziegler

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;
Library xpm;
use xpm.vcomponents.all;

entity bram is
    generic (
        INIT_FILE: string
    );
    port (
        -- Port A
        A_clk: in std_logic;
        A_Enable: in std_logic;
        A_Addr: in std_logic_vector(9 downto 0);

        A_Read: out std_logic_vector(31 downto 0);
        A_Write: in std_logic_vector(31 downto 0);

        -- Port B
        B_clk: in std_logic;
        B_Addr: in std_logic_vector(9 downto 0);

        B_Read: out std_logic_vector(31 downto 0)
    );
end entity bram;

architecture Behavior of bram is
begin
    xpm_memory_tdpram : xpm.vcomponents.xpm_memory_tdpram
    generic map (
        -- Memory Size: 36kb
        MEMORY_SIZE => 32768, --36864,

        -- Width of data ports
        READ_DATA_WIDTH_A => 32,
        READ_DATA_WIDTH_B => 32,
        WRITE_DATA_WIDTH_A => 32,
        WRITE_DATA_WIDTH_B => 32,

        -- Data Width of the memory
        -- 36864 / 32 = 1152 Memory Locations
        -- We need 11 bits to address 1152 locations
        ADDR_WIDTH_A => 10, -- 11,
        ADDR_WIDTH_B => 10, -- 11,

        -- Collision Handling. Don't care because Port B is read only.
        WRITE_MODE_A => "write_first",
        WRITE_MODE_B => "write_first",

        -- Seperate Clocks for Port A and B
        CLOCKING_MODE => "independent_clock",

        -- This might be able, to cascade multiple BRAMs?
        -- Disable for now
        CASCADE_HEIGHT => 0,

        -- Enable Memory Initialization for synthesis
        MEMORY_INIT_FILE => INIT_FILE,
        MEMORY_INIT_PARAM => "0",

        -- Enable Debug Messages
        MESSAGE_CONTROL => 1,
        SIM_ASSERT_CHK => 1,

        -- Enable Combinatorial Read
        READ_LATENCY_A => 0,
        READ_LATENCY_B => 0,

        -- Disable Memory Initialization Message
        USE_MEM_INIT => 0,
        USE_MEM_INIT_MMI => 0,



        -- Sync Reset Values
        READ_RESET_VALUE_A => "00000000",
        READ_RESET_VALUE_B => "00000000",
        RST_MODE_A => "SYNC",
        RST_MODE_B => "SYNC",

        -- Disable Auto Sleep
        WAKEUP_TIME => "disable_sleep",
        AUTO_SLEEP_TIME => 0,
        -- Disable Memory Optimization
        MEMORY_OPTIMIZATION => "false",
        MEMORY_PRIMITIVE => "block",
        RAM_DECOMP => "area",
        -- Disable Write Protect
        WRITE_PROTECT => 0,

        -- Disable ECC
        ECC_MODE => "no_ecc",
        ECC_BIT_RANGE => "0:0",
        ECC_TYPE => "none",

        -- Tell the BRAM that a byte is 8 bits
        BYTE_WRITE_WIDTH_A => 8,
        BYTE_WRITE_WIDTH_B => 8,

        -- No Idea
        USE_EMBEDDED_CONSTRAINT => 0
    )
    port map(
        -- Port A I/O Signals
        clka => A_clk,
        addra => A_Addr,
        ena => '1',
        regcea => '1',
        rsta => '0',
        wea => (others => A_Enable),

        douta => A_Read,
        dina => A_Write,

        -- Port B I/O Signals
        clkb => B_clk,
        addrb => B_Addr,
        enb => '1',
        regceb => '1',
        rstb => '0',
        web => (others => '0'),

        doutb => B_Read,
        dinb => (others => '0'),

        -- Disabled Signals
        dbiterra => open,
        dbiterrb => open,

        injectdbiterra => '0',
        injectdbiterrb => '0',
        injectsbiterra => '0',
        injectsbiterrb => '0',

        sbiterra => open,
        sbiterrb => open,

        sleep => '0'
    );
end architecture Behavior;