SETCP 0
DICTPUSHCONST 19, (xC_)
DICTIGETJMPZ {
  0 => <{
    SAVECTR c2
    SAMEALTSAVE
    DUP
    SEMPTY
    IFJMP:<{
      BLKDROP 4
    }>
    SWAP
    CTOS
    LDU 4
    SWAP
    PUSHINT 1
    AND
    EQINT 1
    IFJMP:<{
      BLKDROP 4
    }>
    XCPU s3, s2
    SUB
    SETGLOB 26
    XCHG s0, s2
    LDMSGADDR
    LDMSGADDR
    NIP
    LDGRAMS
    NIP
    SKIPDICT
    LDGRAMS
    NIP
    LDGRAMS
    SWAP
    PUSHINT 0
    GETORIGINALFWDFEE
    NIP
    CALLDICT 184
    XCHG s0, s3
    LDU 32
    SWAP
    SWAP
    LDU 64
    SWAP
    XCHG s1, s2
    OVER
    PUSHINT 3624791682
    EQUAL
    IFJMP:<{
      NIP
      POP s3
      POP s3
      GETGLOB 1
      THROWIF 1004
      GETGLOB 3
      SDEQ
      THROWIFNOT 1000
      SWAP
      LDREF
      DROP
      POP c4
      CALLDICT 184
      GETGLOB 8
      PUSHINT 50000
      LEQ
      THROWIFNOT 2000
      GETGLOB 9
      PUSHINT 15000
      LEQ
      THROWIFNOT 2001
      GETGLOB 10
      PUSHINT 100000
      LEQ
      THROWIFNOT 2002
      GETGLOB 11
      PUSHINT 30000
      LEQ
      THROWIFNOT 2003
      GETGLOB 12
      GETGLOB 13
      OVER
      GTINT 99
      PUSH s2
      PUSHINT 9900
      LEQ
      AND
      THROWIFNOT 2004
      DUP
      PUSHINT 2500
      GEQ
      OVER
      PUSHINT 9900
      LEQ
      AND
      THROWIFNOT 2004
      SWAP
      GREATER
      THROWIFNOT 2004
      GETGLOB 14
      PUSHINT 267
      DICTMIN
      NULLSWAPIFNOT2
      XCHG s1, s2
      WHILE:<{
      }>DO<{
        LDREFRTOS
        LDMSGADDR
        LDMSGADDR
        LDREF
        LDU 14
        SWAP
        SWAP
        LDU 14
        SWAP
        SWAP
        LDI 1
        SWAP
        SWAP
        LDI 1
        SWAP
        NIP
        TUPLE 7
        UNTUPLE 7
        XCHG s0, s7
        LDU 40
        SWAP
        SWAP
        LDGRAMS
        LDGRAMS
        LDGRAMS
        LDGRAMS
        LDGRAMS
        LDGRAMS
        LDGRAMS
        BLKSWAP 8, 1
        TUPLE 8
        UNTUPLE 8
        TUPLE 0
        XCHG2 s0, s8
        TPUSH
        XCHG2 s0, s6
        TPUSH
        XCHG2 s0, s4
        TPUSH
        ROT
        TPUSH
        SWAP
        TPUSH
        SWAP
        TPUSH
        SWAP
        TPUSH
        SWAP
        TPUSH
        XCHG2 s0, s7
        TPUSH
        XCHG2 s0, s5
        TPUSH
        XCHG2 s0, s3
        TPUSH
        SWAP
        TPUSH
        SWAP
        TPUSH
        SWAP
        TPUSH
        ROT
        TPUSH
        NIP
        DUP
        INDEX 9
        PLDU 2
        EQINT 0
        IF:<{
          DUP
          INDEX 10
          CTOS
          LDGRAMS
          NIP
          LDU 14
          SWAP
          SWAP
          LDU 14
          SWAP
          NIP
          PUSHINT 3000
          PUSH s2
          GTINT 99
          PUSH s3
          AND
          PUSHINT 9900
          LEQ
          THROWANYIFNOT
          PUSHINT 3000
          OVER
          GTINT 99
          PUSH s2
          AND
          PUSHINT 9900
          LEQ
          THROWANYIFNOT
          PUSHINT 3000
          XCHG s0, s2
          GEQ
          THROWANYIFNOT
        }>
        INDEX 8
        PLDU 2
        EQINT 0
        IF:<{
          2DUP
          CALLDICT 60
        }>
        GETGLOB 14
        SWAP
        SWAP
        PUSHINT 267
        DICTGETNEXT
        NULLSWAPIFNOT2
        XCHG s1, s2
      }>
      BLKDROP 3
    }>
    OVER
    PUSHINT 3513996288
    EQUAL
    IFJMP:<{
      2DROP
      BLKDROP2 2, 2
      GETGLOB 14
      PUSH s2
      CALL:<{
        SWAP
        PUSHINT 267
        DICTGET
        NULLSWAPIFNOT
        NOT
        IFJMP:<{
          DROP
          TUPLE 0
          PUSHINT 0
        }>
        LDREFRTOS
        LDMSGADDR
        LDMSGADDR
        LDREF
        LDU 14
        SWAP
        SWAP
        LDU 14
        SWAP
        SWAP
        LDI 1
        SWAP
        SWAP
        LDI 1
        SWAP
        NIP
        TUPLE 7
        UNTUPLE 7
        XCHG s0, s7
        LDU 40
        SWAP
        SWAP
        LDGRAMS
        LDGRAMS
        LDGRAMS
        LDGRAMS
        LDGRAMS
        LDGRAMS
        LDGRAMS
        BLKSWAP 8, 1
        TUPLE 8
        UNTUPLE 8
        TUPLE 0
        XCHG2 s0, s8
        TPUSH
        XCHG2 s0, s6
        TPUSH
        XCHG2 s0, s4
        TPUSH
        ROT
        TPUSH
        SWAP
        TPUSH
        SWAP
        TPUSH
        SWAP
        TPUSH
        SWAP
        TPUSH
        XCHG2 s0, s7
        TPUSH
        XCHG2 s0, s5
        TPUSH
        XCHG2 s0, s3
        TPUSH
        SWAP
        TPUSH
        SWAP
        TPUSH
        SWAP
        TPUSH
        ROT
        TPUSH
        NIP
        PUSHINT 1
      }>
      THROWIFNOT 1001
      SWAP
      LDMSGADDR
      DROP
      PUSHINT 8
      SETINDEXVAR
      GETGLOB 14
      ROTREV
      CALL:<{
        NEWC
        SWAP
        DUP
        INDEX 8
        OVER
        INDEX 9
        PUSH s2
        INDEX 10
        PUSH s3
        INDEX 11
        PUSH s4
        INDEX 12
        PUSH s5
        INDEX 13
        PUSH s6
        INDEX 14
        XCHG s7, s8
        NEWC
        XCHG2 s0, s7
        STSLICER
        XCHG2 s0, s5
        STSLICER
        XCHG s1, s3
        STREF
        SWAP
        SWAP
        STU 14
        SWAP
        SWAP
        STU 14
        SWAP
        SWAP
        STI 1
        SWAP
        SWAP
        STI 1
        ENDC
        SWAP
        STREF
        OVER
        INDEX 0
        PUSH s2
        INDEX 1
        PUSH s3
        INDEX 2
        PUSH s4
        INDEX 3
        PUSH s5
        INDEX 4
        PUSH s6
        INDEX 5
        PUSH s7
        INDEX 6
        XCHG s0, s8
        INDEX 7
        XCHG s7, s8
        XCHG s6, s7
        XCHG s5, s6
        XCHG s4, s5
        XCHG s3, s4
        XCHG3 s1, s3, s0
        XCHG2 s8, s7
        SWAP
        STU 40
        XCHG2 s0, s5
        STGRAMS
        XCHG2 s0, s3
        STGRAMS
        SWAP
        STGRAMS
        SWAP
        STGRAMS
        SWAP
        STGRAMS
        ROT
        STGRAMS
        SWAP
        STGRAMS
        XCHG s0, s2
        PUSHINT 267
        DICTSETB
      }>
      SETGLOB 14
      CALLDICT 185
    }>
    OVER
    PUSHINT 1935855772
    EQUAL
    IF:<{
      XCHG s0, s2
      LDGRAMS
      LDMSGADDR
      PUSH3 s0, s5, s4
      PUSH2 s5, s4
      PUSH c4
      PUSH c5
      PUSH c7
      CONT:<{
        NIP
        PUSHINT 0
        PUSHNULL
        2OVER
        NEQINT 9
        IF:<{
          BLKDROP 3
          PUSH s5
          PLDREFIDX 0
          CTOS
          LDMSGADDR
          LDU 32
          SWAP
          SWAP
          LDMSGADDR
          LDMSGADDR
          LDGRAMS
          LDDICT
          BLKSWAP 6, 1
          BLKDROP2 3, 3
          POP s3
          ROTREV
        }>
        PUSH s6
        XCPU s4, s5
        XCHG s4, s9
        PUXC2 s7, s3, s9
        SWAP
        CALLDICT 204
        NEWC
        ROT
        STGRAMS
        OVER
        STSLICER
        XCHG2 s0, s4
        STSLICER
        XCHG3 s3, s3, s0
        PUSHINT 1935855772
        ROTREV
        CALLDICT 202
        RETALT
      }>
      SETCONTCTR c7
      SETCONTCTR c5
      SETCONTCTR c4
      PUSHINT 5
      PUSHINT -1
      SETCONTVARARGS
      CONT:<{
        LDREFRTOS
        LDMSGADDR
        LDU 32
        SWAP
        SWAP
        LDMSGADDR
        LDMSGADDR
        LDGRAMS
        LDDICT
        BLKSWAP 6, 1
        PUSH s5
        REWRITESTDADDR
        DROP
        EQINT 0
        THROWIFNOT 333
        PUSH s2
        REWRITESTDADDR
        DROP
        EQINT 0
        THROWIFNOT 333
        GETGLOB 14
        PUSH s4
        CALL:<{
          SWAP
          PUSHINT 267
          DICTGET
          NULLSWAPIFNOT
          NOT
          IFJMP:<{
            DROP
            TUPLE 0
            PUSHINT 0
          }>
          LDREFRTOS
          LDMSGADDR
          LDMSGADDR
          LDREF
          LDU 14
          SWAP
          SWAP
          LDU 14
          SWAP
          SWAP
          LDI 1
          SWAP
          SWAP
          LDI 1
          SWAP
          NIP
          TUPLE 7
          UNTUPLE 7
          XCHG s0, s7
          LDU 40
          SWAP
          SWAP
          LDGRAMS
          LDGRAMS
          LDGRAMS
          LDGRAMS
          LDGRAMS
          LDGRAMS
          LDGRAMS
          BLKSWAP 8, 1
          TUPLE 8
          UNTUPLE 8
          TUPLE 0
          XCHG2 s0, s8
          TPUSH
          XCHG2 s0, s6
          TPUSH
          XCHG2 s0, s4
          TPUSH
          ROT
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          XCHG2 s0, s7
          TPUSH
          XCHG2 s0, s5
          TPUSH
          XCHG2 s0, s3
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          ROT
          TPUSH
          NIP
          PUSHINT 1
        }>
        THROWIFNOT 1001
        INDEX 8
        PUXC s13, s(-1)
        SDEQ
        THROWIFNOT 1002
        PUSHINT -1
        GETGLOB 6
        PLDU 2
        EQINT 0
        PUSH s6
        ROTREV
        PUSH s17
        PUSH s5
        PUSH s18
        PUSH s5
        PUSHINT 1207989464
        EQUAL
        IF:<{
          GETGLOB 16
          PUXC s3, s(-1)
          ADD
          GETGLOB 21
          ADD
          GETGLOB 22
          ADD
          PUSH s2
          ADD
          GETGLOB 24
          ADD
          PUXC s1, s(-1)
          GEQ
          THROWIFNOT 1017
        }>
        PUSH s5
        PUSHINT 3406020527
        EQUAL
        IF:<{
          PUSH s3
          NEQINT 0
          IF:<{
            PUSHINT 3
          }>ELSE<{
            PUSHINT 5
          }>
          PUXC s3, s(-1)
          MUL
          GETGLOB 17
          ADD
          GETGLOB 21
          ADD
          GETGLOB 22
          ADD
          PUSH s2
          ADD
          GETGLOB 24
          ADD
          XCHG s0, s5
          IF:<{
            GETGLOB 23
            XCHG s1, s5
            ADD
            XCHG s0, s4
          }>
          PUXC s0, s4
          GEQ
          THROWIFNOT 1017
        }>ELSE<{
          POP s4
        }>
        PUSH s4
        PUSHINT 3485616356
        EQUAL
        IF:<{
          PUSH s2
          NEQINT 0
          IF:<{
            PUSHINT 3
          }>ELSE<{
            PUSHINT 5
          }>
          PUXC s2, s(-1)
          MUL
          GETGLOB 18
          ADD
          GETGLOB 21
          ADD
          GETGLOB 22
          ADD
          OVER
          ADD
          GETGLOB 23
          ADD
          GETGLOB 24
          ADD
          PUXC s4, s(-1)
          GEQ
          THROWIFNOT 1017
        }>
        PUSH s4
        PUSHINT 3998571052
        EQUAL
        IF:<{
          OVER
          MULINT 3
          GETGLOB 19
          ADD
          GETGLOB 21
          ADD
          GETGLOB 22
          ADD
          OVER
          ADD
          GETGLOB 24
          ADD
          PUXC s4, s(-1)
          GEQ
          THROWIFNOT 1017
        }>
        XCHG s0, s4
        PUSHINT 3427973859
        EQUAL
        IF:<{
          SWAP
          NEQINT 0
          IF:<{
            PUSHINT 3
          }>ELSE<{
            PUSHINT 5
          }>
          MUL
          GETGLOB 20
          ADD
          GETGLOB 21
          LSHIFT 1
          ADD
          GETGLOB 22
          ADD
          ROT
          ADD
          GETGLOB 23
          ADD
          GETGLOB 24
          LSHIFT 1
          ADD
          PUSHINT 50000000
          ADD
          GEQ
          THROWIFNOT 1017
        }>ELSE<{
          BLKDROP 4
        }>
        PUSH s4
        PUSHINT 1207989464
        EQUAL
        IFJMP:<{
          2DROP
          POP s2
          POP s4
          POP s6
          POP s7
          POP s7
          POP s7
          XCHG s3, s6
          XCHG3 s1, s4, s5
          CALLDICT 212
          RETALT
        }>
        PUSH s4
        PUSHINT 3998571052
        EQUAL
        IFJMP:<{
          POP s7
          POP s9
          POP s10
          POP s10
          POP s10
          NEWC
          XCHG s0, s8
          NOW
          PUSH s2
          XCHG s0, s9
          XCHG s8, s12
          XCHG3 s5, s7, s11
          XCHG2 s3, s4
          XCHG3 s12, s12, s0
          NEWC
          XCHG2 s0, s6
          STSLICER
          ROT
          STGRAMS
          STDICT
          XCHG2 s0, s3
          STSLICER
          ENDC
          BLKSWAP 4, 4
          2SWAP
          STSLICER
          ROT
          SWAP
          STU 32
          SWAP
          SWAP
          STU 40
          XCHG3 s4, s4, s3
          2SWAP
          STSLICER
          ROT
          STSLICER
          SWAP
          STGRAMS
          STREF
          CALLDICT 188
          XCHG3 s3, s0, s0
          CALL:<{
            MYADDR
            GETGLOB 15
            XCHG3 s1, s4, s0
            XCHG s0, s2
            PUSHINT 0
            XCHG s0, s2
            PUSHNULL
            PUSHNULL
            NEWC
            XCHG2 s0, s4
            STSLICER
            ROT
            STSLICER
            XCHG s1, s2
            STDICT
            STDICT
            ENDC
            OVER
            NEWC
            STU 2
            XCHG s1, s3
            STDICT
            XCHG s1, s2
            STDICT
            STU 1
            ENDC
            HASHCU
            PUSHINT 0
            PUSHINT 4
            NEWC
            STU 3
            STI 8
            STU 256
            ENDC
            CTOS
            NEWC
            PUSHINT 736177463
            ROT
            XCHG s0, s5
            XCHG s0, s2
            STU 32
            STU 64
            STREF
            SWAP
            STBR
            PUSHINT 0
            SWAP
            ENDC
            CALLDICT 55
            PUSHINT 64
            SENDRAWMSG
          }>
          RETALT
        }>
        PUSH s4
        PUSHINT 3427973859
        EQUAL
        IFJMP:<{
          POP s7
          POP s9
          POP s10
          POP s10
          POP s10
          SWAP
          LDREF
          LDREFRTOS
          NIP
          DUP
          SBITS
          PUSHINT 267
          EQUAL
          THROWIFNOT 1023
          DUP
          PUSHINT 267
          PLDSLICEX
          GETGLOB 14
          OVER
          CALL:<{
            SWAP
            PUSHINT 267
            DICTGET
            NULLSWAPIFNOT
            NOT
            IFJMP:<{
              DROP
              TUPLE 0
              PUSHINT 0
            }>
            LDREFRTOS
            LDMSGADDR
            LDMSGADDR
            LDREF
            LDU 14
            SWAP
            SWAP
            LDU 14
            SWAP
            SWAP
            LDI 1
            SWAP
            SWAP
            LDI 1
            SWAP
            NIP
            TUPLE 7
            UNTUPLE 7
            XCHG s0, s7
            LDU 40
            SWAP
            SWAP
            LDGRAMS
            LDGRAMS
            LDGRAMS
            LDGRAMS
            LDGRAMS
            LDGRAMS
            LDGRAMS
            BLKSWAP 8, 1
            TUPLE 8
            UNTUPLE 8
            TUPLE 0
            XCHG2 s0, s8
            TPUSH
            XCHG2 s0, s6
            TPUSH
            XCHG2 s0, s4
            TPUSH
            ROT
            TPUSH
            SWAP
            TPUSH
            SWAP
            TPUSH
            SWAP
            TPUSH
            SWAP
            TPUSH
            XCHG2 s0, s7
            TPUSH
            XCHG2 s0, s5
            TPUSH
            XCHG2 s0, s3
            TPUSH
            SWAP
            TPUSH
            SWAP
            TPUSH
            SWAP
            TPUSH
            ROT
            TPUSH
            NIP
            PUSHINT 1
          }>
          NIP
          THROWIFNOT 1001
          PUSH s10
          SDEQ
          THROWIF 1019
          NEWC
          XCHG s0, s8
          NOW
          PUSH s4
          XCHG s0, s9
          XCHG s8, s13
          XCHG s1, s7
          XCHG s1, s6
          XCHG s5, s11
          XCHG s4, s12
          XCHG s3, s13
          XCHG3 s0, s1, s13
          NEWC
          XCHG2 s0, s6
          STSLICER
          ROT
          STGRAMS
          STDICT
          XCHG2 s0, s3
          STSLICER
          ENDC
          BLKSWAP 4, 4
          2SWAP
          STSLICER
          ROT
          SWAP
          STU 32
          SWAP
          SWAP
          STU 40
          XCHG3 s4, s4, s3
          2SWAP
          STSLICER
          ROT
          STSLICER
          SWAP
          STGRAMS
          STREF
          GETGLOB 6
          PLDU 2
          EQINT 0
          IFJMP:<{
            GETGLOB 7
            XCHG2 s0, s3
            CALLDICT 115
            NEWC
            STREF
            ROT
            STBR
            CALLDICT 188
            SWAP
            CALL:<{
              MYADDR
              GETGLOB 15
              XCHG3 s1, s4, s0
              XCHG s0, s2
              PUSHINT 0
              XCHG s0, s2
              PUSHNULL
              PUSHNULL
              NEWC
              XCHG2 s0, s4
              STSLICER
              ROT
              STSLICER
              XCHG s1, s2
              STDICT
              STDICT
              ENDC
              OVER
              NEWC
              STU 2
              XCHG s1, s3
              STDICT
              XCHG s1, s2
              STDICT
              STU 1
              ENDC
              HASHCU
              PUSHINT 0
              PUSHINT 4
              NEWC
              STU 3
              STI 8
              STU 256
              ENDC
              CTOS
              NEWC
              PUSHINT 736177463
              ROT
              XCHG s0, s5
              XCHG s0, s2
              STU 32
              STU 64
              STREF
              SWAP
              STBR
              PUSHINT 0
              SWAP
              ENDC
              CALLDICT 55
              PUSHINT 64
              SENDRAWMSG
            }>
            RETALT
          }>
          NIP
          CALLDICT 197
          RETALT
        }>
        XCHG s7, s9
        BLKDROP 9
        PUSHPOW2DEC 16
        THROWANY
      }>
      PUSH c1
      BOOLOR
      SWAP
      TRY
      XCHG s0, s2
    }>
    OVER
    PUSHINT 3406020527
    EQUAL
    PUSH s2
    PUSHINT 3485616356
    EQUAL
    OR
    IFJMP:<{
      XCHG s0, s2
      LDDICT
      PUSH3 s0, s4, s2
      PUSH s6
      PUSH c4
      PUSH c5
      PUSH c7
      CONT:<{
        NIP
        XCHG2 s0, s4
        CALLDICT 201
        RETALT
      }>
      SETCONTCTR c7
      SETCONTCTR c5
      SETCONTCTR c4
      PUSHINT 4
      PUSHINT -1
      SETCONTVARARGS
      CONT:<{
        DUP
        DUP
        SBITS
        PUXC s1, s(-1)
        PLDSLICEX
        LDMSGADDR
        LDI 1
        SWAP
        SWAP
        LDGRAMS
        LDMSGADDR
        LDMSGADDR
        LDGRAMS
        LDU 1
        DROP
        IF:<{
          XCHG s0, s6
          PLDREFIDX 0
        }>ELSE<{
          POP s6
          PUSHNULL
        }>
        XCHG s5, s6
        XCHG s4, s5
        XCHG s3, s4
        XCHG3 s1, s3, s0
        DROP
        XCHG s0, s2
        REWRITESTDADDR
        DROP
        EQINT 0
        THROWIFNOT 333
        REWRITESTDADDR
        DROP
        EQINT 0
        THROWIFNOT 333
        GETGLOB 14
        XCHG2 s0, s4
        CALL:<{
          SWAP
          PUSHINT 267
          DICTGET
          NULLSWAPIFNOT
          NOT
          IFJMP:<{
            DROP
            TUPLE 0
            PUSHINT 0
          }>
          LDREFRTOS
          LDMSGADDR
          LDMSGADDR
          LDREF
          LDU 14
          SWAP
          SWAP
          LDU 14
          SWAP
          SWAP
          LDI 1
          SWAP
          SWAP
          LDI 1
          SWAP
          NIP
          TUPLE 7
          UNTUPLE 7
          XCHG s0, s7
          LDU 40
          SWAP
          SWAP
          LDGRAMS
          LDGRAMS
          LDGRAMS
          LDGRAMS
          LDGRAMS
          LDGRAMS
          LDGRAMS
          BLKSWAP 8, 1
          TUPLE 8
          UNTUPLE 8
          TUPLE 0
          XCHG2 s0, s8
          TPUSH
          XCHG2 s0, s6
          TPUSH
          XCHG2 s0, s4
          TPUSH
          ROT
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          XCHG2 s0, s7
          TPUSH
          XCHG2 s0, s5
          TPUSH
          XCHG2 s0, s3
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          ROT
          TPUSH
          NIP
          PUSHINT 1
        }>
        PUSH s6
        ISNULL
        NOT
        GETGLOB 6
        PLDU 2
        EQINT 0
        PUSH s9
        XCHG3 s4, s3, s5
        XCHG3 s14, s7, s13
        PUSH s5
        PUSHINT 1207989464
        EQUAL
        IF:<{
          GETGLOB 16
          PUXC s3, s(-1)
          ADD
          GETGLOB 21
          ADD
          GETGLOB 22
          ADD
          PUSH s2
          ADD
          GETGLOB 24
          ADD
          PUXC s1, s(-1)
          GEQ
          THROWIFNOT 1017
        }>
        PUSH s5
        PUSHINT 3406020527
        EQUAL
        IF:<{
          PUSH s3
          NEQINT 0
          IF:<{
            PUSHINT 3
          }>ELSE<{
            PUSHINT 5
          }>
          PUXC s3, s(-1)
          MUL
          GETGLOB 17
          ADD
          GETGLOB 21
          ADD
          GETGLOB 22
          ADD
          PUSH s2
          ADD
          GETGLOB 24
          ADD
          XCHG s0, s5
          IF:<{
            GETGLOB 23
            XCHG s1, s5
            ADD
            XCHG s0, s4
          }>
          PUXC s0, s4
          GEQ
          THROWIFNOT 1017
        }>ELSE<{
          POP s4
        }>
        PUSH s4
        PUSHINT 3485616356
        EQUAL
        IF:<{
          PUSH s2
          NEQINT 0
          IF:<{
            PUSHINT 3
          }>ELSE<{
            PUSHINT 5
          }>
          PUXC s2, s(-1)
          MUL
          GETGLOB 18
          ADD
          GETGLOB 21
          ADD
          GETGLOB 22
          ADD
          OVER
          ADD
          GETGLOB 23
          ADD
          GETGLOB 24
          ADD
          PUXC s4, s(-1)
          GEQ
          THROWIFNOT 1017
        }>
        PUSH s4
        PUSHINT 3998571052
        EQUAL
        IF:<{
          OVER
          MULINT 3
          GETGLOB 19
          ADD
          GETGLOB 21
          ADD
          GETGLOB 22
          ADD
          OVER
          ADD
          GETGLOB 24
          ADD
          PUXC s4, s(-1)
          GEQ
          THROWIFNOT 1017
        }>
        XCHG s0, s4
        PUSHINT 3427973859
        EQUAL
        IF:<{
          SWAP
          NEQINT 0
          IF:<{
            PUSHINT 3
          }>ELSE<{
            PUSHINT 5
          }>
          MUL
          GETGLOB 20
          ADD
          GETGLOB 21
          LSHIFT 1
          ADD
          GETGLOB 22
          ADD
          ROT
          ADD
          GETGLOB 23
          ADD
          GETGLOB 24
          LSHIFT 1
          ADD
          PUSHINT 50000000
          ADD
          GEQ
          THROWIFNOT 1017
        }>ELSE<{
          BLKDROP 4
        }>
        SWAP
        THROWIFNOT 1001
        GETGLOB 5
        XCHG s1, s8
        CALL:<{
          NOW
          PUSH s2
          INDEX 7
          EQINT 0
          PUSH s3
          INDEX 1
          EQINT 0
          OR
          IFJMP:<{
            NIP
            PUSHINT 0
            SETINDEXVAR
          }>
          PUSH s2
          INDEX 0
          PUXC s1, s(-1)
          SUB
          DUP
          EQINT 0
          IFJMP:<{
            BLKDROP 3
          }>
          PUSH s3
          INDEX 1
          MUL
          PUSH s3
          INDEX 5
          PUSHINT 14551915228366851806640625
          LSHIFT 36
          MULDIV
          PUXC s0, s2
          PUSHINT 10000
          MULDIV
          XCPU s3, s2
          OVER
          INDEX 5
          SWAP
          ADD
          PUSHINT 5
          SETINDEXVAR
          XCPU s2, s3
          SUB
          XCHG s1, s2
          OVER
          INDEX 4
          SWAP
          ADD
          PUSHINT 4
          SETINDEXVAR
          ROT
          OVER
          INDEX 2
          SWAP
          ADD
          PUSHINT 2
          SETINDEXVAR
          SWAP
          PUSHINT 0
          SETINDEXVAR
        }>
        PUSH s3
        PUSHINT 3406020527
        EQUAL
        IF:<{
          XC2PU s6, s7, s7
          SWAP
          IF:<{
            PUXC s1, s(-1)
            DUP
            INDEX 6
            DUP
            EQINT 0
            IF:<{
              2DROP
            }>ELSE<{
              SWAP
              INDEX 4
              ROTREV
              MULDIV
            }>
          }>ELSE<{
            PUXC s1, s(-1)
            DUP
            INDEX 4
            DUP
            EQINT 0
            IF:<{
              2DROP
            }>ELSE<{
              SWAP
              INDEX 6
              ROTREV
              MULDIV
            }>
            SWAP
          }>
          NIP
        }>ELSE<{
          XC2PU s6, s7, s7
          SWAP
          IF:<{
            PUXC s1, s(-1)
            DUP
            INDEX 7
            DUP
            EQINT 0
            IF:<{
              2DROP
            }>ELSE<{
              SWAP
              INDEX 5
              ROTREV
              MULDIV
            }>
          }>ELSE<{
            PUXC s1, s(-1)
            DUP
            INDEX 5
            DUP
            EQINT 0
            IF:<{
              2DROP
            }>ELSE<{
              SWAP
              INDEX 7
              ROTREV
              MULDIV
            }>
            SWAP
          }>
          NIP
        }>
        PUXC s6, s(-1)
        SWAP
        INDEX 3
        SWAP
        GEQ
        IF:<{
          PUSHINT -1
        }>ELSE<{
          PUSHINT 0
        }>
        THROWIFNOT 1005
        OVER
        PUSHINT 3485616356
        EQUAL
        IF:<{
          XCHG s0, s5
          INDEX 14
          THROWIFNOT 1012
          PUSH s4
          ISNULL
          THROWIF 1008
        }>ELSE<{
          POP s5
        }>
        PUSHNULL
        NEWC
        PUSHINT 0
        ROT
        PUSHINT 267
        DICTISETB
        PUSH s5
        ISNULL
        NOT
        IF:<{
          DROP
          GETGLOB 6
          PLDU 2
          EQINT 0
          NOT
          IFJMP:<{
            NEWC
            XCHG3 s3, s1, s3
            NOW
            XCHG2 s0, s5
            NEWC
            SWAP
            STSLICER
            ENDC
            BLKSWAP 4, 1
            2SWAP
            STSLICER
            ROT
            SWAP
            STU 32
            SWAP
            SWAP
            STU 40
            STREF
            XCHG s1, s2
            CALLDICT 197
            RETALT
          }>
          GETGLOB 7
          XCHG2 s0, s5
          CALLDICT 115
          XCHG s0, s4
        }>ELSE<{
          POP s5
        }>
        XCHG s0, s4
        NEWC
        STREF
        XCHG s0, s2
        NOW
        PUXC2 s1, s0, s2
        XCHG3 s6, s1, s5
        NEWC
        SWAP
        STSLICER
        ENDC
        BLKSWAP 4, 1
        2SWAP
        STSLICER
        ROT
        SWAP
        STU 32
        SWAP
        SWAP
        STU 40
        STREF
        CALLDICT 188
        XCHG3 s3, s0, s0
        CALL:<{
          MYADDR
          GETGLOB 15
          XCHG3 s1, s4, s0
          XCHG s0, s2
          PUSHINT 0
          XCHG s0, s2
          PUSHNULL
          PUSHNULL
          NEWC
          XCHG2 s0, s4
          STSLICER
          ROT
          STSLICER
          XCHG s1, s2
          STDICT
          STDICT
          ENDC
          OVER
          NEWC
          STU 2
          XCHG s1, s3
          STDICT
          XCHG s1, s2
          STDICT
          STU 1
          ENDC
          HASHCU
          PUSHINT 0
          PUSHINT 4
          NEWC
          STU 3
          STI 8
          STU 256
          ENDC
          CTOS
          NEWC
          PUSHINT 736177463
          ROT
          XCHG s0, s5
          XCHG s0, s2
          STU 32
          STU 64
          STREF
          SWAP
          STBR
          PUSHINT 0
          SWAP
          ENDC
          CALLDICT 55
          PUSHINT 64
          SENDRAWMSG
        }>
        RETALT
      }>
      PUSH c1
      BOOLOR
      SWAP
      TRY
    }>
    POP s4
    POP s4
    PUSH s3
    PUSHINT 3123276026
    EQUAL
    IFJMP:<{
      POP s3
      GETGLOB 6
      SDEQ
      THROWIFNOT 1003
      OVER
      PUSHINT 267
      PLDSLICEX
      CALLDICT 188
      BLKSWAP 1, 3
      CALL:<{
        MYADDR
        GETGLOB 15
        XCHG3 s1, s4, s0
        XCHG s0, s2
        PUSHINT 0
        XCHG s0, s2
        PUSHNULL
        PUSHNULL
        NEWC
        XCHG2 s0, s4
        STSLICER
        ROT
        STSLICER
        XCHG s1, s2
        STDICT
        STDICT
        ENDC
        OVER
        NEWC
        STU 2
        XCHG s1, s3
        STDICT
        XCHG s1, s2
        STDICT
        STU 1
        ENDC
        HASHCU
        PUSHINT 0
        PUSHINT 4
        NEWC
        STU 3
        STI 8
        STU 256
        ENDC
        CTOS
        NEWC
        PUSHINT 736177463
        ROT
        XCHG s0, s5
        XCHG s0, s2
        STU 32
        STU 64
        STREF
        SWAP
        STSLICER
        PUSHINT 0
        SWAP
        ENDC
        CALLDICT 55
        PUSHINT 64
        SENDRAWMSG
      }>
    }>
    PUSH s3
    PUSHINT 736177463
    EQUAL
    IF:<{
      LDMSGADDR
      LDU 32
      SWAP
      SWAP
      LDU 40
      SWAP
      XCHG3 s3, s3, s0
      DROP
      MYADDR
      GETGLOB 15
      PUXC s3, s(-1)
      XCHG s0, s2
      PUSHINT 0
      XCHG s0, s2
      PUSHNULL
      PUSHNULL
      NEWC
      XCHG2 s0, s4
      STSLICER
      ROT
      STSLICER
      XCHG s1, s2
      STDICT
      STDICT
      ENDC
      OVER
      NEWC
      STU 2
      XCHG s1, s3
      STDICT
      XCHG s1, s2
      STDICT
      STU 1
      ENDC
      HASHCU
      PUSHINT 0
      PUSHINT 4
      NEWC
      STU 3
      STI 8
      STU 256
      ENDC
      CTOS
      PUXC s4, s(-1)
      SDEQ
      THROWIFNOT 1003
      DUP
      PUSHINT 3998571052
      EQUAL
      IFJMP:<{
        DROP
        POP s2
        BLKDROP2 1, 3
        CALLDICT 215
        RETALT
      }>
      DUP
      PUSHINT 3406020527
      EQUAL
      IFJMP:<{
        DROP
        POP s2
        BLKDROP2 1, 3
        PREPAREDICT 213
        CALLXARGS 4, 0
        RETALT
      }>
      DUP
      PUSHINT 3485616356
      EQUAL
      IFJMP:<{
        DROP
        POP s2
        BLKDROP2 1, 3
        PREPAREDICT 214
        CALLXARGS 4, 0
        RETALT
      }>
      PUSHINT 3427973859
      EQUAL
      IFJMP:<{
        POP s2
        BLKDROP2 1, 3
        CALLDICT 216
        RETALT
      }>
      DROP
    }>
    PUSH s3
    PUSHINT 3503975190
    EQUAL
    IFJMP:<{
      POP s3
      XCHG s0, s2
      LDGRAMS
      LDREF
      LDMSGADDR
      LDMSGADDR
      DROP
      GETGLOB 14
      PUSH s2
      CALL:<{
        SWAP
        PUSHINT 267
        DICTGET
        NULLSWAPIFNOT
        NOT
        IFJMP:<{
          DROP
          TUPLE 0
          PUSHINT 0
        }>
        LDREFRTOS
        LDMSGADDR
        LDMSGADDR
        LDREF
        LDU 14
        SWAP
        SWAP
        LDU 14
        SWAP
        SWAP
        LDI 1
        SWAP
        SWAP
        LDI 1
        SWAP
        NIP
        TUPLE 7
        UNTUPLE 7
        XCHG s0, s7
        LDU 40
        SWAP
        SWAP
        LDGRAMS
        LDGRAMS
        LDGRAMS
        LDGRAMS
        LDGRAMS
        LDGRAMS
        LDGRAMS
        BLKSWAP 8, 1
        TUPLE 8
        UNTUPLE 8
        TUPLE 0
        XCHG2 s0, s8
        TPUSH
        XCHG2 s0, s6
        TPUSH
        XCHG2 s0, s4
        TPUSH
        ROT
        TPUSH
        SWAP
        TPUSH
        SWAP
        TPUSH
        SWAP
        TPUSH
        SWAP
        TPUSH
        XCHG2 s0, s7
        TPUSH
        XCHG2 s0, s5
        TPUSH
        XCHG2 s0, s3
        TPUSH
        SWAP
        TPUSH
        SWAP
        TPUSH
        SWAP
        TPUSH
        ROT
        TPUSH
        NIP
        PUSHINT 1
      }>
      THROWIFNOT 1001
      DUP
      INDEX 9
      XCHG s1, s7
      SDEQ
      THROWIFNOT 1003
      XCHG2 s5, s3
      PUSHINT 1
      SETINDEXVAR
      SWAP
      PUSHINT 10
      SETINDEXVAR
      GETGLOB 14
      XCHG3 s0, s4, s4
      CALL:<{
        NEWC
        SWAP
        DUP
        INDEX 8
        OVER
        INDEX 9
        PUSH s2
        INDEX 10
        PUSH s3
        INDEX 11
        PUSH s4
        INDEX 12
        PUSH s5
        INDEX 13
        PUSH s6
        INDEX 14
        XCHG s7, s8
        NEWC
        XCHG2 s0, s7
        STSLICER
        XCHG2 s0, s5
        STSLICER
        XCHG s1, s3
        STREF
        SWAP
        SWAP
        STU 14
        SWAP
        SWAP
        STU 14
        SWAP
        SWAP
        STI 1
        SWAP
        SWAP
        STI 1
        ENDC
        SWAP
        STREF
        OVER
        INDEX 0
        PUSH s2
        INDEX 1
        PUSH s3
        INDEX 2
        PUSH s4
        INDEX 3
        PUSH s5
        INDEX 4
        PUSH s6
        INDEX 5
        PUSH s7
        INDEX 6
        XCHG s0, s8
        INDEX 7
        XCHG s7, s8
        XCHG s6, s7
        XCHG s5, s6
        XCHG s4, s5
        XCHG s3, s4
        XCHG3 s1, s3, s0
        XCHG2 s8, s7
        SWAP
        STU 40
        XCHG2 s0, s5
        STGRAMS
        XCHG2 s0, s3
        STGRAMS
        SWAP
        STGRAMS
        SWAP
        STGRAMS
        SWAP
        STGRAMS
        ROT
        STGRAMS
        SWAP
        STGRAMS
        XCHG s0, s2
        PUSHINT 267
        DICTSETB
      }>
      SETGLOB 14
      CALLDICT 185
      GETGLOB 26
      PUSHINT 100000000
      MAX
      XCHG s1, s2
      CALLDICT 61
    }>
    PUSH s3
    PUSHINT 1501249002
    EQUAL
    IFJMP:<{
      POP s3
      XCHG s0, s2
      LDMSGADDR
      DROP
      GETGLOB 14
      OVER
      CALL:<{
        SWAP
        PUSHINT 267
        DICTGET
        NULLSWAPIFNOT
        NOT
        IFJMP:<{
          DROP
          TUPLE 0
          PUSHINT 0
        }>
        LDREFRTOS
        LDMSGADDR
        LDMSGADDR
        LDREF
        LDU 14
        SWAP
        SWAP
        LDU 14
        SWAP
        SWAP
        LDI 1
        SWAP
        SWAP
        LDI 1
        SWAP
        NIP
        TUPLE 7
        UNTUPLE 7
        XCHG s0, s7
        LDU 40
        SWAP
        SWAP
        LDGRAMS
        LDGRAMS
        LDGRAMS
        LDGRAMS
        LDGRAMS
        LDGRAMS
        LDGRAMS
        BLKSWAP 8, 1
        TUPLE 8
        UNTUPLE 8
        TUPLE 0
        XCHG2 s0, s8
        TPUSH
        XCHG2 s0, s6
        TPUSH
        XCHG2 s0, s4
        TPUSH
        ROT
        TPUSH
        SWAP
        TPUSH
        SWAP
        TPUSH
        SWAP
        TPUSH
        SWAP
        TPUSH
        XCHG2 s0, s7
        TPUSH
        XCHG2 s0, s5
        TPUSH
        XCHG2 s0, s3
        TPUSH
        SWAP
        TPUSH
        SWAP
        TPUSH
        SWAP
        TPUSH
        ROT
        TPUSH
        NIP
        PUSHINT 1
      }>
      DROP
      GETGLOB 5
      CALL:<{
        NOW
        PUSH s2
        INDEX 7
        EQINT 0
        PUSH s3
        INDEX 1
        EQINT 0
        OR
        IFJMP:<{
          NIP
          PUSHINT 0
          SETINDEXVAR
        }>
        PUSH s2
        INDEX 0
        PUXC s1, s(-1)
        SUB
        DUP
        EQINT 0
        IFJMP:<{
          BLKDROP 3
        }>
        PUSH s3
        INDEX 1
        MUL
        PUSH s3
        INDEX 5
        PUSHINT 14551915228366851806640625
        LSHIFT 36
        MULDIV
        PUXC s0, s2
        PUSHINT 10000
        MULDIV
        XCPU s3, s2
        OVER
        INDEX 5
        SWAP
        ADD
        PUSHINT 5
        SETINDEXVAR
        XCPU s2, s3
        SUB
        XCHG s1, s2
        OVER
        INDEX 4
        SWAP
        ADD
        PUSHINT 4
        SETINDEXVAR
        ROT
        OVER
        INDEX 2
        SWAP
        ADD
        PUSHINT 2
        SETINDEXVAR
        SWAP
        PUSHINT 0
        SETINDEXVAR
      }>
      XC2PU s2, s2, s0
      XCHG s0, s4
      CALLDICT 211
      GETGLOB 14
      ROTREV
      CALL:<{
        NEWC
        SWAP
        DUP
        INDEX 8
        OVER
        INDEX 9
        PUSH s2
        INDEX 10
        PUSH s3
        INDEX 11
        PUSH s4
        INDEX 12
        PUSH s5
        INDEX 13
        PUSH s6
        INDEX 14
        XCHG s7, s8
        NEWC
        XCHG2 s0, s7
        STSLICER
        XCHG2 s0, s5
        STSLICER
        XCHG s1, s3
        STREF
        SWAP
        SWAP
        STU 14
        SWAP
        SWAP
        STU 14
        SWAP
        SWAP
        STI 1
        SWAP
        SWAP
        STI 1
        ENDC
        SWAP
        STREF
        OVER
        INDEX 0
        PUSH s2
        INDEX 1
        PUSH s3
        INDEX 2
        PUSH s4
        INDEX 3
        PUSH s5
        INDEX 4
        PUSH s6
        INDEX 5
        PUSH s7
        INDEX 6
        XCHG s0, s8
        INDEX 7
        XCHG s7, s8
        XCHG s6, s7
        XCHG s5, s6
        XCHG s4, s5
        XCHG s3, s4
        XCHG3 s1, s3, s0
        XCHG2 s8, s7
        SWAP
        STU 40
        XCHG2 s0, s5
        STGRAMS
        XCHG2 s0, s3
        STGRAMS
        SWAP
        STGRAMS
        SWAP
        STGRAMS
        SWAP
        STGRAMS
        ROT
        STGRAMS
        SWAP
        STGRAMS
        XCHG s0, s2
        PUSHINT 267
        DICTSETB
      }>
      SETGLOB 14
      CALLDICT 185
    }>
    PUSH s3
    PUSHINT 251183862
    EQUAL
    IFJMP:<{
      NIP
      BLKDROP2 1, 2
      LDMSGADDR
      DROP
      GETGLOB 14
      OVER
      CALL:<{
        SWAP
        PUSHINT 267
        DICTGET
        NULLSWAPIFNOT
        NOT
        IFJMP:<{
          DROP
          TUPLE 0
          PUSHINT 0
        }>
        LDREFRTOS
        LDMSGADDR
        LDMSGADDR
        LDREF
        LDU 14
        SWAP
        SWAP
        LDU 14
        SWAP
        SWAP
        LDI 1
        SWAP
        SWAP
        LDI 1
        SWAP
        NIP
        TUPLE 7
        UNTUPLE 7
        XCHG s0, s7
        LDU 40
        SWAP
        SWAP
        LDGRAMS
        LDGRAMS
        LDGRAMS
        LDGRAMS
        LDGRAMS
        LDGRAMS
        LDGRAMS
        BLKSWAP 8, 1
        TUPLE 8
        UNTUPLE 8
        TUPLE 0
        XCHG2 s0, s8
        TPUSH
        XCHG2 s0, s6
        TPUSH
        XCHG2 s0, s4
        TPUSH
        ROT
        TPUSH
        SWAP
        TPUSH
        SWAP
        TPUSH
        SWAP
        TPUSH
        SWAP
        TPUSH
        XCHG2 s0, s7
        TPUSH
        XCHG2 s0, s5
        TPUSH
        XCHG2 s0, s3
        TPUSH
        SWAP
        TPUSH
        SWAP
        TPUSH
        SWAP
        TPUSH
        ROT
        TPUSH
        NIP
        PUSHINT 1
      }>
      NIP
      THROWIFNOT 1001
      CALLDICT 60
    }>
    PUSH3 s3, s2, s1
    PUSH s3
    CALLDICT 218
    IFJMP:<{
      BLKDROP 4
    }>
    PUSH3 s3, s2, s1
    PUSH s3
    CALLDICT 217
    IFJMP:<{
      BLKDROP 4
    }>
    CALLDICT 219
    IFRET
    PUSHPOW2DEC 16
    THROWANY
  }>
  52 => <{
    LDREFRTOS
    LDU 16
    OVER
    IFJMP:<{
      DROP
      PUSHINT 0
    }>
    NIP
    LDGRAMS
    DROP
    PUSHINT 0
    SWAP
  }>
  53 => <{
    LDREFRTOS
    LDU 16
    OVER
    IFJMP:<{
      DROP
      PUSHINT 0
      DUP
    }>
    NIP
    LDGRAMS
    LDGRAMS
    DROP
    PUSHINT 0
    ROTREV
  }>
  54 => <{
    NEWC
    PUSHINT 24
    SWAP
    STU 6
    XCHG2 s0, s4
    STSLICER
    ROT
    STGRAMS
    XCHG s0, s2
    PUSHINT 7
    XCHG2 s0, s3
    STU 108
    STREF
    STREF
    ENDC
  }>
  55 => <{
    NEWC
    PUSHINT 24
    SWAP
    STU 6
    XCHG2 s0, s3
    STSLICER
    SWAP
    STGRAMS
    SWAP
    PUSHINT 1
    ROT
    STU 107
    STREF
    ENDC
  }>
  56 => <{
    NEWC
    PUSHINT 16
    SWAP
    STU 6
    XCHG2 s0, s3
    STSLICER
    SWAP
    STGRAMS
    SWAP
    PUSHINT 1
    ROT
    STU 107
    STREF
    ENDC
  }>
  57 => <{
    NEWC
    PUSHINT 24
    SWAP
    STU 6
    XCHG2 s0, s3
    STSLICER
    SWAP
    STGRAMS
    PUSHINT 0
    SWAP
    STU 107
    SWAP
    STBR
    ENDC
  }>
  60 => <{
    PUSHINT 0
    NEWC
    PUSHINT 745978227
    ROT
    XCHG s0, s4
    XCHG s0, s2
    STU 32
    STU 64
    MYADDR
    STSLICER
    XCHG s1, s2
    STU 1
    PUSHINT 30000000
    SWAP
    CALLDICT 57
    PUSHINT 0
    SENDRAWMSG
  }>
  61 => <{
    BALANCE
    UNTUPLE 2
    DROP
    OVER
    GREATER
    IF:<{
      PUSHINT 2
      RAWRESERVE
      PUSHINT 0
      PUSHINT 16
      NEWC
      STU 6
      ROT
      STSLICER
      OVER
      STGRAMS
      STU 107
      PUSHINT 3576854235
      ROT
      XCHG s0, s2
      STU 32
      STU 64
      ENDC
      PUSHINT 130
      SENDRAWMSG
    }>ELSE<{
      BLKDROP 3
    }>
  }>
  83 => <{
    REWRITEVARADDR
    SWAP
    EQINT 0
    THROWIFNOT 72
  }>
  84 => <{
    OVER
    CALLDICT 83
    DROP
    XCHG s0, s2
    NEWC
    STU 32
    ROT
    STBR
    ENDC
    PUSHINT 1
    PUSHINT 16
    NEWC
    STU 6
    XCHG2 s0, s3
    STSLICER
    PUSHINT 0
    STGRAMS
    XCHG s1, s2
    STU 107
    STREF
    ENDC
    PUSHINT 66
    SENDRAWMSG
  }>
  85 => <{
    NEWC
    SWAP
    STSLICER
    ENDC
    SWAP
    STREF
  }>
  89 => <{
    PUSHINT 0
    SWAP
    NEWC
    CALLDICT 84
  }>
  93 => <{
    DUP
    LESSINT 1
    IFJMP:<{
      DROP
      PUSHINT 0
    }>
    DUP
    PUSHPOW2 8
    LEQ
    THROWIFNOT 997
    2DUP
    SDCUTLAST
    OVER
    LDUX
    DROP
    ROTREV
    SDSKIPLAST
    SWAP
  }>
  94 => <{
    DUP
    LESSINT 1
    IFJMP:<{
      DROP
      PUSHINT 0
    }>
    DUP
    PUSHINT 257
    LEQ
    THROWIFNOT 997
    2DUP
    SDCUTLAST
    OVER
    LDIX
    DROP
    ROTREV
    SDSKIPLAST
    SWAP
  }>
  95 => <{
    SAVECTR c2
    SAMEALTSAVE
    OVER
    TLEN
    DEC
    WHILE:<{
      DUP
      GTINT -1
    }>DO<{
      PUSH2 s2, s0
      INDEXVAR
      PUSH s2
      EQUAL
      IFJMP:<{
        BLKDROP2 2, 1
        RETALT
      }>
      DEC
    }>
    BLKDROP 3
    PUSHINT -100
  }>
  96 => <{
    TUPLE 0
    OVER
    TLEN
    REPEAT:<{
      TUPLE 0
      XCHG s0, s2
      TPOP
      WHILE:<{
        OVER
        TLEN
        GTINT 0
      }>DO<{
        SWAP
        TPOP
        XCHG s1, s2
        MINMAX
        XCHG s1, s4
        TPUSH
        XCHG s0, s3
      }>
      NIP
      TPUSH
    }>
    NIP
  }>
  97 => <{
    DUP
    TLEN
    DUP
    GTINT 0
    THROWIFNOT 999
    DUP
    EQINT 1
    IFJMP:<{
      DROP
      INDEX 0
    }>
    DUP
    EQINT 2
    IFJMP:<{
      DROP
      DUP
      INDEX 0
      SWAP
      INDEX 1
      ADD
      RSHIFT 1
    }>
    DUP
    RSHIFT 1
    SWAP
    MODPOW2# 1
    XCHG s0, s2
    CALLDICT 96
    XCHG s0, s2
    EQINT 1
    IFJMP:<{
      INDEXVAR
    }>
    2DUP
    INDEXVAR
    SWAP
    DEC
    XCHG s1, s2
    INDEXVAR
    ADD
    RSHIFT 1
  }>
  99 => <{
    TUPLE 0
    OVER
    TLEN
    REPEAT:<{
      SWAP
      TPOP
      XCHG s1, s2
      TPUSH
    }>
    NIP
  }>
  100 => <{
    CTOS
    TUPLE 0
    SWAP
    LDI 24
    OVER
    PUSHPOW2DEC 8
    LEQ
    THROWIFNOT 997
    SWAP
    REPEAT:<{
      LDREF
      DUP
      PLDI 15
      PUSHPOW2 8
      EQUAL
      IF:<{
        PUSHINT 257
      }>ELSE<{
        PUSHINT 64
      }>
      CALLDICT 94
      NIP
      XCHG s1, s2
      TPUSH
      SWAP
      CTOS
    }>
    DROP
    CALLDICT 99
  }>
  103 => <{
    NEWC
    ROT
    STUX
    PU2XC s0, s1, s3
    PUSH s4
    DICTUREPLACEB
    DUP
    NOT
    IF:<{
      DROP
      ROT
      DICTUADDB
      SWAP
    }>ELSE<{
      POP s4
      BLKDROP2 2, 1
    }>
    SWAP
  }>
  104 => <{
    PUSH s3
    TLEN
    PUSH s3
    TLEN
    EQUAL
    THROWIFNOT 995
    PUSHINT 0
    WHILE:<{
      PUSH s4
      TLEN
      PUXC s1, s(-1)
      LESS
    }>DO<{
      PUSH2 s4, s0
      INDEXVAR
      PUSH2 s4, s1
      INDEXVAR
      PUSH s4
      XCHG s3, s8
      XCPUXC s2, s4, s2
      CALLDICT 103
      DROP
      XCHG s0, s5
      INC
    }>
    BLKDROP 5
  }>
  107 => <{
    LDU 256
    LDU 256
    LDU 8
    DROP
    DUP
    GTINT 26
    IF:<{
      ADDINT -27
    }>
    ROTREV
    ECRECOVER
    NULLSWAPIFNOT
    NULLSWAPIFNOT2
    POP s3
    PUSH s2
    NOT
    IFJMP:<{
      2DROP
    }>
    POP s2
    NEWC
    STU 256
    STU 256
    PUSHINT 1
    HASHEXT 3
    PUSHPOW2DEC 160
    AND
  }>
  108 => <{
    PUSHINT 24
    CALLDICT 93
    PUSHINT 600
    OVER
    ADD
    SWAP
    EQINT 1
    THROWANYIFNOT
    PUSHINT 32
    CALLDICT 93
    LSHIFT 3
    PUSHINT 600
    OVER
    ADD
    OVER
    PUSHPOW2 8
    LEQ
    THROWANYIFNOT
    PUSHINT 600
    OVER
    ADD
    OVER
    GTINT 0
    THROWANYIFNOT
    SWAP
    PUSHINT 48
    CALLDICT 93
    XCHG s0, s2
    CALLDICT 93
    SWAP
    PUSHPOW2 8
    CALLDICT 93
    DUP
    NEQINT 0
    IF:<{
      WHILE:<{
        DUP
        RSHIFT 8
        LSHIFT 8
        PUXC s1, s(-1)
        EQUAL
      }>DO<{
        RSHIFT 8
      }>
    }>
    SWAP
    ENDS
    XCHG s0, s2
  }>
  109 => <{
    SWAP
    PUSHINT 1
    HASHEXT 3
    SWAP
    CALLDICT 107
  }>
  110 => <{
    LDREF
    SWAP
    CTOS
    PUXC s0, s1
    CALLDICT 109
    SWAP
    CALLDICT 108
  }>
  111 => <{
    PUSH2 s0, s1
    GREATER
    IF:<{
      PUSHINT 200
      PUSH s3
      ADD
      PUSH2 s1, s2
      SUB
      PUSHINT 900
      GREATER
      THROWANYIF
    }>
    2DUP
    GREATER
    IF:<{
      PUSHINT 200
      XCHG2 s0, s3
      ADD
      ADDINT 50
      XCHG s0, s2
      SUB
      PUSHINT 180
      GREATER
      THROWANYIF
    }>ELSE<{
      BLKDROP 3
    }>
    PUSHINT -1
  }>
  112 => <{
    PUSHNULL
    PUSHPOW2DEC 64
    PUSHINT -1
    PUSHINT 0
    XCPU s1, s8
    PUSHINT 16
    DICTUGETNEXT
    NULLSWAPIFNOT2
    WHILE:<{
    }>DO<{
      SWAP
      CALLDICT 110
      DUP
      PUSHINT 1000
      DIV
      PU2XC s5, s9, s(-1)
      CALLDICT 111
      DROP
      PUXC s9, s3
      CALLDICT 95
      PUXC s10, s2
      CALLDICT 95
      PUSH s2
      NEQINT -100
      OVER
      NEQINT -100
      AND
      IF:<{
        PUSH s9
        TLEN
        SWAP
        MUL
        ROT
        ADD
        XCHG s2, s6
        PUSHINT 16
        XCHG s0, s2
        PUSHPOW2 8
        SWAP
        CALLDICT 103
        DROP
        XCHG2 s3, s4
        MIN
        XCHG s0, s2
      }>ELSE<{
        BLKDROP 4
      }>
      PUSH s8
      PUSHINT 16
      DICTUGETNEXT
      NULLSWAPIFNOT2
      XCHG s0, s3
      INC
      XCHG s0, s3
    }>
    2DROP
    BLKDROP2 3, 3
    POP s4
    PUSH s3
    ADDINT 100
    XCHG2 s3, s4
    EQUAL
    XCHG s1, s3
    THROWANYIFNOT
  }>
  113 => <{
    TUPLE 0
    PUSHINT 0
    WHILE:<{
      PUSH2 s0, s4
      LESS
    }>DO<{
      PUSHINT 0
      TUPLE 0
      WHILE:<{
        PUSH2 s1, s5
        LESS
      }>DO<{
        PUSH2 s5, s2
        MUL
        PUSH s2
        ADD
        PUSH s8
        PUSHINT 16
        DICTUGET
        NULLSWAPIFNOT
        IF:<{
          LDI 256
          DROP
          TPUSH
        }>ELSE<{
          DROP
        }>
        SWAP
        INC
        SWAP
      }>
      NIP
      DUP
      DEBUG 32
      DROP
      PUSHINT 300
      PUSH s2
      ADD
      OVER
      TLEN
      PUSH s5
      GEQ
      THROWANYIFNOT
      CALLDICT 97
      XCHG s1, s2
      TPUSH
      SWAP
      INC
    }>
    XCHG s1, s5
    BLKDROP 5
  }>
  114 => <{
    XCHG s0, s4
    CTOS
    PUSHINT 72
    CALLDICT 93
    PUSHINT 823907890102272
    EQUAL
    THROWIFNOT 500
    PUSHINT 24
    CALLDICT 93
    CALLDICT 93
    DROP
    PUSHINT 16
    CALLDICT 93
    SWAP
    LDREF
    ENDS
    PU2XC s4, s3, s2
    XCHG s0, s7
    CALLDICT 112
    XCHG s0, s3
    TLEN
    XCHG s0, s2
    TLEN
    XCHG2 s0, s3
    XCHG s0, s4
    CALLDICT 113
    SWAP
  }>
  115 => <{
    SWAP
    CTOS
    LDDICT
    LDGRAMS
    LDREF
    DROP
    XCHG s0, s3
    CTOS
    LDREF
    LDREF
    DROP
    SWAP
    CALLDICT 100
    XCPUXC s2, s0, s2
    XCHG s1, s5
    PUSHINT 117047
    PUSH c3
    EXECUTE
    DROP
    PUSHNULL
    PUSHINT 0
    WHILE:<{
      PUSH s4
      TLEN
      PUXC s1, s(-1)
      LESS
    }>DO<{
      PUSH2 s4, s0
      INDEXVAR
      PUSH s4
      PUSHINT 64
      DICTUGETREF
      NULLSWAPIFNOT
      IF:<{
        CTOS
        LDMSGADDR
        LDGRAMS
        DROP
        PUSH2 s4, s2
        INDEXVAR
        PUSHINT 100000000
        ROT
        MULDIV
        NEWC
        SWAP
        STGRAMS
        XCHG3 s0, s1, s3
        PUSHINT 267
        DICTSETB
        SWAP
      }>ELSE<{
        DROP
      }>
      INC
    }>
    XCHG s1, s4
    BLKDROP 4
  }>
  184 => <{
    PUSH c4
    CTOS
    LDI 1
    SWAP
    SETGLOB 1
    LDGRAMS
    SWAP
    SETGLOB 2
    LDMSGADDR
    SWAP
    SETGLOB 3
    LDMSGADDR
    SWAP
    SETGLOB 4
    LDU 14
    SWAP
    SETGLOB 5
    LDMSGADDR
    SWAP
    SETGLOB 6
    LDREF
    SWAP
    SETGLOB 7
    LDU 20
    SWAP
    SETGLOB 8
    LDU 14
    SWAP
    SETGLOB 9
    LDU 20
    SWAP
    SETGLOB 10
    LDU 14
    SWAP
    SETGLOB 11
    LDU 14
    SWAP
    SETGLOB 12
    LDU 14
    SWAP
    SETGLOB 13
    LDREF
    SWAP
    SETGLOB 25
    GETGLOB 25
    CTOS
    LDGRAMS
    SWAP
    SETGLOB 16
    LDGRAMS
    SWAP
    SETGLOB 17
    LDGRAMS
    SWAP
    SETGLOB 18
    LDGRAMS
    SWAP
    SETGLOB 19
    LDGRAMS
    SWAP
    SETGLOB 20
    LDGRAMS
    SWAP
    SETGLOB 21
    LDGRAMS
    SWAP
    SETGLOB 22
    LDGRAMS
    SWAP
    SETGLOB 23
    LDGRAMS
    DROP
    SETGLOB 24
    LDDICT
    SWAP
    SETGLOB 14
    LDREF
    SWAP
    SETGLOB 15
    ENDS
  }>
  185 => <{
    GETGLOB 15
    GETGLOB 14
    GETGLOB 25
    GETGLOB 10
    GETGLOB 8
    GETGLOB 7
    NEWC
    GETGLOB 1
    SWAP
    STI 1
    GETGLOB 2
    STGRAMS
    GETGLOB 3
    STSLICER
    GETGLOB 4
    STSLICER
    GETGLOB 5
    SWAP
    STU 14
    GETGLOB 6
    STSLICER
    STREF
    STU 20
    GETGLOB 9
    SWAP
    STU 14
    STU 20
    GETGLOB 11
    SWAP
    STU 14
    GETGLOB 12
    SWAP
    STU 14
    GETGLOB 13
    SWAP
    STU 14
    STREF
    STDICT
    STREF
    ENDC
    POP c4
  }>
  186 => <{
    NEWC
    GETGLOB 16
    STGRAMS
    GETGLOB 17
    STGRAMS
    GETGLOB 18
    STGRAMS
    GETGLOB 19
    STGRAMS
    GETGLOB 20
    STGRAMS
    GETGLOB 21
    STGRAMS
    GETGLOB 22
    STGRAMS
    GETGLOB 23
    STGRAMS
    GETGLOB 24
    STGRAMS
    ENDC
    SETGLOB 25
  }>
  188 => <{
    PUSHNULL
    GETGLOB 14
    PUSHINT 267
    DICTMIN
    NULLSWAPIFNOT2
    XCHG s1, s2
    WHILE:<{
    }>DO<{
      LDREFRTOS
      LDMSGADDR
      LDMSGADDR
      LDREF
      LDU 14
      SWAP
      SWAP
      LDU 14
      SWAP
      SWAP
      LDI 1
      SWAP
      SWAP
      LDI 1
      SWAP
      NIP
      TUPLE 7
      UNTUPLE 7
      XCHG s0, s7
      LDU 40
      SWAP
      SWAP
      LDGRAMS
      LDGRAMS
      LDGRAMS
      LDGRAMS
      LDGRAMS
      LDGRAMS
      LDGRAMS
      BLKSWAP 8, 1
      TUPLE 8
      UNTUPLE 8
      TUPLE 0
      XCHG2 s0, s8
      TPUSH
      XCHG2 s0, s6
      TPUSH
      XCHG2 s0, s4
      TPUSH
      ROT
      TPUSH
      SWAP
      TPUSH
      SWAP
      TPUSH
      SWAP
      TPUSH
      SWAP
      TPUSH
      XCHG2 s0, s7
      TPUSH
      XCHG2 s0, s5
      TPUSH
      XCHG2 s0, s3
      TPUSH
      SWAP
      TPUSH
      SWAP
      TPUSH
      SWAP
      TPUSH
      ROT
      TPUSH
      NIP
      GETGLOB 5
      CALL:<{
        NOW
        PUSH s2
        INDEX 7
        EQINT 0
        PUSH s3
        INDEX 1
        EQINT 0
        OR
        IFJMP:<{
          NIP
          PUSHINT 0
          SETINDEXVAR
        }>
        PUSH s2
        INDEX 0
        PUXC s1, s(-1)
        SUB
        DUP
        EQINT 0
        IFJMP:<{
          BLKDROP 3
        }>
        PUSH s3
        INDEX 1
        MUL
        PUSH s3
        INDEX 5
        PUSHINT 14551915228366851806640625
        LSHIFT 36
        MULDIV
        PUXC s0, s2
        PUSHINT 10000
        MULDIV
        XCPU s3, s2
        OVER
        INDEX 5
        SWAP
        ADD
        PUSHINT 5
        SETINDEXVAR
        XCPU s2, s3
        SUB
        XCHG s1, s2
        OVER
        INDEX 4
        SWAP
        ADD
        PUSHINT 4
        SETINDEXVAR
        ROT
        OVER
        INDEX 2
        SWAP
        ADD
        PUSHINT 2
        SETINDEXVAR
        SWAP
        PUSHINT 0
        SETINDEXVAR
      }>
      NEWC
      OVER
      INDEX 4
      STGRAMS
      OVER
      INDEX 5
      STGRAMS
      OVER
      INDEX 6
      STGRAMS
      OVER
      INDEX 7
      STGRAMS
      OVER
      INDEX 13
      SWAP
      STI 1
      OVER
      INDEX 11
      SWAP
      STU 14
      SWAP
      INDEX 12
      SWAP
      STU 14
      XCPUXC s2, s2, s(-1)
      XCHG s0, s2
      PUSHINT 267
      DICTSETB
      GETGLOB 14
      ROT
      SWAP
      PUSHINT 267
      DICTGETNEXT
      NULLSWAPIFNOT2
      XCHG s1, s2
    }>
    2DROP
    GETGLOB 10
    GETGLOB 8
    NEWC
    STU 20
    GETGLOB 9
    SWAP
    STU 14
    STU 20
    GETGLOB 11
    SWAP
    STU 14
    GETGLOB 12
    SWAP
    STU 14
    GETGLOB 13
    SWAP
    STU 14
    STDICT
    ENDC
  }>
  193 => <{
    XCHG s0, s2
    PUSHINT 0
    XCHG s0, s2
    PUSHNULL
    PUSHNULL
    NEWC
    XCHG2 s0, s4
    STSLICER
    ROT
    STSLICER
    XCHG s1, s2
    STDICT
    STDICT
    ENDC
    OVER
    NEWC
    STU 2
    XCHG s1, s3
    STDICT
    XCHG s1, s2
    STDICT
    STU 1
    ENDC
    DUP
    HASHCU
    PUSHINT 0
    PUSHINT 4
    NEWC
    STU 3
    STI 8
    STU 256
    ENDC
    CTOS
  }>
  194 => <{
    MYADDR
    GETGLOB 15
    XCHG3 s1, s4, s0
    XCHG s0, s2
    PUSHINT 0
    XCHG s0, s2
    PUSHNULL
    PUSHNULL
    NEWC
    XCHG2 s0, s4
    STSLICER
    ROT
    STSLICER
    XCHG s1, s2
    STDICT
    STDICT
    ENDC
    OVER
    NEWC
    STU 2
    XCHG s1, s3
    STDICT
    XCHG s1, s2
    STDICT
    STU 1
    ENDC
    HASHCU
    PUSHINT 0
    PUSHINT 4
    NEWC
    STU 3
    STI 8
    STU 256
    ENDC
    CTOS
    NEWC
    PUSHINT 475980227
    ROT
    XCHG s0, s5
    XCHG s0, s2
    STU 32
    STU 64
    STDICT
    SWAP
    STSLICER
    ENDC
    GETGLOB 21
    SWAP
    CALLDICT 55
    PUSHINT 1
    SENDRAWMSG
  }>
  195 => <{
    MYADDR
    GETGLOB 15
    XCHG3 s1, s4, s0
    CALLDICT 193
    NEWC
    PUSHINT 475980227
    ROT
    XCHG s0, s6
    XCHG s0, s2
    STU 32
    STU 64
    XCHG s1, s2
    STDICT
    ROT
    STSLICER
    ENDC
    GETGLOB 21
    ROTREV
    CALLDICT 54
    PUSHINT 1
    SENDRAWMSG
  }>
  196 => <{
    MYADDR
    GETGLOB 15
    XCHG3 s1, s6, s0
    XCHG s0, s2
    PUSHINT 0
    XCHG s0, s2
    PUSHNULL
    PUSHNULL
    NEWC
    XCHG2 s0, s4
    STSLICER
    ROT
    STSLICER
    XCHG s1, s2
    STDICT
    STDICT
    ENDC
    OVER
    NEWC
    STU 2
    XCHG s1, s3
    STDICT
    XCHG s1, s2
    STDICT
    STU 1
    ENDC
    HASHCU
    PUSHINT 0
    PUSHINT 4
    NEWC
    STU 3
    STI 8
    STU 256
    ENDC
    CTOS
    NEWC
    PUSHINT 1913225186
    ROT
    XCHG s0, s7
    XCHG s0, s2
    STU 32
    STU 64
    XCHG2 s0, s3
    SWAP
    STI 1
    SWAP
    STSLICER
    SWAP
    STGRAMS
    SWAP
    STSLICER
    ENDC
    GETGLOB 21
    SWAP
    CALLDICT 55
    PUSHINT 1
    SENDRAWMSG
  }>
  197 => <{
    GETGLOB 7
    NEWC
    STREF
    XCHG s1, s2
    STREF
    ENDC
    NEWC
    PUSHINT 640246958
    ROT
    XCHG s0, s4
    XCHG s0, s2
    STU 32
    STU 64
    XCHG s1, s2
    STREF
    SWAP
    STBR
    GETGLOB 6
    PUSHINT 0
    XCHG s0, s2
    ENDC
    XCHG s1, s2
    CALLDICT 55
    PUSHINT 64
    SENDRAWMSG
  }>
  200 => <{
    NEWC
    XCHG2 s0, s3
    STGRAMS
    SWAP
    STGRAMS
    STDICT
    ENDC
    NEWC
    PUSHINT 718585003
    ROT
    XCHG s0, s7
    XCHG s0, s2
    STU 32
    STU 64
    XCHG2 s0, s3
    STSLICER
    SWAP
    STSLICER
    SWAP
    STSLICER
    XCHG s1, s2
    STREF
    PUSHINT 50000000
    SWAP
    ENDC
    CALLDICT 56
    PUSHINT 1
    SENDRAWMSG
  }>
  201 => <{
    GETGLOB 26
    PUSHINT 100000000
    MAX
    PUSHINT 2
    RAWRESERVE
    NEWC
    SWAP
    STSLICER
    ENDC
    NEWC
    PUSHINT 2712805003
    ROT
    XCHG s0, s6
    XCHG s0, s2
    STU 32
    STU 64
    ROT
    SWAP
    STU 32
    STU 16
    XCHG s1, s2
    STREF
    PUSHINT 0
    SWAP
    ENDC
    CALLDICT 56
    PUSHPOW2 7
    SENDRAWMSG
  }>
  202 => <{
    GETGLOB 26
    PUSHINT 100000000
    MAX
    PUSHINT 2
    RAWRESERVE
    NEWC
    PUSHINT 2712805003
    ROT
    XCHG s0, s6
    XCHG s0, s2
    STU 32
    STU 64
    ROT
    SWAP
    STU 32
    STU 16
    ROT
    STBR
    PUSHINT 0
    SWAP
    ENDC
    CALLDICT 56
    PUSHPOW2 7
    SENDRAWMSG
  }>
  203 => <{
    NEWC
    PUSHINT 3158376183
    ROT
    XCHG s0, s7
    XCHG s0, s2
    STU 32
    STU 64
    XCHG2 s0, s3
    STGRAMS
    SWAP
    STGRAMS
    STREF
    ROT
    STBR
    GETGLOB 24
    SWAP
    CALLDICT 57
    PUSHINT 1
    SENDRAWMSG
  }>
  204 => <{
    PUSHINT 0
    NEWC
    PUSHINT 260734629
    ROT
    XCHG s0, s9
    XCHG s0, s2
    STU 32
    STU 64
    XCHG2 s0, s3
    STGRAMS
    XCHG2 s0, s4
    STSLICER
    ROT
    STSLICER
    XCHG s1, s4
    STU 1
    OVER
    STGRAMS
    XCHG s1, s3
    STDICT
    ENDC
    GETGLOB 22
    XCHG2 s0, s3
    ADD
    ROT
    CALLDICT 55
    PUSHINT 1
    SENDRAWMSG
  }>
  211 => <{
    PUSH s3
    INDEX 9
    PUSH s4
    INDEX 4
    PUSH s5
    INDEX 5
    PUSH s6
    INDEX 10
    PUSH s3
    PLDU 2
    EQINT 0
    IFJMP:<{
      BLKDROP2 4, 3
      CONT:<{
        SAVECTR c2
        SAMEALTSAVE
        DUP
        PUSH c4
        PUSH c5
        PUSH c7
        CONT:<{
          2DROP
          PUSHINT 0
          SWAP
          RETALT
          2DROP
        }>
        SETCONTCTR c7
        SETCONTCTR c5
        SETCONTCTR c4
        PUSHINT 1
        PUSHINT -1
        SETCONTVARARGS
        CONT:<{
          PUSHINT 10000
          XCHG3 s0, s0, s3
          MULDIV
          OVER
          CTOS
          LDGRAMS
          LDU 14
          SWAP
          SWAP
          LDU 14
          SWAP
          SWAP
          LDGRAMS
          LDGRAMS
          LDGRAMS
          BLKSWAP 6, 1
          POP s6
          PUSH2 s6, s3
          LEQ
          IF:<{
            XCHG s1, s3
            BLKDROP 3
            POP s2
            XCHG s0, s2
            PUSHINT 10000
            MULDIV
            ADD
            SWAP
            RETALT
          }>ELSE<{
            PUSH2 s6, s2
            LEQ
            IFJMP:<{
              POP s5
              NIP
              OVER
              PUSHINT 10000
              MULDIV
              XCHG2 s4, s4
              SUB
              XCHG s1, s2
              PUSHINT 10000
              MULDIV
              XCHG s0, s2
              ADD
              SWAP
              ADD
              SWAP
              RETALT
            }>
            XCPU s1, s3
            PUSHINT 10000
            MULDIV
            PUXC s2, s3
            SUB
            PUSHINT 10000
            MULDIV
            XCHG2 s5, s5
            SUB
            XCHG s1, s3
            PUSHINT 10000
            MULDIV
            XCHG s0, s2
            ADD
            ROT
            ADD
            SWAP
            ADD
            SWAP
            RETALT
          }>
        }>
        PUSH c1
        BOOLOR
        SWAP
        TRY
      }>
      CALLXARGS 3, -1
      ROTREV
      PUSHINT 1
      SETINDEXVAR
      SWAP
      PUSHINT 10
      SETINDEXVAR
    }>
    NEWC
    XCHG2 s0, s6
    STSLICER
    XCHG2 s0, s4
    STSLICER
    XCHG3 s4, s3, s0
    XCHG s1, s2
    CALLDICT 203
  }>
  212 => <{
    GETGLOB 14
    PUSH s4
    CALL:<{
      SWAP
      PUSHINT 267
      DICTGET
      NULLSWAPIFNOT
      NOT
      IFJMP:<{
        DROP
        TUPLE 0
        PUSHINT 0
      }>
      LDREFRTOS
      LDMSGADDR
      LDMSGADDR
      LDREF
      LDU 14
      SWAP
      SWAP
      LDU 14
      SWAP
      SWAP
      LDI 1
      SWAP
      SWAP
      LDI 1
      SWAP
      NIP
      TUPLE 7
      UNTUPLE 7
      XCHG s0, s7
      LDU 40
      SWAP
      SWAP
      LDGRAMS
      LDGRAMS
      LDGRAMS
      LDGRAMS
      LDGRAMS
      LDGRAMS
      LDGRAMS
      BLKSWAP 8, 1
      TUPLE 8
      UNTUPLE 8
      TUPLE 0
      XCHG2 s0, s8
      TPUSH
      XCHG2 s0, s6
      TPUSH
      XCHG2 s0, s4
      TPUSH
      ROT
      TPUSH
      SWAP
      TPUSH
      SWAP
      TPUSH
      SWAP
      TPUSH
      SWAP
      TPUSH
      XCHG2 s0, s7
      TPUSH
      XCHG2 s0, s5
      TPUSH
      XCHG2 s0, s3
      TPUSH
      SWAP
      TPUSH
      SWAP
      TPUSH
      SWAP
      TPUSH
      ROT
      TPUSH
      NIP
      PUSHINT 1
    }>
    DROP
    GETGLOB 5
    CALL:<{
      NOW
      PUSH s2
      INDEX 7
      EQINT 0
      PUSH s3
      INDEX 1
      EQINT 0
      OR
      IFJMP:<{
        NIP
        PUSHINT 0
        SETINDEXVAR
      }>
      PUSH s2
      INDEX 0
      PUXC s1, s(-1)
      SUB
      DUP
      EQINT 0
      IFJMP:<{
        BLKDROP 3
      }>
      PUSH s3
      INDEX 1
      MUL
      PUSH s3
      INDEX 5
      PUSHINT 14551915228366851806640625
      LSHIFT 36
      MULDIV
      PUXC s0, s2
      PUSHINT 10000
      MULDIV
      XCPU s3, s2
      OVER
      INDEX 5
      SWAP
      ADD
      PUSHINT 5
      SETINDEXVAR
      XCPU s2, s3
      SUB
      XCHG s1, s2
      OVER
      INDEX 4
      SWAP
      ADD
      PUSHINT 4
      SETINDEXVAR
      ROT
      OVER
      INDEX 2
      SWAP
      ADD
      PUSHINT 2
      SETINDEXVAR
      SWAP
      PUSHINT 0
      SETINDEXVAR
    }>
    PUSH2 s3, s0
    DUP
    INDEX 4
    DUP
    EQINT 0
    IF:<{
      2DROP
    }>ELSE<{
      SWAP
      INDEX 6
      ROTREV
      MULDIV
    }>
    XCPU s1, s4
    OVER
    INDEX 4
    SWAP
    ADD
    PUSHINT 4
    SETINDEXVAR
    OVER
    OVER
    INDEX 6
    SWAP
    ADD
    PUSHINT 6
    SETINDEXVAR
    PUSH s4
    OVER
    INDEX 3
    SWAP
    ADD
    PUSHINT 3
    SETINDEXVAR
    PUSHNULL
    PUSH2 s6, s2
    PUSH2 s2, s1
    SWAP
    PUSHINT 267
    DICTGET
    NULLSWAPIFNOT
    NOT
    IF:<{
      DROP
      PUSHINT 0
      PUSH2 s0, s0
    }>ELSE<{
      LDI 1
      SWAP
      LSHIFT 1
      INC
      SWAP
      LDGRAMS
      XCHG s0, s2
      MUL
      SWAP
      LDI 1
      SWAP
      LSHIFT 1
      INC
      SWAP
      LDGRAMS
      XCHG s0, s2
      MUL
      XCHG s1, s2
      BLKDROP2 1, 2
      PUSHINT 1
    }>
    DROP
    XCHG s0, s2
    ADD
    SWAP
    NEWC
    ROTREV
    ROTREV
    DUP
    LESSINT 0
    XCHG s1, s2
    SWAP
    STI 1
    SWAP
    ABS
    STGRAMS
    SWAP
    DUP
    LESSINT 0
    XCHG s1, s2
    SWAP
    STI 1
    SWAP
    ABS
    STGRAMS
    XCHG s0, s2
    PUSHINT 267
    DICTSETB
    PUXC2 s9, s4, s4
    PUSH s8
    CALLDICT 195
    XCPUXC s2, s7, s(-1)
    PUXC s5, s6
    CALLDICT 211
    GETGLOB 14
    PUXC s4, s1
    CALL:<{
      NEWC
      SWAP
      DUP
      INDEX 8
      OVER
      INDEX 9
      PUSH s2
      INDEX 10
      PUSH s3
      INDEX 11
      PUSH s4
      INDEX 12
      PUSH s5
      INDEX 13
      PUSH s6
      INDEX 14
      XCHG s7, s8
      NEWC
      XCHG2 s0, s7
      STSLICER
      XCHG2 s0, s5
      STSLICER
      XCHG s1, s3
      STREF
      SWAP
      SWAP
      STU 14
      SWAP
      SWAP
      STU 14
      SWAP
      SWAP
      STI 1
      SWAP
      SWAP
      STI 1
      ENDC
      SWAP
      STREF
      OVER
      INDEX 0
      PUSH s2
      INDEX 1
      PUSH s3
      INDEX 2
      PUSH s4
      INDEX 3
      PUSH s5
      INDEX 4
      PUSH s6
      INDEX 5
      PUSH s7
      INDEX 6
      XCHG s0, s8
      INDEX 7
      XCHG s7, s8
      XCHG s6, s7
      XCHG s5, s6
      XCHG s4, s5
      XCHG s3, s4
      XCHG3 s1, s3, s0
      XCHG2 s8, s7
      SWAP
      STU 40
      XCHG2 s0, s5
      STGRAMS
      XCHG2 s0, s3
      STGRAMS
      SWAP
      STGRAMS
      SWAP
      STGRAMS
      SWAP
      STGRAMS
      ROT
      STGRAMS
      SWAP
      STGRAMS
      XCHG s0, s2
      PUSHINT 267
      DICTSETB
    }>
    SETGLOB 14
    CALLDICT 185
    NEWC
    XCHG2 s4, s4
    XCHG2 s4, s3
    STSLICER
    SWAP
    STGRAMS
    ROT
    STGRAMS
    SWAP
    STSLICER
    PUSHINT 1207989464
    PUSHINT 0
    ROT
    CALLDICT 202
  }>
  213 => <{
    SAVECTR c2
    SAMEALTSAVE
    CALLDICT 52
    XCHG s0, s2
    LDREFRTOS
    NIP
    OVER
    IFJMP:<{
      PUSHINT 3406020527
      POP s3
      CALLDICT 201
    }>
    NIP
    PUSH3 s3, s2, s1
    PUSH s3
    PUSH c4
    PUSH c5
    PUSH c7
    CONT:<{
      NIP
      OVER
      DUP
      SBITS
      PUXC s1, s(-1)
      PLDSLICEX
      LDMSGADDR
      LDI 1
      SWAP
      SWAP
      LDGRAMS
      LDMSGADDR
      LDMSGADDR
      LDGRAMS
      LDU 1
      DROP
      IF:<{
        XCHG s0, s6
        PLDREFIDX 0
      }>ELSE<{
        POP s6
        PUSHNULL
      }>
      XCHG s5, s6
      XCHG s4, s5
      XCHG s3, s4
      XCHG3 s1, s3, s0
      XCHG s2, s5
      BLKDROP 5
      PUSHNULL
      XCHG3 s0, s0, s5
      PUSH2 s2, s1
      SWAP
      PUSHINT 267
      DICTGET
      NULLSWAPIFNOT
      NOT
      IF:<{
        DROP
        PUSHINT 0
        PUSH2 s0, s0
      }>ELSE<{
        LDI 1
        SWAP
        LSHIFT 1
        INC
        SWAP
        LDGRAMS
        XCHG s0, s2
        MUL
        SWAP
        LDI 1
        SWAP
        LSHIFT 1
        INC
        SWAP
        LDGRAMS
        XCHG s0, s2
        MUL
        XCHG s1, s2
        BLKDROP2 1, 2
        PUSHINT 1
      }>
      DROP
      XCHG s0, s2
      ADD
      SWAP
      NEWC
      ROTREV
      ROTREV
      DUP
      LESSINT 0
      XCHG s1, s2
      SWAP
      STI 1
      SWAP
      ABS
      STGRAMS
      SWAP
      DUP
      LESSINT 0
      XCHG s1, s2
      SWAP
      STI 1
      SWAP
      ABS
      STGRAMS
      XCHG s0, s2
      PUSHINT 267
      DICTSETB
      PUSH s5
      PUXC2 s5, s(-1), s2
      XCHG s0, s5
      CALLDICT 194
      PUSHINT 3406020527
      ROTREV
      CALLDICT 201
      RETALT
    }>
    SETCONTCTR c7
    SETCONTCTR c5
    SETCONTCTR c4
    PUSHINT 4
    PUSHINT -1
    SETCONTVARARGS
    CONT:<{
      LDMSGADDR
      LDI 1
      SWAP
      SWAP
      LDGRAMS
      LDMSGADDR
      LDMSGADDR
      LDGRAMS
      LDDICT
      BLKSWAP 7, 1
      GETGLOB 14
      PUSH s7
      CALL:<{
        SWAP
        PUSHINT 267
        DICTGET
        NULLSWAPIFNOT
        NOT
        IFJMP:<{
          DROP
          TUPLE 0
          PUSHINT 0
        }>
        LDREFRTOS
        LDMSGADDR
        LDMSGADDR
        LDREF
        LDU 14
        SWAP
        SWAP
        LDU 14
        SWAP
        SWAP
        LDI 1
        SWAP
        SWAP
        LDI 1
        SWAP
        NIP
        TUPLE 7
        UNTUPLE 7
        XCHG s0, s7
        LDU 40
        SWAP
        SWAP
        LDGRAMS
        LDGRAMS
        LDGRAMS
        LDGRAMS
        LDGRAMS
        LDGRAMS
        LDGRAMS
        BLKSWAP 8, 1
        TUPLE 8
        UNTUPLE 8
        TUPLE 0
        XCHG2 s0, s8
        TPUSH
        XCHG2 s0, s6
        TPUSH
        XCHG2 s0, s4
        TPUSH
        ROT
        TPUSH
        SWAP
        TPUSH
        SWAP
        TPUSH
        SWAP
        TPUSH
        SWAP
        TPUSH
        XCHG2 s0, s7
        TPUSH
        XCHG2 s0, s5
        TPUSH
        XCHG2 s0, s3
        TPUSH
        SWAP
        TPUSH
        SWAP
        TPUSH
        SWAP
        TPUSH
        ROT
        TPUSH
        NIP
        PUSHINT 1
      }>
      GETGLOB 5
      XCHG s1, s2
      CALL:<{
        NOW
        PUSH s2
        INDEX 7
        EQINT 0
        PUSH s3
        INDEX 1
        EQINT 0
        OR
        IFJMP:<{
          NIP
          PUSHINT 0
          SETINDEXVAR
        }>
        PUSH s2
        INDEX 0
        PUXC s1, s(-1)
        SUB
        DUP
        EQINT 0
        IFJMP:<{
          BLKDROP 3
        }>
        PUSH s3
        INDEX 1
        MUL
        PUSH s3
        INDEX 5
        PUSHINT 14551915228366851806640625
        LSHIFT 36
        MULDIV
        PUXC s0, s2
        PUSHINT 10000
        MULDIV
        XCPU s3, s2
        OVER
        INDEX 5
        SWAP
        ADD
        PUSHINT 5
        SETINDEXVAR
        XCPU s2, s3
        SUB
        XCHG s1, s2
        OVER
        INDEX 4
        SWAP
        ADD
        PUSHINT 4
        SETINDEXVAR
        ROT
        OVER
        INDEX 2
        SWAP
        ADD
        PUSHINT 2
        SETINDEXVAR
        SWAP
        PUSHINT 0
        SETINDEXVAR
      }>
      XCHG s0, s7
      IF:<{
        POP s5
        PUSH2 s8, s5
        DUP
        INDEX 6
        DUP
        EQINT 0
        IF:<{
          2DROP
        }>ELSE<{
          SWAP
          INDEX 4
          ROTREV
          MULDIV
        }>
      }>ELSE<{
        XCHG s0, s5
      }>
      PUSH s6
      INDEX 3
      OVER
      GEQ
      THROWIFNOT 1005
      XCHG s0, s5
      THROWIFNOT 1001
      XCPU s5, s8
      OVER
      INDEX 6
      SWAP
      SUB
      PUSHINT 6
      SETINDEXVAR
      PUSH s4
      OVER
      INDEX 4
      SWAP
      SUB
      PUSHINT 4
      SETINDEXVAR
      PUSH s4
      OVER
      INDEX 3
      SWAP
      SUB
      PUSHINT 3
      SETINDEXVAR
      DUP
      INDEX 8
      PUSH s11
      XCHG3 s5, s3, s4
      PUXCPU s6, s1, s1
      XCHG s0, s9
      CALLDICT 204
      PU2XC s7, s3, s1
      XCHG s0, s4
      CALLDICT 211
      GETGLOB 14
      PUXC s3, s1
      CALL:<{
        NEWC
        SWAP
        DUP
        INDEX 8
        OVER
        INDEX 9
        PUSH s2
        INDEX 10
        PUSH s3
        INDEX 11
        PUSH s4
        INDEX 12
        PUSH s5
        INDEX 13
        PUSH s6
        INDEX 14
        XCHG s7, s8
        NEWC
        XCHG2 s0, s7
        STSLICER
        XCHG2 s0, s5
        STSLICER
        XCHG s1, s3
        STREF
        SWAP
        SWAP
        STU 14
        SWAP
        SWAP
        STU 14
        SWAP
        SWAP
        STI 1
        SWAP
        SWAP
        STI 1
        ENDC
        SWAP
        STREF
        OVER
        INDEX 0
        PUSH s2
        INDEX 1
        PUSH s3
        INDEX 2
        PUSH s4
        INDEX 3
        PUSH s5
        INDEX 4
        PUSH s6
        INDEX 5
        PUSH s7
        INDEX 6
        XCHG s0, s8
        INDEX 7
        XCHG s7, s8
        XCHG s6, s7
        XCHG s5, s6
        XCHG s4, s5
        XCHG s3, s4
        XCHG3 s1, s3, s0
        XCHG2 s8, s7
        SWAP
        STU 40
        XCHG2 s0, s5
        STGRAMS
        XCHG2 s0, s3
        STGRAMS
        SWAP
        STGRAMS
        SWAP
        STGRAMS
        SWAP
        STGRAMS
        ROT
        STGRAMS
        SWAP
        STGRAMS
        XCHG s0, s2
        PUSHINT 267
        DICTSETB
      }>
      SETGLOB 14
      CALLDICT 185
      NEWC
      XCHG3 s1, s4, s4
      XCHG s0, s3
      XCHG2 s4, s3
      STSLICER
      SWAP
      STGRAMS
      ROT
      STGRAMS
      SWAP
      STSLICER
      PUSHINT 3406020527
      PUSHINT 0
      ROT
      CALLDICT 202
      RETALT
    }>
    PUSH c1
    BOOLOR
    SWAP
    TRY
  }>
  214 => <{
    SAVECTR c2
    SAMEALTSAVE
    CALLDICT 52
    XCHG s0, s2
    LDREFRTOS
    NIP
    OVER
    IFJMP:<{
      PUSHINT 3485616356
      POP s3
      CALLDICT 201
    }>
    NIP
    PUSH3 s3, s2, s1
    PUSH s3
    PUSH c4
    PUSH c5
    PUSH c7
    CONT:<{
      NIP
      OVER
      DUP
      SBITS
      PUXC s1, s(-1)
      PLDSLICEX
      LDMSGADDR
      LDI 1
      SWAP
      SWAP
      LDGRAMS
      LDMSGADDR
      LDMSGADDR
      LDGRAMS
      LDU 1
      DROP
      IF:<{
        XCHG s0, s6
        PLDREFIDX 0
      }>ELSE<{
        POP s6
        PUSHNULL
      }>
      XCHG s5, s6
      XCHG s4, s5
      XCHG s3, s4
      XCHG3 s1, s3, s0
      XCHG s2, s5
      BLKDROP 5
      PUSHINT -1
      PUSH s7
      XCPU s4, s7
      XCHG3 s4, s1, s4
      XCHG2 s7, s3
      CALLDICT 196
      PUSHINT 3485616356
      ROTREV
      CALLDICT 201
      RETALT
    }>
    SETCONTCTR c7
    SETCONTCTR c5
    SETCONTCTR c4
    PUSHINT 4
    PUSHINT -1
    SETCONTVARARGS
    CONT:<{
      LDMSGADDR
      LDI 1
      SWAP
      SWAP
      LDGRAMS
      LDMSGADDR
      LDMSGADDR
      LDGRAMS
      LDDICT
      BLKSWAP 7, 1
      GETGLOB 14
      PUSH s7
      CALL:<{
        SWAP
        PUSHINT 267
        DICTGET
        NULLSWAPIFNOT
        NOT
        IFJMP:<{
          DROP
          TUPLE 0
          PUSHINT 0
        }>
        LDREFRTOS
        LDMSGADDR
        LDMSGADDR
        LDREF
        LDU 14
        SWAP
        SWAP
        LDU 14
        SWAP
        SWAP
        LDI 1
        SWAP
        SWAP
        LDI 1
        SWAP
        NIP
        TUPLE 7
        UNTUPLE 7
        XCHG s0, s7
        LDU 40
        SWAP
        SWAP
        LDGRAMS
        LDGRAMS
        LDGRAMS
        LDGRAMS
        LDGRAMS
        LDGRAMS
        LDGRAMS
        BLKSWAP 8, 1
        TUPLE 8
        UNTUPLE 8
        TUPLE 0
        XCHG2 s0, s8
        TPUSH
        XCHG2 s0, s6
        TPUSH
        XCHG2 s0, s4
        TPUSH
        ROT
        TPUSH
        SWAP
        TPUSH
        SWAP
        TPUSH
        SWAP
        TPUSH
        SWAP
        TPUSH
        XCHG2 s0, s7
        TPUSH
        XCHG2 s0, s5
        TPUSH
        XCHG2 s0, s3
        TPUSH
        SWAP
        TPUSH
        SWAP
        TPUSH
        SWAP
        TPUSH
        ROT
        TPUSH
        NIP
        PUSHINT 1
      }>
      GETGLOB 5
      XCHG s1, s2
      CALL:<{
        NOW
        PUSH s2
        INDEX 7
        EQINT 0
        PUSH s3
        INDEX 1
        EQINT 0
        OR
        IFJMP:<{
          NIP
          PUSHINT 0
          SETINDEXVAR
        }>
        PUSH s2
        INDEX 0
        PUXC s1, s(-1)
        SUB
        DUP
        EQINT 0
        IFJMP:<{
          BLKDROP 3
        }>
        PUSH s3
        INDEX 1
        MUL
        PUSH s3
        INDEX 5
        PUSHINT 14551915228366851806640625
        LSHIFT 36
        MULDIV
        PUXC s0, s2
        PUSHINT 10000
        MULDIV
        XCPU s3, s2
        OVER
        INDEX 5
        SWAP
        ADD
        PUSHINT 5
        SETINDEXVAR
        XCPU s2, s3
        SUB
        XCHG s1, s2
        OVER
        INDEX 4
        SWAP
        ADD
        PUSHINT 4
        SETINDEXVAR
        ROT
        OVER
        INDEX 2
        SWAP
        ADD
        PUSHINT 2
        SETINDEXVAR
        SWAP
        PUSHINT 0
        SETINDEXVAR
      }>
      XCHG s0, s7
      IF:<{
        POP s5
        PUSH2 s8, s5
        DUP
        INDEX 7
        DUP
        EQINT 0
        IF:<{
          2DROP
        }>ELSE<{
          SWAP
          INDEX 5
          ROTREV
          MULDIV
        }>
      }>ELSE<{
        XCHG s0, s5
      }>
      XCHG s0, s5
      THROWIFNOT 1001
      PUSH s5
      INDEX 14
      THROWIFNOT 1012
      PUSH s5
      INDEX 3
      PUSH s5
      GEQ
      THROWIFNOT 1005
      XCPU s5, s8
      OVER
      INDEX 7
      SWAP
      ADD
      PUSHINT 7
      SETINDEXVAR
      PUSH s4
      OVER
      INDEX 5
      SWAP
      ADD
      PUSHINT 5
      SETINDEXVAR
      PUSH s4
      OVER
      INDEX 3
      SWAP
      SUB
      PUSHINT 3
      SETINDEXVAR
      DUP
      INDEX 8
      PUSH s11
      XCHG3 s5, s3, s4
      PUXCPU s6, s1, s1
      XCHG s0, s9
      CALLDICT 204
      PUSH3 s7, s3, s2
      CALLDICT 211
      GETGLOB 14
      PUXC s4, s1
      CALL:<{
        NEWC
        SWAP
        DUP
        INDEX 8
        OVER
        INDEX 9
        PUSH s2
        INDEX 10
        PUSH s3
        INDEX 11
        PUSH s4
        INDEX 12
        PUSH s5
        INDEX 13
        PUSH s6
        INDEX 14
        XCHG s7, s8
        NEWC
        XCHG2 s0, s7
        STSLICER
        XCHG2 s0, s5
        STSLICER
        XCHG s1, s3
        STREF
        SWAP
        SWAP
        STU 14
        SWAP
        SWAP
        STU 14
        SWAP
        SWAP
        STI 1
        SWAP
        SWAP
        STI 1
        ENDC
        SWAP
        STREF
        OVER
        INDEX 0
        PUSH s2
        INDEX 1
        PUSH s3
        INDEX 2
        PUSH s4
        INDEX 3
        PUSH s5
        INDEX 4
        PUSH s6
        INDEX 5
        PUSH s7
        INDEX 6
        XCHG s0, s8
        INDEX 7
        XCHG s7, s8
        XCHG s6, s7
        XCHG s5, s6
        XCHG s4, s5
        XCHG s3, s4
        XCHG3 s1, s3, s0
        XCHG2 s8, s7
        SWAP
        STU 40
        XCHG2 s0, s5
        STGRAMS
        XCHG2 s0, s3
        STGRAMS
        SWAP
        STGRAMS
        SWAP
        STGRAMS
        SWAP
        STGRAMS
        ROT
        STGRAMS
        SWAP
        STGRAMS
        XCHG s0, s2
        PUSHINT 267
        DICTSETB
      }>
      SETGLOB 14
      CALLDICT 185
      PUSHINT 0
      PUSH s7
      PUXC2 s7, s(-1), s2
      PU2XC s5, s7, s4
      CALLDICT 196
      NEWC
      XCHG3 s1, s4, s4
      XCHG s0, s3
      XCHG2 s4, s3
      STSLICER
      SWAP
      STGRAMS
      ROT
      STGRAMS
      SWAP
      STSLICER
      PUSHINT 3485616356
      PUSHINT 0
      ROT
      CALLDICT 202
      RETALT
    }>
    PUSH c1
    BOOLOR
    SWAP
    TRY
  }>
  215 => <{
    CALLDICT 52
    XCHG s0, s2
    LDMSGADDR
    LDMSGADDR
    LDGRAMS
    BLKSWAP 3, 1
    XCHG s0, s3
    LDREFRTOS
    NIP
    LDMSGADDR
    LDGRAMS
    LDDICT
    GETGLOB 14
    PUSH s5
    CALL:<{
      SWAP
      PUSHINT 267
      DICTGET
      NULLSWAPIFNOT
      NOT
      IFJMP:<{
        DROP
        TUPLE 0
        PUSHINT 0
      }>
      LDREFRTOS
      LDMSGADDR
      LDMSGADDR
      LDREF
      LDU 14
      SWAP
      SWAP
      LDU 14
      SWAP
      SWAP
      LDI 1
      SWAP
      SWAP
      LDI 1
      SWAP
      NIP
      TUPLE 7
      UNTUPLE 7
      XCHG s0, s7
      LDU 40
      SWAP
      SWAP
      LDGRAMS
      LDGRAMS
      LDGRAMS
      LDGRAMS
      LDGRAMS
      LDGRAMS
      LDGRAMS
      BLKSWAP 8, 1
      TUPLE 8
      UNTUPLE 8
      TUPLE 0
      XCHG2 s0, s8
      TPUSH
      XCHG2 s0, s6
      TPUSH
      XCHG2 s0, s4
      TPUSH
      ROT
      TPUSH
      SWAP
      TPUSH
      SWAP
      TPUSH
      SWAP
      TPUSH
      SWAP
      TPUSH
      XCHG2 s0, s7
      TPUSH
      XCHG2 s0, s5
      TPUSH
      XCHG2 s0, s3
      TPUSH
      SWAP
      TPUSH
      SWAP
      TPUSH
      SWAP
      TPUSH
      ROT
      TPUSH
      NIP
      PUSHINT 1
    }>
    DROP
    PUSH s8
    IFJMP:<{
      POP s9
      XCHG s0, s8
      INDEX 8
      PU2XC s10, s5, s(-1)
      PUSH3 s5, s8, s4
      PUSH s6
      CALLDICT 204
      NEWC
      XCHG s0, s7
      PUSHINT 3998571052
      XCHG s0, s7
      XCPU s6, s0
      XCHG s0, s6
      XCHG s5, s11
      XCHG s0, s4
      XCHG s3, s11
      XCHG3 s10, s0, s11
      NEWC
      XCHG s0, s6
      XCHG s0, s5
      XCHG s4, s9
      XCHG s0, s3
      XCHG3 s9, s9, s9
      XCHG2 s6, s5
      STSLICER
      XCHG2 s0, s3
      SWAP
      STU 32
      SWAP
      STSLICER
      SWAP
      STSLICER
      ROT
      STGRAMS
      STDICT
      XCHG2 s0, s3
      STSLICER
      ENDC
      XCHG2 s3, s3
      STGRAMS
      SWAP
      STSLICER
      STREF
      PUSHINT 1935855772
      ROTREV
      CALLDICT 202
    }>
    POP s8
    GETGLOB 5
    XCHG s1, s8
    CALL:<{
      NOW
      PUSH s2
      INDEX 7
      EQINT 0
      PUSH s3
      INDEX 1
      EQINT 0
      OR
      IFJMP:<{
        NIP
        PUSHINT 0
        SETINDEXVAR
      }>
      PUSH s2
      INDEX 0
      PUXC s1, s(-1)
      SUB
      DUP
      EQINT 0
      IFJMP:<{
        BLKDROP 3
      }>
      PUSH s3
      INDEX 1
      MUL
      PUSH s3
      INDEX 5
      PUSHINT 14551915228366851806640625
      LSHIFT 36
      MULDIV
      PUXC s0, s2
      PUSHINT 10000
      MULDIV
      XCPU s3, s2
      OVER
      INDEX 5
      SWAP
      ADD
      PUSHINT 5
      SETINDEXVAR
      XCPU s2, s3
      SUB
      XCHG s1, s2
      OVER
      INDEX 4
      SWAP
      ADD
      PUSHINT 4
      SETINDEXVAR
      ROT
      OVER
      INDEX 2
      SWAP
      ADD
      PUSHINT 2
      SETINDEXVAR
      SWAP
      PUSHINT 0
      SETINDEXVAR
    }>
    PUSHINT 0
    PUSH2 s9, s1
    DUP
    INDEX 7
    DUP
    EQINT 0
    IF:<{
      2DROP
    }>ELSE<{
      SWAP
      INDEX 5
      ROTREV
      MULDIV
    }>
    PUSH2 s0, s8
    LESS
    IF:<{
      NIP
      POP s10
      XCPU s6, s9
      SUB
      PUSH s6
      INDEX 8
      PUSH s11
      PUXC2 s7, s3, s2
      PUSH s6
      PUXC2 s1, s2, s6
      SWAP
      CALLDICT 204
    }>ELSE<{
      POP s3
      POP s3
      PUSH2 s1, s6
      GREATER
      IF:<{
        XCPU s1, s6
        SUB
        OVER
        DUP
        INDEX 5
        DUP
        EQINT 0
        IF:<{
          2DROP
        }>ELSE<{
          SWAP
          INDEX 7
          ROTREV
          MULDIV
        }>
        XCPU s8, s8
        SUB
        PUSHNULL
        XCPUXC s0, s5, s9
        PUSH2 s2, s1
        SWAP
        PUSHINT 267
        DICTGET
        NULLSWAPIFNOT
        NOT
        IF:<{
          DROP
          PUSHINT 0
          PUSH2 s0, s0
        }>ELSE<{
          LDI 1
          SWAP
          LSHIFT 1
          INC
          SWAP
          LDGRAMS
          XCHG s0, s2
          MUL
          SWAP
          LDI 1
          SWAP
          LSHIFT 1
          INC
          SWAP
          LDGRAMS
          XCHG s0, s2
          MUL
          XCHG s1, s2
          BLKDROP2 1, 2
          PUSHINT 1
        }>
        DROP
        ROT
        ADD
        NEWC
        ROTREV
        ROTREV
        DUP
        LESSINT 0
        XCHG s1, s2
        SWAP
        STI 1
        SWAP
        ABS
        STGRAMS
        SWAP
        DUP
        LESSINT 0
        XCHG s1, s2
        SWAP
        STI 1
        SWAP
        ABS
        STGRAMS
        XCHG s0, s2
        PUSHINT 267
        DICTSETB
        PUXC2 s10, s9, s9
        PUSH s4
        CALLDICT 194
        XCHG s4, s7
      }>ELSE<{
        POP s6
        POP s8
      }>
    }>
    XCPU s4, s7
    OVER
    INDEX 5
    SWAP
    SUB
    PUSHINT 5
    SETINDEXVAR
    PUSH s6
    OVER
    INDEX 7
    SWAP
    SUB
    PUSHINT 7
    SETINDEXVAR
    PUSH s7
    OVER
    INDEX 3
    SWAP
    ADD
    PUSHINT 3
    SETINDEXVAR
    PU2XC s8, s2, s1
    CALLDICT 211
    GETGLOB 14
    PUXC s2, s1
    CALL:<{
      NEWC
      SWAP
      DUP
      INDEX 8
      OVER
      INDEX 9
      PUSH s2
      INDEX 10
      PUSH s3
      INDEX 11
      PUSH s4
      INDEX 12
      PUSH s5
      INDEX 13
      PUSH s6
      INDEX 14
      XCHG s7, s8
      NEWC
      XCHG2 s0, s7
      STSLICER
      XCHG2 s0, s5
      STSLICER
      XCHG s1, s3
      STREF
      SWAP
      SWAP
      STU 14
      SWAP
      SWAP
      STU 14
      SWAP
      SWAP
      STI 1
      SWAP
      SWAP
      STI 1
      ENDC
      SWAP
      STREF
      OVER
      INDEX 0
      PUSH s2
      INDEX 1
      PUSH s3
      INDEX 2
      PUSH s4
      INDEX 3
      PUSH s5
      INDEX 4
      PUSH s6
      INDEX 5
      PUSH s7
      INDEX 6
      XCHG s0, s8
      INDEX 7
      XCHG s7, s8
      XCHG s6, s7
      XCHG s5, s6
      XCHG s4, s5
      XCHG s3, s4
      XCHG3 s1, s3, s0
      XCHG2 s8, s7
      SWAP
      STU 40
      XCHG2 s0, s5
      STGRAMS
      XCHG2 s0, s3
      STGRAMS
      SWAP
      STGRAMS
      SWAP
      STGRAMS
      SWAP
      STGRAMS
      ROT
      STGRAMS
      SWAP
      STGRAMS
      XCHG s0, s2
      PUSHINT 267
      DICTSETB
    }>
    SETGLOB 14
    CALLDICT 185
    NEWC
    XCHG2 s4, s5
    XCHG s3, s6
    XCHG3 s0, s6, s6
    XCHG2 s5, s4
    STSLICER
    ROT
    STGRAMS
    SWAP
    STGRAMS
    ROT
    STGRAMS
    SWAP
    STSLICER
    PUSHINT 3998571052
    PUSHINT 0
    ROT
    CALLDICT 202
  }>
  216 => <{
    CALLDICT 53
    XCHG s0, s3
    LDMSGADDR
    LDMSGADDR
    LDGRAMS
    BLKSWAP 3, 1
    XCHG s0, s3
    LDREFRTOS
    NIP
    LDMSGADDR
    LDGRAMS
    LDDICT
    LDMSGADDR
    GETGLOB 14
    PUSH s6
    CALL:<{
      SWAP
      PUSHINT 267
      DICTGET
      NULLSWAPIFNOT
      NOT
      IFJMP:<{
        DROP
        TUPLE 0
        PUSHINT 0
      }>
      LDREFRTOS
      LDMSGADDR
      LDMSGADDR
      LDREF
      LDU 14
      SWAP
      SWAP
      LDU 14
      SWAP
      SWAP
      LDI 1
      SWAP
      SWAP
      LDI 1
      SWAP
      NIP
      TUPLE 7
      UNTUPLE 7
      XCHG s0, s7
      LDU 40
      SWAP
      SWAP
      LDGRAMS
      LDGRAMS
      LDGRAMS
      LDGRAMS
      LDGRAMS
      LDGRAMS
      LDGRAMS
      BLKSWAP 8, 1
      TUPLE 8
      UNTUPLE 8
      TUPLE 0
      XCHG2 s0, s8
      TPUSH
      XCHG2 s0, s6
      TPUSH
      XCHG2 s0, s4
      TPUSH
      ROT
      TPUSH
      SWAP
      TPUSH
      SWAP
      TPUSH
      SWAP
      TPUSH
      SWAP
      TPUSH
      XCHG2 s0, s7
      TPUSH
      XCHG2 s0, s5
      TPUSH
      XCHG2 s0, s3
      TPUSH
      SWAP
      TPUSH
      SWAP
      TPUSH
      SWAP
      TPUSH
      ROT
      TPUSH
      NIP
      PUSHINT 1
    }>
    DROP
    GETGLOB 14
    PUSH s3
    CALL:<{
      SWAP
      PUSHINT 267
      DICTGET
      NULLSWAPIFNOT
      NOT
      IFJMP:<{
        DROP
        TUPLE 0
        PUSHINT 0
      }>
      LDREFRTOS
      LDMSGADDR
      LDMSGADDR
      LDREF
      LDU 14
      SWAP
      SWAP
      LDU 14
      SWAP
      SWAP
      LDI 1
      SWAP
      SWAP
      LDI 1
      SWAP
      NIP
      TUPLE 7
      UNTUPLE 7
      XCHG s0, s7
      LDU 40
      SWAP
      SWAP
      LDGRAMS
      LDGRAMS
      LDGRAMS
      LDGRAMS
      LDGRAMS
      LDGRAMS
      LDGRAMS
      BLKSWAP 8, 1
      TUPLE 8
      UNTUPLE 8
      TUPLE 0
      XCHG2 s0, s8
      TPUSH
      XCHG2 s0, s6
      TPUSH
      XCHG2 s0, s4
      TPUSH
      ROT
      TPUSH
      SWAP
      TPUSH
      SWAP
      TPUSH
      SWAP
      TPUSH
      SWAP
      TPUSH
      XCHG2 s0, s7
      TPUSH
      XCHG2 s0, s5
      TPUSH
      XCHG2 s0, s3
      TPUSH
      SWAP
      TPUSH
      SWAP
      TPUSH
      SWAP
      TPUSH
      ROT
      TPUSH
      NIP
      PUSHINT 1
    }>
    DROP
    PUSH s11
    IFJMP:<{
      DROP
      POP s9
      POP s10
      XCHG s0, s7
      INDEX 8
      PU2XC s11, s5, s(-1)
      PUSH3 s5, s8, s4
      PUSH s6
      CALLDICT 204
      NEWC
      XCHG2 s0, s7
      STSLICER
      XCHG2 s0, s8
      STSLICER
      ENDC
      NEWC
      STREF
      NEWC
      XCHG s0, s7
      PUSHINT 3427973859
      XCPU s7, s5
      XCHG s5, s11
      XCHG s4, s11
      XCHG s3, s11
      XCHG3 s11, s10, s10
      NEWC
      XCHG s0, s6
      XCHG s0, s5
      XCHG s4, s9
      XCHG s0, s3
      XCHG3 s9, s9, s9
      XCHG2 s6, s5
      STSLICER
      XCHG2 s0, s3
      SWAP
      STU 32
      SWAP
      STSLICER
      SWAP
      STSLICER
      ROT
      STGRAMS
      STDICT
      XCHG2 s0, s3
      STBR
      ENDC
      XCHG2 s3, s3
      STGRAMS
      SWAP
      STSLICER
      STREF
      XCHG s1, s2
      PUSHINT 1935855772
      ROTREV
      CALLDICT 202
    }>
    POP s4
    POP s4
    POP s9
    GETGLOB 5
    XCHG s1, s3
    CALL:<{
      NOW
      PUSH s2
      INDEX 7
      EQINT 0
      PUSH s3
      INDEX 1
      EQINT 0
      OR
      IFJMP:<{
        NIP
        PUSHINT 0
        SETINDEXVAR
      }>
      PUSH s2
      INDEX 0
      PUXC s1, s(-1)
      SUB
      DUP
      EQINT 0
      IFJMP:<{
        BLKDROP 3
      }>
      PUSH s3
      INDEX 1
      MUL
      PUSH s3
      INDEX 5
      PUSHINT 14551915228366851806640625
      LSHIFT 36
      MULDIV
      PUXC s0, s2
      PUSHINT 10000
      MULDIV
      XCPU s3, s2
      OVER
      INDEX 5
      SWAP
      ADD
      PUSHINT 5
      SETINDEXVAR
      XCPU s2, s3
      SUB
      XCHG s1, s2
      OVER
      INDEX 4
      SWAP
      ADD
      PUSHINT 4
      SETINDEXVAR
      ROT
      OVER
      INDEX 2
      SWAP
      ADD
      PUSHINT 2
      SETINDEXVAR
      SWAP
      PUSHINT 0
      SETINDEXVAR
    }>
    GETGLOB 5
    XCHG s1, s2
    CALL:<{
      NOW
      PUSH s2
      INDEX 7
      EQINT 0
      PUSH s3
      INDEX 1
      EQINT 0
      OR
      IFJMP:<{
        NIP
        PUSHINT 0
        SETINDEXVAR
      }>
      PUSH s2
      INDEX 0
      PUXC s1, s(-1)
      SUB
      DUP
      EQINT 0
      IFJMP:<{
        BLKDROP 3
      }>
      PUSH s3
      INDEX 1
      MUL
      PUSH s3
      INDEX 5
      PUSHINT 14551915228366851806640625
      LSHIFT 36
      MULDIV
      PUXC s0, s2
      PUSHINT 10000
      MULDIV
      XCPU s3, s2
      OVER
      INDEX 5
      SWAP
      ADD
      PUSHINT 5
      SETINDEXVAR
      XCPU s2, s3
      SUB
      XCHG s1, s2
      OVER
      INDEX 4
      SWAP
      ADD
      PUSHINT 4
      SETINDEXVAR
      ROT
      OVER
      INDEX 2
      SWAP
      ADD
      PUSHINT 2
      SETINDEXVAR
      SWAP
      PUSHINT 0
      SETINDEXVAR
    }>
    PUSH2 s7, s1
    DUP
    INDEX 7
    DUP
    EQINT 0
    IF:<{
      2DROP
    }>ELSE<{
      SWAP
      INDEX 5
      ROTREV
      MULDIV
    }>
    PUSH2 s0, s7
    GREATER
    IF:<{
      PUSH s7
      SUB
      PUSH s2
      DUP
      INDEX 5
      DUP
      EQINT 0
      IF:<{
        2DROP
      }>ELSE<{
        SWAP
        INDEX 7
        ROTREV
        MULDIV
      }>
      XCPU s8, s8
      SUB
      PUSHNULL
      XCPUXC s0, s6, s9
      PUSH2 s2, s1
      SWAP
      PUSHINT 267
      DICTGET
      NULLSWAPIFNOT
      NOT
      IF:<{
        DROP
        PUSHINT 0
        PUSH2 s0, s0
      }>ELSE<{
        LDI 1
        SWAP
        LSHIFT 1
        INC
        SWAP
        LDGRAMS
        XCHG s0, s2
        MUL
        SWAP
        LDI 1
        SWAP
        LSHIFT 1
        INC
        SWAP
        LDGRAMS
        XCHG s0, s2
        MUL
        XCHG s1, s2
        BLKDROP2 1, 2
        PUSHINT 1
      }>
      DROP
      ROT
      ADD
      NEWC
      ROTREV
      ROTREV
      DUP
      LESSINT 0
      XCHG s1, s2
      SWAP
      STI 1
      SWAP
      ABS
      STGRAMS
      SWAP
      DUP
      LESSINT 0
      XCHG s1, s2
      SWAP
      STI 1
      SWAP
      ABS
      STGRAMS
      XCHG s0, s2
      PUSHINT 267
      DICTSETB
      PU2XC s12, s11, s(-2)
      PUSH s6
      CALLDICT 194
    }>ELSE<{
      POP s7
    }>
    XCPU s1, s7
    OVER
    INDEX 7
    SWAP
    SUB
    PUSHINT 7
    SETINDEXVAR
    PUSH s6
    OVER
    INDEX 5
    SWAP
    SUB
    PUSHINT 5
    SETINDEXVAR
    PUSH s6
    OVER
    INDEX 3
    SWAP
    ADD
    PUSHINT 3
    SETINDEXVAR
    PUSHNULL
    PUSH2 s3, s10
    PUSH2 s2, s1
    SWAP
    PUSHINT 267
    DICTGET
    NULLSWAPIFNOT
    NOT
    IF:<{
      DROP
      PUSHINT 0
      PUSH2 s0, s0
    }>ELSE<{
      LDI 1
      SWAP
      LSHIFT 1
      INC
      SWAP
      LDGRAMS
      XCHG s0, s2
      MUL
      SWAP
      LDI 1
      SWAP
      LSHIFT 1
      INC
      SWAP
      LDGRAMS
      XCHG s0, s2
      MUL
      XCHG s1, s2
      BLKDROP2 1, 2
      PUSHINT 1
    }>
    DROP
    XCHG s0, s2
    ADD
    SWAP
    NEWC
    ROTREV
    ROTREV
    DUP
    LESSINT 0
    XCHG s1, s2
    SWAP
    STI 1
    SWAP
    ABS
    STGRAMS
    SWAP
    DUP
    LESSINT 0
    XCHG s1, s2
    SWAP
    STI 1
    SWAP
    ABS
    STGRAMS
    XCHG s0, s2
    PUSHINT 267
    DICTSETB
    PU2XC s12, s6, s(-2)
    PUSH s6
    CALLDICT 195
    PUSHNULL
    PUXC2 s12, s11, s(-1)
    PU2XC s5, s6, s(-2)
    PU2XC s6, s11, s(-2)
    PUXC s15, s(-1)
    XCHG s0, s17
    CALLDICT 200
    XCPU2 s9, s10, s3
    PUSH s4
    CALLDICT 211
    XCPUXC s9, s10, s(-1)
    PUXC s10, s3
    CALLDICT 211
    GETGLOB 14
    XCPUXC s0, s3, s2
    CALL:<{
      NEWC
      SWAP
      DUP
      INDEX 8
      OVER
      INDEX 9
      PUSH s2
      INDEX 10
      PUSH s3
      INDEX 11
      PUSH s4
      INDEX 12
      PUSH s5
      INDEX 13
      PUSH s6
      INDEX 14
      XCHG s7, s8
      NEWC
      XCHG2 s0, s7
      STSLICER
      XCHG2 s0, s5
      STSLICER
      XCHG s1, s3
      STREF
      SWAP
      SWAP
      STU 14
      SWAP
      SWAP
      STU 14
      SWAP
      SWAP
      STI 1
      SWAP
      SWAP
      STI 1
      ENDC
      SWAP
      STREF
      OVER
      INDEX 0
      PUSH s2
      INDEX 1
      PUSH s3
      INDEX 2
      PUSH s4
      INDEX 3
      PUSH s5
      INDEX 4
      PUSH s6
      INDEX 5
      PUSH s7
      INDEX 6
      XCHG s0, s8
      INDEX 7
      XCHG s7, s8
      XCHG s6, s7
      XCHG s5, s6
      XCHG s4, s5
      XCHG s3, s4
      XCHG3 s1, s3, s0
      XCHG2 s8, s7
      SWAP
      STU 40
      XCHG2 s0, s5
      STGRAMS
      XCHG2 s0, s3
      STGRAMS
      SWAP
      STGRAMS
      SWAP
      STGRAMS
      SWAP
      STGRAMS
      ROT
      STGRAMS
      SWAP
      STGRAMS
      XCHG s0, s2
      PUSHINT 267
      DICTSETB
    }>
    SETGLOB 14
    GETGLOB 14
    PUXC s8, s1
    CALL:<{
      NEWC
      SWAP
      DUP
      INDEX 8
      OVER
      INDEX 9
      PUSH s2
      INDEX 10
      PUSH s3
      INDEX 11
      PUSH s4
      INDEX 12
      PUSH s5
      INDEX 13
      PUSH s6
      INDEX 14
      XCHG s7, s8
      NEWC
      XCHG2 s0, s7
      STSLICER
      XCHG2 s0, s5
      STSLICER
      XCHG s1, s3
      STREF
      SWAP
      SWAP
      STU 14
      SWAP
      SWAP
      STU 14
      SWAP
      SWAP
      STI 1
      SWAP
      SWAP
      STI 1
      ENDC
      SWAP
      STREF
      OVER
      INDEX 0
      PUSH s2
      INDEX 1
      PUSH s3
      INDEX 2
      PUSH s4
      INDEX 3
      PUSH s5
      INDEX 4
      PUSH s6
      INDEX 5
      PUSH s7
      INDEX 6
      XCHG s0, s8
      INDEX 7
      XCHG s7, s8
      XCHG s6, s7
      XCHG s5, s6
      XCHG s4, s5
      XCHG s3, s4
      XCHG3 s1, s3, s0
      XCHG2 s8, s7
      SWAP
      STU 40
      XCHG2 s0, s5
      STGRAMS
      XCHG2 s0, s3
      STGRAMS
      SWAP
      STGRAMS
      SWAP
      STGRAMS
      SWAP
      STGRAMS
      ROT
      STGRAMS
      SWAP
      STGRAMS
      XCHG s0, s2
      PUSHINT 267
      DICTSETB
    }>
    SETGLOB 14
    CALLDICT 185
    NEWC
    XCHG2 s5, s6
    XCHG s4, s7
    XCHG3 s7, s0, s0
    XCHG2 s6, s5
    STSLICER
    XCHG2 s0, s3
    STSLICER
    SWAP
    STGRAMS
    SWAP
    STGRAMS
    ROT
    STGRAMS
    SWAP
    STSLICER
    PUSHINT 3427973859
    PUSHINT 0
    ROT
    CALLDICT 202
  }>
  217 => <{
    SAVECTR c2
    SAMEALTSAVE
    GETGLOB 3
    XCHG s1, s2
    SDEQ
    IF:<{
      PUSH s2
      PUSHINT 4250682550
      EQUAL
      IFJMP:<{
        BLKDROP2 2, 1
        LDMSGADDR
        LDREF
        DROP
        GETGLOB 14
        PUSH s2
        CALL:<{
          SWAP
          PUSHINT 267
          DICTGET
          NULLSWAPIFNOT
          NOT
          IFJMP:<{
            DROP
            TUPLE 0
            PUSHINT 0
          }>
          LDREFRTOS
          LDMSGADDR
          LDMSGADDR
          LDREF
          LDU 14
          SWAP
          SWAP
          LDU 14
          SWAP
          SWAP
          LDI 1
          SWAP
          SWAP
          LDI 1
          SWAP
          NIP
          TUPLE 7
          UNTUPLE 7
          XCHG s0, s7
          LDU 40
          SWAP
          SWAP
          LDGRAMS
          LDGRAMS
          LDGRAMS
          LDGRAMS
          LDGRAMS
          LDGRAMS
          LDGRAMS
          BLKSWAP 8, 1
          TUPLE 8
          UNTUPLE 8
          TUPLE 0
          XCHG2 s0, s8
          TPUSH
          XCHG2 s0, s6
          TPUSH
          XCHG2 s0, s4
          TPUSH
          ROT
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          XCHG2 s0, s7
          TPUSH
          XCHG2 s0, s5
          TPUSH
          XCHG2 s0, s3
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          ROT
          TPUSH
          NIP
          PUSHINT 1
        }>
        DROP
        DUP
        INDEX 8
        PLDU 2
        EQINT 0
        IF:<{
          OVER
          CTOS
          LDGRAMS
          NIP
          LDU 14
          SWAP
          SWAP
          LDU 14
          SWAP
          NIP
          PUSHINT 3000
          PUSH s2
          GTINT 99
          PUSH s3
          AND
          PUSHINT 9900
          LEQ
          THROWANYIFNOT
          PUSHINT 3000
          OVER
          GTINT 99
          PUSH s2
          AND
          PUSHINT 9900
          LEQ
          THROWANYIFNOT
          PUSHINT 3000
          XCHG s0, s2
          GEQ
          THROWANYIFNOT
        }>
        SWAP
        PUSHINT 10
        SETINDEXVAR
        GETGLOB 14
        ROTREV
        CALL:<{
          NEWC
          SWAP
          DUP
          INDEX 8
          OVER
          INDEX 9
          PUSH s2
          INDEX 10
          PUSH s3
          INDEX 11
          PUSH s4
          INDEX 12
          PUSH s5
          INDEX 13
          PUSH s6
          INDEX 14
          XCHG s7, s8
          NEWC
          XCHG2 s0, s7
          STSLICER
          XCHG2 s0, s5
          STSLICER
          XCHG s1, s3
          STREF
          SWAP
          SWAP
          STU 14
          SWAP
          SWAP
          STU 14
          SWAP
          SWAP
          STI 1
          SWAP
          SWAP
          STI 1
          ENDC
          SWAP
          STREF
          OVER
          INDEX 0
          PUSH s2
          INDEX 1
          PUSH s3
          INDEX 2
          PUSH s4
          INDEX 3
          PUSH s5
          INDEX 4
          PUSH s6
          INDEX 5
          PUSH s7
          INDEX 6
          XCHG s0, s8
          INDEX 7
          XCHG s7, s8
          XCHG s6, s7
          XCHG s5, s6
          XCHG s4, s5
          XCHG s3, s4
          XCHG3 s1, s3, s0
          XCHG2 s8, s7
          SWAP
          STU 40
          XCHG2 s0, s5
          STGRAMS
          XCHG2 s0, s3
          STGRAMS
          SWAP
          STGRAMS
          SWAP
          STGRAMS
          SWAP
          STGRAMS
          ROT
          STGRAMS
          SWAP
          STGRAMS
          XCHG s0, s2
          PUSHINT 267
          DICTSETB
        }>
        SETGLOB 14
        CALLDICT 185
        CONT:<{
          PUSH c4
          PUSH c5
          PUSH c7
          CONT:<{
            2DROP
            THROW 1024
          }>
          SETCONTCTR c7
          SETCONTCTR c5
          SETCONTCTR c4
          CONT:<{
            CALLDICT 184
          }>
          PUSH c1
          BOOLOR
          SWAP
          TRY
        }>
        CALLXARGS 0, -1
        PUSHINT -1
        RETALT
      }>
      PUSH s2
      PUSHINT 1485769650
      EQUAL
      IFJMP:<{
        BLKDROP2 2, 1
        LDMSGADDR
        LDU 14
        SWAP
        NIP
        GETGLOB 14
        PUSH s2
        CALL:<{
          SWAP
          PUSHINT 267
          DICTGET
          NULLSWAPIFNOT
          NOT
          IFJMP:<{
            DROP
            TUPLE 0
            PUSHINT 0
          }>
          LDREFRTOS
          LDMSGADDR
          LDMSGADDR
          LDREF
          LDU 14
          SWAP
          SWAP
          LDU 14
          SWAP
          SWAP
          LDI 1
          SWAP
          SWAP
          LDI 1
          SWAP
          NIP
          TUPLE 7
          UNTUPLE 7
          XCHG s0, s7
          LDU 40
          SWAP
          SWAP
          LDGRAMS
          LDGRAMS
          LDGRAMS
          LDGRAMS
          LDGRAMS
          LDGRAMS
          LDGRAMS
          BLKSWAP 8, 1
          TUPLE 8
          UNTUPLE 8
          TUPLE 0
          XCHG2 s0, s8
          TPUSH
          XCHG2 s0, s6
          TPUSH
          XCHG2 s0, s4
          TPUSH
          ROT
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          XCHG2 s0, s7
          TPUSH
          XCHG2 s0, s5
          TPUSH
          XCHG2 s0, s3
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          ROT
          TPUSH
          NIP
          PUSHINT 1
        }>
        DROP
        SWAP
        PUSHINT 11
        SETINDEXVAR
        GETGLOB 14
        ROTREV
        CALL:<{
          NEWC
          SWAP
          DUP
          INDEX 8
          OVER
          INDEX 9
          PUSH s2
          INDEX 10
          PUSH s3
          INDEX 11
          PUSH s4
          INDEX 12
          PUSH s5
          INDEX 13
          PUSH s6
          INDEX 14
          XCHG s7, s8
          NEWC
          XCHG2 s0, s7
          STSLICER
          XCHG2 s0, s5
          STSLICER
          XCHG s1, s3
          STREF
          SWAP
          SWAP
          STU 14
          SWAP
          SWAP
          STU 14
          SWAP
          SWAP
          STI 1
          SWAP
          SWAP
          STI 1
          ENDC
          SWAP
          STREF
          OVER
          INDEX 0
          PUSH s2
          INDEX 1
          PUSH s3
          INDEX 2
          PUSH s4
          INDEX 3
          PUSH s5
          INDEX 4
          PUSH s6
          INDEX 5
          PUSH s7
          INDEX 6
          XCHG s0, s8
          INDEX 7
          XCHG s7, s8
          XCHG s6, s7
          XCHG s5, s6
          XCHG s4, s5
          XCHG s3, s4
          XCHG3 s1, s3, s0
          XCHG2 s8, s7
          SWAP
          STU 40
          XCHG2 s0, s5
          STGRAMS
          XCHG2 s0, s3
          STGRAMS
          SWAP
          STGRAMS
          SWAP
          STGRAMS
          SWAP
          STGRAMS
          ROT
          STGRAMS
          SWAP
          STGRAMS
          XCHG s0, s2
          PUSHINT 267
          DICTSETB
        }>
        SETGLOB 14
        CALLDICT 185
        CONT:<{
          PUSH c4
          PUSH c5
          PUSH c7
          CONT:<{
            2DROP
            THROW 1024
          }>
          SETCONTCTR c7
          SETCONTCTR c5
          SETCONTCTR c4
          CONT:<{
            CALLDICT 184
          }>
          PUSH c1
          BOOLOR
          SWAP
          TRY
        }>
        CALLXARGS 0, -1
        PUSHINT -1
        RETALT
      }>
      PUSH s2
      PUSHINT 3304866359
      EQUAL
      IFJMP:<{
        BLKDROP2 2, 1
        LDMSGADDR
        LDU 14
        SWAP
        NIP
        GETGLOB 14
        PUSH s2
        CALL:<{
          SWAP
          PUSHINT 267
          DICTGET
          NULLSWAPIFNOT
          NOT
          IFJMP:<{
            DROP
            TUPLE 0
            PUSHINT 0
          }>
          LDREFRTOS
          LDMSGADDR
          LDMSGADDR
          LDREF
          LDU 14
          SWAP
          SWAP
          LDU 14
          SWAP
          SWAP
          LDI 1
          SWAP
          SWAP
          LDI 1
          SWAP
          NIP
          TUPLE 7
          UNTUPLE 7
          XCHG s0, s7
          LDU 40
          SWAP
          SWAP
          LDGRAMS
          LDGRAMS
          LDGRAMS
          LDGRAMS
          LDGRAMS
          LDGRAMS
          LDGRAMS
          BLKSWAP 8, 1
          TUPLE 8
          UNTUPLE 8
          TUPLE 0
          XCHG2 s0, s8
          TPUSH
          XCHG2 s0, s6
          TPUSH
          XCHG2 s0, s4
          TPUSH
          ROT
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          XCHG2 s0, s7
          TPUSH
          XCHG2 s0, s5
          TPUSH
          XCHG2 s0, s3
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          ROT
          TPUSH
          NIP
          PUSHINT 1
        }>
        DROP
        SWAP
        PUSHINT 12
        SETINDEXVAR
        GETGLOB 14
        ROTREV
        CALL:<{
          NEWC
          SWAP
          DUP
          INDEX 8
          OVER
          INDEX 9
          PUSH s2
          INDEX 10
          PUSH s3
          INDEX 11
          PUSH s4
          INDEX 12
          PUSH s5
          INDEX 13
          PUSH s6
          INDEX 14
          XCHG s7, s8
          NEWC
          XCHG2 s0, s7
          STSLICER
          XCHG2 s0, s5
          STSLICER
          XCHG s1, s3
          STREF
          SWAP
          SWAP
          STU 14
          SWAP
          SWAP
          STU 14
          SWAP
          SWAP
          STI 1
          SWAP
          SWAP
          STI 1
          ENDC
          SWAP
          STREF
          OVER
          INDEX 0
          PUSH s2
          INDEX 1
          PUSH s3
          INDEX 2
          PUSH s4
          INDEX 3
          PUSH s5
          INDEX 4
          PUSH s6
          INDEX 5
          PUSH s7
          INDEX 6
          XCHG s0, s8
          INDEX 7
          XCHG s7, s8
          XCHG s6, s7
          XCHG s5, s6
          XCHG s4, s5
          XCHG s3, s4
          XCHG3 s1, s3, s0
          XCHG2 s8, s7
          SWAP
          STU 40
          XCHG2 s0, s5
          STGRAMS
          XCHG2 s0, s3
          STGRAMS
          SWAP
          STGRAMS
          SWAP
          STGRAMS
          SWAP
          STGRAMS
          ROT
          STGRAMS
          SWAP
          STGRAMS
          XCHG s0, s2
          PUSHINT 267
          DICTSETB
        }>
        SETGLOB 14
        CALLDICT 185
        CONT:<{
          PUSH c4
          PUSH c5
          PUSH c7
          CONT:<{
            2DROP
            THROW 1024
          }>
          SETCONTCTR c7
          SETCONTCTR c5
          SETCONTCTR c4
          CONT:<{
            CALLDICT 184
          }>
          PUSH c1
          BOOLOR
          SWAP
          TRY
        }>
        CALLXARGS 0, -1
        PUSHINT -1
        RETALT
      }>
      PUSH s2
      PUSHINT 4009334242
      EQUAL
      IFJMP:<{
        BLKDROP2 2, 1
        LDMSGADDR
        LDI 1
        SWAP
        NIP
        GETGLOB 14
        PUSH s2
        CALL:<{
          SWAP
          PUSHINT 267
          DICTGET
          NULLSWAPIFNOT
          NOT
          IFJMP:<{
            DROP
            TUPLE 0
            PUSHINT 0
          }>
          LDREFRTOS
          LDMSGADDR
          LDMSGADDR
          LDREF
          LDU 14
          SWAP
          SWAP
          LDU 14
          SWAP
          SWAP
          LDI 1
          SWAP
          SWAP
          LDI 1
          SWAP
          NIP
          TUPLE 7
          UNTUPLE 7
          XCHG s0, s7
          LDU 40
          SWAP
          SWAP
          LDGRAMS
          LDGRAMS
          LDGRAMS
          LDGRAMS
          LDGRAMS
          LDGRAMS
          LDGRAMS
          BLKSWAP 8, 1
          TUPLE 8
          UNTUPLE 8
          TUPLE 0
          XCHG2 s0, s8
          TPUSH
          XCHG2 s0, s6
          TPUSH
          XCHG2 s0, s4
          TPUSH
          ROT
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          XCHG2 s0, s7
          TPUSH
          XCHG2 s0, s5
          TPUSH
          XCHG2 s0, s3
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          ROT
          TPUSH
          NIP
          PUSHINT 1
        }>
        DROP
        SWAP
        PUSHINT 13
        SETINDEXVAR
        GETGLOB 14
        ROTREV
        CALL:<{
          NEWC
          SWAP
          DUP
          INDEX 8
          OVER
          INDEX 9
          PUSH s2
          INDEX 10
          PUSH s3
          INDEX 11
          PUSH s4
          INDEX 12
          PUSH s5
          INDEX 13
          PUSH s6
          INDEX 14
          XCHG s7, s8
          NEWC
          XCHG2 s0, s7
          STSLICER
          XCHG2 s0, s5
          STSLICER
          XCHG s1, s3
          STREF
          SWAP
          SWAP
          STU 14
          SWAP
          SWAP
          STU 14
          SWAP
          SWAP
          STI 1
          SWAP
          SWAP
          STI 1
          ENDC
          SWAP
          STREF
          OVER
          INDEX 0
          PUSH s2
          INDEX 1
          PUSH s3
          INDEX 2
          PUSH s4
          INDEX 3
          PUSH s5
          INDEX 4
          PUSH s6
          INDEX 5
          PUSH s7
          INDEX 6
          XCHG s0, s8
          INDEX 7
          XCHG s7, s8
          XCHG s6, s7
          XCHG s5, s6
          XCHG s4, s5
          XCHG s3, s4
          XCHG3 s1, s3, s0
          XCHG2 s8, s7
          SWAP
          STU 40
          XCHG2 s0, s5
          STGRAMS
          XCHG2 s0, s3
          STGRAMS
          SWAP
          STGRAMS
          SWAP
          STGRAMS
          SWAP
          STGRAMS
          ROT
          STGRAMS
          SWAP
          STGRAMS
          XCHG s0, s2
          PUSHINT 267
          DICTSETB
        }>
        SETGLOB 14
        CALLDICT 185
        CONT:<{
          PUSH c4
          PUSH c5
          PUSH c7
          CONT:<{
            2DROP
            THROW 1024
          }>
          SETCONTCTR c7
          SETCONTCTR c5
          SETCONTCTR c4
          CONT:<{
            CALLDICT 184
          }>
          PUSH c1
          BOOLOR
          SWAP
          TRY
        }>
        CALLXARGS 0, -1
        PUSHINT -1
        RETALT
      }>
      PUSH s2
      PUSHINT 2105004856
      EQUAL
      IFJMP:<{
        BLKDROP2 2, 1
        LDMSGADDR
        LDI 1
        SWAP
        NIP
        GETGLOB 14
        PUSH s2
        CALL:<{
          SWAP
          PUSHINT 267
          DICTGET
          NULLSWAPIFNOT
          NOT
          IFJMP:<{
            DROP
            TUPLE 0
            PUSHINT 0
          }>
          LDREFRTOS
          LDMSGADDR
          LDMSGADDR
          LDREF
          LDU 14
          SWAP
          SWAP
          LDU 14
          SWAP
          SWAP
          LDI 1
          SWAP
          SWAP
          LDI 1
          SWAP
          NIP
          TUPLE 7
          UNTUPLE 7
          XCHG s0, s7
          LDU 40
          SWAP
          SWAP
          LDGRAMS
          LDGRAMS
          LDGRAMS
          LDGRAMS
          LDGRAMS
          LDGRAMS
          LDGRAMS
          BLKSWAP 8, 1
          TUPLE 8
          UNTUPLE 8
          TUPLE 0
          XCHG2 s0, s8
          TPUSH
          XCHG2 s0, s6
          TPUSH
          XCHG2 s0, s4
          TPUSH
          ROT
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          XCHG2 s0, s7
          TPUSH
          XCHG2 s0, s5
          TPUSH
          XCHG2 s0, s3
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          ROT
          TPUSH
          NIP
          PUSHINT 1
        }>
        DROP
        SWAP
        PUSHINT 14
        SETINDEXVAR
        GETGLOB 14
        ROTREV
        CALL:<{
          NEWC
          SWAP
          DUP
          INDEX 8
          OVER
          INDEX 9
          PUSH s2
          INDEX 10
          PUSH s3
          INDEX 11
          PUSH s4
          INDEX 12
          PUSH s5
          INDEX 13
          PUSH s6
          INDEX 14
          XCHG s7, s8
          NEWC
          XCHG2 s0, s7
          STSLICER
          XCHG2 s0, s5
          STSLICER
          XCHG s1, s3
          STREF
          SWAP
          SWAP
          STU 14
          SWAP
          SWAP
          STU 14
          SWAP
          SWAP
          STI 1
          SWAP
          SWAP
          STI 1
          ENDC
          SWAP
          STREF
          OVER
          INDEX 0
          PUSH s2
          INDEX 1
          PUSH s3
          INDEX 2
          PUSH s4
          INDEX 3
          PUSH s5
          INDEX 4
          PUSH s6
          INDEX 5
          PUSH s7
          INDEX 6
          XCHG s0, s8
          INDEX 7
          XCHG s7, s8
          XCHG s6, s7
          XCHG s5, s6
          XCHG s4, s5
          XCHG s3, s4
          XCHG3 s1, s3, s0
          XCHG2 s8, s7
          SWAP
          STU 40
          XCHG2 s0, s5
          STGRAMS
          XCHG2 s0, s3
          STGRAMS
          SWAP
          STGRAMS
          SWAP
          STGRAMS
          SWAP
          STGRAMS
          ROT
          STGRAMS
          SWAP
          STGRAMS
          XCHG s0, s2
          PUSHINT 267
          DICTSETB
        }>
        SETGLOB 14
        CALLDICT 185
        CONT:<{
          PUSH c4
          PUSH c5
          PUSH c7
          CONT:<{
            2DROP
            THROW 1024
          }>
          SETCONTCTR c7
          SETCONTCTR c5
          SETCONTCTR c4
          CONT:<{
            CALLDICT 184
          }>
          PUSH c1
          BOOLOR
          SWAP
          TRY
        }>
        CALLXARGS 0, -1
        PUSHINT -1
        RETALT
      }>
      PUSH s2
      PUSHINT 4005334343
      EQUAL
      IFJMP:<{
        BLKDROP2 1, 2
        LDMSGADDR
        LDREFRTOS
        LDMSGADDR
        LDMSGADDR
        LDREF
        LDU 14
        SWAP
        SWAP
        LDU 14
        SWAP
        SWAP
        LDI 1
        SWAP
        SWAP
        LDI 1
        SWAP
        NIP
        TUPLE 7
        NIP
        UNTUPLE 7
        POP s6
        GETGLOB 14
        PUSH s7
        CALL:<{
          SWAP
          PUSHINT 267
          DICTGET
          NULLSWAPIFNOT
          NOT
          IFJMP:<{
            DROP
            TUPLE 0
            PUSHINT 0
          }>
          LDREFRTOS
          LDMSGADDR
          LDMSGADDR
          LDREF
          LDU 14
          SWAP
          SWAP
          LDU 14
          SWAP
          SWAP
          LDI 1
          SWAP
          SWAP
          LDI 1
          SWAP
          NIP
          TUPLE 7
          UNTUPLE 7
          XCHG s0, s7
          LDU 40
          SWAP
          SWAP
          LDGRAMS
          LDGRAMS
          LDGRAMS
          LDGRAMS
          LDGRAMS
          LDGRAMS
          LDGRAMS
          BLKSWAP 8, 1
          TUPLE 8
          UNTUPLE 8
          TUPLE 0
          XCHG2 s0, s8
          TPUSH
          XCHG2 s0, s6
          TPUSH
          XCHG2 s0, s4
          TPUSH
          ROT
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          XCHG2 s0, s7
          TPUSH
          XCHG2 s0, s5
          TPUSH
          XCHG2 s0, s3
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          ROT
          TPUSH
          NIP
          PUSHINT 1
        }>
        NIP
        THROWIF 1015
        NEWC
        PUSHSLICE x{2_}
        BLKSWAP 6, 1
        XCHG s0, s7
        NEWC
        XCHG2 s0, s7
        STSLICER
        XCHG2 s0, s5
        STSLICER
        XCHG s1, s3
        STREF
        SWAP
        SWAP
        STU 14
        SWAP
        SWAP
        STU 14
        SWAP
        SWAP
        STI 1
        SWAP
        SWAP
        STI 1
        ENDC
        SWAP
        STREF
        PUSHINT 0
        SWAP
        STU 68
        GETGLOB 14
        PUXC s2, s1
        XCHG s0, s2
        PUSHINT 267
        DICTSETB
        SETGLOB 14
        CALLDICT 60
        CALLDICT 185
        CONT:<{
          PUSH c4
          PUSH c5
          PUSH c7
          CONT:<{
            2DROP
            THROW 1024
          }>
          SETCONTCTR c7
          SETCONTCTR c5
          SETCONTCTR c4
          CONT:<{
            CALLDICT 184
          }>
          PUSH c1
          BOOLOR
          SWAP
          TRY
        }>
        CALLXARGS 0, -1
        PUSHINT -1
        RETALT
      }>
      NIP
      OVER
      PUSHINT 591689426
      EQUAL
      IFJMP:<{
        NIP
        LDMSGADDR
        LDMSGADDR
        DROP
        GETGLOB 14
        PUSH s2
        CALL:<{
          SWAP
          PUSHINT 267
          DICTGET
          NULLSWAPIFNOT
          NOT
          IFJMP:<{
            DROP
            TUPLE 0
            PUSHINT 0
          }>
          LDREFRTOS
          LDMSGADDR
          LDMSGADDR
          LDREF
          LDU 14
          SWAP
          SWAP
          LDU 14
          SWAP
          SWAP
          LDI 1
          SWAP
          SWAP
          LDI 1
          SWAP
          NIP
          TUPLE 7
          UNTUPLE 7
          XCHG s0, s7
          LDU 40
          SWAP
          SWAP
          LDGRAMS
          LDGRAMS
          LDGRAMS
          LDGRAMS
          LDGRAMS
          LDGRAMS
          LDGRAMS
          BLKSWAP 8, 1
          TUPLE 8
          UNTUPLE 8
          TUPLE 0
          XCHG2 s0, s8
          TPUSH
          XCHG2 s0, s6
          TPUSH
          XCHG2 s0, s4
          TPUSH
          ROT
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          XCHG2 s0, s7
          TPUSH
          XCHG2 s0, s5
          TPUSH
          XCHG2 s0, s3
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          ROT
          TPUSH
          NIP
          PUSHINT 1
        }>
        DROP
        DUP
        INDEX 8
        PLDU 2
        EQINT 0
        IF:<{
          SWAP
          PUSHINT 8
          SETINDEXVAR
          GETGLOB 14
          ROTREV
          CALL:<{
            NEWC
            SWAP
            DUP
            INDEX 8
            OVER
            INDEX 9
            PUSH s2
            INDEX 10
            PUSH s3
            INDEX 11
            PUSH s4
            INDEX 12
            PUSH s5
            INDEX 13
            PUSH s6
            INDEX 14
            XCHG s7, s8
            NEWC
            XCHG2 s0, s7
            STSLICER
            XCHG2 s0, s5
            STSLICER
            XCHG s1, s3
            STREF
            SWAP
            SWAP
            STU 14
            SWAP
            SWAP
            STU 14
            SWAP
            SWAP
            STI 1
            SWAP
            SWAP
            STI 1
            ENDC
            SWAP
            STREF
            OVER
            INDEX 0
            PUSH s2
            INDEX 1
            PUSH s3
            INDEX 2
            PUSH s4
            INDEX 3
            PUSH s5
            INDEX 4
            PUSH s6
            INDEX 5
            PUSH s7
            INDEX 6
            XCHG s0, s8
            INDEX 7
            XCHG s7, s8
            XCHG s6, s7
            XCHG s5, s6
            XCHG s4, s5
            XCHG s3, s4
            XCHG3 s1, s3, s0
            XCHG2 s8, s7
            SWAP
            STU 40
            XCHG2 s0, s5
            STGRAMS
            XCHG2 s0, s3
            STGRAMS
            SWAP
            STGRAMS
            SWAP
            STGRAMS
            SWAP
            STGRAMS
            ROT
            STGRAMS
            SWAP
            STGRAMS
            XCHG s0, s2
            PUSHINT 267
            DICTSETB
          }>
          SETGLOB 14
          CALLDICT 185
          CONT:<{
            PUSH c4
            PUSH c5
            PUSH c7
            CONT:<{
              2DROP
              THROW 1024
            }>
            SETCONTCTR c7
            SETCONTCTR c5
            SETCONTCTR c4
            CONT:<{
              CALLDICT 184
            }>
            PUSH c1
            BOOLOR
            SWAP
            TRY
          }>
          CALLXARGS 0, -1
        }>ELSE<{
          BLKDROP 3
        }>
        PUSHINT -1
        RETALT
      }>
      OVER
      PUSHINT 171034560
      EQUAL
      IFJMP:<{
        NIP
        LDMSGADDR
        DROP
        SETGLOB 3
        CALLDICT 185
        CONT:<{
          PUSH c4
          PUSH c5
          PUSH c7
          CONT:<{
            2DROP
            THROW 1024
          }>
          SETCONTCTR c7
          SETCONTCTR c5
          SETCONTCTR c4
          CONT:<{
            CALLDICT 184
          }>
          PUSH c1
          BOOLOR
          SWAP
          TRY
        }>
        CALLXARGS 0, -1
        PUSHINT -1
        RETALT
      }>
      OVER
      PUSHINT 888886630
      EQUAL
      IFJMP:<{
        NIP
        LDMSGADDR
        DROP
        SETGLOB 6
        CALLDICT 185
        CONT:<{
          PUSH c4
          PUSH c5
          PUSH c7
          CONT:<{
            2DROP
            THROW 1024
          }>
          SETCONTCTR c7
          SETCONTCTR c5
          SETCONTCTR c4
          CONT:<{
            CALLDICT 184
          }>
          PUSH c1
          BOOLOR
          SWAP
          TRY
        }>
        CALLXARGS 0, -1
        PUSHINT -1
        RETALT
      }>
      OVER
      PUSHINT 3643877086
      EQUAL
      IFJMP:<{
        NIP
        LDREF
        DROP
        SETGLOB 7
        CALLDICT 185
        CONT:<{
          PUSH c4
          PUSH c5
          PUSH c7
          CONT:<{
            2DROP
            THROW 1024
          }>
          SETCONTCTR c7
          SETCONTCTR c5
          SETCONTCTR c4
          CONT:<{
            CALLDICT 184
          }>
          PUSH c1
          BOOLOR
          SWAP
          TRY
        }>
        CALLXARGS 0, -1
        PUSHINT -1
        RETALT
      }>
      OVER
      PUSHINT 691583522
      EQUAL
      IFJMP:<{
        NIP
        LDU 20
        DROP
        DUP
        PUSHINT 50000
        LEQ
        THROWIFNOT 2000
        SETGLOB 8
        CALLDICT 185
        CONT:<{
          PUSH c4
          PUSH c5
          PUSH c7
          CONT:<{
            2DROP
            THROW 1024
          }>
          SETCONTCTR c7
          SETCONTCTR c5
          SETCONTCTR c4
          CONT:<{
            CALLDICT 184
          }>
          PUSH c1
          BOOLOR
          SWAP
          TRY
        }>
        CALLXARGS 0, -1
        PUSHINT -1
        RETALT
      }>
      OVER
      PUSHINT 1035141596
      EQUAL
      IFJMP:<{
        NIP
        LDU 14
        SWAP
        NIP
        DUP
        PUSHINT 15000
        LEQ
        THROWIFNOT 2001
        SETGLOB 9
        CALLDICT 185
        CONT:<{
          PUSH c4
          PUSH c5
          PUSH c7
          CONT:<{
            2DROP
            THROW 1024
          }>
          SETCONTCTR c7
          SETCONTCTR c5
          SETCONTCTR c4
          CONT:<{
            CALLDICT 184
          }>
          PUSH c1
          BOOLOR
          SWAP
          TRY
        }>
        CALLXARGS 0, -1
        PUSHINT -1
        RETALT
      }>
      OVER
      PUSHINT 3427415258
      EQUAL
      IFJMP:<{
        NIP
        LDU 20
        DROP
        DUP
        PUSHINT 100000
        LEQ
        THROWIFNOT 2002
        SETGLOB 10
        CALLDICT 185
        CONT:<{
          PUSH c4
          PUSH c5
          PUSH c7
          CONT:<{
            2DROP
            THROW 1024
          }>
          SETCONTCTR c7
          SETCONTCTR c5
          SETCONTCTR c4
          CONT:<{
            CALLDICT 184
          }>
          PUSH c1
          BOOLOR
          SWAP
          TRY
        }>
        CALLXARGS 0, -1
        PUSHINT -1
        RETALT
      }>
      OVER
      PUSHINT 204334213
      EQUAL
      IFJMP:<{
        NIP
        LDU 14
        SWAP
        NIP
        DUP
        PUSHINT 30000
        LEQ
        THROWIFNOT 2003
        SETGLOB 11
        CALLDICT 185
        CONT:<{
          PUSH c4
          PUSH c5
          PUSH c7
          CONT:<{
            2DROP
            THROW 1024
          }>
          SETCONTCTR c7
          SETCONTCTR c5
          SETCONTCTR c4
          CONT:<{
            CALLDICT 184
          }>
          PUSH c1
          BOOLOR
          SWAP
          TRY
        }>
        CALLXARGS 0, -1
        PUSHINT -1
        RETALT
      }>
      OVER
      PUSHINT 3607076063
      EQUAL
      IFJMP:<{
        NIP
        LDU 14
        SWAP
        SWAP
        LDU 14
        SWAP
        NIP
        2DUP
        OVER
        GTINT 99
        PUSH s2
        PUSHINT 9900
        LEQ
        AND
        THROWIFNOT 2004
        DUP
        PUSHINT 2500
        GEQ
        OVER
        PUSHINT 9900
        LEQ
        AND
        THROWIFNOT 2004
        SWAP
        GREATER
        THROWIFNOT 2004
        SWAP
        SETGLOB 12
        SETGLOB 13
        CALLDICT 185
        CONT:<{
          PUSH c4
          PUSH c5
          PUSH c7
          CONT:<{
            2DROP
            THROW 1024
          }>
          SETCONTCTR c7
          SETCONTCTR c5
          SETCONTCTR c4
          CONT:<{
            CALLDICT 184
          }>
          PUSH c1
          BOOLOR
          SWAP
          TRY
        }>
        CALLXARGS 0, -1
        PUSHINT -1
        RETALT
      }>
      OVER
      PUSHINT 1639833483
      EQUAL
      IFJMP:<{
        NIP
        LDREF
        DROP
        DUP
        CTOS
        BLESS
        POP c3
        SETCODE
        PUSH c4
        PUSHINT 113417
        PUSH c3
        EXECUTE
        PUSHINT -1
        RETALT
      }>
      SWAP
      PUSHINT 1356365085
      EQUAL
      IFJMP:<{
        LDGRAMS
        SWAP
        SETGLOB 16
        LDGRAMS
        SWAP
        SETGLOB 17
        LDGRAMS
        SWAP
        SETGLOB 18
        LDGRAMS
        SWAP
        SETGLOB 19
        LDGRAMS
        SWAP
        SETGLOB 20
        LDGRAMS
        SWAP
        SETGLOB 21
        LDGRAMS
        SWAP
        SETGLOB 22
        LDGRAMS
        SWAP
        SETGLOB 23
        LDGRAMS
        DROP
        SETGLOB 24
        CALLDICT 186
        CALLDICT 185
        CONT:<{
          PUSH c4
          PUSH c5
          PUSH c7
          CONT:<{
            2DROP
            THROW 1024
          }>
          SETCONTCTR c7
          SETCONTCTR c5
          SETCONTCTR c4
          CONT:<{
            CALLDICT 184
          }>
          PUSH c1
          BOOLOR
          SWAP
          TRY
        }>
        CALLXARGS 0, -1
        PUSHINT -1
        RETALT
      }>
      DROP
    }>ELSE<{
      BLKDROP 3
    }>
    PUSHINT 0
  }>
  218 => <{
    SAVECTR c2
    SAMEALTSAVE
    GETGLOB 4
    XCHG s1, s2
    SDEQ
    IF:<{
      PUSH s2
      PUSHINT 2402645591
      EQUAL
      IFJMP:<{
        BLKDROP2 2, 1
        LDMSGADDR
        DROP
        SETGLOB 4
        CALLDICT 185
        PUSHINT -1
        RETALT
      }>
      PUSH s2
      PUSHINT 2182326539
      EQUAL
      IFJMP:<{
        BLKDROP2 2, 1
        LDU 14
        SWAP
        NIP
        SETGLOB 5
        CALLDICT 185
        PUSHINT -1
        RETALT
      }>
      XCHG s0, s2
      PUSHINT 2636247514
      EQUAL
      IFJMP:<{
        SWAP
        LDMSGADDR
        LDGRAMS
        LDMSGADDR
        DROP
        GETGLOB 14
        PUSH s3
        CALL:<{
          SWAP
          PUSHINT 267
          DICTGET
          NULLSWAPIFNOT
          NOT
          IFJMP:<{
            DROP
            TUPLE 0
            PUSHINT 0
          }>
          LDREFRTOS
          LDMSGADDR
          LDMSGADDR
          LDREF
          LDU 14
          SWAP
          SWAP
          LDU 14
          SWAP
          SWAP
          LDI 1
          SWAP
          SWAP
          LDI 1
          SWAP
          NIP
          TUPLE 7
          UNTUPLE 7
          XCHG s0, s7
          LDU 40
          SWAP
          SWAP
          LDGRAMS
          LDGRAMS
          LDGRAMS
          LDGRAMS
          LDGRAMS
          LDGRAMS
          LDGRAMS
          BLKSWAP 8, 1
          TUPLE 8
          UNTUPLE 8
          TUPLE 0
          XCHG2 s0, s8
          TPUSH
          XCHG2 s0, s6
          TPUSH
          XCHG2 s0, s4
          TPUSH
          ROT
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          XCHG2 s0, s7
          TPUSH
          XCHG2 s0, s5
          TPUSH
          XCHG2 s0, s3
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          ROT
          TPUSH
          NIP
          PUSHINT 1
        }>
        DROP
        GETGLOB 5
        CALL:<{
          NOW
          PUSH s2
          INDEX 7
          EQINT 0
          PUSH s3
          INDEX 1
          EQINT 0
          OR
          IFJMP:<{
            NIP
            PUSHINT 0
            SETINDEXVAR
          }>
          PUSH s2
          INDEX 0
          PUXC s1, s(-1)
          SUB
          DUP
          EQINT 0
          IFJMP:<{
            BLKDROP 3
          }>
          PUSH s3
          INDEX 1
          MUL
          PUSH s3
          INDEX 5
          PUSHINT 14551915228366851806640625
          LSHIFT 36
          MULDIV
          PUXC s0, s2
          PUSHINT 10000
          MULDIV
          XCPU s3, s2
          OVER
          INDEX 5
          SWAP
          ADD
          PUSHINT 5
          SETINDEXVAR
          XCPU s2, s3
          SUB
          XCHG s1, s2
          OVER
          INDEX 4
          SWAP
          ADD
          PUSHINT 4
          SETINDEXVAR
          ROT
          OVER
          INDEX 2
          SWAP
          ADD
          PUSHINT 2
          SETINDEXVAR
          SWAP
          PUSHINT 0
          SETINDEXVAR
        }>
        DUP
        INDEX 3
        PUSH s3
        GEQ
        THROWIFNOT 1005
        DUP
        INDEX 2
        PUSH s3
        GEQ
        THROWIFNOT 1011
        PUSH s2
        OVER
        INDEX 2
        SWAP
        SUB
        PUSHINT 2
        SETINDEXVAR
        PUSH s2
        OVER
        INDEX 3
        SWAP
        SUB
        PUSHINT 3
        SETINDEXVAR
        DUP
        INDEX 8
        XCHG s3, s5
        PUXC2 s2, s2, s5
        PUSHINT 0
        PUSHNULL
        CALLDICT 204
        GETGLOB 14
        XCHG s0, s2
        CALL:<{
          NEWC
          SWAP
          DUP
          INDEX 8
          OVER
          INDEX 9
          PUSH s2
          INDEX 10
          PUSH s3
          INDEX 11
          PUSH s4
          INDEX 12
          PUSH s5
          INDEX 13
          PUSH s6
          INDEX 14
          XCHG s7, s8
          NEWC
          XCHG2 s0, s7
          STSLICER
          XCHG2 s0, s5
          STSLICER
          XCHG s1, s3
          STREF
          SWAP
          SWAP
          STU 14
          SWAP
          SWAP
          STU 14
          SWAP
          SWAP
          STI 1
          SWAP
          SWAP
          STI 1
          ENDC
          SWAP
          STREF
          OVER
          INDEX 0
          PUSH s2
          INDEX 1
          PUSH s3
          INDEX 2
          PUSH s4
          INDEX 3
          PUSH s5
          INDEX 4
          PUSH s6
          INDEX 5
          PUSH s7
          INDEX 6
          XCHG s0, s8
          INDEX 7
          XCHG s7, s8
          XCHG s6, s7
          XCHG s5, s6
          XCHG s4, s5
          XCHG s3, s4
          XCHG3 s1, s3, s0
          XCHG2 s8, s7
          SWAP
          STU 40
          XCHG2 s0, s5
          STGRAMS
          XCHG2 s0, s3
          STGRAMS
          SWAP
          STGRAMS
          SWAP
          STGRAMS
          SWAP
          STGRAMS
          ROT
          STGRAMS
          SWAP
          STGRAMS
          XCHG s0, s2
          PUSHINT 267
          DICTSETB
        }>
        SETGLOB 14
        CALLDICT 185
        PUSHINT -1
        RETALT
      }>
      2DROP
    }>ELSE<{
      BLKDROP 3
    }>
    PUSHINT 0
  }>
  219 => <{
    PUSH s3
    PUSHINT 2145615302
    EQUAL
    IFJMP:<{
      POP s3
      XCHG s0, s2
      LDMSGADDR
      GETGLOB 14
      PUSH s2
      CALL:<{
        SWAP
        PUSHINT 267
        DICTGET
        NULLSWAPIFNOT
        NOT
        IFJMP:<{
          DROP
          TUPLE 0
          PUSHINT 0
        }>
        LDREFRTOS
        LDMSGADDR
        LDMSGADDR
        LDREF
        LDU 14
        SWAP
        SWAP
        LDU 14
        SWAP
        SWAP
        LDI 1
        SWAP
        SWAP
        LDI 1
        SWAP
        NIP
        TUPLE 7
        UNTUPLE 7
        XCHG s0, s7
        LDU 40
        SWAP
        SWAP
        LDGRAMS
        LDGRAMS
        LDGRAMS
        LDGRAMS
        LDGRAMS
        LDGRAMS
        LDGRAMS
        BLKSWAP 8, 1
        TUPLE 8
        UNTUPLE 8
        TUPLE 0
        XCHG2 s0, s8
        TPUSH
        XCHG2 s0, s6
        TPUSH
        XCHG2 s0, s4
        TPUSH
        ROT
        TPUSH
        SWAP
        TPUSH
        SWAP
        TPUSH
        SWAP
        TPUSH
        SWAP
        TPUSH
        XCHG2 s0, s7
        TPUSH
        XCHG2 s0, s5
        TPUSH
        XCHG2 s0, s3
        TPUSH
        SWAP
        TPUSH
        SWAP
        TPUSH
        SWAP
        TPUSH
        ROT
        TPUSH
        NIP
        PUSHINT 1
      }>
      DROP
      GETGLOB 5
      CALL:<{
        NOW
        PUSH s2
        INDEX 7
        EQINT 0
        PUSH s3
        INDEX 1
        EQINT 0
        OR
        IFJMP:<{
          NIP
          PUSHINT 0
          SETINDEXVAR
        }>
        PUSH s2
        INDEX 0
        PUXC s1, s(-1)
        SUB
        DUP
        EQINT 0
        IFJMP:<{
          BLKDROP 3
        }>
        PUSH s3
        INDEX 1
        MUL
        PUSH s3
        INDEX 5
        PUSHINT 14551915228366851806640625
        LSHIFT 36
        MULDIV
        PUXC s0, s2
        PUSHINT 10000
        MULDIV
        XCPU s3, s2
        OVER
        INDEX 5
        SWAP
        ADD
        PUSHINT 5
        SETINDEXVAR
        XCPU s2, s3
        SUB
        XCHG s1, s2
        OVER
        INDEX 4
        SWAP
        ADD
        PUSHINT 4
        SETINDEXVAR
        ROT
        OVER
        INDEX 2
        SWAP
        ADD
        PUSHINT 2
        SETINDEXVAR
        SWAP
        PUSHINT 0
        SETINDEXVAR
      }>
      PUSH3 s3, s2, s4
      CALLDICT 211
      GETGLOB 14
      XC2PU s0, s3, s3
      CALL:<{
        NEWC
        SWAP
        DUP
        INDEX 8
        OVER
        INDEX 9
        PUSH s2
        INDEX 10
        PUSH s3
        INDEX 11
        PUSH s4
        INDEX 12
        PUSH s5
        INDEX 13
        PUSH s6
        INDEX 14
        XCHG s7, s8
        NEWC
        XCHG2 s0, s7
        STSLICER
        XCHG2 s0, s5
        STSLICER
        XCHG s1, s3
        STREF
        SWAP
        SWAP
        STU 14
        SWAP
        SWAP
        STU 14
        SWAP
        SWAP
        STI 1
        SWAP
        SWAP
        STI 1
        ENDC
        SWAP
        STREF
        OVER
        INDEX 0
        PUSH s2
        INDEX 1
        PUSH s3
        INDEX 2
        PUSH s4
        INDEX 3
        PUSH s5
        INDEX 4
        PUSH s6
        INDEX 5
        PUSH s7
        INDEX 6
        XCHG s0, s8
        INDEX 7
        XCHG s7, s8
        XCHG s6, s7
        XCHG s5, s6
        XCHG s4, s5
        XCHG s3, s4
        XCHG3 s1, s3, s0
        XCHG2 s8, s7
        SWAP
        STU 40
        XCHG2 s0, s5
        STGRAMS
        XCHG2 s0, s3
        STGRAMS
        SWAP
        STGRAMS
        SWAP
        STGRAMS
        SWAP
        STGRAMS
        ROT
        STGRAMS
        SWAP
        STGRAMS
        XCHG s0, s2
        PUSHINT 267
        DICTSETB
      }>
      SETGLOB 14
      CALLDICT 185
      NEWC
      PUSHINT 1547537320
      SWAP
      STU 32
      XCHG2 s0, s3
      SWAP
      STU 64
      SWAP
      DUP
      INDEX 8
      OVER
      INDEX 9
      PUSH s2
      INDEX 10
      PUSH s3
      INDEX 11
      PUSH s4
      INDEX 12
      PUSH s5
      INDEX 13
      PUSH s6
      INDEX 14
      XCHG s7, s8
      NEWC
      XCHG2 s0, s7
      STSLICER
      XCHG2 s0, s5
      STSLICER
      XCHG s1, s3
      STREF
      SWAP
      SWAP
      STU 14
      SWAP
      SWAP
      STU 14
      SWAP
      SWAP
      STI 1
      SWAP
      SWAP
      STI 1
      ENDC
      SWAP
      STREF
      OVER
      INDEX 0
      PUSH s2
      INDEX 1
      PUSH s3
      INDEX 2
      PUSH s4
      INDEX 3
      PUSH s5
      INDEX 4
      PUSH s6
      INDEX 5
      PUSH s7
      INDEX 6
      XCHG s0, s8
      INDEX 7
      XCHG s7, s8
      XCHG s6, s7
      XCHG s5, s6
      XCHG s4, s5
      XCHG s3, s4
      XCHG3 s1, s3, s0
      XCHG2 s8, s7
      SWAP
      STU 40
      XCHG2 s0, s5
      STGRAMS
      XCHG2 s0, s3
      STGRAMS
      SWAP
      STGRAMS
      SWAP
      STGRAMS
      SWAP
      STGRAMS
      ROT
      STGRAMS
      SWAP
      STGRAMS
      OVER
      SEMPTY
      NOT
      IF:<{
        SWAP
        STSLICER
      }>ELSE<{
        NIP
      }>
      PUSHINT 0
      SWAP
      ENDC
      CALLDICT 55
      PUSHINT 64
      SENDRAWMSG
      PUSHINT -1
    }>
    PUSH s3
    PUSHINT 1769360371
    EQUAL
    IFJMP:<{
      POP s3
      XCHG s0, s2
      LDDICT
      PUSHNULL
      PUSH s2
      PUSHINT 267
      DICTMIN
      NULLSWAPIFNOT2
      XCHG s1, s2
      NIP
      WHILE:<{
      }>DO<{
        GETGLOB 14
        OVER
        CALL:<{
          SWAP
          PUSHINT 267
          DICTGET
          NULLSWAPIFNOT
          NOT
          IFJMP:<{
            DROP
            TUPLE 0
            PUSHINT 0
          }>
          LDREFRTOS
          LDMSGADDR
          LDMSGADDR
          LDREF
          LDU 14
          SWAP
          SWAP
          LDU 14
          SWAP
          SWAP
          LDI 1
          SWAP
          SWAP
          LDI 1
          SWAP
          NIP
          TUPLE 7
          UNTUPLE 7
          XCHG s0, s7
          LDU 40
          SWAP
          SWAP
          LDGRAMS
          LDGRAMS
          LDGRAMS
          LDGRAMS
          LDGRAMS
          LDGRAMS
          LDGRAMS
          BLKSWAP 8, 1
          TUPLE 8
          UNTUPLE 8
          TUPLE 0
          XCHG2 s0, s8
          TPUSH
          XCHG2 s0, s6
          TPUSH
          XCHG2 s0, s4
          TPUSH
          ROT
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          XCHG2 s0, s7
          TPUSH
          XCHG2 s0, s5
          TPUSH
          XCHG2 s0, s3
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          SWAP
          TPUSH
          ROT
          TPUSH
          NIP
          PUSHINT 1
        }>
        DROP
        GETGLOB 5
        CALL:<{
          NOW
          PUSH s2
          INDEX 7
          EQINT 0
          PUSH s3
          INDEX 1
          EQINT 0
          OR
          IFJMP:<{
            NIP
            PUSHINT 0
            SETINDEXVAR
          }>
          PUSH s2
          INDEX 0
          PUXC s1, s(-1)
          SUB
          DUP
          EQINT 0
          IFJMP:<{
            BLKDROP 3
          }>
          PUSH s3
          INDEX 1
          MUL
          PUSH s3
          INDEX 5
          PUSHINT 14551915228366851806640625
          LSHIFT 36
          MULDIV
          PUXC s0, s2
          PUSHINT 10000
          MULDIV
          XCPU s3, s2
          OVER
          INDEX 5
          SWAP
          ADD
          PUSHINT 5
          SETINDEXVAR
          XCPU s2, s3
          SUB
          XCHG s1, s2
          OVER
          INDEX 4
          SWAP
          ADD
          PUSHINT 4
          SETINDEXVAR
          ROT
          OVER
          INDEX 2
          SWAP
          ADD
          PUSHINT 2
          SETINDEXVAR
          SWAP
          PUSHINT 0
          SETINDEXVAR
        }>
        PUSH3 s5, s1, s6
        CALLDICT 211
        GETGLOB 14
        PUSH2 s2, s1
        CALL:<{
          NEWC
          SWAP
          DUP
          INDEX 8
          OVER
          INDEX 9
          PUSH s2
          INDEX 10
          PUSH s3
          INDEX 11
          PUSH s4
          INDEX 12
          PUSH s5
          INDEX 13
          PUSH s6
          INDEX 14
          XCHG s7, s8
          NEWC
          XCHG2 s0, s7
          STSLICER
          XCHG2 s0, s5
          STSLICER
          XCHG s1, s3
          STREF
          SWAP
          SWAP
          STU 14
          SWAP
          SWAP
          STU 14
          SWAP
          SWAP
          STI 1
          SWAP
          SWAP
          STI 1
          ENDC
          SWAP
          STREF
          OVER
          INDEX 0
          PUSH s2
          INDEX 1
          PUSH s3
          INDEX 2
          PUSH s4
          INDEX 3
          PUSH s5
          INDEX 4
          PUSH s6
          INDEX 5
          PUSH s7
          INDEX 6
          XCHG s0, s8
          INDEX 7
          XCHG s7, s8
          XCHG s6, s7
          XCHG s5, s6
          XCHG s4, s5
          XCHG s3, s4
          XCHG3 s1, s3, s0
          XCHG2 s8, s7
          SWAP
          STU 40
          XCHG2 s0, s5
          STGRAMS
          XCHG2 s0, s3
          STGRAMS
          SWAP
          STGRAMS
          SWAP
          STGRAMS
          SWAP
          STGRAMS
          ROT
          STGRAMS
          SWAP
          STGRAMS
          XCHG s0, s2
          PUSHINT 267
          DICTSETB
        }>
        SETGLOB 14
        XCPUXC s2, s2, s(-1)
        CALL:<{
          NEWC
          SWAP
          DUP
          INDEX 8
          OVER
          INDEX 9
          PUSH s2
          INDEX 10
          PUSH s3
          INDEX 11
          PUSH s4
          INDEX 12
          PUSH s5
          INDEX 13
          PUSH s6
          INDEX 14
          XCHG s7, s8
          NEWC
          XCHG2 s0, s7
          STSLICER
          XCHG2 s0, s5
          STSLICER
          XCHG s1, s3
          STREF
          SWAP
          SWAP
          STU 14
          SWAP
          SWAP
          STU 14
          SWAP
          SWAP
          STI 1
          SWAP
          SWAP
          STI 1
          ENDC
          SWAP
          STREF
          OVER
          INDEX 0
          PUSH s2
          INDEX 1
          PUSH s3
          INDEX 2
          PUSH s4
          INDEX 3
          PUSH s5
          INDEX 4
          PUSH s6
          INDEX 5
          PUSH s7
          INDEX 6
          XCHG s0, s8
          INDEX 7
          XCHG s7, s8
          XCHG s6, s7
          XCHG s5, s6
          XCHG s4, s5
          XCHG s3, s4
          XCHG3 s1, s3, s0
          XCHG2 s8, s7
          SWAP
          STU 40
          XCHG2 s0, s5
          STGRAMS
          XCHG2 s0, s3
          STGRAMS
          SWAP
          STGRAMS
          SWAP
          STGRAMS
          SWAP
          STGRAMS
          ROT
          STGRAMS
          SWAP
          STGRAMS
          XCHG s0, s2
          PUSHINT 267
          DICTSETB
        }>
        PUXC s3, s1
        SWAP
        PUSHINT 267
        DICTGETNEXT
        NULLSWAPIFNOT2
        XCHG s1, s2
        NIP
      }>
      DROP
      POP s2
      CALLDICT 185
      NEWC
      PUSHINT 3277838682
      SWAP
      STU 32
      XCHG2 s0, s3
      SWAP
      STU 64
      STDICT
      OVER
      SEMPTY
      NOT
      IF:<{
        SWAP
        STSLICER
      }>ELSE<{
        NIP
      }>
      PUSHINT 0
      SWAP
      ENDC
      CALLDICT 55
      PUSHINT 64
      SENDRAWMSG
      PUSHINT -1
    }>
    PUSH s3
    PUSHINT 712360689
    EQUAL
    IFJMP:<{
      POP s3
      PUSHNULL
      GETGLOB 14
      PUSHINT 267
      DICTMIN
      NULLSWAPIFNOT2
      XCHG s1, s2
      WHILE:<{
      }>DO<{
        LDREFRTOS
        LDMSGADDR
        LDMSGADDR
        LDREF
        LDU 14
        SWAP
        SWAP
        LDU 14
        SWAP
        SWAP
        LDI 1
        SWAP
        SWAP
        LDI 1
        SWAP
        NIP
        TUPLE 7
        UNTUPLE 7
        XCHG s0, s7
        LDU 40
        SWAP
        SWAP
        LDGRAMS
        LDGRAMS
        LDGRAMS
        LDGRAMS
        LDGRAMS
        LDGRAMS
        LDGRAMS
        BLKSWAP 8, 1
        TUPLE 8
        UNTUPLE 8
        TUPLE 0
        XCHG2 s0, s8
        TPUSH
        XCHG2 s0, s6
        TPUSH
        XCHG2 s0, s4
        TPUSH
        ROT
        TPUSH
        SWAP
        TPUSH
        SWAP
        TPUSH
        SWAP
        TPUSH
        SWAP
        TPUSH
        XCHG2 s0, s7
        TPUSH
        XCHG2 s0, s5
        TPUSH
        XCHG2 s0, s3
        TPUSH
        SWAP
        TPUSH
        SWAP
        TPUSH
        SWAP
        TPUSH
        ROT
        TPUSH
        NIP
        GETGLOB 5
        CALL:<{
          NOW
          PUSH s2
          INDEX 7
          EQINT 0
          PUSH s3
          INDEX 1
          EQINT 0
          OR
          IFJMP:<{
            NIP
            PUSHINT 0
            SETINDEXVAR
          }>
          PUSH s2
          INDEX 0
          PUXC s1, s(-1)
          SUB
          DUP
          EQINT 0
          IFJMP:<{
            BLKDROP 3
          }>
          PUSH s3
          INDEX 1
          MUL
          PUSH s3
          INDEX 5
          PUSHINT 14551915228366851806640625
          LSHIFT 36
          MULDIV
          PUXC s0, s2
          PUSHINT 10000
          MULDIV
          XCPU s3, s2
          OVER
          INDEX 5
          SWAP
          ADD
          PUSHINT 5
          SETINDEXVAR
          XCPU s2, s3
          SUB
          XCHG s1, s2
          OVER
          INDEX 4
          SWAP
          ADD
          PUSHINT 4
          SETINDEXVAR
          ROT
          OVER
          INDEX 2
          SWAP
          ADD
          PUSHINT 2
          SETINDEXVAR
          SWAP
          PUSHINT 0
          SETINDEXVAR
        }>
        PUSH3 s4, s1, s3
        CALLDICT 211
        GETGLOB 14
        PUSH2 s2, s1
        CALL:<{
          NEWC
          SWAP
          DUP
          INDEX 8
          OVER
          INDEX 9
          PUSH s2
          INDEX 10
          PUSH s3
          INDEX 11
          PUSH s4
          INDEX 12
          PUSH s5
          INDEX 13
          PUSH s6
          INDEX 14
          XCHG s7, s8
          NEWC
          XCHG2 s0, s7
          STSLICER
          XCHG2 s0, s5
          STSLICER
          XCHG s1, s3
          STREF
          SWAP
          SWAP
          STU 14
          SWAP
          SWAP
          STU 14
          SWAP
          SWAP
          STI 1
          SWAP
          SWAP
          STI 1
          ENDC
          SWAP
          STREF
          OVER
          INDEX 0
          PUSH s2
          INDEX 1
          PUSH s3
          INDEX 2
          PUSH s4
          INDEX 3
          PUSH s5
          INDEX 4
          PUSH s6
          INDEX 5
          PUSH s7
          INDEX 6
          XCHG s0, s8
          INDEX 7
          XCHG s7, s8
          XCHG s6, s7
          XCHG s5, s6
          XCHG s4, s5
          XCHG s3, s4
          XCHG3 s1, s3, s0
          XCHG2 s8, s7
          SWAP
          STU 40
          XCHG2 s0, s5
          STGRAMS
          XCHG2 s0, s3
          STGRAMS
          SWAP
          STGRAMS
          SWAP
          STGRAMS
          SWAP
          STGRAMS
          ROT
          STGRAMS
          SWAP
          STGRAMS
          XCHG s0, s2
          PUSHINT 267
          DICTSETB
        }>
        SETGLOB 14
        XCPU2 s2, s1, s2
        CALL:<{
          NEWC
          SWAP
          DUP
          INDEX 8
          OVER
          INDEX 9
          PUSH s2
          INDEX 10
          PUSH s3
          INDEX 11
          PUSH s4
          INDEX 12
          PUSH s5
          INDEX 13
          PUSH s6
          INDEX 14
          XCHG s7, s8
          NEWC
          XCHG2 s0, s7
          STSLICER
          XCHG2 s0, s5
          STSLICER
          XCHG s1, s3
          STREF
          SWAP
          SWAP
          STU 14
          SWAP
          SWAP
          STU 14
          SWAP
          SWAP
          STI 1
          SWAP
          SWAP
          STI 1
          ENDC
          SWAP
          STREF
          OVER
          INDEX 0
          PUSH s2
          INDEX 1
          PUSH s3
          INDEX 2
          PUSH s4
          INDEX 3
          PUSH s5
          INDEX 4
          PUSH s6
          INDEX 5
          PUSH s7
          INDEX 6
          XCHG s0, s8
          INDEX 7
          XCHG s7, s8
          XCHG s6, s7
          XCHG s5, s6
          XCHG s4, s5
          XCHG s3, s4
          XCHG3 s1, s3, s0
          XCHG2 s8, s7
          SWAP
          STU 40
          XCHG2 s0, s5
          STGRAMS
          XCHG2 s0, s3
          STGRAMS
          SWAP
          STGRAMS
          SWAP
          STGRAMS
          SWAP
          STGRAMS
          ROT
          STGRAMS
          SWAP
          STGRAMS
          XCHG s0, s2
          PUSHINT 267
          DICTSETB
        }>
        NEWC
        PUSH s3
        INDEX 4
        STGRAMS
        PUSH s3
        INDEX 5
        STGRAMS
        PUSH s3
        INDEX 6
        STGRAMS
        XCHG s0, s3
        INDEX 7
        XCHG s1, s3
        STGRAMS
        XCPUXC s2, s2, s(-1)
        XCHG s0, s2
        PUSHINT 267
        DICTSETB
        GETGLOB 14
        ROT
        SWAP
        PUSHINT 267
        DICTGETNEXT
        NULLSWAPIFNOT2
        XCHG s1, s2
      }>
      2DROP
      CALLDICT 185
      NEWC
      PUSHINT 3061173925
      SWAP
      STU 32
      XCHG2 s0, s3
      SWAP
      STU 64
      XCHG s1, s2
      STDICT
      PUSH s2
      SEMPTY
      NOT
      IF:<{
        ROT
        STSLICER
        SWAP
      }>ELSE<{
        POP s2
      }>
      PUSHINT 0
      XCHG s0, s2
      ENDC
      XCHG s1, s2
      CALLDICT 55
      PUSHINT 64
      SENDRAWMSG
      PUSHINT -1
    }>
    XCHG s0, s3
    PUSHINT 133294794
    EQUAL
    IFJMP:<{
      XCHG s0, s2
      LDMSGADDR
      MYADDR
      GETGLOB 15
      XCHG3 s1, s3, s0
      XCHG s0, s2
      PUSHINT 0
      XCHG s0, s2
      PUSHNULL
      PUSHNULL
      NEWC
      XCHG2 s0, s4
      STSLICER
      ROT
      STSLICER
      XCHG s1, s2
      STDICT
      STDICT
      ENDC
      OVER
      NEWC
      STU 2
      XCHG s1, s3
      STDICT
      XCHG s1, s2
      STDICT
      STU 1
      ENDC
      HASHCU
      PUSHINT 0
      PUSHINT 4
      NEWC
      STU 3
      STI 8
      STU 256
      ENDC
      CTOS
      NEWC
      PUSHINT 3237028662
      SWAP
      STU 32
      XCHG2 s0, s3
      SWAP
      STU 64
      ROT
      STSLICER
      OVER
      SEMPTY
      NOT
      IF:<{
        SWAP
        STSLICER
      }>ELSE<{
        NIP
      }>
      PUSHINT 0
      SWAP
      ENDC
      CALLDICT 55
      PUSHINT 64
      SENDRAWMSG
      PUSHINT -1
    }>
    BLKDROP 3
    PUSHINT 0
  }>
  68369 => <{
    CALLDICT 184
    MYADDR
    GETGLOB 15
    XCHG s1, s2
    XCHG s0, s2
    PUSHINT 0
    XCHG s0, s2
    PUSHNULL
    PUSHNULL
    NEWC
    XCHG2 s0, s4
    STSLICER
    ROT
    STSLICER
    XCHG s1, s2
    STDICT
    STDICT
    ENDC
    OVER
    NEWC
    STU 2
    XCHG s1, s3
    STDICT
    XCHG s1, s2
    STDICT
    STU 1
    ENDC
    HASHCU
    PUSHINT 0
    PUSHINT 4
    NEWC
    STU 3
    STI 8
    STU 256
    ENDC
    CTOS
  }>
  81689 => <{
    CALLDICT 184
    TUPLE 0
    GETGLOB 14
    PUSHINT 267
    DICTMIN
    NULLSWAPIFNOT2
    XCHG s1, s2
    WHILE:<{
    }>DO<{
      LDREFRTOS
      LDMSGADDR
      LDMSGADDR
      LDREF
      LDU 14
      SWAP
      SWAP
      LDU 14
      SWAP
      SWAP
      LDI 1
      SWAP
      SWAP
      LDI 1
      SWAP
      NIP
      TUPLE 7
      UNTUPLE 7
      XCHG s0, s7
      LDU 40
      SWAP
      SWAP
      LDGRAMS
      LDGRAMS
      LDGRAMS
      LDGRAMS
      LDGRAMS
      LDGRAMS
      LDGRAMS
      BLKSWAP 8, 1
      TUPLE 8
      UNTUPLE 8
      TUPLE 0
      XCHG2 s0, s8
      TPUSH
      XCHG2 s0, s6
      TPUSH
      XCHG2 s0, s4
      TPUSH
      ROT
      TPUSH
      SWAP
      TPUSH
      SWAP
      TPUSH
      SWAP
      TPUSH
      SWAP
      TPUSH
      XCHG2 s0, s7
      TPUSH
      XCHG2 s0, s5
      TPUSH
      XCHG2 s0, s3
      TPUSH
      SWAP
      TPUSH
      SWAP
      TPUSH
      SWAP
      TPUSH
      ROT
      TPUSH
      NIP
      OVER
      TPUSH
      XCHG s1, s2
      TPUSH
      GETGLOB 14
      ROT
      SWAP
      PUSHINT 267
      DICTGETNEXT
      NULLSWAPIFNOT2
      XCHG s1, s2
    }>
    2DROP
    GETGLOB 1
    GETGLOB 2
    GETGLOB 3
    GETGLOB 4
    GETGLOB 5
    GETGLOB 6
    GETGLOB 7
    GETGLOB 8
    GETGLOB 9
    GETGLOB 10
    GETGLOB 11
    GETGLOB 12
    GETGLOB 13
    GETGLOB 25
    GETGLOB 15
    XCHG s14, s15
    XCHG s13, s14
    XCHG s12, s13
    XCHG s11, s12
    XCHG s10, s11
    XCHG s9, s10
    XCHG s8, s9
    XCHG s7, s8
    XCHG s6, s7
    XCHG s5, s6
    XCHG s4, s5
    XCHG s3, s4
    XCHG s2, s3
  }>
  113417 => <{
    DROP
    CONT:<{
      PUSH c4
      PUSH c5
      PUSH c7
      CONT:<{
        2DROP
        THROW 1024
      }>
      SETCONTCTR c7
      SETCONTCTR c5
      SETCONTCTR c4
      CONT:<{
        CALLDICT 184
      }>
      PUSH c1
      BOOLOR
      SWAP
      TRY
    }>
    CALLXARGS 0, -1
  }>
  117047 => <{
    SWAP
    CALLDICT 100
    XCHG3 s3, s0, s3
    NOW
    CALLDICT 114
  }>
}
THROWARG 11
