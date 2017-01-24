function [ lineEqn ] = lineEqn2Pt( x1, y1, x2, y2 )
%lineEqn2Pt Computes the line equation given two points in the line. The output
%equation is of the form lineEqn = [a b c] where ax+by+c=0

if x2-x1 ~= 0
    a = (y2-y1)/(x2-x1);    
    b = -1;
    c = y1-a*x1;
else
    a = 1;
    b = 0;
    c = -x1;
end    

lineEqn.a = a;
lineEqn.b = b;
lineEqn.c = c;

end

