function C = overlay_config()
% IGP overlay configuration
%
% Convention used by overlayBifurcationBoundary:
%   - "b" corresponds to the x-axis parameter
%   - "a" corresponds to the y-axis parameter
%
% This file maps the IGP MatCont continuation output onto those roles.

C.output_base = "igpVBfield";

% MatCont curve files to overlay (must live in IGP/mats/)
% Update names if MatCont saved them differently
C.default_curve_files = ["LP_LP(1).mat","LP_LP(2).mat"];

% MatCont row mapping:
% For a 1D equilibrium continuation, MatCont stores:
%   x(1,:) = state variable
%   x(2,:), x(3,:) = active parameters (order depends on ActiveParams)
%
% Set these so that:
%   matcont_b_row → parameter used on VB x-axis
%   matcont_a_row → parameter used on VB y-axis
%
% Start with the standard assumption; swap after checking ranges if needed.
C.matcont_a_row = 3;   % y-axis parameter
C.matcont_b_row = 4;   % x-axis parameter

% Optional defaults so overlayBifurcationBoundary can be called with no args
C.x_param = "b";
C.y_param = "a";
end
