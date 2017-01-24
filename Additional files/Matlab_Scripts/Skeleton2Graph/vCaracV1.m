%%/////////////////////////////////////////////////////
%	Andoni Beristain Iraola. PhD. Student. 2009
%  Computer Intelligence Group (GIC). University of The Basque Country UPV/EHU.
%	beristainandoni@yahoo.es
%%/////////////////////////////////////////////////////

function [mAdjacency,nNodes]=vCaracV1(iBranch,iGroups,lNodes)
%----------------------------------------
%Name: mAdjacency=vCaracV1(iBranch,iGroups,lNodesI)
%Desc: Based on the initial node classification of limpiar NodosFP
%obtains the adjacency matrix and the final node list
% This version employs only the feature points and the links between them
% feature vector. Skeleton branches are not characterized
%Param: iBranch: Binary image. If iBranch(x,y) is branch type then 1, else 0
%      iGroups: Binary image. If iGroups(x,y) is not a node pixel then its
%      value is 0, otherwise indicates the node id to which it belongs to
%      lNodes: cListaNodos object with the node list
%Return: mAdjacency: Adjacency matrix
%        nNodes: Number of resulting nodes.
%----------------------------------------
%% Initialization


numNodos=lNodes.numNodos();
nNodes=numNodos;

disp(strcat('vCaracV1 --> Number of nodes: ',int2str(numNodos)));

mAdjacency=zeros(numNodos,numNodos);% In this version it does not grow, it is static.

iR=iBranch;%The procedure will progressively erase the branch image, therefore a copy is done. It is not really necessary because parameters are passed by value.

%8-Neighbouring pixel visiting order
oX=[-1,-1,0,1,1,1,0,-1];
oY=[0,-1,-1,-1,0,1,1,1];

%% Compute all the segments with origin in each neighbour of each node
for nAbst=1:numNodos
    %For each branch of each node
    numRamas=lNodes.n(nAbst).numVecinos();

    hayRamasQueEliminar=false;
    branchesToRemove(1,1)=-1;

    for r=1:numRamas
        %Get r-th neighbour of the virtual nodel nAbst
        [xt,yt]=lNodes.n(nAbst).vecinoI(r);

        pt.x=xt;
        pt.y=yt;

        %Mark the first entrance point to avoid going back to it

        %The first point of the branch is special since it has at least a FORK_POINT or an END_POINT in its
        %neighbourhood. That from which it comes

        ptOrigen.x=pt.x;
        ptOrigen.y=pt.y;
        %Case when a neighbour is a feature point
        %Only between FORK_POINT and END_POINT

        idGrupoPt=iGroups(pt.x,pt.y);
        if idGrupoPt>0
            mAdjacency(nAbst,idGrupoPt)=mAdjacency(nAbst,idGrupoPt)+1;
            mAdjacency(idGrupoPt,nAbst)=mAdjacency(idGrupoPt,nAbst)+1;
            continue;
        end

        if iR(pt.x,pt.y)==0%This branch has already been visited
            continue;
        end

        %Visit neighbours

        longRama=1;

        nOut=-1;
        seguir=true;
        while seguir
            seguir=false;
            %Visit neighbours
            for v=1:8
                pvec.x=pt.x+oX(v);
                pvec.y=pt.y+oY(v);

                %it is a branch point

                if iR(pvec.x,pvec.y)>0
                    iR(pt.x,pt.y)=0;%delete actual pixel
                    pt.x=pvec.x;%go
                    pt.y=pvec.y;

                    longRama=longRama+1;

                    seguir=true;
                    break;
                else

                    vImGrupos=iGroups(pvec.x,pvec.y);

                    if ((vImGrupos>0)&&(vImGrupos~=nAbst))
                        %I suppose that there are not branches with the
                        %same origin and destination node

                        %Check if the point itself is a feature point
                        %to erase it or not

                        if(iGroups(pt.x,pt.y)==0)
                            iR(pt.x,pt.y)=0;
                        end
                        nOut=vImGrupos;
                        break;
                    end
                end
            end
        end

        if nOut>0
            mAdjacency(nAbst,nOut)=mAdjacency(nAbst,nOut)+1;
            mAdjacency(nOut,nAbst)=mAdjacency(nOut,nAbst)+1;
        else
            %It is an incorrectly classified branch, therefore
            %this node neighbour can be removed and reduce its neighbour
            %number

            %Mark nodes to remove
            if longRama<=1
                hayRamasQueEliminar=true;
                tamElim=size(branchesToRemove);
                branchesToRemove(tamElim+1)=r;
            end

        end

    end

    %Remove neighbours that don't go to any feature point
    %Case when a L shape appears:

    if hayRamasQueEliminar
        tamElim=size(branchesToRemove);
        for relim=tamElim:-1:1
            lNodes.n(nAbst).eliminarVecino(relim);
        end

        switch lNodes.n(nAbst).numVecinos()
            case 1
                lNodes.n(nAbst).tipo=nodo.END_POINT;
            case 2
                lNodes.n(nAbst).tipo=nodo.BRANCH_POINT;
            otherwise
                lNodes.n(nAbst).tipo=nodo.FORK_POINT;
        end
    end
end
end
