function xb = igp_boundary_equilibrium(focal)
% Fallback boundary equilibrium when no relevant saddle exists.

    switch lower(string(focal))
        case "high"
            xb = [1, 0];
        case "low"
            xb = [0, 1];
        otherwise
            error('focal must be "low" or "high".');
    end
end
