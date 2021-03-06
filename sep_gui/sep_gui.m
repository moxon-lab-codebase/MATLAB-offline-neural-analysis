% SEP_GUI MATLAB code for sep_gui.fig
function varargout = sep_gui(varargin)
    %      SEP_GUI, by itself, creates a new SEP_GUI or raises the existing
    %      singleton*.
    %
    %      H = SEP_GUI returns the handle to a new SEP_GUI or the handle to
    %      the existing singleton*.
    %
    %      SEP_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
    %      function named CALLBACK in SEP_GUI.M with the given input arguments.
    %
    %      SEP_GUI('Property','Value',...) creates a new SEP_GUI or raises the
    %      existing singleton*.  Starting from the left, property value pairs are
    %      applied to the GUI before sep_gui_OpeningFcn gets called.  An
    %      unrecognized property name or invalid value makes property application
    %      stop.  All inputs are passed to sep_gui_OpeningFcn via varargin.
    %
    %      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
    %      instance to run (singleton)".
    %
    % See also: GUIDE, GUIDATA, GUIHANDLES

    % Edit the above text to modify the response to help sep_gui

    % Last Modified by GUIDE v2.5 06-Jul-2020 17:03:01

    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                    'gui_Singleton',  gui_Singleton, ...
                    'gui_OpeningFcn', @sep_gui_OpeningFcn, ...
                    'gui_OutputFcn',  @sep_gui_OutputFcn, ...
                    'gui_LayoutFcn',  [] , ...
                    'gui_Callback',   []);
    if nargin && ischar(varargin{1})
        gui_State.gui_Callback = str2func(varargin{1});
    end

    if nargout
        [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
    else
        gui_mainfcn(gui_State, varargin{:});
    end
    % End initialization code - DO NOT EDIT

% --- Executes just before sep_gui is made visible.
function sep_gui_OpeningFcn(hObject, eventdata, handles, varargin)
    % Choose default command line output for sep_gui
    handles.output = hObject;
    %load the file and save struct to handles.sep_data
    [file_name, original_path] = uigetfile('*.mat', 'MultiSelect', 'off');
    file_path = [original_path, file_name];
    setappdata(0,'select_path',file_path);
    load(file_path, 'sep_analysis_results', 'filename_meta', 'chan_group_log');
    handles.file_path = file_path;
    handles.filename_meta = filename_meta;
    handles.chan_group_log = chan_group_log;

    handles.sep_data = sep_analysis_results;
    %initial set
    handles.index = 1;
    handles.changed_channel_index = [];
    %sort peaks to the ascending order
    sort_peaks(hObject, handles);
    handles = guidata(hObject);
    %plot the graph on sep_gui
    plot_sep_gui(handles, sep_analysis_results, handles.index);
    %turn on the datacursormode(which gives you the coordinates when you click on the curve)
    dcm_obj = datacursormode(handles.figure1);
    datacursormode on;
    set(dcm_obj,'UpdateFcn', @myupdatefcn )
    set(0, 'userdata', []);
    %check the status for checkboxes in "Change peaks" panel and "Add peaks" panel
    check_check(handles);
    add_check(handles);
    %preview window scale set
    setappdata(0,'scale_selection',1);
    find_universal_peaks(handles);
    %plot the preview window
    all_channels_sep;
    % Update handles structure
    guidata(hObject, handles);

%Get the coordinates from the graph
function txt = myupdatefcn(handles, event_obj)
    pos = event_obj.Position;
    txt = {['X: ',num2str(pos(1)),'s, Y: ',num2str(pos(2)), 'mV']};
    set(0, 'userdata', pos);

% --- Outputs from this function are returned to the command line.
function varargout = sep_gui_OutputFcn(hObject, eventdata, handles) 
    varargout{1} = handles.output;

% --- Switch to the previous channel
function prev_button_Callback(hObject, eventdata, handles)
    if handles.index > 1
        %save the notes in textbox
        analysis_notes = get(handles.notes_text, 'String');
        if isempty(analysis_notes)
            analysis_notes = 'n/a';
        end
        handles.sep_data(handles.index).analysis_notes = analysis_notes;
        %switch the channel
        handles.index = handles.index - 1;
        guidata(hObject,handles);
        handles = guidata(hObject);
        %plot new graph
        cla(handles.axes1);
        plot_sep_gui(handles, handles.sep_data, handles.index); 
        set(0, 'userdata', []);
        %refresh the status of all checkboxes and buttons
        set(handles.pos1_check, 'Value', 0);
        set(handles.pos2_check, 'Value', 0);
        set(handles.pos3_check, 'Value', 0);
        set(handles.neg1_check, 'Value', 0);
        set(handles.neg2_check, 'Value', 0);
        set(handles.neg3_check, 'Value', 0);
        check_check(handles);
        set(handles.change_button, 'Enable', 'off');
        add_check(handles);
        set(handles.addpos_check, 'Value', 0);
        set(handles.addneg_check, 'Value', 0);
        set(handles.add_button, 'Enable', 'off');

        set(handles.pos1_changeTo, 'Enable', 'off');
        set(handles.pos2_changeTo, 'Enable', 'off');
        set(handles.pos3_changeTo, 'Enable', 'off');
        set(handles.neg1_changeTo, 'Enable', 'off');
        set(handles.neg2_changeTo, 'Enable', 'off');
        set(handles.neg3_changeTo, 'Enable', 'off');

        set(handles.pos1_changeTo, 'Value', 0);
        set(handles.pos2_changeTo, 'Value', 0);
        set(handles.pos3_changeTo, 'Value', 0);
        set(handles.neg1_changeTo, 'Value', 0);
        set(handles.neg2_changeTo, 'Value', 0);
        set(handles.neg3_changeTo, 'Value', 0);
    end

% --- Switch to next channel
function next_button_Callback(hObject, eventdata, handles)
    %The process is the same as above
    if handles.index < length(handles.sep_data)
        analysis_notes = get(handles.notes_text, 'String');
        if isempty(analysis_notes)
            analysis_notes = 'n/a';
        end
        handles.sep_data(handles.index).analysis_notes = analysis_notes;
        handles.index = handles.index + 1;
        guidata(hObject,handles);

        handles = guidata(hObject); 
        cla(handles.axes1);
        plot_sep_gui(handles, handles.sep_data, handles.index);
        set(0, 'userdata', []);
        set(handles.pos1_check, 'Value', 0);
        set(handles.pos2_check, 'Value', 0);
        set(handles.pos3_check, 'Value', 0);
        set(handles.neg1_check, 'Value', 0);
        set(handles.neg2_check, 'Value', 0);
        set(handles.neg3_check, 'Value', 0);
        check_check(handles);
        set(handles.change_button, 'Enable', 'off');
        add_check(handles);
        set(handles.addpos_check, 'Value', 0);
        set(handles.addneg_check, 'Value', 0);
        set(handles.add_button, 'Enable', 'off');

        set(handles.pos1_changeTo, 'Enable', 'off');
        set(handles.pos2_changeTo, 'Enable', 'off');
        set(handles.pos3_changeTo, 'Enable', 'off');
        set(handles.neg1_changeTo, 'Enable', 'off');
        set(handles.neg2_changeTo, 'Enable', 'off');
        set(handles.neg3_changeTo, 'Enable', 'off');

        set(handles.pos1_changeTo, 'Value', 0);
        set(handles.pos2_changeTo, 'Value', 0);
        set(handles.pos3_changeTo, 'Value', 0);
        set(handles.neg1_changeTo, 'Value', 0);
        set(handles.neg2_changeTo, 'Value', 0);
        set(handles.neg3_changeTo, 'Value', 0);
    end

% --- Executes on mouse press over axes background.
function axes1_ButtonDownFcn(hObject, eventdata, handles)
    % hObject    handle to axes1 (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

% --- Executes during object creation, after setting all properties.
function axes1_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to axes1 (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called

    % Hint: place code in OpeningFcn to populate axes1

% --- Click to change peaks
function change_button_Callback(hObject, eventdata, handles)
    % hObject    handle to change_button (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    %get the coordinates of selected point in the curve
    position = get(0,'userdata');
    %check which peak the user wants to change
    if get(handles.pos1_check, 'Value')
        if ~isempty(position)
            handles.sep_data(handles.index).pos_peak_latency1 = (position(1)*1000);
            handles.sep_data(handles.index).pos_peak1 = position(2);
        end

        if get(handles.pos2_changeTo, 'Value')
            handles.sep_data(handles.index).pos_peak_latency2 = handles.sep_data(handles.index).pos_peak_latency1;
            handles.sep_data(handles.index).pos_peak2 = handles.sep_data(handles.index).pos_peak1;

            handles.sep_data(handles.index).pos_peak_latency1 = nan;
            handles.sep_data(handles.index).pos_peak1 = nan;
        elseif get(handles.pos3_changeTo, 'Value')
            handles.sep_data(handles.index).pos_peak_latency3 = handles.sep_data(handles.index).pos_peak_latency1;
            handles.sep_data(handles.index).pos_peak3 = handles.sep_data(handles.index).pos_peak1; 

            handles.sep_data(handles.index).pos_peak_latency1 = nan;
            handles.sep_data(handles.index).pos_peak1 = nan;
        else
            sort_peaks(hObject, handles);
        end
    end

    if get(handles.pos2_check, 'Value')
        if ~isempty(position)
            handles.sep_data(handles.index).pos_peak_latency2 = (position(1)*1000);
            handles.sep_data(handles.index).pos_peak2 = position(2);
        end

        if get(handles.pos1_changeTo, 'Value')
            handles.sep_data(handles.index).pos_peak_latency1 = handles.sep_data(handles.index).pos_peak_latency2;
            handles.sep_data(handles.index).pos_peak1 = handles.sep_data(handles.index).pos_peak2;

            handles.sep_data(handles.index).pos_peak_latency2 = nan;
            handles.sep_data(handles.index).pos_peak2 = nan;
        elseif get(handles.pos3_changeTo, 'Value')
            handles.sep_data(handles.index).pos_peak_latency3 = handles.sep_data(handles.index).pos_peak_latency2;
            handles.sep_data(handles.index).pos_peak3 = handles.sep_data(handles.index).pos_peak2;

            handles.sep_data(handles.index).pos_peak_latency2 = nan;
            handles.sep_data(handles.index).pos_peak2 = nan;
        else
            sort_peaks(hObject, handles);
        end
    end

    if get(handles.pos3_check, 'Value')
        if ~isempty(position)
            handles.sep_data(handles.index).pos_peak_latency3 = (position(1)*1000);
            handles.sep_data(handles.index).pos_peak3 = position(2);
        end

        if get(handles.pos1_changeTo, 'Value')
            handles.sep_data(handles.index).pos_peak_latency1 = handles.sep_data(handles.index).pos_peak_latency3;
            handles.sep_data(handles.index).pos_peak1 = handles.sep_data(handles.index).pos_peak3;
            
            handles.sep_data(handles.index).pos_peak_latency3 = nan;
            handles.sep_data(handles.index).pos_peak3 = nan;
        elseif get(handles.pos2_changeTo, 'Value')
            handles.sep_data(handles.index).pos_peak_latency2 = handles.sep_data(handles.index).pos_peak_latency3;
            handles.sep_data(handles.index).pos_peak2 = handles.sep_data(handles.index).pos_peak3;

            handles.sep_data(handles.index).pos_peak_latency3 = nan;
            handles.sep_data(handles.index).pos_peak3 = nan;
        else
            sort_peaks(hObject, handles);
        end
    end

    if get(handles.neg1_check, 'Value')
        if ~isempty(position)
            handles.sep_data(handles.index).neg_peak_latency1 = (position(1)*1000);
            handles.sep_data(handles.index).neg_peak1 = position(2);
        end

        if get(handles.neg2_changeTo, 'Value')
            handles.sep_data(handles.index).neg_peak_latency2 = handles.sep_data(handles.index).neg_peak_latency1;
            handles.sep_data(handles.index).neg_peak2 = handles.sep_data(handles.index).neg_peak1;

            handles.sep_data(handles.index).neg_peak_latency1 = nan;
            handles.sep_data(handles.index).neg_peak1 = nan;
        elseif get(handles.neg3_changeTo, 'Value')
            handles.sep_data(handles.index).neg_peak_latency3 = handles.sep_data(handles.index).neg_peak_latency1;
            handles.sep_data(handles.index).neg_peak3 = handles.sep_data(handles.index).neg_peak1;

            handles.sep_data(handles.index).neg_peak_latency1 = nan;
            handles.sep_data(handles.index).neg_peak1 = nan;
        else
            sort_peaks(hObject, handles);
        end
    end

    if get(handles.neg2_check, 'Value')
        if ~isempty(position)
            handles.sep_data(handles.index).neg_peak_latency2 = (position(1)*1000);
            handles.sep_data(handles.index).neg_peak2 = position(2);
        end
        
        if get(handles.neg1_changeTo, 'Value')
            handles.sep_data(handles.index).neg_peak_latency1 = handles.sep_data(handles.index).neg_peak_latency2;
            handles.sep_data(handles.index).neg_peak1 = handles.sep_data(handles.index).neg_peak2;

            handles.sep_data(handles.index).neg_peak_latency2 = nan;
            handles.sep_data(handles.index).neg_peak2 = nan;
        elseif get(handles.neg3_changeTo, 'Value')
            handles.sep_data(handles.index).neg_peak_latency3 = handles.sep_data(handles.index).neg_peak_latency2;
            handles.sep_data(handles.index).neg_peak3 = handles.sep_data(handles.index).neg_peak2;

            handles.sep_data(handles.index).neg_peak_latency2 = nan;
            handles.sep_data(handles.index).neg_peak2 = nan;
        else
            sort_peaks(hObject, handles);
        end
    end

    if get(handles.neg3_check, 'Value')
        if ~isempty(position)
            handles.sep_data(handles.index).neg_peak_latency3 = (position(1)*1000);
            handles.sep_data(handles.index).neg_peak3 = position(2);
        end

        if get(handles.neg1_changeTo, 'Value')
            handles.sep_data(handles.index).neg_peak_latency1 = handles.sep_data(handles.index).neg_peak_latency3;
            handles.sep_data(handles.index).neg_peak1 = handles.sep_data(handles.index).neg_peak3;
            
            handles.sep_data(handles.index).neg_peak_latency3 = nan;
            handles.sep_data(handles.index).neg_peak3 = nan;
        elseif get(handles.neg2_changeTo, 'Value')
            handles.sep_data(handles.index).neg_peak_latency2 = handles.sep_data(handles.index).neg_peak_latency3;
            handles.sep_data(handles.index).neg_peak2 = handles.sep_data(handles.index).neg_peak3;

            handles.sep_data(handles.index).neg_peak_latency3 = nan;
            handles.sep_data(handles.index).neg_peak3 = nan;
        else
            sort_peaks(hObject, handles);
        end
    end
    %record the changed channel index (no use in the current) 
    handles.changed_channel_index = [handles.changed_channel_index handles.index];

    guidata(hObject, handles);
    handles = guidata(hObject);
    %plot the new curve
    cla(handles.axes1);
    plot_sep_gui(handles, handles.sep_data, handles.index);
    %refresh the status of checkboxes and buttons
    set(handles.pos1_check, 'Enable', 'on');
    set(handles.neg1_check, 'Enable', 'on');
    set(handles.pos1_check, 'Value', 0);
    set(handles.pos2_check, 'Value', 0);
    set(handles.pos3_check, 'Value', 0);
    set(handles.neg1_check, 'Value', 0);
    set(handles.neg2_check, 'Value', 0);
    set(handles.neg3_check, 'Value', 0);

    set(handles.pos1_changeTo, 'Enable', 'off');
    set(handles.pos2_changeTo, 'Enable', 'off');
    set(handles.pos3_changeTo, 'Enable', 'off');
    set(handles.neg1_changeTo, 'Enable', 'off');
    set(handles.neg2_changeTo, 'Enable', 'off');
    set(handles.neg3_changeTo, 'Enable', 'off');

    set(handles.pos1_changeTo, 'Value', 0);
    set(handles.pos2_changeTo, 'Value', 0);
    set(handles.pos3_changeTo, 'Value', 0);
    set(handles.neg1_changeTo, 'Value', 0);
    set(handles.neg2_changeTo, 'Value', 0);
    set(handles.neg3_changeTo, 'Value', 0);

    check_check(handles);
    set(handles.change_button, 'Enable', 'off');
    set(handles.delete_button, 'Enable', 'off');
    changeTo_check(handles);

    set(0, 'userdata', []);

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
    % hObject    handle to figure1 (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Save the file when close this window
    % sep_analysis_results = handles.sep_data;
    % filename_meta = handles.filename_meta;
    % chan_group_log = handles.chan_group_log;
    % save(handles.save_file_path, 'sep_analysis_results', 'filename_meta', 'chan_group_log'); 

    delete(hObject);

% --- Executes on button press in addpos_check.
function addpos_check_Callback(hObject, eventdata, handles)
    % hObject    handle to addpos_check (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hint: get(hObject,'Value') returns toggle state of addpos_check
    addpos_check = get(handles.addpos_check, 'Value');
    if addpos_check
        set(handles.addneg_check, 'Enable', 'off');
        set(handles.add_button, 'Enable', 'on');
    else
        set(handles.addneg_check, 'Enable', 'on');
        set(handles.add_button, 'Enable', 'off');
    end

% --- Executes on button press in addneg_check.
function addneg_check_Callback(hObject, eventdata, handles)
    % hObject    handle to addneg_check (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hint: get(hObject,'Value') returns toggle state of addneg_check
    addneg_check = get(handles.addneg_check, 'Value');
    if addneg_check
        set(handles.addpos_check, 'Enable', 'off');
        set(handles.add_button, 'Enable', 'on');
    else
        set(handles.addpos_check, 'Enable', 'on');
        set(handles.add_button, 'Enable', 'off');
    end

% --- Executes on button press in add_button.
function add_button_Callback(hObject, eventdata, handles)
    %get the coordinates of selected point in the curve
    position = get(0,'userdata');

    if get(handles.addpos_check, 'Value')
        if ~isempty(position)
            %if peak2 is vacant, fill peak2 first, and then go to peak3 next
            %time(a little hard code here...)
            if ~isnan(handles.sep_data(handles.index).pos_peak2)
                handles.sep_data(handles.index).pos_peak_latency3 = (position(1)*1000);
                handles.sep_data(handles.index).pos_peak3 = position(2);
            else
                handles.sep_data(handles.index).pos_peak_latency2 = (position(1)*1000);
                handles.sep_data(handles.index).pos_peak2 = position(2);
            end
        end
    end

    if get(handles.addneg_check, 'Value')
        if ~isempty(position)
            if ~isnan(handles.sep_data(handles.index).neg_peak2)
                handles.sep_data(handles.index).neg_peak_latency3 = (position(1)*1000);
                handles.sep_data(handles.index).neg_peak3 = position(2);
            else
                handles.sep_data(handles.index).neg_peak_latency2 = (position(1)*1000);
                handles.sep_data(handles.index).neg_peak2 = position(2);
            end
        end
    end

    handles.changed_channel_index = [handles.changed_channel_index handles.index];

    guidata(hObject, handles);

    sort_peaks(hObject, handles);
    handles = guidata(hObject);

    cla(handles.axes1);
    plot_sep_gui(handles, handles.sep_data, handles.index);
    add_check(handles);

    set(handles.addpos_check, 'Value', 0);
    set(handles.addneg_check, 'Value', 0);
    set(handles.add_button, 'Enable', 'off');

    check_check(handles);
    set(handles.change_button, 'Enable', 'off');
    set(0, 'userdata', []);

% --- Executes on button press in discard_button.
function discard_button_Callback(hObject, eventdata, handles)
    % load the last saved file
    load(handles.file_path, 'sep_analysis_results', 'filename_meta', 'chan_group_log');
    cla(handles.axes1);
    plot_sep_gui(handles, sep_analysis_results, handles.index);
    handles.sep_data = sep_analysis_results;
    handles.filename_meta = filename_meta;
    handles.chan_group_log = chan_group_log;
    check_check(handles);
    set(handles.change_button, 'Enable', 'off');
    add_check(handles);
    set(handles.add_button, 'Enable', 'off');
    % Update handles structure
    guidata(hObject, handles);

function pos1_check_Callback(hObject, eventdata, handles)
    % --- Executes on button press in pos1_check.
    % hObject    handle to pos1_check (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hint: get(hObject,'Value') returns toggle state of pos1_check
    pos_check = get(handles.pos1_check, 'Value');
    if pos_check
        set(handles.pos2_check, 'Enable', 'off');
        set(handles.pos3_check, 'Enable', 'off');
        set(handles.neg1_check, 'Enable', 'off');
        set(handles.neg2_check, 'Enable', 'off');
        set(handles.neg3_check, 'Enable', 'off');
        set(handles.change_button, 'Enable', 'on');
        set(handles.delete_button, 'Enable', 'on');
        changeTo_check(handles);
    else
        check_check(handles);
        set(handles.change_button, 'Enable', 'off');
        set(handles.delete_button, 'Enable', 'off');

        set(handles.pos1_changeTo, 'Enable', 'off');
        set(handles.pos2_changeTo, 'Enable', 'off');
        set(handles.pos3_changeTo, 'Enable', 'off');
        set(handles.neg1_changeTo, 'Enable', 'off');
        set(handles.neg2_changeTo, 'Enable', 'off');
        set(handles.neg3_changeTo, 'Enable', 'off');

        set(handles.pos1_changeTo, 'Value', 0);
        set(handles.pos2_changeTo, 'Value', 0);
        set(handles.pos3_changeTo, 'Value', 0);
        set(handles.neg1_changeTo, 'Value', 0);
        set(handles.neg2_changeTo, 'Value', 0);
        set(handles.neg3_changeTo, 'Value', 0);
    end

% --- Executes on button press in neg1_check.
function neg1_check_Callback(hObject, eventdata, handles)
    % hObject    handle to neg1_check (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hint: get(hObject,'Value') returns toggle state of neg1_check
    neg_check = get(handles.neg1_check, 'Value');
    if neg_check
        set(handles.pos2_check, 'Enable', 'off');
        set(handles.pos3_check, 'Enable', 'off');
        set(handles.pos1_check, 'Enable', 'off');
        set(handles.neg2_check, 'Enable', 'off');
        set(handles.neg3_check, 'Enable', 'off');
        set(handles.change_button, 'Enable', 'on');
        set(handles.delete_button, 'Enable', 'on');
        changeTo_check(handles);
    else
        check_check(handles);
        set(handles.change_button, 'Enable', 'off');
        set(handles.delete_button, 'Enable', 'off');

        set(handles.pos1_changeTo, 'Enable', 'off');
        set(handles.pos2_changeTo, 'Enable', 'off');
        set(handles.pos3_changeTo, 'Enable', 'off');
        set(handles.neg1_changeTo, 'Enable', 'off');
        set(handles.neg2_changeTo, 'Enable', 'off');
        set(handles.neg3_changeTo, 'Enable', 'off');

        set(handles.pos1_changeTo, 'Value', 0);
        set(handles.pos2_changeTo, 'Value', 0);
        set(handles.pos3_changeTo, 'Value', 0);
        set(handles.neg1_changeTo, 'Value', 0);
        set(handles.neg2_changeTo, 'Value', 0);
        set(handles.neg3_changeTo, 'Value', 0);
    end

% --- Executes on button press in pos2_check.
function pos2_check_Callback(hObject, eventdata, handles)
    % hObject    handle to pos2_check (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hint: get(hObject,'Value') returns toggle state of pos2_check
    pos_check = get(handles.pos2_check, 'Value');
    if pos_check
        set(handles.pos1_check, 'Enable', 'off');
        set(handles.pos3_check, 'Enable', 'off');
        set(handles.neg1_check, 'Enable', 'off');
        set(handles.neg2_check, 'Enable', 'off');
        set(handles.neg3_check, 'Enable', 'off');
        set(handles.change_button, 'Enable', 'on');
        set(handles.delete_button, 'Enable', 'on');
        changeTo_check(handles);
    else
        check_check(handles);
        set(handles.change_button, 'Enable', 'off');
        set(handles.delete_button, 'Enable', 'off');

        set(handles.pos1_changeTo, 'Enable', 'off');
        set(handles.pos2_changeTo, 'Enable', 'off');
        set(handles.pos3_changeTo, 'Enable', 'off');
        set(handles.neg1_changeTo, 'Enable', 'off');
        set(handles.neg2_changeTo, 'Enable', 'off');
        set(handles.neg3_changeTo, 'Enable', 'off');

        set(handles.pos1_changeTo, 'Value', 0);
        set(handles.pos2_changeTo, 'Value', 0);
        set(handles.pos3_changeTo, 'Value', 0);
        set(handles.neg1_changeTo, 'Value', 0);
        set(handles.neg2_changeTo, 'Value', 0);
        set(handles.neg3_changeTo, 'Value', 0);
    end

% --- Executes on button press in neg2_check.
function neg2_check_Callback(hObject, eventdata, handles)
    % hObject    handle to neg2_check (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hint: get(hObject,'Value') returns toggle state of neg2_check
    neg_check = get(handles.neg2_check, 'Value');
    if neg_check
        set(handles.pos2_check, 'Enable', 'off');
        set(handles.pos3_check, 'Enable', 'off');
        set(handles.neg1_check, 'Enable', 'off');
        set(handles.pos1_check, 'Enable', 'off');
        set(handles.neg3_check, 'Enable', 'off');
        set(handles.change_button, 'Enable', 'on');
        set(handles.delete_button, 'Enable', 'on');
        changeTo_check(handles);
    else
        check_check(handles);
        set(handles.change_button, 'Enable', 'off');
        set(handles.delete_button, 'Enable', 'off');

        set(handles.pos1_changeTo, 'Enable', 'off');
        set(handles.pos2_changeTo, 'Enable', 'off');
        set(handles.pos3_changeTo, 'Enable', 'off');
        set(handles.neg1_changeTo, 'Enable', 'off');
        set(handles.neg2_changeTo, 'Enable', 'off');
        set(handles.neg3_changeTo, 'Enable', 'off');

        set(handles.pos1_changeTo, 'Value', 0);
        set(handles.pos2_changeTo, 'Value', 0);
        set(handles.pos3_changeTo, 'Value', 0);
        set(handles.neg1_changeTo, 'Value', 0);
        set(handles.neg2_changeTo, 'Value', 0);
        set(handles.neg3_changeTo, 'Value', 0);
    end

% --- Executes on button press in pos3_check.
function pos3_check_Callback(hObject, eventdata, handles)
    % hObject    handle to pos3_check (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hint: get(hObject,'Value') returns toggle state of pos3_check
    pos_check = get(handles.pos3_check, 'Value');
    if pos_check
        set(handles.pos2_check, 'Enable', 'off');
        set(handles.pos1_check, 'Enable', 'off');
        set(handles.neg1_check, 'Enable', 'off');
        set(handles.neg2_check, 'Enable', 'off');
        set(handles.neg3_check, 'Enable', 'off');
        set(handles.change_button, 'Enable', 'on');
        set(handles.delete_button, 'Enable', 'on');
        changeTo_check(handles);
    else
        check_check(handles);
        set(handles.change_button, 'Enable', 'off');
        set(handles.delete_button, 'Enable', 'off');

        set(handles.pos1_changeTo, 'Enable', 'off');
        set(handles.pos2_changeTo, 'Enable', 'off');
        set(handles.pos3_changeTo, 'Enable', 'off');
        set(handles.neg1_changeTo, 'Enable', 'off');
        set(handles.neg2_changeTo, 'Enable', 'off');
        set(handles.neg3_changeTo, 'Enable', 'off');

        set(handles.pos1_changeTo, 'Value', 0);
        set(handles.pos2_changeTo, 'Value', 0);
        set(handles.pos3_changeTo, 'Value', 0);
        set(handles.neg1_changeTo, 'Value', 0);
        set(handles.neg2_changeTo, 'Value', 0);
        set(handles.neg3_changeTo, 'Value', 0);
    end

% --- Executes on button press in neg3_check.
function neg3_check_Callback(hObject, eventdata, handles)
    % hObject    handle to neg3_check (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hint: get(hObject,'Value') returns toggle state of neg3_check
    neg_check = get(handles.neg3_check, 'Value');
    if neg_check
        set(handles.pos2_check, 'Enable', 'off');
        set(handles.pos3_check, 'Enable', 'off');
        set(handles.neg1_check, 'Enable', 'off');
        set(handles.neg2_check, 'Enable', 'off');
        set(handles.pos1_check, 'Enable', 'off');
        set(handles.change_button, 'Enable', 'on');
        set(handles.delete_button, 'Enable', 'on');
        changeTo_check(handles);
    else
        check_check(handles);
        set(handles.change_button, 'Enable', 'off');
        set(handles.delete_button, 'Enable', 'off');

        set(handles.pos1_changeTo, 'Enable', 'off');
        set(handles.pos2_changeTo, 'Enable', 'off');
        set(handles.pos3_changeTo, 'Enable', 'off');
        set(handles.neg1_changeTo, 'Enable', 'off');
        set(handles.neg2_changeTo, 'Enable', 'off');
        set(handles.neg3_changeTo, 'Enable', 'off');

        set(handles.pos1_changeTo, 'Value', 0);
        set(handles.pos2_changeTo, 'Value', 0);
        set(handles.pos3_changeTo, 'Value', 0);
        set(handles.neg1_changeTo, 'Value', 0);
        set(handles.neg2_changeTo, 'Value', 0);
        set(handles.neg3_changeTo, 'Value', 0);
    end

% --- Executes on button press in save_button.
function save_button_Callback(hObject, eventdata, handles)
    %save path
    path_parts = strsplit(handles.file_path, {'/', '\'});
    dir_name = path_parts{end - 1};
    file_name = path_parts{end};

    path_parts = strcat(path_parts, '\');
    parent_path = cell2mat(path_parts(1:end-3));
    [output_path, ~] = create_dir(parent_path, 'sep_gui_data');
    [dir_path, ~] = create_dir(output_path, dir_name);
    save_file_path = [dir_path, '/', file_name];
    setappdata(0, 'save_path', save_file_path);
    handles.save_file_path = save_file_path;

    %save notes
    analysis_notes = get(handles.notes_text, 'String');
    if isempty(analysis_notes)
        analysis_notes = 'n/a';
    end
    handles.sep_data(handles.index).analysis_notes = analysis_notes;
    %save the data back to the loaded mat.flie 
    sep_analysis_results = handles.sep_data;
    %recalculates region / label based analysis
    sep_analysis_results = norm_sep_peaks(sep_analysis_results);
    filename_meta = handles.filename_meta;
    chan_group_log = handles.chan_group_log;
    save(handles.save_file_path, 'sep_analysis_results', 'filename_meta', 'chan_group_log');
    %refresh subplot graph
    setappdata(0, 'changed_channel_index', handles.changed_channel_index); %no use currently
    obj_sub = findobj('Name', 'all_channels_sep'); %get the Object from 'all_channels_sep' gui
    handles_sub = guidata(obj_sub); %get the handles from 'all_channels_sep' gui
    %call the function 'subplot_refresh_Callback' in 'all_channels_sep' gui
    all_channels_sep('subplot_refresh_Callback', handles_sub.subplot_refresh,[],handles_sub);
    handles.changed_channel_index = [];
    % Update handles structure
    guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function axes2_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to axes2 (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called

    % Hint: place code in OpeningFcn to populate axes2

function notes_text_Callback(hObject, eventdata, handles)
    % hObject    handle to notes_text (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hints: get(hObject,'String') returns contents of notes_text as text
    %        str2double(get(hObject,'String')) returns contents of notes_text as a double

% --- Executes during object creation, after setting all properties.
function notes_text_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to notes_text (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called

    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

% --- Executes on button press in delete_button.
function delete_button_Callback(hObject, eventdata, handles)
    % hObject    handle to delete_button (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    if get(handles.pos1_check, 'Value')
        handles.sep_data(handles.index).pos_peak_latency1 = NaN;
        handles.sep_data(handles.index).pos_peak1 = NaN;
    end

    if get(handles.pos2_check, 'Value')
        handles.sep_data(handles.index).pos_peak_latency2 = NaN;
        handles.sep_data(handles.index).pos_peak2 = NaN;
    end

    if get(handles.pos3_check, 'Value')
        handles.sep_data(handles.index).pos_peak_latency3 = NaN;
        handles.sep_data(handles.index).pos_peak3 = NaN;
    end

    if get(handles.neg1_check, 'Value')
        handles.sep_data(handles.index).neg_peak_latency1 = NaN;
        handles.sep_data(handles.index).neg_peak1 = NaN;
    end

    if get(handles.neg2_check, 'Value')
        handles.sep_data(handles.index).neg_peak_latency2 = NaN;
        handles.sep_data(handles.index).neg_peak2 = NaN;
    end

    if get(handles.neg3_check, 'Value')
        handles.sep_data(handles.index).neg_peak_latency3 = NaN;
        handles.sep_data(handles.index).neg_peak3 = NaN;
    end

    handles.changed_channel_index = [handles.changed_channel_index handles.index];

    guidata(hObject, handles);
    sort_peaks(hObject, handles);
    handles = guidata(hObject);
    cla(handles.axes1);
    plot_sep_gui(handles, handles.sep_data, handles.index);
    set(handles.pos1_check, 'Enable', 'on');
    set(handles.neg1_check, 'Enable', 'on');
    set(handles.pos1_check, 'Value', 0);
    set(handles.pos2_check, 'Value', 0);
    set(handles.pos3_check, 'Value', 0);
    set(handles.neg1_check, 'Value', 0);
    set(handles.neg2_check, 'Value', 0);
    set(handles.neg3_check, 'Value', 0);
    add_check(handles);
    check_check(handles);
    set(handles.change_button, 'Enable', 'off');
    set(handles.delete_button, 'Enable', 'off');

    set(handles.pos1_changeTo, 'Enable', 'off');
    set(handles.pos2_changeTo, 'Enable', 'off');
    set(handles.pos3_changeTo, 'Enable', 'off');
    set(handles.neg1_changeTo, 'Enable', 'off');
    set(handles.neg2_changeTo, 'Enable', 'off');
    set(handles.neg3_changeTo, 'Enable', 'off');

    set(handles.pos1_changeTo, 'Value', 0);
    set(handles.pos2_changeTo, 'Value', 0);
    set(handles.pos3_changeTo, 'Value', 0);
    set(handles.neg1_changeTo, 'Value', 0);
    set(handles.neg2_changeTo, 'Value', 0);
    set(handles.neg3_changeTo, 'Value', 0);

    set(0, 'userdata', []);

% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)
    % hObject    handle to figure1 (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

% --- Executes on button press in channel_switch.
function channel_switch_Callback(hObject, eventdata, handles)
    %Switch the graph to the channel selected in preview window

    %save the notes in textbox
    analysis_notes = get(handles.notes_text, 'String');
    if isempty(analysis_notes)
        analysis_notes = 'n/a';
    end
    handles.sep_data(handles.index).analysis_notes = analysis_notes;
    %get the selected channel index
    handles.index = getappdata(0,'select_index');

    guidata(hObject,handles);
    % sort_peaks(hObject, handles);
    handles = guidata(hObject);
    cla(handles.axes1);
    %plot the selected channel
    plot_sep_gui(handles, handles.sep_data, handles.index);
    set(0, 'userdata', []);
    set(handles.pos1_check, 'Enable', 'on');
    set(handles.neg1_check, 'Enable', 'on');
    set(handles.pos1_check, 'Value', 0);
    set(handles.pos2_check, 'Value', 0);
    set(handles.pos3_check, 'Value', 0);
    set(handles.neg1_check, 'Value', 0);
    set(handles.neg2_check, 'Value', 0);
    set(handles.neg3_check, 'Value', 0);
    check_check(handles);
    set(handles.change_button, 'Enable', 'off');

    add_check(handles);
    set(handles.addpos_check, 'Value', 0);
    set(handles.addneg_check, 'Value', 0);
    set(handles.add_button, 'Enable', 'off');

% --- Executes during object creation, after setting all properties.
function prev_button_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to prev_button (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called

% --- Executes during object creation, after setting all properties.
function save_button_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to save_button (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called

% --- Executes on button press in load_button.
function load_button_Callback(hObject, eventdata, handles)
    %save notes
    analysis_notes = get(handles.notes_text, 'String');
    if isempty(analysis_notes)
        analysis_notes = 'n/a';
    end
    handles.sep_data(handles.index).analysis_notes = analysis_notes;
    %load new files
    [file_name, original_path] = uigetfile('*.mat', 'MultiSelect', 'off');
    path_parts = strsplit(original_path, {'/', '\'});
    % end - 1 because uigetfile returns path with backslash at end of string
    dir_name = path_parts{end - 1};
    file_path = [original_path '\' file_name];
    setappdata(0,'select_path',file_path);
    handles.file_path = file_path;

    %%set save path to empty string
    save_file_path = []; 
    setappdata(0, 'save_path', save_file_path);
    handles.save_file_path = save_file_path;

    %%
    load(handles.file_path, 'sep_analysis_results', 'filename_meta', 'chan_group_log');
    handles.sep_data = sep_analysis_results;
    handles.filename_meta = filename_meta;
    handles.chan_group_log = chan_group_log;
    find_universal_peaks(handles);
    cla(handles.axes1);
    handles.index = 1;
    plot_sep_gui(handles, sep_analysis_results, handles.index);
    %checkbox status
    set(handles.pos1_check, 'Value', 0);
    set(handles.pos2_check, 'Value', 0);
    set(handles.pos3_check, 'Value', 0);
    set(handles.neg1_check, 'Value', 0);
    set(handles.neg2_check, 'Value', 0);
    set(handles.neg3_check, 'Value', 0);
    check_check(handles);
    set(handles.change_button, 'Enable', 'off');
    add_check(handles);
    set(handles.addpos_check, 'Value', 0);
    set(handles.addneg_check, 'Value', 0);
    set(handles.add_button, 'Enable', 'off');
    %refresh subplot graph
    handles.changed_channel_index = 1 : length(sep_analysis_results);
    setappdata(0, 'changed_channel_index', handles.changed_channel_index);
    obj_sub = findobj('Name', 'all_channels_sep');
    handles_sub = guidata(obj_sub);
    all_channels_sep('subplot_refresh_Callback', handles_sub.subplot_refresh, [], handles_sub);
    handles.changed_channel_index = [];
    % Update handles structure
    guidata(hObject, handles);

% --- Executes on button press in pos1_changeTo.
function pos1_changeTo_Callback(hObject, eventdata, handles)
    % hObject    handle to pos1_changeTo (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hint: get(hObject,'Value') returns toggle state of pos1_changeTo

    checkbox_check = get(handles.pos1_changeTo, 'Value');

    if checkbox_check == 1
        set(handles.pos2_changeTo, 'Enable', 'off');
        set(handles.pos3_changeTo, 'Enable', 'off');
        set(handles.neg1_changeTo, 'Enable', 'off');
        set(handles.neg2_changeTo, 'Enable', 'off');
        set(handles.neg3_changeTo, 'Enable', 'off');
    else
        changeTo_check(handles);
    end

% --- Executes on button press in pos2_changeTo.
function pos2_changeTo_Callback(hObject, eventdata, handles)
    % hObject    handle to pos2_changeTo (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hint: get(hObject,'Value') returns toggle state of pos2_changeTo

    checkbox_check = get(handles.pos2_changeTo, 'Value');

    if checkbox_check == 1
        set(handles.pos1_changeTo, 'Enable', 'off');
        set(handles.pos3_changeTo, 'Enable', 'off');
        set(handles.neg1_changeTo, 'Enable', 'off');
        set(handles.neg2_changeTo, 'Enable', 'off');
        set(handles.neg3_changeTo, 'Enable', 'off');
    else
        changeTo_check(handles);
    end

% --- Executes on button press in pos3_changeTo.
function pos3_changeTo_Callback(hObject, eventdata, handles)
    % hObject    handle to pos3_changeTo (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hint: get(hObject,'Value') returns toggle state of pos3_changeTo

    checkbox_check = get(handles.pos3_changeTo, 'Value');

    if checkbox_check == 1
        set(handles.pos1_changeTo, 'Enable', 'off');
        set(handles.pos2_changeTo, 'Enable', 'off');
        set(handles.neg1_changeTo, 'Enable', 'off');
        set(handles.neg2_changeTo, 'Enable', 'off');
        set(handles.neg3_changeTo, 'Enable', 'off');
    else
        changeTo_check(handles);
    end

% --- Executes on button press in neg1_changeTo.
function neg1_changeTo_Callback(hObject, eventdata, handles)
    % hObject    handle to neg1_changeTo (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hint: get(hObject,'Value') returns toggle state of neg1_changeTo

    checkbox_check = get(handles.neg1_changeTo, 'Value'); 

    if checkbox_check
        set(handles.pos1_changeTo, 'Enable', 'off');
        set(handles.pos2_changeTo, 'Enable', 'off');
        set(handles.pos3_changeTo, 'Enable', 'off');
        set(handles.neg2_changeTo, 'Enable', 'off');
        set(handles.neg3_changeTo, 'Enable', 'off');
    else
        changeTo_check(handles);
    end

% --- Executes on button press in neg2_changeTo.
function neg2_changeTo_Callback(hObject, eventdata, handles)
    % hObject    handle to neg2_changeTo (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hint: get(hObject,'Value') returns toggle state of neg2_changeTo

    checkbox_check = get(handles.neg2_changeTo, 'Value'); 

    if checkbox_check == 1
        set(handles.pos1_changeTo, 'Enable', 'off');
        set(handles.pos2_changeTo, 'Enable', 'off');
        set(handles.pos3_changeTo, 'Enable', 'off');
        set(handles.neg1_changeTo, 'Enable', 'off');
        set(handles.neg3_changeTo, 'Enable', 'off');
    else
        changeTo_check(handles);
    end

% --- Executes on button press in neg3_changeTo.
function neg3_changeTo_Callback(hObject, eventdata, handles)
    % hObject    handle to neg3_changeTo (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hint: get(hObject,'Value') returns toggle state of neg3_changeTo

    checkbox_check = get(handles.neg3_changeTo, 'Value');

    if checkbox_check
        set(handles.pos1_changeTo, 'Enable', 'off');
        set(handles.pos2_changeTo, 'Enable', 'off');
        set(handles.pos3_changeTo, 'Enable', 'off');
        set(handles.neg1_changeTo, 'Enable', 'off');
        set(handles.neg2_changeTo, 'Enable', 'off');
    else
        changeTo_check(handles);
    end