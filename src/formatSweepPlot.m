
function formatSweepPlot(param1_name, param1_vals, param2_name, param2_vals)
% FORMATSWEEPPLOT Customizes axis, labels, colorbar, and export settings
%   Call this after plotting your imagesc, using the same param1/param2 setup.

    ax = gca;
    ax.FontSize = 20;

    % Map param names to LaTeX-style labels
    param_label_map = containers.Map( ...
        {'h', 'a', 'b', 'd', 'k', 'e', 'r'}, ...
        {'h', '\alpha', '\beta', '\delta', '\kappa', '\epsilon', 'r'} ...
    );

    % Resolve label names (fallback to raw param name)
    if isKey(param_label_map, param1_name)
        x_label = param_label_map(param1_name);
    else
        x_label = param1_name;
    end
    if isKey(param_label_map, param2_name)
        y_label = param_label_map(param2_name);
    else
        y_label = param2_name;
    end

    xlabel(x_label, 'FontSize', 20, 'FontWeight', 'bold', 'FontAngle', 'italic');
    ylabel(y_label, 'FontSize', 20, 'FontWeight', 'bold', 'FontAngle', 'normal');

    ax.XTick = [min(param1_vals), max(param1_vals)];
    ax.YTick = [min(param2_vals), max(param2_vals)];
    ax.XLim = [min(param1_vals), max(param1_vals)];
    ax.YLim = [min(param2_vals), max(param2_vals)];

    % Format colorbar
    cb = colorbar;
    cb.Location = 'eastoutside';
    cb.FontSize = 16;
    cb.FontWeight = 'normal';
    cb.Position(3) = cb.Position(3) * 0.6;

    % Adjust axes width
    axPos = ax.Position;
    ax.Position = [axPos(1), axPos(2), axPos(3)*0.87, axPos(4)];

    % Clean export formatting
    set(gcf, 'Units', 'Inches');
    pos = get(gcf, 'Position');
    set(gcf, 'PaperPositionMode', 'Auto', ...
             'PaperUnits', 'Inches', ...
             'PaperSize', [pos(3), pos(4)]);
end
