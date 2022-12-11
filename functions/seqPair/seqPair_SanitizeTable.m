function [left,right,above,below] = seqPair_SanitizeTable(inputArg1)
%seqPair_SanitizeTable Sanitize tabular inputs of placement Table for passing arguments
%into other functions
%   Detailed explanation goes here
        temp = inputArg1.Left_of;
        left = splitString(temp{1});
         temp = inputArg1.Right_of;
       right =  splitString(temp{1});
         temp = inputArg1.Above;
       above = splitString(temp{1});
        temp = inputArg1.Below;
       below = splitString(temp{1});
end

