-- Jan Ziegler

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.vcomponents.all;

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
    RAMB36E1 : UNISIM.vcomponents.RAMB36E1
    generic map (
        -- Address Collision Mode: "PERFORMANCE" or "DELAYED_WRITE"
        RDADDR_COLLISION_HWCONFIG => "PERFORMANCE",

        -- Collision check: Values ("ALL", "WARNING_ONLY", "GENERATE_X_ONLY" or "NONE")
        SIM_COLLISION_CHECK => "ALL",

        -- Do not pipeline the data output
        DOA_REG => 0,
        DOB_REG => 0,

        -- ECC Disabled
        EN_ECC_READ => FALSE,
        EN_ECC_WRITE => FALSE,

        -- INIT_A, INIT_B: Initial values on output ports
        INIT_A => X"000000000",
        INIT_B => X"000000000",

        -- Initialization File: RAM initialization file
        INIT_FILE => INIT_FILE,

        -- RAM Mode: "SDP" or "TDP"
        RAM_MODE => "TDP",

        -- RAM_EXTENSION_A, RAM_EXTENSION_B: Selects cascade mode ("UPPER", "LOWER", or "NONE")
        RAM_EXTENSION_A => "NONE",
        RAM_EXTENSION_B => "NONE",

        -- READ_WIDTH_A/B, WRITE_WIDTH_A/B: Read/write width per port
        READ_WIDTH_A => 32,
        READ_WIDTH_B => 32,
        WRITE_WIDTH_A => 32,
        WRITE_WIDTH_B => 0,

        -- RSTREG_PRIORITY_A, RSTREG_PRIORITY_B: Reset or enable priority ("RSTREG" or "REGCE")
        RSTREG_PRIORITY_A => "RSTREG",
        RSTREG_PRIORITY_B => "RSTREG",

        -- SRVAL_A, SRVAL_B: Set/reset value for output
        SRVAL_A => X"000000000",
        SRVAL_B => X"000000000",

        -- Simulation Device: Must be set to "7SERIES" for simulation behavior
        SIM_DEVICE => "7SERIES",

        -- WriteMode: Value on output upon a write ("WRITE_FIRST", "READ_FIRST", or "NO_CHANGE")
        WRITE_MODE_A => "WRITE_FIRST",
        WRITE_MODE_B => "WRITE_FIRST"
    )
    port map (
        -- Port A I/O Signals
        CLKARDCLK => A_clk,
        ENARDEN => A_Enable,
        ADDRARDADDR => A_Addr,

        DOADO => A_Read,
        DIADI => A_Write,

        -- Port B I/O Signals
        CLKBWRCLK => B_clk,
        ENBWREN => '0',
        ADDRBWRADDR => B_Addr,

        DOBDO => B_Read,
        DIBDI => "00000000000000000000000000000000",

        -- Disabled Signals
        RSTRAMARSTRAM => '0',
        RSTREGARSTREG => '0',
        RSTRAMB => '0',
        RSTREGB => '0',

        WEA => "1111",
        WEBWE => "11111111",
        REGCEAREGCE => '0',
        REGCEB => '0',

        -- Partity Data
        DIPADIP => "0000",
        DIPBDIP => "0000",
        DOPADOP => open,
        DOPBDOP => open,

        -- Cascade Signals
        CASCADEINA => '0',
        CASCADEINB => '0',
        CASCADEOUTA => open,
        CASCADEOUTB => open,

        -- ECC Signals
        INJECTDBITERR => '0',
        INJECTSBITERR => '0',
        DBITERR => open,
        ECCPARITY => open,
        RDADDRECC => open,
        SBITERR => open
    );
end architecture Behavior;