#!/usr/bin/lua
local config_path = os.getenv("HOME") .. "/.config/tomato/";
local summary_path = config_path .. "summary/";
local tmp_path = config_path .. "tmp/";
local thing_file = tmp_path .. ".thing";

local title = "Tomato Time Limit";
local first_time = true;
local work_time = 25;
local rest_time = 5;

local speed_up_rest_time = 0;
local put_off_rest_time = 0;
local put_off_work_time = 0;
local totale_work_time = 0;
local totale_rest_time = 0;

local time_block = 0;
local begin_time = {};
local plan_to_do = {};
local have_done = {};
local end_time = {};

-- code_back_run() | Run command in shell and return the signal code {{{
code_back_run = function(command)
	local val, infor, code = os.execute(command);
	return code;
end
-- }}}

-- out_back_run() | Run command in shell and return its output {{{
out_back_run = function(command)
	local file = io.popen(command, "r");
	local content = file:read("*a");
	io.close(file);
	return content;
end
-- }}}

-- to_int() | Turn float to int {{{
to_int = function(num)
	if string.find(num, "%.") == nil then return num; end
	return string.sub(num, 1, string.find(num, "%.") - 1); 
end
-- }}}

-- check_path() | Check if the path is exist
check_path = function(path) return code_back_run("test -e " .. path) == 0; end

get_second = function() return os.date("%H") * 3600 + os.date("%M") * 60 + os.date("%S"); end

get_time = function() return os.date("%H") .. ":" .. os.date("%M"); end

-- format_thing() | Format the things which plan to do and have done {{{
format_thing = function()
	local result = "";
	for i = 1, time_block - 1, 1 do
		result = result .. "[" .. begin_time[i] .. " - " .. end_time[i] .. "] " .. have_done[i];
		if have_done[i] == plan_to_do[i] then
			result = result .. "(" .. plan_to_do[i] .. ")\n";
		end
	end
	return result;
end
-- }}}

-- Write summary file to /summary/xxx_xxx.txt
write_file = function()
	local date = os.date("%Y") .. os.date("%m") .. os.date("%d");

	local infor = format_thing() .. "\n";
	infor = infor .. "Totale work title: " .. to_int(totale_work_time) .. " minutes\n";
	infor = infor .. "Totale rest title: " .. to_int(totale_rest_time) .. " minutes\n";
	infor = infor .. "Put off work time: " .. to_int(put_off_work_time) .. " minutes\n"
	infor = infor .. "Put off rest time: " .. to_int(put_off_rest_time) .. " minutes\n";
	infor = infor .. "Speeded up rest time: " .. to_int(speed_up_rest_time) .. " minutes\n"

	local index = 0;
	while check_path(summary_path .. date .. "_" .. index) == true do index = index + 1; end
	local path = summary_path .. date .. "_" .. index;
	path = path .. date .. ".txt";
	local file = io.open(path, "w");
	file:write(infor);
	io.close(file);
end

-- Package zenity
zenity = function(kind, ok, cancel, text, ...)
	local command = "zenity --" .. kind .. " --title='" .. title .. "' --cancel-label='" .. ok .. "' --ok-label='" .. cancel .. "' --text='" .. text .. "' --default-cancel";
	for i, v in ipairs{...} do command = command .. " " .. v; end
	return code_back_run(command);
end

-- Node the data
note = function()
	zenity("notification", "", "", "Totale work time: " .. totale_work_time .. " minutes");
	zenity("notification", "", "", "Totale rest time: " .. totale_rest_time .. " minutes");
	zenity("notification", "", "", "Put off work time: " .. put_off_work_time .. " minutes");
	zenity("notification", "", "", "Put off rest time: " .. put_off_rest_time .. " minutes");
	zenity("notification", "", "", "Speeded up rest time: " .. speed_up_rest_time .. " minutes");
end

-- Exit the application
exit = function()
	local choose = code_back_run("zenity --question --title='" .. title .. "' --cancel-label='Yes' --ok-label='No' --text='Are you sure to exit this application?' --default-cancel --no-wrap");
	if choose == 1 then 
		note();
		write_file();
		os.exit(0); 
	end
end

-- Calculate the time used by function
timing = function(func)
	local begin_time = get_second();
	func();
	local use_time = (get_second() - begin_time) / 60;
	return use_time - use_time % 1;
end

-- Use zenity to ask if is ready
ready = function(thing)
	return zenity("question", "Start", "Exit", "Click 'Start' when you are ready to " .. thing, "--no-wrap");
end

-- Set up the basic folder
init = function()
	if check_path(config_path) == false then code_back_run("mkdir -p " .. config_path); end
	if check_path(summary_path) == false then code_back_run("mkdir -p " .. summary_path);end
	if check_path(tmp_path) == false then code_back_run("mkdir -p " .. tmp_path);end
end

-- Count the rest of time
count_time = function(need_time)
	need_time = tonumber(need_time);
	local cnt = 0;
	local sec = 0;
	if need_time > 60 then
		while sec <= need_time do
			local left = need_time - sec;
			print("# Back in " .. to_int(left / 60) .. " m " .. to_int(left % 60) .. " s");
			print(cnt);
			os.execute("sleep 1");
			sec = sec + 1;
			cnt = math.floor(sec * 100 / need_time);
		end
	else
		while cnt <= 100 do
			local left = need_time - sec;
			print("# Back in " .. to_int(left / 60) .. " m " .. to_int(left % 60) .. " s");
			print(cnt);
			os.execute("sleep " .. need_time / 100);
			cnt = cnt + 1;
			sec = math.floor(cnt * (need_time / 100));
		end
	end
end

loop = function()
	local choose;
	time_block = time_block + 1;

	-- Plan to do
	put_off_work_time = put_off_work_time + timing(function()
	  plan_to_do[time_block] = out_back_run("zenity --entry --text='Make a plan and start work' --ok-label='Start' --cancel-label='Exit'");
		while plan_to_do[time_block] == "\n" or plan_to_do[time_block] == "" do
			if plan_to_do[time_block] == "\n" then
				plan_to_do[time_block] = out_back_run("zenity --entry --text='Make a plan first please :)' --ok-label='Start' --cancel='Exit'");
			end
			if plan_to_do[time_block] == "" then 
				exit(); -- The only export for this application
				plan_to_do[time_block] = out_back_run("zenity --entry --text='Make a plan and start work' --ok-label='Start' --cancel-label='Exit'");
			end
		end
		begin_time[time_block] = get_time();
		plan_to_do[time_block] = string.gsub(plan_to_do[time_block], "\n", "");
	end);

	-- Working
	totale_work_time = totale_work_time + timing(function()
		os.execute("sleep " .. (work_time * 60));
	end);

	-- Record have done
	put_off_rest_time = put_off_rest_time + timing(function()
		have_done[time_block] = out_back_run("zenity --entry --text='Time is up, record what you do and have a rest.' --ok-label='Start' --cancel-label='Exit' --entry-text='" .. plan_to_do[time_block] .. "'");
		have_done[time_block] = string.gsub(have_done[time_block], "\n", "");
		end_time[time_block] = get_time();
	end)

	local this_rest_time = timing(function()
		choose = code_back_run("./tomato.lua --progress " .. rest_time * 60 .. " | zenity --progress --title='" .. title .. "' --cancel-label='Skip' --ok-label='Done' --auto-close");
		if choose == 1 then 
			-- Operation after user skipping the rest time.
		end;
	end);
	totale_rest_time = totale_rest_time + this_rest_time;
	speed_up_rest_time = speed_up_rest_time + rest_time - this_rest_time;

end

if arg[1] == "--progress" then
	count_time(arg[2])
	os.exit(0);
end

init();
while true do
	loop();
end

