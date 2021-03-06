/*********************************************************************/
/*                                                                   */
/*             Optimized BLAS libraries                              */
/*                     By Kazushige Goto <kgoto@tacc.utexas.edu>     */
/*                                                                   */
/* Copyright (c) The University of Texas, 2009. All rights reserved. */
/* UNIVERSITY EXPRESSLY DISCLAIMS ANY AND ALL WARRANTIES CONCERNING  */
/* THIS SOFTWARE AND DOCUMENTATION, INCLUDING ANY WARRANTIES OF      */
/* MERCHANTABILITY, FITNESS FOR ANY PARTICULAR PURPOSE,              */
/* NON-INFRINGEMENT AND WARRANTIES OF PERFORMANCE, AND ANY WARRANTY  */
/* THAT MIGHT OTHERWISE ARISE FROM COURSE OF DEALING OR USAGE OF     */
/* TRADE. NO WARRANTY IS EITHER EXPRESS OR IMPLIED WITH RESPECT TO   */
/* THE USE OF THE SOFTWARE OR DOCUMENTATION.                         */
/* Under no circumstances shall University be liable for incidental, */
/* special, indirect, direct or consequential damages or loss of     */
/* profits, interruption of business, or related expenses which may  */
/* arise from use of Software or Documentation, including but not    */
/* limited to those resulting from defects in Software and/or        */
/* Documentation, or loss or inaccuracy of data of any kind.         */
/*********************************************************************/

#define ASSEMBLER
#include "common.h"

#if defined(OPTERON) || defined(BARCELONA)
#define PREFETCH	prefetch
#define PREFETCHW	prefetchw
#else
#define PREFETCH	prefetcht0
#define PREFETCHW	prefetcht0
#endif

#define PREFETCHSIZE (5 + 4 * 10)
#define STACK	16
#define ARGS	16
	
#define J	 0 + STACK(%esp)
#define KK	 4 + STACK(%esp)
#define KKK	 8 + STACK(%esp)

#define M	 4 + STACK + ARGS(%esp)
#define N	 8 + STACK + ARGS(%esp)
#define K	12 + STACK + ARGS(%esp)
#define ALPHA	16 + STACK + ARGS(%esp)
#define A	32 + STACK + ARGS(%esp)
#define ARG_B	36 + STACK + ARGS(%esp)
#define C	40 + STACK + ARGS(%esp)
#define ARG_LDC	44 + STACK + ARGS(%esp)
#define OFFSET	48 + STACK + ARGS(%esp)

#define I	%esi
#define B	%ebx
#define CO	%edi
#define AO	%edx
#define BO	%ecx
#define LDC	%ebp

#define PREFETCH_OFFSET 48

	PROLOGUE

	subl	$ARGS, %esp	# Generate Stack Frame

	pushl	%ebp
	pushl	%edi
	pushl	%esi
	pushl	%ebx

	PROFCODE

#if defined(TRMMKERNEL) && !defined(LEFT)
	movl	OFFSET, %eax
	negl	%eax
	movl	%eax, KK
#endif
	
	movl	ARG_LDC, LDC
	movl	ARG_B,   B

	addl	$8 * SIZE, A
	addl	$8 * SIZE, B
	
	sall	$BASE_SHIFT, LDC

	movl	N,   %eax
	sarl	$1,  %eax
	movl	%eax, J
	je	.L30
	ALIGN_4

.L01:
#if defined(TRMMKERNEL) && defined(LEFT)
	movl	OFFSET, %eax
	movl	%eax, KK
#endif	

	movl	A, AO

	movl	C, CO
	lea	(, LDC, 2), %eax
	addl	%eax, C

	movl	M,  I
	sarl	$1, I
	je	.L20
	ALIGN_4

.L11:
#if !defined(TRMMKERNEL) || \
	(defined(TRMMKERNEL) &&  defined(LEFT) &&  defined(TRANSA)) || \
	(defined(TRMMKERNEL) && !defined(LEFT) && !defined(TRANSA))
	movl	B, BO
#else
	movl	KK,   %eax
	sall	$BASE_SHIFT, %eax
	leal	(AO, %eax, 2), AO
	leal	(B,  %eax, 2), BO
#endif	

	fldz
	fldz
	fldz
	fldz

#if   defined(HAVE_3DNOW)
	prefetchw	2 * SIZE(CO)
 	prefetchw	2 * SIZE(CO, LDC, 1)
#elif defined(HAVE_SSE)
	prefetchnta	2 * SIZE(CO)
 	prefetchnta	2 * SIZE(CO, LDC, 1)
#endif

#ifndef TRMMKERNEL
	movl	K, %eax
#elif (defined(LEFT) && !defined(TRANSA)) || (!defined(LEFT) && defined(TRANSA))
	movl	K, %eax
	subl	KK, %eax
	movl	%eax, KKK	
#else
	movl	KK, %eax
#ifdef LEFT
	addl	$2, %eax
#else
	addl	$2, %eax
#endif
	movl	%eax, KKK
#endif
	sarl	$2, %eax
 	je	.L15
	ALIGN_4

.L12:
	PREFETCH	(PREFETCHSIZE + 0) * SIZE(AO)

	FLD	 -8 * SIZE(AO)

	FLD	 -8 * SIZE(BO)
	fld	 %st(1)
	fmul	 %st(1), %st
	faddp	 %st, %st(3)

	FLD	 -7 * SIZE(BO)
	fmul	 %st, %st(2)
	 
	FLD	 -7 * SIZE(AO)
	fmul	 %st, %st(2)
	fmulp	 %st, %st(1)

	faddp	 %st, %st(6)
	faddp	 %st, %st(3)
	faddp	 %st, %st(3)

	FLD	 -6 * SIZE(AO)

	FLD	 -6 * SIZE(BO)
	fld	 %st(1)
	fmul	 %st(1), %st
	faddp	 %st, %st(3)

	FLD	 -5 * SIZE(BO)
	fmul	 %st, %st(2)
	 
	FLD	 -5 * SIZE(AO)
	fmul	 %st, %st(2)
	fmulp	 %st, %st(1)

	faddp	 %st, %st(6)
	faddp	 %st, %st(3)
	faddp	 %st, %st(3)

	PREFETCH	(PREFETCHSIZE + 4) * SIZE(AO)

	FLD	 -4 * SIZE(AO)

	FLD	 -4 * SIZE(BO)
	fld	 %st(1)
	fmul	 %st(1), %st
	faddp	 %st, %st(3)

	FLD	 -3 * SIZE(BO)
	fmul	 %st, %st(2)
	 
	FLD	 -3 * SIZE(AO)
	fmul	 %st, %st(2)
	fmulp	 %st, %st(1)

	faddp	 %st, %st(6)
	faddp	 %st, %st(3)
	faddp	 %st, %st(3)

	FLD	 -2 * SIZE(AO)

	FLD	 -2 * SIZE(BO)
	fld	 %st(1)
	fmul	 %st(1), %st
	faddp	 %st, %st(3)

	FLD	 -1 * SIZE(BO)
	fmul	 %st, %st(2)
	 
	FLD	 -1 * SIZE(AO)
	fmul	 %st, %st(2)
	fmulp	 %st, %st(1)

	faddp	 %st, %st(6)
	faddp	 %st, %st(3)
	faddp	 %st, %st(3)

	addl	$8 * SIZE,AO
	addl	$8 * SIZE,BO

	decl	%eax
	jne	.L12
	ALIGN_4

.L15:
#ifndef TRMMKERNEL
	movl	K, %eax
#else
	movl	KKK, %eax
#endif
	and	$3,  %eax
	je	.L18
	ALIGN_4

.L16:
	FLD	 -8 * SIZE(AO)

	FLD	 -8 * SIZE(BO)
	fld	 %st(1)
	fmul	 %st(1), %st
	faddp	 %st, %st(3)

	FLD	 -7 * SIZE(BO)
	fmul	 %st, %st(2)
	 
	FLD	 -7 * SIZE(AO)
	fmul	 %st, %st(2)
	fmulp	 %st, %st(1)

	faddp	 %st, %st(6)
	faddp	 %st, %st(3)
	faddp	 %st, %st(3)

	addl	$2 * SIZE,AO
	addl	$2 * SIZE,BO

	decl	%eax
	jne	 .L16
	ALIGN_4

.L18:
#ifndef TRMMKERNEL
	FLD	ALPHA

	fmul	%st, %st(1)
	fmul	%st, %st(2)
	fmul	%st, %st(3)
	fmulp	%st, %st(4)

	FLD	0 * SIZE(CO)
	faddp	%st, %st(1)
	FST	0 * SIZE(CO)

	FLD	1 * SIZE(CO)
	faddp	%st, %st(1)
	FST	1 * SIZE(CO)

	FLD	0 * SIZE(CO, LDC)
	faddp	%st, %st(1)
	FST	0 * SIZE(CO, LDC)

	FLD	1 * SIZE(CO, LDC)
	faddp	%st, %st(1)
	FST	1 * SIZE(CO, LDC)
#else
	FST	0 * SIZE(CO)
	FST	1 * SIZE(CO)
	FST	0 * SIZE(CO, LDC)
	FST	1 * SIZE(CO, LDC)
#endif

#if (defined(TRMMKERNEL) &&  defined(LEFT) &&  defined(TRANSA)) || \
    (defined(TRMMKERNEL) && !defined(LEFT) && !defined(TRANSA))
	movl	K, %eax
	subl	KKK, %eax
	sall	$BASE_SHIFT, %eax
	leal	(AO, %eax, 2), AO
	leal	(BO, %eax, 2), BO
#endif

#if defined(TRMMKERNEL) && defined(LEFT)
	addl	$2, KK
#endif

	addl	$2 * SIZE, CO
	decl	I
	jne	.L11
	ALIGN_4

.L20:
	movl	 M, %eax
	andl	$1, %eax
	je	.L29
	ALIGN_4

.L21:
#if !defined(TRMMKERNEL) || \
	(defined(TRMMKERNEL) &&  defined(LEFT) &&  defined(TRANSA)) || \
	(defined(TRMMKERNEL) && !defined(LEFT) && !defined(TRANSA))
	movl	B, BO
#else
	movl	KK,   %eax
	sall	$BASE_SHIFT, %eax
	leal	(AO, %eax, 1), AO
	leal	( B, %eax, 2), BO
#endif	

	fldz
	fldz

#ifndef TRMMKERNEL
	movl	K, %eax
#elif (defined(LEFT) && !defined(TRANSA)) || (!defined(LEFT) && defined(TRANSA))
	movl	K, %eax
	subl	KK, %eax
	movl	%eax, KKK	
#else
	movl	KK, %eax
#ifdef LEFT
	addl	$1, %eax
#else
	addl	$2, %eax
#endif
	movl	%eax, KKK
#endif
	sarl	$2, %eax
 	je	.L25
	ALIGN_4

.L22:
	PREFETCH	(PREFETCHSIZE + 0) * SIZE(AO)

	FLD	 -8 * SIZE(AO)

	FLD	 -8 * SIZE(BO)
	fmul	 %st(1), %st
	faddp	 %st, %st(2)

	FLD	 -7 * SIZE(BO)
	fmulp	 %st, %st(1)
	faddp	 %st, %st(2)

	FLD	 -7 * SIZE(AO)

	FLD	 -6 * SIZE(BO)
	fmul	 %st(1), %st
	faddp	 %st, %st(2)

	FLD	 -5 * SIZE(BO)
	fmulp	 %st, %st(1)
	faddp	 %st, %st(2)

	FLD	 -6 * SIZE(AO)

	FLD	 -4 * SIZE(BO)
	fmul	 %st(1), %st
	faddp	 %st, %st(2)

	FLD	 -3 * SIZE(BO)
	fmulp	 %st, %st(1)
	faddp	 %st, %st(2)

	FLD	 -5 * SIZE(AO)

	FLD	 -2 * SIZE(BO)
	fmul	 %st(1), %st
	faddp	 %st, %st(2)

	FLD	 -1 * SIZE(BO)
	fmulp	 %st, %st(1)
	faddp	 %st, %st(2)

	addl	$4 * SIZE,AO
	addl	$8 * SIZE,BO

	decl	%eax
	jne	.L22
	ALIGN_4

.L25:
#ifndef TRMMKERNEL
	movl	K, %eax
#else
	movl	KKK, %eax
#endif
	and	$3,  %eax
	je	.L28
	ALIGN_4

.L26:
	FLD	 -8 * SIZE(AO)

	FLD	 -8 * SIZE(BO)
	fmul	 %st(1), %st
	faddp	 %st, %st(2)

	FLD	 -7 * SIZE(BO)
	fmulp	 %st, %st(1)
	faddp	 %st, %st(2)

	addl	$1 * SIZE,AO
	addl	$2 * SIZE,BO

	decl	%eax
	jne	 .L26
	ALIGN_4

.L28:
#ifndef TRMMKERNEL
	FLD	ALPHA

	fmul	%st, %st(1)
	fmulp	%st, %st(2)

	FLD	0 * SIZE(CO)
	faddp	%st, %st(1)
	FST	0 * SIZE(CO)

	FLD	0 * SIZE(CO, LDC)
	faddp	%st, %st(1)
	FST	0 * SIZE(CO, LDC)
#else
	FST	0 * SIZE(CO)
	FST	0 * SIZE(CO, LDC)
#endif

#if (defined(TRMMKERNEL) &&  defined(LEFT) &&  defined(TRANSA)) || \
    (defined(TRMMKERNEL) && !defined(LEFT) && !defined(TRANSA))
	movl	K, %eax
	subl	KKK, %eax
	sall	$BASE_SHIFT, %eax
	leal	(AO, %eax, 1), AO
	leal	(BO, %eax, 2), BO
#endif

#if defined(TRMMKERNEL) && defined(LEFT)
	addl	$1, KK
#endif

	addl	$1 * SIZE, CO
	ALIGN_4

.L29:
#if defined(TRMMKERNEL) && !defined(LEFT)
	addl	$2, KK
#endif

	movl	BO, B
	decl	J
	jne	.L01
	ALIGN_4

.L30:
	movl	N,  %eax
	testl	$1, %eax	
	je	.L999

#if defined(TRMMKERNEL) && defined(LEFT)
	movl	OFFSET, %eax
	movl	%eax, KK
#endif	

	movl	A, AO

	movl	C, CO
	addl	LDC, C

	movl	M,  I
	sarl	$1, I
	je	.L40
	ALIGN_4

.L31:
#if !defined(TRMMKERNEL) || \
	(defined(TRMMKERNEL) &&  defined(LEFT) &&  defined(TRANSA)) || \
	(defined(TRMMKERNEL) && !defined(LEFT) && !defined(TRANSA))
	movl	B, BO
#else
	movl	KK,   %eax
	sall	$BASE_SHIFT, %eax
	leal	(AO, %eax, 2), AO
	leal	( B, %eax, 1), BO
#endif	

	fldz
	fldz

#if   defined(HAVE_3DNOW)
	prefetchw	2 * SIZE(CO)
#elif defined(HAVE_SSE)
	prefetchnta	2 * SIZE(CO)
#endif

#ifndef TRMMKERNEL
	movl	K, %eax
#elif (defined(LEFT) && !defined(TRANSA)) || (!defined(LEFT) && defined(TRANSA))
	movl	K, %eax
	subl	KK, %eax
	movl	%eax, KKK	
#else
	movl	KK, %eax
#ifdef LEFT
	addl	$2, %eax
#else
	addl	$1, %eax
#endif
	movl	%eax, KKK
#endif
	sarl	$2, %eax
 	je	.L35
	ALIGN_4

.L32:
	PREFETCH	(PREFETCHSIZE + 0) * SIZE(AO)

	FLD	 -8 * SIZE(BO)
	FLD	 -8 * SIZE(AO)
	fmul	 %st(1), %st
	faddp	 %st, %st(2)

	FLD	 -7 * SIZE(AO)
	fmulp	 %st, %st(1)
	faddp	 %st, %st(2)

	FLD	 -7 * SIZE(BO)
	FLD	 -6 * SIZE(AO)
	fmul	 %st(1), %st
	faddp	 %st, %st(2)

	FLD	 -5 * SIZE(AO)
	fmulp	 %st, %st(1)
	faddp	 %st, %st(2)

	FLD	 -6 * SIZE(BO)
	FLD	 -4 * SIZE(AO)
	fmul	 %st(1), %st
	faddp	 %st, %st(2)

	FLD	 -3 * SIZE(AO)
	fmulp	 %st, %st(1)
	faddp	 %st, %st(2)

	FLD	 -5 * SIZE(BO)
	FLD	 -2 * SIZE(AO)
	fmul	 %st(1), %st
	faddp	 %st, %st(2)

	FLD	 -1 * SIZE(AO)
	fmulp	 %st, %st(1)
	faddp	 %st, %st(2)

	addl	$8 * SIZE,AO
	addl	$4 * SIZE,BO

	decl	%eax
	jne	.L32
	ALIGN_4

.L35:
#ifndef TRMMKERNEL
	movl	K, %eax
#else
	movl	KKK, %eax
#endif
	and	$3,  %eax
	je	.L38
	ALIGN_4

.L36:
	FLD	 -8 * SIZE(BO)

	FLD	 -8 * SIZE(AO)
	fmul	 %st(1), %st
	faddp	 %st, %st(2)

	FLD	 -7 * SIZE(AO)
	fmulp	 %st, %st(1)
	faddp	 %st, %st(2)

	addl	$2 * SIZE,AO
	addl	$1 * SIZE,BO

	decl	%eax
	jne	 .L36
	ALIGN_4

.L38:
#ifndef TRMMKERNEL
	FLD	ALPHA

	fmul	%st, %st(1)
	fmulp	%st, %st(2)

	FLD	0 * SIZE(CO)
	faddp	%st, %st(1)
	FST	0 * SIZE(CO)

	FLD	1 * SIZE(CO)
	faddp	%st, %st(1)
	FST	1 * SIZE(CO)
#else
	FST	0 * SIZE(CO)
	FST	1 * SIZE(CO)
#endif

#if (defined(TRMMKERNEL) &&  defined(LEFT) &&  defined(TRANSA)) || \
    (defined(TRMMKERNEL) && !defined(LEFT) && !defined(TRANSA))
	movl	K, %eax
	subl	KKK, %eax
	sall	$BASE_SHIFT, %eax
	leal	(AO, %eax, 2), AO
	leal	(BO, %eax, 1), BO
#endif

#if defined(TRMMKERNEL) && defined(LEFT)
	addl	$2, KK
#endif

	addl	$2 * SIZE, CO
	decl	I
	jne	.L31
	ALIGN_4

.L40:
	movl	 M, %eax
	andl	$1, %eax
	je	.L49
	ALIGN_4

.L41:
#if !defined(TRMMKERNEL) || \
	(defined(TRMMKERNEL) &&  defined(LEFT) &&  defined(TRANSA)) || \
	(defined(TRMMKERNEL) && !defined(LEFT) && !defined(TRANSA))
	movl	B, BO
#else
	movl	KK,   %eax
	sall	$BASE_SHIFT, %eax
	leal	(AO, %eax, 1), AO
	leal	( B, %eax, 1), BO
#endif	

	fldz

#ifndef TRMMKERNEL
	movl	K, %eax
#elif (defined(LEFT) && !defined(TRANSA)) || (!defined(LEFT) && defined(TRANSA))
	movl	K, %eax
	subl	KK, %eax
	movl	%eax, KKK	
#else
	movl	KK, %eax
#ifdef LEFT
	addl	$1, %eax
#else
	addl	$1, %eax
#endif
	movl	%eax, KKK
#endif
	sarl	$2, %eax
 	je	.L45
	ALIGN_4

.L42:
	PREFETCH	(PREFETCHSIZE + 0) * SIZE(AO)

	FLD	 -8 * SIZE(AO)
	FLD	 -8 * SIZE(BO)
	fmulp	 %st, %st(1)
	faddp	 %st, %st(1)

	FLD	 -7 * SIZE(AO)
	FLD	 -7 * SIZE(BO)
	fmulp	 %st, %st(1)
	faddp	 %st, %st(1)

	FLD	 -6 * SIZE(AO)
	FLD	 -6 * SIZE(BO)
	fmulp	 %st, %st(1)
	faddp	 %st, %st(1)

	FLD	 -5 * SIZE(AO)
	FLD	 -5 * SIZE(BO)
	fmulp	 %st, %st(1)
	faddp	 %st, %st(1)

	addl	$4 * SIZE,AO
	addl	$4 * SIZE,BO

	decl	%eax
	jne	.L42
	ALIGN_4

.L45:
#ifndef TRMMKERNEL
	movl	K, %eax
#else
	movl	KKK, %eax
#endif
	and	$3,  %eax
	je	.L48
	ALIGN_4

.L46:
	FLD	 -8 * SIZE(AO)

	FLD	 -8 * SIZE(BO)
	fmulp	 %st, %st(1)
	faddp	 %st, %st(1)

	addl	$1 * SIZE,AO
	addl	$1 * SIZE,BO

	decl	%eax
	jne	 .L46
	ALIGN_4

.L48:
#ifndef TRMMKERNEL
	FLD	ALPHA

	fmulp	%st, %st(1)

	FLD	0 * SIZE(CO)
	faddp	%st, %st(1)
	FST	0 * SIZE(CO)
#else
	FST	0 * SIZE(CO)
#endif

#if (defined(TRMMKERNEL) &&  defined(LEFT) &&  defined(TRANSA)) || \
    (defined(TRMMKERNEL) && !defined(LEFT) && !defined(TRANSA))
	movl	K, %eax
	subl	KKK, %eax
	sall	$BASE_SHIFT, %eax
	leal	(AO, %eax, 1), AO
	leal	(BO, %eax, 1), BO
#endif

#if defined(TRMMKERNEL) && defined(LEFT)
	addl	$1, KK
#endif

	addl	$1 * SIZE, CO
	ALIGN_4

.L49:
#if defined(TRMMKERNEL) && !defined(LEFT)
	addl	$1, KK
#endif

	movl	BO, B
	ALIGN_4

.L999:
	popl	%ebx
	popl	%esi
	popl	%edi
	popl	%ebp
	addl	$ARGS, %esp
	ret

	EPILOGUE
