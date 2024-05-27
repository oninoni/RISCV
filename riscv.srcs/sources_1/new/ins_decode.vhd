-- Jan Ziegler

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ins_decode is
    Port ( 
        instruction : in STD_LOGIC_VECTOR (31 downto 0);

        opcode : out STD_LOGIC_VECTOR (6 downto 0);
        funct3 : out STD_LOGIC_VECTOR (3 downto 0);
        funct7 : out STD_LOGIC_VECTOR (6 downto 0);

        rs1 : out STD_LOGIC_VECTOR (4 downto 0);
        rs2 : out STD_LOGIC_VECTOR (4 downto 0);
        rd : out STD_LOGIC_VECTOR (4 downto 0);
        
        imm : out STD_LOGIC_VECTOR (31 downto 0);
    );
end ins_decode;

architecture Behavioral of ins_decode is
begin

    -- Simple Decoder
    process(all) 
    begin
        opcode <= instruction(6 downto 0);
        funct3 <= instruction(14 downto 12);
        funct7 <= instruction(31 downto 25);

        rs1 <= instruction(19 downto 15);
        rs2 <= instruction(24 downto 20);
        rd <= instruction(11 downto 7);
    end process;

    -- Immediate Decoder + Sign Extension
    process(all)
    begin
        case (opcode) is
        when "0110011" => -- R-Type (ALU)
            imm <= (others => '0');
        when "0010011" => -- I-Type (ALU)
            imm <= (others => instruction(31), instruction(31 downto 20));
        when "0000011" => -- I-Type (Load)
            imm <= (others => instruction(31), instruction(31 downto 20));
        when "0100011" => -- S-Type (Store)
            imm <= (others => instruction(31), instruction(31 downto 25), instruction(11 downto 7));
        when "1100011" => -- B-Type (Branch)
            imm <= (others => instruction(31), instruction(7), instruction(30 downto 25), instruction(11 downto 8), '0');
        when "1100111" => -- J-Type (JAL)
            imm <= (others => instruction(31), instruction(19 downto 12), instruction(20), instruction(30 downto 21), '0');
        when "1100111" => -- I-Type (JALR)
            imm <= (others => instruction(31), instruction(31 downto 20));
        when "0110111" => -- U-Type (LUI)
            imm <= (instruction(31 downto 12), others => '0');
        when "1110011" => -- I-Type (ECALL / EBREAK)
            imm <= (others => instruction(31), instruction(31 downto 20));
        when others =>
            imm <= (others => '0');
        end case;
    end process;
    
end Behavioral;