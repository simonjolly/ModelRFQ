function enhanceFigure(figureNo)
%
% function enhanceFigure([figureNo])
%
%	enhanceFigure enhances the line width and text settings on a plot ready 
%   for export as a JPEG file. 
%
%   Based on jpgplot by Simon Jolly, which was in turn based on 
%   Janice Nelson's ENHANCE_PLOT function.
%
%   enhanceFigure() 
%     - changes the text setting of the title, xlabel, ylabel and, if 
%       available, the legend, of the current figure to make them
%       more easily readable when exporting to a JPEG file.
%
%   enhanceFigure(figureNo) 
%     - adjusts settings for the figure figureNo.
%
%   The Font/line settings are as follows:
%        Font: 'Times'
%        Font size: 14
%        Line width: 1
%
%   See also plotTrajectories, modelRFQ.

% File released under the GNU public license.
% Originally written by Matt Easton for ModelRFQ distribution. Functional
% code taken from jpgplot by Simon Jolly of Imperial Colege London
%
% File history
%
%   20-Dec-2010 M. J. Easton
%       Created function enhanceFigure as part of ModelRFQ distribution.
%
%=========================================================================

%% Check syntax 

    try %to check syntax 
        if nargin > 1 %then throw error ModelRFQ:Functions:enhanceFigure:excessiveInputArguments 
            error('ModelRFQ:Functions:enhanceFigure:excessiveInputArguments', ...
                  'Can only specify 1 input argument: enhanceFigure([figureNo])');
        end
        if nargout > 0 %then throw error ModelRFQ:Functions:enhanceFigure:excessiveOutputArguments 
            error('ModelRFQ:Functions:enhanceFigure:excessiveOutputArguments', ... 
                  'enhanceFigure does accept output arguments: enhanceFigure([figureNo])');
        end        
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:Functions:enhanceFigure:syntaxException';
        message.text = 'Syntax error calling enhanceFigure: correct syntax is enhanceFigure([figureNo])';
        message.priorityLevel = 3;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message);
    end

%% Define default values 
    
    try %to define default values 
        if nargin < 1 %then use current figure
            figureNo = gcf;
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:Functions:enhanceFigure:defaultsException';
        message.text = 'Could not define default values. Attempting to contiune...';
        message.priorityLevel = 3;
        message.errorLevel = 'warning';
        message.exception = exception;
        logMessage(message);
    end
    
%% Set up variables for plot adjustment 

    try %to set variables 
        fontName = ('times');
        fontSize = 14;
        lineWidth = 1;
        titleFontName = fontName;
        titleFontSize = fontSize + 2;
        legendFontName = fontName;
        legendFontSize = fontSize - 2;
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:Functions:enhanceFigure:initialiseException';
        message.text = 'Cannot set up plot adjustment variables.';
        message.priorityLevel = 3;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message);
    end

%% Get plot ID data 

    try %to get plot ID data
        figureAxes = get(figureNo, 'CurrentAxes');
        xLabel = get(figureAxes, 'XLabel');
        yLabel = get(figureAxes, 'YLabel');
        figureTitle = get(figureAxes, 'Title');
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:Functions:enhanceFigure:findObjectsException';
        message.text = 'Cannot get plot ID data.';
        message.priorityLevel = 3;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message);
    end

%% Change plot settings 

    try %to change plot settings
        set(figureAxes, 'LineWidth' ,lineWidth);
        set(xLabel, 'fontname', fontName);
        set(xLabel, 'fontsize', fontSize);
        set(yLabel, 'fontname', fontName);
        set(yLabel, 'fontsize', fontSize);
        set(figureAxes, 'fontname', fontName);
        set(figureAxes, 'fontsize', fontSize);
        set(figureTitle, 'fontname', titleFontName);
        set(figureTitle, 'fontsize', titleFontSize);
        set(yLabel, 'VerticalAlignment', 'bottom');
        set(xLabel, 'VerticalAlignment', 'cap');
        set(figureTitle, 'VerticalAlignment', 'baseline');
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:Functions:enhanceFigure:runException';
        message.text = 'Cannot change plot settings. Attempting to continue...';
        message.priorityLevel = 3;
        message.errorLevel = 'warning';
        message.exception = exception;
        logMessage(message);
    end

%% Change plot settings for children, if they exist 

    try %to change child settings 
        figureChildren = get(figureAxes, 'Children');
        nChildren = length(figureChildren);
        if nChildren > 0 %then change settings 
            objectType = get(figureChildren,'Type') ;
            for j = 1:nChildren %change settings for each child object 
                try %to change settings 
                    if strcmp('text', objectType(j,:)) %then set text settings 
                        set(figureChildren(j), 'fontname', titleFontName);
                        set(figureChildren(j), 'fontsize', fontSize);
                    end
                    if strcmp('line', objectType(j,:)) %then set line settings 
                        set(figureChildren(j), 'LineWidth', lineWidth);
                    end
                catch exception
                    message = struct;
                    message.identifier = 'ModelRFQ:Functions:enhanceFigure:childException';
                    message.text = ['Cannot change plot child ' num2str(j) ' settings. Attempting to continue...'];
                    message.priorityLevel = 5;
                    message.errorLevel = 'warning';
                    message.exception = exception;
                    logMessage(message);
                end
            end
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:Functions:enhanceFigure:childrenException';
        message.text = 'Cannot change plot children settings. Attempting to continue...';
        message.priorityLevel = 3;
        message.errorLevel = 'warning';
        message.exception = exception;
        logMessage(message);
    end

%% Change legend settings 

    try %to change legend settings 
        figureLegend = legend(figureAxes);
        figureChildren = get(figureLegend, 'Children');
        nChildren = length(figureChildren);
        if nChildren > 0 %then change settings 
            objectType = get(figureChildren,'Type');
            for j = 1:nChildren %change settings for each child object 
                try %to change settings 
                    if strcmp('text',objectType(j,:)) %then change text settings 
                        set(figureChildren(j),'fontName',legendFontName);
                        set(figureChildren(j),'fontSize',legendFontSize);
                    end
                    if strcmp('line',objectType(j,:)) %then change line settings 
                        set(figureChildren(j),'LineWidth',lineWidth);
                    end
                catch exception
                    message = struct;
                    message.identifier = 'ModelRFQ:Functions:enhanceFigure:legendChildException';
                    message.text = ['Cannot change legend child ' num2str(j) ' settings. Attempting to continue...'];
                    message.priorityLevel = 3;
                    message.errorLevel = 'warning';
                    message.exception = exception;
                    logMessage(message);
                end
            end
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:Functions:enhanceFigure:legendException';
        message.text = 'Cannot change plot legend settings. Attempting to continue...';
        message.priorityLevel = 3;
        message.errorLevel = 'warning';
        message.exception = exception;
        logMessage(message);
    end
    
%% Save changes and exit 

    figure(figureNo);

return