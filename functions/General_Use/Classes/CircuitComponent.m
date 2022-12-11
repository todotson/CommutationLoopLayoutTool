classdef CircuitComponent
    %CircuitComponent: Storage Class for Component Footprints
    %   Detailed explanation goes here
    
    properties
        ID
        Footprint
        Land_Pattern  
        Terminals
        Rotation
        Units %Units of measurement. Default is 'mm'
        TTable
        Shift %Struct for use with shifting components around the layout
        LeftOf
        Above
        Right %A string identifying 
        Up
    end
    
    methods
        function obj = CircuitComponent(dimensions, ID, Terminals)
            %CircuitComponent Construct an instance of this class
            %   Detailed explanation goes here
            obj.ID = ID;
            obj.Footprint = obj.ID.* ones(dimensions);
            obj.Land_Pattern = zeros(dimensions);
            obj.Terminals = struct;
            for i=1:length(Terminals)
                obj.Terminals(i).Index = Terminals{i};
                %%%%%%%%%%%%%%%% %%%%%%%%%%%%%%%% %%%%%%%%%%%%%%%%
                %%This one needs work.
                 if all(diff(obj.Terminals(i).Index)==1)
                     obj.Terminals(i).Excitations = mean(obj.Terminals(i).Index); %%Will only assign excitations for terminals with adjacent cells.
                 else
                     obj.Terminals(i).Excitations = double([]);
                 end
                  %%%%%%%%%%%%%%%% %%%%%%%%%%%%%%%% %%%%%%%%%%%%%%%%
                obj.Terminals(i).Net  = i ;
                obj.Land_Pattern(obj.Terminals(i).Index) = i;
            end
            obj.Rotation = 0;
%             obj.Excitations = struct;
            obj.Units = sprintf('mm');
            obj.TTable = table;
            obj.Shift = struct;
            obj.LeftOf =  char;
            obj.Above = char;
            obj.Right = 0;
            obj.Up = 0;
        end
        
        function obj = loadCircuitNets(obj,Nets)
            for i=1:length(Nets)
                obj.Terminals(i).Net = Nets(i);
                obj.Land_Pattern(obj.Terminals(i).Index) = obj.Terminals(i).Net;
            end
        end 
        %degrees==0,90,180,270;
        function obj = assignRotation(obj, degrees)
            outputArg1 = 0;
            switch degrees
                case '90'
                    obj.Land_Pattern = rot90(obj.Land_Pattern,1);
                    obj.Footprint = rot90(obj.Footprint,1);
                    obj.Rotation = 90;
                case '180'
                    obj.Land_Pattern = rot90(obj.Land_Pattern,2);
                    obj.Footprint = rot90(obj.Footprint,2);
                    obj.Rotation = 180;
                case '270'
                    obj.Land_Pattern = rot90(obj.Land_Pattern,3);
                    obj.Footprint = rot90(obj.Footprint,3);
                    obj.Rotation = 270;
                case '0'
                otherwise
                    outputArg1 = -1;
                    sprintf('Error:Invalid Rotation')
            end
        end
        function obj = assignShifting(obj, direction, distance, reset)
            if (reset == 1)
                obj.Shift = struct;
                return;
            end
            obj.Shift.(direction) = distance;
        end
        function obj = assignSpacingRequirements(obj, right, up, reset)
            if (reset == 1)
                obj.Right= 0;
                obj.Up = 0;
                return;
            end
            obj.Right = right;
            obj.Up = up;
        end
        function obj = loadSpacingIntoShift(obj)
            obj = obj.assignShifting('right',obj.Right, 1);
            if(~isempty(obj.LeftOf))
                obj = obj.assignShifting('right', obj.Right, 0);
            end
            if(~isempty(obj.Above))
                obj = obj.assignShifting('up', obj.Up, 0);
            end
        end
        function obj = identifyAdjacentComponents(obj, TTable)
            TTable1 = sortrows(TTable);
            obj.TTable = TTable1;
            obj.LeftOf  = TTable1.Right_of{obj.ID};
            obj.Above =  TTable1.Below{obj.ID};
        end
        function obj = implementSeqPairSpacing(obj, TTable, right, up)
            obj = obj.identifyAdjacentComponents(TTable);
            obj = obj.assignSpacingRequirements(right, up, 0);
            obj = obj.loadSpacingIntoShift();
        end
    end
end
