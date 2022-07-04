# PoliLEGv8
O PoliLEGv8 é uma implementação do processador descrito no livro texto da disciplina de SD2.

O processador é uma variação de um ARMv8 chamada de LEGv8, o Poli vem da nossa implementação dessa especificação. Nossa implementação é didática, sem pipeline.

## Processador
- [X] Memórias
- [X] Fluxo de Dados
    - [X] ULA 64b
    - [X] Banco de registradores
- Instruções (monociclo)
    * [X] B
    * [X] AND
    * [X] ADD
    * [X] ORR
    * [X] CBZ
    * [X] SUB
    * [X] STUR
    * [X] LDUR
- Instruções (completo, inclui as monociclo)
    * [X] B
    * [X] STURB
    * [X] LDURB
    * [X] B.cond
        * [X] B.EQ
        * [X] B.NE
        * [X] B.LT
        * [X] B.LE
        * [X] B.GT
        * [X] B.GE
        * [X] B.LO
        * [X] B.LS
        * [X] B.HI
        * [X] B.HS
        * [X] B.MI
        * [X] B.PL
        * [X] B.VS
        * [X] B.VC
    * [X] STURH
    * [X] LDURH
    * [X] AND
    * [X] ADD
    * [X] ADDI
    * [X] ANDI
    * [X] BL
    * [X] SDIV
    * [X] UDIV
    * [X] MUL
    * [X] SMULH
    * [X] UMULH
    * [X] ORR
    * [X] ADDS
    * [X] ADDIS
    * [X] ORRI
    * [X] CBZ
    * [X] CBNZ
    * [X] STURW
    * [X] LDURSW
    * [X] STURS
    * [X] LDURS
    * [X] STXR
    * [X] LDXR
    * [X] EOR
    * [X] SUB
    * [X] SUBI
    * [X] EORI
    * [X] MOVZ
    * [X] LSR
    * [X] LSL
    * [X] BR
    * [X] ANDS
    * [X] SUBS
    * [X] SUBIS
    * [X] ANDIS
    * [X] MOVK
    * [X] STUR
    * [X] LDUR
    * [X] STURD
    * [X] LDURD
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
