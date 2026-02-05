function dirShiftMap_Interpolated(S, tcDoc_All, options)
%DIRSHIFTMAP_INTERPOLATED Create a continuous map of direction shift
%
%   Generates a spatial heatmap showing how direction preference shifts 
%   between low and high TF. Uses complex-value interpolation.
%
%   Process:
%   1. Calculate shift vector for each cell (using complex division/rotation).
%   2. Interpolate these scattered vectors onto a regular grid (mesh).
%   3. Color-code the angle of the interpolated vectors (The "Shift").

    arguments
        S (1,1) {mustBeA(S,["ndi.session" "ndi.dataset"])}
        tcDoc_All (1,:)
        options.MinDI (1,1) double = 0.1
        options.GridSize (1,1) double = 512 % Resolution of the output image
        options.LowTF (1,1) double = 1.6
        options.HighTF (1,1) double = 6.4

    end

    e = S.getelements('element.type','roi');
    
    % Data containers
    x_coords = [];
    y_coords = [];
    shift_vectors = []; % Complex numbers representing the shift
    
    fprintf('Extracting shift data...\n');

    for i = 1:numel(tcDoc_All)
        if isempty(tcDoc_All{i}), continue; end
        if sigDirSFTF(tcDoc_All{i}) > 0.05, continue; end
        
        [~, theta_pref, TF, DI, SF_used] = dirVector_AdaptiveSF(tcDoc_All{i});
        
        if numel(DI) < 4, continue; end
        
        low_TF = options.LowTF;
        high_TF = options.HighTF;

        idx_low = find(TF == low_TF);
        idx_high = find(TF == high_TF);
        
        
        if DI(idx_low) < options.MinDI || DI(idx_high) < options.MinDI, continue; end
        
        % Get position
        [x, y] = cellname2position(S.path, e{i}.name);
        
        % Magnitude of z_shift = DI_high (weighted by how strong the tuning is)
        
        ang_low = deg2rad(theta_pref(idx_low));
        ang_high = deg2rad(theta_pref(idx_high));
        
        % Rotation factor to bring Ref to 0 (Pure alignment)
        rotation_factor = exp(-1i * ang_low);
        
        % The "Shift Vector": The high TF vector, rotated by the low TF baseline
        % If there is no shift, this points to 0 degrees (Right).
        z_shift_cell = (DI(idx_high) * exp(1i * ang_high)) * rotation_factor;
        
        x_coords(end+1) = x;
        y_coords(end+1) = y;
        shift_vectors(end+1) = z_shift_cell;
    end

    if isempty(x_coords)
        warning('No cells passed criteria.');
        return;
    end

    % 2. Interpolation (Creating the Matrix "M")
    fprintf('Interpolating map...\n');
    
    % Define the grid (mesh)
    min_x = min(x_coords); max_x = max(x_coords);
    min_y = min(y_coords); max_y = max(y_coords);
    
    % Add some padding
    pad = 20;
    [xq, yq] = meshgrid(linspace(min_x-pad, max_x+pad, options.GridSize), ...
                        linspace(min_y-pad, max_y+pad, options.GridSize));
    
    % Interpolate Real and Imaginary parts separately
    grid_real = griddata(x_coords, y_coords, real(shift_vectors), xq, yq, 'natural');
    grid_imag = griddata(x_coords, y_coords, imag(shift_vectors), xq, yq, 'natural');
    
    % Recombine into Complex Matrix M
    M = complex(grid_real, grid_imag);

    % 3. Visualization
    
    f = figure;
    f.Position(3:4) = [800, 700];
    
    % Calculate Phase (The Shift Angle)
    Phase = angle(M); % Result is in radians (-pi to pi)
    
    % Rescale to 0-1 for visualization logic, then to index
    Phase_rescaled = (Phase + pi) / (2*pi); % Now 0 to 1
    
    % Display
    % We use 'AlphaData' to hide NaN values (areas outside the cell drawing)
    im = imagesc(xq(1,:), yq(:,1), Phase); 
    set(im, 'AlphaData', ~isnan(Phase)); 
    axis xy; axis equal;
    
    % Colormap Setup
    try
        % Try using the lab's specific colormap if available
        cmap = fitzlabclut(256); 
    catch
        % Fallback: HSV is the standard substitute for circular phase data
        % (Red at start, Red at end, continuous cycle)
        warning('fitzlabclut not found, using hsv colormap.');
        cmap = hsv(256);
    end
    
    colormap(cmap);
    colorbar;
    
    % Labeling
    c = colorbar;
    c.Label.String = 'Direction Shift (Rad)';
    c.Ticks = [-pi, -pi/2, 0, pi/2, pi];
    c.TickLabels = {'-\pi (Opposite)', '-\pi/2', '0 (No Shift)', '+\pi/2', '+\pi'};
    
    title('Spatial Map of TF-Dependent Direction Shift');
    xlabel('X Position');
    ylabel('Y Position');
    
    % Overlay the original cell points as black dots for reference
    hold on;
    plot(x_coords, y_coords, 'k.', 'MarkerSize', 4, 'DisplayName', 'ROIs');
    legend('Location', 'best');
    
end