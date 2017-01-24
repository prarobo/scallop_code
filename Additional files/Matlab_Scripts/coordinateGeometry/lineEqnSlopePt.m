function [ lineEqn ] = lineEqnSlopePt( x1, y1, m )
%lineEqnSlopePt Computes the line equation given one point and slope. The output
%equation is of the form lineEqn = [a b c] where ax+by+c=0

if m ~= inf && m ~= -inf
    a = m;    
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

