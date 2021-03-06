function [] = plx_spike_parser(parsed_path, failed_path, raw_file, config, label_table)
    %% Get filename info
    [~, filename, ~] = fileparts(raw_file);
    filename_meta = get_filename_info(filename);

    total_trials = config.total_trials; total_events = config.total_events;
    trial_lower_bound = config.trial_lower_bound; event_map = config.event_map;
    is_non_strobed_and_strobed = config.is_non_strobed_and_strobed;
    %% Check event_map is set properly
    if is_non_strobed_and_strobed
        if isempty(event_map) || (~iscell(event_map) && all(isnan(event_map)))
            error('Must have mapping array for events when is_non_strobed_and_strobed is set to true');
        end
        if iscell(event_map)
            event_map = event_map{:};
        end
    end

    % Take the spike times and event times
    try
        try
            % tscounts and wfcounts dimension padded by extra column and row
            [tscounts, ~, evcounts, ~] = plx_info(raw_file,1);
        catch ME
            if (strcmpi(ME.identifier,'MATLAB:TooManyOutputs'))
                msg = ['Old version of plexon matlab sdk on path -- please remove and use the ', ...
                    'most recent version of the matlab offline sdk.'];
                causeException = MException('MATLAB:myCode:depricatedSoftware', msg);
                ME = addCause(ME,causeException);
            end
            rethrow(ME);
        end

        [tot_chans, tot_channels] = size(tscounts);
        [~, channel_names] = plx_chan_names(raw_file);

        subchan = {'i','a','b','c','d'};
        channel_map = [];
        for chan_i = 1:tot_chans - 1 % Start at 0 for unsorted 
            for channel_i = 1:tot_channels - 1
                if (tscounts(chan_i + 1, channel_i + 1) > 0) && chan_i < length(subchan)
                    %% get the timestamps for this channel and chan
                    [~, channel_timestamps] = plx_ts(raw_file, channel_i, chan_i);
                    % channel_names is a char array
                    current_channel = channel_names(channel_i, :);
                    split_channel = strsplit(current_channel, ' ');
                    current_channel = split_channel{1};
                    current_channel = deblank(current_channel);
                    current_subchan = subchan{chan_i + 1};
                    complete_channel_name = [current_channel, current_subchan];
                    channel_map = [channel_map; {complete_channel_name}, {channel_timestamps}];
                end
            end
        end

        [total_event_chan, event_channels] = plx_event_chanmap(raw_file);
        event_ts = [];
        event_map_counter = 1;
        for channel = 1:total_event_chan
            %% strobbed channel is always 257
            current_channel = event_channels(channel);
            if current_channel == 257 && evcounts(channel) > 0
                [~, event_timestamps, strobed_values] = plx_event_ts(raw_file, current_channel);
                event_ts = [strobed_values, event_timestamps];
            elseif evcounts(channel) > trial_lower_bound
                [total_timestamps, event_timestamps, ~] = plx_event_ts(raw_file, current_channel);
                if is_non_strobed_and_strobed
                    current_event = event_map(event_map_counter);
                    event_ts = [event_ts; repmat(current_event, [total_timestamps, 1]), event_timestamps];
                    event_map_counter = event_map_counter + 1;
                else
                    event_ts = [event_ts; repmat(current_channel, [total_timestamps, 1]), event_timestamps];
                end
            end
        end

        %% Removed repeated time stamps
        [events_rows, ~] = size(event_ts);
        count = 1;
        while events_rows > (total_trials * total_events)
            i = 1;
            while i <= (length(event_ts)-1)
                if ((event_ts(i, 2) + 2) > event_ts(i+1, 2))
                    event_ts(i + 1,:) = [];
                end
                i = i + 1;
            end
            [events_rows, ~] = size(event_ts);
            if count > 15
                warning('Potential infinite loop in %s, when trying to remove duplicate events.', ...
                    'Check to make sure that the total events is greater than the standard total', ...
                    'trials * total events');
                break;
            end
            count = count + 1;
        end

        event_ts = sortrows(event_ts, 2);
        [tot_trials, ~] = size(event_ts);
        event_i = 1:1:tot_trials;
        event_info = array2table([event_ts, event_i'], ...
            'VariableNames', {'event_labels', 'event_ts', 'event_indices'});
        event_strs = {};
        for event_i = 1:height(event_info)
            event = event_info.event_labels(event_i);
            event_label = ['event_', num2str(event)];
            event_strs = [event_strs; event_label];
        end
        event_info.event_labels = event_strs;
        channel_map = sortrows(channel_map, 1);
        channel_map = cell2table(channel_map, 'VariableNames', ["channel", "channel_data"]);

        %% enforce labels is all inclusive
        session_table = label_table(label_table.recording_session == filename_meta.session_num, :);
        enforce_labels(channel_map.channel, session_table.channel, filename_meta.session_num)

        %% Saves parsed files
        matfile = fullfile(parsed_path, [filename_meta.filename, '.mat']);
        save(matfile, 'event_info', 'channel_map', 'filename_meta');
        clear('event_ts', 'event_info', 'channel_map', 'filename_meta');
    catch ME
        handle_ME(ME, failed_path, filename_meta.filename);
    end
end