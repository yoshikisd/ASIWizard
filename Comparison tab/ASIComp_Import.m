% Imports ASI datasets. Only one item can be imported at a time.
function ASIComp_Import(app)
    % By default, the spinner (Spinner_ASIComp_Import) will only allow the user to import ASI data incrementally
    % Store the value of the spinner
    idx = app.Spinner_ASIComp_Import.Value;
    % Open an import dialog request
    if app.dirImages == 0
        [FileName,app.dirImages] = uigetfile('*.mat','Select ASI datafile');
    else
        [FileName,app.dirImages] = uigetfile('*.mat','Select ASI datafile',app.dirImages);
    end
    
    if ~ischar(FileName); return; end
    % Save the data to the idx-th value of app.d2c
    if isempty(app.d2c)
        app.d2c = CompareASI(load(fullfile(app.dirImages,FileName)));
    elseif idx == app.Spinner_ASIComp_Import.Limits(2) 
        app.d2c.addData(load(fullfile(app.dirImages,FileName)));
    elseif idx < app.Spinner_ASIComp_Import.Limits(2)
        app.d2c.asi(idx) = load(fullfile(app.dirImages,FileName));
    end 
    % Update the name of the entry in the datalist to the name of the datafile
    app.Datalist_ASIComp.Items{idx} = sprintf('%i) %s',idx,FileName);
    % Increase the spinner value and range by 1
    if app.Spinner_ASIComp_Import.Limits(2) >= 2 && app.Spinner_ASIComp_Import.Value > 1
        app.Spinner_ASIComp_Import.Limits = [1,app.Spinner_ASIComp_Import.Limits(2)+1]; 
    end
    app.Spinner_ASIComp_Import.Value = idx+1;
    % Show real space image in external window
    general_imageDisplay(app,app.extWindow.axes,mat2gray(app.d2c.asi(idx).xmcd));
end

