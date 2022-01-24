
kernel/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00000117          	auipc	sp,0x0
    80000004:	0e010113          	addi	sp,sp,224 # 800000e0 <stack0>
    80000008:	00001537          	lui	a0,0x1
    8000000c:	f14025f3          	csrr	a1,mhartid
    80000010:	00158593          	addi	a1,a1,1
    80000014:	02b50533          	mul	a0,a0,a1
    80000018:	00a10133          	add	sp,sp,a0
    8000001c:	080000ef          	jal	ra,8000009c <start>

0000000080000020 <spin>:
    80000020:	0000006f          	j	80000020 <spin>

0000000080000024 <lib_putc>:
#define UART_THR    (uint8_t*)(UART+0x00) // THR:transmitter holding register
#define UART_LSR    (uint8_t*)(UART+0x05) // LSR:line status register
#define UART_LSR_EMPTY_MASK 0x40          // LSR Bit 6: Transmitter empty; both the THR and LSR are empty
#define NCPU          8  // maximum number of CPUs

int lib_putc(char ch) {
    80000024:	ff010113          	addi	sp,sp,-16
    80000028:	00813423          	sd	s0,8(sp)
    8000002c:	01010413          	addi	s0,sp,16
  while ((*UART_LSR & UART_LSR_EMPTY_MASK) == 0);
    80000030:	100007b7          	lui	a5,0x10000
    80000034:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000038:	0407f793          	andi	a5,a5,64
    8000003c:	00078063          	beqz	a5,8000003c <lib_putc+0x18>
  return *UART_THR = ch;
    80000040:	100007b7          	lui	a5,0x10000
    80000044:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>
}
    80000048:	00813403          	ld	s0,8(sp)
    8000004c:	01010113          	addi	sp,sp,16
    80000050:	00008067          	ret

0000000080000054 <lib_puts>:

void lib_puts(char *s) {
    80000054:	fe010113          	addi	sp,sp,-32
    80000058:	00113c23          	sd	ra,24(sp)
    8000005c:	00813823          	sd	s0,16(sp)
    80000060:	00913423          	sd	s1,8(sp)
    80000064:	02010413          	addi	s0,sp,32
    80000068:	00050493          	mv	s1,a0
  while (*s) lib_putc(*s++);
    8000006c:	00054503          	lbu	a0,0(a0) # 1000 <_entry-0x7ffff000>
    80000070:	00050c63          	beqz	a0,80000088 <lib_puts+0x34>
    80000074:	00148493          	addi	s1,s1,1
    80000078:	00000097          	auipc	ra,0x0
    8000007c:	fac080e7          	jalr	-84(ra) # 80000024 <lib_putc>
    80000080:	0004c503          	lbu	a0,0(s1)
    80000084:	fe0518e3          	bnez	a0,80000074 <lib_puts+0x20>
}
    80000088:	01813083          	ld	ra,24(sp)
    8000008c:	01013403          	ld	s0,16(sp)
    80000090:	00813483          	ld	s1,8(sp)
    80000094:	02010113          	addi	sp,sp,32
    80000098:	00008067          	ret

000000008000009c <start>:

// 这里开辟了栈空间，每个CPU都有自己的独有的栈空间。
__attribute__ ((aligned (16))) char stack0[4096 * NCPU];

// entry.S 会在机器模式下跳转到这里，当然栈是 stack0 。
void start() {
    8000009c:	ff010113          	addi	sp,sp,-16
    800000a0:	00113423          	sd	ra,8(sp)
    800000a4:	00813023          	sd	s0,0(sp)
    800000a8:	01010413          	addi	s0,sp,16
  lib_puts("你好，世界!\n");
    800000ac:	00000517          	auipc	a0,0x0
    800000b0:	01450513          	addi	a0,a0,20 # 800000c0 <start+0x24>
    800000b4:	00000097          	auipc	ra,0x0
    800000b8:	fa0080e7          	jalr	-96(ra) # 80000054 <lib_puts>
  while (1) {}
    800000bc:	0000006f          	j	800000bc <start+0x20>
