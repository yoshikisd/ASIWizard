% Plots the rough detection points from the EMD calculation    
function vertexDetect_roughDetection(app)
    try
        % Plot the rough detection points
        plotStatus = uiprogressdlg(app.IceScannerUI,'Title','Plotting','Message',...
            'Plotting the points. If this is taking a long time you should decrease the threshold.',...
            'Indeterminate','on');
        % Reset the detection state
        app.xasGrid(:,:,2) = zeros(app.gridHeight,app.gridWidth); 
        app.xasGrid(:,:,3) = zeros(app.gridHeight,app.gridWidth);
        % Show the topography image
        imshow(mat2gray(app.xasGrid(:,:,1)),'Parent',app.extWindow.axes,'InitialMagnification','fit');
        % Apply thresholds
        threshold1 = min(app.emdGlobalRef1(:,:,1),[],'all','omitnan') + app.img1Threshold.Value*(std(app.emdGlobalRef1(:,:,1),0,'all','omitnan'));
        switch app.vd.typeASI
            case {'Brickwork','Kagome'}
                threshold2 = min(app.emdGlobalRef2(:,:,1),[],'all','omitnan') + app.img2Threshold.Value*(std(app.emdGlobalRef2(:,:,1),0,'all','omitnan'));
            case 'Tetris'
                threshold2 = min(app.emdGlobalRef2(:,:,1),[],'all','omitnan') + app.img2Threshold.Value*(std(app.emdGlobalRef2(:,:,1),0,'all','omitnan'));
                threshold3 = min(app.emdGlobalRef3(:,:,1),[],'all','omitnan') + app.img3Threshold.Value*(std(app.emdGlobalRef3(:,:,1),0,'all','omitnan'));
                threshold4 = min(app.emdGlobalRef4(:,:,1),[],'all','omitnan') + app.img4Threshold.Value*(std(app.emdGlobalRef4(:,:,1),0,'all','omitnan'));
                threshold5 = min(app.emdGlobalRef5(:,:,1),[],'all','omitnan') + app.img5Threshold.Value*(std(app.emdGlobalRef5(:,:,1),0,'all','omitnan'));
                threshold6 = min(app.emdGlobalRef6(:,:,1),[],'all','omitnan') + app.img6Threshold.Value*(std(app.emdGlobalRef6(:,:,1),0,'all','omitnan'));
                threshold7 = min(app.emdGlobalRef7(:,:,1),[],'all','omitnan') + app.img7Threshold.Value*(std(app.emdGlobalRef7(:,:,1),0,'all','omitnan'));
                threshold8 = min(app.emdGlobalRef8(:,:,1),[],'all','omitnan') + app.img8Threshold.Value*(std(app.emdGlobalRef8(:,:,1),0,'all','omitnan'));
        end
        hold(app.extWindow.axes,'on');
        % Rough detection of minimas below a certain threshold in the reference 1 EMD
        switch app.vd.typeASI
            case 'Square' % For the square ice case
                for j = 1:app.jRangeSize
                    for i = 1:app.iRangeSize
                        if app.emdGlobalRef1(j,i,1) <= threshold1
                            app.xasGrid(app.emdGlobalRef1(j,i,3),app.emdGlobalRef1(j,i,2),2) = 1;                       % Indicate what frame detected this
                            app.xasGrid(app.emdGlobalRef1(j,i,3),app.emdGlobalRef1(j,i,2),3) = app.emdGlobalRef1(j,i,1);    % Store the detected intensity
                            plot(app.extWindow.axes,app.emdGlobalRef1(j,i,2),app.emdGlobalRef1(j,i,3),'r.','MarkerSize',10)
                        end
                    end
                end
            case {'Brickwork','Kagome'} % For brickwork or kagome
                for j = 1:app.jRangeSize
                    for i = 1:app.iRangeSize
                        if app.emdGlobalRef1(j,i,1) <= threshold1
                            app.xasGrid(app.emdGlobalRef1(j,i,3),app.emdGlobalRef1(j,i,2),2) = 1;                       % Indicate what frame detected this
                            app.xasGrid(app.emdGlobalRef1(j,i,3),app.emdGlobalRef1(j,i,2),3) = app.emdGlobalRef1(j,i,1);    % Store the detected intensity
                            plot(app.extWindow.axes,app.emdGlobalRef1(j,i,2),app.emdGlobalRef1(j,i,3),'r.','MarkerSize',10)
                        end
                        if app.emdGlobalRef2(j,i,1) <= threshold2
                            app.xasGrid(app.emdGlobalRef2(j,i,3),app.emdGlobalRef2(j,i,2),2) = 2;                       % Indicate what frame detected this
                            app.xasGrid(app.emdGlobalRef2(j,i,3),app.emdGlobalRef2(j,i,2),3) = app.emdGlobalRef2(j,i,1);    % Store the detected intensity
                            plot(app.extWindow.axes,app.emdGlobalRef2(j,i,2),app.emdGlobalRef2(j,i,3),'b.','MarkerSize',10)
                        end
                    end
                end
            case 'Tetris'
                for j = 1:app.jRangeSize
                    for i = 1:app.iRangeSize
                        if app.emdGlobalRef1(j,i,1) <= threshold1
                            app.xasGrid(app.emdGlobalRef1(j,i,3),app.emdGlobalRef1(j,i,2),2) = 1;                       % Indicate what frame detected this
                            app.xasGrid(app.emdGlobalRef1(j,i,3),app.emdGlobalRef1(j,i,2),3) = app.emdGlobalRef1(j,i,1);    % Store the detected intensity
                            plot(app.extWindow.axes,app.emdGlobalRef1(j,i,2),app.emdGlobalRef1(j,i,3),'r.','MarkerSize',10)
                        end
                        if app.emdGlobalRef2(j,i,1) <= threshold2
                            app.xasGrid(app.emdGlobalRef2(j,i,3),app.emdGlobalRef2(j,i,2),2) = 2;                       % Indicate what frame detected this
                            app.xasGrid(app.emdGlobalRef2(j,i,3),app.emdGlobalRef2(j,i,2),3) = app.emdGlobalRef2(j,i,1);    % Store the detected intensity
                            plot(app.extWindow.axes,app.emdGlobalRef2(j,i,2),app.emdGlobalRef2(j,i,3),'r.','MarkerSize',10)
                        end
                        if app.emdGlobalRef3(j,i,1) <= threshold3
                            app.xasGrid(app.emdGlobalRef3(j,i,3),app.emdGlobalRef3(j,i,2),2) = 3;                       % Indicate what frame detected this
                            app.xasGrid(app.emdGlobalRef3(j,i,3),app.emdGlobalRef3(j,i,2),3) = app.emdGlobalRef3(j,i,1);    % Store the detected intensity
                            plot(app.extWindow.axes,app.emdGlobalRef3(j,i,2),app.emdGlobalRef3(j,i,3),'r.','MarkerSize',10)
                        end
                        if app.emdGlobalRef4(j,i,1) <= threshold4
                            app.xasGrid(app.emdGlobalRef4(j,i,3),app.emdGlobalRef4(j,i,2),2) = 4;                       % Indicate what frame detected this
                            app.xasGrid(app.emdGlobalRef4(j,i,3),app.emdGlobalRef4(j,i,2),3) = app.emdGlobalRef4(j,i,1);    % Store the detected intensity
                            plot(app.extWindow.axes,app.emdGlobalRef4(j,i,2),app.emdGlobalRef4(j,i,3),'r.','MarkerSize',10)
                        end
                        if app.emdGlobalRef5(j,i,1) <= threshold5
                            app.xasGrid(app.emdGlobalRef5(j,i,3),app.emdGlobalRef5(j,i,2),2) = 5;                       % Indicate what frame detected this
                            app.xasGrid(app.emdGlobalRef5(j,i,3),app.emdGlobalRef5(j,i,2),3) = app.emdGlobalRef5(j,i,1);    % Store the detected intensity
                            plot(app.extWindow.axes,app.emdGlobalRef5(j,i,2),app.emdGlobalRef5(j,i,3),'r.','MarkerSize',10)
                        end
                        if app.emdGlobalRef6(j,i,1) <= threshold6
                            app.xasGrid(app.emdGlobalRef6(j,i,3),app.emdGlobalRef6(j,i,2),2) = 6;                       % Indicate what frame detected this
                            app.xasGrid(app.emdGlobalRef6(j,i,3),app.emdGlobalRef6(j,i,2),3) = app.emdGlobalRef6(j,i,1);    % Store the detected intensity
                            plot(app.extWindow.axes,app.emdGlobalRef6(j,i,2),app.emdGlobalRef6(j,i,3),'r.','MarkerSize',10)
                        end
                        if app.emdGlobalRef7(j,i,1) <= threshold7
                            app.xasGrid(app.emdGlobalRef7(j,i,3),app.emdGlobalRef7(j,i,2),2) = 7;                       % Indicate what frame detected this
                            app.xasGrid(app.emdGlobalRef7(j,i,3),app.emdGlobalRef7(j,i,2),3) = app.emdGlobalRef7(j,i,1);    % Store the detected intensity
                            plot(app.extWindow.axes,app.emdGlobalRef7(j,i,2),app.emdGlobalRef7(j,i,3),'r.','MarkerSize',10)
                        end
                        if app.emdGlobalRef8(j,i,1) <= threshold8
                            app.xasGrid(app.emdGlobalRef8(j,i,3),app.emdGlobalRef8(j,i,2),2) = 8;                       % Indicate what frame detected this
                            app.xasGrid(app.emdGlobalRef8(j,i,3),app.emdGlobalRef8(j,i,2),3) = app.emdGlobalRef8(j,i,1);    % Store the detected intensity
                            plot(app.extWindow.axes,app.emdGlobalRef8(j,i,2),app.emdGlobalRef8(j,i,3),'r.','MarkerSize',10)
                        end
                    end
                end
        end
        app.extWindow.axes.XLim = [0 app.gridWidth];
        app.extWindow.axes.YLim = [0 app.gridHeight];
        hold(app.extWindow.axes,'off');
    catch ME
        errorNotice(app,ME);
        return;
    end
    close(plotStatus);
end