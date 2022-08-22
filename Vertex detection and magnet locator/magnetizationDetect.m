% magnetizationDetect - Detects the magnetization of each nanoisland, depending on the
%                       processed magnetic contrast image used.
%
% magnetizationDetect(app)
%       app = host application (IceScanner)
function magnetizationDetect(app)
    %% Extract magnetization for all nanoislands from magnetic contrast image
    
    % Define a rectangular bounding box on which to perform the grayscale scan
    magnetLength = app.magnetHeight.Value;
    magnetWidth = app.magnetWidth.Value;
    
    % This comes into play when we're extracting the ROIs which read the magnetizations
    f = uiprogressdlg(app.IceScannerUI,'Title','Detecting and mapping magnetizations');
    % Magnetization interpretation will depend on the contrast mechanism (XMCD or MFM)
    switch app.contrastMode.Value
        case 'XMCD-PEEM'
            %spmd
                % Process all magnets
                for magInd = 1:length(app.vd.magnet)
                    f.Value = magInd/length(app.vd.magnet);
                    % Extract magnet positions and ray angle from adjacent vertices
                    [yMidpoint,xMidpoint,angle] = extractMagPosition(app,magInd);
                    % Detect the magnetization through the XMCD signal (autoupdates app.vd)
                    detectXMCD(app,magInd,magnetLength,magnetWidth,xMidpoint,yMidpoint,angle);
                    % Assign mapped Ising magnetization (autoupdates app.vd)
                    magnetizationAssignment(app,magInd,angle);
                    % Change ignore flag to zero
                    app.vd.magnet(magInd).ignoreFlag = false;
                end
                % Call the EMD-detecting function
                if magnetLength > magnetWidth
                    numCols = magnetLength;
                    numRows = magnetWidth;
                else
                    numCols = magnetWidth;
                    numRows = magnetLength;
                end

                [EMDMtx,detectState,confidence] = ...
                    magDetectEMD('/home/yoshikisd/ASIWizard/ASIWizard/Reference images',app.vd.magnet,numRows,numCols,app);

                % Save madDetectEMD information to magnet
                for i = 1:length(app.vd.magnet)
                    app.vd.magnet(i).EMDMtx = EMDMtx(i,:);
                    app.vd.magnet(i).detectState = detectState(i);
                    app.vd.magnet(i).confidence = confidence(i);
                end
                1 + 1;
            %end
        case 'MFM'
            % Process all magnets
            for magInd = 1:length(app.vd.magnet)
                f.Value = magInd/length(app.vd.magnet);
                % Extract magnet positions and ray angle from adjacent vertices
                [yMidpoint,xMidpoint,angle] = extractMagPosition(app,magInd);
                % Detect the magnetization through the MFM signal (autoupdates app.vd)
                detectMFM(app,magInd,magnetLength,magnetWidth,xMidpoint,yMidpoint,angle)
                % Assign mapped Ising magnetization (autoupdates app.vd)
                magnetizationAssignment(app,magInd,angle);
                % Change ignore flag to zero
                app.vd.magnet(magInd).ignoreFlag = false;
            end
    end
    close(f);
    
    % Look through all the magnet values and change empty projections into zero projections
    for i = 1:length(app.vd.magnet)
        if isempty(app.vd.magnet(i).projection)
            app.vd.magnet(i).projection = 0;
        end
    end
    
    % Output ROI matrices
    app.vd.xmcdTrinarySkeleton = app.vd.xmcdCorrectedTrinary;
    app.vd.xmcdTrinarySkeleton(app.vd.magnetMask == 0) = 0;
    app.vd.xmcdBoostSkeleton = app.vd.xmcdBoost;
    app.vd.xmcdBoostSkeleton(app.vd.magnetMask == 0) = 1/2;
    app.vd.xmcdOriginalSkeleton = mat2gray(app.vd.xmcd,...
        [-double(max(app.vd.xmcd,[],'all')/2),double(max(app.vd.xmcd,[],'all')/2)]);
    app.vd.xmcdOriginalSkeleton(app.vd.magnetMask == 0) = 1/2;
    app.vd.magnetInterpretCombinedImg = ...
        mat2gray(app.vd.magnetInterpretCombined,[-double(max(app.vd.magnetInterpretCombined,[],'all')/2),...
        double(max(app.vd.magnetInterpretCombined,[],'all')/2)]);

    %% Pulling information about magnet position and the ray casted from the adjacent vertices
    %{
    function [yMidpoint,xMidpoint,angle] = extractMagPosition(app,magInd)
        % Pull information about magnet center location
        yMidpoint = app.vd.magnet(magInd).rowYPos;
        xMidpoint = app.vd.magnet(magInd).colXPos;
        
        % Using the neighboring vertex positions, determine what quadrant the ray 
        % casted from currIndVtx-TO-nbrIndVtx vector lies in. This comes into play
        % when we're figuring out how the magnetizations are oriented
        currIndVtx = app.vd.magnet(magInd).nbrVertexInd(1);
        nbrIndVtx = app.vd.magnet(magInd).nbrVertexInd(2);
        
        nbrXPos = app.vd.vertex(nbrIndVtx).colXPos;    % Formerly neighborInfo(j,1)
        nbrYPos = app.vd.vertex(nbrIndVtx).rowYPos;    % Formerly neighborInfo(j,2)

        % X and Y position of current vertex currIndVtx
        currXPos = app.vd.vertex(currIndVtx).colXPos;  % Formerly trueMinLoc(i,1);
        currYPos = app.vd.vertex(currIndVtx).rowYPos;  % Formerly trueMinLoc(i,2);

        dx = nbrXPos - currXPos;
        dy = nbrYPos - currYPos;
        angle = atan2d(dy,dx);
    end
    %}

    %% Detection for XMCD-PEEM images
    %{
    function detectXMCD(app,magInd,magnetLength,magnetWidth,xMidpoint,yMidpoint,angle)
        % Create perimeter for performing ROI scan of the magnetic contrast
        magnetPerX = magnetLength/2 * [-1:0.02:1,ones(1,length(-1:0.02:1)),1:-0.02:-1,-ones(1,length(-1:0.02:1))];
        magnetPerY = magnetWidth/2 * [ones(1,length(-1:0.02:1)),1:-0.02:-1,-ones(1,length(-1:0.02:1)),-1:0.02:1];

        % Initialize scan area for reading magnetization
        magnetAreaScanX = cosd(angle)*magnetPerX - sind(angle)*magnetPerY + xMidpoint;
        magnetAreaScanY = sind(angle)*magnetPerX + cosd(angle)*magnetPerY + yMidpoint;
        magnetLocalArea = [magnetAreaScanX',magnetAreaScanY'];
        % Remove any portions of the ROI scan that would exceed the edge
        magnetLocalArea(magnetLocalArea(:,1) < 1 | magnetLocalArea(:,1) > app.vd.gridWidth) = NaN;
        magnetLocalArea(magnetLocalArea(:,2) < 1 | magnetLocalArea(:,2) > app.vd.gridHeight) = NaN;
        magnetLocalArea(any(isnan(magnetLocalArea),2) == 1,:) = []; 
        roiScan = poly2mask(magnetLocalArea(:,1),magnetLocalArea(:,2),app.vd.gridHeight,app.vd.gridWidth);
        
        % To save an image of the ROI that has been rotated (edge lies flat with x- and y-axes),
        % create a duplicate ROI and image set that are globally rotates by "angle"

        % Create rotated images of both corrected and raw XMCD images
        rotContrast = imrotate(app.vd.xmcdCorrectedTrinary,angle,'bilinear');
        rotContrastRaw = imrotate(app.vd.xmcd,angle,'bilinear');
        [rotHeight,rotWidth] = size(rotContrast);
        % Rotate the positions of xMidpoint and yMidpoint relative to the center of the image
        % First, change the coordinate system so that the midpoints are relative to the origin of the original image
        xMidOffset = xMidpoint - round(app.vd.gridWidth/2);
        yMidOffset = round(app.vd.gridHeight/2) - yMidpoint; % Remember that row/column/x/y notations have a weird inversion to them
        % Next, rotate the coordinate by "angle"
        xMidRot = xMidOffset*cosd(angle) - yMidOffset*sind(angle);
        yMidRot = xMidOffset*sind(angle) + yMidOffset*cosd(angle);
        % Change the coordinate system to correspond with that of the rotated image
        % Bear in mind that the center of the image will not necessairly correspond with the
        % center of the imrotate frame; you have to back calculate the true center position
        xMidRot = xMidRot + round(rotWidth/2);
        yMidRot = round(rotHeight/2) - yMidRot;
        % Create new rotated ROI
        magnetLocalAreaRot = [(magnetPerX + xMidRot)',(magnetPerY + yMidRot)'];
        roiRot = poly2mask(magnetLocalAreaRot(:,1),magnetLocalAreaRot(:,2),rotHeight,rotWidth);
        % Save image of the ROI
        roiXMCD = roiRot.*rotContrast;
        roiXMCDRaw = roiRot.*rotContrastRaw;
        % Crop the frame
        [nzRow, nzCol] = find(roiRot);
        roiXMCD = roiXMCD(min(nzRow(:)):max(nzRow(:)), min(nzCol(:)):max(nzCol(:)));
        roiXMCDRaw = roiXMCDRaw(min(nzRow(:)):max(nzRow(:)), min(nzCol(:)):max(nzCol(:)));
        % For trinarized image, correct for rotation interpolation
        roiXMCD(roiXMCD < -0.1) = -1; roiXMCD(roiXMCD > 0.1) = 1; roiXMCD(abs(roiXMCD) ~= 1) = 0;
        % Save to magnet structure
        app.vd.magnet(magInd).roi = roiXMCD;
        app.vd.magnet(magInd).roiRaw = roiXMCDRaw;
        % Save volume-normalized version for EMD calculation
        roiXMCD = roiXMCD + abs(min(roiXMCD,[],'all')) + 1; % Ensures that there are no zero elements
        app.vd.magnet(magInd).roiNorm = roiXMCD / sum(roiXMCD,'all');
        roiXMCDRaw = roiXMCDRaw + abs(min(roiXMCDRaw,[],'all')) + 1; % Ensures that there are no zero elements
        app.vd.magnet(magInd).roiNormRaw = roiXMCDRaw / sum(roiXMCDRaw,'all');

        % Find out the matrix indices corresponding with the nearest neighboring vertices, but exclude background
        scanRegion = app.vd.xmcdCorrectedTrinary(roiScan == 1);

        % Determine the average XMCD contrast value of all the pixels in the ROI
        app.vd.magnet(magInd).xmcdAvg = mean(scanRegion,'all');

        % Determine and save XMCD contrast values
        % First, determine the weights associated with black/white pixel population
        whiteMean = sum(scanRegion(scanRegion > 0))/numel(scanRegion);
        blackMean = sum(scanRegion(scanRegion < 0))/numel(scanRegion);
        grayMean = sum(scanRegion(scanRegion == 0))/numel(scanRegion);
        whitePop = sum(scanRegion > 0);
        blackPop = sum(scanRegion < 0);
        grayPop = sum(scanRegion == 0);

        % Combined average
        app.vd.magnet(magInd).xmcdWeighted = (whiteMean*whitePop + blackMean*blackPop + grayMean*grayPop)/(whitePop + blackPop + grayPop);

        % Binary average
        app.vd.magnet(magInd).xmcdTrinary = mean(app.vd.xmcdCorrectedTrinary(roiScan == 1),'all');


        % Determine the standard deviation of the trinary XMCD image, to be used in providing Ising detection
        % confidence level
        app.vd.magnet(magInd).xmcdSTD = std(app.vd.xmcdCorrectedTrinary(roiScan == 1),0,'all','omitnan');

        % List all unique trinary intensities identified in ROI scan
        app.vd.magnet(magInd).uniqueTrinaryInt = unique(app.vd.xmcdCorrectedTrinary(roiScan == 1));
        app.vd.magnet(magInd).uniqueTrinaryInt_num = length(app.vd.magnet(magInd).uniqueTrinaryInt);
        app.vd.magnet(magInd).uniqueTrinaryInt_absSum = sum(abs(app.vd.magnet(magInd).uniqueTrinaryInt));

        % Adjust magnetMask, magnetInterpretReg, and magnetInterpretCombined
        app.vd.magnetMask(roiScan == 1) = 1;
        app.vd.magnetInterpretReg(roiScan == 1) = app.vd.magnet(magInd).xmcdAvg;
        app.vd.magnetInterpretCombined(roiScan == 1) = app.vd.magnet(magInd).xmcdWeighted;
        %app.vd.magnetEntropy(roiScan == 1) = app.vd.magnet(magInd).xmcdEntropy;
    end
    %}
    
    %% Detection for MFM images
    function detectMFM(app,magInd,magnetLength,magnetWidth,xMidpoint,yMidpoint,angle)
        % MFM interpretation mode is based on XMCD-reading mode. The way this will work is that the value of the left-end of
        % the nanoisland (either positive or negative) will cause the nanoisland magnetization to be read as if it was
        % a "white" or "black" island in an XMCD-PEEM image.

        % The primary caveat to this is that if the program detects that the nanoisland ends are both positive/negative, then it will
        % ignore the nanoisland from further analysis (assuming the island moment flipped)

        % We're assuming here that the nanoislands are tilted. This will not work for perfectly vertical nanoislands
        % Create two circles that sit at the ends of the nanoislands
        % First, identify where the centers of these circles reside at. For now we will set the positions to reside a distance of half 
        % the nanoisland width away from the ends 
        xOffset = cosd(angle)*(magnetLength-magnetWidth)/2;
        yOffset = sind(angle)*(magnetLength-magnetWidth)/2;

        % Define the left and right magnet end locations
        if xOffset < 0
            leftEnd_XPos = xMidpoint + xOffset;
            leftEnd_YPos = yMidpoint + yOffset;
            rightEnd_XPos = xMidpoint - xOffset;
            rightEnd_YPos = yMidpoint - yOffset;
        elseif xOffset > 0
            leftEnd_XPos = xMidpoint - xOffset;
            leftEnd_YPos = yMidpoint - yOffset;
            rightEnd_XPos = xMidpoint + xOffset;
            rightEnd_YPos = yMidpoint + yOffset;
        end

        % Create circle ROIs that will be used to read the MFM magnetizations
        MFMPerX = magnetWidth/2 * cosd(0:15:360);
        MFMPerY = magnetWidth/2 * sind(0:15:360);

        leftMFM = [MFMPerX' + leftEnd_XPos,MFMPerY' + leftEnd_YPos];
        rightMFM = [MFMPerX' + rightEnd_XPos,MFMPerY' + rightEnd_YPos];

        % Remove any portions of the left MFM ROI scan that would exceed the edge
        leftMFM(leftMFM(:,1) < 1 | leftMFM(:,1) > app.vd.gridWidth) = NaN;
        leftMFM(leftMFM(:,2) < 1 | leftMFM(:,2) > app.vd.gridHeight) = NaN;
        leftMFM(any(isnan(leftMFM),2) == 1,:) = [];
        leftMFMScan = poly2mask(leftMFM(:,1),leftMFM(:,2),app.vd.gridHeight,app.vd.gridWidth);

        rightMFM(rightMFM(:,1) < 1 | rightMFM(:,1) > app.vd.gridWidth) = NaN;
        rightMFM(rightMFM(:,2) < 1 | rightMFM(:,2) > app.vd.gridHeight) = NaN;
        rightMFM(any(isnan(rightMFM),2) == 1,:) = [];
        rightMFMScan = poly2mask(rightMFM(:,1),rightMFM(:,2),app.vd.gridHeight,app.vd.gridWidth);

        % Read the magnetizations in the regions and save the ROIs in an image form
        leftScanRegion = app.vd.xmcdCorrectedTrinary(leftMFMScan);
        rightScanRegion = app.vd.xmcdCorrectedTrinary(rightMFMScan);

        % Average the intensity within the scanned ROIs
        leftMean = sum(leftScanRegion,'all')/numel(leftScanRegion);
        rightMean = sum(rightScanRegion,'all')/numel(rightScanRegion);

        % Read the left MFM poles as the black/white XMCD contrast, depending on the MFM tip magnetization
        % First, check if both ends are the same "color" or not. Easiest way to do this is to multiply the left
        % and right mean: if both ends are different "colors" (i.e. positive and negative), then their product
        % will always be negative
        if leftMean * rightMean < 0 % Both ends are different colors
            % If the tip is "North", then white contrast (repulsive) is "North" and black contrast (attractive) is "South"
            % If the tip is "South", then the above statement is reversed (North is black and South is white)
            % Following the existing XMCD convention for this program, "White is right, Black is left"

            % Create a variable tipFactor to flip the convention of leftMean, depending on the tip magnetization
            tipFactor = 1;
            switch app.tipPole.Value
                case 'N'
                    tipFactor = 1;
                case 'S'
                    tipFactor = -1;
            end

            if leftMean*tipFactor > 0 
                % If the left end is white (+1) and the tip is North (+1), then the nanoisland will point to the left (north pole)
                % Or, if the left is black (-1) and the tip is South (-1), then the nanoisland will point to the left (north pole)
                app.vd.magnet(magInd).xmcdAvg = -1;

            elseif leftMean*tipFactor < 0
                % If the left end is white (+1) and the tip is South (-1), then the nanoisland will point to the right (south pole)
                % Or, if the left is black (-1) and the tip is North (+1), then the nanoisland will point to the right (south pole)
                app.vd.magnet(magInd).xmcdAvg = 1;
            end

        else % Both ends are same color; probably switched. Treat as a unidentifiable magnet (gray)
            app.vd.magnet(magInd).xmcdAvg = 0;
        end

        app.vd.magnet(magInd).xmcdWeighted = app.vd.magnet(magInd).xmcdAvg;
        app.vd.magnet(magInd).xmcdTrinary = app.vd.magnet(magInd).xmcdAvg;

        % Due to the way the magnetization is being re-mapped here, xmcdSTD and xmcdEntropy are not really relevant
        app.vd.magnet(magInd).xmcdSTD = 0;
        app.vd.magnet(magInd).xmcdEntropy = 0;

        % Adjust magnetMask, magnetInterpretReg, and magnetInterpretCombined
        app.vd.magnetMask(leftMFMScan | rightMFMScan) = 1;
        app.vd.magnetInterpretReg(leftMFMScan) = app.vd.magnet(magInd).xmcdAvg;
        app.vd.magnetInterpretReg(rightMFMScan) = -app.vd.magnet(magInd).xmcdAvg;
        app.vd.magnetInterpretCombined(leftMFMScan) = leftMean;
        app.vd.magnetInterpretCombined(rightMFMScan) = rightMean;
        app.vd.magnetEntropy(leftMFMScan | rightMFMScan) = 0;
    end

    %% Assignment of Ising magnetization vectors
    %{
    function magnetizationAssignment(app,magInd,angle)
        % Assign the lateral orientation (black is -1/left, white is +1/right)
        magnetizationIntensity = app.vd.magnet(magInd).xmcdTrinary;
        %app.vd.magnet(magInd).xmcdWeighted;
        if magnetizationIntensity > 0      % Right (White)
            app.vd.magnet(magInd).projection = 1;
            % Define how the magnetization is oriented on the unit circle
            % If the vector associated with the variable angle is oriented towards the second or third quadrant
            % (angle = [90 270]), then flip it.
            if angle >= 90 && angle <= 270
                if angle >= 180
                    app.vd.magnet(magInd).spinAngle = angle-180;
                elseif angle < 180
                    app.vd.magnet(magInd).spinAngle = angle+180;
                end
            else
                app.vd.magnet(magInd).spinAngle = angle;
            end

            % Determine the X and Y offsets when plotting the Ising macrospins
            app.vd.magnet(magInd).spinPlotXOffset = app.vd.magnet(magInd).colXPos - 7*cosd(angle);
            app.vd.magnet(magInd).spinPlotYOffset = app.vd.magnet(magInd).rowYPos - 7*sind(angle);

        elseif magnetizationIntensity < -0     % Left (Black)
            app.vd.magnet(magInd).projection = -1;

            % Define how the magnetization is oriented on the unit circle
            % If the vector associated with the variable angle is oriented towards the second or third quadrant
            % (angle = [90 270]), then keep it. Otherwise flip it.
            if angle >= 90 && angle <= 270
                app.vd.magnet(magInd).spinAngle = angle;
            else
                if angle >= 180
                    app.vd.magnet(magInd).spinAngle = angle-180;
                elseif angle < 180
                    app.vd.magnet(magInd).spinAngle = angle+180;
                end
            end

            % Determine the X and Y offsets when plotting the Ising macrospins
            app.vd.magnet(magInd).spinPlotXOffset = app.vd.magnet(magInd).colXPos + 7*cosd(angle);
            app.vd.magnet(magInd).spinPlotYOffset = app.vd.magnet(magInd).rowYPos + 7*sind(angle);
        end
    end
    %}
end