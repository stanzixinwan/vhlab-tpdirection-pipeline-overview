function dirMap_shift(S, tcDoc_All, options)
    %DIRMAP_SHIFT Display direction selectivity map with shifted vectors
    %
    %   DIRMAP_SHIFT(S, TCDOC_ALL)
    %
    %   Creates a spatial map where the preferred direction at the reference 
    %   temporal frequency (TF index 2, Blue) is shifted to be 0 degrees (East).
    %   The comparison frequency (TF index 4/last, Red) is shifted by the same
    %   amount to show the relative shift.
    %
    %   Optional Name-Value Pairs:
    %       'MinDI', value - Minimum Direction Index to include a cell (default: 0.0)
    %                        Helps filter out noisy cells with weak tuning.
    %       'ShowSummary', logical - Plot a summary polar histogram (default: false)
    
        arguments
            S (1,1) {mustBeA(S,["ndi.session" "ndi.dataset"])}
            tcDoc_All (1,:)
            options.MinDI (1,1) double = 0.0
            options.ShowSummary (1,1) logical = false
            options.LowTF (1,1) double = 1.6
            options.HighTF (1,1) double = 6.4
            options.FixedSF (1,1) double = -1
        end
    
        e = S.getelements('element.type','roi');
    
        % Pre-allocate arrays for speed (estimating size, will truncate later)
        max_cells = numel(tcDoc_All);
        positions = zeros(max_cells, 2);
        vectors_aligned = zeros(max_cells, 2, 2); % [cell, TF_idx, component(real/imag)]
        valid_indices = false(max_cells, 1);
        
        count = 0;
        
        fprintf('Processing %d cells...\n', max_cells);
    
        for i = 1:max_cells
            % Skip cells with empty tuning documents
            if isempty(tcDoc_All{i})
                continue
            end
            
            % 1. Significance Test
            % Only plot cells with significant direction selectivity
            p_anova1 = sigDirSFTF(tcDoc_All{i});
            if p_anova1 > 0.05
                continue
            end
            
            % 2. Get Raw Vectors
            % Get preferred direction and direction index for each temporal frequency
            if options.FixedSF == -1
                [~, theta_pref, TF, DI, SF_used] = dirVector(tcDoc_All{i});
            else
                [~, theta_pref, TF, DI, SF_used] = dirVector_FixedSF(tcDoc_All{i}, 'FixedSF', options.FixedSF);
            end
            fprintf('SF used: %f\n', SF_used);
            
            % Check if we have enough temporal frequencies
            if numel(DI) < 2 || numel(theta_pref) < 2
                continue
            end
            
            % 3. Select Temporal Frequencies
            % TF_ref = Blue (Reference), TF_comp = Red (Comparison)
            low_TF = options.LowTF;
            high_TF = options.HighTF;

            idx_low = find(TF == low_TF);
            idx_high = find(TF == high_TF);

            % Only require valid DI at the two TFs we use (low_TF and high_TF).
            % Do not skip the whole cell if other TFs have NaN (e.g. missing (TF, best_SF) data).
            if isempty(idx_low) || isempty(idx_high)
                continue
            end
            if isnan(DI(idx_low)) || isnan(DI(idx_high))
                continue
            end

            % 4. Quality Control (New Feature)
            % Skip if the low TF DI is too weak (direction is unreliable) or the high TF DI is too weak
            if DI(idx_low) < options.MinDI
                continue 
            end
    
            % Get cell position
            [x, y] = cellname2position(S.path, e{i}.name);
            
            % 5. Complex Alignment Logic (Steve's Whiteboard Implementation)
            % Convert to radians
            ang_low = deg2rad(theta_pref(idx_low));
            ang_high = deg2rad(theta_pref(idx_high));
            
            % Create complex vectors: Z = DI * e^(i*theta)
            z_low = DI(idx_low) * exp(1i * ang_low);
            z_high = DI(idx_high) * exp(1i * ang_high);
            
            % Calculate Rotation Factor R = e^(-i * theta_ref)
            % Multiplying by this rotates the reference angle to 0
            rotation_factor = exp(-1i * ang_low);
            
            % Apply Rotation
            z_low_aligned = z_low * rotation_factor;   % Imaginary part should be ~0
            z_high_aligned = z_high * rotation_factor; % Rotated by same amount
            
            % Store Data
            count = count + 1;
            positions(count, :) = [x, y];
            
            % Store Real (U) and Imag (V) components
            % Layer 1: Blue (Reference), Layer 2: Red (Comparison)
            vectors_aligned(count, 1, :) = [real(z_low_aligned), imag(z_low_aligned)];
            vectors_aligned(count, 2, :) = [real(z_high_aligned), imag(z_high_aligned)];
            
            valid_indices(count) = true;
        end
        
        % Truncate arrays to actual count
        positions = positions(1:count, :);
        vectors_aligned = vectors_aligned(1:count, :, :);
    
        if count == 0
            warning('No significant cells found passing criteria.');
            return;
        end
    
        %% Visualization 1: Spatial Map (Aligned)
        try
            f = figure('Name', 'Aligned Direction Map', 'Units', 'normalized', 'Position', [0.3 0.1 0.4 0.7]);

            X = positions(:, 1);
            Y = positions(:, 2);
            
            % Extract components
            % Blue vectors (Ref) - Should be all pointing East
            U1 = vectors_aligned(:, 1, 1);
            V1 = vectors_aligned(:, 1, 2);

            % Red vectors (Comp) - Shifted relative to Blue
            U2 = vectors_aligned(:, 2, 1);
            V2 = vectors_aligned(:, 2, 2);

            hold on;
            % Plot Blue arrows (Reference)
            q1 = quiver(X, Y, U1, V1, 'LineWidth', 1, 'Color', [0.8 0.8 0.8], 'MaxHeadSize', 1);

            offset_y = 1; 
            
            % Plot Red arrows (Comparison)
            q2 = quiver(X, Y - offset_y, U2, V2, 'LineWidth', 1.5, 'Color', [0 0.4 0.15], 'MaxHeadSize', 1);
            
            axis equal;
            grid on;
            xlabel('X position (pixels)');
            ylabel('Y position (pixels)');
            title(sprintf('Aligned Direction Map (n=%d)\nBlue rotated to 0 degrees, Red relative shift', count));
            
            legend([q1, q2], ...
                sprintf('TF index %d (%.1f Hz)', idx_low, low_TF), ...
                sprintf('TF index %d (%.1f Hz)', idx_high, high_TF), ...
                'Location', 'best');
                
            set(gca, 'Color', [0.95 0.95 0.95]); % Light gray background
            hold off;
            
        catch ME
            warning('DIRMAP_ALIGNED:MapFailed', 'Cannot generate map: %s', ME.message);
        end
    
        %% Visualization 2: Summary Polar Histogram
        if options.ShowSummary
            try
                f2 = figure;
                f2.Position(3:4) = [500, 400];
                
                % Calculate the relative angle of the red vectors
                % Since Blue is at 0, the angle of Red is the difference (Delta Theta)
                z_red_vectors = complex(vectors_aligned(:, 2, 1), vectors_aligned(:, 2, 2));
                relative_angles = angle(z_red_vectors); % Returns radians between -pi and pi
                
                % Polar Histogram
                p = polarhistogram(relative_angles, 20);
                p.FaceColor = 'r';
                p.FaceAlpha = 0.6;
                
                mean_angle = angle(mean(z_red_vectors));
                title({ ...
                    'Population Shift Summary', ...
                    'Angle of Red vector (relative to Blue)', ...
                    sprintf('Mean Shift: %.1f degrees', rad2deg(mean_angle)) ...
                });
                
                % Add circular mean line (optional)
                hold on;
                polarplot([0 mean_angle], [0 max(p.Values)], 'k-', 'LineWidth', 2);
                
                
            catch ME
                warning('DIRMAP_ALIGNED:SummaryFailed', 'Cannot generate summary: %s', ME.message);
            end
        end
    
    end