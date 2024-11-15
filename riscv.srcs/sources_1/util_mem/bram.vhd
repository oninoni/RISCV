--------------------------------
--                            --
--         RISC-V CPU         --
--        Single Cycle        --
--                            --
--       by Jan Ziegler       --
--                            --
--------------------------------

--------------------------------
--   Dual Single Cycle BRAM   --
--------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.vcomponents.all;

entity bram is
    generic (
        INIT_VALUE: bit_vector(0 to 32767)
    );
    port (
        -- Port A
        A_clk: in std_logic;
        A_Enable: in std_logic;

        A_Write: in std_logic_vector(3 downto 0);
        A_Addr: in std_logic_vector(9 downto 0);

        A_RData: out std_logic_vector(31 downto 0);
        A_WData: in std_logic_vector(31 downto 0);

        -- Port B
        B_clk: in std_logic;
        B_Enable: in std_logic;

        B_Write: in std_logic_vector(3 downto 0);
        B_Addr: in std_logic_vector(9 downto 0);

        B_RData: out std_logic_vector(31 downto 0);
        B_WData: in std_logic_vector(31 downto 0)
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

        -- RAM Mode: "SDP" or "TDP"
        RAM_MODE => "TDP",

        -- RAM_EXTENSION_A, RAM_EXTENSION_B: Selects cascade mode ("UPPER", "LOWER", or "NONE")
        RAM_EXTENSION_A => "NONE",
        RAM_EXTENSION_B => "NONE",

        -- READ_WIDTH_A/B, WRITE_WIDTH_A/B: Read/write width per port
        READ_WIDTH_A => 36,
        READ_WIDTH_B => 36,
        WRITE_WIDTH_A => 36,
        WRITE_WIDTH_B => 36,

        -- RSTREG_PRIORITY_A, RSTREG_PRIORITY_B: Reset or enable priority ("RSTREG" or "REGCE")
        RSTREG_PRIORITY_A => "RSTREG",
        RSTREG_PRIORITY_B => "RSTREG",

        -- SRVAL_A, SRVAL_B: Set/reset value for output
        SRVAL_A => X"000000000",
        SRVAL_B => X"000000000",

        -- Simulation Device: Must be set to "7SERIES" for simulation behavior
        SIM_DEVICE => "7SERIES",

        -- WriteMode: Value on output upon a write ("WRITE_FIRST", "READ_FIRST", or "NO_CHANGE")
        WRITE_MODE_A => "READ_FIRST",
        WRITE_MODE_B => "READ_FIRST",

        -- Memory Initialization
        --INIT_FILE => INIT_FILE -> Only works in simulation

        -- Done in 256 bit blocks, since init_file is not supported.
        -- 32 bits data + 4 bits parity = 36 bits
        -- 36864 bits / 36 bits = 1024

        -- Generate all INIT_XX signals until INIT_7F
        INIT_00 => INIT_VALUE(0     to   255),
        INIT_01 => INIT_VALUE(256   to   511),
        INIT_02 => INIT_VALUE(512   to   767),
        INIT_03 => INIT_VALUE(768   to  1023),
        INIT_04 => INIT_VALUE(1024  to  1279),
        INIT_05 => INIT_VALUE(1280  to  1535),
        INIT_06 => INIT_VALUE(1536  to  1791),
        INIT_07 => INIT_VALUE(1792  to  2047),
        INIT_08 => INIT_VALUE(2048  to  2303),
        INIT_09 => INIT_VALUE(2304  to  2559),
        INIT_0A => INIT_VALUE(2560  to  2815),
        INIT_0B => INIT_VALUE(2816  to  3071),
        INIT_0C => INIT_VALUE(3072  to  3327),
        INIT_0D => INIT_VALUE(3328  to  3583),
        INIT_0E => INIT_VALUE(3584  to  3839),
        INIT_0F => INIT_VALUE(3840  to  4095),
        INIT_10 => INIT_VALUE(4096  to  4351),
        INIT_11 => INIT_VALUE(4352  to  4607),
        INIT_12 => INIT_VALUE(4608  to  4863),
        INIT_13 => INIT_VALUE(4864  to  5119),
        INIT_14 => INIT_VALUE(5120  to  5375),
        INIT_15 => INIT_VALUE(5376  to  5631),
        INIT_16 => INIT_VALUE(5632  to  5887),
        INIT_17 => INIT_VALUE(5888  to  6143),
        INIT_18 => INIT_VALUE(6144  to  6399),
        INIT_19 => INIT_VALUE(6400  to  6655),
        INIT_1A => INIT_VALUE(6656  to  6911),
        INIT_1B => INIT_VALUE(6912  to  7167),
        INIT_1C => INIT_VALUE(7168  to  7423),
        INIT_1D => INIT_VALUE(7424  to  7679),
        INIT_1E => INIT_VALUE(7680  to  7935),
        INIT_1F => INIT_VALUE(7936  to  8191),
        INIT_20 => INIT_VALUE(8192  to  8447),
        INIT_21 => INIT_VALUE(8448  to  8703),
        INIT_22 => INIT_VALUE(8704  to  8959),
        INIT_23 => INIT_VALUE(8960  to  9215),
        INIT_24 => INIT_VALUE(9216  to  9471),
        INIT_25 => INIT_VALUE(9472  to  9727),
        INIT_26 => INIT_VALUE(9728  to  9983),
        INIT_27 => INIT_VALUE(9984  to 10239),
        INIT_28 => INIT_VALUE(10240 to 10495),
        INIT_29 => INIT_VALUE(10496 to 10751),
        INIT_2A => INIT_VALUE(10752 to 11007),
        INIT_2B => INIT_VALUE(11008 to 11263),
        INIT_2C => INIT_VALUE(11264 to 11519),
        INIT_2D => INIT_VALUE(11520 to 11775),
        INIT_2E => INIT_VALUE(11776 to 12031),
        INIT_2F => INIT_VALUE(12032 to 12287),
        INIT_30 => INIT_VALUE(12288 to 12543),
        INIT_31 => INIT_VALUE(12544 to 12799),
        INIT_32 => INIT_VALUE(12800 to 13055),
        INIT_33 => INIT_VALUE(13056 to 13311),
        INIT_34 => INIT_VALUE(13312 to 13567),
        INIT_35 => INIT_VALUE(13568 to 13823),
        INIT_36 => INIT_VALUE(13824 to 14079),
        INIT_37 => INIT_VALUE(14080 to 14335),
        INIT_38 => INIT_VALUE(14336 to 14591),
        INIT_39 => INIT_VALUE(14592 to 14847),
        INIT_3A => INIT_VALUE(14848 to 15103),
        INIT_3B => INIT_VALUE(15104 to 15359),
        INIT_3C => INIT_VALUE(15360 to 15615),
        INIT_3D => INIT_VALUE(15616 to 15871),
        INIT_3E => INIT_VALUE(15872 to 16127),
        INIT_3F => INIT_VALUE(16128 to 16383),
        INIT_40 => INIT_VALUE(16384 to 16639),
        INIT_41 => INIT_VALUE(16640 to 16895),
        INIT_42 => INIT_VALUE(16896 to 17151),
        INIT_43 => INIT_VALUE(17152 to 17407),
        INIT_44 => INIT_VALUE(17408 to 17663),
        INIT_45 => INIT_VALUE(17664 to 17919),
        INIT_46 => INIT_VALUE(17920 to 18175),
        INIT_47 => INIT_VALUE(18176 to 18431),
        INIT_48 => INIT_VALUE(18432 to 18687),
        INIT_49 => INIT_VALUE(18688 to 18943),
        INIT_4A => INIT_VALUE(18944 to 19199),
        INIT_4B => INIT_VALUE(19200 to 19455),
        INIT_4C => INIT_VALUE(19456 to 19711),
        INIT_4D => INIT_VALUE(19712 to 19967),
        INIT_4E => INIT_VALUE(19968 to 20223),
        INIT_4F => INIT_VALUE(20224 to 20479),
        INIT_50 => INIT_VALUE(20480 to 20735),
        INIT_51 => INIT_VALUE(20736 to 20991),
        INIT_52 => INIT_VALUE(20992 to 21247),
        INIT_53 => INIT_VALUE(21248 to 21503),
        INIT_54 => INIT_VALUE(21504 to 21759),
        INIT_55 => INIT_VALUE(21760 to 22015),
        INIT_56 => INIT_VALUE(22016 to 22271),
        INIT_57 => INIT_VALUE(22272 to 22527),
        INIT_58 => INIT_VALUE(22528 to 22783),
        INIT_59 => INIT_VALUE(22784 to 23039),
        INIT_5A => INIT_VALUE(23040 to 23295),
        INIT_5B => INIT_VALUE(23296 to 23551),
        INIT_5C => INIT_VALUE(23552 to 23807),
        INIT_5D => INIT_VALUE(23808 to 24063),
        INIT_5E => INIT_VALUE(24064 to 24319),
        INIT_5F => INIT_VALUE(24320 to 24575),
        INIT_60 => INIT_VALUE(24576 to 24831),
        INIT_61 => INIT_VALUE(24832 to 25087),
        INIT_62 => INIT_VALUE(25088 to 25343),
        INIT_63 => INIT_VALUE(25344 to 25599),
        INIT_64 => INIT_VALUE(25600 to 25855),
        INIT_65 => INIT_VALUE(25856 to 26111),
        INIT_66 => INIT_VALUE(26112 to 26367),
        INIT_67 => INIT_VALUE(26368 to 26623),
        INIT_68 => INIT_VALUE(26624 to 26879),
        INIT_69 => INIT_VALUE(26880 to 27135),
        INIT_6A => INIT_VALUE(27136 to 27391),
        INIT_6B => INIT_VALUE(27392 to 27647),
        INIT_6C => INIT_VALUE(27648 to 27903),
        INIT_6D => INIT_VALUE(27904 to 28159),
        INIT_6E => INIT_VALUE(28160 to 28415),
        INIT_6F => INIT_VALUE(28416 to 28671),
        INIT_70 => INIT_VALUE(28672 to 28927),
        INIT_71 => INIT_VALUE(28928 to 29183),
        INIT_72 => INIT_VALUE(29184 to 29439),
        INIT_73 => INIT_VALUE(29440 to 29695),
        INIT_74 => INIT_VALUE(29696 to 29951),
        INIT_75 => INIT_VALUE(29952 to 30207),
        INIT_76 => INIT_VALUE(30208 to 30463),
        INIT_77 => INIT_VALUE(30464 to 30719),
        INIT_78 => INIT_VALUE(30720 to 30975),
        INIT_79 => INIT_VALUE(30976 to 31231),
        INIT_7A => INIT_VALUE(31232 to 31487),
        INIT_7B => INIT_VALUE(31488 to 31743),
        INIT_7C => INIT_VALUE(31744 to 31999),
        INIT_7D => INIT_VALUE(32000 to 32255),
        INIT_7E => INIT_VALUE(32256 to 32511),
        INIT_7F => INIT_VALUE(32512 to 32767)
    )
    port map (
        -- Port A I/O Signals
        CLKARDCLK => A_clk,
        ENARDEN => A_Enable,

        WEA => A_Write,
        ADDRARDADDR => ('1', A_Addr(9 downto 0), others => '0'),

        DOADO => A_RData,
        DIADI => A_WData,

        -- Port B I/O Signals
        CLKBWRCLK => B_clk,
        ENBWREN => B_Enable,

        WEBWE => ("0000", B_Write),
        ADDRBWRADDR => ('1', B_Addr(9 downto 0), others => '0'),

        DOBDO => B_RData,
        DIBDI => B_WData,

        -- Disabled Signals
        RSTRAMARSTRAM => '0',
        RSTREGARSTREG => '0',
        RSTRAMB => '0',
        RSTREGB => '0',

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