function [ scallopTesting ] = loadScallopPrevResultsBarebones( scallopTesting, prevResultsFile )
%LOADSCALLOPPREVRESULTS Loads data from previous 3-layered scallop
%classification results

%% Loading previous results
prevResults = goodLoad(prevResultsFile);

%% Loading params
scallopTesting.prevParams = prevResults.params;
scallopTesting.params.gCM = prevResults.params.gCM;
scallopTesting.params.gFM = prevResults.params.gFM;
scallopTesting.params.boundaryCropPercent = prevResults.params.boundaryCropPercent;

end