function parameters = getModelParameters()
%
% getModelParameters sets various parameters for the model RFQ 
% function parameters = getrunparameters()
%
%   getModelParameters returns a structure containing all run parameters

% File released under the GNU public license.
% Originally written by Matt Easton.
%
% File history:
%
%   15-Dec-2010 M. J. Easton
%       Created coherent function to define model parameters.
%
%=========================================================================

%% Check input arguments 
    if nargin ~= 0 %then throw error ModelRFQ:getModelParameters:incorrectInputArguments 
        error('ModelRFQ:getModelParameters:incorrectInputArguments', ...
              'Incorrect number of input variables: syntax is parameters = getModelParameters()');
    end
    if nargout ~= 1 %then throw error ModelRFQ:getModelParameters:incorrectoutputArguments
        error('ModelRFQ:getModelParameters:incorrectoutputArguments', ...
              'Incorrect number of output variables: syntax is parameters = getModelParameters()');    
    end
    
%% Initialise parameter structure 
    parameters = struct;
    parameters.rfqType = 'FETS';
    %   parameters.rfqType determines the type of RFQ to be modelled.
    %   parameters.rfqType can be:
    %       - FETS: high-power proton RFQ for the Front-End Test Stand
    %       - PAMELA: superconducting carbon RFQ for the PAMELA FFAG
    %   Other types could be added by setting the variables correctly below.
    
%% Optional actions 
    parameters.options = struct;    
    
    % Verbosity settings to screen, to log file and to Twitter
    %  - see logMessage function for full details
    %
    % Verbosity levels:
    %    0 - no output
    %    1 - start and stop of full function
    %    2 - also start of each major section in the main modelRfq function
    %    3 - also start of major sections in subroutines
    %    4 - also more detail in modelRfq function
    %    5 - also more detail in subroutines
    %    6 - also more detail from external processes
    %    9 - also include Twitter connection errors
    %   10 - maximum detail
    parameters.options.verbosity = struct;
    parameters.options.verbosity.toScreen = 6;
    parameters.options.verbosity.toFile = 8;
    parameters.options.verbosity.toTwitter = 3;    
    
    parameters.options.shouldBuildModel = true;                    % build model in Comsol and export field map?
    parameters.options.shouldUseCadImport = true;                  % set to false to use template Comsol model instead
    parameters.options.shouldConvertFieldMaps = true;              % convert field maps to GDF?
    parameters.options.shouldRunGpt = true;                        % run GPT?
    parameters.options.shouldRunGdftrans = true;                   % run GDFTrans?
    parameters.options.shouldCalculateEmittance = true;            % calculate emittance?
    parameters.options.shouldBuildLossesFigure = true;             % build losses diagram?
    parameters.options.shouldBuildEnergyFigures = true;            % build energy diagrams?
    parameters.options.shouldBuildMovies = true;                   % build movies?
    parameters.options.shouldPause = false;                        % pause after each figure?
    
    parameters.options.shouldSaveMovies = true;                    % save movie files?
    parameters.options.shouldMakeFullLongitudinalMovie = true;     % build full longitudinal profile movie?
    parameters.options.shouldMakeBunchLongitudinalMovie = true;    % build bunch longitudinal profile movie?
    parameters.options.shouldMakeTransverseMovie = true;           % build transvers profile movie?
    parameters.options.shouldMakeXPhaseMovie = true;               % build x-phase movie?
    parameters.options.shouldMakeYPhaseMovie = true;               % build y-phase movie?
    parameters.options.shouldMakeEnergyMovie = true;               % build energy movie?
        
%% Files 
    parameters.files = struct;
    
    parameters.files.logFolder = 'Logs';
    parameters.files.resultsFolder = 'Results';
    parameters.files.cadFolder = 'CAD';
    parameters.files.comsolFolder = 'Comsol';
    parameters.files.gptFolder = 'GPT';
    parameters.files.matlabFolder = 'Matlab';
    parameters.files.resultsFolder = 'Results';
    
    folderName = regexp(pwd, filesep, 'split');
    if strcmpi(folderName(length(folderName)), parameters.files.matlabFolder) ...
            || strcmpi(folderName(length(folderName)), 'Matlab') %then need parent folder
        folderName = folderName(end-1);
    else
        folderName = folderName(end);
    end
    folderName = folderName{1};
    
    switch getComputerName() %set source locations accordingly 
        case 'heppc237'
            parameters.files.cadSourceFolder = 'D:\MJE\Dropbox\ModelRFQ\CAD\';          % location of CAD master files (include trailing filesep)
            parameters.files.comsolServer = 'C:\COMSOL41\bin\win64\comsolserver.exe';	% location of Comsol server
            parameters.files.comsolSourceFolder = 'D:\MJE\Dropbox\ModelRFQ\Comsol\';    % location of Comsol master files (include trailing filesep)
            parameters.files.gptSourceFolder = 'D:\MJE\Dropbox\ModelRFQ\GPT\';          % location of GPT master files (include trailing filesep)
        case 'chui'
            parameters.files.cadSourceFolder = '~/Dropbox/ModelRFQ/CAD/';
            parameters.files.comsolServer = '/Applications/COMSOL41/bin/comsol server';
            parameters.files.comsolSourceFolder = '~/Dropbox/ModelRFQ/Comsol/';
            parameters.files.gptSourceFolder = '~/Dropbox/ModelRFQ/GPT/';
        case 'windui'
            parameters.files.cadSourceFolder = 'C:\Users\Matt Easton\Dropbox\ModelRFQ\CAD\';
            parameters.files.comsolServer = 'C:\Program Files\Comsol 4.1\bin\win64\comsolserver.exe';
            parameters.files.comsolSourceFolder = 'C:\Users\Matt Easton\Dropbox\ModelRFQ\Comsol\';
            parameters.files.gptSourceFolder = 'C:\Users\Matt Easton\Dropbox\ModelRFQ\GPT\';
        otherwise
            parameters.files.cadSourceFolder = '.\CAD\';
            parameters.files.comsolServer = 'C:\COMSOL41\bin\comsolserver.exe';
            parameters.files.comsolSourceFolder = '.\Comsol\';
            parameters.files.gptSourceFolder = '.\GPT\';
    end
    parameters.files.comsolPort = 'default';

    if ispc %then use Inventor assembly instead of SAT file 
        parameters.files.cadFile = 'RFQFull.sat';
    else
        parameters.files.cadFile = 'RFQFull.sat';   % Inventor assemblies are only supported on Windows 
    end
    parameters.files.modulationsFile = 'RFQParameters.xls';
    parameters.files.comsolModel = 'RFQQuadrant.mph';
    parameters.files.outputFieldMapText = 'RFQFieldMap.txt';
    parameters.files.outputFieldMapMatlab = 'RFQFieldMap.mat';
    
    parameters.files.gptInputFile = 'RFQ.in';
    parameters.files.inputFieldMapText = 'RFQFieldMap.txt';                                    % name of field map text file to be read/generated
    parameters.files.inputFieldMapGdf = 'RFQFieldMap.gdf';                                     % name of field map gdf file to be read/generated
    parameters.files.gptParticleFile = 'RFQParticles.gdf';                                     % name of gpt output file to be read/generated
    parameters.files.gptTrajectoryFile = 'RFQTrajectories.gdf';                                % name of gpt output file to be read/generated
    
    parameters.files.lossesFigure = ['RFQLosses-' folderName '.jpg'];                          % name of losses diagram file
    parameters.files.energyFigure = ['RFQEnergyProfile-' folderName '.jpg'];                   % name of energy diagram file
    parameters.files.closeupEnergyFigure = ['RFQEnergyProfileCloseUp-' folderName '.jpg'];     % name of energy diagram file
    parameters.files.fullLongitudinalMovie = ['RFQFullLongitudinal-' folderName];              % name of full longitudinal movie file
    parameters.files.bunchLongitudinalMovie = ['RFQBunchLongitudinal-' folderName];            % name of bunch longitudinal movie file
    parameters.files.transverseMovie = ['RFQTransverse-' folderName];                          % name of transverse movie file
    parameters.files.xPhaseMovie = ['RFQPhaseX-' folderName];                                  % name of x phase space movie file
    parameters.files.yPhaseMovie = ['RFQPhaseY-' folderName];                                  % name of y phase space movie file
    parameters.files.energyMovie = ['RFQEnergy-' folderName];                                  % name of energy movie file

%% Particle settings 
    parameters.particle = struct;    
    
    parameters.particle.lightSpeed = 299792458;                                                        % speed of light
    parameters.particle.electronCharge = 1.602176487e-19;                                              % electron charge in C
    parameters.particle.protonMass = 1.672621637e-27;                                                  % mass of proton in kg
    parameters.particle.electronMass = 9.10938215e-31;                                                 % mass of electron in kg
    parameters.particle.atomicMassUnit = 1.660538782e-27;                                              % atomic mass unit in kg
    
    if strcmpi(parameters.rfqType, 'PAMELA') || strcmpi(parameters.rfqType, 'PAMELA6') || strcmpi(parameters.rfqType, 'FETS>PAMELA') || strcmpi(parameters.rfqType, 'FETS>PAMELA6')
        parameters.particle.nNucleons = 12;                                                            % carbon-12
        parameters.particle.eCharge = 6;                                                               % C 6+ ion
        parameters.particle.mass = (12 * parameters.particle.atomicMassUnit) ...
            - (6 * parameters.particle.electronMass);                                                  % mass of carbon ion 
        parameters.particle.sourceVoltage = 24e3;                                                      % voltage of ion source in V        
    elseif strcmpi(parameters.rfqType, 'PAMELA4') || strcmpi(parameters.rfqType, 'FETS>PAMELA4')
        parameters.particle.nNucleons = 12;                                                            % carbon-12
        parameters.particle.eCharge = 4;                                                               % C 4+ ion
        parameters.particle.mass = (12 * parameters.particle.atomicMassUnit) ...
            - (4 * parameters.particle.electronMass);                                                  % mass of carbon ion 
        parameters.particle.sourceVoltage = 24e3;                                                      % voltage of ion source in V       
    elseif strcmpi(parameters.rfqType, 'FETS')
        parameters.particle.nNucleons = 1;                                                             % single proton nucleon
        parameters.particle.eCharge = -1;                                                              % H- ion
        parameters.particle.mass = parameters.particle.protonMass ...
            + (2 * parameters.particle.electronMass);                                                  % mass of H- ion 
        parameters.particle.sourceVoltage = -65e3;                                                     % voltage of ion source in V
    end
    
    parameters.particle.energy = parameters.particle.sourceVoltage * parameters.particle.eCharge;      % beam energy from ion source in eV
    parameters.particle.energyPerNucleon = parameters.particle.energy / parameters.particle.nNucleons; % energy per nuclen in eV/u
    parameters.particle.charge = parameters.particle.eCharge * parameters.particle.electronCharge;     % convert to C
    parameters.particle.evMass = parameters.particle.mass / parameters.particle.electronCharge ...
        * parameters.particle.lightSpeed.^2;                                                           % convert to eV
    parameters.particle.gamma = 1 + (parameters.particle.energy / parameters.particle.evMass);         % Lorentzian gamma factor
    parameters.particle.beta = sqrt(1 - ( 1 / parameters.particle.gamma.^2 ) );                        % particle velocity []
    parameters.particle.velocity = parameters.particle.beta * parameters.particle.lightSpeed;          % particle velocity [m/s]
    
%% Vane settings 
    parameters.vane = struct;
    
    parameters.vane.voltage = 42500;                    % vane voltage - potential difference between vanes = vane voltage x 2
    
    parameters.vane.nExtraCells = 1;                    % how many cells to include either side of the cell being solved
    parameters.vane.shouldSaveSeparateCells = false;    % build and save cells separately for troubleshooting?
    
%% Selection names 

    parameters.defaultSelectionNames = struct;
    parameters.defaultSelectionNames.allVanes = 'sel1';
    parameters.defaultSelectionNames.horizontalVanes = 'sel2';
    parameters.defaultSelectionNames.verticalVanes = 'sel3';
    parameters.defaultSelectionNames.allTerminals = 'sel4';
    parameters.defaultSelectionNames.horizontalTerminals = 'sel5';
    parameters.defaultSelectionNames.verticalTerminals = 'sel6';
    parameters.defaultSelectionNames.airVolumes = 'sel7';
    parameters.defaultSelectionNames.innerBeamBox = 'sel8';
    parameters.defaultSelectionNames.innerBeamBoxFront = 'sel9';
    parameters.defaultSelectionNames.innerBeamBoxMid = 'sel10';
    parameters.defaultSelectionNames.innerBeamBoxRear = 'sel11';
    parameters.defaultSelectionNames.innerBeamBoxBoundaries = 'sel12';
    parameters.defaultSelectionNames.innerBeamBoxFrontFace = 'sel13';
    parameters.defaultSelectionNames.innerBeamBoxRearFace = 'sel14';
    parameters.defaultSelectionNames.outerBeamBox = 'sel15';
    parameters.defaultSelectionNames.airBag = 'sel16';
    parameters.defaultSelectionNames.airBagBoundaries = 'sel16';
    parameters.defaultSelectionNames.innerBeamBoxFrontEdges = 'sel18';
    parameters.defaultSelectionNames.innerBeamBoxLeadingFaces = 'sel19';
    parameters.defaultSelectionNames.innerBeamBoxLeadingEdges = 'sel20';
    parameters.defaultSelectionNames.beamBoxes = 'sel21';

%% Beam settings 
    parameters.beam = struct;
    
    parameters.beam.nParticles = 1000;                     % number of particles
    
    if strcmpi(parameters.rfqType, 'PAMELA') || strcmpi(parameters.rfqType, 'PAMELA6') || strcmpi(parameters.rfqType, 'FETS>PAMELA') || strcmpi(parameters.rfqType, 'FETS>PAMELA6') %then set values accordingly 
        parameters.beam.current = 1e-6;                    % beam current is 1 micro-A
        parameters.beam.frequency = 280e6;                 % rf frequency is 280 MHz
        parameters.beam.pulseLength = 3e-9;                % beam pulse length is 3 ns
    elseif strcmpi(parameters.rfqType, 'PAMELA4') || strcmpi(parameters.rfqType, 'FETS>PAMELA4')
        parameters.beam.current = 3e-4;                    % beam current is 300 micro-A
        parameters.beam.frequency = 200e6;                 % rf frequency is 200 MHz
        parameters.beam.pulseLength = 3e-9;                % beam pulse length is 3 ns
    elseif strcmpi(parameters.rfqType, 'FETS')
        parameters.beam.current = -60e-3;                  % beam current is -60 mA
        parameters.beam.frequency = 324e6;                 % rf frequency is 324 MHz
        parameters.beam.pulseLength = 3e-9;                % beam pulse length is 3 ns
    end
    
%% Tracking settings 
    parameters.tracking = struct;
    
    if strcmpi(parameters.rfqType, 'PAMELA') || strcmpi(parameters.rfqType, 'PAMELA4') || strcmpi(parameters.rfqType, 'PAMELA6')
        
        % tracking parameters
        parameters.tracking.fieldFactor = 1;                                                   % multiply field map by constant factor
        parameters.tracking.xFactor = 1;                                                       % multiply x-coordinate by constant factor
        parameters.tracking.yFactor = 1;                                                       % multiply y-coordinate by constant factor
        parameters.tracking.zFactor = 1;                                                       % multiply z-coordinate by constant factor
        parameters.tracking.simulationTime = 1e-6;                                             % simulation time [s]
        parameters.tracking.timeStepLength = 1e-9;                                             % simulation step time [s]
        parameters.tracking.screenStepLength = 0.1;                                            % screen spacing [m]
        parameters.tracking.rfqLength = 2.0326689;                                             % z-position of end of rfq (m)
        parameters.tracking.simulationLength = 2.1;                                            % z-length of simulation (m) (end of rfq to nearest 0.1m)
        parameters.tracking.nSlices = 1000;                                                    % number of time slices to include
        parameters.tracking.nScreens = parameters.tracking.simulationLength ...
            / parameters.tracking.screenStepLength;                                            % number of screens / position slices
        parameters.tracking.endScreenNo = 1;                                                   % screen at end of rfq
        
        if strcmpi(parameters.rfqType, 'PAMELA4') 
            parameters.tracking.endSliceNo = 780;                                              % slice at end of rfq 
        else           
            parameters.tracking.endSliceNo = 557;                                              % slice at end of rfq            
        end

    elseif strcmpi(parameters.rfqType, 'FETS>PAMELA') || strcmpi(parameters.rfqType, 'FETS>PAMELA4') || strcmpi(parameters.rfqType, 'FETS>PAMELA6')
        
        % fets values for scaling:
        fets = struct;
        fets.beta = 0.01176;
        fets.frequency = 324e6;
        fets.mass = parameters.particle.protonMass + (2 * parameters.particle.electronMass);
        fets.eCharge = -1;
        fets.length = 4.05793;
              
        % ratios
        ratio = struct;
        ratio.beta = parameters.particle.beta / fets.beta;
        ratio.frequency = parameters.beam.frequency / fets.frequency;
        ratio.mass = parameters.particle.mass / fets.mass;
        ratio.charge = parameters.particle.eCharge / fets.eCharge;
        ratio.length = ratio.beta / ratio.frequency;
        ratio.field = abs(ratio.charge / ratio.mass / ratio.frequency.^2);
        
        % tracking parameters
        parameters.tracking.fieldFactor = 1;%ratio.field;                                         % multiply field map by constant factor
        parameters.tracking.xFactor = 1;                                                       % multiply x-coordinate by constant factor
        parameters.tracking.yFactor = 1;                                                       % multiply y-coordinate by constant factor
        parameters.tracking.zFactor = ratio.length;                                            % multiply z-coordinate by constant factor
        parameters.tracking.simulationTime = 1e-6;                                             % simulation time [s]
        parameters.tracking.timeStepLength = 1e-9;                                             % simulation step time [s]
        parameters.tracking.screenStepLength = 0.1;                                            % screen spacing [m]
        parameters.tracking.rfqLength = fets.length * ratio.length;                            % z-position of end of rfq (m)
        parameters.tracking.simulationLength = ceil(parameters.tracking.rfqLength.*10)/10;     % z-length of simulation (m) (end of rfq to nearest 0.1m)
        parameters.tracking.nSlices = 1000;                                                    % number of time slices to include
        parameters.tracking.nScreens = parameters.tracking.simulationLength ...
            / parameters.tracking.screenStepLength;                                            % number of screens / position slices
        parameters.tracking.endScreenNo = 1;                                                   % screen at end of rfq
        
        if strcmpi(parameters.rfqType, 'FETS>PAMELA4')            
            parameters.tracking.endSliceNo = 780;    % slice at end of rfq 
        else           
            parameters.tracking.endSliceNo = 557;   % slice at end of rfq            
        end
     
    elseif strcmpi(parameters.rfqType, 'FETS')
        parameters.tracking.fieldFactor = 1;            % multiply field map by constant factor
        parameters.tracking.xFactor = 1;                % multiply x-coordinate by constant factor
        parameters.tracking.yFactor = 1;                % multiply y-coordinate by constant factor
        parameters.tracking.zFactor = 1;                % multiply z-coordinate by constant factor
        parameters.tracking.simulationTime = 5e-7;      % simulation time [s]
        parameters.tracking.timeStepLength = 1e-9;      % simulation step time [s]
        parameters.tracking.screenStepLength = 0.1;     % screen spacing [m]
        parameters.tracking.rfqLength = 4.05793;        % z-position of end of rfq (m)
        parameters.tracking.simulationLength = 4.1;     % z-length of simulation (m)
        parameters.tracking.nSlices = 500;              % number of time slices to include
        parameters.tracking.endSliceNo = 484;           % slice at end of rfq
        parameters.tracking.nScreens = 41;              % number of screens / position slices
        parameters.tracking.endScreenNo = 1;            % screen at end of rfq
    end

%% Tagging settings 
    parameters.tagging = struct;
    
    if strcmpi(parameters.rfqType, 'FETS') %then set colour ranges accordingly 
    	parameters.tagging.ranges = 0:1:parameters.tracking.rfqLength;  % length of colour range for losses diagram
    else
        parameters.tagging.ranges = 0:0.5:parameters.tracking.rfqLength;% length of colour range for losses diagram
    end
    parameters.tagging.colourLoop = ('rgbcmy');                         % colours to use
    parameters.tagging.markerLoop = ('x+*o.sd^v><ph');                   % markers to use

%% Plot settings 
    parameters.plot = struct;
    
    parameters.plot.maxMovieSize = 400; %how many frames to include in a single movie file 
    
    if strcmpi(parameters.rfqType, 'PAMELA') || strcmpi(parameters.rfqType, 'PAMELA6') || strcmpi(parameters.rfqType, 'FETS>PAMELA') || strcmpi(parameters.rfqType, 'FETS>PAMELA6')
        parameters.plot.maxEnergy = 800e3*parameters.particle.nNucleons;         % width of energy axis in energy plots
        parameters.plot.maxEnergyHistogram = 30;   % height of y axis in energy plots
        parameters.plot.framesPerSecond = 50;                  % frames per second for all movie files
        parameters.plot.minEnergy = 500e3;         % minimum energy to include for transmission [eV/u]
        parameters.plot.minGraphEnergy = 1;        % minimum energy to include for histogram [eV/u]
        parameters.plot.shouldUseTightN = true;                % use tight n axis for histogram
        parameters.plot.shouldUseTightEnergy = false;           % use tight energy axis for histogram
        parameters.plot.energyScale = 'keV';       % scale of energy for histogram
        parameters.plot.isPerNucleon = true;            % plot histogram with energy per nucleon
    elseif strcmpi(parameters.rfqType, 'PAMELA4') || strcmpi(parameters.rfqType, 'FETS>PAMELA4')
        parameters.plot.maxEnergy = 400e3*parameters.particle.nNucleons;           % width of energy axis in energy plots
        parameters.plot.maxEnergyHistogram = 30;   % height of y axis in energy plots
        parameters.plot.framesPerSecond = 50;                  % frames per second for all movie files
        parameters.plot.minEnergy = 300e3;         % minimum energy to include for transmission [eV/u]
        parameters.plot.minGraphEnergy = 1;        % minimum energy to include for histogram [eV/u]
        parameters.plot.shouldUseTightN = true;                % use tight n axis for histogram
        parameters.plot.shouldUseTightEnergy = false;           % use tight energy axis for histogram
        parameters.plot.energyScale = 'keV';       % scale of energy for histogram
        parameters.plot.isPerNucleon = true;            % plot histogram with energy per nucleon
    elseif strcmpi(parameters.rfqType, 'FETS')
        parameters.plot.maxEnergy = 4e6;             % width of energy axis in energy plots
        parameters.plot.maxEnergyHistogram = 30;   % height of y axis in energy plots
        parameters.plot.framesPerSecond = 50;                  % frames per second for all movie files
        parameters.plot.minEnergy = 2.8e6;         % minimum energy to include for transmission [eV/u]
        parameters.plot.minGraphEnergy = 1;        % minimum energy to include for histogram [eV/u]
        parameters.plot.shouldUseTightN = true;                % use tight n axis for histogram
        parameters.plot.shouldUseTightEnergy = false;           % use tight energy axis for histogram
        parameters.plot.energyScale = 'MeV';       % scale of energy for histogram
        parameters.plot.isPerNucleon = false;            % plot histogram with energy per nucleon
    end %if

return