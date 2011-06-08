function numericValue(v) {
  idx = match(v, "0x[0-9a-fA-F]*");
  if ( idx != 0 ) { v = strtonum(v); }
  
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

function ldreg(reg, val) {
  printf("\tldr\t\tr0, =0x%x\n", (regs+numericValue(reg)));
  printf("\tldr\t\tr1, =0x%x\n", numericValue(val));
  printf("\tstr\t\tr1, [r0]\n\n");
}

