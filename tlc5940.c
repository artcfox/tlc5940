/*

  tlc5940.c

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

#include <avr/interrupt.h>
#include <util/delay_basic.h>

#include "tlc5940.h"

#if (TLC5940_ENABLE_MULTIPLEXING)

uint8_t gsData[TLC5940_MULTIPLEX_N][gsDataSize];
static uint8_t gsDataCache[TLC5940_MULTIPLEX_N][gsDataSize];
uint8_t *pBack;

// If the pins we are multiplexing across come from the same PORT as XLAT,
// then we don't need to toggle XLAT separately, we can toggle XLAT
// during the same clock cycle that we toggle the MOSFET pins. If BLANK
// also shares the same PORT, then we can toggle BLANK during that same
// clock cycle as well. We also need to be careful not to violate the
// setup and hold times as described in the datasheet.
#if (MULTIPLEX_AND_XLAT_SHARE_PORT == 1)
#if (BLANK_AND_XLAT_SHARE_PORT == 1)
#define TLC5940_TR_EXTRAS ((1 << BLANK_PIN) | (1 << XLAT_PIN))
#else // BLANK_AND_XLAT_SHARE_PORT
#define TLC5940_TR_EXTRAS (1 << XLAT_PIN)
#endif // BLANK_AND_XLAT_SHARE_PORT
#else // MULTIPLEX_AND_XLAT_SHARE_PORT
#define TLC5940_TR_EXTRAS 0
#endif // MULTIPLEX_AND_XLAT_SHARE_PORT

// The toggleRows array now starts on the second to last channel
const uint8_t toggleRows[2 * TLC5940_MULTIPLEX_N] = {
#if (TLC5940_MULTIPLEX_N == 1)
  (1 << ROW0_PIN) | TLC5940_TR_EXTRAS,
  (1 << ROW0_PIN) | TLC5940_TR_EXTRAS,
#elif (TLC5940_MULTIPLEX_N == 2)
  (1 << ROW1_PIN) | TLC5940_TR_EXTRAS, (1 << ROW0_PIN) | TLC5940_TR_EXTRAS,
  (1 << ROW0_PIN) | TLC5940_TR_EXTRAS, (1 << ROW1_PIN) | TLC5940_TR_EXTRAS,
#elif (TLC5940_MULTIPLEX_N == 3) 
  (1 << ROW2_PIN) | TLC5940_TR_EXTRAS, (1 << ROW0_PIN) | TLC5940_TR_EXTRAS,
  (1 << ROW1_PIN) | TLC5940_TR_EXTRAS,
  (1 << ROW1_PIN) | TLC5940_TR_EXTRAS, (1 << ROW2_PIN) | TLC5940_TR_EXTRAS,
  (1 << ROW0_PIN) | TLC5940_TR_EXTRAS,
#elif (TLC5940_MULTIPLEX_N == 4)
  (1 << ROW3_PIN) | TLC5940_TR_EXTRAS, (1 << ROW0_PIN) | TLC5940_TR_EXTRAS,
  (1 << ROW1_PIN) | TLC5940_TR_EXTRAS, (1 << ROW2_PIN) | TLC5940_TR_EXTRAS,
  (1 << ROW2_PIN) | TLC5940_TR_EXTRAS, (1 << ROW3_PIN) | TLC5940_TR_EXTRAS,
  (1 << ROW0_PIN) | TLC5940_TR_EXTRAS, (1 << ROW1_PIN) | TLC5940_TR_EXTRAS,
#elif (TLC5940_MULTIPLEX_N == 5)
  (1 << ROW4_PIN) | TLC5940_TR_EXTRAS, (1 << ROW0_PIN) | TLC5940_TR_EXTRAS,
  (1 << ROW1_PIN) | TLC5940_TR_EXTRAS, (1 << ROW2_PIN) | TLC5940_TR_EXTRAS,
  (1 << ROW3_PIN) | TLC5940_TR_EXTRAS,
  (1 << ROW3_PIN) | TLC5940_TR_EXTRAS, (1 << ROW4_PIN) | TLC5940_TR_EXTRAS,
  (1 << ROW0_PIN) | TLC5940_TR_EXTRAS, (1 << ROW1_PIN) | TLC5940_TR_EXTRAS,
  (1 << ROW2_PIN) | TLC5940_TR_EXTRAS,
#elif (TLC5940_MULTIPLEX_N == 6)
  (1 << ROW5_PIN) | TLC5940_TR_EXTRAS, (1 << ROW0_PIN) | TLC5940_TR_EXTRAS,
  (1 << ROW1_PIN) | TLC5940_TR_EXTRAS, (1 << ROW2_PIN) | TLC5940_TR_EXTRAS,
  (1 << ROW3_PIN) | TLC5940_TR_EXTRAS, (1 << ROW4_PIN) | TLC5940_TR_EXTRAS,
  (1 << ROW4_PIN) | TLC5940_TR_EXTRAS, (1 << ROW5_PIN) | TLC5940_TR_EXTRAS,
  (1 << ROW0_PIN) | TLC5940_TR_EXTRAS, (1 << ROW1_PIN) | TLC5940_TR_EXTRAS,
  (1 << ROW2_PIN) | TLC5940_TR_EXTRAS, (1 << ROW3_PIN) | TLC5940_TR_EXTRAS,
#elif (TLC5940_MULTIPLEX_N == 7)
  (1 << ROW6_PIN) | TLC5940_TR_EXTRAS, (1 << ROW0_PIN) | TLC5940_TR_EXTRAS,
  (1 << ROW1_PIN) | TLC5940_TR_EXTRAS, (1 << ROW2_PIN) | TLC5940_TR_EXTRAS,
  (1 << ROW3_PIN) | TLC5940_TR_EXTRAS, (1 << ROW4_PIN) | TLC5940_TR_EXTRAS,
  (1 << ROW5_PIN) | TLC5940_TR_EXTRAS,
  (1 << ROW5_PIN) | TLC5940_TR_EXTRAS, (1 << ROW6_PIN) | TLC5940_TR_EXTRAS,
  (1 << ROW0_PIN) | TLC5940_TR_EXTRAS, (1 << ROW1_PIN) | TLC5940_TR_EXTRAS,
  (1 << ROW2_PIN) | TLC5940_TR_EXTRAS, (1 << ROW3_PIN) | TLC5940_TR_EXTRAS,
  (1 << ROW4_PIN) | TLC5940_TR_EXTRAS,
#elif (TLC5940_MULTIPLEX_N == 8)
  (1 << ROW7_PIN) | TLC5940_TR_EXTRAS, (1 << ROW0_PIN) | TLC5940_TR_EXTRAS,
  (1 << ROW1_PIN) | TLC5940_TR_EXTRAS, (1 << ROW2_PIN) | TLC5940_TR_EXTRAS,
  (1 << ROW3_PIN) | TLC5940_TR_EXTRAS, (1 << ROW4_PIN) | TLC5940_TR_EXTRAS,
  (1 << ROW5_PIN) | TLC5940_TR_EXTRAS, (1 << ROW6_PIN) | TLC5940_TR_EXTRAS,
  (1 << ROW6_PIN) | TLC5940_TR_EXTRAS, (1 << ROW7_PIN) | TLC5940_TR_EXTRAS,
  (1 << ROW0_PIN) | TLC5940_TR_EXTRAS, (1 << ROW1_PIN) | TLC5940_TR_EXTRAS,
  (1 << ROW2_PIN) | TLC5940_TR_EXTRAS, (1 << ROW3_PIN) | TLC5940_TR_EXTRAS,
  (1 << ROW4_PIN) | TLC5940_TR_EXTRAS, (1 << ROW5_PIN) | TLC5940_TR_EXTRAS,
#endif // TLC5940_MULTIPLEX_N
}; // const toggleRows[2 * TLC5940_MULTIPLEX_N]
#else // TLC5940_ENABLE_MULTIPLEXING
uint8_t gsData[gsDataSize];
#endif // TLC5940_ENABLE_MULTIPLEXING

#if (TLC5940_USE_GPIOR0 == 0)
volatile bool gsUpdateFlag;
#endif // TLC5940_USE_GPIOR0

#if (TLC5940_INCLUDE_GAMMA_CORRECT)
#if (TLC5940_PWM_BITS == 12)
#define V 4095.0
#elif (TLC5940_PWM_BITS == 11)
#define V 2047.0
#elif (TLC5940_PWM_BITS == 10)
#define V 1023.0
#elif (TLC5940_PWM_BITS == 9)
#define V 511.0
#elif (TLC5940_PWM_BITS == 8)
#define V 255.0
#else
#error "TLC5940_PWM_BITS must be 8, 9, 10, 11, or 12"
#endif // TLC5940_PWM_BITS
// Maps a linear 8-bit value to a TLC5940_PWM_BITS-bit gamma corrected value
// This array was computer-generated using the following formula:
// for (uint16_t x = 0; x < 256; x++)
//   printf("%e*V+.5, ", (pow((double)x / 255.0, 2.5)));
const uint16_t TLC5940_GammaCorrect[] PROGMEM = {
  0.000000e+00*V+.5, 9.630516e-07*V+.5, 5.447842e-06*V+.5, 1.501249e-05*V+.5,
  3.081765e-05*V+.5, 5.383622e-05*V+.5, 8.492346e-05*V+.5, 1.248518e-04*V+.5,
  1.743310e-04*V+.5, 2.340215e-04*V+.5, 3.045437e-04*V+.5, 3.864838e-04*V+.5,
  4.803996e-04*V+.5, 5.868241e-04*V+.5, 7.062682e-04*V+.5, 8.392236e-04*V+.5,
  9.861648e-04*V+.5, 1.147551e-03*V+.5, 1.323826e-03*V+.5, 1.515422e-03*V+.5,
  1.722759e-03*V+.5, 1.946246e-03*V+.5, 2.186282e-03*V+.5, 2.443257e-03*V+.5,
  2.717551e-03*V+.5, 3.009536e-03*V+.5, 3.319578e-03*V+.5, 3.648035e-03*V+.5,
  3.995256e-03*V+.5, 4.361587e-03*V+.5, 4.747366e-03*V+.5, 5.152925e-03*V+.5,
  5.578591e-03*V+.5, 6.024686e-03*V+.5, 6.491527e-03*V+.5, 6.979425e-03*V+.5,
  7.488689e-03*V+.5, 8.019621e-03*V+.5, 8.572521e-03*V+.5, 9.147682e-03*V+.5,
  9.745397e-03*V+.5, 1.036595e-02*V+.5, 1.100963e-02*V+.5, 1.167672e-02*V+.5,
  1.236748e-02*V+.5, 1.308220e-02*V+.5, 1.382115e-02*V+.5, 1.458459e-02*V+.5,
  1.537279e-02*V+.5, 1.618601e-02*V+.5, 1.702451e-02*V+.5, 1.788854e-02*V+.5,
  1.877837e-02*V+.5, 1.969424e-02*V+.5, 2.063640e-02*V+.5, 2.160510e-02*V+.5,
  2.260058e-02*V+.5, 2.362309e-02*V+.5, 2.467286e-02*V+.5, 2.575014e-02*V+.5,
  2.685516e-02*V+.5, 2.798815e-02*V+.5, 2.914934e-02*V+.5, 3.033898e-02*V+.5,
  3.155727e-02*V+.5, 3.280446e-02*V+.5, 3.408077e-02*V+.5, 3.538641e-02*V+.5,
  3.672162e-02*V+.5, 3.808661e-02*V+.5, 3.948159e-02*V+.5, 4.090679e-02*V+.5,
  4.236242e-02*V+.5, 4.384870e-02*V+.5, 4.536583e-02*V+.5, 4.691403e-02*V+.5,
  4.849350e-02*V+.5, 5.010446e-02*V+.5, 5.174710e-02*V+.5, 5.342165e-02*V+.5,
  5.512829e-02*V+.5, 5.686723e-02*V+.5, 5.863868e-02*V+.5, 6.044283e-02*V+.5,
  6.227988e-02*V+.5, 6.415003e-02*V+.5, 6.605348e-02*V+.5, 6.799041e-02*V+.5,
  6.996104e-02*V+.5, 7.196554e-02*V+.5, 7.400411e-02*V+.5, 7.607694e-02*V+.5,
  7.818422e-02*V+.5, 8.032614e-02*V+.5, 8.250289e-02*V+.5, 8.471466e-02*V+.5,
  8.696162e-02*V+.5, 8.924397e-02*V+.5, 9.156189e-02*V+.5, 9.391556e-02*V+.5,
  9.630516e-02*V+.5, 9.873087e-02*V+.5, 1.011929e-01*V+.5, 1.036914e-01*V+.5,
  1.062265e-01*V+.5, 1.087985e-01*V+.5, 1.114074e-01*V+.5, 1.140536e-01*V+.5,
  1.167371e-01*V+.5, 1.194582e-01*V+.5, 1.222169e-01*V+.5, 1.250135e-01*V+.5,
  1.278482e-01*V+.5, 1.307211e-01*V+.5, 1.336324e-01*V+.5, 1.365822e-01*V+.5,
  1.395708e-01*V+.5, 1.425983e-01*V+.5, 1.456648e-01*V+.5, 1.487705e-01*V+.5,
  1.519157e-01*V+.5, 1.551004e-01*V+.5, 1.583249e-01*V+.5, 1.615892e-01*V+.5,
  1.648936e-01*V+.5, 1.682382e-01*V+.5, 1.716232e-01*V+.5, 1.750487e-01*V+.5,
  1.785149e-01*V+.5, 1.820220e-01*V+.5, 1.855701e-01*V+.5, 1.891593e-01*V+.5,
  1.927899e-01*V+.5, 1.964620e-01*V+.5, 2.001758e-01*V+.5, 2.039313e-01*V+.5,
  2.077289e-01*V+.5, 2.115685e-01*V+.5, 2.154504e-01*V+.5, 2.193747e-01*V+.5,
  2.233416e-01*V+.5, 2.273512e-01*V+.5, 2.314038e-01*V+.5, 2.354993e-01*V+.5,
  2.396381e-01*V+.5, 2.438201e-01*V+.5, 2.480457e-01*V+.5, 2.523149e-01*V+.5,
  2.566279e-01*V+.5, 2.609848e-01*V+.5, 2.653858e-01*V+.5, 2.698310e-01*V+.5,
  2.743207e-01*V+.5, 2.788548e-01*V+.5, 2.834336e-01*V+.5, 2.880572e-01*V+.5,
  2.927258e-01*V+.5, 2.974395e-01*V+.5, 3.021985e-01*V+.5, 3.070028e-01*V+.5,
  3.118527e-01*V+.5, 3.167483e-01*V+.5, 3.216896e-01*V+.5, 3.266770e-01*V+.5,
  3.317105e-01*V+.5, 3.367902e-01*V+.5, 3.419163e-01*V+.5, 3.470889e-01*V+.5,
  3.523082e-01*V+.5, 3.575743e-01*V+.5, 3.628874e-01*V+.5, 3.682475e-01*V+.5,
  3.736549e-01*V+.5, 3.791096e-01*V+.5, 3.846119e-01*V+.5, 3.901617e-01*V+.5,
  3.957594e-01*V+.5, 4.014049e-01*V+.5, 4.070985e-01*V+.5, 4.128403e-01*V+.5,
  4.186304e-01*V+.5, 4.244690e-01*V+.5, 4.303562e-01*V+.5, 4.362920e-01*V+.5,
  4.422767e-01*V+.5, 4.483105e-01*V+.5, 4.543933e-01*V+.5, 4.605254e-01*V+.5,
  4.667068e-01*V+.5, 4.729378e-01*V+.5, 4.792185e-01*V+.5, 4.855489e-01*V+.5,
  4.919292e-01*V+.5, 4.983596e-01*V+.5, 5.048401e-01*V+.5, 5.113710e-01*V+.5,
  5.179523e-01*V+.5, 5.245841e-01*V+.5, 5.312666e-01*V+.5, 5.380000e-01*V+.5,
  5.447842e-01*V+.5, 5.516196e-01*V+.5, 5.585062e-01*V+.5, 5.654441e-01*V+.5,
  5.724334e-01*V+.5, 5.794743e-01*V+.5, 5.865670e-01*V+.5, 5.937114e-01*V+.5,
  6.009079e-01*V+.5, 6.081564e-01*V+.5, 6.154571e-01*V+.5, 6.228102e-01*V+.5,
  6.302157e-01*V+.5, 6.376738e-01*V+.5, 6.451846e-01*V+.5, 6.527482e-01*V+.5,
  6.603648e-01*V+.5, 6.680345e-01*V+.5, 6.757574e-01*V+.5, 6.835336e-01*V+.5,
  6.913632e-01*V+.5, 6.992464e-01*V+.5, 7.071833e-01*V+.5, 7.151740e-01*V+.5,
  7.232186e-01*V+.5, 7.313173e-01*V+.5, 7.394701e-01*V+.5, 7.476773e-01*V+.5,
  7.559389e-01*V+.5, 7.642549e-01*V+.5, 7.726257e-01*V+.5, 7.810512e-01*V+.5,
  7.895316e-01*V+.5, 7.980670e-01*V+.5, 8.066575e-01*V+.5, 8.153033e-01*V+.5,
  8.240044e-01*V+.5, 8.327611e-01*V+.5, 8.415733e-01*V+.5, 8.504412e-01*V+.5,
  8.593650e-01*V+.5, 8.683447e-01*V+.5, 8.773805e-01*V+.5, 8.864724e-01*V+.5,
  8.956207e-01*V+.5, 9.048254e-01*V+.5, 9.140865e-01*V+.5, 9.234044e-01*V+.5,
  9.327790e-01*V+.5, 9.422104e-01*V+.5, 9.516989e-01*V+.5, 9.612445e-01*V+.5,
  9.708472e-01*V+.5, 9.805073e-01*V+.5, 9.902249e-01*V+.5, 1.000000e+00*V+.5,
};
#undef V
#endif // TLC5940_INCLUDE_GAMMA_CORRECT

#if (TLC5940_PWM_BITS == 12)
// Generate an interrupt every 4096 clock cycles
#define TLC5940_CTC_TOP 15
#elif (TLC5940_PWM_BITS == 11)
// Generate an interrupt every 2048 clock cycles
#define TLC5940_CTC_TOP 7
#elif (TLC5940_PWM_BITS == 10)
// Generate an interrupt every 1024 clock cycles
#define TLC5940_CTC_TOP 3
#elif (TLC5940_PWM_BITS == 9)
// Generate an interrupt every 512 clock cycles
#define TLC5940_CTC_TOP 1
#elif (TLC5940_PWM_BITS == 8)
// Generate an interrupt every 256 clock cycles
#define TLC5940_CTC_TOP 0
#else
#error "TLC5940_PWM_BITS must be 8, 9, 10, 11, or 12"
#endif // TLC5940_PWM_BITS

void TLC5940_Init(void) {
  setOutput(SCLK_DDR, SCLK_PIN);
  setLow(SCLK_PORT, SCLK_PIN);
#if (TLC5940_VPRG_DCPRG_HARDWIRED_TO_GND == 0)
  setOutput(DCPRG_DDR, DCPRG_PIN);
  setLow(DCPRG_PORT, DCPRG_PIN);
  setOutput(VPRG_DDR, VPRG_PIN);
  setHigh(VPRG_PORT, VPRG_PIN);
#endif // TLC5940_VPRG_DCPRG_HARDWIRED_TO_GND
  setOutput(XLAT_DDR, XLAT_PIN);
  setLow(XLAT_PORT, XLAT_PIN);

  // setHigh called first to ensure BLANK doesn't briefly go low
  setHigh(BLANK_PORT, BLANK_PIN);
  setOutput(BLANK_DDR, BLANK_PIN);

  setOutput(SIN_DDR, SIN_PIN);
#if (TLC5940_SPI_MODE == 2)
  setLow(SIN_PORT, SIN_PIN); // since USI only toggles, start in known state
#endif // TLC5940_SPI_MODE

  TLC5940_SetGSUpdateFlag();

#if (TLC5940_ENABLE_MULTIPLEXING)
  // Set multiplex pins as outputs, and turn all multiplexing MOSFETs off
  setHigh(MULTIPLEX_PORT, ROW0_PIN);
  setOutput(MULTIPLEX_DDR, ROW0_PIN);
#if (TLC5940_MULTIPLEX_N > 1)
  setHigh(MULTIPLEX_PORT, ROW1_PIN);
  setOutput(MULTIPLEX_DDR, ROW1_PIN);
#endif // TLC5940_MULTIPLEX_N
#if (TLC5940_MULTIPLEX_N > 2)
  setHigh(MULTIPLEX_PORT, ROW2_PIN);
  setOutput(MULTIPLEX_DDR, ROW2_PIN);
#endif // TLC5940_MULTIPLEX_N
#if (TLC5940_MULTIPLEX_N > 3)
  setHigh(MULTIPLEX_PORT, ROW3_PIN);
  setOutput(MULTIPLEX_DDR, ROW3_PIN);
#endif // TLC5940_MULTIPLEX_N
#if (TLC5940_MULTIPLEX_N > 4)
  setHigh(MULTIPLEX_PORT, ROW4_PIN);
  setOutput(MULTIPLEX_DDR, ROW4_PIN);
#endif // TLC5940_MULTIPLEX_N
#if (TLC5940_MULTIPLEX_N > 5)
  setHigh(MULTIPLEX_PORT, ROW5_PIN);
  setOutput(MULTIPLEX_DDR, ROW5_PIN);
#endif // TLC5940_MULTIPLEX_N
#if (TLC5940_MULTIPLEX_N > 6)
  setHigh(MULTIPLEX_PORT, ROW6_PIN);
  setOutput(MULTIPLEX_DDR, ROW6_PIN);
#endif // TLC5940_MULTIPLEX_N
#if (TLC5940_MULTIPLEX_N > 7)
  setHigh(MULTIPLEX_PORT, ROW7_PIN);
  setOutput(MULTIPLEX_DDR, ROW7_PIN);
#endif // TLC5940_MULTIPLEX_N

  // Initialize the write pointer for page-flipping
  pBack = &gsDataCache[0][0];
#else // TLC5940_ENABLE_MULTIPLEXING
  TLC5940_ClearXLATNeedsPulseFlag();
#endif // TLC5940_ENABLE_MULTIPLEXING

#if (TLC5940_SPI_MODE == 0)
  // Enable SPI, Master, set clock rate fck/2
  SPCR = (1 << SPE) | (1 << MSTR);
  SPSR = (1 << SPI2X);
#elif (TLC5940_SPI_MODE == 1)
  // Baud rate must be set to 0 prior to enabling the USART as SPI
  // master, to ensure proper initialization of the XCK line.
  UBRR0 = 0;
  // Set USART to Master SPI mode.
  UCSR0C = (1 << UMSEL01) | (1 << UMSEL00);
  // Enable TX only
  UCSR0B = (1 << TXEN0);
  // Set baud rate. Must be set _after_ enabling the transmitter.
  UBRR0 = 0;
#endif // TLC5940_SPI_MODE

#if (TLC5940_ISR_CTC_TIMER == 0)
  // CTC with OCR0A as TOP
  TCCR0A = (1 << WGM01);
  // clk_io/256 (From prescaler)
  TCCR0B = (1 << CS02);
  // Generate an interrupt every (TLC5940_CTC_TOP + 1) * 256 clock cycles
  OCR0A = TLC5940_CTC_TOP;

  // Enable Timer/Counter0 Compare Match A interrupt
#ifdef TIMSK0
  TIMSK0 |= (1 << OCIE0A);
#else // TIMSK0
  TIMSK |= (1 << OCIE0A);
#endif // TIMSK0

#elif (TLC5940_ISR_CTC_TIMER == 2)
  // CTC with OCR2A as TOP
  TCCR2A = (1 << WGM21);
  // clk_io/256 (From prescaler)
  TCCR2B = (1 << CS22) | (1 << CS21);
  // Generate an interrupt every (TLC5940_CTC_TOP + 1) * 256 clock cycles
  OCR2A = TLC5940_CTC_TOP;
  // Enable Timer/Counter2 Compare Match A interrupt
  TIMSK2 |= (1 << OCIE2A);
#else
#error "TLC5940_ISR_CTC_TIMER must be 0 or 2"
#endif // TLC5940_ISR_CTC_TIMER
}

void TLC5940_ClockInGS(void) {
  // Manually load in a bunch of dummy data (all zeroes), so the ISR
  // doesn't have to have extra conditionals for firstCycleFlag or
  // worry about having to pulse SCLK one extra time in those cases.

#if (TLC5940_VPRG_DCPRG_HARDWIRED_TO_GND == 0)
  bool firstCycleFlag = false;
  if (getValue(VPRG_PORT, VPRG_PIN)) {
    setLow(VPRG_PORT, VPRG_PIN);
    firstCycleFlag = true;
  }
#endif // TLC5940_VPRG_DCPRG_HARDWIRED_TO_GND

  // Normally we would set BLANK low here (it should still be high
  // from the previous call to TLC5940_Init), but the TLC5940's
  // grayscale registers will contain garbage right after powering on
  // so by keeping BLANK high, we will prevent that garbage from being
  // displayed, and then we will clock in all zeroes to prevent that
  // garbage from ever being displayed.

  for (gsData_t i = 0; i < gsDataSize; i++)
    TLC5940_TX(0x00); // clock in zeroes, since this data will be latched now

#if (TLC5940_SPI_MODE == 1)
  _delay_loop_1(12); // delay until double-buffered TX register is clear
#endif // TLC5940_SPI_MODE

  // If we hadn't skipped setting BLANK low above, this is where we
  // would have set it back to high.

  pulse(XLAT_PORT, XLAT_PIN);
#if (TLC5940_VPRG_DCPRG_HARDWIRED_TO_GND == 0)
  if (firstCycleFlag) {
#endif // TLC5940_VPRG_DCPRG_HARDWIRED_TO_GND

#if (TLC5940_SPI_MODE == 0)
    SPCR = SPSR = 0;

    setHigh(SCLK_PORT, SCLK_PIN);
    // SCLK will be set low automatically by the SPI hardware

    SPCR = (1 << SPE) | (1 << MSTR);
    SPSR = (1 << SPI2X);
#elif (TLC5940_SPI_MODE == 1)

    // According to the ATmega328P datasheet, we should only have to
    // disable the transmitter in order to manually pulse the XCK pin,
    // however my logic analyzer disagrees.

    // Disable the USART Master SPI Mode, and Transmitter completely
    UCSR0C = UCSR0B = 0;

    // Only now can we manually pulse our XCK pin to provide an extra
    // pulse on SCLK. To ensure we only get a single pulse (rather than
    // a double pulse) we only call setHigh(), rather than pulse()
    // because re-enabling the USART as SPI master below will force
    // the XCK pin back low, but sometimes it will briefly be set high
    // first, which would result in a double pulse.

    setHigh(SCLK_PORT, SCLK_PIN);

    // Baud rate must be set to 0 prior to enabling the USART as SPI
    // master, to ensure proper initialization of the XCK line.
    UBRR0 = 0;
    // Set USART to Master SPI mode.
    UCSR0C = (1 << UMSEL01) | (1 << UMSEL00);
    // Enable TX only
    UCSR0B = (1 << TXEN0);
    // Set baud rate. Must be set _after_ enabling the transmitter.
    UBRR0 = 0;
#elif (TLC5940_SPI_MODE == 2)
    pulse(SCLK_PORT, SCLK_PIN);
#endif // TLC5940_SPI_MODE
#if (TLC5940_VPRG_DCPRG_HARDWIRED_TO_GND == 0)
  }
#endif // TLC5940_VPRG_DCPRG_HARDWIRED_TO_GND

#if (TLC5940_ENABLE_MULTIPLEXING)
  // Turn on the last multiplexing MOSFET (so the toggle function works).
  // The "& ~(TLC5940_TR_EXTRAS)" is so we don't erroneously toggle
  // XLAT/BLANK if they share the same PORT as the MULTIPLEX pins.
  MULTIPLEX_INPUT = toggleRows[TLC5940_MULTIPLEX_N] & ~(TLC5940_TR_EXTRAS);

  // Shift in more zeroes, since the first thing the ISR does is pulse XLAT
  for (gsData_t i = 0; i < gsDataSize; i++)
    TLC5940_TX(0x00);

#if (TLC5940_SPI_MODE == 1)
  _delay_loop_1(12); // delay until double-buffered TX register is clear
#endif // TLC5940_SPI_MODE

#endif // TLC5940_ENABLE_MULTIPLEXING

  // Set BLANK low, so the ISR can do a toggle, which is quicker
  setLow(BLANK_PORT, BLANK_PIN);
}

#if (TLC5940_ENABLE_MULTIPLEXING == 0)
#if (TLC5940_USE_GPIOR0 == 0)
bool xlatNeedsPulse;
#endif // TLC5940_USE_GPIOR0
#endif // TLC5940_ENABLE_MULTIPLEXING

#if (TLC5940_INCLUDE_DEFAULT_ISR)
// Interrupt gets called every (TLC5940_CTC_TOP + 1) * 256 clock cycles
ISR(TLC5940_TIMER_COMPA_vect) {
#if (TLC5940_ENABLE_MULTIPLEXING)

  static uint8_t *pFront = &gsData[0][0]; // read pointer
  static uint8_t row; // the row we are clocking new data out for
  const uint8_t *p = toggleRows + row; // force efficient use of Z-pointer
  uint8_t tmp1 = *p;
  uint8_t tmp2 = *(p + TLC5940_MULTIPLEX_N);

  TLC5940_ToggleBLANK_XLAT();
  MULTIPLEX_INPUT = tmp2; // turn off the previous row
  TLC5940_RespectSetupAndHoldTimes();
  MULTIPLEX_INPUT = tmp1; // turn on the next row
  TLC5940_ToggleXLAT_BLANK();
  // We now have (TLC5940_CTC_TOP + 1) * 256 clocks to send data for next cycle

  // Only page-flip if new data is ready and we finished displaying all rows
  if (TLC5940_GetGSUpdateFlag() && row == 0) {
    uint8_t *tmp = pFront;
    pFront = pBack;
    pBack = tmp;
    TLC5940_ClearGSUpdateFlag();
    __asm__ volatile ("" ::: "memory"); // ensure pBack gets re-read
  }

  gsOffset_t offset = (gsOffset_t)gsDataSize * row;
  gsData_t i = gsDataSize + 1;
  while (--i) // loop over gsData[row][i] or gsDataCache[row][i]
    TLC5940_TX(*(pFront + offset++));

  if (++row == TLC5940_MULTIPLEX_N)
    row = 0;

#else // TLC5940_ENABLE_MULTIPLEXING

  if (TLC5940_GetXLATNeedsPulseFlag()) {
    TLC5940_ToggleBLANK_XLAT();
    TLC5940_RespectSetupAndHoldTimes();
    TLC5940_ToggleXLAT_BLANK();
    TLC5940_ClearXLATNeedsPulseFlag();
  } else {
    togglePin(BLANK_INPUT, BLANK_PIN); // high
    TLC5940_RespectSetupAndHoldTimes();
    togglePin(BLANK_INPUT, BLANK_PIN); // low
  }
  // We now have (TLC5940_CTC_TOP + 1) * 256 clocks to send data for next cycle

  if (TLC5940_GetGSUpdateFlag()) {
    for (gsData_t i = 0; i < gsDataSize; i++)
      TLC5940_TX(gsData[i]);
    TLC5940_SetXLATNeedsPulseFlagAndClearGSUpdateFlag(); // faster than separate
  }

#endif // TLC5940_ENABLE_MULTIPLEXING
}
#endif // TLC5940_INCLUDE_DEFAULT_ISR
