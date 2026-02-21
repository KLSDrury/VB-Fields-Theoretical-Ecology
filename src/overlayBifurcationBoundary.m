function overlayBifurcationBoundary(matFiles, paramMap)
% OVERLAYBIFURCATIONBOUNDARY
%
% Overlay one or more MatCont bifurcation curves (stored as *.mat)
% onto the currently active VB colormap axes, and save the composite.
%
% Default behavior (recommended):
%   Uses model-specific settings from overlay_config.m in the same folder.
%
% Assumes:
%   - This script lives in the model folder (e.g. DW/)
%   - MatCont curve files live in ./mats/
%   - figs saved to ./figs/
%
% Usage (explicit, double-well example):
%   overlayBifurcationBoundary( ...
%       {'LP_LP(1).mat','LP_LP(2).mat'}, ...
%       struct('x','b','y','a') );
%
% Notes:
%   - The VB figure must already be open.
%   - Click once on the axes before calling this if MATLAB focus is confused.
%   - For MatCont output, we assume the curve is stored in S.x with
%     parameters in rows (common case). The row mapping is taken from config
%     when available (matcont_a_row/matcont_b_row), otherwise defaults to (2,3).

    % ---------------------------------------------------------------------
    % Resolve folders relative to this script
    % ---------------------------------------------------------------------
    thisFile = mfilename('fullpath');
    modelDir = fileparts(thisFile);
    matsDir  = fullfile(modelDir, 'mats');
    figsDir  = fullfile(modelDir, 'figs');
    if ~exist(figsDir,'dir'); mkdir(figsDir); end

    % ---------------------------------------------------------------------
    % Load model-specific config IF PRESENT (UNCONDITIONALLY for naming)
    %   (This is the correction: ensure C/output_base exists even when the
    %    user passes matFiles/paramMap explicitly.)
    % ---------------------------------------------------------------------
    cfgPath = fullfile(modelDir, 'overlay_config.m');
    have_cfg = (exist(cfgPath,'file') == 2);

    C = struct();
    if have_cfg
        C = overlay_config();  % if this errors, let it error (better than silent fallback)
    end

    % ---------------------------------------------------------------------
    % If args are missing/empty, fall back to config defaults (if available)
    % ---------------------------------------------------------------------
    if nargin < 1 || isempty(matFiles) || nargin < 2 || isempty(paramMap)
        if ~have_cfg
            error('Provide matFiles and paramMap, or add overlay_config.m in %s.', modelDir);
        end

        if nargin < 1 || isempty(matFiles)
            if isfield(C,'default_curve_files')
                matFiles = cellstr(string(C.default_curve_files));
            else
                error('overlay_config.m must define default_curve_files when matFiles is omitted.');
            end
        end

        if nargin < 2 || isempty(paramMap)
            % Keep your explicit paramMap behavior for models that use 'a'/'b'
            % (used only to decide whether to plot (b,a) or (a,b)).
            if isfield(C,'x_param') && isfield(C,'y_param')
                paramMap = struct('x', char(string(C.x_param)), 'y', char(string(C.y_param)));
            else
                error('overlay_config.m must define x_param and y_param when paramMap is omitted.');
            end
        end
    end

    if ischar(matFiles) || isstring(matFiles)
        matFiles = {matFiles};
    end

    % ---------------------------------------------------------------------
    % Plot onto current axes
    % ---------------------------------------------------------------------
    ax = gca;
    hold(ax, 'on');

    for k = 1:numel(matFiles)
        matPath = fullfile(matsDir, matFiles{k});
        if ~exist(matPath,'file')
            warning('File not found: %s', matPath);
            continue;
        end

        S = load(matPath);

        if ~isfield(S,'x')
            warning('No variable "x" found in %s', matFiles{k});
            continue;
        end

        % -----------------------------------------------------------------
        % Parameter mapping (model-specific row mapping if provided by config)
        % -----------------------------------------------------------------
        % Defaults
        a_row = 2; b_row = 3;
        
        if have_cfg
            % Preferred: x/y row mapping (most general)
            if isfield(C,'matcont_x_row') && isfield(C,'matcont_y_row')
                xplot = S.x(C.matcont_x_row,:);
                yplot = S.x(C.matcont_y_row,:);
            else
                % Backward compatible: a/b row mapping
                if isfield(C,'matcont_a_row'), a_row = C.matcont_a_row; end
                if isfield(C,'matcont_b_row'), b_row = C.matcont_b_row; end
        
                a = S.x(a_row,:);
                b = S.x(b_row,:);
        
                % Decide plot order from paramMap (x-axis variable)
                switch lower(string(paramMap.x))
                    case "b"
                        xplot = b; yplot = a;
                    case "a"
                        xplot = a; yplot = b;
                    otherwise
                        error('paramMap.x must be ''a'' or ''b''.');
                end
            end
        else
            a = S.x(a_row,:);
            b = S.x(b_row,:);
        
            switch lower(string(paramMap.x))
                case "b"
                    xplot = b; yplot = a;
                case "a"
                    xplot = a; yplot = b;
                otherwise
                    error('paramMap.x must be ''a'' or ''b''.');
            end
        end

        plot(ax, xplot, yplot, 'k-', 'LineWidth', 2);
    end

    hold(ax, 'off');

    % ---------------------------------------------------------------------
    % Save composite figure
    % ---------------------------------------------------------------------
    if have_cfg && isfield(C,'output_base') && strlength(string(C.output_base)) > 0
        baseName = char(string(C.output_base));
    else
        % fallback: folder tag + VBfield
        [~, tag] = fileparts(modelDir);
        baseName = [tag '_VBfield'];   % underscore for readability
        warning('overlay_config.output_base not found. Using fallback name: %s', baseName);
    end

    outBase = fullfile(figsDir, baseName);

    % Save in common formats
    saveas(gcf, [outBase '.png']);
    savefig(gcf, [outBase '.fig']);
    % print(gcf, [outBase '.eps'], '-depsc');

    fprintf('Saved composite to:\n  %s.png\n  %s.fig\n  %s.eps\n', outBase, outBase, outBase);
end
