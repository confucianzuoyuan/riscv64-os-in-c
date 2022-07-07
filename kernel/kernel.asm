
kernel/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00001117          	auipc	sp,0x1
    80000004:	bd010113          	addi	sp,sp,-1072 # 80000bd0 <stack0>
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
    80000068:	00001717          	auipc	a4,0x1
    8000006c:	a2870713          	addi	a4,a4,-1496 # 80000a90 <timer_scratch>
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
    80000084:	15078793          	addi	a5,a5,336 # 800001d0 <timervec>
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
    800000c8:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <uart_tx_w+0xffffffff7fff5adf>
    800000cc:	00e7f7b3          	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000d0:	00001737          	lui	a4,0x1
    800000d4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000d8:	00e7e7b3          	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000dc:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000e0:	00000797          	auipc	a5,0x0
    800000e4:	06c78793          	addi	a5,a5,108 # 8000014c <main>
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

000000008000014c <main>:
#include "riscv.h"
#include "defs.h"

void
main()
{
    8000014c:	ff010113          	addi	sp,sp,-16
    80000150:	00113423          	sd	ra,8(sp)
    80000154:	00813023          	sd	s0,0(sp)
    80000158:	01010413          	addi	s0,sp,16
  if (cpuid() == 0) {
    8000015c:	00000097          	auipc	ra,0x0
    80000160:	2c4080e7          	jalr	708(ra) # 80000420 <cpuid>
    80000164:	00050a63          	beqz	a0,80000178 <main+0x2c>
    printf("\n");
    printf("xv6 kernel is booting\n");
    printf("你好，世界！\n");
    printf("\n");
  }
    80000168:	00813083          	ld	ra,8(sp)
    8000016c:	00013403          	ld	s0,0(sp)
    80000170:	01010113          	addi	sp,sp,16
    80000174:	00008067          	ret
    consoleinit();
    80000178:	00000097          	auipc	ra,0x0
    8000017c:	744080e7          	jalr	1860(ra) # 800008bc <consoleinit>
    printfinit();
    80000180:	00000097          	auipc	ra,0x0
    80000184:	698080e7          	jalr	1688(ra) # 80000818 <printfinit>
    printf("\n");
    80000188:	00001517          	auipc	a0,0x1
    8000018c:	88050513          	addi	a0,a0,-1920 # 80000a08 <uartgetc+0x3c>
    80000190:	00000097          	auipc	ra,0x0
    80000194:	41c080e7          	jalr	1052(ra) # 800005ac <printf>
    printf("xv6 kernel is booting\n");
    80000198:	00001517          	auipc	a0,0x1
    8000019c:	87850513          	addi	a0,a0,-1928 # 80000a10 <uartgetc+0x44>
    800001a0:	00000097          	auipc	ra,0x0
    800001a4:	40c080e7          	jalr	1036(ra) # 800005ac <printf>
    printf("你好，世界！\n");
    800001a8:	00001517          	auipc	a0,0x1
    800001ac:	88050513          	addi	a0,a0,-1920 # 80000a28 <uartgetc+0x5c>
    800001b0:	00000097          	auipc	ra,0x0
    800001b4:	3fc080e7          	jalr	1020(ra) # 800005ac <printf>
    printf("\n");
    800001b8:	00001517          	auipc	a0,0x1
    800001bc:	85050513          	addi	a0,a0,-1968 # 80000a08 <uartgetc+0x3c>
    800001c0:	00000097          	auipc	ra,0x0
    800001c4:	3ec080e7          	jalr	1004(ra) # 800005ac <printf>
    800001c8:	fa1ff06f          	j	80000168 <main+0x1c>
    800001cc:	0000                	unimp
	...

00000000800001d0 <timervec>:
    800001d0:	34051573          	csrrw	a0,mscratch,a0
    800001d4:	00b53023          	sd	a1,0(a0)
    800001d8:	00c53423          	sd	a2,8(a0)
    800001dc:	00d53823          	sd	a3,16(a0)
    800001e0:	01853583          	ld	a1,24(a0)
    800001e4:	02053603          	ld	a2,32(a0)
    800001e8:	0005b683          	ld	a3,0(a1)
    800001ec:	00c686b3          	add	a3,a3,a2
    800001f0:	00d5b023          	sd	a3,0(a1)
    800001f4:	00200593          	li	a1,2
    800001f8:	14459073          	csrw	sip,a1
    800001fc:	01053683          	ld	a3,16(a0)
    80000200:	00853603          	ld	a2,8(a0)
    80000204:	00053583          	ld	a1,0(a0)
    80000208:	34051573          	csrrw	a0,mscratch,a0
    8000020c:	30200073          	mret
    80000210:	0000                	unimp
	...

0000000080000214 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000214:	ff010113          	addi	sp,sp,-16
    80000218:	00813423          	sd	s0,8(sp)
    8000021c:	01010413          	addi	s0,sp,16
  lk->name = name;
    80000220:	00b53423          	sd	a1,8(a0)
  lk->locked = 0;
    80000224:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000228:	00053823          	sd	zero,16(a0)
}
    8000022c:	00813403          	ld	s0,8(sp)
    80000230:	01010113          	addi	sp,sp,16
    80000234:	00008067          	ret

0000000080000238 <holding>:
// 中断必须处于关闭状态
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000238:	00052783          	lw	a5,0(a0)
    8000023c:	00079663          	bnez	a5,80000248 <holding+0x10>
    80000240:	00000513          	li	a0,0
  return r;
}
    80000244:	00008067          	ret
{
    80000248:	fe010113          	addi	sp,sp,-32
    8000024c:	00113c23          	sd	ra,24(sp)
    80000250:	00813823          	sd	s0,16(sp)
    80000254:	00913423          	sd	s1,8(sp)
    80000258:	02010413          	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    8000025c:	01053483          	ld	s1,16(a0)
    80000260:	00000097          	auipc	ra,0x0
    80000264:	1e0080e7          	jalr	480(ra) # 80000440 <mycpu>
    80000268:	40a48533          	sub	a0,s1,a0
    8000026c:	00153513          	seqz	a0,a0
}
    80000270:	01813083          	ld	ra,24(sp)
    80000274:	01013403          	ld	s0,16(sp)
    80000278:	00813483          	ld	s1,8(sp)
    8000027c:	02010113          	addi	sp,sp,32
    80000280:	00008067          	ret

0000000080000284 <push_off>:
// are initially off, then push_off, pop_off leaves them off.
// 关闭中断和打开中断的操作必须配对

void
push_off(void)
{
    80000284:	fe010113          	addi	sp,sp,-32
    80000288:	00113c23          	sd	ra,24(sp)
    8000028c:	00813823          	sd	s0,16(sp)
    80000290:	00913423          	sd	s1,8(sp)
    80000294:	02010413          	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000298:	100024f3          	csrr	s1,sstatus
    8000029c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800002a0:	ffd7f793          	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800002a4:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    800002a8:	00000097          	auipc	ra,0x0
    800002ac:	198080e7          	jalr	408(ra) # 80000440 <mycpu>
    800002b0:	00052783          	lw	a5,0(a0)
    800002b4:	02078663          	beqz	a5,800002e0 <push_off+0x5c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    800002b8:	00000097          	auipc	ra,0x0
    800002bc:	188080e7          	jalr	392(ra) # 80000440 <mycpu>
    800002c0:	00052783          	lw	a5,0(a0)
    800002c4:	0017879b          	addiw	a5,a5,1
    800002c8:	00f52023          	sw	a5,0(a0)
}
    800002cc:	01813083          	ld	ra,24(sp)
    800002d0:	01013403          	ld	s0,16(sp)
    800002d4:	00813483          	ld	s1,8(sp)
    800002d8:	02010113          	addi	sp,sp,32
    800002dc:	00008067          	ret
    mycpu()->intena = old;
    800002e0:	00000097          	auipc	ra,0x0
    800002e4:	160080e7          	jalr	352(ra) # 80000440 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    800002e8:	0014d493          	srli	s1,s1,0x1
    800002ec:	0014f493          	andi	s1,s1,1
    800002f0:	00952223          	sw	s1,4(a0)
    800002f4:	fc5ff06f          	j	800002b8 <push_off+0x34>

00000000800002f8 <acquire>:
{
    800002f8:	fe010113          	addi	sp,sp,-32
    800002fc:	00113c23          	sd	ra,24(sp)
    80000300:	00813823          	sd	s0,16(sp)
    80000304:	00913423          	sd	s1,8(sp)
    80000308:	02010413          	addi	s0,sp,32
    8000030c:	00050493          	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000310:	00000097          	auipc	ra,0x0
    80000314:	f74080e7          	jalr	-140(ra) # 80000284 <push_off>
  if(holding(lk))
    80000318:	00048513          	mv	a0,s1
    8000031c:	00000097          	auipc	ra,0x0
    80000320:	f1c080e7          	jalr	-228(ra) # 80000238 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000324:	00100713          	li	a4,1
  if(holding(lk))
    80000328:	00050463          	beqz	a0,80000330 <acquire+0x38>
    for(;;);
    8000032c:	0000006f          	j	8000032c <acquire+0x34>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000330:	00070793          	mv	a5,a4
    80000334:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000338:	0007879b          	sext.w	a5,a5
    8000033c:	fe079ae3          	bnez	a5,80000330 <acquire+0x38>
  __sync_synchronize();
    80000340:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000344:	00000097          	auipc	ra,0x0
    80000348:	0fc080e7          	jalr	252(ra) # 80000440 <mycpu>
    8000034c:	00a4b823          	sd	a0,16(s1)
}
    80000350:	01813083          	ld	ra,24(sp)
    80000354:	01013403          	ld	s0,16(sp)
    80000358:	00813483          	ld	s1,8(sp)
    8000035c:	02010113          	addi	sp,sp,32
    80000360:	00008067          	ret

0000000080000364 <pop_off>:

void
pop_off(void)
{
    80000364:	ff010113          	addi	sp,sp,-16
    80000368:	00113423          	sd	ra,8(sp)
    8000036c:	00813023          	sd	s0,0(sp)
    80000370:	01010413          	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000374:	00000097          	auipc	ra,0x0
    80000378:	0cc080e7          	jalr	204(ra) # 80000440 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000037c:	10002773          	csrr	a4,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000380:	00277713          	andi	a4,a4,2
  if(intr_get())
    80000384:	00070463          	beqz	a4,8000038c <pop_off+0x28>
    for(;;);
    80000388:	0000006f          	j	80000388 <pop_off+0x24>
  if(c->noff < 1)
    8000038c:	00052703          	lw	a4,0(a0)
    80000390:	02e05c63          	blez	a4,800003c8 <pop_off+0x64>
    for(;;);
  c->noff -= 1;
    80000394:	fff7071b          	addiw	a4,a4,-1
    80000398:	0007069b          	sext.w	a3,a4
    8000039c:	00e52023          	sw	a4,0(a0)
  if(c->noff == 0 && c->intena)
    800003a0:	00069c63          	bnez	a3,800003b8 <pop_off+0x54>
    800003a4:	00452783          	lw	a5,4(a0)
    800003a8:	00078863          	beqz	a5,800003b8 <pop_off+0x54>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800003ac:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800003b0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800003b4:	10079073          	csrw	sstatus,a5
    intr_on();
}
    800003b8:	00813083          	ld	ra,8(sp)
    800003bc:	00013403          	ld	s0,0(sp)
    800003c0:	01010113          	addi	sp,sp,16
    800003c4:	00008067          	ret
    for(;;);
    800003c8:	0000006f          	j	800003c8 <pop_off+0x64>

00000000800003cc <release>:
{
    800003cc:	fe010113          	addi	sp,sp,-32
    800003d0:	00113c23          	sd	ra,24(sp)
    800003d4:	00813823          	sd	s0,16(sp)
    800003d8:	00913423          	sd	s1,8(sp)
    800003dc:	02010413          	addi	s0,sp,32
    800003e0:	00050493          	mv	s1,a0
  if(!holding(lk))
    800003e4:	00000097          	auipc	ra,0x0
    800003e8:	e54080e7          	jalr	-428(ra) # 80000238 <holding>
    800003ec:	00051463          	bnez	a0,800003f4 <release+0x28>
    for(;;);
    800003f0:	0000006f          	j	800003f0 <release+0x24>
  lk->cpu = 0;
    800003f4:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    800003f8:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    800003fc:	0f50000f          	fence	iorw,ow
    80000400:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000404:	00000097          	auipc	ra,0x0
    80000408:	f60080e7          	jalr	-160(ra) # 80000364 <pop_off>
}
    8000040c:	01813083          	ld	ra,24(sp)
    80000410:	01013403          	ld	s0,16(sp)
    80000414:	00813483          	ld	s1,8(sp)
    80000418:	02010113          	addi	sp,sp,32
    8000041c:	00008067          	ret

0000000080000420 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80000420:	ff010113          	addi	sp,sp,-16
    80000424:	00813423          	sd	s0,8(sp)
    80000428:	01010413          	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    8000042c:	00020513          	mv	a0,tp
  int id = r_tp();
  return id;
}
    80000430:	0005051b          	sext.w	a0,a0
    80000434:	00813403          	ld	s0,8(sp)
    80000438:	01010113          	addi	sp,sp,16
    8000043c:	00008067          	ret

0000000080000440 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80000440:	ff010113          	addi	sp,sp,-16
    80000444:	00813423          	sd	s0,8(sp)
    80000448:	01010413          	addi	s0,sp,16
    8000044c:	00020793          	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80000450:	0007879b          	sext.w	a5,a5
    80000454:	00379793          	slli	a5,a5,0x3
  return c;
    80000458:	00008517          	auipc	a0,0x8
    8000045c:	77850513          	addi	a0,a0,1912 # 80008bd0 <cpus>
    80000460:	00f50533          	add	a0,a0,a5
    80000464:	00813403          	ld	s0,8(sp)
    80000468:	01010113          	addi	sp,sp,16
    8000046c:	00008067          	ret

0000000080000470 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000470:	fd010113          	addi	sp,sp,-48
    80000474:	02113423          	sd	ra,40(sp)
    80000478:	02813023          	sd	s0,32(sp)
    8000047c:	00913c23          	sd	s1,24(sp)
    80000480:	01213823          	sd	s2,16(sp)
    80000484:	03010413          	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    80000488:	00060463          	beqz	a2,80000490 <printint+0x20>
    8000048c:	0a054c63          	bltz	a0,80000544 <printint+0xd4>
    x = -xx;
  else
    x = xx;
    80000490:	0005051b          	sext.w	a0,a0
    80000494:	00000893          	li	a7,0
    80000498:	fd040693          	addi	a3,s0,-48

  i = 0;
    8000049c:	00000713          	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004a0:	0005859b          	sext.w	a1,a1
    800004a4:	00000617          	auipc	a2,0x0
    800004a8:	5d460613          	addi	a2,a2,1492 # 80000a78 <digits>
    800004ac:	00070813          	mv	a6,a4
    800004b0:	0017071b          	addiw	a4,a4,1
    800004b4:	02b577bb          	remuw	a5,a0,a1
    800004b8:	02079793          	slli	a5,a5,0x20
    800004bc:	0207d793          	srli	a5,a5,0x20
    800004c0:	00f607b3          	add	a5,a2,a5
    800004c4:	0007c783          	lbu	a5,0(a5)
    800004c8:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004cc:	0005079b          	sext.w	a5,a0
    800004d0:	02b5553b          	divuw	a0,a0,a1
    800004d4:	00168693          	addi	a3,a3,1
    800004d8:	fcb7fae3          	bgeu	a5,a1,800004ac <printint+0x3c>

  if(sign)
    800004dc:	00088c63          	beqz	a7,800004f4 <printint+0x84>
    buf[i++] = '-';
    800004e0:	fe040793          	addi	a5,s0,-32
    800004e4:	00e78733          	add	a4,a5,a4
    800004e8:	02d00793          	li	a5,45
    800004ec:	fef70823          	sb	a5,-16(a4)
    800004f0:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004f4:	02e05c63          	blez	a4,8000052c <printint+0xbc>
    800004f8:	fd040793          	addi	a5,s0,-48
    800004fc:	00e784b3          	add	s1,a5,a4
    80000500:	fff78913          	addi	s2,a5,-1
    80000504:	00e90933          	add	s2,s2,a4
    80000508:	fff7071b          	addiw	a4,a4,-1
    8000050c:	02071713          	slli	a4,a4,0x20
    80000510:	02075713          	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	348080e7          	jalr	840(ra) # 80000864 <consputc>
  while(--i >= 0)
    80000524:	fff48493          	addi	s1,s1,-1
    80000528:	ff2498e3          	bne	s1,s2,80000518 <printint+0xa8>
}
    8000052c:	02813083          	ld	ra,40(sp)
    80000530:	02013403          	ld	s0,32(sp)
    80000534:	01813483          	ld	s1,24(sp)
    80000538:	01013903          	ld	s2,16(sp)
    8000053c:	03010113          	addi	sp,sp,48
    80000540:	00008067          	ret
    x = -xx;
    80000544:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000548:	00100893          	li	a7,1
    x = -xx;
    8000054c:	f4dff06f          	j	80000498 <printint+0x28>

0000000080000550 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000550:	fe010113          	addi	sp,sp,-32
    80000554:	00113c23          	sd	ra,24(sp)
    80000558:	00813823          	sd	s0,16(sp)
    8000055c:	00913423          	sd	s1,8(sp)
    80000560:	02010413          	addi	s0,sp,32
    80000564:	00050493          	mv	s1,a0
  pr.locking = 0;
    80000568:	00008797          	auipc	a5,0x8
    8000056c:	6c07a023          	sw	zero,1728(a5) # 80008c28 <pr+0x18>
  printf("panic: ");
    80000570:	00000517          	auipc	a0,0x0
    80000574:	4d050513          	addi	a0,a0,1232 # 80000a40 <uartgetc+0x74>
    80000578:	00000097          	auipc	ra,0x0
    8000057c:	034080e7          	jalr	52(ra) # 800005ac <printf>
  printf(s);
    80000580:	00048513          	mv	a0,s1
    80000584:	00000097          	auipc	ra,0x0
    80000588:	028080e7          	jalr	40(ra) # 800005ac <printf>
  printf("\n");
    8000058c:	00000517          	auipc	a0,0x0
    80000590:	47c50513          	addi	a0,a0,1148 # 80000a08 <uartgetc+0x3c>
    80000594:	00000097          	auipc	ra,0x0
    80000598:	018080e7          	jalr	24(ra) # 800005ac <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000059c:	00100793          	li	a5,1
    800005a0:	00008717          	auipc	a4,0x8
    800005a4:	76f72823          	sw	a5,1904(a4) # 80008d10 <panicked>
  for(;;)
    800005a8:	0000006f          	j	800005a8 <panic+0x58>

00000000800005ac <printf>:
{
    800005ac:	f4010113          	addi	sp,sp,-192
    800005b0:	06113c23          	sd	ra,120(sp)
    800005b4:	06813823          	sd	s0,112(sp)
    800005b8:	06913423          	sd	s1,104(sp)
    800005bc:	07213023          	sd	s2,96(sp)
    800005c0:	05313c23          	sd	s3,88(sp)
    800005c4:	05413823          	sd	s4,80(sp)
    800005c8:	05513423          	sd	s5,72(sp)
    800005cc:	05613023          	sd	s6,64(sp)
    800005d0:	03713c23          	sd	s7,56(sp)
    800005d4:	03813823          	sd	s8,48(sp)
    800005d8:	03913423          	sd	s9,40(sp)
    800005dc:	03a13023          	sd	s10,32(sp)
    800005e0:	01b13c23          	sd	s11,24(sp)
    800005e4:	08010413          	addi	s0,sp,128
    800005e8:	00050a13          	mv	s4,a0
    800005ec:	00b43423          	sd	a1,8(s0)
    800005f0:	00c43823          	sd	a2,16(s0)
    800005f4:	00d43c23          	sd	a3,24(s0)
    800005f8:	02e43023          	sd	a4,32(s0)
    800005fc:	02f43423          	sd	a5,40(s0)
    80000600:	03043823          	sd	a6,48(s0)
    80000604:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    80000608:	00008d97          	auipc	s11,0x8
    8000060c:	620dad83          	lw	s11,1568(s11) # 80008c28 <pr+0x18>
  if(locking)
    80000610:	020d9e63          	bnez	s11,8000064c <printf+0xa0>
  if (fmt == 0)
    80000614:	040a0663          	beqz	s4,80000660 <printf+0xb4>
  va_start(ap, fmt);
    80000618:	00840793          	addi	a5,s0,8
    8000061c:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000620:	000a4503          	lbu	a0,0(s4)
    80000624:	1a050063          	beqz	a0,800007c4 <printf+0x218>
    80000628:	00000493          	li	s1,0
    if(c != '%'){
    8000062c:	02500a93          	li	s5,37
    switch(c){
    80000630:	07000b13          	li	s6,112
  consputc('x');
    80000634:	01000d13          	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000638:	00000b97          	auipc	s7,0x0
    8000063c:	440b8b93          	addi	s7,s7,1088 # 80000a78 <digits>
    switch(c){
    80000640:	07300c93          	li	s9,115
    80000644:	06400c13          	li	s8,100
    80000648:	0400006f          	j	80000688 <printf+0xdc>
    acquire(&pr.lock);
    8000064c:	00008517          	auipc	a0,0x8
    80000650:	5c450513          	addi	a0,a0,1476 # 80008c10 <pr>
    80000654:	00000097          	auipc	ra,0x0
    80000658:	ca4080e7          	jalr	-860(ra) # 800002f8 <acquire>
    8000065c:	fb9ff06f          	j	80000614 <printf+0x68>
    panic("null fmt");
    80000660:	00000517          	auipc	a0,0x0
    80000664:	3f050513          	addi	a0,a0,1008 # 80000a50 <uartgetc+0x84>
    80000668:	00000097          	auipc	ra,0x0
    8000066c:	ee8080e7          	jalr	-280(ra) # 80000550 <panic>
      consputc(c);
    80000670:	00000097          	auipc	ra,0x0
    80000674:	1f4080e7          	jalr	500(ra) # 80000864 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000678:	0014849b          	addiw	s1,s1,1
    8000067c:	009a07b3          	add	a5,s4,s1
    80000680:	0007c503          	lbu	a0,0(a5)
    80000684:	14050063          	beqz	a0,800007c4 <printf+0x218>
    if(c != '%'){
    80000688:	ff5514e3          	bne	a0,s5,80000670 <printf+0xc4>
    c = fmt[++i] & 0xff;
    8000068c:	0014849b          	addiw	s1,s1,1
    80000690:	009a07b3          	add	a5,s4,s1
    80000694:	0007c783          	lbu	a5,0(a5)
    80000698:	0007891b          	sext.w	s2,a5
    if(c == 0)
    8000069c:	12078463          	beqz	a5,800007c4 <printf+0x218>
    switch(c){
    800006a0:	07678263          	beq	a5,s6,80000704 <printf+0x158>
    800006a4:	02fb7a63          	bgeu	s6,a5,800006d8 <printf+0x12c>
    800006a8:	0b978663          	beq	a5,s9,80000754 <printf+0x1a8>
    800006ac:	07800713          	li	a4,120
    800006b0:	0ee79c63          	bne	a5,a4,800007a8 <printf+0x1fc>
      printint(va_arg(ap, int), 16, 1);
    800006b4:	f8843783          	ld	a5,-120(s0)
    800006b8:	00878713          	addi	a4,a5,8
    800006bc:	f8e43423          	sd	a4,-120(s0)
    800006c0:	00100613          	li	a2,1
    800006c4:	000d0593          	mv	a1,s10
    800006c8:	0007a503          	lw	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	da4080e7          	jalr	-604(ra) # 80000470 <printint>
      break;
    800006d4:	fa5ff06f          	j	80000678 <printf+0xcc>
    switch(c){
    800006d8:	0d578063          	beq	a5,s5,80000798 <printf+0x1ec>
    800006dc:	0d879663          	bne	a5,s8,800007a8 <printf+0x1fc>
      printint(va_arg(ap, int), 10, 1);
    800006e0:	f8843783          	ld	a5,-120(s0)
    800006e4:	00878713          	addi	a4,a5,8
    800006e8:	f8e43423          	sd	a4,-120(s0)
    800006ec:	00100613          	li	a2,1
    800006f0:	00a00593          	li	a1,10
    800006f4:	0007a503          	lw	a0,0(a5)
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	d78080e7          	jalr	-648(ra) # 80000470 <printint>
      break;
    80000700:	f79ff06f          	j	80000678 <printf+0xcc>
      printptr(va_arg(ap, uint64));
    80000704:	f8843783          	ld	a5,-120(s0)
    80000708:	00878713          	addi	a4,a5,8
    8000070c:	f8e43423          	sd	a4,-120(s0)
    80000710:	0007b983          	ld	s3,0(a5)
  consputc('0');
    80000714:	03000513          	li	a0,48
    80000718:	00000097          	auipc	ra,0x0
    8000071c:	14c080e7          	jalr	332(ra) # 80000864 <consputc>
  consputc('x');
    80000720:	07800513          	li	a0,120
    80000724:	00000097          	auipc	ra,0x0
    80000728:	140080e7          	jalr	320(ra) # 80000864 <consputc>
    8000072c:	000d0913          	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000730:	03c9d793          	srli	a5,s3,0x3c
    80000734:	00fb87b3          	add	a5,s7,a5
    80000738:	0007c503          	lbu	a0,0(a5)
    8000073c:	00000097          	auipc	ra,0x0
    80000740:	128080e7          	jalr	296(ra) # 80000864 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    80000744:	00499993          	slli	s3,s3,0x4
    80000748:	fff9091b          	addiw	s2,s2,-1
    8000074c:	fe0912e3          	bnez	s2,80000730 <printf+0x184>
    80000750:	f29ff06f          	j	80000678 <printf+0xcc>
      if((s = va_arg(ap, char*)) == 0)
    80000754:	f8843783          	ld	a5,-120(s0)
    80000758:	00878713          	addi	a4,a5,8
    8000075c:	f8e43423          	sd	a4,-120(s0)
    80000760:	0007b903          	ld	s2,0(a5)
    80000764:	02090263          	beqz	s2,80000788 <printf+0x1dc>
      for(; *s; s++)
    80000768:	00094503          	lbu	a0,0(s2)
    8000076c:	f00506e3          	beqz	a0,80000678 <printf+0xcc>
        consputc(*s);
    80000770:	00000097          	auipc	ra,0x0
    80000774:	0f4080e7          	jalr	244(ra) # 80000864 <consputc>
      for(; *s; s++)
    80000778:	00190913          	addi	s2,s2,1
    8000077c:	00094503          	lbu	a0,0(s2)
    80000780:	fe0518e3          	bnez	a0,80000770 <printf+0x1c4>
    80000784:	ef5ff06f          	j	80000678 <printf+0xcc>
        s = "(null)";
    80000788:	00000917          	auipc	s2,0x0
    8000078c:	2c090913          	addi	s2,s2,704 # 80000a48 <uartgetc+0x7c>
      for(; *s; s++)
    80000790:	02800513          	li	a0,40
    80000794:	fddff06f          	j	80000770 <printf+0x1c4>
      consputc('%');
    80000798:	000a8513          	mv	a0,s5
    8000079c:	00000097          	auipc	ra,0x0
    800007a0:	0c8080e7          	jalr	200(ra) # 80000864 <consputc>
      break;
    800007a4:	ed5ff06f          	j	80000678 <printf+0xcc>
      consputc('%');
    800007a8:	000a8513          	mv	a0,s5
    800007ac:	00000097          	auipc	ra,0x0
    800007b0:	0b8080e7          	jalr	184(ra) # 80000864 <consputc>
      consputc(c);
    800007b4:	00090513          	mv	a0,s2
    800007b8:	00000097          	auipc	ra,0x0
    800007bc:	0ac080e7          	jalr	172(ra) # 80000864 <consputc>
      break;
    800007c0:	eb9ff06f          	j	80000678 <printf+0xcc>
  if(locking)
    800007c4:	040d9063          	bnez	s11,80000804 <printf+0x258>
}
    800007c8:	07813083          	ld	ra,120(sp)
    800007cc:	07013403          	ld	s0,112(sp)
    800007d0:	06813483          	ld	s1,104(sp)
    800007d4:	06013903          	ld	s2,96(sp)
    800007d8:	05813983          	ld	s3,88(sp)
    800007dc:	05013a03          	ld	s4,80(sp)
    800007e0:	04813a83          	ld	s5,72(sp)
    800007e4:	04013b03          	ld	s6,64(sp)
    800007e8:	03813b83          	ld	s7,56(sp)
    800007ec:	03013c03          	ld	s8,48(sp)
    800007f0:	02813c83          	ld	s9,40(sp)
    800007f4:	02013d03          	ld	s10,32(sp)
    800007f8:	01813d83          	ld	s11,24(sp)
    800007fc:	0c010113          	addi	sp,sp,192
    80000800:	00008067          	ret
    release(&pr.lock);
    80000804:	00008517          	auipc	a0,0x8
    80000808:	40c50513          	addi	a0,a0,1036 # 80008c10 <pr>
    8000080c:	00000097          	auipc	ra,0x0
    80000810:	bc0080e7          	jalr	-1088(ra) # 800003cc <release>
}
    80000814:	fb5ff06f          	j	800007c8 <printf+0x21c>

0000000080000818 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000818:	fe010113          	addi	sp,sp,-32
    8000081c:	00113c23          	sd	ra,24(sp)
    80000820:	00813823          	sd	s0,16(sp)
    80000824:	00913423          	sd	s1,8(sp)
    80000828:	02010413          	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000082c:	00008497          	auipc	s1,0x8
    80000830:	3e448493          	addi	s1,s1,996 # 80008c10 <pr>
    80000834:	00000597          	auipc	a1,0x0
    80000838:	22c58593          	addi	a1,a1,556 # 80000a60 <uartgetc+0x94>
    8000083c:	00048513          	mv	a0,s1
    80000840:	00000097          	auipc	ra,0x0
    80000844:	9d4080e7          	jalr	-1580(ra) # 80000214 <initlock>
  pr.locking = 1;
    80000848:	00100793          	li	a5,1
    8000084c:	00f4ac23          	sw	a5,24(s1)
}
    80000850:	01813083          	ld	ra,24(sp)
    80000854:	01013403          	ld	s0,16(sp)
    80000858:	00813483          	ld	s1,8(sp)
    8000085c:	02010113          	addi	sp,sp,32
    80000860:	00008067          	ret

0000000080000864 <consputc>:
// called by printf, and to echo input characters,
// but not from write().
//
void
consputc(int c)
{
    80000864:	ff010113          	addi	sp,sp,-16
    80000868:	00113423          	sd	ra,8(sp)
    8000086c:	00813023          	sd	s0,0(sp)
    80000870:	01010413          	addi	s0,sp,16
  if(c == BACKSPACE){
    80000874:	10000793          	li	a5,256
    80000878:	00f50e63          	beq	a0,a5,80000894 <consputc+0x30>
    // if the user typed backspace, overwrite with a space.
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
  } else {
    uartputc_sync(c);
    8000087c:	00000097          	auipc	ra,0x0
    80000880:	0e4080e7          	jalr	228(ra) # 80000960 <uartputc_sync>
  }
}
    80000884:	00813083          	ld	ra,8(sp)
    80000888:	00013403          	ld	s0,0(sp)
    8000088c:	01010113          	addi	sp,sp,16
    80000890:	00008067          	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000894:	00800513          	li	a0,8
    80000898:	00000097          	auipc	ra,0x0
    8000089c:	0c8080e7          	jalr	200(ra) # 80000960 <uartputc_sync>
    800008a0:	02000513          	li	a0,32
    800008a4:	00000097          	auipc	ra,0x0
    800008a8:	0bc080e7          	jalr	188(ra) # 80000960 <uartputc_sync>
    800008ac:	00800513          	li	a0,8
    800008b0:	00000097          	auipc	ra,0x0
    800008b4:	0b0080e7          	jalr	176(ra) # 80000960 <uartputc_sync>
    800008b8:	fcdff06f          	j	80000884 <consputc+0x20>

00000000800008bc <consoleinit>:
  uint e;  // Edit index
} cons;

void
consoleinit(void)
{
    800008bc:	ff010113          	addi	sp,sp,-16
    800008c0:	00113423          	sd	ra,8(sp)
    800008c4:	00813023          	sd	s0,0(sp)
    800008c8:	01010413          	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    800008cc:	00000597          	auipc	a1,0x0
    800008d0:	19c58593          	addi	a1,a1,412 # 80000a68 <uartgetc+0x9c>
    800008d4:	00008517          	auipc	a0,0x8
    800008d8:	35c50513          	addi	a0,a0,860 # 80008c30 <cons>
    800008dc:	00000097          	auipc	ra,0x0
    800008e0:	938080e7          	jalr	-1736(ra) # 80000214 <initlock>

  uartinit();
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	018080e7          	jalr	24(ra) # 800008fc <uartinit>
}
    800008ec:	00813083          	ld	ra,8(sp)
    800008f0:	00013403          	ld	s0,0(sp)
    800008f4:	01010113          	addi	sp,sp,16
    800008f8:	00008067          	ret

00000000800008fc <uartinit>:

void uartstart();

void
uartinit(void)
{
    800008fc:	ff010113          	addi	sp,sp,-16
    80000900:	00113423          	sd	ra,8(sp)
    80000904:	00813023          	sd	s0,0(sp)
    80000908:	01010413          	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000090c:	100007b7          	lui	a5,0x10000
    80000910:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    80000914:	f8000713          	li	a4,-128
    80000918:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    8000091c:	00300713          	li	a4,3
    80000920:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    80000924:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    80000928:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    8000092c:	00700693          	li	a3,7
    80000930:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    80000934:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    80000938:	00000597          	auipc	a1,0x0
    8000093c:	13858593          	addi	a1,a1,312 # 80000a70 <uartgetc+0xa4>
    80000940:	00008517          	auipc	a0,0x8
    80000944:	39850513          	addi	a0,a0,920 # 80008cd8 <uart_tx_lock>
    80000948:	00000097          	auipc	ra,0x0
    8000094c:	8cc080e7          	jalr	-1844(ra) # 80000214 <initlock>
}
    80000950:	00813083          	ld	ra,8(sp)
    80000954:	00013403          	ld	s0,0(sp)
    80000958:	01010113          	addi	sp,sp,16
    8000095c:	00008067          	ret

0000000080000960 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    80000960:	fe010113          	addi	sp,sp,-32
    80000964:	00113c23          	sd	ra,24(sp)
    80000968:	00813823          	sd	s0,16(sp)
    8000096c:	00913423          	sd	s1,8(sp)
    80000970:	02010413          	addi	s0,sp,32
    80000974:	00050493          	mv	s1,a0
  push_off();
    80000978:	00000097          	auipc	ra,0x0
    8000097c:	90c080e7          	jalr	-1780(ra) # 80000284 <push_off>

  if(panicked){
    80000980:	00008797          	auipc	a5,0x8
    80000984:	3907a783          	lw	a5,912(a5) # 80008d10 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000988:	10000737          	lui	a4,0x10000
  if(panicked){
    8000098c:	00078463          	beqz	a5,80000994 <uartputc_sync+0x34>
    for(;;)
    80000990:	0000006f          	j	80000990 <uartputc_sync+0x30>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000994:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000998:	0ff7f793          	andi	a5,a5,255
    8000099c:	0207f793          	andi	a5,a5,32
    800009a0:	fe078ae3          	beqz	a5,80000994 <uartputc_sync+0x34>
    ;
  WriteReg(THR, c);
    800009a4:	0ff4f793          	andi	a5,s1,255
    800009a8:	10000737          	lui	a4,0x10000
    800009ac:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    800009b0:	00000097          	auipc	ra,0x0
    800009b4:	9b4080e7          	jalr	-1612(ra) # 80000364 <pop_off>
}
    800009b8:	01813083          	ld	ra,24(sp)
    800009bc:	01013403          	ld	s0,16(sp)
    800009c0:	00813483          	ld	s1,8(sp)
    800009c4:	02010113          	addi	sp,sp,32
    800009c8:	00008067          	ret

00000000800009cc <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009cc:	ff010113          	addi	sp,sp,-16
    800009d0:	00813423          	sd	s0,8(sp)
    800009d4:	01010413          	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009d8:	100007b7          	lui	a5,0x10000
    800009dc:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009e0:	0017f793          	andi	a5,a5,1
    800009e4:	00078e63          	beqz	a5,80000a00 <uartgetc+0x34>
    // input data is ready.
    return ReadReg(RHR);
    800009e8:	100007b7          	lui	a5,0x10000
    800009ec:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009f0:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009f4:	00813403          	ld	s0,8(sp)
    800009f8:	01010113          	addi	sp,sp,16
    800009fc:	00008067          	ret
    return -1;
    80000a00:	fff00513          	li	a0,-1
    80000a04:	ff1ff06f          	j	800009f4 <uartgetc+0x28>
