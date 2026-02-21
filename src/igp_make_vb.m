function out = igp_make_vb(focal, param1_name, param1_range, ...
                           param2_name, param2_range, grid_size, opts)
% -------------------------------------------------------------------------
% igp_make_vb
%
% Purpose:
%   Parameter sweep for the Intra-guild Predation (IGP) model.
%   Computes V_B as Euclidean distance in (x,y) phase space from a selected
%   stable equilibrium (low-y or high-y) to its destabilizing boundary:
%     - nearest bounding saddle (from a focal-dependent candidate set), or
%     - fallback to a boundary equilibrium in monostable regimes.
%
% Example:
%   out = igp_make_vb("low",  'b',[0 1], 'a',[0 1], [40 40]); % testing
%   out = igp_make_vb("high", 'b',[0 1], 'a',[0 1], [350 350]); %
%   publication
%
% Requirements:
%   - find_real_eqa.m
%   - classify_equilibria.m
%   - igp_vb_distance_at_params.m
%   - igp_boundary_equilibrium.m
% -------------------------------------------------------------------------

% Ensure utilities folder is on path
this_file = mfilename('fullpath');
repo_root = fileparts(fileparts(this_file));  % go up from model folder
utilities_path = fullfile(repo_root, 'utilities');
addpath(utilities_path);

    if nargin < 6
        error('Usage: igp_make_vb(focal, param1_name, param1_range, param2_name, param2_range, grid_size, [opts])');
    end
    if nargin < 7
        opts = struct();
    end

    % defaults
    if ~isfield(opts,'base_params')
        opts.base_params = struct('a', 0.7, 'b', 0.9, 'd', 0.1, 'k', 0.1, ...
                                  'e', 0.01, 'r', 2 );
    end
    if ~isfield(opts,'save_outputs'), opts.save_outputs = true; end
    if ~isfield(opts,'make_plot'),    opts.make_plot = true; end
    if ~isfield(opts,'outdir'),       opts.outdir = ''; end
    if ~isfield(opts,'y_min'),        opts.y_min = 0.0; end

    % normalize + validate focal
    if ischar(focal), focal = string(focal); end
    focal = lower(string(focal));
    if ~(focal=="low" || focal=="high")
        error('focal must be "low" or "high".');
    end

    % Directories
    if isempty(opts.outdir)
        my_folder = fileparts(mfilename('fullpath'));
    else
        my_folder = opts.outdir;
    end
    mats_folder = fullfile(my_folder, 'mats');
    figs_folder = fullfile(my_folder, 'figs');
    if ~exist(mats_folder, 'dir'); mkdir(mats_folder); end
    if ~exist(figs_folder, 'dir'); mkdir(figs_folder); end

    % Grid
    param1_vals = linspace(param1_range(1), param1_range(2), grid_size(1));
    param2_vals = linspace(param2_range(1), param2_range(2), grid_size(2));
    [P1, P2] = meshgrid(param1_vals, param2_vals);

    % Output field
    D = NaN(size(P1));

    start_time = tic;
    fprintf('IGP sweep (%s focal) started at %s\n', ...
        focal, string(datetime('now','Format','HH:mm:ss')));

    progress_interval = max(1, round(0.05 * numel(P1)));

    for i = 1:numel(P1)
        if mod(i, progress_interval) == 0 || i == 1
            fprintf('Progress: %d/%d (%.1f%%), %s=%.4f, %s=%.4f\n', ...
                i, numel(P1), 100*i/numel(P1), ...
                param1_name, P1(i), param2_name, P2(i));
        end

        params = opts.base_params;
        params.(param1_name) = P1(i);
        params.(param2_name) = P2(i);

        var_names  = {param1_name, param2_name};
        var_values = [P1(i), P2(i)];

        D(i) = igp_vb_distance_at_params(params, focal, var_names, var_values, opts);
    end

    % Package output
    out = struct();
    out.model = "IGP";
    out.focal = focal;
    out.D = D;
    out.param1_vals = param1_vals;
    out.param2_vals = param2_vals;
    out.param1_name = param1_name;
    out.param2_name = param2_name;
    out.param1_range = param1_range;
    out.param2_range = param2_range;
    out.grid_size = grid_size;
    out.meta = struct('timestamp', datetime('now'), 'base_params', opts.base_params, 'y_min', opts.y_min);

    % Filenames (include focal + grid size)
    base_filename = sprintf('%s%.4f_%.4f_%s%.4f_%.4f_grid%dx%d', ...
        param1_name, param1_range(1), param1_range(2), ...
        param2_name, param2_range(1), param2_range(2), ...
        grid_size(1), grid_size(2));

    matfile_path = fullfile(mats_folder, sprintf('D_raw_igp_%s_%s.mat', focal, base_filename));
    figfile_path = fullfile(figs_folder, sprintf('vb_igp_%s_%s', focal, base_filename));

    if opts.save_outputs
        save(matfile_path, 'D', 'param1_vals', 'param2_vals', ...
            'param1_name', 'param2_name', 'param1_range', 'param2_range', ...
            'grid_size', 'focal');
    end

    if opts.make_plot
        fig = figure;
        imagesc(param1_vals, param2_vals, D);
        set(gca,'YDir','normal');
        cmap = parula(256);  % optional: set cmap(1,:)=[1 1 1] if you want
        colormap(cmap);
        colorbar;
        xlabel(param1_name);
        ylabel(param2_name);

        if exist('formatSweepPlot','file') == 2
            formatSweepPlot(param1_name, param1_vals, param2_name, param2_vals);
        end

        % Optional saves
        savefig([figfile_path '.fig']);
        saveas(fig, [figfile_path '.png']);
        % print(fig, [figfile_path '.tiff'], '-dtiff', '-r600');
        % print(fig, [figfile_path '.eps'], '-depsc');
    end

    elapsed_time = toc(start_time);
    fprintf('IGP sweep complete. Elapsed: %.2f s (%.2f min)\n', elapsed_time, elapsed_time/60);
end
