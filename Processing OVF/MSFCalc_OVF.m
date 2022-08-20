function [pseudoXMCD,MSF,MSFTable] = MSFCalc_OVF(directory,latticeParam,steps,qMax, method)
    arguments
        directory string    % File name and path
        latticeParam double % Lattice parameter in nm
        steps double        % Number of steps for MSF
        qMax double         % Max/min q values for MSF
        method {mustBeMember(method,['full','half'])}
    end

    % Read parameters from ovf file
    fid = fopen(directory,'r');
    for i = 1:21; if i == 12; cellSizeTxt = fgetl(fid); elseif i == 21; cellNumTxt = fgetl(fid); else; fgetl(fid); end; end
    cellSize = str2double(cellSizeTxt(14:end))*1e9; % In nm
    cellNum = str2double(cellNumTxt(10:end));
    S = readmatrix(directory,'FileType','text','NumHeaderLines',28);
    S(end-1:end,:) = [];
    Sx = reshape(S(:,1),cellNum,cellNum)';
    Sy = reshape(S(:,2),cellNum,cellNum)';
    
    % Define positions of each pixel
    xR_Matx = zeros(cellNum);
    yR_Matx = xR_Matx;
    for i = 1:cellNum
        xR_Matx(:,i) = cellSize*i/latticeParam; % in units of lattice coordinates
        yR_Matx(i,:) = cellSize*i/latticeParam; % in units of lattice coordinates
    end
    xSpin = Sx(:);
    ySpin = Sy(:);
    xR = xR_Matx(:);
    yR = yR_Matx(:);
    xRay = [1,-1]/sqrt(2);
    pseudoXMCD = imrotate((xRay(1)*Sx)+(xRay(2)*Sy),-45,'crop');
    
    [MSF,MSFTable] = generateMSF([],steps,qMax,xSpin,ySpin,xR,yR,method,'mumax');
end