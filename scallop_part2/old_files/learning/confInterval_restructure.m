function confIntervalDataEff = confInterval_restructure( confIntervalData )
%CONFINTERVAL_RESTRUCTURE store lookup data efficiently

%% Initialization

[numRows, numCols] = size(confIntervalData.isValid);

%% Restructuring
for rowI = 1:numRows
    for colI = 1:numCols
        varname = sprintf('conf_%d_%d',rowI, colI);
        confIntervalDataEff.(varname).confInterval = confIntervalData.confInterval{rowI,colI};
        confIntervalDataEff.(varname).isvalid = confIntervalData.isValid(rowI,colI);
        confIntervalDataEff.(varname).numPoints = confIntervalData.numPoints(rowI,colI);
        confIntervalDataEff.(varname).pointsID = confIntervalData.pointsID{rowI,colI};
        confIntervalDataEff.(varname).meanPoints = confIntervalData.meanPoints{rowI,colI};
        confIntervalDataEff.(varname).stddevPoints = confIntervalData.stddevPoints{rowI,colI};
    end
end

end