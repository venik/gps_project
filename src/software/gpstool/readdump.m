% /* readdump(fname,nDumpSize) */
% /* function reads textual dump with I,Q samples */
% /* nDumpSize - number of samples to read */
% /* Status: almost tested */
function x = readdump(fname,nDumpSize)
x = zeros(nDumpSize,1) ;
f = fopen(fname,'r+t') ;
% /* read header */
str = fgets(f) ;
for n=1:nDumpSize
    if feof(f)
        fprintf('[readdump], Warning: End of file detected at sample %d\n',n) ;
        break ;
    end
    str = fgets(f) ;
    str_tr = strtrim(str) ;
    if str_tr(1)=='#'
        fprintf(str) ;
        continue ;
    end
    [v,k] = sscanf(str,'%d  %d') ;
    if k==2
        x(n) = v(1) + j*v(2) ;
    else
        fprintf('[readdump], Error: unknown format\n') ;
        break ;
    end
end
fclose(f) ;