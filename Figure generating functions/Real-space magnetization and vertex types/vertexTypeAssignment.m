% Assigns the different vertex types
function vertexTypeAssignment(app,currIndVtx)
    % First, we need to determine if we have sufficient neighboring magnet data to classify the vertex
    % We start by storing the values of the neighboring magnet indices for the currIndVtx
    nbrMagnetList = app.vd.vertex(currIndVtx).nbrMagnetInd;

    % Then we initialize a variable to store the vertex charge
    vertexCharge = 0;

    % Then we need to determine if, for the selected ASI type, we have sufficnent number of known magnet magnetizations.
    % Otherwise we will return here.
    verifyKagome = strcmp(app.vd.typeASI,'Kagome') == 1 & length(nbrMagnetList) == 3;
    verifyBrickwork = strcmp(app.vd.typeASI,'Brickwork') == 1 & length(nbrMagnetList) == 3;
    verifySquare = strcmp(app.vd.typeASI,'Square') == 1 & length(nbrMagnetList) == 4;
    if verifyKagome ~= 1 && verifyBrickwork ~=1 && verifySquare ~= 1
        app.vd.vertex(currIndVtx).type = NaN; % Add vertex charge of some absurd amount here
    end

    % At this point we should have sufficient amount of magnet data to classify the vertex charge state (topological)
    % This requires that none of the magnets possess an orientation normal to the horizontal x-axis
    % Otherwise you will need to introduce additional controls specific to those vertex types

    % Prevent an inaccessible index error by removing any values of nbrMagnetList that exceeds app.vd.magnet length
    nbrMagnetList(nbrMagnetList > length(vertcat(app.vd.magnet.rowYPos))) = [];

    for magInd = 1:length(nbrMagnetList)
        % Access the corresponding magnets and determine their relative lateral position
        accessMagIndex = nbrMagnetList(magInd);

        % Check if any magnet surrounding the vertex possesses a zero projection. 
        % If so, immediately break out of the loop and assign a vertex charge and type equal to NaN
        if app.vd.magnet(accessMagIndex).projection == 0
            vertexCharge = NaN;
            break;
        end

        % If the magnet is to the left of the vertex
        if app.vd.magnet(accessMagIndex).colXPos < app.vd.vertex(currIndVtx).colXPos 
            vertexCharge = vertexCharge + app.vd.magnet(accessMagIndex).projection;

        % If the magnet is to the right of the vertex
        elseif app.vd.magnet(accessMagIndex).colXPos > app.vd.vertex(currIndVtx).colXPos
            vertexCharge = vertexCharge - app.vd.magnet(accessMagIndex).projection;

        end
    end

    % Save the vertex charge state
    app.vd.vertex(currIndVtx).charge = vertexCharge;

    % We can go further by classifying the vertices in terms of the degenerate vertex types (geometrical)

    % First initialize vertexType (in case it is zero)
    vertexType = 0;
    switch app.vd.typeASI
        case {'Square','Tetris'}
            % A vertex with a +-4 charge state is a Type IV
            if abs(vertexCharge) == 4
                vertexType = 4;

            % A vertex with a +-2 charge is a Type III
            elseif abs(vertexCharge) == 2
                vertexType = 3;

            % A vertex with no net charge can either be Type I or II
            elseif vertexCharge == 0
                % For Type I vertices, magnets on opposing sides of a vertex have antiparallel magnetizations
                % For Type II vertices, magnets on opposing sides of a vertex have parallel magnetizations
                % We need to first identify what quadrant the magnets lie in with respect to the vertex as the origin
                localMagX = vertcat(app.vd.magnet(nbrMagnetList).colXPos) - app.vd.vertex(currIndVtx).colXPos;
                localMagY = vertcat(app.vd.magnet(nbrMagnetList).rowYPos) - app.vd.vertex(currIndVtx).rowYPos;
                indQuad1 = nbrMagnetList(localMagX > 0 & localMagY > 0);
                indQuad3 = nbrMagnetList(localMagX < 0 & localMagY < 0);

                % Only proceed if both projQuad1 and projQuad3 are defined and not null (not looking at the edge)
                if isempty(indQuad1) == 0 && isempty(indQuad3) == 0
                    % Extract quadrant projections
                    projQuad1 = app.vd.magnet(indQuad1).projection;
                    projQuad3 = app.vd.magnet(indQuad3).projection;

                    % If the magnetizations of the corner-shared quadrant (e.g., 1-3 or 2-4) possess antiparallel magnetizations
                    % then they are Type I. Otherwise they are Type II
                    if projQuad1 == -projQuad3 % Type I
                        vertexType = 1;
                    elseif projQuad1 == projQuad3
                        vertexType = 2;
                    end
                end
            end

        case 'Kagome'
            % For the Kagome system, the vertex type is just the absolute value of the charge state
            vertexType = abs(vertexCharge);

        case 'Brickwork'
            % A vertex with a +- 3 charge state is a Type III
            if abs(vertexCharge) == 3
                vertexType = 3;

            % A vertex with a +- 1 charge state is either a Type I or Type II
            elseif abs(vertexCharge) == 1
                % For Type I vertices, collinear magnet sets must have antiparallel magnetizations
                % For Type II vertices, collinear magnet sets must have parallel magnetizations
                % We need to first identify what quadrant the magnets lie in with respect to the vertex as the origin
                localMagX = vertcat(app.vd.magnet(nbrMagnetList).colXPos) - app.vd.vertex(currIndVtx).colXPos;
                localMagY = vertcat(app.vd.magnet(nbrMagnetList).rowYPos) - app.vd.vertex(currIndVtx).rowYPos;
                indQuad1 = nbrMagnetList(localMagX > 0 & localMagY > 0);
                indQuad2 = nbrMagnetList(localMagX > 0 & localMagY < 0);
                indQuad3 = nbrMagnetList(localMagX < 0 & localMagY < 0);
                indQuad4 = nbrMagnetList(localMagX < 0 & localMagY > 0);

                % For the brickwork system, one quadrant will be missing. Therefore we only need to look at either quadrants
                % 1-3 or 2-4.
                is13There = isempty(indQuad1) ~= 1 & isempty(indQuad3) ~= 1;
                is24There = isempty(indQuad2) ~= 1 & isempty(indQuad4) ~= 1;

                % If 1-3 are there, then analyze that pair. If not, analyze pair 2-4
                if is13There == 1
                    if app.vd.magnet(indQuad1).projection == -app.vd.magnet(indQuad3).projection % Type I
                        vertexType = 1;
                    elseif app.vd.magnet(indQuad1).projection == app.vd.magnet(indQuad3).projection % Type II
                        vertexType = 2;
                    end
                elseif is24There == 1
                    if app.vd.magnet(indQuad2).projection == -app.vd.magnet(indQuad4).projection % Type I
                        vertexType = 1;
                    elseif app.vd.magnet(indQuad2).projection == app.vd.magnet(indQuad4).projection % Type II
                        vertexType = 2;
                    end
                else
                    vertexType = 0;
                end
            end
    end
    % Save the vertex type 
    app.vd.vertex(currIndVtx).type = vertexType;
end