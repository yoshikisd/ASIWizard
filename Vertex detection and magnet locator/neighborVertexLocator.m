% Searches for neighboring vertices and stores information regarding their locations
function neighborVertexLocator(app,currIndVtx,cross1Angle,cross1PerimeterX,cross1PerimeterY,cross2Angle,...
        cross2PerimeterX,cross2PerimeterY,trueMinXPos,trueMinYPos,thetaRange,diameter)
    % First save the current vertex position

    % Second find the nearest neighboring neighbors
    switch app.vd.typeASI
        case {'Square','Brickwork','Tetris'}
            % Define the perimeter which will bound the area scan
            cross1AreaScanX = cosd(-cross1Angle)*cross1PerimeterX - sind(-cross1Angle)*cross1PerimeterY + trueMinXPos(currIndVtx);
            cross1AreaScanY = sind(-cross1Angle)*cross1PerimeterX + cosd(-cross1Angle)*cross1PerimeterY + trueMinYPos(currIndVtx);
            cross2AreaScanX = cosd(-cross2Angle)*cross2PerimeterX - sind(-cross2Angle)*cross2PerimeterY + trueMinXPos(currIndVtx);
            cross2AreaScanY = sind(-cross2Angle)*cross2PerimeterX + cosd(-cross2Angle)*cross2PerimeterY + trueMinYPos(currIndVtx);

            detectedNeighbor = find((inpolygon(trueMinXPos,trueMinYPos,cross1AreaScanX,cross1AreaScanY) == 1) | ...
                (inpolygon(trueMinXPos,trueMinYPos,cross2AreaScanX,cross2AreaScanY) == 1)); 

        case 'Kagome'
            areaScanX = diameter*cos(thetaRange) + trueMinXPos(currIndVtx);
            areaScanY = diameter*sin(thetaRange) + trueMinYPos(currIndVtx);

            % Find out the indices corresponding with the nearest neighboring vertices
            detectedNeighbor = find(inpolygon(trueMinXPos,trueMinYPos,areaScanX,areaScanY) == 1); 
    end

    % Store the indices of the neighbors
    % Make sure that the current detectedNeighbor variable contain whatever is currently stored in nbrVertexInd
    % Bone-head approach: append app.vd.vertex(currIndVtx).nbrVertexInd to detectedNeighbor
    detectedNeighbor = unique([detectedNeighbor(:)', app.vd.vertex(currIndVtx).nbrVertexInd(:)']);
    detectedNeighbor(detectedNeighbor == currIndVtx) = [];   % Prevents detectedNeighbor from double counting the vertex of interest
    app.vd.vertex(currIndVtx).nbrVertexInd = detectedNeighbor;
end