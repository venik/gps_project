G1=[1 1 1 1 1 1 1 1 1 1];
G2=G1;

k1=[2 3 4 5 1 2 1 2 3 2 3 5 6 7 8 9 1 2 3 4 5 6 1 4 5 6 7 8 1 2 3 4 5 4 1 2 4];
k2=[6 7 8 9 9 10 8 9 10 3 4 6 7 8 9 10 4 5 6 7 8 9 3 6 7 8 9 10 6 7 8 9 10 10 7 8 10];

NumSat=1; //Number Satellite

  ResBitTemp=(G2(k1(NumSat))|G2(k2(NumSat)))&(G2(k1(NumSat))~=G2(k2(NumSat))); //G2(k1) xor G2(k2)
  ResBit=(G1(10)|ResBitTemp)&(G1(10)~=ResBitTemp) //G1(10)xor ResBitTemp
