% Enables or disables buttons on the neighbor scan tab
function nbrScanButtonEnable(app)
    switch app.vd.typeASI
        case {'Square','Brickwork','Tetris'}
            if app.scanCross1Width.Value == 0 || app.scanCross1Height.Value == 0 ||...
                    app.scanCross2Height.Value == 0 || app.scanCross2Width.Value == 0
                app.ButtonPreviewScan.Enable = 0;
                app.ButtonNeighborDetect.Enable = 0;
                app.next_nbrScan.Enable = 0;
            elseif app.scanCross1Width.Value ~= 0 && app.scanCross1Height.Value ~= 0 &&...
                    app.scanCross2Height.Value ~= 0 && app.scanCross2Width.Value ~= 0
                app.ButtonPreviewScan.Enable = 1;
            end
        case 'Kagome'
            if app.scanDiameter.Value == 0
                app.ButtonPreviewScan.Enable = 0;
                app.ButtonNeighborDetect.Enable = 0;
                app.next_nbrScan.Enable = 0;
            else
                app.ButtonPreviewScan.Enable = 1;
            end
    end
end