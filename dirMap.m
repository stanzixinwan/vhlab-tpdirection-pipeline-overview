function dirMap(S, tcDoc_All, options)
%DIRMAP Display direction selectivity map with arrows
%
%   DIRMAP(S, TCDOC_ALL, OPTIONS)
%
%   Creates a spatial map showing direction selectivity for each cell.
%   Arrow length represents direction index (DI), arrow orientation represents
%   preferred direction. Two arrows per cell show selectivity at different
%   temporal frequencies (blue = low TF, red = high TF).
%
%   Inputs:
%       S        - NDI session or dataset
%       tcDoc_All - Cell array of tuning curve documents for all cells
%       options   - Structure with optional parameters:
%                   .LowTF - Low temporal frequency (default: 1.6 Hz)
%                   .HighTF - High temporal frequency (default: 6.4 Hz)
    arguments
        S (1,1) {mustBeA(S,["ndi.session" "ndi.dataset"])}
        tcDoc_All (1,:)
        options.LowTF (1,1) double = 1.6
        options.HighTF (1,1) double = 6.4
    end

    e = S.getelements('element.type','roi');

    count = 0;
    for i = 1:numel(tcDoc_All)
        % Skip cells with empty tuning documents
        if isempty(tcDoc_All{i})
            continue
        end
        
        % Only plot cells with significant direction selectivity
        p_anova1 = sigDirSFTF(tcDoc_All{i});
        if p_anova1 > 0.05
            continue
        end
        
        % Get preferred direction and direction index for each temporal frequency
        [~, theta_pref, TF, DI, SF_used] = dirVector_AdaptiveSF(tcDoc_All{i});
        
        % Get cell position
        [x, y] = cellname2position(S.path, e{i}.name);
        
        % Check if we have enough temporal frequencies
        if numel(DI) < 2 || numel(theta_pref) < 2
            continue
        end
        
        % Select two temporal frequencies to display
        % Vector format: [DI, theta_pref, unused]
        V = zeros(2, 3);
        low_TF = options.LowTF;
        high_TF = options.HighTF;

        idx_low = find(TF == low_TF);
        idx_high = find(TF == high_TF);

        V(1, 1:2) = [DI(idx_low), theta_pref(idx_low)];
        V(2, 1:2) = [DI(idx_high), theta_pref(idx_high)];

        if any(isnan(V(:,1))) || any(isnan(V(:,2)))
            continue
        end
        
        count = count + 1;
        positions(count, :) = [x, y];
        vectors(count, :, :) = V(:, :);
    end

    try
        % Create figure and plot arrows
        f = figure;
        f.Position(3:4) = [800, 800];
        X = positions(:, 1);
        Y = positions(:, 2);
        
        % Convert direction angles from degrees to radians for vector components
        % vectors(:, :, 1) = DI (direction index), vectors(:, :, 2) = theta_pref (degrees)
        U1 = vectors(:, 1, 1) .* cos(vectors(:, 1, 2) * pi/180);  % x-component, first TF
        V1 = vectors(:, 1, 1) .* sin(vectors(:, 1, 2) * pi/180);  % y-component, first TF
        U2 = vectors(:, 2, 1) .* cos(vectors(:, 2, 2) * pi/180);  % x-component, second TF
        V2 = vectors(:, 2, 1) .* sin(vectors(:, 2, 2) * pi/180);  % y-component, second TF
        
        hold on;
        quiver(X, Y, U1, V1, 'LineWidth', 1.2, 'Color', 'b', 'DisplayName', sprintf('TF index %d (%.1f Hz)', idx_low, low_TF));
        quiver(X, Y, U2, V2, 'LineWidth', 1.2, 'Color', 'r', 'DisplayName', sprintf('TF index %d (%.1f Hz)', idx_high, high_TF));
        axis equal;
        xlabel('X position (pixels)');
        ylabel('Y position (pixels)');
        title('Direction Selectivity Map');
        legend('Location', 'best');
        hold off;
        
    catch ME
        warning('DIRMAP:MapGenerationFailed', 'Cannot generate map: %s', ME.message);
    end


end