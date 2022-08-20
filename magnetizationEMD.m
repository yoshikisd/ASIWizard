% Detects magnetization
filePath = '/home/yoshikisd/ASIWizard/ASIWizard/Reference images';
numRows = 8;
numCols = 22;
% Create matrix with values of x- and y-positions
xPosMtx = zeros(numRows,numCols);
yPosMtx = xPosMtx;
for i = 1:numCols; xPosMtx(:,i) = i; end
for i = 1:numRows; yPosMtx(i,:) = i; end
% Convert the xPosMtx and yPosMtx into vectors
xPos = xPosMtx(:);
yPos = yPosMtx(:);

% Load reference magnetization states in structure magRef
magRef = struct('name',[],'imgRescale',[],'imgOriginal',[],'imgEMD',[]);
magRef(1).name = 'Ising_Black';
magRef(2).name = 'Ising_White';
magRef(3).name = 'OBIW_1';
magRef(4).name = 'OBIW_2';
magRef(5).name = 'OWIB_1';
magRef(6).name = 'OWIB_2';
magRef(7).name = 'TBBW_1';
magRef(8).name = 'TBBW_2';
magRef(9).name = 'TWBB_1';
magRef(10).name = 'TWBB_2';
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

% EMD Test on P.magnet(32).roiNorm
f = waitbar(0,'hang on');
parfor idx = 1:length(P.magnet)
    magTarget = [P.magnet(idx).roiNorm(:),xPos,yPos];
    % Calculate EMD values for all reference images
    confidence = zeros(length(magRef),1);

    for i = 1:length(magRef)
        confidence(i) = cvEMD(magRef(i).imgEMD,magTarget,'DistType','L1');
    end
    
    % Extract the likely candidate
    
    % Update waitbar
    %waitbar(idx/length(P.magnet),f,'wait fucker');
end