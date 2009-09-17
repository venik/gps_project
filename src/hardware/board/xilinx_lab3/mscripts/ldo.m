clc, clear all ;

%Vout = 2.85 ;   % required output
Vout = 1.8 ;   % required output

R1 = 330 ;      % (see. LM117.pdf)
Vref = 1.25 ;   % (see LM117.pdf, mc33269-d.pdf)
Iadj = 100e-6 ; % (see LM117.pdf, mc33269-d.pdf)
%Iadj = 0 ;

R2 = (Vout - Vref)/(Vref/R1+Iadj) ;

% check part
%R_2 = round(R2/100)*100 ;
R_2 = ceil(R2/10)*10 ;
V_out = Vref*(1+R_2/R1)+Iadj*R_2 ; 

fprintf('R1 = %5.1f Om\nR2 = %5.1f Om\nOutput is %5.4f v\n', ...
    R1, R_2, V_out) ;