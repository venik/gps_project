function gui_pll(varargin)

global corr_bahr nco_ctl_plot I_chan_f Q_chan_f mixed_I mixed_Q theta_plot;

hMain = figure(1) ;
DataStruct = get(hMain,'UserData') ;

max_sat_freq = zeros(32,1) ;
sat_shift_ca = zeros(32,1) ;

max_sat_freq = DataStruct.max_sat_freq ;
sat_shift_ca = DataStruct.sat_shift_ca ;
work_data = DataStruct.work_data ;
PRN_range = DataStruct.PRN;

nDumpSize = 16368*30 ;          % FIXME - we can more up to 32ms
%load('./data/x.mat') ;
%pwelch(x(1:16368),[],[],[],16.368e6) ;
FR = 4092-5:1:4092+5 ; % frequency range kHz
t_offs = 100 ;     % /* FIXME - time offset */
N = 16368 ;   % /* correlation length */
fs = 16368 ;   % /* sampling freq kHz */
ts = 1/(fs * 1000) ;



% costas & DLL
time_range = N * (DataStruct.time_range - 1);
%time_range = N;
chip_length = N/1023;
I_data = zeros(time_range,1);
Q_data = zeros(time_range,1);

% filter constants - tsui related values
zu_cl = 0.7 ;             % damping ratio
%zu_cl = 1 ;             % damping ratio
k0k1_cl = 4*pi * 100 ;      % gain
B_cl = 20 ;                 % noise bandwith
omega_cl = 8*zu_cl*B_cl / (4*zu_cl^2 + 1) ;
C1_cl = (1/k0k1_cl) * (8*zu_cl*omega_cl*ts / (4 + 4*zu_cl*omega_cl*ts + (omega_cl*ts)^2) ) ;
C2_cl = (1/k0k1_cl) * (4*(omega_cl*ts)^2   / (4 + 4*zu_cl*omega_cl*ts + (omega_cl*ts)^2) ) ;
nco_ctl = 0 ;
mixer_I1 = 0 ;
mixer_Q1 = 0 ;
lpf_I = 0 ;
lpf_I1 = 0 ;
lpf_Q = 0 ;
lpf_Q1 = 0 ;

data_mixed_I = zeros(time_range,1) ;
data_mixed_Q = zeros(time_range,1) ;
data_lpf_I = zeros(time_range,1) ;
data_lpf_Q = zeros(time_range,1) ;
data_theta = zeros(time_range,1) ;
data_lf_theta = zeros(time_range,1) ; 
data_nco_ctl = zeros(time_range,1) ; 

% lowpass filter coefs
lpf_b = 0.981 ;
lpf_a = 0.0095 ;

data_chip = zeros(time_range, 1) ;

if 1
for PRN=PRN_range
    data = work_data(sat_shift_ca(PRN): end);
    ca16 = get_ca_code16(N/16,PRN) ;
    
    %freq_error = 36 ;
    %max_sat_freq(PRN) = max_sat_freq(PRN)*1000 + freq_error;      % convert kHz => Hz
    %fprintf('start with freq\t%10.5f err = %f\n', max_sat_freq(PRN), freq_error) ;
    
    max_sat_freq(PRN) = max_sat_freq(PRN)*1000 ;      % convert kHz => Hz
    fprintf('start with freq\t%10.5f \n', max_sat_freq(PRN)) ;
    
    for data_step=1
        
        data_chip = data(1:time_range);
        data_chip = data_chip .* [ca16;ca16;ca16;ca16;ca16;ca16;ca16;ca16;ca16;ca16;ca16;ca16;ca16;ca16;ca16;ca16;ca16;ca16;ca16;ca16;
                                  ca16;ca16;ca16;ca16;ca16;ca16;ca16;ca16;ca16] ;
        
        %data_chip = data_chip .* ca16 ;
                            
        I_data(1:time_range) = real( data_chip(1:time_range) ) ;
        Q_data(1:time_range) = real( data_chip(1:time_range) ) ;
        %Q_data(1:time_range) = imag( data_chip ) ;
                   
        % loop filter queues
        y_theta_cl = zeros(3,1) ;
        x_theta_cl = zeros(3,1) ;
        
        % make 1ms
        for h=1:time_range
                    
            nco_sample = exp(j*2*pi*(max_sat_freq(PRN) - nco_ctl)/fs*(h-1)) ;
            mixer_I = I_data(h)*real(nco_sample) ;
            mixer_Q = Q_data(h)*imag(nco_sample) ;
            
            % I lowpass filter
            lpf_I = lpf_b*lpf_I1 + lpf_a*mixer_I + lpf_a*mixer_I1 ;
            mixer_I1 = mixer_I ;
            lpf_I1 = lpf_I ;

            % Q lowpass filter
            lpf_Q = lpf_b*lpf_Q1 + lpf_a*mixer_Q + lpf_a*mixer_Q1 ;
            mixer_Q1 = mixer_Q ;
            lpf_Q1 = lpf_Q ;
    
            % descriminator
            if lpf_I1==0
                theta = 0 ;
            else
                theta = atan(lpf_Q1/lpf_I1) ;
            end
            
            % loop filter
            x_theta_cl(3) = theta ;
            y_theta_cl(3) = k0k1_cl*(C1_cl+C2_cl)*x_theta_cl(2) - k0k1_cl*C1_cl*x_theta_cl(1) - ...
                        (k0k1_cl*(C1_cl+C2_cl) - 2)*y_theta_cl(2) - (1 - k0k1_cl*C1_cl)*y_theta_cl(1) ;
            y_theta_cl(1:2) = y_theta_cl(2:3) ;
            x_theta_cl(1:2) = x_theta_cl(2:3) ;

            lf_theta = y_theta_cl(3) ;

            nco_ctl = lf_theta * 1000 ;   
            
            % collect data
            data_mixed_I(h) = mixer_I ;
            data_mixed_Q(h) = mixer_Q ;
            data_lpf_I(h) = lpf_I ;
            data_lpf_Q(h) = lpf_Q ;
            data_theta(h) = theta ;
            data_lf_theta(h) = lf_theta ;
            data_nco_ctl(h) = nco_ctl ;
            
            if (mod(h,N) == 0) && (h > N)
                axes(nco_ctl_plot)
                plot(data_nco_ctl(1:h)), grid on, title('PLL correction') ;

                axes(I_chan_f)
                plot(data_lpf_I(1:h)), grid on, title('I channel after lpf') ;

                axes(Q_chan_f)
                plot(data_lpf_Q(1:h)), grid on, title('Q channel after lpf') ;

                axes(mixed_I)
                plot(data_mixed_I(h-100:h)), grid on, title('mixed I') ;

                axes(mixed_Q)
                plot(data_mixed_Q(h-100:h)), grid on, title('mixed Q') ;

                axes(theta_plot)
                plot(data_theta(h-100:h)), grid on, title('theta') ;
                
                drawnow ;
           end

        end % for h=
        
        fprintf('resulted freq\t%10.5f phi = %f\n', max_sat_freq(PRN) - nco_ctl, nco_ctl) ;
        
    end % for data_step=1
end

axes(nco_ctl_plot)
plot(data_nco_ctl), grid on, title('PLL correction') ;

axes(I_chan_f)
plot(data_lpf_I), grid on, title('I channel after lpf') ;

axes(Q_chan_f)
plot(data_lpf_Q), grid on, title('Q channel after lpf') ;

%axes(mixed_I)
%plot(data_mixed_I), grid on, title('mixed I') ;

%axes(mixed_Q)
%plot(data_mixed_Q), grid on, title('mixed Q') ;

%axes(theta_plot)
%plot(data_theta), grid on, title('theta') ;

end