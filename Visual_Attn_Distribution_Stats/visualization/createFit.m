function [pd1,pd2] = createFit(nonScallopDistrMatchCounts,scallopDistrMatchCounts)
%CREATEFIT    Create plot of datasets and fits
%   [PD1,PD2] = CREATEFIT(NONSCALLOPDISTRMATCHCOUNTS,SCALLOPDISTRMATCHCOUNTS)
%   Creates a plot, similar to the plot in the main distribution fitting
%   window, using the data that you provide as input.  You can
%   apply this function to the same data you used with dfittool
%   or with different data.  You may want to edit the function to
%   customize the code and this help message.
%
%   Number of datasets:  2
%   Number of fits:  2
%
%   See also FITDIST.

% This function was automatically generated on 30-May-2013 16:34:40

% Output fitted probablility distributions: PD1,PD2

% Data from dataset "nonScallopDistrMatchCounts data":
%    Y = nonScallopDistrMatchCounts

% Data from dataset "scallopDistrMatchCounts data":
%    Y = scallopDistrMatchCounts

% Force all inputs to be column vectors
nonScallopDistrMatchCounts = nonScallopDistrMatchCounts(:);
scallopDistrMatchCounts = scallopDistrMatchCounts(:);

% Prepare figure
clf;
hold on;
LegHandles = []; LegText = {};


% --- Plot data originally in dataset "nonScallopDistrMatchCounts data"
[CdfF,CdfX] = ecdf(nonScallopDistrMatchCounts,'Function','cdf');  % compute empirical cdf
BinInfo.rule = 1;
[~,BinEdge] = internal.stats.histbins(nonScallopDistrMatchCounts,[],[],BinInfo,CdfF,CdfX);
[BinHeight,BinCenter] = ecdfhist(CdfF,CdfX,'edges',BinEdge);
hLine = bar(BinCenter,BinHeight,'hist');
set(hLine,'FaceColor','none','EdgeColor',[0.333333 0 0.666667],...
    'LineStyle','-', 'LineWidth',1);
xlabel('Data');
ylabel('Density')
LegHandles(end+1) = hLine;
LegText{end+1} = 'nonScallopDistrMatchCounts data';

% --- Plot data originally in dataset "scallopDistrMatchCounts data"
[CdfF,CdfX] = ecdf(scallopDistrMatchCounts,'Function','cdf');  % compute empirical cdf
BinInfo.rule = 1;
[~,BinEdge] = internal.stats.histbins(scallopDistrMatchCounts,[],[],BinInfo,CdfF,CdfX);
[BinHeight,BinCenter] = ecdfhist(CdfF,CdfX,'edges',BinEdge);
hLine = bar(BinCenter,BinHeight,'hist');
set(hLine,'FaceColor','none','EdgeColor',[0.333333 0.666667 0],...
    'LineStyle','-', 'LineWidth',1);
xlabel('Data');
ylabel('Density')
LegHandles(end+1) = hLine;
LegText{end+1} = 'scallopDistrMatchCounts data';

% Create grid where function will be computed
XLim = get(gca,'XLim');
XLim = XLim + [-1 1] * 0.01 * diff(XLim);
XGrid = linspace(XLim(1),XLim(2),100);


% --- Create fit "nonscallop burr"

% Fit this distribution to get parameter values
% To use parameter estimates from the original fit:
%     pd1 = ProbDistUnivParam('burr',[ 325.854175606, 139.974897648, 0.03340016277454])
pd1 = fitdist(nonScallopDistrMatchCounts, 'burr');
YPlot = pdf(pd1,XGrid);
hLine = plot(XGrid,YPlot,'Color',[1 0 0],...
    'LineStyle','-', 'LineWidth',2,...
    'Marker','none', 'MarkerSize',6);
LegHandles(end+1) = hLine;
LegText{end+1} = 'nonscallop burr';

% --- Create fit "scallop"

% Fit this distribution to get parameter values
% To use parameter estimates from the original fit:
%     pd2 = ProbDistUnivParam('burr',[ 458.7966450181, 14.12924051012, 1.29087678912])
pd2 = fitdist(scallopDistrMatchCounts, 'burr');
YPlot = pdf(pd2,XGrid);
hLine = plot(XGrid,YPlot,'Color',[0 0 1],...
    'LineStyle','-', 'LineWidth',2,...
    'Marker','none', 'MarkerSize',6);
LegHandles(end+1) = hLine;
LegText{end+1} = 'scallop';

% Adjust figure
box on;
hold off;

% Create legend from accumulated handles and labels
hLegend = legend(LegHandles,LegText,'Orientation', 'vertical', 'Location', 'NorthEast');
set(hLegend,'Interpreter','none');
