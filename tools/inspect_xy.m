% Inspect X and Y structures
input_file = 'D:\Project\SynologyDrive\analysis_GUI\HILData\HILData0525\MultiSine_0A.mat';

data = load(input_file);
s = data.MultiSine_0A;

fprintf('=== X structure (inputs) ===\n');
for i = 1:length(s.X)
    fprintf('\nX(%d):\n', i);
    if isstruct(s.X(i))
        fn = fieldnames(s.X(i));
        for j = 1:length(fn)
            val = s.X(i).(fn{j});
            fprintf('  %s: ', fn{j});
            if isnumeric(val)
                fprintf('size=%s, range=[%.4f, %.4f]\n', mat2str(size(val)), min(val(:)), max(val(:)));
            else
                fprintf('class=%s\n', class(val));
            end
        end
    end
end

fprintf('\n=== Y structure (outputs) ===\n');
for i = 1:min(3, length(s.Y))  % Show first 3 only
    fprintf('\nY(%d):\n', i);
    if isstruct(s.Y(i))
        fn = fieldnames(s.Y(i));
        for j = 1:length(fn)
            val = s.Y(i).(fn{j});
            fprintf('  %s: ', fn{j});
            if isnumeric(val)
                fprintf('size=%s, range=[%.4f, %.4f]\n', mat2str(size(val)), min(val(:)), max(val(:)));
            else
                fprintf('class=%s\n', class(val));
            end
        end
    end
end
fprintf('\n... (total %d Y signals)\n', length(s.Y));
