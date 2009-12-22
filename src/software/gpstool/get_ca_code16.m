% /* get_ca_code16(N,PRN) */
% /* function computes N values of C/A code 
%                   resampled to 16.368MHz*/
% /* N - number of chip values */
% /* PRN  - sattelite code */
% /* Status: is not tested */
function ca16 = get_ca_code16(N,PRN)
ca = get_ca_code(N,PRN) ;
ca16 = zeros(N*16,1) ;
for k=1:N
    ca16((k-1)*16+1:(k-1)*16+16) = ca(k) ;
end
