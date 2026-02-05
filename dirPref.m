function dirPref_TF = dirPref(tcDoc)
%DIRPREF Calculate direction preference for each temporal frequency
%
%   DIRPREF_TF = DIRPREF(TCDOC)
%
%   Calculates preferred direction, orientation, and response strength
%   for each temporal frequency. Plots tuning curves for visualization.
%
%   Input:
%       tcDoc - NDI document containing stimulus tuning curve data
%
%   Output:
%       dirPref_TF - Matrix [numTF x 5] with columns:
%                    [pref_resp, null_resp, dir_pref, ori_pref, TF]
    tc = tcDoc.document_properties.stimulus_tuningcurve;

    [temporalFrequencies,~,~] = unique(tc.independent_variable_value(:,3),'sorted');

    dirPref_TF = nan(numel(temporalFrequencies), 5);
    figure('Position', [100, 100, 600, 800]);
    
    for i = 1:numel(temporalFrequencies)
        angles = [];
        responses = [];
        count = 0;
        for j = 1:numel(tc.response_mean)
            if tc.independent_variable_value(j,3) == temporalFrequencies(i)
                count = count + 1;
                angles(count) = tc.independent_variable_value(j,1);
                responses(count) = tc.response_mean(j);
                stderr(count) = tc.response_stderr(j);
            end
        end
        
        subplot(numel(temporalFrequencies),1,i);
        bar(angles,responses);
        errorbar(angles,responses, stderr);
        txt = ("TF = " + num2str(temporalFrequencies(i)));
        subtitle(txt);
        [PREF_RESP, NULL_RESP, DIR_PREF, ORI_PREF] = ...
            vlt.neuro.vision.oridir.vector_direction_pref(angles, responses);
        dirPref_TF(i, :) = [PREF_RESP NULL_RESP DIR_PREF ORI_PREF temporalFrequencies(i)];
    end

end