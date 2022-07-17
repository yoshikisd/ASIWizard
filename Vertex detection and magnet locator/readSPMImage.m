function SPMImage = readSPMImage(SPMTable)
    % Converts processed and exported Park Systems XEI file (SPMtable) into a readable image (SPMImage)
    % The text file needs to be converted into a table using the readtable function beforehand
    
    % First, find the dimensions of the SPM scan (assuming square area)
    [numel,~] = size(SPMTable);
    edgeLength = sqrt(numel);
    
    % Initialize SPMImage
    SPMImage = zeros(edgeLength);
    
    % Write entries
    SPMImage = zeros(edgeLength);
    for y = 1:edgeLength
        SPMImage(edgeLength + 1 - y, 1:edgeLength) = SPMTable{(1:edgeLength)+edgeLength*(y-1),3};
    end
end

