/* See COPYRIGHT for copyright information. */

#include <inc/mmu.h>
#include <inc/memlayout.h>
#include <inc/trap.h>



###################################################################
# exceptions/interrupts
###################################################################

/* TRAPHANDLER defines a globally-visible function for handling a trap.
 * It pushes a trap number onto the stack, then jumps to _alltraps.
 * Use TRAPHANDLER for traps where the CPU automatically pushes an error code.
 *
 * You shouldn't call a TRAPHANDLER function from C, but you may
 * need to _declare_ one in C (for instance, to get a function pointer
 * during IDT setup).  You can declare the function with
 *   void NAME();
 * where NAME is the argument passed to TRAPHANDLER.
 */
#define TRAPHANDLER(name, num)						\
	.globl name;		/* define global symbol for 'name' */	\
	.type name, @function;	/* symbol type is function */		\
	.align 2;		/* align function definition */		\
	name:			/* function starts here */		\
	pushl $(num);							\
	jmp _alltraps

/* Use TRAPHANDLER_NOEC for traps where the CPU doesn't push an error code.
 * It pushes a 0 in place of the error code, so the trap frame has the same
 * format in either case.
 */
#define TRAPHANDLER_NOEC(name, num)					\
	.globl name;							\
	.type name, @function;						\
	.align 2;							\
	name:								\
	pushl $0;							\
	pushl $(num);							\
	jmp _alltraps

.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
/*
		TRAPHANDLER_NOEC(t_divide, T_DIVIDE)
TRAPHANDLER_NOEC(t_debug, T_DEBUG)
TRAPHANDLER_NOEC(t_nmi, T_NMI)
TRAPHANDLER_NOEC(t_brkpt, T_BRKPT)
TRAPHANDLER_NOEC(t_oflow, T_OFLOW)
TRAPHANDLER_NOEC(t_bound, T_BOUND)
TRAPHANDLER_NOEC(t_illop, T_ILLOP)
TRAPHANDLER_NOEC(t_device, T_DEVICE)
TRAPHANDLER(t_dblflt, T_DBLFLT)
TRAPHANDLER(t_tss, T_TSS)
TRAPHANDLER(t_segnp, T_SEGNP)
TRAPHANDLER(t_stack, T_STACK)
TRAPHANDLER(t_gpflt, T_GPFLT)
TRAPHANDLER(t_pgflt, T_PGFLT)
TRAPHANDLER_NOEC(t_fperr, T_FPERR)
TRAPHANDLER(t_align, T_ALIGN)
TRAPHANDLER_NOEC(t_mchk, T_MCHK)
TRAPHANDLER_NOEC(t_simderr, T_SIMDERR)

TRAPHANDLER_NOEC(t_syscall, T_SYSCALL)
*/
	TRAPHANDLER_NOEC(T_DIVIDE_H, T_DIVIDE)
TRAPHANDLER_NOEC(T_DEBUG_H, T_DEBUG)
TRAPHANDLER_NOEC(T_NMI_H, T_NMI)
TRAPHANDLER_NOEC(T_BRKPT_H, T_BRKPT)
TRAPHANDLER_NOEC(T_OFLOW_H, T_OFLOW)
TRAPHANDLER_NOEC(T_BOUND_H, T_BOUND)
TRAPHANDLER_NOEC(T_ILLOP_H, T_ILLOP)
TRAPHANDLER_NOEC(T_DEVICE_H, T_DEVICE)
TRAPHANDLER(T_DBLFLT_H, T_DBLFLT)
TRAPHANDLER(T_TSS_H, T_TSS)
TRAPHANDLER(T_SEGNP_H, T_SEGNP)
TRAPHANDLER(T_STACK_H, T_STACK)
TRAPHANDLER(T_GPFLT_H, T_GPFLT)
TRAPHANDLER(T_PGFLT_H, T_PGFLT)
TRAPHANDLER_NOEC(T_FPERR_H, T_FPERR)
TRAPHANDLER(T_ALIGN_H, T_ALIGN)
TRAPHANDLER_NOEC(T_MCHK_H, T_MCHK)
TRAPHANDLER_NOEC(T_SIMDERR_H, T_SIMDERR)
TRAPHANDLER_NOEC(T_SYSCALL_H, T_SYSCALL)
TRAPHANDLER_NOEC(T_DEFAULT_H, T_DEFAULT)


/*
 * Lab 3: Your code here for _alltraps
 */

_alltraps:
	pushl %ds
	pushl %es
	pushal
	# load GD_KD into %ds and %es
	movw $GD_KD, %ax
	movw %ax, %ds
	movw %ax, %es
	# pushl %esp to pass a pointer to the Trapframe as an argument to trap()
	pushl %esp
	# call trap (can trap ever return?)
	call trap
