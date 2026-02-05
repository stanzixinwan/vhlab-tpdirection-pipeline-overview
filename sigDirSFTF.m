function p_anova1 = sigDirSFTF(tcDoc)
% SIGDIRSFTF - Computes P values for real responses
%   p_anova1 = a single P value of ANOVA: individual responses matrix

    tc = tcDoc.document_properties.stimulus_tuningcurve;
    responses = [tc.individual_responses_real tc.control_individual_responses_real(:,1)];
    p_anova1 = anova1(responses,'','off');

end
