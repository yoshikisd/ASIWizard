% Generates and plots the magnetic structure factor
%function generateMSF(app,savePath,saveOption,tableOption)
function [MSF,MSFTable] = generateMSF(app,steps,qMax,xSpin,ySpin,xR,yR,options)
    arguments
        app
        steps (1,1) int16
        qMax (1,1) double
        xSpin double
        ySpin double
        xR double
        yR double
        options.SaveTo char % Combines savePath and saveOption
        options.Table {mustBeMember(options.Table,['on','off'])}
        options.Type {mustBeMember(options.Type,["ideal asi","mumax"])}
    end

    try
        range_qx = linspace(-qMax*2*pi,qMax*2*pi,steps);
        range_qy = range_qx;
        MSF = zeros(length(range_qx));
        MSFTable = zeros(length(MSF)^2,3);
        % Remove all NaN magnets
        xR = xR(~isnan(xSpin));         yR = yR(~isnan(xSpin));
        xSpin = xSpin(~isnan(xSpin));   ySpin = ySpin(~isnan(xSpin));
        invSpinLength = 1/length(xSpin);
        onesVector_Q = ones(steps,1);

        %% Calculating MSF
        % If ASIWizard is calling this function, create the loading bar in the UI and update the loading counter after
        % every iteration of the MSF calculation loop. Otherwise, just calculate the MSF
        if exist("app",'var')
            msfDialog = uiprogressdlg(app.IceScannerUI,'Title','Magnetic structure factor','Message',...
                'Generating the magnetic structure factor. This may take several minutes.');
        end
        
        % Calculate MSF
        for x = 1:steps
            qx = range_qx(x);
            q_dot_r_xComp = (qx*xR); 
            % Determine the scattering unit vector
            qNorm = sqrt((qx^2*onesVector_Q')+range_qy.^2);
            qHat_x = qx./qNorm;
            qHat_y = range_qy./qNorm; 
            % Define the perpendicular spin vector (at the specified q) using matrix representation
            q_dot_S = qHat_x.*xSpin + qHat_y.*ySpin;
            q_dot_S_dot_qHat_x = q_dot_S.*qHat_x;
            q_dot_S_dot_qHat_y = q_dot_S.*qHat_y;
            % Define dot product vector between q and r_ij
            q_dot_r = (onesVector_Q'.*q_dot_r_xComp + range_qy.*yR);
            % Calculate A and B
            A = [sum((xSpin - q_dot_S_dot_qHat_x).*cos(q_dot_r),1);sum((ySpin - q_dot_S_dot_qHat_y).*cos(q_dot_r),1)];
            B = [sum((xSpin - q_dot_S_dot_qHat_x).*sin(q_dot_r),1);sum((ySpin - q_dot_S_dot_qHat_y).*sin(q_dot_r),1)];
            MSF(x,:) = invSpinLength * (sum(A.*A,1) + sum(B.*B,1));
            if exist("app",'var'); msfDialog.Value = x/steps; end
        end
        if exist("app",'var'); close(msfDialog); end

        %% Generate MSF figure
        if exist("app",'var')
            imageStatus = uiprogressdlg(app.IceScannerUI,'Title','Generating image','Message',...
                'Generating MSF image for previewing.','Indeterminate','on');
        end
        msfFigure = figure('visible','off','Name','Magnetic Structure Factor', 'Position', [100,100,2000,1600]);
        ax1 = axes(msfFigure,'Visible','off');
        imagesc(ax1,MSF);
        pbaspect(ax1,[1,1,1]);
        colormap(parula);
        colorbar;
        set(ax1,'FontSize',20)
        set(ax1,'colorscale','linear')
        caxis('auto')
        if isfield(options,"SaveTo")
            print(msfFigure,sprintf('%sMSF.tif',options.SaveTo),'-dtiffn');
            close(msfFigure);
        end
        if exist("app",'var')
            close(imageStatus);
        end
        
        % Converts 2D MSF matrix into n*3 matrix, where each column represents qx, qy, and I, respectively
        if exist("app",'var')
            convertStatus = uiprogressdlg(app.IceScannerUI,'Title','Generating text file','Message',...
                'Exporting MSF text file.','Indeterminate','on');
        end
        for i = 1:length(MSF)
            if exist("app",'var'); convertStatus.Value = i/length(MSF); end
            for j = 1:length(MSF)
                % Store qx
                MSFTable(j + length(MSF)*(i-1),1) = range_qx(i);
                MSFTable(j + length(MSF)*(i-1),2) = range_qy(j);
                MSFTable(j + length(MSF)*(i-1),3) = MSF(i,j);
            end
        end
        
        if isfield(options,"Table") && isfield(options,"SaveTo")
            if strcmp(options.Table,'on')
                dlmwrite(sprintf('%sMSF.txt',options.SaveTo),MSFTable);
            end
        end

        if exist("app",'var');close(convertStatus);end

    catch ME
        if exist('msfDialog','var'); close(msfDialog); end
        if exist("app",'var'); errorNotice(app,ME); end
        return;
    end
end