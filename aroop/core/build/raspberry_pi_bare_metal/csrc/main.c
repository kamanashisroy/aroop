
#include <stdint.h>
#include "alloc.h"

#define serial_dev(x) ({asm volatile("ldr %[dev],=0x101f1000" :: [dev]"r"(x));})
#define dev_putc(dev,ch) ({asm volatile("str %[data], [%[dest]]" :: [dest]"r"(dev), [data]"r"(ch));})

#if 0
void inline serial_dev_inline(unsigned int*dev) {
        serial_dev(dev);
}
void inline dev_putc_inline(unsigned int*dev, char ch) {
        dev_putc(dev, ch);
}
#endif
static void dev_puts_func(const char*data) {
        int i = 0;
        uint32_t*dev = (uint32_t*)0x101f1000;
        char ch = 0;
        serial_dev(dev);
        for(i=0;;i++) {
                //ch = *(data+i);
                ch = data[i];
                if(ch == '\0')
                        break;
                dev_putc(dev, ch);
        }
}

int raspberry_serial_printf(char*format, ...) {
	return 0;
}

int raspberry_snprintf(char*format, ...) {
	return 0;
}

int program(void)
{
   dev_puts_func("Hello world\r\n");
   dev_puts_func("wait for input> \r\n");
   
   while(1)
   {
   }
   return(0);
}
