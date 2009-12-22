% /* get_ca_bits(N,PRN) */
% /* function computes N bits of C/A code*/
% /* N - number of bits */
% /* PRN  - sattelite code */
% /* Status: almost tested */
% /* Note1: C/A code values can be computed as x = 2*bitar-1 */
function bitar = get_ca_bits(N,PRN)
K = [2,6;3,7;4,8;5,9;1,9;2,10;1,8;2,9;3,10;2,3;3,4;5,6;6,7;7,8;8,9;9,10;...
    1,4;2,5;3,6;4,7;5,8;6,9;1,3;4,6;5,7;6,8;7,9;8,10;1,6;2,7;3,8;4,9] ;
k1 = K(PRN,1) ;
k2 = K(PRN,2) ;
g1 = ones(10,1) ;
g2 = ones(10,1) ;
bitar = [] ;
for k=1:N
    bitar = [bitar; mod(g1(10)+mod(g2(k1)+g2(k2),2),2)] ;
    g11 = mod(g1(10)+g1(3),2) ;
    g21 = mod(g2(2)+g2(3)+g2(6)+g2(8)+g2(9)+g2(10),2) ;
    g1(2:end) = g1(1:end-1) ;
    g2(2:end) = g2(1:end-1) ;
    g1(1) = g11 ;
    g2(1) = g21 ;
end
