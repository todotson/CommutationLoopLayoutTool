classdef Netlist
    %Netlist object Summary of this class goes here
    % Stores data from the netlist and layout matrix and implements the
    % routing algorithm.
    
    properties
        Matrix % Struct that contains the layout matrix.
        %         Constructor function accepts a matrix as input.
        %         This input matrix is stored in Matrix.Layer1.
        Base_Matrix %The initial matrix loaded into the Netlist. Needed for assigning Excitations.
        Components % Struct which stores component objects within the Netlist Object
        Nets;
        Stackup % Struct with fields named after layers(Stackup.Layer1, Stackup.Layer2, etc.). Fields identify which nets are present on each layer.
        Vias % Struct with fields named after nets(Vias.Net1, Vias.Net2, etc.). Fields contain an array of indices each via for a single net.
        Rules %Struct with fields named after a logical rule check. Each field contains a single boolean.
        ComponentMasks %Struct with fields mapping the location of components within the matrix.
        Holes % Struct that acts as a handler for FH2 Hole objects. Fields are named after the ID that is used to identify them in FH2, and contain information parameterizing each hole.
        Excitations
        Netlist_Graph %Graphical data related to the netlist. Accepted as an input.
        FH2_Command % Struct that contains a series of commands to be saved as a FH2 simulation file.
        FH2_Units% Layout grid cell size(default is mm)
        FH2_interLayerThickness;%Distance between conductive PCB layers. Default is 12.
        FH2_Datum% Datums used to define FH2 Objects.
    end
    
    methods
        function obj = Netlist(Matrix, Stackup, Vias, Rules, ComponentMasks, Input_Components, Netlist_Graph)
            %UNTITLED2 Construct an instance of this class
            %   Detailed explanation goes here
            fields = struct('Stackup',[],'Vias',[], 'Rules',[]);
            
            if isstruct(Stackup)
                fields.Stackup = fieldnames(Stackup);
                shadow_Stackup = Stackup;
            else
                shadow_Stackup = struct;%Initialize Stackup variable
            end
            obj.Stackup = shadow_Stackup;
            
            shadow_Matrix = struct('Layer1', struct);
            if ismatrix(Matrix)%Load the matrix into the Netlist object using a shadow variable.
                
                shadow_Matrix.Layer1 = Matrix;
            else
                shadow_Matrix.Layer1 = zeros(1);%('Root',[]);
            end
            obj.Matrix = shadow_Matrix;
            obj.Base_Matrix = shadow_Matrix.Layer1;
            %Extract unique nets from layout matrix
            shadow_Nets = unique(shadow_Matrix.Layer1);
            %             shadow_Nets = find(shadow_Nets);
            obj.Nets = shadow_Nets(shadow_Nets & shadow_Nets);
            
            if isstruct(Vias)%Load the struct into the Netlist object using a shadow variable.
                shadow_Vias= Vias;
            else
                shadow_Vias = struct;
            end
            obj.Vias = shadow_Vias;
            
            
            if isstruct(Rules)%Load the struct into the Netlist object using a shadow variable.
                shadow_Rules = Rules;
            else
                shadow_Rules = struct;
            end
            obj.Rules = shadow_Rules;
            
            if isstruct(ComponentMasks)%Load the struct into the Netlist object using a shadow variable.
                shadow_ComponentMasks = ComponentMasks;
            else
                shadow_ComponentMasks = struct;
            end
            obj.ComponentMasks = shadow_ComponentMasks;
            if isempty(Input_Components)
                obj.Components = struct([]);
            else
                obj.Components = Input_Components;
            end
            
            if isempty(Netlist_Graph)
                Shadow_Netlist_Graph = [];
            else
                Shadow_Netlist_Graph = Netlist_Graph;
            end
            
            obj.Netlist_Graph = Shadow_Netlist_Graph;
            Shadow_Holes = struct();
            obj.Holes = Shadow_Holes;
            newline = '\n';
            FH2Command_Header = struct('Preamble', ...
                sprintf('*This is an example Preamble. Please replace me with a seeded ID.\n'));
%             FH2Command_Header_DefaultValues_Shadow  = sprintf('*  R/cm = 15 ohm / 0.4 cm = 37.5 Ohm/cm');
%             FH2Command_Header_DefaultValues_Shadow = [FH2Command_Header_DefaultValues_Shadow ...
%                 newline '*  L/cm = 14.8 / (2*pi*6e8) / 0.4 cm = 9.81 nH/cm' ];
            FH2Command_Header_DefaultValues_Shadow = ['.units mm' newline ...
                '.default sigma = 3.5e7' ...
                newline '*' ...
                newline '*' ...
                newline '*' ...
            ];
%                     FH2Command_Header_DefaultValues_Shadow = ['.units mm' newline ...
%                 '.default sigma = 3.5e7' ...
%                 newline '.default units = "mm"' ...
%                 newline '*' ...
%                 newline '*' ...
%                 newline '*' ...
%             ];
            FH2Command_Header.DefaultValues = FH2Command_Header_DefaultValues_Shadow;
            
            FH2Command_Ending_Shadow =  sprintf('.freq fmin=6e8 fmax=6e8 ndec=1');
            FH2Command_Ending_Shadow = [FH2Command_Ending_Shadow newline sprintf('.end')];
            FH2Command_Ending = FH2Command_Ending_Shadow;
            shadow_FH2Command = struct('Header', FH2Command_Header, 'Body', struct(), 'Ending', struct( 'Frequency' , FH2Command_Ending ));
            obj.FH2_Command = shadow_FH2Command;
            obj.Excitations = struct;
            obj.FH2_Units = 'mm';
            obj.FH2_interLayerThickness = struct;
            obj.FH2_interLayerThickness.Layer1 = struct('TopLayer', 1, 'BottomLayer', 2, 'Weight', ['2oz'], 'InterlayerDistance', 0.0347);%Interlayer distance for 1.6mm board% 0.0347);
            %obj.FH2_interLayerThickness.Layer1.totalInterlayerDistance= obj.FH2_interLayerThickness.Layer1.InterlayerDistance + 0.487; %Total distance is equal to half of the copper weight(here, 2oz) x 2, plus the specified interlayer distance
             obj.FH2_interLayerThickness.Layer1.totalInterlayerDistance= obj.FH2_interLayerThickness.Layer1.InterlayerDistance +0;%+ 0.487; %Total distance is equal to half of the copper weight(here, 2oz) x 2, plus the specified interlayer distance
            obj.FH2_interLayerThickness.Layer2 = struct('TopLayer', 1, 'BottomLayer', 2, 'Weight', ['2oz'], 'InterlayerDistance',  0.0347);%Interlayer distance for 1.6mm board% 0.0347);
            obj.FH2_interLayerThickness.Layer2.totalInterlayerDistance= obj.FH2_interLayerThickness.Layer2.InterlayerDistance +0.31; %Total distance is equal to half of the copper weight(here, 2oz) x 2, plus the specified interlayer distance
            obj.FH2_interLayerThickness.Layer3 = struct('TopLayer', 1, 'BottomLayer', 2, 'Weight', ['2oz'], 'InterlayerDistance',  0.0347);%Interlayer distance for 1.6mm board% 0.0347);
            obj.FH2_interLayerThickness.Layer3.totalInterlayerDistance= obj.FH2_interLayerThickness.Layer3.InterlayerDistance + 0.73; %Total distance is equal to half of the copper weight(here, 2oz) x 2, plus the specified interlayer distance
             obj.FH2_interLayerThickness.Layer4 = struct('TopLayer', 1, 'BottomLayer', 2, 'Weight', ['2oz'], 'InterlayerDistance',  0.0347);%Interlayer distance for 1.6mm board% 0.0347);
            obj.FH2_interLayerThickness.Layer4.totalInterlayerDistance= obj.FH2_interLayerThickness.Layer4.InterlayerDistance + 0.31; %Total distance is equal to half of the copper weight(here, 2oz) x 2, plus the specified interlayer distance
        obj.FH2_interLayerThickness.Layer5 = struct('TopLayer', 1, 'BottomLayer', 2, 'Weight', ['2oz'], 'InterlayerDistance',  0.0347);%Interlayer distance for 1.6mm board% 0.0347);
            obj.FH2_interLayerThickness.Layer5.totalInterlayerDistance= obj.FH2_interLayerThickness.Layer5.InterlayerDistance + 0.31; %Total distance is equal to half of the copper weight(here, 2oz) x 2, plus the specified interlayer distance

            obj.FH2_Datum = struct;
        end
        function [outputArg, obj] = BBRouteNet2(obj,Net)
            % BBRoutingAlgorithm This is the bounding box algorithm. This
            % will route nets vertically through the PCB using polygons.The
            % function will route a single net in the layout, and update
            % the layout matrix struct, holes struct, excitations
            % struct, and the vias struct as necessary.
            % pours.
            %   Detailed explanation goes here
            
            %Load Shadow Registers
            shadow_Nets = obj.Nets;
            if ~ismember(Net, shadow_Nets)
                sprintf('Error in Netlist.BBRouteNet; Invalid Net')
                outputArg = -1;
                return
            end
            shadow_Matrix2 = obj.Matrix;
            shadow_MatrixFields = fields(shadow_Matrix2);
            shadow_Matrix = obj.Matrix.Layer1;
            shadow_Stackup = obj.Stackup;
            if isempty(fields(shadow_Stackup))
                shadow_Stackup.Layer1 = struct;
            end
            shadow_Mask = arrayfun(@(x) isequal(x,Net), shadow_Matrix);%Find all of the array elements that contain the integer 'Net'
            shadow_Holes = obj.Holes;
            shadow_Vias = obj.Vias;
            %%%Shadow_Matrix2
            shadow_Mask_Indices = find(shadow_Mask);%Extract their indices
            [row, col] = ind2sub(size(shadow_Matrix), shadow_Mask_Indices);%Convert Indices to Subscripts for 2Darray
            BBcorner1 = [min(row), min(col)];
            BBcorner2 = [max(row), max(col)];
            Matrix_Corner1 = [1 1];
            Matrix_Corner2 = size(shadow_Matrix);
            NetMask_boundingBox = seqPairBoundingBox(BBcorner1,BBcorner2,Matrix_Corner1,Matrix_Corner2);%%Create a bounding box that covers all of the elements in the matrix containing the net.
            netPolygonPour = NetMask_boundingBox;
            %%%For Loop Here. Iterate through all of the layers of
            %%%shadow_Matrix2
            for i = 1:length(shadow_MatrixFields)
                shadow_Matrix = shadow_Matrix2.(shadow_MatrixFields{i});
                PolygonMask = shadow_Matrix(NetMask_boundingBox);
                check_For_Other_Nets = find(PolygonMask);
                check_For_Other_Nets2 = PolygonMask(check_For_Other_Nets)~=Net;
                if (any(check_For_Other_Nets2))
                    %%add a flag here
                    flagset = 1;
                else
                    %%reset flag
                    %%Stop iterating
                    number_of_layers = length(fields(shadow_Stackup));
                    shadow_Matrix(NetMask_boundingBox) = Net;
                    shadow_Matrix2.(shadow_MatrixFields{i}) = shadow_Matrix;
                    currentLayer = i;
                    flagset = 0;
                    break;
                end
            end
            if(flagset)
                %Update Layers
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                number_of_layers = length(fields(shadow_Stackup))+1;
                currentLayer = number_of_layers;
                newLayer = sprintf('Layer%i', number_of_layers);
                newNet = sprintf('Net%i', Net);
                %%netPolygonPour = NetMask_boundingBox;
                newStackupEntry = struct('Net', Net, 'Polygon', netPolygonPour);
                shadow_Stackup.(newLayer) = struct(newNet, newStackupEntry) ;
                temp = zeros(size(shadow_Matrix));
                temp(NetMask_boundingBox) = Net;
                shadow_Matrix2.(newLayer) = temp;
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %Update Holes
                %Need to update this.
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                holeMask = zeros(size(PolygonMask));
                holeMask = holeMask&holeMask;
                holeMask(check_For_Other_Nets(check_For_Other_Nets2 == 1)) = (1&1) ;
                holeMaskIndex = find(holeMask);
                for i = 1:length(holeMaskIndex)
                    number_of_holes = length(fields(shadow_Holes))+1;
                    newHole = sprintf('Hole%i', number_of_holes);
                    holeTerminalLayer = sprintf('Layer%i', number_of_layers) ;
                    holeMask2 = zeros(size(shadow_Matrix));
                    holeMask3 = zeros(size(NetMask_boundingBox(NetMask_boundingBox == 1)));
                    holeMask3(holeMaskIndex(i)) = 1;
                    holeMask2(NetMask_boundingBox) =  holeMask3;
                    newHoleEntry = struct(newHole, number_of_holes, ...
                        'terminalLayer', holeTerminalLayer, 'holeMask', holeMask2);
                    shadow_Holes.(newHole) = newHoleEntry;
                end
            else
                %Update Layers
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                newLayer = sprintf('Layer%i', currentLayer);
                newNet = sprintf('Net%i', Net);
                %netPolygonPour = NetMask_boundingBox;
                newStackupEntry = struct('Net', Net, 'Polygon', netPolygonPour);
                shadow_Stackup.(newLayer).(newNet) = newStackupEntry ;
                temp = shadow_Matrix;
                temp(NetMask_boundingBox) = Net;
                shadow_Matrix2.(newLayer) = temp;
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %Update vias
            %Place a via that goes from the top layer until it reaches
            %the current layer. Function will not create vias if the
            %current layer of this net is the top layer.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if (currentLayer ~=1)
                viaMask = zeros(size(PolygonMask));
                viaMask = viaMask&viaMask;
                viaMask(check_For_Other_Nets(check_For_Other_Nets2 == 0)) = (1&1) ;
                viaMaskIndex = find(viaMask);
                for i = 1:length(viaMaskIndex)
                    number_of_vias = length(fields(shadow_Vias))+1;
                    newVia = sprintf('Via%i', number_of_vias);
                    viaTerminalLayer = sprintf('Layer%i', number_of_layers);
                    viaMask2 = zeros(size(shadow_Matrix));
                    viaMask3 = zeros(size(NetMask_boundingBox(NetMask_boundingBox == 1)));
                    viaMask3 (viaMaskIndex(i)) = 1;
                    viaMask2(NetMask_boundingBox) =  viaMask3;
                    viaType = sprintf('Blind');
                    newViaEntry = struct('ViaID', number_of_vias, ...
                        'terminalLayer', viaTerminalLayer, 'viaMask', ...
                        viaMask2, 'Type', viaType, 'Net', Net);
                    shadow_Vias.(newVia) = newViaEntry;
                end
            end
            
            obj.Stackup = shadow_Stackup;
            obj.Holes = shadow_Holes;
            obj.Vias = shadow_Vias;
            obj.Holes = shadow_Holes;
            obj.Matrix = shadow_Matrix2;
            
            variableDump = struct('shadow_Stackup', shadow_Stackup, ...
                'shadow_Matrix',shadow_Matrix,'shadow_Nets',shadow_Nets,...
                'BBcorner1', BBcorner1, 'BBcorner2', BBcorner2, 'Matrix_Corner1',...
                Matrix_Corner1, 'Matrix_Corner2', Matrix_Corner2, ...
                'NetMask_boundingBox',NetMask_boundingBox, 'PolygonMask', PolygonMask,...
                'check_For_Other_Nets', check_For_Other_Nets, 'check_For_Other_Nets2',...
                check_For_Other_Nets2);
            outputArg = variableDump;
            
            variableDump_withLines124_135 = variableDump;
            variableDump_withLines124_135.number_of_layers = number_of_layers;
            if(exist('newLayer') == 1) variableDump_withLines124_135.newLayer = newLayer; end
            variableDump_withLines124_135.netPolygonPour = netPolygonPour;
            variableDump_withLines124_135.shadow_Matrix2 = shadow_Matrix2;
            if(exist('holeMask') == 1) variableDump_withLines124_135.holeMask = holeMask; end
            if(exist('holeMaskIndex') == 1) variableDump_withLines124_135.holeMaskIndex = holeMaskIndex; end
            if(exist('holeMask2') == 1) variableDump_withLines124_135.holeMask2 = holeMask2; end
            if(exist('holeMask3') == 1) variableDump_withLines124_135.holeMask3 = holeMask3; end
            if(exist('newHoleEntry') == 1) variableDump_withLines124_135.newHoleEntry = newHoleEntry; end
            if(exist('newHoleEntry') == 1) variableDump_withLines124_135.holeMaskIndex = holeMaskIndex; end
            variableDump_withLines124_135.shadow_Holes = shadow_Holes;
            variableDump_withLines124_135.shadow_Vias = shadow_Vias;
            variableDump_withLines124_135.flagset = flagset;
            variableDump_withLines124_135.currentLayer = currentLayer;
            % outputArg = variableDump_withLines124_135;
            outputArg = orderfields(variableDump_withLines124_135);
            
        end
        %%FH2_AssignExcitations Can beused to set and reset excitations
        %%within the circuit.
        function [outputArg1, obj] = FH2_AssignExcitations2(obj)
            shadow_ComponentMasks = obj.ComponentMasks;
            Components = fields(shadow_ComponentMasks);
            shadow_Excitations = struct;
            NodesEntry1 = struct;
            for i = 1:length(Components)
                CurrentComponent = sprintf('%s', Components{i});
                shadow_BaseMatrix = obj.Base_Matrix;
                shadow_BaseMatrix(~shadow_ComponentMasks.(CurrentComponent)) = 0;
                sz= size(shadow_BaseMatrix);
                componentPadIndices = [];
                [componentPadIndices(1,:) componentPadIndices(2,:)] = ind2sub(sz, find(shadow_BaseMatrix));
                %======================================================================
                %This part needs work. There is a bug here that prevents
                %the use of circular pads. For the time being, we will
                %constrain our problem only to pads occupying a single
                %column.
                componentPadIndicesVertical = flipud(rot90(componentPadIndices,1));
                componentPadIndicesHorizontal = sortrows(flipud(rot90(componentPadIndices,1)));
                Diff1 = diff(componentPadIndicesVertical,1,1);
                Diff2 = diff(componentPadIndicesHorizontal,1,1);
                Breakpoints = find(Diff1 ~=0 & Diff1 ~= 1);
                [row_Diff1, col_Diff1] = size(Diff1);
                [row_Diff2, col_Diff2] = size(Diff2);
                %%Try to identify whether to use rows or columns to
                %%symbolize excitations by measuring the length of the
                %%Breakpoints array
                if isequal(length(Breakpoints), length(Diff1(:,1)))
                    Breakpoints = find(Diff2 ~=0 & Diff2 ~= 1);
                    [row_Breakpoints, col_Breakpoints]  = ind2sub([row_Diff2 col_Diff2], Breakpoints);
                    componentPadIndices = componentPadIndicesHorizontal;
                else
                    [row_Breakpoints, col_Breakpoints]  = ind2sub([row_Diff1 col_Diff1], Breakpoints);
                    componentPadIndices = componentPadIndicesVertical;
                end
                %======================================================================
                
                NodesEntryField1 =  sprintf('%s',CurrentComponent); %Struct to store components. Branches into Terminal Structs
                if ~isempty(Breakpoints)
                    for i=1:length(Breakpoints)/2
                        %                         NodesEntryField = sprintf('%sTerminal%i',CurrentComponent,  i);
                        NodesEntry2 = struct;%Struct to store terminals. Pointed to from Component branch.
                        switch i
                            case 1
                                NodesEntry2.Cells = componentPadIndices(1:row_Breakpoints(i),:);
                                
                            otherwise
                                NodesEntry2.Cells = componentPadIndices(row_Breakpoints(i-1)+1:row_Breakpoints(i),:);
                        end
                        NodesEntry2.Net = shadow_BaseMatrix(NodesEntry2.Cells(1,1), NodesEntry2.Cells(1,2));
                        NodesEntry2.L = length(unique(NodesEntry2.Cells(:,1)));
                        NodesEntry2.H = length(unique(NodesEntry2.Cells(:,2)));
                        NodesEntry2.Node = [mean(NodesEntry2.Cells(:,1)), mean(NodesEntry2.Cells(:,2))];
                        terminalEntry = sprintf('Terminal%i', i);
                        NodesEntry2.FH2Handle = sprintf('%s%s_GP',CurrentComponent, terminalEntry);%FH2 reference used to name this node
                        NodesEntry1.(terminalEntry) = NodesEntry2;
                        shadow_Excitations.(NodesEntryField1) = NodesEntry1;
                        
                    end
                    terminalEntry = sprintf('Terminal%1.0f', length(Breakpoints)/2 +1);
                    NodesEntry2.Cells = componentPadIndices(row_Breakpoints(end)+1:end,:);
                    NodesEntry2.Net = shadow_BaseMatrix(NodesEntry2.Cells(1,1), NodesEntry2.Cells(1,2));
                    NodesEntry2.L = length(unique(NodesEntry2.Cells(:,1)));
                    NodesEntry2.H = length(unique(NodesEntry2.Cells(:,2)));
                    NodesEntry2.Node = [mean(NodesEntry2.Cells(:,1)), mean(NodesEntry2.Cells(:,2))];
                    NodesEntry2.FH2Handle = sprintf('%s%s_GP',CurrentComponent, terminalEntry);%FH2 reference used to name this node
                    NodesEntry1.(terminalEntry) = NodesEntry2;
                    shadow_Excitations.(NodesEntryField1) = NodesEntry1;
                end
            end
            obj.Excitations = shadow_Excitations;
            outputArg1 = struct('Components', Components, ...
                'CurrentComponent', CurrentComponent,...
                'shadow_BaseMatrix',shadow_BaseMatrix,...
                'sz',sz,...
                'componentPadIndices',componentPadIndices,...
                'Diff1',Diff1, ...
                'Diff2', Diff2, ...
                'Breakpoints',Breakpoints, ...
                'row_Diff1',row_Diff1, ...
                'col_Diff1',col_Diff1, ...
                'row_Breakpoints',row_Breakpoints ...
                );
        end
        
                %%FH2_AssignExcitations Can beused to set and reset excitations
        %%within the circuit.
        function [outputArg1, obj] = FH2_AssignExcitations(obj)
            debug = struct;
            shadow_ComponentMasks = obj.ComponentMasks;
            Components = fields(shadow_ComponentMasks);
            shadow_NetlistGraph = obj.Netlist_Graph;
            shadow_Edges = shadow_NetlistGraph.Edges;
            shadow_Excitations = struct;
            NodesEntry1 = struct;           
            for i = 1:length(Components)
                CurrentComponent = sprintf('%s', Components{i});
                shadow_BaseMatrix = obj.Base_Matrix;
                shadow_BaseMatrix(~shadow_ComponentMasks.(CurrentComponent)) = 0;
                sz= size(shadow_BaseMatrix);
                componentPadIndices = [];
                [componentPadIndices(1,:) componentPadIndices(2,:)] = ind2sub(sz, find(shadow_BaseMatrix));
                %======================================================================
                %This part needs work. There is a bug here that prevents
                %the use of circular pads. For the time being, we will
                %constrain our problem only to pads occupying a single
                %column.
                componentPadIndicesVertical = flipud(rot90(componentPadIndices,1));
                componentPadIndicesHorizontal = sortrows(flipud(rot90(componentPadIndices,1)));
                Diff1 = diff(componentPadIndicesVertical,1,1);
                Diff2 = diff(componentPadIndicesHorizontal,1,1);
                Breakpoints = find(Diff1 ~=0 & Diff1 ~= 1);
                [row_Diff1, col_Diff1] = size(Diff1);
                [row_Diff2, col_Diff2] = size(Diff2);
                %%Try to identify whether to use rows or columns to
                %%symbolize excitations by measuring the length of the
                %%Breakpoints array
                if isequal(length(Breakpoints), length(Diff1(:,1)))
                    Breakpoints = find(Diff2 ~=0 & Diff2 ~= 1);
                    [row_Breakpoints, col_Breakpoints]  = ind2sub([row_Diff2 col_Diff2], Breakpoints);
                    componentPadIndices = componentPadIndicesHorizontal;
                else
                    [row_Breakpoints, col_Breakpoints]  = ind2sub([row_Diff1 col_Diff1], Breakpoints);
                    componentPadIndices = componentPadIndicesVertical;
                end
                %======================================================================
                
                NodesEntryField1 =  sprintf('%s',CurrentComponent); %Struct to store components. Branches into Terminal Structs
                if ~isempty(Breakpoints)
                    for ii=1:length(Breakpoints)/2
                        %                         NodesEntryField = sprintf('%sTerminal%i',CurrentComponent,  i);
                        NodesEntry2 = struct;%Struct to store terminals. Pointed to from Component branch.
                        switch ii
                            case 1
                                NodesEntry2.Cells = componentPadIndices(1:row_Breakpoints(ii),:);
                                
                            otherwise
                                NodesEntry2.Cells = componentPadIndices(row_Breakpoints(ii-1)+1:row_Breakpoints(ii),:);
                        end
                        terminalEntry = sprintf('Terminal%i', ii);
                        debug(i).(CurrentComponent).TerminalEntry = terminalEntry;
                        Nets_ = shadow_Edges.Net;
                        terminals = struct;
                        for iii = 1:length(Nets_)
                            comparison = struct;
                            comparisonString = strcat(CurrentComponent, terminalEntry);
                            code = shadow_Edges.code{iii};
                            comparison.comparisonString = comparisonString;
                            comparison.code = code;
                            terminals(iii).comparison = comparison;
                            if contains(code, comparisonString)
                                 NodesEntry2.Net = sscanf(Nets_{iii}, 'Net%d');
                                 break;
                            end
                            
                        end
                        debug(i).(CurrentComponent).Terminals =  terminals;
%                         NodesEntry2.Net = shadow_BaseMatrix(NodesEntry2.Cells(1,1), NodesEntry2.Cells(1,2));
                        NodesEntry2.L = length(unique(NodesEntry2.Cells(:,1)));
                        NodesEntry2.H = length(unique(NodesEntry2.Cells(:,2)));
                        NodesEntry2.Node = [mean(NodesEntry2.Cells(:,1)), mean(NodesEntry2.Cells(:,2))];
                        NodesEntry2.FH2Handle = sprintf('%s%s_GP',CurrentComponent, terminalEntry);%FH2 reference used to name this node
                        NodesEntry1.(terminalEntry) = NodesEntry2;
                        shadow_Excitations.(NodesEntryField1) = NodesEntry1;
                        
                    end
                    %terminalEntry = sprintf('Terminal%1.0f', length(Breakpoints)/2 +1);
                    terminalEntry = sprintf('Terminal%i', length(Breakpoints)/2 +1);
                    NodesEntry2.Cells = componentPadIndices(row_Breakpoints(end)+1:end,:);
                    % NodesEntry2.Net = shadow_BaseMatrix(NodesEntry2.Cells(1,1), NodesEntry2.Cells(1,2));
                    Nets_ = shadow_Edges.Net;
                    terminals = struct;
                    for iii = 1:length(Nets_)
                        comparisonString = strcat(CurrentComponent, terminalEntry);
                        code = shadow_Edges.code{iii};
                        terminals(iii).comparison = comparison;
                        if contains(code, comparisonString)
                            NodesEntry2.Net = sscanf(Nets_{iii}, 'Net%d');
                            break;
                        end
                    end

                    NodesEntry2.L = length(unique(NodesEntry2.Cells(:,1)));
                    NodesEntry2.H = length(unique(NodesEntry2.Cells(:,2)));
                    NodesEntry2.Node = [mean(NodesEntry2.Cells(:,1)), mean(NodesEntry2.Cells(:,2))];
                    NodesEntry2.FH2Handle = sprintf('%s%s_GP',CurrentComponent, terminalEntry);%FH2 reference used to name this node
                    NodesEntry1.(terminalEntry) = NodesEntry2;
                    shadow_Excitations.(NodesEntryField1) = NodesEntry1;
                end
            end
            obj.Excitations = shadow_Excitations;
            outputArg1 = struct('Components', Components, ...
                'CurrentComponent', CurrentComponent,...
                'shadow_BaseMatrix',shadow_BaseMatrix,...
                'sz',sz,...
                'componentPadIndices',componentPadIndices,...
                'Diff1',Diff1, ...
                'Diff2', Diff2, ...
                'Breakpoints',Breakpoints, ...
                'row_Diff1',row_Diff1, ...
                'col_Diff1',col_Diff1, ...
                'row_Breakpoints',row_Breakpoints, ...
                'debug', debug...
                );
        end
                        %%FH2_AssignExcitations Can beused to set and reset excitations
        %%within the circuit.
        function [obj, outputArg1] = FH2_AssignExcitations3(obj)
            debug = struct;
            shadow_ComponentMasks = obj.ComponentMasks;
            Components = fields(shadow_ComponentMasks);
            shadow_components = obj.Components;
            shadow_NetlistGraph = obj.Netlist_Graph;
            shadow_Edges = shadow_NetlistGraph.Edges;
            shadow_Excitations = struct;
            NodesEntry1 = struct;
             %Struct to store components. Branches into Terminal Struct
                % NodesEntry2.Net = shadow_BaseMatrix(NodesEntry2.Cells(1,1), NodesEntry2.Cells(1,2));
                Nets_ = shadow_Edges.Net;
                NodesEntry1 = struct;
                 for i = 1:length(Components)
                     CurrentComponent = shadow_components.(Components{i});
                     shadow_BaseMatrix = obj.Base_Matrix;
                     shadow_BaseMatrix(~shadow_ComponentMasks.(Components{i})) = 0;
                      NodesEntryField1 =  sprintf('%s',Components{i});
                      Terminals = CurrentComponent.Terminals;
                      NodesEntry1 = struct;
                      NodesEntry2 = struct;
                      for ii = 1:length(Terminals)
                          CurrentNet = Terminals(ii).Net;
                          componentPadIndices = arrayfun(@(x) x == CurrentNet, shadow_BaseMatrix);
                          ind = find(componentPadIndices);
                          sz = size(shadow_BaseMatrix);
                          [row,col] = ind2sub(sz,ind);
                          Cells = zeros(length(row), 2);
                          Cells(:, 1) = row;
                          Cells(:, 2) = col;
                          TerminalEntry = sprintf('Terminal%d', ii);
                          NodesEntry2.Net = CurrentNet;
                          NodesEntry2.Cells = Cells;
                          NodesEntry2.L = length(unique(NodesEntry2.Cells(:,1)));
                          NodesEntry2.H = length(unique(NodesEntry2.Cells(:,2)));
                          NodesEntry2.Node = [mean(NodesEntry2.Cells(:,1)), mean(NodesEntry2.Cells(:,2))];
                          NodesEntry2.FH2Handle = sprintf('%s%s_GP',Components{i}, TerminalEntry);%FH2 reference used to name this node
                          NodesEntry1.(TerminalEntry) = NodesEntry2;
                      end
                      shadow_Excitations.(Components{i}) = NodesEntry1;
                 end
            obj.Excitations = shadow_Excitations;
            outputArg1 = 0;
    end
        %%FH2_CreatePlanes Can beused to generate the string for all
        %%excitations in the FEA model.
        function [outputArg1, obj] = FH2_CreatePlanes2(obj)
            shadow_Stackup = obj.Stackup;
            shadow_Excitations = obj.Excitations;
            shadow_Vias = obj.Vias;
            shadow_FH2_Command = obj.FH2_Command;
            Excitations_Components = fields(shadow_Excitations);%Excitation fields
            Layers = fields(shadow_Stackup);
            %Thickness = obj.FH2_interLayerThickness.Layer1.InterlayerDistance;%%For now, all inter-layers have the same thickness.
            Thickness1 = obj.FH2_interLayerThickness; %Gives each inter-layer distance different values
            %Skin depth calculation. Default
            %frequency is 10MHz, compareable with the default
            %value for Ansys EM Workbench.
            freq = 1e7;%%Maximum Test Frequency = 10 MHz
            rho = 1.678; %%CopperResistivity (muOhm*cm)
            rho_ = rho * 1e-7;%%Conversion to Ohm* mm
            permeability = 4*pi*1e-7;%%Permeability of Air
            Cu_RelativePermeability = 1;%Relative Permeability of copper
            skinDepth = 1e3 ./ sqrt(freq * (1/rho_) * Cu_RelativePermeability * permeability);%%Skin Depth(mm)
            Hits = struct; %Search hit references
            Hit1 = struct; % Used forentries into the Hits struct
            debug = struct;
            for i=1:length(Layers)
                Nets_ = fields(shadow_Stackup.(Layers{i}));
                if ~isempty(Nets_)
                    
                    for ii=1:length(Nets_)
                        Polygon = shadow_Stackup.(Layers{i}).(Nets_{ii}).Polygon;
                        %%Find the vertices this polygon within the
                        %%simulation coordinate system.
                        [PolygonRows, PolygonCols] = find(Polygon);
                        x = [min(PolygonRows), max(PolygonRows), max(PolygonRows)];
                        y = [ min(PolygonCols), min(PolygonCols),  max(PolygonCols)];
                        %  Segmentation calculation
                        PolygonHeight = floor((max(PolygonRows)- min(PolygonRows)) ./ skinDepth);
                        PolygonLength = floor((max(PolygonCols)- min(PolygonCols)) ./ skinDepth);
%                         segx = [temp_segx, temp_segx, temp_segx];
%                         segy = [temp_segy, temp_segy, temp_segy];
                        segx = [PolygonLength, PolygonLength, PolygonLength];
                        segy = [PolygonHeight, PolygonHeight, PolygonHeight];
                        %Create the name of the plane. Planes are named
                        %after their respective nets...
                        str = Nets_{ii};
                        %Find excitations and nodes. Requires a search...
                        %==============================================
                        %==============================================
                        %==============================================
                        %==============================================
                        
                        
                        %Search Algorithm for finding Excitation references
                        %in the plane coordinates. Needed for mating vias,
                        %holes, and excitations.
                        %==============================================
                        %==============================================
                        %==============================================
                        %==============================================
                        
                        
                        if ~isempty(Excitations_Components)
                            for iii = 1:length(Excitations_Components)
                                Excitations_Components_Terminals = fields(shadow_Excitations.(Excitations_Components{iii}));
                                if ~isempty(Excitations_Components_Terminals)
                                    for iiii = 1:length(Excitations_Components_Terminals)
                                        referenceNet = sscanf(Nets_{ii},'Net%d'); %Comparison Net
                                        comparisonNet = shadow_Excitations.(Excitations_Components{iii}).(Excitations_Components_Terminals{iiii}).Net;
                                        fieldName1 = sprintf('%s_%s', ...
                                            Excitations_Components{iii}, ...
                                            Excitations_Components_Terminals{iiii});
                                        fieldName2 = sprintf('%s', Nets_{ii});
                                        fieldName3 = sprintf('%s', Layers{i});
                                        %Store the search hits!
                                        if isequal(referenceNet, comparisonNet)
                                            Hits.(fieldName3).(fieldName2).(fieldName1) = shadow_Excitations.(Excitations_Components{iii}).(Excitations_Components_Terminals{iiii});
                                            Hits.(fieldName3).(fieldName2).(fieldName1).Polygon = Polygon;
                                            Hits.(fieldName3).(fieldName2).(fieldName1).PolygonRows = PolygonRows;
                                            Hits.(fieldName3).(fieldName2).(fieldName1).PolygonCols = PolygonCols;
                                            Hits.(fieldName3).(fieldName2).(fieldName1).x = x;
                                            Hits.(fieldName3).(fieldName2).(fieldName1).y = y;
                                            Hits.(fieldName3).(fieldName2).(fieldName1).PolygonHeight = PolygonHeight;
                                            Hits.(fieldName3).(fieldName2).(fieldName1).PolygonLength = PolygonLength;
                                            Hits.(fieldName3).(fieldName2).(fieldName1).segx = segx;
                                            Hits.(fieldName3).(fieldName2).(fieldName1).segy = segy;
                                            Hits.(fieldName3).(fieldName2).(fieldName1).str = str;
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            
            %             Crack the loops for the search and FH2 file authoring
            %             algorithms. Make the code more modular such that its easier
            %             to readand modify.
            FH2Data =struct([]);
            FH2DataOutput = struct([]);
            for i = 1:length(Layers)
                excitationLayer = i;
                Thickness = Thickness1.(Layers{i}).totalInterlayerDistance;
                excitationLayerZAxisCoordinate  = -1 .* (excitationLayer -1)  .*  Thickness;
                Nets_ = fields(Hits.(Layers{i}));
                if ~isempty(Nets_)
                    for ii=1:length(Nets_)
                        str = Nets_{ii};
                        Test = Hits.(Layers{i}).(Nets_{ii});
                        Terminals = fields(Hits.(Layers{i}).(Nets_{ii}));
                        Hits.(Layers{i}).ZAxisCoordinate = excitationLayerZAxisCoordinate;
                        Polygon = Hits.(Layers{i}).(Nets_{ii}).(Terminals{1}).Polygon;
                        PolygonRows = Hits.(Layers{i}).(Nets_{ii}).(Terminals{1}).PolygonRows;
                        PolygonCols = Hits.(Layers{i}).(Nets_{ii}).(Terminals{1}).PolygonCols;
                        x = Hits.(Layers{i}).(Nets_{ii}).(Terminals{1}).x;
                        y = Hits.(Layers{i}).(Nets_{ii}).(Terminals{1}).y;
                        PolygonHeight = Hits.(Layers{i}).(Nets_{ii}).(Terminals{1}).PolygonHeight;
                        PolygonLength = Hits.(Layers{i}).(Nets_{ii}).(Terminals{1}).PolygonLength;
                        segx = Hits.(Layers{i}).(Nets_{ii}).(Terminals{1}).segx;
                        segy = Hits.(Layers{i}).(Nets_{ii}).(Terminals{1}).segy;
                        str = Hits.(Layers{i}).(Nets_{ii}).(Terminals{1}).str;
                        
                        exc = struct;
                        nodes = [];
                        
                        for iii = 1:length(Terminals)
                            hitTerminal  = Hits.(Layers{i}).(Nets_{ii}).(Terminals{iii});
                            hitTerminalNode = hitTerminal.Node;
                            exc(iii).FH2Handle = hitTerminal.FH2Handle;
                            nodes = [nodes; [hitTerminalNode(1), hitTerminalNode(2), ...
                                excitationLayerZAxisCoordinate]];
                        end
                        
                        
                        
                        
 %                     POSSIBLE BUG:     TRY REARRANGING THE VARIABLE:
%                                 nodes = [nodes; ...
%                                     [col,row, excitationLayerZAxisCoordinate] ...
%                                     ];
%                                      TO:
%                                     nodes = [nodes; ...
%                                     [row,col, excitationLayerZAxisCoordinate] ...
%                                     ];
%                                     IF AXES ON THE FH2 PLOT FOR NODES ARE
%                                     INCORRECT
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        shadowViasintoLayers = struct();
                        ViaHits = struct([]);
                        Vias = fields(shadow_Vias);
                        for iii = 1:length(Vias)
                            if strcmp(shadow_Vias.(Vias{iii}).terminalLayer, Layers{i})
                                currentIteration = length(ViaHits)+1;
                                ViaHits(currentIteration).Hit = ...
                                    shadow_Vias.(Vias{iii});
                                exc(length(exc)+1).FH2Handle = Vias{iii};
                                sz = size(ViaHits(currentIteration).Hit.viaMask);
                                ind = find(ViaHits(currentIteration).Hit.viaMask);
                                [row,col] = ind2sub(sz,ind);
                                nodes = [nodes; ...%%%<--------------------------------THIS ONE
                                    [col,row, excitationLayerZAxisCoordinate] ...
                                    ];
                            end
                        end
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        
                        %%Reorganize data before entering it into the
                        %%FH2_Plane function.
                        iteration_count = length(FH2Data)+1;
                        FH2Data(iteration_count).str = str;
                        FH2Data(iteration_count).x = x;
                        FH2Data(iteration_count).y = y;
                        FH2Data(iteration_count).z = ones(3) * excitationLayerZAxisCoordinate;
                        FH2Data(iteration_count).PolygonHeight = PolygonHeight;
                        FH2Data(iteration_count).PolygonLength = PolygonLength;
                        FH2Data(iteration_count).seg =  [PolygonHeight, PolygonLength];
                        FH2Data(iteration_count).str = str;
                        FH2Data(iteration_count).thick = Thickness;
                        FH2Data(iteration_count).rho = [];
                        FH2Data(iteration_count).segwid = [];
                        FH2Data(iteration_count).exc = exc;
                        FH2Data(iteration_count).nodes = nodes;
                        FH2Data(iteration_count).Vias= ViaHits;
                        FH2Data(iteration_count).Vias1 =  Layers{i};
                        FH2Data(iteration_count).Vias2 = shadow_Vias.(Vias{iii}).terminalLayer;
                        %%Store hits into a permanent struct array.
                        FH2DataOutput(iteration_count).Command = FH2Plane(FH2Data(iteration_count).str,...
                            FH2Data(iteration_count).x, FH2Data(iteration_count).y, ...
                            FH2Data(iteration_count).z,FH2Data(iteration_count).thick,...
                            FH2Data(iteration_count).rho,  FH2Data(iteration_count).seg, ...
                            FH2Data(iteration_count).segwid, FH2Data(iteration_count).exc, ...
                            FH2Data(iteration_count).nodes);
                    end
                end
            end
            shadow_FH2_Command.Planes = FH2DataOutput;
            shadow_FH2_Datum = FH2Data;
            obj.FH2_Command = shadow_FH2_Command;
            obj.FH2_Datum.Planes = shadow_FH2_Datum;
            outputArg1 = struct('shadow_Stackup', shadow_Stackup,...
                'shadow_Excitations' , shadow_Excitations,...
                'Layers', struct('Layers', Layers), ...
                'Thickness', Thickness, ...
                'freq', freq, ...
                'rho', rho, ...
                'rho_', rho_, ...
                'permeability', permeability, ...
                'Cu_RelativePermeability', Cu_RelativePermeability, ...
                'skinDepth', skinDepth, ...
                'Nets', struct('Nets', Nets_),...
                'Excitations_Components', struct('Components', Excitations_Components), ...
                'Hits', Hits, ...
                'x', x, 'y', y, 'FH2Data', FH2Data, ...
                'FH2DataOutput', FH2DataOutput,  ...
                'Test', Test...
                );
            %outputArg1.debug = debug;
        end
          function [outputArg, obj] = BBRouteNet(obj,Net)
            % BBRoutingAlgorithm This is the bounding box algorithm. This
            % will route nets vertically through the PCB using polygons.The
            % function will route a single net in the layout, and update
            % the layout matrix struct, holes struct, excitations
            % struct, and the vias struct as necessary.
            % pours.
            %   Detailed explanation goes here
            
            %Load Shadow Registers
            shadow_Nets = obj.Nets;
            if ~ismember(Net, shadow_Nets)
                sprintf('Error in Netlist.BBRouteNet; Invalid Net')
                outputArg = -1;
                return
            end
            shadow_Matrix2 = obj.Matrix;
            shadow_MatrixFields = fields(shadow_Matrix2);
            shadow_Matrix = obj.Matrix.Layer1;
            shadow_Stackup = obj.Stackup;
            shadow_Components = obj.Components;
            individual_Components = fields(shadow_Components);
            components_connected_to_this_net_boolean = zeros(length(individual_Components),1);
            components_connected_to_this_net_boolean = components_connected_to_this_net_boolean&components_connected_to_this_net_boolean;
            %%Seach for this Net's Components
            for i=1:length(individual_Components)
                Terminals = shadow_Components.(individual_Components{i}).Terminals;
                for ii = 1:length(Terminals)
                    checkNet = Terminals(ii).Net;
                    if(isequal(checkNet, Net))
                        components_connected_to_this_net_boolean(i) = true;
                        break;
                    end
                end
            end
            individual_Components = individual_Components(components_connected_to_this_net_boolean);
            shadow_ComponentMasks = obj.ComponentMasks;
            shadow_Base_Matrix = obj.Base_Matrix;
            if isempty(fields(shadow_Stackup))
                shadow_Stackup.Layer1 = struct;
            end
            shadow_Mask = arrayfun(@(x) isequal(x,Net), shadow_Matrix);%Find all of the array elements that contain the integer 'Net'
            shadow_Holes = obj.Holes;
            shadow_Vias = obj.Vias;
            %%%Shadow_Matrix2
            shadow_Mask_Indices = find(shadow_Mask);%Extract their indices
            [row, col] = ind2sub(size(shadow_Matrix), shadow_Mask_Indices);%Convert Indices to Subscripts for 2Darray
            BBcorner1 = [min(row), min(col)];
            BBcorner2 = [max(row), max(col)];
            Matrix_Corner1 = [1 1];
            Matrix_Corner2 = size(shadow_Matrix);
            NetMask_boundingBox = seqPairBoundingBox(BBcorner1,BBcorner2,Matrix_Corner1,Matrix_Corner2);%%Create a bounding box that covers all of the elements in the matrix containing the net.
            netPolygonPour = NetMask_boundingBox;
            %%%For Loop Here. Iterate through all of the layers of
            %%%shadow_Matrix2
            for i = 1:length(shadow_MatrixFields)
                shadow_Matrix = shadow_Matrix2.(shadow_MatrixFields{i});
                PolygonMask = shadow_Matrix(NetMask_boundingBox);
                check_For_Other_Nets = find(PolygonMask);
                check_For_Other_Nets2 = PolygonMask(check_For_Other_Nets)~=Net;
                if (any(check_For_Other_Nets2))
                    %%add a flag here
                    flagset = 1;
                else
                    %%reset flag
                    %%Stop iterating
                    number_of_layers = length(fields(shadow_Stackup));
                    shadow_Matrix(NetMask_boundingBox) = Net;
                    shadow_Matrix2.(shadow_MatrixFields{i}) = shadow_Matrix;
                    currentLayer = i;
                    flagset = 0;
                    break;
                end
            end
            if(flagset)
                %Update Layers
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                Hold_on_Layers = length(fields(shadow_Stackup));
                number_of_layers = length(fields(shadow_Stackup))+1;
                currentLayer = number_of_layers;
                newLayer = sprintf('Layer%i', number_of_layers);
                newNet = sprintf('Net%i', Net);
                %%netPolygonPour = NetMask_boundingBox;
                newStackupEntry = struct('Net', Net, 'Polygon', netPolygonPour);
                shadow_Stackup.(newLayer) = struct(newNet, newStackupEntry) ;
                temp = zeros(size(shadow_Matrix));
                temp(NetMask_boundingBox) = Net;
                shadow_Matrix2.(newLayer) = temp;
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %Update Holes
                %Need to update this.
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                
                
                holeMask = zeros(size(PolygonMask));
                holeMask = holeMask&holeMask;
                holeMask(check_For_Other_Nets(check_For_Other_Nets2 == 1)) = (1&1) ;
                holeMaskIndex = find(holeMask);
                
                
                
                for i = 1:length(holeMaskIndex)
                    number_of_holes = length(fields(shadow_Holes))+1;
                    newHole = sprintf('Hole%i', number_of_holes);
                    holeTerminalLayer = sprintf('Layer%i', number_of_layers) ;
                    holeMask2 = zeros(size(shadow_Matrix));
                    holeMask3 = zeros(size(NetMask_boundingBox(NetMask_boundingBox == 1)));
                    holeMask3(holeMaskIndex(i)) = 1;
                    holeMask2(NetMask_boundingBox) =  holeMask3;
                    newHoleEntry = struct(newHole, number_of_holes, ...
                        'terminalLayer', holeTerminalLayer, 'holeMask', holeMask2);
                    %shadow_Holes.(newHole) = newHoleEntry;
                end
            else
                %Update Layers
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                newLayer = sprintf('Layer%i', currentLayer);
                newNet = sprintf('Net%i', Net);
                %netPolygonPour = NetMask_boundingBox;
                newStackupEntry = struct('Net', Net, 'Polygon', netPolygonPour);
                shadow_Stackup.(newLayer).(newNet) = newStackupEntry ;
                temp = shadow_Matrix;
                temp(NetMask_boundingBox) = Net;
                shadow_Matrix2.(newLayer) = temp;
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %Update vias
            %Place a via that goes from the top layer until it reaches
            %the current layer. Function will not create vias if the
            %current layer of this net is the top layer.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%Find the right Components
            if (currentLayer ~=1)
               via_Struct = struct();
                for i=1:length(individual_Components)
                    temp1 = shadow_Base_Matrix;
                    temp1(~shadow_ComponentMasks.(individual_Components{i})) = 0;
                    via_Struct.(individual_Components{i}) = temp1;
                end
                
                via_Locations = struct();
                for i=1:length(individual_Components)
                    temp1 = via_Struct.(individual_Components{i});
                    temp1(temp1~=Net) = 0;
                    ind = find(temp1);
                    sz = size(temp1);
                    [row, col] = ind2sub(sz, ind);
                    row_ave = mean(row);
                    col_ave = mean(col);
                    fieldName = sprintf('%s_Net%i', individual_Components{i}, Net);
                    via_Locations.(fieldName) = [row_ave, col_ave];
                end
                fields1 = fields(via_Locations);
                %Need to find the terminal layer
                searchString = sprintf('Net%i', Net);
                Layers10 = fields(shadow_Stackup);
                for i = 1:length(Layers10)
                    CurrentLayer10 = Layers10{i};
                    Nets10 = fields(shadow_Stackup.(CurrentLayer10));
                    if ~isempty(Nets10)
                        for ii = 1:length(Nets10)
                            hitCondition =strcmp(Nets10{ii}, searchString);
                            if hitCondition
                                break;
                            else
                                terminalLayer = number_of_layers;
                            end
                        end
                        if hitCondition
                                terminalLayer = i;
                                break;
                        end
                    end
                end
                
                
                for i=1:length(individual_Components)
                    number_of_vias = length(fields(shadow_Vias))+1;
                    newVia = sprintf('Via%i', number_of_vias);
                    viaStartingLayer = sprintf('Layer1');
                    viaTerminalLayer = sprintf('Layer%i', terminalLayer);
                    viaType = sprintf('Blind');
                    viaFH2Coords = via_Locations.(fields1{i});
                     newViaEntry = struct('ViaID', number_of_vias, ...
                        'viaStartingLayer', viaStartingLayer, ...
                        'terminalLayer', viaTerminalLayer, 'viaFH2Coords', ...
                        viaFH2Coords, 'Type', viaType, 'Net', Net);
                    shadow_Vias.(newVia) = newViaEntry;
                end
            end
            
            
            if (1 ~=1)
                viaMask = zeros(size(PolygonMask));
                viaMask = viaMask&viaMask;
                viaMask(check_For_Other_Nets(check_For_Other_Nets2 == 0)) = (1&1) ;
                viaMaskIndex = find(viaMask);
                for i = 1:length(viaMaskIndex)
                    number_of_vias = length(fields(shadow_Vias))+1;
                    newVia = sprintf('Via%i', number_of_vias);
                    viaTerminalLayer = sprintf('Layer%i', terminalLayer);
                    viaStartingLayer = sprintf('Layer1');
                    viaMask2 = zeros(size(shadow_Matrix));
                    viaMask3 = zeros(size(NetMask_boundingBox(NetMask_boundingBox == 1)));
                    viaMask3 (viaMaskIndex(i)) = 1;
                    viaMask2(NetMask_boundingBox) =  viaMask3;
                    viaType = sprintf('Blind');
                    newViaEntry = struct('ViaID', number_of_vias, ...
                        'viaStartingLayer', viaStartingLayer, ...
                        'terminalLayer', viaTerminalLayer, 'viaMask', ...
                        viaMask2, 'Type', viaType, 'Net', Net);
                    shadow_Vias.(newVia) = newViaEntry;
                end
            end
            
            obj.Stackup = shadow_Stackup;
           % obj.Holes = shadow_Holes;
            obj.Vias = shadow_Vias;
            obj.Matrix = shadow_Matrix2;
            
            variableDump = struct('shadow_Stackup', shadow_Stackup, ...
                'shadow_Matrix',shadow_Matrix,'shadow_Nets',shadow_Nets,...
                'BBcorner1', BBcorner1, 'BBcorner2', BBcorner2, 'Matrix_Corner1',...
                Matrix_Corner1, 'Matrix_Corner2', Matrix_Corner2, ...
                'NetMask_boundingBox',NetMask_boundingBox, 'PolygonMask', PolygonMask,...
                'check_For_Other_Nets', check_For_Other_Nets, 'check_For_Other_Nets2',...
                check_For_Other_Nets2, 'components_connected_to_this_net_boolean', ...
                 components_connected_to_this_net_boolean);
            outputArg = variableDump;
            
            variableDump_withLines124_135 = variableDump;
            variableDump_withLines124_135.('number_of_layers') = number_of_layers;
            if(exist('newLayer') == 1) variableDump_withLines124_135.newLayer = newLayer; end
            variableDump_withLines124_135.netPolygonPour = netPolygonPour;
            variableDump_withLines124_135.shadow_Matrix2 = shadow_Matrix2;
            if(exist('holeMask') == 1) variableDump_withLines124_135.holeMask = holeMask; end
            if(exist('holeMaskIndex') == 1) variableDump_withLines124_135.holeMaskIndex = holeMaskIndex; end
            if(exist('holeMask2') == 1) variableDump_withLines124_135.holeMask2 = holeMask2; end
            if(exist('holeMask3') == 1) variableDump_withLines124_135.holeMask3 = holeMask3; end
            if(exist('newHoleEntry') == 1) variableDump_withLines124_135.newHoleEntry = newHoleEntry; end
            if(exist('newHoleEntry') == 1) variableDump_withLines124_135.holeMaskIndex = holeMaskIndex; end
            variableDump_withLines124_135.shadow_Holes = shadow_Holes;
            variableDump_withLines124_135.shadow_Vias = shadow_Vias;
            variableDump_withLines124_135.flagset = flagset;
            variableDump_withLines124_135.currentLayer = currentLayer;
            if(exist('via_Struct') == 1)variableDump_withLines124_135.via_Struct = via_Struct; end
            if(exist('via_Struct') == 1)variableDump_withLines124_135.via_Locations = via_Locations; end
            % outputArg = variableDump_withLines124_135;
            outputArg = orderfields(variableDump_withLines124_135);
            
          end
         function [outputArg1, obj] = FH2_CreatePlanes(obj)
            shadow_Stackup = obj.Stackup;
            shadow_Excitations = obj.Excitations;
            shadow_Vias = obj.Vias;
            shadow_FH2_Command = obj.FH2_Command;
            Excitations_Components = fields(shadow_Excitations);%Excitation fields
            Layers = fields(shadow_Stackup);
            %Thickness = obj.FH2_interLayerThickness.Layer1.InterlayerDistance;%%For now, all inter-layers have the same thickness.
            InterLayerDistance = obj.FH2_interLayerThickness.Layer1.totalInterlayerDistance;%%For now, all inter-layers have the same thickness.
            Thickness1 = obj.FH2_interLayerThickness;
            %Skin depth calculation. Default
            %frequency is 10MHz, compareable with the default
            %value for Ansys EM Workbench.
            freq = 1e7;%%Maximum Test Frequency = 10 MHz
            rho = 1.678; %%CopperResistivity (muOhm*cm)
            rho_ = rho * 1e-7;%%Conversion to Ohm* mm
            permeability = 4*pi*1e-7;%%Permeability of Air
            Cu_RelativePermeability = 1;%Relative Permeability of copper
            skinDepth = 1e3 ./ sqrt(freq * (1/rho_) * Cu_RelativePermeability * permeability);%%Skin Depth(mm)
            Hits = struct; %Search hit references
            Hit1 = struct; % Used forentries into the Hits struct
            debug = struct;
            for i=1:length(Layers)
                 Thickness = Thickness1.(Layers{i}).InterlayerDistance;
                  InterLayerDistance =  Thickness1.(Layers{i}).totalInterlayerDistance;%%For now, all inter-layers have the same thickness.

                Nets_ = fields(shadow_Stackup.(Layers{i}));
                if ~isempty(Nets_)
                    
                    for ii=1:length(Nets_)
                        Polygon = shadow_Stackup.(Layers{i}).(Nets_{ii}).Polygon;
                        %%Find the vertices this polygon within the
                        %%simulation coordinate system.
                        [PolygonRows, PolygonCols] = find(Polygon);
                        if(min(PolygonRows) == 1)
                            x = [0, max(PolygonRows), max(PolygonRows)];
                        else
                            x = [min(PolygonRows)-1, max(PolygonRows), max(PolygonRows)];
                        end
                        if(min(PolygonCols) == 1)
                            y = [0, 0, max(PolygonCols)];
                        else
                            y = [ min(PolygonCols)-1, min(PolygonCols)-1,  max(PolygonCols)];
                        end
                        %  Segmentation calculation
                        PolygonHeight = floor((max(PolygonRows)- min(PolygonRows)) ./ (2.*skinDepth));
                        PolygonLength = floor((max(PolygonCols)- min(PolygonCols)) ./ (2.*skinDepth));
%                         segx = [temp_segx, temp_segx, temp_segx];
%                         segy = [temp_segy, temp_segy, temp_segy];
                        segx = [PolygonLength+1, PolygonLength+1, PolygonLength+1];
                        segy = [PolygonHeight+1, PolygonHeight+1, PolygonHeight+1];
                        %Create the name of the plane. Planes are named
                        %after their respective nets...
                        str = Nets_{ii};
                        %Find excitations and nodes. Requires a search...
                        %==============================================
                        %==============================================
                        %==============================================
                        %==============================================
                        
                        
                        %Search Algorithm for finding Excitation references
                        %in the plane coordinates. Needed for mating vias,
                        %holes, and excitations.
                        %==============================================
                        %==============================================
                        %==============================================
                        %==============================================
                        
                        
                        if ~isempty(Excitations_Components)
                            for iii = 1:length(Excitations_Components)
                                Excitations_Components_Terminals = fields(shadow_Excitations.(Excitations_Components{iii}));
                                if ~isempty(Excitations_Components_Terminals)
                                    for iiii = 1:length(Excitations_Components_Terminals)
                                        referenceNet = sscanf(Nets_{ii},'Net%d'); %Comparison Net
                                        comparisonNet = shadow_Excitations.(Excitations_Components{iii}).(Excitations_Components_Terminals{iiii}).Net;
                                        fieldName1 = sprintf('%s_%s', ...
                                            Excitations_Components{iii}, ...
                                            Excitations_Components_Terminals{iiii});
                                        fieldName2 = sprintf('%s', Nets_{ii});
                                        fieldName3 = sprintf('%s', Layers{i});
                                        %Store the search hits!
                                        if isequal(referenceNet, comparisonNet)
                                            Hits.(fieldName3).(fieldName2).(fieldName1) = shadow_Excitations.(Excitations_Components{iii}).(Excitations_Components_Terminals{iiii});
                                            Hits.(fieldName3).(fieldName2).(fieldName1).Polygon = Polygon;
                                            Hits.(fieldName3).(fieldName2).(fieldName1).PolygonRows = PolygonRows;
                                            Hits.(fieldName3).(fieldName2).(fieldName1).PolygonCols = PolygonCols;
                                            Hits.(fieldName3).(fieldName2).(fieldName1).x = x;
                                            Hits.(fieldName3).(fieldName2).(fieldName1).y = y;
                                            Hits.(fieldName3).(fieldName2).(fieldName1).PolygonHeight = PolygonHeight;
                                            Hits.(fieldName3).(fieldName2).(fieldName1).PolygonLength = PolygonLength;
                                            Hits.(fieldName3).(fieldName2).(fieldName1).segx = segx;
                                            Hits.(fieldName3).(fieldName2).(fieldName1).segy = segy;
                                            Hits.(fieldName3).(fieldName2).(fieldName1).str = str;
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            
            %             Crack the loops for the search and FH2 file authoring
            %             algorithms. Make the code more modular such that its easier
            %             to readand modify.
            FH2Data =struct([]);
            FH2DataOutput = struct([]);
            for i = 1:length(Layers)
                excitationLayer = i;
                excitationLayerZAxisCoordinate = 0.0;
                for ii = 1: excitationLayer
                    CurrentLayer = sprintf('Layer%i',ii) ;
                    shadow_FH2_interLayerThickness =  Thickness1.(CurrentLayer).totalInterlayerDistance;
                    excitationLayerZAxisCoordinate = excitationLayerZAxisCoordinate   - (1*shadow_FH2_interLayerThickness);
                end
                %excitationLayerZAxisCoordinate  = -1 .* (excitationLayer -1)  .*  InterLayerDistance;
                 
                if isfield(Hits, (Layers{i}))
                    Nets_ = fields(Hits.(Layers{i}));
                    if ~isempty(Nets_)
                        for ii=1:length(Nets_)
                            str = Nets_{ii};
                            Net = Hits.(Layers{i}).(Nets_{ii});
                            Terminals = fields(Hits.(Layers{i}).(Nets_{ii}));
                            Hits.(Layers{i}).ZAxisCoordinate = excitationLayerZAxisCoordinate;
                            Polygon = Hits.(Layers{i}).(Nets_{ii}).(Terminals{1}).Polygon;
                            PolygonRows = Hits.(Layers{i}).(Nets_{ii}).(Terminals{1}).PolygonRows;
                            PolygonCols = Hits.(Layers{i}).(Nets_{ii}).(Terminals{1}).PolygonCols;
                            x = Hits.(Layers{i}).(Nets_{ii}).(Terminals{1}).x;
                            y = Hits.(Layers{i}).(Nets_{ii}).(Terminals{1}).y;
                            PolygonHeight = Hits.(Layers{i}).(Nets_{ii}).(Terminals{1}).PolygonHeight;
                            PolygonLength = Hits.(Layers{i}).(Nets_{ii}).(Terminals{1}).PolygonLength;
                            segx = Hits.(Layers{i}).(Nets_{ii}).(Terminals{1}).segx;
                            segy = Hits.(Layers{i}).(Nets_{ii}).(Terminals{1}).segy;
                            str = Hits.(Layers{i}).(Nets_{ii}).(Terminals{1}).str;
                            
                            exc = struct;
                            nodes = [];
                            
                            for iii = 1:length(Terminals)
                                hitTerminal  = Hits.(Layers{i}).(Nets_{ii}).(Terminals{iii});
                                hitTerminalNode = hitTerminal.Node;
                                exc(iii).FH2Handle = hitTerminal.FH2Handle;
                                %%%%%%Here?
                                nodes = [nodes; [hitTerminalNode(1), hitTerminalNode(2), ...
                                    excitationLayerZAxisCoordinate]];
                            end
                            
                            
                            
                            
                            %                     POSSIBLE BUG:     TRY REARRANGING THE VARIABLE:
                            %                                 nodes = [nodes; ...
                            %                                     [col,row, excitationLayerZAxisCoordinate] ...
                            %                                     ];
                            %                                      TO:
                            %                                     nodes = [nodes; ...
                            %                                     [row,col, excitationLayerZAxisCoordinate] ...
                            %                                     ];
                            %                                     IF AXES ON THE FH2 PLOT FOR NODES ARE
                            %                                     INCORRECT
                            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                            shadowViasintoLayers = struct();
                            ViaHits = struct([]);
                            Vias = fields(shadow_Vias);
                            %%%%%
                            if ~isempty(Vias)
                                if length(Vias)>0
                                    for iii = 1:length(Vias)
                                        if strcmp(shadow_Vias.(Vias{iii}).terminalLayer, Layers{i}) ...
                                            && isequal(shadow_Vias.(Vias{iii}).Net, Net)
                                            currentIteration = length(ViaHits)+1;
                                            ViaHits(currentIteration).Hit = ...
                                                shadow_Vias.(Vias{iii});
                                            exc(length(exc)+1).FH2Handle = Vias{iii};
                                            %                                 sz = size(ViaHits(currentIteration).Hit.viaMask);
                                            %                                 ind = find(ViaHits(currentIteration).Hit.viaMask);
                                            %                                 [row,col] = ind2sub(sz,ind);
                                            viaFH2Coords = ViaHits(currentIteration).Hit.viaFH2Coords;
                                            col = viaFH2Coords(2);
                                            row = viaFH2Coords(1);
                                            nodes = [nodes; ...%%%<--------------------------------THIS ONE
                                                [row,col, excitationLayerZAxisCoordinate] ...
                                                ];
                                        end
                                    end
                                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                end
                            end
                            %%Reorganize data before entering it into the
                            %%FH2_Plane function.
                            iteration_count = length(FH2Data)+1;
                            FH2Data(iteration_count).str = str;
                            FH2Data(iteration_count).x = x;
                            FH2Data(iteration_count).y = y;
                            FH2Data(iteration_count).z = ones(3) * excitationLayerZAxisCoordinate;
                            FH2Data(iteration_count).PolygonHeight = PolygonHeight;
                            FH2Data(iteration_count).PolygonLength = PolygonLength;
                            if (PolygonHeight <=10)
                                PolygonHeight = 10;
                            end
                            if (PolygonLength <=10)
                                PolygonLength = 10;
                            end
                            FH2Data(iteration_count).seg =  [PolygonHeight+1, PolygonLength+1];
                            FH2Data(iteration_count).str = str;
                            FH2Data(iteration_count).thick = Thickness;
                            FH2Data(iteration_count).rho = [];
                            FH2Data(iteration_count).segwid = [];
                            FH2Data(iteration_count).exc = exc;
                            FH2Data(iteration_count).nodes = nodes;
                            if ~isempty(Vias) %%If all of the nets are on a single layer, this field will be empty.
                                FH2Data(iteration_count).Vias= ViaHits;
                                FH2Data(iteration_count).Vias2 = shadow_Vias.(Vias{iii}).terminalLayer;
                            end
                            FH2Data(iteration_count).Vias1 =  Layers{i};
                            %%Store hits into a permanent struct array.
                            FH2DataOutput(iteration_count).Command = FH2Plane(FH2Data(iteration_count).str,...
                                FH2Data(iteration_count).x, FH2Data(iteration_count).y, ...
                                FH2Data(iteration_count).z,FH2Data(iteration_count).thick,...
                                FH2Data(iteration_count).rho,  FH2Data(iteration_count).seg, ...
                                FH2Data(iteration_count).segwid, FH2Data(iteration_count).exc, ...
                                FH2Data(iteration_count).nodes);
                            
                        end
                    end
                end
            end
            shadow_FH2_Command.Planes = FH2DataOutput;
            shadow_FH2_Datum = FH2Data;
            obj.FH2_Command = shadow_FH2_Command;
            obj.FH2_Datum.Planes = shadow_FH2_Datum;
            outputArg1 = struct('shadow_Stackup', shadow_Stackup,...
                'shadow_Excitations' , shadow_Excitations,...
                'Layers', struct('Layers', Layers), ...
                'Thickness', Thickness, ...
                'freq', freq, ...
                'rho', rho, ...
                'rho_', rho_, ...
                'permeability', permeability, ...
                'Cu_RelativePermeability', Cu_RelativePermeability, ...
                'skinDepth', skinDepth, ...
                'Nets', struct('Nets', Nets_),...
                'Excitations_Components', struct('Components', Excitations_Components), ...
                'Hits', Hits, ...
                'x', x, 'y', y, 'FH2Data', FH2Data, ...
                'FH2DataOutput', FH2DataOutput ...
                );
            %outputArg1.debug = debug;
         end
         %%Detect which vias require holes and store hole information into
         %%Netlist.Holes field.
         function [outputArg1, obj] = FH2_DetectHoles(obj)
             %Load Shadow Registers. Shadow Registers are used to prevent
             %writing directly to the object fields, and to make the code
             %easier to write.
             shadow_Vias = obj.Vias;
             viaNames = fields(shadow_Vias);
             if isempty(viaNames)
                 outputArg1 = -1;
                 sprintf('Error: There are no vias in the netlist. Either rewrite the simulation \n or all of the nets are on a single layer.')
                 return;
             end
             shadow_Holes = obj.Holes;
% % % % %              if (isempty(shadow_Holes)) || (length(fields(shadow_Holes))))
% % % % %                  shadow_Holes = struct([]);
% % % % %              end
             shadow_Stackup = obj.Stackup;
             Layers = fields(shadow_Stackup);
             shadow_FH2_interLayerThickness = obj.FH2_interLayerThickness;
             Thickness = shadow_FH2_interLayerThickness.Layer1.InterlayerDistance;
             
             holeHits = struct;%Used for debugging.
             debug = struct;%For Debuggint the inner loop
             debug1 = struct;
             %%Lets start the iterations, shall we?
             for i = 1:length(viaNames)
                 %%Store Via information locally in this loop. Makes it
                 %%easy to change without messing with variables in
                 %%subloops.
                viaName = viaNames{i};
                viaStruct = shadow_Vias.(viaName);
                viaStructFields = fields(viaStruct);
                viaNet = viaStruct.Net;
                viaID = viaStruct.ViaID;
                viaCoords = viaStruct.viaFH2Coords;
                viaStartingLayer = viaStruct.viaStartingLayer;
                viaTerminalLayer = viaStruct.terminalLayer;
                %%If the starting layer is the bottom layer, reorganize the
                %%layers for this iteration.
                SortedSubloopLayers = Layers;
%                 if strcmp(viaStartingLayer,  Layers{end})
%                     SortedSubloopLayers = sort(Layers, 'descend');
%                 else
%                     SortedSubloopLayers = sort(Layers, 'ascend');
%                 end
                iterationLayers = {};
                for ii = 1:length(SortedSubloopLayers)
                    currentLayer = SortedSubloopLayers{ii};
                    iterationLayers{ii} = currentLayer;
                    if strcmp(currentLayer, viaTerminalLayer)
                        break;
                    end
                end
                %%Now we have all of the layers needed for the subloop
                %%organized into the iterationLayers cell. Time to create
                %%the subloop.
                for ii = 1:length(iterationLayers)
                    LayerStruct = shadow_Stackup.(iterationLayers{ii});
                    Nets = fields(LayerStruct);
                    %%Another subloop for the Nets...
                    if ~isempty(Nets)
                        for iii = 1:length(Nets)
                            currentNet = LayerStruct.(Nets{iii});
                            %%Compare the current iterated net to the
                            %%viaNet.
                            viaNetMatchesCurrentNet = isequal(currentNet.Net, viaNet);
                            %%Continue only if the layers don't match. They
                            %%won't need a hole for the via if their nets
                            %%match.
                            debug(ii).viaNetMatchesCurrentNet = viaNetMatchesCurrentNet;
                            debug(ii).currentNet =  currentNet;
                            debug(ii).viaID = viaID;
                            if ~viaNetMatchesCurrentNet
                            
                                currentNetPolygon = currentNet.Polygon;
                                ind = find(currentNetPolygon);
                                sz = size(currentNetPolygon);
                                [currentNetPolygon_row,currentNetPolygon_col] ...
                                    = ind2sub(sz,ind);
                                currentNetPolygon_row = unique(currentNetPolygon_row);
                                currentNetPolygon_col = unique(currentNetPolygon_col);
                                viaRow = viaCoords(1);
                                viaCol = viaCoords(2);
                                %%%Identify where, if at all, this via is
                                %%%within the range of the
                                %%%currentNetPolygon. This information may
                                %%%be usesul for further development.
                                rows_RangeIndices = (currentNetPolygon_row == ceil(viaRow)) ...
                                    | (currentNetPolygon_row == floor(viaRow));
                                cols_RangeIndices = (currentNetPolygon_col == ceil(viaCol)) ...
                                    | (currentNetPolygon_col == floor(viaCol));
                                debug(ii).rows_RangeIndices = rows_RangeIndices;
                                debug(ii).cols_RangeIndices = cols_RangeIndices;
                                debug(ii).currentNetPolygon_row = currentNetPolygon_row;
                                debug(ii).currentNetPolygon_col = currentNetPolygon_col;
                                %%%If the hole is within the row/col range
                                %%%of currentNetPolygon, create a new hole
                                %%%at this layer.
                                if (any(rows_RangeIndices) && any(cols_RangeIndices))
                                    numberofHoles = length(fields(shadow_Holes))+1;
                                    str = iterationLayers{ii};
                                    currentLayer = sscanf(str,'Layer%d');
                                    LayerZAxisCoordinate  = -1 .* (currentLayer -1)  .*  Thickness;
                                    HoleVia = viaName;
                                    HoleCoords =viaCoords;
                                    debug(ii).HoleVia = HoleVia;
                                    debug(ii). HoleCoords = HoleCoords;
                                    if (length(fields(shadow_Holes)) ~=0)
                                    HoleName = sprintf('Hole%i', numberofHoles);
                                    else
                                        HoleName = sprintf('Hole1');
                                    end
                                    
                                    HoleLayer = iterationLayers{ii};
                                    HoleNet = Nets{iii};
                                    debug(ii).HoleLayer = HoleLayer;
                                    debug(ii).HoleNet  = HoleNet;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%THIS MAY BE A BUG THIS MAY BE A BUG THIS MAY BE A BUG
                                    HoleRectangularCoordinates = [viaRow-0.5, viaCol-0.5, LayerZAxisCoordinate];
                                    HoleRadius = 0.9;%%Placeholder. For circular holes only!
%%%%%%%%%%THIS MAY BE A BUG THIS MAY BE A BUG THIS MAY BE A BUG
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                    holeEntry = struct('HoleVia', HoleVia, ...
                                        'HoleCoords', HoleCoords, ...
                                        'HoleName', HoleName, ...
                                        'HoleLayer', HoleLayer, ...
                                        'HoleNet', HoleNet, ...
                                        'HoleRectangularCoordinates', HoleRectangularCoordinates, ...
                                        'HoleRadius', HoleRadius ...
                                        );
                                    debug(ii).holeEntry = holeEntry;
                                    shadow_Holes.(HoleName) = holeEntry;
                                end
                                debug(ii).holeHitsLength = length(holeHits);
%                                 if(length(fields(holeHits)) == 1)
%                                     HitEntry = length(holeHits);
%                                 else
%                                     HitEntry = length(holeHits)+1;
%                                 end
                                HitEntry = length(fields(holeHits))+1;
                                debug(ii).HitEntry =HitEntry;
                                HitEntryField = sprintf('HoleHit%i', HitEntry);
                                debug(ii).HitEntryField =HitEntryField;
                                holeHits.(HitEntryField) = struct('currentNet', currentNet.Net, ...
                                    'viaNet', viaNet, ...
                                    'currentNetPolygon', currentNetPolygon, ...
                                    'currentNetPolygon_row', currentNetPolygon_row, ...
                                    'currentNetPolygon_col', currentNetPolygon_col, ...
                                    'viaRow', viaRow, ...
                                    'viaCol', viaCol, ...
                                    'rows_RangeIndices', rows_RangeIndices, ...
                                    'cols_RangeIndices', cols_RangeIndices ...
                                );
                             debug(ii).holeHits =holeHits;
                            end
                        end
                    end
                end
                debug1(i).debug=debug;
             end
            
             outputArg1 = struct('shadow_Vias', shadow_Vias, ...
                 'shadow_Holes', shadow_Holes, ...
                 'shadow_Stackup', shadow_Stackup, ...
                 'viaName', viaName, ...
                 'viaStruct', viaStruct, ...
                 'viaID', viaID, ...
                 'viaCoords', viaCoords, ...
                 'viaStartingLayer', viaStartingLayer, ...
                 'viaTerminalLayer', viaTerminalLayer, ...
                 'SortedSubloopLayers', struct('SortedSubloopLayers', SortedSubloopLayers), ...
                 'iterationLayers', struct('iterationLayers', iterationLayers), ...
                 'LayerStruct', LayerStruct, ...
                 'currentNet', currentNet, ...
                 'viaNet', viaNet, ...
                 'viaNetMatchesCurrentNet', viaNetMatchesCurrentNet, ...
                 'holeHits', holeHits ...
                 , 'debug1', debug1 ...
                 );
             obj.Holes =  shadow_Holes;

         end
         %Create FH2 String and Datums for Holes
         function  [obj] = FH2_CreateHoles(obj)
             shadow_FH2_Datum = obj.FH2_Datum;
             shadow_Holes = obj.Holes;
             shadow_FH2_Command = obj.FH2_Command;
             FH2Data =struct([]);
             FH2DataOutput = struct([]);
             Holes = fields(shadow_Holes);
             Plane_Datum = shadow_FH2_Datum.Planes;
             for i = 1:length(Holes)
                 currentHole = Holes{i};
                 HoleRectangularCoordinates = ...
                     shadow_Holes.(currentHole).HoleRectangularCoordinates;
                 HoleRadius = ...
                     shadow_Holes.(currentHole).HoleRadius;
%                  Need to keep holes from extending off of planes to avoid
%                  problems with FH2 Simulation crashes.
                 HoleNet = ...
                     shadow_Holes.(currentHole).HoleNet;
                 HolePlaneDatumIndex = strcmp({Plane_Datum(:).str}, HoleNet);
                 HolePlaneDatum = Plane_Datum(HolePlaneDatumIndex);
                 HolePlaneX = HolePlaneDatum.x;
                 HolePlaneY = HolePlaneDatum.y;
                 HolePlaneMaxX = max(HolePlaneX);
                 HolePlaneMinX = min(HolePlaneX);
                 HolePlaneMaxY = max(HolePlaneY);
                 HolePlaneMinY = min(HolePlaneY);
                 iteration_count = length(FH2Data)+1;
                 FH2Data(iteration_count).type = sprintf('rect');
                 switch FH2Data(iteration_count).type
                     case 'circ'
                         FH2Data(iteration_count).x = HoleRectangularCoordinates(1);
                         FH2Data(iteration_count).y = HoleRectangularCoordinates(2);
                         FH2Data(iteration_count).z = HoleRectangularCoordinates(3);
                     case 'rect'
                         RectDimension = 0.45;
                         temp_x = [max([HoleRectangularCoordinates(1) - RectDimension , HolePlaneMinX]), ...
                             min([HoleRectangularCoordinates(1) + RectDimension, HolePlaneMaxX])];
                         temp_y = [max([HoleRectangularCoordinates(2) - RectDimension , HolePlaneMinY]), ...
                             min([HoleRectangularCoordinates(2) + RectDimension, HolePlaneMaxY])];
%                          temp_x = [HoleRectangularCoordinates(1) - 0.5, ...
%                              HoleRectangularCoordinates(1) + 0.5];
%                          temp_y = [HoleRectangularCoordinates(2) - 0.5, ...
%                              HoleRectangularCoordinates(2) + 0.5];                         
                             FH2Data(iteration_count).x = temp_x;
                             FH2Data(iteration_count).y =  temp_y;
                         FH2Data(iteration_count).z = [HoleRectangularCoordinates(3), ...
                             HoleRectangularCoordinates(3)];
                 end
                 
                 FH2Data(iteration_count).r = HoleRadius;
                 FH2Data(iteration_count).HoleLayer = shadow_Holes.(currentHole).HoleLayer;
                 FH2Data(iteration_count).HoleNet = shadow_Holes.(currentHole).HoleNet;
                 FH2DataOutput(iteration_count).Command = FH2Hole(FH2Data(iteration_count).type, ...
                     FH2Data(iteration_count).x, FH2Data(iteration_count).y, ...
                     FH2Data(iteration_count).z, FH2Data(iteration_count).r ...
                     );
             end
             
             shadow_FH2_Datum = FH2Data;
              obj.FH2_Datum.Holes = shadow_FH2_Datum;
              shadow_FH2_Command.Holes = FH2DataOutput;
              obj.FH2_Command = shadow_FH2_Command;
         end
         %Create FH2 String and Datums for Vias
          function  [obj] = FH2_CreateVias(obj)
             shadow_Vias = obj.Vias;
             shadow_FH2_Command = obj.FH2_Command;
              shadow_FH2_interLayerThickness1= ...
                 obj.FH2_interLayerThickness;
            %shadow_FH2_interLayerThickness = ...
                % obj.FH2_interLayerThickness;
              shadow_FH2_copperLayerThickness = ...
                  obj.FH2_interLayerThickness.Layer1.InterlayerDistance;
             planes = shadow_FH2_Command.Planes;
             FH2Data =struct([]);
             FH2DataOutput = struct([]);
             Vias = fields(shadow_Vias);
             for i = 1:length(Vias)
                 currentVia = Vias{i};
                 viaFH2Coords = ...
                     shadow_Vias.(currentVia).viaFH2Coords;
                 iteration_count = length(FH2Data)+1;
                 
                 x = [viaFH2Coords(1), viaFH2Coords(1)];
                 y =   [viaFH2Coords(2), viaFH2Coords(2)];
                 %Updated Values: Included offset for FH2 Coordinates
                 x = [x(1) - 0.5, x(2) - 0.5];
                 y = [y(1) - 0.5, y(2) - 0.5];
                 FH2Data(iteration_count).x = x;
                 FH2Data(iteration_count).y = y;
                 
                 shadow_FH2_interLayerThickness =  shadow_FH2_interLayerThickness1.(shadow_Vias.(currentVia).viaStartingLayer).InterlayerDistance;
                 start_zAxisCoordinate = -1 * shadow_FH2_interLayerThickness * ...
                     (sscanf(shadow_Vias.(currentVia).viaStartingLayer, 'Layer%i')-1) ...
                    + shadow_FH2_copperLayerThickness/2;
                
                %Use a counter to determine via length
                %11/5/2022
                numLayers = sscanf(shadow_Vias.(currentVia).terminalLayer, 'Layer%i');
                terminal_zAxisCoordinate  = 0.0;
                TotalViaDepth = 0.0;
                for ii = 1:numLayers
                    CurrentLayer = sprintf('Layer%i',ii);
                    shadow_FH2_interLayerThickness =  shadow_FH2_interLayerThickness1.(CurrentLayer).totalInterlayerDistance;
                    terminal_zAxisCoordinate = terminal_zAxisCoordinate   - (1*shadow_FH2_interLayerThickness);
                    %terminal_zAxisCoordinate =  -1 * shadow_FH2_interLayerThickness * ...
                     %(sscanf(shadow_Vias.(currentVia).terminalLayer, 'Layer%i')-1);
                end
                 z = [start_zAxisCoordinate,terminal_zAxisCoordinate];
                 FH2Data(iteration_count).z =  z;

                 FH2Data(iteration_count).nodes = [1, 2];
                 FH2Data(iteration_count).viaID = sscanf(currentVia, 'Via%i');
                 FH2Data(iteration_count).w = 0.8;
                 FH2Data(iteration_count).h = 0.8;
                 %%Finding the nodes
                
                 FH2DataOutput(iteration_count).Command = FH2Via_Version1_1(...
                     FH2Data(iteration_count).x, FH2Data(iteration_count).y,FH2Data(iteration_count).z, ...
                     FH2Data(iteration_count).nodes, FH2Data(iteration_count).viaID,...
                     FH2Data(iteration_count).w, FH2Data(iteration_count).h);
             end

             shadow_FH2_Datum = FH2Data;
              obj.FH2_Datum.Vias = shadow_FH2_Datum;
              shadow_FH2_Command.Vias= FH2DataOutput;
              obj.FH2_Command = shadow_FH2_Command;
          end
          %Create FH2 String and Datums for Excitations
         function [outputArg1, obj] = FH2_CreateExcitations(obj)

            shadow_Stackup = obj.Stackup;
            Layers = fields(shadow_Stackup);

            shadow_FH2_Datum = obj.FH2_Datum;
            shadow_FH2_Command = obj.FH2_Command;
             shadow_FH2_interLayerThickness1 = ...
                 obj.FH2_interLayerThickness;

              shadow_Netlist_Graph = obj.Netlist_Graph;
            Edges = shadow_Netlist_Graph.Edges;
            Nodes =  shadow_Netlist_Graph.Nodes;
            Planes= shadow_FH2_Datum.Planes;
            shadow_Excitations = obj.Excitations;
            %Pull out all of the useful data using direct
            %search.
            shadow_FH2_interLayerThickness = ...
                obj.FH2_interLayerThickness.Layer1.InterlayerDistance;
            excitationHeight = 1e-4+shadow_FH2_interLayerThickness/2;%Infinitesimally small value.
            %             excitationHeight = 1e-5;%Infinitesimally small value.
            %             This allows to move the excitation face off of the plane,
            %             and control the shape of the excitation surface.        
            FH2Data= struct('x', [], 'y', [],'z', excitationHeight,'nodes', [],...
                'viaID', [],'L', [],'H', []);
            Search_Indices = struct();
             [number_of_edges, number_of_fields] = size(Edges);
             %%Find all of the Excitation Nodes by searching the
             %%Netlist_Graph Edges Table
            for i = 1:number_of_edges
                connected_ComponentTerminals = Edges.code{i};
                %%%Can update this variable for adding parallel components.
                raw_ComponentTerminalData = sscanf(connected_ComponentTerminals,'Component%dTerminal%d Component%dTerminal%d');
                Terminal_1 = sprintf('Component%iTerminal%i', raw_ComponentTerminalData(1), raw_ComponentTerminalData(2));
                Terminal_2 = sprintf('Component%iTerminal%i', raw_ComponentTerminalData(3), raw_ComponentTerminalData(4));
                Search_Indices.(Terminal_1) = sprintf('%s_GP', Terminal_1);
                Search_Indices.(Terminal_2) = sprintf('%s_GP', Terminal_2);
            end
             %%Search for the excitation data for each Search_Field
            Search_Fields = fields(Search_Indices);
            Hits = struct();
            for i=1:length(Search_Fields)
                %Search through the Excitations struct for the matching
                %FH2Handle
                Index_Handle = Search_Indices.(Search_Fields{i});
                Components = fields(shadow_Excitations);
                 for ii = 1:length(Components)
                     Terminals = fields(shadow_Excitations.(Components{ii}));
                     for iii = 1:length(Terminals)
                         comparison_Handle = shadow_Excitations.(Components{ii}).(Terminals{iii}).FH2Handle;
                         if strcmp(Index_Handle, comparison_Handle)
                             Hits.(Index_Handle) = shadow_Excitations.(Components{ii}).(Terminals{iii});
                         end
                     end
                 end
            end
            Hit_fields = fields(Hits);
            %%Quick hotfix adding layer information to the Hits struct
            for i=1:length(Hit_fields)
                index_Net = Hits.(Hit_fields{i}).Net;
                for ii = 1:length(Layers)
                    Nets = fields(shadow_Stackup.(Layers{ii}));
                    for iii = 1:length(Nets)
                        comparison_Net = sscanf(Nets{iii}, 'Net%d');
                        if isequal(index_Net, comparison_Net)
                            Hits.(Hit_fields{i}).Layer = Layers{ii};
                        end
                    end
                end
            end
            
            
            for iteration_count = 1:length(Hit_fields)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%POTENTIAL BUG HERE
                x = Hits.(Hit_fields{iteration_count}).Node(1);
                y = Hits.(Hit_fields{iteration_count}).Node(2);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %Find Z-axis coordinate 
%                 z = -1.*shadow_FH2_interLayerThickness.*(sscanf(Hits.(Hit_fields{iteration_count}).Layer, 'Layer%d')-1) + shadow_FH2_interLayerThickness/2;
                z =  shadow_FH2_interLayerThickness/2;
                FH2Data(iteration_count).x = [x, x];
                FH2Data(iteration_count).y = [y, y];
                %%Update: Include Offset for FH2 Coordinates
                FH2Data(iteration_count).x = [x-0.5, x-0.5];
                FH2Data(iteration_count).y = [y-0.5, y-0.5];                
                FH2Data(iteration_count).z = [excitationHeight, z-(0.0347)];%z];
                FH2Data(iteration_count).nodes = {'Node1', Hit_fields{iteration_count}};
                FH2Data(iteration_count).viaID = iteration_count;
                FH2Data(iteration_count).L = Hits.(Hit_fields{iteration_count}).L;
                FH2Data(iteration_count).H = Hits.(Hit_fields{iteration_count}).H;
                FH2Data(iteration_count).Excitation_Name = sprintf('nExc_Via%i', iteration_count);
                FH2Data(iteration_count).FH2Handle = Hits.(Hit_fields{iteration_count}).FH2Handle;
                FH2DataOutput(iteration_count).Command = FH2ExcitationVia(...
                    FH2Data(iteration_count).x, FH2Data(iteration_count).y,FH2Data(iteration_count).z, ...
                    FH2Data(iteration_count).nodes, FH2Data(iteration_count).viaID,...
                    FH2Data(iteration_count).L, FH2Data(iteration_count).H);
            end
            
            shadow_FH2_Datum = FH2Data;
            %%Iterate through netlist graph
            Hits_External = struct();
            [row, col] =size(Edges);
            for i = 1:row
                code = Edges{i, 3};
                code = code{1};
                
                
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%Update this one to use the digraph edge nodes to
%%%%%%%%%%%%%%%%%%%%%%%%%%determine source/sink terminals, rather than
%%%%%%%%%%%%%%%%%%%%%%%%%%relying on the order of component & terminal
%%%%%%%%%%%%%%%%%%%%%%%%%%data.
                comparison = sscanf(code, 'Component%iTerminal%i Component%iTerminal%i');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                
                
                
                
                
                SourceComponent = comparison(1);
                SourceTerminal = comparison(2);
                SinkComponent = comparison(3);
                SinkTerminal = comparison(4);
                searchString_source = sprintf('Component%iTerminal%i_GP', ...
                    SourceComponent, SourceTerminal);
                searchString_sink =sprintf('Component%iTerminal%i_GP', ...
                    SinkComponent, SinkTerminal);
                 for ii = 1:length(shadow_FH2_Datum)
                      comparison_String = shadow_FH2_Datum(ii).FH2Handle;
                      if strcmp(searchString_source, comparison_String)
                          source_Index = ii;
                          break
                      end
                 end
                  for ii = 1:length(shadow_FH2_Datum)
                      comparison_String = shadow_FH2_Datum(ii).FH2Handle;
                      if strcmp(searchString_sink, comparison_String)
                          sink_Index = ii;
                          break
                      end
                  end  
                 
                  FH2DataExternal(i).excitationSourceNode = sprintf('nExc_Via%iNode1', source_Index);
                  FH2DataExternal(i).excitationSinkNode = sprintf('nExc_Via%iNode1', sink_Index);
                  FH2DataExternalOutput(i).Command = ...
                      FH2Excitations(FH2DataExternal(i).excitationSourceNode, ...
                      FH2DataExternal(i).excitationSinkNode);
%                   Archive_Loop2(i).SourceComponent = SourceComponent;
%                   Archive_Loop2(i).SourceTerminal = SourceTerminal;
%                   Archive_Loop2(i).SinkComponent = SinkComponent;
%                   Archive_Loop2(i).SinkTerminal = SinkTerminal;
%                   Archive_Loop2(i).searchString_source = searchString_source;
%                   Archive_Loop2(i).searchString_sink = searchString_sink;
%                   Archive_Loop2(i).comparison = comparison;
            end
            
            
            %%Now make the .external statements
            shadow_FH2_Datum = FH2Data;
            shadow_FH2_Datum_External = FH2DataExternal;
            obj.FH2_Datum.Excitations = shadow_FH2_Datum;
             obj.FH2_Datum.External = shadow_FH2_Datum_External;
            shadow_FH2_Command.Excitations= FH2DataOutput;
            shadow_FH2_Command.External = FH2DataExternalOutput;
            obj.FH2_Command = shadow_FH2_Command;
            
            outputArg1 = struct('Hits', Hits,'Search_Indices', Search_Indices, ...
                'comparison_Net', comparison_Net, 'index_Net', index_Net, 'FH2Data', FH2Data, ...
                'FH2DataOutput', FH2DataOutput, 'Edges', Edges, 'Nodes', Nodes, 'Planes', Planes, ...
                'SourceComponent', SourceComponent, 'SourceTerminal', SourceTerminal, ...
                'SinkComponent', SinkComponent, 'SinkTerminal', SinkTerminal ...
...%                 'Archive_Loop2', Archive_Loop2 ...
                ...
                );
          
            
            
            
         end
         %Create FH2 Command File
          function [outputArg1, obj] = FH2_AssembleCommand(obj)
              shadow_Stackup = obj.Stackup;
              shadow_FH2_Command = obj.FH2_Command;
              shadow_FH2_Datum = obj.FH2_Datum;
              Planes = shadow_FH2_Datum.Planes;
              PlaneCommands =  shadow_FH2_Command.Planes;
              Holes = shadow_FH2_Datum.Holes;
              HoleCommands =  shadow_FH2_Command.Holes;
              ViaCommands = shadow_FH2_Command.Vias;
              ExcitationCommands = shadow_FH2_Command.Excitations;
              ExternCommands = shadow_FH2_Command.External;
              Ending = shadow_FH2_Command.Ending;
              Layers = fields(obj.Stackup);
              shadow_FH2CommandFileInput = [shadow_FH2_Command.Header.Preamble ...
                  shadow_FH2_Command.Header.DefaultValues '\n' ];
              %%%1. Find the corresponding layer for the holes and ground planes
                  %%%2. Place Vias in the string
                  %%%3. Place excitation vias
                  %%%4. Insert .extern statements
                  %%%5. Place frequency Statement
                  numiter = 0;
                  numiter1 = 0;
                  debug = struct();
              for i=1:length(Layers)
                  debug(i).currentLayer =  Layers{i};
                  currentLayer = Layers{i};
                  structInput = struct();
                  for ii = 1:length(Planes)
                       planeLayer = Planes(ii).Vias1;
                       planeNet = Planes(ii).str;
                       structInput(ii).planeLayer = planeLayer;
                       structInput(ii).Index = ii;
                       structInput(ii).Logical = strcmp(currentLayer, planeLayer);
                       if strcmp(currentLayer, planeLayer)
                           shadow_FH2CommandFileInput = [shadow_FH2CommandFileInput...
                               PlaneCommands(ii).Command '\n'];
                           for iii = 1:length(Holes)
                               holeLayer = Holes(iii).HoleLayer;
                                holeNet = Holes(iii).HoleNet;
                               if  strcmp(planeNet , holeNet)
                                   shadow_FH2CommandFileInput = [shadow_FH2CommandFileInput...
                                       HoleCommands(iii).Command '\n'];
                               end
                           end
                       end
                  end
                  debug(i).structInput = structInput;
                  

                  shadow_FH2CommandFileInput = [shadow_FH2CommandFileInput...
                      '\n**************************************************\n'];
                  
                  
              end
               shadow_FH2CommandFileInput = [shadow_FH2CommandFileInput...
                                '\n*Vias for lower layer nets\n**************************************************\n'];
              for i = 1:length(ViaCommands)
                  shadow_FH2CommandFileInput = [shadow_FH2CommandFileInput...
                                ViaCommands(i).Command '\n\n**************************************************\n'];
              end
              shadow_FH2CommandFileInput = [shadow_FH2CommandFileInput...
                  '\n*Vias for Excitations\n**************************************************\n'];
              for i = 1:length(ExcitationCommands)
                   shadow_FH2CommandFileInput = [shadow_FH2CommandFileInput...
                                ExcitationCommands(i).Command '\n\n**************************************************\n'];
              end
              shadow_FH2CommandFileInput = [shadow_FH2CommandFileInput...
              '\n*Place External Excitations\n**************************************************\n'];
              for i = 1:length(ExternCommands)
                  shadow_FH2CommandFileInput = [shadow_FH2CommandFileInput...
                      ExternCommands(i).Command '\n'];
              end
              shadow_FH2CommandFileInput = [shadow_FH2CommandFileInput...
              '\n*Simulation Frequency\n**************************************************\n'];
          
              shadow_FH2CommandFileInput = [shadow_FH2CommandFileInput...
               Ending.Frequency];
              shadow_FH2_Command.FileOutput = shadow_FH2CommandFileInput;
              
          obj.FH2_Command = shadow_FH2_Command;
          
          outputArg1= struct('shadow_Stackup',  shadow_Stackup ...
                  , 'shadow_FH2_Command', shadow_FH2_Command ...
                  , 'Layers', Layers...
                  , 'shadow_FH2CommandFileInput', shadow_FH2CommandFileInput ...
                  , 'Planes', Planes ...
                  , 'PlaneCommands', PlaneCommands ...
                  , 'Holes', Holes ...
                  , 'HoleCommands', HoleCommands ...
                  , 'numiter', numiter ...
                  , 'numiter1', numiter1 ...
                  , 'debug', debug ...
                  );
          end
         
         
         
    end
    
end


