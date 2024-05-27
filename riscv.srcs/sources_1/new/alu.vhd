-- Jan Ziegler

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu is
    Port (
        opcode : in STD_LOGIC_VECTOR (6 downto 0);
        funct3 : in STD_LOGIC_VECTOR (2 downto 0);
        funct7 : in STD_LOGIC_VECTOR (6 downto 0);

        imm : in STD_LOGIC_VECTOR (31 downto 0);

        rd1 : in STD_LOGIC_VECTOR (31 downto 0);
        rd2 : in STD_LOGIC_VECTOR (31 downto 0);
        res : out STD_LOGIC_VECTOR (31 downto 0)
    );
end alu;

architecture Behavioral of alu is
begin

    -- RISC-V ALU
    -- Opcode: https://www.cs.sfu.ca/~ashriram/Courses/CS295/assets/notebooks/RISCV/RISCV_CARD.pdf
    process(all)
    begin
        case (opcode) is
        when "0110011" => -- R-type (res = rd1 ? rd2)
            case (funct3) is
            when "000" => -- ADD / SUB
                case (funct7) is
                when "0000000" => -- ADD
                    res <= std_logic_vector(signed(rd1) + signed(rd2));
                when "0100000" => -- SUB
                    res <= std_logic_vector(signed(rd1) - signed(rd2));
                when others =>
                    res <= (others => '0');
                end case;
            --when "001" => -- SLL
            --when "010" => -- SLT
            --when "011" => -- SLTU
            when "100" => -- XOR
                res <= rd1 xor rd2;
            --when "101" => -- SRL / SRA
            when "110" => -- OR
                res <= rd1 or rd2;
            when "111" => -- AND
                res <= rd1 and rd2;
            when others =>
                res <= (others => '0');
            end case;
        when "0010011" => -- I-type (res = rd1 ? imm)
            case (funct3) is
            when "000" => -- ADDI
                res <= std_logic_vector(signed(rd1) + signed(imm));
            --when "001" => -- SLLI
            --when "010" => -- SLTI
            --when "011" => -- SLTIU
            when "100" => -- XORI
                res <= rd1 xor imm;
            --when "101" => -- SRLI / SRAI
            when "110" => -- ORI
                res <= rd1 or imm;
            when "111" => -- ANDI
                res <= rd1 and imm;
            when others =>
                res <= (others => '0');
            end case;

        -- Reuse of ALU Adder for memory address operations

        when "0000011" => -- I-Type (Load, res = address)
            res <= std_logic_vector(signed(rd1) + signed(imm));
        when "0100011" => -- S-Type (Store, res = address)
            res <= std_logic_vector(signed(rd1) + signed(imm));

        when "1100011" => -- B-Type (Branch, res = address)
            res <= std_logic_vector(signed(unsigned(pc)) + signed(imm));
        when "1101111" => -- J-Type (JAL, res = address)
            res <= std_logic_vector(signed(unsigned(pc)) + signed(imm));
        when "1100111" => -- I-Type (JALR, res = address)
            res <= std_logic_vector(signed(rd1) + signed(imm));

        when "0010111" => -- U-Type (AUIPC, res = imm)
            res <= std_logic_vector(signed(unsigned(pc)) + signed(imm));

        when others =>
            res <= (others => '0');
        end case;
    end process;

end Behavioral;