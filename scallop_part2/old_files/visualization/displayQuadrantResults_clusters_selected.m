function [] = displayQuadrantResults_clusters_selected( params, quadrantID )
%DISPLAYQUADRANTRESULTS Function to display quadrant results

%% Initialization

quadrantI = 1;
numQuadrants = params.numQuadrants;
showAllQuadrants = false;
showAllQuadrantsSel = false;

figure;

%% User Interface to toggle between features and quadrants

while true
    displayNow( params, quadrantID, quadrantI, showAllQuadrants, showAllQuadrantsSel );
    
    ch = waitforbuttonpress;
    if ch == 1
        key = get(gcf,'CurrentCharacter');
        switch key
            case 'a'     
                showAllQuadrants = false;
                showAllQuadrantsSel = false;
                if quadrantI ~=1
                    quadrantI=quadrantI-1;
                else
                    quadrantI = numQuadrants;
                end
            case 'd'
                showAllQuadrants = false;
                showAllQuadrantsSel = false;
                if quadrantI ~= numQuadrants
                    quadrantI = quadrantI+1;
                else
                    quadrantI = 1;
                end
            case 'r'
                showAllQuadrantsSel = false;
                showAllQuadrants = ~showAllQuadrants;
            case 'f'
                showAllQuadrants = false;
                showAllQuadrantsSel = ~showAllQuadrantsSel;                
            case 'q'
                close(gcf);
                break;
            otherwise
                disp('d/a-next/previous quadrant, r-show all quadrants, f-show all quadrants selected, q-quit');
        end
    else
        disp('d/a-next/previous quadrant, r-show all quadrants, f-show all quadrants selected, q-quit');
    end
end

end

%% Display now function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function displayNow( params, quadrantID, quadrantI, showAllQuadrants, showAllQuadrantsSel )

quadrantRow = floor(quadrantI/params.numWidthQuadrants)+1;
quadrantCol = mod( quadrantI, params.numWidthQuadrants );
if quadrantCol == 0
    quadrantCol = params.numWidthQuadrants;
    quadrantRow = quadrantRow-1;
end
numQuadrants = params.numQuadrants;
numWidthQuadrants = params.numWidthQuadrants;
numHeightQuadrants = params.numHeightQuadrants;

if showAllQuadrants
    for quadrantI = 1:numQuadrants
        subplot(numHeightQuadrants, numWidthQuadrants, quadrantI)
        scatter( quadrantID(quadrantI).mappedData(:,1), quadrantID(quadrantI).mappedData(:,2) );
    end
elseif showAllQuadrantsSel
    for quadrantI = 1:numQuadrants
        subplot(numHeightQuadrants, numWidthQuadrants, quadrantI)
        scatter( quadrantID(quadrantI).mappedDataSel(:,1), quadrantID(quadrantI).mappedDataSel(:,2) );
    end    
else
    axisLimits = computeAxisLimits( quadrantID(quadrantI).mappedData, quadrantID(quadrantI).mappedDataSel);
    clf
    subplot(121)
    scatter( quadrantID(quadrantI).mappedData(:,1), quadrantID(quadrantI).mappedData(:,2) );
    title( sprintf('Quadrant %d %d All Attributes', quadrantRow, quadrantCol) );
    axis( axisLimits );
    subplot(122)
    scatter( quadrantID(quadrantI).mappedDataSel(:,1), quadrantID(quadrantI).mappedDataSel(:,2) );
    title( sprintf('Quadrant %d %d Selected Attributes', quadrantRow, quadrantCol) );   
    axis( axisLimits );
end

end

%% Function to compute axis limits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function axisLimits = computeAxisLimits( data1, data2 )

axisLimits = zeros(1,4);

axisLimits(1) = min( min(data1(:,1)), min(data2(:,1)) );
axisLimits(2) = max( max(data1(:,1)), max(data2(:,1)) );
axisLimits(3) = min( min(data1(:,2)), min(data2(:,2)) );
axisLimits(4) = max( max(data1(:,2)), max(data2(:,2)) );

end

