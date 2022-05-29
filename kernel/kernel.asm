
kernel/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00000117          	auipc	sp,0x0
    80000004:	60010113          	addi	sp,sp,1536 # 80000600 <stack0>
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
  // 每个cpu都有自己的定时器中断源
  int id = r_mhartid();
    80000034:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  // 请求一个定时器中断
  // 间隔是1000000个时钟周期，在qemu中大约0.1秒。
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
    8000006c:	45870713          	addi	a4,a4,1112 # 800004c0 <timer_scratch>
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
  // 设置机器模式陷入处理器
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  // 启用机器模式中断
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000090:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000094:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000098:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  // 启用机器模式定时器中断
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
    800000c8:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <cpus+0xffffffff7fff61ff>
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
    800001d8:	2cc50513          	addi	a0,a0,716 # 800004a0 <mycpu+0x30>
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

0000000080000244 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000244:	ff010113          	addi	sp,sp,-16
    80000248:	00813423          	sd	s0,8(sp)
    8000024c:	01010413          	addi	s0,sp,16
  lk->name = name;
    80000250:	00b53423          	sd	a1,8(a0)
  lk->locked = 0;
    80000254:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000258:	00053823          	sd	zero,16(a0)
}
    8000025c:	00813403          	ld	s0,8(sp)
    80000260:	01010113          	addi	sp,sp,16
    80000264:	00008067          	ret

0000000080000268 <holding>:
// 中断必须处于关闭状态
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000268:	00052783          	lw	a5,0(a0)
    8000026c:	00079663          	bnez	a5,80000278 <holding+0x10>
    80000270:	00000513          	li	a0,0
  return r;
}
    80000274:	00008067          	ret
{
    80000278:	fe010113          	addi	sp,sp,-32
    8000027c:	00113c23          	sd	ra,24(sp)
    80000280:	00813823          	sd	s0,16(sp)
    80000284:	00913423          	sd	s1,8(sp)
    80000288:	02010413          	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    8000028c:	01053483          	ld	s1,16(a0)
    80000290:	00000097          	auipc	ra,0x0
    80000294:	1e0080e7          	jalr	480(ra) # 80000470 <mycpu>
    80000298:	40a48533          	sub	a0,s1,a0
    8000029c:	00153513          	seqz	a0,a0
}
    800002a0:	01813083          	ld	ra,24(sp)
    800002a4:	01013403          	ld	s0,16(sp)
    800002a8:	00813483          	ld	s1,8(sp)
    800002ac:	02010113          	addi	sp,sp,32
    800002b0:	00008067          	ret

00000000800002b4 <push_off>:
// are initially off, then push_off, pop_off leaves them off.
// 关闭中断和打开中断的操作必须配对

void
push_off(void)
{
    800002b4:	fe010113          	addi	sp,sp,-32
    800002b8:	00113c23          	sd	ra,24(sp)
    800002bc:	00813823          	sd	s0,16(sp)
    800002c0:	00913423          	sd	s1,8(sp)
    800002c4:	02010413          	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800002c8:	100024f3          	csrr	s1,sstatus
    800002cc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800002d0:	ffd7f793          	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800002d4:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    800002d8:	00000097          	auipc	ra,0x0
    800002dc:	198080e7          	jalr	408(ra) # 80000470 <mycpu>
    800002e0:	00052783          	lw	a5,0(a0)
    800002e4:	02078663          	beqz	a5,80000310 <push_off+0x5c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    800002e8:	00000097          	auipc	ra,0x0
    800002ec:	188080e7          	jalr	392(ra) # 80000470 <mycpu>
    800002f0:	00052783          	lw	a5,0(a0)
    800002f4:	0017879b          	addiw	a5,a5,1
    800002f8:	00f52023          	sw	a5,0(a0)
}
    800002fc:	01813083          	ld	ra,24(sp)
    80000300:	01013403          	ld	s0,16(sp)
    80000304:	00813483          	ld	s1,8(sp)
    80000308:	02010113          	addi	sp,sp,32
    8000030c:	00008067          	ret
    mycpu()->intena = old;
    80000310:	00000097          	auipc	ra,0x0
    80000314:	160080e7          	jalr	352(ra) # 80000470 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000318:	0014d493          	srli	s1,s1,0x1
    8000031c:	0014f493          	andi	s1,s1,1
    80000320:	00952223          	sw	s1,4(a0)
    80000324:	fc5ff06f          	j	800002e8 <push_off+0x34>

0000000080000328 <acquire>:
{
    80000328:	fe010113          	addi	sp,sp,-32
    8000032c:	00113c23          	sd	ra,24(sp)
    80000330:	00813823          	sd	s0,16(sp)
    80000334:	00913423          	sd	s1,8(sp)
    80000338:	02010413          	addi	s0,sp,32
    8000033c:	00050493          	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f74080e7          	jalr	-140(ra) # 800002b4 <push_off>
  if(holding(lk))
    80000348:	00048513          	mv	a0,s1
    8000034c:	00000097          	auipc	ra,0x0
    80000350:	f1c080e7          	jalr	-228(ra) # 80000268 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000354:	00100713          	li	a4,1
  if(holding(lk))
    80000358:	00050463          	beqz	a0,80000360 <acquire+0x38>
    for(;;);
    8000035c:	0000006f          	j	8000035c <acquire+0x34>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000360:	00070793          	mv	a5,a4
    80000364:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000368:	0007879b          	sext.w	a5,a5
    8000036c:	fe079ae3          	bnez	a5,80000360 <acquire+0x38>
  __sync_synchronize();
    80000370:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000374:	00000097          	auipc	ra,0x0
    80000378:	0fc080e7          	jalr	252(ra) # 80000470 <mycpu>
    8000037c:	00a4b823          	sd	a0,16(s1)
}
    80000380:	01813083          	ld	ra,24(sp)
    80000384:	01013403          	ld	s0,16(sp)
    80000388:	00813483          	ld	s1,8(sp)
    8000038c:	02010113          	addi	sp,sp,32
    80000390:	00008067          	ret

0000000080000394 <pop_off>:

void
pop_off(void)
{
    80000394:	ff010113          	addi	sp,sp,-16
    80000398:	00113423          	sd	ra,8(sp)
    8000039c:	00813023          	sd	s0,0(sp)
    800003a0:	01010413          	addi	s0,sp,16
  struct cpu *c = mycpu();
    800003a4:	00000097          	auipc	ra,0x0
    800003a8:	0cc080e7          	jalr	204(ra) # 80000470 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800003ac:	10002773          	csrr	a4,sstatus
  return (x & SSTATUS_SIE) != 0;
    800003b0:	00277713          	andi	a4,a4,2
  if(intr_get())
    800003b4:	00070463          	beqz	a4,800003bc <pop_off+0x28>
    for(;;);
    800003b8:	0000006f          	j	800003b8 <pop_off+0x24>
  if(c->noff < 1)
    800003bc:	00052703          	lw	a4,0(a0)
    800003c0:	02e05c63          	blez	a4,800003f8 <pop_off+0x64>
    for(;;);
  c->noff -= 1;
    800003c4:	fff7071b          	addiw	a4,a4,-1
    800003c8:	0007069b          	sext.w	a3,a4
    800003cc:	00e52023          	sw	a4,0(a0)
  if(c->noff == 0 && c->intena)
    800003d0:	00069c63          	bnez	a3,800003e8 <pop_off+0x54>
    800003d4:	00452783          	lw	a5,4(a0)
    800003d8:	00078863          	beqz	a5,800003e8 <pop_off+0x54>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800003dc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800003e0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800003e4:	10079073          	csrw	sstatus,a5
    intr_on();
}
    800003e8:	00813083          	ld	ra,8(sp)
    800003ec:	00013403          	ld	s0,0(sp)
    800003f0:	01010113          	addi	sp,sp,16
    800003f4:	00008067          	ret
    for(;;);
    800003f8:	0000006f          	j	800003f8 <pop_off+0x64>

00000000800003fc <release>:
{
    800003fc:	fe010113          	addi	sp,sp,-32
    80000400:	00113c23          	sd	ra,24(sp)
    80000404:	00813823          	sd	s0,16(sp)
    80000408:	00913423          	sd	s1,8(sp)
    8000040c:	02010413          	addi	s0,sp,32
    80000410:	00050493          	mv	s1,a0
  if(!holding(lk))
    80000414:	00000097          	auipc	ra,0x0
    80000418:	e54080e7          	jalr	-428(ra) # 80000268 <holding>
    8000041c:	00051463          	bnez	a0,80000424 <release+0x28>
    for(;;);
    80000420:	0000006f          	j	80000420 <release+0x24>
  lk->cpu = 0;
    80000424:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000428:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    8000042c:	0f50000f          	fence	iorw,ow
    80000430:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000434:	00000097          	auipc	ra,0x0
    80000438:	f60080e7          	jalr	-160(ra) # 80000394 <pop_off>
}
    8000043c:	01813083          	ld	ra,24(sp)
    80000440:	01013403          	ld	s0,16(sp)
    80000444:	00813483          	ld	s1,8(sp)
    80000448:	02010113          	addi	sp,sp,32
    8000044c:	00008067          	ret

0000000080000450 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80000450:	ff010113          	addi	sp,sp,-16
    80000454:	00813423          	sd	s0,8(sp)
    80000458:	01010413          	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    8000045c:	00020513          	mv	a0,tp
  int id = r_tp();
  return id;
}
    80000460:	0005051b          	sext.w	a0,a0
    80000464:	00813403          	ld	s0,8(sp)
    80000468:	01010113          	addi	sp,sp,16
    8000046c:	00008067          	ret

0000000080000470 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80000470:	ff010113          	addi	sp,sp,-16
    80000474:	00813423          	sd	s0,8(sp)
    80000478:	01010413          	addi	s0,sp,16
    8000047c:	00020793          	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80000480:	0007879b          	sext.w	a5,a5
    80000484:	00379793          	slli	a5,a5,0x3
  return c;
    80000488:	00008517          	auipc	a0,0x8
    8000048c:	17850513          	addi	a0,a0,376 # 80008600 <cpus>
    80000490:	00f50533          	add	a0,a0,a5
    80000494:	00813403          	ld	s0,8(sp)
    80000498:	01010113          	addi	sp,sp,16
    8000049c:	00008067          	ret
