local lm	= require "libmoon"
local device	= require "device"
local stats	= require "stats"
local memory	= require "memory"
local ffi	= require "ffi"

local BUCKET	= 2

ffi.cdef[[
	typedef struct {float tokens; uint32_t bucket_size;} subnet;
]]

local tbl24
local tbllong
local subnets
local subnetcounter
local counter
local loginterval = 10
local round = 1000000000000

function getsubnetid(ip)
	local a = bit.rshift(ip, 24)
        local b = bit.rshift(ip, 16) - bit.lshift(a, 8)
        local c = bit.rshift(ip, 8) - bit.lshift(b, 8) - bit.lshift(a, 16)
        local d = ip - bit.lshift(c, 8) - bit.lshift(b, 16) - bit.lshift(a, 24)
        local index1 = c + bit.lshift(b, 8) + bit.lshift(a, 16)
	if tbl24[index1] == 0 then
		return 0
	end
	if tbl24[index1] > 0 and tbl24[index1] % 10 == 0 then
                return tbl24[index1] / 10
        else
		local index2 = ((tbl24[index1] - 1) / 10) * 256 + d
                return tbllong[index2] / 10
        end
end

function removetoken(id)
	if id == 0 then
		return 1
	end
	if subnets[id].tokens >= 1 then
        	subnets[id].tokens = subnets[id].tokens - 1
                return 1
        end
	return 0
end

function addtoken(interval)
	for  i = 1, subnetcounter do
		subnets[i].tokens = subnets[i].tokens + interval * subnets[i].bucket_size / BUCKET
		if subnets[i].tokens > subnets[i].bucket_size then
			subnets[i].tokens = subnets[i].bucket_size
		end
	end
end

function readconfig()
	local config = io.open("./config", "r")
	subnetcounter = 0
	local tmp0 = 0
	local tmp1 = 0
	while true do
		local line = config:read()
		if line == nil then
			break
		end
		subnetcounter = subnetcounter + 1
		for word in string.gmatch(line, '[^./	]+') do
			if tmp0 == 4 then
				if tonumber(word) > 24 then
					tmp1 = tmp1 + 1
				end
			end
			tmp0 = tmp0 + 1
			if tmp0 == 6 then
				tmp0 = 0
			end
		end
	end
	io.close(config)
	tbl24 = ffi.new("uint32_t[16777216]")
	tbllong = ffi.new("uint32_t[?]", tmp1 * 256)
	config = io.open("./config", "r")
	subnets = ffi.new("subnet[?]", (subnetcounter + 1))
	counter = ffi.new("uint32_t[?]", ((subnetcounter + 1) * 2))
	tmp0 = 0
	tmp1 = 1
	local tmp2 = 0
       	while true do
                local line = config:read()
                if line == nil then
			break
		end
                local a, b, c, d, p, l
		for word in string.gmatch(line, '[^./	]+') do
			if tmp0 == 0 then
                                a = tonumber(word)
                        end
                        if tmp0 == 1 then
                                b = tonumber(word)
                        end
                        if tmp0 == 2 then
                                c = tonumber(word)
                        end
                        if tmp0 == 3 then
                                d = tonumber(word)
                        end
                        if tmp0 == 4 then
                                p = tonumber(word)
                        end
                        if tmp0 == 5 then
                                l = tonumber(word)
                        end
                        tmp0 = tmp0 + 1
                        if tmp0 == 6  then
				tmp0 = 0
			end
		end
		if p < 25 then
			local index = c + bit.lshift(b, 8) + bit.lshift(a, 16)
			local space = 2 ^ (24 - p)
			for i = 0, space - 1 do
				tbl24[index + i] = tmp1 * 10
			end
		else
			tbl24[c + bit.lshift(b, 8) + bit.lshift(a, 16)] = tmp2 * 10 + 1
			local index = tmp2 * 256 + d
			local space = 2 ^ (32 - p)
			for i = 0, space - 1 do
				tbllong[index + i] = tmp1 * 10
			end
			tmp2 = tmp2 + 1
		end
		subnets[tmp1].bucket_size = BUCKET * l
		subnets[tmp1].tokens = BUCKET * l
		counter[tmp1 * 2] = 0
		counter[tmp1 * 2 + 1] = 0
		tmp1 = tmp1 + 1
	end
	io.close(config)
end

function master()
	readconfig()
	local dev = device.config{port = 0}
	device.waitForLinks()
	stats.startStatsTask{dev}
	local rxQ = dev:getRxQueue(0)
	local txQ = dev:getTxQueue(0)
	local rxBufs = memory.bufArray()
	local txBufs = memory.bufArray()
	local tokenlast = lm.getTime()
	local tokeninterval
	local roundctr = 0
	while lm.running() do
		local rx = rxQ:recv(rxBufs)
		local j = 0
		for i = 1, rx do
			local id = getsubnetid(rxBufs[i]:getUdpPacket().ip4:getSrc())
                	if removetoken(id) > 0 then
				j = j + 1
				txBufs[j] = rxBufs[i]
				local pkt = txBufs[j]:getUdpPacket()
                        	pkt.eth:setDst(DST_MAC)
                        	pkt.eth:setSrc(SRC_MAC)
			else
				rxBufs[i]:free()
			end
		end
		roundctr = roundctr + 1
		if roundctr >= round then
			tokeninterval = lm.getTime() - tokenlast
                	tokenlast = lm.getTime()
               		addtoken(tokeninterval)
			roundctr = 0
		end
		txQ:sendN(txBufs, j)
        end
	lm.waitForTasks()
end
