function [] = writeAttrCSV_testing_linear(attrFile_testing, currDataPoint, imageI, numImages, objI, numObj, numFeatures)
%writeAttrCSV_testing_linear Write attribute values to csv files

%% Initialization

fid = fopen( attrFile_testing, 'a' );
fprintf('Writing attribute data: Image %d of %d, object %d of %d ...', imageI, numImages, objI, numObj);

%% Writing to file

for featI = 1:numFeatures
    fprintf(fid,'%d',currDataPoint(featI) );
    if featI ~= numFeatures
        fprintf(fid,',');
    end
end
fprintf(fid,'\n');

%% Closing
fclose(fid);
fprintf('done\n');

end

