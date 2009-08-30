/*ca_generate.c*/
#include <stdio.h>
#include <math.h>
#include "ca_generate.h"
#define Num 10
#define M 37

int main()
{
 int i,j,Step,NumSat,SLength,Length,G1[Num],G2[Num]; 
 int  k1[] = {2, 3, 4, 5, 1, 2, 1, 2, 3, 2, 3, 5, 6, 7, 8, 9, 1, 2, 3, 4, 5, 6, 1, 4, 5, 6, 7, 8, 1, 2, 3, 4, 5, 4, 1, 2, 4};
 int k2[] = {6, 7, 8, 9, 9, 10, 8, 9, 10, 3, 4, 6, 7, 8, 9, 10, 4, 5, 6, 7, 8, 9, 3, 6, 7, 8, 9, 10, 6, 7, 8, 9, 10, 10, 7, 8, 10};

Step=0;
  printf("Input number satellite ");
  scanf("%d",&NumSat);
  
  printf("Input length string ");
  scanf("%d",&Length);

SLength=Length/16;

 double x_re[Length], x_im[Length];
 int ResBit[Length];
 
 Init(G1,G2,x_re,x_im,Length);
 CAGen(G1,G2,ResBit,Step,NumSat,k1,k2,Length);
Sig_Gen(x_re,x_im,Length);
 Output(G1,G2,ResBit,x_re,x_im,Length);
}

void CAGen (int G1[n], int G2[n], int ResBit[n], int Step, int NumSat, int k1[n], int k2[n], int Length)
{
 for (Step=0;Step<Length;Step++)
 {
  ResultBit(G1,G2,ResBit,Step,NumSat,k1,k2);
  RotateG1(G1);
  RotateG2(G2);
 }
}

void Output(int G1[n], int G2[n], int ResBit[n], double x_re[n], double x_im[n], int Length)
{
int i,j; 
 for(i=0;i<Num;i++)
 {
  printf("G1[%d]=%d \n",i+1, G1[i]);
 }

 for (i=0;i<Num;i++)
 { 
  printf("G2[%d]=%d \n",i+1, G2[i]);
 }

 for(j=0;j<Length;j++)
 {
  printf("ResBit[%d]=%d \n", j+1, ResBit[j]);
 }

 for(i=0;i<Length;i++)
 {
  printf("x_re[%d]=%f \n", i+1, x_re[i]);
  printf("x_im[%d]=%f \n", i+1, x_im[i]);
 }
}
 
void Init(int G1[n], int G2[n], double x_re[n], double x_im[n], int Length)
{
 int i;
  for(i=0;i<Num;i++)
  {
   G1[i]=1;
   G2[i]=1;
  } 
  for(i=0;i<Length;i++)
  {
   x_re[i]=0;
   x_im[i]=0;
  }
}



void RotateG1(int G1[n])
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

void RotateG2(int G2[n])
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

void ResultBit(int G1[n], int G2[n], int ResBit[], int k, int NumSat, int k1[], int k2[])
{
 int out1=k1[NumSat-1];
 int out2=k2[NumSat-1]; 
 ResBit[k]=(G1[9]+G2[out1-1]+G2[out2-1])%2;
}

void Sig_Gen(double x_re[n], double x_im[n], int Step)
{
int i;
for (i=0;i<Step;i++)
 {
  x_re[i]=sin(2*3.141*4.092/16.368*i);
  x_im[i]=cos(2*3.141*4.092/16.368*i);
 }
}
