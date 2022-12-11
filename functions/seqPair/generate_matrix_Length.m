function [num_elements] = generate_matrix_Length(Table_column1,Table_column2)
%UNTITLEDRequires detailed explanation
% 
%   Accepts a table as input

temp1=cell(size(Table_column1));
for i=1:length(temp1)
    temp0 = {Table_column1{i},Table_column2{i}};
    temp2 = cellfun(@(x) strlength(x) == 0,temp0);
    temp0(temp2) = [];
    temp1{i} = temp0;
end

%%From the table, identify the components with components that are above or
%%below
temp3 = cellfun(@(x) size(x),temp1,'UniformOutput',false);
Above_and_Below =cellfun(@(x) x(2)>1,temp3,'UniformOutput',false);
Above_or_Below =cellfun(@(x) x(2)==1,temp3,'UniformOutput',false);
Neither_Above_Below =cellfun(@(x) x(2)==0,temp3,'UniformOutput',false);

%%Sanitize the Indices
Above_or_Below = cell2mat(Above_or_Below);
Above_and_Below = cell2mat(Above_and_Below);
Neither_Above_Below =  cell2mat(Neither_Above_Below);

%%Merge cells with 2 elements
 temp7= temp1(Above_and_Below);
 if length(Above_and_Below(Above_and_Below==1))>0
      temp71 = size(temp7);
      temp74 = temp1(Above_and_Below);
      for i = 1:length(Above_and_Below(Above_and_Below==1))
          temp72 = temp7(i);
          temp73 = temp72{1};%%Sanitizing variable
          temp74(i) = {sprintf('%s,%s', temp73{1},temp73{2})};
      end
       temp1(Above_and_Below) = temp74;
 end

%%Sanitize nested cell structure
temp1(Above_or_Below) = cellfun(@(x) x{1},temp1(Above_or_Below),'UniformOutput',false);
%%Get rid of cells for components that are not above or below other
%%components
temp1(Neither_Above_Below) = {''};

%%Calculate the number of elements
temp8 = unique(temp1);
temp9= strlength(unique(temp1))>0;
temp8 = size(temp8(temp9));
num_elements = temp8(1);
if (num_elements == 0)%%If this is empty, there are no elements above or below this one. This in turn means that there is only one row.
    num_elements = 1;
end
end

