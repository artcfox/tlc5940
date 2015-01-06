#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>

#include "tlc5940.h"

int main(void) {
  TLC5940_Init();

#if (TLC5940_INCLUDE_DC_FUNCS)
  TLC5940_SetAllDC(63);
  TLC5940_ClockInDC();
#endif

  TLC5940_SetAllGS(0);
  TLC5940_ClockInGS();

  // Enable Global Interrupts
  sei();

  for (;;) {
    for (channel_t i = 0; i < TLC5940_CHANNELS_N; ++i) {     // loop forwards over all output channels
      while(TLC5940_GetGSUpdateFlag());                      // wait until we are allowed to update the grayscale values
      TLC5940_SetGS((i - 1) % TLC5940_CHANNELS_N, 0);        // turn off the output from the previous channel            
      TLC5940_SetGS(i, 4095);                                // turn on the output from the current channel              
      TLC5940_SetGSUpdateFlag();                             // tell the library to start using the new grayscale values 
      _delay_ms(25);                                         // delay for a bit, so we can actually see what is happening
    }
    for (channel_t i = TLC5940_CHANNELS_N - 1; i > 0; --i) { // loop backwards over all output channels, skipping the last and first
      while(TLC5940_GetGSUpdateFlag());                      // wait until we are allowed to update the grayscale values
      TLC5940_SetGS((i + 1) % TLC5940_CHANNELS_N, 0);        // turn off the output from the previous channel            
      TLC5940_SetGS(i, 4095);                                // turn on the output from the current channel              
      TLC5940_SetGSUpdateFlag();                             // tell the library to start using the new grayscale values 
      _delay_ms(25);                                         // delay for a bit, so we can actually see what is happening
    }
  }

  return 0;
}
