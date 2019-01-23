#!/usr/bin/lua
local title = "Tomato Time Limit";
local first_time = true;
local work_time = 25;
local rest_time = 5;

local speed_up_rest_time = 0;
local put_off_rest_time = 0;
local put_off_work_time = 0;
local totale_work_time = 0;
local totale_rest_time = 0;

run = function(command)
	val, infor, code = os.execute(command);
	return code;
end

to_int = function(num)
	return string.sub(num, string.find(num, "%.") - 1);
end

get_time = function()
	return tonumber(os.date("%H")) * 3600 + tonumber(os.date("%M")) * 60 + tonumber(os.date("%S"));
end

check_path = function(path)
	local file = io.open(path, "r");
	if file == nil then return false; end
	io.close(file);
	return true;
end

write_file = function()
	local path = os.getenv("HOME") .. "/.config/tomato/summary/";
	if check_path(path) == false then 
		run("mkdir -p " .. path);
	end
	local infor = "[Totale work title]\n" .. totale_work_time .. " minutes\n[Totale rest title]\n" .. totale_rest_time .. " minutes\n[Speeded up rest time]\n" .. speed_up_rest_time .. " minutes\n[Put off work time]\n" .. put_off_work_time .. " minutes\n[Put off rest time]\n" .. put_off_rest_time .. " minutes\n";
	local date = os.date("%Y") .. os.date("%m") .. os.date("%d") .. "_" .. os.date("%H") .. os.date("%M") .. os.date("%S");
	local path = path .. date .. ".txt";
	local file = io.open(path, "w");
	file:write(infor);
	io.close(file);
end

note = function()
	run("zenity --notification --text 'Totale work time: " .. totale_work_time .. " minutes'");
	run("zenity --notification --text 'Totale rest time: " .. totale_rest_time .. " minutes'");
	run("zenity --notification --text 'Speeded up rest time: " .. speed_up_rest_time .. " minutes'");
	run("zenity --notification --text 'Put off work time: " .. put_off_work_time .. " minutes'");
	run("zenity --notification --text 'Put off rest time: " .. put_off_rest_time .. " minutes'");
end

exit = function()
	local choose = run("zenity --question --title='" .. title .. "' --cancel-label='Yes' --ok-label='No' --text='Are you sure to exit this application?' --no-wrap --default-cancel");
	if choose == 1 then 
		note();
		write_file();
		os.exit(0); 
	end
end

ready = function(thing)
	return run("zenity --question --title='" .. title .. "' --cancel-label='Start' --ok-label='Exit' --text='Click 'Start' when you are ready to " .. thing .. "' --no-wrap --default-cancel");
end

main = function()
	local tTime = get_time();
	local choose = ready("work");
	while choose == 0 do 
		exit();
		choose = ready("work");
	end
	
	-- Calculate the put off work time
	if first_time == false then 
		tTime = (get_time() - tTime) / 60;
		put_off_work_time = put_off_work_time + tTime - tTime % 1;
	end
	first_time = false;

	-- Working
	tTime = get_time();
	print(os.execute("sleep " .. (work_time * 60)));
	tTime = (get_time() - tTime) / 60;
	totale_work_time = totale_work_time + tTime - tTime % 1;

	choose = run("zenity --question --title='" .. title .. "' --cancel-label='Have a rest' --ok-label='Wait' --text='Time is up, Have a rest.' --no-wrap --default-cancel");
	if choose == 0 then
		local tTime = get_time();
		choose = ready("rest");
		while choose == 0 do
			exit();
			choose = ready("rest");
		end
		tTime = (get_time() - tTime) / 60;
		put_off_rest_time = put_off_rest_time + tTime - tTime % 1;
	end

	tTime = get_time();
	for i = 1, rest_time, 1 do
		local status = run("zenity --info --title='" .. title .. "' --ok-label='Enter to speed up' --text='Back to work after " .. rest_time - i + 1 .. " minutes.' --no-wrap --timeout=60");
		if status ~= 60 then speed_up_rest_time = speed_up_rest_time + 1; end
	end
	tTime = (get_time() - tTime) / 60;
	totale_rest_time = totale_rest_time + tTime - tTime % 1;
end

while true do
	main();
end
