function ASIComp_selectDatalistItem(app)
% Clicking an item on the data list will update the external window with
% the associated real/reciprocal space magnetic image
    idx = find(strcmp(app.Datalist_ASIComp.Items,app.Datalist_ASIComp.Value));
    
    % Real space values
    if app.Radio_ASIComp_ShowRealSpace.Value
        switch app.Drop_ASIComp.Value
            case 'Topography'
                backgroundImage = (app.d2c.asi(idx).align.xas);
            case 'Magnetic contrast'
                backgroundImage = (app.d2c.asi(idx).align.xmcd);
            case 'Boosted magnetic contrast'
                backgroundImage = (app.d2c.asi(idx).align.xmcd);
            case 'Magnetic contrast magnitude'
                backgroundImage = (-abs(app.d2c.asi(idx).align.xmcdCorrectedTrinary));
            case 'Trinary contrast'
                backgroundImage = (app.d2c.asi(idx).align.xmcdTrinary);
            case 'Background corrected trinary'
                backgroundImage = (app.d2c.asi(idx).align.xmcdCorrectedTrinary);
            case 'ROI - Regular'
                backgroundImage = (app.d2c.asi(idx).align.xmcdOriginalSkeleton);
            case 'ROI - Trinary'
                backgroundImage = (app.d2c.asi(idx).align.xmcdTrinarySkeleton);
        end
        cla(app.extWindow.axes,'reset');
        [imgHeight,imgWidth,~] = size(backgroundImage);
        imshow(backgroundImage,[],'Parent',app.extWindow.axes,'InitialMagnification','fit',...
            'Border','tight');
        clim(app.extWindow.axes,[-0.01,0.01])
        refFrame.XLim = [0 imgHeight];
        refFrame.YLim = [0 imgWidth];

    % Reciprocal space values
    elseif app.Radio_ASIComp_ShowMSF.Value
        general_imageDisplay(app,app.extWindow.axes,app.d2c.asi(idx).MSF.matrix);
        % Set colormap (default Plasma)
        switch app.Drop_CMap.Value
            case 'Plasma'
                cmap = plasma;
            case 'Magma'
                cmap = magma;
            case 'Inferno'
                cmap = inferno;
            case 'Viridis'
                cmap = viridis;
            case 'HSV'
                cmap = hsv;
            case 'Jet'
                cmap = jet;
        end
        % Set color scale
        switch app.Switch_MSF_Scaling.Value
            case 'Linear'
                scaling = 'linear';
            case 'Log'
                scaling = 'log';
        end
        % Set intensity limits
        clim(app.extWindow.axes,[app.Field_MSF_IMin.Value,app.Field_MSF_IMax.Value]);
        set(app.extWindow.axes,'Colormap',cmap,'ColorScale',scaling);colorbar;
    end
end

