% Decides the appropriate assignment method of magnets between vertices based on vertex positions and reference image info
function magnetScanFilter(app,currIndVtx)
    detectedNeighbor = app.vd.vertex(currIndVtx).nbrVertexInd;
    % From the nearest neighboring vertex positions, extrapolate the magnet positions by taking the ray bisector
    currentX = app.vd.vertex(currIndVtx).colXPos;
    currentY = app.vd.vertex(currIndVtx).rowYPos;

    for j = 1:length(detectedNeighbor)
        nbrIndVtx = detectedNeighbor(j);
        switch app.vd.typeASI
            case 'Brickwork' % For brickwork we need to differentiate between the two types of detected vertices
                % Find the X and Y position associated with the observed detected neighbor
                neighborX = app.vd.vertex(nbrIndVtx).colXPos;
                neighborY = app.vd.vertex(nbrIndVtx).rowYPos;
                
                % Legacy mode definitions of reference 1 and 2
                % ------------ THIS IS VERY IMPORTANT, HEED THIS MESSAGE DANYE!!! ---------------------
                % ------------ IF YOU USED THE OLD VERSION OF VERTEXEMDDETECT, USE THE ORDER 2 AND 1
                % ------------ IF YOU USED THE NEW VERSION, USE THE ORDER 1 AND 2
                switch app.oldVersion.Value
                    case 'Yes'
                        k1 = 2; k2 = 1;
                    case 'No'
                        k1 = 1; k2 = 2;
                    otherwise
                        uialert(app.iceScannerUI,'Please indicate the the version of vertex detection used.','Error');
                        return;
                end

                % Second, determine whether the observed vertex was detected by reference image 1 or 2
                % First, figure out if the bricks are oriented "\" or "/"
                switch app.vd.brickMode
                    case '\'
                        % Magnets oriented like a backwards "y". The magnet will ONLY EXIST if the neighboring vertex DOES NOT have
                        % a y-position greater than AND a x-position less than the observed vertex
                        % OR
                        % Magnets oriented like "lambda". The magnet will ONLY EXIST if the neighboring vertex DOES NOT have a
                        % y-position less than AND a x-position greater than the observed vertex
                        if (app.vd.vertex(currIndVtx).refImg == k1 && ~((neighborX < currentX) && (neighborY > currentY))) ||...
                           (app.vd.vertex(currIndVtx).refImg == k2 && ~((neighborX > currentX) && (neighborY < currentY)))
                            % Run the magnetLocator
                            magnetLocator(app,currIndVtx,nbrIndVtx);
                        end
                    case '/'
                        % Magnets oriented like a "y". The magnet will ONLY EXIST if the neighboring vertex DOES NOT have
                        % a y-position greater than AND a x-position greater than than the observed vertex
                        % OR
                        % Magnets oriented like a backwards "lambda". The magnet will ONLY EXIST if the neighboring vertex DOES NOT have a
                        % y-position less than AND a x-position less than than the observed vertex
                        if (app.vd.vertex(currIndVtx).refImg == k1 && ~((neighborX > currentX) && (neighborY > currentY))) ||...
                           (app.vd.vertex(currIndVtx).refImg == k2 && ~((neighborX < currentX) && (neighborY < currentY)))
                            % Run the magnetLocator
                            magnetLocator(app,currIndVtx,nbrIndVtx);
                        end
                end

            case {'Square','Kagome','Tetris'}
                % Just run the magnetLocator
                magnetLocator(app,currIndVtx,nbrIndVtx);
        end

        % Make sure no duplicate entries exist in the neighbor magnet index
        app.vd.vertex(currIndVtx).nbrMagnetInd = unique(app.vd.vertex(currIndVtx).nbrMagnetInd);
    end
end