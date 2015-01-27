# Name: Makefile
# Copyright: 2011-2015 Matthew T. Pandina

# This is a prototype Makefile. Modify it according to your needs.
# You should at least check the settings for
# CLOCK ........ Target AVR clock rate in Hertz
# DEVICE ....... The AVR device you compile for
# FUSES ........ Parameters for avrdude to flash the fuses appropriately.
# OBJECTS ...... The object files created from your source files. This list is
#                usually the same as the list of source files with suffix ".o".
# PROGRAMMER ... Options to avrdude which define the hardware you use for
#                uploading to the AVR and the interface where this hardware
#                is connected.

CLOCK      = 30000000
#CLOCK      = 20000000
#CLOCK      = 18432000
#CLOCK      = 16000000
#CLOCK      = 8000000
#CLOCK      = 1000000

DEVICE     = atmega328p
# ATmega328P - Default setting in Arduino Duemilanove
#FUSES      = -U hfuse:w:0xda:m -U lfuse:w:0xff:m
# ATmega328P - Default setting
#FUSES      = -U hfuse:w:0xd9:m -U lfuse:w:0x62:m
# ATmega328P - Enable clock output
#FUSES      = -U hfuse:w:0xd9:m -U lfuse:w:0x22:m
# ATmega328P - Remove clock divider
#FUSES      = -U hfuse:w:0xd9:m -U lfuse:w:0xe2:m
# ATmega328P - Remove clock divider, enable clock output
#FUSES      = -U hfuse:w:0xd9:m -U lfuse:w:0xa2:m
# ATmega328P - Remove clock divider, set external crystal
#FUSES      = -U hfuse:w:0xd9:m -U lfuse:w:0xe6:m
# ATmega328P - Remove clock divider, set external crystal, enable clock output
FUSES      = -U hfuse:w:0xd9:m -U lfuse:w:0xa6:m
# ATmega328P - Remove clock divider, set external crystal, enable clock output, BOD 2.7 V
#FUSES      = -U hfuse:w:0xd9:m -U lfuse:w:0xa6:m -U efuse:w:0xFD:m

#DEVICE     = attiny85
# ATtiny85 - Default setting
#FUSES      = -U hfuse:w:0xdf:m -U lfuse:w:0x62:m
# ATtiny85 - Enable clock output
#FUSES      = -U hfuse:w:0xdf:m -U lfuse:w:0x22:m
# ATtiny85 - Remove clock divider
#FUSES      = -U hfuse:w:0xdf:m -U lfuse:w:0xe2:m
# ATtiny85 - Remove clock divider, enable clock output
#FUSES      = -U hfuse:w:0xdf:m -U lfuse:w:0xa2:m
# ATtiny85- Remove clock divider, set PLL Clock
#FUSES      = -U hfuse:w:0xdf:m -U lfuse:w:0xe1:m
# ATtiny85 - Remove clock divider, set PLL Clock, enable clock output
#FUSES      = -U hfuse:w:0xdf:m -U lfuse:w:0xa1:m
# ATtiny85 - Remove clock divider, set PLL Clock, enable clock output, BOD 2.7 V
#FUSES      = -U hfuse:w:0xdd:m -U lfuse:w:0xa1:m

CC = avr-gcc
TARGET_ARCH = -mmcu=$(DEVICE)
CFLAGS = -std=gnu99 -Wall -Wextra -Werror -Winline -mint8 -O3
CPPFLAGS = -DF_CPU=$(CLOCK) -D__DELAY_BACKWARD_COMPATIBLE__ $(TLC5940_DEFINES)
LDFLAGS = -lc -lm
OBJECTS = main.o tlc5940.o
PROGRAMMER = -c avrispmkII -P usb
AVRDUDE = avrdude $(PROGRAMMER) -p $(DEVICE)

#include tlc5940-attiny85.mk
include tlc5940-rgb-pov.mk

all: main.hex

.PHONY: clean install flash pflash fuse disasm cpp

flash: all
	$(AVRDUDE) -U flash:w:main.hex:i

pflash: all
	$(AVRDUDE) -n -U flash:w:main.hex:i

fuse:
	$(AVRDUDE) $(FUSES)

# Xcode uses the Makefile targets "", "clean" and "install"
install: fuse flash

# if you use a bootloader, change the command below appropriately:
load: all
	bootloadHID main.hex

clean:
	rm -f main.hex main.elf $(OBJECTS)

main.elf: $(OBJECTS)
	$(LINK.c) -o $@ $^

main.hex: main.elf
	rm -f main.hex
	avr-objcopy -j .text -j .data -O ihex $^ $@
	avr-size -A --format=avr --mcu=$(DEVICE) $^
# If you have an EEPROM section, you must also create a hex file for the
# EEPROM and add it to the "flash" target.

# Targets for code debugging and analysis:
disasm: main.elf
	avr-objdump -d $^

cpp:
	$(COMPILE.c) -E $(OBJECTS:.o=.c)

%.lst: %.c
	{ echo '.psize 0' ; $(COMPILE.c) -S -g -o - $< ; } | avr-as -alhd -mmcu=$(DEVICE) -o /dev/null - > $@
