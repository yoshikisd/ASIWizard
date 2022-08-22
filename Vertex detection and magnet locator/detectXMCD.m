% Detection for XMCD-PEEM images
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