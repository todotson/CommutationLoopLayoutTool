function [outputArg1] = seqPair_CheckMatrixViolations(comp_Indices, left_Indices,right_Indices,above_Indices,below_Indices)
%seqPair_CheckMatrix(comp_Indices, left_Indices,right_Indices,above_Indices,below_Indices) 
%Checks a given sequence pair placement matrix based on a series of logical
%indices, and tracks the number of violations in a counter that can be used
%for a Genetic Algorithm Fitness function.
%comp_Indices identifies where the the component is in the matrix.
%The other indices reference components that are supposed to be to the
%right, left, above, and below the referenced component, hereby referred to
%as elements. These indices are determined by the sequence pair algorithmm.
%   outputArg1 is the counter for the number of violations found in this matrix. 

[row,col] = ind2sub([length(comp_Indices(:,1)) length(comp_Indices(1,:))],find(comp_Indices));
outputArg1 = 0;
for i=1:length(row)
    %%%Check Left of
    aboveCheck = ~isempty(find(left_Indices(1:row(i), col(i)),1));%%%If any of these indices are true, then there are elements above the component that are supposed to be to the left of it. The placement cell is moot.
    belowCheck = ~isempty(find(left_Indices(row(i):end,col(i)),1));%%%If any of these indices are true, then there are elements below the component that are supposed to be to the left of it. The placement cell is moot.
    rightCheck = ~isempty(find(left_Indices(:,1:col(i)),1));%%%If any of these indices are true, then there are elements to the right of the component that are supposed to be to the left of it. The placement cell is moot.
    if (aboveCheck||belowCheck||rightCheck)
        if aboveCheck
            returnError('11');
            outputArg1 = outputArg1+1;
        end
        if belowCheck
            returnError('12');
            outputArg1 = outputArg1+1;
        end
        if rightCheck
            returnError('13');
            outputArg1 = outputArg1+1;
        end
    end
%%%Check Right of
    aboveCheck = ~isempty(find(right_Indices(1:row(i), col(i)),1));%%%If any of these indices are true, then there are elements above the component that are supposed to be to the left of it. The placement cell is moot.
    belowCheck = ~isempty(find(right_Indices(row(i):end,col(i)),1));%%%If any of these indices are true, then there are elements below the component that are supposed to be to the left of it. The placement cell is moot.
    leftCheck = ~isempty(find(right_Indices(:,col(i):end),1));%%%If any of these indices are true, then there are elements to the right of the component that are supposed to be to the left of it. The placement cell is moot.
    if (aboveCheck||belowCheck||leftCheck)
        if ~aboveCheck
            returnError('21');
            outputArg1 = outputArg1+1;
        end
        if ~belowCheck
            returnError('22');
            outputArg1 = outputArg1+1;
        end
        if ~leftCheck
            returnError('23');
            outputArg1 = outputArg1+1;
        end
    end
%%%Check Above
    rightCheck = ~isempty(find(above_Indices(row(i), col(i):end),1));%%%If any of these indices are true, then there are elements above the component that are supposed to be below it. The placement cell is moot.
    belowCheck = ~isempty(find(above_Indices(row(i):end,col(i)),1));%%%If any of these indices are true, then there are elements below the component that are supposed to be below it. The placement cell is moot.
    leftCheck = ~isempty(find(above_Indices(row(i),1:col(i)),1));%%%If any of these indices are true, then there are elements to the right of the component that are supposed to be below it. The placement cell is moot.
    if (rightCheck||belowCheck||leftCheck)
        if ~rightCheck
            returnError('31');
            outputArg1 = outputArg1+1;
        end
        if ~belowCheck
            returnError('32');
            outputArg1 = outputArg1+1;
        end
        if ~leftCheck
            returnError('33');
            outputArg1 = outputArg1+1;
        end
    end
%%%Check Below
    rightCheck = ~isempty(find(below_Indices(row(i), col(i):end),1));%%%If any of these indices are true, then there are elements above the component that are supposed to be above it. The placement cell is moot.
    aboveCheck = ~isempty(find(below_Indices(1:row(i), col(i)),1));%%%If any of these indices are true, then there are elements above the component that are supposed to be above it. The placement cell is moot.
    leftCheck = ~isempty(find(below_Indices(row(i),1:col(i)),1));%%%If any of these indices are true, then there are elements to the right of the component that are supposed to be above it. The placement cell is moot.
    if (rightCheck||aboveCheck||leftCheck)
        if ~rightCheck
            returnError('41');
            outputArg1 = outputArg1+1;
        end
        if ~aboveCheck
            returnError('42');
            outputArg1 = outputArg1+1;
        end
        if ~leftCheck
            returnError('43');
            outputArg1 = outputArg1+1;
        end
    end
end
end
%%Subroutines used in this function.
function returnError(string_input)
switch string_input
    case '11'
        sprintf('seqPair_CheckMatrix Error 1.1: Element found above indexed component that should be to the left of it.');
    case '12'
        sprintf('seqPair_CheckMatrix Error Error 1.2: Element found below indexed component that should be to the left of it.');
    case '13'
        sprintf('seqPair_CheckMatrix Error Error 1.3: Element found to the right of indexed component that should be to the left of it.');
    case '21'
        sprintf('seqPair_CheckMatrix Error Error 2.1: Element found above indexed component that should be to the right of it.');
    case '22'
        sprintf('seqPair_CheckMatrix Error Error 2.2: Element found below indexed component that should be to the right of it.');
    case '23'
        sprintf('seqPair_CheckMatrix Error Error 2.3: Element found below indexed component that should be to the right of it.');
    case '31'
        sprintf('seqPair_CheckMatrix Error Error 3.1: Element found to the right of indexed component that should be below it.');
    case '32'
        sprintf('seqPair_CheckMatrix Error Error 3.2: Element found above indexed component that should be below it.');
    case '33'
        sprintf('seqPair_CheckMatrix Error Error 3.3: Element found to the right of indexed component that should be below it.');
    case '41'
        sprintf('seqPair_CheckMatrix Error Error 4.1: Element found to the right of indexed component that should be above it.');
    case '42'
        sprintf('seqPair_CheckMatrix Error Error 4.2: Element found below of indexed component that should be above it.');
    case '43'     
        sprintf('seqPair_CheckMatrix Error Error 4.3: Element found to left of indexed component that should be above it.');
    otherwise
        sprintf('Error undefined: Please check seqPair_CheckMatrix function and error code input function for bugs!');
end
end
% function [outputArg1] = leftCheck(Indices,row,col)
% outputArg1 = isempty(find(Indices(row,col:end),1));
% end
% function [outputArg1] = rightCheck(Indices,row,col)
%  outputArg1 = isempty(find(Indices(row,1:col),1));
% end
% function [outputArg1] = aboveCheck(Indices,row,col)
%  outputArg1 = isempty(find(Indices(1:row, col),1));
% end
% function [outputArg1] = belowCheck(Indices,row,col)
% outputArg1 = isempty(find(Indices(row:end,col),1));
% end