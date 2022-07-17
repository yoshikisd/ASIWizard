function neighborIdxLocator(app)
    % Determines the alpha, beta, gamma, delta, ... neighbors for correlation function calculation
    % Based on Li et al. PRB 81, 092406 (2010)
    switch app.vd.typeASI
        case 'Kagome'
            dist1 = 1;              % Beta /
            dist2 = sqrt(3);        % Gamma /
            dist3 = 2;              % Delta 
            dist4 = dist3;          % Nu
            dist5 = 3;              % Eta /
            dist6 = 3.4641;         % Phi /
            dist7 = 2.6458;         % Tau /
            hexToRectCoords(app);
            idx = [vertcat(app.vd.magnet.aInd_Hex2Rec),vertcat(app.vd.magnet.bInd_Hex2Rec)];
        case {'Square','Brickwork','Tetris'}
            dist1 = sqrt(2);
            dist2 = 2;
            dist3 = dist2;
            dist4 = 4;
            dist5 = 3.1623;
            dist6 = 2*sqrt(2);
            dist7 = dist4;
            idx = [vertcat(app.vd.magnet.xR),vertcat(app.vd.magnet.yR)];
    end
    currentStatus = uiprogressdlg(app.IceScannerUI,'Title','Spin-spin correlation',...
        'Message',sprintf('%s\n\n%s','Identifying n-th nearest neighbors for each nanomagnet.',...
        'This may take a while.'));
    switch app.vd.typeASI
        case 'Brickwork'
            % First, clear all neighbor idx
            currentStatus2 = uiprogressdlg(app.IceScannerUI,'Title','Spin-spin correlation',...
                'Message',sprintf('%s\n\n%s','Clearing neighbor indices.',...
                'This may take a while.'));
            ctr = 1;
            for alpha = 1:length(idx)
                for i = 1:11
                    app.vd.magnet(alpha).nbr(i).idx = [];
                    currentStatus2.Value = ctr / (length(idx)*11);
                    ctr = ctr + 1;
                end
            end
            close(currentStatus2);
            for alpha = 1:length(idx)
                reinitVar();
                app.vd.magnet(alpha).nbr(11).idx = [];
                % Tabulate the distance to all neighboring magnets
                vectorToIdx = idx - idx(alpha,:);
                distToIdx = sqrt(vectorToIdx(:,1).^2 + vectorToIdx(:,2).^2);
                % See the neighbor rules ppt slide about how neighbors were assigned (based on an interpretation of Fig 1(b))
                
                % In both vertical and horizontal nanomagnets, neighbors S1, S5a, S5b, and S6a can be found
                % S1 can be defined using the same method as the square system
                app.vd.magnet(alpha).nbr(1).idx = find(distToIdx >= 0.95*dist1 & distToIdx <= 1.05*dist1);
                % All nbr5 neighbors are dist5 away from the observed alpha mag. In the case of the brickwork system we need
                % to identify the two unique subtypes. In terms of lattice coordinates the difference magnitude should be as follows:
                % a-subtype: |Delta_aInd| = 3, |Delta_bInd| = 1
                % b-subtype: |Delta_aInd| = 1, |Delta_bInd| = 3
                % First, we look for all the potential 5a and 5b neighbors
                nbr5aORb = find(distToIdx >= 0.95*dist5 & distToIdx <= 1.05*dist5);
                if ~isempty(nbr5aORb)
                    % Then, we identify those elements that satisify the lattice coordinate criteria listed above
                    nbr5_aInd = vertcat(app.vd.magnet(nbr5aORb).aInd);
                    nbr5_bInd = vertcat(app.vd.magnet(nbr5aORb).bInd);
                    nbr5_aIndDelta = abs(nbr5_aInd - app.vd.magnet(alpha).aInd);
                    nbr5_bIndDelta = abs(nbr5_bInd - app.vd.magnet(alpha).bInd);
                    isNbr5a = nbr5_aIndDelta == 3 & nbr5_bIndDelta == 1;
                    app.vd.magnet(alpha).nbr(5).idx = nbr5aORb(isNbr5a);
                    app.vd.magnet(alpha).nbr(9).idx = nbr5aORb(~isNbr5a);
                end
                % All nbr6 neighbors are dist6 away from the observed alpha mag. In the case of the brickwork system we need
                % to identify the two unique subtypes. In terms of the array topology, nbr6a is 1 nanomagnet separated from alpha
                % whereas nbr6b is two nanomagnets separated. One way to figure out which-is-which by using only the lattice coordinates
                % is to figure out whether or not the previously detected nbr1 resides immediately between the nbr6 and the alpha magnet
                % First, we look for all the potential 6a and 6b neighbors
                nbr6aORb = find(distToIdx >= 0.95*dist6 & distToIdx <= 1.05*dist6);
                if ~isempty(nbr6aORb)
                    % Then, we take a look at the lattice coordinates of the detected neighbors
                    nbr6_aInd = vertcat(app.vd.magnet(nbr6aORb).aInd);
                    nbr6_bInd = vertcat(app.vd.magnet(nbr6aORb).bInd);
                    % We now define a vector cast from the alpha magnet to the nbr6 magnets
                    alphaToNbr6 = [nbr6_aInd - app.vd.magnet(alpha).aInd, nbr6_bInd - app.vd.magnet(alpha).bInd];
                    % Now, we define another vector cast from the alpha magnet to the nbr1 magnets
                    nbr1_aInd = vertcat(app.vd.magnet(app.vd.magnet(alpha).nbr(1).idx).aInd);
                    nbr1_bInd = vertcat(app.vd.magnet(app.vd.magnet(alpha).nbr(1).idx).bInd);
                    alphaToNbr1 = [nbr1_aInd - app.vd.magnet(alpha).aInd, nbr1_bInd - app.vd.magnet(alpha).bInd];
                    % Determine the angle of separation between alphaToNbr6 and alphaToNbr1; nbr6a has been detected if the angle is zero
                    isNbr6a = false(1,length(nbr6aORb));
                    for i = 1:length(app.vd.magnet(alpha).nbr(1).idx)
                        for j = 1:length(nbr6aORb)
                            % Each row has an a-b index pair, while each column has either a or b indices
                            if atan2(norm(cross([alphaToNbr1(i,:),0],[alphaToNbr6(j,:),0])),dot(alphaToNbr1(i,:),alphaToNbr6(j,:))) == 0
                                isNbr6a(j) = true;
                            end
                        end
                    end
                    app.vd.magnet(alpha).nbr(6).idx = nbr6aORb(isNbr6a);
                end
                % Neighbor 6b only exists for the horizontal magnet, so that will be called if the horizontal magnet is being observed
                if (app.vd.brickMode == '\' && (mod(app.vd.magnet(alpha).aInd,2) == 1 && mod(app.vd.magnet(alpha).bInd,2) == 1)) ...
                        || (app.vd.brickMode == '/' && (mod(app.vd.magnet(alpha).aInd,2) == 0 && mod(app.vd.magnet(alpha).bInd,2) == 0))% "Vertical" magnets, nbr_#b
                    % S2 and S3 do not exist for the vertical magnet (in the context described in the article)
                    % S4a and S7a
                    % To distinguish between nbr4 and nbr7, check whether or not the spin vector of the alpha magnet
                    % is parallel with a vector projected from the alpha to the neighbor magnet
                    nbr4or7 = find(distToIdx >= 0.95*dist4 & distToIdx <= 1.05*dist4);
                    if ~isempty(nbr4or7)
                        nbr4or7_xR = vertcat(app.vd.magnet(nbr4or7).xR);
                        nbr4or7_yR = vertcat(app.vd.magnet(nbr4or7).yR);
                        nbr4or7_rij = round([nbr4or7_xR - app.vd.magnet(alpha).xR, nbr4or7_yR - app.vd.magnet(alpha).yR]);
                        % If the dot product between the alpha spin and r_ij is zero (normal), then the observed
                        % magnet is nbr7. Otherwise it is nbr4.
                        [ht, wt] = size(nbr4or7_rij);
                        alpha_spin = zeros(ht,wt);
                        alpha_spin(:,1) = app.vd.magnet(alpha).xSpin;
                        alpha_spin(:,2) = app.vd.magnet(alpha).ySpin;
                        isNbr7 = round(dot(alpha_spin, nbr4or7_rij, 2)) == 0;
                        app.vd.magnet(alpha).nbr(11).idx = nbr4or7(isNbr7);
                        app.vd.magnet(alpha).nbr(8).idx = nbr4or7(~isNbr7);
                    end
                    % Vertical magnets possess neighbors S5a and S5b
                elseif (app.vd.brickMode == '\' && (mod(app.vd.magnet(alpha).aInd,2) == 0 && mod(app.vd.magnet(alpha).bInd,2) == 0))...
                        || (app.vd.brickMode == '/' && (mod(app.vd.magnet(alpha).aInd,2) == 1 && mod(app.vd.magnet(alpha).bInd,2) == 1))% "Horizontal" magnets, nbr_#a
                    app.vd.magnet(alpha).nbr(10).idx = nbr6aORb(~isNbr6a);
                    % To distinguish between nbr2 and nbr3, check whether or not the spin vector of the alpha magnet
                    % is parallel with a vector projected from the alpha to the neighbor magnet
                    nbr2or3 = find(distToIdx >= 0.95*dist2 & distToIdx <= 1.05*dist2);
                    if ~isempty(nbr2or3)
                        nbr2or3_xR = vertcat(app.vd.magnet(nbr2or3).xR);
                        nbr2or3_yR = vertcat(app.vd.magnet(nbr2or3).yR);
                        nbr2or3_rij = round([nbr2or3_xR - app.vd.magnet(alpha).xR, nbr2or3_yR - app.vd.magnet(alpha).yR]);
                        [ht, wt] = size(nbr2or3_rij);
                        alpha_spin = zeros(ht,wt);
                        alpha_spin(:,1) = app.vd.magnet(alpha).xSpin;
                        alpha_spin(:,2) = app.vd.magnet(alpha).ySpin;
                        % If the dot product between the alpha spin and r_ij is zero (normal), then the observed
                        % magnet is nbr3. Otherwise it is nbr2.
                        isNbr3 = round(dot(alpha_spin, nbr2or3_rij,2)) == 0;
                        app.vd.magnet(alpha).nbr(3).idx = nbr2or3(isNbr3);
                        app.vd.magnet(alpha).nbr(2).idx = nbr2or3(~isNbr3);
                    end
                    % To distinguish between nbr4 and nbr7, check whether or not the spin vector of the alpha magnet
                    % is parallel with a vector projected from the alpha to the neighbor magnet
                    nbr4or7 = find(distToIdx >= 0.95*dist4 & distToIdx <= 1.05*dist4);
                    if ~isempty(nbr4or7)
                        nbr4or7_xR = vertcat(app.vd.magnet(nbr4or7).xR);
                        nbr4or7_yR = vertcat(app.vd.magnet(nbr4or7).yR);
                        nbr4or7_rij = round([nbr4or7_xR - app.vd.magnet(alpha).xR, nbr4or7_yR - app.vd.magnet(alpha).yR]);
                        % If the dot product between the alpha spin and r_ij is zero (normal), then the observed
                        % magnet is nbr7. Otherwise it is nbr4.
                        [ht, wt] = size(nbr4or7_rij);
                        alpha_spin = zeros(ht,wt);
                        alpha_spin(:,1) = app.vd.magnet(alpha).xSpin;
                        alpha_spin(:,2) = app.vd.magnet(alpha).ySpin;
                        isNbr7 = round(dot(alpha_spin, nbr4or7_rij, 2)) == 0;
                        app.vd.magnet(alpha).nbr(7).idx = nbr4or7(isNbr7);
                        app.vd.magnet(alpha).nbr(4).idx = nbr4or7(~isNbr7);
                    end
                end
                currentStatus.Value = alpha/length(idx);
            end
        case 'Square'
            for alpha = 1:length(idx)
                reinitVar();
                app.vd.magnet(alpha).nbr(11).idx = [];
                % Tabulate the distance to all neighboring magnets
                vectorToIdx = idx - idx(alpha,:);
                distToIdx = sqrt(vectorToIdx(:,1).^2 + vectorToIdx(:,2).^2);
                % All nbr1 neighbors are dist1 away from the observed alpha mag
                app.vd.magnet(alpha).nbr(1).idx = find(distToIdx >= 0.95*dist1 & distToIdx <= 1.05*dist1);
                % All nbr5 neighbors are dist5 away from the observed alpha mag
                app.vd.magnet(alpha).nbr(5).idx = find(distToIdx >= 0.95*dist5 & distToIdx <= 1.05*dist5);
                % All nbr6 neighbors are dist6 away from the observed alpha mag
                app.vd.magnet(alpha).nbr(6).idx = find(distToIdx >= 0.95*dist6 & distToIdx <= 1.05*dist6);
                
                % To distinguish between nbr2 and nbr3, check whether or not the spin vector of the alpha magnet
                % is parallel with a vector projected from the alpha to the neighbor magnet
                nbr2or3 = find(distToIdx >= 0.95*dist2 & distToIdx <= 1.05*dist2);
                nbr2or3_xR = vertcat(app.vd.magnet(nbr2or3).xR);
                nbr2or3_yR = vertcat(app.vd.magnet(nbr2or3).yR);
                nbr2or3_rij = round([nbr2or3_xR - app.vd.magnet(alpha).xR, nbr2or3_yR - app.vd.magnet(alpha).yR]);
                [ht, wt] = size(nbr2or3_rij);
                alpha_spin = zeros(ht,wt);
                alpha_spin(:,1) = app.vd.magnet(alpha).xSpin;
                alpha_spin(:,2) = app.vd.magnet(alpha).ySpin;
                % If the dot product between the alpha spin and r_ij is zero (normal), then the observed
                % magnet is nbr3. Otherwise it is nbr2.
                isNbr3 = round(dot(alpha_spin, nbr2or3_rij,2)) == 0;
                app.vd.magnet(alpha).nbr(3).idx = nbr2or3(isNbr3);
                app.vd.magnet(alpha).nbr(2).idx = nbr2or3(~isNbr3);
                
                % To distinguish between nbr4 and nbr7, check whether or not the spin vector of the alpha magnet
                % is parallel with a vector projected from the alpha to the neighbor magnet
                nbr4or7 = find(distToIdx >= 0.95*dist4 & distToIdx <= 1.05*dist4);
                nbr4or7_xR = vertcat(app.vd.magnet(nbr4or7).xR);
                nbr4or7_yR = vertcat(app.vd.magnet(nbr4or7).yR);
                nbr4or7_rij = round([nbr4or7_xR - app.vd.magnet(alpha).xR, nbr4or7_yR - app.vd.magnet(alpha).yR]);
                % If the dot product between the alpha spin and r_ij is zero (normal), then the observed
                % magnet is nbr7. Otherwise it is nbr4.
                [ht, wt] = size(nbr4or7_rij);
                alpha_spin = zeros(ht,wt);
                alpha_spin(:,1) = app.vd.magnet(alpha).xSpin;
                alpha_spin(:,2) = app.vd.magnet(alpha).ySpin;
                isNbr7 = round(dot(alpha_spin, nbr4or7_rij, 2)) == 0;
                app.vd.magnet(alpha).nbr(7).idx = nbr4or7(isNbr7);
                app.vd.magnet(alpha).nbr(4).idx = nbr4or7(~isNbr7);
                currentStatus.Value = alpha/length(idx);
            end
        case 'Kagome'
            for alpha = 1:length(idx)
                reinitVar();
                % Tabulate the distance to all neighboring magnets
                vectorToIdx = idx - idx(alpha,:);
                distToIdx = sqrt(vectorToIdx(:,1).^2 + vectorToIdx(:,2).^2);
                % All beta neighbors are dist1 away from the observed alpha mag
                app.vd.magnet(alpha).nbr(1).idx = find(distToIdx >= 0.95*dist1 & distToIdx <= 1.05*dist1);
                % All eta neighbors are dist5 away from the observed alpha mag
                app.vd.magnet(alpha).nbr(5).idx = find(distToIdx >= 0.95*dist5 & distToIdx <= 1.05*dist5);
                % All phi neighbors are dist6 away from the observed alpha mag
                % For the case of the Kagome ASI, make sure that the nbr6 magnets directly lie within the
                % alpha axis of elongation. This can be determined by taking the dot product of two vectors:
                % The alpha spin vector and a vector cast from the center of the alpha magnet to a candidate
                % nbr6 magnet. If the two vectors coincide with one another, then the nbr6 magnet has been detected.
                % Here a slightly different approach is used: Rotate the alpha spin vector by 90 degrees and take
                % the dot product: a zero value will indicate detection of a nbr6 magnet.
                nbr6 = find(distToIdx >= 0.999*dist6 & distToIdx <= 1.001*dist6);
                nbr6_a = vertcat(app.vd.magnet(nbr6).aInd_Hex2Rec);
                nbr6_b = vertcat(app.vd.magnet(nbr6).bInd_Hex2Rec);
                alpha2nbr6 = [nbr6_b - app.vd.magnet(alpha).bInd_Hex2Rec nbr6_a - app.vd.magnet(alpha).aInd_Hex2Rec ];
                [ht, wt] = size(alpha2nbr6);
                % Generate a matrix containing the vector information of the alpha magnet to perform element-wise dot products
                alpha_v_R90 = zeros(ht,wt);
                % The absence of a "-" is associated with an mapping correction since MATLAB does this dumb f-ck thing where the coordinate system
                % on regular plots and images are inverted
                alpha_v_R90(:,1) = app.vd.magnet(alpha).ySpin; 
                alpha_v_R90(:,2) = app.vd.magnet(alpha).xSpin; 
                isNbr6 = round(dot(alpha_v_R90,alpha2nbr6,2)) == 0;
                app.vd.magnet(alpha).nbr(6).idx = nbr6(isNbr6);
                % For gamma, delta, nu, and tau neighbors need additional information regarding "topological" distance away from the
                % alpha magnet (i.e., how many magnets away is the neighbor magnet)

                % Search for all neighbors that have a unique distance away from the alpha magnet
                app.vd.magnet(alpha).nbr(2).idx = find(distToIdx >= 0.95*dist2 & distToIdx <= 1.05*dist2);
                app.vd.magnet(alpha).nbr(7).idx = find(distToIdx >= 0.95*dist7 & distToIdx <= 1.05*dist7);
                % For the nu and delta magnets, first identify all magnets that are dist3 = dist4 away from alpha
                deltaNu = find(distToIdx >= 0.99*dist3 & distToIdx <= 1.01*dist3);
                % Delta magnets are separated from the alpha magnet by 1 magnet (beta), 
                % whereas the nu magnet is separated by 2 (beta and gamma).
                % Using the information acquired about the beta magnet, we can simply look for which magnet indices in deltaNu
                % share at least 1 vertex with the same index
                mat_34 = vertcat(app.vd.magnet(deltaNu).nbrVertexInd);
                idx1 = app.vd.magnet(alpha).nbr(1).idx;
                mat_2 = vertcat(app.vd.magnet(idx1).nbrVertexInd);
                compare_34_2 = ismember(mat_34,mat_2);
                isNbr3 = compare_34_2(:,1) | compare_34_2(:,2);
                app.vd.magnet(alpha).nbr(4).idx = deltaNu(~isNbr3);
                app.vd.magnet(alpha).nbr(3).idx = deltaNu(isNbr3);
                currentStatus.Value = alpha/length(idx);
            end
    end
    
    % Reinitializes all unique variables to avoid indexing errors associated with past iteration definitions
    function reinitVar()
        vectorToIdx = [];
        distToIdx = [];
        nbr5aORb = [];
        nbr5_aInd = [];
        nbr5_bInd = [];
        nbr5_aIndDelta = [];
        nbr5_bIndDelta = [];
        isNbr5a = [];
        nbr6aORb = [];
        nbr6_aInd = [];
        nbr6_bInd = [];
        alphaToNbr6 = [];
        nbr1_aInd = [];
        nbr1_bInd = [];
        alphaToNbr1 = [];
        isNbr6a = [];
        nbr4or7 = [];
        nbr4or7_xR = [];
        nbr4or7_yR = [];
        nbr4or7_rij = [];
        ht = [];
        wt = [];
        alpha_spin = [];
        isNbr7 = [];
        nbr2or3 = [];
        nbr2or3_xR = [];
        nbr2or3_yR = [];
        nbr2or3_rij = [];
        isNbr3 = [];
        nbr4or7 = [];
        nbr4or7_xR = [];
        nbr4or7_yR = [];
        nbr4or7_rij = [];
        isNbr7 = [];
        nbr6 = [];
        nbr6_a = [];
        nbr6_b = [];
        alpha2nbr6 = [];
        [ht, wt] = size(alpha2nbr6);
        alpha_v_R90 = [];
        isNbr6 = [];
        deltaNu = [];
        mat_34 = [];
        idx1 = [];
        mat_2 = [];
        compare_34_2 = [];
    end
end