/*
* 	Copyright (c) Altera Corporation 2002.
* 	All rights reserved.
*
*	UARTComm.h
*
*       Function prototypes and definitions to use the UART IO functions
*/

#ifndef UARTCOMM_H
#define UARTCOMM_H


#define BUFF_SIZE	16384
#define BUFF_MASK	0x3FFF
#define EOF (-1)

#define UART00_TYPE (volatile unsigned int*)

void uart_start_tx(void);
void uart_init(void);
void uart_irq_handler(void);

#endif /* UARTCOMM_H */
