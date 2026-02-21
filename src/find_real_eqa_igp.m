function eq_pts = find_real_eqa_igp(params, var_names, var_values)
% FIND_REAL_EQA_IGP  Find real-valued equilibria for the IGP model
%
%   eq_pts = find_real_eqa_igp(params, var_names, var_values)
%
% Inputs:
%   params      - Struct with parameters: a,b,d,k,e,r
%   var_names   - Cell array of swept parameter names (e.g., {'b','a'})
%   var_values  - Values to override in params (same order as var_names)
%
% Output:
%   eq_pts      - N×2 array of unique equilibria [x, y]

    % Apply parameter overrides (matches your old calling style)
    if nargin >= 2 && ~isempty(var_names)
        for i = 1:length(var_names)
            params.(var_names{i}) = var_values(i);
        end
    end

    % Unpack parameters used by RHS
    a = params.a;  b = params.b;  d = params.d;
    k = params.k;  e = params.e;  r = params.r;

    % Root function: F([x;y]) = [dx; dy]
    F = @(Y) [ ...
        Y(1) * (1 - Y(1) - a*Y(2)) - d * Y(1)^2 * Y(2) / (k^2 + Y(1)^2); ...
        r*Y(2) * (1 - b*Y(1) - Y(2)) + e * Y(1)^2 * Y(2) / (k^2 + Y(1)^2) ...
    ];

    % ---- Multistart guesses (ecology: typically nonnegative) -------------
    % Start conservative. If you later discover missing equilibria, widen.
    grid = linspace(0, 1.2, 13);
    [X, Y] = meshgrid(grid, grid);
    guesses = [X(:), Y(:)];

    eq_list = [];
    residual_tol = 1e-7;
    uniq_tol = 1e-6;

    opts = optimset('Display','off', ...
                    'TolX',1e-9,'TolFun',1e-9, ...
                    'MaxIter',1000,'MaxFunEvals',4000);

    for i = 1:size(guesses,1)
        guess = guesses(i,:)';

        try
            [sol, ~, flag] = fsolve(F, guess, opts);

            if flag > 0 && all(isreal(sol))
                res = norm(F(sol), 2);
                if res < residual_tol

                    % Keep physical equilibria (nonnegative); allow tiny negatives
                    if any(sol < -1e-10)
                        continue;
                    end

                    sol = real(sol);

                    % De-duplicate
                    if isempty(eq_list) || ~any(all(abs(eq_list - sol') < uniq_tol, 2))
                        eq_list(end+1,:) = sol';
                    end
                end
            end
        catch
            % Skip failures
        end
    end

    eq_pts = eq_list;
end
