function ca16 = get_ca_code16(N,PRN)
% /* get_ca_code16(N,PRN) */
% /* function computes N values of C/A code 
%                   resampled to 16.368MHz*/
% /* N - number of chip values */
% /* PRN  - sattelite code */
% /* Status: is not tested */

ca = get_ca_code(N+1,PRN) ; 
chip_width = 1/1.023e6 ;                % /* CA chip duration, sec */
ts = 1/16.368e6 ;                       % /* discretization period, sec */
ca16 = zeros(N*16,1) ;
for k=1:N*16
    ca16(k) = ca(ceil(ts*k/chip_width)) ;
end
ca16 = [ca16(1); ca16(1:end-1)] ;

% ca = get_ca_code(N,PRN) ;
% ca16 = zeros(N*16,1) ;
% for k=1:N
%     ca16((k-1)*16+1:(k-1)*16+16) = ca(k) ;
% end
