/*
*	Copyright (c) Altera Corporation 2002.
*	All rights reserved.
*
*	C Exception Handlers
*/
#include <stdio.h>

void CAbtHandler(void)
{
	printf("Data abort\r\n");
}

void CPabtHandler(void)
{
	printf("Error prefetch abort\r\n");
}

void CDabtHandler(void)
{
	printf("Error data abort\r\n");
}

void CSwiHandler(int swi)
{
	if (swi == 0x123456)
	{
		printf ("Exit\r\n");
	}
	else
	{
		printf("Error swi %x\r\n", swi);
	}
}


void CUdefHandler(void)
{
	printf("Error undefined instruction\r\n");
}
