
ENTRY(_start)

SECTIONS
{
    . = 0x8000;
    _start = .;
    _text_start = .;
    .text :
    {
        KEEP(*(.text.boot))
        *(.text)
    }
    . = ALIGN(4096); /* align to page size */
    _text_end = .;
 
    _rodata_start = .;
    .rodata :
    {
        *(.rodata)
    }
    . = ALIGN(4096); /* align to page size */
    _rodata_end = .;
 
    _data_start = .;
    .data :
    {
        *(.data)
    }
    . = ALIGN(4096); /* align to page size */
    _data_end = .;
 
    _bss_start = .;
    .bss :
    {
        bss = .;
        *(.bss)
    }
    . = ALIGN(4096); /* align to page size */
    _bss_end = .;
    _end = .;
   heap_low = .; /* for _sbrk */
   . = . + 0x10000; /* 64kB of heap memory */
   heap_top = .; /* for _sbrk */
   . = . + 0x10000; /* 64kB of stack memory */
   stack_top = .; /* for startup.s */ 
}
