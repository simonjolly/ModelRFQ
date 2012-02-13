function comsolPort = getComsolPort(portSetting)
% function comsolPort = getComsolPort(portSetting)
%
% comsolPort takes the specified setting, checks it, and returns a port
% number.
%
% portSetting can be a port number (default 2036) or a string value:
%   - default
%   - secondary
%   - tertiary
% Using secondary and tertiary settings allows multiple simulations to be
% run concurrently.
%
% See also buildComsolModel, modelRfq, getModelParameters.

% File released under the GNU public license.
% Originally written by Matt Easton. Based on code by Simon Jolly.
%
% File history
%
%   13-Mar-2011 M. J. Easton
%       Wrote getComsolPort as part of ModelRFQ distribution.
%
%=======================================================================
    defaultComsolPort = 2036;

    if ischar(portSetting) %then set port
        switch portSetting
            case 'default'
                comsolPort = defaultComsolPort;
            case 'secondary'
                comsolPort = defaultComsolPort+1;
            case 'tertiary'
                comsolPort = defaultComsolPort+2;
            otherwise
                comsolPort = defaultComsolPort;
        end
    elseif isnumeric(portSetting) %then check number 
        if portSetting >= defaultComsolPort %then use number 
            comsolPort = portSetting;
        else
            comsolPort = defaultComsolPort;
        end
    else
        comsolPort = defaultComsolPort;
    end

return