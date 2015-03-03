/*

  main.c

  Copyright 2015 Matthew T. Pandina. All rights reserved.

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

  --------------------------------------------------------------------

  This is a demonstration of the latest version of the "Demystifying
  the TLC5940" library. It is compatible with every schematic
  provided, though it may require a couple additional configuration
  settings to be tweaked for it to work (beyond those listed on each
  schematic).

  When using the multiplexing configurations, an assumption is made
  that there are three multiplexing channels, corresponding to red,
  green, and blue in that order, and that the gamma correction lookup
  table is included so that colors may be displayed properly.

  Additional Makefile configuration for "-multiplexing" schematics:
  TLC5940_MULTIPLEX_N = 3
  TLC5940_INCLUDE_GAMMA_CORRECT = 1

  How dot correction works:

    With a 2.2K resistor between the TLC5940's IREF pin and GND, the
    maximum current that each channel can sink is governed by the
    following formula:

      I_MAX = 39.06 / R_IREF = 39.06 / 2200 = 17.8 mA

    By setting the dot correction for a specific channel, we place an
    additional limit on the maximum current that channel is allowed to
    sink, while still being able to PWM across the full range of
    grayscale values.

    For example, say we want to limit just the 0th channel to sink a
    maximum of 10mA. First we need to calculate the appropriate dot
    correction value, based on our calculation for I_MAX above:

      DCn = (0.010 * 63) / (39.06 / 2200) = 35.5

    Only integer values between 0 and 63 may be used, so either round
    up, or down, it's your choice. If that matters to you, then you
    probably also want to measure the exact value of R_IREF with a
    multimeter and use that in your calculation too.

    To set the dot correction for the 0th channel to the value we just
    calculated, add the following line of code between the calls to
    TLC5940_SetAllDC(63) and TLC5940_ClockInDC() inside the main
    function:

      TLC5940_SetDC(0, 35);

*/

#include <stdint.h>
#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>

#include "tlc5940.h"

// ------ The non-multiplexing (single-color) example is presented first ------
#if (TLC5940_ENABLE_MULTIPLEXING == 0)

int main(void) {
  // Initialize the TLC5940 library
  TLC5940_Init();

#if (TLC5940_INCLUDE_DC_FUNCS)
  // Set the default dot correction value to 100% for all channels
  TLC5940_SetAllDC(63);
  // Clock in the dot correction values now, otherwise they won't be used
  TLC5940_ClockInDC();
#endif // TLC5940_INCLUDE_DC_FUNCS

  // Set the initial grayscale value for every channel to 0
  TLC5940_SetAllGS(0);
  // Always clock in the initial grayscale values before enabling interrupts
  TLC5940_ClockInGS();

  // Enable global interrupts
  sei();

  // Infinite loop
  for (;;) {
    // Loop forward over all output channels
    for (channel_t i = 0; i < TLC5940_CHANNELS_N; ++i) {

      // Wait until we are allowed to update the grayscale values
      while(TLC5940_GetGSUpdateFlag());

      // Set the PWM duty cycle for all channels to 0%
      TLC5940_SetAllGS(0);

      // Set the PWM duty cycle for the current channel to 100%
      TLC5940_SetGS(i, 4095);

      // Signal the library to start using the new grayscale values
      TLC5940_SetGSUpdateFlag();

      // Delay for a bit, so we can actually see what is happening
      _delay_ms(25);
    }

    // Loop backward over all output channels, skipping the last and first
    for (channel_t i = TLC5940_CHANNELS_N - 1; i > 0; --i) {

      // Wait until we are allowed to update the grayscale values
      while(TLC5940_GetGSUpdateFlag());

      // Set the PWM duty cycle for all channels to 0%
      TLC5940_SetAllGS(0);

      // Set the PWM duty cycle for the current channel to 100%
      TLC5940_SetGS(i, 4095);

      // Signal the library to start using the new grayscale values
      TLC5940_SetGSUpdateFlag();

      // Delay for a bit, so we can actually see what is happening
      _delay_ms(25);
    }
  }

  return 0;
}

// -------- The multiplexing (multi-color) example is presented next --------
#elif (TLC5940_ENABLE_MULTIPLEXING != 0)

// Ensure the additional configuration requirements for this demo have been met
#if (TLC5940_MULTIPLEX_N != 3)
#error "This demo requires TLC5940_MULTIPLEX_N = 3 set in tlc5940.mk"
#endif // TLC5940_MULTIPLEX_N

#if (TLC5940_INCLUDE_GAMMA_CORRECT != 1)
#error "This demo requires TLC5940_INCLUDE_GAMMA_CORRECT = 1 set in tlc5940.mk"
#endif // TLC5940_INCLUDE_GAMMA_CORRECT

/*
  Accepts a color_index (ranging between 0 and 767, inclusive) into
  the spectrum of colors. Upon returning, the arguments r, g, and b
  will be set to the red, green, and blue components of that part of
  the spectrum.
*/
static inline void SetColorToIndex(uint16_t color_index, uint8_t *r, uint8_t *g, uint8_t *b) __attribute__ (( always_inline ));
static inline void SetColorToIndex(uint16_t color_index, uint8_t *r, uint8_t *g, uint8_t *b) {
  uint8_t group = color_index >> 8;
  uint8_t value = (uint8_t)color_index;

  switch (group) {
  case 0:
    *r = 255 - value;
    *g = value;
    *b = 0;
    break;
  case 1:
    *r = 0;
    *g = 255 - value;
    *b = value;
    break;
  case 2:
    *r = value;
    *g = 0;
    *b = 255 - value;
    break;
  }
}

int main(void) {
  // Initialize the TLC5940 library
  TLC5940_Init();

#if (TLC5940_INCLUDE_DC_FUNCS)
  // Set the default dot correction value to 100% for all channels
  TLC5940_SetAllDC(63);
  // Clock in the dot correction values now, otherwise they won't be used
  TLC5940_ClockInDC();
#endif // TLC5940_INCLUDE_DC_FUNCS

  // Set the initial grayscale value for every row and channel to 0
  for (uint8_t i = 0; i < TLC5940_MULTIPLEX_N; ++i)
    TLC5940_SetAllGS(i, 0);
  // Always clock in the initial grayscale values before enabling interrupts
  TLC5940_ClockInGS();

  // Enable global interrupts
  sei();

  // Stores the index of the current color we are drawing with
  uint16_t color_index = 0;

  // Infinite loop
  for (;;) {
    // Loop forward over all output channels
    for (channel_t i = 0; i < TLC5940_CHANNELS_N; ++i) {

      // Wait until we are allowed to update the grayscale values
      while(TLC5940_GetGSUpdateFlag());

      // Set the PWM duty cycle for every row and channel to 0%
      for (uint8_t row = 0; row < TLC5940_MULTIPLEX_N; ++row)
        TLC5940_SetAllGS(row, 0);

      // Retrieve the RGB components of our current place in the spectrum
      uint8_t r = 0;
      uint8_t g = 0;
      uint8_t b = 0;
      SetColorToIndex(color_index, &r, &g, &b);

      // Increment our place in the spectrum by 1, accounting for rollover
      if (++color_index >= 768)
        color_index = 0;

      // Set the RGB color (using gamma-correction) for the current channel
      TLC5940_SetGS(0, i, TLC5940_GammaCorrect(r));
      TLC5940_SetGS(1, i, TLC5940_GammaCorrect(g));
      TLC5940_SetGS(2, i, TLC5940_GammaCorrect(b));

      // Signal the library to start using the new grayscale values
      TLC5940_SetGSUpdateFlag();

      // Delay for a bit, so we can actually see what is happening
      _delay_ms(10);
    }

    // Loop backward over all output channels, skipping the last and first
    for (channel_t i = TLC5940_CHANNELS_N - 1; i > 0; --i) {

      // Wait until we are allowed to update the grayscale values
      while(TLC5940_GetGSUpdateFlag());

      // Set the PWM duty cycle for every row and channel to 0%
      for (uint8_t row = 0; row < TLC5940_MULTIPLEX_N; ++row)
        TLC5940_SetAllGS(row, 0);

      // Retrieve the RGB components of our current place in the spectrum
      uint8_t r = 0;
      uint8_t g = 0;
      uint8_t b = 0;
      SetColorToIndex(color_index, &r, &g, &b);

      // Increment our place in the spectrum by 1, accounting for rollover
      if (++color_index >= 768)
        color_index = 0;

      // Set the RGB color (using gamma-correction) for the current channel
      TLC5940_SetGS(0, i, TLC5940_GammaCorrect(r));
      TLC5940_SetGS(1, i, TLC5940_GammaCorrect(g));
      TLC5940_SetGS(2, i, TLC5940_GammaCorrect(b));

      // Signal the library to start using the new grayscale values
      TLC5940_SetGSUpdateFlag();

      // Delay for a bit, so we can actually see what is happening
      _delay_ms(10);
    }
  }

  return 0;
}

#endif // TLC5940_ENABLE_MULTIPLEXING
