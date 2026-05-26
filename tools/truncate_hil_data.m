function truncate_hil_data(input_file, output_file, time_limit)
% TRUNCATE_HIL_DATA Truncate HIL data to specified time limit
%
% Usage:
%   truncate_hil_data(input_file, output_file, time_limit)
%
% Example:
%   truncate_hil_data('MultiSine_0A.mat', 'MultiSine_0A_truncated.mat', 4)

if nargin < 3
    time_limit = 4; % Default to 4 seconds
end

% Load the data
fprintf('Loading data from: %s\n', input_file);
data = load(input_file);

% Get all variable names
var_names = fieldnames(data);
fprintf('Found %d variables\n', length(var_names));

% Find time vector
time_var = [];
for i = 1:length(var_names)
    if strcmpi(var_names{i}, 'time') || strcmpi(var_names{i}, 't')
        time_var = var_names{i};
        break;
    end
end

if isempty(time_var)
    error('Could not find time vector (looking for "time" or "t")');
end

time = data.(time_var);
fprintf('Time vector: %s, length = %d, range = [%.3f, %.3f]\n', ...
    time_var, length(time), min(time), max(time));

% Find indices for first 4 seconds
idx = time <= time_limit;
n_keep = sum(idx);
fprintf('Keeping first %d samples (time <= %.1f s)\n', n_keep, time_limit);

% Truncate all variables
truncated_data = struct();
for i = 1:length(var_names)
    var = data.(var_names{i});

    % Check if it's a time series (first dimension matches time length)
    if size(var, 1) == length(time)
        truncated_data.(var_names{i}) = var(idx, :);
        fprintf('  Truncated %s: %s -> %s\n', var_names{i}, ...
            mat2str(size(var)), mat2str(size(truncated_data.(var_names{i}))));
    else
        % Keep non-time-series variables as-is
        truncated_data.(var_names{i}) = var;
        fprintf('  Kept %s unchanged: %s\n', var_names{i}, mat2str(size(var)));
    end
end

% Save truncated data
fprintf('Saving to: %s\n', output_file);
save(output_file, '-struct', 'truncated_data');
fprintf('Done!\n');

end
