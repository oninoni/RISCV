-- Jan Ziegler

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reg_file is
    Port (
        clk : in STD_LOGIC;
        res_n : in STD_LOGIC;

        opcode : in STD_LOGIC_VECTOR (6 downto 0);

        rs1 : in STD_LOGIC_VECTOR (4 downto 0);
        rs2 : in STD_LOGIC_VECTOR (4 downto 0);

        imm : in STD_LOGIC_VECTOR (31 downto 0);
        pc_4 : in STD_LOGIC_VECTOR (31 downto 0);

        rd : in STD_LOGIC_VECTOR (4 downto 0);
        res : in STD_LOGIC_VECTOR (31 downto 0);

        rd1 : out STD_LOGIC_VECTOR (31 downto 0);
        rd2 : out STD_LOGIC_VECTOR (31 downto 0);

        ram_rd : in STD_LOGIC_VECTOR (31 downto 0)
    );
end reg_file;

architecture Behavioral of reg_file is
    type reg_array is array (1 to 31) of std_logic_vector(31 downto 0);
    signal regs : reg_array := (others => (others => '0'));

    signal pc_4_stored : std_logic_vector(31 downto 0);
begin

    -- Read register file
    process(all)
    begin
        if (rs1 = "00000") then -- Hard Zero
            rd1 <= (others => '0');
        else
            case (opcode) is
            when "0110011" => -- R-Type (ALU)
                rd1 <= regs(to_integer(unsigned(rs1)));
            when "0010011" => -- I-Type (ALU Imm)
                rd1 <= regs(to_integer(unsigned(rs1)));
            when "0000011" => -- I-Type (Load)
                rd1 <= regs(to_integer(unsigned(rs1)));
            when "0100011" => -- S-Type (Store)
                rd1 <= regs(to_integer(unsigned(rs1)));
            when "1100011" => -- B-Type (Branch)
                rd1 <= regs(to_integer(unsigned(rs1)));
            when "1100111" => -- I-Type (JALR)
                rd1 <= regs(to_integer(unsigned(rs1)));

            when others =>
                rd1 <= (others => '0');
            end case;
        end if;

        if (rs2 = "00000") then -- Hard Zero
            rd2 <= (others => '0');
        else
            case (opcode) is
            when "0110011" => -- R-Type (ALU)
                rd2 <= regs(to_integer(unsigned(rs2)));
            when "0100011" => -- S-Type (Store)
                rd2 <= regs(to_integer(unsigned(rs2)));
            when "1100011" => -- B-Type (Branch)
                rd2 <= regs(to_integer(unsigned(rs2)));

            when others =>
                rd2 <= (others => '0');
            end case;
        end if;
    end process;

    -- Write register file
    process(clk, res_n)
    begin
        if (res_n = '0') then -- Reset
            regs <= (others => (others => '0'));
        elsif (rising_edge(clk)) then
            if rd /= "00000" then -- Ignore Hard Zero
                case (opcode) is
                when "0110011" => -- R-Type (ALU)
                    regs(to_integer(unsigned(rd))) <= res;
                when "0010011" => -- I-Type (ALU Imm)
                    regs(to_integer(unsigned(rd))) <= res;
                when "0000011" => -- I-Type (Load)
                    regs(to_integer(unsigned(rd))) <= ram_rd;
                when "1101111" => -- J-Type (JAL)
                    regs(to_integer(unsigned(rd))) <= pc_4_stored;
                when "1100111" => -- I-Type (JALR)
                    regs(to_integer(unsigned(rd))) <= pc_4_stored;
                when "0110111" => -- U-Type (LUI)
                    regs(to_integer(unsigned(rd))) <= imm;
                when "0010111" => -- U-Type (AUIPC)
                    regs(to_integer(unsigned(rd))) <= res;
                when others =>
                    null;
                end case;
            end if;
        end if;
    end process;

    -- Store pc_4 on falling edge, so it is still the previous value on rising edge
    process(clk, res_n)
    begin
        if (res_n = '0') then -- Reset
            pc_4_stored <= (others => '0');
        elsif falling_edge(clk) then
            pc_4_stored <= pc_4;
        end if;
    end process;
end Behavioral;