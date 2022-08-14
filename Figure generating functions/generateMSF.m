% Generates and plots the magnetic structure factor
%function generateMSF(app,savePath,saveOption,tableOption)
function [MSF,MSFTable] = generateMSF(app,steps,qMax,xSpin,ySpin,xR,yR,method,type,options)
    arguments
        app                     % The ASIWizard app. Set this parameter to ~ when not using the app
        steps (1,1) int16       % Number of pixels along qx/qy
        qMax (1,1) double       % Max/min values of qx/qy
        xSpin (:,1) double      % Vector containing x component of spin vector
        ySpin (:,1) double      % Vector containing y component of spin vector
        xR (:,1) double         % Vector containing x position of position vector
        yR (:,1) double         % Vector containing y position of position vector

        % MSF calculation method
        %   "full": Calculate each individual point
        %   "half": Calculate only the 1st and 4th quadrants in q-space. Then
        %           use inversion symmetry relation to extract 2nd and 3rd quadrants
        method {mustBeMember(method,['full','half'])}

        % Type of dataset
        %   "ideal asi": ASI data extracted from ASIWizard or IceScanner
        %   "mumax': Data extracted from mumax/oommf ovf file converted into csv
        type {mustBeMember(type,['asi','mumax'])}
        
        % Directory to save MSF data as an image or (optionally) a table
        options.SaveTo char

        % Option to save MSF data as a table. SaveTo must be populated
        options.Table {mustBeMember(options.Table,['on','off'])}
    end

    try
        % Define qx and qy positions
        range_qx = linspace(-qMax*2*pi,qMax*2*pi,steps); range_qy = range_qx; 
        % Define the qx range for the 1st/4th quadrant
        qx_Q1_Range = range_qx(steps/2+1:end);
        % Define the MSF in "2D image" and table form
        MSF = zeros(length(range_qx));      % Dimensions: row = qy, column = qx
        MSFTable = zeros(length(MSF)^2,3);  % Dimensions: col1: qx, col2: qy, col3: I
        % Create doubleSteps. It's the double-precision version of steps
        doubleSteps = double(steps);

        % Define the intensity variable in the 1st and 4th quadrants
        % Dimensions: colX = steps/2, x-range from qx_Q1_Range(1) ~ 0 to qx_Q1_Range(end) = +qMax
        %             rowY = steps, y-range from range_qy(1) = -qMax to range_qy(end) = +qMax
        intensity_Q1Q4 = zeros(steps,steps/2);
        % Remove all NaN magnets
        xR = xR(~isnan(xSpin)); yR = yR(~isnan(xSpin));
        xSpin = xSpin(~isnan(xSpin)); ySpin = ySpin(~isnan(xSpin));
        % Apply corrections for either OVF or ASIWizard data
        switch type
            case 'mumax'
                % For OVF files, delete all zero-spin entries to speed up calculation
                idxZeroSpin = (ySpin == 0 & xSpin == 0);
                xR(idxZeroSpin)=[];yR(idxZeroSpin)=[];xSpin(idxZeroSpin)=[];ySpin(idxZeroSpin)=[];
        end
        invSpinLength = 1/length(xSpin);

        % Calculating MSF by calling subfunctions fullMSF or halfMSF
        % Check if the function was called by ASIWizard
        if exist("app",'var'); isRunningWizard = ~isempty(app); end;
        if isRunningWizard
            msfDialog = uiprogressdlg(app.IceScannerUI,'Title','Magnetic structure factor','Message',...
                'Generating the magnetic structure factor. This may take several minutes.');
        end
        switch method
            case 'full'; fullMSF;
            case 'half'; halfMSF;
        end

        % Generate MSF figure
        if isRunningWizard
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
        if isRunningWizard; close(imageStatus); end
        
        % Converts 2D MSF matrix into n*3 matrix, where each column represents qx, qy, and I, respectively
        if isRunningWizard
            convertStatus = uiprogressdlg(app.IceScannerUI,'Title','Generating text file','Message',...
                'Exporting MSF text file.','Indeterminate','on');
        end
        for i = 1:length(MSF)
            if isRunningWizard; convertStatus.Value = i/length(MSF); end
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

        if isRunningWizard;close(convertStatus);end

    catch ME
        if exist('msfDialog','var'); close(msfDialog); end
        if isRunningWizard; errorNotice(app,ME); end
        return;
    end

    %% Functions for calculating the "full" and "half" MSFs
    % Calculate the MSF intensity at each point in q-space
    function fullMSF
        % Calculate MSF using inversion-symmetry-based calculation
        onesVector_Q = ones(steps,1);
        for x = 1:steps
            qx = range_qx(x);
            q_dot_r_xComp = (qx*xR); 
            % Determine the scattering unit vector
            qNorm = sqrt((qx^2*onesVector_Q')+range_qy.^2);
            qHat_x = qx./qNorm;
            qHat_y = range_qy./qNorm; 
            % Define the perpendicular spin vector (at the specified q) using matrix representation
            q_dot_S = qHat_x.*xSpin + qHat_y.*ySpin;
            q_dot_S_dot_qHat_x = q_dot_S.*qHat_x; q_dot_S_dot_qHat_y = q_dot_S.*qHat_y;
            % Define dot product vector between q and r_ij
            q_dot_r = (onesVector_Q'.*q_dot_r_xComp + range_qy.*yR);
            % Calculate A and B
            V_cos = cos(q_dot_r);
            V_sin = sin(q_dot_r);
            A = [sum((xSpin - q_dot_S_dot_qHat_x).*V_cos,1);sum((ySpin - q_dot_S_dot_qHat_y).*V_cos,1)];
            B = [sum((xSpin - q_dot_S_dot_qHat_x).*V_sin,1);sum((ySpin - q_dot_S_dot_qHat_y).*V_sin,1)];
            MSF(:,x) = invSpinLength * (sum(A.*A,1) + sum(B.*B,1))';
            if isRunningWizard; msfDialog.Value = x/doubleSteps; end
        end
        if isRunningWizard; close(msfDialog); end
    end
    % Symmetry-optimized MSF calculation: Solve for MSF intensity at each point
    % in the 1st and 4th quadrants in q-space. Then use inversion symmetry
    % to relate 1st-3rd and 4th-2nd quadrant intensities.
    function halfMSF
        for x = 1:length(qx_Q1_Range)
            qx = qx_Q1_Range(x);
            qx_xR = qx*xR;
            for y = 1:length(range_qy)
                % Determine the scattering vector
                qy = range_qy(y);
                qNorm = sqrt(qx^2+qy^2);
                qHat_x = qx/qNorm;
                qHat_y = qy/qNorm;
                % Define the perpendicular spin vector (at the specified qx and qy) using matrix representation
                q_dot_S = qHat_x*xSpin + qHat_y*ySpin;
                S_perp_x = (xSpin - q_dot_S*qHat_x)';
                S_perp_y = (ySpin - q_dot_S*qHat_y)';
                % Define dot product vector between q=(qx,qy) and r_ij
                % q_dot_r dimension: spinLength X 1 vector
                q_dot_r = (qx_xR + qy*yR);
                V_cos = cos(q_dot_r);
                V_sin = sin(q_dot_r);
                % Determine A and B
                A = [S_perp_x*V_cos;S_perp_y*V_cos]; B = [S_perp_x*V_sin;S_perp_y*V_sin];
                % Determine A and B (see Ostman's paper: https://doi.org/10.1038/s41567-017-0027-2)
                intensity_Q1Q4(y,x) = invSpinLength * ((A'*A) + (B'*B));
            end
            if isRunningWizard; msfDialog.Value = x/doubleSteps*2; end
        end
        if isRunningWizard; close(msfDialog); end
        % Update MSF
        MSF(:,steps/2+1:end) = intensity_Q1Q4;
        MSF(end:-1:1,steps/2:-1:1) = intensity_Q1Q4;
    end
end