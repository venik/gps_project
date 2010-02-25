function ca_generate()
 function [G1,G2,k1,k2]=init()
  G1=[1 1 1 1 1 1 1 1 1 1];
  G2=[1 1 1 1 1 1 1 1 1 1];
  k1=[2 3 4 5 1 2 1 2 3 2 3 5 6 7 8 9 1 2 3 4 5 6 1 4 5 6 7 8 1 2 3 4 5 4 1 2 4];
  k2=[6 7 8 9 9 10 8 9 10 3 4 6 7 8 9 10 4 5 6 7 8 9 3 6 7 8 9 10 6 7 8 9 10 10 7 8 10];
 end

 function [xora]=xors(G2Temp10, G2Temp9, G2Temp8, G2Temp6, G2Temp3, G2Temp2)
   XorTmp1=xor(G2Temp10,G2Temp9);
   XorTmp2=xor(G2Temp8,G2Temp6);
   XorTmp3=xor(G2Temp3,G2Temp2);
   XorTmp4=xor(XorTmp1,XorTmp2);
   xora=xor(XorTmp4,XorTmp3); 
 end

 function [G1]=rotateg1(G1)
  G1Temp10=G1(10);
  G1(10)=G1(9);
  G1(9)=G1(8);
  G1(8)=G1(7);
  G1(7)=G1(6);
  G1(6)=G1(5);
  G1(5)=G1(4);
  G1(4)=G1(3);
  G1Temp3=G1(3); 
  G1(3)=G1(2);
  G1(2)=G1(1);
  G1(1)=xor(G1Temp3,G1Temp10);
 end

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
   [xora]=xors(G2Temp10, G2Temp9, G2Temp8, G2Temp6, G2Temp3, G2Temp2);
  G2(1)=xora;
 end 
  
 function [ResBit]=result_bit(G1,G2,NumSat,Length,ResBit)
  for k=1:Length;
   ResBitTemp=xor(G1(10),G2(k2(NumSat)));
   ResBit(k)=xor(ResBitTemp,G2(k1(NumSat)));
   [G1]=rotateg1(G1);
   [G2]=rotateg2(G2);
  end
 end

 function [x_re,x_im]=gen_sin(nSample,ShiftSat,NumSat,x_re,x_im)
  takt=nSample*16;
  for i=1:takt-ShiftSat; 
   x_re(i+ShiftSat,NumSat)=sin(2*pi*4.092/16.368*i);
   x_im(i+ShiftSat,NumSat)=cos(2*pi*4.092/16.368*i);
  end
 end

 function [x_re,x_im]=sig_gen(ResBit,nSample,x_re,x_im,NumSat)
  for i=0:nSample-1;
   castr(i+1)=ResBit(i+1)*2-1;
   for j=0:15;
    xnum=i*16+j+1;
    x_re(xnum,NumSat)=x_re(xnum,NumSat)*castr(i+1);
    x_im(xnum,NumSat)=x_im(xnum,NumSat)*castr(i+1);
   end  
  end
 end

% Program
 [G1,G2,k1,k2]=init();
 addsat=1;
 x_resum=0;
 x_imsum=0;
 ResBit=0;
 while addsat==1
  param = inputdlg({'NumSat (1-37)' 'Length' 'ShiftSat'}, 'Input Data',[1 10;1 10; 1 10], {'6' '37' '0'}, 'on');
  NumSat = str2double(param{1});
   if (NumSat<1)||(NumSat>37) 
      errnumsat = errordlg('NumSat<1 or NumSat >37 ', 'NumSat incorrect');
      disp('NumSat incorrect')
   end    
  Length = str2double(param{2});
    if Length<1 
      errlength = errordlg('Length<1', 'Length incorrect');
      disp('Length incorrect')
    end 
  ShiftSat = str2double(param{3});
    if ShiftSat<0 
      errshiftsat = errordlg('ShiftSat<0', 'ShiftSat incorrect');
      disp('ShiftSat incorrect')
    end 
  nSample=fix(Length/16);
  x_re=zeros(Length,37);
  x_im=zeros(Length,37);
  [ResBit]=result_bit(G1,G2,NumSat,Length,ResBit);
  [x_re,x_im]=gen_sin(nSample,ShiftSat,NumSat,x_re,x_im);
  [x_re,x_im]=sig_gen(ResBit,nSample,x_re,x_im,NumSat);
  x_resum=x_resum+x_re
  x_imsum=x_imsum+x_im
  addsat = menu('Add Sattelite', 'Add new sattelite', 'Exit');
 end
 
   
end