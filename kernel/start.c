#include <stdint.h>

#include "types.h"
#include "riscv.h"

#define NCPU          8  // maximum number of CPUs

void main();

// 这里开辟了栈空间，每个CPU都有自己的独有的栈空间。
__attribute__ ((aligned (16))) char stack0[4096 * NCPU];

// entry.S 会在机器模式下跳转到这里，当然栈是 stack0 。

// entry.S jumps here in machine mode on stack0.
void
start()
{
  // set M Previous Privilege mode to Supervisor, for mret.
  // 将当前特权级的上一次特权级设置为监管者级别
  // 这样mret执行之后就返回到监管者级别了。
  unsigned long x = r_mstatus();
  x &= ~MSTATUS_MPP_MASK;
  x |= MSTATUS_MPP_S;
  // 写入mstatus寄存器
  w_mstatus(x);

  // set M Exception Program Counter to main, for mret.
  // requires gcc -mcmodel=medany
  // 将main函数在汇编中的开始地址写入mepc寄存器中
  // start() 除了設定時間中斷之外，會透過 w_mepc((uint64)main) 這行指令，設定機器模式的 mret 返回點，在最後在 asm volatile("mret") 這行指令執行時，進入 main() 函數。
  w_mepc((uint64)main);

  // disable paging for now.
  w_satp(0);

  // delegate all interrupts and exceptions to supervisor mode.
  // 将所有中断和异常代理到监管者模式。
  // 这里的意思应该是：机器模式的中断和异常由监管者模式来处理。
  w_medeleg(0xffff);
  w_mideleg(0xffff);
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);

  // configure Physical Memory Protection to give supervisor mode
  // access to all of physical memory.
  // 让监管者模式可以访问所有的物理内存
  w_pmpaddr0(0x3fffffffffffffull);
  w_pmpcfg0(0xf);

  // ask for clock interrupts.
  // timerinit();

  // keep each CPU's hartid in its tp register, for cpuid().
  // 将每个CPU的hartid写入它自己的tp寄存器中。
  int id = r_mhartid();
  w_tp(id);

  // switch to supervisor mode and jump to main().
  // 执行mret切换到监管者模式，然后跳转到main函数执行。
  asm volatile("mret");
}