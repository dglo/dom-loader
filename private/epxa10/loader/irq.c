/*
*    Simple interrupt controller intialisation and fist level
*	 IRQ and FIQ handlers
*
*    Copyright (c) Altera Corporation 2000-2001.
*    All rights reserved.
*/

#include <stdio.h>

#include "irq.h"

#include "booter/epxa.h"

#define EXC_INT_CTRL00_BASE (REGISTERS + 0xc00)
#include "int_ctrl00.h"
#include "uartcomm.h"

#define INT_CTRL00_TYPE (volatile unsigned int *)
#define UART_IRQ_PRI 2

void uart_irq_handler(void);

void irq_init(void) {
   /*
    *	Disable the interrupts for all the PLD sources
    *	confusingly enough these are all on by default
    *	The reason is in case people want to implement their own
    *	interrupt controller in the PLD they don't have to write
    *	any code to enable interrupts in the Excalibur controller
    */
   *INT_MC(EXC_INT_CTRL00_BASE) =	
      INT_MC_P0_MSK | INT_MC_P1_MSK |
      INT_MC_P2_MSK | INT_MC_P3_MSK |
      INT_MC_P4_MSK | INT_MC_P5_MSK;
   
   /*
    * Set priority for the UART interrupts
    */
   *INT_PRIORITY_UA(EXC_INT_CTRL00_BASE)=UART_IRQ_PRI;
   
   /*
    *	Enable the UART interrupt
    */
   *INT_MS(EXC_INT_CTRL00_BASE)=INT_MS_UA_MSK;
}

void CIrqHandler(void) {
   volatile int irqID;
   
   irqID = *INT_ID(EXC_INT_CTRL00_BASE);
   
   switch (irqID) {
      case UART_IRQ_PRI:
	 uart_irq_handler();
	 break;
      default:
	 /* This shouldn't happen, but let's trap it in case */
	 printf("Unknown irq\r\n");
	 break;
   }
}

void CFiqHandler(void) {
   /* This shouldn't happen */
}








