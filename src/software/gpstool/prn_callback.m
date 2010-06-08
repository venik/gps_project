function prn_callback

hMain = figure(1) ;
DataStruct = get(hMain,'UserData') ;

ui_tmp = findobj(hMain,'Tag','PRNS') ;
val = get(ui_tmp,'value') ;

DataStruct.PRN = val

set(hMain,'UserData',DataStruct) ;

%fprintf('%d\n',DataStruct.a) ;
end