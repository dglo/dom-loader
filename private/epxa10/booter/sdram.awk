#
# genpll.awk, generate code to program
# the sdram pll (pll2)...
#
# uses the config file to get the correct
# parameters...
#
BEGIN {
  ahb1 = 0;
  sdram = 0;
  regs = 0;
  rcd = 0;
  ras = 0;
  rrd = 0;
  rp = 0;
  wr = 0;
  rc = 0;
  bl = 0;
  rfc = 0;
  mt = 0;
  rfsh = 0;
  row = 0;
  col = 0;
  cas = 0;
  cl = 0;
  ddr = 0;
  width = 0;
  loopcnt = 0;
}

/^REGISTERS/ {
  regs = numericValue($2);
}

/^AHB1/ {
  ahb1 = numericValue($2);
}

/^SDRAM_CLK/ {
  sdram = numericValue($2);
}

/^DEVICE/ {
  device = $2;
}

/^RCD/ { rcd = nstoclks($2, 1, 4); }
/^RAS/ { ras = nstoclks($2, 1, 8); }
/^RRD/ { rrd = nstoclks($2, 1, 4); }
/^RP/ { rp = nstoclks($2, 1, 4); }
/^WR/ { wr = nstoclks($2, 1, 3); }
/^RC/ { rc = nstoclks($2, 1, 10); }
/^BL/ { 
  bl = numericValue($2);
  if (bl!=8) {
    printf("invalid burst length [8, 8]\n");
    exit(1);
  }
  bl = 3; # convert 8 to bits...
}

/^RFC/ { rfc = nstoclks($2, 3, 11); }
/^RFSH/ { rfsh = nstoclks($2, 0, 65535); }
/^ROW/ { 
  row = numericValue($2);
  if (row<11 || row>13) {
    printf("invalid row! [11, 13]\n");
    exit(1);
  }
}

/^COL/ { 
  col = numericValue($2);
  if (col<8 || col>13) {
    printf("invalid col! [8, 12]\n");
    exit(1);
  }
}

/^CAS/ { 
  cas = numericValue($2);

  if (cas==2)      cl = 3;
  else if (cas==3) cl = 5;
  else {
    printf("invalid cas! [2, 3]\n");
    exit(1);
  }
}

/^WIDTH/ { width = numericValue($2); }
/^DDR/ { ddr = numericValue($2); }

END {
  if ( regs == 0) {
    printf "can't find registers in config!\n";
    exit(1);
  }

  printf("\t#\n\t# autogenerated by sdram.awk\n\t#\n\n");

  #
  # wait 100us after pll2 is locked...
  #
  printf("\t#\n\t# wait 200us for pll2 to lock\n\t#\n");
  printf("\tldr\t\tr0, =0x%x\n", (regs+numericValue("0x328")));
  printf("\tldr\t\tr1, =%u\n", (200 * ahb1/1000000));
  printf("\tldr\t\tr2, [r0]\n");
  printf("\tadd\t\tr2, r2, r1\n");
  printf("wait_ahb1:\n");
  printf("\tldr\t\tr1, [r0]\n");
  printf("\tcmp\t\tr1, r2\n");
  printf("\tbhi\t\twait_ahb1\n\n");

  printf("\t#\n\t# load sdram config registers\n\t#\n");
  r =  or(wr, 
	  or(lshift(rp, 3), 
	     or(lshift(rrd, 6), 
		or(lshift(ras, 9), lshift(rcd, 13)))));
  ldreg("0x400", r);

  r = or(lshift(rfc, 3), 
	 or(lshift(bl, 7),
	    or(lshift(cl, 9), lshift(rc, 12))));
  ldreg("0x404", r);

  ldreg("0x408", lshift(ddr, 15));
  ldreg("0x40c", rfsh);

  r = or(lshift(1, 7),
	 or(lshift(col, 8), lshift(row, 12)));
  ldreg("0x410", r);

  #
  # burst length and sequential are hardwired in sdram controller...
  #
  # cas is set on the chip...
  #
  r = or(3, or(bl, lshift(cas, 4)));
  ldreg("0x420", r);

  #
  # set width...
  #
  ldreg("0x7c", (width==32)?2:0);

  #
  # initialize the controller
  #
  printf("\tadr\t\tr1, CACHE_THIS_CODE_START\n");
  printf("\tadr\t\tr2, CACHE_THIS_CODE_END\n");
    
  printf("SDR_Load_Cache:\n");
  printf("\tmcr\t\tp15, 0, r1, c7, c13, 1\n");
  printf("\tadd\t\tr1, r1, #8\n");
  printf("\tcmp\t\tr1, r2\n");
  printf("\tble\t\tSDR_Load_Cache\n\n");

  printf("INIT_SDRAM:\n");
  printf("\tldr\t\tr2, =0x8000\n");
  printf("\tldr\t\tr3, =0xc000\n");
  printf("\tldr\t\tr4, =0x8800\n");
  printf("\tldr\t\tr5, =0xa000\n");

  # we need the wait for all EPXAs
  #if (device == "epxa10") {
      printf("\tldr\t\tr6, =0x%x\n", (regs+numericValue("0x328")));
      printf("\tldr\t\tr9, =%u\n", int(50*ahb1/sdram));
  
  #}
#  else {
#    printf("\tldr\t\tr9, =%u\n", int(5*ahb1/sdram));
#  }

  printf("CACHE_THIS_CODE_START:\n");
  printf("\tldr\t\tr0, =0x%x\n", (regs+numericValue("0x41c")));
  printf("\tldr\t\tr1, [r0]\n");
  printf("\torr\t\tr1, r1, r2\n");
  printf("\tstr\t\tr1, [r0]\n");

  printf("\tstr\t\tr3, [r0]\n");
  waitclks();
  printf("\n");
 
  printf("\tstr\t\tr4, [r0]\n");
  waitclks();
  printf("\n");

  printf("\tstr\t\tr4, [r0]\n");
  waitclks();
  printf("\n");

  printf("\tstr\t\tr5, [r0]\n");
  waitclks();
  printf("\n");

  printf("CACHE_THIS_CODE_END:\n\n");

  #
  # now map sdram (0x20000000)...
  #
  #printf("\t#\n\t# now map sdram to 0x20000000\n\t#\n");
  #ldreg("0xb0", or(numericValue("0x20000001"), lshift(22, 7)));
}
  
#
# convert ns to clocks, check for tailing CK or ns...
#
function nstoclks(ns, mnv, mxv) {
    isCK = 0;

    if ( (idx = match(ns, "ns")) != 0) {
	ns = substr(ns, 1, idx-1);
    }
    else if ((idx = match(ns, "CK"))!=0) {
	isCK = 1;
	ns = substr(ns, 1, idx-1);
    }
    
    if ( isCK ) {
	clks = numericValue(ns);
    }
    else {
	ns = numericValue(ns);
    
	nc = ns*sdram/1000000000;
	clks = (nc != int(nc)) ? int(nc) + 1 : int(nc);
    }

    if (clks<mnv)      clks = mnv;
    else if (clks>mxv) clks = mxv;
    
    return clks;
}

function waitclks() {
  # we need the wait for all EPXAs
  #if (device == "epxa10") {
    printf("\tldr\t\tr7, [r6]\n");
    printf("\tadd\t\tr7, r7, r9\n");
    printf("loopcnt" loopcnt ":\n");
    printf("\tldr\t\tr8, [r6]\n");
    printf("\tcmp\t\tr7, r8\n");
    printf("\tbhi\t\tloopcnt" loopcnt "\n");
    loopcnt++;
  #}
}




