#
# uart.awk, initialize the serial port...
#
# uses the config file to get the correct
# parameters...
#
BEGIN {
  regs = 0;
  uart_mc = 0;
  baud = 0;
  ahb2 = 0;
}

/^REGISTERS/ {
  regs = numericValue($2);
}

/^AHB1/ {
  ahb2 = int(numericValue($2)/2);
}

/^UART_SETTINGS/ {
  baud = numericValue($2);

  if ($3 == "N" ) {}
  else if ($3 == "E") {
    uart_mc = or(uart_mc, lshift(3, 3));
  }
  else if ($3 == "O") {
    uart_mc = or(uart_mc, lshift(1, 3));
  }
  else {
    printf("invalid parity setting (" $3 ")\n");
    exit(1);
  }

  if ($4<5 || $4>8) {
    printf("invalid number of character bits (" $4 "), [5..8] allowed\n");
    exit(1);
  }
  uart_mc = or(uart_mc, int($4-5));

  if ($5<1 || $5>2) {
    printf("invalid number of stop bits (" $5 "), [1..2] allowed\n");
    exit(1);
  }
  uart_mc = or(uart_mc, lshift(int($5-1), 2));
}

END {
  if (regs == 0) {
    print("can't find registers parameter!");
    exit(1);
  }

  if (ahb2 == 0) {
    print("can't find ahb2 parameter!");
    exit(1);
  }

  printf("\t#\n\t# autogenerated by uart.awk...\n\t#\n");

  ldreg("0x2a8", uart_mc);
  ldreg("0x294", 0);
  ldreg("0x298", 0);
  
  clks = int( 0.5 + ahb2 / (16 * baud));

  ldreg("0x2b4", int(clks%256));
  ldreg("0x2b8", int(clks/256));
}
