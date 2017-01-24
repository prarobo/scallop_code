function intersectVerdict = checkBBIntersect(BB1, BB2)
%checkBBIntersct returns true if the given 2 bounding boxes intersect

intersectVerdict = (checkBBHelper(BB1, BB2) || checkBBHelper(BB2, BB1));
end

function verdict = checkLim(pt, lwrLim, uprLim)
%checkLim returns true if pt lies between the lwrLim and uprLim
    verdict = (pt >=lwrLim && pt <= uprLim );
end

function verdict = checkBBHelper(BB1, BB2)

verdict = ((checkLim(BB1(1), BB2(1), BB2(1)+BB2(3)-1) && ...
                     checkLim(BB1(2), BB2(2), BB2(2)+BB2(4)-1)) || ...
                    (checkLim(BB1(1)+BB1(3)-1, BB2(1), BB2(1)+BB2(3)-1) && ...
                     checkLim(BB1(2), BB2(2), BB2(2)+BB2(4)-1)) || ...
                    (checkLim(BB1(1), BB2(1), BB2(1)+BB2(3)-1) && ...
                     checkLim(BB1(2)+BB1(4)-1, BB2(2), BB2(2)+BB2(4)-1)) || ...
                    (checkLim(BB1(1)+BB1(3)-1, BB2(1), BB2(1)+BB2(3)-1) && ...
                     checkLim(BB1(2)+BB1(4)-1, BB2(2), BB2(2)+BB2(4)-1)));

end