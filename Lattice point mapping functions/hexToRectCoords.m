function hexToRectCoords(app)
    % Converts the hexagonal coordinates used in the Kagome ASI to rectangular coordinates
    % Refer to notebook about the lattice coordinate system used
    % (a,b)_hex -> (a-b*sin(30), b*cos(30))
    for i = 1:length(vertcat(app.vd.magnet.aInd))
        a_Hex = app.vd.magnet(i).aInd;
        b_Hex = app.vd.magnet(i).bInd;
        app.vd.magnet(i).aInd_Hex2Rec = a_Hex-b_Hex*0.5;
        app.vd.magnet(i).bInd_Hex2Rec = b_Hex*sqrt(3)/2;
    end
end