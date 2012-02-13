function name = getComputerName()
%
%   function name = getComputerName()
%
%   GETCOMPUTERNAME returns the name of the computer (hostname)
%
%   Created by Manuel Marin, modified by Matt Easton.
%
%   See also SYSTEM, GETENV, ISPC, ISUNIX
%
% m j m a r i n j (AT) y a h o o (DOT) e s
% (c) MJMJ/2007

% File released under the GNU public license.
% Originally written by Matt Easton.
%
% File history:
%
%   19-Sep-2007 M. Marin
%       Original file version uploaded to http://www.mathworks.com/matlabcentral/fileexchange/16450-get-computer-namehostname
%
%   09-Feb-2010 M. J. Easton
%       Tidied up function and included in ModelRFQ distribution.
%
%=========================================================================

    % try hostname command
    [ret, name] = system('hostname');

    % if this fails, use getenv
    if ret ~= 0, 
       if ispc 
          name = getenv('COMPUTERNAME'); 
       else 
          name = getenv('HOSTNAME'); 
       end 
    end
    
    % convert to lower case for easy comparisons
    name = lower(name);

    % remove trailing newline or null characters 
    name = deblank(name);
    
    % select only the part before the first dot
    name = regexp(name, '\.', 'split');
    name = name(1);
    name = name{1};
    
return