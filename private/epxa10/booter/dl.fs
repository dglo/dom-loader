\
\ test sdram...
\
: tsd0 $00100000 0 $00100000 memtest-stuck-address ;
: tsd1 $00800000 0 $00200000 memtest-stuck-address ;

\
\ print memory by copying it to the stack, then printing the
\ stack...
\
: pmem 0 ?DO dup @ 4 + LOOP drop .s ;

\
\ I2C debugging...
\
: w 2 usleep ;
: ch 1 5 lshift 2 or CPLD 6 + c! ;
: cl 1 5 lshift CPLD 6 + c! ;
: dh 7 1 4 lshift or CPLD 5 + c! ;
: dl 7 CPLD 5 + c! ;
: pc CPLD 6 + c@ 2 and 1 rshift .s drop ;
: pd CPLD 5 + c@ 1 4 lshift and 4 rshift .s drop ;

\ start and end conditions...
: sc dh w ch w dl w cl w;
: ec dl w ch w dh w ;

\ put bit, bit to put is on stack
: pb if dh else dl endif ch w cl w ;

\ byte to put is on stack, ack is left on stack
: pbyte 8 0 ?DO dup 1 7 i - lshift and 7 i - rshift pb LOOP drop rbit;

\ bit read is returned on stack...
: rbit dh ch w CPLD 5 + c@ 1 4 lshift and 4 rshift cl w;

\ ack value is on the stack, byte read is put on the stack...
: rbyte 0 8 0 ?DO rbit 7 i - lshift or LOOP swap pb;

\ read cfg, ack ack cfg
: rcfg sc $90 pbyte drop $ac pbyte drop sc $91 pbyte drop 0 rbyte ec;
: tcvt ;
: trd ;

