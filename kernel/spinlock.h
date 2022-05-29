// Mutual exclusion lock.
struct spinlock {
  // 锁被持有了吗？
  uint locked;       // Is the lock held?

  // For debugging:
  // 锁的名字
  char *name;        // Name of lock.
  /* 持有锁的cpu */
  struct cpu *cpu;   // The cpu holding the lock.
};

