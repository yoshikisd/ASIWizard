function ASIComp_Align(app)
%ASICOMP_SUPERIMPOSE Spatially aligns the ASI datasets
    % Create dialog to tell user to wait
    dialog = uiprogressdlg(app.IceScannerUI,'Title','Aligning','Message','Aligning the data.','Indeterminate','on');
    % Perform alignment of imported datasets
    app.d2c.alignDatasets;
    % Close dialog
    close(dialog)
    % Enable the datalist for selection
    app.Datalist_ASIComp.Enable = "on";
end

