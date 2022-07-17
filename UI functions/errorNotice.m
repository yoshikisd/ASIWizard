% Notifies the user of an error
function errorNotice(app,ME)
    uialert(app.IceScannerUI,sprintf('MATLAB has reported the following error:\n\n%s\n\nCheck function: "%s" at line %d',...
           ME.message,ME.stack(1).name,ME.stack(1).line),'Error','Icon','error');
end