# PoliLEGv8
O PoliLEGv8 é uma implementação do processador descrito no livro texto da disciplina de SD2.

O processador é uma variação de um ARMv8 chamada de LEGv8, o Poli vem da nossa implementação dessa especificação. Nossa implementação é didática, sem pipeline.

## Processador
- [X] Memórias
- [ ] Fluxo de Dados
    - [X] ULA 64b
    - [X] Banco de registradores
- Instruções (monociclo)
    * [ ] B
    * [ ] AND
    * [ ] ADD
    * [ ] ORR
    * [ ] CBZ
    * [ ] SUB
    * [ ] STUR
    * [ ] LDUR
- Instruções (completo, inclui as monociclo)
    * [ ] B
    * [ ] STURB
    * [ ] LDURB
    * [ ] B.cond
        * [ ] B.EQ
        * [ ] B.NE
        * [ ] B.LT
        * [ ] B.LE
        * [ ] B.GT
        * [ ] B.GE
        * [ ] B.LO
        * [ ] B.LS
        * [ ] B.HI
        * [ ] B.HS
        * [ ] B.MI
        * [ ] B.PL
        * [ ] B.VS
        * [ ] B.VC
    * [ ] STURH
    * [ ] LDURH
    * [ ] AND
    * [ ] ADD
    * [ ] ADDI
    * [ ] ANDI
    * [ ] BL
    * [ ] SDIV
    * [ ] UDIV
    * [ ] MUL
    * [ ] SMULH
    * [ ] UMULH
    * [ ] ORR
    * [ ] ADDS
    * [ ] ADDIS
    * [ ] ORRI
    * [ ] CBZ
    * [ ] CBNZ
    * [ ] STURW
    * [ ] LDURSW
    * [ ] STURS
    * [ ] LDURS
    * [ ] STXR
    * [ ] LDXR
    * [ ] EOR
    * [ ] SUB
    * [ ] SUBI
    * [ ] EORI
    * [ ] MOVZ
    * [ ] LSR
    * [ ] LSL
    * [ ] BR
    * [ ] ANDS
    * [ ] SUBS
    * [ ] SUBIS
    * [ ] ANDIS
    * [ ] MOVK
    * [ ] STUR
    * [ ] LDUR
    * [ ] STURD
    * [ ] LDURD
- Instruções de ponto flutuante (opcional):
    * [ ] FMULS
    * [ ] FDIVS
    * [ ] FCMPS
    * [ ] FADDS
    * [ ] FSUBS
    * [ ] FMULD
    * [ ] FDIVD
    * [ ] FCMPD
    * [ ] FADDD
    * [ ] FSUBD
- Pseudo instruções (suportadas pelo _assembler_ mas não implementadas):
    * [ ] NOP
    * [ ] MOV
    * [ ] CMP
    * [ ] CMPI
    * [ ] LDA

## Implementação na placa (DE10-Lite)
- [ ] SDRAM da placa (64M)
- [ ] ROM da placa (módulos MK9, 1638Kb)
- [ ] Barramento (AXI-Lite v4)
- [ ] Serial (UART)
- [ ] Display (6 x 7-segmentos)
- [ ] Chaves (10x)
- [ ] Botões (2x)
- [ ] VGA (opcional)

## Software
- Montador (_assembler_)
    - [ ] Monociclo
    - [ ] Multiciclo
