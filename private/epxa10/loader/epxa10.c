/*
 * epxa10.c
 *
 * Copyright (c) Altera Corporation 2002.
 * All rights reserved.
 *
 * This file provides the functions necessary to run the Gnu C runtime
 * environment on the EPXA10. This is a minimal implementation in that
 * no file system support is provided. 
 *
 * The EPXA10 UART is used to implement standard in, standard out and 
 * standard error.
 *
 * The functions provided are those required by newlib:
 *
 *                       _write
 *                       isatty
 *                       _sbrk
 *                       _close
 *                       _fstat
 *                       _lseek
 *                       _read
 *
 * and their associated support functions for device initialisation, and
 * interrupt handling:
 *
 *                       uart_init
 *                       uart_tx_handler
 *                       uart_rx_handler
 *                       uart_irq_handler
 *  
 */

#include <sys/stat.h> 

#include "uartcomm.h"

#include "uart00.h"
#include "int_ctrl00.h"
#include "stripe.h"

extern char tx_buffer[BUFF_SIZE];
extern char rx_buffer[BUFF_SIZE];
extern volatile int tx_head,tx_tail,rx_head,rx_tail;


typedef void* Caddr_t; 

/*
 * _write directs output to the file indicated by 'file'. In this 
 * case all output is directed to the UART, regardless of the value
 * of 'file'. This is valid, since file open is not supported - so
 * the only valid file descriptors available are standard out and
 * standard error.
 *
 */

int _write(int file, char *ptr, int len)
{
	int retval=len;
	
	while (len)
	{
		/* Copy the character into the tx buffer */
		tx_buffer[tx_tail++]=*ptr;
		tx_tail&=BUFF_MASK;
		if(tx_tail==tx_head)
		{
			return -1;
		}
		++ptr;
		len--;
	}	
		
	/* Give the transmitter a kick */
	uart_start_tx();

	/* Everything is OK... */
	return retval-len;
}	 

/*
 * Test if a valid file descriptor is a TTY device. In our case this 
 * is always true.
 */

int isatty(int file){
	return 1;
}

/* 
 * _sbrk is used to implement malloc(). In this case the heap is 
 * defined to grow up from the end of the code image.
 */

Caddr_t _sbrk(int incr){
	extern char end;
	
	static char* heap_end;
	char* prev_heap_end;
	
	if (heap_end == 0) { 
      heap_end = &end; 
   } 
   prev_heap_end = heap_end; 
   heap_end += incr; 
   return (caddr_t) prev_heap_end; 
} 	 

/*
 * _close will close an open file. Since no files can be opened,
 * it isn't possible to close them...
 */
	
int _close(int file)
{
	return -1;
}
	
/*
 * Obtain file status information.
 */

int _fstat(int file, struct stat *st) { 
   st->st_mode = S_IFCHR; 
   return 0; 
} 

/* 
 * Seek a position within a file. This is not possible for the
 * stdio streams, which are the only valid file descriptors for
 * our system.
 */

int _lseek(int file, int ptr, int dir){ 
   return 0; 
} 

/* 
 * Read from a file. This is always interpreted as a read from 
 * standard in, regardless of the value of 'file'. Standard in
 * is implemented using the EPXA10 UART.
 */
 
int _read(int file, char *ptr, int len){ 
	int characters=0;
	
	/* Block waiting for a character */
	while(rx_head==rx_tail);
	
	/* Process any more characters */
	while(rx_head!=rx_tail)
	{
		if (characters > len)
		{
			break;
		}
		else
		{
			*ptr=rx_buffer[rx_head++];
			rx_head&=BUFF_MASK;
			ptr++;
			characters++;
		}
	}
	return characters;	
}

/*
*	Exit a process
*/
void _exit( int status )
{
	while(1);
}
