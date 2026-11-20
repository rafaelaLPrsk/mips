----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Amanda Thum
-- 
-- Create Date: 20.11.2026 10:48:55
-- Design Name: 
-- Module Name: banco_registradores - Behavioral
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

entity Reg_File is
    port(
        clk      : in  std_logic;
        rst      : in  std_logic;
        RegWrite : in  std_logic;
        R_Reg1   : in  std_logic_vector(4 downto 0);
        R_Reg2   : in  std_logic_vector(4 downto 0);
        W_Reg3   : in  std_logic_vector(4 downto 0);
        WD       : in  std_logic_vector(31 downto 0);
        RD1      : out std_logic_vector(31 downto 0);
        RD2      : out std_logic_vector(31 downto 0)
    );
end Reg_File;

architecture rtl of Reg_File is

    type reg_array is array (0 to 31)
        of std_logic_vector(31 downto 0);

    signal registradores : reg_array :=
        (others => (others => '0'));

begin

    -- Leitura combinacional
    RD1 <= (others => '0')
        when unsigned(R_Reg1) = 0
        else registradores(to_integer(unsigned(R_Reg1)));

    RD2 <= (others => '0')
        when unsigned(R_Reg2) = 0
        else registradores(to_integer(unsigned(R_Reg2)));

    -- Escrita sincronizada pelo clock
    process(clk, rst)
    begin
        if rst = '1' then
            registradores <= (others => (others => '0'));

        elsif rising_edge(clk) then
            if RegWrite = '1' and unsigned(W_Reg3) /= 0 then
                registradores(to_integer(unsigned(W_Reg3))) <= WD;
            end if;
        end if;
    end process;

end rtl;

-- removi conversões desnecessárias para inteiro nas comparações com zero