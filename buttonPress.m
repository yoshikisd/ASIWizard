% Executes various tasks when a button is pressed in the ASIWizard UI
function buttonPress(app,trigger)
    try
        switch trigger
            % Buttons in app.Tab_Import
            case 'next_ImportImgProcess'; next_ImportImgProcess;
            case 'browse_DetectionResult'; browse_DetectionResult;
            case 'browse_MagneticImage'; browse_MagneticImage;
            % Buttons in app.Tab_CleanUp
            case 'next_CleanUp'; next_CleanUp;
            case 'back_CleanUp'; back_CleanUp;
            case 'select_RemovePts'; select_RemovePts;
            case 'select_AddPts'; select_AddPts;  
            % Buttons in app.Tab_NeighborScan
            case 'next_Nbr'; next_Nbr;
            case 'back_Nbr'; back_Nbr;
            case 'preview_Magnet'; preview_Magnet;
            case 'preview_ScanArea'; preview_ScanArea;
            case 'detection_Nbr'; detection_Nbr;
            % Buttons in app.Tab_LatticeIndexing
            case 'next_LatticeIdx'; next_LatticeIdx;
            case 'back_LatticeIdx'; back_LatticeIdx;
            case 'select_LatticeOrigin'; select_LatticeOrigin;
            % Buttons in app.Tab_MapMagnet
            case 'next_MapMagnet'; next_MapMagnet;
            case 'back_MapMagnet'; back_MapMagnet;
            case 'select_BackgroundArea'; select_BackgroundArea;
            case 'update_TrinaryContrast'; update_TrinaryContrast;
            % Buttons in app.Tab_FinalInspection
            case 'next_FinalInspect'; next_FinalInspect;
            case 'back_FinalInspect'; back_FinalInspect;
            case 'show_STDHistogram'; show_STDHistogram;
            case 'show_nonIsing'; show_nonIsing;
            case 'show_Ising'; show_Ising;
            case 'show_zeroizeIsing'; show_zeroizeIsing;
            case 'modify_ZeroMoment'; modify_ZeroMoment;
            case 'modify_MarkIsing'; modify_MarkIsing;
            case 'modify_MarkCST'; modify_MarkCST;
            case 'modify_RemoveMagnet'; modify_RemoveMagnet;
            case 'modify_FlipSpin'; modify_FlipSpin;
            case 'modify_UndoAll'; modify_UndoAll;
            case 'next_PostProcess'; next_PostProcess;
            case 'back_PostProcess'; back_PostProcess;
            case 'next_Finish'; next_Finish;
        end
    catch ME; errorNotice(app,ME); return;
    end


    %% Buttons in app.Tab_Import
    % 'Next >' button is pressed
    function next_ImportImgProcess
        switch app.processedBefore.Value
            case 'No'
                % Make xas grid have 5 dimensions (in case it hasn't already been done.
                app.vd.xasGrid(:,:,5) = 0;
                % Save a variable xasOld
                app.vd.xasOld = app.vd.xasGrid;
                % Extract the locations of the detected vertex clusters in minLoc
                [app.vd.minLocJ,app.vd.minLocI] = find(app.vd.xasGrid(:,:,3) ~= 0);
                app.vd.minLoc = [app.vd.minLocJ,app.vd.minLocI,zeros(length(app.vd.minLocI),2)];
                for i = 1:length(app.vd.minLoc)
                    % Store intensity
                    app.vd.minLoc(i,3) = app.vd.xasGrid(app.vd.minLoc(i,1),app.vd.minLoc(i,2),3);
                    % Store which reference image was utilized for detection
                    app.vd.minLoc(i,4) = app.vd.xasGrid(app.vd.minLoc(i,1),app.vd.minLoc(i,2),2);
                end
                % Save an old version of minLoc
                app.vd.minLocOld = app.vd.minLoc;
                % Initialize matrices to capture ROI images that will be acquired later in the analysis process.
                app.vd.magnetMask = zeros(app.vd.gridHeight,app.vd.gridWidth);
                app.vd.magnetInterpretReg = app.vd.magnetMask;
                app.vd.magnetInterpretCombined = app.vd.magnetMask;
                app.vd.magnetEntropy = app.vd.magnetMask;
                % Additional values to initialize for later use in the analysis
                app.vd.thetaRange = linspace(0,2*pi,100);   
                % Move to the clean-up step
                app.TabGroup_ImgProcess.SelectedTab = app.Tab_CleanUp;
                app.arrow_import.Visible = 0;
                app.steps_import.Enable = 0;
                app.arrow_cleanUp.Visible = 1;
                app.steps_cleanUp.Enable = 1;
            case 'Yes'
                % Go to the select step option tab
                app.TabGroup_ImgProcess.SelectedTab = app.Tab_Reprocess;
        end

    end
    % 'Browse' button is pressed
    function browse_DetectionResult
        % Open dialogue for importing vertex detection data
        oldDirImages = app.dirImages;
        [app.FileName,app.dirImages] = uigetfile({'*.mat'},'Select vertex detection *.mat file',app.dirImages);
        if ~ischar(app.FileName)
            app.dirImages = oldDirImages;
            return;
        end
        % Load the file
        app.vd = load(fullfile(app.dirImages,app.FileName));
        % Show path to the EMD file
        app.Field_detectionPath.Value = sprintf('%s%s',app.dirImages,app.FileName);
    end
    % 'Browse' button is pressed
    function browse_MagneticImage
        % Open dialogue for importing XMCD image
        oldDirImages = app.dirImages;
        % Processing depends on whether or not the image was acquired at PEEM3/PEEMViewer or Park XEI
        switch app.contrastMode.Value
            case 'XMCD-PEEM'
                [FileName,app.dirImages] = uigetfile({'*.tif';'*.tiff'},'Select XMCD-PEEM image',app.dirImages);
                if ~ischar(FileName)
                    app.dirImages = oldDirImages;
                    return;
                end
                % Import xmcd raw xmcd image
                app.vd.xmcd = double(imread(fullfile(app.dirImages,FileName))); 
            case 'MFM'
                [FileName,app.dirImages] = uigetfile({'*.png';'*.tif';'*.tiff'},'Select MFM image',app.dirImages);
                if ~ischar(FileName)
                    app.dirImages = oldDirImages;
                    return;
                end
                % Import xmcd raw xmcd image
                app.vd.xmcd = double(imread(fullfile(app.dirImages,FileName))); 
        end
        % Duplicate xmcd image for viewing
        app.vd.xmcdOriginal = app.vd.xmcd;
        % Show the initial asymmetry image
        app.vd.xmcdBoost = imadjust(mat2gray(app.vd.xmcd,[-double(max(app.vd.xmcd,[],'all')/2),double(max(app.vd.xmcd,[],'all')/2)])...
            ,[0.4,0.6],[],0.5);
        %general_imageDisplay(app,app.AxesImportMagneticContrast,mat2gray(app.vd.xmcd));
        general_imageDisplay(app,app.extWindow.axes,mat2gray(app.vd.xmcd));
        % Save a binarized image (really a trinary image)
        % For background subtraction, we first bin the intensities into
        % 50 bins, then take the mode (assuming most frequent intensity is "gray")
        app.vd.xmcdTrinary = floor(mat2gray(app.vd.xmcd)*50);
        binMode = mode(app.vd.xmcdTrinary,'all');
        binSTD = std(app.vd.xmcdTrinary,0,'all');
        app.vd.xmcdTrinary(app.vd.xmcdTrinary < binMode - binSTD/2) = -1;
        app.vd.xmcdTrinary(app.vd.xmcdTrinary > binMode + binSTD/2) = 1;
        app.vd.xmcdTrinary(abs(app.vd.xmcdTrinary) ~= 1) = 0;
        app.vd.xmcdCorrectedTrinary = app.vd.xmcdTrinary; % Initially define the corrected trinary to the original trinary.
        % Show path to the magnetic contrast image file
        app.Field_magImagePath.Value = sprintf('%s%s',app.dirImages,FileName);
    end
    
    %% Buttons in app.Tab_CleanUp
    % 'Next >' button is pressed
    function next_CleanUp
        % Once the user is happy with the vertex layout, then several variables will be initialized for use in the analysis
        % TrueMinLoc is now Vertex
        % First, reset vertex
        if isfield(app.vd,'vertex') == 1
            app.vd = rmfield(app.vd,'vertex');
        end
        % Initialize trueMinLoc as a structure and import minLoc values
        app.vd.vertex(1).type = [];                             % (5) Vertex type
        app.vd.vertex(1).charge = [];                           %     Vertex charge state
        app.vd.vertex(1).nbrVertexInd = [];                     % (6-9) Index of neighboring vertices
        app.vd.vertex(1).nbrMagnetInd = [];                     % (10-13) Index of neighboring magnets in magnet
        app.vd.vertex(1).rowYPos = [];     
        app.vd.vertex(1).colXPos = []; 
        % First, make sure that EACH X-Y PAIR IN MINLOC IS UNIQUE!!!
        j = 1;
        for i = 1:length(app.vd.minLoc)
            if app.vd.minLoc(i,4) ~= 0
                if ~isempty(app.vd.vertex(1).rowYPos)
                    j = j + 1;
                end
                app.vd.vertex(j).rowYPos = app.vd.minLoc(i,1);      % Row position / y-position of colXPos
                app.vd.vertex(j).colXPos = app.vd.minLoc(i,2);      % Column position / x-position of vertex
                app.vd.vertex(j).topInt = app.vd.minLoc(i,3);       % (3) Topographical intensity
                app.vd.vertex(j).refImg = app.vd.minLoc(i,4);       % (4) Index of the reference image that detected this vertex
            end
        end
        app.vd.vertexOld = app.vd.vertex;
        % Initialize iceMagnets as a structure
        % IceMagnets is now magnet
        initializeMagnet(app);
        app.vd.oldMagnet = app.vd.magnet;
        % Within structure vd, create substructure app.vd.postProcessFlag.* to indicate what items to generate for postprocessing
        app.TabGroup_ImgProcess.SelectedTab = app.Tab_NeighborScan;
        app.arrow_nbrScan.Visible = 1;
        app.steps_nbrScan.Enable = 1;
        app.arrow_cleanUp.Visible = 0;
        app.steps_cleanUp.Enable = 0;
        
        % Make sure the irrelevant options in the "Neighbor Scan" tab are disabled
        switch app.vd.typeASI
            case 'Kagome'
                app.scanDiameter.Enable = 1;
                app.scanCross1Angle.Enable = 0;
                app.scanCross2Angle.Enable = 0;
                app.scanCross1Height.Enable = 0;
                app.scanCross2Height.Enable = 0;
                app.scanCross1Width.Enable = 0;
                app.scanCross2Width.Enable = 0;
            case {'Square','Brickwork','Tetris'}
                app.scanDiameter.Enable = 0;
                app.scanCross1Angle.Enable = 1;
                app.scanCross2Angle.Enable = 1;
                app.scanCross1Height.Enable = 1;
                app.scanCross2Height.Enable = 1;
                app.scanCross1Width.Enable = 1;
                app.scanCross2Width.Enable = 1;
        end

    end
    % '< Back' button is pressed
    function back_CleanUp
        app.TabGroup_ImgProcess.SelectedTab = app.Tab_Import;
        app.arrow_import.Visible = 1;
        app.steps_import.Enable = 1;
        app.arrow_cleanUp.Visible = 0;
        app.steps_cleanUp.Enable = 0;
    end
    % 'Select' button is pressed to remove points
    function select_RemovePts
        %%%%%%%%%% Manual removal of garbage points %%%%%%%%%%
        % Show the analysis window
        %app.TabGroupAnalysis.SelectedTab = app.AnalysisTab;
        app.extWindow.axes.XLim = [0 app.vd.gridHeight];
        app.extWindow.axes.YLim = [0 app.vd.gridWidth];
        deletionFigure = figure('Name','Select vertices to delete');
        deletionFigure.MenuBar = 'none';
        deletionFigure.ToolBar = 'none';
        deletionAxes = axes(deletionFigure);
        movegui(deletionFigure,'center');
        vertexPlot(app,deletionAxes)
        set(deletionAxes,'position',[0 0 1 1],'units','normalized');
        % Display message box indicating to user the operation of the point removal/adder step
        removalDialog = uiprogressdlg(app.IceScannerUI,'Title','Please view the pop-up figure window','Message',...
            strcat('In the pop-up figure window, click near the existing vertex detection points you wish to remove. To undo the last',...
            ' selection, press the delete/backspace key. You may also resize this window. Once you are done, press the enter key. For this to',...
            ' work, the last object you click must be somewhere within the analysis window.'),...
            'Indeterminate','on');
        % Deletion script
        try
            [iRemove, jRemove] = getpts(deletionAxes);
            jRemove = floor(jRemove);
            iRemove = floor(iRemove);
            for i = 1:length(jRemove)
                app.vd.xasGrid(jRemove(i)-10:jRemove(i)+10,iRemove(i)-10:iRemove(i)+10,4) = 0;
            end
        catch ME; close(deletionFigure); close(removalDialog); return;
        end
        close(deletionFigure);
        close(removalDialog);
        minLocator(app);
        vertexPlot(app,app.extWindow.axes);

    end
    % 'Select' button is pressed to add points
    function select_AddPts
        %%%%%%%%%% Manual addition of vertex points %%%%%%%%%%
        app.extWindow.axes.XLim = [0 app.vd.gridHeight];
        app.extWindow.axes.YLim = [0 app.vd.gridWidth];
        switch app.vd.typeASI
            case {'Square','Kagome','Tetris'}
                removalDialog = uiprogressdlg(app.IceScannerUI,'Title','Please view the pop-up figure window','Message',...
                    strcat('In the pop-up figure window, click the points where you would like to add a vertex. To undo the last selection, ',...
                    'press the delete/backspace key. Once you are done, press the enter key. For this to work, the last object you click ',...
                    'must be somewhere within the analysis window.'),'Indeterminate','on');
                [iAdd, jAdd] = additionPlotter(app);
                jAdd = floor(jAdd);
                iAdd = floor(iAdd);
                for i = 1:length(jAdd)
                    app.vd.xasGrid(jAdd(i),iAdd(i),4) = 1;
                    app.vd.xasGrid(jAdd(i),iAdd(i),2) = 1;
                end 
            case 'Brickwork'
                removalDialog = uiprogressdlg(app.IceScannerUI,'Title','Please view the pop-up figure window','Message',...
                    strcat('In the pop-up figure window, click the points where you would like to add a vertex associated with the FIRST ',...
                    ' reference frame (BLUE PLUS). To undo the last selection, press the delete/backspace key. Once you are done, press the ',...
                    'enter key. For this to work, the last object you click must be somewhere within the analysis window.'),...
                    'Indeterminate','on');
                [iAdd, jAdd] = additionPlotter(app);
                jAdd = floor(jAdd);
                iAdd = floor(iAdd);
                for i = 1:length(jAdd)
                    app.vd.xasGrid(jAdd(i),iAdd(i),4) = 1;
                    app.vd.xasGrid(jAdd(i),iAdd(i),2) = 1; %#ok<*SAGROW>
                end 
                minLocator(app);
                close(removalDialog);
                pause(1);
                removalDialog = uiprogressdlg(app.IceScannerUI,'Title','Please view the pop-up figure window','Message',...
                    strcat('In the pop-up figure window, click the points where you would like to add a vertex associated with the SECOND ',...
                    ' reference frame (GREEN X). To undo the last selection, press the delete/backspace key. Once you are done, press the ',...
                    'enter key. For this to work, the last object you click must be somewhere within the analysis window.'),...
                    'Indeterminate','on');
                [iAdd, jAdd] = additionPlotter(app);
                jAdd = floor(jAdd);
                iAdd = floor(iAdd);
                for i = 1:length(jAdd)
                    app.vd.xasGrid(jAdd(i),iAdd(i),4) = 1;
                    app.vd.xasGrid(jAdd(i),iAdd(i),2) = 2; %#ok<*SAGROW>
                end
                pause(1);
        end
        close(removalDialog);
        minLocator(app);
        vertexPlot(app,app.extWindow.axes);
    end

    %% Buttons in app.Tab_NeighborScan
    % 'Next >' button is pressed
    function next_Nbr
        %app.TabGroup_ImgProcess.SelectedTab = app.Tab_MapMagnet;
        %app.arrow_magRead.Visible = 1;
        %app.steps_magRead.Enable = 1;
        app.TabGroup_ImgProcess.SelectedTab = app.Tab_LatticeIndexing;
        app.arrow_latticeIdx.Visible = 1;
        app.steps_latticeIdx.Enable = 1;
        app.arrow_nbrScan.Visible = 0;
        app.steps_nbrScan.Enable = 0;
        
        % Change image in external window to the magnetic contrast
        general_imageDisplay(app,app.extWindow.axes,mat2gray(app.vd.xmcd));
    end
    % '< Back' button is pressed
    function back_Nbr
        app.TabGroup_ImgProcess.SelectedTab = app.Tab_CleanUp;
        app.arrow_nbrScan.Visible = 0;
        app.steps_nbrScan.Enable = 0;
        app.arrow_cleanUp.Visible = 1;
        app.steps_cleanUp.Enable = 1;
        % Reset vertex and magnet
        app.vd = rmfield(app.vd,'vertex');
        app.vd = rmfield(app.vd,'magnet');
    end
    % 'Preview magnet' button is pressed
    function preview_Magnet
        % Show the topography image
        general_imageDisplay(app,app.extWindow.axes,mat2gray(app.vd.xasGrid(:,:,1)));
        delete(app.magnetROI);
        [imageWidth,imageHeight] = size(app.vd.xasGrid(:,:,1));
        app.magnetROI = drawrectangle(app.extWindow.axes,'Deletable',false,'FaceAlpha',0.1,...
            'InteractionsAllowed','translate','Rotatable',true,'MarkerSize',5,'Position',[round(imageHeight/2),...
            round(imageWidth/2),app.magnetWidth.Value,app.magnetHeight.Value]);
    end
    % 'Preview scan area' button is pressed
    function preview_ScanArea
        % Plot the preview of the scan area around the chosen vertex index
        % Show the topography image
        general_imageDisplay(app,app.extWindow.axes,mat2gray(app.vd.xasGrid(:,:,1)));
        hold(app.extWindow.axes,'on');
        vertex = app.vd.vertex;
        pointSelect = app.vd.pointSelect;
        switch app.vd.typeASI
            case {'Square', 'Brickwork','Tetris'}
                % Variable duplication
                cross1Width = app.scanCross1Width.Value;
                cross1Height = app.scanCross1Height.Value;
                cross1Angle = app.scanCross1Angle.Value;
                cross2Width = app.scanCross2Width.Value;
                cross2Height = app.scanCross2Height.Value;
                cross2Angle = app.scanCross2Angle.Value;
                cross1PerimeterX = cross1Width * [-1:0.02:1,ones(1,length(-1:0.02:1)),1:-0.02:-1,-ones(1,length(-1:0.02:1))];
                cross1PerimeterY = cross1Height * [ones(1,length(-1:0.02:1)),1:-0.02:-1,-ones(1,length(-1:0.02:1)),-1:0.02:1];
                cross1AreaScanX = cosd(-cross1Angle)*cross1PerimeterX - sind(-cross1Angle)*cross1PerimeterY + ...
                    vertex(pointSelect).colXPos;
                cross1AreaScanY = sind(-cross1Angle)*cross1PerimeterX + cosd(-cross1Angle)*cross1PerimeterY + ...
                    vertex(pointSelect).rowYPos;
                cross1LocalArea = [cross1AreaScanX',cross1AreaScanY'];
                % Remove any portions of the circle that would exceed the edge
                cross1LocalArea(cross1LocalArea(:,1) < 1 | cross1LocalArea(:,1) > app.vd.gridWidth) = NaN;
                cross1LocalArea(cross1LocalArea(:,2) < 1 | cross1LocalArea(:,2) > app.vd.gridHeight) = NaN;
                cross1LocalArea(any(isnan(cross1LocalArea),2) == 1,:) = [];
                cross2PerimeterX = cross2Width * [-1:0.02:1,ones(1,length(-1:0.02:1)),1:-0.02:-1,-ones(1,length(-1:0.02:1))];
                cross2PerimeterY = cross2Height * [ones(1,length(-1:0.02:1)),1:-0.02:-1,-ones(1,length(-1:0.02:1)),-1:0.02:1];
                cross2AreaScanX = cosd(-cross2Angle)*cross2PerimeterX - sind(-cross2Angle)*cross2PerimeterY + ...
                    vertex(pointSelect).colXPos;
                cross2AreaScanY = sind(-cross2Angle)*cross2PerimeterX + cosd(-cross2Angle)*cross2PerimeterY + ...
                    vertex(pointSelect).rowYPos;
                cross2LocalArea = [cross2AreaScanX',cross2AreaScanY'];
                % Remove any portions of the circle that would exceed the edge
                cross2LocalArea(cross2LocalArea(:,1) < 1 | cross2LocalArea(:,1) > app.vd.gridWidth) = NaN;
                cross2LocalArea(cross2LocalArea(:,2) < 1 | cross2LocalArea(:,2) > app.vd.gridHeight) = NaN;
                cross2LocalArea(any(isnan(cross2LocalArea),2) == 1,:) = [];
                localArea = [cross1LocalArea;cross2LocalArea];
                app.vd.cross1PerimeterX = cross1PerimeterX;
                app.vd.cross1PerimeterY = cross1PerimeterY;
                app.vd.cross2PerimeterX = cross2PerimeterX;
                app.vd.cross2PerimeterY = cross2PerimeterY;
            case 'Kagome'
                areaScanX = app.scanDiameter.Value*cos(app.vd.thetaRange) + vertex(pointSelect).colXPos;
                areaScanY = app.scanDiameter.Value*sin(app.vd.thetaRange) + vertex(pointSelect).rowYPos;
                localArea = [areaScanX',areaScanY']; 
        end
        
        % Remove any portions of the scan area that would exceed the edge
        localArea(localArea(:,1) < 1 | localArea(:,1) > app.vd.gridWidth) = NaN;
        localArea(localArea(:,2) < 1 | localArea(:,2) > app.vd.gridHeight) = NaN;
        localArea(any(isnan(localArea),2) == 1,:) = [];
        % Plot
        switch app.vd.typeASI
            case {'Square', 'Brickwork','Tetris'}
                plot(app.extWindow.axes,cross1LocalArea(:,1),cross1LocalArea(:,2));
                plot(app.extWindow.axes,cross2LocalArea(:,1),cross2LocalArea(:,2));
            case 'Kagome'
                plot(app.extWindow.axes,localArea(:,1),localArea(:,2));
        end
        xPos = vertex(pointSelect).colXPos;
        yPos = vertex(pointSelect).rowYPos;
        plot(app.extWindow.axes,xPos,yPos,'b.','MarkerSize',20);
        plot(app.extWindow.axes,vertcat(app.vd.vertex.colXPos),vertcat(app.vd.vertex.rowYPos),...
            'g.');
        hold(app.extWindow.axes,'off');
        % Enable the neighbor detection button if it is currently disabled
        if app.ButtonNeighborDetect.Enable == 0
            app.ButtonNeighborDetect.Enable = 1;
        end
    end
    % 'Neighbor detection' button is pressed
    function detection_Nbr
        % Set brickmode (regardless of the imaging type)
        app.vd.brickMode = app.brickMode.Value;
        % Scan for neighboring vertices
        % First create a waitbar to get an idea of where we're at
        f = uiprogressdlg(app.IceScannerUI,'Title','Neighbor search','Message',...
            'Searching for neighboring vertices, assigning magnet positions, and reading magnetizations.');
        % Reset vertex
        app.vd = rmfield(app.vd,'vertex');
        app.vd.vertex = app.vd.vertexOld;
        
        % Reset magnet
        app.vd = rmfield(app.vd,'magnet');
        app.vd.magnet = app.vd.oldMagnet;
        % Clear and initialize magnet
        initializeMagnet(app)
        
        % Variable duplication
        trueMinXPos = vertcat(app.vd.vertex.colXPos);
        trueMinYPos = vertcat(app.vd.vertex.rowYPos);
        thetaRange = app.vd.thetaRange;   
        switch app.vd.typeASI
            case {'Square','Brickwork','Tetris'}
                diameter = 0;
                cross1Angle = app.scanCross1Angle.Value;
                cross2Angle = app.scanCross2Angle.Value;
                cross1PerimeterX = app.vd.cross1PerimeterX;
                cross1PerimeterY = app.vd.cross1PerimeterY;
                cross2PerimeterX = app.vd.cross2PerimeterX;
                cross2PerimeterY = app.vd.cross2PerimeterY;
            case 'Kagome'
                diameter = app.scanDiameter.Value;
                cross1Angle = 0;
                cross2Angle = 0;
                cross1PerimeterX = 0;
                cross1PerimeterY = 0;
                cross2PerimeterX = 0;
                cross2PerimeterY = 0;
        end
        
        % Conduct area scan to search for nearest neighboring vertices
        for currIndVtx = 1:length(app.vd.vertex)
            f.Value = currIndVtx/length(app.vd.vertex);
            % First, locate the neighboring vertices
            neighborVertexLocator(app,currIndVtx,cross1Angle,cross1PerimeterX,cross1PerimeterY,cross2Angle,...
                cross2PerimeterX,cross2PerimeterY,trueMinXPos,trueMinYPos,thetaRange,diameter);
            
            % Second, define/locate magnets between vertices
            magnetScanFilter(app,currIndVtx); % This seems like it's adding additional entries into nbrMagnetInd...
        end
        close(f);
        % Once the analysis has been completed, plot the results
       
        % First, show the analysis window with the XMCD image
        general_imageDisplay(app,app.extWindow.axes,mat2gray(app.vd.xasGrid(:,:,1)));
        hold(app.extWindow.axes,'on')
        plot(app.extWindow.axes,vertcat(app.vd.magnet.colXPos),vertcat(app.vd.magnet.rowYPos),'rs');
        plot(app.extWindow.axes,vertcat(app.vd.vertex.colXPos),vertcat(app.vd.vertex.rowYPos),'g.');
        pause(1);
       
        uialert(app.IceScannerUI,'Calculated magnet positions are shown in the external window with red squares.',...
            'Ready for previewing','Icon','success');
        % Enable the next button if it is currently disabled
        if app.next_nbrScan.Enable == 0
            app.next_nbrScan.Enable = 1;
        end
    end

    %% Buttons in app.Tab_LatticeIndexing
    % 'Next >' button is pressed
    function next_LatticeIdx
        % For this reference magnet (0,0), determine the start and end vertices to calculate the reference vector for magnet00
        % First, set magnet00 to be equal to app.vd.magnet00
        magnet00 = app.vd.magnet00;
        % MAKE SURE YOU SELECT A TYPE 3 MAGNET FIRST "\"
        if app.vd.vertex(app.vd.magnet(magnet00).nbrVertexInd(1)).colXPos > app.vd.magnet(magnet00).colXPos % If the vertex lies to the right of magnet00
            vertexMagEnd = app.vd.magnet(magnet00).nbrVertexInd(1);
            vertexMagStart = app.vd.magnet(magnet00).nbrVertexInd(2); 
        else
            vertexMagEnd = app.vd.magnet(magnet00).nbrVertexInd(2);
            vertexMagStart = app.vd.magnet(magnet00).nbrVertexInd(1);
        end
        % Look for the magnets neighboring magnet00's "end" vertex
        magNeigh = app.vd.vertex(vertexMagEnd).nbrMagnetInd;
        % Remove magnets that are null or includes the reference magnet
        magNeigh(magNeigh == 0 | magNeigh == magnet00) = [];
        % Maps the ASI magnets to a perfect lattice with corresponding lattice coordinates
        switch app.vd.typeASI
            case 'Kagome'
                kagomeMapper(app,magNeigh,vertexMagStart,vertexMagEnd,magnet00);
            case {'Square','Tetris'}
                squareMapper(app,magNeigh,vertexMagStart,vertexMagEnd,magnet00);
            case 'Brickwork'
                squareMapper(app,magNeigh,vertexMagStart,vertexMagEnd,magnet00);
        end
        % Rather than showing the full plot in the UI, create a high-resolution image from an invisible figure
        plotDialog = uiprogressdlg(app.IceScannerUI,'Title','Plotting lattice points','Message',...
            'Plotting the mapped lattice points with corresponding lattice coordinates.','Indeterminate','on');
        f = figure('visible','off','Position',[0,0,app.vd.gridWidth*2,app.vd.gridHeight*2]);
        ax1 = axes(f,'Position',[0,0,1,1],'Visible','off');
        hold(ax1,'on');
        imshow(mat2gray(app.vd.xasGrid(:,:,1)),'Parent',ax1);
        axis(ax1,'image');
        for magIndex = 1:length(app.vd.magnet)
            x = app.vd.magnet(magIndex).colXPos;
            y = app.vd.magnet(magIndex).rowYPos;
            a = app.vd.magnet(magIndex).aInd;
            b = app.vd.magnet(magIndex).bInd;
            plot(ax1,x,y,'r.','MarkerSize',20);
            text(ax1,x,y,sprintf('(%i,%i)',a,b),'FontSize',7,'Color','green');
        end
        hold(ax1,'off');
        f_img = frame2im(getframe(f));
        app.vd.latticeMap = f_img;
        close(f);
        close(plotDialog);
        % Plot the lattice points in the main window
        app.extWindow.axes.XLim = [0 app.vd.gridHeight*10];
        app.extWindow.axes.YLim = [0 app.vd.gridWidth*10];
        general_imageDisplay(app,app.extWindow.axes,f_img);
        axis(app.extWindow.axes,'image');
        % Show a uiconfirm if the program detects duplicate lattice coordinates
        latticePts = [horzcat(app.vd.magnet.aInd);horzcat(app.vd.magnet.bInd)];
        [~,~,pairIdx] = unique(latticePts','rows');
        numOccurences = accumarray(pairIdx,1);
        repeatPairIdx = find(numOccurences ~= 1);
        % Save a copy of the current app.vd.magnet state in case a magnetization is erroneously deleted
        determineSpinVectorComp(app);
        if length(repeatPairIdx) > 1
            duplicateDialog = uiconfirm(app.IceScannerUI,...
                sprintf('%d duplicate lattice points found.',length(repeatPairIdx)),...
                'Warning','Options',{'Go back','Proceed'},'Icon','warning');
            close(duplicateDialog);
            switch duplicateDialog.SelectedOption
                case 'Go back'
                    return;
            end
        end
        app.TabGroup_ImgProcess.SelectedTab = app.Tab_MapMagnet;
        app.arrow_magRead.Visible = 1;
        app.steps_magRead.Enable = 1;
        app.arrow_latticeIdx.Visible = 0;
        app.steps_latticeIdx.Enable = 0;
    end
    % '< Back' button is pressed
    function back_LatticeIdx
        app.TabGroup_ImgProcess.SelectedTab = app.Tab_NeighborScan;
        app.arrow_latticeIdx.Visible = 0;
        app.steps_latticeIdx.Enable = 0;
        app.arrow_nbrScan.Visible = 1;
        app.steps_nbrScan.Enable = 1;
    end
    % 'Select' button is pressed
    function select_LatticeOrigin
        % Lets the user select the reference magnet state used for performing lattice indexing.
        selectionFigure = figure('Name','Select reference magnet');
        selectionAxes = axes(selectionFigure);
        movegui(selectionFigure,'center');
        general_imageDisplay(app,selectionAxes,mat2gray(app.vd.xasGrid(:,:,1)));
        hold(selectionAxes,'on')
        plot(selectionAxes,vertcat(app.vd.magnet.colXPos),vertcat(app.vd.magnet.rowYPos),...
            'rs');
        plot(selectionAxes,vertcat(app.vd.vertex.colXPos),vertcat(app.vd.vertex.rowYPos),...
            'g.');
        set(selectionAxes,'position',[0 0 1 1],'units','normalized');
        hold(selectionAxes,'off')
        truesize(app.extWindow.figure);
        % Display message box indicating to user the operation of the point removal/adder step
        latticeDialog = uiprogressdlg(app.IceScannerUI,'Title','Please view the pop-up figure window','Message',...
            strcat('In the pop-up figure window, click near the center of the magnet you wish to choose as the reference magnet. ',...
            'To undo the last selection, press the delete/backspace key. Once you are done, press the enter key.',...
            'For this to work, the last object you click must be somewhere within the analysis window.'),...
            'Indeterminate','on');
        
        % Selection script
        try
            [colXRef, rowYRef] = getpts(selectionAxes);
            colXRef = floor(colXRef);
            rowYRef = floor(rowYRef);
        catch ME
            close(selectionFigure);
            close(latticeDialog);
            return;
        end
        close(selectionFigure);
        close(latticeDialog);
        % Initialize the magnet index that will reside at the origin of the generated lattice
        magnet00 = find((vertcat(app.vd.magnet.rowYPos) <= rowYRef + 10 & vertcat(app.vd.magnet.rowYPos) >= rowYRef - 10) &...
            vertcat(app.vd.magnet.colXPos) <= colXRef + 10 & vertcat(app.vd.magnet.colXPos) >= colXRef - 10);
        app.vd.magnet00 = magnet00;
        
        % Before doing anything else, initialize all index flags to be zero (old code work based on assumption that all index flags start as 0)
        for magIdx = 1:length(app.vd.magnet)
            app.vd.magnet(magIdx).indexFlag = 0;
        end
        
        % Initialize the origin state
        app.vd.magnet(magnet00).aInd = 0;
        app.vd.magnet(magnet00).bInd = 0;
        app.vd.magnet(magnet00).indexFlag = 2;
        switch app.vd.typeASI
            case 'Kagome'
                app.vd.magnet(magnet00).orient = 1;
                app.vd.magnet(magnet00).forkType = 1;
            case {'Brickwork','Square','Tetris'}
                app.vd.magnet(magnet00).orient = 3;
                app.vd.magnet(magnet00).forkType = 0;
        end
        
        % Plot the first lattice point
        %app.TabGroupAnalysis.SelectedTab = app.AnalysisTab;
        app.extWindow.axes.XLim = [0 app.vd.gridHeight];
        app.extWindow.axes.YLim = [0 app.vd.gridWidth];
        general_imageDisplay(app,app.extWindow.axes,mat2gray(app.vd.xasGrid(:,:,1)));
        
        hold(app.extWindow.axes,'on');
        plot(app.extWindow.axes,app.vd.magnet(magnet00).colXPos,app.vd.magnet(magnet00).rowYPos,'r.','MarkerSize',10);
        text(app.extWindow.axes,app.vd.magnet(magnet00).colXPos,app.vd.magnet(magnet00).rowYPos,...
            sprintf('(%i,%i)',app.vd.magnet(magnet00).aInd,app.vd.magnet(magnet00).bInd),'Color','r')
        
        % Enable mapping button
        app.next_latticeIdx.Enable = 1;
    end

    %% Buttons in app.Tab_MapMagnet
    % 'Next >' button is pressed
    function next_MapMagnet
        % Map magnetizations
        magnetizationDetect(app);
        % Perform vertex type assignment
        f = uiprogressdlg(app.IceScannerUI,'Title','Classifying vertices');
        for currIndVtx = 1:length(app.vd.vertex)
            f.Value = currIndVtx/length(app.vd.vertex);
            vertexTypeAssignment(app,currIndVtx);
        end
        close(f);
        % Plot magnetizations
        general_imageDisplay(app,app.extWindow.axes,mat2gray(app.vd.xmcdCorrectedTrinary));
        overlayVertexType(app,app.extWindow.axes);
        overlayMagnetization(app,app.extWindow.axes,'off');
        % Save current state of magnet as oldmagnet
        app.vd.oldMagnet = app.vd.magnet;
        app.TabGroup_ImgProcess.SelectedTab = app.Tab_Finalinspection;
        app.arrow_finalInspect.Visible = 1;
        app.steps_finalInspect.Enable = 1;
        app.arrow_magRead.Visible = 0;
        app.steps_magRead.Enable = 0;
    end
    % '< Back' button is pressed
    function back_MapMagnet
        app.TabGroup_ImgProcess.SelectedTab = app.Tab_LatticeIndexing;
        app.arrow_latticeIdx.Visible = 1;
        app.steps_latticeIdx.Enable = 1;
        app.arrow_magRead.Visible = 0;
        app.steps_magRead.Enable = 0;
    end
    % 'Select background area' button is pressed
    function select_BackgroundArea
        dialog = uiprogressdlg(app.IceScannerUI,'Title','Please view the pop-up figure window','Message',...
            strcat('In the pop-up figure window, create a ROI polygon by clicking the image to define the polygon vertices.',...
            ' Click the first point you created to close the polygon. The vertices and the entire polygon can be dragged around.',...
            ' To delete the polygon, press backspace or delete. When you are done, right-click the polygon and select Create Mask from the context menu.'),...
            'Indeterminate','on');
        % Shows rectangular ROI for selecting the background region
        % From https://www.mathworks.com/matlabcentral/answers/328980-how-to-crop-a-square-that-has-a-rotational-angle
        tempFigure = figure("Name",'Select background ROI');
        app.vd.background.ROI = roipoly(mat2gray(app.vd.xmcd));
        S = regionprops(app.vd.background.ROI,'ConvexImage','BoundingBox');
        % Define a box which encapsualtes the ROI. Then take the image of
        % app.vd.xmcd inside this box
        Q = app.vd.xmcd(round(S.BoundingBox(2))+(1:S.BoundingBox(4)),...
            round(S.BoundingBox(1))+(1:S.BoundingBox(3)));
        % Set all pixels outside of the ROI in Q to be NaN
        Q(S.ConvexImage == 0) = NaN;
        % Close the temporary ROI capturing figure
        close(tempFigure);
        % Extract relevant statistics
        app.vd.background.mean = mean(Q,'all','omitnan');
        app.vd.background.mode = mode(Q,'all');
        app.vd.background.stdev = std(Q,0,'all','omitnan');
        app.vd.background.min = min(Q,[],'all','omitnan');
        app.vd.background.max = max(Q,[],'all','omitnan');
        % Update statistics on UI
        app.label_backgroundMean.Text = sprintf("%-01.4f",app.vd.background.mean);
        app.label_backgroundMode.Text = sprintf("%-01.4f",app.vd.background.mode);
        app.label_backgroundMin.Text = sprintf("%-01.4f",app.vd.background.min);
        app.label_backgroundMax.Text = sprintf("%-01.4f",app.vd.background.max);
        app.label_backgroundSTDEV.Text = sprintf("%-01.4f",app.vd.background.stdev);
        % Update upper and lower limits on trinary contrast property
        app.field_backgroundUpper.Value = app.vd.background.max;
        app.field_backgroundLower.Value = app.vd.background.min;
        close(dialog);
    end
    % 'Update trinary contrast' button is pressed
    function update_TrinaryContrast
        app.vd.xmcdCorrectedTrinary = app.vd.xmcd;
        if app.option_meanSTDEV.Value == 1 %'Mean ± n*STDEV'
            n_bkg = app.field_nSTDEV.Value;
            mean_bkg = app.vd.background.mean;
            stdev_bkg = app.vd.background.stdev;
            % Set everything below lower threshold to -1
            app.vd.xmcdCorrectedTrinary(app.vd.xmcdCorrectedTrinary <= (mean_bkg - n_bkg*stdev_bkg))...
                = -1;
            % Set everything above upper threshold to +1
            app.vd.xmcdCorrectedTrinary(app.vd.xmcdCorrectedTrinary >= (mean_bkg + n_bkg*stdev_bkg))...
                = 1;
            % Set everything that is neither +- 1 to zero
            app.vd.xmcdCorrectedTrinary(abs(app.vd.xmcdCorrectedTrinary)~=1) = 0;
        elseif app.option_ULLimit.Value == 1 %'Upper/lower limits'
            upperLim = app.field_backgroundUpper.Value;
            lowerLim = app.field_backgroundLower.Value;
            % Set everything below lower threshold to -1
            app.vd.xmcdCorrectedTrinary(app.vd.xmcdCorrectedTrinary <= lowerLim)...
                = -1;
            % Set everything above upper threshold to +1
            app.vd.xmcdCorrectedTrinary(app.vd.xmcdCorrectedTrinary >= upperLim)...
                = 1;
            % Set everything that is neither +- 1 to zero
            app.vd.xmcdCorrectedTrinary(abs(app.vd.xmcdCorrectedTrinary)~=1) = 0;
        elseif app.option_Original.Value == 1 % Assuming the intensity mode is the background (calculated in line 864)
            app.vd.xmcdCorrectedTrinary = app.vd.xmcdTrinary;
        end
        
        % Update the image in the external window
        general_imageDisplay(app,app.extWindow.axes,mat2gray(app.vd.xmcdCorrectedTrinary));
    end

    %% Buttons in app.Tab_FinalInspection
    % 'Next >' button is pressed
    function next_FinalInspect
        %%%%%%%%%% Move to the next tab and determine spin vector components for magnetic structure factor and correlation length %%%%%%%%%%
        app.TabGroup_ImgProcess.SelectedTab = app.Tab_Postprocessing;
        app.arrow_finalInspect.Visible = 0;
        app.steps_finalInspect.Enable = 0;
        app.arrow_postProcess.Visible = 1;
        app.steps_postProcess.Enable = 1;
    end
    % '< Back' button is pressed
    function back_FinalInspect
        app.TabGroup_ImgProcess.SelectedTab = app.Tab_MapMagnet;
        app.arrow_finalInspect.Visible = 0;
        app.steps_finalInspect.Enable = 0;
        app.arrow_magRead.Visible = 1;
        app.steps_magRead.Enable = 1;
    end
    % 'Show standard deviation histogram' button is pressed
    function show_STDHistogram
        % Shows a histogram containing the standard deviation of trinarized intensity throughout
        % the nanomagnet ROI
        figure();
        hold on;
        histogram(vertcat(app.vd.magnet.xmcdSTD));
        title('STD of trinarized pixel intensity within magnet ROI');
        xlabel('Standard deviation');
        ylabel('Counts');
        hold off;
    end
    % Alter magnetic state buttons
    function show_nonIsing
        alterMagnet(app,'displayNonIsing');
    end
    function show_Ising
        alterMagnet(app,'displayIsing');
    end
    function show_zeroizeIsing
        alterMagnet(app,'autoZeroize');
    end
    function modify_ZeroMoment
        alterMagnet(app,'zeroize');
    end
    function modify_MarkIsing
        alterMagnet(app,'makeIsing');
    end
    function modify_MarkCST
        alterMagnet(app,convertCharsToStrings(app.drop_CST.Value));
    end
    function modify_RemoveMagnet
        alterMagnet(app,'ignore');
    end
    function modify_FlipSpin
        alterMagnet(app,'flip');
    end
    function modify_UndoAll
        %%%%%%%%%% Reverses any deletion of the magnetization %%%%%%%%%%
        app.vd.magnet = app.vd.oldMagnet;
        %app.TabGroupAnalysis.SelectedTab = app.AnalysisTab;
        general_imageDisplay(app,app.extWindow.axes,mat2gray(app.vd.xmcd));
        overlayMagnetization(app,app.extWindow.axes);
        overlayVertexType(app,app.extWindow.axes,'off');
        uialert(app.IceScannerUI,'Magnetization data restored.','Undo all','Icon','success');
    end
    
    %% Buttons in app.Tab_Postprocessing
    % 'Next >' button is pressed
    function next_PostProcess
        % Generates all requested postprocessing material
        % First, ask user where to save the files to
        oldDirImages = app.dirImages;
        [FileName,app.dirImages] = uiputfile(strcat(app.dirImages,'*.mat'),'PostProcessing data file');
        if ~ischar(FileName)
            app.dirImages = oldDirImages;
            return;
        end

        currentStatus = uiprogressdlg(app.IceScannerUI,'Title','Generating image','Message',...
                'Closing IceScanner external window (prevents subsequent figures from getting messed up).','Indeterminate','on');
        close(app.extWindow.figure);
        pause(2);
        close(currentStatus);
        % If MSF option was selected, make MSF plots
        if app.Check_CalcMSF.Value == 1
            if app.Radio_MSF_CalcEachPt.Value; method = 'full';
            elseif app.Radio_MSF_CalcInversion.Value; method = 'half'; end

            [app.vd.postProcess.MSF.map,app.vd.postProcess.MSF.mapExport] = generateMSF(...
                app,app.MSFSteps.Value,app.MSFStart.Value,...
                vertcat(app.vd.magnet.xSpin), vertcat(app.vd.magnet.ySpin),...
                vertcat(app.vd.magnet.xR), vertcat(app.vd.magnet.yR),...
                method,'asi','SaveTo',app.dirImages,'Table','on');
        end
        
        % If pair-wise correlation option was selected, calculate correlations
        if app.Check_CalcCorr.Value && (app.correlation_SpinDot.Value || app.correlation_DotBinary.Value ||...
                app.correlation_Magnetostatic.Value || app.correlation_localMap.Value)
            % First, determine the n-th neighbors for each magnet
            neighborIdxLocator(app);
            if app.correlation_localMap.Value
                % Calculate local spin-spin correlations
                correlationCalcLocal(app,app.dirImages);
            end
            % For each neighbor type, compile a list of index pairs to eliminate redundant index pairs
            removeRedundantNbrIdx(app);
            % Calculate global spin-spin correlations
            correlationCalcGlobal(app,app.dirImages);
        end
        

        % Plot vertex and magnetization detection results
        if app.Check_CalcRealSpace.Value
            % If the vertex count option was selected, plot the vertex statistics
            if app.VertexcountsCheckBox.Value == 1; exportVertexStatistics(app,app.dirImages); end
            
            % If the mapped lattice point option is selected, save app.vd.latticeMap
            if app.LatticecoordinatesCheckBox.Value == 1
                currentStatus = uiprogressdlg(app.IceScannerUI,'Title','Generating image','Message',...
                    'Generating topography image with superimposed lattice coordinates.','Indeterminate','on');
                imwrite(app.vd.latticeMap,sprintf('%sLattice coordinates.tif',app.dirImages),'tif',"Resolution",[10000,10000]);
            end
            
            % If the contrast + vertex type check box is selected, save that image
            if app.ContrastvertextypeCheckBox.Value == 1
                currentStatus = uiprogressdlg(app.IceScannerUI,'Title','Generating image','Message',...
                    'Generating contrast image with vertex types superimposed.','Indeterminate','on');
                [imgHeight,imgWidth,~] = size(mat2gray(app.vd.xmcd));
                f = figure('visible','off','Name','Magnetic Structure Factor', 'Position', [100,100,imgWidth,imgHeight]);
                ax1 = axes(f,'Visible','off','Position',[0,0,1,1],'units','normalized');
                axis image;
                imshow(mat2gray(mat2gray(app.vd.xmcd),[0.2,0.7]),'Parent',ax1);
                overlayVertexType(app,ax1);
                truesize(f);
                print(f,sprintf('%sContrast and vertex types.tif',app.dirImages),'-dtiffn','-r600');
                close(f);

                f = figure('visible','off','Name','Magnetic Structure Factor', 'Position', [100,100,imgWidth,imgHeight]);
                ax1 = axes(f,'Visible','off','Position',[0,0,1,1],'units','normalized');
                axis image;
                imshow(mat2gray(app.vd.xmcdTrinarySkeleton),'Parent',ax1);
                overlayVertexType(app,ax1);
                truesize(f);
                print(f,sprintf('%sContrast and vertex types trinary ROI.tif',app.dirImages),'-dtiffn','-r600');
                close(f);

                f = figure('visible','off','Name','Magnetic Structure Factor', 'Position', [100,100,imgWidth,imgHeight]);
                ax1 = axes(f,'Visible','off','Position',[0,0,1,1],'units','normalized');
                axis image;
                imshow(mat2gray(app.vd.magnetInterpretCombinedImg),'Parent',ax1);
                overlayVertexType(app,ax1);
                truesize(f);
                print(f,sprintf('%sContrast and vertex types averaged ROI.tif',app.dirImages),'-dtiffn','-r600');
                close(f);
                close(currentStatus);
            end
            
            % If the contrast + vertex type check box is selected, save that image
            if app.ContrastdetectedMCheckBox.Value == 1
                currentStatus = uiprogressdlg(app.IceScannerUI,'Title','Generating image','Message',...
                    'Generating contrast image with vertex types and detected magnetizations superimposed.','Indeterminate','on');
                [imgHeight,imgWidth,~] = size(mat2gray(app.vd.xmcd));
                f = figure('visible','off','Name','Magnetic Structure Factor', 'Position', [100,100,imgWidth,imgHeight]);
                ax1 = axes(f,'Visible','off','Position',[0,0,1,1],'units','normalized');
                axis image;
                imshow(mat2gray(mat2gray(app.vd.xmcd),[0.3,0.7]),'Parent',ax1);
                overlayVertexType(app,ax1);
                overlayMagnetization(app,ax1,'off');
                truesize(f);
                print(f,sprintf('%sContrast and magnetizations.tif',app.dirImages),'-dtiffn','-r600');
                close(f);

                f = figure('visible','off','Name','Magnetic Structure Factor', 'Position', [100,100,imgWidth,imgHeight]);
                ax1 = axes(f,'Visible','off','Position',[0,0,1,1],'units','normalized');
                axis image;
                imshow(mat2gray(app.vd.xmcdTrinarySkeleton),'Parent',ax1);
                overlayVertexType(app,ax1);
                overlayMagnetization(app,ax1,'off');
                truesize(f);
                print(f,sprintf('%sContrast and magnetizations trinary ROI.tif',app.dirImages),'-dtiffn','-r600');
                close(f);

                f = figure('visible','off','Name','Magnetic Structure Factor', 'Position', [100,100,imgWidth,imgHeight]);
                ax1 = axes(f,'Visible','off','Position',[0,0,1,1],'units','normalized');
                axis image;
                imshow(mat2gray(app.vd.magnetInterpretCombinedImg),'Parent',ax1);
                overlayVertexType(app,ax1);
                overlayMagnetization(app,ax1,'off');
                truesize(f);
                print(f,sprintf('%sContrast and magnetizations averaged ROI.tif',app.dirImages),'-dtiffn','-r600');
                close(f);
                close(currentStatus);
            end
            
            % If the M + vertex type check box is selected, save that image
            if app.MlatticeCheckBox.Value == 1
                currentStatus = uiprogressdlg(app.IceScannerUI,'Title','Generating image','Message',...
                    'Generating contrast image with detected magnetizations and lattice coordinates superimposed.','Indeterminate','on');
                [imgHeight,imgWidth,~] = size(mat2gray(app.vd.xmcd));
                f = figure('visible','off','Name','M with Lattice', 'Position', [100,100,imgWidth,imgHeight]);
                ax1 = axes(f,'Visible','off','Position',[0,0,1,1],'units','normalized');
                axis image;
                imshow(mat2gray(mat2gray(app.vd.xmcd),[0.3,0.7]),'Parent',ax1);
                overlayVertexType(app,ax1);
                overlayMagnetization(app,ax1,'on');
                truesize(f);
                print(f,sprintf('%sContrast+M+lattice.tif',app.dirImages),'-dtiffn','-r600');
                close(f);
            end
            
            % If the M + vertex type check box is selected, save that image
            if app.MlatticeidealCheckBox.Value == 1
                currentStatus = uiprogressdlg(app.IceScannerUI,'Title','Generating image','Message',...
                    'Generating image with ideal detected magnetizations and lattice coordinates superimposed.','Indeterminate','on');
                [imgHeight,imgWidth,~] = size(mat2gray(app.vd.xmcd));
                f = figure('visible','off','Name','M with Lattice', 'Position', [100,100,imgWidth,imgHeight]);
                xPos = vertcat(app.vd.magnet.xSpin) > 0;
                xNeg = vertcat(app.vd.magnet.xSpin) < 0;
                yPos = vertcat(app.vd.magnet.ySpin) > 0;
                yNeg = vertcat(app.vd.magnet.ySpin) < 0;
                % Combine the four vectors into a nx4 matrix
                posIdx = [xPos,xNeg,yPos,yNeg];
                % Create offset vectors
                xOffset = 1/2*[-1,1,0,0];
                yOffset = 1/2*[0,0,-1,1];
                
                hold on;
                for i = 1:4
                    % Introduce appropriate x and y offsets to the quiver spins based on the value of xSpin and ySpin
                    posI = find(posIdx(:,i));
                    if ~isempty(posI)
                        quiver(vertcat(app.vd.magnet(posI).xR)*2+xOffset(i),...
                            vertcat(app.vd.magnet(posI).yR)*2+yOffset(i),...
                            vertcat(app.vd.magnet(posI).xSpin),...
                            vertcat(app.vd.magnet(posI).ySpin),'AutoScale','off');
                        plot(vertcat(app.vd.magnet(posI).xR)*2,vertcat(app.vd.magnet(posI).yR)*2,'r.');
                        for j = 1:length(posI)
                            xText = app.vd.magnet(posI(j)).xR;
                            yText = app.vd.magnet(posI(j)).yR;
                            a = app.vd.magnet(posI(j)).xR;
                            b = app.vd.magnet(posI(j)).yR;
                            text(xText*2,yText*2,sprintf('(%.1f,%.1f)',a,b),'FontSize',3,'Color','green');
                        end
                    end
                end
                print(f,sprintf('%sIdealM+lattice.tif',app.dirImages),'-dtiffn','-r600');
                close(f);
            end
        end
        currentStatus = uiprogressdlg(app.IceScannerUI,'Title','Saving data','Message',...
            'Saving analysis data to MAT-file.','Indeterminate','on');
        vd = app.vd;
        if ischar(FileName)
            save(fullfile(app.dirImages,FileName),'-struct','vd');
        end
        close(currentStatus)
        app.TabGroup_ImgProcess.SelectedTab = app.Tab_Finish;
        app.arrow_finish.Visible = 1;
        app.steps_finish.Enable = 1;
        app.arrow_postProcess.Visible = 0;
        app.steps_postProcess.Enable = 0;
        % Reopen external window
        app.extWindow.figure = figure("Name","IceScanner - External Window",...
            "NumberTitle","off");
        app.extWindow.axes = axes(app.extWindow.figure,...
            'Position',[0,0,1,1]);
        movegui(app.extWindow.figure,'center');
        uialert(app.IceScannerUI,'Requested files have been saved.','Save completed','Icon','success')
    end
    % '< Back' button is pressed
    function back_PostProcess
        app.TabGroup_ImgProcess.SelectedTab = app.Tab_Finalinspection;
        app.arrow_finalInspect.Visible = 1;
        app.steps_finalInspect.Enable = 1;
        app.arrow_postProcess.Visible = 0;
        app.steps_postProcess.Enable = 0;
    end
    %% Buttons in app.Tab_Finish
    function next_Finish
        % Variable reset
        app.Field_magImagePath.Value = '';
        app.Field_detectionPath.Value = '';
        app.EditFieldVertexReduction.Value = 0;
        %app.oldVersion.Value = '-';
        app.EditFieldVertexIndex.Value = 0;
        app.contrastMode.Value = 'XMCD-PEEM';
        app.scanCross1Width.Value = 0;
        app.scanCross2Width.Value = 0;
        app.scanCross1Height.Value = 0;
        app.scanCross2Height.Value = 0;
        app.scanCross1Angle.Value = 0;
        app.scanCross2Angle.Value = 0;
        app.scanDiameter.Value = 0;
        app.drop_inspectionImage.Value = '-';
        app.MSFSteps.Value = 1200;
        app.MSFStart.Value = -6;
        app.MSFEnd.Value = 6;
        app.processedBefore.Value = 'No';
        % Delete structures app.vd.vertex and app.vd.magnet
        clear app.vd.vertex;
        clear app.vd.magnet;
        % Reset UI
        app.TabGroup_ImgProcess.SelectedTab = app.Tab_Import;
        %app.TabGroupAnalysis.SelectedTab = app.AnalysisTab;
        app.arrow_finish.Visible = 0;
        app.steps_finish.Enable = 0;
        app.arrow_import.Visible = 1;
        app.steps_import.Enable = 1;
        app.ButtonRemovePts.Enable = 0;
        app.ButtonAddPts.Enable = 0;
        app.next_cleanUp.Enable = 0;
        app.ButtonPreviewScan.Enable = 0;
        app.ButtonNeighborDetect.Enable = 0;
        app.next_nbrScan.Enable = 0;
        app.next_latticeIdx.Enable = 0;
        app.browse_importMagContrast.Enable = 1;
        app.Field_magImagePath.Enable = 1;
    end

end

