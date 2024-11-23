--------------------------------
--                            --
--         RISC-V CPU         --
--        Single Cycle        --
--                            --
--       by Jan Ziegler       --
--                            --
--------------------------------

--------------------------------
--     Instruction Decoder    --
--------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ins_decode is
    Port (
        instruction : in STD_LOGIC_VECTOR (31 downto 0);

        -- Stage 2: Decode / Register Read
        rs1 : out STD_LOGIC_VECTOR (4 downto 0) := (others => '0');
        rs2 : out STD_LOGIC_VECTOR (4 downto 0) := (others => '0');

        -- Stage 3: Execute
        imm : out STD_LOGIC_VECTOR (31 downto 0) := (others => '0');

        -- Operand Selection
        op_sel : out STD_LOGIC_VECTOR (1 downto 0) := (others => '0');

        -- Operation Selection (ALU Mux)
        alu_op : out STD_LOGIC_VECTOR (1 downto 0) := (others => '0');
        -- 00 : Adder (ADD, SUB, NOP, NOP)
        -- 01 : Shift (SLL, NOP, SRL, SRA)
        -- 10 : Logic (AND, OR, XOR, LUI)
        -- 11 : Compare (SLT, SLTU, NOP, NOP)

        -- Additional mode bits for ALU.
        alu_mode : out STD_LOGIC_VECTOR (1 downto 0) := (others => '0');

        -- Branch Control Signals
        bra_sel : out STD_LOGIC_VECTOR (2 downto 0) := (others => '0');
        -- 000 : None
        -- 001 : JAL / JALR Same except for how the pc is calculated in the ALU.
        -- 010 : BEQ
        -- 011 : BNE
        -- 100 : BLT
        -- 101 : BGE
        -- 110 : BLTU
        -- 111 : BGEU

        -- Stage 4: Memory Access

        -- Memory Control Signals
        mem_read : out STD_LOGIC := '0';
        mem_write : out STD_LOGIC := '0';
        mem_size : out STD_LOGIC_VECTOR (1 downto 0) := (others => '0');
        mem_signed : out STD_LOGIC := '0';

        -- Stage 5: Write Back
        wb_sel : out STD_LOGIC_VECTOR (1 downto 0) := (others => '0');
        -- 00: None
        -- 01: ALU
        -- 10: PC+4
        -- 11: RAM

        wb_write : out STD_LOGIC := '0';
        rd : out STD_LOGIC_VECTOR (4 downto 0) := (others => '0')
    );
end ins_decode;

architecture Behavioral of ins_decode is
    signal opcode : std_logic_vector(6 downto 0) := (others => '0');
    signal funct3 : std_logic_vector(2 downto 0) := (others => '0');
    signal funct7 : std_logic_vector(6 downto 0) := (others => '0');
begin
    -- Stage 2: Decode / Register Read

    -- Simple Instruction Decoder
    opcode <= instruction(6 downto 0);
    funct3 <= instruction(14 downto 12);
    funct7 <= instruction(31 downto 25);

    rs1 <= instruction(19 downto 15);
    rs2 <= instruction(24 downto 20);
    rd <= instruction(11 downto 7);

    -- Immediate Decoder + Sign Extension
    process(all)
    begin
        case (opcode) is
        when "0110011" => -- R-Type (ALU)
            imm <= (others => '0');
        when "0010011" => -- I-Type (ALU)
            imm <= (31 downto 11 => instruction(31),
                    10 downto 0 => instruction(30 downto 20));
        when "0000011" => -- I-Type (Load)
            imm <= (31 downto 11 => instruction(31),
                    10 downto 0 => instruction(30 downto 20));
        when "0100011" => -- S-Type (Store)
            imm <= (31 downto 11 => instruction(31),
                    10 downto 5 => instruction(30 downto 25),
                    4 downto 0 => instruction(11 downto 7));
        when "1100011" => -- B-Type (Branch)
            imm <= (31 downto 12 => instruction(31),
                    11 downto 11 => instruction(7),
                    10 downto 5 => instruction(30 downto 25),
                    4 downto 1 => instruction(11 downto 8),
                    0 downto 0 => '0');
        when "1101111" => -- J-Type (JAL)
            imm <= (31 downto 20 => instruction(31),
                    19 downto 12 => instruction(19 downto 12),
                    11 downto 11 => instruction(20),
                    10 downto 1 => instruction(30 downto 21),
                    0 downto 0 => '0');
        when "1100111" => -- I-Type (JALR)
            imm <= (31 downto 11 => instruction(31),
                    10 downto 0 => instruction(30 downto 20));
        when "0110111" => -- U-Type (LUI)
            imm <= (31 downto 12 => instruction(31 downto 12),
                    11 downto 0 => '0');
        when "0010111" => -- U-Type (AUIPC)
            imm <= (31 downto 12 => instruction(31 downto 12),
                    11 downto 0 => '0');
        when "1110011" => -- I-Type (ECALL / EBREAK)
            imm <= (31 downto 11 => instruction(31),
                    10 downto 0 => instruction(30 downto 20));

        when others =>
            imm <= (others => '0');
        end case;
    end process;

    -- Stage 3: Execute

    -- ALU Operation Selection Signal Generation
    process(all)
    begin
        case (opcode) is
        when "0110011" => -- R-type (res = rd1 ? rd2)
            op_sel <= "00"; -- rd1 ? rd2
        when "0010011" => -- I-type (res = rd1 ? imm)
            op_sel <= "01"; -- rd1 ? imm
        when "0000011" => -- I-Type (Load, res = rd1 + imm)
            op_sel <= "01"; -- rd1 ? imm
        when "0100011" => -- S-Type (Store, res = rd1 + imm)
            op_sel <= "01"; -- rd1 ? imm
        when "1100011" => -- B-Type (Branch, res = pc + imm)
            op_sel <= "11"; -- pc ? imm
        when "1101111" => -- J-Type (JAL, res = pc + imm)
            op_sel <= "11"; -- pc ? imm
        when "1100111" => -- I-Type (JALR, res = rd1 + imm)
            op_sel <= "01"; -- rd1 ? imm
        when "0110111" => -- U-Type (LUI, res = imm)
            op_sel <= "01"; -- rd1 ? imm
        when "0010111" => -- U-Type (AUIPC, res = pc + imm)
            op_sel <= "11"; -- pc ? imm

        when others =>
            op_sel <= "00";
        end case;
    end process;

    -- ALU Operation Selection Signal Generation
    process(all)
    begin
        case (opcode) is
        when "0110011" | "0010011" => -- R-type | I-type -> res = op1 ? op2
            case (funct3) is
            when "000" => -- ADD / SUB
                case (funct7) is
                when "0000000" => -- ADD
                    alu_op <= "00"; -- Adder
                    alu_mode <= "00"; -- ADD
                when "0100000" => -- SUB
                    alu_op <= "00"; -- Adder
                    alu_mode <= "01"; -- SUB

                when others => -- TODO: Exception
                    alu_op <= "00";
                    alu_mode <= "00";
                end case;
            when "001" => -- SLL
                alu_op <= "01"; -- Shift
                alu_mode <= "00"; -- SLL
            when "010" => -- SLT
                alu_op <= "11"; -- Compare
                alu_mode <= "00"; -- SLT
            when "011" => -- SLTU
                alu_op <= "11"; -- Compare
                alu_mode <= "01"; -- SLTU
            when "100" => -- XOR
                alu_op <= "10"; -- Logic
                alu_mode <= "00"; -- XOR
            when "101" => -- SRL / SRA
                case (funct7) is
                when "0000000" => -- SRL
                    alu_op <= "01"; -- Shift
                    alu_mode <= "10"; -- SRL
                when "0100000" => -- SRA
                    alu_op <= "01"; -- Shift
                    alu_mode <= "11"; -- SRA

                when others => -- TODO: Exception
                    alu_op <= "00";
                    alu_mode <= "00";
                end case;
            when "110" => -- OR
                alu_op <= "10"; -- Logic
                alu_mode <= "01"; -- OR
            when "111" => -- AND
                alu_op <= "10"; -- Logic
                alu_mode <= "10"; -- AND

            when others => -- TODO: Exception
                alu_op <= "00";
                alu_mode <= "00";
            end case;

        when "0000011" | "0100011" | "1100111" | "1100011" | "1101111" => -- I-Type (Load) S-Type (Store) | I-Type (JALR) | B-Type (Branch) | J-Type (JAL) -> res = op1 + op2
            alu_op <= "00"; -- Adder
            alu_mode <= "00"; -- ADD

        when "0110111" => -- U-Type (LUI, res = imm)
            alu_op <= "10"; -- Logic
            alu_mode <= "11"; -- Pass Through op2

        when others => -- TODO: Exception
            alu_op <= "00";
            alu_mode <= "00";
        end case;
    end process;

    -- Branch Control Signal Generation
    process(all)
    begin
        case (opcode) is
        when "1100011" => -- B-Type (Branch)
            case (funct3) is
            when "000" => -- BEQ
                bra_sel <= "010"; -- BEQ
            when "001" => -- BNE
                bra_sel <= "011"; -- BNE
            when "100" => -- BLT
                bra_sel <= "100"; -- BLT
            when "101" => -- BGE
                bra_sel <= "101"; -- BGE
            when "110" => -- BLTU
                bra_sel <= "110"; -- BLTU
            when "111" => -- BGEU
                bra_sel <= "111"; -- BGEU

            when others => -- TODO: Exception
                bra_sel <= "000";
            end case;
        when "1101111" => -- J-Type (JAL)
            bra_sel <= "001"; -- JAL
        when "1100111" => -- I-Type (JALR)
            bra_sel <= "001"; -- JALR

        when others => -- TODO: Exception
            bra_sel <= "000";
        end case;
    end process;

    -- Stage 4: Memory Access

    -- Memory Control Signal Generation
    process(all)
    begin
        case (opcode) is
        when "0000011" => -- I-Type (Load)
            mem_read <= '1';
            mem_write <= '0';

            case (funct3) is
            when "000" => -- LB
                mem_size <= "00"; -- Byte
                mem_signed <= '1'; -- Signed
            when "001" => -- LH
                mem_size <= "01"; -- Halfword
                mem_signed <= '1'; -- Signed
            when "010" => -- LW
                mem_size <= "10"; -- Word
                mem_signed <= '1'; -- Signed
            when "100" => -- LBU
                mem_size <= "00"; -- Byte
                mem_signed <= '0'; -- Unsigned
            when "101" => -- LHU
                mem_size <= "01"; -- Halfword
                mem_signed <= '0'; -- Unsigned

            when others => -- TODO: Exception
                mem_size <= "00";
                mem_signed <= '0';
            end case;

        when "0100011" => -- S-Type (Store)
            mem_read <= '0';
            mem_write <= '1';

            case (funct3) is
            when "000" => -- SB
                mem_size <= "00"; -- Byte
            when "001" => -- SH
                mem_size <= "01"; -- Halfword
            when "010" => -- SW
                mem_size <= "10"; -- Word

            when others => -- TODO: Exception
                mem_size <= "00";
            end case;

            mem_signed <= '0';

        when others => -- TODO: Exception
            mem_read <= '0';
            mem_write <= '0';

            mem_size <= "00";
            mem_signed <= '0';
        end case;
    end process;

    -- Stage 5: Write Back

    -- Write Back Control Signal Generation
    process(all)
    begin
        case (opcode) is
        when "0110011" => -- R-Type (ALU)
            wb_sel <= "01"; -- ALU
            wb_write <= '1';
        when "0010011" => -- I-Type (ALU)
            wb_sel <= "01"; -- ALU
            wb_write <= '1';
        when "0000011" => -- I-Type (Load)
            wb_sel <= "11"; -- RAM
            wb_write <= '1';
        when "1101111" => -- J-Type (JAL)
            wb_sel <= "10"; -- PC+4
            wb_write <= '1';
        when "1100111" => -- I-Type (JALR)
            wb_sel <= "10"; -- PC+4
            wb_write <= '1';
        when "0110111" => -- U-Type (LUI)
            wb_sel <= "01"; -- ALU
            wb_write <= '1';
        when "0010111" => -- U-Type (AUIPC)
            wb_sel <= "01"; -- ALU
            wb_write <= '1';

        when others =>
            wb_sel <= "00"; -- None
            wb_write <= '0';
        end case;
    end process;
end Behavioral;