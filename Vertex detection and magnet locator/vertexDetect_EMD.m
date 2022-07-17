function vertexDetect_EMD(app)
    % Calculates the Earth Movers Distance between a reference vertex image and a region in the topography image
    % Set x and y limits for each analyzed image
    [ySizeGrid,xSizeGrid] = size(app.EMDGrid);                          % Initial x and y limits for ASI topography image
    [ySizeRef1,xSizeRef1] = size(app.refFrame1);                        % Initial x and y limits for first vertex reference image

    % Set initial scanning length limits relative to a scanning center (your current index (i,j))
    yBranchLen = floor(ySizeRef1/2);                                    % Scanning length along y direction, relative to the scanning center
    xBranchLen = floor(xSizeRef1/2);                                    % Scanning length along x direction, relative to the scanning center

    % Convert reference images into format readable by cvEMD (the "signatures")
    numFrameElements = numel(app.refFrame1);                                % Total number of pixels inside the first reference image
    refInfo1 = zeros(numFrameElements,3);                               % Information regarding the reference image intensity and location
                                                                        % refInfo(1,:) = [grayscale intensity, x coordinate, y coordinate]
    app.refFrame1 = app.refFrame1 / sum(app.refFrame1,'all');           % Normalize the reference frame for comparison in EMD
    refInfo1(:,1) = app.refFrame1(1:numFrameElements);                  % Store the relevant information in refInfo1
    [refInfo1(:,2),refInfo1(:,3)] = ...
        ind2sub([ySizeRef1,xSizeRef1],1:numFrameElements);

    % In the V7 version of the code, the X and Y were switched. Keep this in mind if you process data acquired from that version
    % or earlier...
    currentInfoX = refInfo1(:,2);                                       % Saves the x/Col positions of the reference frame (i.e., refInfo1 and 2)
    currentInfoY = refInfo1(:,3);                                       % Saves the y/Row positions of the reference frame (i.e., refInfo1 and 2)

    % Initialize the scanning range vector and extent to which points are skipped during the scan at regular intervals 
    jRange = yBranchLen + 1:app.EMD_skipInterval.Value:ySizeGrid - yBranchLen;
    iRange = xBranchLen + 1:app.EMD_skipInterval.Value:xSizeGrid - xBranchLen;

    % Initialize a matrix earthMoversDistance that stores the calculated cvEMD values = [EMD intensity, x position, y position]
    privateJRangeSize = numel(jRange);
    privateIRangeSize = numel(iRange);
    app.jRangeSize = privateJRangeSize;
    app.iRangeSize = privateIRangeSize;
    privateEmdGlobalRef1 = NaN(app.jRangeSize,app.iRangeSize,3);           % With the parfor loop, a single instance of distance bank cannot be used to store
    privateEmdGlobalRef2 = NaN(app.jRangeSize,app.iRangeSize,3);           % the distances associated with multiple different reference frames.
    privateEmdGlobalRef3 = NaN(app.jRangeSize,app.iRangeSize,3);           % the distances associated with multiple different reference frames.
    privateEmdGlobalRef4 = NaN(app.jRangeSize,app.iRangeSize,3);           % the distances associated with multiple different reference frames.
    privateEmdGlobalRef5 = NaN(app.jRangeSize,app.iRangeSize,3);           % the distances associated with multiple different reference frames.
    privateEmdGlobalRef6 = NaN(app.jRangeSize,app.iRangeSize,3);           % the distances associated with multiple different reference frames.
    privateEmdGlobalRef7 = NaN(app.jRangeSize,app.iRangeSize,3);           % the distances associated with multiple different reference frames.
    privateEmdGlobalRef8 = NaN(app.jRangeSize,app.iRangeSize,3);           % the distances associated with multiple different reference frames.

    % Duplicate values from app to allow for parfor calculation
    privateEMDGrid = app.EMDGrid;
    privateScalingFactor = app.EMD_scaleFactor.Value;


    % Make a nice waitbar to tell how far the calculation has progressed
    parDataQ = parallel.pool.DataQueue;
    statusEMD = uiprogressdlg(app.IceScannerUI,'Title','EMD calculation','Message',...
       'Calculating how dissimilar the reference images are compared to regions in the topography image. This will take several minutes.',...
       'Cancelable','off');
    afterEach(parDataQ, @nUpdateWaitbar);
    p = 1;
    try
        % The meat and potatoes: EMD Calculation
        switch app.vd.typeASI
            case 'Square' % Square ASI system
                parfor j = 1:privateJRangeSize
                    % Initialize a matrix of zeros to temporarily store a small frame of EMDGrid
                    currentFrame = zeros(ySizeRef1,xSizeRef1);          
                    % Initialize a matrix of zeros to temporarily store the locally determined EMD w/r to ref 1 and ref 2 -> [EMD intensity, x position, y position]
                    emdLocalRef1 = zeros(1,privateIRangeSize,3);
                    % Store the current y-position value
                    jPar = jRange(j);                                   
                    for i = 1:privateIRangeSize
                        % Store the current x-position value
                        iPar = iRange(i);                               
                        % Define/redefine an [j-yBranchLen:j+yBranchLen] X [i-xBranchLen:i+xBranchLen] frame to compare with the reference frame
                        currentFrame = privateEMDGrid((jPar-yBranchLen:jPar+yBranchLen),(iPar-xBranchLen:iPar+xBranchLen));
                        % Normalize local frame
                        currentFrame = currentFrame/sum(currentFrame,'all');
                        % Convert the matrix into a "signature" (according to EMD), where all rows contain the grayscale intensity along with the x and
                        % y coordinates
                        currentInfo = [(currentFrame(1:numFrameElements)/sum(currentFrame,'all'))',currentInfoX,currentInfoY];
                        % Calculate the Earth Movers Distance
                        emdLocalRef1(1,i,1) = cvEMD(refInfo1,currentInfo,'DistType','L1');
                        % Recalculate the original unscaled position values associated with the calculated EMD intensities
                        emdLocalRef1(1,i,2) = floor(iPar / privateScalingFactor);
                        emdLocalRef1(1,i,3) = floor(jPar / privateScalingFactor);
                    end
                    % Update values in the global EMD storage matrices
                    privateEmdGlobalRef1(j,:,:) = emdLocalRef1;
                    send(parDataQ,j);
                end

            case {'Brickwork','Kagome'} % Other than square ASI
                refInfo2 = zeros(numFrameElements,3);                       % Information regarding the reference image intensity and location
                app.refFrame2 = app.refFrame2 / sum(app.refFrame2,'all');   % Normalize the reference frame for comparison in EMD
                refInfo2(:,1) = app.refFrame2(1:numFrameElements);              % Store the relevant information in refInfo2
                [refInfo2(:,2),refInfo2(:,3)] = ...
                    ind2sub([ySizeRef1,xSizeRef1],1:numFrameElements);

                % Start calculation
                parfor j = 1:privateJRangeSize
                    % Initialize a matrix of zeros to temporarily store a small frame of EMDGrid
                    currentFrame = zeros(ySizeRef1,xSizeRef1);          
                    % Initialize a matrix of zeros to temporarily store the locally determined EMD w/r to ref 1 and ref 2 -> [EMD intensity, x position, y position]
                    emdLocalRef1 = zeros(1,privateIRangeSize,3);
                    emdLocalRef2 = zeros(1,privateIRangeSize,3);   
                    % Store the current y-position value
                    jPar = jRange(j);                                   
                    for i = 1:privateIRangeSize
                        % Store the current x-position value
                        iPar = iRange(i);                               
                        % Define/redefine an [j-yBranchLen:j+yBranchLen] X [i-xBranchLen:i+xBranchLen] frame to compare with the reference frame
                        currentFrame = privateEMDGrid((jPar-yBranchLen:jPar+yBranchLen),(iPar-xBranchLen:iPar+xBranchLen));
                        currentFrame = currentFrame./sum(currentFrame,'all');
                        % Convert the matrix into a "signature" (according to EMD), where all rows contain the grayscale intensity along with the x and
                        % y coordinates
                        currentInfo = [(currentFrame(1:numFrameElements)/sum(currentFrame,'all'))',currentInfoX,currentInfoY];
                        % Calculate the Earth Movers Distance
                        emdLocalRef1(1,i,1) = cvEMD(refInfo1,currentInfo,'DistType','L1');
                        emdLocalRef2(1,i,1) = cvEMD(refInfo2,currentInfo,'DistType','L1');
                        % Recalculate the original unscaled position values associated with the calculated EMD intensities
                        emdLocalRef1(1,i,2) = floor(iPar / privateScalingFactor);
                        emdLocalRef1(1,i,3) = floor(jPar / privateScalingFactor);
                    end
                    emdLocalRef2(1,:,2) = emdLocalRef1(1,:,2);
                    emdLocalRef2(1,:,3) = emdLocalRef1(1,:,3);
                    % Update values in the global EMD storage matrices
                    privateEmdGlobalRef1(j,:,:) = emdLocalRef1;
                    privateEmdGlobalRef2(j,:,:) = emdLocalRef2;
                    send(parDataQ,j);
                end
                app.emdGlobalRef2 = privateEmdGlobalRef2;

            case 'Tetris'
                refInfo2 = zeros(numFrameElements,3);                       % Information regarding the reference image intensity and location
                app.refFrame2 = app.refFrame2 / sum(app.refFrame2,'all');   % Normalize the reference frame for comparison in EMD
                refInfo2(:,1) = app.refFrame2(1:numFrameElements);              % Store the relevant information in refInfo2
                [refInfo2(:,2),refInfo2(:,3)] = ...
                    ind2sub([ySizeRef1,xSizeRef1],1:numFrameElements);

                refInfo3 = zeros(numFrameElements,3);                       % Information regarding the reference image intensity and location
                app.refFrame3 = app.refFrame3 / sum(app.refFrame3,'all');   % Normalize the reference frame for comparison in EMD
                refInfo3(:,1) = app.refFrame3(1:numFrameElements);              % Store the relevant information in refInfo3
                [refInfo3(:,2),refInfo3(:,3)] = ...
                    ind2sub([ySizeRef1,xSizeRef1],1:numFrameElements);

                refInfo4 = zeros(numFrameElements,3);                       % Information regarding the reference image intensity and location
                app.refFrame4 = app.refFrame4 / sum(app.refFrame4,'all');   % Normalize the reference frame for comparison in EMD
                refInfo4(:,1) = app.refFrame4(1:numFrameElements);              % Store the relevant information in refInfo4
                [refInfo4(:,2),refInfo4(:,3)] = ...
                    ind2sub([ySizeRef1,xSizeRef1],1:numFrameElements);

                refInfo5 = zeros(numFrameElements,3);                       % Information regarding the reference image intensity and location
                app.refFrame5 = app.refFrame5 / sum(app.refFrame5,'all');   % Normalize the reference frame for comparison in EMD
                refInfo5(:,1) = app.refFrame5(1:numFrameElements);              % Store the relevant information in refInfo5
                [refInfo5(:,2),refInfo5(:,3)] = ...
                    ind2sub([ySizeRef1,xSizeRef1],1:numFrameElements);

                refInfo6 = zeros(numFrameElements,3);                       % Information regarding the reference image intensity and location
                app.refFrame6 = app.refFrame6 / sum(app.refFrame6,'all');   % Normalize the reference frame for comparison in EMD
                refInfo6(:,1) = app.refFrame6(1:numFrameElements);              % Store the relevant information in refInfo6
                [refInfo6(:,2),refInfo6(:,3)] = ...
                    ind2sub([ySizeRef1,xSizeRef1],1:numFrameElements);

                refInfo7 = zeros(numFrameElements,3);                       % Information regarding the reference image intensity and location
                app.refFrame7 = app.refFrame7 / sum(app.refFrame7,'all');   % Normalize the reference frame for comparison in EMD
                refInfo7(:,1) = app.refFrame7(1:numFrameElements);              % Store the relevant information in refInfo7
                [refInfo7(:,2),refInfo7(:,3)] = ...
                    ind2sub([ySizeRef1,xSizeRef1],1:numFrameElements);

                refInfo8 = zeros(numFrameElements,3);                       % Information regarding the reference image intensity and location
                app.refFrame8 = app.refFrame8 / sum(app.refFrame8,'all');   % Normalize the reference frame for comparison in EMD
                refInfo8(:,1) = app.refFrame8(1:numFrameElements);              % Store the relevant information in refInfo8
                [refInfo8(:,2),refInfo8(:,3)] = ...
                    ind2sub([ySizeRef1,xSizeRef1],1:numFrameElements);

                % Start calculation
                parfor j = 1:privateJRangeSize
                    % Initialize a matrix of zeros to temporarily store a small frame of EMDGrid
                    currentFrame = zeros(ySizeRef1,xSizeRef1);          
                    % Initialize a matrix of zeros to temporarily store the locally determined EMD w/r to ref 1 and ref 2 -> [EMD intensity, x position, y position]
                    emdLocalRef1 = zeros(1,privateIRangeSize,3);
                    emdLocalRef2 = zeros(1,privateIRangeSize,3);   
                    emdLocalRef3 = zeros(1,privateIRangeSize,3); 
                    emdLocalRef4 = zeros(1,privateIRangeSize,3); 
                    emdLocalRef5 = zeros(1,privateIRangeSize,3);
                    emdLocalRef6 = zeros(1,privateIRangeSize,3); 
                    emdLocalRef7 = zeros(1,privateIRangeSize,3); 
                    emdLocalRef8 = zeros(1,privateIRangeSize,3); 
                    % Store the current y-position value
                    jPar = jRange(j);                                   
                    for i = 1:privateIRangeSize
                        % Store the current x-position value
                        iPar = iRange(i);                               
                        % Define/redefine an [j-yBranchLen:j+yBranchLen] X [i-xBranchLen:i+xBranchLen] frame to compare with the reference frame
                        currentFrame = privateEMDGrid((jPar-yBranchLen:jPar+yBranchLen),(iPar-xBranchLen:iPar+xBranchLen));
                        currentFrame = currentFrame./sum(currentFrame,'all');
                        currentFrame(currentFrame == 0) = 0.01;
                        % Convert the matrix into a "signature" (according to EMD), where all rows contain the grayscale intensity along with the x and
                        % y coordinates
                        currentInfo = [(currentFrame(1:numFrameElements)/sum(currentFrame,'all'))',currentInfoX,currentInfoY];
                        % Calculate the Earth Movers Distance
                        emdLocalRef1(1,i,1) = cvEMD(refInfo1,currentInfo,'DistType','L1');
                        emdLocalRef2(1,i,1) = cvEMD(refInfo2,currentInfo,'DistType','L1');
                        emdLocalRef3(1,i,1) = cvEMD(refInfo3,currentInfo,'DistType','L1');
                        emdLocalRef4(1,i,1) = cvEMD(refInfo4,currentInfo,'DistType','L1');
                        emdLocalRef5(1,i,1) = cvEMD(refInfo5,currentInfo,'DistType','L1');
                        emdLocalRef6(1,i,1) = cvEMD(refInfo6,currentInfo,'DistType','L1');
                        emdLocalRef7(1,i,1) = cvEMD(refInfo7,currentInfo,'DistType','L1');
                        emdLocalRef8(1,i,1) = cvEMD(refInfo8,currentInfo,'DistType','L1');
                        % Recalculate the original unscaled position values associated with the calculated EMD intensities
                        emdLocalRef1(1,i,2) = floor(iPar / privateScalingFactor);
                        emdLocalRef1(1,i,3) = floor(jPar / privateScalingFactor);
                    end
                    emdLocalRef2(1,:,2) = emdLocalRef1(1,:,2);
                    emdLocalRef3(1,:,2) = emdLocalRef1(1,:,2);
                    emdLocalRef4(1,:,2) = emdLocalRef1(1,:,2);
                    emdLocalRef5(1,:,2) = emdLocalRef1(1,:,2);
                    emdLocalRef6(1,:,2) = emdLocalRef1(1,:,2);
                    emdLocalRef7(1,:,2) = emdLocalRef1(1,:,2);
                    emdLocalRef8(1,:,2) = emdLocalRef1(1,:,2);

                    emdLocalRef2(1,:,3) = emdLocalRef1(1,:,3);
                    emdLocalRef3(1,:,3) = emdLocalRef1(1,:,3);
                    emdLocalRef4(1,:,3) = emdLocalRef1(1,:,3);
                    emdLocalRef5(1,:,3) = emdLocalRef1(1,:,3);
                    emdLocalRef6(1,:,3) = emdLocalRef1(1,:,3);
                    emdLocalRef7(1,:,3) = emdLocalRef1(1,:,3);
                    emdLocalRef8(1,:,3) = emdLocalRef1(1,:,3);

                    % Update values in the global EMD storage matrices
                    privateEmdGlobalRef1(j,:,:) = emdLocalRef1;
                    privateEmdGlobalRef2(j,:,:) = emdLocalRef2;
                    privateEmdGlobalRef3(j,:,:) = emdLocalRef3;
                    privateEmdGlobalRef4(j,:,:) = emdLocalRef4;
                    privateEmdGlobalRef5(j,:,:) = emdLocalRef5;
                    privateEmdGlobalRef6(j,:,:) = emdLocalRef6;
                    privateEmdGlobalRef7(j,:,:) = emdLocalRef7;
                    privateEmdGlobalRef8(j,:,:) = emdLocalRef8;
                    send(parDataQ,j);
                end
                app.emdGlobalRef2 = privateEmdGlobalRef2;
                app.emdGlobalRef3 = privateEmdGlobalRef3;
                app.emdGlobalRef4 = privateEmdGlobalRef4;
                app.emdGlobalRef5 = privateEmdGlobalRef5;
                app.emdGlobalRef6 = privateEmdGlobalRef6;
                app.emdGlobalRef7 = privateEmdGlobalRef7;
                app.emdGlobalRef8 = privateEmdGlobalRef8;
        end
        close(statusEMD);

        % Transfer parpool calculations to app structure
        app.emdGlobalRef1 = privateEmdGlobalRef1;

        plotStatus = uiprogressdlg(app.IceScannerUI,'Title','Plotting','Message',...
            'Processing the rough detection points.',...
            'Indeterminate','on');
        vertexDetect_roughDetection(app);
        close(plotStatus);
    catch ME
        close(statusEMD)
        errorNotice(app,ME);
        return;
    end
    

    % Function for the waitbar
    function nUpdateWaitbar(~)
        statusEMD.Value = p/privateJRangeSize;
        p = p+1;
    end


end