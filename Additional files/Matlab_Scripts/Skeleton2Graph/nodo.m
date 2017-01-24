%%/////////////////////////////////////////////////////
%	Andoni Beristain Iraola. PhD. Student. 2009
%  Computer Intelligence Group (GIC). University of The Basque Country UPV/EHU.
%	beristainandoni@yahoo.es
%%/////////////////////////////////////////////////////

classdef nodo < handle
    properties
        % Node coordinates
        x=0;
        y=0;
        % Node type
        tipo=1;
        % Real node or virtual node
        esAbstracto=false;
        
        % Coordinates of the first skeleton branch pixel of each branch
        %originating from the node.
        lVecRamax;
        lVecRamay;
    end
    properties
        % Number of branches connected to this node
        numVecRama=0;
    end
    properties (Constant)
        % Possible values for property tipo.
        END_POINT=1;
        FORK_POINT=2;
        BRANCH_POINT=3;
    end
    methods
        % Adds a neighbouring branch's initial pixel
        function anadirVecino(this,x,y)
            this.lVecRamax(this.numVecRama+1)=x;
            this.lVecRamay(this.numVecRama+1)=y;
            this.numVecRama=this.numVecRama+1;
        end
        % Returns the number of neighbours
        function val=numVecinos(this)
            val=this.numVecRama;
        end
        % Returns the coordinates of the first BRANCH_POINT for the i-th neighbouring branch.
        function [x,y]=vecinoI(this,i)
            if i>this.numVecRama
                x=-1;
                y=-1;
            else
                x=this.lVecRamax(i);
                y=this.lVecRamay(i);
            end
        end
        
        % Deletes neighbour i of the node.
        function eliminarVecino(this,i)
            if i>0&&i<=this.numVecRama
                this.lVecRamax(:,i)=[];
                this.lVecRamax(:,i)=[];
                this.numVecRama=max(this.numVecRama-1,0);
            end
        end

        %Assgination functions
        function this=set.x(this,x)
            assert(x>=0,'nodo.x must be >=0');
            this.x=x;
        end
        function this=set.y(this,y)
            assert(y>=0,'nodo.y must be >=0');
            this.y=y;
        end
        function x=get.x(this)
            x=this.x;
        end
    end
end
