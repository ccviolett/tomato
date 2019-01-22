#!/usr/bin/lua

local title = "Tomato Time Limit";
local first_time = true;
local work_time = 25;
local rest_time = 5;

local speed_up_rest_time = 0;
local put_off_rest_time = 0;
local put_off_work_time = 0;

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

write_file = function()
	run("zenity --notification --text 'You have speeded up " .. speed_up_rest_time .. " minutes your rest time'");
	run("zenity --notification --text 'You have put off " .. put_off_work_time .. " minutes your work time'");
	run("zenity --notification --text 'You have put off " .. put_off_rest_time .. " minutes your rest time'");
end

exit = function()
	choose = run("zenity --question --title='" .. title .. "' --cancel-label='Yes' --ok-label='No' --text='Are you sure to exit this application?' --no-wrap --default-cancel");
	if choose == 1 then 
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
	print(os.execute("sleep " .. (work_time * 60)));

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

	for i = 1, rest_time, 1 do
		local status = run("zenity --info --title='" .. title .. "' --ok-label='Enter to speed up' --text='Back to work after " .. rest_time - i + 1 .. " minutes.' --no-wrap --timeout=60");
		if status ~= 60 then speed_up_rest_time = speed_up_rest_time + 1; end
	end
end

while true do
	main();
end
