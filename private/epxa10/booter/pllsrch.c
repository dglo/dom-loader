#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char *argv[]) {
  unsigned ref;
  unsigned pll;
  unsigned plln;
  int nmax, mmax, kmax;
  int kmin = 1, kinc = 1;
  const char *device;
  int sm=0, sn=0, sk=0;
  int m, n, k;
  int diff = -1;
  int fmax = -1;

  if (argc!=5) {
    fprintf(stderr, "usage: pllsrch device reference pll plln\n");
    return 1;
  }

  device = argv[1];
  ref = atoi(argv[2]);
  pll = atoi(argv[3]);
  plln = atoi(argv[4]);
  
 if (strcmp(device, "epxa10")==0) {
    nmax = 15;
    mmax = 15;
    kmax = 7;
  }
  else if (strcmp(device, "epxa1")==0 ||
	   strcmp(device, "epxa4")==0) {
    nmax = 255;
    mmax = 255;
    kmax = 255;
  }
  else return 1;

  if (plln==1) {
    kmin = kinc = 1;
  }
  else if (plln==2) {
    kmin = 2;
    kinc = 2;
    kmax = 4;
  }
  else return 1;

  for (m=1; m<=mmax; m++) {
      if (ref*m<160000000) continue;
      for (n=1; n<=nmax; n++) {
	  const int fvco = ref*m/n;
	  if (fvco>=160000000 && fvco<=600000000) {
	     for (k=kmin; k<=kmax; k+=kinc) {
		const int dv = abs( fvco/k - pll );
		if (diff==-1 || dv<diff) {
		   diff = dv;
		   fmax = fvco;
		   sm = m; sn = n; sk = k;
		}
		else if (diff == dv) {
		   if (fvco>fmax) {
		      diff = dv;
		      fmax = fvco;
		      sm = m; sn = n; sk = k;
		   }
		}
	     }
	  }
      }
  }
  printf("%d %d %d\n", sm, sn, sk);
  return 0;
}





