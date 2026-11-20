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
        
        -- Programa de testes
        
        -- 0: lw $1, 160($0)
        mem(0)  <= x"8C0100A0";
        
        -- 1: lw $2, 164($0)
        mem(1)  <= x"8C0200A4";
        
        -- 2: add $3, $1, $2
        mem(2)  <= x"00221800";
        
        -- 3: and $4, $1, $2
        mem(3)  <= x"04222000";
        
        -- 4: sw $3, 168($0)
        mem(4)  <= x"AC0300A8";
        
        -- 5: lwx $5, $4($1)
        mem(5)  <= x"40242800";
        
        -- 6: cmovz $6, $5, $2 (condição falsa)
        mem(6)  <= x"44A23000";
        
        -- 7: cmovz $7, $3, $0 (condição verdadeira)
        mem(7)  <= x"44603800";
        
        -- 8: beq $1, $2, 1 (não tomado)
        mem(8)  <= x"10220001";
        
        -- 9: add $8, $1, $1
        mem(9)  <= x"00214000";
        
        -- 10: beq $3, $3, 1 (tomado)
        mem(10) <= x"10630001";
        
        -- 11: add $9, $1, $2 (deve ser ignorado)
        mem(11) <= x"00224800";
        
        -- 12: j 14
        mem(12) <= x"0800000E";
        
        -- 13: add $10, $1, $1 (deve ser ignorado)
        mem(13) <= x"00215000";
        
        -- 14: j 14 (loop)
        mem(14) <= x"0800000E";
        
        
        -- Dados de teste
        -- Endereço 160 (posição 40)
        mem(40) <= x"000000A8";
        
        -- Endereço 164 (posição 41)
        mem(41) <= x"0000000C";
        
        -- Endereço 176 (posição 44): dado para lwx
        mem(44) <= x"DEADBEEF";
        

        elsif rising_edge(clk) then

            if MemWrite = '1' then
                mem(word_addr) <= WriteData;
            end if;

        end if;
    end process;

end rtl;
