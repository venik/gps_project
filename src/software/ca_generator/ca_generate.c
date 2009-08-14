/*ca_generate.c*/
#include <stdio.h>
#include "ca_generate.h"
#define N 10
#define M 37

int main()
{
 int i,j,k,NumSat;
 int G1[]={0,0,0,0,0,0,0,0,0,0};
 int G2[]={0,0,0,0,0,0,0,0,0,0}; 
 int k1[] = {2, 3, 4, 5, 1,  2, 1, 2,  3, 2, 3, 5, 6, 7, 8,  9, 1, 2, 3, 4, 5, 6, 1, 4, 5, 6, 7,  8, 1, 2, 3, 4,  5,  4, 1, 2, 4 } ;
 int k2[] = {6, 7, 8, 9, 9, 10, 8, 9, 10, 3, 4, 6, 7, 8, 9, 10, 4, 5, 6, 7, 8, 9, 3, 6, 7, 8, 9, 10, 6, 7, 8, 9, 10, 10, 7, 8, 10 } ;
 int ResBit[]={0};
k=0;
NumSat=1;
init(G1, G2);
rotateg1(G1);
rotateg2(G2);
ResultBit(G1,G2,ResBit,k,NumSat);
 for(i=0;i<N;i++)
 {
  printf("G1[%d]=%d \n",i+1, G1[i]);
  printf("G2[%d]=%d \n",i+1, G2[i]);
 }

 for(j=0;j<M;j++)
 {
  //printf("k1[%d]=%d \n", j+1, k1[j]);
  //printf("k2[%d]=%d \n", j+1, k2[j]);
 }

 printf("ResBit[%d]=%d \n", 0, ResBit[1]);
}


void init(int G1[n], int G2[n])
{
 int i;
  for(i=0;i<N;i++)
  {
   G1[i]=1;
   G2[i]=1;
  } 
}


void rotateg1(int G1[n])
{
 int i; 
 int G1Temp;
 G1Temp=(G1[9]+G1[2])%2; 
  for (i=9;i>0;i--)
  {
   G1[i]=G1[i-1];
  }
 G1[0]=G1Temp;
}

void rotateg2(int G2[n])
{
 int i;
 int G2Temp;
 G2Temp=(G2[9]+G2[8]+G2[7]+G2[5]+G2[2]+G2[1])%2;
  for (i=9;i>0;i--)
  {
   G2[i]=G2[i-1];
  }
 G2[0]=G2Temp;
}

void ResultBit(int G1[n], int G2[n], int ResBit[], int k, int NumSat)
{
 ResBit[k]=(G1[9]+G2[k1[NumSat]]+G2[k2[NumSat]])%2;
}
