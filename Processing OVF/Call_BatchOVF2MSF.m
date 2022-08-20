% Calculates magnetic structure factor from OVF files within a given directory
function Call_BatchOVF2MSF(app)
    % Ask the user if the ovf files are located in the target directory or in subdirectories
    selection = uiconfirm(app.IceScannerUI,'Where will the ovf files be located in?','OVF location','Options',...
        {'Subdirectories','Target directory','Cancel'},'CancelOption',3);
    switch selection
        case 'Target directory'
            app.dirImages = uigetdir(app.dirImages,'Select ovf directory');
            ovfIn = 'directory';
        case 'Subdirectories'
            app.dirImages = uigetdir(app.dirImages,'Select ovf superdirectory');
            ovfIn = 'subdirectories';
        case 'Cancel'
            return;
    end
    if ~ischar(app.dirImages)
        app.dirImages = oldDirImages;
        return;
    end
    resSel = uiconfirm(app.IceScannerUI,'How many pixels?','Resolution','Options',...
        {'300x300','600x600','Cancel'},'CancelOption',3);
    switch resSel
        case '300x300'
            res = 300;
        case '600x600'
            res = 600;
        case 'Cancel'
            return;
    end
    method = uiconfirm(app.IceScannerUI,'MSF calculation method?','MSF','Options',...
        {'Half','Full','Cancel'},'CancelOption',3);
    switch method
        case 'Half'
            OVF2MSF(app.dirImages,ovfIn,'half',res,app);
        case 'Full'
            OVF2MSF(app.dirImages,ovfIn,'full',res,app);
        case 'Cancel'
            return;
    end
end