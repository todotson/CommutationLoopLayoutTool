function [outputArg1] = FH2Plane(str,x,y,z,thick,rho, seg, segwid, exc, nodes)
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
% rho:                  resistivity value of the material. Input as a
%                           float.
%seg:                   segmentation array for descretization of the planar
%                          conductor. Requires a format of [seg1,seg2]
%segwid:             segmentation array for meshing of the planar
%                          conductor. Places holes in the planar conductor with the meshing frequency in 2 dimensions. 
%                          Requires a format of [segwid1,segwid2]
%exc:                   These are identifiers for the excitations used in
%                           the geometry. There is a single ID per node.
%                           The length of the exc array must equal the
%                           number of columns in the nodes array.
%nodes:               These are the points where external connections for
%                           excitations can be made. Requires xyz
%                           coordinates for each node. Format is
%                           [x1,y1,z1;x2,y2,z2;....xm,ym,zm;] for m nodes
% sprintf('running FH2Plane...');
count = 1;
if (length(x) == 3) && (length(y)==3) && (length(z) == 3) && not(isempty(thick))&& (length(nodes(:,1)) == length(exc))
    fileInput{count} = sprintf('g%s x1 =%i y1 = %i      z1 = %i ',str,x(1),y(1),z(1) );
    count= count + 1;
    fileInput{count} = sprintf('+  x2 = %i   y2 = %i      z2 = %i ',x(2),y(2),z(2) );
    count= count + 1;
    fileInput{count} = sprintf('+  x3 = %i   y3 = %i   z3 = %i ',x(3),y(3),z(3) );
    count= count + 1;
    fileInput{count} = sprintf('+  thick = %0.5f', thick);
    count= count + 1;
    if not(isempty(rho))
        fileInput{count} = sprintf('+ rho= %0.2f ',rho);
        count= count + 1;
    end
    fileInput{count} = sprintf('+  seg1 = %i seg2=%i', seg(1),seg(2));
    count= count + 1;
    if not(isempty(segwid))
        fileInput{count} = sprintf('+ segwid1= %0.2f ',segwid(1));
        count= count + 1;
        fileInput{count} = sprintf('+ segwid2= %0.2f ',segwid(2));
        count= count + 1;
    end
        for i=1:length(nodes(:,1))
%             if ~isstruct(exc)
%                 fileInput{count} = sprintf('+  ng_%i (%i,%i,%i)',exc(i),nodes(i,1),nodes(i,2),nodes(i,3));
%                 count= count + 1;
%             else
%                 fileInput{count} = sprintf('+  ng_%s (%i,%i,%i)',exc(i).FH2Handle,nodes(i,1),nodes(i,2),nodes(i,3));
%                 count= count + 1;
%             end
%Offset of -0.5 applied for conversion from matlab coordinates(starting
%from 2) and FH2 coordinates (starting from 0)
                        if ~isstruct(exc)
                fileInput{count} = sprintf('+  ng_%i (%i,%i,%i)',exc(i),nodes(i,1)-0.5,nodes(i,2)-0.5,nodes(i,3));
                count= count + 1;
            else
                fileInput{count} = sprintf('+  ng_%s (%i,%i,%i)',exc(i).FH2Handle,nodes(i,1)-0.5,nodes(i,2)-0.5,nodes(i,3));
                count= count + 1;
            end
        end
    outputArg1 = strjoin(fileInput, '\n');
%     sprintf('FH2Plane run successful!');
else%Error definitions
    if not((length(x) == 3) && (length(y)==3) && (length(z) == 3))
        sprintf('Error: Underdefined planar coordinates')
    end
    if isempty(thick)
         sprintf('Error: Undefined thickness')
    end
    if ~(length(nodes(:,1)) == length(exc))
         sprintf('Error: Mismatch between node exc ID and the number of coordinates')
    end
    if isempty(nodes) || isempty(length(exc))
         sprintf('Error: No nodes or excitations')
    end
    outputArg1= 0;
end
end