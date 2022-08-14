% Clears data in cache
function ASIComp_ClearCache(app)
    % Ensure the user wants to actually clear the cache
    selection = uiconfirm(app.IceScannerUI,'Are you sure you want to clear the cache?',...
        'Clear cache','Icon','question');
    % Immediately break out of ASIComp_ClearCache if 'Cancel' was selected
    switch selection; case 'Cancel'; return; end

    % Clear out d2c
    app.d2c = [];
    % Disable the datalist
    app.Datalist_ASIComp.Enable = "off";
    % Reset entries in the datalist
    app.Datalist_ASIComp.Items(2:end) = [];
    app.Datalist_ASIComp.Items{1} = 'Image 1';
    % Reset spinner
    app.Spinner_ASIComp_Import.Value = 1;
    app.Spinner_ASIComp_Import.Limits = [1,2]; 
    % Notify user that cache has been reset
    uialert(app.IceScannerUI,'Cache has been cleared.','Cleared cache','Icon','success');
end

