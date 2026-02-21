function types = classify_equilibria_igp(eq_pts, params)
% CLASSIFY_EQUILIBRIA_IGP  Classify equilibria of IGP model
%
% Inputs:
%   eq_pts - N×2 equilibria [x, y]
%   params - Struct with parameters: a,b,d,k,e,r
%
% Output:
%   types - string array: "stable", "saddle", "other"

    a = params.a;  b = params.b;  d = params.d;
    k = params.k;  e = params.e;  r = params.r;

    types = strings(size(eq_pts,1), 1);

    imag_tol = 1e-8;  % 2D should be real in most cases
    eig_tol  = 1e-8;

    for i = 1:size(eq_pts,1)
        x = eq_pts(i,1);
        y = eq_pts(i,2);

        denom = (k^2 + x^2);
        denom2 = denom^2;

        % dx = x*(1 - x - a*y) - d*x^2*y/(k^2 + x^2)
        % dy = r*y*(1 - b*x - y) + e*x^2*y/(k^2 + x^2)

        % Partial derivatives:

        % d/dx of d*x^2*y/(k^2+x^2) term:
        % g(x)=x^2/(k^2+x^2) => g'(x)= 2x*k^2/(k^2+x^2)^2
        gprime = (2*x*k^2) / denom2;

        dxdx = (1 - 2*x - a*y) - d * y * gprime;
        dxdy = -a*x - d * (x^2 / denom);

        dydx = -r*b*y + e * y * gprime;
        dydy = r*(1 - b*x - 2*y) + e * (x^2 / denom);

        J = [dxdx, dxdy;
             dydx, dydy];

        eigvals = eig(J);

        if any(abs(imag(eigvals)) > imag_tol)
            types(i) = "other";
            continue;
        end
        eigvals = real(eigvals);

        if all(eigvals < -eig_tol)
            types(i) = "stable";
        elseif any(eigvals > eig_tol) && any(eigvals < -eig_tol)
            types(i) = "saddle";
        else
            types(i) = "other";  % near-bifurcation / degenerate / numerical fuzz
        end
    end
end
