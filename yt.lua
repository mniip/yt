#!/usr/bin/lua
local function unurl(x)
	return (x:gsub("%%(..)",function(x)return string.char(tonumber(x,16))end))
end
local function unjs(x)
	return (x:gsub("\\u(....)",function(x)return string.char(tonumber(x,16))end))
end
local function backtick(x)
	local f=io.popen(x)
	if f then
		local s=f:read"*a"
		f:close()
		return s
	end
end
local function wflush(x)
	io.write(x)
	io.stdout:flush()
end
assert(arg[1],"Must specify an URI or an ID")
local id=assert(arg[1]:match"[?&]v=([^&]*)"or arg[1],"Could not find and ID in:\n"..arg[1])
assert(not id:match"[^a-zA-Z0-9_-]","Does not look like a valid ID:\n"..id)
wflush"Fetching headers... "
local page=assert(backtick("wget -qO- http://youtube.com/watch?v="..id),"Could not fetch http://youtube.com/watch?v="..id)
print"Done"
local formats=unjs(assert(page:match'"adaptive_fmts": "([^"]*)',"Could not find format specifiers"))
local formattbl={}
for p in formats:gmatch"[^&,]+" do
	local k,v=p:match"^([^=]*)=(.*)$"
	if not k then
		print("Odd format specifier: "..p)
	end
	table.insert(formattbl,{unurl(k),unurl(v)})
end
local audios={}
local videos={}
local i=#formattbl
local sep=formattbl[i][1]
while i>0 do
	assert(formattbl[i][1]==sep,"Expected "..sep..", got: "..formattbl[i][1])
	local fmt={}
	local k,v=formattbl[i][1],formattbl[i][2]
	fmt[k]=v
	i=i-1
	while i>0 do
		local k,v=formattbl[i][1],formattbl[i][2]
		if k==sep then
			break
		end
		fmt[k]=v
		i=i-1
	end
	if fmt.url then
		if fmt.type then
			local kind,codec=fmt.type:match"^([^/]*)/(.*)$"
			fmt.codec=(codec or""):gsub('+codecs="([^"]*)"',"%1")
			if kind=="audio" then
				table.insert(audios,fmt)
			elseif kind=="video" then
				table.insert(videos,fmt)
			else
				print("Neither video nor audio, ignoring:\n"..fmt.type)
			end
		else
			print"Format without a type, ignoring"
		end
	else
		print"Format without an url, ignoring"
	end
end
local af,aurl
local vf,vurl
if #audios>0 then
	local n=arg[2]
	if n=="" then n=nil end
	if not n then
		print"Following audio formats available:"
		print"0) Do not download audio at all"
		print"+) Pick best"
		print"-) Pick smallest"
		for i,v in pairs(audios) do
			print(("%d) codec=%s   bitrate=%d Kbit/s"):format(i,v.codec or"?",v.bitrate and v.bitrate/1024 or"?"))
		end
		wflush"Choose one >"
		n=io.read"*l"
	end
	if n=="+" then
		local maxb,choice=0,0
		for i,v in ipairs(audios) do
			if (tonumber(v.bitrate)or 0)>maxb then
				maxb=tonumber(v.bitrate)
				choice=i
			end
		end
		n=choice
	elseif n=="-" then
		local maxb,choice=1e309,0
		for i,v in ipairs(audios) do
			if (tonumber(v.bitrate)or 0)<maxb then
				maxb=tonumber(v.bitrate)
				choice=i
			end
		end
		n=choice
	else
		n=assert(tonumber(n))
		if n<0 then
			n=#audios+n+1
		end
	end
	print("Picking number "..n)
	if audios[n] then
		local ext=(audios[n].codec or "?"):match"^[^;]*"
		af=id..".a."..ext
		aurl=audios[n].url
		print("Saving as "..af)
	end
else
	print"No audio formats available"
end
if #videos>0 then
	local n=arg[3]
	if n=="" then n=nil end
	if not n then
		print"Following video formats available:"
		print"0) Do not download audio at all"
		print"+) Pick best"
		print"-) Pick smallest"
		for i,v in pairs(videos) do
			print(("%d) %s   codec=%s   bitrate=%d Kbit/s"):format(i,v.size or"?x?",v.codec or"?",v.bitrate and v.bitrate/1024 or"?"))
		end
		wflush"Choose one >"
		n=io.read"*l"
	end
	if n=="+" then
		local maxb,choice=0,0
		for i,v in ipairs(videos) do
			if (tonumber(v.bitrate)or 0)>maxb then
				maxb=tonumber(v.bitrate)
				choice=i
			end
		end
		n=choice
	elseif n=="-" then
		local maxb,choice=1e309,0
		for i,v in ipairs(videos) do
			if (tonumber(v.bitrate)or 0)<maxb then
				maxb=tonumber(v.bitrate)
				choice=i
			end
		end
		n=choice
	else
		n=assert(tonumber(n))
		if n<0 then
			n=#videos+n+1
		end
	end
	print("Picking number "..n)
	if videos[n] then
		local ext=(videos[n].codec or "?"):match"^[^;]*"
		vf=id..".v."..ext
		vurl=videos[n].url
		print("Saving as "..vf)
	end
else
	print"No video formats available"
end
print"Downloading"
if af then
	if vf then
		os.execute("wget -O '"..vf.."' '"..vurl.."' &wget -O '"..af.."' '"..aurl.."';wait $!")
		print"Attempting to merge the audio and video"
		os.execute([[
			if test -s ]]..af..[[;then
				if test -s ]]..vf..[[;then
					if hash ffmpeg;then
						ffmpeg -i ]]..af..[[ -i ]]..vf..[[ -c:v copy -c:a copy -strict experimental ]]..id..[[.mp4
					else
						if hash avconv;then
							avconv -i ]]..af..[[ -i ]]..vf..[[ -c:v copy -c:a copy ]]..id..[[.mp4
						else
							echo No video converter found
						fi
					fi
				else
					echo Video file not present
				fi
			else
				echo Audio file not present
			fi
		]])
	else
		os.execute("wget -O '"..af.."' '"..aurl.."'")
	end
else
	if vf then
		os.execute("wget -O '"..vf.."' '"..vurl.."'")
	else
		print"Nothing to download"
	end
end
print"Done"
