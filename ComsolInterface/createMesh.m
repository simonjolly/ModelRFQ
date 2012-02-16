function [comsolModel, outputParameters] = createMesh(comsolModel, selectionNames, nBeamBoxCells, inputParameters)
%
% function [comsolModel, outputParameters] = createMesh(comsolModel, selectionNames, nBeamBoxCells, inputParameters)
%
%   CREATEMESH.M - define define solver mesh.
%
%   createMesh(comsolModel, selectionNames, nBeamBoxCells)
%   createMesh(comsolModel, selectionNames, nBeamBoxCells, inputParameters)
%
%   comsolModel = createMesh(...)
%   [comsolModel, outputParameters] = createMesh(...)
%
%   createMesh defines the solver mesh for the RFQ vane tip Comsol model.
%   An extremely fine triangular mesh is used for the vane tips, a swept
%   regular mesh for the inner beam box with converted outer faces, an
%   extremely fine tetrahedral mesh for the outer beam box and a regular
%   tetrahedral mesh for the air bag (and remainder of the model).
%
%   createMesh(comsolModel, selectionNames, nBeamBoxCells) - create solver
%   mesh for the Comsol model COMSOLMODEL.  NBEAMBOXCELLS sets the number
%   of transverse mesh elements for the square mesh on the front faces of
%   the inner beam box.  SELECTIONNAMES is a Matlab structure containing
%   strings of the names of various selections for the Comsol model:
%
%       selectionNames.allTerminals - vane tip surfaces
%       selectionNames.innerBeamBoxLeadingFaces - inner beam box leading faces
%       selectionNames.innerBeamBoxLeadingEdges - inner beam box leading edges
%       selectionNames.innerBeamBox - inner beam box (all domains)
%       selectionNames.innerBeamBoxFrontFace - inner beam box front boundary
%       selectionNames.innerBeamBoxRearFace - inner beam box rear boundary
%       selectionNames.innerBeamBoxFront - front domain of inner beam box
%       selectionNames.innerBeamBoxMid - mid domain of inner beam box
%       selectionNames.innerBeamBoxRear - rear domain of inner beam box
%       selectionNames.innerBeamBoxBoundaries - surface boundaries of inner beam box
%       selectionNames.outerBeamBox - outer beam box domain
%       selectionNames.airBag - air bag domain
%
%   createMesh(comsolModel, selectionNames, nBeamBoxCells, inputParameters)
%   - also specify parameters to be passed to logMessage for information
%   logging and display, produced by getModelParameters.
%
%   comsolModel = createMesh(...) - output the modified Comsol model
%   as the Matlab object COMSOLMODEL.
%
%   [comsolModel, outputParameters] = createMesh(...) - returns the
%   parameters from logMessage as the structure outputParameters.
%
%   See also setupModel, buildComsolModel, modelRfq, getModelParameters,
%   logMessage.

% File released under the GNU public license.
% Originally written by Matt Easton. Based on code by Simon Jolly.
%
% File history
%
%   22-Nov-2010 S. Jolly
%       Initial creation of model in Comsol and setup of electrostatic
%       physics, mesh, geometry and study.
%
%   21-Feb-2011 M. J. Easton
%       Built function createMesh from mphrfqsetup and subroutines. 
%       Included in ModelRFQ distribution.
%
%   27-May-2011 S. Jolly
%       Removed error checking (contained in wrapper functions) and
%       streamlined input variable parsing.
%
%======================================================================

%% Declarations 
    
    import com.comsol.model.*
    import com.comsol.model.util.*
    
%% Check syntax

    if nargin < 4 || isempty(inputParameters) || ~isstruct(inputParameters) %then create parameters
        parameters = struct ;
    else % store parameters
        parameters = inputParameters ;
    end

    try %to test syntax
        if nargin < 3 %then throw error ModelRFQ:ComsolInterface:createMesh:insufficientInputArguments 
            error('ModelRFQ:ComsolInterface:createMesh:insufficientInputArguments', ...
                  'Too few input variables: syntax is comsolModel = createMesh(comsolModel, selectionNames, nBeamBoxCells)');
        end
        if nargin > 4 %then throw error ModelRFQ:ComsolInterface:createMesh:excessiveInputArguments 
            error('ModelRFQ:ComsolInterface:createMesh:excessiveInputArguments', ...
                  'Too many input variables: syntax is comsolModel = createMesh(comsolModel, selectionNames, nBeamBoxCells, inputParameters)');
        end
%        if nargout < 1 %then throw error ModelRFQ:ComsolInterface:createMesh:insufficientOutputArguments 
%            error('ModelRFQ:ComsolInterface:createMesh:insufficientOutputArguments', ...
%                'Too few output variables: syntax is comsolModel = createMesh(comsolModel, selectionNames, nBeamBoxCells)');
%        end
        if nargout > 2 %then throw error ModelRFQ:ComsolInterface:createMesh:excessiveOutputArguments 
            error('ModelRFQ:ComsolInterface:createMesh:excessiveOutputArguments', ...
                  'Too many output variables: syntax is [comsolModel, outputParameters] = createMesh(comsolModel, selectionNames, nBeamBoxCells, inputParameters)');
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:createMesh:syntaxException';
        message.text = 'Syntax error calling createGeometry';
        message.priorityLevel = 6;
        message.errorLevel = 'error';
        message.exception = exception;
        parameters = logMessage(message, parameters) ;
    end

%% Create mesh 

    try % to create vane surface mesh

        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:createMesh:createVaneSurfaceMesh';
        message.text = '     --> Creating vane surface mesh...';
        message.priorityLevel = 9;
        message.errorLevel = 'information';
        parameters = logMessage(message, parameters) ;
        clear message;

        comsolModel.mesh('mesh1').feature('size').set('hauto', '5');
        comsolModel.mesh('mesh1').feature.create('ftri1', 'FreeTri');
        comsolModel.mesh('mesh1').feature('ftri1').selection.named(selectionNames.allTerminals);
        comsolModel.mesh('mesh1').feature('ftri1').feature.create('size1', 'Size');
%        comsolModel.mesh('mesh1').feature('ftri1').feature('size1').set('hauto', '2');
        comsolModel.mesh('mesh1').feature('ftri1').feature('size1').set('hauto', '1');
        comsolModel.mesh('mesh1').feature('ftri1').feature('size1').selection.named(selectionNames.allTerminals);
        comsolModel.mesh('mesh1').feature('ftri1').name('Vane Surface Mesh');
        comsolModel.mesh('mesh1').run;

    catch exception
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:ComsolInterface:createMesh:createVaneSurfaceMesh:exception';
        errorMessage.text = 'Could not create vane surface mesh';
        errorMessage.priorityLevel = 6;
        errorMessage.errorLevel = 'error';
        errorMessage.exception = exception;
        parameters = logMessage(errorMessage, parameters) ; 
    end

    try % to create inner beam box front face mesh

        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:createMesh:createInnerBeamBoxFrontFaceMesh';
        message.text = '     --> Creating inner beam box front face mesh...';
        message.priorityLevel = 10;
        message.errorLevel = 'information';
        logMessage(message, parameters) ;
        clear message;

        comsolModel.mesh('mesh1').feature.create('map1', 'Map');
        comsolModel.mesh('mesh1').feature('map1').selection.named(selectionNames.innerBeamBoxLeadingFaces);
        comsolModel.mesh('mesh1').feature('map1').feature.create('dis1', 'Distribution');
        comsolModel.mesh('mesh1').feature('map1').feature('dis1').selection.named(selectionNames.innerBeamBoxLeadingEdges);
        comsolModel.mesh('mesh1').feature('map1').feature('dis1').set('numelem', num2str(nBeamBoxCells./2));
        comsolModel.mesh('mesh1').feature('map1').name('Beam Box Front Face');
        comsolModel.mesh('mesh1').run;

    catch exception
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:ComsolInterface:createMesh:createInnerBeamBoxFrontFaceMesh:exception';
        errorMessage.text = 'Could not create inner beam box front face mesh';
        errorMessage.priorityLevel = 6;
        errorMessage.errorLevel = 'error';
        errorMessage.exception = exception;
        logMessage(errorMessage, parameters) ; 
    end

    try % to create inner beam box swept mesh

        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:createMesh:createInnerBeamBoxSweptMesh';
        message.text = '     --> Creating inner beam box swept mesh...';
        message.priorityLevel = 9;
        message.errorLevel = 'information';
        logMessage(message, parameters) ;
        clear message;

        comsolModel.mesh('mesh1').feature.create('swe1', 'Sweep');
        comsolModel.mesh('mesh1').feature('swe1').selection.geom('geom1', 3);
        comsolModel.mesh('mesh1').feature('swe1').selection.named(selectionNames.innerBeamBox);
        comsolModel.mesh('mesh1').feature('swe1').selection('sourceface').named(selectionNames.innerBeamBoxFrontFace);
        comsolModel.mesh('mesh1').feature('swe1').selection('targetface').named(selectionNames.innerBeamBoxRearFace);
        comsolModel.mesh('mesh1').feature('swe1').feature.create('dis1', 'Distribution');
        comsolModel.mesh('mesh1').feature('swe1').feature('dis1').selection.named(selectionNames.innerBeamBoxFront);
%        comsolModel.mesh('mesh1').feature('swe1').feature('dis1').set('numelem', '16');
        comsolModel.mesh('mesh1').feature('swe1').feature('dis1').set('numelem', '32');
        comsolModel.mesh('mesh1').feature('swe1').feature.create('dis2', 'Distribution');
        comsolModel.mesh('mesh1').feature('swe1').feature('dis2').selection.named(selectionNames.innerBeamBoxMid);
        comsolModel.mesh('mesh1').feature('swe1').feature('dis2').set('numelem', '32');
        comsolModel.mesh('mesh1').feature('swe1').feature.create('dis3', 'Distribution');
        comsolModel.mesh('mesh1').feature('swe1').feature('dis3').selection.named(selectionNames.innerBeamBoxRear);
%        comsolModel.mesh('mesh1').feature('swe1').feature('dis3').set('numelem', '16');
        comsolModel.mesh('mesh1').feature('swe1').feature('dis3').set('numelem', '32');
        comsolModel.mesh('mesh1').run;

    catch exception
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:ComsolInterface:createMesh:createInnerBeamBoxSweptMesh:exception';
        errorMessage.text = 'Could not create inner beam box swept mesh';
        errorMessage.priorityLevel = 6;
        errorMessage.errorLevel = 'error';
        errorMessage.exception = exception;
        logMessage(errorMessage, parameters) ; 
    end

    try % to convert inner beam box surface mesh

        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:createMesh:convertInnerBeamBoxSurfaceMesh';
        message.text = '     --> Converting inner beam box surface mesh...';
        message.priorityLevel = 10;
        message.errorLevel = 'information';
        logMessage(message, parameters) ;
        clear message;

        comsolModel.mesh('mesh1').feature.create('conv1', 'Convert');
        comsolModel.mesh('mesh1').feature('conv1').selection.geom('geom1', 2);
        comsolModel.mesh('mesh1').feature('conv1').selection.named(selectionNames.innerBeamBoxBoundaries);
        comsolModel.mesh('mesh1').run;

    catch exception
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:ComsolInterface:createMesh:convertInnerBeamBoxSurfaceMesh:exception';
        errorMessage.text = 'Could not convert inner beam box surface mesh';
        errorMessage.priorityLevel = 6;
        errorMessage.errorLevel = 'error';
        errorMessage.exception = exception;
        logMessage(errorMessage, parameters) ; 
    end

    try % to create outer beam box mesh

        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:createMesh:createOuterBeamBoxMesh';
        message.text = '     --> Creating outer beam box mesh...';
        message.priorityLevel = 9;
        message.errorLevel = 'information';
        logMessage(message, parameters) ;
        clear message;

        comsolModel.mesh('mesh1').feature.create('ftet1', 'FreeTet');
        comsolModel.mesh('mesh1').feature('ftet1').selection.geom('geom1', 3);
        comsolModel.mesh('mesh1').feature('ftet1').selection.named(selectionNames.outerBeamBox);
        comsolModel.mesh('mesh1').feature('ftet1').feature.create('size1', 'Size');
        comsolModel.mesh('mesh1').feature('ftet1').feature('size1').set('hauto', '1');
%        comsolModel.mesh('mesh1').feature('ftet1').feature('size1').set('hauto', '2');
        comsolModel.mesh('mesh1').feature('ftet1').feature('size1').selection.named(selectionNames.outerBeamBox);
        comsolModel.mesh('mesh1').feature('ftet1').name('Outer Beam Box Mesh');
        comsolModel.mesh('mesh1').run;

    catch exception
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:ComsolInterface:createMesh:createOuterBeamBoxMesh:exception';
        errorMessage.text = 'Could not create outer beam box mesh';
        errorMessage.priorityLevel = 6;
        errorMessage.errorLevel = 'error';
        errorMessage.exception = exception;
        logMessage(errorMessage, parameters) ; 
    end

    try % to create air bag mesh

        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:createMesh:createAirBagMesh';
        message.text = '     --> Creating air bag mesh...';
        message.priorityLevel = 9;
        message.errorLevel = 'information';
        logMessage(message, parameters) ;
        clear message;

        comsolModel.mesh('mesh1').feature.create('ftet2', 'FreeTet');
        comsolModel.mesh('mesh1').feature('ftet2').selection.geom('geom1', 3);
        comsolModel.mesh('mesh1').feature('ftet2').selection.named(selectionNames.airBag);
        comsolModel.mesh('mesh1').feature('ftet2').feature.create('size1', 'Size');
        comsolModel.mesh('mesh1').feature('ftet2').feature('size1').set('hauto', '5');
        comsolModel.mesh('mesh1').feature('ftet2').feature('size1').selection.named(selectionNames.airBag);
        comsolModel.mesh('mesh1').feature('ftet2').name('Air Bag Mesh');
        comsolModel.mesh('mesh1').run;

    catch exception
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:ComsolInterface:createMesh:createAirBagMesh:exception';
        errorMessage.text = 'Could not create air bag mesh';
        errorMessage.priorityLevel = 6;
        errorMessage.errorLevel = 'error';
        errorMessage.exception = exception;
        logMessage(errorMessage, parameters) ; 
    end

    outputParameters = parameters ;

    return
