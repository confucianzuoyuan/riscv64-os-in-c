#include <stdint.h>

// UART是外部设备，外部设备对应的寄存器维护在内存里面
// 所以当进行赋值操作*UART_THR='a'时，UART地址对应的物理内存被修改为'a'，然后这个字节被发送到UART外部设备，
// 然后就可以打印出来了。
#define UART        0x10000000
#define UART_THR    (uint8_t*)(UART+0x00) // THR:transmitter holding register
#define UART_LSR    (uint8_t*)(UART+0x05) // LSR:line status register
#define UART_LSR_EMPTY_MASK 0x40          // LSR Bit 6: Transmitter empty; both the THR and LSR are empty

int lib_putc(char ch) {
  while ((*UART_LSR & UART_LSR_EMPTY_MASK) == 0);
  return *UART_THR = ch;
}

void lib_puts(char *s) {
  while (*s) lib_putc(*s++);
}

void
main()
{
  lib_puts("你好，世界！");
}