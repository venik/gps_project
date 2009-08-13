/*ca_generate.c*/
#include <stdio.h>
#include "ca_generate.h"


int main()
{
 int i,j;
 int G1[]={1,2,3,4,5,6,7,8,9,10};
 int G2[]={0,0,0,0,0,0,0,0,0,0}; 
 int k1[] = {2, 3, 4, 5, 1,  2, 1, 2,  3, 2, 3, 5, 6, 7, 8,  9, 1, 2, 3, 4, 5, 6, 1, 4, 5, 6, 7,  8, 1, 2, 3, 4,  5,  4, 1, 2, 4 } ;
 int k2[] = {6, 7, 8, 9, 9, 10, 8, 9, 10, 3, 4, 6, 7, 8, 9, 10, 4, 5, 6, 7, 8, 9, 3, 6, 7, 8, 9, 10, 6, 7, 8, 9, 10, 10, 7, 8, 10 } ;

 //init(G1, G2);
rotateg1(G1);
 for(i=0;i<10;i++)
 {
  printf("G1[%d]=%d \n",i+1, G1[i]);
  //printf("G2[%d]=%d \n",i+1, G2[i]);
 }

 for(j=0;j<37;j++)
 {
  //printf("k1[%d]=%d \n", j+1, k1[j]);
  //printf("k2[%d]=%d \n", j+1, k2[j]);
 }
}


void init(int G1[n], int G2[n])
{
 int i;
 
 for(i=0;i<10;i++)
 {
  G1[i]=1;
  G2[i]=1;
 } 
}


void rotateg1(int G1[n])
{
int i; 
for (i=9;i>0;i--)
{//int G1Temp10=G1[9];
G1[i]=G1[i-1];
}
G1[0]=255;
}
