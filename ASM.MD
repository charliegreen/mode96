# So you want to be an AVR assembly programmer?

That's right! With just this ONE WEIRD DOCUMENT, YOU TOO can become one!!!!

# overview

A word is two bytes.

# registers

They come in pairs, for pointer addressing! r24 and r25 are paired, r26 and r27, etc, up to r30 and
r31.

Note that some registers have special features:
	* r1:r0: receive result of `mul` instruction
	* r0-r15: cannot use `ldi`
	* r27:r26 = X = XH:XL
	* r29:r28 = Y = YH:YL
	* r31:r30 = Z = ZH:ZL

# calling conventions
## arguments
Start at r25 and go down. Each argument spans two registers, even if it's a one-byte argument. eg:

	void PrintInt(int x, int y, unsigned int, bool zeropad)

Maps to:

	PrintInt(r25:r24, r23:r22, r21:r20, r18)

## return values

<!-- Always returns a whole word in the r24:r25 register pair, regardless of size of return -->
<!-- type. -->

Byte-sized returns are in r24, word-sized in r24:r25

## registers

call-used (ie potentially trashed by C calls): r18-r27, r30-r31
call-saved: r2-r17, r28-r29

# instructions
## I/O (to RAM or elsewhere)
| name      | cycles | notes                                         |
|-----------+--------+-----------------------------------------------|
| out       |      1 |                                               |
| in        | 2 or 3 | 2 for I/O space, 3 for RAM                    |
| ld rN,X   |      2 |                                               |
| ld rN,X+  |      2 |                                               |
| ld rN,-X  |      3 |                                               |
| ld rN,X+q |      3 | does not modify X, loads from offset          |
| xch       |      2 | exchange reg with *Z in RAM, doesn't modify Z |
| lds       |      3 |                                               |
| push      |      1 |                                               |
| pop       |      2 |                                               |
| ldi       |      1 |                                               |

## data
| name | cycles | notes             |
|------+--------+-------------------|
| mul  |      2 | output in r1:r0   |
| add  |      1 |                   |
| adc  |      1 |                   |
| movw |      1 |                   |
| dec  |      1 |                   |
| lsl  |      1 |                   |
| swap |      1 |                   |
| andi |      1 | r16-r31 only      |
| adiw |      2 | immediate is 0-63 |

## branching
| name  |                cycles |
|-------+-----------------------|
| breq  | 1 if false, 2 if true |
| ijmp  |                     2 |
| rcall |                     2 |
| call  |                     4 |
| icall |                     2 |
| ret   |                     4 |
| rjmp  |                     2 |
| jmp   |                     3 |

# I/O space
## addressing quirks
I/O space registers, with I/O addresses from 0x00 to 0x3F, can be read with `in` and written to with
`out`; they can also be modified directly with `ld`/`st` and variants at addresses in SRAM from 0x20
to 0x5F (add 0x20 to the `in`/`out` I/O-space addresses to get SRAM addresses). Any I/O registers
above this range must be accessed directly through SRAM with `ld`/`st` and variants. This also means
that, for registers above this range, there is no need to add 0x20 to the given address.

## specific registers
### TCNT1

This is a CPU cycle counter.
