--------------------------------
--                            --
--         RISC-V CPU         --
--        Single Cycle        --
--                            --
--       by Jan Ziegler       --
--                            --
--------------------------------

--------------------------------
--    Seven Segment Display   --
--------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity seven_segment is
    Port (
        clk : in STD_LOGIC;
        res_n : in STD_LOGIC;
        data : in STD_LOGIC_VECTOR (31 downto 0);
        seg : out STD_LOGIC_VECTOR (6 downto 0) := (others => '0');
        an : out STD_LOGIC_VECTOR (7 downto 0) := (others => '0')
    );
end seven_segment;

architecture Behavioral of seven_segment is
    signal LED_BCD : STD_LOGIC_VECTOR(3 downto 0);

    signal counter : unsigned(2 downto 0) := "000";
begin
    -- Count through the 4 7-segment displays
    process(clk, res_n)
    begin
        if res_n = '0' then
            counter <= "000";
        elsif rising_edge(clk) then
            if counter = "111" then
                counter <= "000";
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;

    -- Control the anodes of the 4 7-segment displays and set the LED_BCD
    process(counter, data)
    begin
        case counter is
        when "000" =>
            an <= "11111110";
            LED_BCD <= data(3 downto 0);
        when "001" =>
            an <= "11111101";
            LED_BCD <= data(7 downto 4);
        when "010" =>
            an <= "11111011";
            LED_BCD <= data(11 downto 8);
        when "011" =>
            an <= "11110111";
            LED_BCD <= data(15 downto 12);
        when "100" =>
            an <= "11101111";
            LED_BCD <= data(19 downto 16);
        when "101" =>
            an <= "11011111";
            LED_BCD <= data(23 downto 20);
        when "110" =>
            an <= "10111111";
            LED_BCD <= data(27 downto 24);
        when "111" =>
            an <= "01111111";
            LED_BCD <= data(31 downto 28);

        when others =>
            an <= "11111111";
            LED_BCD <= "0000";
        end case;
    end process;

    -- Control a single 7-segment display
    process(LED_BCD)
    begin
        case LED_BCD is
        when "0000" => seg <= "1000000"; -- "0"
        when "0001" => seg <= "1111001"; -- "1"
        when "0010" => seg <= "0100100"; -- "2"
        when "0011" => seg <= "0110000"; -- "3"
        when "0100" => seg <= "0011001"; -- "4"
        when "0101" => seg <= "0010010"; -- "5"
        when "0110" => seg <= "0000010"; -- "6"
        when "0111" => seg <= "1111000"; -- "7"
        when "1000" => seg <= "0000000"; -- "8"
        when "1001" => seg <= "0010000"; -- "9"
        when "1010" => seg <= "0001000"; -- A
        when "1011" => seg <= "0000011"; -- B
        when "1100" => seg <= "1000110"; -- C
        when "1101" => seg <= "0100001"; -- D
        when "1110" => seg <= "0000110"; -- E
        when "1111" => seg <= "0001110"; -- F

        when others => seg <= "1111111"; -- Off
        end case;
    end process;
end Behavioral;
