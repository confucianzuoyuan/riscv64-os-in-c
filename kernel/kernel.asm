
kernel/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00000117          	auipc	sp,0x0
    80000004:	17010113          	addi	sp,sp,368 # 80000170 <stack0>
    80000008:	00001537          	lui	a0,0x1
    8000000c:	f14025f3          	csrr	a1,mhartid
    80000010:	00158593          	addi	a1,a1,1
    80000014:	02b50533          	mul	a0,a0,a1
    80000018:	00a10133          	add	sp,sp,a0
    8000001c:	008000ef          	jal	ra,80000024 <start>

0000000080000020 <spin>:
    80000020:	0000006f          	j	80000020 <spin>

0000000080000024 <start>:
// entry.S 会在机器模式下跳转到这里，当然栈是 stack0 。

// entry.S jumps here in machine mode on stack0.
void
start()
{
    80000024:	ff010113          	addi	sp,sp,-16
    80000028:	00813423          	sd	s0,8(sp)
    8000002c:	01010413          	addi	s0,sp,16
// 读取机器状态寄存器中的内容
static inline uint64
r_mstatus()
{
  uint64 x;
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000030:	300027f3          	csrr	a5,mstatus
  // set M Previous Privilege mode to Supervisor, for mret.
  // 将当前特权级的上一次特权级设置为监管者级别
  // 这样mret执行之后就返回到监管者级别了。
  unsigned long x = r_mstatus();
  x &= ~MSTATUS_MPP_MASK;
    80000034:	ffffe737          	lui	a4,0xffffe
    80000038:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <stack0+0xffffffff7fffe68f>
    8000003c:	00e7f7b3          	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    80000040:	00001737          	lui	a4,0x1
    80000044:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    80000048:	00e7e7b3          	or	a5,a5,a4

// 将`x`的值写入mstatus寄存器
static inline void 
w_mstatus(uint64 x)
{
  asm volatile("csrw mstatus, %0" : : "r" (x));
    8000004c:	30079073          	csrw	mstatus,a5
// exception will go.
// 写入机器异常程序计数器（保存了从异常返回以后要执行的指令的地址）
static inline void 
w_mepc(uint64 x)
{
  asm volatile("csrw mepc, %0" : : "r" (x));
    80000050:	00000797          	auipc	a5,0x0
    80000054:	0d878793          	addi	a5,a5,216 # 80000128 <main>
    80000058:	34179073          	csrw	mepc,a5
// supervisor address translation and protection;
// holds the address of the page table.
static inline void 
w_satp(uint64 x)
{
  asm volatile("csrw satp, %0" : : "r" (x));
    8000005c:	00000793          	li	a5,0
    80000060:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    80000064:	000107b7          	lui	a5,0x10
    80000068:	fff78793          	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    8000006c:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    80000070:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    80000074:	104027f3          	csrr	a5,sie
  // delegate all interrupts and exceptions to supervisor mode.
  // 将所有中断和异常代理到监管者模式。
  // 这里的意思应该是：机器模式的中断和异常由监管者模式来处理。
  w_medeleg(0xffff);
  w_mideleg(0xffff);
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    80000078:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    8000007c:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    80000080:	fff00793          	li	a5,-1
    80000084:	00a7d793          	srli	a5,a5,0xa
    80000088:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    8000008c:	00f00793          	li	a5,15
    80000090:	3a079073          	csrw	pmpcfg0,a5
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000094:	f14027f3          	csrr	a5,mhartid
  // timerinit();

  // keep each CPU's hartid in its tp register, for cpuid().
  // 将每个CPU的hartid写入它自己的tp寄存器中。
  int id = r_mhartid();
  w_tp(id);
    80000098:	0007879b          	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    8000009c:	00078213          	mv	tp,a5

  // switch to supervisor mode and jump to main().
  // 执行mret切换到监管者模式，然后跳转到main函数执行。
  asm volatile("mret");
    800000a0:	30200073          	mret
    800000a4:	00813403          	ld	s0,8(sp)
    800000a8:	01010113          	addi	sp,sp,16
    800000ac:	00008067          	ret

00000000800000b0 <lib_putc>:
#define UART        0x10000000
#define UART_THR    (uint8_t*)(UART+0x00) // THR:transmitter holding register
#define UART_LSR    (uint8_t*)(UART+0x05) // LSR:line status register
#define UART_LSR_EMPTY_MASK 0x40          // LSR Bit 6: Transmitter empty; both the THR and LSR are empty

int lib_putc(char ch) {
    800000b0:	ff010113          	addi	sp,sp,-16
    800000b4:	00813423          	sd	s0,8(sp)
    800000b8:	01010413          	addi	s0,sp,16
  while ((*UART_LSR & UART_LSR_EMPTY_MASK) == 0);
    800000bc:	100007b7          	lui	a5,0x10000
    800000c0:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800000c4:	0407f793          	andi	a5,a5,64
    800000c8:	00078063          	beqz	a5,800000c8 <lib_putc+0x18>
  return *UART_THR = ch;
    800000cc:	100007b7          	lui	a5,0x10000
    800000d0:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>
}
    800000d4:	00813403          	ld	s0,8(sp)
    800000d8:	01010113          	addi	sp,sp,16
    800000dc:	00008067          	ret

00000000800000e0 <lib_puts>:

void lib_puts(char *s) {
    800000e0:	fe010113          	addi	sp,sp,-32
    800000e4:	00113c23          	sd	ra,24(sp)
    800000e8:	00813823          	sd	s0,16(sp)
    800000ec:	00913423          	sd	s1,8(sp)
    800000f0:	02010413          	addi	s0,sp,32
    800000f4:	00050493          	mv	s1,a0
  while (*s) lib_putc(*s++);
    800000f8:	00054503          	lbu	a0,0(a0) # 1000 <_entry-0x7ffff000>
    800000fc:	00050c63          	beqz	a0,80000114 <lib_puts+0x34>
    80000100:	00148493          	addi	s1,s1,1
    80000104:	00000097          	auipc	ra,0x0
    80000108:	fac080e7          	jalr	-84(ra) # 800000b0 <lib_putc>
    8000010c:	0004c503          	lbu	a0,0(s1)
    80000110:	fe0518e3          	bnez	a0,80000100 <lib_puts+0x20>
}
    80000114:	01813083          	ld	ra,24(sp)
    80000118:	01013403          	ld	s0,16(sp)
    8000011c:	00813483          	ld	s1,8(sp)
    80000120:	02010113          	addi	sp,sp,32
    80000124:	00008067          	ret

0000000080000128 <main>:

void
main()
{
    80000128:	ff010113          	addi	sp,sp,-16
    8000012c:	00113423          	sd	ra,8(sp)
    80000130:	00813023          	sd	s0,0(sp)
    80000134:	01010413          	addi	s0,sp,16
  lib_puts("你好，世界！");
    80000138:	00000517          	auipc	a0,0x0
    8000013c:	02050513          	addi	a0,a0,32 # 80000158 <main+0x30>
    80000140:	00000097          	auipc	ra,0x0
    80000144:	fa0080e7          	jalr	-96(ra) # 800000e0 <lib_puts>
    80000148:	00813083          	ld	ra,8(sp)
    8000014c:	00013403          	ld	s0,0(sp)
    80000150:	01010113          	addi	sp,sp,16
    80000154:	00008067          	ret
