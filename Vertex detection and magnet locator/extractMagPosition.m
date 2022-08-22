% Pulling information about magnet position and the ray casted from the adjacent vertices
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