#
# pll.awk, generate code to program
# the sdram pll (pll2)...
#
# uses the config file to get the correct
# parameters...
#
BEGIN {
  ahb1 = 0;
  sdram = 0;
  external = 0;
  regs = 0;
  device = "";
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

/^EXTERNAL/ {
  external = numericValue($2);
}

/^DEVICE/ {
  device = $2;
}

END {
  if ( external == 0  || regs == 0) {
    printf "can't find external clock or registers in config!\n";
    exit(1);
  }

  split( getmnk(external, ahb1*2, 1), ar, " ");
  m1 = ar[1];
  n1 = ar[2];
  k1 = ar[3];
  chkparms(external, n1, m1, k1, 1);

  split( getmnk(external, sdram*2, 2), ar, " ");
  m2 = ar[1];
  n2 = ar[2];
  k2 = ar[3];
  chkparms(external, n2, m2, k2, 2);
    
  printf("\t#\n\t# autogenerated by pll.awk, for both plls...\n\t#\n");

  #
  # bypass both plls in clk_derive...
  #
  printf("\tldr\t\tr0, =0x%x\n", (regs+numericValue("0x320")));
  printf("\tldr\t\tr1, [r0]\n");
  printf("\tldr\t\tr2, =0x3000\n");
  printf("\torr\t\tr1, r1, r2\n");
  printf("\tstr\t\tr1, [r0]\n\n");
  
  ldreg("0x300", cntreg(n1));
  ldreg("0x304", cntreg(m1));
  ldreg("0x308", cntreg(k1));
  
  ldreg("0x310", cntreg(n2));
  ldreg("0x314", cntreg(m2));
  ldreg("0x318", cntreg(k2));
  
  ldreg("0x30c", lwwreg(external, n1));
  ldreg("0x31c", lwwreg(external, n2));
  
  #
  # enable both plls in clk_derive...
  #
  printf("\tldr\t\tr0, =0x%x\n", (regs+numericValue("0x320")));
  printf("\tldr\t\tr1, [r0]\n");
  printf("\tldr\t\tr2, =0xffffcfff\n");
  printf("\tand\t\tr1, r1, r2\n");
  printf("\tstr\t\tr1, [r0]\n\n");
  
  #
  # wait for lock...
  #
  printf("\tldr\t\tr0, =0x%x\n", (regs+numericValue("0x324")));
  printf("\tldr\t\tr2, =0x03\n");
  printf("wait_for_pll_lock:\n");
  printf("\tldr\t\tr1, [r0]\n");
  printf("\tand\t\tr1, r1, r2\n");
  printf("\tcmp\t\tr1, r2\n");
  printf("\tbne\t\twait_for_pll_lock\n\n");
  printf("\tldr\t\tr1, =0xc\n");
  printf("\tstr\t\tr1, [r0]\n");
}

function cntreg(z) {
  if (z == 1) { 
    cnt = numericValue("0x40000"); 
  }
  else {
    cntlo = int(z/2);
    cnthi = int(z/2) + (z%2);
    hi = 4 * (z==1) + 2*((z+1)%2) + (z%2);
    cnt = or(cntlo, or(lshift(hi, 16), lshift(cnthi, 8)));
  }
  return cnt;
}

#
# lock window register...
#
function lwwreg(external, n) {
    #
    # rcf relative clk ref...
    # mxlw: max lock window
    # mnlw: min lock window
    # lw: actual lock window
    #
    rcf = external/n;
    mxlw = (rcf <= 20000000) ? 6 : 5;
  
    if (rcf <= 10000000)      mnlw = 6;
    else if (rcf <= 15000000) mnlw = 5;
    else if (rcf <= 20000000) mnlw = 4;
    else                      mnlw = 3;

    lw = int( (mnlw+mxlw) / 2);
    return or(numericValue("0x01005"), lshift(lw, 4));
}

function chkparms(external, n, m, k, plln) {
  fvco = external * m / n;
  if ( fvco < 160000000 ) {
    printf("fvco is too small " fvco " must be at least 160000000\n");
    exit(1);
  }
  else if (fvco > 600000000 ) {
    printf("fvco is too big " fvco " must be less than 600000000\n");
    exit(1);
  }

  if (device=="epxa10") {
    nmax = 15;
    mmax = 15;
    kmax = 7;
    emin = 10000000;
  }
  else if (device == "epxa1" || device == "epxa4" ) {
    nmax = 255;
    mmax = 255;
    kmax = 255;
    emin = 1000000;
  }
  else {
    print("unknown device: (" device ") expecting epxa1, epxa4 or epxa10");
    exit(1);
  }

  if (external<emin || external>66000000) {
     printf("invalid external clock: (" external ") must be " emain " to 66000000\n");
     exit(1);
  }
  
  if (n<1 || n>nmax) {
    printf("n parameter is invalid [" n "] must be [1.." nmax "]\n");
    exit(1);
  }
  if (m<1 || m>mmax) {
    printf("m parameter is invalid [" m "] must be [1.." mmax "]\n");
    exit(1);
  }
  if (k<1 || k>kmax) {
    printf("k parameter is invalid [" k "] must be [1.." kmax "]\n");
    exit(1);
  }

  if (plln==2 && (k!=2 && k!=4)) {
    printf("k parameter is invalid [" k "] must be 2 or 4\n");
    exit(1);
  }
}

#
# get fcvo from pll, external
#
#  160M < ref*m/n < 600M
#  k = 2 or 4
#  pll = (ref*m/n)/k
#
#  we want to maximize ref*m/n, if plln == 2 we
#    force k to be 2 or 4...
#
#
function getmnk(ref, pll, plln) {
  if (deviced!= "epxa10" && device != "epxa1" && device != "epxa4" ) {
    print("unknown device: (" device ") expecting epxa1, epxa4 or epxa10");
    exit(1);
  }
  
  if (plln<1 || plln>2) {
      print("invalid plln (" plln ") must be 1 or 2");
      exit(1);	     
  }

  if (pllsrch!=0) {
     cmd = pllsrch " " device " " ref " " pll " " plln;  
  }
  else {
     cmd = "../../../../Linux-i386/build/dom-loader/pllsrch " device " " ref " " pll " " plln;  
  }
  
  cmd | getline mnk;

  return mnk;
}

function abs(v) { return (v<0) ? -v : v; }

