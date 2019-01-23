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

-- Run command in shell and return the signal code
run = function(command)
	val, infor, code = os.execute(command);
	return code;
end

-- Turn float to int
to_int = function(num)
	if string.find(num, "%.") == nil then return num; end
	return string.sub(num, 1, string.find(num, "%.") - 1); 
end

-- Check if the path is exist
check_path = function(path) return run("test -e " .. path) == 0; end

get_second = function() return os.date("%H") * 3600 + os.date("%M") * 60 + os.date("%S"); end

get_time = function() return os.date("%H") .. ":" .. os.date("%M"); end

-- Get and format the things which wrote to /tmp/.thing
format_thing = function()
	local file = io.open(thing_file, "r");
	local result = "";
	while true do
		local begin_time = file:read("*l");
		if begin_time == nil then break; end
		local plan_to_do = file:read("*l");
		if plan_to_do == "" then plan_to_do = "Unknow"; end
		local have_done = file:read("*l");
		if have_done == "" then have_done = "Unknow"; end
		local end_time = file:read("*l");
		result = result .. "[" .. begin_time .. " - " .. end_time .. "] " .. have_done .. "(" .. plan_to_do .. ")\n";
	end
	run("rm -r " .. thing_file);
	return result;
end

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
	return run(command);
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
	local choose = zenity("question", "Yes", "No", "Are you sure to exit this application?", "--no-wrap");
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
	if check_path(config_path) == false then run("mkdir -p " .. config_path); end
	if check_path(summary_path) == false then run("mkdir -p " .. summary_path);end
	if check_path(tmp_path) == false then run("mkdir -p " .. tmp_path);end
end

-- Count the rest of time
count_time = function(need_time)
	local cnt = 1;
	while cnt <= 100 do
		os.execute("sleep " .. need_time / 100);
		local left = math.ceil(need_time - cnt * (need_time / 100));
		print("# Back in " .. to_int(left / 60) .. " m " .. to_int(left % 60) .. " s");
		print(cnt);
		cnt = cnt + 1;
	end
end

main = function()
	init();
	local choose;
	put_off_work_time = put_off_work_time + timing(function()
		choose = ready("work");
		while choose == 0 do 
			exit();
			choose = ready("work");
		end
	end);
	
	-- Record thing
	run("echo " .. get_time() .. " >> " .. thing_file);
	zenity("entry", "Ok", "Cancel", "What do you plan to do?", ">> " .. thing_file);

	-- Working
	totale_work_time = totale_work_time + timing(function()
		os.execute("sleep " .. (work_time * 60));
	end);

	-- Record thing
	zenity("entry", "Ok", "Cancel", "Time is up, what have you done?", ">> " .. thing_file);
	run("echo " .. get_time() .. " >> " .. thing_file);

	put_off_rest_time = put_off_rest_time + timing(function()
		choose = ready("rest");
		while choose == 0 do
			exit();
			choose = ready("rest");
		end
	end)

	totale_rest_time = totale_rest_time + timing(function()
		for i = 1, rest_time, 1 do
			local status = run("zenity --info --title='" .. title .. "' --ok-label='Enter to speed up' --text='Back to work after " .. rest_time - i + 1 .. " minutes.' --no-wrap --timeout=60");
			print(status);
			if status ~= 5 then speed_up_rest_time = speed_up_rest_time + 1; end
		end
	end);
end

if arg[1] == "--count-time" then
	count_time(arg[2] * 60)
	os.exit(0);
end

while true do
	main();
end

