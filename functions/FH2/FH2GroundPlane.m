function [outputArg1] = FH2Plane(str,x,y,z,thick,rho, seg, nodes)
%FH2GroundPlane Creates a string formatted to create a uniformly discretized plane in the
%FastHenry2 Solver. Returns a formatted string if successful. Returns 0
%if unsuccessful.
%   str :               title string of the ground plane
% x,y,and z :       define the corners of the groundplane in clockwise order. There
%                           need to be three of each coordinate for the program to execute.
%                           Units need to be defined outside of this
%                           function and be consistent with the sigma
%                           variable.
% thick:                thickness of the plane
% rho:                  resistivity value of the material. 
%seg:                   segmentation array for descretization of the planar
%                          conductor
%nodes:               These are the points where external connections for
%                           excitations can be made
% sprintf('running FH2GroundPlane...');
count = 1;
if (length(x) == 3) && (length(y)==3) && (length(z) == 3) && not(isempty(thick))
    fileInput{count} = sprintf('g%s x1 =%i y1 = %i      z1 = %i ',str,x(1),y(1),z(1) );
    count= count + 1;
    fileInput{count} = sprintf('+  x2 = %i   y2 = %i      z2 = %i ',x(2),y(2),z(2) );
    count= count + 1;
    fileInput{count} = sprintf('+  x3 = %i   y3 = %i   z3 = %i ',x(3),y(3),z(3) );
    count= count + 1;
    fileInput{count} = sprintf('+  thick = %i', thick);
    count= count + 1;
    if not(isempty(rho))
        fileInput{count} = sprintf('+ rho= %0.2f ',rho);
        count= count + 1;
    end
    fileInput{count} = sprintf('+  seg1 = %i seg2=%i', seg(1),seg(2));
    count= count + 1;
    if length(nodes(:,1)) >1
        for i=1:length(nodes(:,1))
            fileInput{count} = sprintf('+  np%i (%i,%i,%i)',i,nodes(i,1),nodes(i,2),nodes(i,3));
            count= count + 1;
        end
    end
    outputArg1 = strjoin(fileInput, '\n');
%     sprintf('FH2GroundPlane run successful!');
else%Error definitions
    if not((length(x) == 3) && (length(y)==3) && (length(z) == 3))
        sprintf('Error: Underdefined planar coordinates');
    end
    if isempty(thick)
         sprintf('Error: Undefined thickness');
    end
    outputArg1= 0;
end
end