%%/////////////////////////////////////////////////////
%	Andoni Beristain Iraola. PhD. Student. 2009
%  Computer Intelligence Group (GIC). University of The Basque Country UPV/EHU.
%	beristainandoni@yahoo.es
%%/////////////////////////////////////////////////////

classdef cListaNodos < handle
    properties (GetAccess='private', SetAccess='private')
        % Node list
        lista=nodo;
        % Number of nodes in the list
        numElem=0;
    end
    properties (Constant)
        END_POINT=1;
        FORK_POINT=2;
        BRANCH_POINT=3;
    end
    methods
        % returns a copy of the node at index i
        function nod=n(this,i)
            assert(i>=1 && i<=this.numElem,'Error en listaNodos. Función n: el índice está fuera de rango');
            nod=this.lista(i);
        end
        % adds a node at the end of the list
        function addN(this,nod)
            this.numElem=this.numElem+1;
            this.lista(this.numElem)=nodo;
            this.lista(this.numElem)=nod;
        end
        % deletes a node from the end of the list
        function delN(this,i)
            assert(i>=1 && i<=this.numElem,'Error in listaNodos. Función n: index out of range');
            this.lista(i)=[];
            this.numElem=this.numElem-1;
        end
        % returns the number of nodes in the list
        function total=numNodos(this)
            total=this.numElem;
        end
    end
end