function squareMapper(app,magNeigh,vertexMagStart,vertexMagEnd,magnet00)
    % Maps the experimental square/brick magnet position to square lattice coordinates
    % Begin the scan by looking towards the "right" (90degree T branch)
    for i = 1:length(magNeigh)
        % Look for the neighboring vertex in the observed magnet (magNeigh(i)) that is not the reference vertexMagEnd and
        % calculate the angle associated with the vector projected from vertexMagEnd to iceMagnets(magNeigh(i),X)
        if app.vd.magnet(magNeigh(i)).nbrVertexInd(1) ~= vertexMagEnd
            projectVertex = app.vd.magnet(magNeigh(i)).nbrVertexInd(1);
        else
            projectVertex = app.vd.magnet(magNeigh(i)).nbrVertexInd(2);
        end
        relativeAngle = angleCalc(app,vertexMagStart,vertexMagEnd,vertexMagEnd,projectVertex);
        if relativeAngle < -45 % CCW
            app.vd.magnet(magNeigh(i)).aInd = app.vd.magnet(magnet00).aInd + 1; % Set A
            app.vd.magnet(magNeigh(i)).bInd = app.vd.magnet(magnet00).bInd + 1; % Set B
            app.vd.magnet(magNeigh(i)).orient = 2; % Tilted as /
            app.vd.magnet(magNeigh(i)).startVertex = vertexMagEnd;
        elseif relativeAngle > 45 % CW
            app.vd.magnet(magNeigh(i)).aInd = app.vd.magnet(magnet00).aInd + 1; % Set A
            app.vd.magnet(magNeigh(i)).bInd = app.vd.magnet(magnet00).bInd - 1; % Set B
            app.vd.magnet(magNeigh(i)).orient = 2; % Tilted as /
            app.vd.magnet(magNeigh(i)).startVertex = vertexMagEnd;
        else % More or less collinear with alpha magnet
            app.vd.magnet(magNeigh(i)).aInd = app.vd.magnet(magnet00).aInd + 2; % Set A
            app.vd.magnet(magNeigh(i)).bInd = app.vd.magnet(magnet00).bInd; % Set B
            app.vd.magnet(magNeigh(i)).orient = 3; % Tilted as \
            app.vd.magnet(magNeigh(i)).startVertex = vertexMagEnd;
        end
        app.vd.magnet(magNeigh(i)).forkType = 0;%app.vd.magnet(magnet00).forkType * -1; % Set the tilt-type
        app.vd.magnet(magNeigh(i)).indexFlag = 1;  % Look into this magnet as the next reference
    end

    % Perform a repetitive loop to index all magnets
    f = uiprogressdlg(app.IceScannerUI,'Title','Mapping to lattice','Message',...
        'Mapping detected magnet positions to ideal lattice and assigning corresponding coordinates.');
    while nnz(vertcat(app.vd.magnet.indexFlag) == 2) < length(app.vd.magnet) % While all magnets have not been indexed
        % Update waitbar
        f.Value = nnz(vertcat(app.vd.magnet(:).indexFlag))/length(app.vd.magnet);

        % Determine the new reference magnets to begin indexing of unindexed magnets
        referenceMagnet = find(vertcat(app.vd.magnet(:).indexFlag) == 1);
        if isempty(referenceMagnet)
            break
        end
        for i = 1:length(referenceMagnet)
            % Identify the "end" vertex for the observed magnet

            % If the "alpha" vertex is not the same as the "start" vertex
            if app.vd.magnet(referenceMagnet(i)).nbrVertexInd(1) ~= app.vd.magnet(referenceMagnet(i)).startVertex 
                vertexMagEnd = app.vd.magnet(referenceMagnet(i)).nbrVertexInd(1);
            % Otherwise, if they are the same, then the refVertexEnd is the beta vertex
            else 
                vertexMagEnd = app.vd.magnet(referenceMagnet(i)).nbrVertexInd(2);
            end

            % Look for the magnets neighboring the reference magnet's "end" vertex
            magNeigh = app.vd.vertex(vertexMagEnd).nbrMagnetInd;
            % Remove magnets that are null or includes the reference magnet or magnets that have aleady been indexed
            magNeigh(magNeigh == 0 | magNeigh == referenceMagnet(i)) = [];
            magNeigh(vertcat(app.vd.magnet(magNeigh).indexFlag) ~= 0) = []; % flag used to be ~=0
            for j = 1:length(magNeigh)
                % Look for the neighboring vertex in the observed magnet (magNeigh(j)) that is not the reference vertexMagEnd and
                % calculate the angle associated with the vector projected from vertexMagEnd to iceMagnets(magNeigh(j),X)
                if app.vd.magnet(magNeigh(j)).nbrVertexInd(1) ~= vertexMagEnd
                    projectVertex = app.vd.magnet(magNeigh(j)).nbrVertexInd(1);
                else
                    projectVertex = app.vd.magnet(magNeigh(j)).nbrVertexInd(2);
                end
                % Calculate the relative angle
                if app.vd.magnet(referenceMagnet(i)).startVertex ~= 0
                    relativeAngle = angleCalc(app,app.vd.magnet(referenceMagnet(i)).startVertex,vertexMagEnd,...
                        vertexMagEnd, projectVertex);
                    % VECTOR POINTS LEFT
                    if app.vd.vertex(app.vd.magnet(referenceMagnet(i)).startVertex).colXPos > app.vd.vertex(vertexMagEnd).colXPos
                        if app.vd.magnet(referenceMagnet(i)).orient == 2 % If the reference magnet is "/"
                            if relativeAngle < -45 % CCW
                                app.vd.magnet(magNeigh(j)).aInd = app.vd.magnet(referenceMagnet(i)).aInd + 1; % Set A
                                app.vd.magnet(magNeigh(j)).bInd = app.vd.magnet(referenceMagnet(i)).bInd - 1; % Set B
                                app.vd.magnet(magNeigh(j)).orient = 3; % Tilted as \
                                app.vd.magnet(magNeigh(j)).startVertex = vertexMagEnd;
                            elseif relativeAngle > 45 % CW
                                app.vd.magnet(magNeigh(j)).aInd = app.vd.magnet(referenceMagnet(i)).aInd - 1; % Set A
                                app.vd.magnet(magNeigh(j)).bInd = app.vd.magnet(referenceMagnet(i)).bInd - 1; % Set B
                                app.vd.magnet(magNeigh(j)).orient = 3; % Tilted as \
                                app.vd.magnet(magNeigh(j)).startVertex = vertexMagEnd;
                            else % More or less collinear
                                app.vd.magnet(magNeigh(j)).aInd = app.vd.magnet(referenceMagnet(i)).aInd; % Set A
                                app.vd.magnet(magNeigh(j)).bInd = app.vd.magnet(referenceMagnet(i)).bInd - 2; % Set B
                                app.vd.magnet(magNeigh(j)).orient = 2; % Tilted as /
                                app.vd.magnet(magNeigh(j)).startVertex = vertexMagEnd;
                            end                
                        elseif app.vd.magnet(referenceMagnet(i)).orient == 3 % If the reference magnet is "\"
                            if relativeAngle < -45 % CCW
                                app.vd.magnet(magNeigh(j)).aInd = app.vd.magnet(referenceMagnet(i)).aInd - 1; % Set A
                                app.vd.magnet(magNeigh(j)).bInd = app.vd.magnet(referenceMagnet(i)).bInd - 1; % Set B
                                app.vd.magnet(magNeigh(j)).orient = 2; % Tilted as /
                                app.vd.magnet(magNeigh(j)).startVertex = vertexMagEnd;
                            elseif relativeAngle > 45 % CW
                                app.vd.magnet(magNeigh(j)).aInd = app.vd.magnet(referenceMagnet(i)).aInd - 1; % Set A
                                app.vd.magnet(magNeigh(j)).bInd = app.vd.magnet(referenceMagnet(i)).bInd + 1; % Set B
                                app.vd.magnet(magNeigh(j)).orient = 2; % Tilted as /
                                app.vd.magnet(magNeigh(j)).startVertex = vertexMagEnd;
                            else % More or less collinear
                                app.vd.magnet(magNeigh(j)).aInd = app.vd.magnet(referenceMagnet(i)).aInd - 2; % Set A
                                app.vd.magnet(magNeigh(j)).bInd = app.vd.magnet(referenceMagnet(i)).bInd; % Set B
                                app.vd.magnet(magNeigh(j)).orient = 3; % Tilted as \
                                app.vd.magnet(magNeigh(j)).startVertex = vertexMagEnd;
                            end 
                        end
                    else % VECTOR POINTS RIGHT
                        if app.vd.magnet(referenceMagnet(i)).orient == 2 % If the reference magnet is "/"
                            if relativeAngle < -45 % CCW
                                app.vd.magnet(magNeigh(j)).aInd = app.vd.magnet(referenceMagnet(i)).aInd - 1; % Set A
                                app.vd.magnet(magNeigh(j)).bInd = app.vd.magnet(referenceMagnet(i)).bInd + 1; % Set B
                                app.vd.magnet(magNeigh(j)).orient = 3; % Tilted as \
                                app.vd.magnet(magNeigh(j)).startVertex = vertexMagEnd;
                            elseif relativeAngle > 45 % CW
                                app.vd.magnet(magNeigh(j)).aInd = app.vd.magnet(referenceMagnet(i)).aInd + 1; % Set A
                                app.vd.magnet(magNeigh(j)).bInd = app.vd.magnet(referenceMagnet(i)).bInd + 1; % Set B
                                app.vd.magnet(magNeigh(j)).orient = 3; % Tilted as \
                                app.vd.magnet(magNeigh(j)).startVertex = vertexMagEnd;
                            else % More or less collinear
                                app.vd.magnet(magNeigh(j)).aInd = app.vd.magnet(referenceMagnet(i)).aInd; % Set A
                                app.vd.magnet(magNeigh(j)).bInd = app.vd.magnet(referenceMagnet(i)).bInd + 2; % Set B
                                app.vd.magnet(magNeigh(j)).orient = 2; % Tilted as /
                                app.vd.magnet(magNeigh(j)).startVertex = vertexMagEnd;
                            end                
                        elseif app.vd.magnet(referenceMagnet(i)).orient == 3 % If the reference magnet is "\"
                            if relativeAngle < -45 % CCW
                                app.vd.magnet(magNeigh(j)).aInd = app.vd.magnet(referenceMagnet(i)).aInd + 1; % Set A
                                app.vd.magnet(magNeigh(j)).bInd = app.vd.magnet(referenceMagnet(i)).bInd + 1; % Set B
                                app.vd.magnet(magNeigh(j)).orient = 2; % Tilted as /
                                app.vd.magnet(magNeigh(j)).startVertex = vertexMagEnd;
                            elseif relativeAngle > 45 % CW
                                app.vd.magnet(magNeigh(j)).aInd = app.vd.magnet(referenceMagnet(i)).aInd + 1; % Set A
                                app.vd.magnet(magNeigh(j)).bInd = app.vd.magnet(referenceMagnet(i)).bInd - 1; % Set B
                                app.vd.magnet(magNeigh(j)).orient = 2; % Tilted as /
                                app.vd.magnet(magNeigh(j)).startVertex = vertexMagEnd;
                            else % More or less collinear
                                app.vd.magnet(magNeigh(j)).aInd = app.vd.magnet(referenceMagnet(i)).aInd + 2; % Set A
                                app.vd.magnet(magNeigh(j)).bInd = app.vd.magnet(referenceMagnet(i)).bInd; % Set B
                                app.vd.magnet(magNeigh(j)).orient = 3; % Tilted as \
                                app.vd.magnet(magNeigh(j)).startVertex = vertexMagEnd;
                            end 
                        end

                    end
                end
                %app.vd.magnet(magNeigh(j)).forkType = app.vd.magnet(referenceMagnet(i)).forkType * -1; % Set the tilt-type
                app.vd.magnet(magNeigh(j)).indexFlag = 1;  % Look into this magnet as the next reference
            end
            % Done looking at this particular reference magnet
            app.vd.magnet(referenceMagnet(i)).indexFlag = 2;
        end
    end 
    close(f);
end