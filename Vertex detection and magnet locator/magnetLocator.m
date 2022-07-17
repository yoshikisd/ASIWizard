% This searches for magnets and stores information regarding their approximate locations in terms of a rectangular ROI
function magnetLocator(app,currIndVtx,nbrIndVtx)
    % In order to run this thing, we need to look at variables associated with the currently observed vertex index "currIndVtx"
    % and the neighboring vertex index "nbrIndVtx" within the structure app.vd.vertex.
    
    % X and Y position of vertex nbrIndVtx
    nbrXPos = app.vd.vertex(nbrIndVtx).colXPos;    % Formerly neighborInfo(j,1)
    nbrYPos = app.vd.vertex(nbrIndVtx).rowYPos;    % Formerly neighborInfo(j,2)

    % X and Y position of current vertex currIndVtx
    currXPos = app.vd.vertex(currIndVtx).colXPos;  % Formerly trueMinLoc(i,1);
    currYPos = app.vd.vertex(currIndVtx).rowYPos;  % Formerly trueMinLoc(i,2);

    % Calculate the midpoints between these two positions to determine the approximate magnet location
    xMidpoint = floor((nbrXPos+currXPos)/2);
    yMidpoint = floor((nbrYPos+currYPos)/2);

    % First thing: Figure out if a magnet with this position has already been discovered
    [~,fieldSize] = size(app.vd.magnet);


    if isempty(app.vd.magnet(1).rowYPos) == 1       % For the first magnet entry, record the information at index 1 
        magInd = 1;
    else
        % Create vectors to store variables associated with the x and y positions of all saved magnet indices
        storedXMidpoint = vertcat(app.vd.magnet.colXPos);
        storedYMidpoint = vertcat(app.vd.magnet.rowYPos);

        % Search all elements within app.vd.magnet to see if there are already exists a magnet with the calculated positions
        existingMagInd = find(storedXMidpoint == xMidpoint & storedYMidpoint == yMidpoint); 

        % Apply switch statement for cases where an existing magnet has been found or not
        magnetExists = ~isempty(existingMagInd);

        switch magnetExists
            case 1 % Magnet already exists. Archive position
                app.vd.vertex(currIndVtx).nbrMagnetInd(end+1) = existingMagInd;
                return;
            case 0 % Magnet does not exist. Create new entry at fieldSize+1 (new entry at end)
                magInd = fieldSize + 1;
        end
    end

    app.vd.magnet(magInd).rowYPos = yMidpoint;
    app.vd.magnet(magInd).colXPos = xMidpoint;
    app.vd.magnet(magInd).nbrVertexInd(1) = currIndVtx;
    app.vd.magnet(magInd).nbrVertexInd(2) = nbrIndVtx;
    % We make an assumption that the domain state is Ising-like. This can be corrected manually in later steps
    app.vd.magnet(magInd).domainState = "Ising";
    
    % Store the magnet index
    app.vd.vertex(currIndVtx).nbrMagnetInd(end+1) = magInd;
end