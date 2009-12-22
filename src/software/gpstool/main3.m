% search in time with window
% Samsung
clc, clear all, close all ;
plot_mode = 0 ;
nDumpSize = 16368*4 ; 
x = readdump('./data/flush',nDumpSize) ;
%pwelch(x(1:16368),[],[],[],16.368e6) ;
FR = 4092-5:0.5:4092+5 ; % frequency range
N = 16368 ;   % /* correlation length */
for PRN=31
    max_acx = 0 ;
    max_f0 = 0 ;
    for f0 = FR
        for t_offs = 1:10:1000
            acx = gpsacq(x(t_offs:end),N,PRN,f0, 0) ;
            max_a = max(acx) ;
            if max_a>max_acx
                max_f0 = f0 ;
                max_acx = max_a ;
            end
            if plot_mode
                plot(acx), ylim([0 1e7]), grid on;
                title(sprintf('PRN=%d, F_0=%f, t=%d,  max=%e (F_0=%f)',PRN,f0,t_offs,max_acx,max_f0),...
                    'FontSize',14) ;
                drawnow ;
            end
        end
    end
    %pause(0.2) ;
    fprintf('Sat: %02d, max=%e F=%f\n',PRN,max_acx,max_f0) ;
end
