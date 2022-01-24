OUTPUT_ARCH( "riscv" )
ENTRY( _entry )

SECTIONS
{
  /*
   * 保证 entry.S / _entry 位于内存地址为 0x80000000 的地方，
   * 这样 qemu's -kernel 可以跳转过去。
   */
  . = 0x80000000;
}