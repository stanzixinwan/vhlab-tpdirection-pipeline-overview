function [tuning_doc] = combinedTuningCurve(S, neuronElement, options)
%COMBINEDTUNINGCURVE Construct tuning curve from multiple stimulus presentations
%
%   TUNING_DOC = COMBINEDTUNINGCURVE(S, NEURONELEMENT, OPTIONS)
%
%   Constructs a tuning curve combining responses across direction, spatial
%   frequency, and temporal frequency. Aggregates responses from multiple
%   stimulus presentations and computes mean, standard deviation, and standard
%   error for each parameter combination.
%
%   Inputs:
%       S            - NDI session or dataset
%       neuronElement - NDI element (ROI) to analyze
%       options      - Structure with optional parameters:
%                      .direction - Field name for direction parameter (default: 'angle')
%                      .spatialFrequency - Field name for SF parameter (default: 'sFrequency')
%                      .temporalFrequency - Field name for TF parameter (default: 'tFrequency')
%
%   Output:
%       tuning_doc   - NDI document containing the tuning curve data

    arguments
        S (1,1) {mustBeA(S,["ndi.session" "ndi.dataset"])}
        neuronElement (1,1) ndi.element
        options.direction = 'angle';
        options.spatialFrequency = 'sFrequency';
        options.temporalFrequency = 'tFrequency';
    end

    independent_label = {'Direction'; 'Spatial Frequency'; 'Temporal Frequency'};
    response_units = 'Spikes/s';
    tuning_doc = [];

    % Search for stimulus responses for this neuron
    q1 = ndi.query('', 'isa', 'stimulus_response_scalar');
    q2 = ndi.query('', 'depends_on', 'element_id', neuronElement.id());

    % Find all stimulus responses for this neuron
    stimulus_response_docs = S.database_search(q1 & q2);
    
    % Find corresponding stimulus presentation documents
    stimulus_presentation_docs = {};
    control_stimulus_docs = {};
    for i=1:numel(stimulus_response_docs)
        q_stimulus_presentation = ndi.query('base.id','exact_string',...
            stimulus_response_docs{i}.dependency_value('stimulus_presentation_id'));
        stimulus_presentation_docs_here = S.database_search(q_stimulus_presentation);
        try
            stimulus_presentation_docs{i} = stimulus_presentation_docs_here{1};
        catch
            fprintf('Cannot find stimulus presentation doc for stimulus response %d\n', i);
            continue
        end
        q_controlstimids = ndi.query('','isa','control_stimulus_ids') & ...
            ndi.query('','depends_on','stimulus_presentation_id',stimulus_presentation_docs{i}.id());
        control_stim_docs_here = S.database_search(q_controlstimids);
        try
            control_stimulus_docs{i} = control_stim_docs_here{1};
        catch
            fprintf('Cannot find control stimulus doc for stimulus response %d\n', i);
            continue
        end
    end
    if isempty(stimulus_presentation_docs)
        disp ('Cannot find stimulus presentation docs')
        return
    end

    % Step 1: Extract all unique parameter values
    directions = [];
    spatialFrequencies = [];
    temporalFrequencies = [];
    for i=1:numel(stimulus_presentation_docs)
        for j=1:numel(stimulus_presentation_docs{i}.document_properties.stimulus_presentation.stimuli)
            params = stimulus_presentation_docs{i}.document_properties.stimulus_presentation.stimuli(j).parameters;
            if isfield(params,options.direction) && ...
               isfield(params, options.spatialFrequency) && ...
               isfield(params, options.temporalFrequency)
                directions(end+1) = getfield(params,options.direction);
                spatialFrequencies(end+1) = getfield(params,options.spatialFrequency);
                temporalFrequencies(end+1) = getfield(params,options.temporalFrequency);
            end
            
        end
    end
    % Get unique parameter values
    directions = unique(directions);
    spatialFrequencies = unique(spatialFrequencies);
    temporalFrequencies = unique(temporalFrequencies);

    % Step 2: Create tuning curve structure
    tuning_curve = vlt.data.emptystruct( ...
        'independent_variable_label','independent_variable_value','stimid', ...
        'response_mean','response_stddev','response_stderr', ...
        'individual_responses_real','individual_responses_imaginary', ...
        'stimulus_presentation_number','control_stimid', ...
        'control_response_mean','control_response_stddev','control_response_stderr', ...
        'control_individual_responses_real','control_individual_responses_imaginary', ...
        'response_units');

    tuning_curve(1).independent_variable_label = independent_label;
    tuning_curve.independent_variable_value = zeros(0,numel(independent_label));
    tuning_curve.response_units = response_units;
    
    % Step 3: Calculate responses for each parameter combination
    I = 1;  % Counter for parameter combinations
    for i = 1:numel(directions)
        for j = 1:numel(spatialFrequencies)
            for k = 1:numel(temporalFrequencies)
                match_found = false;
                for sp = 1:numel(stimulus_presentation_docs)
                    sr_doc = stimulus_response_docs{sp};
                    
                    % Search through all stimuli in this presentation
                    for n = 1:numel(stimulus_presentation_docs{sp}.document_properties.stimulus_presentation.stimuli)
                        params = stimulus_presentation_docs{sp}.document_properties.stimulus_presentation.stimuli(n).parameters;
                        
                        % Check if this stimulus has the required parameters
                        if isfield(params, options.direction) && ...
                           isfield(params, options.spatialFrequency) && ...
                           isfield(params, options.temporalFrequency)
                            
                            % Extract parameter values
                            dir_val = getfield(params, options.direction);
                            sf_val = getfield(params, options.spatialFrequency);
                            tf_val = getfield(params, options.temporalFrequency);
                            
                            % Check if parameters match current combination
                            if dir_val == directions(i) && ...
                               sf_val == spatialFrequencies(j) && ...
                               tf_val == temporalFrequencies(k)
                                
                                % Store parameter combination
                                tuning_curve.independent_variable_value(I, :) = ...
                                    [directions(i), spatialFrequencies(j), temporalFrequencies(k)];
                                
                                % Find stimulus presentation indices
                                stim_indexes = find(stimulus_presentation_docs{sp}.document_properties.stimulus_presentation.presentation_order == n);
                                if isempty(stim_indexes)
                                    fprintf('Warning: No presentation found for stimid %d in stimulus presentation %d\n', n, sp);
                                    continue;
                                end
                                
                                tuning_curve.stimid(I, 1) = n;
                                tuning_curve.stimulus_presentation_number{I} = stim_indexes;
                                
                                % Store individual responses (real and imaginary components)
                                tuning_curve.individual_responses_real{I} = ...
                                    sr_doc.document_properties.stimulus_response_scalar.responses.response_real(stim_indexes);
                                tuning_curve.individual_responses_imaginary{I} = ...
                                    sr_doc.document_properties.stimulus_response_scalar.responses.response_imaginary(stim_indexes);
                                tuning_curve.control_individual_responses_real{I} = ...
                                    sr_doc.document_properties.stimulus_response_scalar.responses.control_response_real(stim_indexes);
                                tuning_curve.control_individual_responses_imaginary{I} = ...
                                    sr_doc.document_properties.stimulus_response_scalar.responses.control_response_imaginary(stim_indexes);
                                
                                % Combine real and imaginary components into complex numbers
                                all_responses = tuning_curve.individual_responses_real{I} + ...
                                    sqrt(-1) * tuning_curve.individual_responses_imaginary{I};
                                all_control_responses = tuning_curve.control_individual_responses_real{I} + ...
                                    sqrt(-1) * tuning_curve.control_individual_responses_imaginary{I};
                                
                                % Compute statistics
                                tuning_curve.response_mean(I, 1) = mean(all_responses);
                                tuning_curve.response_stddev(I, 1) = std(all_responses);
                                tuning_curve.response_stderr(I, 1) = std(all_responses) / sqrt(numel(all_responses));
                                tuning_curve.control_response_mean(I, 1) = mean(all_control_responses);
                                tuning_curve.control_response_stddev(I, 1) = std(all_control_responses);
                                tuning_curve.control_response_stderr(I, 1) = std(all_control_responses) / sqrt(numel(all_control_responses));
                                
                                match_found = true;
                                break;  % Found match, move to next parameter combination
                            end
                        end
                    end
                    if match_found
                        break;  % Found match, move to next parameter combination
                    end
                end
                if match_found
                    I = I + 1;  % Only increment if we found a match
                end
            end
        end
    end
  
    % Convert cell arrays to matrices for easier manipulation
    tuning_curve.individual_responses_real = vlt.data.cellarray2mat(tuning_curve.individual_responses_real);
    tuning_curve.individual_responses_imaginary = vlt.data.cellarray2mat(tuning_curve.individual_responses_imaginary);
    tuning_curve.control_individual_responses_real = vlt.data.cellarray2mat(tuning_curve.control_individual_responses_real);
    tuning_curve.control_individual_responses_imaginary = vlt.data.cellarray2mat(tuning_curve.control_individual_responses_imaginary);
    tuning_curve.stimulus_presentation_number = vlt.data.cellarray2mat(tuning_curve.stimulus_presentation_number);

    tuning_doc = ndi.document('stimulus_tuningcurve','stimulus_tuningcurve',tuning_curve) + S.newdocument();
    if ~isempty(stimulus_response_docs)
        tuning_doc = tuning_doc.set_dependency_value('stimulus_response_scalar_id',stimulus_response_docs{1}.id());
    end
    tuning_doc = tuning_doc.set_dependency_value('element_id',neuronElement.id());

end


