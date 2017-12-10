;;; ok wow I don't know AVR assembly, let's learn it

	.global test_func
	.global test_func_init
	.global what_is_five
	.global test_get

	.section .bss
_test_string:
	.space 30

	.section .text

;;; ========================================
;;; Either set a buffer to copy or copy a buffer somewhere.
;;;
;;; C-callable
;;; r25:r24: pointer to buffer
;;; r22: true if initializing
;;; ========================================
	.global	buffer_test
	.section .text.buffer_test
buffer_test:
	ldi	XH, hi8(_test_string)
	ldi	XL, lo8(_test_string)

	mov	YH, r25
	mov	YL, r24

	;; done with setup; stay for initializing, branch for copy buffer out
	cpi	r22, 0
	breq	0f

1:				;inner loop for initializing
	ld	r16, Y+
	st	X+, r16
	cpi	r16, 0
	brne 1b
	ret
0: 				;we're here if r22 was false (so, not initializing)
	ld	r16, X+
	st	Y+, r16
	cpi	r16, 0
	brne 0b
	
	ret

;;; ========================================
;;; Get some value dependent on whatever test I want to run
;;;
;;; C-callable
;;; returns: (unsigned int) r25:24
;;; ========================================
	.section .text.test_get
test_get:
	ldi	YL, lo8(_test_string)
	ldi	YH, hi8(_test_string)

	;; lds	YH, hi8(_test_string)
	;; lds	YL, _test_string

	;; mov	ZH, r25
	;; mov	ZL, r24
	ld	r20, Y

	;; 07AE
	;; ldi	r25, hi8(_test_string)
	;; ldi	r24, lo8(_test_string)
	;; lds	r16, 0x07AE
	
	;; ld	r16, Y

	clr	r25
	mov	r24, r20
	ret
	
;; ;;; ========================================
;; ;;; Get the value of 5.
;; ;;; 
;; ;;; C-callable
;; ;;; returns: (unsigned int) r25:r24
;; ;;; ========================================
;; 	.section .text.what_is_five
;; what_is_five:
;; 	clr	r25
;; 	clr	r24
;; 	;; ldi	r25, 1
;; 	ldi	r24, 5
;; 	ret
