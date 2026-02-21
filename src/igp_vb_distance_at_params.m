function d = igp_vb_distance_at_params(params, focal, var_names, var_values, opts)
% IGP_VB_DISTANCE_AT_PARAMS
% Compute V_B distance for IGP at a single parameter pair.

    if nargin < 5, opts = struct(); end
    if ~isfield(opts,'y_min'), opts.y_min = 0.0; end

    % Find equilibria at this parameter pair
    eq_pts = find_real_eqa_igp(params, var_names, var_values);
    if isempty(eq_pts) || size(eq_pts,1) < 1
        d = NaN; return;
    end

    % Classify equilibria
    types = classify_equilibria_igp(eq_pts, params);
    stable_pts = eq_pts(types=="stable" & eq_pts(:,2) > opts.y_min, :);
    saddle_pts = eq_pts(types=="saddle", :);

    if isempty(stable_pts)
        d = NaN; return;
    end

    focal = lower(string(focal));

    switch focal
        case "high"
            % highest-y stable equilibrium
            [~, idx] = max(stable_pts(:,2));
            focal_pt = stable_pts(idx, :);

            % candidate saddles: right of and below focal point (your established rule)
            candidate = saddle_pts( saddle_pts(:,1) > focal_pt(1) & saddle_pts(:,2) < focal_pt(2), :);

        case "low"
            % lowest-y stable equilibrium
            [~, idx] = min(stable_pts(:,2));
            focal_pt = stable_pts(idx, :);

            % candidate saddles: left of and above focal point (your established rule)
            candidate = saddle_pts( saddle_pts(:,1) < focal_pt(1) & saddle_pts(:,2) > focal_pt(2), :);

        otherwise
            error('focal must be "low" or "high".');
    end

    if isempty(candidate)
        xb = igp_boundary_equilibrium(focal);
        d = norm(focal_pt - xb);
    else
        [~, j] = min(vecnorm(candidate - focal_pt, 2, 2));
        d = norm(focal_pt - candidate(j,:));
    end
end
