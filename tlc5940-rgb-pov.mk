# ---------- Begin TLC5940 Configuration Section ----------

# Defines the number of TLC5940 chips that are connected in series
TLC5940_N = 4

# Flag for whether the VPRG and DCPRG pins on the TLC5940 are
# hardwired to GND. This uses two fewer pins on the AVR, but the dot
# correction values will always (and can only!) be read from the
# TLC5940's EEPROM.
#  0 = The VPRG and DCPRG pins on the TLC5940 are not hardwired to
#      GND, and are connected to two pins of the AVR that are defined
#      later in this makefile. By default the dot correction values will
#      be read from the TLC5940's EEPROM, but this setting allows the
#      AVR to override the EEPROM defaults during initialization using
#      the Set*DC family of functions followed by a call to ClockInDC.
#  1 = The VPRG and DCPRG inputs on the TLC5940 are both hardwired to
#      GND (disabling programmable dot correction mode), and forces the
#      dot correction values to be read in from the TLC5940's EEPROM.
#
# WARNING: Do not change this option without also changing how the
#          physical hardware is wired!
TLC5940_VPRG_DCPRG_HARDWIRED_TO_GND = 0

# TLC5940_DCPRG_HARDWIRED_TO_VCC is only defined if:
#     TLC5940_VPRG_DCPRG_HARDWIRED_TO_GND = 0
# Flag for whether the DCPRG pin on the TLC5940 is hardwired to VCC.
# This uses one fewer pin on the AVR, but the dot correction values
# will always need to (and can only!) be set manually using the
# Set*DC family of functions, followed by a call to the ClockInDC
#  0 = The VPRG pin on the TLC5940 is not hardwired to VCC, and is
#      connected to a pin on the AVR that is defined later in this
#      makefile. By default the dot correction values will be read
#      from the TLC5940's EEPROM, but this setting allows the AVR to
#      override the EEPROM defaults during initialization using the
#      Set*DC family of functions followed by a call to ClockInDC.
#  1 = The DCPRG input on the TLC5940 is hardwired to VCC (disabling
#      reading them from the TLC5940's EEPROM), and requires the dot
#      correction values to be programmed manually by the AVR.
#
# Note: If you are using this TLC5940 library to drive a TLC5944
#       (which does not have a DCPRG pin), you should also set this
#       flag to 1.
#
# WARNING: Do not change this option without also changing how the
#          physical hardware is wired!
ifeq ($(TLC5940_VPRG_DCPRG_HARDWIRED_TO_GND), 0)
TLC5940_DCPRG_HARDWIRED_TO_VCC = 1
endif

# Flag for including functions for manually setting the dot correction
#  0 = Do not include dot correction features (generates smaller code)
#  1 = Include dot correction features (will still read from EEPROM by
#      default)
#
# Note: If TLC5940_VPRG_DCPRG_HARDWIRED_TO_GND = 1, that will force
#       this setting to 0, since there would be no way to
#       programmatically set the dot correction data. Conversely,
#       if TLC5940_DCPRG_HARDWIRED_TO_VCC = 1, that will force this
#       setting to 1, since there would be no way for the TLC5940 to
#       read dot correction values from its EEPROM.
TLC5940_INCLUDE_DC_FUNCS = 1

# Flag for including efficient functions for setting the grayscale
# (and optionally dot correction) values of four channels at once.
#  0 = Do not include functions for ganging outputs in groups of four
#  1 = Include functions for ganging outputs in groups of four

# Note: Any number of outputs can be ganged together at any time by
#       simply connecting them together. These function only provide a
#       more efficient way of setting the values if outputs 0-3, 4-7,
#       8-11, 12-15, ... are connected together
TLC5940_INCLUDE_SET4_FUNCS = 0

# Flag for including a default implementation of the ISR.
#  0 = For advanced users only! Only choose this if you want to
#      override the default implementation of the
#      ISR(TIMER0_COMPA_vect) with your own custom implemetation
#      inside main.c
#  1 = Most users should use this setting. Use the default
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
#    TLC5940_SetGS(0, pgm_read_word(&TLC5940_GammaCorrect[127]));
# will make the LED appear half as bright as calling:
#    TLC5940_SetGS(0, pgm_read_word(&TLC5940_GammaCorrect[255]));
#
#  0 = Do not store a gamma correction table in flash memory
#  1 = Stores a gamma correction table in flash memory
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
# IRLML9301 (better) for each row to be multiplexed.
#  0 = Disable multiplexing; library functions as normal.
#  1 = Enable multiplexing; The gsData array will become
#      two-dimensional, and functions in the Set*GS family require
#      another argument which corresponds to the multiplexed row they
#      operate on.
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

# TLC5940_XLAT_AND_BLANK_HARDWIRED_TOGETHER is only defined if:
#     TLC5940_ENABLE_MULTIPLEXING = 1
# When multiplexing, you don't actually need to run a separate wire to
# the BLANK pin of the TLC5940, as long as you connect its BLANK and
# XLAT pins together. The multiplexing MOSFETs will keep the LEDs off
# during initialization, so no garbage will ever be displayed. You
# still need to connect a 10K pullup resistor between the shared
# XLAT/BLANK and VCC, as the datasheet mandates this for the BLANK
# pin.
#
# WARNING: Before you change this option, you must wire the chip up
#          differently!
TLC5940_XLAT_AND_BLANK_HARDWIRED_TOGETHER = 1
endif

# Setting to select among, Normal SPI Master mode, USART in MSPIM
# mode, or USI mode to communicate with the TLC5940. One major
# advantage of using the USART in MSPIM mode is that the transmit
# register is double-buffered, so you can send data to the TLC5940
# much faster. Refer to schematics ending in _usart_mspim for details
# on how to connect the hardware before changing this mode to 1.
#  0 = Use normal SPI Master mode to communicate with TLC5940 (slower)
#  1 = Use the USART in double-buffered MSPIM mode to communicate with
#      the TLC5940 (faster, but requires the use of different hardware
#      pins)
#  2 = Use the USI (Universal Serial Interface) found on the ATtiny*
#      family of chips.
#
#      Ex: DEVICE = attiny85
#          FUSES = (use fuse bits for ATtiny85 with clock out enabled)
#          TLC5940_INCLUDE_DC_FUNCS = 0
#          TLC5940_VPRG_DCPRG_HARDWIRED_TO_GND = 1
#          TLC5940_ISR_CTC_TIMER = 0
#          BLANK_PIN = PB3 (so LEDs are off while programming)
#          XLAT_PIN = PB0 (since this is the only free pin left)
#
# WARNING: Before you change this option, you must wire the chip up
#          differently, and/or switch chips!
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

# This setting allows you to directly choose the interrupt interval in
# steps of 64 clock cycles, if TLC5940_PWM_BITS = 0
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
# should be an external 10K pull-up resistor attached to this pin, but
# the pin value be chosen carefully, such that during ICSP
# programming, BLANK remains high to keep the outputs disabled.
#
# WARNING: For an ATtiny85, when TLC5940_SPI_MODE = 2, BLANK_PIN
#          should be PB3 so the outputs are blanked during programming.
#
# Note: The library is extra-optimized when BLANK and XLAT are
#       configured to be pins from the same PORT.
#
# Super-optimization: When TLC5940_ENABLE_MULTIPLEXING = 1, you don't
# even need to use a pin to drive BLANK, if you hardwire the BLANK and
# XLAT pins on the TLC5940 together and set the
# TLC5940_XLAT_AND_BLANK_HARDWIRED_TOGETHER flag above. Note, you'll
# still need to use an external 10K pullup resistor on the shared
# XLAT/BLANK line.
ifneq ($(TLC5940_XLAT_AND_BLANK_HARDWIRED_TOGETHER), 1)
BLANK_DDR = DDRD
BLANK_PORT = PORTD
BLANK_INPUT = PIND
BLANK_PIN = PD5
endif

# DDR, PORT, and PIN connected to XLAT (always configurable)
#
# Note: The library is extra-optimized when BLANK and XLAT are
#       configured to be pins from the same PORT.
XLAT_DDR = DDRC
XLAT_PORT = PORTC
XLAT_INPUT = PINC
XLAT_PIN = PC3

# VPRG and DCPRG are only defined if:
#     TLC5940_VPRG_DCPRG_HARDWIRED_TO_GND = 0
ifneq ($(TLC5940_VPRG_DCPRG_HARDWIRED_TO_GND), 1)
# DCPRG is only defined if TLC5940_DCPRG_HARDWIRED_TO_VCC = 0
ifneq ($(TLC5940_DCPRG_HARDWIRED_TO_VCC), 1)
# DDR, PORT, and PIN connected to DCPRG
DCPRG_DDR = DDRD
DCPRG_PORT = PORTD
DCPRG_PIN = PD3
endif

# DDR, PORT, and PIN connected to VPRG
VPRG_DDR = DDRD
VPRG_PORT = PORTD
VPRG_PIN = PD0
endif

ifeq ($(TLC5940_ENABLE_MULTIPLEXING), 1)
# DDR, PORT, and PIN registers used for driving P-channel multiplexing
# MOSFETs. I have had good luck using the IRF9520, but the IRLML9301
# performed much better.
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
# Note: All pins used for multiplexing must share the same DDR, PORT,
#       and PIN registers.
# Don't worry, any pins defined beyond TLC5940_MULTIPLEX_N will be
# ignored.
ROW0_PIN = PC0
ROW1_PIN = PC1
ROW2_PIN = PC2
ROW3_PIN = PC3
ROW4_PIN = PC4
ROW5_PIN = PC5
ROW6_PIN =
ROW7_PIN =
endif

# Feel free to delete each backwards compatible variable mapping after
# you have updated your application to use its new name. After you have
# updated (and deleted) every variable mapping, then you should also
# delete the BACKWARDS_COMPATIBLE_DEFINES variable itself below.
BACKWARDS_COMPATIBLE_DEFINES = \
-DgsDataSize=TLC5940_GRAYSCALE_BYTES \
-DnumChannels=TLC5940_CHANNELS_N \
-DdcDataSize=TLC5940_DOT_CORRECTION_BYTES

# ---------- End TLC5940 Configuration Section ----------

# ---------- DO NOT MODIFY BELOW THIS LINE ----------

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
BLANK_AND_XLAT_SHARE_PORT = 1
else
BLANK_AND_XLAT_SHARE_PORT = 0
endif
ifeq ($(TLC5940_XLAT_AND_BLANK_HARDWIRED_TOGETHER), 1)
BLANK_AND_XLAT_SHARE_PORT = 1
endif
ifeq ($(TLC5940_ENABLE_MULTIPLEXING), 1)
ifeq ($(MULTIPLEX_INPUT), $(XLAT_INPUT))
MULTIPLEX_AND_XLAT_SHARE_PORT = 1
else
MULTIPLEX_AND_XLAT_SHARE_PORT = 0
endif
else
MULTIPLEX_AND_XLAT_SHARE_PORT = 0
endif

# This avoids adding needless defines if TLC5940_USE_GPIOR0 = 0
ifeq ($(TLC5940_USE_GPIOR0), 1)
TLC5940_GPIOR0_DEFINES = -DTLC5940_FLAG_GS_UPDATE=$(TLC5940_FLAG_GS_UPDATE) \
                         -DTLC5940_FLAG_XLAT_NEEDS_PULSE=$(TLC5940_FLAG_XLAT_NEEDS_PULSE)
endif

ifeq ($(TLC5940_PWM_BITS), 0)
TLC5940_CTC_TOP_DEFINE = -DTLC5940_CTC_TOP=$(TLC5940_CTC_TOP)
endif

ifeq ($(TLC5940_XLAT_AND_BLANK_HARDWIRED_TOGETHER), 0)
BLANK_DEFINES = -DBLANK_DDR=$(BLANK_DDR) \
                -DBLANK_PORT=$(BLANK_PORT) \
                -DBLANK_INPUT=$(BLANK_INPUT) \
                -DBLANK_PIN=$(BLANK_PIN)
endif

# This avoids adding needless defines if TLC5940_VPRG_DCPRG_HARDWIRED_TO_GND = 1
ifeq ($(TLC5940_VPRG_DCPRG_HARDWIRED_TO_GND), 0)
VPRG_DEFINES = -DVPRG_DDR=$(VPRG_DDR) \
               -DVPRG_PORT=$(VPRG_PORT) \
               -DVPRG_PIN=$(VPRG_PIN)
endif

# This avoids adding needless defines if TLC5940_VPRG_DCPRG_HARDWIRED_TO_GND = 1
# or if TLC5940_DCPRG_HARDWIRED_TO_VCC = 1
ifeq ($(TLC5940_VPRG_DCPRG_HARDWIRED_TO_GND), 0)
ifeq ($(TLC5940_DCPRG_HARDWIRED_TO_VCC), 0)
DCPRG_DEFINES = -DDCPRG_DDR=$(DCPRG_DDR) \
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
$(warning @ indicated that VPRG and DCPRG are hardwired to GND by setting)
$(warning @ TLC5940_VPRG_DCPRG_HARDWIRED_TO_GND = 1)
$(warning @)
$(warning @ With the hardware configured this way, it is impossible for the TLC5940)
$(warning @ to receive dot correction data, and so it must use the values stored in)
$(warning @ its EEPROM.)
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
$(warning @ indicated that DCPRG is hardwired to VCC by setting)
$(warning @ TLC5940_DCPRG_HARDWIRED_TO_VCC = 1)
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

ifeq ($(TLC5940_PB2_UNMAPPED), 1)
TLC5940_PB2_UNMAPPED_DEFINE = -DTLC5940_PB2_UNMAPPED=$(TLC5940_PB2_UNMAPPED)
endif

# This line integrates all options into a single flag called:
#     $(TLC5940_DEFINES)
# which should be appended to the definition of COMPILE in the Makefile
TLC5940_DEFINES = -DTLC5940_N=$(TLC5940_N) \
                  -DTLC5940_INCLUDE_DC_FUNCS=$(TLC5940_INCLUDE_DC_FUNCS) \
                  -DTLC5940_VPRG_DCPRG_HARDWIRED_TO_GND=$(TLC5940_VPRG_DCPRG_HARDWIRED_TO_GND) \
                  -DTLC5940_DCPRG_HARDWIRED_TO_VCC=$(TLC5940_DCPRG_HARDWIRED_TO_VCC) \
                  -DTLC5940_INCLUDE_SET4_FUNCS=$(TLC5940_INCLUDE_SET4_FUNCS) \
                  -DTLC5940_INCLUDE_DEFAULT_ISR=$(TLC5940_INCLUDE_DEFAULT_ISR) \
                  -DTLC5940_INCLUDE_GAMMA_CORRECT=$(TLC5940_INCLUDE_GAMMA_CORRECT) \
                  -DTLC5940_INLINE_SETDC_FUNCS=$(TLC5940_INLINE_SETDC_FUNCS) \
                  -DTLC5940_INLINE_SETGS_FUNCS=$(TLC5940_INLINE_SETGS_FUNCS) \
                  -DTLC5940_ENABLE_MULTIPLEXING=$(TLC5940_ENABLE_MULTIPLEXING) \
                  -DMULTIPLEX_AND_XLAT_SHARE_PORT=$(MULTIPLEX_AND_XLAT_SHARE_PORT) \
                  $(TLC5940_MULTIPLEXING_DEFINES) \
                  -DTLC5940_SPI_MODE=$(TLC5940_SPI_MODE) \
                  -DTLC5940_PWM_BITS=$(TLC5940_PWM_BITS) \
                  $(TLC5940_CTC_TOP_DEFINE) \
                  -DTLC5940_USE_GPIOR0=$(TLC5940_USE_GPIOR0) \
                  $(BLANK_DEFINES) \
                  $(VPRG_DEFINES) \
                  $(DCPRG_DEFINES) \
                  $(TLC5940_GPIOR0_DEFINES) \
                  -DXLAT_DDR=$(XLAT_DDR) \
                  -DXLAT_PORT=$(XLAT_PORT) \
                  -DXLAT_INPUT=$(XLAT_INPUT) \
                  -DXLAT_PIN=$(XLAT_PIN) \
                  -DBLANK_AND_XLAT_SHARE_PORT=$(BLANK_AND_XLAT_SHARE_PORT) \
                  -DTLC5940_XLAT_AND_BLANK_HARDWIRED_TOGETHER=$(TLC5940_XLAT_AND_BLANK_HARDWIRED_TOGETHER) \
                  $(TLC5940_PB2_UNMAPPED_DEFINE) \
                  $(BACKWARDS_COMPATIBLE_DEFINES)
