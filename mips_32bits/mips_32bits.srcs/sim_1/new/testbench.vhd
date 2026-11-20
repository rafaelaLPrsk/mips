
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_TopLevel is
end TB_TopLevel;

architecture behavior of TB_TopLevel is

    -- Componente do processador
    component TopLevel is
        port(
            clk        : in std_logic;
            reset      : in std_logic;
            Debug_Regs : out std_logic_vector(1023 downto 0)
        );
    end component;

    -- Tipo que representa os 32 registradores
    type debug_array is array (0 to 31) of std_logic_vector(31 downto 0);

    -- Sinais
    signal clk        : std_logic := '0';
    signal reset      : std_logic := '0';
    signal Debug_Regs : std_logic_vector(1023 downto 0);
    signal Reg_Debug  : debug_array;

    constant clk_period : time := 10 ns;

begin

    -- Instancia o processador
    UUT: TopLevel
        port map(
            clk        => clk,
            reset      => reset,
            Debug_Regs => Debug_Regs
        );

    -- Separa os 32 registradores
    gen_debug: for i in 0 to 31 generate
        Reg_Debug(i) <= Debug_Regs((i+1)*32-1 downto i*32);
    end generate;

    -- Clock
    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for clk_period / 2;
            clk <= '1';
            wait for clk_period / 2;
        end loop;
    end process;

    -- Reset e execução
    stim_proc: process
    begin
        reset <= '1';
        wait for 25 ns;
        reset <= '0';

        wait for 550 ns;
        wait;
    end process;

end behavior;
