function nbrCoeff = spinCorrelation(app,pairNbrList,definition,calcMode)
    nbrCoeff = 0;
    % Calculate nbr coefficient
    % When we're taking the average spin-spin correlation, we need to make sure that 
    % we omit magnets that are flagged to be ignored. This is relevant for the case where
    % the program reports a non-magnet region as a magnet.
    % Figure out the size of the array
    [numel,~] = size(pairNbrList);
    for i = 1:numel
        mag1Idx = pairNbrList(i,1);
        mag2Idx = pairNbrList(i,2);
        spin1 = [app.vd.magnet(mag1Idx).xSpin, app.vd.magnet(mag1Idx).ySpin];
        % Check domain state of alpha magnet pairNbrList(:,2) before assigning spin2
        % Only perform this when calculating the local correlations
        % For global correlator calculation, always treat CST as effective zero moment entities
        if app.vd.magnet(mag2Idx).domainState == "Ising" || calcMode == "global"
            spin2 = [app.vd.magnet(mag2Idx).xSpin, app.vd.magnet(mag2Idx).ySpin];
        elseif calcMode == "local" && (app.vd.magnet(mag2Idx).domainState == "OWIB" ||...
               app.vd.magnet(mag2Idx).domainState == "OBIW" ||...
               app.vd.magnet(mag2Idx).domainState == "TWBB" ||...
               app.vd.magnet(mag2Idx).domainState == "TBBW")
            spin2 = [app.vd.magnet(mag2Idx).xPseudospin, app.vd.magnet(mag2Idx).yPseudospin];
        end
        
        switch definition
            case "dot"
                nbrCoeff = dot(spin1,spin2)/length(pairNbrList) + nbrCoeff;
            case "dot binary"
                if dot(spin1,spin2) > 0
                    nbrCoeff = 1/length(pairNbrList) + nbrCoeff;
                elseif dot(spin1,spin2) < 0
                    nbrCoeff = -1/length(pairNbrList) + nbrCoeff;
                end
            case "magnetostatic"
                r_ij = [app.vd.magnet(mag1Idx).xR - app.vd.magnet(mag2Idx).xR,...
                    app.vd.magnet(mag1Idx).yR - app.vd.magnet(mag2Idx).yR];
                E_init = dot(spin1,spin2) - 3*dot(spin1,r_ij)*dot(spin2,r_ij);
                E_flip = dot(-spin1,spin2) - 3*dot(-spin1,r_ij)*dot(spin2,r_ij);
                if E_init < E_flip
                    nbrCoeff = 1/length(pairNbrList) + nbrCoeff;
                elseif E_init > E_flip
                    nbrCoeff = -1/length(pairNbrList) + nbrCoeff;
                end
        end
    end
end
