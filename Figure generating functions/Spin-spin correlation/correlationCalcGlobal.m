function correlationCalcGlobal(app,savePath)
    % Determines the system-averaged spin-spin correlations
    % First approach: direct dot-product method
    % Private function correlationLoop
    % Performs the actual correlation function calculation
    switch app.vd.typeASI
        case {'Square','Kagome'}
            % Access structure nbr with indices 1-7
            nbrRange = 1:7;
        case 'Brickwork'
            % Access structure nbr with indices 1-7 and 8-11 (the "b" neighbors)
            nbrRange = 1:11;
    end
    
    % Create variable calcType which will tell the program what method to use for calculating the correlation coeff.
    calcType = strings;
    % Create variable calcFileName which will tell the program what the file names will be for the used calculation method
    calcFileName = strings;
    if app.correlation_SpinDot.Value == 1
        calcType(end+1) = "dot";
        calcFileName(end+1) = sprintf('%sCorrelation_dot.txt',savePath);
    end
    if app.correlation_DotBinary.Value == 1
        calcType(end+1) = "dot binary";
        calcFileName(end+1) = sprintf('%sCorrelation_dotBinary.txt',savePath);
    end
    if app.correlation_Magnetostatic.Value == 1
        calcType(end+1) = "magnetostatic";
        calcFileName(end+1) = sprintf('%sCorrelation_magnetostatic.txt',savePath);
    end
    
    % Remove null entries
    calcType(cellfun('isempty',calcType)) = [];
    calcFileName(cellfun('isempty',calcFileName)) = [];
    
    % Set the format used for saving the correlation coefficients
    formatSpec = 'Alpha - neighbor %s coefficient: %f\n'; 
    % Set the text used for each unique neighbor type
    nbrText = ["1","2","3","4","5","6","7","4b","5b","6b","7b"];
    % Save values
    for i = 1:length(calcType)
        % Initialize structure nbrCoeff which will store the spin correlation values
        nbrCoeff = struct('Value',{});
        for j = 1:length(nbrRange)
            nbrCoeff(j).Value = spinCorrelation(app,app.vd.pairNbr(j).Value,calcType(i),"global");
        end
        % Horizontaly concatenate neighbor coefficients into a single vector
        coeffList = horzcat(nbrCoeff.Value);
        % Write coefficients to text file
        fileID = fopen(calcFileName(i),'w');
        fprintf(fileID,formatSpec,[nbrText(nbrRange);string(coeffList)]);
        fclose(fileID);
    end
end