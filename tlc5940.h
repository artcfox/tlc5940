/*

  tlc5940.h

  Copyright 2010-2014 Matthew T. Pandina. All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions
  are met:

  1. Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

  2. Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.

  THIS SOFTWARE IS PROVIDED BY MATTHEW T. PANDINA "AS IS" AND ANY
  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL MATTHEW T. PANDINA OR
  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
  USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
  OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
  SUCH DAMAGE.

*/

#pragma once

#include <stdint.h>
#include <stdbool.h>
#include <avr/io.h>

#if (TLC5940_INCLUDE_GAMMA_CORRECT)
#include <avr/pgmspace.h>
#endif // TLC5940_INCLUDE_GAMMA_CORRECT

// These options are not configurable because they rely on specific hardware
// features of the ATmega328P that are only available on specific pins.
#if (TLC5940_SPI_MODE == 0)
#define SIN_DDR DDRB
#define SIN_PORT PORTB
#define SIN_PIN PB3

#define SCLK_DDR DDRB
#define SCLK_PORT PORTB
#define SCLK_PIN PB5

#define BLANK_DDR DDRB
#define BLANK_PORT PORTB
#define BLANK_PIN PB2
#elif (TLC5940_SPI_MODE == 1)
#define SIN_DDR DDRD
#define SIN_PORT PORTD
#define SIN_PIN PD1

#define SCLK_DDR DDRD
#define SCLK_PORT PORTD
#define SCLK_PIN PD4
#elif (TLC5940_SPI_MODE == 2)
#define SIN_DDR DDRB
#define SIN_PORT PORTB
#define SIN_PIN PB1

#define SCLK_DDR DDRB
#define SCLK_PORT PORTB
#define SCLK_PIN PB2
#endif // TLC5940_SPI_MODE

// --------------------------------------------------------

#define setOutput(ddr, pin) ((ddr) |= (1 << (pin)))
#define setLow(port, pin) ((port) &= ~(1 << (pin)))
#define setHigh(port, pin) ((port) |= (1 << (pin)))
#define getValue(port, pin) ((port) & (1 << (pin)))
#define pulse(port, pin) do {                       \
                           setHigh((port), (pin));  \
                           setLow((port), (pin));   \
                         } while (0)

#if (24 * TLC5940_N > 255)
#define gsData_t uint16_t
#else
#define gsData_t uint8_t
#endif

#if (16 * TLC5940_N > 255)
#define channel_t uint16_t
#else
#define channel_t uint8_t
#endif

#if (3 * 16 * TLC5940_N > 255)
#define channel3_t uint16_t
#else
#define channel3_t uint8_t
#endif

#if (24 * TLC5940_N * TLC5940_MULTIPLEX_N > 255)
#define gsOffset_t uint16_t
#else
#define gsOffset_t uint8_t
#endif

#define gsDataSize ((gsData_t)24 * TLC5940_N)
#define numChannels ((channel_t)16 * TLC5940_N)

#if (TLC5940_ENABLE_MULTIPLEXING)
extern const uint8_t toggleRows[2 * TLC5940_MULTIPLEX_N];
extern uint8_t gsData[TLC5940_MULTIPLEX_N][gsDataSize];
extern uint8_t *pBack;
#else // TLC5940_ENABLE_MULTIPLEXING
extern uint8_t gsData[gsDataSize];
#endif // TLC5940_ENABLE_MULTIPLEXING

#if (TLC5940_USE_GPIOR0)
#define TLC5940_FLAGS GPIOR0
// gsUpdateFlag is now a convenience macro so client code can remain unchanged
#define gsUpdateFlag (getValue(TLC5940_FLAGS, TLC5940_FLAG_GS_UPDATE))
#else // TLC5940_USE_GPIOR0
extern volatile bool gsUpdateFlag;
#endif // TLC5940_USE_GPIOR0

static inline void TLC5940_SetGSUpdateFlag(void) __attribute__(( always_inline ));
static inline void TLC5940_SetGSUpdateFlag(void) {
  __asm__ volatile ("" ::: "memory");
#if (TLC5940_USE_GPIOR0)
  setHigh(TLC5940_FLAGS, TLC5940_FLAG_GS_UPDATE);
#else // TLC5940_USE_GPIOR0
  gsUpdateFlag = true;
#endif // TLC5940_USE_GPIOR0
  __asm__ volatile ("" ::: "memory");
}
// TLC5940_ClearGSUpdateFlag() should never be called from user code, except when providing a non-default ISR
static inline void TLC5940_ClearGSUpdateFlag(void) __attribute__(( always_inline ));
static inline void TLC5940_ClearGSUpdateFlag(void) {
#if (TLC5940_USE_GPIOR0)
  setLow(TLC5940_FLAGS, TLC5940_FLAG_GS_UPDATE);
#else // TLC5940_USE_GPIOR0
  gsUpdateFlag = false;
#endif // TLC5940_USE_GPIOR0
}
static inline bool TLC5940_GetGSUpdateFlag(void) __attribute__(( always_inline ));
static inline bool TLC5940_GetGSUpdateFlag(void) {
#if (TLC5940_USE_GPIOR0)
  return getValue(TLC5940_FLAGS, TLC5940_FLAG_GS_UPDATE);
#else // TLC5940_USE_GPIOR0
  return gsUpdateFlag;
#endif // TLC5940_USE_GPIOR0
}

#if (TLC5940_ENABLE_MULTIPLEXING == 0)
#if (TLC5940_USE_GPIOR0 == 0)
extern bool xlatNeedsPulse; // should never be directly read/written from user code, ever
#endif // TLC5940_USE_GPIOR0

// TLC5940_SetXLATNeedsPulseFlag should never be called from user code, except when implementing a non-default ISR
static inline void TLC5940_SetXLATNeedsPulseFlag(void) __attribute__(( always_inline ));
static inline void TLC5940_SetXLATNeedsPulseFlag(void) {
#if (TLC5940_USE_GPIOR0)
  setHigh(TLC5940_FLAGS, TLC5940_FLAG_XLAT_NEEDS_PULSE);
#else // TLC5940_USE_GPIOR0
  xlatNeedsPulse = true;
#endif // TLC5940_USE_GPIOR0
}
// TLC5940_ClearXLATNeedsPulseFlag should never be called from user code, except when implementing a non-default ISR
static inline void TLC5940_ClearXLATNeedsPulseFlag(void) __attribute__(( always_inline ));
static inline void TLC5940_ClearXLATNeedsPulseFlag(void) {
#if (TLC5940_USE_GPIOR0)
  setLow(TLC5940_FLAGS, TLC5940_FLAG_XLAT_NEEDS_PULSE);
#else // TLC5940_USE_GPIOR0
  xlatNeedsPulse = false;
#endif // TLC5940_USE_GPIOR0
}
// TLC5940_GetXLATNeedsPulseFlag() should never be called from user code, except when implementing a non-default ISR
static inline bool TLC5940_GetXLATNeedsPulseFlag(void) __attribute__(( always_inline ));
static inline bool TLC5940_GetXLATNeedsPulseFlag(void) {
#if (TLC5940_USE_GPIOR0)
  return getValue(TLC5940_FLAGS, TLC5940_FLAG_XLAT_NEEDS_PULSE);
#else // TLC5940_USE_GPIOR0
  return xlatNeedsPulse;
#endif // TLC5940_USE_GPIOR0
}
#endif // TLC5940_ENABLE_MULTIPLEXING

#if (TLC5940_INCLUDE_GAMMA_CORRECT)
extern const uint16_t TLC5940_GammaCorrect[] PROGMEM;
#endif // TLC5940_INCLUDE_GAMMA_CORRECT

// Define a macro for SPI Transmit
#if (TLC5940_SPI_MODE == 0)
#define TLC5940_TX(data) do {                              \
                           SPDR = (data);                  \
                           while (!(SPSR & (1 << SPIF)));  \
                         } while (0)
#elif (TLC5940_SPI_MODE == 1)
#define TLC5940_TX(data) do {                                 \
                           while (!(UCSR0A & (1 << UDRE0)));  \
                           UDR0 = (data);                     \
                         } while (0)
#elif (TLC5940_SPI_MODE == 2)
#define TLC5940_TX(data) \
do {                                                                         \
  USIDR = (data);                                                            \
  uint8_t lo = (1 << USIWM0) | (0 << USICS0) | (1 << USITC);                 \
  uint8_t hi = (1 << USIWM0) | (0 << USICS0) | (1 << USITC) | (1 << USICLK); \
  USICR = lo; USICR = hi; USICR = lo; USICR = hi;                            \
  USICR = lo; USICR = hi; USICR = lo; USICR = hi;                            \
  USICR = lo; USICR = hi; USICR = lo; USICR = hi;                            \
  USICR = lo; USICR = hi; USICR = lo; USICR = hi;                            \
 } while (0)
#endif // TLC5940_SPI_MODE

#if (TLC5940_INCLUDE_DC_FUNCS)
#if (12 * TLC5940_N > 255)
#define dcData_t uint16_t
#else
#define dcData_t uint8_t
#endif

#define dcDataSize ((dcData_t)12 * TLC5940_N)

extern uint8_t dcData[dcDataSize];

#if (TLC5940_INLINE_SETDC_FUNCS)
static inline void TLC5940_SetDC(channel_t channel, uint8_t value) __attribute__(( always_inline ));
static inline void TLC5940_SetDC(channel_t channel, uint8_t value) {
#else // TLC5940_INLINE_SETDC_FUNCS
static        void TLC5940_SetDC(channel_t channel, uint8_t value) __attribute__(( noinline, unused ));
static        void TLC5940_SetDC(channel_t channel, uint8_t value) {
#endif // TLC5940_INLINE_SETDC_FUNCS
  channel = numChannels - 1 - channel;
  channel_t i = (channel3_t)channel * 3 / 4;

  switch (channel % 4) {
  case 0:
    dcData[i] = (dcData[i] & 0x03) | (uint8_t)(value << 2);
    break;
  case 1:
    dcData[i] = (dcData[i] & 0xFC) | (value >> 4);
    i++;
    dcData[i] = (dcData[i] & 0x0F) | (uint8_t)(value << 4);
    break;
  case 2:
    dcData[i] = (dcData[i] & 0xF0) | (value >> 2);
    i++;
    dcData[i] = (dcData[i] & 0x3F) | (uint8_t)(value << 6);
    break;
  default: // case 3:
    dcData[i] = (dcData[i] & 0xC0) | (value);
    break;
  }
}

#if (TLC5940_INLINE_SETDC_FUNCS)
static inline void TLC5940_SetAllDC(uint8_t value) __attribute__(( always_inline ));
static inline void TLC5940_SetAllDC(uint8_t value) {
#else // TLC5940_INLINE_SETDC_FUNCS
static        void TLC5940_SetAllDC(uint8_t value) __attribute__(( noinline, unused ));
static        void TLC5940_SetAllDC(uint8_t value) {
#endif // TLC5940_INLINE_SETDC_FUNCS
  uint8_t tmp1 = (uint8_t)(value << 2);
  uint8_t tmp2 = (uint8_t)(tmp1 << 2);
  uint8_t tmp3 = (uint8_t)(tmp2 << 2);
  tmp1 |= (value >> 4);
  tmp2 |= (value >> 2);
  tmp3 |= value;

  dcData_t i = 0;
  do {
    dcData[i++] = tmp1;              // bits: 05 04 03 02 01 00 05 04
    dcData[i++] = tmp2;              // bits: 03 02 01 00 05 04 03 02
    dcData[i++] = tmp3;              // bits: 01 00 05 04 03 02 01 00
  } while (i < dcDataSize);
}

#if (TLC5940_INCLUDE_SET4_FUNCS)
// Assumes that outputs 0-3, 4-7, 8-11, 12-15 of the TLC5940 have
// been connected together to sink more current. For a single
// TLC5940, the parameter 'channel' should be in the range 0-3
#if (TLC5940_INLINE_SETDC_FUNCS)
static inline void TLC5940_Set4DC(channel_t channel, uint8_t value) __attribute__(( always_inline ));
static inline void TLC5940_Set4DC(channel_t channel, uint8_t value) {
#else // TLC5940_INLINE_SETDC_FUNCS
static        void TLC5940_Set4DC(channel_t channel, uint8_t value) __attribute__(( noinline, unused ));
static        void TLC5940_Set4DC(channel_t channel, uint8_t value) {
#endif // TLC5940_INLINE_SETDC_FUNCS
  channel = numChannels - 1 - (channel * 4) - 3;
  channel_t i = (channel3_t)channel * 3 / 4;

  uint8_t tmp1 = (uint8_t)(value << 2);
  uint8_t tmp2 = (uint8_t)(tmp1 << 2);
  uint8_t tmp3 = (uint8_t)(tmp2 << 2);
  tmp1 |= (value >> 4);
  tmp2 |= (value >> 2);
  tmp3 |= value;

  dcData[i++] = tmp1;              // bits: 05 04 03 02 01 00 05 04
  dcData[i++] = tmp2;              // bits: 03 02 01 00 05 04 03 02
  dcData[i] = tmp3;                // bits: 01 00 05 04 03 02 01 00
}

#endif // TLC5940_INCLUDE_SET4_FUNCS
void TLC5940_ClockInDC(void);
#endif // TLC5940_INCLUDE_DC_FUNCS

#if (TLC5940_ENABLE_MULTIPLEXING)
#if (TLC5940_INLINE_SETGS_FUNCS)
static inline void TLC5940_SetGS(uint8_t row, channel_t channel, uint16_t value) __attribute__(( always_inline ));
static inline void TLC5940_SetGS(uint8_t row, channel_t channel, uint16_t value) {
#else // TLC5940_INLINE_SETGS_FUNCS
static        void TLC5940_SetGS(uint8_t row, channel_t channel, uint16_t value) __attribute__(( noinline, unused ));
static        void TLC5940_SetGS(uint8_t row, channel_t channel, uint16_t value) {
#endif // TLC5940_INLINE_SETGS_FUNCS
  channel = numChannels - 1 - channel;
  uint16_t offset = (uint16_t)((channel3_t)channel * 3 / 2) + (gsOffset_t)gsDataSize * row;

  switch (channel % 2) {
  case 0:
    *(pBack + offset++) = (value >> 4);
    *(pBack + offset) = (*(pBack + offset) & 0x0F) | (uint8_t)(value << 4);
    break;
  default: // case 1:
    *(pBack + offset) = (*(pBack + offset) & 0xF0) | (value >> 8);
    *(pBack + ++offset) = (uint8_t)value;
    break;
  }
}
#else // TLC5940_ENABLE_MULTIPLEXING
#if (TLC5940_INLINE_SETGS_FUNCS)
static inline void TLC5940_SetGS(channel_t channel, uint16_t value) __attribute__(( always_inline ));
static inline void TLC5940_SetGS(channel_t channel, uint16_t value) {
#else // TLC5940_INLINE_SETGS_FUNCS
static        void TLC5940_SetGS(channel_t channel, uint16_t value) __attribute__(( noinline, unused ));
static        void TLC5940_SetGS(channel_t channel, uint16_t value) {
#endif // TLC5940_INLINE_SETGS_FUNCS
  channel = numChannels - 1 - channel;
  channel3_t i = (channel3_t)channel * 3 / 2;

  switch (channel % 2) {
  case 0:
    gsData[i++] = (value >> 4);
    gsData[i] = (gsData[i] & 0x0F) | (uint8_t)(value << 4);
    break;
  default: // case 1:
    gsData[i] = (gsData[i] & 0xF0) | (value >> 8);
    gsData[++i] = (uint8_t)value;
    break;
  }
}
#endif // TLC5940_ENABLE_MULTIPLEXING

#if (TLC5940_ENABLE_MULTIPLEXING)
#if (TLC5940_INLINE_SETGS_FUNCS)
static inline void TLC5940_SetAllGS(uint8_t row, uint16_t value) __attribute__(( always_inline ));
static inline void TLC5940_SetAllGS(uint8_t row, uint16_t value) {
#else // TLC5940_INLINE_SETGS_FUNCS
static        void TLC5940_SetAllGS(uint8_t row, uint16_t value) __attribute__(( noinline, unused ));
static        void TLC5940_SetAllGS(uint8_t row, uint16_t value) {
#endif // TLC5940_INLINE_SETGS_FUNCS
  uint8_t tmp1 = (value >> 4);
  uint8_t tmp2 = (uint8_t)(value << 4) | (tmp1 >> 4);

  gsOffset_t offset = (gsOffset_t)gsDataSize * row;
  gsData_t i = gsDataSize / 3 + 1;
  while (--i) {
    *(pBack + offset++) = tmp1;              // bits: 11 10 09 08 07 06 05 04
    *(pBack + offset++) = tmp2;              // bits: 03 02 01 00 11 10 09 08
    *(pBack + offset++) = (uint8_t)value;    // bits: 07 06 05 04 03 02 01 00
  }
}
#else // TLC5940_ENABLE_MULTIPLEXING
#if (TLC5940_INLINE_SETGS_FUNCS)
static inline void TLC5940_SetAllGS(uint16_t value) __attribute__(( always_inline ));
static inline void TLC5940_SetAllGS(uint16_t value) {
#else // TLC5940_INLINE_SETGS_FUNCS
static        void TLC5940_SetAllGS(uint16_t value) __attribute__(( noinline, unused ));
static        void TLC5940_SetAllGS(uint16_t value) {
#endif // TLC5940_INLINE_SETGS_FUNCS
  uint8_t tmp1 = (value >> 4);
  uint8_t tmp2 = (uint8_t)(value << 4) | (tmp1 >> 4);

  gsData_t i = 0;
  do {
    gsData[i++] = tmp1;              // bits: 11 10 09 08 07 06 05 04
    gsData[i++] = tmp2;              // bits: 03 02 01 00 11 10 09 08
    gsData[i++] = (uint8_t)value;    // bits: 07 06 05 04 03 02 01 00
  } while (i < gsDataSize);
}
#endif // TLC5940_ENABLE_MULTIPLEXING

#if (TLC5940_INCLUDE_SET4_FUNCS)
// Assumes that outputs 0-3, 4-7, 8-11, 12-15 of the TLC5940 have
// been connected together to sink more current. For a single
// TLC5940, the parameter 'channel' should be in the range 0-3
#if (TLC5940_ENABLE_MULTIPLEXING)
#if (TLC5940_INLINE_SETGS_FUNCS)
static inline void TLC5940_Set4GS(uint8_t row, channel_t channel, uint16_t value) __attribute__(( always_inline ));
static inline void TLC5940_Set4GS(uint8_t row, channel_t channel, uint16_t value) {
#else // TLC5940_INLINE_SETGS_FUNCS
static        void TLC5940_Set4GS(uint8_t row, channel_t channel, uint16_t value) __attribute__(( noinline, unused ));
static        void TLC5940_Set4GS(uint8_t row, channel_t channel, uint16_t value) {
#endif // TLC5940_INLINE_SETGS_FUNCS
  channel = numChannels - 1 - (channel * 4) - 3;
  uint16_t offset = (uint16_t)((channel3_t)channel * 3 / 2) + (gsOffset_t)gsDataSize * row;

  uint8_t tmp1 = (value >> 4);
  uint8_t tmp2 = (uint8_t)(value << 4) | (tmp1 >> 4);

  *(pBack + offset++) = tmp1;              // bits: 11 10 09 08 07 06 05 04
  *(pBack + offset++) = tmp2;              // bits: 03 02 01 00 11 10 09 08
  *(pBack + offset++) = (uint8_t)value;    // bits: 07 06 05 04 03 02 01 00
  *(pBack + offset++) = tmp1;              // bits: 11 10 09 08 07 06 05 04
  *(pBack + offset++) = tmp2;              // bits: 03 02 01 00 11 10 09 08
  *(pBack + offset) = (uint8_t)value;      // bits: 07 06 05 04 03 02 01 00
}
#else // TLC5940_ENABLE_MULTIPLEXING
#if (TLC5940_INLINE_SETGS_FUNCS)
static inline void TLC5940_Set4GS(channel_t channel, uint16_t value) __attribute__(( always_inline ));
static inline void TLC5940_Set4GS(channel_t channel, uint16_t value) {
#else // TLC5940_INLINE_SETGS_FUNCS
static        void TLC5940_Set4GS(channel_t channel, uint16_t value) __attribute__(( noinline, unused ));
static        void TLC5940_Set4GS(channel_t channel, uint16_t value) {
#endif // TLC5940_INLINE_SETGS_FUNCS
  channel = numChannels - 1 - (channel * 4) - 3;
  channel3_t i = (channel3_t)channel * 3 / 2;

  uint8_t tmp1 = (value >> 4);
  uint8_t tmp2 = (uint8_t)(value << 4) | (tmp1 >> 4);

  gsData[i++] = tmp1;              // bits: 11 10 09 08 07 06 05 04
  gsData[i++] = tmp2;              // bits: 03 02 01 00 11 10 09 08
  gsData[i++] = (uint8_t)value;    // bits: 07 06 05 04 03 02 01 00
  gsData[i++] = tmp1;              // bits: 11 10 09 08 07 06 05 04
  gsData[i++] = tmp2;              // bits: 03 02 01 00 11 10 09 08
  gsData[i] = (uint8_t)value;      // bits: 07 06 05 04 03 02 01 00
}
#endif // TLC5940_ENABLE_MULTIPLEXING
#endif // TLC5940_INCLUDE_SET4_FUNCS

void TLC5940_ClockInGS(void);
void TLC5940_Init(void);

#if (TLC5940_ISR_CTC_TIMER == 0)
#define TLC5940_TIMER_COMPA_vect TIMER0_COMPA_vect
#elif (TLC5940_ISR_CTC_TIMER == 2)
#define TLC5940_TIMER_COMPA_vect TIMER2_COMPA_vect
#else // TLC5940_ISR_CTC_TIMER
#error "TLC5940_ISR_CTC_TIMER must be 0 or 2"
#endif // TLC5940_ISR_CTC_TIMER
