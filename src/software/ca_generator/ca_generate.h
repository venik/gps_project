/*ca_generate.h*/
int n,k;
int main();
void init(int G1[n], int  G2[n]);
void RotateG1(int G1[n]);
void RotateG2(int G2[n]);
void ResultBit(int G1[n], int G2[n], int ResBit[], int k, int NumSat, int k1[], int k2[]);
void Sig_Gen(double x_re[5], double x_im[5]);

