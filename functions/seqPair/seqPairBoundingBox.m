function [outputArg1] = seqPairBoundingBox(BBcorner1,BBcorner2,graphcorner1,graphcorner2)
%BoundingBox Creates a bounding box defined by two opposite corners of the
%box. The function automatically detects the extrema of each index. The
%output is a cell array of self-indexed terms for the bounding box.This
%function is meant to be applied to a matrix in order to identify the
%indices within the bounding box. The output is a logical array that can be
%applied to the graph defined by the graphcorner variables.
%
%If any of the inputs is below zero, function will set it equal to 1 before
%processing the function.
%testInputs:
% BBcorner1 = [144,5]
% BBcorner2=[5,144]
% graphcorner1 =[1,500]
% graphcorner2=[500,1]

if(graphcorner1(1)<1)
    graphcorner1(1)=1;
end
if(graphcorner1(2)<1)
    graphcorner1(2)=1;
end
if(graphcorner2(1)<1)
    graphcorner2(1)=1;
end
if(graphcorner1(2)<1)
    graphcorner1(2)=1;
end

if(BBcorner1(1)<1)
    BBcorner1(1)=1;
end
if(BBcorner1(2)<1)
    BBcorner1(2)=1;
end
if(BBcorner2(1)<1)
    BBcorner2(1)=1;
end
if(BBcorner1(2)<1)
    BBcorner1(2)=1;
end

graphHeight = max(graphcorner1(1),graphcorner2(1)) - min(graphcorner1(1),graphcorner2(1))+1;
graphLength = max(graphcorner1(2),graphcorner2(2)) - min(graphcorner1(2),graphcorner2(2))+1;
BBheight = max(BBcorner1(1),BBcorner2(1)) - min(BBcorner1(1),BBcorner2(1))+1;
BBlength = max(BBcorner1(2),BBcorner2(2)) - min(BBcorner1(2),BBcorner2(2))+1;
vIndices = linspace(min(BBcorner1(1),BBcorner2(1)),max(BBcorner1(1),BBcorner2(1)),BBheight);
hIndices = linspace(min(BBcorner1(2),BBcorner2(2)),max(BBcorner1(2),BBcorner2(2)),  BBlength);
graph = zeros(graphHeight,graphLength);
graph(vIndices,hIndices)= 1;
outputArg1 = graph&graph;
end

