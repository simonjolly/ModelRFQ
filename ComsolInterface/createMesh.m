function comsolModel = createMesh(comsolModel, selectionNames, nBeamBoxCells)
%
% function comsolModel = createMesh(comsolModel, selectionNames, nBeamBoxCells)
%
%   createMesh defines the solver mesh for the given Comsol model.
%
%   Credit for the majority of the modelling code must go to Simon Jolly of
%   Imperial College London.
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
%======================================================================

%% Declarations 
    
    import com.comsol.model.*
    import com.comsol.model.util.*
    
%% Check syntax 

    try %to test syntax 
        if nargin < 3 %then throw error ModelRFQ:ComsolInterface:createMesh:insufficientInputArguments 
            error('ModelRFQ:ComsolInterface:createMesh:insufficientInputArguments', ...
                  'Too few input variables: syntax is comsolModel = createMesh(comsolModel, selectionNames, nBeamBoxCells)');
        end
        if nargin > 3 %then throw error ModelRFQ:ComsolInterface:createMesh:excessiveInputArguments 
            error('ModelRFQ:ComsolInterface:createMesh:excessiveInputArguments', ...
                  'Too many input variables: syntax is comsolModel = createMesh(comsolModel, selectionNames, nBeamBoxCells)');
        end
        if nargout < 1 %then throw error ModelRFQ:ComsolInterface:createMesh:insufficientOutputArguments 
            error('ModelRFQ:ComsolInterface:createMesh:insufficientOutputArguments', ...
                  'Too few output variables: syntax is comsolModel = createMesh(comsolModel, selectionNames, nBeamBoxCells)');
        end
        if nargout > 1 %then throw error ModelRFQ:ComsolInterface:createMesh:excessiveOutputArguments 
            error('ModelRFQ:ComsolInterface:createMesh:excessiveOutputArguments', ...
                  'Too many output variables: syntax is comsolModel = createMesh(comsolModel, selectionNames, nBeamBoxCells)');
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:createMesh:syntaxException';
        message.text = 'Syntax error calling createMesh';
        message.priorityLevel = 6;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message);
    end

%% Create mesh 

    comsolModel.mesh('mesh1').feature('size').set('hauto', '5');
    comsolModel.mesh('mesh1').feature.create('ftri1', 'FreeTri');
    comsolModel.mesh('mesh1').feature('ftri1').selection.named(selectionNames.allTerminals);
    comsolModel.mesh('mesh1').feature('ftri1').feature.create('size1', 'Size');
    comsolModel.mesh('mesh1').feature('ftri1').feature('size1').set('hauto', '1');
    comsolModel.mesh('mesh1').feature('ftri1').feature('size1').selection.named(selectionNames.allTerminals);
    comsolModel.mesh('mesh1').feature('ftri1').name('Vane Surface Mesh');
    comsolModel.mesh('mesh1').run;
    comsolModel.mesh('mesh1').feature.create('map1', 'Map');
    comsolModel.mesh('mesh1').feature('map1').selection.named(selectionNames.innerBeamBoxLeadingFaces);
    comsolModel.mesh('mesh1').feature('map1').feature.create('dis1', 'Distribution');
    comsolModel.mesh('mesh1').feature('map1').feature('dis1').selection.named(selectionNames.innerBeamBoxLeadingEdges);
    comsolModel.mesh('mesh1').feature('map1').feature('dis1').set('numelem', num2str(nBeamBoxCells));
    comsolModel.mesh('mesh1').feature('map1').name('Beam Box Front Face');
    comsolModel.mesh('mesh1').run;
    comsolModel.mesh('mesh1').feature.create('swe1', 'Sweep');
    comsolModel.mesh('mesh1').feature('swe1').selection.geom('geom1', 3);
    comsolModel.mesh('mesh1').feature('swe1').selection.named(selectionNames.innerBeamBox);
    comsolModel.mesh('mesh1').feature('swe1').selection('sourceface').named(selectionNames.innerBeamBoxFrontFace);
    comsolModel.mesh('mesh1').feature('swe1').selection('targetface').named(selectionNames.innerBeamBoxRearFace);
    comsolModel.mesh('mesh1').feature('swe1').feature.create('dis1', 'Distribution');
    comsolModel.mesh('mesh1').feature('swe1').feature('dis1').selection.named(selectionNames.innerBeamBoxFront);
    comsolModel.mesh('mesh1').feature('swe1').feature('dis1').set('numelem', '16');
    comsolModel.mesh('mesh1').feature('swe1').feature.create('dis2', 'Distribution');
    comsolModel.mesh('mesh1').feature('swe1').feature('dis2').selection.named(selectionNames.innerBeamBoxMid);
    comsolModel.mesh('mesh1').feature('swe1').feature('dis2').set('numelem', '32');
    comsolModel.mesh('mesh1').feature('swe1').feature.create('dis3', 'Distribution');
    comsolModel.mesh('mesh1').feature('swe1').feature('dis3').selection.named(selectionNames.innerBeamBoxRear);
    comsolModel.mesh('mesh1').feature('swe1').feature('dis3').set('numelem', '16');
    comsolModel.mesh('mesh1').run;
    comsolModel.mesh('mesh1').feature.create('conv1', 'Convert');
    comsolModel.mesh('mesh1').feature('conv1').selection.geom('geom1', 2);
    comsolModel.mesh('mesh1').feature('conv1').selection.named(selectionNames.innerBeamBoxBoundaries);
    comsolModel.mesh('mesh1').run;
    comsolModel.mesh('mesh1').feature.create('ftet1', 'FreeTet');
    comsolModel.mesh('mesh1').feature('ftet1').selection.geom('geom1', 3);
    comsolModel.mesh('mesh1').feature('ftet1').selection.named(selectionNames.outerBeamBox);
    comsolModel.mesh('mesh1').feature('ftet1').feature.create('size1', 'Size');
    comsolModel.mesh('mesh1').feature('ftet1').feature('size1').set('hauto', '1');
    comsolModel.mesh('mesh1').feature('ftet1').feature('size1').selection.named(selectionNames.outerBeamBox);
    comsolModel.mesh('mesh1').feature('ftet1').name('Outer Beam Box Mesh');
    comsolModel.mesh('mesh1').run;
    comsolModel.mesh('mesh1').feature.create('ftet2', 'FreeTet');
    comsolModel.mesh('mesh1').feature('ftet2').selection.geom('geom1', 3);
    comsolModel.mesh('mesh1').feature('ftet2').selection.named(selectionNames.airBag);
    comsolModel.mesh('mesh1').feature('ftet2').name('Air Bag Mesh');
    comsolModel.mesh('mesh1').run;

return