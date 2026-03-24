% Define which runs you have
runs = {'01', '02', '03'}; % Add more if needed

% Base directory of events files
base_dir = 'C:\Users\ahmed\Downloads\ds000005_R2.0.0\ds005_R2.0.0\sub-02\func';

% Loop over runs
for k = 1:length(runs)
    run_num = runs{k};

    % Construct full path to TSV file
    tsv_file = fullfile(base_dir, sprintf('sub-02_task-mixedgamblestask_run-%s_events.tsv', run_num));

    if ~exist(tsv_file, 'file')
        warning('File not found: %s — skipping.', tsv_file);
        continue;
    end

    % Load the TSV file
    try
        data = readtable(tsv_file, ...
            'Delimiter', '\t', 'VariableNamingRule', 'preserve', 'FileType', 'text');
    catch ME
        warning('Could not load TSV in run %s: %s', run_num, ME.message);
        continue;
    end

    % Display column names and some sample data
    fprintf('\nRun %s — Column names:\n', run_num);
    disp(data.Properties.VariableNames);
    disp('First 5 rows:');
    disp(data(1:5, :));

    % Confirm numeric columns and show summary
    fprintf('Gain summary: min=%.2f, max=%.2f, mean=%.2f\n', ...
        min(data.gain, [], 'omitnan'), max(data.gain, [], 'omitnan'), mean(data.gain, 'omitnan'));
    fprintf('Loss summary: min=%.2f, max=%.2f, mean=%.2f\n', ...
        min(data.loss, [], 'omitnan'), max(data.loss, [], 'omitnan'), mean(data.loss, 'omitnan'));

    % Initialize trial_type as "Neutral" by default
    data.trial_type = repmat("Neutral", height(data), 1);

    % Define thresholds
    GAIN_THRESHOLD = 30; % Adjust based on your experiment
    LOSS_THRESHOLD = 10; % Adjust based on your experiment

    % Classify trials
    for i = 1:height(data)
        gain_val = double(data.gain(i));
        loss_val = double(data.loss(i));

        if gain_val >= GAIN_THRESHOLD && loss_val >= LOSS_THRESHOLD
            data.trial_type(i) = "Mixed";
        elseif gain_val >= GAIN_THRESHOLD
            data.trial_type(i) = "Gain";
        elseif loss_val >= LOSS_THRESHOLD
            data.trial_type(i) = "Loss";
        else
            data.trial_type(i) = "Neutral";
        end

        % Debug: Print classification for each trial
        fprintf('Trial %d: gain = %.2f, loss = %.2f -> %s\n', ...
            i, gain_val, loss_val, data.trial_type(i));
    end

    % Extract unique conditions
    unique_conditions = unique(data.trial_type);
    names = cellstr(unique_conditions); % Convert to cell array

    % Group onsets and durations
    onsets = cell(length(names), 1);
    durations = cell(length(names), 1);

    for i = 1:length(names)
        idx = (data.trial_type == names{i});
        onsets{i} = double(data.onset(idx))';     % Convert to numeric vector
        durations{i} = double(data.duration(idx))'; % Same here
    end

    % Remove empty conditions
    valid_idx = cellfun(@(x) ~isempty(x), onsets);
    names = names(valid_idx);
    onsets = onsets(valid_idx);
    durations = durations(valid_idx);

    % Verify we found at least one condition
    if isempty(names)
        error('No valid conditions found in run %s.', run_num);
    end

    % Display final result
    fprintf('\nRun %s - Final Conditions:\n', run_num);
    for i = 1:length(names)
        fprintf('Condition %d (%s): %d trials\n', i, names{i}, length(onsets{i}));
    end

    % Save to .mat file
    mat_file = fullfile(base_dir, sprintf('bold_run%s.mat', run_num));
    save(mat_file, 'names', 'onsets', 'durations');
    fprintf('Saved: %s\n', mat_file);
end

disp('All runs processed.');
