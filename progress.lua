#!/usr/bin/lua
to_int = function(num)
	if string.find(num, "%.") == nil then return num; end
	return string.sub(num, 1, string.find(num, "%.") - 1); 
end

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

count_time(arg[1]);
