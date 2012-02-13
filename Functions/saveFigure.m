function saveFigure(figureNo, fileName)
% function saveFigure(figureNo, fileName)
%
%   saveFigure wraps up a number of the Matlab PRINT commands to provide
%   optimum graphics export for JPEG, PDF and EPS files.  The figure
%   settings have been optimised to ensure graphics files are (relatively)
%   square and the images are centred.
%
%   Based on figsave by Simon Jolly.
%
%   saveFigure(figureNo, fileName) 
%     - export figure number figureNo to graphics file fileName.
%       The file extension of SAVENAME is used to specify the graphics
%       format of the saved file.  It can be one of the following:
%           'jpg' - export as JPEG, with 300dpi resolution and quality 
%                   level of 80.
%           'pdf' - export to colour PDF file.
%           'eps' - export to colour Level 2 encapsulated postscript with 
%                   TIFF preview.
%
%   saveFigure extracts code from the function figsave written 
%   by Simon Jolly and released under the GNU public licence. 
%   figsave can handle many more input variables, and allows 
%   much more functionality for the omage manipulation. 
%   saveFigure includes only the code required for the ModelRFQ 
%   distribution.
%
%   See also modelRfq, enhanceFigure.

% File released under the GNU public license.
% Originally written by Matt Easton for ModelRFQ distribution. Functional
% code taken from figsave by Simon Jolly of Imperial Colege London
%
% File history
%
%   20-Dec-2010 M. J. Easton
%       Created function saveFigure as part of ModelRFQ distribution.
%
%=========================================================================

%% Check syntax 

    try %to check syntax 
        if nargin ~= 2 %then throw error ModelRFQ:Functions:saveFigure:incorrectInputArguments 
            error('ModelRFQ:Functions:saveFigure:incorrectInputArguments', ...
                  'Must specify 2 input arguments: saveFigure(figureNo, fileName)');
        end
        if nargout > 0 %then throw error ModelRFQ:Functions:saveFigure:excessiveOutputArguments 
            error('ModelRFQ:Functions:saveFigure:excessiveOutputArguments', ... 
                  'saveFigure does accept output arguments: saveFigure(figureNo, fileName)');
        end
        dotLocations = find(fileName == '.');
        fileType = fileName(dotLocations(end)+1:end);
        if ~ischar(fileName) %then throw error ModelRFQ:Functions:saveFigure:invalidInputArguments 
            error('ModelRFQ:Functions:saveFigure:invalidInputArguments', ...
                  'fileName must be a string');
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:Functions:saveFigure:syntaxException';
        message.text = 'Syntax error calling enhanceFigure: correct syntax is saveFigure(figureNo, fileName)';
        message.priorityLevel = 3;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message);
    end

%% Save current paper settings 

    try %to save settings 
        originalPaperUnits = get(figureNo, 'PaperUnits');
        originalPaperSize = get(figureNo, 'PaperSize');
        originalPaperPositionMode = get(figureNo, 'PaperPositionMode');
        originalPaperPosition = get(figureNo, 'PaperPosition');
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:Functions:saveFigure:saveSettingsException';
        message.text = 'Could not save original paper settings. Attempting to continue...';
        message.priorityLevel = 5;
        message.errorLevel = 'warning';
        message.exception = exception;
        logMessage(message);
    end

%% Set figure size for saving

    try %to set new paper settings 
        set(figureNo, 'PaperPositionMode', 'auto');
        screenPaperPosition = get(figureNo,'PaperPosition');
        set(figureNo, 'PaperSize', screenPaperPosition(3:4));
        set(figureNo, 'PaperPositionMode', 'manual');
        set(figureNo, 'PaperUnits','normalized');
        set(figureNo, 'PaperPosition', [0 0 1 1]);
        set(figureNo, 'PaperUnits', 'centimeters');
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:Functions:saveFigure:settingsException';
        message.text = 'Could not apply new paper settings.';
        message.priorityLevel = 3;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message);
    end

%% Export 

    try %to export figure 
        switch fileType %save correct file type 
            case {'jpg', 'jpeg'}
                eval(['print -f' num2str(figureNo) ' -r300 -djpeg80 ' fileName ' ;']);
            case 'pdf'            
                eval(['print -f' num2str(figureNo) ' -r300 -dpdf ' fileName ' ;']);
            case 'eps'
                eval(['print -f' num2str(figureNo) ' -r300 -depsc2 ' fileName ' ;']);            
            otherwise %throw error ModelRFQ:Functions:saveFigure:invalidFileType 
                error('ModelRFQ:Functions:saveFigure:invalidFileType', ...
                      'Graphics format not recognised: must be jpg, pdf or eps') ;
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:Functions:saveFigure:exportException';
        message.text = 'Could not export figure. Attempting to continue...';
        message.priorityLevel = 3;
        message.errorLevel = 'warning';
        message.exception = exception;
        logMessage(message);
    end

%% Reset to previous paper settings 

    try %to reset paper settings
        set(figureNo, 'PaperUnits', originalPaperUnits);
        set(figureNo, 'PaperSize', originalPaperSize);
        set(figureNo, 'PaperPositionMode', originalPaperPositionMode);
        set(figureNo, 'PaperPosition', originalPaperPosition);
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:Functions:saveFigure:resetException';
        message.text = 'Could not reset paper settings. Attempting to continue...';
        message.priorityLevel = 5;
        message.errorLevel = 'warning';
        message.exception = exception;
        logMessage(message);
    end

return