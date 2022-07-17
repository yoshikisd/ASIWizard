function alterMagnet(app,alterMode)
    try
        % Alters the magnetization state of a selected magnet

        switch app.drop_inspectionImage.Value
            case '-'
                uialert(app.IceScannerUI,'Select an image to perform manual masking of nanomagnets.','Error');
                return;
            case 'Topography'
                backgroundImage = mat2gray(app.vd.xasGrid(:,:,1));
            case 'Magnetic contrast'
                backgroundImage = mat2gray(app.vd.xmcd);
            case 'Boosted magnetic contrast'
                backgroundImage = mat2gray(mat2gray(app.vd.xmcd),[0.25,0.75]);
            case 'Magnetic contrast magnitude'
                backgroundImage = mat2gray(abs(app.vd.xmcdTrinary));
            case 'Trinary contrast'
                backgroundImage = mat2gray(app.vd.xmcdCorrectedTrinary);
            case 'ROI - Regular'
                backgroundImage = mat2gray(app.vd.xmcdOriginalSkeleton);
            case 'ROI - Averaged'
                backgroundImage = mat2gray(app.vd.magnetInterpretCombinedImg);
            case 'ROI - Trinary'
                backgroundImage = mat2gray(app.vd.xmcdTrinarySkeleton);
        end

        % Determine whether a manual-selection-based operation or an auto-detection operation will be performed
        switch alterMode
            case {'zeroize','ignore','flip','OWIB','OBIW','TWBB','TBBW','makeIsing'}
                % Generate the image figure
                selectionFigure = figure('Name','Select magnets to mask');
                selectionFigure.MenuBar = 'none';
                selectionFigure.ToolBar = 'none';
                selectionAxes = axes(selectionFigure);
                movegui(selectionFigure,'center');
                general_imageDisplay(app,selectionAxes,backgroundImage);
                overlayVertexType(app,selectionAxes);
                if app.showMagVector.Value
                    overlayMagnetization(app,selectionAxes);    
                end
                % If the "show magnetization vector" option is true, then show the magnetization
                if app.showMagVector.Value
                    overlayMagnetization(app,selectionAxes);    
                end
                manualEdit(app, alterMode, backgroundImage);
            case {'displayNonIsing','displayIsing','autoZeroize'}
                autoEdit(app, alterMode, backgroundImage);
        end
    catch ME
        errorNotice(app,ME);
        return;
    end
    
    % Update the analysis window with the new magnetization based on whatever the chosen inspection image was

    
    
    % Alters app.vd.magnet so that the code interprets the entry as a zero-moment magnet
    function spinZeroize(app,selectIdx,vtx1,vtx2)
        % Set the magnetization equal to zero (background/ambiguous)
        app.vd.magnet(selectIdx).projection = 0;
        % Zeroize the spin vector
        app.vd.magnet(selectIdx).xSpin = 0;
        app.vd.magnet(selectIdx).ySpin = 0;
        % Set corresponding vertex types to NaN
        app.vd.vertex(vtx1).type = NaN;
        app.vd.vertex(vtx2).type = NaN;
    end
    
    % Displays detected non-Ising/Ising states. Deletes them if autoZeroize is selected
    function autoEdit(app, alterMode, backgroundImage)
        % Change method of magnet index acquisition based on the isingDetectMethod value
        switch app.isingDetectMethod.SelectedObject.Text
            case 'STDEV'
                magValues = vertcat(app.vd.magnet.xmcdSTD);
                
                % Make magnet index list based on threshold std
                switch alterMode
                    case 'displayIsing'
                        magSelect = find(magValues < app.nonIsingThreshold.Value);
                    case {'displayNonIsing','autoZeroize'}
                        magSelect = find(magValues >= app.nonIsingThreshold.Value);
                end
                
            case 'Unique intensities'
                magValues = vertcat(app.vd.magnet.uniqueTrinaryInt_absSum);
                
                % Make magnet index list based on number of unique trinary values
                switch alterMode
                    case 'displayIsing'
                        % Ising should only have +1 and 0, -1 and 0, +1, or -1 only.
                        % Thus, the sum of the unique intensity value magnitudes should be 1
                        magSelect = find(magValues == 1); 
                    case {'displayNonIsing','autoZeroize'}
                        % CST states have a mixture of +1 and -1, or +1 -1 and 0. Thus,
                        % the sum of the unique intensity value magnitudes should be 2
                        magSelect = find(magValues == 2);
                end
        end
        
        % Extract the trinarized intensity standard deviation of each magnet
        magValues = vertcat(app.vd.magnet.xmcdSTD);
        
        % Perform autozeroize operation if selected
        switch alterMode
            case 'autoZeroize'
                for i = 1:length(magSelect)
                    % Preindex neighboring vertices for vertex calculation correction
                    vtx1 = app.vd.magnet(magSelect(i)).nbrVertexInd(1);
                    vtx2 = app.vd.magnet(magSelect(i)).nbrVertexInd(2);

                    % Perform specified operation on selected magnet
                    app.vd.magnet(magSelect(i)).domainState = 'unknown (autoremoved)';
                    spinZeroize(app,magSelect(i),vtx1,vtx2);
                end
        end
        
        % Show an image of the magnetization/vertices with cyan circles encompassing the detected magnets
        general_imageDisplay(app,app.extWindow.axes,backgroundImage);
        if app.showMagVector.Value
            overlayMagnetization(app,app.extWindow.axes);    
        end
        overlayVertexType(app,app.extWindow.axes);
        
        hold(app.extWindow.axes,'on');
        plot(app.extWindow.axes,vertcat(app.vd.magnet(magSelect).colXPos),...
            vertcat(app.vd.magnet(magSelect).rowYPos),'co','MarkerSize',7,...
            'LineWidth',1);
        hold(app.extWindow.axes,'off');
        
    end

    % Creates figure where user manually selects points for varyious operations
    function manualEdit(app, alterMode, backgroundImage)
        % Notify the user to select points on the popup figure that will be initiated after activation of the dialog
        switch alterMode
            case 'zeroize' 
                informOperation = 'set the magnetization to zero.';
            case 'ignore'
                informOperation = 'remove from subsequent analysis.';
            case 'flip'
                informOperation = 'have the magnetization reversed.';
            case {'OWIB','OBIW','TWBB','TBBW'}
                informOperation = sprintf('designate as a complex spin texture with domain state %s.',alterMode);
            case 'makeIsing'
                informOperation = 'set as Ising states.';
        end
        
        alterDialog = uiprogressdlg(app.IceScannerUI,'Title','Please view the pop-up figure window','Message',...
            sprintf('%s%s\n\n%s\n\n%s',...
            'In the pop-up window, select the centers of the nanomagnets you wish to ', informOperation,...
            'To undo the last selection, press the delete/backspace key. Once you are done, press the enter key.',...
            'For this to work, the last object you click must be somewhere within the analysis window.'),'Indeterminate','on');

        % Allow user to select points for alteration
        try
            [xSelect, ySelect] = getpts(selectionAxes);
            xSelect = floor(xSelect);
            ySelect = floor(ySelect);
        catch ME
            errorNotice(app,ME);
            close(alterDialog);
            return;
        end

        % Store magnet x and y values in vectors
        magnetRowYLoc = vertcat(app.vd.magnet.rowYPos);
        magnetColXLoc = vertcat(app.vd.magnet.colXPos);

        % Perform specified operation on selected magnets
        % In this case, I put the switch statement inside the for loop since I'm running under an assumption that
        % the number of points the user selects will result in a neglegible performance hit 
        for i = 1:length(xSelect)
            % Look for the corresponding magnet coordinates in iceMagnets within a +- 10 variance along x and y
            selectIdx = find((magnetRowYLoc <= ySelect(i) + 10 & magnetRowYLoc >= ySelect(i) - 10) &...
                magnetColXLoc <= xSelect(i) + 10 & magnetColXLoc >= xSelect(i) - 10);
            % Preindex neighboring vertices for vertex calculation correction
            vtx1 = app.vd.magnet(selectIdx).nbrVertexInd(1);
            vtx2 = app.vd.magnet(selectIdx).nbrVertexInd(2);

            % Perform specified operation on selected magnet
            switch alterMode
                case 'zeroize' 
                    app.vd.magnet(selectIdx).domainState = 'indiscernible';
                    spinZeroize(app,selectIdx,vtx1,vtx2);
                case {'OWIB','OBIW','TWBB','TBBW'}
                    % Flag a magnet as a CST; domain type reported in alterMode
                    app.vd.magnet(selectIdx).domainState = alterMode;
                    % Save the current spin state in the pseudospin variable
                    for j = 1:length(selectIdx)
                        app.vd.magnet(selectIdx(j)).xPseudospin = app.vd.magnet(selectIdx(j)).xSpin;
                        app.vd.magnet(selectIdx(j)).yPseudospin = app.vd.magnet(selectIdx(j)).ySpin;
                    end
                    % Zeroize spin
                    spinZeroize(app,selectIdx,vtx1,vtx2);
                case 'ignore'
                    % Set a flag to ignore this magnet in all subsequent analysis
                    app.vd.magnet(selectIdx).ignoreFlag = true;
                    % Set the magnetization equal to zero (background/ambiguous)
                    app.vd.magnet(selectIdx).projection = NaN;
                    % NaN spin vector
                    app.vd.magnet(selectIdx).xSpin = NaN;
                    app.vd.magnet(selectIdx).ySpin = NaN;
                    % Set corresponding vertex types to NaN
                    app.vd.vertex(vtx1).type = NaN;
                    app.vd.vertex(vtx2).type = NaN;
                case 'flip'
                    % Flip the projection of the magnetization
                    % Here it is assumed that the user is not trying to define a null/NaN magnet
                    app.vd.magnet(selectIdx).projection = app.vd.magnet(selectIdx).projection * -1;
                    % Change the orientation of the spin vector
                    app.vd.magnet(selectIdx).xSpin = -app.vd.magnet(selectIdx).xSpin;
                    app.vd.magnet(selectIdx).ySpin = -app.vd.magnet(selectIdx).ySpin;
                    % Change the corresponding spin angle
                    if app.vd.magnet(selectIdx).projection ~= 0
                        app.vd.magnet(selectIdx).spinAngle = app.vd.magnet(selectIdx).spinAngle + 180;
                    end
                    % Recalculate vertex types
                    vertexTypeAssignment(app,vtx1);
                    vertexTypeAssignment(app,vtx2);
                    % Redetermine the X and Y offsets when plotting the Ising macrospins
                    app.vd.magnet(selectIdx).spinPlotXOffset = app.vd.magnet(selectIdx).colXPos -...
                        7*cosd(app.vd.magnet(selectIdx).spinAngle);
                    app.vd.magnet(selectIdx).spinPlotYOffset = app.vd.magnet(selectIdx).rowYPos -...
                        7*sind(app.vd.magnet(selectIdx).spinAngle);
                case 'makeIsing'
                    % Just reload the original Ising state from app.vd.oldMagnet
                    app.vd.magnet(selectIdx).projection = app.vd.oldMagnet(selectIdx).projection;
                    app.vd.magnet(selectIdx).xSpin = app.vd.oldMagnet(selectIdx).xSpin;
                    app.vd.magnet(selectIdx).ySpin = app.vd.oldMagnet(selectIdx).ySpin;
                    app.vd.magnet(selectIdx).spinAngle = app.vd.oldMagnet(selectIdx).spinAngle;
                    app.vd.magnet(selectIdx).spinPlotXOffset = app.vd.oldMagnet(selectIdx).spinPlotXOffset;
                    app.vd.magnet(selectIdx).spinPlotYOffset = app.vd.oldMagnet(selectIdx).spinPlotYOffset;
                    app.vd.magnet(selectIdx).domainState = 'Ising';
                    % Recalculate vertex types
                    vertexTypeAssignment(app,vtx1);
                    vertexTypeAssignment(app,vtx2);
            end
        end
        
        close(selectionFigure);
        general_imageDisplay(app,app.extWindow.axes,backgroundImage);
        if app.showMagVector.Value
            overlayMagnetization(app,app.extWindow.axes);    
        end
        overlayVertexType(app,app.extWindow.axes);
        close(alterDialog);
    end
end