function [pref_resp, theta_pref, TF, DI, SF_used] = dirVector_FixedSF(tcDoc, options)
%DIRVECTOR_FIXEDSF Calculate preferred direction and response strength for each temporal frequency
%
%   [PREF_RESP, THETA_PREF, TF, DI, SF_used] = DIRVECTOR_FIXEDSF(TCDOC, OPTIONS)
%
%   Computes direction tuning using responses at a fixed spatial frequency
%   specified by the user. For each temporal frequency, returns preferred
%   direction, response strength, and direction index.
%
%   Inputs:
%       tcDoc     - NDI document containing stimulus tuning curve data
%       options   - Structure with optional parameters:
%                   .do_plot - Logical flag to plot tuning curves (default: false)
%
%   Outputs:
%       pref_resp - Preferred response strength for each temporal frequency
%       theta_pref - Preferred direction (degrees) for each temporal frequency
%       TF        - Temporal frequencies (Hz)
%       DI        - Direction index (1 - circular variance), range [0,1]
%                   where 0 = no direction selectivity, 1 = perfect selectivity
%       SF_used   - The fixed Spatial Frequency value used for each temporal frequency
    arguments
        tcDoc (1,1) {mustBeA(tcDoc,["ndi.document" "ndi.document.stimulus_tuningcurve"])}
        options.do_plot (1,1) logical = false
        options.FixedSF (1,1) double = 0.15
    end

    tc = tcDoc.document_properties.stimulus_tuningcurve;
    [temporalFrequencies, ~, ~] = unique(tc.independent_variable_value(:, 3), 'sorted');

    TF = zeros(numel(temporalFrequencies), 1);
    theta_pref = TF;
    DI = TF;
    pref_resp = TF; 
    SF_used = options.FixedSF;
    % Initialize figure if plotting is requested
    if options.do_plot
        figure('Position', [100, 100, 600, 800]);
    end
   
    for i = 1:numel(temporalFrequencies)
        % Collect direction angles and responses at best SF for this temporal frequency
        angles = [];
        responses = [];
        stderr = [];
        count = 0;
        for j = 1:numel(tc.response_mean)
            % Filter: same TF AND same SF (best SF)
            if tc.independent_variable_value(j, 3) == temporalFrequencies(i) && ...
               tc.independent_variable_value(j, 2) == options.FixedSF
                count = count + 1;
                angles(count) = tc.independent_variable_value(j, 1);
                responses(count) = tc.response_mean(j);
                stderr(count) = tc.response_stderr(j);
            end
        end
        
        if options.do_plot
            subplot(numel(temporalFrequencies),1,i); 
            bar(angles,responses);
            errorbar(angles,responses, stderr);
            xlim([-10 350]);
            txt = ("TF = " + num2str(temporalFrequencies(i)));
            subtitle(txt);
        end
        
        % Check if we have enough data points for direction preference calculation
        if numel(angles) < 2
            pref_resp(i) = NaN;
            theta_pref(i) = NaN;
            DI(i) = NaN;
            TF(i) = temporalFrequencies(i);
            continue;
        end
        
        % Calculate preferred direction and response using vector methods
        [pref_resp(i), ~, theta_pref(i), ~] = ...
            vlt.neuro.vision.oridir.vector_direction_pref(angles, responses);
        
        % Calculate direction index: 1 - circular variance
        DI(i) = 1 - compute_dircircularvariance(angles, responses);
        TF(i) = temporalFrequencies(i);
    end

end