function [ imageStatusComplete, dataPoint ] = restorePointHandler_discretization( params, imageStatusComplete, dataPoint )
%RESTOREPOINTHANDLER_DISCRETIZATION Restores discretization points

%% Initialization

restoreFileList = sprintf('%s*.mat', params.restoreFile);
filedata = dir( restoreFileList );

numFiles = length( filedata );
startImage = params.startImage;
endImage = startImage + params.numImages - 1;

%% File merge

for fileI = 1:numFiles
    % Loading restore file 
    newRestoreMat = load(filedata(fileI).name);
    newRestoreMat = newRestoreMat.restoreMat;
    
    newStartImage = newRestoreMat.params.startImage;
    newEndImage = newStartImage + newRestoreMat.params.numImages - 1;
    
    % Check if the restore file start and end image are within the parent
    % file limits
    if  (newStartImage < startImage || newStartImage > endImage || ...
            newEndImage < startImage || newEndImage > endImage)
        continue;
    end
    
    fprintf('Restoring segment image data (image %d - %d)...', newStartImage, newEndImage);
    imageIndex = 0;
    
    for imageI = newStartImage:newEndImage
        imageIndex = imageIndex+1;
        if( ~imageStatusComplete(imageI) )
            if ( newRestoreMat.imageStatusComplete(imageIndex) )
                dataPoint{imageI} = newRestoreMat.dataPoint{imageIndex};
            end
        end
    end
    
    imageStatusComplete(newStartImage:newEndImage) =...
        imageStatusComplete(newStartImage:newEndImage) | newRestoreMat.imageStatusComplete;
    
    fprintf('done\n');
end

%% Save Restore Point

restoreMat.params = params;
restoreMat.imageStatusComplete = imageStatusComplete;
restoreMat.dataPoint = dataPoint;

delete( restoreFileList )
save( sprintf('%s.mat', params.restoreFile), 'restoreMat' );

end

