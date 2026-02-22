MEMORY
{
    ram (rwx) : ORIGIN = 0x00000000, LENGTH = 0x1000 /* 4KB */
}

SECTIONS
{
    . = 0x00000000;

    .text : {
        . = ALIGN(4);
        *(.text)
        *(.text.*)
        . = ALIGN(4);
    } > ram

    .rodata : {
        . = ALIGN(4);
        *(.rodata)
        *(.rodata.*)
        *(.srodata.*)
        . = ALIGN(4);
    } > ram

    .data : {
        . = ALIGN(4);
        *(.data)
        *(.data.*)
        *(.sdata.*)
        . = ALIGN(4);
    } > ram

    .bss : {
        . = ALIGN(4);
        _bss_start = .;    
        *(.bss)
        *(.bss.*)
        *(.sbss.*)
        *(COMMON)
        . = ALIGN(4);
        _bss_end = .;
    } > ram

    /* Define o topo da RAM como o início da Stack (cresce para baixo) */
    _stack_top = ORIGIN(ram) + LENGTH(ram);
}