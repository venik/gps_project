% /* get_ca_code(N,PRN) */
% /* function computes N values of C/A code*/
% /* N - number of chip values */
% /* PRN  - sattelite code */
% /* Status: almost tested */
function x = get_ca_code(N,PRN)
bitar = get_ca_bits(N,PRN) ;
x = bitar*2-1 ;