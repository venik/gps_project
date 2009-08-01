function [ResBit]=cagen(NumSat,Length)
 function [G1,G2,k1,k2]=init()
  G1=[1 1 1 1 1 1 1 1 1 1]
  G2=[1 1 1 1 1 1 1 1 1 1]
  k1=[2 3 4 5 1 2 1 2 3 2 3 5 6 7 8 9 1 2 3 4 5 6 1 4 5 6 7 8 1 2 3 4 5 4 1 2 4];
  k2=[6 7 8 9 9 10 8 9 10 3 4 6 7 8 9 10 4 5 6 7 8 9 3 6 7 8 9 10 6 7 8 9 10 10 7 8 10];
 endfunction

function [G1]=rotateg1(G1)
G1Temp10=G1(10)
 G1(10)=G1(9)
 G1(9)=G1(8)
 G1(8)=G1(7)
 G1(7)=G1(6)
 G1(6)=G1(5)
 G1(5)=G1(4)
 G1(4)=G1(3)
G1Temp3=G1(3) 
 G1(3)=G1(2)
 G1(2)=G1(1)
 G1(1)=((G1Temp10)|(G1Temp3))&((G1Temp10)~=(G1Temp3))
endfunction

function [G2]=rotateg2(G2)
G2Temp10=G2(10);
 G2(10)=G2(9);
G2Temp9=G2(9);
 G2(9)=G2(8);
G2Temp8=G2(8);
 G2(8)=G2(7);
 G2(7)=G2(6);
G2Temp6=G2(6);
 G2(6)=G2(5);
 G2(5)=G2(4);
 G2(4)=G2(3);
G2Temp3=G2(3);
 G2(3)=G2(2);
G2Temp2=G2(2);
 G2(2)=G2(1);
   XorTmp1=((G2Temp10)|(G2Temp9))&((G2Temp10)~=(G2Temp9));
   XorTmp2=((G2Temp8)|(G2Temp6))&((G2Temp8)~=(G2Temp6));
   XorTmp3=((G2Temp3)|(G2Temp2))&((G2Temp3)~=(G2Temp2));
   XorTmp4=((XorTmp1)|(XorTmp2))&((XorTmp1)~=(XorTmp2));
   XorTmp5=((XorTmp4)|(XorTmp3))&((XorTmp4)~=(XorTmp3));
 G2(1)=XorTmp5;
endfunction

function [ResBit]=ResultBit(G1,G2,ResBit,k,NumSat)
  ResBitTemp=0
  ResBitTemp2=0
ResBitTemp(1)=(G1(10)|G2(k2(NumSat)))&(G1(10)~=G2(k2(NumSat))); //G1 xor G2(k2)
ResBitTemp2(1)=(ResBitTemp(1)|G2(k1(NumSat)))&(ResBitTemp(1)~=G2(k1(NumSat))); // ResBitTemp xor G2(k1)
  ResBit(k)=ResBitTemp2(1); //G1(10)xor ResBitTemp 
endfunction  

[G1,G2,k1,k2]=init();
ResBit=0;
for k=1:Length;
  [ResBit]=ResultBit(G1,G2,ResBit,k,NumSat);
[G1]=rotateg1(G1);
[G2]=rotateg2(G2);
end;
endfunction

function [x,castr]=sig_gen(NumSat,nSample,x)

for i=1:nSample;x(i,NumSat)=sin(2*3.141*4.092/16.368*i); end;
    cel=nSample/16;
    celint=uint32(cel);
castr=cagen(NumSat,celint);

for i=0:celint-1;
  castr(i+1)=castr(i+1)*2-1;
   for j=0:15;
    xnum=i*16+j+1;
    x(xnum,NumSat)=x(xnum,NumSat)*castr(i+1);
    end;  
end;  
endfunction  

//Program
z=1;
i=1;
y=x_dialog('Enter a length string or 0 for exit',["32"]);
y=evstr(y);
 if y~=0 then
  x=ones(y,37);
   while z~=0;
    z=x_dialog('Enter a number satellite or 0 for exit',["17"]);
    z=evstr(z);
     if z~=0 then
     [x,castr]=sig_gen(z,y,x);
     mem(i)=z; i=i+1;
     end;
   end;
end;
x=prod(x,"c") 
//printf("%1.12f ",x); 
mem
