function [comsolModel, selectionNames] = createGeometry(comsolModel, cadFile)
%
% function [comsolModel, selectionNames] = createGeometry(comsolModel, cadFile)
%
%   createGeometry creates the RFQ geometry in the given Comsol model from
%   the given CAD model. It returns the updated Comsol model and the names
%   of all the selection objects.
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
%       Built function createGeometry from mphrfqsetup and subroutines. 
%       Included in ModelRFQ distribution.
%
%======================================================================

%% Declarations 
    
    import com.comsol.model.*
    import com.comsol.model.util.*
    selectionNames = struct;
    
%% Check syntax 

    try %to test syntax 
        if nargin < 2 %then throw error ModelRFQ:ComsolInterface:createGeometry:insufficientInputArguments 
            error('ModelRFQ:ComsolInterface:createGeometry:insufficientInputArguments', ...
                  'Too few input variables: syntax is [comsolModel, selectionNames] = createGeometry(comsolModel, cadFile)');
        end
        if nargin > 2 %then throw error ModelRFQ:ComsolInterface:createGeometry:excessiveInputArguments 
            error('ModelRFQ:ComsolInterface:createGeometry:excessiveInputArguments', ...
                  'Too many input variables: syntax is [comsolModel, selectionNames] = createGeometry(comsolModel, cadFile)');
        end
        if nargout < 2 %then throw error ModelRFQ:ComsolInterface:createGeometry:insufficientOutputArguments 
            error('ModelRFQ:ComsolInterface:createGeometry:insufficientOutputArguments', ...
                  'Too few output variables: syntax is [comsolModel, selectionNames] = createGeometry(comsolModel, cadFile)');
        end
        if nargout > 2 %then throw error ModelRFQ:ComsolInterface:createGeometry:excessiveOutputArguments 
            error('ModelRFQ:ComsolInterface:createGeometry:excessiveOutputArguments', ...
                  'Too many output variables: syntax is [comsolModel, selectionNames] = createGeometry(comsolModel, cadFile)');
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:createGeometry:syntaxException';
        message.text = 'Syntax error calling createGeometry';
        message.priorityLevel = 6;
        message.errorLevel = 'error';
        message.exception = exception;
        logMessage(message);
    end

%% Create geometry 

    comsolModel.geom('geom1').run;
    comsolModel.geom('geom1').repairTol(1.0E-8);
    try %to notify CAD import 
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:createGeometry:startCadImport';
        message.text = ['    > Importing CAD file from ' regexprep(cadFile, '\\', '\\\\') '...'];
        message.priorityLevel = 6;
        message.errorLevel = 'information';
        logMessage(message);
        clear message;
    catch exception
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:ComsolInterface:createGeometry:startCadImport:exception';
        errorMessage.text = 'Could not notify start of section';
        errorMessage.priorityLevel = 8;
        errorMessage.errorLevel = 'warning';
        errorMessage.exception = exception;
        logMessage(errorMessage);
    end
    comsolModel.geom('geom1').feature.create('imp1', 'Import');
    comsolModel.geom('geom1').feature('imp1').set('type', 'cad');
    comsolModel.geom('geom1').feature('imp1').set('filename', cadFile);
    comsolModel.geom('geom1').feature('imp1').set('importtol', '1.0E-8');
    comsolModel.geom('geom1').feature('imp1').name('Vane CAD Import');
    comsolModel.geom('geom1').run('imp1');
    try %to notify unifying vane sections  
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:createGeometry:startUnification';
        message.text = '    > Unifying vane sections...';
        message.priorityLevel = 6;
        message.errorLevel = 'information';
        logMessage(message);
        clear message;
    catch exception
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:ComsolInterface:createGeometry:startUnification:exception';
        errorMessage.text = 'Could not notify start of section';
        errorMessage.priorityLevel = 8;
        errorMessage.errorLevel = 'warning';
        errorMessage.exception = exception;
        logMessage(errorMessage);
    end
    comsolModel.geom('geom1').feature.create('uni1', 'Union');
    comsolModel.geom('geom1').feature('uni1').selection('input').set({'imp1(1)' 'imp1(6)'});
    comsolModel.geom('geom1').feature('uni1').set('intbnd', 'off');
    comsolModel.geom('geom1').feature('uni1').set('repairtol', '1.0E-6');
    comsolModel.geom('geom1').feature.create('uni2', 'Union');
    comsolModel.geom('geom1').feature('uni2').selection('input').set({'imp1(2)' 'imp1(5)'});
    comsolModel.geom('geom1').feature('uni2').set('intbnd', 'off');
    comsolModel.geom('geom1').feature('uni2').set('repairtol', '1.0E-6');
    comsolModel.geom('geom1').feature.create('uni3', 'Union');
    comsolModel.geom('geom1').feature('uni3').selection('input').set({'imp1(3)' 'imp1(8)'});
    comsolModel.geom('geom1').feature('uni3').set('intbnd', 'off');
    comsolModel.geom('geom1').feature('uni3').set('repairtol', '1.0E-6');
    comsolModel.geom('geom1').feature.create('uni4', 'Union');
    comsolModel.geom('geom1').feature('uni4').set('intbnd', 'off');
    comsolModel.geom('geom1').feature('uni4').selection('input').set({'imp1(4)' 'imp1(7)'});
    comsolModel.geom('geom1').feature('uni4').set('repairtol', '1.0E-6');
    comsolModel.geom('geom1').run('uni1');
    comsolModel.geom('geom1').run('uni2');
    comsolModel.geom('geom1').run('uni3');
    comsolModel.geom('geom1').run('uni4');
    clear endObjectName vaneSelection;
    try %to notify selection block creation 
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:createGeometry:startSelectionBlock';
        message.text = '    > Creating selection block...';
        message.priorityLevel = 6;
        message.errorLevel = 'information';
        logMessage(message);
        clear message;
    catch exception
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:ComsolInterface:createGeometry:startSelectionBlock:exception';
        errorMessage.text = 'Could not notify start of section';
        errorMessage.priorityLevel = 8;
        errorMessage.errorLevel = 'warning';
        errorMessage.exception = exception;
        logMessage(errorMessage);
    end
    comsolModel.geom('geom1').feature.create('blk1', 'Block');
    comsolModel.geom('geom1').feature('blk1').setIndex('size', 'boxWidth', 0);
    comsolModel.geom('geom1').feature('blk1').setIndex('size', 'boxWidth', 1);
    comsolModel.geom('geom1').feature('blk1').setIndex('size', 'selectionLength', 2);
    comsolModel.geom('geom1').feature('blk1').setIndex('pos', 'selectionStart', 2);
    comsolModel.geom('geom1').feature('blk1').name('Selected Vane Block');
    comsolModel.geom('geom1').run('blk1');
    try %to notify cutting 
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:createGeometry:startCutting';
        message.text = '    > Cutting out vane section...';
        message.priorityLevel = 6;
        message.errorLevel = 'information';
        logMessage(message);
        clear message;
    catch exception
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:ComsolInterface:createGeometry:startCutting:exception';
        errorMessage.text = 'Could not notify start of section';
        errorMessage.priorityLevel = 8;
        errorMessage.errorLevel = 'warning';
        errorMessage.exception = exception;
        logMessage(errorMessage);
    end
    comsolModel.geom('geom1').feature.create('int1', 'Intersection');
    comsolModel.geom('geom1').feature('int1').selection('input').set({'blk1' 'uni1' 'uni2' 'uni3' 'uni4'});
    comsolModel.geom('geom1').feature('int1').name('Cut Out Vanes');
    comsolModel.geom('geom1').run('int1');
    try %to notify inner beam box creation 
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:createGeometry:startInnerBeamBox';
        message.text = '    > Creating inner beam box...';
        message.priorityLevel = 6;
        message.errorLevel = 'information';
        logMessage(message);
        clear message;
    catch exception
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:ComsolInterface:createGeometry:startInnerBeamBox:exception';
        errorMessage.text = 'Could not notify start of section';
        errorMessage.priorityLevel = 8;
        errorMessage.errorLevel = 'warning';
        errorMessage.exception = exception;
        logMessage(errorMessage);
    end
    comsolModel.geom('geom1').feature.create('blk2', 'Block');
    comsolModel.geom('geom1').feature('blk2').setIndex('size', 'beamBoxWidth', 0);
    comsolModel.geom('geom1').feature('blk2').setIndex('size', 'beamBoxWidth', 1);
    comsolModel.geom('geom1').feature('blk2').setIndex('size', 'selectionLength', 2);
    comsolModel.geom('geom1').feature('blk2').setIndex('pos', 'selectionStart', 2);
    comsolModel.geom('geom1').feature('blk2').name('Beam Box (Inner)');
    comsolModel.geom('geom1').run('blk2');
    comsolModel.geom('geom1').feature.create('blk3', 'Block');
    comsolModel.geom('geom1').feature('blk3').setIndex('size', 'beamBoxWidth', 0);
    comsolModel.geom('geom1').feature('blk3').setIndex('size', 'beamBoxWidth', 1);
    comsolModel.geom('geom1').feature('blk3').setIndex('size', 'cellLength', 2);
    comsolModel.geom('geom1').feature('blk3').setIndex('pos', 'cellStart', 2);
    comsolModel.geom('geom1').feature('blk3').name('Beam Box (Inner - Mid)');
    comsolModel.geom('geom1').run('blk3');
    try %to notify outer beam box creation 
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:createGeometry:startOuterBeamBox';
        message.text = '    > Creating outer beam box...';
        message.priorityLevel = 6;
        message.errorLevel = 'information';
        logMessage(message);
        clear message;
    catch exception
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:ComsolInterface:createGeometry:startOuterBeamBox:exception';
        errorMessage.text = 'Could not notify start of section';
        errorMessage.priorityLevel = 8;
        errorMessage.errorLevel = 'warning';
        errorMessage.exception = exception;
        logMessage(errorMessage);
    end
    comsolModel.geom('geom1').feature.create('blk4', 'Block');
    comsolModel.geom('geom1').feature('blk4').setIndex('size', '(2*r0)+rho', 0);
    comsolModel.geom('geom1').feature('blk4').setIndex('size', '(2*r0)+rho', 1);
    comsolModel.geom('geom1').feature('blk4').setIndex('size', 'selectionLength', 2);
    comsolModel.geom('geom1').feature('blk4').setIndex('pos', 'selectionStart', 2);
    comsolModel.geom('geom1').feature('blk4').name('Beam Box (Outer)');
    comsolModel.geom('geom1').run('blk4');
    try %to notify air bag creation 
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:createGeometry:startAirBag';
        message.text = '    > Creating air bag...';
        message.priorityLevel = 6;
        message.errorLevel = 'information';
        logMessage(message);
        clear message;
    catch exception
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:ComsolInterface:createGeometry:startAirBag:exception';
        errorMessage.text = 'Could not notify start of section';
        errorMessage.priorityLevel = 8;
        errorMessage.errorLevel = 'warning';
        errorMessage.exception = exception;
        logMessage(errorMessage);
    end
    comsolModel.geom('geom1').feature.create('blk5', 'Block');
    comsolModel.geom('geom1').feature('blk5').setIndex('size', 'boxWidth', 0);
    comsolModel.geom('geom1').feature('blk5').setIndex('size', 'boxWidth', 1);
    comsolModel.geom('geom1').feature('blk5').setIndex('size', 'selectionLength', 2);
    comsolModel.geom('geom1').feature('blk5').setIndex('pos', 'selectionStart', 2);
    comsolModel.geom('geom1').feature('blk5').name('Air Bag');
    comsolModel.geom('geom1').runAll;
    comsolModel.view('view1').set('transparency', 'on');
    comsolModel.geom('geom1').run;
    try %to notify start of section 
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:createGeometry:startSelections';
        message.text = '    > Creating selections...';
        message.priorityLevel = 6;
        message.errorLevel = 'information';
        logMessage(message);
        clear message;
    catch exception
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:ComsolInterface:createGeometry:startSelections';
        errorMessage.text = 'Could not notify start of section';
        errorMessage.priorityLevel = 8;
        errorMessage.errorLevel = 'warning';
        errorMessage.exception = exception;
        logMessage(errorMessage);
    end
    comsolModel.selection.create('sel1');
    comsolModel.selection('sel1').set([5 6 8 9]);
    comsolModel.selection('sel1').name('All Vanes');
    selectionNames.allVanes = 'sel1';
    comsolModel.selection.create('sel2');
    comsolModel.selection('sel2').set([8 9]);
    comsolModel.selection('sel2').name('Horizontal Vanes');
    selectionNames.horizontalVanes = 'sel2';
    comsolModel.selection.create('sel3');
    comsolModel.selection('sel3').set([5 6]);
    comsolModel.selection('sel3').name('Vertical Vanes');
    selectionNames.verticalVanes = 'sel3';
    comsolModel.selection.create('sel4');
    comsolModel.selection('sel4').geom('geom1', 3, 2, {'exterior'});
    comsolModel.selection('sel4').set([5 6 8 9]);
    comsolModel.selection('sel4').name('All Terminals');
    selectionNames.allTerminals = 'sel4';
    comsolModel.selection.create('sel5');
    comsolModel.selection('sel5').geom('geom1', 3, 2, {'exterior'});
    comsolModel.selection('sel5').set([8 9]);
    comsolModel.selection('sel5').name('Horizontal Terminals');
    selectionNames.horizontalTerminals = 'sel5';
    comsolModel.selection.create('sel6');
    comsolModel.selection('sel6').geom('geom1', 3, 2, {'exterior'});
    comsolModel.selection('sel6').set([5 6]);
    comsolModel.selection('sel6').name('Vertical Terminals');
    selectionNames.verticalTerminals = 'sel6';
    comsolModel.selection.create('sel7');
    comsolModel.selection('sel7').set([1 2 3 4 7]);
    comsolModel.selection('sel7').name('Air Volumes');
    selectionNames.airVolumes = 'sel7';
    comsolModel.selection.create('sel8');
    comsolModel.selection('sel8').set([1 2 3]);
    comsolModel.selection('sel8').name('Inner Beam Box');
    selectionNames.innerBeamBox = 'sel8';
    comsolModel.selection.create('sel9');
    comsolModel.selection('sel9').set(1);
    comsolModel.selection('sel9').name('Inner Beam Box (Front)');
    selectionNames.innerBeamBoxFront = 'sel9';
    comsolModel.selection.create('sel10');
    comsolModel.selection('sel10').set(2);
    comsolModel.selection('sel10').name('Inner Beam Box (Mid)');
    selectionNames.innerBeamBoxMid = 'sel10';
    comsolModel.selection.create('sel11');
    comsolModel.selection('sel11').set(3);
    comsolModel.selection('sel11').name('Inner Beam Box (Rear)');
    selectionNames.innerBeamBoxRear = 'sel11';
    comsolModel.selection.create('sel12');
    comsolModel.selection('sel12').geom('geom1', 3, 2, {'exterior'});
    comsolModel.selection('sel12').set([1 2 3]);
    comsolModel.selection('sel12').name('Inner Beam Box (Boundaries)');
    selectionNames.innerBeamBoxBoundaries = 'sel12';
    comsolModel.selection.create('sel13');
    comsolModel.selection('sel13').geom(2);
    comsolModel.selection('sel13').set(3);
    comsolModel.selection('sel13').name('Inner Beam Box (Front Face)');
    selectionNames.innerBeamBoxFrontFace = 'sel13';
    comsolModel.selection.create('sel14');
    comsolModel.selection('sel14').geom(2);
    comsolModel.selection('sel14').set(10);
    comsolModel.selection('sel14').name('Inner Beam Box (Rear Face)');
    selectionNames.innerBeamBoxRearFace = 'sel14';
    comsolModel.selection.create('sel15');
    comsolModel.selection('sel15').set(4);
    comsolModel.selection('sel15').name('Outer Beam Box');
    selectionNames.outerBeamBox = 'sel15';
    comsolModel.selection.create('sel16');
    comsolModel.selection('sel16').set(7);
    comsolModel.selection('sel16').name('Air Bag');
    selectionNames.airBag = 'sel16';
    comsolModel.selection.create('sel17');
    comsolModel.selection('sel17').geom('geom1', 3, 2, {'exterior'});
    comsolModel.selection('sel17').set(7);
    comsolModel.selection('sel17').name('Air Bag (Boundaries)');
    selectionNames.airBagBoundaries = 'sel16';
    comsolModel.selection.create('sel18');
    comsolModel.selection('sel18').geom(2);
    comsolModel.selection('sel18').geom('geom1', 2, 1, {'exterior'});
    comsolModel.selection('sel18').set(3);
    comsolModel.selection('sel18').name('Inner Beam Box (Front Edges)');
    selectionNames.innerBeamBoxFrontEdges = 'sel18';
    comsolModel.selection.create('sel19');
    comsolModel.selection('sel19').geom(2);
    comsolModel.selection('sel19').set([3 6 9]);
    comsolModel.selection('sel19').name('Inner Beam Box (Leading Faces)');
    selectionNames.innerBeamBoxLeadingFaces = 'sel19';
    comsolModel.selection.create('sel20');
    comsolModel.selection('sel20').geom(2);
    comsolModel.selection('sel20').geom('geom1', 2, 1, {'exterior'});
    comsolModel.selection('sel20').set([3 6 9]);
    comsolModel.selection('sel20').name('Inner Beam Box (Leading Edges)');
    selectionNames.innerBeamBoxLeadingEdges = 'sel20';
    comsolModel.selection.create('sel21');
    comsolModel.selection('sel21').set([1 2 3 4]);
    comsolModel.selection('sel21').name('Beam Boxes');
    selectionNames.beamBoxes = 'sel21';

return