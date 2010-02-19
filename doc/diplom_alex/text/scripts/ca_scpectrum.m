clc, clear all, close all ;
N = 16368 ;   % /* correlation length */
PRN=12


ca16 = get_ca_code16(N/16,PRN) ;
CA16 = fft(ca16) ;
c_CA16 = conj(CA16) ;

y = 20 * log10(abs(c_CA16)) ;

plot(fftshift(y)), xlim([0 N]), grid on ;
h1 = ylabel('јмплитуда в дЅ' ,'FontName','Courier New Cyr', 'FontSize',16) ;
h2 = xlabel('„астота в к√ц', 'FontName','Courier New Cyr', 'FontSize',16) ;
    