% Calculates the magnetic structure factor for OVF magnetization files
function OVF2MSF(filePath,ovfIn,method,steps,app)
    arguments
        filePath string
        ovfIn {mustBeMember(ovfIn,{'subdirectories','direcrory'})}
        method {mustBeMember(method,['full','half'])}
        steps double
        app % IceWizard app
    end

    % Determine location of OVF files
    switch ovfIn
        case 'subdirectories'
            % Extract subdirectories
            fileList = dir(fullfile(filePath,'*.out'));
        case 'directory'
            % Load ovf files in the directory
            fileList = dir(fullfile(filePath,'*.ovf'));
    end
    % Display calculation status if called by ASIWizard/IceScanner
    if exist("app",'var'); isRunningWizard = ~isempty(app); end
    if isRunningWizard
        msfDialog = uiprogressdlg(app.IceScannerUI,'Title','OVF2MSF','Message',...
            'Calculating structure factors.');
    end
    % Calculate MSF for all ovf files in the directory
    for i = 1:length(fileList)
        % Create a name to save the MSF as
        exportName = fileList(i).name(1:end-4);
        % Calculate MSF
        [pseudoXMCD,MSF,MSFTable] = MSFCalc_OVF(strcat(filePath,'/',fileList(i).name,'/',exportName,'.ovf'),650,steps,3,method);
        % Export the MSF
        msfFigure = figure('visible','off','Name','Magnetic Structure Factor', 'Position', [100,100,2000,1600]);
        ax1 = axes(msfFigure,'Visible','off');
        imagesc(ax1,MSF);
        pbaspect(ax1,[1,1,1]);
        colormap(parula);
        colorbar;
        set(ax1,'FontSize',20)
        set(ax1,'colorscale','linear')
        caxis('auto')
        set(ax1,'YDir','normal');
        print(msfFigure,sprintf('%s/MSF_%s.tif',filePath,exportName),'-dtiffn');
        close(msfFigure);
        % Export the XMCD image
        msfFigure = figure('visible','off','Name','Magnetic Structure Factor', 'Position', [100,100,2000,1600]);
        ax1 = axes(msfFigure,'Visible','off');
        imagesc(ax1,pseudoXMCD);
        pbaspect(ax1,[1,1,1]);
        colormap(gray);
        colorbar;
        set(ax1,'FontSize',20)
        set(ax1,'colorscale','linear')
        caxis('auto')
        set(ax1,'YDir','normal');
        print(msfFigure,sprintf('%s/XMCD_%s.tif',filePath,exportName),'-dtiffn');
        close(msfFigure);
        % Export the MSF table
        dlmwrite(sprintf('%s/MSFTable_%s.txt',filePath,exportName),MSFTable);
        if isRunningWizard; msfDialog.Value = i/length(fileList); end
    end
    if isRunningWizard; close(msfDialog); end
end