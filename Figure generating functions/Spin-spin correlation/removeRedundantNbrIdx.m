function removeRedundantNbrIdx(app)
    % Generates a list of unique vertex pairs based on what n-th neighbors they are
    currentStatus = uiprogressdlg(app.IceScannerUI,'Title','Spin-spin correlation',...
        'Message',sprintf('%s\n\n%s','Identifying all unique n-th nearest neighboring pairs.',...
        'This will take a while.'));
    
    % Make a list of all indices that have a ignore flag
    ignoreFlagList = find(vertcat(app.vd.magnet.ignoreFlag)==true);
    
    % Index all alpha and n-th neighbor pairs (make sure the n-th neighbor isnt blank)
    switch app.vd.typeASI
        case {'Square','Kagome'}
            % Access structure nbr with indices 1-7
            nbrRange = 1:7;
        case 'Brickwork'
            % Access structure nbr with indices 1-7 and 8-11 (the "b" neighbors)
            nbrRange = 1:11;
    end
    
    % Look at the neighbor magnets
    for i = nbrRange
        % Set up a counter variable to indicate which row in pairNbr the unique neighbors
        % should be added to
        idxNbr = 1;
        % Set up a vector pairNbr that stores unique magnet pairs based on what i-th neighbors they are
        pairNbr = zeros(length(app.vd.magnet)*10,2);
        % Loop over all magnets alpha
        for alpha = 1:length(app.vd.magnet)
            % If the alpha magnet doesnt have an i-th neighbor, ignore it
            if ~isempty(app.vd.magnet(alpha).nbr(i).idx)
                % Identify and store the indices of the i-th neighbor magnets
                for j = 1:length(vertcat(app.vd.magnet(alpha).nbr(i).idx))
                    pairNbr(idxNbr,1) = alpha;
                    pairNbr(idxNbr,2) = app.vd.magnet(alpha).nbr(i).idx(j);
                    % Change the counter variable to look at the next row in pairNbr
                    idxNbr = idxNbr + 1;
                end
            end
            %currentStatus.Value = alpha/length(app.vd.magnet)*i/length(nbrRange);
        end
        % Get rid of entries that are zero in both columns
        pairNbr(pairNbr(:,1) == 0 & pairNbr(:,2) == 0,:) = [];
        % Sort each row so that the smallest entry is in the first column
        pairNbr = sort(pairNbr,2);
        % Identify the unique combinations of neighbors
        pairNbr = unique(pairNbr,'rows');
        % Remove all pairs containing an index with a ignore flag
        nbrFlags = ~ismember(pairNbr,ignoreFlagList);
        nbrFlags = nbrFlags(:,1).*nbrFlags(:,2);
        pairNbr = pairNbr(nbrFlags == 1,:);
        % Save the pair identifications
        app.vd.pairNbr(i).Value = pairNbr;
        currentStatus.Value = i/length(nbrRange);
    end
    close(currentStatus);
    
    % Plot the final vertices, but make sure to omit any ignoreFlagList indices
    if app.correlation_nbrMovie.Value == 1
        currentStatus = uiprogressdlg(app.IceScannerUI,'Title','Spin-spin correlation',...
            'Message',sprintf('%s\n\n%s','Results are being archived as a movie.',...
            'This will take a while.'));
        v = VideoWriter(sprintf('%sNbr',app.dirImages),'Motion JPEG AVI');
        v.FrameRate = 10;
        open(v);
        f = figure('Visible','off');
        f.Position = [10 10 800 800];
        ax = axes('Position',[0,0,1,1],'units','normalized');
        axis image;
        hold on
        imshow(mat2gray(app.vd.xmcd),'Parent',ax);
        quiver(app.vd.whiteOffsetX,app.vd.whiteOffsetY,app.vd.whiteVectorX,app.vd.whiteVectorY,'b',...
            'AutoScale','off','LineWidth',1);
        quiver(app.vd.blackOffsetX,app.vd.blackOffsetY,app.vd.blackVectorX,app.vd.blackVectorY,'r',...
            'AutoScale','off','LineWidth',1);
        for alpha = 1:length(app.vd.magnet)
            if app.vd.magnet(alpha).ignoreFlag == false
                % Initialize structure plotSave to perform figure deletion later
                pltNbr = struct('text',{});
                % Initialize vector plotColor which will contain the colors to use for each i-th neighbor
                plotColor = ["blue","red","blue","red","blue","red","blue","red","blue","red","blue"];
                % Initialize vector nbrText which will contain the text to use for each i-th neighbor
                nbrText = ["1","2","3","4","5","6","7","4b","5b","6b","7b"];
                % Plot for each unique i-th neighbor type
                pltAlpha = text(vertcat(app.vd.magnet(alpha).colXPos),vertcat(app.vd.magnet(alpha).rowYPos),...
                    sprintf('%d',alpha),'Color','green','FontSize',15,'FontWeight','bold','HorizontalAlignment','center');
                circAlpha = plot(vertcat(app.vd.magnet(alpha).colXPos),vertcat(app.vd.magnet(alpha).rowYPos),'ro',...
                    'MarkerSize',15);
                for i = nbrRange
                    finalNbr = app.vd.magnet(alpha).nbr(i).idx;
                    finalNbr = finalNbr(~ismember(finalNbr,ignoreFlagList));
                    pltNbr(i).text = text(vertcat(app.vd.magnet(finalNbr).colXPos),vertcat(app.vd.magnet(finalNbr).rowYPos),...
                        nbrText(i),'Color',plotColor(i),'FontSize',10,'FontWeight','bold','HorizontalAlignment','center');
                end
                frame = getframe(f);
                writeVideo(v,frame);
                delete(pltAlpha);
                delete(circAlpha);
                for i = nbrRange
                    delete(pltNbr(i).text);
                end
            end
            currentStatus.Value = alpha/length(app.vd.magnet);
        end
        close(v);
        close(f);
        close(currentStatus);
    end
end