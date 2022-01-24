        # qemu -kernel 会把编译出的内核代码的二进制格式加载到内存地址为 0x80000000 的地方
        # 然后CPU顺序执行每条指令
        # 然后使每个 CPU 都跳转到那里。
        # kernel.ld 链接文件会将下面的代码放在 0x80000000 这个地方。
.section .text
.global _entry
_entry:
        # 为 C 语言开辟一个栈空间。
        # stack0 是在 start.c 中声明的。
        # 我们会为每个 CPU 开辟一个 4096 个字节的栈空间。
        # sp = stack0 + (hartid * 4096)
        la sp, stack0     # 将栈的起始地址加载到 sp 栈指针寄存器中。
        li a0, 1024*4     # 此时 a0 寄存器中的值是 4096
        csrr a1, mhartid  # 将当前的 hart id 读取到 a1 寄存器中
        addi a1, a1, 1    # 执行操作：a1 <- a1 + 1
        mul a0, a0, a1    # 执行操作：a0 <- a0 * a1
        add sp, sp, a0    # 执行操作：sp <- sp + a0 ，此时栈指针指向栈的空间的尾部，因为栈地址是从高地址向低地址生长的。
        # 跳转到 start.c 中的 start() 函数
        call start
spin:
        j spin # 自旋