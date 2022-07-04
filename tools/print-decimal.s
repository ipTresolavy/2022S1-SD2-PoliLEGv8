      LDUR X9, [XZR, #0]
      MOVZ X10, 10, LSL 0
      MOVZ X13, {endereco de IO de dados}, LSL 0
      MOVZ X14, {endereco de IO de termino}, LSL 0
loop: UDIV  X9, X10, X11
      MUL  X11, X10, X12
      SUB  X9, X12, X12
      STUR X12, [X13, #0]
      ORR  XZR, X11, X9
      CBNZ X9, loop
      STUR X10, [X14, #0]
