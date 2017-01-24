%%/////////////////////////////////////////////////////
%	Andoni Beristain Iraola. PhD. Student. 2009
%  Computer Intelligence Group (GIC). University of The Basque Country UPV/EHU.
%	beristainandoni@yahoo.es
%%/////////////////////////////////////////////////////

function [lNodes,imGroups]=limpiarNodosFp(imClasif, lForkX,lForkY,lEndX,lEndY)
%Output: listaNodos: cListaNodos Class object containing the final nodes
%        imGroups: Node labeling image. For each skeleton pixel indicates
%        the node id it belongs to. 0 means that it doesn't belong to any
%        node.
%input : imClasif: image showing the type of skeleton for each pixel
%(FORK_POINT, END_POINT or BRANCH_POINT)
%        lForkX: x coordinate of the FORK_POINT list
%        lForkY: y coordinate of the FORK_POINT list
%        lEndX: x coordinate of the END_POINT list
%        lEndY: y coordinate of the END_POINT list
%% Inicialización

%Point type
END_POINT=1;
FORK_POINT=2;
BRANCH_POINT=3;

%Number of Fork and end points
numFP=size(lForkX,1);
numEP=size(lEndX,1);

%Input image size
xSize=size(imClasif,1);
ySize=size(imClasif,2);

lNodes=cListaNodos;


%% get fork points image, end points image and branch points image.

matForkPoint=zeros(xSize,ySize);
for l=1:numFP
    matForkPoint(lForkX(l),lForkY(l))=1;
end

%% Obtain every fork point group in an image

numFPReducido=0;
%Matrix with pixel groups to collapse into 1
matPuntosAReducir=matForkPoint;%Only for FORK_POINTs.

%Create image with node ID for each group
imGroups=zeros(xSize,ySize);

[imGroups,numFPReducido]=bwlabel(matPuntosAReducir);

disp(strcat('limpiarNodosFp --> Fork number node= ',int2str(numFPReducido)));


%% Create final fork nodes

oX=[-1,-1,0,1,1,1,0,-1];
oY=[0,-1,-1,-1,0,1,1,1];

for nr=1:numFPReducido

    %Obtain point list for point group nr
    [tmpPtosx,tmpPtosy]=find(imGroups==nr);

    %Create node instance
    nodTmp=nodo;

    numPtTmp=size(tmpPtosx,1);%Point number of the fork points group
    nodTmp.esAbstracto=numPtTmp>1;%Indicates if it is or not a group

    sumax=0;
    sumay=0;


    %There is a case where the neighbouring branch obtaining function
    %fails:
    %If we have a L shaped branch of 1 pixel thick, the pixel in the corner
    %forming the 90º angle is classified as a fork point but both points
    %connected to it are classified wrongly as joint points.

    for p=1:numPtTmp
        %Summing for centroid
        sumax=sumax+tmpPtosx(p);
        sumay=sumay+tmpPtosy(p);
        %Look for branch points in the neighbourhood
        %Add to the branch neighbour list
        for vec=1:8
            pVecX=tmpPtosx(p)+oX(vec);
            pVecY=tmpPtosy(p)+oY(vec);
            if((imClasif(pVecX,pVecY)==END_POINT)||(imClasif(pVecX,pVecY)==BRANCH_POINT))
                %Avoid to insert the same neigbour several times
                numVecActuales=nodTmp.numVecinos();
                insertar=true;
                for vecActuales=1:numVecActuales
                    [xt,yt]=nodTmp.vecinoI(vecActuales);
                    if(xt==pVecX)&&(yt==pVecY)
                        insertar=false;
                    end
                end
                if insertar==true
                    nodTmp.anadirVecino(pVecX,pVecY);
                end
            end
        end
    end

    %Compute centroid
    nodTmp.x=(round(sumax/numPtTmp));
    nodTmp.y=(round(sumay/numPtTmp));


    %Set the node type based in the number of neigbours END_POINT Y BRANCH_POINT
    %of the virtual node
    if(nodTmp.esAbstracto)
        switch nodTmp.numVecinos()
            case 1
                nodTmp.tipo=END_POINT;
            case 2
                nodTmp.tipo=BRANCH_POINT;
            otherwise
                nodTmp.tipo=FORK_POINT;
        end
    else
        %If it is not a virtual node, then the initial classification was
        %correct
        nodTmp.tipo=FORK_POINT;
    end

    %Añadir nodo a la clase
    lNodes.addN(nodTmp);
end

%% Add every end point
% They are allways unique and can not be grouped like fork points, so there
% is no need for "cleaning"

for en=numFPReducido+1:numFPReducido+numEP
    imGroups(lEndX(en-numFPReducido),lEndY(en-numFPReducido))=en;%add "group" or idNodo for end points
    nodTmp2=nodo;
    nodTmp2.x=lEndX(en-numFPReducido);
    nodTmp2.y=lEndY(en-numFPReducido);
    nodTmp2.tipo=END_POINT;
    nodTmp2.esAbstracto=false;

    %Add neighbouring branch, that can directly be a fork point
    for vec=1:8
        px=nodTmp2.x+oX(vec);
        py=nodTmp2.y+oY(vec);
        if imClasif(px,py)>0%es del esqueleto
            nodTmp2.anadirVecino(px,py);
            break;
        end
    end

    %Add node to the class
    lNodes.addN(nodTmp2);
end

end