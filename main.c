/*

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

*/

#include <stdint.h>
#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>

#include "tlc5940.h"

/*
  Since this demo works with both multiplexing and non-multiplexing
  hardware configurations, we need to do things a bit differently
  depending on the current configuration, so you'll see some lines
  like the one below:
 */
#if (TLC5940_ENABLE_MULTIPLEXING)

// Error out early if the additional configuration requirements have not been met
#if (TLC5940_MULTIPLEX_N != 3)
#error "Sorry, if TLC5940_ENABLE_MULTIPLEXING = 1, this demo also requires TLC5940_MULTIPLEX_N = 3"
#endif // TLC5940_MULTIPLEX_N
#if (TLC5940_INCLUDE_GAMMA_CORRECT != 1)
#error "Sorry, if TLC5940_ENABLE_MULTIPLEXING = 1, this demo also requires TLC5940_INCLUDE_GAMMA_CORRECT = 1"
#endif // TLC5940_INCLUDE_GAMMA_CORRECT

/*
  Given an index into the spectrum of colors, gives back the red,
  green, and blue components of that particular index.

  color_index should be between 0 and 767, inclusive
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

#endif // TLC5940_ENABLE_MULTIPLEXING

int main(void) {

  // Initialize the TLC5940 library
  TLC5940_Init();

#if (TLC5940_INCLUDE_DC_FUNCS)

  /*
     With a 2.2K resistor between the TLC5940's IREF pin and GND, the
     maximum current that each channel can sink is:

       I_MAX = 39.06 / 2200 = 17.8 mA

     By setting a dot correction value for a specific channel, we can
     place additional limits on the maximum current that channel can
     sink, while still being able to modify its brightness across the
     entire range of grayscale values.
   */

  // First, set a default dot correction value of 100% for all channels
  TLC5940_SetAllDC(63);

  /*
    Say we want to limit just the 0th channel to sink a maximum of
    10mA. First we need to calculate the appropriate dot correction
    value, based on our calculation for I_MAX above:

      DCn = (0.010 * 63) / (39.06 / 2200) = 35.5

    Either round up, or round down, it's your choice. If that matters
    to you, then you probably also want to measure the exact value of
    R_IREF with a multimeter and use that in your calculation.

    To test this, uncomment the following line of code to set the dot
    correction for the 0th channel to the value we just calculated:
  */
  //TLC5940_SetDC(0, 35);

  // Clock in the dot correction values, otherwise they won't be used
  TLC5940_ClockInDC();

#endif // TLC5940_INCLUDE_DC_FUNCS

#if (TLC5940_ENABLE_MULTIPLEXING)

  // Stores the current color we are drawing with
  uint16_t color_index = 0;

  // Set the initial grayscale value for every row and channel to 0
  for (uint8_t i = 0; i < TLC5940_MULTIPLEX_N; i++)
    TLC5940_SetAllGS(i, 0);

#else // TLC5940_ENABLE_MULTIPLEXING

  // Set the initial grayscale value for every channel to 0
  TLC5940_SetAllGS(0);

#endif // TLC5940_ENABLE_MULTIPLEXING

  // It is required that we clock in the initial grayscale values now
  TLC5940_ClockInGS();

  // Only now should we enable global interrupts
  sei();

  for (;;) {

    // Loop forwards over all output channels
    for (channel_t i = 0; i < TLC5940_CHANNELS_N; ++i) {

      // Wait until we are allowed to update the grayscale values
      while(TLC5940_GetGSUpdateFlag());

#if (TLC5940_ENABLE_MULTIPLEXING)

      // Default all outputs to off
      for (uint8_t row = 0; row < TLC5940_MULTIPLEX_N; row++)
        TLC5940_SetAllGS(row, 0);

      // Get the color associated with our current place in the spectrum
      uint8_t r = 0;
      uint8_t g = 0;
      uint8_t b = 0;
      SetColorToIndex(color_index, &r, &g, &b);

      // Increment our place in the spectrum by 1, accounting for rollover
      if (++color_index >= 768)
        color_index = 0;

      // Set the RGB color for the current channel
      TLC5940_SetGS(0, i, TLC5940_GammaCorrect(r));
      TLC5940_SetGS(1, i, TLC5940_GammaCorrect(g));
      TLC5940_SetGS(2, i, TLC5940_GammaCorrect(b));

#else // TLC5940_ENABLE_MULTIPLEXING

      // Turn off the output from the previous channel
      TLC5940_SetGS((i - 1) % TLC5940_CHANNELS_N, 0);

      // Turn on the output for the current channel
      TLC5940_SetGS(i, 4095);

#endif // TLC5940_ENABLE_MULTIPLEXING

      // Tell the library to start using the new grayscale values
      TLC5940_SetGSUpdateFlag();

      // Delay for a bit, so we can actually see what is happening
      _delay_ms(10);
    }

    // Loop backwards over all output channels, skipping the last and first
    for (channel_t i = TLC5940_CHANNELS_N - 1; i > 0; --i) {

      // Wait until we are allowed to update the grayscale values
      while(TLC5940_GetGSUpdateFlag());

#if (TLC5940_ENABLE_MULTIPLEXING)

      // Default all outputs to off
      for (uint8_t row = 0; row < TLC5940_MULTIPLEX_N; row++)
        TLC5940_SetAllGS(row, 0);

      // Get the color associated with our current place in the spectrum
      uint8_t r = 0;
      uint8_t g = 0;
      uint8_t b = 0;
      SetColorToIndex(color_index, &r, &g, &b);

      // Increment our place in the spectrum by 1, accounting for rollover
      if (++color_index >= 768)
        color_index = 0;

      // Set the RGB color for the current channel
      TLC5940_SetGS(0, i, TLC5940_GammaCorrect(r));
      TLC5940_SetGS(1, i, TLC5940_GammaCorrect(g));
      TLC5940_SetGS(2, i, TLC5940_GammaCorrect(b));

#else // TLC5940_ENABLE_MULTIPLEXING

      // Turn off the output from the previous channel
      TLC5940_SetGS((i + 1) % TLC5940_CHANNELS_N, 0);

      // Turn on the output from the current channel
      TLC5940_SetGS(i, 4095);

#endif // TLC5940_ENABLE_MULTIPLEXING

      // Tell the library to start using the new grayscale values
      TLC5940_SetGSUpdateFlag();

      // Delay for a bit, so we can actually see what is happening
      _delay_ms(10);
    }
  }

  return 0;
}
