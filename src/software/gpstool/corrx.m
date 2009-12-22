function r = corrx(x,y,N)
mx = mean(x) ;
my = mean(y) ;
len = numel(x) ;
xr = x(:)'-mx ;
yc = y(:)-my ;
for alpha=1:N
    r(alpha) = xr(1:16368)*yc(alpha:16368+alpha-1)/(16368) ;
end
