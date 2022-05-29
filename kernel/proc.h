struct cpu {
  /* push_off嵌套的深度 */
  int noff;                   // Depth of push_off() nesting.
  /* 中断在push_off之前启用了吗 */
  int intena;                 // Were interrupts enabled before push_off()?
};

extern struct cpu cpus[NCPU];