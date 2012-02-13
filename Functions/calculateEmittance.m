function emittance = calculateEmittance(xData, xpData, energyData, massData, dimensionName)
%
% function emittance = calculateEmittance(xData, xpData, energyData, massData, dimensionName)
%
%   calculateEmittance calculates beam emittance and errors from X and X'
%   values.
%
%   Based on emitcalc code by Simon Jolly.
%
%   calculateEmittance(xData, xpData, energyData, massData, dimensionName) 
%     - displays the RMS normalised emittance of the beam from the 
%       specified X and X' values of each particle.  The X and X' arrays 
%       must be the same size.  The X values are assumed to be in [mm]
%       and the X' values in [mrad] - the result is therefore given 
%       in [pi mm mrad].
%     - energyData specifies the beam energy in eV.  The array can either 
%       be a single number, specifying the  mean beam energy, or an array 
%       of energies for individual particles, the same size as X and XP.
%     - massData specifies the mass of the particles in the beam in eV.  
%       The array can either be a single number, specifying the mass of 
%       all identical particles in the beam, or an array of masses for 
%       individual particles of the same size as X and XP.
%     - dimenstionName specifies whether one is inputting X or Y data. 
%       It must be a string: either 'X' or 'Y'.  This makes no difference 
%       to the calculation itself, only the results displayed.
%
%   Returns emittance which is a structure containing the following terms:
%    emittance    - the normalised RMS emittance.
%    beta, gamma  - the mean Beta and Gamma values of the beam 
%                   (relativistic, not Twiss).
%    xRms, xpRms  - the rms X and X' sizes of the beam.
%    twiss        - the Twiss parameters of the beam as a structure:
%                   twiss.beta gives BETA_X, twiss.alpha gives ALPHA_X 
%                   and twiss.gamma gives GAMMA_X. These are for the 
%                   UNNORMALISED beam.
%
%   calculateEmittance makes use of constants defined in
%   getModelParameters, so this function must be run first, and the results
%   declared as global parameters.
%
%   calculateEmittance extracts code from the function emitcalc written 
%   by Simon Jolly and released under the GNU public licence. 
%   emitcalc can handle many more input and output variables, and allows 
%   much more functionality for the calculation. 
%   calculateEmittance includes only the code required for the ModelRFQ 
%   distribution.
%
%   See also modelRfq, getModelParameters.

% File released under the GNU public license.
% Originally written by Matt Easton for ModelRFQ distribution. Functional
% code taken from emitcalc by Simon Jolly, Imperial College London.
% For information on the theory, see DIPAC'09 paper WEOA02.
%
% File history
%
%   17-May-2008 S. Jolly
%       Original version of emitcalc.
%
%   20-Dec-2010 M. J. Easton
%       Created function calculateEmittance as part of ModelRFQ
%       distribution.
%
%======================================================================

%% Declarations 

    global parameters;
    evAtomicMassUnit = ... % Atomic mass in eV
        (parameters.particle.atomicMassUnit.*(parameters.particle.lightSpeed.^2))./(parameters.particle.electronCharge);
    evElectronMass = 510998.9; % Electron mass in eV

%% Check syntax 

    try %to check syntax 
        if nargin > 5 %then throw error ModelRFQ:Functions:calculateEmittance:excessiveInputArguments 
            error('ModelRFQ:Functions:calculateEmittance:excessiveInputArguments', ...
                  'Can only specify 5 input arguments: calculateEmittance(xData, xpData, energyData, massData, dimensionName)');
        end
        if nargin < 5 %then throw error ModelRFQ:Functions:calculateEmittance:insufficientInputArguments 
            error('ModelRFQ:Functions:calculateEmittance:insufficientInputArguments', ...
                  'Must specify 5 input arguments: calculateEmittance(xData, xpData, energyData, massData, dimensionName)');
        end
        if nargout > 1 %then throw error ModelRFQ:Functions:calculateEmittance:excessiveOutputArguments 
            error('ModelRFQ:Functions:calculateEmittance:excessiveOutputArguments', ... 
                  'Can only specify 1 output argument: emittance = calculateEmittance(xData, xpData, energyData, massData, dimensionName)');
        end
        if ischar(massData) %then check value
            if ~(strcmp(massData, 'H0') || strcmp(massData, 'H-') || strcmp(massData, 'e')) %then show warning ModelRFQ:Functions:calculateEmittance:unknownMassType 
                message = struct;
                message.identifier = 'ModelRFQ:Functions:calculateEmittance:unknownMassType';
                message.text = 'Unknown mass type selected: defaulting to H- mass';
                message.priorityLevel = 3;
                message.errorLevel = 'warning';
                logMessage(message);
                massData = 'H-';
            end
        end
        if ~ischar(dimensionName) %then throw error ModelRFQ:Functions:calculateEmittance:invalidDimensionName 
            error('ModelRFQ:Functions:calculateEmittance:invalidDimensionName', ...
                  'dimensionName variable must be a string');
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:Functions:calculateEmittance:syntaxException';
        message.text = 'Syntax error calling calculateEmittance: correct syntax is emittance = calculateEmittance(xData, xpData, energyData, massData, dimensionName)';
        message.priorityLevel = 3;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message);
    end
    
%% Initialise variables 
    
    try %to initialise variables 
        x = reshape(xData,[],1);
        xp = reshape(xpData,[],1);
        if ischar(massData) %then select from H0, H- or electron mass, otherwise use data array
            switch massData
                case 'H0'
                    mass = evAtomicMassUnit;
                case 'H-'
                    mass = 1.0083736 * evAtomicMassUnit;
                case 'e'
                    mass = evElectronMass;
            end
        else
            mass = reshape(massData,[],1);
        end
        energy = reshape(energyData,[],1);              
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:Functions:calculateEmittance:initialisationException';
        message.text = 'Cannot initialise variables';
        message.priorityLevel = 3;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message);
    end
    
%% Check input arrays 
        
    try %to check length of arrays
        if length(xp) ~= length(x) %then throw error ModelRFQ:Functions:calculateEmittance:invalidXp 
            error('ModelRFQ:Functions:calculateEmittance:invalidXp', ...
                  'Input variables xData and xpData are different sizes: must contain same number of data points ie. pairs of x and xp values');
        end
        if ~(isnumeric(mass) == 1 || length(mass) == length(x)) %then throw error ModelRFQ:Functions:calculateEmittance:invalidMass 
            error('ModelRFQ:Functions:calculateEmittance:invalidMass', ...
                  'massData variable must either be single valued or the same length as xData and xpData');
        end
        if ~(isnumeric(energy) == 1 || length(energy) == length(x)) %then throw error ModelRFQ:Functions:calculateEmittance:invalidMass 
            error('ModelRFQ:Functions:calculateEmittance:invalidEnergy', ...
                  'energyData variable must either be single valued or the same length as xData and xpData');
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:Functions:calculateEmittance:checkInputArraysException';
        message.text = 'Cannot initialise variables';
        message.priorityLevel = 3;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message);
    end

%% Calculate velocities and energy spreads

    try %to calculate 
        gammaData = 1 + (energy./mass);             % Corresponding Lorentz factor Gamma []
        betaGammaData = sqrt((gammaData.^2) - 1);   % Corresponding beta-gamma factor []
        betaData = sqrt(1 - (gammaData.^-2));       % Corresponding Normalized velocity []
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:Functions:calculateEmittance:calculateSpreadsException';
        message.text = 'Cannot calculate velocities and energy spreads';
        message.priorityLevel = 3;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message);
    end

%% Calculate emittance 

    try %to calculate
        nParticles = length(x);
        xMean = sum(x)./nParticles;
        xpMean = sum(xp)./nParticles;
        x2Sum = sum(((x - xMean).^2));
        xp2Sum = sum(((xp - xpMean).^2));
        xxpSum = sum((x - xMean).*(xp - xpMean));
        x2 = x2Sum./nParticles;
        xp2 = xp2Sum./nParticles;
        xxp = xxpSum./nParticles;
        xVariance = x - xMean;
        xpVariance = xp - xpMean;
        x2Variance = (x - xMean).^2;
        xp2Variance = (xp - xpMean).^2;
        xxpVariance = xVariance.*xpVariance;
        % emittance calculation
        emittance = struct;
        emittance.normalised = 0; %placeholder for later calculation
        emittance.unnormalised = sqrt((xp2.*x2) - (xxp.^2));
        emittance.xRms = sqrt(x2);
        emittance.xpRms = sqrt(xp2);
        emittance.xWidth = max((x - xMean)) - min((x - xMean));
        emittance.xpWidth = max((xp - xpMean)) - min((xp - xpMean));
        % normalisation
        emittance.beta = mean(betaData);
        emittance.gamma = mean(gammaData);
        emittance.betagamma = mean(betaGammaData);
        emittance.normalised = (emittance.unnormalised * emittance.beta * emittance.gamma);
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:Functions:calculateEmittance:runException';
        message.text = 'Cannot calculate emittance';
        message.priorityLevel = 3;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message);
    end

%% Calculate Twiss parameters 

    try %to calculate Twiss parameters 
        emittance.twiss.beta = x2 / emittance.unnormalised;
        emittance.twiss.gamma = xp2 / emittance.unnormalised;
        emittance.twiss.alpha = -sqrt((emittance.twiss.beta * emittance.twiss.gamma) - 1);
        % Calculate covariance matrix and give Alpha the correct sign
        covariantMatrix = cov(x,xp,1);
        if covariantMatrix(2) < 0
            emittance.twiss.alpha = -emittance.twiss.alpha;
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:Functions:calculateEmittance:twissException';
        message.text = 'Cannot calculate Twiss parameters. Attempting to continue...';
        message.priorityLevel = 5;
        message.errorLevel = 'warning';
        message.exception = exception;
        logMessage(message);
    end   

%% Display all data

    try %to display data 
        text = [       '    Normalised RMS ' dimensionName ' emittance is: ' num2str(emittance.normalised,8) ' [pi mm mrad].'];
        text = [text '\n    Un-normalised RMS ' dimensionName ' emittance is: ' num2str(emittance.unnormalised,8) ' [pi mm mrad].'];
        text = [text '\n    Mean betaData-Gamma is: ' num2str(emittance.betagamma,8) '.'];
        text = [text '\n    RMS ' dimensionName ' size is: ' num2str(emittance.xRms,8) ' [mm].'];
        text = [text '\n    RMS ' dimensionName ''' size is: ' num2str(emittance.xpRms,8) ' [mrad].'];
        text = [text '\n    Total ' dimensionName ' width is: ' num2str(emittance.xWidth,8) ' [mm].'];
        text = [text '\n    Total ' dimensionName ''' width is: ' num2str(emittance.xpWidth,8) ' [mrad].'];
        text = [text '\n    Ratio of Total to RMS size (' dimensionName ') is : ' num2str((emittance.xWidth/emittance.xRms),8) '.'];
        text = [text '\n    Ratio of Total to RMS size (' dimensionName ''') is : ' num2str((emittance.xpWidth/emittance.xpRms),8) '.'];
        text = [text '\n    Courant-Snyder (Twiss) Parameters: '];
        text = [text '\n     - Alpha = ' num2str(emittance.twiss.alpha)];
        text = [text '\n     - Beta = ' num2str(emittance.twiss.beta)];
        text = [text '\n     - Gamma = ' num2str(emittance.twiss.gamma)];
        message = struct;
        message.identifier = 'ModelRFQ:Functions:calculateEmittance:displayEmittance';
        message.text = text;
        message.priorityLevel = 5;
        message.errorLevel = 'information';
        logMessage(message);
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:Functions:calculateEmittance:displayException';
        message.text = 'Cannot log emittance values. Attempting to continue...';
        message.priorityLevel = 5;
        message.errorLevel = 'warning';
        message.exception = exception;
        logMessage(message);
    end

return