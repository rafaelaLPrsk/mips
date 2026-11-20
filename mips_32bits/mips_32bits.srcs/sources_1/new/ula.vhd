----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Amanda
-- 
-- Create Date: 20.11.2026 10:54:41
-- Design Name: 
-- Module Name: ula - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ULA is
    port(
        Op_A       : in  std_logic_vector(31 downto 0);
        Op_B       : in  std_logic_vector(31 downto 0);
        ALUOp      : in  std_logic_vector(2 downto 0);
        ULA_Result : out std_logic_vector(31 downto 0);
        Zero       : out std_logic
    );
end ULA;

architecture rtl of ULA is

    signal res_interno : std_logic_vector(31 downto 0);

begin

    -- Seleção combinacional da operação
    process(Op_A, Op_B, ALUOp)
    begin
        case ALUOp is

            when "000" => -- ADD
                res_interno <= std_logic_vector(
                    unsigned(Op_A) + unsigned(Op_B)
                );

            when "001" => -- SUB
                res_interno <= std_logic_vector(
                    unsigned(Op_A) - unsigned(Op_B)
                );

            when "010" => -- AND
                res_interno <= Op_A and Op_B;

            when "011" => -- PASSA B
                res_interno <= Op_B;


            when "100" => -- PASSA A
                res_interno <= Op_A; -- pass a e pass b deixam um valor passar pela ula sem mudar nada (cmovz)

            when others =>
                res_interno <= (others => '0');

        end case;
    end process;

    -- Saída do resultado
    ULA_Result <= res_interno;

    -- Flag Zero
    Zero <= '1' when res_interno = x"00000000" else '0';

end rtl;
