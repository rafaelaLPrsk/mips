----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 20.11.2026 11:04:14
-- Design Name: 
-- Module Name: memoria - Behavioral
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

entity Mem is
    port(
        clk       : in  std_logic;
        rst       : in  std_logic;
        MemRead   : in  std_logic;
        MemWrite  : in  std_logic;
        End_in    : in  std_logic_vector(31 downto 0);
        WriteData : in  std_logic_vector(31 downto 0);
        MemData   : out std_logic_vector(31 downto 0)
    );
end Mem;

architecture rtl of Mem is

    subtype palavra is std_logic_vector(31 downto 0);

    type ram_type is array (0 to 255) of palavra;

    signal mem : ram_type := (others => (others => '0'));

    signal word_addr : integer range 0 to 255;

begin

    -- Conversão do endereço de byte para índice da memória
    word_addr <= to_integer(unsigned(End_in(9 downto 2)));

    -- Leitura combinacional
    MemData <= mem(word_addr) when MemRead = '1'
               else (others => '0');

    -- Escrita e inicialização da memória
    process(clk, rst)
    begin
        if rst = '1' then

            mem <= (others => (others => '0'));

            -- PROGRAMA DE TESTE

            mem(0)  <= x"8C010040"; -- lw $1, 64($0)
            mem(1)  <= x"8C020044"; -- lw $2, 68($0)
            mem(2)  <= x"00221800"; -- add $3, $1, $2
            mem(3)  <= x"04222000"; -- and $4, $1, $2
            mem(4)  <= x"AC030048"; -- sw $3, 72($0)
            mem(5)  <= x"40242800"; -- lwx $5, $4($1)
            mem(6)  <= x"44613000"; -- cmovz $6, $3, $1
            mem(7)  <= x"44603000"; -- cmovz $6, $3, $0
            mem(8)  <= x"10C30001"; -- beq $6, $3, 1
            mem(9)  <= x"00213800"; -- add $7, $1, $1
            mem(10) <= x"0800000A"; -- j 10

            -- DADOS INICIAIS

            mem(16) <= x"0000000C"; -- Endereço 64: valor 12
            mem(17) <= x"00000005"; -- Endereço 68: valor 5

        elsif rising_edge(clk) then

            if MemWrite = '1' then
                mem(word_addr) <= WriteData;
            end if;

        end if;
    end process;

end rtl;
