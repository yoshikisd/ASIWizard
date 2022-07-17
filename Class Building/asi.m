classdef asi
    % Class ASI
    %   Contains information about the properties of the ASI, including the
    %   ASI nanoislands and vertices
    
    properties
        arrayType   % (string)      ASI lattice type: square, kagome, brickwork, ...
        vertex      % (struct)      Contains information about each vertex

        % (struct)     Contains information about each nanoisland
        magnet = struct('posColX','posRowY','indexFlag','indA','indB','orientation',...
            'forkType','nbrVertex')    
        image       % (struct)      Contains
    end
    
    methods
        function obj = asi(inputArg1,inputArg2)
            %ASI Construct an instance of this class
            %   Detailed explanation goes here
            obj.Property1 = inputArg1 + inputArg2;
        end
        
        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end

