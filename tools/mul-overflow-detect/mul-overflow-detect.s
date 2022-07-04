       MOVZ X12, 0xFFFF, LSL 0 
       MOVK X12, 0xFFFF, LSL 1 
       MOVZ X13, 0x03FE    
       MOVZ X14, 0x03FF
       LDURW X9, [XZR, #0]
       LDURW X10 [XZR, #8]
       UMULH X11, X9, X10
       ADDS XZR, X11, XZR
       B.Z no_ov
       STURW X12, [X13, #0] # should write -1 (FFFF sign extended to doubleword)
       B exit
no_ov: STURW XZR, [X13, #0]
exit:  STURW XZR, [X14, #0]
