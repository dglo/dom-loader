#
# waitns.awk, generate code to program
# wait r0 ns...
#
# uses the config file to get the correct
# parameters...
#
BEGIN {
  ahb1 = 0;
}

/^AHB1/ {
  ahb1 = numericValue($2);
}

END {
  if ( ahb1 == 0) {
    printf "can't find external clock or registers in config!\n";
    exit(1);
  }

  

    pllrem = pll % external;

    if (pllrem>0) {
      split(simplify(pllrem, external), v, " ");
      pllnum = v[1] + (pllmult*v[2]);
      pllden = v[2];
    }
    else {
      pllnum = pllmult;
      pllden = 1;
    }
    
    #
    # k must be 2 or 4
    #
    # pllden = n * k
    #
    # FIXME: get this right...
    #
    #m = pllnum;
    #k = 2;
    #n = int(pllden / k);
    #
    #printf "n = %d\n", n;
    #
    #if ( pllden % (n*k) ) {
    #  k = 4;
    #  n = int(pllden / k);
    #  if (pllden % (n*k) ) {
    #	printf("can't initialize pll, not evenly divisable!\n");
    #	exit(1);
    #  }
    #}

    #
    # HACK!:  
    # pll = 80000000
    # ext = 20000000
    #
    # pll/ext = 4
    #
    m = 8;
    k = 2;
    n = 1;

    mcntlo = int(m/2);
    mcnthi = int(m/2) + (m%2);
    ncntlo = int(n/2);
    ncnthi = int(n/2) + (n%2);
    kcntlo = int(k/2);
    kcnthi = int(k/2) + (k%2);

    mhi = 4 * (m==1) + 2*((m+1)%2) + (m%2);
    nhi = 4 * (n==1) + 2*((n+1)%2) + (n%2);
    khi = 4 * (k==1) + 2*((k+1)%2) + (k%2);
    
    mcnt = or(mcntlo, or(lshift(mhi, 16), lshift(mcnthi, 8)));
    ncnt = or(ncntlo, or(lshift(nhi, 16), lshift(ncnthi, 8)));
    kcnt = or(kcntlo, or(lshift(khi, 16), lshift(kcnthi, 8)));

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

    lww = or(numericValue("0x01005"), lshift(lw, 4));

    printf("\t#\n\t# autogenerated by genpll.awk, for pll2...\n\t#\n");

    #
    # bypass pll2 in clk_derive...
    #
    printf("\tldr\t\tr0, =0x%x\n", (regs+numericValue("0x320")));
    printf("\tldr\t\tr1, [r0]\n");
    printf("\tldr\t\tr2, =0x2000\n");
    printf("\torr\t\tr1, r1, r2\n");
    printf("\tstr\t\tr1, [r0]\n\n");

    printf("\tldr\t\tr0, =0x%x\n", (regs+numericValue("0x310")));
    printf("\tldr\t\tr1, =0x%x\n", ncnt);
    printf("\tstr\t\tr1, [r0]\n\n");

    printf("\tldr\t\tr0, =0x%x\n", (regs+numericValue("0x314")));
    printf("\tldr\t\tr1, =0x%x\n", mcnt);
    printf("\tstr\t\tr1, [r0]\n\n");

    printf("\tldr\t\tr0, =0x%x\n", (regs+numericValue("0x318")));
    printf("\tldr\t\tr1, =0x%x\n", kcnt);
    printf("\tstr\t\tr1, [r0]\n\n");

    printf("\tldr\t\tr0, =0x%x\n", (regs+numericValue("0x31c")));
    printf("\tldr\t\tr1, =0x%x\n", lww);
    printf("\tstr\t\tr1, [r0]\n\n");

    #
    # enable pll2 in clk_derive...
    #
    printf("\tldr\t\tr0, =0x%x\n", (regs+numericValue("0x320")));
    printf("\tldr\t\tr1, [r0]\n");
    printf("\tldr\t\tr2, =0xffffdfff\n");
    printf("\tand\t\tr1, r1, r2\n");
    printf("\tstr\t\tr1, [r0]\n\n");

    #
    # wait for lock...
    #
    printf("\tldr\t\tr0, =0x%x\n", (regs+numericValue("0x324")));
    printf("wait_for_pll_lock:\n");
    printf("\tldr\t\tr1, [r0]\n");
    printf("\tcmp\t\tr1, #0x3f\n");
    printf("\tbne\t\twait_for_pll_lock\n\n");
    printf("\tldr\t\tr1, =0xc\n");
    printf("\tstr\t\tr1, [r0]\n");
  }
}

function numericValue(v) {
  idx = match(v, "0x[0-9a-fA-F]*");
  if ( idx != 0 ) {
    str = "0123456789ABCDEF";
    sum = 0;
    mult = 1;
    for (i=length(v); i>2; i--) {
      si = index(str, toupper(substr(v, i, 1)));
      if ( si != 0 ) {
	sum = sum + (si-1)*mult;
      }
      mult = mult*16;
    }
    v = sum;
  }

  idx = match(v, "[0-9]*[mM]$");
  if ( idx != 0 ) {
    v = substr(v, 1, length(v)-1);
    v *= 1000000;
  }
  
  idx = match(v, "[0-9]*[kK]$");
  if ( idx != 0 ) {
    v = substr(v, 1, length(v)-1);
    v *= 1000;
  }
  
  return v;
}

#
# factor num, den into primes filter common...
#
function simplify(num, den) {
  cmd = "factor " num "| awk -F ':' '{print $2;}'";
  cmd | getline nlist
  cmd = "factor " den "| awk -F ':' '{print $2;}'";
  cmd | getline dlist

  split(nlist, nar, " ");
  split(dlist, dar, " ");

  for ( i in nar ) {
    for ( j in dar ) {
      if ( nar[i] == dar[j] ) {
	delete nar[i];
	delete dar[j];
      }
    }
  }

  nprod = 1;
  for (i in nar) { if (nar[i]>0) nprod *= nar[i]; }

  dprod = 1;
  for (j in dar) { if (dar[j]>0) dprod *= dar[j]; }

  return nprod " " dprod;
}

function or(v1, v2) {
  ret = 0;
  for (i=0; i<32; i++) {
    set = 0;
    bit = int(2^(31-i));
    v1d = int(v1/bit);
    v2d = int(v2/bit);
    if (v1d != 0 ) {
      v1 = int(v1 - bit);
      set = 1;
    }
    if (v2d != 0) {
      v2 = int(v2 - bit);
      set = 1;
    }
    if (set) ret += bit;
  }
  return ret;
}

function lshift(v1, amnt) {
  mult = int(2 ^ amnt);
  return ( int(v1 * mult));
}