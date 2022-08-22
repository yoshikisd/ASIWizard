function [EMDMtx,detectState,confidence] = magDetectEMD(filePath,magnet,numRows,numCols,app)
    % Define lengths
    magLength = length(magnet);

    % Create matrix with values of x- and y-positions
    xPosMtx = zeros(numRows,numCols);   yPosMtx = xPosMtx;
    for i = 1:numCols; xPosMtx(:,i) = i; end
    for i = 1:numRows; yPosMtx(i,:) = i; end
    % Convert the xPosMtx and yPosMtx into vectors
    xPos = xPosMtx(:);  yPos = yPosMtx(:);
    
    % Load reference magnetization states in structure magRef
    magRef = struct('name',[],'imgRescale',[],'imgOriginal',[],'imgEMD',[]);
    magRef(1).name = 'Ising_X';
    % Orient 2 "/" images
    magRef(2).name = 'OBIW_1';  magRef(4).name = 'OWIB_1';
    magRef(6).name = 'TBBW_1';  magRef(8).name = 'TWBB_1';
    % Orient 3 "\" images
    magRef(3).name = 'OBIW_2';  magRef(5).name = 'OWIB_2';
    magRef(7).name = 'TBBW_2';  magRef(9).name = 'TWBB_2';
    
    % Load images
    for i = 1:length(magRef)
        % Save original image
        temp = imread(strcat(filePath,'/',magRef(i).name,'.tif'));
        magRef(i).imgOriginal = temp;
        % Save resized image for EMD calculation
        temp = imresize(temp,[numRows numCols]);
        temp = temp + abs(min(temp,[],'all')) + 1;
        magRef(i).imgRescale = temp / sum(temp,'all');
        % Convert image into EMD-readable format
        magRef(i).imgEMD = [magRef(i).imgRescale(:),xPos,yPos];
    end
   
    % Separate calculation into two parts depending on the orientation of the magnet:
    % Get a list of the different magnet orientation (need to include implemetation for Kagome ASI later)
    magIdxOrient2 = find(vertcat(magnet.orient) == 2);  magIdxOrient3 = find(vertcat(magnet.orient) == 3);

    % Establish which specific reference images to look for based on the orientation
    magRefOrient2 = [1,2,4,6,8];    magRefOrient3 = [1,3,5,7,9];
    magRefOrient2Length = length(magRefOrient2);    magRefOrient3Length = length(magRefOrient3);

    % Define EMDMatrix, which will store the EMD values associated with each magRef
    % Format:
    %   Rows - magnet in order of associated idx
    %   Columns - magRef in order shown in lines 12-22
    EMDMtx = nan(magLength,magRefOrient2Length);
    EMDMtxOrient2 = nan(length(magIdxOrient2),magRefOrient2Length); EMDMtxOrient3 = nan(length(magIdxOrient3),magRefOrient3Length);
    % Define cell vector detectedState
    detectState = cell(magRefOrient2Length ,1);
    detectStateOrient2 = cell(length(magIdxOrient2),1); detectStateOrient3 = cell(length(magIdxOrient3),1);
    % Define relative confidence vector
    confidence = zeros(magRefOrient2Length,1);
    confidenceOrient2 = zeros(length(magIdxOrient2),1); confidenceOrient3 = zeros(length(magIdxOrient3),1);

    % If the ASIWizard app called this function, show a loading bar
    if ~isempty(app)
        statusEMD = uiprogressdlg(app.IceScannerUI,'Title','Classifying domains','Message',...
            'Performing domain classifications on ROIs.');
    end
    parDataQ = parallel.pool.DataQueue;
    afterEach(parDataQ, @nUpdateWaitbar);
    p = 1;

    % Calculate EMD for "/" orient 2 state
    parfor i = 1:length(magIdxOrient2)
        idx = magIdxOrient2(i);
        magTarget = [magnet(idx).roiNorm(:),xPos,yPos];
        % Calculate EMD values for all reference images (subset of magRef)
        EMDValues = zeros(1,magRefOrient2Length);
        for j = 1:magRefOrient2Length
            EMDValues(j) = cvEMD(magRef(magRefOrient2(j)).imgEMD,magTarget,'DistType','L1');
        end
        % Load the EMD values in EMDMtxOrient2
        EMDMtxOrient2(i,:) = EMDValues;
        % Determine the minimum EMD value
        idxEMDMin = find(EMDValues == min(EMDValues));
        EMDMin = EMDValues(idxEMDMin);
        % Label the detected state based on the minimum EMD
        if length(idxEMDMin) ~= 1
            % If there is more than 1 minimum, flag the magnet as "unknown"
            detectStateOrient2{i} = 'unknown';
        else
            % Save the magnetic state
            detectStateOrient2{i} = magRef(idxEMDMin).name(1:end-2);
        end
        % Calculate relative confidence, defined as 1 minus the relative
        % difference between the smallest EMD value and 2nd smallest EMD value
        EMDValues(EMDValues == min(EMDValues)) = [];
        EMDMin2nd = min(EMDValues);
        confidenceOrient2(i) = 1-abs(EMDMin/EMDMin2nd);
        send(parDataQ,i);
    end
    % Populate values in the primary matrices/arrays
    for i = 1:length(magIdxOrient2)
        idx = magIdxOrient2(i);
        EMDMtx(idx,:) = EMDMtxOrient2(i,:);
        detectState{idx} = detectStateOrient2{i};
        confidence(idx) = confidenceOrient2(i);
        send(parDataQ,i);
    end

    
    % Calculate EMD for "\" orient 3 state
    parfor i = 1:length(magIdxOrient3)
        idx = magIdxOrient3(i);
        magTarget = [magnet(idx).roiNorm(:),xPos,yPos];
        % Calculate EMD values for all reference images (subset of magRef)
        EMDValues = zeros(1,magRefOrient3Length);
        for j = 1:magRefOrient3Length
            EMDValues(j) = cvEMD(magRef(magRefOrient3(j)).imgEMD,magTarget,'DistType','L1');
        end
        % Load the EMD values in EMDMtxOrient3
        EMDMtxOrient3(i,:) = EMDValues;
        % Determine the minimum EMD value
        idxEMDMin = find(EMDValues == min(EMDValues));
        EMDMin = EMDValues(idxEMDMin);
        % Label the detected state based on the minimum EMD
        if length(idxEMDMin) ~= 1
            % If there is more than 1 minimum, flag the magnet as "unknown"
            detectStateOrient3{i} = 'unknown';
        else
            % Save the magnetic state
            detectStateOrient3{i} = magRef(idxEMDMin).name(1:end-2);
        end
        % Calculate relative confidence, defined as 1 minus the relative
        % difference between the smallest EMD value and 2nd smallest EMD value
        EMDValues(EMDValues == min(EMDValues)) = [];
        EMDMin2nd = min(EMDValues);
        confidenceOrient3(i) = 1-abs(EMDMin/EMDMin2nd);
        send(parDataQ,i);
    end
    % Populate values in the primary matrices/arrays
    for i = 1:length(magIdxOrient3)
        idx = magIdxOrient3(i);
        EMDMtx(idx,:) = EMDMtxOrient3(i,:);
        detectState{idx} = detectStateOrient3{i};
        confidence(idx) = confidenceOrient3(i);
        send(parDataQ,i);
    end
    
    if ~isempty(app); close(statusEMD); end

    % Function for the waitbar
    function nUpdateWaitbar(~)
        statusEMD.Value = p/(magLength*2);
        p = p+1;
    end

end