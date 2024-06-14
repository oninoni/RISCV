-- Jan Ziegler

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity alu is
    Port (
        opcode : in STD_LOGIC_VECTOR (6 downto 0);
        funct3 : in STD_LOGIC_VECTOR (2 downto 0);
        funct7 : in STD_LOGIC_VECTOR (6 downto 0);

        pc : in STD_LOGIC_VECTOR (31 downto 0);
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
            when "001" => -- SLL
                res <= rd1 sll to_integer(unsigned(rd2(4 downto 0)));
            when "010" => -- SLT
                if (signed(rd1) < signed(rd2)) then
                    res <= X"00000001";
                else
                    res <= (others => '0');
                end if;
            when "011" => -- SLTU
                if (unsigned(rd1) < unsigned(rd2)) then
                    res <= X"00000001";
                else
                    res <= (others => '0');
                end if;
            when "100" => -- XOR
                res <= rd1 xor rd2;
            when "101" => -- SRL / SRA
                case (funct7) is
                when "0000000" => -- SRL
                    res <= rd1 srl to_integer(unsigned(rd2(4 downto 0)));
                when "0100000" => -- SRA
                    --res <= rd1 sra to_integer(unsigned(rd2(4 downto 0)));
                    res <= (others => '0');
                when others =>
                    res <= (others => '0');
                end case;
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
            when "001" => -- SLLI
                res <= rd1 sll to_integer(unsigned(imm(4 downto 0)));
            when "010" => -- SLTI
                if (signed(rd1) < signed(imm)) then
                    res <= X"00000001";
                else
                    res <= (others => '0');
                end if;
            when "011" => -- SLTIU
                if (unsigned(rd1) < unsigned(imm)) then
                    res <= X"00000001";
                else
                    res <= (others => '0');
                end if;
            when "100" => -- XORI
                res <= rd1 xor imm;
            when "101" => -- SRLI / SRAI
                case (funct7) is
                when "0000000" => -- SRLI
                    res <= rd1 srl to_integer(unsigned(imm(4 downto 0)));
                when "0100000" => -- SRAI
                    --res <= rd1 sra to_integer(unsigned(imm(4 downto 0)));
                    res <= (others => '0');
                when others =>
                    res <= (others => '0');
                end case;
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