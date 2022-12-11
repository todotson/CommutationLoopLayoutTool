function [outputArg1] = FH2Hole(type,x,y,z,r)
%
%
%FH2Hole Generates strings that define holes in uniform planar conductors
%in the FastHenry2 language. The output strings must be placed immediately
%after a planar conductor definition because the FH2 language attaches
%holes to a conductor and uses them as a tool part to subtract geometry
%from the blank plane part. Outputs a string if successful and a 0 if
%unsuccessful
%
%
%   type:               Defines the type of hole in the FH2 geometry. Expects a string input. There
%                           are three types available: 
%                           -Circular: defined by 'circ'
%                           -Rectangular: defined by 'rect
%                           -Point: defined by 'point'
%  x,y,z:               The coordinates used to locate the hole. For
%                           circular and point holes, a single coordinate is needed to locate the
%                           hole, and the point is at the center of the hole. For rectangular parts,
%                           coordinates for 2 opposite corners are necessary.
% r:                      For circular holes, the r value defines the
%                           radius in units defined for the planar conductor
switch type
    case 'rect'
        if (length(x)>=2)&&(length(y)>=2)&&(length(z)>=2)
            outputArg1 = sprintf('+ hole rect (%0.5f,%0.5f,%0.5f,%0.5f,%0.5f,%0.5f) ',x(1),y(1),z(1),x(2),y(2),z(2));
%             sprintf('Rectangular Hole created with corners at [%0.5f,%0.5f,%0.5f] and [%0.5f,%0.5f,%0.5f] ',x(1),y(1),z(1),x(2),y(2),z(2))
        else
            sprintf('Error: Rectangular Hole Dimensions underdefined')
            outputArg1= 0;
        end
    case 'circ'
        if ~(isempty(x)&&isempty(y)&&isempty(z)&&isempty(r))
            outputArg1 = sprintf('+ hole circle (%0.5f,%0.5f,%0.5f,%0.5f)',x(1),y(1),z(1),r );
            sprintf('Circular Hole created at [%0.5f,%0.5f,%0.5f] with radius %0.5f ',x(1),y(1),z(1),r)
        else
            sprintf('Error: Circular Hole Dimensions underdefined')
            outputArg1= 0;
        end
    case 'point'
        if ~(isempty(x)&&isempty(y)&&isempty(z)&&isempty(r))
            outputArg1 = sprintf('+  hole point (%0.5f,%0.5f,%0.5f) ',x(1),y(1),z(1) );
%             sprintf('Point Hole created at [%0.5f,%0.5f,%0.5f]',x(1),y(1),z(1))
        else
            sprintf('Error: Point Hole Dimensions underdefined')
            outputArg1= 0;
        end
end

