classdef emd < detect
    % Subclass EMD of superclass DETECT
    %   Contains functions relevant for processing data for EMD calculation
    
    properties
        Property1
    end
    
    methods
        function outputImg = emd(inputArg1,inputArg2)
            %EMD Construct an instance of this class
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

