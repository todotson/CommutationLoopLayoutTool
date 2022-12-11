function outputArg1 = FH2setFreqRange(minVal,maxVal,ndec)
sprintf('Setting Frequency Range...')
fileInput{1} = sprintf('.freq fmin=%.0d fmax=%.0d ndec=%.0d ',minVal, maxVal, ndec);
fileInput{2} = sprintf('.end');
outputArg1 = strjoin(fileInput, '\n');
sprintf('Frequency Range set.')
end

