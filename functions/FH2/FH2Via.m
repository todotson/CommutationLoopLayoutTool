function outputArg1 = FH2Via(x,y,z,nodes,equiv, viaID,w,h)
%FH2Via Defines traces from one component to another. The primary use of
%this function is to create vias connecting planes together. Via
%definitions are done by first defining 2 via nodes 
% x,y, and z:               Defines the coordinates of the via nodes.
%                                Format is [x1,x2]. Exactly 2 nodes are required
%nodes:                     A number identifying the fia node. FastHenry
%                                requires each node to have a unique identifier. Expected input is an
%                                integer number aray with format [nodes(1), nodes(2)]
%equiv:                     Equivalent nodes in the FastHenry2 Model.
%                               A common practice is to define reference nodes within ground planes and
%                               then set via and trace nodes to be equivalent to them. Expected format is
%                               [equiv(1), equiv(2)]. 
%w:                           Width of via. The via is approximated as a
%                               rectangular prism. Expected format is a double.
%h:                             Height of via. Expected format is a double.
count=1;
% sprintf('running FH2FH2Via...');
if not(isempty(nodes)&&isempty(viaID)&&isempty(w)&&isempty(h))
    if (length(x)>=2)&&(length(y)>=2)&&(length(z)>=2)
        fileInput{count} = sprintf('node%i x=%0.5f y=%0.5f z=%0.5f',nodes(1),x(1), y(1), z(1));
        count = count+1;
        fileInput{count} = sprintf('node%i x=%0.5f y=%0.5f z=%0.5f',nodes(2),x(2), y(2), z(2));
        count = count+1;
    end
    if(~isempty(equiv))
        fileInput{count} = sprintf('.equiv node%i node%i',nodes(1),equiv(1));
        count = count+1;
        fileInput{count} = sprintf('.equiv node%i node%i',nodes(2),equiv(2));
        count = count+1;
    end
    fileInput{count} = sprintf('E%i node%i node%i w=%0.5f h=%0.5f',viaID,nodes(1),nodes(2),w, h);
    outputArg1 = strjoin(fileInput, '\n');
%     sprintf('FH2Via run successful');
else
    outputArg1=0;
    if ~(length(x)>=2)&&(length(y)>=2)&&(length(z)>=2)
        sprintf('Error: Via Node Coordinates underdefined')
    end
    if isempty(nodes)
        sprintf('Error: nodes undefined')
    end
     if isempty(viaID)
        sprintf('Error: no ID label for Via')
     end
     if isempty(w)||isempty(h)
        sprintf('Error: Via dimensions undefined')
     end
end

end

