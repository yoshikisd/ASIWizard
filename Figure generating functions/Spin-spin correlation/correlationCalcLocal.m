function correlationCalcLocal(app,savePath)
    % Determines the local spin-spin correlations
    switch app.vd.typeASI
        case {'Square','Kagome'}
            % Access structure nbr with indices 1-7
            nbrRange = 1:7;
        case 'Brickwork'
            % Access structure nbr with indices 1-7 and 8-11 (the "b" neighbors)
            nbrRange = 1:11;
    end
    % Make a list of all indices that have a ignore flag
    flagIgnore = find(vertcat(app.vd.magnet.ignoreFlag)==true);
    % Make a list of all indices that are flagged as a CST
    flagOWIB = find(vertcat(app.vd.magnet.domainState) == "OWIB");
    flagOBIW = find(vertcat(app.vd.magnet.domainState) == "OBIW");
    flagTWBB = find(vertcat(app.vd.magnet.domainState) == "TWBB");
    flabTBBW = find(vertcat(app.vd.magnet.domainState) == "TBBW");
    
    % Set the text used for each unique neighbor type
    nbrText = ["1","2","3","4","5","6","7","4b","5b","6b","7b"];
    
    currentStatus = uiprogressdlg(app.IceScannerUI,'Title','Spin-spin correlation',...
        'Message',sprintf('%s\n\n%s','Calculating local correlations.',...
        'This will take a while.'));
    % Look at each magnet alpha
    for alpha = 1:length(app.vd.magnet)
        % Make sure that the observed alpha magnet isn't flagged to be ignored
        if app.vd.magnet(alpha).ignoreFlag == false
            % Compute the local correlation for the i-th neighbor
            for i = 1:length(nbrRange)
                % Make sure that the i-th neighbor exists
                if ~isempty(app.vd.magnet(alpha).nbr(i).idx)
                    % Construct a list of neighbor pairs (including the alpha magnet)
                    pairList = app.vd.magnet(alpha).nbr(i).idx;
                    % Omit any element which has been flagged to ignore
                    pairList = pairList(~ismember(pairList,flagIgnore));
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % Add alpha. Keep this in mind since it's very important regarding
                    % the calculation of correlators from a CST-to-Ising neighbors and
                    % Ising-to-CST neighbors. CST-to-Ising may produce non-zero values (CST treated as finite moment)
                    % Ising-to-CST will always produce zero values (CST treated as zero moment).
                    pairList(:,2) = alpha;
                    % Compute the local correlation based on the calculation type
                    if app.correlation_SpinDot.Value == 1
                        app.vd.magnet(alpha).nbr(i).c.dot = spinCorrelation(app,pairList,"dot","local");
                    end
                    if app.correlation_DotBinary.Value == 1
                        app.vd.magnet(alpha).nbr(i).c.dotBinary = spinCorrelation(app,pairList,"dot binary","local");
                    end
                    if app.correlation_DotBinary.Value == 1
                        app.vd.magnet(alpha).nbr(i).c.ms = spinCorrelation(app,pairList,"magnetostatic","local");
                    end
                end
            end
        end
        currentStatus.Value = alpha/length(app.vd.magnet);
    end
    close(currentStatus);
    
    % Generate correlation map (BlueWhiteRed)
    % First, set the colormap
    cmap = zeros(256,3);
    for i = 1:256
        if i <= 127 % The color will be between blue and white
            cmap(i,:) = [i/128, i/128, 1];
        else 
            cmap(i,:) = [1, 2 - (i)/128, 2 - (i)/128];
        end
    end

    % Create variable calcType which will tell the program what method to use for calculating the correlation coeff.
    calcType = strings;
    if app.correlation_SpinDot.Value == 1
        calcType(end+1) = "dot";
    end
    if app.correlation_DotBinary.Value == 1
        calcType(end+1) = "dot binary";
    end
    if app.correlation_Magnetostatic.Value == 1
        calcType(end+1) = "magnetostatic";
    end
    % Remove null entries
    calcType(cellfun('isempty',calcType)) = [];
    
    currentStatus = uiprogressdlg(app.IceScannerUI,'Title','Spin-spin correlation',...
        'Message',sprintf('%s\n\n%s','Saving local correlations.',...
        'This will take a while.'));
    counter = 0;
    for j = 1:length(calcType)
        for i = 1:length(nbrRange)
            f = figure('Visible','off');
            f.Position = [10 10 1000 1000];
            ax = axes('Position',[0.05,0.05,0.9,0.9],'units','normalized');
            axis image;
            hold on
            imshow(mat2gray(app.vd.xmcd,[double(min(min(app.vd.xmcd)))*1.25,double(max(max(app.vd.xmcd)))*0.75]),...
                'Parent',ax);
            cr = colorbar;
            cr.Ticks = [];
            % Create a matrix intensity that will store the different color for each point
            intensity = zeros(length(app.vd.magnet),3);
            % Create a matrix correlation that will store the correlation values
            correlation = zeros(length(app.vd.magnet),1);
            % Calculate the point intensities
            for alpha = 1:length(app.vd.magnet)
                % Make sure the neighbor idx is not null
                if ~isempty(app.vd.magnet(alpha).nbr(i).idx)
                    % Figure out what the color is (linear interpolation, blue = -1, red = +1)
                    switch calcType(j)
                        case "dot"
                            correlation(alpha) = app.vd.magnet(alpha).nbr(i).c.dot;
                        case "dot binary"
                            correlation(alpha) = app.vd.magnet(alpha).nbr(i).c.dotBinary;
                        case "magnetostatic"
                            correlation(alpha) = app.vd.magnet(alpha).nbr(i).c.ms;
                    end
                    if correlation(alpha) < 0 % The color will be between blue and white
                        intensity(alpha,:) = [1 + correlation(alpha), 1 + correlation(alpha), 1];
                    elseif correlation(alpha) > 0 % The color will be between 
                        intensity(alpha,:) = [1, 1 - correlation(alpha), 1 - correlation(alpha)];
                    elseif correlation(alpha) == 0
                        intensity(alpha,:) = [1,1,1];
                    end
                else
                    correlation(alpha) = NaN;
                end
                counter = counter + 1;
                currentStatus.Value = counter/(length(app.vd.magnet)*length(calcType)*length(nbrRange));
            end
            % Make a list of all entries with correlation that are NaN, which corresponds to [0 0 0] intensity
            notNaN = ~isnan(correlation);
            % Plot points in the center of each magnet with colors dependent on the correlation
            scatter(ax,vertcat(app.vd.magnet(notNaN).colXPos),vertcat(app.vd.magnet(notNaN).rowYPos),50,...
                intensity(notNaN,:),'filled','MarkerEdgeColor','k','MarkerFaceAlpha',0.8);
            ax3 = axes('Position',[0.05,0.05,0.9,0.9],'units','normalized','visible','off');
            colormap(ax3,cmap);
            colorbar;
            caxis([-1.2 1.2]);
            print(f,sprintf('%scorrelationMap-%s-Nbr%s.tif',app.dirImages,calcType(j),nbrText(i)),'-dtiff','-r600');
            close(f);
        end
    end
end

