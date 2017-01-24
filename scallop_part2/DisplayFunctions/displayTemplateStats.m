function displayTemplateStats( templateData )
%DISPLAYTEMPLATESTATS display template matching value histograms

%% Initialization
templateAvailable = templateData.templateAvailable;
templateNumbers = templateData.templateMatchNumbers(templateAvailable);
numScallops = length(templateNumbers);
templateMatchStruct(numScallops) = templateNumbers{end};
totalScallops = length(templateAvailable);

%% Cell to struct
for scallopI=1:numScallops
    templateMatchStruct(scallopI) = templateNumbers{scallopI};
end

%% Histograms
figure('Name', sprintf('Total scallops = %d, Valid scallops = %d', totalScallops, numScallops));
subplot(141); hist([templateMatchStruct.corrVal], 100); title('Correlation values');
subplot(142); hist([templateMatchStruct.corrWtVal], 100); title('Weighted correlation values');
subplot(143); hist([templateMatchStruct.ssdVal], 100); title('ssd values');
subplot(144); hist([templateMatchStruct.ssdWtVal], 100); title('Weighted ssd values');

end


