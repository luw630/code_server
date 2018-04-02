collectgarbage("setpause", 100)
collectgarbage("setstepmul", 5000)
math.randomseed(tostring(os.time()):reverse():sub(1, 6))
print = function (...) end
local _ALERT_count = 0
function _ALERT(str) 
	_ALERT_count = _ALERT_count + 1
	if _ALERT_count < 1000 then -- 防止日志文件爆炸
		log_assert(str) 
	end
end
-------------------------------
DEF_NUM_MAX = 0x7fffffffffffffff
ly_cash_switch = 0
ly_game_switch = 0
ly_cash_ali_switch = 0
ly_cash_bank_switch = 0
g_ly_game_switch_list = {}
ly_robot_stores_mode = false
ly_jjj_value = 300
ly_jjj_limit_line = 200
ly_jjj_time_limit = 2
ly_ip_limit = true
ly_use_robot = false
ly_robot_storage = DEF_NUM_MAX 
ly_robot_smart_lv = 0 
ly_add_robot_random_time = 200
g_zjh_tb_maxplayernum = 5
auto_broadcast_money_limit = 200*100
g_robot_guid_cfg = {begin = 100, last = 24000 }
ly_niuniu_banker_times = 0			--牛牛系统当庄次数 当天
ly_android_online_count = 0
ly_ios_online_count = 0
ly_brnn_chi_cfg = {}
ly_kill_list = {} --杀猪名单
ly_black_list = {}
g_ly_playerpromotion = {}
g_notify_list = {}
ly_robot_name = {
	"子部", "一杯倒地", "大强哥 ", "弟大", "一眼万年","东三大师","笨笨","刀刀烈火",
	"农民一哥", "万里江河", "走走走 ", "崩盘局", "往事不堪","计划失败","阿尔法狗","大犇哥",
	"摩托变宝马", "刺刺玩", "滚粗 ", "让你跳", "来一手","大表哥02","大哥911","广东扛把子",
	"山ji哥", "浩南", "铜锣湾三爷 ", "sada", "本恶哥","牛逼了","老槐树","西北风",
	"三观不正", "BBC", "TTpp ", "atp", "哒哒di","dota09","lumaopi","12306",
	"13512564359", "897589743", "456qaw ", "xia天", "vsbv","喋血老虎机","kuangren","seller",
	"001sky", "13524558978", "北极光 ","nima","201411","ds19871202",
	"lkv7424", "湖南人", "隐de士", "赢&&08", "lao爷","uussxn","赢他一个亿","我要赢",
	"tonghua", "试试", "取个名字 ", "742dsa036987", "cx4784sdad4","lixian1986","sk15883678524","13583754568",
	"244144789", "东山再起", "连赢10把", "来个三同","KQA",
	"玩家987","玩家1987","玩家2317","玩家5896","玩家3258","玩家7854","玩家1254","玩家6984","玩家2433",
	"玩家564","玩家2347","玩家9526","玩家3298","玩家2047","玩家4069","玩家1027","玩家1224","玩家78",
	"玩家2963","玩家3041","玩家4096","玩家3721","玩家4520","玩家8847","玩家6154","玩家7203","玩家4463",
	"玩家369","玩家472","玩家617","玩家86","玩家4114","玩家5446","玩家1583","玩家2009","玩家2538",

	"玩家3536","玩家5687","玩家317","玩家696","玩家788","玩家904","玩家3254","玩家4284","玩家2333",
	"玩家674","玩家8047","玩家5526","玩家6598","玩家3447","玩家2369","玩家4527","玩家6124","玩家878",
	"玩家363","玩家641","玩家486","玩家5221","玩家3420","玩家2847","玩家6454","玩家2103","玩家3163",
	"玩家3449","玩家562","玩家434","玩家840","玩家2314","玩家6796","玩家1233","玩家2549","玩家308",

	"玩家13536","玩家15687","玩家12317","玩家14696","玩家17788","玩家10904","玩家13254","玩家14284","玩家12333",
	"玩家10674","玩家18047","玩家15526","玩家16598","玩家13447","玩家12369","玩家14527","玩家16124","玩家10878",
	"玩家10363","玩家17641","玩家14486","玩家15221","玩家13420","玩家12847","玩家16454","玩家12103","玩家13163",
	"玩家13449","玩家12562","玩家14434","玩家12840","玩家12314","玩家16796","玩家11233","玩家12549","玩家10308",
}

ly_game_name = {
	[3] = "李逵劈鱼",
	[4] = "李逵劈鱼",
	[5] = "李逵劈鱼",
	[6] = "李逵劈鱼",
	[20] = "斗地主",
	[21] = "斗地主",
	[22] = "斗地主",
	[30] = "炸金花",
	[31] = "炸金花",
	[32] = "炸金花",
	[33] = "炸金花",
	[50] = "百人牛牛",
	[51] = "百人牛牛",
	[110] = "抢庄牛牛",
	[111] = "抢庄牛牛",
	[112] = "抢庄牛牛",
	[113] = "抢庄牛牛",
	[150] = "三公对决",
	[151] = "三公对决",
	[152] = "三公对决",
	[153] = "三公对决",
}

ly_game_name_switch = {}
for k,v in pairs(ly_game_name) do
	ly_game_name_switch[#ly_game_name_switch + 1] = k
end

ly_robot_addr_mgr = {
	"黑龙江伊春","黑龙江大庆","山西运城","山西临汾","山西晋城","山西晋中",
	"吉林通化","吉林四平","四川内江","四川广元",
	"江苏徐州","山东青岛","山东潍坊","山东淄博","山东临沂","安徽蚌埠",
	"湖北荆州","湖南株洲","湖北荆州","广西玉林","湖北孝感",
	"安徽亳州","河南洛阳","河南焦作","河南濮阳","河南许昌",
	"海南三亚","湖北武汉","湖北宜昌","湖北襄阳","湖北天门","湖北黄冈",
	"广东佛山","广东韶关","广东惠州","广东珠海","广东湛江",
	"广东中山","广东河源","广东清远","广东云浮","广东潮州",
	"浙江杭州","浙江台州","浙江衢州","江苏南京","江苏宿迁",
	"江苏连云港","江苏泰州","江苏扬州","江苏徐州","江苏南通",
	"广西桂林","广西梧州","甘肃张掖","内蒙古包头","山西临汾",
    "陕西铜川","陕西安康","陕西延安","贵州六盘水","河南平顶山","河南鹤壁","广东肇庆",
	"广东汕尾","广东广州","广东揭阳","广东梅州","四川德阳",
	"广东阳江","广东茂名","福建泉州","福建莆田","福建宁德",
	"福建漳州","福建龙岩","福建三明","浙江湖州","浙江嘉兴",
	"四川遂宁","四川南充","贵州毕节","河北张家口","河北秦皇岛","山西阳泉",
	"陕西汉中","江西赣州","江西鹰潭","江西九江","江苏南京","江苏常州",
	"陕西西安","河北石家庄","山东济南","吉林长春","湖北武汉",
	"辽宁锦州","辽宁丹东","辽宁鞍山","辽宁本溪","广东广州","广东深圳",
	"山西太原","江西南昌","山东青岛","湖南长沙","重庆重庆","河南郑州",
	"广东江门","广东东莞","广东汕头","上海上海","北京北京",
	"云南昆明","甘肃兰州","贵州贵阳","福建福州","西藏拉萨","天津天津",
	"四川成都","江苏南京","福建厦门","安徽合肥","广西南宁",
}
ly_robot_mgr={}
ly_robot_mgr.robot_list = {}
ly_robot_mgr.ip_table = ly_robot_addr_mgr

reg_file_map = 
{
	fishing	= "fishing",
	land	= "ddz",
	zhajinhua	= "zjh",
	ox	= "brnn",
	banker_ox	= "qznn",
	classic_ox	= "qznn",
	showhand	= "showhand",
	texas	= "texas",
	point21	= "point21",
	sangong	= "sangong",
	hongheidz = "hhdz",
	longhudz = "longhu",
}
------------------------------------
--[[
local use_log = true
local lua_log_info 		= log_info
local lua_log_error 	= log_error
local lua_log_warning 	= log_warning
local lua_log_debug 	= log_debug
local lua_log_assert 	= log_assert

log_info 	= function (...) if use_log then lua_log_info(...) end end
log_error 	= function (...) if use_log then lua_log_error(...) end end
log_warning = function (...) if use_log then lua_log_warning(...) end end
log_debug 	= function (...) if use_log then lua_log_debug(...) end end
log_assert 	= function (...) if use_log then lua_log_assert(...) end end
]]
------------------------------------

ox_bet_num=3
ox_bet_tb={low={100,500,1000},high={500,1000,5000}}
many_ox_room_config = {
	[1] = { Ox_FreeTime = 3, 
			Ox_BetTime = 18,
			Ox_EndTime = 15,
			Ox_MustWinCoeff = 5,
			Ox_FloatingCoeff = 3,
			Ox_bankerMoneyLimit = 10000*100,
			Ox_SystemBankerSwitch = 1,
			Ox_BankerCount = 5,
			Ox_RobotBankerInitUid = 500000,
			Ox_RobotBankerInitMoney = 10000000,
			Ox_BetRobotSwitch = 1,
			Ox_BetRobotInitUid = 600000,
			Ox_BetRobotInitMoney = 35000,
			Ox_BetRobotNumControl = 5,
			Ox_BetRobotTimeControl = 10,
			Ox_RobotBetMoneyControl = 10000,
			Ox_PLAYER_MIN_LIMIT = 1000,
			Ox_basic_chip = ox_bet_tb.high 
			},
	[2] = {	Ox_FreeTime = 3, 
			Ox_BetTime = 18,
			Ox_EndTime = 15,
			Ox_MustWinCoeff = 5,
			Ox_FloatingCoeff = 3,
			Ox_bankerMoneyLimit = 10000*100,
			Ox_SystemBankerSwitch = 1,
			Ox_BankerCount = 5,
			Ox_RobotBankerInitUid = 700000,
			Ox_RobotBankerInitMoney = 10000000,
			Ox_BetRobotSwitch = 1,
			Ox_BetRobotInitUid = 800000,
			Ox_BetRobotInitMoney = 15000,
			Ox_BetRobotNumControl = 5,
			Ox_BetRobotTimeControl = 10,
			Ox_RobotBetMoneyControl = 10000,
			Ox_PLAYER_MIN_LIMIT = 1000,
			Ox_basic_chip =ox_bet_tb.low
			 }
}


zhajinhua_room_score = {
	[1] = {[10] = 10, [20] = 20, [50] =50, [80] = 80, [100] = 100},
	[2] = {[100] = 100, [200] = 200, [500] =500, [800] = 800, [1000] = 1000},
	[3] = {[500] = 500, [1000] = 1000, [2500] = 2500, [4000] = 4000, [5000] = 5000},
	[4] = {[1000] = 1000, [2000] = 2000, [5000] = 5000, [8000] = 8000, [10000] = 10000},
	[5] = {[2000] = 2000, [4000] = 4000, [10000] = 10000, [16000] = 16000, [20000] = 20000}
}

data_online = {
	{cd = 60*1, money = 500},
	{cd = 60*5, money = 1000},
	{cd = 60*10, money = 1500},
	{cd = 60*15, money = 2000},
	{cd = 60*20, money = 2500},
	{cd = 60*30, money = 3000},
	{cd = 60*30, money = 3500},
	{cd = 60*30, money = 4000},
	{cd = 60*30, money = 4500},
	{cd = 60*30, money = 5000},
}
data_login = {
	1000,
	1500,
	2000,
	3000,
	5000,
}
notify_win_big_money_str = {
	[1] = "厉害了，<%s> 在<%s>狂赢了<%d>金币 ！",
	[2] = "恭喜恭喜，<%s> 在<%s>赚取了<%d>金币 ！",
	[3] = "快报！快报！<%s> 在<%s>斩获了<%d>金币 ！",
}

def_game_id_table = {
	[1] = 1,
	[3] = 3,
	[4] = 3,
	[5] = 3,
	[6] = 3,
	[20] = 5,
	[21] = 5,
	[22] = 5,
	[30] = 6,
	[31] = 6,
	[32] = 6,
	[33] = 6,
	[40] = 7,
	[41] = 7,
	[42] = 7,
	[43] = 7,
	[50] = 8,
	[51] = 8,
	[80] = 11,
	[81] = 11,
	[82] = 11,
	[83] = 11,
	[110] = 14,
	[111] = 14,
	[112] = 14,
	[113] = 14,
	[150] = 18,
	[151] = 18,
	[152] = 18,
	[153] = 18,
	[160] = 19,
	[170] = 20,
}