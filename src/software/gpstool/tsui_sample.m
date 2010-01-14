function tsui_sample()
% p7 1.m performs acquisition on collected data
clear
% ******* initial condition *******
svnum=input('enter satellite number = ');
intodat=10001; %input('enter initial pt into data (multiple of n) = ');
%fs=5e6; % *** sampling freq
fs=16368000; % *** sampling freq
ts=1/fs; % *** sampling time
n=fs/1000; % *** data pt in 1 ms
nn=[0:n-1]; % *** total no. of pts
fc=1.25e6; % *** center freq without Doppler
nsat=length(svnum); % *** total number of satellites to be processed

% ******* input data file *********
% fid=fopen('d:\gps\Big data\srvy1sf1.dat','r');
% fseek(fid,intodat-1,'bof');
% x2=fread(fid,6*n,'schar');
x2 = readdump('./data/flush',6*n) ;

yy = zeros(21,n);

% ******* start acquisition *******
code=digitizg(n,fs,0,svnum); % digitize C/A code
xf = fft(x2(1:n)');
for i = [1:21]; %**** find coarse freq 1 kHz resolution
fr=fc-10000+(i-1)*1000;
lc=code.* exp(j*2*pi*fr*ts*nn); % generate local code
lcf=fft(lc);
yy(i,:)=ifft(xf .* conj(lcf)); % circular correlation
end
[amp crw]=max(max(abs(yy'))); % find highest peak
[amp ccn]=max(max(abs(yy)));
pt_init=ccn; % initial point
cfrq=fc+1000*(crw-11); % coarse freq

for kk1=1:21
    plot(abs(yy(kk1,:))), ylim([0 5000]), pause ;
end
amp
return ;

% ******* gerenate 5 ms data by stripping C/A code *******
z5=x2(pt_init:pt_init+5*n-1); % take 5 ms data starting with C/A code
za5=z5' .* [code code code code code];% create cw from 5 sets of data

% ******* find medium freq resolution 400 kHz apart *******
for i = [1:3];
fr=cfrq-400+(i-1)*400;
mfrq0(i)=sum(za5(1:5000) .* exp(j*2*pi*fr*ts*nn));
mfrq1(i)=abs(mfrq0(i));
end

[mamp mrw] = max(mfrq1); % find highest peak
mfrq=cfrq+200*(mrw-2);
fr=mfrq; % medium freq

% ******* find fine freq *******
zb5=za5 .* exp(j*2*pi*fr*ts*[0:5*n-1]); % one DFT component
zc5=diff(-angle(sum(reshape(zb5,n,5)))); % find difference
angle
zc5fix=zc5;

%******* Adjust phase and take out possible phase shift*******
threshold=2.3*pi\5;
for i=1:4;
if abs(zc5(i))>threshold;% for angle adjustment
zc5(i)=zc5fix(i)-2*pi;
if abs(zc5(i))>threshold;
zc5(i)=zc5fix(i)+2*pi; % end
if abs(zc5(i))>2.2*pi\5; %for pi phase shift
correction
zc5(i)=zc5fix(i)-pi;
if abs(zc5(i))>threshold;
zc5(i)=zc5fix(i)-3*pi;
if abs(zc5(i))>threshold;
zc5(i)=zc5fix(i)+pi; %end
end
end
end
end
end
end
dfrq=mean(zc5)*1000/(2*pi);
frr=fr+dfrq;% fine freq
plot(abs(yy(crw,1:n)))
title(['GPS = ' num2str(svnum) ' max at '
num2str(pt_init)])
figure
plot(abs(yy(:,ccn)),'*')

% title(['GPS = ' num2str(svnum) ' Freq = ' num2str(frr)])
format
pt_init
format long e
frr

% digitizg.m This prog generate the C/A code and digitize it
function code2 = digitizg(n,fs,offset,svnum);
% code - gold code
% n - number of samples
% fs - sample frequency in Hz;
% offset - delay time in second must be less than 1/fs can not shift left
% svnum - satellite number;
gold_rate = 1.023e6; %gold code clock rate in Hz.
ts=1/fs;
tc=1/gold_rate;
cmd1 = codegen(svnum); % generate C/A code
code_in=cmd1;

% ******* creating 16 C/A code for digitizing *******
code_a = [code_in code_in code_in code_in];
code_a=[code_a code_a];
code_a=[code_a code_a];
% ******* digitizing *******
b = [1:n];
c = ceil((ts*b+offset)/tc);
code = code_a(c) ;
% ******* adjusting first data point *******
if offset>=0;
code2=[code(1) code(1:n-1)];
else
code2=[code(n) code(1:n-1)];
end

% codegen.m generate one of the 32 C/A codes written by D.Akos modified by J. Tsui
function [ca_used]=codegen(svnum);
% ca used : a vector containing the desired output sequence
% the g2s vector holds the appropriate shift of the g2 code to generate
% the C/A code (ex. for SV#19 - use a G2 shift of g2s(19)=471)
% svnum: Satellite number
g2s = [5;6;7;8;17;18;139;140;141;251;252;254;255;256;257; 258;469;470;471;472;473;474;509;512;513;514;515;516;859;860;861;862];
g2shift=g2s(svnum,1);
% ******* Generate G1 code *******
% load shift register
reg = -1*ones(1,10);
for i = 1:1023,
g1(i) = reg(10);
save1 = reg(3)*reg(10);
reg(1,2:10) = reg(1:1:9);
reg(1) = save1;
end,
% ******* Generate G2 code *******
% load shift register
reg = -1*ones(1,10);
for i = 1:1023,
g2(i) = reg(10);
save2 = reg(2)*reg(3)*reg(6)*reg(8)*reg(9)*reg(10);
reg(1,2:10) = reg(1:1:9);
reg(1) = save2;
end,
% ******* Shift G2 code *******
g2tmp(1,1:g2shift)=g2(1,1023-g2shift+1:1023);
g2tmp(1,g2shift+1:1023)=g2(1,1:1023-g2shift);
g2 = g2tmp;
% ******* Form single sample C/A code by multiplying G1 and G2
ss_ca = g1.*g2 ;
ca_used=-ss_ca ;
