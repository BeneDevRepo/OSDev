ENTRY(entry)
OUTPUT_FORMAT("binary")

phys = 0x00000500; /* offset at which stage 2 gets loaded into memory */

/* symbol = .; -> defines symbol with value of current offset*/

SECTIONS {
    . = phys; /* assigns offset to 0x500 using symbol phys */
    .entry              : { __entry_start = .;      *(.entry)   } /* Contains Entry point */
    .text               : { __text_start = .;       *(.text)    } /* Contains rest of stage2 code */
    .data               : { __data_start = .;       *(.data)    } /* Contains initialized global variables */
    .rodata             : { __rodata_start = .;     *(.rodata)  } /* Contains constants */
    .bss                : { __bss_start = .;        *(.bss)     } /* Contains uninitialized global variables (gets zeroed on startup) */
    __end = .;
}
/* SECTIONS {
	. = 0x00;
	.entry              : { __entry_start = .;      *(.entry)   }
	.text               : { __text_start = .;       *(.text)    }
	.data               : { __data_start = .;       *(.data)    }
	.rodata             : { __rodata_start = .;     *(.rodata)  }
	.bss                : { __bss_start = .;        *(.bss)     }
	__end = .;
} */

/* ORDER
	CLNAME CODE
		SEGMENT _ENTRY
		SEGMENT _TEXT
	CLNAME DATA */
