----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 20.11.2026 11:10:00
-- Design Name: 
-- Module Name: datapath - Behavioral
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

entity data_path is
    port(
        clk              : in  std_logic;
        rst              : in  std_logic;
        
        -- Sinais de Controle vindos da Unidade de Controle (FSM)
        PcWriteCondition : in  std_logic;                     -- Branch
        PcEnable         : in  std_logic;                     -- Escrita incondicional no PC
        IorD             : in  std_logic;                     -- 0: PC, 1: ULA_Out
        MemRead          : in  std_logic;
        MemWrite         : in  std_logic;
        IRWrite          : in  std_logic;
        MemToReg         : in  std_logic;                     -- 0: ULA_Out, 1: MDR
        PCSource         : in  std_logic_vector(1 downto 0);  -- 00: ULA_Result, 01: ULA_Out, 10: Jump
        ALUOp            : in  std_logic_vector(2 downto 0);  -- Operação da ULA
        ALUSrcB          : in  std_logic_vector(1 downto 0);  -- 00: B, 01: 4, 10: SignExt, 11: ShiftLeft2
        ALUSrcA          : in  std_logic;                     -- 0: PC, 1: Reg A
        RegWrite         : in  std_logic;
        RegDst           : in  std_logic;                     -- 0: rt [20-16], 1: rd [15-11]
        
        -- Saídas de Status para a Unidade de Controle (FSM)
        Opcode           : out std_logic_vector(5 downto 0);  -- Instruction [31-26]
        Zero_Flag        : out std_logic;                      -- Flag Zero da ULA (para cmovz em S13)
        Debug_Regs       : out std_logic_vector(1023 downto 0)
    );
end data_path;

architecture rtl of data_path is

    -- 1. DECLARAÇÃO DOS SUBCOMPONENTES (Etapas 1, 2 e 3)
    component Mem is
        port(
            clk       : in  std_logic;
            rst       : in  std_logic;
            MemRead   : in  std_logic;
            MemWrite  : in  std_logic;
            End_in    : in  std_logic_vector(31 downto 0);
            WriteData : in  std_logic_vector(31 downto 0);
            MemData   : out std_logic_vector(31 downto 0)
        );
    end component;

    component Reg_File is
        port(
            clk      : in  std_logic;
            rst      : in  std_logic;
            RegWrite : in  std_logic;
            R_Reg1   : in  std_logic_vector(4 downto 0);
            R_Reg2   : in  std_logic_vector(4 downto 0);
            W_Reg3   : in  std_logic_vector(4 downto 0);
            WD       : in  std_logic_vector(31 downto 0);
            RD1      : out std_logic_vector(31 downto 0);
            RD2      : out std_logic_vector(31 downto 0);
            Debug_Regs : out std_logic_vector(1023 downto 0) -- outra coisa pro debug
        );
    end component;

    component ULA is
        port(
            Op_A       : in  std_logic_vector(31 downto 0);
            Op_B       : in  std_logic_vector(31 downto 0);
            ALUOp      : in  std_logic_vector(2 downto 0);
            ULA_Result : out std_logic_vector(31 downto 0);
            Zero       : out std_logic
        );
    end component;

    -- 2. REGISTRADORES INTERNOS DO MULTICICLO
    signal PC      : std_logic_vector(31 downto 0) := (others => '0');
    signal IR      : std_logic_vector(31 downto 0) := (others => '0');
    signal MDR     : std_logic_vector(31 downto 0) := (others => '0');
    signal Reg_A   : std_logic_vector(31 downto 0) := (others => '0');
    signal Reg_B   : std_logic_vector(31 downto 0) := (others => '0');
    signal ULA_Out : std_logic_vector(31 downto 0) := (others => '0');

    -- 3. FIOS (BARRAMENTOS) DE CONEXÃO E SAÍDAS DOS MUXES
    signal pc_write_en    : std_logic;
    signal mux_pcsource_o : std_logic_vector(31 downto 0);
    signal mux_end_o      : std_logic_vector(31 downto 0);
    signal mem_data_o     : std_logic_vector(31 downto 0);
    signal mux_regdst_o   : std_logic_vector(4 downto 0);
    signal mux_memtoreg_o : std_logic_vector(31 downto 0);
    signal rd1_o          : std_logic_vector(31 downto 0);
    signal rd2_o          : std_logic_vector(31 downto 0);
    signal sign_ext_o     : std_logic_vector(31 downto 0);
    signal shift_left_br  : std_logic_vector(31 downto 0);
    signal jump_address   : std_logic_vector(31 downto 0);
    signal mux_alusrca_o  : std_logic_vector(31 downto 0);
    signal mux_b_o        : std_logic_vector(31 downto 0);
    signal ula_result_o   : std_logic_vector(31 downto 0);
    signal ula_zero_o     : std_logic;

begin

    ----------------------------------------------------------------------------
    -- LÓGICA DE CONTROLE DO PC (Portas AND e OR do diagrama)
    ----------------------------------------------------------------------------
    pc_write_en <= PcEnable or (PcWriteCondition and ula_zero_o);

    -- Envia Opcode e Flag Zero para a Unidade de Controle
    Opcode    <= IR(31 downto 26);
    Zero_Flag <= ula_zero_o;

    ----------------------------------------------------------------------------
    -- EXTENSÃO DE SINAL E DESLOCADORES (SHIFT LEFT 2)
    ----------------------------------------------------------------------------
    -- Sign Extend: estende o bit de sinal IR(15) de 16 para 32 bits
    sign_ext_o <= std_logic_vector(resize(signed(IR(15 downto 0)), 32));

    -- Shift Left 2 (Inferior - Branch): multiplica o offset estendido por 4
    shift_left_br <= sign_ext_o(29 downto 0) & "00";

    -- Shift Left 2 (Superior - Jump): concatena PC[31-28] com IR[25-0] << 2
    jump_address <= PC(31 downto 28) & IR(25 downto 0) & "00";

    ----------------------------------------------------------------------------
    -- MULTIPLEXADORES DO CAMINHO DE DADOS
    ----------------------------------------------------------------------------
    -- Mux_End (IorD): 0 = PC, 1 = ULA_Out
    mux_end_o <= PC when IorD = '0' else ULA_Out;

    -- MUX RegDst: 0 = rt [20-16], 1 = rd [15-11]
    mux_regdst_o <= IR(20 downto 16) when RegDst = '0' else IR(15 downto 11);

    -- MUX MemToReg: 0 = ULA_Out, 1 = Memory Data Register (MDR)
    mux_memtoreg_o <= ULA_Out when MemToReg = '0' else MDR;

    -- MUX ALUSrcA: 0 = PC, 1 = Registrador A
    mux_alusrca_o <= PC when ALUSrcA = '0' else Reg_A;

    -- Mux_B (ALUSrcB): 00 = Reg_B, 01 = 4, 10 = Sign Extend, 11 = Shift Left 2
    with ALUSrcB select
        mux_b_o <= Reg_B          when "00",
                   x"00000004"    when "01",
                   sign_ext_o     when "10",
                   shift_left_br  when "11",
                   (others => '0') when others;

    -- Mux_PCSource: 00 = ULA_Result (PC+4), 01 = ULA_Out (Branch), 10 = Jump Address
    with PCSource select
        mux_pcsource_o <= ula_result_o when "00",
                          ULA_Out      when "01",
                          jump_address when "10",
                          (others => '0') when others;

    ----------------------------------------------------------------------------
    -- INSTANCIAÇÃO DOS COMPONENTES (Memória, Registradores e ULA)
    ----------------------------------------------------------------------------
    Inst_Memory: Mem
        port map(
            clk       => clk,
            rst       => rst,
            MemRead   => MemRead,
            MemWrite  => MemWrite,
            End_in    => mux_end_o,
            WriteData => Reg_B,
            MemData   => mem_data_o
        );

    Inst_Registradores: Reg_File
        port map(
            clk      => clk,
            rst      => rst,
            RegWrite => RegWrite,
            R_Reg1   => IR(25 downto 21),
            R_Reg2   => IR(20 downto 16),
            W_Reg3   => mux_regdst_o,
            WD       => mux_memtoreg_o,
            RD1      => rd1_o,
            RD2      => rd2_o,
            Debug_Regs => Debug_Regs -- a saída do banco de registradores tá conectada diretamente à saída do datapath
        );

    Inst_ULA: ULA
        port map(
            Op_A       => mux_alusrca_o,
            Op_B       => mux_b_o,
            ALUOp      => ALUOp,
            ULA_Result => ula_result_o,
            Zero       => ula_zero_o
        );

    ----------------------------------------------------------------------------
    -- ATUALIZAÇÃO SÍNCRONA DOS REGISTRADORES INTERNOS (Borda de Subida do Clock)
    ----------------------------------------------------------------------------
    process(clk, rst)
    begin
        if rst = '1' then
            PC      <= (others => '0');
            IR      <= (others => '0');
            MDR     <= (others => '0');
            Reg_A   <= (others => '0');
            Reg_B   <= (others => '0');
            ULA_Out <= (others => '0');
        elsif rising_edge(clk) then
            -- PC só atualiza quando autorizado pela lógica (PcEnable ou Branch tomado)
            if pc_write_en = '1' then
                PC <= mux_pcsource_o;
            end if;

            -- IR só grava a instrução vinda da memória no estado S0 (IRWrite = '1')
            if IRWrite = '1' then
                IR <= mem_data_o;
            end if;

            -- Registradores temporários sem sinal de controle atualizam a cada ciclo
            MDR     <= mem_data_o;
            Reg_A   <= rd1_o;
            Reg_B   <= rd2_o;
            ULA_Out <= ula_result_o;
        end if;
    end process;

end rtl;