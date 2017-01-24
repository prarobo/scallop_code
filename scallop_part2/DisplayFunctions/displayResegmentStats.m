function displayResegmentStats( resegmentData )
%DISPLAYRESEGMENTSTATS Display resegmentation statistics

%% Initialization
resegAvailable = resegmentData.resegAvailable;
statNumbers = resegmentData.statNumbers(resegAvailable);
numScallops = length(statNumbers);
statStruct(numScallops) = statNumbers{end};
totalScallops = length(resegAvailable);

%% Cell to struct
for scallopI=1:numScallops
    statStruct(scallopI) = statNumbers{scallopI};
end

%% Histograms
figure('Name', sprintf('Total scallops = %d, Valid scallops = %d', totalScallops, numScallops));
subplot(141); hist([statStruct.segmentApprecPercent], 100); title('Segment Aprreciation');
subplot(142); hist([statStruct.fgInCircPercent], 100); title('FG in circle');
subplot(143); hist([statStruct.segmentInCircPercent], 100); title('Segment in circle');
subplot(144); hist([statStruct.segmentOutCircPercent], 100); title('Segment out circle');

end
