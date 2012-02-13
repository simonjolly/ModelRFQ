function parameters = getModelParameters(rfqType, cadFile, modsFile, comsModFolder, comsModel, fileVerbLev, screenVerbLev, ...
    twitVerbLev, rfqFMapFile, rfqFMatFile, gptInFile, gptPartFile, logFileName, fourQuad, boxWidthMod)
%
% function parameters = getModelParameters(rfqType, cadFile, modsFile, comsModFolder, comsModel, fileVerbLev, screenVerbLev, twitVerbLev, ...
%                                       rfqFMapFile, rfqFMatFile, gptInFile, gptPartFile, logFileName, fourQuad, boxWidthMod)
%
%   GETMODELPARAMETERS.M - set various parameters for the Comsol and beam
%   dynamics RFQ model.
%
%   getModelParameters()
%   parameters = getModelParameters()
%   parameters = getModelParameters(rfqType, cadFile, modsFile, comsModFolder, comsModel, fileVerbLev, screenVerbLev, ...
%                               twitVerbLev, rfqFMapFile, rfqFMatFile, gptInFile, gptPartFile, logFileName, fourQuad, boxWidthMod)
%
%   getModelParameters returns a structure containing all run parameters
%   for modelling and running beam dynamics simulations of the FETS RFQ.
%   These parameters are used to specify many options for setting
%   filenames, beam simulations parameters and verbosity of error checking:
%   for more information, please see the code itself.
%
%   getModelParameters() - output default model parameters.
%
%   parameters = getModelParameters() - output default model parameters to
%   the variable PARAMETERS.
%
%   parameters = getModelParameters(rfqType, cadFile, modsFile, comsModFolder, comsModel, fileVerbLev, screenVerbLev, ...
%                            twitVerbLev, rfqFMapFile, rfqFMatFile, gptInFile, gptPartFile, logFileName, fourQuad, boxWidthMod)
%   - also specify certain specific parameters; these are:
%
%       rfqType = 'fets' - type of RFQ to model
%       cadFile = 'RFQFull.sat' - CAD file containing RFQ vane tip model
%       modsFile = 'RFQParameters.xls' - Excel file containing vane tip modulation parameters
%       comsModFolder = 'Comsol' - folder containing the Comsol model
%       comsModel = 'RFQQuadrant.mph - Comsol model filename
%       twitVerbLev = 3 - verbosity of messages to Twitter (see logMessage)
%       fileVerbLev = 8 - verbosity of messages saved to log file (see logMessage)
%       screenVerbLev(1) = 6 - verbosity of messages displayed on screen (see logMessage)
%       screenVerbLev(2) = 0 - controls display of plots during model creation/solving
%       rfqFMapFile = 'RFQFieldMap.txt' - text file containing RFQ field map data
%       rfqFMatFile = 'RFQFieldMap.mat' - Matlab file containing RFQ field map data
%       gptInFile = 'RFQ.in' - GPT input filename
%       gptPartFile = 'RFQParticles.gdf' - GDF data file containing input particle distribution
%       logFileName = 'ModelRFQ.log' - log filename
%       fourQuad = false - set to true to build a 4-quadrant RFQ model
%       boxWidthMod = 0 - use to adjust the size of the cutout volume of
%                         the model, normally when a vane is misaligned
%
%   It is not necessary to specify any of these parameters, so leaving a
%   certain variable as an empty matrix eg. cadFile = [], uses the default
%   value. In some circumstances the default parameter depends on the
%   particular machine in use.
%
%   Note that screenVerbLev is nominally a 2-component array, but only the
%   first value needs to be specified ie. setting screenVerbLev = [10 4]
%   sets the verbosity of messages displayed to screen to 10 and the
%   plottting display to 4, while screenVerbLev = 6 sets the verbosity of
%   messages displayed to screen to 6 and the plottting display to 0.
%
%   See also buildComsolModel, modelRfq, setupModel, logMessage.

% File released under the GNU public license.
% Originally written by Matt Easton.
%
% File history:
%
%   15-Dec-2010 M. J. Easton
%       Created coherent function to define model parameters.
%
%   25-May-2011 S. Jolly
%       Added input variables to specify multiple options.
%
%   23-Dec-2011 S. Jolly
%       Added "fourQuad" and "boxWidthMod" input options.
%
%=========================================================================

%% Check input arguments

    if nargin > 16 %then throw error ModelRFQ:getModelParameters:incorrectInputArguments 
        error('ModelRFQ:getModelParameters:excessiveInputArguments', ...
              ['Too many input variables: syntax is parameters = getModelParameters(rfqType, ' ...
              'cadFile, modsFile, comsModFolder, comsModel, twitVerbLev, fileVerbLev, screenVerbLev, ' ...
              'rfqFMapFile, rfqFMatFile, gptInFile, gptPartFile, logFileName, fourQuad, boxWidthMod, vaneOffset)']) ;
    end
    if nargout > 1 %then throw error ModelRFQ:getModelParameters:incorrectoutputArguments
        error('ModelRFQ:getModelParameters:excessiveOutputArguments', ...
              'Too many output variables: syntax is parameters = getModelParameters(...)') ;    
    end

%% Initialise parameter structure 

%    parameters.rfqType determines the type of RFQ to be modelled.
%    parameters.rfqType can be:
%        - FETS: high-power proton RFQ for the Front-End Test Stand
%        - PAMELA: superconducting carbon RFQ for the PAMELA FFAG

    parameters = struct ;
    if nargin < 1 || isempty(rfqType)
        parameters.rfqType = 'FETS' ;
    else
        parameters.rfqType = rfqType ;
    end
    
%% Optional actions

%    Verbosity settings to screen, to log file and to Twitter
%     - see logMessage function for full details
%
%    Verbosity levels:
%       0 - no output
%       1 - start and stop of full function
%       2 - also start of each major section in the main modelRfq function
%       3 - also start of major sections in subroutines
%       4 - also more detail in modelRfq function
%       5 - also more detail in subroutines
%       6 - also more detail from external processes
%       9 - also include Twitter connection errors
%      10 - maximum detail

    parameters.options = struct;    

    parameters.options.verbosity = struct;

    if nargin < 6 || isempty(fileVerbLev)
        parameters.options.verbosity.toFile = 8 ;
    else
        parameters.options.verbosity.toFile = fileVerbLev ;
    end
    if nargin < 7 || isempty(screenVerbLev)
        parameters.options.verbosity.toScreen = 6 ;
        parameters.options.verbosity.toPlots = 0 ;
    else
        parameters.options.verbosity.toScreen = screenVerbLev(1) ;
        if length(screenVerbLev) > 1
            parameters.options.verbosity.toPlots = screenVerbLev(2) ;
        else
            parameters.options.verbosity.toPlots = 0 ;
        end
    end
    if nargin < 8 || isempty(twitVerbLev)
        parameters.options.verbosity.toTwitter = 3 ;
    else
        parameters.options.verbosity.toTwitter = twitVerbLev ;
    end

    if ispc
        parameters.options.shouldUseCadImport = true ;             % set to false to use template Comsol model instead
    else
        parameters.options.shouldUseCadImport = false ;            % CAD import only works on Windows
    end
    parameters.options.shouldBuildModel = true;                    % build model in Comsol and export field map?
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
            defcadSourceFolder = 'D:\MJE\Dropbox\ModelRFQ\CAD\';          % location of CAD master files (include trailing filesep)
            defcomsolServer = 'C:\COMSOL41\bin\win64\comsolserver.exe';	  % location of Comsol server
            defcomsolSourceFolder = 'D:\MJE\Dropbox\ModelRFQ\Comsol\';    % location of Comsol master files (include trailing filesep)
            defgptSourceFolder = 'D:\MJE\Dropbox\ModelRFQ\GPT\';          % location of GPT master files (include trailing filesep)
            defcadFile = 'RFQFull.sat';
            defmodulationsFile = 'RFQParameters.xls' ;
            defcomsolModel = 'RFQQuadrant.mph' ;
            defoutputFieldMapText = 'RFQFieldMap.txt' ;
            defoutputFieldMapMatlab = 'RFQFieldMap.mat' ;
            defgptInputFile = 'RFQ.in';
            defgptParticleFile = 'RFQParticles.gdf';        % name of gpt output file to be read/generated
            defcadSourceFolder = 'D:\SJ\CADFiles\' ;
            defcomsolServer = 'C:\COMSOL41\bin\win64\comsolserver.exe';
            defcomsolSourceFolder = 'D:\SJ\Comsol\Models\' ;
            defgptSourceFolder = 'D:\SJ\gpt\rfq_cad\' ;
            defcadFile = fullfile(defcadSourceFolder, 'FETSRFQ_FullVanes+Match_SJ.iam') ;
            defmodulationsFile = fullfile(defcadSourceFolder,'RFQVaneParamsMaster.xls') ;
            if nargin > 1 && ~isempty(cadFile)
                [strcadfolder, strcadfile, strcadext] = fileparts(cadFile) ;
            else
                [strcadfolder, strcadfile, strcadext] = fileparts(defcadFile) ;
            end
            defcomsolModel = [strcadfile '.mph'] ;
            defoutputFieldMapText = fullfile(defcomsolSourceFolder, 'FETSRFQFieldMap.txt') ;
            defoutputFieldMapMatlab = fullfile(defcomsolSourceFolder, 'FETSRFQFieldMap.mat') ;
            defgptInputFile = fullfile(defgptSourceFolder, 'RFQ.in') ;
            defgptParticleFile = fullfile(defgptSourceFolder, 'RFQParticles.gdf') ;
        case 'chui'
            defcadSourceFolder = '~/Dropbox/ModelRFQ/CAD/';
            defcomsolServer = '/Applications/COMSOL41/bin/comsol server';
            defcomsolSourceFolder = '~/Dropbox/ModelRFQ/Comsol/';
            defgptSourceFolder = '~/Dropbox/ModelRFQ/GPT/';
            defcadFile = 'RFQFull.sat';
            defmodulationsFile = 'RFQParameters.xls' ;
            defcomsolModel = 'RFQQuadrant.mph' ;
            defoutputFieldMapText = 'RFQFieldMap.txt' ;
            defoutputFieldMapMatlab = 'RFQFieldMap.mat' ;
            defgptInputFile = 'RFQ.in';
            defgptParticleFile = 'RFQParticles.gdf';
        case 'windui'
            defcadSourceFolder = 'C:\Users\Matt Easton\Dropbox\ModelRFQ\CAD\';
            defcomsolServer = 'C:\Program Files\Comsol 4.1\bin\win64\comsolserver.exe';
            defcomsolSourceFolder = 'C:\Users\Matt Easton\Dropbox\ModelRFQ\Comsol\';
            defgptSourceFolder = 'C:\Users\Matt Easton\Dropbox\ModelRFQ\GPT\';
            defcadFile = 'RFQFull.sat';
            defmodulationsFile = 'RFQParameters.xls' ;
            defcomsolModel = 'RFQQuadrant.mph' ;
            defoutputFieldMapText = 'RFQFieldMap.txt' ;
            defoutputFieldMapMatlab = 'RFQFieldMap.mat' ;
            defgptInputFile = 'RFQ.in';
            defgptParticleFile = 'RFQParticles.gdf';
        case 'heppc53' %,'dyn1205-11'}
            if ispc
                if exist('Z:\Comsol','dir')
                    driveletter = 'Z:' ;
                else
                    driveletter = 'D:' ;
                end
                defcadSourceFolder = 'C:\CADFiles\' ;
                defcomsolServer = 'C:\COMSOL41\bin\win32\comsolserver.exe' ;
                defcomsolSourceFolder = [driveletter '\Comsol\Models\'] ;
                defgptSourceFolder = [driveletter '\gpt\rfq_comsol\'] ;
            elseif ismac
                defcadSourceFolder = '/Volumes/WINDOWS/CADFiles/';
                defcomsolServer = '/Applications/COMSOL41/bin/maci64/comsol server';
                defcomsolSourceFolder = '/Volumes/FATSWAP/Comsol/Models/';
                defgptSourceFolder = '/Volumes/FATSWAP/gpt/rfq_comsol/';
            end
            defcadFile = fullfile(defcadSourceFolder, 'FETSRFQ_FullVanes+Match_SJ.iam') ;
            defmodulationsFile = fullfile(defcadSourceFolder,'RFQVaneParamsMaster.xls') ;
%            defcomsolModel = fullfile(defcomsolSourceFolder, 'FETSRFQQuadModel.mph') ;
%            defcomsolModel = 'FETSRFQQuadModel.mph' ;
            if nargin > 1 && ~isempty(cadFile)
                [strcadfolder, strcadfile] = fileparts(cadFile) ;
            else
                [strcadfolder, strcadfile] = fileparts(defcadFile) ;
            end
            defcomsolModel = [strcadfile '.mph'] ;
            defoutputFieldMapText = fullfile(defcomsolSourceFolder, 'FETSRFQFieldMap.txt') ;
            defoutputFieldMapMatlab = fullfile(defcomsolSourceFolder, 'FETSRFQFieldMap.mat') ;
            defgptInputFile = fullfile(defgptSourceFolder, 'RFQ.in') ;
            defgptParticleFile = fullfile(defgptSourceFolder, 'RFQParticles.gdf') ;
        case 'heppc222'
            if ispc
                if exist('Y:\CADFiles','dir')
                    driveletter = 'Y:' ;
                    driveletterz = 'Z:' ;
                else
                    driveletter = 'D:' ;
                    driveletterz = 'D:' ;
                end
                defcadSourceFolder = [driveletter '\CADFiles\'] ;
                defcomsolServer = 'C:\COMSOL41\bin\win64\comsolserver.exe';
                defcomsolSourceFolder = [driveletterz '\Comsol\Models\'] ;
                defgptSourceFolder = [driveletter '\gpt\rfq_comsol\'] ;
            elseif ismac
                defcadSourceFolder = '/Volumes/WINDATA/CADFiles/';
                defcomsolServer = '/Applications/COMSOL41/bin/maci64/comsol server';
                defcomsolSourceFolder = '/Volumes/FATSWAP/Comsol/Models/';
                defgptSourceFolder = '/Volumes/FATSWAP/gpt/rfq_comsol/';
            end
            defcadFile = fullfile(defcadSourceFolder, 'FETSRFQ_FullVanes+Match_SJ.iam') ;
            defmodulationsFile = fullfile(defcadSourceFolder,'RFQVaneParamsMaster.xls') ;
%            defcomsolModel = fullfile(defcomsolSourceFolder, 'FETSRFQQuadModel.mph') ;
%            defcomsolModel = 'FETSRFQQuadModel.mph' ;
            if nargin > 1 && ~isempty(cadFile)
                [strcadfolder, strcadfile, strcadext] = fileparts(cadFile) ;
            else
                [strcadfolder, strcadfile, strcadext] = fileparts(defcadFile) ;
            end
            defcomsolModel = [strcadfile '.mph'] ;
            defoutputFieldMapText = fullfile(defcomsolSourceFolder, 'FETSRFQFieldMap.txt') ;
            defoutputFieldMapMatlab = fullfile(defcomsolSourceFolder, 'FETSRFQFieldMap.mat') ;
            defgptInputFile = fullfile(defgptSourceFolder, 'RFQ.in') ;
            defgptParticleFile = fullfile(defgptSourceFolder, 'RFQParticles.gdf') ;
        otherwise
            if ispc
                defcomsolServer = 'C:\COMSOL41\bin\win32\comsolserver.exe';
            elseif ismac
                defcomsolServer = '/Applications/COMSOL41/bin/comsol server';
            end
            defcadSourceFolder = '.\CAD\';
            defcomsolSourceFolder = '.\Comsol\';
            defgptSourceFolder = '.\GPT\';
            defcadFile = 'RFQFull.sat';
            defmodulationsFile = 'RFQParameters.xls' ;
            defcomsolModel = 'RFQQuadrant.mph' ;
            defoutputFieldMapText = 'RFQFieldMap.txt' ;
            defoutputFieldMapMatlab = 'RFQFieldMap.mat' ;
            defgptInputFile = 'RFQ.in';
            defgptParticleFile = 'RFQParticles.gdf';
    end

    if nargin < 4 || isempty(comsModFolder)
        parameters.files.comsolSourceFolder = defcomsolSourceFolder ;
    else
        parameters.files.comsolSourceFolder = comsModFolder ;
    end

    if nargin < 13 || isempty(logFileName)
        parameters.files.logFileName = fullfile(parameters.files.comsolSourceFolder, 'ModelRFQ.log') ;
    else
        parameters.files.logFileName = logFileName ;
    end

    parameters.files.cadSourceFolder = defcadSourceFolder ;
    parameters.files.comsolServer = defcomsolServer;
    parameters.files.gptSourceFolder = defgptSourceFolder ;

    parameters.files.comsolPort = 'default';

    if nargin < 2 || isempty(cadFile)
        if ispc %then use Inventor assembly instead of SAT file 
            parameters.files.cadFile = defcadFile ;
        else
            parameters.files.cadFile = defcadFile ;     % Inventor assemblies are only supported on Windows 
        end
    else
        parameters.files.cadFile = fullfile(parameters.files.cadSourceFolder, cadFile) ;
    end
    if nargin < 3 || isempty(modsFile)
        parameters.files.modulationsFile = defmodulationsFile ;
    else
        parameters.files.modulationsFile = modsFile ;
    end
    if nargin < 5 || isempty(comsModel)
        parameters.files.comsolModel = defcomsolModel ;
    else
        parameters.files.comsolModel = comsModel ;
    end
    if nargin < 9 || isempty(rfqFMapFile)
        parameters.files.outputFieldMapText = defoutputFieldMapText ;
    else
        parameters.files.outputFieldMapText = rfqFMapFile ;
    end
    if nargin < 10 || isempty(rfqFMatFile)
        parameters.files.outputFieldMapMatlab = defoutputFieldMapMatlab ;
    else
        parameters.files.outputFieldMapMatlab = rfqFMatFile ;
    end
    if nargin < 11 || isempty(gptInFile)
        parameters.files.gptInputFile = defgptInputFile ;
    else
        parameters.files.gptInputFile = gptInFile ;
    end
    if nargin < 12 || isempty(gptPartFile)
        parameters.files.gptParticleFile = defgptParticleFile ;                                 % name of gpt output file to be read/generated
    else
        parameters.files.gptParticleFile = gptPartFile ;
    end

%    parameters.files.inputFieldMapText = 'RFQFieldMap.txt';                                    % name of field map text file to be read/generated
    parameters.files.inputFieldMapText = parameters.files.outputFieldMapText ;
    parameters.files.inputFieldMapGdf = 'RFQFieldMap.gdf';                                     % name of field map gdf file to be read/generated
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

    parameters.particle = struct ;    
    
    parameters.particle.lightSpeed = 299792458;                                                        % speed of light
    parameters.particle.electronCharge = 1.602176487e-19;                                              % electron charge in C
    parameters.particle.protonMass = 1.672621637e-27;                                                  % mass of proton in kg
    parameters.particle.electronMass = 9.10938215e-31;                                                 % mass of electron in kg
    parameters.particle.atomicMassUnit = 1.660538782e-27;                                              % atomic mass unit in kg
    
    if strcmpi(parameters.rfqType, 'PAMELA') || strcmpi(parameters.rfqType, 'PAMELA6') ...
            || strcmpi(parameters.rfqType, 'FETS>PAMELA') || strcmpi(parameters.rfqType, 'FETS>PAMELA6')
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

    if nargin < 14 || isempty(fourQuad)
        fourQuad = false ;
    end
        
    parameters.vane = struct;
    
    parameters.vane.voltage = 42500;                    % vane voltage - potential difference between vanes = vane voltage x 2
    
    parameters.vane.nExtraCells = 1;                    % how many cells to include either side of the cell being solved
    parameters.vane.shouldSaveSeparateCells = false;    % build and save cells separately for troubleshooting?
    parameters.vane.fourQuad = fourQuad ;               % build a 4-quadrant model?

    if nargin < 15 || isempty(boxWidthMod)
        parameters.vane.boxWidthMod = [] ;
    else
        parameters.vane.boxWidthMod = boxWidthMod ;
    end

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
    parameters.defaultSelectionNames.airBagBoundaries = 'sel17';
    parameters.defaultSelectionNames.innerBeamBoxFrontEdges = 'sel18';
    parameters.defaultSelectionNames.innerBeamBoxLeadingFaces = 'sel19';
    parameters.defaultSelectionNames.innerBeamBoxLeadingEdges = 'sel20';
    parameters.defaultSelectionNames.beamBoxes = 'sel21';
    parameters.defaultSelectionNames.endFlangeGrounded = 'sel22';

%% Beam settings

    parameters.beam = struct;
    
    parameters.beam.nParticles = 10000;                     % number of particles
    
    if strcmpi(parameters.rfqType, 'PAMELA') || strcmpi(parameters.rfqType, 'PAMELA6') ...
            || strcmpi(parameters.rfqType, 'FETS>PAMELA') || strcmpi(parameters.rfqType, 'FETS>PAMELA6') %then set values accordingly 
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
    
    if strcmpi(parameters.rfqType, 'PAMELA') || strcmpi(parameters.rfqType, 'PAMELA6') ...
            || strcmpi(parameters.rfqType, 'FETS>PAMELA') || strcmpi(parameters.rfqType, 'FETS>PAMELA6')
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
