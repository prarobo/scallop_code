function [] = displayQuadrantResults_clusters( params, quadrantID )
%DISPLAYQUADRANTRESULTS Function to display quadrant results

%% Initialization

quadrantI = 1;
numQuadrants = params.numQuadrants;
showAllQuadrants = false;

figure;

%% User Interface to toggle between features and quadrants

while true
    displayNow( params, quadrantID, quadrantI, showAllQuadrants );
    
    ch = waitforbuttonpress;
    if ch == 1
        key = get(gcf,'CurrentCharacter');
        switch key
            case 'a'     
                if showAllQuadrants
                    showAllQuadrants = false;
                end
                if quadrantI ~=1
                    quadrantI=quadrantI-1;
                else
                    quadrantI = numQuadrants;
                end
            case 'd'
                if showAllQuadrants
                    showAllQuadrants = false;
                end                
                if quadrantI ~= numQuadrants
                    quadrantI = quadrantI+1;
                else
                    quadrantI = 1;
                end
            case 'r'               
                showAllQuadrants = ~showAllQuadrants;
            case 'q'
                close(gcf);
                break;
            otherwise
                disp('d/a-next/previous quadrant, r-show all quadrants, q-quit');
        end
    else
        disp('d/a-next/previous quadrant, r-show all quadrants, q-quit');
    end
end

end

%% Display now function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function displayNow( params, quadrantID, quadrantI, showAllQuadrants )

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
else
    clf
    scatter( quadrantID(quadrantI).mappedData(:,1), quadrantID(quadrantI).mappedData(:,2) );
    title( sprintf('Quadrant %d %d', quadrantRow, quadrantCol) );    
end

end

