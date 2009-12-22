% check for serial and parallel searchers equality
clc, clear all ;
nDumpSize = 16368*4 ; 
%x = readdump('./data/gdump.txt',nDumpSize) ;
%pwelch(x(1:16368),[],[],[],16.368e6) ;
FR = 4092-5:0.5:4092+5 ; % frequency range
t_offs = 16 ; % time offset
N = 16368 ; % /* correlation length */
N_check = 256 ; % /* points check to */
x = get_sat_signal(nDumpSize,23,FR(1)) ;
pwelch(x(1:16368),[],[],[],16.368e6) ;
for PRN=23
    for f0 = FR
        acx = gpsacq(x(t_offs:end),N,PRN,f0, 0) ;
        plot(acx), grid on, title(sprintf('PRN=%d, F_0=%f',PRN,f0)) ;
        
        acx_serial = zeros(N,1) ;
        for ca_phase = 1:N_check
            acx_serial(ca_phase) = ...
                gpssearch(x(t_offs:end),N,ca_phase,PRN,f0, 0) ;
        end
        
        hold off, plot(acx(1:N_check)), hold on, plot(acx_serial(1:N_check),'r-.'), grid on
        
        % relative error
        err = acx(1:N_check) - acx_serial(1:N_check) ;
        err2 = sum(err.*conj(err))/N_check ;
        std2 = sum(acx(1:N_check).*conj(acx(1:N_check)))/N_check ;
        rerr = err2/std2 ;
        
        title(sprintf('Number of points: %d, relative error: %e',N_check,rerr)) ;
        
        return ;
        
    end
end
