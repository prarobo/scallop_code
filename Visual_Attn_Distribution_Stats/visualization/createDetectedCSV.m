function createDetectedCSV( detectionStats, classData, params )
%CREATEDETECTEDCSV Save scallop detection results in csv file

%% Initialization

csvFilename = 'detectedScallops.csv';
numImages = length( detectionStats );

fid = fopen( csvFilename, 'w' );

%% Write csv

for imageI = 1:numImages
    detectionString = '';
    numScallops = detectionStats(imageI).numScallops;
    for scallopI = 1:numScallops
        if detectionStats(imageI).scallop{scallopI}.foundScallop
            detectionString = strcat( detectionString, 'y');
        else
            detectionString = strcat( detectionString, 'n');
        end
    end
    
    classificationString = '';
    numScallops = detectionStats(imageI).numScallops;
    for scallopI = 1:numScallops
        if detectionStats(imageI).scallop{scallopI}.classifiedScallop
            classificationString = strcat( classificationString, 'y');
        else
            classificationString = strcat( classificationString, 'n');
        end
    end
    
    fprintf(fid,'%s,%s\n', detectionString, classificationString);    
end

fclose(fid);

end

