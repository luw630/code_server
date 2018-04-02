local scriptlist = {}
local equipdir = "D://work//3th//Hy_CardServer//server//project//data//script//game_script//virtual//"
function delnote( filename,newfilename) --替换和删除pb.enum_id
	local file = io.open(filename,"r")
	local nfile = io.open(newfilename,"w")
	if file ~= nil then
		 local tag = {}
		 local line = 1
		 for i in file:lines("*l") do 
			 for k, v in string.gmatch(i, "(%g+) = (%w.+)") do
			 	if string.find(v,"pb.enum_id") ~= nil then
			 		 tag[k] = {v,line}
		 		end
		     end

		     for k, v in string.gmatch(i, "(%g+)=(%w.+)") do
			 	if string.find(v,"pb.enum_id") ~= nil then
			 		 tag[k] = {v,line}
		 		end
		     end

		     for k, v in string.gmatch(i, "(%g+)= (%w.+)") do
			 	if string.find(v,"pb.enum_id") ~= nil then
			 		 tag[k] = {v,line}
		 		end
		     end

		     for k, v in string.gmatch(i, "(%g+) =(%w.+)") do
			 	if string.find(v,"pb.enum_id") ~= nil then
			 		 tag[k] = {v,line}
		 		end
		     end
		     line = line + 1
		 end
		 line = 1
		 file:close()
		 file = io.open(filename,"r")
		 for i in file:lines("*l") do 
		 	local newline = i
			 for k,v in pairs(tag) do
				if line ~= v[2] then
					local locst,loced = string.find(i,k)
					if locst ~= nil then
						if locst > 1 then
							newline = string.sub(i,1,locst-1)..v[1]..string.sub(i,loced+1)
						else
							newline = v[1]..string.sub(i,loced+1)
						end
						break
					end
				else
					newline=""
				end
			 end
			 if newline ~= "" then
			 	nfile:write(newline.."\n")
			 end
			 line = line + 1
		end
	end
	if file ~= nil then
		file:close()
	end
	nfile:close()
end


function getfilelist( ... )
	local filelist = io.popen("dir /B")
	if filelist ~= nil then
		for c in filelist:lines("*l") do 
			local tag = string.find(c,".lua")
			if tag~= nil then
				local newfilename = "new//"..c
				scriptlist[equipdir..c] = equipdir..newfilename
				--print(filename,newfilename)
				os.execute("type nul>"..newfilename)
			end
		end
	end
end

function delallnote( ... )
	getfilelist()
	for k,v in pairs(scriptlist) do
		delnote(k,v)
	end
end
--getfilelist()
delallnote()
--delnote(equipdir.."handler_login_logout.lua",equipdir.."handler_login_logout_n.lua")