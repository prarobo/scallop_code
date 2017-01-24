%%/////////////////////////////////////////////////////
%	Andoni Beristain Iraola. PhD. Student. 2009
%  Computer Intelligence Group (GIC). University of The Basque Country UPV/EHU.
%	beristainandoni@yahoo.es
%%/////////////////////////////////////////////////////

% Based in 1999 Identification of Fork Points on the Skeletons of Handwritten Chinese Characters
% @article{Liu1999,
%  author = {Liu,, Ke and Huang,, Yea C. and Suen,, Ching Y.},
%  title = {Identification of Fork Points on the Skeletons of Handwritten Chinese Characters},
%  journal = {IEEE Trans. Pattern Anal. Mach. Intell.},
%  volume = {21},
%  number = {10},
%  year = {1999},
%  issn = {0162-8828},
%  pages = {1095--1100},
%  doi = {http://dx.doi.org/10.1109/34.799914},
%  publisher = {IEEE Computer Society},
%  address = {Washington, DC, USA},
%  }


function [listaNodos,matrizAdyacencia,numNodosFinales]=skel2Graph(imEsqueleto)
%Return: listaNodos: cListaNodos Class object containing the final nodes
%        matrizAdyacencia: adjacency matrix of the resulting graph
%Param : imEsqueleto Pruned skeleton image

xSize=size(imEsqueleto,1);%240
ySize=size(imEsqueleto,2);%320

imResult=zeros(xSize,ySize);

sumaMat=zeros(xSize,ySize);
sumaDifMat=zeros(xSize,ySize);

END_POINT=1;
FORK_POINT=2;
BRANCH_POINT=3;

%% Classify skeleton points as endpoints, jointpoints or branch points
for i=2:xSize-1
    for j=2:ySize-1
        %if belongs to skeleton
        if(imEsqueleto(i,j)>0)
            sumaVec=sumaVecinos(imEsqueleto, i, j);
            sumaDif=difVecinos(imEsqueleto, i, j);

            sumaMat(i,j)=sumaVec;
            sumaDifMat(i,j)=sumaDif;

            % end point
            if sumaVec==1
                imResult(i,j)=END_POINT;
            else
                %it is a fork point
                if ((sumaVec>=3)||(sumaDif>=4))
                    imResult(i,j)=FORK_POINT;
                else
                    %it is a branch point
                    imResult(i,j)=BRANCH_POINT;
                end
            end

        end
    end
end

%% Obtain each point class list
[lEndPX,lEndPY]=find(imResult==END_POINT);
[lForkPX,lForkPY]=find(imResult==FORK_POINT);
[lBranchPX,lBranchPY]=find(imResult==BRANCH_POINT);

 matBranchPoint=zeros(xSize,ySize);
 numBPt=size(lBranchPX,1);
 for l=1:numBPt
     matBranchPoint(lBranchPX(l),lBranchPY(l))=1;
 end


%% Graph construction
% 1. Every end and fork point is considered feature point and initial graph
% nodes.

% 2. Compute every branch between points. 

% 3. Remove touching nodes.

%% Create initial node list with the centroid of fork point groups and the
%% end points.
[listaNodos,imagenGrupos]=limpiarNodosFp(imResult,lForkPX,lForkPY,lEndPX,lEndPY);

%% Show the nodes of limpiarNodosFp
numFPReducido=listaNodos.numNodos();

disp(strcat('skel2Graph --> Number of Nodes:',int2str(numFPReducido)));

IlimpiarNodosFp=zeros(xSize,ySize);

for n=1:numFPReducido
    suma=0;
    switch listaNodos.n(n).tipo
        case END_POINT
            suma=2;
        case FORK_POINT
            suma=3;
            numRamas=listaNodos.n(n).numVecinos();
            for k=1:numRamas
                [i,j]=listaNodos.n(n).vecinoI(k);
                if(i<0)
                    continue;
                end
                IlimpiarNodosFp(i,j)=IlimpiarNodosFp(i,j)+3;
            end
        case BRANCH_POINT
            suma=4;
            numRamas=listaNodos.n(n).numVecinos();
            for k=1:numRamas
                [i,j]=listaNodos.n(n).vecinoI(k);
                if(i<0)
                    continue;
                end
                IlimpiarNodosFp(i,j)=IlimpiarNodosFp(i,j)+3;
            end
    end
    IlimpiarNodosFp(listaNodos.n(n).x,listaNodos.n(n).y)=IlimpiarNodosFp(listaNodos.n(n).x,listaNodos.n(n).y)+suma;
end

subplot(1,2,1)
imagesc(imagenGrupos);
title('Nodes in the group image');
for n=1:numFPReducido
    text(listaNodos.n(n).y,listaNodos.n(n).x,int2str(n));
end

subplot(1,2,2);
%Binary image with feature points
imagesc(IlimpiarNodosFp+matBranchPoint);
title('Skeleton with final nodes');
for n=1:numFPReducido
    text(listaNodos.n(n).y,listaNodos.n(n).x,int2str(n));
end

%% Obtain adjacency matrix
[matrizAdyacencia,numNodosFinales]=vCaracV1(matBranchPoint,imagenGrupos,listaNodos);

end

%Computes the 8-neighbourhood number of neighbours of a pixel
function ret=sumaVecinos(matriz, x, y)
ret=sum(sum(matriz(x-1:x+1,y-1:y+1)))-1;
end

%Computes the absolute difference between adjacent pixel in horary order of
%the 8-neighbourhood of a pixel
function ret=difVecinos(matriz, x, y)
ret=0;
oX=[-1,-1,0,1,1,1,0,-1];
oY=[0,-1,-1,-1,0,1,1,1];

maxIter=size(oX,2);
for it=1:maxIter-1
    ret=ret+abs(matriz(x+oX(it+1),y+oY(it+1))-matriz(x+oX(it),y+oY(it)));
end

ret=ret+abs(matriz(x+oX(1),y+oY(1))-matriz(x+oX(maxIter),y+oY(maxIter)));
ret=ret/2;
end