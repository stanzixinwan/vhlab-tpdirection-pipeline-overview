function [pref_resp, theta_pref, TF, DI, SF_used] = dirVector_AdaptiveSF(tcDoc, options)
    %DIRVECTOR_ADAPTIVESF Calculate direction tuning using the BEST SF for EACH TF independently
    %
    %   Comparison with original: Instead of locking SF to the global maximum,
    %   this function finds the optimal spatial frequency for each temporal
    %   frequency step. This ensures high SNR for direction vectors at all TFs.
    %
    %   Additional Output:
    %       SF_used - The Spatial Frequency value used for each TF
    
        arguments
            tcDoc (1,1) {mustBeA(tcDoc,["ndi.document" "ndi.document.stimulus_tuningcurve"])}
            options.do_plot (1,1) logical = false
        end
    
        tc = tcDoc.document_properties.stimulus_tuningcurve;
        [temporalFrequencies, ~, ~] = unique(tc.independent_variable_value(:, 3), 'sorted');
    
        % Pre-allocate outputs
        TF = zeros(numel(temporalFrequencies), 1);
        theta_pref = TF;
        DI = TF;
        pref_resp = TF; 
        
        % Initialize figure if plotting is requested
        if options.do_plot
            figure('Position', [100, 100, 600, 800]);
        end
       
        for i = 1:numel(temporalFrequencies)
            current_TF = temporalFrequencies(i);
            
            % --- STEP 1: Find Best SF for THIS specific TF ---
            % Find all indices corresponding to the current TF
            tf_indices = find(tc.independent_variable_value(:, 3) == current_TF);
            
            if isempty(tf_indices)
                continue; 
            end
            
            % Extract responses for this TF subset
            tf_responses = tc.response_mean(tf_indices);
            
            % Find the index of the max response within this subset
            [~, max_local_idx] = max(tf_responses);
            
            % Map back to the original index to find the SF
            best_idx_global = tf_indices(max_local_idx);
            current_best_SF = tc.independent_variable_value(best_idx_global, 2);
            
            SF_used(i) = current_best_SF; % Record it
            
            % --- STEP 2: Collect Direction Tuning Curve at this Adaptive SF ---
            angles = [];
            responses = [];
            stderr = [];
            count = 0;
            
            for j = 1:numel(tc.response_mean)
                % Filter: Same TF AND Same Adaptive SF
                if tc.independent_variable_value(j, 3) == current_TF && ...
                   tc.independent_variable_value(j, 2) == current_best_SF
               
                    count = count + 1;
                    angles(count) = tc.independent_variable_value(j, 1);
                    responses(count) = tc.response_mean(j);
                    stderr(count) = tc.response_stderr(j);
                end
            end
            
            % --- Plotting & Calculation (Same as before) ---
            if options.do_plot
                subplot(numel(temporalFrequencies),1,i); 
                bar(angles,responses);
                hold on;
                errorbar(angles,responses, stderr, 'k', 'linestyle', 'none');
                xlim([-10 350]);
                % Update title to show the SF used
                txt = sprintf("TF = %.1f Hz (Best SF = %.2f cpd)", current_TF, current_best_SF);
                subtitle(txt);
                hold off;
            end
            
            % Check if we have enough data points
            if numel(angles) < 2
                pref_resp(i) = NaN;
                theta_pref(i) = NaN;
                DI(i) = NaN;
                TF(i) = current_TF;
                continue;
            end
            
            % Vector Sum Calculation
            [pref_resp(i), ~, theta_pref(i), ~] = ...
                vlt.neuro.vision.oridir.vector_direction_pref(angles, responses);
            
            % Direction Index
            DI(i) = 1 - compute_dircircularvariance(angles, responses);
            TF(i) = current_TF;
        end
    
    end