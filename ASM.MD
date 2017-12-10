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
## cycle count

| instruction |           cycle count |
|-------------+-----------------------|
| out         |                     1 |
| ld          |                     3 |
| mul         |                     2 |
| add         |                     1 |
| adc         |                     1 |
| movw        |                     1 |
| dec         |                     1 |
| breq        | 1 if false, 2 if true |
| ijmp        |                     2 |
| lsl         |                     1 |
| rcall       |                     2 |
| call        |                     4 |
| icall       |                     2 |
| ret         |                     4 |
| push        |                     1 |
| pop         |                     2 |
| rjmp        |                     2 |
| jmp         |                     3 |

