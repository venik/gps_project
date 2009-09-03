clc, clear all ;

Fin = 16.384 ;
Fout = 16.368 ;
err = 1e10 ;
optLcount = 0 ;
optMcount = 0 ;
for Lcount = 1:4095
    for Mcount = 1:4095
        k = Lcount/(4096-Mcount+Lcount) ;        
        if abs(k-Fout/Fin)<err
            optLcount = Lcount ;
            optMcount = Mcount ;
            err = abs(k-Fout/Fin) ;
            disp(sprintf('L=%5d, M=%5d, err: %f',optLcount,optMcount,err)) ;
        end
    end
end


