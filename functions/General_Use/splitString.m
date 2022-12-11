function [outputArg1] = splitString(inputArg1)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
if (~ischar(inputArg1)) && (~isempty(inputArg1))
    sprintf('Error in splitString: Input is not a string. Please enter your data as a string, formatted as {"xyz...."}.')
    outputArg1 = -1;
    return
end
lengthstr = strlength(inputArg1);
if lengthstr==0
    outputArg1 = [];
    return
else
    outputArg1 = zeros(1,lengthstr);
    for i=1:lengthstr
        component = str2num(inputArg1(i));
        if isempty(component)
            sprintf('Error in stringSplit: Input formatted incorrectly. Input character %s is not a number', inputArg1(i))
            outputArg1=-2;
            return
        end
        outputArg1(i)=component;
    end
end
end

