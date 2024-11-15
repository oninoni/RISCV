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
        data : in STD_LOGIC_VECTOR (15 downto 0);
        seg : out STD_LOGIC_VECTOR (6 downto 0);
        an : out STD_LOGIC_VECTOR (3 downto 0)
    );
end seven_segment;

architecture Behavioral of seven_segment is
    signal LED_BCD : STD_LOGIC_VECTOR(3 downto 0);

    signal counter : unsigned(1 downto 0) := "00";
begin
    -- Count through the 4 7-segment displays
    process(clk, res_n)
    begin
        if res_n = '0' then
            counter <= "00";
        elsif rising_edge(clk) then
            if counter = "11" then
                counter <= "00";
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;    

    -- Control the anodes of the 4 7-segment displays and set the LED_BCD
    process(counter)
    begin
        case counter is
        when "00" =>
            an <= "1110";
            LED_BCD <= data(3 downto 0);
        when "01" =>
            an <= "1101";
            LED_BCD <= data(7 downto 4);
        when "10" =>
            an <= "1011";
            LED_BCD <= data(11 downto 8);
        when "11" =>
            an <= "0111";
            LED_BCD <= data(15 downto 12);
        end case;
    end process;

    -- Control a single 7-segment display
    process(LED_BCD)
    begin
        case LED_BCD is
        when "0000" => seg <= "0000001"; -- "0"     
        when "0001" => seg <= "1001111"; -- "1" 
        when "0010" => seg <= "0010010"; -- "2" 
        when "0011" => seg <= "0000110"; -- "3" 
        when "0100" => seg <= "1001100"; -- "4" 
        when "0101" => seg <= "0100100"; -- "5" 
        when "0110" => seg <= "0100000"; -- "6" 
        when "0111" => seg <= "0001111"; -- "7" 
        when "1000" => seg <= "0000000"; -- "8"     
        when "1001" => seg <= "0000100"; -- "9" 
        when "1010" => seg <= "0000010"; -- a
        when "1011" => seg <= "1100000"; -- b
        when "1100" => seg <= "0110001"; -- C
        when "1101" => seg <= "1000010"; -- d
        when "1110" => seg <= "0110000"; -- E
        when "1111" => seg <= "0111000"; -- F
        end case;
    end process;
end Behavioral;
