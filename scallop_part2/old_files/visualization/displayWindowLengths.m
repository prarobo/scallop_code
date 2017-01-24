function displayWindowLengths( visualAttnData )
% Computing windowlength statistics

fixationResults = visualAttnData.finalResults.fixStats;
fixationWindowLength = min( visualAttnOutData.params.fixationWindowSize(:))/2;
numGroundScallops = visualAttnOutData.finalResults.numGroundTruthScallops;
numImages = length( fixationResults.distFixScallop );

windowVect = [];
for imageI = 1:numImages
    numScallops = length( fixationResults.distFixScallop{imageI} );
    for scallopI =1:numScallops
        if fixationResults.distFixScallop{imageI}(scallopI) ~= -1 && ~isinf(fixationResults.distFixScallop{imageI}(scallopI))
            windowVect = [windowVect fixationResults.distFixScallop{imageI}(scallopI)];
        end
    end
end

% hist(windowVect);
windowStat = histc(windowVect, 1:fixationWindowLength);
cumVal = (cumsum(windowStat)./numGroundScallops).*100;
plot(1:fixationWindowLength,cumVal);

end

