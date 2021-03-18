function [chan_table] = join_label_meta(label_table, chan_table)
    tot_rows = height(chan_table);
    label_table.sig_channels = string(label_table.sig_channels);
    joined = innerjoin(chan_table, label_table, 'LeftKeys', 'channel', ...
        'RightKeys', 'sig_channels', 'RightVariables', {'user_channels', 'recording_notes'});
    if isempty(joined)
        chan_table.user_channels = cell(tot_rows, 1);
        chan_table.recording_notes = strings(tot_rows, 1);
    else
        chan_table = joined;
    end
end