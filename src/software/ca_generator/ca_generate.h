/*ca_generate.h*/
int n,Step;
int main();
void CAGen (int G1[n], int G2[n], int ResBit[n], int Step, int NumSat, int k1[n], int k2[n], int Length);
void Output(int G1[n], int G2[n], int ResBit[n], double x_re[n], double x_im[n], int Length);
void Init(int G1[n], int G2[n], double x_re[n], double x_im[n], int Length);
void RotateG1(int G1[n]);
void RotateG2(int G2[n]);
void ResultBit(int G1[n], int G2[n], int ResBit[], int k, int NumSat, int k1[], int k2[]);
void Sig_Gen(double x_re[n], double x_im[n], int Step);

