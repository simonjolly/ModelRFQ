function plotEnergies(energyFigureNo, energyData, minEnergy, maxEnergy)
%
% function plotEnergies(energyFigureNo, energyData, [minEnergy], [maxEnergy])
%
%   plotEnergies plots a histogram of the output energy of particles from 
%   an RFQ modelled by ModelRFQ.
%
%   energyFigureNo is the figure to work on.
%   energyData is the array of energies to be plotted.
%   minEnergy and maxEnergy are the minimum and maximum of the energy axis.
%   If omitted, a tight axis is used.
%
%   potEnergies also makes use of the parameters global variable, which
%   contains plot options and particle data. This is defined by
%   getModelParameters and called by modelRfq.
%
%   See also modelRfq, getModelParameters, enhanceFigure, saveFigure,
%   plotTrajectories.

% File released under the GNU public license.
% Originally written by Matt Easton for ModelRFQ distribution.
%
% File history
%
%   20-Dec-2010 M. J. Easton
%       Created function plotEnergies as part of ModelRFQ distribution
%
%=========================================================================

%% Declarations 

    global parameters
    
%% Check syntax 

    try %to check syntax 
        if nargin > 4 %then throw error ModelRFQ:Functions:plotEnergies:excessiveInputArguments 
            error('ModelRFQ:Functions:plotEnergies:excessiveInputArguments', ...
                  'Can only specify 4 input arguments: plotEnergies(energyFigureNo, energyData, [minEnergy], [maxEnergy])');
        end
        if nargin < 2 %then throw error ModelRFQ:Functions:plotEnergies:insufficientInputArguments 
            error('ModelRFQ:Functions:plotEnergies:insufficientInputArguments', ...
                  'Must specify at least 2 input arguments: plotEnergies(energyFigureNo, energyData, [minEnergy], [maxEnergy])');
        end
        if nargout > 0 %then throw error ModelRFQ:Functions:plotEnergies:excessiveOutputArguments 
            error('ModelRFQ:Functions:plotEnergies:excessiveOutputArguments', ... 
                  'plotEnergies does accept output arguments: plotEnergies(energyFigureNo, energyData, [minEnergy], [maxEnergy])');
        end
        % energy limits 
        if nargin == 4 %then limit the energy exis as requested 
            shouldLimitEnergyAxis = true;
        end
        if nargin == 3 %then warn that minimum will be ignored 
            shouldLimitEnergyAxis = false;
            message = struct;
            message.identifier = 'ModelRFQ:Functions:plotEnergies:missingMaxEnergy';
            message.text = 'minEnergy specified without maxEnergy: ignoring value';
            message.priorityLevel = 5;
            message.errorLevel = 'warning';
            logMessage(message);
        end
        if nargin == 2 %then don't constrain the energy axis 
            shouldLimitEnergyAxis = false;
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:Functions:plotEnergies:syntaxException';
        message.text = 'Syntax error calling plotTrajectories: correct syntax is plotEnergies(energyFigureNo, energyData, [minEnergy], [maxEnergy])';
        message.priorityLevel = 3;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message);
    end

%% Plot figure 

    try %to plot figure 
        figure(energyFigureNo), hold off;
        set(energyFigureNo, 'color', 'white');
        set(energyFigureNo, 'Position', [50 50 600 600]);
        figure(energyFigureNo), hold on;
        % define energy axis from model parameters
        energyFactor = 1;
        xLabel = 'E (';
        if strcmpi(parameters.plot.energyScale,'keV') %then use keV instead of MeV 
            energyFactor = energyFactor * 1e-3;
            xLabel = [xLabel 'keV'];
        else % default MeV
            energyFactor = energyFactor * 1e-6;
            xLabel = [xLabel 'MeV'];
        end
        if parameters.plot.isPerNucleon %then make per nucleon calculation 
            energyFactor = energyFactor/parameters.particle.nNucleons;
            xLabel = [xLabel '/u'];
        end
        xLabel = [xLabel ')'];
        hist(energyData.*energyFactor, 100);
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:Functions:plotEnergies:runException';
        message.text = 'Could not create energy histogram';
        message.priorityLevel = 3;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message);
    end
    
%% Set axes and labels 

    try %to change plot settings 
        axis tight;
        if shouldLimitEnergyAxis %then limit energy axis 
            xlim([minEnergy*energyFactor maxEnergy*energyFactor]);
        end
        if ~parameters.plot.shouldUseTightN %then limt y-axis 
            ylim([0 parameters.plot.maxEnergyHistogram]);
        end
        xlabel(xLabel);
        ylabel('n');
        title('\bf RFQ Energy Profile');
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:Functions:plotEnergies:settingsException';
        message.text = 'Could not adjust settings for energy histogram. Attempting to continue...';
        message.priorityLevel = 3;
        message.errorLevel = 'warning';
        message.exception = exception;
        logMessage(message);
    end
        
%% Clean up 
    
    try
        enhanceFigure(energyFigureNo);
        hold off;
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:Functions:plotEnergies:cleanupException';
        message.text = 'Could not clean up energy histogram. Attempting to continue...';
        message.priorityLevel = 5;
        message.errorLevel = 'warning';
        message.exception = exception;
        logMessage(message);
    end
            
return