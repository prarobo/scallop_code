%%/////////////////////////////////////////////////////
%	Andoni Beristain Iraola. PhD. Student. 2009
%  Computer Intelligence Group (GIC). University of The Basque Country UPV/EHU.
%	beristainandoni@yahoo.es
%%/////////////////////////////////////////////////////

%% Initialize environment
function Test1Elemento()
clear;
close all;
clc;

%% Load sample image
% user_entry = input('Enter binary image path as a string to obtain skeleton graph:\n');
user_entry = 'carriage-17.GIF';

Imagen=imread(user_entry);
ManoB = im2bw(Imagen);

figure;imshow(ManoB);

ft=zeros(size(ManoB));% feature transform (normalized [0..255])
dt=zeros(size(ManoB));% Distance transform (normalized [0..255])
skel=zeros(size(ManoB));% image skeleton
dtCrudo=zeros(size(ManoB));%Real Distance Transform

%% Compute distance transform (dist), feature transform (lab) and skeleton
%% (skel)

xTam=size(ManoB ,1);
yTam=size(ManoB ,2);

%The skeletonization procedure requires the image to have a background
%contour
ManoB(1:3,:)=0;
ManoB(:,1:3)=0;
ManoB(xTam-3:xTam,:)=0;
ManoB(:,yTam-3:yTam)=0;


ManoBNegativo=1-ManoB;

[dtTmp,ftTmp] = bwdist(ManoBNegativo);

dtCrudo=dtTmp;

dt=round(dtTmp);

maxFtTmp=max(max(ftTmp));
ftF=ftTmp/maxFtTmp;
ftF=ftF*255;
ftF=round(ftTmp);% Normalization of feature transform [0..255].


% @article{bai2007,
% 	address = {Washington, DC, USA},
% 	author = {Bai, Xiang   and Latecki, Longin  J.  and Liu, Wen  Y. },
% 	citeulike-article-id = {4195001},
% 	doi = {http://dx.doi.org/10.1109/TPAMI.2007.59},
% 	journal = {{IEEE} Transactions on Pattern Analysis and Machine Intelligence},
% 	keywords = {skeletonization},
% 	number = {3},
% 	pages = {449--462},
% 	posted-at = {2009-03-19 12:52:27},
% 	priority = {0},
% 	publisher = {IEEE Computer Society},
% 	title = {Skeleton Pruning by Contour Partitioning with Discrete Curve Evolution},
% 	url = {http://dx.doi.org/http://dx.doi.org/10.1109/TPAMI.2007.59},
% 	volume = {29},
% 	year = {2007}
% }

% Source: http://knight.cis.temple.edu/~shape/partshape/structure/

[skel,IO,x,y,x1,y1,aa,bb]=div_skeleton_new(4,1,ManoBNegativo,15);
skel=im2bw(skel);

figure;imshow(skel);

%% Obtain graph from skeleton
nuevoBin=skel;

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

[lNod,MatAdya,numNod]=skel2Graph(nuevoBin);

%% Show skeleton graph
xy=zeros(numNod,2);
for nF=1:numNod
    xy(nF,1)=lNod.n(nF).x;
    xy(nF,2)=lNod.n(nF).y;
end

figure;
%subplot(1,2,1);
gplot(MatAdya,xy,'-o');

for n=1:numNod
    text(lNod.n(n).x,lNod.n(n).y,int2str(n));
end

end
