function [out] = prealloc_table(headers, tbl_size)
    out = table('Size', tbl_size, ...
        'VariableNames', headers(:, 1), ...
        'VariableTypes', headers(:, 2));
end