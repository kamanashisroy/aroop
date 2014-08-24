

DEBUGFLAG=-g
ARMGNU ?= tools-master/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian/bin/arm-linux-gnueabihf
AFLAGS = --warn --fatal-warnings -mfpu=vfp -mfloat-abi=hard -march=armv6zk -mcpu=arm1176jzf-s $(DEBUGFLAG)

CFLAGS = -O2 -nostdlib -nostartfiles -ffreestanding -mfpu=vfp -mfloat-abi=hard -march=armv6zk -mtune=arm1176jzf-s $(DEBUGFLAG)
CFLAGS += -Wall
CFLAGS += -DRASPBERRY_PI_BARE_METAL -DAROOP_BASIC 

INCLUDES=-I../../ -I../../aroop/platform/raspberrypi
#C_SOURCES_DIR=csrc/
C_SOURCES_DIR=../../src/
OBJECT_DIR=.objects/

INCLUDES+=-Iinclude
C_SOURCES=$(wildcard $(C_SOURCES_DIR)*.c)
C_SOURCES+=$(wildcard csrc/*.c)
C_SOURCES_BASE=$(basename $(notdir $(C_SOURCES)))
C_OBJECTS=$(addprefix $(OBJECT_DIR)/, $(addsuffix .o, $(C_SOURCES_BASE)))
OBJECTS+=$(C_OBJECTS)

ASM_SOURCES_DIR=asmsrc/
ASM_SOURCES=$(wildcard $(ASM_SOURCES_DIR)*.s)
ASM_SOURCES_BASE=$(basename $(notdir $(ASM_SOURCES)))
ASM_OBJECTS=$(addprefix $(OBJECT_DIR)/, $(addsuffix .o, $(ASM_SOURCES_BASE)))
OBJECTS+=$(ASM_OBJECTS)

STATIC_LIB=aroop_core_rtl.a
KERNEL_IMG=kernel.img
KERNEL_ELF=kernel.elf
TARGETS+=$(OBJECTS) $(STATIC_LIB) $(KERNEL_IMG) $(KERNEL_ELF)

LIBS = 

all : depend $(TARGETS)

depend:
	mkdir -p .objects

clean :
	rm -f $(TARGETS)
	rm -f *.dump

$(OBJECT_DIR)%.o : $(ASM_SOURCES_DIR)%.s
	$(ARMGNU)-as $(AFLAGS) $< -o $@

$(OBJECT_DIR)%.o : $(C_SOURCES_DIR)%.c
	$(ARMGNU)-gcc $(CFLAGS) $(INCLUDES) -c $< -o $@

$(OBJECT_DIR)%.o : csrc/%.c
	$(ARMGNU)-gcc $(CFLAGS) $(INCLUDES) -c $< -o $@

$(KERNEL_ELF) : memmap.ld $(OBJECTS) $(LIBS)
	$(ARMGNU)-ld $(OBJECTS) $(LIBS) -T memmap.ld -o $(KERNEL_ELF)

$(KERNEL_IMG) : $(KERNEL_ELF)
	$(ARMGNU)-objcopy $(KERNEL_ELF) -O binary $(KERNEL_IMG)
	$(ARMGNU)-objdump -D $(KERNEL_ELF) > main.dump

$(STATIC_LIB) : $(OBJECTS)
	$(ARMGNU)-ar crv $@ $<

test: $(KERNEL_ELF)
	qemu-system-arm -cpu arm1176 -nographic -m 256 -kernel $(KERNEL_ELF) -M versatilepb

test_debug: $(KERNEL_ELF)
	qemu-system-arm -cpu arm1176 -nographic -m 256 -kernel $(KERNEL_ELF) -M versatilepb -s -S

toolchain:
	wget -N https://github.com/raspberrypi/tools/archive/master.zip
	unzip master.zip


