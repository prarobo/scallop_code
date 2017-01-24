function [ scallopTesting ] = loadScallopPrevResults( scallopTesting, prevResultsFile )
%LOADSCALLOPPREVRESULTS Loads data from previous 3-layered scallop
%classification results

%% Loading previous results
prevResults = goodLoad(prevResultsFile);

%% Loading params
scallopTesting.prevParams = prevResults.params;
scallopTesting.params.numImages = prevResults.params.numImages;

%% Loading fileinfo
scallopTesting.fileInfo.filename = prevResults.fileInfo.filename;
scallopTesting.fileInfo.foldername = scallopTesting.params.imageFolder;
scallopTesting.fileInfo.foldernameUnsmooth = scallopTesting.params.imageFolderUnsmooth;

%% Loading visual attention results
scallopTesting.fixationData = prevResults.fixationData;

%% Loading object data
scallopTesting.segmentData.circList = prevResults.distributionData.objList;
scallopTesting.segmentData.objectList = getObjectList(prevResults.distributionData.objList);
scallopTesting.segmentData.dataPointMatch = prevResults.distributionData.dataPointMatch;

%% Loading results data
scallopTesting.classData.segmentDetectionStats = prevResults.statData.detectionStats;
scallopTesting.classData.segmentCategoryStats = prevResults.statData.categoryStats;
scallopTesting.classData.fixationDetectionStats = prevResults.classData.fixationResults;

end
