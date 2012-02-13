function [comsolModel, selectionNames, vaneBoundBoxes, modelBoundBox, outputParameters] = ...
    createGeometry(comsolModel, cadFile, fourQuad, inputParameters)
%
% function [comsolModel, selectionNames, vaneBoundBoxes, modelBoundBox, outputParameters] = 
%    createGeometry(comsolModel, cadFile, fourQuad, inputParameters)
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
%   11-May-2011 S. Jolly
%       Automated finding CAD objects for vane Union commands to allow for
%       more complex vane models (including half cells and end plates).
%       Modified error checking to provide better feedback for each
%       section.
%
%   21-Nov-2011 S. Jolly
%       Added fourQuad variable to create 4-quadrant model.
%
%======================================================================

%% Declarations 
    
    import com.comsol.model.*
    import com.comsol.model.util.*
    selectionNames = struct;
    
%% Check syntax 

    if nargin < 4 || isempty(inputParameters) || ~isstruct(inputParameters) %then create parameters
        parameters = struct ;
    else % store parameters
        parameters = inputParameters ;
    end
    if nargin < 3 || isempty(fourQuad)
        fourQuad = false ;
    end

    try %to test syntax 
        if nargin < 2 %then throw error ModelRFQ:ComsolInterface:createGeometry:insufficientInputArguments 
            error('ModelRFQ:ComsolInterface:createGeometry:insufficientInputArguments', ...
                  'Too few input variables: syntax is createGeometry(comsolModel, cadFile)');
        end
        if nargin > 4 %then throw error ModelRFQ:ComsolInterface:createGeometry:excessiveInputArguments 
            error('ModelRFQ:ComsolInterface:createGeometry:excessiveInputArguments', ...
                  'Too many input variables: syntax is createGeometry(comsolModel, cadFile, fourQuad, inputParameters)');
        end
%        if nargout < 2 %then throw error ModelRFQ:ComsolInterface:createGeometry:insufficientOutputArguments 
%            error('ModelRFQ:ComsolInterface:createGeometry:insufficientOutputArguments', ...
%                  'Too few output variables: syntax is [comsolModel, selectionNames] = createGeometry(comsolModel, cadFile)');
%        end
        if nargout > 5 %then throw error ModelRFQ:ComsolInterface:createGeometry:excessiveOutputArguments 
            error('ModelRFQ:ComsolInterface:createGeometry:excessiveOutputArguments', ...
                  ['Too many output variables: syntax is [comsolModel, selectionNames, vaneBoundBoxes, modelBoundBox, outputParameters]' ...
                  '= createGeometry(comsolModel, cadFile)']) ;
        end
    catch exception
        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:createGeometry:syntaxException';
        message.text = 'Syntax error calling createGeometry';
        message.priorityLevel = 6;
        message.errorLevel = 'error';
        message.exception = exception;
        parameters = logMessage(message, parameters) ;
    end

%% Create geometry

    comsolModel.geom('geom1').run;
    comsolModel.geom('geom1').repairTol(1.0E-8);

    try % to import CAD files

        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:createGeometry:startCadImport';
        message.text = ['    > Importing CAD file from ' regexprep(cadFile, '\\', '\\\\') '...'];
        message.priorityLevel = 6;
        message.errorLevel = 'information';
        parameters = logMessage(message, parameters) ;
        clear message;

        comsolModel.geom('geom1').feature.create('imp1', 'Import');
        comsolModel.geom('geom1').feature('imp1').set('type', 'cad');
        comsolModel.geom('geom1').feature('imp1').set('filename', cadFile);
        comsolModel.geom('geom1').feature('imp1').set('importtol', '1.0E-8');
        comsolModel.geom('geom1').feature('imp1').name('Vane CAD Import');
        comsolModel.geom('geom1').run('imp1');

    catch exception
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:ComsolInterface:createGeometry:startCadImport:exception';
        errorMessage.text = 'Could not notify start of section';
        errorMessage.priorityLevel = 6; 
        errorMessage.errorLevel = 'error';
        errorMessage.exception = exception;
        parameters = logMessage(errorMessage, parameters) ; 
    end

    try % to unify vane sections

        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:createGeometry:vaneUnification';
        message.text = '     --> Unifying vane sections...';
        message.priorityLevel = 9;
        message.errorLevel = 'information';
        logMessage(message, parameters) ;
        clear message;

        cadimpnames = comsolModel.geom('geom1').feature('imp1').objectNames ;
        topvaneobs = 0 ; botvaneobs = 0 ; leftvaneobs = 0 ; rightvaneobs = 0 ; nonvaneobs = 0 ;
        topvanenames = [] ; botvanenames = [] ; leftvanenames = [] ; rightvanenames = [] ; nonvanenames = [] ;
        for i = 1:length(cadimpnames)
            boundbox = comsolModel.geom('geom1').feature('imp1').object(cadimpnames(i)).getBoundingBox ;
            if boundbox(3) > 0
                topvaneobs = topvaneobs + 1 ; topvanenames{topvaneobs} = char(cadimpnames(i)) ;
            elseif boundbox(4) < 0
                botvaneobs = botvaneobs + 1 ; botvanenames{botvaneobs} = char(cadimpnames(i)) ;
            elseif boundbox(1) > 0
                leftvaneobs = leftvaneobs + 1 ; leftvanenames{leftvaneobs} = char(cadimpnames(i)) ;
            elseif boundbox(2) < 0
                rightvaneobs = rightvaneobs + 1 ; rightvanenames{rightvaneobs} = char(cadimpnames(i)) ;
            else
                nonvaneobs = nonvaneobs + 1 ; nonvanenames{nonvaneobs} = char(cadimpnames(i)) ;
            end
        end

        comsolModel.geom('geom1').feature.create('uni1', 'Union');
        comsolModel.geom('geom1').feature('uni1').selection('input').set(topvanenames) ;
        comsolModel.geom('geom1').feature('uni1').set('intbnd', 'off');
        comsolModel.geom('geom1').feature('uni1').set('repairtol', '1.0E-8') ;

        comsolModel.geom('geom1').feature.create('uni2', 'Union');
        comsolModel.geom('geom1').feature('uni2').selection('input').set(botvanenames);
        comsolModel.geom('geom1').feature('uni2').set('intbnd', 'off');
        comsolModel.geom('geom1').feature('uni2').set('repairtol', '1.0E-8');

        comsolModel.geom('geom1').feature.create('uni3', 'Union');
        comsolModel.geom('geom1').feature('uni3').selection('input').set(leftvanenames);
        comsolModel.geom('geom1').feature('uni3').set('intbnd', 'off');
        comsolModel.geom('geom1').feature('uni3').set('repairtol', '1.0E-8');

        comsolModel.geom('geom1').feature.create('uni4', 'Union');
        comsolModel.geom('geom1').feature('uni4').set('intbnd', 'off');
        comsolModel.geom('geom1').feature('uni4').selection('input').set(rightvanenames);
        comsolModel.geom('geom1').feature('uni4').set('repairtol', '1.0E-8');

        comsolModel.geom('geom1').run('uni1');
        comsolModel.geom('geom1').run('uni2');
        comsolModel.geom('geom1').run('uni3');
        comsolModel.geom('geom1').run('uni4');
        clear endObjectName vaneSelection;

        vaneBoundBoxes = [comsolModel.geom('geom1').object('uni1').getBoundingBox, comsolModel.geom('geom1').object('uni2').getBoundingBox, ...
            comsolModel.geom('geom1').object('uni3').getBoundingBox, comsolModel.geom('geom1').object('uni4').getBoundingBox] ;
        extraBoundBox = [vaneBoundBoxes] ;
        if nonvaneobs > 0
            for i = 1:nonvaneobs
                extraBoundBox = [extraBoundBox, comsolModel.geom('geom1').object(char(nonvanenames{i})).getBoundingBox] ;
            end
        end
        modelBoundBox = [] ;
        modelBoundBox([1 3 5]) = min(extraBoundBox([1 3 5],:),[],2) ;
        modelBoundBox([2 4 6]) = max(extraBoundBox([2 4 6],:),[],2) ;
        modelBoundBox = modelBoundBox' ;

        comsolModel.param.set('vaneModelStart', [num2str(floor(modelBoundBox(5).*1e8)./1e8) '[m]']) ;
        comsolModel.param.set('vaneModelEnd', [num2str(ceil(modelBoundBox(6).*1e8)./1e8) '[m]']) ;

    catch exception
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:ComsolInterface:createGeometry:vaneUnification:exception';
        errorMessage.text = 'Could not unify vane sections';
        errorMessage.priorityLevel = 6; 
        errorMessage.errorLevel = 'error';
        errorMessage.exception = exception;
        logMessage(errorMessage, parameters) ; 
    end

    try % to create selection block

        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:createGeometry:createSelectionBlock';
        message.text = '     --> Creating selection block...';
        message.priorityLevel = 9;
        message.errorLevel = 'information';
        logMessage(message, parameters) ;
        clear message;

        comsolModel.geom('geom1').feature.create('blk1', 'Block');
        if fourQuad
            comsolModel.geom('geom1').feature('blk1').set('base', 'center');
            comsolModel.geom('geom1').feature('blk1').setIndex('size', 'boxWidth*2', 0);
            comsolModel.geom('geom1').feature('blk1').setIndex('size', 'boxWidth*2', 1);
            comsolModel.geom('geom1').feature('blk1').setIndex('pos', 'selectionMiddle', 2);
        else
            comsolModel.geom('geom1').feature('blk1').setIndex('size', 'boxWidth', 0);
            comsolModel.geom('geom1').feature('blk1').setIndex('size', 'boxWidth', 1);
            comsolModel.geom('geom1').feature('blk1').setIndex('pos', 'selectionStart', 2);
        end
        comsolModel.geom('geom1').feature('blk1').setIndex('size', 'selectionLength', 2);
        comsolModel.geom('geom1').feature('blk1').name('Selected Vane Block');
        comsolModel.geom('geom1').run('blk1');

    catch exception
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:ComsolInterface:createGeometry:createSelectionBlock:exception';
        errorMessage.text = 'Could not create selection block';
        errorMessage.priorityLevel = 6; 
        errorMessage.errorLevel = 'error';
        errorMessage.exception = exception;
        logMessage(errorMessage, parameters) ; 
    end

    try % to cut out vane segment

        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:createGeometry:vaneCutOut';
        message.text = '     --> Cutting out vane section...';
        message.priorityLevel = 9;
        message.errorLevel = 'information';
        logMessage(message, parameters) ;
        clear message;

        intersectionNames = {'blk1' 'uni1' 'uni2' 'uni3' 'uni4'} ;
        if nonvaneobs > 0
            for i = 1:nonvaneobs
                intersectionNames{end+1} = nonvanenames{i} ;
            end
        end
        comsolModel.geom('geom1').feature.create('int1', 'Intersection');
        comsolModel.geom('geom1').feature('int1').selection('input').set(intersectionNames);
        comsolModel.geom('geom1').feature('int1').name('Cut Out Vanes');
        comsolModel.geom('geom1').run('int1');

    catch exception
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:ComsolInterface:createGeometry:vaneCutOut:exception';
        errorMessage.text = 'Could not cut out vane segment';
        errorMessage.priorityLevel = 6; 
        errorMessage.errorLevel = 'error';
        errorMessage.exception = exception;
        logMessage(errorMessage, parameters) ; 
    end
    
    try % to create inner beam box

        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:createGeometry:createInnerBeamBox';
        message.text = '     --> Creating inner beam box...';
        message.priorityLevel = 9;
        message.errorLevel = 'information';
        logMessage(message, parameters) ; 
        clear message;

        comsolModel.geom('geom1').feature.create('blk2', 'Block');
        if fourQuad
            comsolModel.geom('geom1').feature('blk2').set('base', 'center');
            comsolModel.geom('geom1').feature('blk2').setIndex('size', 'beamBoxWidth*2', 0);
            comsolModel.geom('geom1').feature('blk2').setIndex('size', 'beamBoxWidth*2', 1);
            comsolModel.geom('geom1').feature('blk2').setIndex('pos', 'selectionMiddle', 2);
        else
            comsolModel.geom('geom1').feature('blk2').setIndex('size', 'beamBoxWidth', 0);
            comsolModel.geom('geom1').feature('blk2').setIndex('size', 'beamBoxWidth', 1);
            comsolModel.geom('geom1').feature('blk2').setIndex('pos', 'selectionStart', 2);
        end
        comsolModel.geom('geom1').feature('blk2').setIndex('size', 'selectionLength', 2);
        comsolModel.geom('geom1').feature('blk2').name('Beam Box (Inner)');
        comsolModel.geom('geom1').run('blk2');

        comsolModel.geom('geom1').feature.create('blk3', 'Block');
        if fourQuad
            comsolModel.geom('geom1').feature('blk3').setIndex('size', 'beamBoxWidth*2', 0);
            comsolModel.geom('geom1').feature('blk3').setIndex('size', 'beamBoxWidth*2', 1);
            comsolModel.geom('geom1').feature('blk3').set('base', 'center');
            comsolModel.geom('geom1').feature('blk3').setIndex('pos', 'cellMiddle', 2);
        else
            comsolModel.geom('geom1').feature('blk3').setIndex('size', 'beamBoxWidth', 0);
            comsolModel.geom('geom1').feature('blk3').setIndex('size', 'beamBoxWidth', 1);
            comsolModel.geom('geom1').feature('blk3').setIndex('pos', 'cellStart', 2);
        end
        comsolModel.geom('geom1').feature('blk3').setIndex('size', 'cellLength', 2);
        comsolModel.geom('geom1').feature('blk3').name('Beam Box (Inner - Mid)');
        comsolModel.geom('geom1').run('blk3');

    catch exception
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:ComsolInterface:createGeometry:createInnerBeamBox:exception';
        errorMessage.text = 'Could not create inner beam box';
        errorMessage.priorityLevel = 6; 
        errorMessage.errorLevel = 'error';
        errorMessage.exception = exception;
        logMessage(errorMessage, parameters) ; 
    end
    
    try % to create outer beam box

        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:createGeometry:createOuterBeamBox';
        message.text = '     --> Creating outer beam box...';
        message.priorityLevel = 9;
        message.errorLevel = 'information';
        logMessage(message, parameters) ; 
        clear message;

        comsolModel.geom('geom1').feature.create('blk4', 'Block');
        if fourQuad
            comsolModel.geom('geom1').feature('blk4').set('base', 'center');
            comsolModel.geom('geom1').feature('blk4').setIndex('pos', 'selectionMiddle', 2);
            comsolModel.geom('geom1').feature('blk4').setIndex('size', '((2*r0)+rho)*2', 0);
            comsolModel.geom('geom1').feature('blk4').setIndex('size', '((2*r0)+rho)*2', 1);
        else
            comsolModel.geom('geom1').feature('blk4').setIndex('size', '(2*r0)+rho', 0);
            comsolModel.geom('geom1').feature('blk4').setIndex('size', '(2*r0)+rho', 1);
            comsolModel.geom('geom1').feature('blk4').setIndex('pos', 'selectionStart', 2);
        end
        comsolModel.geom('geom1').feature('blk4').setIndex('size', 'selectionLength', 2);
        comsolModel.geom('geom1').feature('blk4').name('Beam Box (Outer)');
        comsolModel.geom('geom1').run('blk4');

    catch exception
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:ComsolInterface:createGeometry:createOuterBeamBox:exception';
        errorMessage.text = 'Could not create outer beam box';
        errorMessage.priorityLevel = 6; 
        errorMessage.errorLevel = 'error';
        errorMessage.exception = exception;
        logMessage(errorMessage, parameters) ;
    end

    try %to to create air bag

        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:createGeometry:createAirBag';
        message.text = '     --> Creating air bag...';
        message.priorityLevel = 9;
        message.errorLevel = 'information';
        logMessage(message, parameters) ; 
        clear message;

        comsolModel.geom('geom1').feature.create('blk5', 'Block');
        if fourQuad
            comsolModel.geom('geom1').feature('blk5').setIndex('size', 'boxWidth*2', 0);
            comsolModel.geom('geom1').feature('blk5').setIndex('size', 'boxWidth*2', 1);
            comsolModel.geom('geom1').feature('blk5').set('base', 'center');
            comsolModel.geom('geom1').feature('blk5').setIndex('pos', 'selectionMiddle', 2);
        else
            comsolModel.geom('geom1').feature('blk5').setIndex('size', 'boxWidth', 0);
            comsolModel.geom('geom1').feature('blk5').setIndex('size', 'boxWidth', 1);
            comsolModel.geom('geom1').feature('blk5').setIndex('pos', 'selectionStart', 2);
        end
        comsolModel.geom('geom1').feature('blk5').setIndex('size', 'selectionLength', 2);
        comsolModel.geom('geom1').feature('blk5').name('Air Bag');
        comsolModel.geom('geom1').runAll;
        comsolModel.view('view1').set('transparency', 'on');
        comsolModel.geom('geom1').run;

    catch exception
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:ComsolInterface:createGeometry:createAirBag:exception';
        errorMessage.text = 'Could not create air bag';
        errorMessage.priorityLevel = 6; 
        errorMessage.errorLevel = 'error';
        errorMessage.exception = exception;
        logMessage(errorMessage, parameters) ; 
    end

    try % to create selections

        message = struct;
        message.identifier = 'ModelRFQ:ComsolInterface:createGeometry:createSelections';
        message.text = '     --> Creating selections...';
        message.priorityLevel = 9;
        message.errorLevel = 'information';
        logMessage(message, parameters) ; 
        clear message;

        comsolModel.selection.create('sel1');
        if fourQuad
            comsolModel.selection('sel1').set([2 5 6 7 8 9 15 16]);
        else
            comsolModel.selection('sel1').set([5 6 8 9]);
        end
        comsolModel.selection('sel1').name('All Vanes');
        selectionNames.allVanes = 'sel1';

        comsolModel.selection.create('sel2');
        if fourQuad
            comsolModel.selection('sel2').set([2 5 15 16]);
        else
            comsolModel.selection('sel2').set([8 9]);
        end
        comsolModel.selection('sel2').name('Horizontal Vanes');
        selectionNames.horizontalVanes = 'sel2';

        comsolModel.selection.create('sel3');
        if fourQuad
            comsolModel.selection('sel3').set([6 7 8 9]);
        else
            comsolModel.selection('sel3').set([5 6]);
        end
        comsolModel.selection('sel3').name('Vertical Vanes');
        selectionNames.verticalVanes = 'sel3';

        comsolModel.selection.create('sel4');
        comsolModel.selection('sel4').geom('geom1', 3, 2, {'exterior'});
        if fourQuad
            comsolModel.selection('sel4').set([2 5 6 7 8 9 15 16]);
        else
            comsolModel.selection('sel4').set([5 6 8 9]);
        end
        comsolModel.selection('sel4').name('All Terminals');
        selectionNames.allTerminals = 'sel4';

        comsolModel.selection.create('sel5');
        comsolModel.selection('sel5').geom('geom1', 3, 2, {'exterior'});
        if fourQuad
            comsolModel.selection('sel5').set([2 5 15 16]);
        else
            comsolModel.selection('sel5').set([8 9]);
        end
        comsolModel.selection('sel5').name('Horizontal Terminals');
        selectionNames.horizontalTerminals = 'sel5';

        comsolModel.selection.create('sel6');
        comsolModel.selection('sel6').geom('geom1', 3, 2, {'exterior'});
        if fourQuad
            comsolModel.selection('sel6').set([6 7 8 9]);
        else
            comsolModel.selection('sel6').set([5 6]);
        end
        comsolModel.selection('sel6').name('Vertical Terminals');
        selectionNames.verticalTerminals = 'sel6';

        comsolModel.selection.create('sel7');
        if fourQuad
            comsolModel.selection('sel7').set([1 3 4 10 11 12 13 14]);
        else
            comsolModel.selection('sel7').set([1 2 3 4 7]);
        end
        comsolModel.selection('sel7').name('Air Volumes');
        selectionNames.airVolumes = 'sel7';

        comsolModel.selection.create('sel8');
        if fourQuad
            comsolModel.selection('sel8').set([10 11 12]);
        else
            comsolModel.selection('sel8').set([1 2 3]);
        end
        comsolModel.selection('sel8').name('Inner Beam Box');
        selectionNames.innerBeamBox = 'sel8';

        comsolModel.selection.create('sel9');
        if fourQuad
            comsolModel.selection('sel9').set(10);
        else
            comsolModel.selection('sel9').set(1);
        end
        comsolModel.selection('sel9').name('Inner Beam Box (Front)');
        selectionNames.innerBeamBoxFront = 'sel9';

        comsolModel.selection.create('sel10');
        if fourQuad
            comsolModel.selection('sel10').set(11);
        else
            comsolModel.selection('sel10').set(2);
        end
        comsolModel.selection('sel10').name('Inner Beam Box (Mid)');
        selectionNames.innerBeamBoxMid = 'sel10';

        comsolModel.selection.create('sel11');
        if fourQuad
            comsolModel.selection('sel11').set(12);
        else
            comsolModel.selection('sel11').set(3);
        end
        comsolModel.selection('sel11').name('Inner Beam Box (Rear)');
        selectionNames.innerBeamBoxRear = 'sel11';

        comsolModel.selection.create('sel12');
        comsolModel.selection('sel12').geom('geom1', 3, 2, {'exterior'});
        if fourQuad
            comsolModel.selection('sel12').set([10 11 12]);
        else
            comsolModel.selection('sel12').set([1 2 3]);
        end
        comsolModel.selection('sel12').name('Inner Beam Box (Boundaries)');
        selectionNames.innerBeamBoxBoundaries = 'sel12';

        comsolModel.selection.create('sel13');
        comsolModel.selection('sel13').geom(2);
        if fourQuad
            comsolModel.selection('sel13').set(46);
        else
            comsolModel.selection('sel13').set(3);
        end
        comsolModel.selection('sel13').name('Inner Beam Box (Front Face)');
        selectionNames.innerBeamBoxFrontFace = 'sel13';

        comsolModel.selection.create('sel14');
        comsolModel.selection('sel14').geom(2);
        if fourQuad
            comsolModel.selection('sel14').set(53);
        else
            comsolModel.selection('sel14').set(10);
        end
        comsolModel.selection('sel14').name('Inner Beam Box (Rear Face)');
        selectionNames.innerBeamBoxRearFace = 'sel14';

        comsolModel.selection.create('sel15');
        comsolModel.selection('sel15').set(4);
        comsolModel.selection('sel15').name('Outer Beam Box');
        selectionNames.outerBeamBox = 'sel15';

        comsolModel.selection.create('sel16');
        if fourQuad
            comsolModel.selection('sel16').set([1 3 13 14]);
        else
            comsolModel.selection('sel16').set(7);
        end
        comsolModel.selection('sel16').name('Air Bag');
        selectionNames.airBag = 'sel16';

        comsolModel.selection.create('sel17');
        comsolModel.selection('sel17').geom('geom1', 3, 2, {'exterior'});
        if fourQuad
            comsolModel.selection('sel17').set([1 3 13 14]);
        else
            comsolModel.selection('sel17').set(7);
        end
        comsolModel.selection('sel17').name('Air Bag (Boundaries)');
        selectionNames.airBagBoundaries = 'sel17';

        comsolModel.selection.create('sel18');
        comsolModel.selection('sel18').geom(2);
        comsolModel.selection('sel18').geom('geom1', 2, 1, {'exterior'});
        if fourQuad
            comsolModel.selection('sel18').set(46);
        else
            comsolModel.selection('sel18').set(3);
        end
        comsolModel.selection('sel18').name('Inner Beam Box (Front Edges)');
        selectionNames.innerBeamBoxFrontEdges = 'sel18';

        comsolModel.selection.create('sel19');
        comsolModel.selection('sel19').geom(2);
        if fourQuad
            comsolModel.selection('sel19').set([46 49 52]);
        else
            comsolModel.selection('sel19').set([3 6 9]);
        end
        comsolModel.selection('sel19').name('Inner Beam Box (Leading Faces)');
        selectionNames.innerBeamBoxLeadingFaces = 'sel19';

        comsolModel.selection.create('sel20');
        comsolModel.selection('sel20').geom(2);
        comsolModel.selection('sel20').geom('geom1', 2, 1, {'exterior'});
        if fourQuad
            comsolModel.selection('sel20').set([46 49 52]);
        else
            comsolModel.selection('sel20').set([3 6 9]);
        end
        comsolModel.selection('sel20').name('Inner Beam Box (Leading Edges)');
        selectionNames.innerBeamBoxLeadingEdges = 'sel20';

        comsolModel.selection.create('sel21');
        if fourQuad
            comsolModel.selection('sel21').set([4 10 11 12]);
        else
            comsolModel.selection('sel21').set([1 2 3 4]);
        end
        comsolModel.selection('sel21').name('Beam Boxes');
        selectionNames.beamBoxes = 'sel21';

        comsolModel.selection.create('sel22');
        comsolModel.selection('sel22').geom('geom1', 3, 2, {'exterior'});
        comsolModel.selection('sel22').set([]);
        comsolModel.selection('sel22').name('End Flange Ground Surface');
        selectionNames.endFlangeGrounded = 'sel22';

    catch exception
        errorMessage = struct;
        errorMessage.identifier = 'ModelRFQ:ComsolInterface:createGeometry:createSelections';
        errorMessage.text = 'Could not create selections';
        errorMessage.priorityLevel = 6; 
        errorMessage.errorLevel = 'error';
        errorMessage.exception = exception;
        logMessage(errorMessage, parameters) ; 
    end

    outputParameters = parameters ;

    return