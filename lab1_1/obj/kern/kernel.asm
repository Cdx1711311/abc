
obj/kern/kernel：     文件格式 elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# physical addresses [0, 4MB).  This 4MB region will be suffice
	# until we set up our real page table in i386_vm_init in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5f 00 00 00       	call   f010009d <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 14             	sub    $0x14,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010004e:	c7 04 24 60 1a 10 f0 	movl   $0xf0101a60,(%esp)
f0100055:	e8 8f 09 00 00       	call   f01009e9 <cprintf>
	if (x > 0)
f010005a:	85 db                	test   %ebx,%ebx
f010005c:	7e 0d                	jle    f010006b <test_backtrace+0x2b>
		test_backtrace(x-1);
f010005e:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100061:	89 04 24             	mov    %eax,(%esp)
f0100064:	e8 d7 ff ff ff       	call   f0100040 <test_backtrace>
f0100069:	eb 1c                	jmp    f0100087 <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f010006b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100072:	00 
f0100073:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010007a:	00 
f010007b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100082:	e8 ff 06 00 00       	call   f0100786 <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 7c 1a 10 f0 	movl   $0xf0101a7c,(%esp)
f0100092:	e8 52 09 00 00       	call   f01009e9 <cprintf>
}
f0100097:	83 c4 14             	add    $0x14,%esp
f010009a:	5b                   	pop    %ebx
f010009b:	5d                   	pop    %ebp
f010009c:	c3                   	ret    

f010009d <i386_init>:

void
i386_init(void)
{
f010009d:	55                   	push   %ebp
f010009e:	89 e5                	mov    %esp,%ebp
f01000a0:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a3:	b8 60 29 11 f0       	mov    $0xf0112960,%eax
f01000a8:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 00 23 11 f0 	movl   $0xf0112300,(%esp)
f01000c0:	e8 ca 14 00 00       	call   f010158f <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 a5 04 00 00       	call   f010056f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 97 1a 10 f0 	movl   $0xf0101a97,(%esp)
f01000d9:	e8 0b 09 00 00       	call   f01009e9 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f1:	e8 5c 07 00 00       	call   f0100852 <monitor>
f01000f6:	eb f2                	jmp    f01000ea <i386_init+0x4d>

f01000f8 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000f8:	55                   	push   %ebp
f01000f9:	89 e5                	mov    %esp,%ebp
f01000fb:	56                   	push   %esi
f01000fc:	53                   	push   %ebx
f01000fd:	83 ec 10             	sub    $0x10,%esp
f0100100:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100103:	83 3d 00 23 11 f0 00 	cmpl   $0x0,0xf0112300
f010010a:	75 3d                	jne    f0100149 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f010010c:	89 35 00 23 11 f0    	mov    %esi,0xf0112300

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f0100112:	fa                   	cli    
f0100113:	fc                   	cld    

	va_start(ap, fmt);
f0100114:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100117:	8b 45 0c             	mov    0xc(%ebp),%eax
f010011a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010011e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100121:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100125:	c7 04 24 b2 1a 10 f0 	movl   $0xf0101ab2,(%esp)
f010012c:	e8 b8 08 00 00       	call   f01009e9 <cprintf>
	vcprintf(fmt, ap);
f0100131:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100135:	89 34 24             	mov    %esi,(%esp)
f0100138:	e8 79 08 00 00       	call   f01009b6 <vcprintf>
	cprintf("\n");
f010013d:	c7 04 24 ee 1a 10 f0 	movl   $0xf0101aee,(%esp)
f0100144:	e8 a0 08 00 00       	call   f01009e9 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100149:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100150:	e8 fd 06 00 00       	call   f0100852 <monitor>
f0100155:	eb f2                	jmp    f0100149 <_panic+0x51>

f0100157 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100157:	55                   	push   %ebp
f0100158:	89 e5                	mov    %esp,%ebp
f010015a:	53                   	push   %ebx
f010015b:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010015e:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100161:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100164:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100168:	8b 45 08             	mov    0x8(%ebp),%eax
f010016b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010016f:	c7 04 24 ca 1a 10 f0 	movl   $0xf0101aca,(%esp)
f0100176:	e8 6e 08 00 00       	call   f01009e9 <cprintf>
	vcprintf(fmt, ap);
f010017b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010017f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100182:	89 04 24             	mov    %eax,(%esp)
f0100185:	e8 2c 08 00 00       	call   f01009b6 <vcprintf>
	cprintf("\n");
f010018a:	c7 04 24 ee 1a 10 f0 	movl   $0xf0101aee,(%esp)
f0100191:	e8 53 08 00 00       	call   f01009e9 <cprintf>
	va_end(ap);
}
f0100196:	83 c4 14             	add    $0x14,%esp
f0100199:	5b                   	pop    %ebx
f010019a:	5d                   	pop    %ebp
f010019b:	c3                   	ret    
f010019c:	66 90                	xchg   %ax,%ax
f010019e:	66 90                	xchg   %ax,%ax

f01001a0 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001a0:	55                   	push   %ebp
f01001a1:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001a3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001a8:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001a9:	a8 01                	test   $0x1,%al
f01001ab:	74 08                	je     f01001b5 <serial_proc_data+0x15>
f01001ad:	b2 f8                	mov    $0xf8,%dl
f01001af:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001b0:	0f b6 c0             	movzbl %al,%eax
f01001b3:	eb 05                	jmp    f01001ba <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001b5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01001ba:	5d                   	pop    %ebp
f01001bb:	c3                   	ret    

f01001bc <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001bc:	55                   	push   %ebp
f01001bd:	89 e5                	mov    %esp,%ebp
f01001bf:	53                   	push   %ebx
f01001c0:	83 ec 04             	sub    $0x4,%esp
f01001c3:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001c5:	eb 2a                	jmp    f01001f1 <cons_intr+0x35>
		if (c == 0)
f01001c7:	85 d2                	test   %edx,%edx
f01001c9:	74 26                	je     f01001f1 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f01001cb:	a1 44 25 11 f0       	mov    0xf0112544,%eax
f01001d0:	8d 48 01             	lea    0x1(%eax),%ecx
f01001d3:	89 0d 44 25 11 f0    	mov    %ecx,0xf0112544
f01001d9:	88 90 40 23 11 f0    	mov    %dl,-0xfeedcc0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01001df:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01001e5:	75 0a                	jne    f01001f1 <cons_intr+0x35>
			cons.wpos = 0;
f01001e7:	c7 05 44 25 11 f0 00 	movl   $0x0,0xf0112544
f01001ee:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001f1:	ff d3                	call   *%ebx
f01001f3:	89 c2                	mov    %eax,%edx
f01001f5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001f8:	75 cd                	jne    f01001c7 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001fa:	83 c4 04             	add    $0x4,%esp
f01001fd:	5b                   	pop    %ebx
f01001fe:	5d                   	pop    %ebp
f01001ff:	c3                   	ret    

f0100200 <kbd_proc_data>:
f0100200:	ba 64 00 00 00       	mov    $0x64,%edx
f0100205:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100206:	a8 01                	test   $0x1,%al
f0100208:	0f 84 ef 00 00 00    	je     f01002fd <kbd_proc_data+0xfd>
f010020e:	b2 60                	mov    $0x60,%dl
f0100210:	ec                   	in     (%dx),%al
f0100211:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100213:	3c e0                	cmp    $0xe0,%al
f0100215:	75 0d                	jne    f0100224 <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f0100217:	83 0d 20 23 11 f0 40 	orl    $0x40,0xf0112320
		return 0;
f010021e:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100223:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100224:	55                   	push   %ebp
f0100225:	89 e5                	mov    %esp,%ebp
f0100227:	53                   	push   %ebx
f0100228:	83 ec 14             	sub    $0x14,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f010022b:	84 c0                	test   %al,%al
f010022d:	79 37                	jns    f0100266 <kbd_proc_data+0x66>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010022f:	8b 0d 20 23 11 f0    	mov    0xf0112320,%ecx
f0100235:	89 cb                	mov    %ecx,%ebx
f0100237:	83 e3 40             	and    $0x40,%ebx
f010023a:	83 e0 7f             	and    $0x7f,%eax
f010023d:	85 db                	test   %ebx,%ebx
f010023f:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100242:	0f b6 d2             	movzbl %dl,%edx
f0100245:	0f b6 82 40 1c 10 f0 	movzbl -0xfefe3c0(%edx),%eax
f010024c:	83 c8 40             	or     $0x40,%eax
f010024f:	0f b6 c0             	movzbl %al,%eax
f0100252:	f7 d0                	not    %eax
f0100254:	21 c1                	and    %eax,%ecx
f0100256:	89 0d 20 23 11 f0    	mov    %ecx,0xf0112320
		return 0;
f010025c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100261:	e9 9d 00 00 00       	jmp    f0100303 <kbd_proc_data+0x103>
	} else if (shift & E0ESC) {
f0100266:	8b 0d 20 23 11 f0    	mov    0xf0112320,%ecx
f010026c:	f6 c1 40             	test   $0x40,%cl
f010026f:	74 0e                	je     f010027f <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100271:	83 c8 80             	or     $0xffffff80,%eax
f0100274:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100276:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100279:	89 0d 20 23 11 f0    	mov    %ecx,0xf0112320
	}

	shift |= shiftcode[data];
f010027f:	0f b6 d2             	movzbl %dl,%edx
f0100282:	0f b6 82 40 1c 10 f0 	movzbl -0xfefe3c0(%edx),%eax
f0100289:	0b 05 20 23 11 f0    	or     0xf0112320,%eax
	shift ^= togglecode[data];
f010028f:	0f b6 8a 40 1b 10 f0 	movzbl -0xfefe4c0(%edx),%ecx
f0100296:	31 c8                	xor    %ecx,%eax
f0100298:	a3 20 23 11 f0       	mov    %eax,0xf0112320

	c = charcode[shift & (CTL | SHIFT)][data];
f010029d:	89 c1                	mov    %eax,%ecx
f010029f:	83 e1 03             	and    $0x3,%ecx
f01002a2:	8b 0c 8d 20 1b 10 f0 	mov    -0xfefe4e0(,%ecx,4),%ecx
f01002a9:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01002ad:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f01002b0:	a8 08                	test   $0x8,%al
f01002b2:	74 1b                	je     f01002cf <kbd_proc_data+0xcf>
		if ('a' <= c && c <= 'z')
f01002b4:	89 da                	mov    %ebx,%edx
f01002b6:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01002b9:	83 f9 19             	cmp    $0x19,%ecx
f01002bc:	77 05                	ja     f01002c3 <kbd_proc_data+0xc3>
			c += 'A' - 'a';
f01002be:	83 eb 20             	sub    $0x20,%ebx
f01002c1:	eb 0c                	jmp    f01002cf <kbd_proc_data+0xcf>
		else if ('A' <= c && c <= 'Z')
f01002c3:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002c6:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002c9:	83 fa 19             	cmp    $0x19,%edx
f01002cc:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002cf:	f7 d0                	not    %eax
f01002d1:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002d3:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002d5:	f6 c2 06             	test   $0x6,%dl
f01002d8:	75 29                	jne    f0100303 <kbd_proc_data+0x103>
f01002da:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002e0:	75 21                	jne    f0100303 <kbd_proc_data+0x103>
		cprintf("Rebooting!\n");
f01002e2:	c7 04 24 e4 1a 10 f0 	movl   $0xf0101ae4,(%esp)
f01002e9:	e8 fb 06 00 00       	call   f01009e9 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ee:	ba 92 00 00 00       	mov    $0x92,%edx
f01002f3:	b8 03 00 00 00       	mov    $0x3,%eax
f01002f8:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002f9:	89 d8                	mov    %ebx,%eax
f01002fb:	eb 06                	jmp    f0100303 <kbd_proc_data+0x103>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01002fd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100302:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100303:	83 c4 14             	add    $0x14,%esp
f0100306:	5b                   	pop    %ebx
f0100307:	5d                   	pop    %ebp
f0100308:	c3                   	ret    

f0100309 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100309:	55                   	push   %ebp
f010030a:	89 e5                	mov    %esp,%ebp
f010030c:	57                   	push   %edi
f010030d:	56                   	push   %esi
f010030e:	53                   	push   %ebx
f010030f:	83 ec 1c             	sub    $0x1c,%esp
f0100312:	89 c7                	mov    %eax,%edi

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100314:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100319:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f010031a:	a8 20                	test   $0x20,%al
f010031c:	75 21                	jne    f010033f <cons_putc+0x36>
f010031e:	bb 00 32 00 00       	mov    $0x3200,%ebx
f0100323:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100328:	be fd 03 00 00       	mov    $0x3fd,%esi
f010032d:	89 ca                	mov    %ecx,%edx
f010032f:	ec                   	in     (%dx),%al
f0100330:	ec                   	in     (%dx),%al
f0100331:	ec                   	in     (%dx),%al
f0100332:	ec                   	in     (%dx),%al
f0100333:	89 f2                	mov    %esi,%edx
f0100335:	ec                   	in     (%dx),%al
f0100336:	a8 20                	test   $0x20,%al
f0100338:	75 05                	jne    f010033f <cons_putc+0x36>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010033a:	83 eb 01             	sub    $0x1,%ebx
f010033d:	75 ee                	jne    f010032d <cons_putc+0x24>
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
f010033f:	89 f8                	mov    %edi,%eax
f0100341:	0f b6 c0             	movzbl %al,%eax
f0100344:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100347:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010034c:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010034d:	b2 79                	mov    $0x79,%dl
f010034f:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100350:	84 c0                	test   %al,%al
f0100352:	78 21                	js     f0100375 <cons_putc+0x6c>
f0100354:	bb 00 32 00 00       	mov    $0x3200,%ebx
f0100359:	b9 84 00 00 00       	mov    $0x84,%ecx
f010035e:	be 79 03 00 00       	mov    $0x379,%esi
f0100363:	89 ca                	mov    %ecx,%edx
f0100365:	ec                   	in     (%dx),%al
f0100366:	ec                   	in     (%dx),%al
f0100367:	ec                   	in     (%dx),%al
f0100368:	ec                   	in     (%dx),%al
f0100369:	89 f2                	mov    %esi,%edx
f010036b:	ec                   	in     (%dx),%al
f010036c:	84 c0                	test   %al,%al
f010036e:	78 05                	js     f0100375 <cons_putc+0x6c>
f0100370:	83 eb 01             	sub    $0x1,%ebx
f0100373:	75 ee                	jne    f0100363 <cons_putc+0x5a>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100375:	ba 78 03 00 00       	mov    $0x378,%edx
f010037a:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f010037e:	ee                   	out    %al,(%dx)
f010037f:	b2 7a                	mov    $0x7a,%dl
f0100381:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100386:	ee                   	out    %al,(%dx)
f0100387:	b8 08 00 00 00       	mov    $0x8,%eax
f010038c:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010038d:	89 fa                	mov    %edi,%edx
f010038f:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100395:	89 f8                	mov    %edi,%eax
f0100397:	80 cc 07             	or     $0x7,%ah
f010039a:	85 d2                	test   %edx,%edx
f010039c:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f010039f:	89 f8                	mov    %edi,%eax
f01003a1:	0f b6 c0             	movzbl %al,%eax
f01003a4:	83 f8 09             	cmp    $0x9,%eax
f01003a7:	74 79                	je     f0100422 <cons_putc+0x119>
f01003a9:	83 f8 09             	cmp    $0x9,%eax
f01003ac:	7f 0a                	jg     f01003b8 <cons_putc+0xaf>
f01003ae:	83 f8 08             	cmp    $0x8,%eax
f01003b1:	74 19                	je     f01003cc <cons_putc+0xc3>
f01003b3:	e9 9e 00 00 00       	jmp    f0100456 <cons_putc+0x14d>
f01003b8:	83 f8 0a             	cmp    $0xa,%eax
f01003bb:	90                   	nop
f01003bc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01003c0:	74 3a                	je     f01003fc <cons_putc+0xf3>
f01003c2:	83 f8 0d             	cmp    $0xd,%eax
f01003c5:	74 3d                	je     f0100404 <cons_putc+0xfb>
f01003c7:	e9 8a 00 00 00       	jmp    f0100456 <cons_putc+0x14d>
	case '\b':
		if (crt_pos > 0) {
f01003cc:	0f b7 05 48 25 11 f0 	movzwl 0xf0112548,%eax
f01003d3:	66 85 c0             	test   %ax,%ax
f01003d6:	0f 84 e5 00 00 00    	je     f01004c1 <cons_putc+0x1b8>
			crt_pos--;
f01003dc:	83 e8 01             	sub    $0x1,%eax
f01003df:	66 a3 48 25 11 f0    	mov    %ax,0xf0112548
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003e5:	0f b7 c0             	movzwl %ax,%eax
f01003e8:	66 81 e7 00 ff       	and    $0xff00,%di
f01003ed:	83 cf 20             	or     $0x20,%edi
f01003f0:	8b 15 4c 25 11 f0    	mov    0xf011254c,%edx
f01003f6:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003fa:	eb 78                	jmp    f0100474 <cons_putc+0x16b>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003fc:	66 83 05 48 25 11 f0 	addw   $0x50,0xf0112548
f0100403:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100404:	0f b7 05 48 25 11 f0 	movzwl 0xf0112548,%eax
f010040b:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100411:	c1 e8 16             	shr    $0x16,%eax
f0100414:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100417:	c1 e0 04             	shl    $0x4,%eax
f010041a:	66 a3 48 25 11 f0    	mov    %ax,0xf0112548
f0100420:	eb 52                	jmp    f0100474 <cons_putc+0x16b>
		break;
	case '\t':
		cons_putc(' ');
f0100422:	b8 20 00 00 00       	mov    $0x20,%eax
f0100427:	e8 dd fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f010042c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100431:	e8 d3 fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f0100436:	b8 20 00 00 00       	mov    $0x20,%eax
f010043b:	e8 c9 fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f0100440:	b8 20 00 00 00       	mov    $0x20,%eax
f0100445:	e8 bf fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f010044a:	b8 20 00 00 00       	mov    $0x20,%eax
f010044f:	e8 b5 fe ff ff       	call   f0100309 <cons_putc>
f0100454:	eb 1e                	jmp    f0100474 <cons_putc+0x16b>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100456:	0f b7 05 48 25 11 f0 	movzwl 0xf0112548,%eax
f010045d:	8d 50 01             	lea    0x1(%eax),%edx
f0100460:	66 89 15 48 25 11 f0 	mov    %dx,0xf0112548
f0100467:	0f b7 c0             	movzwl %ax,%eax
f010046a:	8b 15 4c 25 11 f0    	mov    0xf011254c,%edx
f0100470:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100474:	66 81 3d 48 25 11 f0 	cmpw   $0x7cf,0xf0112548
f010047b:	cf 07 
f010047d:	76 42                	jbe    f01004c1 <cons_putc+0x1b8>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010047f:	a1 4c 25 11 f0       	mov    0xf011254c,%eax
f0100484:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010048b:	00 
f010048c:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100492:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100496:	89 04 24             	mov    %eax,(%esp)
f0100499:	e8 3e 11 00 00       	call   f01015dc <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010049e:	8b 15 4c 25 11 f0    	mov    0xf011254c,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004a4:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f01004a9:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004af:	83 c0 01             	add    $0x1,%eax
f01004b2:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01004b7:	75 f0                	jne    f01004a9 <cons_putc+0x1a0>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01004b9:	66 83 2d 48 25 11 f0 	subw   $0x50,0xf0112548
f01004c0:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01004c1:	8b 0d 50 25 11 f0    	mov    0xf0112550,%ecx
f01004c7:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004cc:	89 ca                	mov    %ecx,%edx
f01004ce:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004cf:	0f b7 1d 48 25 11 f0 	movzwl 0xf0112548,%ebx
f01004d6:	8d 71 01             	lea    0x1(%ecx),%esi
f01004d9:	89 d8                	mov    %ebx,%eax
f01004db:	66 c1 e8 08          	shr    $0x8,%ax
f01004df:	89 f2                	mov    %esi,%edx
f01004e1:	ee                   	out    %al,(%dx)
f01004e2:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004e7:	89 ca                	mov    %ecx,%edx
f01004e9:	ee                   	out    %al,(%dx)
f01004ea:	89 d8                	mov    %ebx,%eax
f01004ec:	89 f2                	mov    %esi,%edx
f01004ee:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004ef:	83 c4 1c             	add    $0x1c,%esp
f01004f2:	5b                   	pop    %ebx
f01004f3:	5e                   	pop    %esi
f01004f4:	5f                   	pop    %edi
f01004f5:	5d                   	pop    %ebp
f01004f6:	c3                   	ret    

f01004f7 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004f7:	83 3d 54 25 11 f0 00 	cmpl   $0x0,0xf0112554
f01004fe:	74 11                	je     f0100511 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100500:	55                   	push   %ebp
f0100501:	89 e5                	mov    %esp,%ebp
f0100503:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100506:	b8 a0 01 10 f0       	mov    $0xf01001a0,%eax
f010050b:	e8 ac fc ff ff       	call   f01001bc <cons_intr>
}
f0100510:	c9                   	leave  
f0100511:	f3 c3                	repz ret 

f0100513 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100513:	55                   	push   %ebp
f0100514:	89 e5                	mov    %esp,%ebp
f0100516:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100519:	b8 00 02 10 f0       	mov    $0xf0100200,%eax
f010051e:	e8 99 fc ff ff       	call   f01001bc <cons_intr>
}
f0100523:	c9                   	leave  
f0100524:	c3                   	ret    

f0100525 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100525:	55                   	push   %ebp
f0100526:	89 e5                	mov    %esp,%ebp
f0100528:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010052b:	e8 c7 ff ff ff       	call   f01004f7 <serial_intr>
	kbd_intr();
f0100530:	e8 de ff ff ff       	call   f0100513 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100535:	a1 40 25 11 f0       	mov    0xf0112540,%eax
f010053a:	3b 05 44 25 11 f0    	cmp    0xf0112544,%eax
f0100540:	74 26                	je     f0100568 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100542:	8d 50 01             	lea    0x1(%eax),%edx
f0100545:	89 15 40 25 11 f0    	mov    %edx,0xf0112540
f010054b:	0f b6 88 40 23 11 f0 	movzbl -0xfeedcc0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100552:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100554:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010055a:	75 11                	jne    f010056d <cons_getc+0x48>
			cons.rpos = 0;
f010055c:	c7 05 40 25 11 f0 00 	movl   $0x0,0xf0112540
f0100563:	00 00 00 
f0100566:	eb 05                	jmp    f010056d <cons_getc+0x48>
		return c;
	}
	return 0;
f0100568:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010056d:	c9                   	leave  
f010056e:	c3                   	ret    

f010056f <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010056f:	55                   	push   %ebp
f0100570:	89 e5                	mov    %esp,%ebp
f0100572:	57                   	push   %edi
f0100573:	56                   	push   %esi
f0100574:	53                   	push   %ebx
f0100575:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100578:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010057f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100586:	5a a5 
	if (*cp != 0xA55A) {
f0100588:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010058f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100593:	74 11                	je     f01005a6 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100595:	c7 05 50 25 11 f0 b4 	movl   $0x3b4,0xf0112550
f010059c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010059f:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f01005a4:	eb 16                	jmp    f01005bc <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f01005a6:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01005ad:	c7 05 50 25 11 f0 d4 	movl   $0x3d4,0xf0112550
f01005b4:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005b7:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
f01005bc:	8b 0d 50 25 11 f0    	mov    0xf0112550,%ecx
f01005c2:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005c7:	89 ca                	mov    %ecx,%edx
f01005c9:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005ca:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005cd:	89 da                	mov    %ebx,%edx
f01005cf:	ec                   	in     (%dx),%al
f01005d0:	0f b6 f0             	movzbl %al,%esi
f01005d3:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005d6:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005db:	89 ca                	mov    %ecx,%edx
f01005dd:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005de:	89 da                	mov    %ebx,%edx
f01005e0:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005e1:	89 3d 4c 25 11 f0    	mov    %edi,0xf011254c
	
	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005e7:	0f b6 d8             	movzbl %al,%ebx
f01005ea:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005ec:	66 89 35 48 25 11 f0 	mov    %si,0xf0112548
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005f3:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005f8:	b8 00 00 00 00       	mov    $0x0,%eax
f01005fd:	89 f2                	mov    %esi,%edx
f01005ff:	ee                   	out    %al,(%dx)
f0100600:	b2 fb                	mov    $0xfb,%dl
f0100602:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100607:	ee                   	out    %al,(%dx)
f0100608:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f010060d:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100612:	89 da                	mov    %ebx,%edx
f0100614:	ee                   	out    %al,(%dx)
f0100615:	b2 f9                	mov    $0xf9,%dl
f0100617:	b8 00 00 00 00       	mov    $0x0,%eax
f010061c:	ee                   	out    %al,(%dx)
f010061d:	b2 fb                	mov    $0xfb,%dl
f010061f:	b8 03 00 00 00       	mov    $0x3,%eax
f0100624:	ee                   	out    %al,(%dx)
f0100625:	b2 fc                	mov    $0xfc,%dl
f0100627:	b8 00 00 00 00       	mov    $0x0,%eax
f010062c:	ee                   	out    %al,(%dx)
f010062d:	b2 f9                	mov    $0xf9,%dl
f010062f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100634:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100635:	b2 fd                	mov    $0xfd,%dl
f0100637:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100638:	3c ff                	cmp    $0xff,%al
f010063a:	0f 95 c1             	setne  %cl
f010063d:	0f b6 c9             	movzbl %cl,%ecx
f0100640:	89 0d 54 25 11 f0    	mov    %ecx,0xf0112554
f0100646:	89 f2                	mov    %esi,%edx
f0100648:	ec                   	in     (%dx),%al
f0100649:	89 da                	mov    %ebx,%edx
f010064b:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f010064c:	85 c9                	test   %ecx,%ecx
f010064e:	75 0c                	jne    f010065c <cons_init+0xed>
		cprintf("Serial port does not exist!\n");
f0100650:	c7 04 24 f0 1a 10 f0 	movl   $0xf0101af0,(%esp)
f0100657:	e8 8d 03 00 00       	call   f01009e9 <cprintf>
}
f010065c:	83 c4 1c             	add    $0x1c,%esp
f010065f:	5b                   	pop    %ebx
f0100660:	5e                   	pop    %esi
f0100661:	5f                   	pop    %edi
f0100662:	5d                   	pop    %ebp
f0100663:	c3                   	ret    

f0100664 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100664:	55                   	push   %ebp
f0100665:	89 e5                	mov    %esp,%ebp
f0100667:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010066a:	8b 45 08             	mov    0x8(%ebp),%eax
f010066d:	e8 97 fc ff ff       	call   f0100309 <cons_putc>
}
f0100672:	c9                   	leave  
f0100673:	c3                   	ret    

f0100674 <getchar>:

int
getchar(void)
{
f0100674:	55                   	push   %ebp
f0100675:	89 e5                	mov    %esp,%ebp
f0100677:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010067a:	e8 a6 fe ff ff       	call   f0100525 <cons_getc>
f010067f:	85 c0                	test   %eax,%eax
f0100681:	74 f7                	je     f010067a <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100683:	c9                   	leave  
f0100684:	c3                   	ret    

f0100685 <iscons>:

int
iscons(int fdnum)
{
f0100685:	55                   	push   %ebp
f0100686:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100688:	b8 01 00 00 00       	mov    $0x1,%eax
f010068d:	5d                   	pop    %ebp
f010068e:	c3                   	ret    
f010068f:	90                   	nop

f0100690 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100690:	55                   	push   %ebp
f0100691:	89 e5                	mov    %esp,%ebp
f0100693:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100696:	c7 44 24 08 40 1d 10 	movl   $0xf0101d40,0x8(%esp)
f010069d:	f0 
f010069e:	c7 44 24 04 5e 1d 10 	movl   $0xf0101d5e,0x4(%esp)
f01006a5:	f0 
f01006a6:	c7 04 24 63 1d 10 f0 	movl   $0xf0101d63,(%esp)
f01006ad:	e8 37 03 00 00       	call   f01009e9 <cprintf>
f01006b2:	c7 44 24 08 fc 1d 10 	movl   $0xf0101dfc,0x8(%esp)
f01006b9:	f0 
f01006ba:	c7 44 24 04 6c 1d 10 	movl   $0xf0101d6c,0x4(%esp)
f01006c1:	f0 
f01006c2:	c7 04 24 63 1d 10 f0 	movl   $0xf0101d63,(%esp)
f01006c9:	e8 1b 03 00 00       	call   f01009e9 <cprintf>
	return 0;
}
f01006ce:	b8 00 00 00 00       	mov    $0x0,%eax
f01006d3:	c9                   	leave  
f01006d4:	c3                   	ret    

f01006d5 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006d5:	55                   	push   %ebp
f01006d6:	89 e5                	mov    %esp,%ebp
f01006d8:	83 ec 18             	sub    $0x18,%esp
	extern char entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006db:	c7 04 24 75 1d 10 f0 	movl   $0xf0101d75,(%esp)
f01006e2:	e8 02 03 00 00       	call   f01009e9 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006e7:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006ee:	00 
f01006ef:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006f6:	f0 
f01006f7:	c7 04 24 24 1e 10 f0 	movl   $0xf0101e24,(%esp)
f01006fe:	e8 e6 02 00 00       	call   f01009e9 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100703:	c7 44 24 08 57 1a 10 	movl   $0x101a57,0x8(%esp)
f010070a:	00 
f010070b:	c7 44 24 04 57 1a 10 	movl   $0xf0101a57,0x4(%esp)
f0100712:	f0 
f0100713:	c7 04 24 48 1e 10 f0 	movl   $0xf0101e48,(%esp)
f010071a:	e8 ca 02 00 00       	call   f01009e9 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010071f:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f0100726:	00 
f0100727:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f010072e:	f0 
f010072f:	c7 04 24 6c 1e 10 f0 	movl   $0xf0101e6c,(%esp)
f0100736:	e8 ae 02 00 00       	call   f01009e9 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010073b:	c7 44 24 08 60 29 11 	movl   $0x112960,0x8(%esp)
f0100742:	00 
f0100743:	c7 44 24 04 60 29 11 	movl   $0xf0112960,0x4(%esp)
f010074a:	f0 
f010074b:	c7 04 24 90 1e 10 f0 	movl   $0xf0101e90,(%esp)
f0100752:	e8 92 02 00 00       	call   f01009e9 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		(end-entry+1023)/1024);
f0100757:	b8 5f 2d 11 f0       	mov    $0xf0112d5f,%eax
f010075c:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("Special kernel symbols:\n");
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100761:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100767:	85 c0                	test   %eax,%eax
f0100769:	0f 48 c2             	cmovs  %edx,%eax
f010076c:	c1 f8 0a             	sar    $0xa,%eax
f010076f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100773:	c7 04 24 b4 1e 10 f0 	movl   $0xf0101eb4,(%esp)
f010077a:	e8 6a 02 00 00       	call   f01009e9 <cprintf>
		(end-entry+1023)/1024);
	return 0;
}
f010077f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100784:	c9                   	leave  
f0100785:	c3                   	ret    

f0100786 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100786:	55                   	push   %ebp
f0100787:	89 e5                	mov    %esp,%ebp
f0100789:	57                   	push   %edi
f010078a:	56                   	push   %esi
f010078b:	53                   	push   %ebx
f010078c:	83 ec 2c             	sub    $0x2c,%esp
	// Your code here.
	cprintf("Stack backtrace:");
f010078f:	c7 04 24 8e 1d 10 f0 	movl   $0xf0101d8e,(%esp)
f0100796:	e8 4e 02 00 00       	call   f01009e9 <cprintf>

static __inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f010079b:	89 e8                	mov    %ebp,%eax
	uint32_t *ebp=(uint32_t*) read_ebp();
f010079d:	89 c3                	mov    %eax,%ebx
	while(ebp!=0)
f010079f:	85 c0                	test   %eax,%eax
f01007a1:	0f 84 9e 00 00 00    	je     f0100845 <mon_backtrace+0xbf>
	{
	  cprintf("\n");
f01007a7:	c7 04 24 ee 1a 10 f0 	movl   $0xf0101aee,(%esp)
f01007ae:	e8 36 02 00 00       	call   f01009e9 <cprintf>

	 uint32_t eip=*(ebp+1);
 	 uint32_t a1=*(ebp+2);
f01007b3:	8b 7b 08             	mov    0x8(%ebx),%edi
	 uint32_t a2=*(ebp+3);
f01007b6:	8b 73 0c             	mov    0xc(%ebx),%esi
	 uint32_t a3=*(ebp+4);
f01007b9:	8b 43 10             	mov    0x10(%ebx),%eax
f01007bc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
 	 uint32_t a4=*(ebp+5);
f01007bf:	8b 53 14             	mov    0x14(%ebx),%edx
f01007c2:	89 55 e0             	mov    %edx,-0x20(%ebp)
	 uint32_t a5=*(ebp+6);
f01007c5:	8b 4b 18             	mov    0x18(%ebx),%ecx
f01007c8:	89 4d dc             	mov    %ecx,-0x24(%ebp)
	 cprintf(" ebp %08x  eip %08x  args",ebp,eip);
f01007cb:	8b 43 04             	mov    0x4(%ebx),%eax
f01007ce:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007d2:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01007d6:	c7 04 24 9f 1d 10 f0 	movl   $0xf0101d9f,(%esp)
f01007dd:	e8 07 02 00 00       	call   f01009e9 <cprintf>
	 cprintf(" %08x",a1);
f01007e2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01007e6:	c7 04 24 b9 1d 10 f0 	movl   $0xf0101db9,(%esp)
f01007ed:	e8 f7 01 00 00       	call   f01009e9 <cprintf>
	 cprintf(" %08x",a2);
f01007f2:	89 74 24 04          	mov    %esi,0x4(%esp)
f01007f6:	c7 04 24 b9 1d 10 f0 	movl   $0xf0101db9,(%esp)
f01007fd:	e8 e7 01 00 00       	call   f01009e9 <cprintf>
	 cprintf(" %08x",a3);
f0100802:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100805:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100809:	c7 04 24 b9 1d 10 f0 	movl   $0xf0101db9,(%esp)
f0100810:	e8 d4 01 00 00       	call   f01009e9 <cprintf>
	 cprintf(" %08x",a4);
f0100815:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100818:	89 54 24 04          	mov    %edx,0x4(%esp)
f010081c:	c7 04 24 b9 1d 10 f0 	movl   $0xf0101db9,(%esp)
f0100823:	e8 c1 01 00 00       	call   f01009e9 <cprintf>
	 cprintf(" %08x",a5);
f0100828:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010082b:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010082f:	c7 04 24 b9 1d 10 f0 	movl   $0xf0101db9,(%esp)
f0100836:	e8 ae 01 00 00       	call   f01009e9 <cprintf>
	 
	 ebp=(uint32_t *)(*ebp);
f010083b:	8b 1b                	mov    (%ebx),%ebx
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	// Your code here.
	cprintf("Stack backtrace:");
	uint32_t *ebp=(uint32_t*) read_ebp();
	while(ebp!=0)
f010083d:	85 db                	test   %ebx,%ebx
f010083f:	0f 85 62 ff ff ff    	jne    f01007a7 <mon_backtrace+0x21>




	return 0;
}
f0100845:	b8 00 00 00 00       	mov    $0x0,%eax
f010084a:	83 c4 2c             	add    $0x2c,%esp
f010084d:	5b                   	pop    %ebx
f010084e:	5e                   	pop    %esi
f010084f:	5f                   	pop    %edi
f0100850:	5d                   	pop    %ebp
f0100851:	c3                   	ret    

f0100852 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100852:	55                   	push   %ebp
f0100853:	89 e5                	mov    %esp,%ebp
f0100855:	57                   	push   %edi
f0100856:	56                   	push   %esi
f0100857:	53                   	push   %ebx
f0100858:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010085b:	c7 04 24 e0 1e 10 f0 	movl   $0xf0101ee0,(%esp)
f0100862:	e8 82 01 00 00       	call   f01009e9 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100867:	c7 04 24 04 1f 10 f0 	movl   $0xf0101f04,(%esp)
f010086e:	e8 76 01 00 00       	call   f01009e9 <cprintf>


	while (1) {
		buf = readline("K> ");
f0100873:	c7 04 24 bf 1d 10 f0 	movl   $0xf0101dbf,(%esp)
f010087a:	e8 61 0a 00 00       	call   f01012e0 <readline>
f010087f:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100881:	85 c0                	test   %eax,%eax
f0100883:	74 ee                	je     f0100873 <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100885:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010088c:	be 00 00 00 00       	mov    $0x0,%esi
f0100891:	eb 0a                	jmp    f010089d <monitor+0x4b>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100893:	c6 03 00             	movb   $0x0,(%ebx)
f0100896:	89 f7                	mov    %esi,%edi
f0100898:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010089b:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f010089d:	0f b6 03             	movzbl (%ebx),%eax
f01008a0:	84 c0                	test   %al,%al
f01008a2:	74 6a                	je     f010090e <monitor+0xbc>
f01008a4:	0f be c0             	movsbl %al,%eax
f01008a7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008ab:	c7 04 24 c3 1d 10 f0 	movl   $0xf0101dc3,(%esp)
f01008b2:	e8 77 0c 00 00       	call   f010152e <strchr>
f01008b7:	85 c0                	test   %eax,%eax
f01008b9:	75 d8                	jne    f0100893 <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f01008bb:	80 3b 00             	cmpb   $0x0,(%ebx)
f01008be:	74 4e                	je     f010090e <monitor+0xbc>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01008c0:	83 fe 0f             	cmp    $0xf,%esi
f01008c3:	75 16                	jne    f01008db <monitor+0x89>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008c5:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f01008cc:	00 
f01008cd:	c7 04 24 c8 1d 10 f0 	movl   $0xf0101dc8,(%esp)
f01008d4:	e8 10 01 00 00       	call   f01009e9 <cprintf>
f01008d9:	eb 98                	jmp    f0100873 <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f01008db:	8d 7e 01             	lea    0x1(%esi),%edi
f01008de:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
		while (*buf && !strchr(WHITESPACE, *buf))
f01008e2:	0f b6 03             	movzbl (%ebx),%eax
f01008e5:	84 c0                	test   %al,%al
f01008e7:	75 0c                	jne    f01008f5 <monitor+0xa3>
f01008e9:	eb b0                	jmp    f010089b <monitor+0x49>
			buf++;
f01008eb:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01008ee:	0f b6 03             	movzbl (%ebx),%eax
f01008f1:	84 c0                	test   %al,%al
f01008f3:	74 a6                	je     f010089b <monitor+0x49>
f01008f5:	0f be c0             	movsbl %al,%eax
f01008f8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008fc:	c7 04 24 c3 1d 10 f0 	movl   $0xf0101dc3,(%esp)
f0100903:	e8 26 0c 00 00       	call   f010152e <strchr>
f0100908:	85 c0                	test   %eax,%eax
f010090a:	74 df                	je     f01008eb <monitor+0x99>
f010090c:	eb 8d                	jmp    f010089b <monitor+0x49>
			buf++;
	}
	argv[argc] = 0;
f010090e:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100915:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100916:	85 f6                	test   %esi,%esi
f0100918:	0f 84 55 ff ff ff    	je     f0100873 <monitor+0x21>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010091e:	c7 44 24 04 5e 1d 10 	movl   $0xf0101d5e,0x4(%esp)
f0100925:	f0 
f0100926:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100929:	89 04 24             	mov    %eax,(%esp)
f010092c:	e8 79 0b 00 00       	call   f01014aa <strcmp>
f0100931:	85 c0                	test   %eax,%eax
f0100933:	74 1b                	je     f0100950 <monitor+0xfe>
f0100935:	c7 44 24 04 6c 1d 10 	movl   $0xf0101d6c,0x4(%esp)
f010093c:	f0 
f010093d:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100940:	89 04 24             	mov    %eax,(%esp)
f0100943:	e8 62 0b 00 00       	call   f01014aa <strcmp>
f0100948:	85 c0                	test   %eax,%eax
f010094a:	75 2f                	jne    f010097b <monitor+0x129>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f010094c:	b0 01                	mov    $0x1,%al
f010094e:	eb 05                	jmp    f0100955 <monitor+0x103>
		if (strcmp(argv[0], commands[i].name) == 0)
f0100950:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f0100955:	8d 14 00             	lea    (%eax,%eax,1),%edx
f0100958:	01 d0                	add    %edx,%eax
f010095a:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010095d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100961:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100964:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100968:	89 34 24             	mov    %esi,(%esp)
f010096b:	ff 14 85 34 1f 10 f0 	call   *-0xfefe0cc(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100972:	85 c0                	test   %eax,%eax
f0100974:	78 1d                	js     f0100993 <monitor+0x141>
f0100976:	e9 f8 fe ff ff       	jmp    f0100873 <monitor+0x21>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f010097b:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010097e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100982:	c7 04 24 e5 1d 10 f0 	movl   $0xf0101de5,(%esp)
f0100989:	e8 5b 00 00 00       	call   f01009e9 <cprintf>
f010098e:	e9 e0 fe ff ff       	jmp    f0100873 <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100993:	83 c4 5c             	add    $0x5c,%esp
f0100996:	5b                   	pop    %ebx
f0100997:	5e                   	pop    %esi
f0100998:	5f                   	pop    %edi
f0100999:	5d                   	pop    %ebp
f010099a:	c3                   	ret    

f010099b <read_eip>:
// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
f010099b:	55                   	push   %ebp
f010099c:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f010099e:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f01009a1:	5d                   	pop    %ebp
f01009a2:	c3                   	ret    

f01009a3 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01009a3:	55                   	push   %ebp
f01009a4:	89 e5                	mov    %esp,%ebp
f01009a6:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f01009a9:	8b 45 08             	mov    0x8(%ebp),%eax
f01009ac:	89 04 24             	mov    %eax,(%esp)
f01009af:	e8 b0 fc ff ff       	call   f0100664 <cputchar>
	*cnt++;
}
f01009b4:	c9                   	leave  
f01009b5:	c3                   	ret    

f01009b6 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01009b6:	55                   	push   %ebp
f01009b7:	89 e5                	mov    %esp,%ebp
f01009b9:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f01009bc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01009c3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01009c6:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01009ca:	8b 45 08             	mov    0x8(%ebp),%eax
f01009cd:	89 44 24 08          	mov    %eax,0x8(%esp)
f01009d1:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01009d4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009d8:	c7 04 24 a3 09 10 f0 	movl   $0xf01009a3,(%esp)
f01009df:	e8 90 04 00 00       	call   f0100e74 <vprintfmt>
	return cnt;
}
f01009e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01009e7:	c9                   	leave  
f01009e8:	c3                   	ret    

f01009e9 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01009e9:	55                   	push   %ebp
f01009ea:	89 e5                	mov    %esp,%ebp
f01009ec:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01009ef:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01009f2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009f6:	8b 45 08             	mov    0x8(%ebp),%eax
f01009f9:	89 04 24             	mov    %eax,(%esp)
f01009fc:	e8 b5 ff ff ff       	call   f01009b6 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100a01:	c9                   	leave  
f0100a02:	c3                   	ret    
f0100a03:	66 90                	xchg   %ax,%ax
f0100a05:	66 90                	xchg   %ax,%ax
f0100a07:	66 90                	xchg   %ax,%ax
f0100a09:	66 90                	xchg   %ax,%ax
f0100a0b:	66 90                	xchg   %ax,%ax
f0100a0d:	66 90                	xchg   %ax,%ax
f0100a0f:	90                   	nop

f0100a10 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100a10:	55                   	push   %ebp
f0100a11:	89 e5                	mov    %esp,%ebp
f0100a13:	57                   	push   %edi
f0100a14:	56                   	push   %esi
f0100a15:	53                   	push   %ebx
f0100a16:	83 ec 10             	sub    $0x10,%esp
f0100a19:	89 c6                	mov    %eax,%esi
f0100a1b:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100a1e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100a21:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100a24:	8b 1a                	mov    (%edx),%ebx
f0100a26:	8b 01                	mov    (%ecx),%eax
f0100a28:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a2b:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	
	while (l <= r) {
f0100a32:	eb 77                	jmp    f0100aab <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0100a34:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100a37:	01 d8                	add    %ebx,%eax
f0100a39:	b9 02 00 00 00       	mov    $0x2,%ecx
f0100a3e:	99                   	cltd   
f0100a3f:	f7 f9                	idiv   %ecx
f0100a41:	89 c1                	mov    %eax,%ecx
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a43:	eb 01                	jmp    f0100a46 <stab_binsearch+0x36>
			m--;
f0100a45:	49                   	dec    %ecx
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a46:	39 d9                	cmp    %ebx,%ecx
f0100a48:	7c 1d                	jl     f0100a67 <stab_binsearch+0x57>
f0100a4a:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100a4d:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100a52:	39 fa                	cmp    %edi,%edx
f0100a54:	75 ef                	jne    f0100a45 <stab_binsearch+0x35>
f0100a56:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100a59:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100a5c:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0100a60:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100a63:	73 18                	jae    f0100a7d <stab_binsearch+0x6d>
f0100a65:	eb 05                	jmp    f0100a6c <stab_binsearch+0x5c>
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100a67:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0100a6a:	eb 3f                	jmp    f0100aab <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100a6c:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100a6f:	89 0b                	mov    %ecx,(%ebx)
			l = true_m + 1;
f0100a71:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a74:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a7b:	eb 2e                	jmp    f0100aab <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100a7d:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a80:	73 15                	jae    f0100a97 <stab_binsearch+0x87>
			*region_right = m - 1;
f0100a82:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100a85:	48                   	dec    %eax
f0100a86:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a89:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100a8c:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a8e:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a95:	eb 14                	jmp    f0100aab <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100a97:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100a9a:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f0100a9d:	89 18                	mov    %ebx,(%eax)
			l = m;
			addr++;
f0100a9f:	ff 45 0c             	incl   0xc(%ebp)
f0100aa2:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100aa4:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0100aab:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100aae:	7e 84                	jle    f0100a34 <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100ab0:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100ab4:	75 0d                	jne    f0100ac3 <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0100ab6:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100ab9:	8b 00                	mov    (%eax),%eax
f0100abb:	48                   	dec    %eax
f0100abc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100abf:	89 07                	mov    %eax,(%edi)
f0100ac1:	eb 22                	jmp    f0100ae5 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100ac3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ac6:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100ac8:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100acb:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100acd:	eb 01                	jmp    f0100ad0 <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100acf:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100ad0:	39 c1                	cmp    %eax,%ecx
f0100ad2:	7d 0c                	jge    f0100ae0 <stab_binsearch+0xd0>
f0100ad4:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0100ad7:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100adc:	39 fa                	cmp    %edi,%edx
f0100ade:	75 ef                	jne    f0100acf <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100ae0:	8b 7d e8             	mov    -0x18(%ebp),%edi
f0100ae3:	89 07                	mov    %eax,(%edi)
	}
}
f0100ae5:	83 c4 10             	add    $0x10,%esp
f0100ae8:	5b                   	pop    %ebx
f0100ae9:	5e                   	pop    %esi
f0100aea:	5f                   	pop    %edi
f0100aeb:	5d                   	pop    %ebp
f0100aec:	c3                   	ret    

f0100aed <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100aed:	55                   	push   %ebp
f0100aee:	89 e5                	mov    %esp,%ebp
f0100af0:	57                   	push   %edi
f0100af1:	56                   	push   %esi
f0100af2:	53                   	push   %ebx
f0100af3:	83 ec 2c             	sub    $0x2c,%esp
f0100af6:	8b 75 08             	mov    0x8(%ebp),%esi
f0100af9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100afc:	c7 03 44 1f 10 f0    	movl   $0xf0101f44,(%ebx)
	info->eip_line = 0;
f0100b02:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100b09:	c7 43 08 44 1f 10 f0 	movl   $0xf0101f44,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100b10:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100b17:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100b1a:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100b21:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100b27:	76 12                	jbe    f0100b3b <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b29:	b8 ba 74 10 f0       	mov    $0xf01074ba,%eax
f0100b2e:	3d 3d 5b 10 f0       	cmp    $0xf0105b3d,%eax
f0100b33:	0f 86 8b 01 00 00    	jbe    f0100cc4 <debuginfo_eip+0x1d7>
f0100b39:	eb 1c                	jmp    f0100b57 <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100b3b:	c7 44 24 08 4e 1f 10 	movl   $0xf0101f4e,0x8(%esp)
f0100b42:	f0 
f0100b43:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100b4a:	00 
f0100b4b:	c7 04 24 5b 1f 10 f0 	movl   $0xf0101f5b,(%esp)
f0100b52:	e8 a1 f5 ff ff       	call   f01000f8 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b57:	80 3d b9 74 10 f0 00 	cmpb   $0x0,0xf01074b9
f0100b5e:	0f 85 67 01 00 00    	jne    f0100ccb <debuginfo_eip+0x1de>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b64:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b6b:	b8 3c 5b 10 f0       	mov    $0xf0105b3c,%eax
f0100b70:	2d 7c 21 10 f0       	sub    $0xf010217c,%eax
f0100b75:	c1 f8 02             	sar    $0x2,%eax
f0100b78:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b7e:	83 e8 01             	sub    $0x1,%eax
f0100b81:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b84:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b88:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100b8f:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100b92:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b95:	b8 7c 21 10 f0       	mov    $0xf010217c,%eax
f0100b9a:	e8 71 fe ff ff       	call   f0100a10 <stab_binsearch>
	if (lfile == 0)
f0100b9f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ba2:	85 c0                	test   %eax,%eax
f0100ba4:	0f 84 28 01 00 00    	je     f0100cd2 <debuginfo_eip+0x1e5>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100baa:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100bad:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100bb0:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100bb3:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100bb7:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100bbe:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100bc1:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100bc4:	b8 7c 21 10 f0       	mov    $0xf010217c,%eax
f0100bc9:	e8 42 fe ff ff       	call   f0100a10 <stab_binsearch>

	if (lfun <= rfun) {
f0100bce:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0100bd1:	3b 7d d8             	cmp    -0x28(%ebp),%edi
f0100bd4:	7f 2e                	jg     f0100c04 <debuginfo_eip+0x117>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100bd6:	6b c7 0c             	imul   $0xc,%edi,%eax
f0100bd9:	8d 90 7c 21 10 f0    	lea    -0xfefde84(%eax),%edx
f0100bdf:	8b 80 7c 21 10 f0    	mov    -0xfefde84(%eax),%eax
f0100be5:	b9 ba 74 10 f0       	mov    $0xf01074ba,%ecx
f0100bea:	81 e9 3d 5b 10 f0    	sub    $0xf0105b3d,%ecx
f0100bf0:	39 c8                	cmp    %ecx,%eax
f0100bf2:	73 08                	jae    f0100bfc <debuginfo_eip+0x10f>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100bf4:	05 3d 5b 10 f0       	add    $0xf0105b3d,%eax
f0100bf9:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100bfc:	8b 42 08             	mov    0x8(%edx),%eax
f0100bff:	89 43 10             	mov    %eax,0x10(%ebx)
f0100c02:	eb 06                	jmp    f0100c0a <debuginfo_eip+0x11d>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100c04:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100c07:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100c0a:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100c11:	00 
f0100c12:	8b 43 08             	mov    0x8(%ebx),%eax
f0100c15:	89 04 24             	mov    %eax,(%esp)
f0100c18:	e8 47 09 00 00       	call   f0101564 <strfind>
f0100c1d:	2b 43 08             	sub    0x8(%ebx),%eax
f0100c20:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c23:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100c26:	39 cf                	cmp    %ecx,%edi
f0100c28:	7c 5c                	jl     f0100c86 <debuginfo_eip+0x199>
	       && stabs[lline].n_type != N_SOL
f0100c2a:	6b c7 0c             	imul   $0xc,%edi,%eax
f0100c2d:	8d b0 7c 21 10 f0    	lea    -0xfefde84(%eax),%esi
f0100c33:	0f b6 56 04          	movzbl 0x4(%esi),%edx
f0100c37:	80 fa 84             	cmp    $0x84,%dl
f0100c3a:	74 2b                	je     f0100c67 <debuginfo_eip+0x17a>
f0100c3c:	05 70 21 10 f0       	add    $0xf0102170,%eax
f0100c41:	eb 15                	jmp    f0100c58 <debuginfo_eip+0x16b>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100c43:	83 ef 01             	sub    $0x1,%edi
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c46:	39 cf                	cmp    %ecx,%edi
f0100c48:	7c 3c                	jl     f0100c86 <debuginfo_eip+0x199>
	       && stabs[lline].n_type != N_SOL
f0100c4a:	89 c6                	mov    %eax,%esi
f0100c4c:	83 e8 0c             	sub    $0xc,%eax
f0100c4f:	0f b6 50 10          	movzbl 0x10(%eax),%edx
f0100c53:	80 fa 84             	cmp    $0x84,%dl
f0100c56:	74 0f                	je     f0100c67 <debuginfo_eip+0x17a>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100c58:	80 fa 64             	cmp    $0x64,%dl
f0100c5b:	75 e6                	jne    f0100c43 <debuginfo_eip+0x156>
f0100c5d:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
f0100c61:	74 e0                	je     f0100c43 <debuginfo_eip+0x156>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100c63:	39 f9                	cmp    %edi,%ecx
f0100c65:	7f 1f                	jg     f0100c86 <debuginfo_eip+0x199>
f0100c67:	6b ff 0c             	imul   $0xc,%edi,%edi
f0100c6a:	8b 87 7c 21 10 f0    	mov    -0xfefde84(%edi),%eax
f0100c70:	ba ba 74 10 f0       	mov    $0xf01074ba,%edx
f0100c75:	81 ea 3d 5b 10 f0    	sub    $0xf0105b3d,%edx
f0100c7b:	39 d0                	cmp    %edx,%eax
f0100c7d:	73 07                	jae    f0100c86 <debuginfo_eip+0x199>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100c7f:	05 3d 5b 10 f0       	add    $0xf0105b3d,%eax
f0100c84:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c86:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100c89:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0100c8c:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c91:	39 ca                	cmp    %ecx,%edx
f0100c93:	7d 5e                	jge    f0100cf3 <debuginfo_eip+0x206>
		for (lline = lfun + 1;
f0100c95:	8d 42 01             	lea    0x1(%edx),%eax
f0100c98:	39 c1                	cmp    %eax,%ecx
f0100c9a:	7e 3d                	jle    f0100cd9 <debuginfo_eip+0x1ec>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100c9c:	6b d0 0c             	imul   $0xc,%eax,%edx
f0100c9f:	80 ba 80 21 10 f0 a0 	cmpb   $0xa0,-0xfefde80(%edx)
f0100ca6:	75 38                	jne    f0100ce0 <debuginfo_eip+0x1f3>
f0100ca8:	81 c2 70 21 10 f0    	add    $0xf0102170,%edx
		     lline++)
			info->eip_fn_narg++;
f0100cae:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100cb2:	83 c0 01             	add    $0x1,%eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100cb5:	39 c1                	cmp    %eax,%ecx
f0100cb7:	7e 2e                	jle    f0100ce7 <debuginfo_eip+0x1fa>
f0100cb9:	83 c2 0c             	add    $0xc,%edx
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100cbc:	80 7a 10 a0          	cmpb   $0xa0,0x10(%edx)
f0100cc0:	74 ec                	je     f0100cae <debuginfo_eip+0x1c1>
f0100cc2:	eb 2a                	jmp    f0100cee <debuginfo_eip+0x201>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100cc4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cc9:	eb 28                	jmp    f0100cf3 <debuginfo_eip+0x206>
f0100ccb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cd0:	eb 21                	jmp    f0100cf3 <debuginfo_eip+0x206>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100cd2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cd7:	eb 1a                	jmp    f0100cf3 <debuginfo_eip+0x206>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0100cd9:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cde:	eb 13                	jmp    f0100cf3 <debuginfo_eip+0x206>
f0100ce0:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ce5:	eb 0c                	jmp    f0100cf3 <debuginfo_eip+0x206>
f0100ce7:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cec:	eb 05                	jmp    f0100cf3 <debuginfo_eip+0x206>
f0100cee:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100cf3:	83 c4 2c             	add    $0x2c,%esp
f0100cf6:	5b                   	pop    %ebx
f0100cf7:	5e                   	pop    %esi
f0100cf8:	5f                   	pop    %edi
f0100cf9:	5d                   	pop    %ebp
f0100cfa:	c3                   	ret    
f0100cfb:	66 90                	xchg   %ax,%ax
f0100cfd:	66 90                	xchg   %ax,%ax
f0100cff:	90                   	nop

f0100d00 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100d00:	55                   	push   %ebp
f0100d01:	89 e5                	mov    %esp,%ebp
f0100d03:	57                   	push   %edi
f0100d04:	56                   	push   %esi
f0100d05:	53                   	push   %ebx
f0100d06:	83 ec 3c             	sub    $0x3c,%esp
f0100d09:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100d0c:	89 d7                	mov    %edx,%edi
f0100d0e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d11:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100d14:	8b 75 0c             	mov    0xc(%ebp),%esi
f0100d17:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0100d1a:	8b 45 10             	mov    0x10(%ebp),%eax
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100d1d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100d22:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100d25:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100d28:	39 f1                	cmp    %esi,%ecx
f0100d2a:	72 14                	jb     f0100d40 <printnum+0x40>
f0100d2c:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0100d2f:	76 0f                	jbe    f0100d40 <printnum+0x40>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100d31:	8b 45 14             	mov    0x14(%ebp),%eax
f0100d34:	8d 70 ff             	lea    -0x1(%eax),%esi
f0100d37:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100d3a:	85 f6                	test   %esi,%esi
f0100d3c:	7f 60                	jg     f0100d9e <printnum+0x9e>
f0100d3e:	eb 72                	jmp    f0100db2 <printnum+0xb2>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100d40:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0100d43:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0100d47:	8b 4d 14             	mov    0x14(%ebp),%ecx
f0100d4a:	8d 51 ff             	lea    -0x1(%ecx),%edx
f0100d4d:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100d51:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d55:	8b 44 24 08          	mov    0x8(%esp),%eax
f0100d59:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0100d5d:	89 c3                	mov    %eax,%ebx
f0100d5f:	89 d6                	mov    %edx,%esi
f0100d61:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100d64:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100d67:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100d6b:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100d6f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100d72:	89 04 24             	mov    %eax,(%esp)
f0100d75:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100d78:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d7c:	e8 4f 0a 00 00       	call   f01017d0 <__udivdi3>
f0100d81:	89 d9                	mov    %ebx,%ecx
f0100d83:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100d87:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100d8b:	89 04 24             	mov    %eax,(%esp)
f0100d8e:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100d92:	89 fa                	mov    %edi,%edx
f0100d94:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100d97:	e8 64 ff ff ff       	call   f0100d00 <printnum>
f0100d9c:	eb 14                	jmp    f0100db2 <printnum+0xb2>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100d9e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100da2:	8b 45 18             	mov    0x18(%ebp),%eax
f0100da5:	89 04 24             	mov    %eax,(%esp)
f0100da8:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100daa:	83 ee 01             	sub    $0x1,%esi
f0100dad:	75 ef                	jne    f0100d9e <printnum+0x9e>
f0100daf:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100db2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100db6:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100dba:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100dbd:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100dc0:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100dc4:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100dc8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100dcb:	89 04 24             	mov    %eax,(%esp)
f0100dce:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100dd1:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100dd5:	e8 26 0b 00 00       	call   f0101900 <__umoddi3>
f0100dda:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100dde:	0f be 80 69 1f 10 f0 	movsbl -0xfefe097(%eax),%eax
f0100de5:	89 04 24             	mov    %eax,(%esp)
f0100de8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100deb:	ff d0                	call   *%eax
}
f0100ded:	83 c4 3c             	add    $0x3c,%esp
f0100df0:	5b                   	pop    %ebx
f0100df1:	5e                   	pop    %esi
f0100df2:	5f                   	pop    %edi
f0100df3:	5d                   	pop    %ebp
f0100df4:	c3                   	ret    

f0100df5 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100df5:	55                   	push   %ebp
f0100df6:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100df8:	83 fa 01             	cmp    $0x1,%edx
f0100dfb:	7e 0e                	jle    f0100e0b <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100dfd:	8b 10                	mov    (%eax),%edx
f0100dff:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100e02:	89 08                	mov    %ecx,(%eax)
f0100e04:	8b 02                	mov    (%edx),%eax
f0100e06:	8b 52 04             	mov    0x4(%edx),%edx
f0100e09:	eb 22                	jmp    f0100e2d <getuint+0x38>
	else if (lflag)
f0100e0b:	85 d2                	test   %edx,%edx
f0100e0d:	74 10                	je     f0100e1f <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100e0f:	8b 10                	mov    (%eax),%edx
f0100e11:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100e14:	89 08                	mov    %ecx,(%eax)
f0100e16:	8b 02                	mov    (%edx),%eax
f0100e18:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e1d:	eb 0e                	jmp    f0100e2d <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100e1f:	8b 10                	mov    (%eax),%edx
f0100e21:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100e24:	89 08                	mov    %ecx,(%eax)
f0100e26:	8b 02                	mov    (%edx),%eax
f0100e28:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100e2d:	5d                   	pop    %ebp
f0100e2e:	c3                   	ret    

f0100e2f <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100e2f:	55                   	push   %ebp
f0100e30:	89 e5                	mov    %esp,%ebp
f0100e32:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100e35:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100e39:	8b 10                	mov    (%eax),%edx
f0100e3b:	3b 50 04             	cmp    0x4(%eax),%edx
f0100e3e:	73 0a                	jae    f0100e4a <sprintputch+0x1b>
		*b->buf++ = ch;
f0100e40:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100e43:	89 08                	mov    %ecx,(%eax)
f0100e45:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e48:	88 02                	mov    %al,(%edx)
}
f0100e4a:	5d                   	pop    %ebp
f0100e4b:	c3                   	ret    

f0100e4c <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100e4c:	55                   	push   %ebp
f0100e4d:	89 e5                	mov    %esp,%ebp
f0100e4f:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100e52:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100e55:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e59:	8b 45 10             	mov    0x10(%ebp),%eax
f0100e5c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100e60:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e63:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e67:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e6a:	89 04 24             	mov    %eax,(%esp)
f0100e6d:	e8 02 00 00 00       	call   f0100e74 <vprintfmt>
	va_end(ap);
}
f0100e72:	c9                   	leave  
f0100e73:	c3                   	ret    

f0100e74 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100e74:	55                   	push   %ebp
f0100e75:	89 e5                	mov    %esp,%ebp
f0100e77:	57                   	push   %edi
f0100e78:	56                   	push   %esi
f0100e79:	53                   	push   %ebx
f0100e7a:	83 ec 3c             	sub    $0x3c,%esp
f0100e7d:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0100e80:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100e83:	eb 18                	jmp    f0100e9d <vprintfmt+0x29>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100e85:	85 c0                	test   %eax,%eax
f0100e87:	0f 84 c3 03 00 00    	je     f0101250 <vprintfmt+0x3dc>
				return;
			putch(ch, putdat);
f0100e8d:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e91:	89 04 24             	mov    %eax,(%esp)
f0100e94:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100e97:	89 f3                	mov    %esi,%ebx
f0100e99:	eb 02                	jmp    f0100e9d <vprintfmt+0x29>
			break;
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
			for (fmt--; fmt[-1] != '%'; fmt--)
f0100e9b:	89 f3                	mov    %esi,%ebx
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100e9d:	8d 73 01             	lea    0x1(%ebx),%esi
f0100ea0:	0f b6 03             	movzbl (%ebx),%eax
f0100ea3:	83 f8 25             	cmp    $0x25,%eax
f0100ea6:	75 dd                	jne    f0100e85 <vprintfmt+0x11>
f0100ea8:	c6 45 e3 20          	movb   $0x20,-0x1d(%ebp)
f0100eac:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100eb3:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0100eba:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f0100ec1:	ba 00 00 00 00       	mov    $0x0,%edx
f0100ec6:	eb 1d                	jmp    f0100ee5 <vprintfmt+0x71>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ec8:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100eca:	c6 45 e3 2d          	movb   $0x2d,-0x1d(%ebp)
f0100ece:	eb 15                	jmp    f0100ee5 <vprintfmt+0x71>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ed0:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100ed2:	c6 45 e3 30          	movb   $0x30,-0x1d(%ebp)
f0100ed6:	eb 0d                	jmp    f0100ee5 <vprintfmt+0x71>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100ed8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100edb:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100ede:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ee5:	8d 5e 01             	lea    0x1(%esi),%ebx
f0100ee8:	0f b6 06             	movzbl (%esi),%eax
f0100eeb:	0f b6 c8             	movzbl %al,%ecx
f0100eee:	83 e8 23             	sub    $0x23,%eax
f0100ef1:	3c 55                	cmp    $0x55,%al
f0100ef3:	0f 87 2f 03 00 00    	ja     f0101228 <vprintfmt+0x3b4>
f0100ef9:	0f b6 c0             	movzbl %al,%eax
f0100efc:	ff 24 85 f8 1f 10 f0 	jmp    *-0xfefe008(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100f03:	8d 41 d0             	lea    -0x30(%ecx),%eax
f0100f06:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				ch = *fmt;
f0100f09:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
f0100f0d:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0100f10:	83 f9 09             	cmp    $0x9,%ecx
f0100f13:	77 50                	ja     f0100f65 <vprintfmt+0xf1>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f15:	89 de                	mov    %ebx,%esi
f0100f17:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100f1a:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
f0100f1d:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0100f20:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f0100f24:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0100f27:	8d 58 d0             	lea    -0x30(%eax),%ebx
f0100f2a:	83 fb 09             	cmp    $0x9,%ebx
f0100f2d:	76 eb                	jbe    f0100f1a <vprintfmt+0xa6>
f0100f2f:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0100f32:	eb 33                	jmp    f0100f67 <vprintfmt+0xf3>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100f34:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f37:	8d 48 04             	lea    0x4(%eax),%ecx
f0100f3a:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100f3d:	8b 00                	mov    (%eax),%eax
f0100f3f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f42:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100f44:	eb 21                	jmp    f0100f67 <vprintfmt+0xf3>
f0100f46:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100f49:	85 c9                	test   %ecx,%ecx
f0100f4b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f50:	0f 49 c1             	cmovns %ecx,%eax
f0100f53:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f56:	89 de                	mov    %ebx,%esi
f0100f58:	eb 8b                	jmp    f0100ee5 <vprintfmt+0x71>
f0100f5a:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100f5c:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100f63:	eb 80                	jmp    f0100ee5 <vprintfmt+0x71>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f65:	89 de                	mov    %ebx,%esi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f0100f67:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100f6b:	0f 89 74 ff ff ff    	jns    f0100ee5 <vprintfmt+0x71>
f0100f71:	e9 62 ff ff ff       	jmp    f0100ed8 <vprintfmt+0x64>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100f76:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f79:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100f7b:	e9 65 ff ff ff       	jmp    f0100ee5 <vprintfmt+0x71>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100f80:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f83:	8d 50 04             	lea    0x4(%eax),%edx
f0100f86:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f89:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100f8d:	8b 00                	mov    (%eax),%eax
f0100f8f:	89 04 24             	mov    %eax,(%esp)
f0100f92:	ff 55 08             	call   *0x8(%ebp)
			break;
f0100f95:	e9 03 ff ff ff       	jmp    f0100e9d <vprintfmt+0x29>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100f9a:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f9d:	8d 50 04             	lea    0x4(%eax),%edx
f0100fa0:	89 55 14             	mov    %edx,0x14(%ebp)
f0100fa3:	8b 00                	mov    (%eax),%eax
f0100fa5:	99                   	cltd   
f0100fa6:	31 d0                	xor    %edx,%eax
f0100fa8:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100faa:	83 f8 06             	cmp    $0x6,%eax
f0100fad:	7f 0b                	jg     f0100fba <vprintfmt+0x146>
f0100faf:	8b 14 85 50 21 10 f0 	mov    -0xfefdeb0(,%eax,4),%edx
f0100fb6:	85 d2                	test   %edx,%edx
f0100fb8:	75 20                	jne    f0100fda <vprintfmt+0x166>
				printfmt(putch, putdat, "error %d", err);
f0100fba:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100fbe:	c7 44 24 08 81 1f 10 	movl   $0xf0101f81,0x8(%esp)
f0100fc5:	f0 
f0100fc6:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100fca:	8b 45 08             	mov    0x8(%ebp),%eax
f0100fcd:	89 04 24             	mov    %eax,(%esp)
f0100fd0:	e8 77 fe ff ff       	call   f0100e4c <printfmt>
f0100fd5:	e9 c3 fe ff ff       	jmp    f0100e9d <vprintfmt+0x29>
			else
				printfmt(putch, putdat, "%s", p);
f0100fda:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100fde:	c7 44 24 08 8a 1f 10 	movl   $0xf0101f8a,0x8(%esp)
f0100fe5:	f0 
f0100fe6:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100fea:	8b 45 08             	mov    0x8(%ebp),%eax
f0100fed:	89 04 24             	mov    %eax,(%esp)
f0100ff0:	e8 57 fe ff ff       	call   f0100e4c <printfmt>
f0100ff5:	e9 a3 fe ff ff       	jmp    f0100e9d <vprintfmt+0x29>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ffa:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0100ffd:	8b 75 e4             	mov    -0x1c(%ebp),%esi
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0101000:	8b 45 14             	mov    0x14(%ebp),%eax
f0101003:	8d 50 04             	lea    0x4(%eax),%edx
f0101006:	89 55 14             	mov    %edx,0x14(%ebp)
f0101009:	8b 00                	mov    (%eax),%eax
				p = "(null)";
f010100b:	85 c0                	test   %eax,%eax
f010100d:	ba 7a 1f 10 f0       	mov    $0xf0101f7a,%edx
f0101012:	0f 45 d0             	cmovne %eax,%edx
f0101015:	89 55 d0             	mov    %edx,-0x30(%ebp)
			if (width > 0 && padc != '-')
f0101018:	80 7d e3 2d          	cmpb   $0x2d,-0x1d(%ebp)
f010101c:	74 04                	je     f0101022 <vprintfmt+0x1ae>
f010101e:	85 f6                	test   %esi,%esi
f0101020:	7f 19                	jg     f010103b <vprintfmt+0x1c7>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101022:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101025:	8d 70 01             	lea    0x1(%eax),%esi
f0101028:	0f b6 10             	movzbl (%eax),%edx
f010102b:	0f be c2             	movsbl %dl,%eax
f010102e:	85 c0                	test   %eax,%eax
f0101030:	0f 85 95 00 00 00    	jne    f01010cb <vprintfmt+0x257>
f0101036:	e9 85 00 00 00       	jmp    f01010c0 <vprintfmt+0x24c>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010103b:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010103f:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101042:	89 04 24             	mov    %eax,(%esp)
f0101045:	e8 88 03 00 00       	call   f01013d2 <strnlen>
f010104a:	29 c6                	sub    %eax,%esi
f010104c:	89 f0                	mov    %esi,%eax
f010104e:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0101051:	85 f6                	test   %esi,%esi
f0101053:	7e cd                	jle    f0101022 <vprintfmt+0x1ae>
					putch(padc, putdat);
f0101055:	0f be 75 e3          	movsbl -0x1d(%ebp),%esi
f0101059:	89 5d 10             	mov    %ebx,0x10(%ebp)
f010105c:	89 c3                	mov    %eax,%ebx
f010105e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101062:	89 34 24             	mov    %esi,(%esp)
f0101065:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101068:	83 eb 01             	sub    $0x1,%ebx
f010106b:	75 f1                	jne    f010105e <vprintfmt+0x1ea>
f010106d:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0101070:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0101073:	eb ad                	jmp    f0101022 <vprintfmt+0x1ae>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0101075:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0101079:	74 1e                	je     f0101099 <vprintfmt+0x225>
f010107b:	0f be d2             	movsbl %dl,%edx
f010107e:	83 ea 20             	sub    $0x20,%edx
f0101081:	83 fa 5e             	cmp    $0x5e,%edx
f0101084:	76 13                	jbe    f0101099 <vprintfmt+0x225>
					putch('?', putdat);
f0101086:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101089:	89 44 24 04          	mov    %eax,0x4(%esp)
f010108d:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0101094:	ff 55 08             	call   *0x8(%ebp)
f0101097:	eb 0d                	jmp    f01010a6 <vprintfmt+0x232>
				else
					putch(ch, putdat);
f0101099:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010109c:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01010a0:	89 04 24             	mov    %eax,(%esp)
f01010a3:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01010a6:	83 ef 01             	sub    $0x1,%edi
f01010a9:	83 c6 01             	add    $0x1,%esi
f01010ac:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f01010b0:	0f be c2             	movsbl %dl,%eax
f01010b3:	85 c0                	test   %eax,%eax
f01010b5:	75 20                	jne    f01010d7 <vprintfmt+0x263>
f01010b7:	89 7d e4             	mov    %edi,-0x1c(%ebp)
f01010ba:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01010bd:	8b 5d 10             	mov    0x10(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01010c0:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01010c4:	7f 25                	jg     f01010eb <vprintfmt+0x277>
f01010c6:	e9 d2 fd ff ff       	jmp    f0100e9d <vprintfmt+0x29>
f01010cb:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01010ce:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01010d1:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01010d4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01010d7:	85 db                	test   %ebx,%ebx
f01010d9:	78 9a                	js     f0101075 <vprintfmt+0x201>
f01010db:	83 eb 01             	sub    $0x1,%ebx
f01010de:	79 95                	jns    f0101075 <vprintfmt+0x201>
f01010e0:	89 7d e4             	mov    %edi,-0x1c(%ebp)
f01010e3:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01010e6:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01010e9:	eb d5                	jmp    f01010c0 <vprintfmt+0x24c>
f01010eb:	8b 75 08             	mov    0x8(%ebp),%esi
f01010ee:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01010f1:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01010f4:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01010f8:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01010ff:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101101:	83 eb 01             	sub    $0x1,%ebx
f0101104:	75 ee                	jne    f01010f4 <vprintfmt+0x280>
f0101106:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0101109:	e9 8f fd ff ff       	jmp    f0100e9d <vprintfmt+0x29>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010110e:	83 fa 01             	cmp    $0x1,%edx
f0101111:	7e 16                	jle    f0101129 <vprintfmt+0x2b5>
		return va_arg(*ap, long long);
f0101113:	8b 45 14             	mov    0x14(%ebp),%eax
f0101116:	8d 50 08             	lea    0x8(%eax),%edx
f0101119:	89 55 14             	mov    %edx,0x14(%ebp)
f010111c:	8b 50 04             	mov    0x4(%eax),%edx
f010111f:	8b 00                	mov    (%eax),%eax
f0101121:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101124:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101127:	eb 32                	jmp    f010115b <vprintfmt+0x2e7>
	else if (lflag)
f0101129:	85 d2                	test   %edx,%edx
f010112b:	74 18                	je     f0101145 <vprintfmt+0x2d1>
		return va_arg(*ap, long);
f010112d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101130:	8d 50 04             	lea    0x4(%eax),%edx
f0101133:	89 55 14             	mov    %edx,0x14(%ebp)
f0101136:	8b 30                	mov    (%eax),%esi
f0101138:	89 75 d8             	mov    %esi,-0x28(%ebp)
f010113b:	89 f0                	mov    %esi,%eax
f010113d:	c1 f8 1f             	sar    $0x1f,%eax
f0101140:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0101143:	eb 16                	jmp    f010115b <vprintfmt+0x2e7>
	else
		return va_arg(*ap, int);
f0101145:	8b 45 14             	mov    0x14(%ebp),%eax
f0101148:	8d 50 04             	lea    0x4(%eax),%edx
f010114b:	89 55 14             	mov    %edx,0x14(%ebp)
f010114e:	8b 30                	mov    (%eax),%esi
f0101150:	89 75 d8             	mov    %esi,-0x28(%ebp)
f0101153:	89 f0                	mov    %esi,%eax
f0101155:	c1 f8 1f             	sar    $0x1f,%eax
f0101158:	89 45 dc             	mov    %eax,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010115b:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010115e:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0101161:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101166:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010116a:	0f 89 80 00 00 00    	jns    f01011f0 <vprintfmt+0x37c>
				putch('-', putdat);
f0101170:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101174:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f010117b:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f010117e:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101181:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101184:	f7 d8                	neg    %eax
f0101186:	83 d2 00             	adc    $0x0,%edx
f0101189:	f7 da                	neg    %edx
			}
			base = 10;
f010118b:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0101190:	eb 5e                	jmp    f01011f0 <vprintfmt+0x37c>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0101192:	8d 45 14             	lea    0x14(%ebp),%eax
f0101195:	e8 5b fc ff ff       	call   f0100df5 <getuint>
			base = 10;
f010119a:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f010119f:	eb 4f                	jmp    f01011f0 <vprintfmt+0x37c>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num=getuint(&ap, lflag);
f01011a1:	8d 45 14             	lea    0x14(%ebp),%eax
f01011a4:	e8 4c fc ff ff       	call   f0100df5 <getuint>
			base=8;
f01011a9:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f01011ae:	eb 40                	jmp    f01011f0 <vprintfmt+0x37c>
			putch('X', putdat);
			break;

		// pointer
		case 'p':
			putch('0', putdat);
f01011b0:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011b4:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01011bb:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01011be:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011c2:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01011c9:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01011cc:	8b 45 14             	mov    0x14(%ebp),%eax
f01011cf:	8d 50 04             	lea    0x4(%eax),%edx
f01011d2:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01011d5:	8b 00                	mov    (%eax),%eax
f01011d7:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01011dc:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01011e1:	eb 0d                	jmp    f01011f0 <vprintfmt+0x37c>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01011e3:	8d 45 14             	lea    0x14(%ebp),%eax
f01011e6:	e8 0a fc ff ff       	call   f0100df5 <getuint>
			base = 16;
f01011eb:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f01011f0:	0f be 75 e3          	movsbl -0x1d(%ebp),%esi
f01011f4:	89 74 24 10          	mov    %esi,0x10(%esp)
f01011f8:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01011fb:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01011ff:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101203:	89 04 24             	mov    %eax,(%esp)
f0101206:	89 54 24 04          	mov    %edx,0x4(%esp)
f010120a:	89 fa                	mov    %edi,%edx
f010120c:	8b 45 08             	mov    0x8(%ebp),%eax
f010120f:	e8 ec fa ff ff       	call   f0100d00 <printnum>
			break;
f0101214:	e9 84 fc ff ff       	jmp    f0100e9d <vprintfmt+0x29>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101219:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010121d:	89 0c 24             	mov    %ecx,(%esp)
f0101220:	ff 55 08             	call   *0x8(%ebp)
			break;
f0101223:	e9 75 fc ff ff       	jmp    f0100e9d <vprintfmt+0x29>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101228:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010122c:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0101233:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101236:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f010123a:	0f 84 5b fc ff ff    	je     f0100e9b <vprintfmt+0x27>
f0101240:	89 f3                	mov    %esi,%ebx
f0101242:	83 eb 01             	sub    $0x1,%ebx
f0101245:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0101249:	75 f7                	jne    f0101242 <vprintfmt+0x3ce>
f010124b:	e9 4d fc ff ff       	jmp    f0100e9d <vprintfmt+0x29>
				/* do nothing */;
			break;
		}
	}
}
f0101250:	83 c4 3c             	add    $0x3c,%esp
f0101253:	5b                   	pop    %ebx
f0101254:	5e                   	pop    %esi
f0101255:	5f                   	pop    %edi
f0101256:	5d                   	pop    %ebp
f0101257:	c3                   	ret    

f0101258 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101258:	55                   	push   %ebp
f0101259:	89 e5                	mov    %esp,%ebp
f010125b:	83 ec 28             	sub    $0x28,%esp
f010125e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101261:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101264:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101267:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010126b:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010126e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101275:	85 c0                	test   %eax,%eax
f0101277:	74 30                	je     f01012a9 <vsnprintf+0x51>
f0101279:	85 d2                	test   %edx,%edx
f010127b:	7e 2c                	jle    f01012a9 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010127d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101280:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101284:	8b 45 10             	mov    0x10(%ebp),%eax
f0101287:	89 44 24 08          	mov    %eax,0x8(%esp)
f010128b:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010128e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101292:	c7 04 24 2f 0e 10 f0 	movl   $0xf0100e2f,(%esp)
f0101299:	e8 d6 fb ff ff       	call   f0100e74 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010129e:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01012a1:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01012a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01012a7:	eb 05                	jmp    f01012ae <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01012a9:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01012ae:	c9                   	leave  
f01012af:	c3                   	ret    

f01012b0 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01012b0:	55                   	push   %ebp
f01012b1:	89 e5                	mov    %esp,%ebp
f01012b3:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01012b6:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01012b9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01012bd:	8b 45 10             	mov    0x10(%ebp),%eax
f01012c0:	89 44 24 08          	mov    %eax,0x8(%esp)
f01012c4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01012c7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012cb:	8b 45 08             	mov    0x8(%ebp),%eax
f01012ce:	89 04 24             	mov    %eax,(%esp)
f01012d1:	e8 82 ff ff ff       	call   f0101258 <vsnprintf>
	va_end(ap);

	return rc;
}
f01012d6:	c9                   	leave  
f01012d7:	c3                   	ret    
f01012d8:	66 90                	xchg   %ax,%ax
f01012da:	66 90                	xchg   %ax,%ax
f01012dc:	66 90                	xchg   %ax,%ax
f01012de:	66 90                	xchg   %ax,%ax

f01012e0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01012e0:	55                   	push   %ebp
f01012e1:	89 e5                	mov    %esp,%ebp
f01012e3:	57                   	push   %edi
f01012e4:	56                   	push   %esi
f01012e5:	53                   	push   %ebx
f01012e6:	83 ec 1c             	sub    $0x1c,%esp
f01012e9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01012ec:	85 c0                	test   %eax,%eax
f01012ee:	74 10                	je     f0101300 <readline+0x20>
		cprintf("%s", prompt);
f01012f0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012f4:	c7 04 24 8a 1f 10 f0 	movl   $0xf0101f8a,(%esp)
f01012fb:	e8 e9 f6 ff ff       	call   f01009e9 <cprintf>

	i = 0;
	echoing = iscons(0);
f0101300:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101307:	e8 79 f3 ff ff       	call   f0100685 <iscons>
f010130c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010130e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101313:	e8 5c f3 ff ff       	call   f0100674 <getchar>
f0101318:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010131a:	85 c0                	test   %eax,%eax
f010131c:	79 17                	jns    f0101335 <readline+0x55>
			cprintf("read error: %e\n", c);
f010131e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101322:	c7 04 24 6c 21 10 f0 	movl   $0xf010216c,(%esp)
f0101329:	e8 bb f6 ff ff       	call   f01009e9 <cprintf>
			return NULL;
f010132e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101333:	eb 6d                	jmp    f01013a2 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101335:	83 f8 7f             	cmp    $0x7f,%eax
f0101338:	74 05                	je     f010133f <readline+0x5f>
f010133a:	83 f8 08             	cmp    $0x8,%eax
f010133d:	75 19                	jne    f0101358 <readline+0x78>
f010133f:	85 f6                	test   %esi,%esi
f0101341:	7e 15                	jle    f0101358 <readline+0x78>
			if (echoing)
f0101343:	85 ff                	test   %edi,%edi
f0101345:	74 0c                	je     f0101353 <readline+0x73>
				cputchar('\b');
f0101347:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010134e:	e8 11 f3 ff ff       	call   f0100664 <cputchar>
			i--;
f0101353:	83 ee 01             	sub    $0x1,%esi
f0101356:	eb bb                	jmp    f0101313 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101358:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010135e:	7f 1c                	jg     f010137c <readline+0x9c>
f0101360:	83 fb 1f             	cmp    $0x1f,%ebx
f0101363:	7e 17                	jle    f010137c <readline+0x9c>
			if (echoing)
f0101365:	85 ff                	test   %edi,%edi
f0101367:	74 08                	je     f0101371 <readline+0x91>
				cputchar(c);
f0101369:	89 1c 24             	mov    %ebx,(%esp)
f010136c:	e8 f3 f2 ff ff       	call   f0100664 <cputchar>
			buf[i++] = c;
f0101371:	88 9e 60 25 11 f0    	mov    %bl,-0xfeedaa0(%esi)
f0101377:	8d 76 01             	lea    0x1(%esi),%esi
f010137a:	eb 97                	jmp    f0101313 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010137c:	83 fb 0d             	cmp    $0xd,%ebx
f010137f:	74 05                	je     f0101386 <readline+0xa6>
f0101381:	83 fb 0a             	cmp    $0xa,%ebx
f0101384:	75 8d                	jne    f0101313 <readline+0x33>
			if (echoing)
f0101386:	85 ff                	test   %edi,%edi
f0101388:	74 0c                	je     f0101396 <readline+0xb6>
				cputchar('\n');
f010138a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0101391:	e8 ce f2 ff ff       	call   f0100664 <cputchar>
			buf[i] = 0;
f0101396:	c6 86 60 25 11 f0 00 	movb   $0x0,-0xfeedaa0(%esi)
			return buf;
f010139d:	b8 60 25 11 f0       	mov    $0xf0112560,%eax
		}
	}
}
f01013a2:	83 c4 1c             	add    $0x1c,%esp
f01013a5:	5b                   	pop    %ebx
f01013a6:	5e                   	pop    %esi
f01013a7:	5f                   	pop    %edi
f01013a8:	5d                   	pop    %ebp
f01013a9:	c3                   	ret    
f01013aa:	66 90                	xchg   %ax,%ax
f01013ac:	66 90                	xchg   %ax,%ax
f01013ae:	66 90                	xchg   %ax,%ax

f01013b0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01013b0:	55                   	push   %ebp
f01013b1:	89 e5                	mov    %esp,%ebp
f01013b3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01013b6:	80 3a 00             	cmpb   $0x0,(%edx)
f01013b9:	74 10                	je     f01013cb <strlen+0x1b>
f01013bb:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f01013c0:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01013c3:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01013c7:	75 f7                	jne    f01013c0 <strlen+0x10>
f01013c9:	eb 05                	jmp    f01013d0 <strlen+0x20>
f01013cb:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f01013d0:	5d                   	pop    %ebp
f01013d1:	c3                   	ret    

f01013d2 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01013d2:	55                   	push   %ebp
f01013d3:	89 e5                	mov    %esp,%ebp
f01013d5:	53                   	push   %ebx
f01013d6:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01013d9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01013dc:	85 c9                	test   %ecx,%ecx
f01013de:	74 1c                	je     f01013fc <strnlen+0x2a>
f01013e0:	80 3b 00             	cmpb   $0x0,(%ebx)
f01013e3:	74 1e                	je     f0101403 <strnlen+0x31>
f01013e5:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f01013ea:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01013ec:	39 ca                	cmp    %ecx,%edx
f01013ee:	74 18                	je     f0101408 <strnlen+0x36>
f01013f0:	83 c2 01             	add    $0x1,%edx
f01013f3:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f01013f8:	75 f0                	jne    f01013ea <strnlen+0x18>
f01013fa:	eb 0c                	jmp    f0101408 <strnlen+0x36>
f01013fc:	b8 00 00 00 00       	mov    $0x0,%eax
f0101401:	eb 05                	jmp    f0101408 <strnlen+0x36>
f0101403:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0101408:	5b                   	pop    %ebx
f0101409:	5d                   	pop    %ebp
f010140a:	c3                   	ret    

f010140b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010140b:	55                   	push   %ebp
f010140c:	89 e5                	mov    %esp,%ebp
f010140e:	53                   	push   %ebx
f010140f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101412:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101415:	89 c2                	mov    %eax,%edx
f0101417:	83 c2 01             	add    $0x1,%edx
f010141a:	83 c1 01             	add    $0x1,%ecx
f010141d:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0101421:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101424:	84 db                	test   %bl,%bl
f0101426:	75 ef                	jne    f0101417 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101428:	5b                   	pop    %ebx
f0101429:	5d                   	pop    %ebp
f010142a:	c3                   	ret    

f010142b <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010142b:	55                   	push   %ebp
f010142c:	89 e5                	mov    %esp,%ebp
f010142e:	56                   	push   %esi
f010142f:	53                   	push   %ebx
f0101430:	8b 75 08             	mov    0x8(%ebp),%esi
f0101433:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101436:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101439:	85 db                	test   %ebx,%ebx
f010143b:	74 17                	je     f0101454 <strncpy+0x29>
f010143d:	01 f3                	add    %esi,%ebx
f010143f:	89 f1                	mov    %esi,%ecx
		*dst++ = *src;
f0101441:	83 c1 01             	add    $0x1,%ecx
f0101444:	0f b6 02             	movzbl (%edx),%eax
f0101447:	88 41 ff             	mov    %al,-0x1(%ecx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010144a:	80 3a 01             	cmpb   $0x1,(%edx)
f010144d:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101450:	39 d9                	cmp    %ebx,%ecx
f0101452:	75 ed                	jne    f0101441 <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101454:	89 f0                	mov    %esi,%eax
f0101456:	5b                   	pop    %ebx
f0101457:	5e                   	pop    %esi
f0101458:	5d                   	pop    %ebp
f0101459:	c3                   	ret    

f010145a <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010145a:	55                   	push   %ebp
f010145b:	89 e5                	mov    %esp,%ebp
f010145d:	57                   	push   %edi
f010145e:	56                   	push   %esi
f010145f:	53                   	push   %ebx
f0101460:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101463:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101466:	8b 75 10             	mov    0x10(%ebp),%esi
f0101469:	89 f8                	mov    %edi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010146b:	85 f6                	test   %esi,%esi
f010146d:	74 34                	je     f01014a3 <strlcpy+0x49>
		while (--size > 0 && *src != '\0')
f010146f:	83 fe 01             	cmp    $0x1,%esi
f0101472:	74 26                	je     f010149a <strlcpy+0x40>
f0101474:	0f b6 0b             	movzbl (%ebx),%ecx
f0101477:	84 c9                	test   %cl,%cl
f0101479:	74 23                	je     f010149e <strlcpy+0x44>
f010147b:	83 ee 02             	sub    $0x2,%esi
f010147e:	ba 00 00 00 00       	mov    $0x0,%edx
			*dst++ = *src++;
f0101483:	83 c0 01             	add    $0x1,%eax
f0101486:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101489:	39 f2                	cmp    %esi,%edx
f010148b:	74 13                	je     f01014a0 <strlcpy+0x46>
f010148d:	83 c2 01             	add    $0x1,%edx
f0101490:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0101494:	84 c9                	test   %cl,%cl
f0101496:	75 eb                	jne    f0101483 <strlcpy+0x29>
f0101498:	eb 06                	jmp    f01014a0 <strlcpy+0x46>
f010149a:	89 f8                	mov    %edi,%eax
f010149c:	eb 02                	jmp    f01014a0 <strlcpy+0x46>
f010149e:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
f01014a0:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01014a3:	29 f8                	sub    %edi,%eax
}
f01014a5:	5b                   	pop    %ebx
f01014a6:	5e                   	pop    %esi
f01014a7:	5f                   	pop    %edi
f01014a8:	5d                   	pop    %ebp
f01014a9:	c3                   	ret    

f01014aa <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01014aa:	55                   	push   %ebp
f01014ab:	89 e5                	mov    %esp,%ebp
f01014ad:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01014b0:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01014b3:	0f b6 01             	movzbl (%ecx),%eax
f01014b6:	84 c0                	test   %al,%al
f01014b8:	74 15                	je     f01014cf <strcmp+0x25>
f01014ba:	3a 02                	cmp    (%edx),%al
f01014bc:	75 11                	jne    f01014cf <strcmp+0x25>
		p++, q++;
f01014be:	83 c1 01             	add    $0x1,%ecx
f01014c1:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01014c4:	0f b6 01             	movzbl (%ecx),%eax
f01014c7:	84 c0                	test   %al,%al
f01014c9:	74 04                	je     f01014cf <strcmp+0x25>
f01014cb:	3a 02                	cmp    (%edx),%al
f01014cd:	74 ef                	je     f01014be <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01014cf:	0f b6 c0             	movzbl %al,%eax
f01014d2:	0f b6 12             	movzbl (%edx),%edx
f01014d5:	29 d0                	sub    %edx,%eax
}
f01014d7:	5d                   	pop    %ebp
f01014d8:	c3                   	ret    

f01014d9 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01014d9:	55                   	push   %ebp
f01014da:	89 e5                	mov    %esp,%ebp
f01014dc:	56                   	push   %esi
f01014dd:	53                   	push   %ebx
f01014de:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01014e1:	8b 55 0c             	mov    0xc(%ebp),%edx
f01014e4:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
f01014e7:	85 f6                	test   %esi,%esi
f01014e9:	74 29                	je     f0101514 <strncmp+0x3b>
f01014eb:	0f b6 03             	movzbl (%ebx),%eax
f01014ee:	84 c0                	test   %al,%al
f01014f0:	74 30                	je     f0101522 <strncmp+0x49>
f01014f2:	3a 02                	cmp    (%edx),%al
f01014f4:	75 2c                	jne    f0101522 <strncmp+0x49>
f01014f6:	8d 43 01             	lea    0x1(%ebx),%eax
f01014f9:	01 de                	add    %ebx,%esi
		n--, p++, q++;
f01014fb:	89 c3                	mov    %eax,%ebx
f01014fd:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101500:	39 f0                	cmp    %esi,%eax
f0101502:	74 17                	je     f010151b <strncmp+0x42>
f0101504:	0f b6 08             	movzbl (%eax),%ecx
f0101507:	84 c9                	test   %cl,%cl
f0101509:	74 17                	je     f0101522 <strncmp+0x49>
f010150b:	83 c0 01             	add    $0x1,%eax
f010150e:	3a 0a                	cmp    (%edx),%cl
f0101510:	74 e9                	je     f01014fb <strncmp+0x22>
f0101512:	eb 0e                	jmp    f0101522 <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101514:	b8 00 00 00 00       	mov    $0x0,%eax
f0101519:	eb 0f                	jmp    f010152a <strncmp+0x51>
f010151b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101520:	eb 08                	jmp    f010152a <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101522:	0f b6 03             	movzbl (%ebx),%eax
f0101525:	0f b6 12             	movzbl (%edx),%edx
f0101528:	29 d0                	sub    %edx,%eax
}
f010152a:	5b                   	pop    %ebx
f010152b:	5e                   	pop    %esi
f010152c:	5d                   	pop    %ebp
f010152d:	c3                   	ret    

f010152e <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010152e:	55                   	push   %ebp
f010152f:	89 e5                	mov    %esp,%ebp
f0101531:	53                   	push   %ebx
f0101532:	8b 45 08             	mov    0x8(%ebp),%eax
f0101535:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f0101538:	0f b6 18             	movzbl (%eax),%ebx
f010153b:	84 db                	test   %bl,%bl
f010153d:	74 1d                	je     f010155c <strchr+0x2e>
f010153f:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f0101541:	38 d3                	cmp    %dl,%bl
f0101543:	75 06                	jne    f010154b <strchr+0x1d>
f0101545:	eb 1a                	jmp    f0101561 <strchr+0x33>
f0101547:	38 ca                	cmp    %cl,%dl
f0101549:	74 16                	je     f0101561 <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010154b:	83 c0 01             	add    $0x1,%eax
f010154e:	0f b6 10             	movzbl (%eax),%edx
f0101551:	84 d2                	test   %dl,%dl
f0101553:	75 f2                	jne    f0101547 <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
f0101555:	b8 00 00 00 00       	mov    $0x0,%eax
f010155a:	eb 05                	jmp    f0101561 <strchr+0x33>
f010155c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101561:	5b                   	pop    %ebx
f0101562:	5d                   	pop    %ebp
f0101563:	c3                   	ret    

f0101564 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101564:	55                   	push   %ebp
f0101565:	89 e5                	mov    %esp,%ebp
f0101567:	53                   	push   %ebx
f0101568:	8b 45 08             	mov    0x8(%ebp),%eax
f010156b:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f010156e:	0f b6 18             	movzbl (%eax),%ebx
f0101571:	84 db                	test   %bl,%bl
f0101573:	74 17                	je     f010158c <strfind+0x28>
f0101575:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f0101577:	38 d3                	cmp    %dl,%bl
f0101579:	75 07                	jne    f0101582 <strfind+0x1e>
f010157b:	eb 0f                	jmp    f010158c <strfind+0x28>
f010157d:	38 ca                	cmp    %cl,%dl
f010157f:	90                   	nop
f0101580:	74 0a                	je     f010158c <strfind+0x28>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0101582:	83 c0 01             	add    $0x1,%eax
f0101585:	0f b6 10             	movzbl (%eax),%edx
f0101588:	84 d2                	test   %dl,%dl
f010158a:	75 f1                	jne    f010157d <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
f010158c:	5b                   	pop    %ebx
f010158d:	5d                   	pop    %ebp
f010158e:	c3                   	ret    

f010158f <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010158f:	55                   	push   %ebp
f0101590:	89 e5                	mov    %esp,%ebp
f0101592:	57                   	push   %edi
f0101593:	56                   	push   %esi
f0101594:	53                   	push   %ebx
f0101595:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101598:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010159b:	85 c9                	test   %ecx,%ecx
f010159d:	74 36                	je     f01015d5 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010159f:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01015a5:	75 28                	jne    f01015cf <memset+0x40>
f01015a7:	f6 c1 03             	test   $0x3,%cl
f01015aa:	75 23                	jne    f01015cf <memset+0x40>
		c &= 0xFF;
f01015ac:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01015b0:	89 d3                	mov    %edx,%ebx
f01015b2:	c1 e3 08             	shl    $0x8,%ebx
f01015b5:	89 d6                	mov    %edx,%esi
f01015b7:	c1 e6 18             	shl    $0x18,%esi
f01015ba:	89 d0                	mov    %edx,%eax
f01015bc:	c1 e0 10             	shl    $0x10,%eax
f01015bf:	09 f0                	or     %esi,%eax
f01015c1:	09 c2                	or     %eax,%edx
f01015c3:	89 d0                	mov    %edx,%eax
f01015c5:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01015c7:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01015ca:	fc                   	cld    
f01015cb:	f3 ab                	rep stos %eax,%es:(%edi)
f01015cd:	eb 06                	jmp    f01015d5 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01015cf:	8b 45 0c             	mov    0xc(%ebp),%eax
f01015d2:	fc                   	cld    
f01015d3:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01015d5:	89 f8                	mov    %edi,%eax
f01015d7:	5b                   	pop    %ebx
f01015d8:	5e                   	pop    %esi
f01015d9:	5f                   	pop    %edi
f01015da:	5d                   	pop    %ebp
f01015db:	c3                   	ret    

f01015dc <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01015dc:	55                   	push   %ebp
f01015dd:	89 e5                	mov    %esp,%ebp
f01015df:	57                   	push   %edi
f01015e0:	56                   	push   %esi
f01015e1:	8b 45 08             	mov    0x8(%ebp),%eax
f01015e4:	8b 75 0c             	mov    0xc(%ebp),%esi
f01015e7:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01015ea:	39 c6                	cmp    %eax,%esi
f01015ec:	73 35                	jae    f0101623 <memmove+0x47>
f01015ee:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01015f1:	39 d0                	cmp    %edx,%eax
f01015f3:	73 2e                	jae    f0101623 <memmove+0x47>
		s += n;
		d += n;
f01015f5:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f01015f8:	89 d6                	mov    %edx,%esi
f01015fa:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01015fc:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101602:	75 13                	jne    f0101617 <memmove+0x3b>
f0101604:	f6 c1 03             	test   $0x3,%cl
f0101607:	75 0e                	jne    f0101617 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101609:	83 ef 04             	sub    $0x4,%edi
f010160c:	8d 72 fc             	lea    -0x4(%edx),%esi
f010160f:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0101612:	fd                   	std    
f0101613:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101615:	eb 09                	jmp    f0101620 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0101617:	83 ef 01             	sub    $0x1,%edi
f010161a:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010161d:	fd                   	std    
f010161e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101620:	fc                   	cld    
f0101621:	eb 1d                	jmp    f0101640 <memmove+0x64>
f0101623:	89 f2                	mov    %esi,%edx
f0101625:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101627:	f6 c2 03             	test   $0x3,%dl
f010162a:	75 0f                	jne    f010163b <memmove+0x5f>
f010162c:	f6 c1 03             	test   $0x3,%cl
f010162f:	75 0a                	jne    f010163b <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101631:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0101634:	89 c7                	mov    %eax,%edi
f0101636:	fc                   	cld    
f0101637:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101639:	eb 05                	jmp    f0101640 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010163b:	89 c7                	mov    %eax,%edi
f010163d:	fc                   	cld    
f010163e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101640:	5e                   	pop    %esi
f0101641:	5f                   	pop    %edi
f0101642:	5d                   	pop    %ebp
f0101643:	c3                   	ret    

f0101644 <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f0101644:	55                   	push   %ebp
f0101645:	89 e5                	mov    %esp,%ebp
f0101647:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f010164a:	8b 45 10             	mov    0x10(%ebp),%eax
f010164d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101651:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101654:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101658:	8b 45 08             	mov    0x8(%ebp),%eax
f010165b:	89 04 24             	mov    %eax,(%esp)
f010165e:	e8 79 ff ff ff       	call   f01015dc <memmove>
}
f0101663:	c9                   	leave  
f0101664:	c3                   	ret    

f0101665 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101665:	55                   	push   %ebp
f0101666:	89 e5                	mov    %esp,%ebp
f0101668:	57                   	push   %edi
f0101669:	56                   	push   %esi
f010166a:	53                   	push   %ebx
f010166b:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010166e:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101671:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101674:	8d 78 ff             	lea    -0x1(%eax),%edi
f0101677:	85 c0                	test   %eax,%eax
f0101679:	74 36                	je     f01016b1 <memcmp+0x4c>
		if (*s1 != *s2)
f010167b:	0f b6 03             	movzbl (%ebx),%eax
f010167e:	0f b6 0e             	movzbl (%esi),%ecx
f0101681:	ba 00 00 00 00       	mov    $0x0,%edx
f0101686:	38 c8                	cmp    %cl,%al
f0101688:	74 1c                	je     f01016a6 <memcmp+0x41>
f010168a:	eb 10                	jmp    f010169c <memcmp+0x37>
f010168c:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f0101691:	83 c2 01             	add    $0x1,%edx
f0101694:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f0101698:	38 c8                	cmp    %cl,%al
f010169a:	74 0a                	je     f01016a6 <memcmp+0x41>
			return (int) *s1 - (int) *s2;
f010169c:	0f b6 c0             	movzbl %al,%eax
f010169f:	0f b6 c9             	movzbl %cl,%ecx
f01016a2:	29 c8                	sub    %ecx,%eax
f01016a4:	eb 10                	jmp    f01016b6 <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01016a6:	39 fa                	cmp    %edi,%edx
f01016a8:	75 e2                	jne    f010168c <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01016aa:	b8 00 00 00 00       	mov    $0x0,%eax
f01016af:	eb 05                	jmp    f01016b6 <memcmp+0x51>
f01016b1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01016b6:	5b                   	pop    %ebx
f01016b7:	5e                   	pop    %esi
f01016b8:	5f                   	pop    %edi
f01016b9:	5d                   	pop    %ebp
f01016ba:	c3                   	ret    

f01016bb <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01016bb:	55                   	push   %ebp
f01016bc:	89 e5                	mov    %esp,%ebp
f01016be:	53                   	push   %ebx
f01016bf:	8b 45 08             	mov    0x8(%ebp),%eax
f01016c2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
f01016c5:	89 c2                	mov    %eax,%edx
f01016c7:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01016ca:	39 d0                	cmp    %edx,%eax
f01016cc:	73 14                	jae    f01016e2 <memfind+0x27>
		if (*(const unsigned char *) s == (unsigned char) c)
f01016ce:	89 d9                	mov    %ebx,%ecx
f01016d0:	38 18                	cmp    %bl,(%eax)
f01016d2:	75 06                	jne    f01016da <memfind+0x1f>
f01016d4:	eb 0c                	jmp    f01016e2 <memfind+0x27>
f01016d6:	38 08                	cmp    %cl,(%eax)
f01016d8:	74 08                	je     f01016e2 <memfind+0x27>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01016da:	83 c0 01             	add    $0x1,%eax
f01016dd:	39 d0                	cmp    %edx,%eax
f01016df:	90                   	nop
f01016e0:	75 f4                	jne    f01016d6 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01016e2:	5b                   	pop    %ebx
f01016e3:	5d                   	pop    %ebp
f01016e4:	c3                   	ret    

f01016e5 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01016e5:	55                   	push   %ebp
f01016e6:	89 e5                	mov    %esp,%ebp
f01016e8:	57                   	push   %edi
f01016e9:	56                   	push   %esi
f01016ea:	53                   	push   %ebx
f01016eb:	8b 55 08             	mov    0x8(%ebp),%edx
f01016ee:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01016f1:	0f b6 0a             	movzbl (%edx),%ecx
f01016f4:	80 f9 09             	cmp    $0x9,%cl
f01016f7:	74 05                	je     f01016fe <strtol+0x19>
f01016f9:	80 f9 20             	cmp    $0x20,%cl
f01016fc:	75 10                	jne    f010170e <strtol+0x29>
		s++;
f01016fe:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101701:	0f b6 0a             	movzbl (%edx),%ecx
f0101704:	80 f9 09             	cmp    $0x9,%cl
f0101707:	74 f5                	je     f01016fe <strtol+0x19>
f0101709:	80 f9 20             	cmp    $0x20,%cl
f010170c:	74 f0                	je     f01016fe <strtol+0x19>
		s++;

	// plus/minus sign
	if (*s == '+')
f010170e:	80 f9 2b             	cmp    $0x2b,%cl
f0101711:	75 0a                	jne    f010171d <strtol+0x38>
		s++;
f0101713:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101716:	bf 00 00 00 00       	mov    $0x0,%edi
f010171b:	eb 11                	jmp    f010172e <strtol+0x49>
f010171d:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0101722:	80 f9 2d             	cmp    $0x2d,%cl
f0101725:	75 07                	jne    f010172e <strtol+0x49>
		s++, neg = 1;
f0101727:	83 c2 01             	add    $0x1,%edx
f010172a:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010172e:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0101733:	75 15                	jne    f010174a <strtol+0x65>
f0101735:	80 3a 30             	cmpb   $0x30,(%edx)
f0101738:	75 10                	jne    f010174a <strtol+0x65>
f010173a:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f010173e:	75 0a                	jne    f010174a <strtol+0x65>
		s += 2, base = 16;
f0101740:	83 c2 02             	add    $0x2,%edx
f0101743:	b8 10 00 00 00       	mov    $0x10,%eax
f0101748:	eb 10                	jmp    f010175a <strtol+0x75>
	else if (base == 0 && s[0] == '0')
f010174a:	85 c0                	test   %eax,%eax
f010174c:	75 0c                	jne    f010175a <strtol+0x75>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010174e:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101750:	80 3a 30             	cmpb   $0x30,(%edx)
f0101753:	75 05                	jne    f010175a <strtol+0x75>
		s++, base = 8;
f0101755:	83 c2 01             	add    $0x1,%edx
f0101758:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f010175a:	bb 00 00 00 00       	mov    $0x0,%ebx
f010175f:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101762:	0f b6 0a             	movzbl (%edx),%ecx
f0101765:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0101768:	89 f0                	mov    %esi,%eax
f010176a:	3c 09                	cmp    $0x9,%al
f010176c:	77 08                	ja     f0101776 <strtol+0x91>
			dig = *s - '0';
f010176e:	0f be c9             	movsbl %cl,%ecx
f0101771:	83 e9 30             	sub    $0x30,%ecx
f0101774:	eb 20                	jmp    f0101796 <strtol+0xb1>
		else if (*s >= 'a' && *s <= 'z')
f0101776:	8d 71 9f             	lea    -0x61(%ecx),%esi
f0101779:	89 f0                	mov    %esi,%eax
f010177b:	3c 19                	cmp    $0x19,%al
f010177d:	77 08                	ja     f0101787 <strtol+0xa2>
			dig = *s - 'a' + 10;
f010177f:	0f be c9             	movsbl %cl,%ecx
f0101782:	83 e9 57             	sub    $0x57,%ecx
f0101785:	eb 0f                	jmp    f0101796 <strtol+0xb1>
		else if (*s >= 'A' && *s <= 'Z')
f0101787:	8d 71 bf             	lea    -0x41(%ecx),%esi
f010178a:	89 f0                	mov    %esi,%eax
f010178c:	3c 19                	cmp    $0x19,%al
f010178e:	77 16                	ja     f01017a6 <strtol+0xc1>
			dig = *s - 'A' + 10;
f0101790:	0f be c9             	movsbl %cl,%ecx
f0101793:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0101796:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f0101799:	7d 0f                	jge    f01017aa <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f010179b:	83 c2 01             	add    $0x1,%edx
f010179e:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f01017a2:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f01017a4:	eb bc                	jmp    f0101762 <strtol+0x7d>
f01017a6:	89 d8                	mov    %ebx,%eax
f01017a8:	eb 02                	jmp    f01017ac <strtol+0xc7>
f01017aa:	89 d8                	mov    %ebx,%eax

	if (endptr)
f01017ac:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01017b0:	74 05                	je     f01017b7 <strtol+0xd2>
		*endptr = (char *) s;
f01017b2:	8b 75 0c             	mov    0xc(%ebp),%esi
f01017b5:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f01017b7:	f7 d8                	neg    %eax
f01017b9:	85 ff                	test   %edi,%edi
f01017bb:	0f 44 c3             	cmove  %ebx,%eax
}
f01017be:	5b                   	pop    %ebx
f01017bf:	5e                   	pop    %esi
f01017c0:	5f                   	pop    %edi
f01017c1:	5d                   	pop    %ebp
f01017c2:	c3                   	ret    
f01017c3:	66 90                	xchg   %ax,%ax
f01017c5:	66 90                	xchg   %ax,%ax
f01017c7:	66 90                	xchg   %ax,%ax
f01017c9:	66 90                	xchg   %ax,%ax
f01017cb:	66 90                	xchg   %ax,%ax
f01017cd:	66 90                	xchg   %ax,%ax
f01017cf:	90                   	nop

f01017d0 <__udivdi3>:
f01017d0:	55                   	push   %ebp
f01017d1:	57                   	push   %edi
f01017d2:	56                   	push   %esi
f01017d3:	83 ec 0c             	sub    $0xc,%esp
f01017d6:	8b 44 24 28          	mov    0x28(%esp),%eax
f01017da:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f01017de:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f01017e2:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f01017e6:	85 c0                	test   %eax,%eax
f01017e8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01017ec:	89 ea                	mov    %ebp,%edx
f01017ee:	89 0c 24             	mov    %ecx,(%esp)
f01017f1:	75 2d                	jne    f0101820 <__udivdi3+0x50>
f01017f3:	39 e9                	cmp    %ebp,%ecx
f01017f5:	77 61                	ja     f0101858 <__udivdi3+0x88>
f01017f7:	85 c9                	test   %ecx,%ecx
f01017f9:	89 ce                	mov    %ecx,%esi
f01017fb:	75 0b                	jne    f0101808 <__udivdi3+0x38>
f01017fd:	b8 01 00 00 00       	mov    $0x1,%eax
f0101802:	31 d2                	xor    %edx,%edx
f0101804:	f7 f1                	div    %ecx
f0101806:	89 c6                	mov    %eax,%esi
f0101808:	31 d2                	xor    %edx,%edx
f010180a:	89 e8                	mov    %ebp,%eax
f010180c:	f7 f6                	div    %esi
f010180e:	89 c5                	mov    %eax,%ebp
f0101810:	89 f8                	mov    %edi,%eax
f0101812:	f7 f6                	div    %esi
f0101814:	89 ea                	mov    %ebp,%edx
f0101816:	83 c4 0c             	add    $0xc,%esp
f0101819:	5e                   	pop    %esi
f010181a:	5f                   	pop    %edi
f010181b:	5d                   	pop    %ebp
f010181c:	c3                   	ret    
f010181d:	8d 76 00             	lea    0x0(%esi),%esi
f0101820:	39 e8                	cmp    %ebp,%eax
f0101822:	77 24                	ja     f0101848 <__udivdi3+0x78>
f0101824:	0f bd e8             	bsr    %eax,%ebp
f0101827:	83 f5 1f             	xor    $0x1f,%ebp
f010182a:	75 3c                	jne    f0101868 <__udivdi3+0x98>
f010182c:	8b 74 24 04          	mov    0x4(%esp),%esi
f0101830:	39 34 24             	cmp    %esi,(%esp)
f0101833:	0f 86 9f 00 00 00    	jbe    f01018d8 <__udivdi3+0x108>
f0101839:	39 d0                	cmp    %edx,%eax
f010183b:	0f 82 97 00 00 00    	jb     f01018d8 <__udivdi3+0x108>
f0101841:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101848:	31 d2                	xor    %edx,%edx
f010184a:	31 c0                	xor    %eax,%eax
f010184c:	83 c4 0c             	add    $0xc,%esp
f010184f:	5e                   	pop    %esi
f0101850:	5f                   	pop    %edi
f0101851:	5d                   	pop    %ebp
f0101852:	c3                   	ret    
f0101853:	90                   	nop
f0101854:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101858:	89 f8                	mov    %edi,%eax
f010185a:	f7 f1                	div    %ecx
f010185c:	31 d2                	xor    %edx,%edx
f010185e:	83 c4 0c             	add    $0xc,%esp
f0101861:	5e                   	pop    %esi
f0101862:	5f                   	pop    %edi
f0101863:	5d                   	pop    %ebp
f0101864:	c3                   	ret    
f0101865:	8d 76 00             	lea    0x0(%esi),%esi
f0101868:	89 e9                	mov    %ebp,%ecx
f010186a:	8b 3c 24             	mov    (%esp),%edi
f010186d:	d3 e0                	shl    %cl,%eax
f010186f:	89 c6                	mov    %eax,%esi
f0101871:	b8 20 00 00 00       	mov    $0x20,%eax
f0101876:	29 e8                	sub    %ebp,%eax
f0101878:	89 c1                	mov    %eax,%ecx
f010187a:	d3 ef                	shr    %cl,%edi
f010187c:	89 e9                	mov    %ebp,%ecx
f010187e:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101882:	8b 3c 24             	mov    (%esp),%edi
f0101885:	09 74 24 08          	or     %esi,0x8(%esp)
f0101889:	89 d6                	mov    %edx,%esi
f010188b:	d3 e7                	shl    %cl,%edi
f010188d:	89 c1                	mov    %eax,%ecx
f010188f:	89 3c 24             	mov    %edi,(%esp)
f0101892:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101896:	d3 ee                	shr    %cl,%esi
f0101898:	89 e9                	mov    %ebp,%ecx
f010189a:	d3 e2                	shl    %cl,%edx
f010189c:	89 c1                	mov    %eax,%ecx
f010189e:	d3 ef                	shr    %cl,%edi
f01018a0:	09 d7                	or     %edx,%edi
f01018a2:	89 f2                	mov    %esi,%edx
f01018a4:	89 f8                	mov    %edi,%eax
f01018a6:	f7 74 24 08          	divl   0x8(%esp)
f01018aa:	89 d6                	mov    %edx,%esi
f01018ac:	89 c7                	mov    %eax,%edi
f01018ae:	f7 24 24             	mull   (%esp)
f01018b1:	39 d6                	cmp    %edx,%esi
f01018b3:	89 14 24             	mov    %edx,(%esp)
f01018b6:	72 30                	jb     f01018e8 <__udivdi3+0x118>
f01018b8:	8b 54 24 04          	mov    0x4(%esp),%edx
f01018bc:	89 e9                	mov    %ebp,%ecx
f01018be:	d3 e2                	shl    %cl,%edx
f01018c0:	39 c2                	cmp    %eax,%edx
f01018c2:	73 05                	jae    f01018c9 <__udivdi3+0xf9>
f01018c4:	3b 34 24             	cmp    (%esp),%esi
f01018c7:	74 1f                	je     f01018e8 <__udivdi3+0x118>
f01018c9:	89 f8                	mov    %edi,%eax
f01018cb:	31 d2                	xor    %edx,%edx
f01018cd:	e9 7a ff ff ff       	jmp    f010184c <__udivdi3+0x7c>
f01018d2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01018d8:	31 d2                	xor    %edx,%edx
f01018da:	b8 01 00 00 00       	mov    $0x1,%eax
f01018df:	e9 68 ff ff ff       	jmp    f010184c <__udivdi3+0x7c>
f01018e4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01018e8:	8d 47 ff             	lea    -0x1(%edi),%eax
f01018eb:	31 d2                	xor    %edx,%edx
f01018ed:	83 c4 0c             	add    $0xc,%esp
f01018f0:	5e                   	pop    %esi
f01018f1:	5f                   	pop    %edi
f01018f2:	5d                   	pop    %ebp
f01018f3:	c3                   	ret    
f01018f4:	66 90                	xchg   %ax,%ax
f01018f6:	66 90                	xchg   %ax,%ax
f01018f8:	66 90                	xchg   %ax,%ax
f01018fa:	66 90                	xchg   %ax,%ax
f01018fc:	66 90                	xchg   %ax,%ax
f01018fe:	66 90                	xchg   %ax,%ax

f0101900 <__umoddi3>:
f0101900:	55                   	push   %ebp
f0101901:	57                   	push   %edi
f0101902:	56                   	push   %esi
f0101903:	83 ec 14             	sub    $0x14,%esp
f0101906:	8b 44 24 28          	mov    0x28(%esp),%eax
f010190a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f010190e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0101912:	89 c7                	mov    %eax,%edi
f0101914:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101918:	8b 44 24 30          	mov    0x30(%esp),%eax
f010191c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0101920:	89 34 24             	mov    %esi,(%esp)
f0101923:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101927:	85 c0                	test   %eax,%eax
f0101929:	89 c2                	mov    %eax,%edx
f010192b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010192f:	75 17                	jne    f0101948 <__umoddi3+0x48>
f0101931:	39 fe                	cmp    %edi,%esi
f0101933:	76 4b                	jbe    f0101980 <__umoddi3+0x80>
f0101935:	89 c8                	mov    %ecx,%eax
f0101937:	89 fa                	mov    %edi,%edx
f0101939:	f7 f6                	div    %esi
f010193b:	89 d0                	mov    %edx,%eax
f010193d:	31 d2                	xor    %edx,%edx
f010193f:	83 c4 14             	add    $0x14,%esp
f0101942:	5e                   	pop    %esi
f0101943:	5f                   	pop    %edi
f0101944:	5d                   	pop    %ebp
f0101945:	c3                   	ret    
f0101946:	66 90                	xchg   %ax,%ax
f0101948:	39 f8                	cmp    %edi,%eax
f010194a:	77 54                	ja     f01019a0 <__umoddi3+0xa0>
f010194c:	0f bd e8             	bsr    %eax,%ebp
f010194f:	83 f5 1f             	xor    $0x1f,%ebp
f0101952:	75 5c                	jne    f01019b0 <__umoddi3+0xb0>
f0101954:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0101958:	39 3c 24             	cmp    %edi,(%esp)
f010195b:	0f 87 e7 00 00 00    	ja     f0101a48 <__umoddi3+0x148>
f0101961:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101965:	29 f1                	sub    %esi,%ecx
f0101967:	19 c7                	sbb    %eax,%edi
f0101969:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010196d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101971:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101975:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0101979:	83 c4 14             	add    $0x14,%esp
f010197c:	5e                   	pop    %esi
f010197d:	5f                   	pop    %edi
f010197e:	5d                   	pop    %ebp
f010197f:	c3                   	ret    
f0101980:	85 f6                	test   %esi,%esi
f0101982:	89 f5                	mov    %esi,%ebp
f0101984:	75 0b                	jne    f0101991 <__umoddi3+0x91>
f0101986:	b8 01 00 00 00       	mov    $0x1,%eax
f010198b:	31 d2                	xor    %edx,%edx
f010198d:	f7 f6                	div    %esi
f010198f:	89 c5                	mov    %eax,%ebp
f0101991:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101995:	31 d2                	xor    %edx,%edx
f0101997:	f7 f5                	div    %ebp
f0101999:	89 c8                	mov    %ecx,%eax
f010199b:	f7 f5                	div    %ebp
f010199d:	eb 9c                	jmp    f010193b <__umoddi3+0x3b>
f010199f:	90                   	nop
f01019a0:	89 c8                	mov    %ecx,%eax
f01019a2:	89 fa                	mov    %edi,%edx
f01019a4:	83 c4 14             	add    $0x14,%esp
f01019a7:	5e                   	pop    %esi
f01019a8:	5f                   	pop    %edi
f01019a9:	5d                   	pop    %ebp
f01019aa:	c3                   	ret    
f01019ab:	90                   	nop
f01019ac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01019b0:	8b 04 24             	mov    (%esp),%eax
f01019b3:	be 20 00 00 00       	mov    $0x20,%esi
f01019b8:	89 e9                	mov    %ebp,%ecx
f01019ba:	29 ee                	sub    %ebp,%esi
f01019bc:	d3 e2                	shl    %cl,%edx
f01019be:	89 f1                	mov    %esi,%ecx
f01019c0:	d3 e8                	shr    %cl,%eax
f01019c2:	89 e9                	mov    %ebp,%ecx
f01019c4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01019c8:	8b 04 24             	mov    (%esp),%eax
f01019cb:	09 54 24 04          	or     %edx,0x4(%esp)
f01019cf:	89 fa                	mov    %edi,%edx
f01019d1:	d3 e0                	shl    %cl,%eax
f01019d3:	89 f1                	mov    %esi,%ecx
f01019d5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01019d9:	8b 44 24 10          	mov    0x10(%esp),%eax
f01019dd:	d3 ea                	shr    %cl,%edx
f01019df:	89 e9                	mov    %ebp,%ecx
f01019e1:	d3 e7                	shl    %cl,%edi
f01019e3:	89 f1                	mov    %esi,%ecx
f01019e5:	d3 e8                	shr    %cl,%eax
f01019e7:	89 e9                	mov    %ebp,%ecx
f01019e9:	09 f8                	or     %edi,%eax
f01019eb:	8b 7c 24 10          	mov    0x10(%esp),%edi
f01019ef:	f7 74 24 04          	divl   0x4(%esp)
f01019f3:	d3 e7                	shl    %cl,%edi
f01019f5:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01019f9:	89 d7                	mov    %edx,%edi
f01019fb:	f7 64 24 08          	mull   0x8(%esp)
f01019ff:	39 d7                	cmp    %edx,%edi
f0101a01:	89 c1                	mov    %eax,%ecx
f0101a03:	89 14 24             	mov    %edx,(%esp)
f0101a06:	72 2c                	jb     f0101a34 <__umoddi3+0x134>
f0101a08:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f0101a0c:	72 22                	jb     f0101a30 <__umoddi3+0x130>
f0101a0e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0101a12:	29 c8                	sub    %ecx,%eax
f0101a14:	19 d7                	sbb    %edx,%edi
f0101a16:	89 e9                	mov    %ebp,%ecx
f0101a18:	89 fa                	mov    %edi,%edx
f0101a1a:	d3 e8                	shr    %cl,%eax
f0101a1c:	89 f1                	mov    %esi,%ecx
f0101a1e:	d3 e2                	shl    %cl,%edx
f0101a20:	89 e9                	mov    %ebp,%ecx
f0101a22:	d3 ef                	shr    %cl,%edi
f0101a24:	09 d0                	or     %edx,%eax
f0101a26:	89 fa                	mov    %edi,%edx
f0101a28:	83 c4 14             	add    $0x14,%esp
f0101a2b:	5e                   	pop    %esi
f0101a2c:	5f                   	pop    %edi
f0101a2d:	5d                   	pop    %ebp
f0101a2e:	c3                   	ret    
f0101a2f:	90                   	nop
f0101a30:	39 d7                	cmp    %edx,%edi
f0101a32:	75 da                	jne    f0101a0e <__umoddi3+0x10e>
f0101a34:	8b 14 24             	mov    (%esp),%edx
f0101a37:	89 c1                	mov    %eax,%ecx
f0101a39:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f0101a3d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0101a41:	eb cb                	jmp    f0101a0e <__umoddi3+0x10e>
f0101a43:	90                   	nop
f0101a44:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101a48:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f0101a4c:	0f 82 0f ff ff ff    	jb     f0101961 <__umoddi3+0x61>
f0101a52:	e9 1a ff ff ff       	jmp    f0101971 <__umoddi3+0x71>
