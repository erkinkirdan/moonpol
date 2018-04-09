local lm	= require "libmoon"
local device	= require "device"
local stats	= require "stats"
local memory	= require "memory"

local SRC_MAC	= "00:00:00:00:00:00"
local DST_MAC	= "00:00:00:00:00:00"
local SRC_IP	= "10.0.0.0"
local DST_IP	= "20.0.0.0"
local SRC_PORT_BASE	= 1234
local DST_POR	= 1234
local PKT_LEN -- min:60 (default), max:1514
local NUM_FLOWS	= 1000

function configure(parser)
	parser:option("-p --packetsize", "Packet size."):args(1):convert(tonumber):default(60)
	return parser:parse()
end

function master(args)
	PKT_LEN = args.packetsize
	local dev = device.config{port = 0}
	device.waitForLinks()
	stats.startStatsTask{dev}
	local mempool
	local txQ = dev:getTxQueue(0)
	mempool = memory.createMemPool(function(buf)
		buf:getUdpPacket():fill{
			ethSrc = SRC_MAC,
                        ethDst = DST_MAC,
                        ip4Src = SRC_IP,
                        ip4Dst = DST_IP,
                        udpSrc = SRC_PORT,
                        udpDst = DST_PORT,
                        pktLength = PKT_LEN
                }
        end)
        local bufs = mempool:bufArray()
        while lm.running() do
                bufs:alloc(PKT_LEN)
                for i, buf in ipairs(bufs) do
                        local pkt = buf:getUdpPacket()
                        pkt.udp:setSrcPort(SRC_PORT_BASE + math.random(0, NUM_FLOWS - 1))
                        pkt.ip4:setSrc(math.random(0, 2 ^ 32 - 1))
                end
                bufs:offloadUdpChecksums()
                txQ:send(bufs)
        end
end
