% Plots the detected vertices
function vertexPlot(app,targetAxes)
    % Show the analysis window
    %app.TabGroupAnalysis.SelectedTab = app.AnalysisTab;

    % Generate figure to convert into image
    f = figure('visible','off','Position',[0,0,app.vd.gridWidth,app.vd.gridHeight]);
    %ax1 = axes(f,'Position',[0,0,1,1],'Visible','off');
    imshow(mat2gray(app.vd.xasGrid(:,:,1)),'InitialMagnification','fit',...
        'Border','tight');
    ax1 = f.CurrentAxes;
    hold(ax1,'on');

    % Figure out the ASI type and plot vertices accordingly (if differentiation between the two reference images are required)
    switch app.vd.typeASI
        case {'Square' , 'Kagome','Tetris'}
            for i = 1:length(app.vd.minLoc)
                plot(ax1,app.vd.minLoc(i,2),app.vd.minLoc(i,1),'b+','MarkerSize',14); 
                plot(ax1,app.vd.minLoc(i,2),app.vd.minLoc(i,1),'b.','MarkerSize',14);
            end
        case 'Brickwork'
            for i = 1:length(app.vd.minLoc)
                switch app.vd.minLoc(i,4)
                    case 1
                        plot(ax1,app.vd.minLoc(i,2),app.vd.minLoc(i,1),'b+','MarkerSize',13);
                        plot(ax1,app.vd.minLoc(i,2),app.vd.minLoc(i,1),'b.','MarkerSize',14);
                    case 2
                        plot(ax1,app.vd.minLoc(i,2),app.vd.minLoc(i,1),'gx','MarkerSize',13);
                        plot(ax1,app.vd.minLoc(i,2),app.vd.minLoc(i,1),'g.','MarkerSize',14);
                end
            end
        otherwise % If the ASI type has not been provided or is invalid
            uialert(app.IceScannerUI,'Please change the ASI type.');
    end
    hold(ax1,'off');
    f_img = frame2im(getframe(f));
    close(f);
    
     % Show converted figure
    general_imageDisplay(app,targetAxes,f_img);
end