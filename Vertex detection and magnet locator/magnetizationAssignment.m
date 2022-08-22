% Assignment of Ising magnetization vectors
function magnetizationAssignment(app,magInd,angle)
    % Assign the lateral orientation (black is -1/left, white is +1/right)
    magnetizationIntensity = app.vd.magnet(magInd).xmcdTrinary;
    %app.vd.magnet(magInd).xmcdWeighted;
    if magnetizationIntensity > 0      % Right (White)
        app.vd.magnet(magInd).projection = 1;
        % Define how the magnetization is oriented on the unit circle
        % If the vector associated with the variable angle is oriented towards the second or third quadrant
        % (angle = [90 270]), then flip it.
        if angle >= 90 && angle <= 270
            if angle >= 180
                app.vd.magnet(magInd).spinAngle = angle-180;
            elseif angle < 180
                app.vd.magnet(magInd).spinAngle = angle+180;
            end
        else
            app.vd.magnet(magInd).spinAngle = angle;
        end

        % Determine the X and Y offsets when plotting the Ising macrospins
        app.vd.magnet(magInd).spinPlotXOffset = app.vd.magnet(magInd).colXPos - 7*cosd(angle);
        app.vd.magnet(magInd).spinPlotYOffset = app.vd.magnet(magInd).rowYPos - 7*sind(angle);

    elseif magnetizationIntensity < -0     % Left (Black)
        app.vd.magnet(magInd).projection = -1;

        % Define how the magnetization is oriented on the unit circle
        % If the vector associated with the variable angle is oriented towards the second or third quadrant
        % (angle = [90 270]), then keep it. Otherwise flip it.
        if angle >= 90 && angle <= 270
            app.vd.magnet(magInd).spinAngle = angle;
        else
            if angle >= 180
                app.vd.magnet(magInd).spinAngle = angle-180;
            elseif angle < 180
                app.vd.magnet(magInd).spinAngle = angle+180;
            end
        end

        % Determine the X and Y offsets when plotting the Ising macrospins
        app.vd.magnet(magInd).spinPlotXOffset = app.vd.magnet(magInd).colXPos + 7*cosd(angle);
        app.vd.magnet(magInd).spinPlotYOffset = app.vd.magnet(magInd).rowYPos + 7*sind(angle);
    end
end