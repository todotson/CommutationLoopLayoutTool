function [outputArg1] = FH2Header(desc,units, sigma ,rho, nhinc, nwinc, rh, rw)
%FH2Header Generates a header for a FastHenry2 file. Sets default values
%for several parameters.
%   desc:               A string that overviews the fasthenry2 file. This
%                           string must be typed with '*' at the beginning of every new line in
%                           order for the fasthenry2 solver to run properly.
%   units:               A string that defines the geometrical unit dimensions used in the simulation. 
%                           
%   rho:                  Default Resistivity of objects defined in
%                            the simulation. Can be overridden by local definitions
%
% sprintf('Running FH2Header...')
count = 1;
if not(isempty(desc))
    fileInput{count}=sprintf(desc);
    count= count + 1;
end
fileInput{count}=sprintf('.units %s', units);
count= count + 1;
if not(isempty(sigma))
    fileInput{count}=sprintf('.default sigma=%0.5f', sigma);
    count= count + 1;
end
if not(isempty(rho))
    fileInput{count}=sprintf('.default rho=%0.5f', rho);
    count= count + 1;
end
if not(isempty(nhinc))
    fileInput{count}=sprintf('.default nhinc=%i', nhinc);
    count= count + 1;
end
if not(isempty(nwinc))
    fileInput{count}=sprintf('.default nwinc=%i', nwinc);
    count= count + 1;
end
if not(isempty(rh))
    fileInput{count}=sprintf('.default rh=%i', rh);
    count= count + 1;
end
if not(isempty(rw))
    fileInput{count}=sprintf('.default rw=%i', rw);
    count= count + 1;
end
outputArg1 = strjoin(fileInput,'\n');
% sprintf('FH2Header Successful');
end

