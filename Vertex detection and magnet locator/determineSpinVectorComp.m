% Determines the spin vector components for magnetic structure factor correlation function calculations
function determineSpinVectorComp(app)
    componentStatus = uiprogressdlg(app.IceScannerUI,'Title','Determining spin vector components','Message',...
        'Determining the spin vector components for magnetic structure factor and/or correlation function calculations.');
    separationDistance = 1; % in nm, can be altered in a future version to calculate q as a function of inverse nm

    % Define number of nanomagnetic elements
    numberOfMagnets = length(vertcat(app.vd.magnet.rowYPos));
    try
        for alpha = 1:numberOfMagnets
            componentStatus.Value = alpha/numberOfMagnets;
            switch app.vd.typeASI
                case {'Brickwork','Square','Tetris'}
                    if app.vd.magnet(alpha).orient == 2 % If the reference magnet is "/"
                        % X-Component: +-cos45, Y-Component: -+sin45
                        app.vd.magnet(alpha).xSpin = app.vd.magnet(alpha).projection * cosd(45);
                        app.vd.magnet(alpha).ySpin = -app.vd.magnet(alpha).projection * sind(45);
                    elseif app.vd.magnet(alpha).orient == 3 % If the reference magnet is "\"
                        % X-Component: +-cos45, Y-Component: +-sin45
                        app.vd.magnet(alpha).xSpin = app.vd.magnet(alpha).projection * cosd(45);
                        app.vd.magnet(alpha).ySpin = app.vd.magnet(alpha).projection * sind(45);
                    end

                    % Determine the position vector (r-vector)
                    xPosition = (app.vd.magnet(alpha).bInd + app.vd.magnet(alpha).aInd) /2;
                    yPosition = (app.vd.magnet(alpha).bInd - app.vd.magnet(alpha).aInd) /2;
                    xSpin = app.vd.magnet(alpha).xSpin;
                    ySpin = -app.vd.magnet(alpha).ySpin;

                    x = -45; % in degrees; can be altered in a future version
                    % Apply rotation transform
                    app.vd.magnet(alpha).xR = (xPosition*cosd(x) - yPosition*sind(x))*sqrt(2);
                    app.vd.magnet(alpha).yR = (xPosition*sind(x) + yPosition*cosd(x))*sqrt(2);
                    app.vd.magnet(alpha).xSpin = xSpin*cosd(x) - ySpin*sind(x);
                    app.vd.magnet(alpha).ySpin = xSpin*sind(x) + ySpin*cosd(x);

                case 'Kagome'
                    if mod(app.vd.magnet(alpha).aInd,2) == 0
                        if mod(app.vd.magnet(alpha).bInd,2) == 0 % If both indices are even: Type 1 "-"
                            % X-Component: +- 1, Y-Component = 0
                            app.vd.magnet(alpha).xSpin = app.vd.magnet(alpha).projection;
                            app.vd.magnet(alpha).ySpin = 0;
                        elseif mod(app.vd.magnet(alpha).bInd,2) == 1 % If a is even and b is odd, Type 2 "/"
                            % X-Component: +-cos60, Y-Component: -+ sin60
                            app.vd.magnet(alpha).xSpin = app.vd.magnet(alpha).projection*cosd(60);
                            app.vd.magnet(alpha).ySpin = -app.vd.magnet(alpha).projection*sind(60);
                        end
                    elseif mod(app.vd.magnet(alpha).aInd,2) == 1 && mod(app.vd.magnet(alpha).bInd,2) == 1 % If both indices are odd: Type 3 "\"
                        % X-Component: +-cos60, Y-Component: +- sin60
                        app.vd.magnet(alpha).xSpin = app.vd.magnet(alpha).projection*cosd(60);
                        app.vd.magnet(alpha).ySpin = app.vd.magnet(alpha).projection*sind(60);
                    end

                    % Determine the position vector (r-vector)
                    xPosition = 2*(sqrt(3) * separationDistance * app.vd.magnet(alpha).bInd / 4);
                    yPosition = 2*(-(separationDistance  * ((app.vd.magnet(alpha).aInd/2) - (app.vd.magnet(alpha).bInd/4))));
                    xSpin = app.vd.magnet(alpha).xSpin;
                    ySpin = -app.vd.magnet(alpha).ySpin;

                    % Apply rotation transform
                    x = 0; % in degrees; can be altered in a future version
                    app.vd.magnet(alpha).xR = (xPosition*cosd(x) - yPosition*sind(x));
                    app.vd.magnet(alpha).yR = (xPosition*sind(x) + yPosition*cosd(x));
                    app.vd.magnet(alpha).xSpin = xSpin*cosd(x) - ySpin*sind(x);
                    app.vd.magnet(alpha).ySpin = xSpin*sind(x) + ySpin*cosd(x);
            end
        end
    catch ME
        errorNotice(app,ME);
    end
    close(componentStatus);
end