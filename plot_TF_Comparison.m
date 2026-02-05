function plot_TF_Comparison(S, tcDoc_All, options)
%PLOT_TF_COMPARISON Compare Direction Maps at two different TFs side-by-side
%
%   Generates two interpolated color maps:
%   Left: Direction Map at Low TF (e.g., 1.6 Hz)
%   Right: Direction Map at High TF (e.g., 6.4 Hz)
%
%   This helps visualize if the pinwheel centers shift or if domains rotate.

    arguments
        S (1,1) {mustBeA(S,["ndi.session" "ndi.dataset"])}
        tcDoc_All (1,:)
        options.MinDI (1,1) double = 0.08 % Slightly relaxed threshold
        options.GridSize (1,1) double = 512
        options.LowTF (1,1) double = 1.6
        options.HighTF (1,1) double = 6.4
    end

    e = S.getelements('element.type','roi');
    
    % Containers for data
    x_coords = [];
    y_coords = [];
    z_tf_low = [];  % Complex vectors for Low TF
    z_tf_high = []; % Complex vectors for High TF
    
    fprintf('Extracting data for TF comparison...\n');

    for i = 1:numel(tcDoc_All)
        if isempty(tcDoc_All{i}), continue; end
        
        % Check significance (global)
        if sigDirSFTF(tcDoc_All{i}) > 0.05, continue; end
        
        [~, theta_pref, TF, DI, SF_used] = dirVector_AdaptiveSF(tcDoc_All{i});
        
        % Ensure we have enough TFs
        if numel(DI) < 4, continue; end

        low_TF = options.LowTF;
        high_TF = options.HighTF;

        idx_low = find(TF == low_TF);
        idx_high = find(TF == high_TF);
        
        % Define indices
        % Quality Control: Only use cells that are tuned in BOTH conditions
        % (Or at least one, depending on how strict you want to be)
        if DI(idx_low) < options.MinDI && DI(idx_high) < options.MinDI
            continue; 
        end
        
        [x, y] = cellname2position(S.path, e{i}.name);
        
        % Convert to complex numbers for interpolation
        % Z = DI * e^(i * theta)
        % This preserves both direction (angle) and tuning strength (magnitude)
        val_low  = DI(idx_low)  * exp(1i * deg2rad(theta_pref(idx_low)));
        val_high = DI(idx_high) * exp(1i * deg2rad(theta_pref(idx_high)));
        
        x_coords(end+1) = x;
        y_coords(end+1) = y;
        z_tf_low(end+1) = val_low;
        z_tf_high(end+1) = val_high;
    end

    if isempty(x_coords)
        warning('No cells passed criteria.');
        return;
    end

    %% Interpolation Setup
    pad = 20;
    min_x = min(x_coords); max_x = max(x_coords);
    min_y = min(y_coords); max_y = max(y_coords);
    
    [xq, yq] = meshgrid(linspace(min_x-pad, max_x+pad, options.GridSize), ...
                        linspace(min_y-pad, max_y+pad, options.GridSize));

    %% Generate Plot
    f = figure;
    f.Position(3:4) = [1200, 500]; % Wide figure
    
    % --- Left Plot: Low TF ---
    subplot(1, 2, 1);
    plotSingleMap(x_coords, y_coords, z_tf_low, xq, yq, sprintf('Low TF (%.1f Hz)', low_TF));
    
    % --- Right Plot: High TF ---
    subplot(1, 2, 2);
    plotSingleMap(x_coords, y_coords, z_tf_high, xq, yq, sprintf('High TF (%.1f Hz)', high_TF));
    
    % Add a main title
    sgtitle(sprintf('Shifting in Direction Selectivity across Temporal Frequencies (Low TF = %.1f Hz, High TF = %.1f Hz)', low_TF, high_TF));

end

function plotSingleMap(x, y, z_vals, xq, yq, title_str)
    % Helper function to interpolate and plot one map
    
    % Interpolate Real and Imag parts separately
    grid_real = griddata(x, y, real(z_vals), xq, yq, 'natural');
    grid_imag = griddata(x, y, imag(z_vals), xq, yq, 'natural');
    M = complex(grid_real, grid_imag);
    
    % Calculate Angle (Preferred Direction)
    Phase = angle(M); % -pi to pi
    
    % Mask out areas with no tuning strength (magnitude near 0)
    % This cleans up the background
    Magnitude = abs(M);
    start_mask = isnan(Phase);
    % Optional: mask areas where interpolated tuning strength is too weak
    % weak_mask = Magnitude < 0.05; 
    
    % Visualization
    imagesc(xq(1,:), yq(:,1), Phase);
    axis xy; axis equal;
    
    % Use FitzLab colormap or HSV
    try
        colormap(gca, fitzlabclut(256));
    catch
        colormap(gca, hsv(256));
    end
    
    % Alpha masking for prettier plot
    set(gca, 'Color', [0.5 0.5 0.5]); % Grey background
    alpha_map = ones(size(Phase));
    alpha_map(start_mask) = 0;
    image_obj = findobj(gca, 'Type', 'Image');
    set(image_obj, 'AlphaData', alpha_map);

    title(title_str);
    colorbar;
        % Labeling
        c = colorbar;
        c.Label.String = 'Direction Shift (Rad)';
        c.Ticks = [-pi, -pi/2, 0, pi/2, pi];
        c.TickLabels = {'-\pi (Opposite)', '-\pi/2', '0 (No Shift)', '+\pi/2', '+\pi'};
    clim([-pi pi]); % Lock color scale
end