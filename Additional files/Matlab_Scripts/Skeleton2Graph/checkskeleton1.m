function bsk=checkskeleton1(bw,dist,lab,i,j,ro,mark)

[m,n] = size(dist);%�任����Ĵ�С
bsk = 0;
%����8�����pi���߽�������б�
qNeighbor = [];
nNeighbor = 0;
%����p�����߽������
[q(1),q(2)] = Lab2Pos(lab(i,j),m,n);

q = q-uint32([j,i]);
for qi = max(i-1,1):min(i+1,m);
    for qj = max(j-1,1):min(j+1,n);
        bIn = false;
        if bw(qi,qj) == 0 && any([i,j]~=[qi,qj]);
            [tq(1),tq(2)] = Lab2Pos(lab(qi,qj),m,n);
            tq = tq-uint32([j,i]);
            for k = 1:nNeighbor;
                if all(tq == qNeighbor(k,:));
                    bIn  = true;
                    break;
                end;
            end;
        
        
            if ~bIn && ~isempty(tq);
                nNeighbor = nNeighbor+1;
                qNeighbor  = [qNeighbor;tq];
            end;
        end;
    end;
end;

%��ÿһ��(qi,q)�������Լ��Ϳ��Լ��
bIsSkeleton = false;
pro =2*dist(i,j)^2;
%proo=dist(i,j)^2/16;
for k = 1:nNeighbor;
    d = sum((q-qNeighbor(k,:)).^2);
    a1=q(1)+j;
    b1=q(2)+i;
    a2=qNeighbor(k,1)+j;
    b2=qNeighbor(k,2)+i;
    %temp=(a2-a1)^2+(b2-b1)^2
    %if d >= ro
   if d >= min(pro,ro);
   
       if abs(sum(q.^2) - sum(qNeighbor(k,:).^2)) <=1*max(abs( q-qNeighbor(k,:)))&&mark(b1,a1)~=mark(b2,a2)%&&temp>121;
          
            bIsSkeleton = true;
            break;
        end;
    end;
end;

if bIsSkeleton;
    bsk = dist(i,j);
end;

                
                            
        
        