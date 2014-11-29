# ---------- Begin TLC5940 Configuration Section ----------

# Defines the number of TLC5940 chips that are connected in series
TLC5940_N = 1

# Flag for including variables/functions for manually setting the dot correction
#  0 = Do not include dot correction features (generates smaller code)
#  1 = Include dot correction features (will still read from EEPROM by default)
TLC5940_INCLUDE_DC_FUNCS = 0

# Flag for whether VPRG and DCPRG are hardwired to GND (uses two less pins)
#  0 = The VPRG and DCPRG pins must be defined on the AVR and
#      connected to the corresponding pins on the TLC5940.
#  1 = The VPRG and DCPRG inputs on the TLC5940 must be hardwired to
#      GND, and TLC5940_INCLUDE_DC_FUNCS must be set to 0 (disables
#      dot correction mode).
# WARNING: Before you enable this option, you must wire the chip up differently!
TLC5940_VPRG_DCPRG_HARDWIRED_TO_GND = 1

# Flag for including efficient functions for setting the grayscale
# (and optionally dot correction) values of four channels at once.
#  0 = Do not include functions for ganging outputs in groups of four
#  1 = Include functions for ganging outputs in groups of four
# Note: Any number of outputs can be ganged together at any time by simply
#       connecting them together. These function only provide a more efficient
#       way of setting the values if outputs 0-3, 4-7, 8-11, 12-15, ... are
#       connected together
TLC5940_INCLUDE_SET4_FUNCS = 0

# Flag for including a default implementation of the TIMER0_COMPA_vect ISR
#  0 = For advanced users only! Only choose this if you want to override the
#      default implementation of the ISR(TIMER0_COMPA_vect) with your own custom
#      implemetation inside main.c
#  1 = Most users should use this setting. Use the default implementation of the
#      TIMER0_COMPA_vect ISR as defined in tlc5940.c
TLC5940_INCLUDE_DEFAULT_ISR = 1

# Flag for including a gamma correction table stored in the flash memory. When
# driving LEDs, it is helpful to use the full 12-bits of PWM the TLC5940 offers
# to output a 12-bit gamma-corrected value derived from an 8-bit value, since
# the human eye has a non-linear perception of brightness.
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
TLC5940_INCLUDE_GAMMA_CORRECT = 0

# Flag for forced inlining of the SetDC, SetAllDC, and Set4DC functions.
#  0 = Force all calls to the Set*DC family of functions to be actual
#      function calls.  This option when used with the -O3 COMPILE
#      option results in smaller code than using -Os.
#  1 = Force all calls to the Set*DC family of functions to be inlined. Use this
#      option if execution speed is critical, possibly at the expense of program
#      size.
TLC5940_INLINE_SETDC_FUNCS = 1

# Flag for forced inlining of the SetGS, SetAllGS, and Set4GS functions.
#  0 = Force all calls to the Set*GS family of functions to be actual
#      function calls.  This option when used with the -O3 COMPILE
#      option results in smaller code than using -Os.
#  1 = Force all calls to the Set*GS family of functions to be inlined. Use this
#      option if execution speed is critical, possibly at the expense of program
#      size.
TLC5940_INLINE_SETGS_FUNCS = 1

# Flag to enable multiplexing. This can be used to drive both common cathode
# (preferred), or common anode RGB LEDs, or even single-color LEDs. Use a
# P-Channel MOSFET such as an IRF9520 for each row to be multiplexed.
#  0 = Disable multiplexing; library functions as normal.
#  1 = Enable multiplexing; The gsData array will become two-dimensional, and
#      functions in the Set*GS family require another argument which corresponds
#      to the multiplexed row they operate on.
TLC5940_ENABLE_MULTIPLEXING = 0

# The following option only applies if TLC5940_ENABLE_MULTIPLEXING = 1
ifeq ($(TLC5940_ENABLE_MULTIPLEXING), 1)
# Defines the number of rows to be multiplexed.
# Note: Without writing a custom ISR, that can toggle pins from multiple PORT
#       registers, the maximum number of rows that can be multiplexed is eight.
#       This option is ignored if TLC5940_ENABLE_MULTIPLEXING = 0
TLC5940_MULTIPLEX_N = 3
endif

# Setting to select among, Normal SPI Master mode, USART in MSPIM
# mode, or USI mode to communicate with the TLC5940. One major
# advantage of using the USART in MSPIM mode is that the transmit
# register is double-buffered, so you can send data to the TLC5940
# much faster. Refer to schematics ending in _usart_mspim for details
# on how to connect the hardware before changing this mode to 1.

#  0 = Use normal SPI Master mode to communicate with TLC5940 (slower)
#  1 = Use the USART in double-buffered MSPIM mode to communicate with the
#      TLC5940 (faster, but requires the use of different hardware pins)
#  2 = Use the USI (Universal Serial Interface) found on the ATtiny* family of
#      chips.
#
#      USI Example: DEVICE = attiny85
#                   FUSES = (proper fuse bits for ATtiny85 with clock out enabled)
#                   TLC5940_INCLUDE_DC_FUNCS = 0
#                   TLC5940_VPRG_DCPRG_HARDWIRED_TO_GND = 1
#                   TLC5940_ISR_CTC_TIMER = 0
#                   BLANK_PIN = PB3 (so LEDs are off while programming)
#                   XLAT_PIN = PB0 (since this is the only free pin left)
#
# WARNING: Before you change this option, you must wire the chip up differently,
#          and/or switch chips!
TLC5940_SPI_MODE = 2

# Defines the number of bits used to define a single PWM cycle. The default
# is 12, but it may be lowered to achieve faster refreshes, at the expense
# of the ISR being called more frequently. If TLC5940_INCLUDE_GAMMA_CORRECT = 1
# then changing TLC5940_PWM_BITS will automatically rescale the gamma correction
# table to use the appropriate maximum value, at the expense of precision.
#  12 = Normal 12-bit PWM mode. Possible output values between 0-4095
#  11 = 11-bit PWM mode. Possible output values between 0-2047
#  10 = 10-bit PWM mode. Possible output values between 0-1023
#   9 =  9-bit PWM mode. Possible output values between 0-511
#   8 =  8-bit PWM mode. Possible output values between 0-255
# Note: Lowering this value will decrease the amount of time you have in the
#       ISR to send the TLC5940 updated values, potentially limiting the
#       number of devices you can connect in series, and it will decrease the
#       number of cycles available to main(), since the ISR will be called
#       more often. Lowering this value will however, reduce flickering and
#       will allow for much quicker updates.
TLC5940_PWM_BITS = 12

# Defines which 8-bit Timer is used to generate the interrupt that
# fires every 2^TLC5940_PWM_BITS clock cycles. Useful if you are
# already using a timer for something else, or if you wish to use a
# particular PWM pin to generate a GSCLK signal instead of using CLKO
# pin for driving GSCLK.
#  0 = 8-bit Timer/Counter0
#  2 = 8-bit Timer/Counter2
TLC5940_ISR_CTC_TIMER = 0

# Determines whether or not GPIOR0 is used to store flags. This special-purpose
# register is designed to store bit flags, as it can set, clear or test a
# single bit in only 2 clock cycles.
#
# Note: If enabled, you must make sure that the flag bits assigned below do not
#       conflict with any other GPIOR0 flag bits your application might use.
TLC5940_USE_GPIOR0 = 1

# GPIOR0 flag bits used
ifeq ($(TLC5940_USE_GPIOR0), 1)
TLC5940_FLAG_GS_UPDATE = 0
ifeq ($(TLC5940_ENABLE_MULTIPLEXING), 0)
TLC5940_FLAG_XLAT_NEEDS_PULSE = 1
endif
endif

# BLANK is not configurable if the TLC5940 is using the normal SPI Master mode (TLC5940_SPI_MODE = 0),
# but it is configurable when TLC5940_SPI_MODE = 1 or 2
# WARNING: When TLC5940_SPI_MODE = 2, BLANK_PIN should be PB3 so the outputs are blanked during programming
# or in USI mode
ifneq ($(TLC5940_SPI_MODE), 0)
#BLANK_DDR = DDRD
#BLANK_PORT = PORTD
#BLANK_PIN = PD6
BLANK_DDR = DDRB
BLANK_PORT = PORTB
BLANK_PIN = PB3
endif

# VPRG and DCPRG pins are only defined if they aren't hardwired to GND
ifeq ($(TLC5940_VPRG_DCPRG_HARDWIRED_TO_GND), 0)
# DDR, PORT, and PIN connected to DCPRG
DCPRG_DDR = DDRD
DCPRG_PORT = PORTD
# DCPRG is always configurable, but the default pin needs to change if
# the TLC5940 is using USART MSPIM mode, because PD4 is needed for XCK
ifeq ($(TLC5940_SPI_MODE), 1)
DCPRG_PIN = PD3
else
DCPRG_PIN = PD4
endif

# DDR, PORT, and PIN connected to VPRG
VPRG_DDR = DDRD
VPRG_PORT = PORTD
VPRG_PIN = PD7
endif

# DDR, PORT, and PIN connected to XLAT (always configurable)
ifeq ($(TLC5940_SPI_MODE), 1)
XLAT_DDR = DDRD
XLAT_PORT = PORTD
XLAT_PIN = PD5
else
#XLAT_DDR = DDRB
#XLAT_PORT = PORTB
#XLAT_PIN = PB1
XLAT_DDR = DDRB
XLAT_PORT = PORTB
XLAT_PIN = PB0
endif

# The following options only apply if TLC5940_ENABLE_MULTIPLEXING = 1
ifeq ($(TLC5940_ENABLE_MULTIPLEXING), 1)
# DDR, PORT, and PIN registers used for driving the multiplexing IRF9520 MOSFETs
# Note: All pins used for multiplexing must share the same DDR, PORT, and PIN
#       registers. These options are ignored if TLC5940_ENABLE_MULTIPLEXING = 0
MULTIPLEX_DDR = DDRC
MULTIPLEX_PORT = PORTC
MULTIPLEX_PIN = PINC

# List of PIN names of pins that are connected to the multiplexing IRF9520
# MOSFETs. You can define up to eight unless you use a custom ISR that can
# toggle PINs on multiple PORTs.
# Note: All pins used for multiplexing must share the same DDR, PORT, and PIN
#       registers. These options are ignored if TLC5940_ENABLE_MULTIPLEXING = 0
# Also: If you add any pins here, do not forget to add those variables to the
#       MULTIPLEXING_DEFINES flag below!
R_PIN = PC0
G_PIN = PC1
B_PIN = PC2

# This avoids adding needless defines if TLC5940_ENABLE_MULTIPLEXING = 0
MULTIPLEXING_DEFINES = -DTLC5940_MULTIPLEX_N=$(TLC5940_MULTIPLEX_N) \
                       -DMULTIPLEX_DDR=$(MULTIPLEX_DDR) \
                       -DMULTIPLEX_PORT=$(MULTIPLEX_PORT) \
                       -DMULTIPLEX_PIN=$(MULTIPLEX_PIN) \
                       -DR_PIN=$(R_PIN) \
                       -DG_PIN=$(G_PIN) \
                       -DB_PIN=$(B_PIN)
endif

# This avoids a redefinition warning if TLC5940_SPI_MODE = 0
ifneq ($(TLC5940_SPI_MODE), 0)
BLANK_DEFINES = -DBLANK_DDR=$(BLANK_DDR) \
                -DBLANK_PORT=$(BLANK_PORT) \
                -DBLANK_PIN=$(BLANK_PIN)
endif

# This avoids adding needless defines if TLC5940_VPRG_DCPRG_HARDWIRED_TO_GND = 1
ifeq ($(TLC5940_VPRG_DCPRG_HARDWIRED_TO_GND), 0)
VPRG_DCPRG_DEFINES = -DDCPRG_DDR=$(DCPRG_DDR) \
                     -DDCPRG_PORT=$(DCPRG_PORT) \
                     -DDCPRG_PIN=$(DCPRG_PIN) \
                     -DVPRG_DDR=$(VPRG_DDR) \
                     -DVPRG_PORT=$(VPRG_PORT) \
                     -DVPRG_PIN=$(VPRG_PIN)
endif

# This avoids adding needless defines if TLC5940_USE_GPIOR0 = 0
ifeq ($(TLC5940_USE_GPIOR0), 1)
TLC5940_GPIOR0_DEFINES = -DTLC5940_FLAG_GS_UPDATE=$(TLC5940_FLAG_GS_UPDATE) \
                         -DTLC5940_FLAG_XLAT_NEEDS_PULSE=$(TLC5940_FLAG_XLAT_NEEDS_PULSE)
endif

# This line integrates all options into a single flag called:
#     $(TLC5940_DEFINES)
# which should be appended to the definition of COMPILE below
TLC5940_DEFINES = -DTLC5940_N=$(TLC5940_N) \
                  -DTLC5940_INCLUDE_DC_FUNCS=$(TLC5940_INCLUDE_DC_FUNCS) \
                  -DTLC5940_VPRG_DCPRG_HARDWIRED_TO_GND=$(TLC5940_VPRG_DCPRG_HARDWIRED_TO_GND) \
                  -DTLC5940_INCLUDE_SET4_FUNCS=$(TLC5940_INCLUDE_SET4_FUNCS) \
                  -DTLC5940_INCLUDE_DEFAULT_ISR=$(TLC5940_INCLUDE_DEFAULT_ISR) \
                  -DTLC5940_INCLUDE_GAMMA_CORRECT=$(TLC5940_INCLUDE_GAMMA_CORRECT) \
                  -DTLC5940_INLINE_SETDC_FUNCS=$(TLC5940_INLINE_SETDC_FUNCS) \
                  -DTLC5940_INLINE_SETGS_FUNCS=$(TLC5940_INLINE_SETGS_FUNCS) \
                  -DTLC5940_ENABLE_MULTIPLEXING=$(TLC5940_ENABLE_MULTIPLEXING) \
                  $(MULTIPLEXING_DEFINES) \
                  -DTLC5940_SPI_MODE=$(TLC5940_SPI_MODE) \
                  -DTLC5940_PWM_BITS=$(TLC5940_PWM_BITS) \
                  -DTLC5940_ISR_CTC_TIMER=$(TLC5940_ISR_CTC_TIMER) \
                  -DTLC5940_USE_GPIOR0=$(TLC5940_USE_GPIOR0) \
                  $(BLANK_DEFINES) \
                  $(VPRG_DCPRG_DEFINES) \
                  $(TLC5940_GPIOR0_DEFINES) \
                  -DXLAT_DDR=$(XLAT_DDR) \
                  -DXLAT_PORT=$(XLAT_PORT) \
                  -DXLAT_PIN=$(XLAT_PIN)

# ---------- End TLC5940 Configuration Section ----------
