# ---------- Begin TLC5940 Configuration Section ----------

# Defines the number of TLC5940 chips that are connected in series
TLC5940_N = 4

# Flag for including functions for manually setting the dot correction
#  0 = Do not include dot correction functions. The dot correction values
#      stored in the TLC5940's EEPROM will always be used. This
#      generates smaller code.
#  1 = By default, uses the dot correction values store in the TLC5940's
#      EEPROM, but also includes dot correction functions:
#      TLC5940_SetAllDC(), TLC5940_SetDC(), and TLC5940_ClockInDC(),
#      which allow you to programatically set the dot correction
#      immediately after TLC5940_Init() is called.
#
# Tip #1: If you are not including dot correction support, consider
#         hardwiring both the DCPRG and VPRG pins to GND and setting
#         DCPRG_PIN = GND and VPRG_PIN = GND farther down in this file.
#         That will free up two pins on your AVR, and you'll have two
#         fewer traces to route between chips.
#
# Tip #2: If you do include dot correction support, and you always
#         set the dot correction values programatically (versus using
#         the EEPROM defaults), consider hardwiring the TLC5940's DCPRG
#         pin to VCC and setting DCPRG_PIN = VCC farther down in this
#         file. That will free up one pin on your AVR, and you'll have
#         one fewer trace to route between chips.
TLC5940_INCLUDE_DC_FUNCS = 1

# Flag for including efficient functions for setting the grayscale
# (and optionally dot correction) values of four channels at once.
#  0 = Do not include functions for ganging outputs in groups of four
#  1 = Include functions for ganging outputs in groups of four
#
# Note: Any number of outputs can be ganged together at any time by
#       simply connecting them together. These functions exist solely
#       to provide a more efficient way of setting the values of four
#       channels at once if outputs 0-3, 4-7, 8-11, 12-15, ... are
#       connected in parallel to the same load.
TLC5940_INCLUDE_SET4_FUNCS = 0

# Flag for including a default implementation of the ISR.
#  0 = For advanced users only! Only choose this if you want to
#      override the default implementation of the
#      ISR(TIMER0_COMPA_vect) with your own custom implemetation
#      inside main.c
#  1 = Most users should use this setting. Uses the default
#      implementation of the ISR as defined in tlc5940.c
TLC5940_INCLUDE_DEFAULT_ISR = 1

# Flag for including a gamma correction table stored in the flash
# memory. When driving LEDs, it is helpful to use the full 12-bits of
# PWM the TLC5940 offers to output a 12-bit gamma-corrected value
# derived from an 8-bit value, since the human eye has a non-linear
# perception of brightness.
#
# For example, calling:
#    TLC5940_SetGS(0, 2047);
# will not make the LED appear half as bright as calling:
#    TLC5940_SetGS(0, 4095);
# However, calling:
#    TLC5940_SetGS(0, TLC5940_GammaCorrect(127)));
# will make the LED appear half as bright as calling:
#    TLC5940_SetGS(0, TLC5940_GammaCorrect(255)));
#
#  0 = Do not store a gamma correction table in PROGMEM
#  1 = Store a gamma correction table in PROGMEM
TLC5940_INCLUDE_GAMMA_CORRECT = 1

# Flag for forced inlining of the SetDC, SetAllDC, and Set4DC
# functions.
#  0 = Force all calls to the Set*DC family of functions to be actual
#      function calls. This option, when used with the -O3 COMPILE
#      flag, often results in smaller code than using -Os.
#  1 = Force all calls to the Set*DC family of functions to be
#      inlined. Use this option if execution speed is critical,
#      possibly at the expense of program size.
TLC5940_INLINE_SETDC_FUNCS = 1

# Flag for forced inlining of the SetGS, SetAllGS, and Set4GS functions.
#  0 = Force all calls to the Set*GS family of functions to be actual
#      function calls.  This option when used with the -O3 COMPILE
#      flag often results in smaller code than using -Os.
#  1 = Force all calls to the Set*GS family of functions to be
#      inlined. Use this option if execution speed is critical,
#      possibly at the expense of program size.
TLC5940_INLINE_SETGS_FUNCS = 1

# Flag to enable multiplexing. This can be used to drive both common
# cathode (preferred), or common anode RGB LEDs, or even way more
# single-color LEDs. Use a P-Channel MOSFET such as an IRF9520, or an
# IRLML9301 (better choice) for each row to be multiplexed.
#  0 = Disable multiplexing; library functions as normal.
#  1 = Enable multiplexing; The gsData array will become
#      two-dimensional, and functions in the Set*GS family require
#      an additional argument (the first) which corresponds to the
#      multiplexed row they operate on.
#
# Tip #3: When multiplexing is enabled, you can actually use a single
#         pin on the AVR to drive both the XLAT and BLANK pins on the
#         TLC5940 if you set XLAT_PIN and BLANK_PIN to the same pin
#         farther down in this file. The multiplexing MOSFETs will keep
#         the LEDs off during initialization, so no garbage will ever
#         be displayed. You still need to connect a 10K pullup resistor
#         between the shared XLAT/BLANK pin and VCC, as the datasheet
#         mandates this for the BLANK pin.
TLC5940_ENABLE_MULTIPLEXING = 1

# TLC5940_MULTIPLEX_N is only defined if:
#     TLC5940_ENABLE_MULTIPLEXING = 1
ifeq ($(TLC5940_ENABLE_MULTIPLEXING), 1)
# Defines the number of rows to be multiplexed
#
# Note: Without writing a custom ISR, that can toggle pins from
#       multiple PORT registers, the maximum number of rows that can
#       be multiplexed is eight.  This option is ignored if
#       TLC5940_ENABLE_MULTIPLEXING = 0
TLC5940_MULTIPLEX_N = 3
endif

# Setting to select among, normal SPI Master mode, USART in MSPIM mode,
# or USI mode to communicate with the TLC5940. Refer to the schematics
# that have -spi-mode-0, -spi-mode-1, or -spi-mode-2 in their filenames
# for details on how to connect the hardware before changing this setting.
# One major advantage of using the USART in MSPIM mode is that its
# transmit register is double-buffered, so you can send data to the
# TLC5940 much faster.
#  0 = Use normal SPI Master mode to communicate with TLC5940 (slower)
#  1 = Use the USART in double-buffered MSPIM mode to communicate with
#      the TLC5940 (faster, but requires the use of different hardware
#      pins)
#  2 = Use the USI (Universal Serial Interface) found on the ATtiny*
#      family of chips.
#
#      Ex: CLOCK = 16000000
#          DEVICE = attiny85
#          FUSES = -U hfuse:w:0xdf:m -U lfuse:w:0xa1:m
#          TLC5940_INCLUDE_DC_FUNCS = 0
#          TLC5940_ISR_CTC_TIMER = 0
#          DCPRG_PIN = GND
#          VPRG_PIN = GND
#          BLANK_PIN = PB3
#          XLAT_PIN = PB0
#
# WARNING: If you change this setting, you must also change your physical
#          hardware configuration to match.
TLC5940_SPI_MODE = 1

# Defines the number of bits used to define a single PWM cycle. The
# default is 12, but it may be lowered to achieve faster refreshes, at
# the expense of the ISR being called more frequently. If
# TLC5940_INCLUDE_GAMMA_CORRECT = 1 then changing TLC5940_PWM_BITS
# will automatically rescale the gamma correction table to use the
# appropriate maximum value, at the expense of precision.
#
#  12 = Normal 12-bit PWM mode. Possible output values between 0-4095
#  11 = 11-bit PWM mode. Possible output values between 0-2047
#  10 = 10-bit PWM mode. Possible output values between 0-1023
#   9 =  9-bit PWM mode. Possible output values between 0-511
#   8 =  8-bit PWM mode. Possible output values between 0-255
#   0 = Manually assign TLC5940_CTC_TOP below
#
# Note: Lowering this value will decrease the amount of time you have
#       in the ISR to send the TLC5940 updated values, potentially
#       limiting the number of devices you can connect in series, and
#       it will decrease the number of cycles available to main(),
#       since the ISR will be called more often. Lowering this value
#       will however, reduce flickering, and will allow for much
#       quicker updates.
TLC5940_PWM_BITS = 12

# If TLC5940_PWM_BITS = 0, this setting allows you to directly choose
# the interrupt interval in steps of 64 clock cycles.
#
# The interrupt will be called every (TLC5940_CTC_TOP + 1) * 64 clock
# cycles, and the output values passed to the Set*GS functions must be
# in the range:
#     0 through ((TLC5940_CTC_TOP + 1) * 64) - 1
#
# Supported values for TCL5940_CTC_TOP range between 3 and 63,
# inclusive, with 3 being equivalent to 8-bit PWM mode (256 clocks),
# and 63 being equivalent to 12-bit PWM mode (4096 clocks).
#
# Note: Lowering this value will decrease the amount of time you have
#       in the ISR to send the TLC5940 updated values, potentially
#       limiting the number of devices you can connect in series, and
#       it will decrease the number of cycles available to main(),
#       since the ISR will be called more often. Lowering this value
#       will however, reduce flickering, and will allow for quicker
#       updates.
ifeq ($(TLC5940_PWM_BITS), 0)
TLC5940_CTC_TOP = 63
endif

# Defines which 8-bit Timer is used to generate the interrupt that
# fires every 2^TLC5940_PWM_BITS (or (TLC5940_CTC_TOP + 1) * 64) clock
# cycles. Useful if you are already using a timer for something else,
# or if you wish to use a particular PWM pin to generate a GSCLK
# signal instead of using CLKO pin for driving GSCLK.
#  0 = 8-bit Timer/Counter0
#  2 = 8-bit Timer/Counter2
TLC5940_ISR_CTC_TIMER = 0

# Determines whether or not GPIOR0 is used to store flags. This
# special-purpose register is designed to store bit flags, as it can
# set, clear or test a single bit in only 2 clock cycles. You should
# definitely use this if you can, as the library will be smaller,
# faster, and use less RAM.
#
# Note: If enabled, you must make sure that the flag bits assigned
#       below do not conflict with any other GPIOR0 flag bits your
#       application might use.
TLC5940_USE_GPIOR0 = 1

# TLC5940_USE_GPIOR1 is only defined if TLC5940_ENABLE_MULTIPLEXING = 1
ifeq ($(TLC5940_ENABLE_MULTIPLEXING), 1)
# Determines whether or not GPIOR1 is used to store the current
# multiplexing row. This special-purpose register is faster to access
# than a variable in RAM. You should definitely use this if you can,
# as the library will be smaller, faster, and use less RAM.
#
# Note: If enabled, you must make sure that no other part of your
#       application uses the GPIOR1 register for anything
#       else.
TLC5940_USE_GPIOR1 = 1
endif

# GPIOR0 flag bits are only defined if:
#     TLC5940_USE_GPIOR0 = 1
ifeq ($(TLC5940_USE_GPIOR0), 1)
TLC5940_FLAG_GS_UPDATE = 0

ifeq ($(TLC5940_ENABLE_MULTIPLEXING), 0)
TLC5940_FLAG_XLAT_NEEDS_PULSE = 1

endif
endif

# When BLANK is high, all outputs of the TLC5940 chip(s) will be
# disabled, and when BLANK is low, all outputs will be enabled. There
# must be an external 10K pull-up resistor attached to this pin. Choose
# this pin assignment wisely, so that during ICSP programming, BLANK
# remains high to keep the outputs disabled.
#
# WARNING: For an ATtiny85, when TLC5940_SPI_MODE = 2, BLANK_PIN
#          should be assigned to PB3 so the outputs are blanked during
#          programming.
#
# Note: The library is extra-optimized when BLANK and XLAT are
#       configured to be pins from the same PORT. Additionally, if
#       TLC5940_ENABLE_MULTIPLEXING = 1, you can assign the same PIN
#       to both BLANK and XLAT with no loss in functionality. If you
#       wish to do this, be sure that both BLANK and XLAT are configured
#       with the same DDR, PORT, INPUT, and PIN settings.
BLANK_DDR = DDRC
BLANK_PORT = PORTC
BLANK_INPUT = PINC
BLANK_PIN = PC3

# DDR, PORT, and PIN connected to XLAT.
# Note: The library is extra-optimized when BLANK and XLAT are
#       configured to be pins from the same PORT, or if multiplexing,
#       when BLANK and XLAT are actually the same pin (see above).
XLAT_DDR = DDRC
XLAT_PORT = PORTC
XLAT_INPUT = PINC
XLAT_PIN = PC3

# You may disable programmable dot correction support entirely (and
# drive the TLC5940 using two fewer pins!) by setting DCPRG_PIN = GND
# and VPRG_PIN = GND below, and hardwiring the TLC5940's DCPRG and
# VPRG pins directly to GND. If you do this, then the TLC5940 will use
# the dot correction values stored in its internal EEPROM.
#
# Alternatively, you may disable EEPROM dot correction support
# entirely (and drive the TLC5940 using one fewer pin) by setting
# DCPRG_PIN = VCC and VPRG_PIN to a pin on the AVR, and hardwiring
# the TLC5940's DCPRG pin directly to VCC. If you do this, then the
# TLC5940 will always require dot correction values to be loaded
# programatically, after TLC5940_Init() is called. To programatically
# load the dot correction values, you may call one or more functions
# from the TLC5940_Set*DC() family of functions, followed by the
# TLC5940_ClockInDC() function.
#
# Note: To drive a TLC5944 (which does not have a DCPRG pin), you
#       should set DCPRG_PIN = VCC

# DDR, PORT, and PIN connected to DCPRG. If DCPRG is hardwired to
# GND (see above), then specify GND for DCPRG_PIN, or if DCPRG is
# hardwired to VCC (see above), then specify VCC for DCPRG_PIN.
# If DCPRG_PIN equals GND or VCC, both DCPRG_DDR and DCPRG_PORT
# will be ignored.
DCPRG_DDR = DDRD
DCPRG_PORT = PORTD
DCPRG_PIN = VCC

# DDR, PORT, and PIN connected to VPRG. If VPRG is hardwired to GND
# (see above), then specify GND for VPRG_PIN. If VPRG_PIN equals
# GND, both VPRG_DDR and VPRG_PORT will be ignored.
VPRG_DDR = DDRD
VPRG_PORT = PORTD
VPRG_PIN = PD0

ifeq ($(TLC5940_ENABLE_MULTIPLEXING), 1)
# DDR, PORT, and PIN registers used for driving the gate of P-channel
# MOSFETs. I have had okay luck using the IRF9520, but the IRLML9301
# performs much better.
#
# Note: All pins used for multiplexing must share the same DDR, PORT,
#       and PIN registers. These options are ignored if
#       TLC5940_ENABLE_MULTIPLEXING = 0
MULTIPLEX_DDR = DDRC
MULTIPLEX_PORT = PORTC
MULTIPLEX_INPUT = PINC

# List of PIN names of pins that are connected to the multiplexing
# MOSFETs. You can define up to eight unless you use a custom ISR that
# can toggle PINs on multiple PORTs.
#
# Note: All pins used for multiplexing must share the same DDR, PORT,
#       and PIN registers. Any pins defined beyond TLC5940_MULTIPLEX_N
#       will be ignored.
ROW0_PIN = PC0
ROW1_PIN = PC1
ROW2_PIN = PC2
ROW3_PIN = PC3
ROW4_PIN = PC4
ROW5_PIN = PC5
ROW6_PIN =
ROW7_PIN =
endif

# Some of the variable names got changed inside the library, but to remain
# compatible with existing code, the old variable names have become macros
# for the new variable names.
#
# Feel free to delete each backwards compatible variable mapping after
# you have updated your application to use its new name. Once all the
# variable mappings are deleted, then you should delete the
# TLC5940_BACKWARDS_COMPATIBLE_DEFINES variable itself below.
TLC5940_BACKWARDS_COMPATIBLE_DEFINES = \
-DgsDataSize=TLC5940_GRAYSCALE_BYTES \
-DnumChannels=TLC5940_CHANNELS_N \
-DdcDataSize=TLC5940_DOT_CORRECTION_BYTES

# ---------- End TLC5940 Configuration Section ----------

# ---------- DO NOT MODIFY BELOW THIS LINE ----------

ifeq ($(VPRG_PIN),GND)
ifeq ($(DCPRG_PIN),GND)
TLC5940_VPRG_DCPRG_HARDWIRED_TO_GND = 1
endif
endif

ifeq ($(DCPRG_PIN),VCC)
ifneq ($(VPRG_PIN),GND)
TLC5940_DCPRG_HARDWIRED_TO_VCC = 1
else
$(warning @@@@@@@@@@@@@@@@@@@@@@@@@@ PIN CONFLICT ERROR @@@@@@@@@@@@@@@@@@@@@@@@@@@)
$(warning @ When DCPRG_PIN = VCC, then dot correction data can only come from the)
$(warning @ DC register, therefore VPRG_PIN cannot also be set to GND, because that)
$(warning @ would make it impossible to even enter DC mode.)
$(warning @)
$(warning @ To get rid of this error, either assign VPRG_PIN to an actual pin on)
$(warning @ the AVR so both dot correction data and grayscale data can be entered,)
$(warning @ or set both VPRG_PIN and DCPRG_PIN to GND to always use dot correction)
$(warning @ values from the TLC5940's EEPROM, and only allow grayscale data to be)
$(warning @ entered. Whichever you choose, remember to also change your physical)
$(warning @ hardware configuration to match!)
$(warning @@@@@@@@@@@@@@@@@@@@@@@@@@ PIN CONFLICT ERROR @@@@@@@@@@@@@@@@@@@@@@@@@@@)
endif
endif

ifeq ($(BLANK_PIN), $(XLAT_PIN))
TLC5940_XLAT_AND_BLANK_HARDWIRED_TOGETHER = 1
endif

# Assign sane defaults, if these variables have not been set
TLC5940_VPRG_DCPRG_HARDWIRED_TO_GND ?= 0
TLC5940_DCPRG_HARDWIRED_TO_VCC ?= 0
TLC5940_XLAT_AND_BLANK_HARDWIRED_TOGETHER ?= 0

# These following chunk of defines are what allow the library to
# automatically determine which extra optimizations can be enabled
# when certain pins share the same PORT. These comparisons needed to
# be done before macro-expansion, so that's why they are here and not
# in the library itself. Do not modify them!
ifeq ($(BLANK_INPUT), $(XLAT_INPUT))
TLC5940_BLANK_AND_XLAT_SHARE_PORT = 1
else
TLC5940_BLANK_AND_XLAT_SHARE_PORT = 0
endif
ifeq ($(TLC5940_XLAT_AND_BLANK_HARDWIRED_TOGETHER), 1)
TLC5940_BLANK_AND_XLAT_SHARE_PORT = 1
endif
ifeq ($(TLC5940_ENABLE_MULTIPLEXING), 1)
ifeq ($(MULTIPLEX_INPUT), $(XLAT_INPUT))
TLC5940_MULTIPLEX_AND_XLAT_SHARE_PORT = 1
else
TLC5940_MULTIPLEX_AND_XLAT_SHARE_PORT = 0
endif
else
TLC5940_MULTIPLEX_AND_XLAT_SHARE_PORT = 0
endif

# This avoids adding needless defines if TLC5940_USE_GPIOR0 = 0
ifeq ($(TLC5940_USE_GPIOR0), 1)
TLC5940_GPIOR0_DEFINES = -DTLC5940_FLAG_GS_UPDATE=$(TLC5940_FLAG_GS_UPDATE)
ifeq ($(TLC5940_ENABLE_MULTIPLEXING), 0)
TLC5940_GPIOR0_DEFINES += -DTLC5940_FLAG_XLAT_NEEDS_PULSE=$(TLC5940_FLAG_XLAT_NEEDS_PULSE)
endif
endif

# This avoids adding a needless define if TLC5940_PWM_BITS = 0
ifeq ($(TLC5940_PWM_BITS), 0)
TLC5940_CTC_TOP_DEFINE = -DTLC5940_CTC_TOP=$(TLC5940_CTC_TOP)
endif

ifeq ($(TLC5940_XLAT_AND_BLANK_HARDWIRED_TOGETHER), 0)
TLC5940_BLANK_DEFINES = -DBLANK_DDR=$(BLANK_DDR) \
                        -DBLANK_PORT=$(BLANK_PORT) \
                        -DBLANK_INPUT=$(BLANK_INPUT) \
                        -DBLANK_PIN=$(BLANK_PIN)
endif

# This avoids adding needless defines if TLC5940_VPRG_DCPRG_HARDWIRED_TO_GND = 1
ifeq ($(TLC5940_VPRG_DCPRG_HARDWIRED_TO_GND), 0)
TLC5940_VPRG_DEFINES = -DVPRG_DDR=$(VPRG_DDR) \
                       -DVPRG_PORT=$(VPRG_PORT) \
                       -DVPRG_PIN=$(VPRG_PIN)
endif

# This avoids adding needless defines if TLC5940_VPRG_DCPRG_HARDWIRED_TO_GND = 1
# or if TLC5940_DCPRG_HARDWIRED_TO_VCC = 1
ifeq ($(TLC5940_VPRG_DCPRG_HARDWIRED_TO_GND), 0)
ifeq ($(TLC5940_DCPRG_HARDWIRED_TO_VCC), 0)
TLC5940_DCPRG_DEFINES = -DDCPRG_DDR=$(DCPRG_DDR) \
                        -DDCPRG_PORT=$(DCPRG_PORT) \
                        -DDCPRG_PIN=$(DCPRG_PIN)
endif
endif

# This avoids adding needless defines if TLC5940_ENABLE_MULTIPLEXING = 0
ifeq ($(TLC5940_ENABLE_MULTIPLEXING), 1)
TLC5940_MULTIPLEXING_DEFINES = -DTLC5940_MULTIPLEX_N=$(TLC5940_MULTIPLEX_N) \
                               -DTLC5940_USE_GPIOR1=$(TLC5940_USE_GPIOR1) \
                               -DMULTIPLEX_DDR=$(MULTIPLEX_DDR) \
                               -DMULTIPLEX_PORT=$(MULTIPLEX_PORT) \
                               -DMULTIPLEX_INPUT=$(MULTIPLEX_INPUT) \
                               -DROW0_PIN=$(ROW0_PIN) \
                               -DROW1_PIN=$(ROW1_PIN) \
                               -DROW2_PIN=$(ROW2_PIN) \
                               -DROW3_PIN=$(ROW3_PIN) \
                               -DROW4_PIN=$(ROW4_PIN) \
                               -DROW5_PIN=$(ROW5_PIN) \
                               -DROW6_PIN=$(ROW6_PIN) \
                               -DROW7_PIN=$(ROW7_PIN)
endif

ifeq ($(TLC5940_SPI_MODE), 0)
$(warning @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ PB4 WARNING @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@)
$(warning @ The pin PB4 will automatically be set as an input pin by the Master)
$(warning @ SPI hardware, because TLC5940_SPI_MODE = 0.)
$(warning @)
$(warning @ This is a hardware override, and thus cannot be avoided, but you)
$(warning @ should be able to use PB4 as an input for something else in your)
$(warning @ application, because the library does not actually receive data on this)
$(warning @ pin.)
$(warning @)
$(warning @ This warning will remain as long as TLC5940_SPI_MODE = 0.)
$(warning @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ PB4 WARNING @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@)
ifneq ($(BLANK_PIN), PB2)
ifneq ($(XLAT_PIN), PB2)
ifneq ($(DCPRG_PIN), PB2)
ifneq ($(VPRG_PIN), PB2)
TLC5940_PB2_UNMAPPED = 1
$(warning @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ PB2 WARNING @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@)
$(warning @ TLC5940_SPI_MODE = 0, but no pin from this library is mapped to PB2!)
$(warning @)
$(warning @ This is allowed, but the library must still set PB2 as an output pin)
$(warning @ to remain in Master SPI mode (read: functional).)
$(warning @)
$(warning @ It is strongly recommended that you map either BLANK, XLAT, DCPRG, or)
$(warning @ VPRG to PB2 to avoid an accidental short.)
$(warning @)
$(warning @ You may also map something else in your project to PB2, as long)
$(warning @ as it is only ever used as an output pin, but this warning will remain.)
$(warning @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ PB2 WARNING @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@)
endif
endif
endif
endif
endif

ifeq ($(TLC5940_VPRG_DCPRG_HARDWIRED_TO_GND), 1)
ifeq ($(TLC5940_INCLUDE_DC_FUNCS), 1)
$(warning @@@@@@@@@@@@@@@@@@@ TLC5940_INCLUDE_DC_FUNCS WARNING @@@@@@@@@@@@@@@@@@@@)
$(warning @ Your configuration of TLC5940_INCLUDE_DC_FUNCS = 1 has been overridden)
$(warning @ and will be changed to TLC5940_INCLUDE_DC_FUNCS = 0, because you)
$(warning @ indicated that VPRG and DCPRG are hardwired to GND.)
$(warning @)
$(warning @ With the hardware configured this way, the TLC5940 can only use the dot)
$(warning @ correction values stored in its EEPROM, so all dot correction related)
$(warning @ functions have been disabled.)
$(warning @)
$(warning @ To prevent this warning from being displayed, you should explicitly set)
$(warning @ TLC5940_INCLUDE_DC_FUNCS = 0)
$(warning @@@@@@@@@@@@@@@@@@@ TLC5940_INCLUDE_DC_FUNCS WARNING @@@@@@@@@@@@@@@@@@@@)
TLC5940_INCLUDE_DC_FUNCS = 0
endif
endif

ifeq ($(TLC5940_DCPRG_HARDWIRED_TO_VCC), 1)
ifeq ($(TLC5940_INCLUDE_DC_FUNCS), 0)
$(warning @@@@@@@@@@@@@@@@@@@ TLC5940_INCLUDE_DC_FUNCS WARNING @@@@@@@@@@@@@@@@@@@@)
$(warning @ Your configuration of TLC5940_INCLUDE_DC_FUNCS = 0 has been overridden)
$(warning @ and will be changed to TLC5940_INCLUDE_DC_FUNCS = 1, because you)
$(warning @ indicated that DCPRG is hardwired to VCC.)
$(warning @)
$(warning @ With the hardware configured this way, it is impossible for the TLC5940)
$(warning @ to use the dot correction data stored in its EEPROM, and so dot)
$(warning @ correction values must be sent from the AVR to the TLC5940 after)
$(warning @ initialization using the Set*DC family of functions followed by a call)
$(warning @ to ClockInDC. In order to do that, those functions must not only be)
$(warning @ included, but also called by your application.)
$(warning @)
$(warning @ To prevent this warning from being displayed, you should explicitly set)
$(warning @ TLC5940_INCLUDE_DC_FUNCS = 1, and be sure to call those functions.)
$(warning @@@@@@@@@@@@@@@@@@@ TLC5940_INCLUDE_DC_FUNCS WARNING @@@@@@@@@@@@@@@@@@@@)
TLC5940_INCLUDE_DC_FUNCS = 1
endif
endif

# This avoids adding a needless define if TLC5940_INCLUDE_DC_FUNCS = 0
ifeq ($(TLC5940_INCLUDE_DC_FUNCS), 1)
TLC5940_INLINE_SETDC_FUNCS_DEFINE = -DTLC5940_INLINE_SETDC_FUNCS=$(TLC5940_INLINE_SETDC_FUNCS)
endif

ifeq ($(TLC5940_PB2_UNMAPPED), 1)
TLC5940_PB2_UNMAPPED_DEFINE = -DTLC5940_PB2_UNMAPPED=$(TLC5940_PB2_UNMAPPED)
endif

# This line integrates all options into a single flag called:
#     $(TLC5940_DEFINES)
# which should be appended to the definition of COMPILE in the Makefile
TLC5940_DEFINES = -D__DELAY_BACKWARD_COMPATIBLE__ \
                  -DTLC5940_N=$(TLC5940_N) \
                  -DTLC5940_INCLUDE_DC_FUNCS=$(TLC5940_INCLUDE_DC_FUNCS) \
                  -DTLC5940_VPRG_DCPRG_HARDWIRED_TO_GND=$(TLC5940_VPRG_DCPRG_HARDWIRED_TO_GND) \
                  -DTLC5940_DCPRG_HARDWIRED_TO_VCC=$(TLC5940_DCPRG_HARDWIRED_TO_VCC) \
                  -DTLC5940_INCLUDE_SET4_FUNCS=$(TLC5940_INCLUDE_SET4_FUNCS) \
                  -DTLC5940_INCLUDE_DEFAULT_ISR=$(TLC5940_INCLUDE_DEFAULT_ISR) \
                  -DTLC5940_INCLUDE_GAMMA_CORRECT=$(TLC5940_INCLUDE_GAMMA_CORRECT) \
                  $(TLC5940_INLINE_SETDC_FUNCS_DEFINE) \
                  -DTLC5940_INLINE_SETGS_FUNCS=$(TLC5940_INLINE_SETGS_FUNCS) \
                  -DTLC5940_ENABLE_MULTIPLEXING=$(TLC5940_ENABLE_MULTIPLEXING) \
                  -DTLC5940_MULTIPLEX_AND_XLAT_SHARE_PORT=$(TLC5940_MULTIPLEX_AND_XLAT_SHARE_PORT) \
                  $(TLC5940_MULTIPLEXING_DEFINES) \
                  -DTLC5940_SPI_MODE=$(TLC5940_SPI_MODE) \
                  -DTLC5940_PWM_BITS=$(TLC5940_PWM_BITS) \
                  $(TLC5940_CTC_TOP_DEFINE) \
                  -DTLC5940_USE_GPIOR0=$(TLC5940_USE_GPIOR0) \
                  $(TLC5940_BLANK_DEFINES) \
                  $(TLC5940_VPRG_DEFINES) \
                  $(TLC5940_DCPRG_DEFINES) \
                  $(TLC5940_GPIOR0_DEFINES) \
                  -DXLAT_DDR=$(XLAT_DDR) \
                  -DXLAT_PORT=$(XLAT_PORT) \
                  -DXLAT_INPUT=$(XLAT_INPUT) \
                  -DXLAT_PIN=$(XLAT_PIN) \
                  -DTLC5940_BLANK_AND_XLAT_SHARE_PORT=$(TLC5940_BLANK_AND_XLAT_SHARE_PORT) \
                  -DTLC5940_XLAT_AND_BLANK_HARDWIRED_TOGETHER=$(TLC5940_XLAT_AND_BLANK_HARDWIRED_TOGETHER) \
                  $(TLC5940_PB2_UNMAPPED_DEFINE) \
                  $(TLC5940_BACKWARDS_COMPATIBLE_DEFINES)
