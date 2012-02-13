function plotTrajectories(timeData, trajectoryData, colours, ...
                          endSliceNo, subplotSliceNo, zStart, zEnd)
%
% function plotTrajectories(timeData, trajectoryData, colours, ...
%                           endSliceNo, subplotSliceNo, zStart, zEnd)
%
%   plotTrajectories plots the trajectories of particles through an RFQ
%   modelled by ModelRFQ.
%
%   Based on gpttraj4plot code by Simon Jolly.
%
%   timeData is the array of particle data split into time slices.
%   trajectoryData is the array of particle data split into particle
%   entities.
%   colours is an array of colours for each particle, produced by the
%   tagLosses and tagColours functions.
%   endSliceNo is the slice in timeData in which the bunch particles reach
%   the end of the RFQ. The main plot is plotted from time 0 to endSliceNo.
%   subplotSliceNo is the slice in timeData for which the subplots will be
%   plotted. These subplots show lost particles in real and phase space.
%
%   plotTrajectories extracts code from the function gpttraj4plot written 
%   by Simon Jolly and released under the GNU public licence. 
%   gpttraj4plot can handle more input and output variables, and allows 
%   much more functionality for the calculation. 
%   gpttraj4plot includes only the code required for the ModelRFQ 
%   distribution.
%
%   See also modelRfq, tagLosses, tagColours, enhanceFigure, saveFigure.

% File released under the GNU public license.
% Originally written by Matt Easton for ModelRFQ distribution. Functional
% code taken from gpttraj4plot by Simon Jolly of Imperial Colege London
%
% File history
%
%   20-Dec-2010 M. J. Easton
%       Created function plotTrajectories as part of ModelRFQ
%       distribution
%
%=========================================================================

%% Check syntax 

    try %to check syntax 
        if nargin > 7 %then throw error ModelRFQ:Functions:plotTrajectories:excessiveInputArguments 
            error('ModelRFQ:Functions:plotTrajectories:excessiveInputArguments', ...
                  'Can only specify 7 input arguments: plotTrajectories(timeData, trajectoryData, [colours], [endSliceNo], [subplotSliceNo], [zStart], [zEnd])');
        end
        if nargin < 2 %then throw error ModelRFQ:Functions:plotTrajectories:insufficientInputArguments 
            error('ModelRFQ:Functions:plotTrajectories:insufficientInputArguments', ...
                  'Must specify at least 2 input arguments: plotTrajectories(timeData, trajectoryData, [colours], [endSliceNo], [subplotSliceNo], [zStart], [zEnd])');
        end
        if nargout > 0 %then throw error ModelRFQ:Functions:plotTrajectories:excessiveOutputArguments 
            error('ModelRFQ:Functions:plotTrajectories:excessiveOutputArguments', ... 
                  'plotTrajectories does accept output arguments: plotTrajectories(timeData, trajectoryData, [colours], [endSliceNo], [subplotSliceNo], [zStart], [zEnd])');
        end        
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:Functions:plotTrajectories:syntaxException';
        message.text = 'Syntax error calling plotTrajectories: correct syntax is plotTrajectories(timeData, trajectoryData, [colours], [endSliceNo], [subplotSliceNo], [zStart], [zEnd])';
        message.priorityLevel = 3;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message);
    end

%% Define default values
    
    try %to define default values 
        nParticles = length(trajectoryData) ;
        if nargin < 6 || (isempty(zStart) && isempty(zEnd)) %then don't limit z axis 
            shouldLimitZ = false;
        else
            shouldLimitZ = true;
        end
        if nargin < 5 || isempty(subplotSliceNo) %then default to start slice 
            subplotSliceNo = 1;
        end
        if nargin < 4 || isempty(endSliceNo) %then default to start slice 
            endSliceNo = 1 ;
        end
        if nargin < 3 || isempty(colours) %then
            for i = 1:nParticles
                colours(i,:) = '.k-';
            end
        elseif size(colours,1) == 1
            colour = colours;
            for i = 1:nParticles
                colours(i,:) = colour;
            end
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:Functions:plotTrajectories:defaultsException';
        message.text = 'Could not define default values. Attempting to contiune...';
        message.priorityLevel = 3;
        message.errorLevel = 'warning';
        message.exception = exception;
        logMessage(message);
    end

%% Find particles 
        
    try %to find particles
        endSlice = timeData(endSliceNo) ;
        subplotSlice = timeData(subplotSliceNo) ;
        survivingParticles = [endSlice.ID] ;
        nSurvivingParticles = length(survivingParticles) ;
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:Functions:plotTrajectories:findParticlesException';
        message.text = 'Could not find particles for plotting.';
        message.priorityLevel = 3;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message);
    end

%% Main figure 

    try %to plot trajectories 
        subplot(2,3,1:3), hold on;
        xlabel('z (m)');
        ylabel('y (mm)');
        if shouldLimitZ %then limit z axis 
            xlim([zStart zEnd]);
        end
        for i = 1:nParticles % plot each particle 
            currentParticle = find(survivingParticles == i, 1);
            if ~isempty(currentParticle) %then particle survived 
                zData = trajectoryData(i).z(1:endSliceNo);
                yData = trajectoryData(i).y(1:endSliceNo);
            else
                zData = trajectoryData(i).z(1:end);
                yData = trajectoryData(i).y(1:end);
            end
            plot(zData,      yData.*1e3,      colours(i,2:3));
            plot(zData(end), yData(end).*1e3, colours(i,1:2), 'MarkerSize',2);
        end
        hold off;
        enhanceFigure;
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:Functions:plotTrajectories:mainPlotException';
        message.text = 'Could not plot trajectories. Attempting to continue...';
        message.priorityLevel = 3;
        message.errorLevel = 'warning';
        message.exception = exception;
        logMessage(message);
    end
    
%% Subfigures 

    try %to plot real space distribution 
        subplot(2,3,4), hold on ;
        xlabel('x (mm)');
        ylabel('y (mm)');
        for i = 1:nSurvivingParticles %add each particle to plot 
            plot(subplotSlice.x(i).*1e3, subplotSlice.y(i).*1e3, colours(survivingParticles(i),1:2), 'MarkerSize',2);
        end
        hold off;
        axis square;
        enhanceFigure;
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:Functions:plotTrajectories:realSpaceException';
        message.text = 'Could not plot real space distribution. Attempting to continue...';
        message.priorityLevel = 3;
        message.errorLevel = 'warning';
        message.exception = exception;
        logMessage(message);
    end

	try %to plot x phase space distribution 
        subplot(2,3,5), hold on;
        xlabel('x (mm)');
        ylabel('x'' (mrad)');
        for i = 1:nSurvivingParticles %add each particle to plot 
            plot(subplotSlice.x(i).*1e3, subplotSlice.xp(i).*1e3, colours(survivingParticles(i),1:2), 'MarkerSize',2);
        end
        hold off;
        axis square;
        enhanceFigure;
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:Functions:plotTrajectories:xPhaseException';
        message.text = 'Could not plot x phase space distribution. Attempting to continue...';
        message.priorityLevel = 3;
        message.errorLevel = 'warning';
        message.exception = exception;
        logMessage(message);
	end

	try %to plot y phase space distribution 
        subplot(2,3,6), hold on;
        xlabel('y (mm)');
        ylabel('y'' (mrad)') ;
        for i = 1:nSurvivingParticles %add each particle to plot 
            plot(subplotSlice.y(i).*1e3, subplotSlice.yp(i).*1e3, colours(survivingParticles(i),1:2), 'MarkerSize',2);
        end
        hold off;
        axis square;
        enhanceFigure;
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:Functions:plotTrajectories:yPhaseException';
        message.text = 'Could not plot y phase space distribution. Attempting to continue...';
        message.priorityLevel = 3;
        message.errorLevel = 'warning';
        message.exception = exception;
        logMessage(message);
	end

return