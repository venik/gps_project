% search in time and shift CA code
% Samsung
clc, clear all, close all ;
plot_mode = 1 ;
nDumpSize = 16368*5 ; 
x = readdump('./data/flush',nDumpSize) ;
%pwelch(x(1:16368),[],[],[],16.368e6) ;
FR = 4092-5:0.5:4092+5 ; % frequency range
N = 16368 ;   % /* correlation length */
for PRN=1:32
    max_acx = 0 ;
    max_f0 = 0 ;
    for f0 = FR
        acxm = zeros(N,1) ;
        t_offs = 1 ;
        for n_offs = 1:5
            acx = gpsacqb(x(t_offs:end),N,PRN,f0, 0,t_offs-1) ;
            acxm = acxm + acx ;
            t_offs = t_offs + 5000 ;
        end
        acxm = acxm/n_offs ;
        if max(acxm)>max_acx
            max_acx = max(acxm) ;
            max_f0 = f0 ;
        end
        if plot_mode
            plot(acxm), ylim([0 1e7]), grid on ;
            title(sprintf('PRN=%d, F_0=%f',PRN,f0), 'FontSize',14) ;
            drawnow ;
        end
    end
    %pause(0.2) ;
    fprintf('Sat: %02d, max=%e F=%f\n',PRN,max_acx,max_f0) ;
end
