function tcDoc_covaryingSFTF = getcovaryingSFTF(tcDoc_All)

    arguments
        tcDoc_All (1,:)
    end

    tcDoc_covaryingSFTF = struct( ...
        'cell_id', {}, ...
        'num_temporal_frequencies', {}, ...
        'temporal_frequencies', {});

    for i = 1:numel(tcDoc_All)
        % Skip cells with empty tuning documents
        if isempty(tcDoc_All{i})
            continue
        end

        tc = tcDoc_All{i}.document_properties.stimulus_tuningcurve;
        [temporalFrequencies, ~, ~] = unique(tc.independent_variable_value(:, 3), 'sorted');


        if numel(temporalFrequencies) <= 1
            continue;
        end

        tcDoc_covaryingSFTF(end+1).cell_id = i; %#ok<AGROW>
        tcDoc_covaryingSFTF(end).num_temporal_frequencies = numel(temporalFrequencies);
        tcDoc_covaryingSFTF(end).temporal_frequencies = temporalFrequencies;
    end
    start_index = 1;
    for i = 1:numel(tcDoc_covaryingSFTF)-1
        if numel(tcDoc_covaryingSFTF(i).temporal_frequencies) == numel(tcDoc_covaryingSFTF(i+1).temporal_frequencies)
            if isequal(tcDoc_covaryingSFTF(i).temporal_frequencies, tcDoc_covaryingSFTF(i+1).temporal_frequencies)
                continue;
            end
        end
        end_index = i;
        fprintf('There are %d TF values:\n', tcDoc_covaryingSFTF(i).num_temporal_frequencies);
        disp(tcDoc_covaryingSFTF(i).temporal_frequencies);
        fprintf('from tcDoc#%d to tcDoc#%d\n', ...
            tcDoc_covaryingSFTF(start_index).cell_id, ...
            tcDoc_covaryingSFTF(end_index).cell_id);
        start_index = i+1;
    end
    fprintf('There are %d TF values:\n', tcDoc_covaryingSFTF(i).num_temporal_frequencies);
    disp(tcDoc_covaryingSFTF(i).temporal_frequencies);
    fprintf('from tcDoc#%d to tcDoc#%d\n', ...
        tcDoc_covaryingSFTF(start_index).cell_id, ...
        tcDoc_covaryingSFTF(numel(tcDoc_covaryingSFTF)).cell_id);
end