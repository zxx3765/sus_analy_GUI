function truncate_hil_multisine(input_file, output_file, time_start, time_end)
% TRUNCATE_HIL_MULTISINE Truncate HIL MultiSine data to specified time range
%
% Usage:
%   truncate_hil_multisine(input_file, output_file, time_start, time_end)
%   truncate_hil_multisine(input_file, output_file, time_end)  % start from 0

if nargin < 4
    time_end = time_start;
    time_start = 0;
end

fprintf('Loading: %s\n', input_file);
data = load(input_file);

% Auto-detect field name
field_names = fieldnames(data);
if isempty(field_names)
    error('No data found in file');
end
field_name = field_names{1};
fprintf('  Found field: %s\n', field_name);

s = data.(field_name);

fprintf('Processing X signals (inputs)...\n');
for i = 1:length(s.X)
    time_vec = s.X(i).Data;
    idx = time_vec >= time_start & time_vec <= time_end;
    n_keep = sum(idx);

    fprintf('  X(%d): %d -> %d samples (%.3f to %.3f s)\n', ...
        i, length(time_vec), n_keep, min(time_vec(idx)), max(time_vec(idx)));

    s.X(i).Data = time_vec(idx);
end

fprintf('Processing Y signals (outputs)...\n');
for i = 1:length(s.Y)
    x_idx = s.Y(i).XIndex;
    time_vec = data.(field_name).X(x_idx).Data;
    idx = time_vec >= time_start & time_vec <= time_end;

    s.Y(i).Data = s.Y(i).Data(idx);

    if mod(i, 5) == 0 || i == length(s.Y)
        fprintf('  Processed %d/%d Y signals\n', i, length(s.Y));
    end
end

MultiSine_data = s;
fprintf('Saving: %s\n', output_file);
save(output_file, 'MultiSine_data');

% Rename variable to match original field name
temp = load(output_file);
eval([field_name ' = temp.MultiSine_data;']);
save(output_file, field_name);

fprintf('Done!\n');

end
