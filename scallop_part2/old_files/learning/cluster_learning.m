function [ clusterData, params] = cluster_learning( params, argNumClusters )
%CLUSTER_LEARNING Clustering from scallop attributes

%% Initialization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin == 1
    params.numClusters = 4;
elseif nargin == 2
    params.numClusters = argNumClusters;
else
    error('Boo! Incompatible arguments in function %s', mfilename );
end

%% Loading Data and Correction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[attributeData, ~, params] = dataCorrection( params );

%% Evaluating Number of Clusters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

newDims = 2;
[clusterData.mappedData, clusterData.mapping] = pcaReduction( attributeData, newDims );

scatter( clusterData.mappedData(:,1), clusterData.mappedData(:,2) );

%% Clustering Data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[clusterData.id, clusterData.centroid, clusterData.sumd, clusterData.ptDist ] = kmeans(attributeData, params.numClusters);

end

