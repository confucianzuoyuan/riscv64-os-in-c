
kernel/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00000117          	auipc	sp,0x0
    80000004:	3a010113          	addi	sp,sp,928 # 800003a0 <stack0>
    80000008:	00001537          	lui	a0,0x1
    8000000c:	f14025f3          	csrr	a1,mhartid
    80000010:	00158593          	addi	a1,a1,1
    80000014:	02b50533          	mul	a0,a0,a1
    80000018:	00a10133          	add	sp,sp,a0
    8000001c:	094000ef          	jal	ra,800000b0 <start>

0000000080000020 <spin>:
    80000020:	0000006f          	j	80000020 <spin>

0000000080000024 <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    80000024:	ff010113          	addi	sp,sp,-16
    80000028:	00813423          	sd	s0,8(sp)
    8000002c:	01010413          	addi	s0,sp,16
// `=r`中`r`表示任意通用寄存器，`=`表示将`r`中的内容输出到变量`x`
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000030:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000034:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    80000038:	0037979b          	slliw	a5,a5,0x3
    8000003c:	02004737          	lui	a4,0x2004
    80000040:	00e787b3          	add	a5,a5,a4
    80000044:	0200c737          	lui	a4,0x200c
    80000048:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000004c:	000f4637          	lui	a2,0xf4
    80000050:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000054:	00c585b3          	add	a1,a1,a2
    80000058:	00b7b023          	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    8000005c:	00269713          	slli	a4,a3,0x2
    80000060:	00d70733          	add	a4,a4,a3
    80000064:	00371693          	slli	a3,a4,0x3
    80000068:	00000717          	auipc	a4,0x0
    8000006c:	1f870713          	addi	a4,a4,504 # 80000260 <timer_scratch>
    80000070:	00d70733          	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    80000074:	00f73c23          	sd	a5,24(a4)
  scratch[4] = interval;
    80000078:	02c73023          	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000007c:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000080:	00000797          	auipc	a5,0x0
    80000084:	18078793          	addi	a5,a5,384 # 80000200 <timervec>
    80000088:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000008c:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000090:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000094:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000098:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000009c:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    800000a0:	30479073          	csrw	mie,a5
    800000a4:	00813403          	ld	s0,8(sp)
    800000a8:	01010113          	addi	sp,sp,16
    800000ac:	00008067          	ret

00000000800000b0 <start>:
{
    800000b0:	ff010113          	addi	sp,sp,-16
    800000b4:	00113423          	sd	ra,8(sp)
    800000b8:	00813023          	sd	s0,0(sp)
    800000bc:	01010413          	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    800000c0:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    800000c4:	ffffe737          	lui	a4,0xffffe
    800000c8:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <stack0+0xffffffff7fffe45f>
    800000cc:	00e7f7b3          	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000d0:	00001737          	lui	a4,0x1
    800000d4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000d8:	00e7e7b3          	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000dc:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000e0:	00000797          	auipc	a5,0x0
    800000e4:	0e478793          	addi	a5,a5,228 # 800001c4 <main>
    800000e8:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ec:	00000793          	li	a5,0
    800000f0:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000f4:	000107b7          	lui	a5,0x10
    800000f8:	fff78793          	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000fc:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    80000100:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    80000104:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    80000108:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    8000010c:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    80000110:	fff00793          	li	a5,-1
    80000114:	00a7d793          	srli	a5,a5,0xa
    80000118:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    8000011c:	00f00793          	li	a5,15
    80000120:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    80000124:	00000097          	auipc	ra,0x0
    80000128:	f00080e7          	jalr	-256(ra) # 80000024 <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    8000012c:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    80000130:	0007879b          	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    80000134:	00078213          	mv	tp,a5
  asm volatile("mret");
    80000138:	30200073          	mret
}
    8000013c:	00813083          	ld	ra,8(sp)
    80000140:	00013403          	ld	s0,0(sp)
    80000144:	01010113          	addi	sp,sp,16
    80000148:	00008067          	ret

000000008000014c <lib_putc>:
#define UART        0x10000000
#define UART_THR    (uint8_t*)(UART+0x00) // THR:transmitter holding register
#define UART_LSR    (uint8_t*)(UART+0x05) // LSR:line status register
#define UART_LSR_EMPTY_MASK 0x40          // LSR Bit 6: Transmitter empty; both the THR and LSR are empty

int lib_putc(char ch) {
    8000014c:	ff010113          	addi	sp,sp,-16
    80000150:	00813423          	sd	s0,8(sp)
    80000154:	01010413          	addi	s0,sp,16
  while ((*UART_LSR & UART_LSR_EMPTY_MASK) == 0);
    80000158:	100007b7          	lui	a5,0x10000
    8000015c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000160:	0407f793          	andi	a5,a5,64
    80000164:	00078063          	beqz	a5,80000164 <lib_putc+0x18>
  return *UART_THR = ch;
    80000168:	100007b7          	lui	a5,0x10000
    8000016c:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>
}
    80000170:	00813403          	ld	s0,8(sp)
    80000174:	01010113          	addi	sp,sp,16
    80000178:	00008067          	ret

000000008000017c <lib_puts>:

void lib_puts(char *s) {
    8000017c:	fe010113          	addi	sp,sp,-32
    80000180:	00113c23          	sd	ra,24(sp)
    80000184:	00813823          	sd	s0,16(sp)
    80000188:	00913423          	sd	s1,8(sp)
    8000018c:	02010413          	addi	s0,sp,32
    80000190:	00050493          	mv	s1,a0
  while (*s) lib_putc(*s++);
    80000194:	00054503          	lbu	a0,0(a0) # 1000 <_entry-0x7ffff000>
    80000198:	00050c63          	beqz	a0,800001b0 <lib_puts+0x34>
    8000019c:	00148493          	addi	s1,s1,1
    800001a0:	00000097          	auipc	ra,0x0
    800001a4:	fac080e7          	jalr	-84(ra) # 8000014c <lib_putc>
    800001a8:	0004c503          	lbu	a0,0(s1)
    800001ac:	fe0518e3          	bnez	a0,8000019c <lib_puts+0x20>
}
    800001b0:	01813083          	ld	ra,24(sp)
    800001b4:	01013403          	ld	s0,16(sp)
    800001b8:	00813483          	ld	s1,8(sp)
    800001bc:	02010113          	addi	sp,sp,32
    800001c0:	00008067          	ret

00000000800001c4 <main>:

void
main()
{
    800001c4:	ff010113          	addi	sp,sp,-16
    800001c8:	00113423          	sd	ra,8(sp)
    800001cc:	00813023          	sd	s0,0(sp)
    800001d0:	01010413          	addi	s0,sp,16
  lib_puts("你好，世界！");
    800001d4:	00000517          	auipc	a0,0x0
    800001d8:	07450513          	addi	a0,a0,116 # 80000248 <timervec+0x48>
    800001dc:	00000097          	auipc	ra,0x0
    800001e0:	fa0080e7          	jalr	-96(ra) # 8000017c <lib_puts>
    800001e4:	00813083          	ld	ra,8(sp)
    800001e8:	00013403          	ld	s0,0(sp)
    800001ec:	01010113          	addi	sp,sp,16
    800001f0:	00008067          	ret
	...

0000000080000200 <timervec>:
    80000200:	34051573          	csrrw	a0,mscratch,a0
    80000204:	00b53023          	sd	a1,0(a0)
    80000208:	00c53423          	sd	a2,8(a0)
    8000020c:	00d53823          	sd	a3,16(a0)
    80000210:	01853583          	ld	a1,24(a0)
    80000214:	02053603          	ld	a2,32(a0)
    80000218:	0005b683          	ld	a3,0(a1)
    8000021c:	00c686b3          	add	a3,a3,a2
    80000220:	00d5b023          	sd	a3,0(a1)
    80000224:	00200593          	li	a1,2
    80000228:	14459073          	csrw	sip,a1
    8000022c:	01053683          	ld	a3,16(a0)
    80000230:	00853603          	ld	a2,8(a0)
    80000234:	00053583          	ld	a1,0(a0)
    80000238:	34051573          	csrrw	a0,mscratch,a0
    8000023c:	30200073          	mret
    80000240:	0000                	unimp
	...
