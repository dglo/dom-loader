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

function ldreg(reg, val) {
  printf("\tldr\t\tr0, =0x%x\n", (regs+numericValue(reg)));
  printf("\tldr\t\tr1, =0x%x\n", numericValue(val));
  printf("\tstr\t\tr1, [r0]\n\n");
}

