% Generates and plots the magnetic structure factor
function generateMSF(app,savePath,saveOption,tableOption)
    try
        steps = app.MSFSteps.Value;
        qMax = app.MSFStart.Value;
        qMin = app.MSFEnd.Value;
        range_qx = linspace(qMin*pi,qMax*pi,steps+1);
        rangeQxSize = length(range_qx);
        range_qy = range_qx;
        intensityMatrix = zeros(length(range_qx));
        xSpin = vertcat(app.vd.magnet.xSpin);
        ySpin = vertcat(app.vd.magnet.ySpin);
        xR = vertcat(app.vd.magnet.xR);
        yR = vertcat(app.vd.magnet.yR);

        % Remove all NaN magnets
        xR = xR(~isnan(xSpin));
        yR = yR(~isnan(xSpin));
        ySpin = ySpin(~isnan(xSpin));
        xSpin = xSpin(~isnan(xSpin));
        spinLength = length(xSpin);
        invSpinLength = 1/spinLength;
        onesVector_Q = ones(rangeQxSize,1);
        parDataQ = parallel.pool.DataQueue;
        msfDialog = uiprogressdlg(app.IceScannerUI,'Title','Magnetic structure factor','Message',...
            'Generating the magnetic structure factor. This may take several minutes.');
        afterEach(parDataQ, @nUpdateWaitbarMSF);
        p = 1;

        parfor x = 1:rangeQxSize
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
            intensityMatrix(x,:) = invSpinLength * (sum(A.*A,1) + sum(B.*B,1));
            send(parDataQ,x);
        end
        app.vd.postProcess.MSF.map = intensityMatrix;
        close(msfDialog);

        % Generate MSF figure
        imageStatus = uiprogressdlg(app.IceScannerUI,'Title','Generating image','Message',...
            'Generating MSF image for previewing.','Indeterminate','on');
        msfFigure = figure('visible','off','Name','Magnetic Structure Factor', 'Position', [100,100,2000,1600]);
        ax1 = axes(msfFigure,'Visible','off');
        imagesc(ax1,intensityMatrix);
        pbaspect(ax1,[1,1,1]);
        xticks([1:steps/6:steps+1])
        yticks([1:steps/6:steps+1])
        colormap(parula);
        colorbar;
        app.vd.postProcess.MSF.image = frame2im(getframe(msfFigure));
        set(ax1,'FontSize',20)
        set(ax1,'colorscale','linear')
        caxis('auto')
        switch saveOption
            case 'on'
                print(msfFigure,sprintf('%sMSF.tif',savePath),'-dtiffn');
        end
        close(msfFigure);
        close(imageStatus);

        switch tableOption
            case 'on'
                % Converts 2D MSF matrix into n*3 matrix, where each column represents qx, qy, and I, respectively
                exportMatrix = zeros(length(intensityMatrix)^2,3);
                convertStatus = uiprogressdlg(app.IceScannerUI,'Title','Generating text file','Message',...
                    'Exporting MSF text file.','Indeterminate','on');
                for i = 1:length(intensityMatrix)
                    convertStatus.Value = i/length(intensityMatrix);
                    for j = 1:length(intensityMatrix)
                        % Store qx
                        exportMatrix(j + length(intensityMatrix)*(i-1),1) = range_qx(i)/(pi);
                        exportMatrix(j + length(intensityMatrix)*(i-1),2) = range_qy(j)/(pi);
                        exportMatrix(j + length(intensityMatrix)*(i-1),3) = intensityMatrix(i,j);
                    end
                end
                app.vd.postProcess.MSF.mapExport = exportMatrix;
                switch saveOption
                    case 'on'
                        dlmwrite(sprintf('%sMSF.txt',savePath),exportMatrix);
                end
                close(convertStatus);
        end

    catch ME
        if exist('msfDialog','var')
            close(msfDialog);
        end
        errorNotice(app,ME);
        return;
    end

    % Function for the waitbar
    function nUpdateWaitbarMSF(~)
        msfDialog.Value = p/rangeQxSize;
            p = p+1;
    end
end