_G.Net = _G.ScriptHelperNetInterface
_G.Client = _G.ScriptHelperClient
_G.Tss = _G.TssManager
if not Client then
  return
end
require("client.slua.logic.HDmpveRemote.HDmpveRemote")
slua.RegCustomErrorTraceback()
if IsEditor or IsWoWEditor and Client.IsDevelopment() then
  GameInstanceID = GameInstanceID or 0
  if _G.IsEnableMockGameSvr then
    GameInstanceID = GameInstanceID + 1
  end
  require("LuaPanda").start("127.0.0.1", 8818 + GameInstanceID)
end

function Client.GetTable(...)
  error("Use CDataTable.GetTable instead!")
end

function Client.GetTableData(...)
  error("Use CDataTable.GetTableData instead!")
end

Client.bEditorSkipDownload = IsEditor and not Client.IsSplitMapPakVersion()
if not Client.IsShipping() then
else
  function assert(condition, msg)
    if not condition then
      msg = msg or "assertion failed!"
      
      local utility = require("common.utility")
      utility.ErrorMessageHandler(msg)
      return false
    end
    return true
  end
end
local GisInWaiting = false
require("client.config.global")
require("common.log")
require("common_ustruct")
require("client.common.game_status")
require("common.gc_util")
require("client.slua.config.sound_config")
require("client.logic.ClientEntry.require_old_files")
if Client.IsDevelopment() then
  require("client.logic.gm.RequireBlackList")
  local LuaAPITimeTracer = RequireBlackList("blacklist.editor.runtime_check.LuaAPITimeTracer")
  if LuaAPITimeTracer then
    log(bWriteLog and "Client_entry StartTracer")
    LuaAPITimeTracer.StartTracer()
  end
  local logic_local_lua_info = GetModuleForBlackList(ModuleManager.CommonModuleConfig.logic_local_lua_info)
  if logic_local_lua_info then
    logic_local_lua_info:CollectLocalLuaInfo()
  else
    log(bWriteLog and "no logic_local_lua_info  ")
  end
end
if not Client.IsReleaseVersion(NetInterface) then
  require("blacklist.tools.ScreenShotReport.ScreenShotReport")
end
_G.UnrealNet = UnrealNet or {}
_G.NetUtil = NetUtil or {
  s2cNeedWaiting = {},
  tNetDisconnected = 0,
  tNetConnecting = 0,
  tNetConnected = 0,
  nDSTimeOutShowBitMask = 0,
  DSTimeOutLong = 1,
  DSTimeOutShort = 2
}
local EventSystem = require("client.common.event.EventSystem")
local xpcall = _ENV.xpcall
local utility = require("common.utility")
local xpcallHandle = utility.ErrorMessageHandler
local TimeUtil = require("client.common.time_util")
local EmulatorSystem = require("client.logic.login.logic_emulator")
local NetManager = require("client.network.comm.NetManager")
local NetHeartBeatHandler = require("client.network.Protocol.NetHeartBeatHandler")
local PublishRegionMacros = require("client.slua.config.ClientMacros.PublishRegionMacros")
NetUtil.ConnectSDKTimeOutSeconds = 15
NetUtil.ConnectLuaTimeOutSeconds = 20
NetUtil.SendTime = NetUtil.SendTime or 0
NetUtil.SendOneTime = NetUtil.SendOneTime or 0
NetUtil.LobbyDelaySendTime = NetUtil.LobbyDelaySendTime or 0
NetUtil.LobbyDelayRecvTime = NetUtil.LobbyDelayRecvTime or 0
NetUtil.gameTick = NetUtil.gameTick or false
NetUtil.showConnectionMsgTimes = NetUtil.showConnectionMsgTimes or 0
NetUtil.hasTryConnectForNetworkError = NetUtil.hasTryConnectForNetworkError or false
NetUtil.hasTryConnectForNetworkErrorTimes = NetUtil.hasTryConnectForNetworkErrorTimes or 0
NetUtil.isWattingDelayReconnect = NetUtil.isWattingDelayReconnect or false
NetUtil.checkWaitingReEnterGameNotify = NetUtil.checkWaitingReEnterGameNotify or false
NetUtil.waitingReEnterGameStartTime = NetUtil.waitingReEnterGameStartTime or 0
NetUtil.checkConnectingInFighting = false
NetUtil.checkConnectingInFightingTimes = 0
NetUtil.checkConnectingInFightingRandomInterval = 0
NetUtil.waitingConnectSuccessStartTime = NetUtil.waitingConnectSuccessStartTime or 0
NetUtil.checkEnterBattle = false
NetUtil.waitingEnterBattleStartTime = NetUtil.waitingEnterBattleStartTime or 0
NetUtil.LoadingTimeOut = 70
NetUtil.EnterBattleLoadingTime = 0
NetUtil.checkLoginOtherLobbyServer = false
NetUtil.checkLoginRsp = NetUtil.checkLoginRsp or false
NetUtil.checkLoginRetryTime = NetUtil.checkLoginRetryTime or 0
NetUtil.checkBattleLoginRetryTime = NetUtil.checkBattleLoginRetryTime or 0
NetUtil.sendLoginTime = NetUtil.sendLoginTime or 0
NetUtil.dsTimeOutRetryTimes = NetUtil.dsTimeOutRetryTimes or 0
NetUtil.dsTimeOutTipsUIShowing = NetUtil.dsTimeOutTipsUIShowing or false
NetUtil.CurTickTime = NetUtil.CurTickTime or 0
NetUtil.LastTickTime = NetUtil.LastTickTime or 0
NetUtil.needInitCentauriWhenLogin = NetUtil.needInitCentauriWhenLogin or false
NetUtil.noRefreshLogout = NetUtil.noRefreshLogout or false
NetUtil.LobbyResultMonitor = NetUtil.LobbyResultMonitor or {
  gameover = false,
  gamemode = "",
  lobbyReconnTimes = 0
}
NetUtil.ResultMonitorStarTime = 0
NetUtil.BResultMonitorOpen = false
NetUtil.BBattleResultRecieved = false
NetUtil.PleaseReloginTimer = nil
NetUtil.EnterBattleGameID = ""
NetUtil.STOP_CONNECT = false
NetUtil.EnterBattleTimeOutGameID = 0
NetUtil.EnterBattleStageDelegate = nil
NetUtil.EnterBattleTime = 0

function OnClientGameOver()
  local logic_enter_game = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_enter_game)
  local game_mode = logic_enter_game:GetSubModeId()
  log(bWriteLog and "OnClientGameOver  mapMode:" .. game_mode .. "NetUtil.BBattleResultRecieved:" .. tostring(NetUtil.BBattleResultRecieved))
  if NetUtil.BBattleResultRecieved then
    return
  end
  ResetResultMonitor()
  NetUtil.BResultMonitorOpen = true
  NetUtil.ResultMonitorStarTime = TimeUtil.OSTime()
  NetUtil.LobbyResultMonitor.gameover = true
  NetUtil.LobbyResultMonitor.gamemode = game_mode
end

function ResetResultMonitor()
  NetUtil.ResultMonitorStarTime = 0
  NetUtil.BResultMonitorOpen = false
  NetUtil.LobbyResultMonitor = {
    gameover = false,
    gamemode = 0,
    lobbyReconnTimes = 0
  }
  log_tree("ClientEntry ----- ResetResultMonitor", NetUtil.LobbyResultMonitor)
end

function UpdateResultMonitor()
  if not NetUtil.BResultMonitorOpen then
    return
  end
  if not NetUtil.LobbyResultMonitor then
    return
  end
  if not NetUtil.LobbyResultMonitor.gameover then
    return
  end
  if TimeUtil.OSTime() - NetUtil.ResultMonitorStarTime < 2 then
    return
  end
  NetUtil.ResultMonitorStarTime = TimeUtil.OSTime()
  NetUtil.LobbyResultMonitor.lobbyReconnTimes = NetUtil.LobbyResultMonitor.lobbyReconnTimes + 1
  if NetUtil.LobbyResultMonitor.lobbyReconnTimes < 5 then
    return
  end
  if Client.IsEditorDedicatedServer() then
    log(bWriteLog and "ClientEntry ----- UpdateResultMonitor IsEditorDedicatedServer return")
    return
  end
  log(bWriteLog and "ClientEntry ----- UpdateResultMonitor  Force back to lobby")
  local strTile = LocUtil.GetLocalizeResStr(102012)
  local strMsg = LocUtil.GetLocalizeResStr(77010)
  local CommonMsgBoxMgr = require("client.slua.logic.common.logic_common_msg_box")
  CommonMsgBoxMgr.Show(1, strTile, strMsg, function()
    if GameStatus.IsInFightingStatus() then
      FuncUtil.ShowLoadingToLobby()
      Client.ReturnToLobby(GameFrontendHUD)
      Client.TPerforPlatDisconnectReport(GameFrontendHUD, 17)
      local param = {}
      NetUtil.GEMReportSubEvent("NoConnectWhenResult", param)
      local ClientTLogManager = SubsystemMgr:Get("ClientTLogManager")
      if ClientTLogManager then
        local Data = {}
        ClientTLogManager:SendReportLobby("NoConnectWhenResult", Data, false)
      end
    end
  end)
  ResetResultMonitor()
  return
end

function Tick(DeltaTime)
  NetUtil.CurTickTime = NetUtil.CurTickTime + DeltaTime
  TimeUtil.nLocalTimeTick = TimeUtil.nLocalTimeTick + DeltaTime
  if NetUtil.CurTickTime - NetUtil.LastTickTime > 5 then
    NetUtil.LastTickTime = NetUtil.CurTickTime
  end
  NetUtil.CheckTime()
  NetUtil.OnTick(TimeUtil.OSTime())
  EmulatorSystem.Tick(DeltaTime)
end

function NetUtil.GEMReportSubEvent(SubEventName, array)
  return Client.GEMReportSubEvent(GameFrontendHUD, "BattleNetworkEvent", SubEventName, array)
end

function NetUtil.DispatchPacket(msg, ...)
  local proc = NetManager.ProcRespondMsg
  if not proc then
    log_error(string.format("undefined msg: %s", msg))
    return
  end
  xpcall(proc, xpcallHandle, msg, ...)
end

function NetUtil.SendTss()
  if Tss then
    Tss.SendSkdData(LuaStateWrapper, NetInterface, "on_recv_client_data")
  else
    log_shipping_client("NetUtil.SendTss Tss is nil")
  end
end

function NetUtil.OnTssRsp(datalen, data)
  if Tss then
    Tss.OnRecvData(datalen, data)
  else
    log_shipping_client("NetUtil.OnTssRsp Tss is nil")
  end
end

local function FindInvalidArchiveType(value, path, depth)
  local t = type(value)
  if t == "number" or t == "string" or t == "boolean" or t == "nil" then
    return nil
  elseif t == "table" then
    if 32 < depth then
      return (path or "?") .. " (table too deep)"
    end
    for k, v in pairs(value) do
      local kt = type(k)
      if kt ~= "number" and kt ~= "string" then
        return string.format("%s[<key type=%s>]", path or "?", kt)
      end
      local bad = FindInvalidArchiveType(v, (path or "") .. "." .. tostring(k), depth + 1)
      if bad then
        return bad
      end
    end
    return nil
  else
    return string.format("%s (type=%s)", path or "?", t)
  end
end

function NetUtil.SendPkg(msgName, ...)
  if NetManager and NetManager.isLogMsgAfterLogin then
    if NetManager.logMsgMap[msgName] then
      NetManager.logMsgMap[msgName] = NetManager.logMsgMap[msgName] + 1
    else
      NetManager.logMsgMap[msgName] = 1
    end
  end
  local nArgs = select("#", ...)
  for i = 1, nArgs do
    local arg = select(i, ...)
    local bad = FindInvalidArchiveType(arg, "arg" .. i, 0)
    if bad then
      log_error(string.format([[
NetUtil.SendPkg drop pkg msg=%s invalid archive type at %s
%s]], tostring(msgName), bad, debug and debug.traceback and debug.traceback("", 2) or ""))
      return
    end
  end
  if Client.IsConnected(NetInterface) then
    Net.SendPacket(LuaStateWrapper, NetInterface, msgName, ...)
  else
    log_shipping_client("ClientEntry -----  connection is failed throw pkg " .. msgName)
  end
end

function NetUtil.ConnectToURL(ip)
  if not ip then
    return
  end
  if Client.IsDevelopment() and NetUtil.STOP_CONNECT then
    log(bWriteLog and "NetUtil.ConnectToURL SWITCH TEST RETURN")
    return
  end
  local EnableDNS = HDmpveRemote.HDmpveRemoteConfigGetString("HTTPDNS", "")
  if EnableDNS ~= "EnableHTTPDNS" then
    return NetUtil.ConnectToURLDirectly(ip)
  else
    return NetUtil.ConnectToURLWithDNSProxy(ip)
  end
end

function NetUtil.ConnectToURLDirectly(ip)
  log(bWriteLog and "NetUtil.ConnectToURLDirectly, url = " .. tostring(ip) .. ", time = " .. tostring(TimeUtil.OSTime()))
  log_shipping_client("[Login process] NetUtil.ConnectToURL " .. ", time" .. tostring(TimeUtil.OSTime()))
  NetUtil.SetWindowEditorLoginTokenIndex()
  Client.ConnectToURL(NetInterface, ip, NetUtil.ConnectSDKTimeOutSeconds)
  local logic_lobby_ping_report = require("client.slua.logic.match.logic_lobby_ping_report")
  logic_lobby_ping_report.OnSendConnectToURL()
end

function NetUtil.SetWindowEditorLoginTokenIndex()
  local DevicePlatformNameMacros = require("client.slua.config.ClientMacros.DevicePlatformNameMacros")
  if DevicePlatformNameMacros.IsPC() then
    local IMSDKHelper = import("IMSDKHelper")
    local IMSDKHelperInstance = IMSDKHelper.GetInstance()
    if IMSDKHelperInstance.SetWindowEditorLoginTokenIndex then
      IMSDKHelperInstance:SetWindowEditorLoginTokenIndex(GameInstanceID)
    end
  end
end

function NetUtil.ConnectToURLWithDNSProxy(ip)
  local DNSServerIP = HDmpveRemote.HDmpveRemoteConfigGetString("HTTPDNSServerIP", "")
  Client.ConnectToURLWithDNSProxy(NetInterface, DNSServerIP, ip, NetUtil.ConnectSDKTimeOutSeconds)
  local logic_lobby_ping_report = require("client.slua.logic.match.logic_lobby_ping_report")
  logic_lobby_ping_report.OnSendConnectToURL()
end

function NetUtil.Disconnect()
  log_shipping_client("ClientEntry ----- NetUtil.Disconnect()")
  Client.Disconnect(NetInterface)
end

function NetUtil.MountPakOfMode(sub_mode, ugc_map_id)
  local MatchModeMgrSystem = require("client.slua.logic.match.logic_mode_mgr")
  local mapKey = MatchModeMgrSystem.GetMapKeyBySubMode(sub_mode, ugc_map_id)
  local PufferTlog = require("client.slua.logic.download.report.puffer_tlog")
  log(bWriteLog and "SubMode: " .. tostring(sub_mode))
  Client.AddAttachFileString("mountmodpaks", true, "sub_mode:" .. tostring(sub_mode) .. " mapKey:" .. tostring(mapKey))
  if mapKey then
    local mapFiles = {}
    local PufferMapManager = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.puffer_map_manager)
    mapFiles = PufferMapManager:GetDependMapFiles(mapKey, sub_mode, ugc_map_id)
    for i in pairs(mapFiles) do
      log(bWriteLog and string.format("NetUtil.MountPakOfMode mapFileName:%s", i))
    end
    local mapKeys = {}
    if mapFiles and next(mapFiles) then
      for filename, key in pairs(mapFiles) do
        mapKeys[key] = true
        local path = Client.ProjectSavedDir() .. "Paks/" .. filename
        if not Client.IsFileExistsWithOutPakCheck(path) then
          PufferTlog.SendTLog(PufferTlog.Enum_TLog_From.MissingPak, PufferTlog.Enum_TLog_Optype.Finish, filename)
          local mountResult = " Path:" .. path .. " not exist!"
          Client.AddAttachFileString("mountmodpaks", false, mountResult)
          local StringUtil = require("common.string_util")
          local splits = StringUtil.Split(filename, ".")
          if splits[1] and splits[2] then
            local pre = splits[1] .. "." .. splits[2]
            local ret = GCPufferDownloader.ReturnLocalFiles(PufferDownloader.DOWNLOAD_DIR_RELATIVE, "")
            local replaceFileName = ""
            for _, localFileName in pairs(ret) do
              if string.find(localFileName, pre) and (replaceFileName == "" or localFileName > replaceFileName) then
                replaceFileName = localFileName
              end
            end
            if replaceFileName ~= "" then
              path = Client.ProjectSavedDir() .. "Paks/" .. replaceFileName
              if not Client.IsMounted(path) then
                Client.MountPakFile(path, "")
              end
            end
          end
        else
          local mountResult = " Path:" .. path
          if not Client.IsMounted(path) then
            local success = Client.MountPakFile(path, "")
            log(bWriteLog and "Start to mount " .. tostring(path) .. tostring(success))
            mountResult = mountResult .. " mounted " .. tostring(success)
            Client.AddAttachFileString("mountmodpaks", false, mountResult)
          else
            log(bWriteLog and "Already mounted " .. tostring(path))
            mountResult = mountResult .. " Already mounted."
            Client.AddAttachFileString("mountmodpaks", false, mountResult)
          end
        end
      end
    end
    PufferMapManager:MountFeaturesODPak(mapKey, sub_mode)
    PufferMapManager:RecordDynamicPaks(mapKeys)
  end
  local AkGameplayStatics = import("AkGameplayStatics")
  AkGameplayStatics.RefreshModDirectories()
end

function NetUtil.EnterBattleStandAlone(GameFrontendHUD, map_path, _player_key, nickName, sub_mode, dynamiclevels_op, AdditionalURLSuffixes)
  if AdditionalURLSuffixes == nil then
    AdditionalURLSuffixes = ""
  else
    local AdditionalURLSuffixesHead = "?"
    if AdditionalURLSuffixes:sub(1, 1) ~= AdditionalURLSuffixesHead then
      AdditionalURLSuffixes = AdditionalURLSuffixesHead .. AdditionalURLSuffixes
    end
  end
  NetUtil.MountPakOfMode(sub_mode)
  _G.ModeID = sub_mode
  local ScriptHelperClient = import("ScriptHelperClient")
  ScriptHelperClient.EnterBattleStandAlone(GameFrontendHUD, map_path, _player_key, nickName, dynamiclevels_op, AdditionalURLSuffixes, sub_mode)
  local UIUtil = require("client.common.ui_util")
  if UIUtil.GetGameFrontendHUD() ~= nil then
    UIUtil.GetGameFrontendHUD():SetGameSubMode(tostring(sub_mode))
  end
end

function NetUtil.SetEnterBattleGameID(InGameID)
  if InGameID ~= nil and NetUtil.EnterBattleGameID ~= InGameID then
    NetUtil.EnterBattleGameID = InGameID
    log_shipping_client("LogBattleNetFlow,  GameId: " .. tostring(InGameID))
  end
end

function NetUtil.OnConnected(isConnected, nReason)
  if _G.IsEnableMockGameSvr then
    log(bWriteLog and "NetUtil.OnConnected(IsEnableMockGameSvr)")
    return
  end
  local logic_lobby_ping_report = require("client.slua.logic.match.logic_lobby_ping_report")
  logic_lobby_ping_report.OnReceiveConnected(isConnected)
  local login_module = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.login_module)
  log(bWriteLog and "NetUtil.OnConnected, isConnected = " .. tostring(isConnected) .. ", reason = " .. tostring(nReason) .. ", status = " .. GameStatus.GetGameStatus() .. ", ReceivedSyncBaseInfo = " .. tostring(login_module.bIsInitLogin))
  log_shipping_client("[Login process] ClientEntry -----  NetUtil.OnConnected " .. tostring(isConnected) .. ", nReason: " .. nReason .. ", isInitLogin:" .. tostring(login_module.bIsInitLogin))
  if not isConnected then
    local IntlHelper = import("IntlHelper")
    IntlHelper.AddErrorCodeToHistory(string.format("connect-%s", tostring(nReason)))
    local PlayerPrefsSystem = require("client.logic.LogicPlayerPrefs.playerprefs")
    local info = {reason = nReason}
    PlayerPrefsSystem.SaveTableToFile_N(info, PlayerPrefsSystem.ePlayerPrefsType.eLoginHDmpveErr)
  end
  if Client.SetTssNetworkStatus ~= nil then
    if isConnected then
      Client.SetTssNetworkStatus(GameFrontendHUD, 0)
    elseif nReason == 100 then
      Client.SetTssNetworkStatus(GameFrontendHUD, nReason)
    end
  end
  local ban_login_module = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.ban_login_module)
  local bKickOutSelf = ban_login_module.hasKickOut or login_module.bHasLogout or NetUtil.checkLoginOtherLobbyServer
  if isConnected == false and (GameStatus.GetGameStatus() == GameStatus.Login or GameStatus.IsInLobbyOrMainCity()) and bKickOutSelf == false then
    if login_module:reconnectGateway() then
      log(bWriteLog and "ClientEntry -----  LoginSystem.reconnectGateway()")
      return
    else
      Client.GEMReportEnterLobbyEvent(GameFrontendHUD, false, "reconnect backup server failed, errorcode:" .. tostring(nReason))
    end
  elseif isConnected == false and bKickOutSelf == false then
    Client.GEMReportEnterLobbyEvent(GameFrontendHUD, false, tostring(nReason))
  end
  if not NetUtil.checkLoginOtherLobbyServer then
    logic_connection_waiting:Hide(1)
  end
  NetManager.ProcConnected(isConnected)
  local nowTime = TimeUtil.GetServerTimeInSec()
  if isConnected then
    log(bWriteLog and "ClientEntry ----- NetUtil.OnConnected step isConnected")
    log(bWriteLog and string.format("ClientEntry ----- NetUtil.OnConnected nowTime = %s", TimeUtil.FormatTime_YMDHMS(nowTime)))
    NetUtil.hasTryConnectForNetworkError = false
    NetUtil.hasTryConnectForNetworkErrorTimes = 0
    if GisInWaiting then
      log(bWriteLog and "ClientEntry ----- is in LoginSystem.GisInWaiting")
      local CommonMsgBoxMgr = require("client.slua.logic.common.logic_common_msg_box")
      CommonMsgBoxMgr.HideAllPanel()
    end
    local CommonMsgBoxMgr = require("client.slua.logic.common.logic_common_msg_box")
    log(bWriteLog and "ClientEntry ----- Close ConnectionMessageBoxUI!!!!")
    CommonMsgBoxMgr.HideConnectionPanel()
    if ban_login_module.hasKickOut then
      NetUtil.gameTick = false
    else
      if Client.IsMatchNoAuthMode and Client.IsMatchNoAuthMode() then
        if login_module.bIsInitLogin == false and GameStatus.GetGameStatus() == GameStatus.Login then
          login_module:competition_login_res(true)
        else
          login_module:TryNoAuthRelogin()
        end
      else
        login_module:OnConnected(NetUtil.ConnectReason)
        NetUtil.ConnectReason = nil
      end
      NetUtil.ClearAutoReconnectParam()
      NetUtil.gameTick = true
    end
    NetUtil.showConnectionMsgTimes = 0
    NetUtil.SendTime = TimeUtil.OSTime()
    NetUtil.LobbyDelaySendTime = TimeUtil.GetMiliseconds()
    NetUtil.LobbyDelayRecvTime = TimeUtil.GetMiliseconds()
    NetUtil.s2cNeedWaiting = {}
    NetUtil.checkConnectingInFighting = false
    NetUtil.checkConnectingInFightingTimes = 0
    log(bWriteLog and "ClientEntry ----- NetUtil.OnConnected step isConnected EVENTID_LOBBY_SERVER_CONNECT_SUCCESS")
    EventSystem:postEvent(EVENTTYPE_NETWORK, EVENTID_LOBBY_SERVER_CONNECT_SUCCESS)
  else
    local login_protect_utils = require("client.slua.logic.login.login_protect_utils")
    login_protect_utils.RecordLoginFailTime()
    log_shipping_client("ClientEntry ----- NetUtil.OnConnected Failed curStatus = " .. GameStatus.GetGameStatus() .. " for reason = " .. nReason)
    EventSystem:postEvent(EVENTTYPE_NETWORK, EVENTID_LOBBY_SERVER_CONNECT_FAILED)
    if ban_login_module.hasKickOut or login_module.bHasLogout or NetUtil.checkLoginOtherLobbyServer then
      log_format("ClientEntry ----- NetUtil.OnConnected kickout or logout state! hasKickOut:%s, hasLogout:%s, checkLoginOtherLobbyServer:%s", ban_login_module.hasKickOut, login_module.bHasLogout, NetUtil.checkLoginOtherLobbyServer)
      log_shipping_client("ClientEntry ----- NetUtil.OnConnected tryConnectLobby failed is in kickout or logout state! hasKickOut:" .. tostring(ban_login_module.hasKickOut) .. ", hasLogout:" .. tostring(login_module.bHasLogout))
      NetUtil.gameTick = false
      return
    end
    local errorMsg = FuncUtil.GetHDmpveErrorMsg(nReason)
    local isInFightingNotSocialNotMainCityNotHome = GameStatus.IsInFightingNotSocialNotMainCityNotHome()
    log_format("NetUtil.OnConnected IsInFightingNotSocialNotMainCityNotHome = %s", isInFightingNotSocialNotMainCityNotHome)
    if isInFightingNotSocialNotMainCityNotHome then
      if not NetUtil.checkConnectingInFighting then
        NetUtil.checkConnectingInFighting = true
        NetUtil.waitingConnectSuccessStartTime = TimeUtil.OSTime()
        log(bWriteLog and "ClientEntry ----- NetUtil.OnConnected waitingConnectSuccessStartTime:" .. NetUtil.waitingConnectSuccessStartTime)
      end
    else
      local gclould_error_define = require("client.common.gclould_error_define")
      if nReason == -1 or nReason == gclould_error_define.GCLOULD_ErrorNetworkException or nReason == gclould_error_define.GCLOULD_ErrorTimeout or nReason == gclould_error_define.GCLOULD_ErrorChecking or nReason == gclould_error_define.GCLOULD_ErrorConnectFailed then
        if not NetUtil.AutoReconnectParam then
          NetUtil.AutoReconnectParam = NetUtil.GetAutoReconnectParam()
          if NetUtil.AutoReconnectParam.showFunc then
            NetUtil.AutoReconnectParam.showFunc()
          end
        end
        log_format("ClientEntry ----- NetUtil.OnConnected AutoReconnectTimes = %s, hasTryConnectForNetworkErrorTimes = %s nowTime = %s", NetUtil.AutoReconnectParam.times, NetUtil.hasTryConnectForNetworkErrorTimes, TimeUtil.FormatTime_YMDHMS(nowTime))
        if NetUtil.hasTryConnectForNetworkErrorTimes < NetUtil.AutoReconnectParam.times then
          log(bWriteLog and "ClientEntry ----- After Connect Failed For Newwork Try Connect One Time......")
          if NetUtil.isWattingDelayReconnect == false then
            NetUtil.isWattingDelayReconnect = true
            NetUtil.ClearAutoReconnectTimer()
            NetUtil.hasTryConnectForNetworkErrorTimes = NetUtil.hasTryConnectForNetworkErrorTimes + 1
            local timer_ticker = require("common.time_ticker")
            NetUtil.autoReconnectTimer = timer_ticker.AddTimerOnce(1, function()
              log(bWriteLog and "ClientEntry ----- NetUtil.OnConnected Auto Reconnect Timer handler")
              NetUtil.tryConnect(Enum_LOGIN_REPORT_CFG.NET_CONNECT_ERR)
              NetUtil.isWattingDelayReconnect = false
            end)
          end
        else
          NetUtil.ClearAutoReconnectParam()
          log(bWriteLog and "ClientEntry ----- Show ConnectingErrorMsg ......")
          NetUtil.showConnectionMsgTimes = NetUtil.showConnectionMsgTimes + 1
          NetUtil.ShowConnectionMsgBox(NetUtil.showConnectionMsgTimes, errorMsg)
        end
      else
        NetUtil.gameTick = false
        local strTile = LocUtil.GetLocalizeResStr(102012)
        if not login_module.bLoginNextRsp then
          local CommonMsgBoxMgr = require("client.slua.logic.common.logic_common_msg_box")
          CommonMsgBoxMgr.Show(1, strTile, errorMsg, function()
            if nReason == gclould_error_define.GCLOULD_ErrorAuthFailed then
              local SettingAccount = require("client.logic.setting.logic_setting_account")
              SettingAccount.ClientLogout()
            end
            login_module:backLogin()
          end, nil, nil, nil, true)
        end
      end
      ResetResultMonitor()
    end
  end
  local param = {}
  table.insert(param, isConnected)
  table.insert(param, nReason)
  EventSystem:postEvent(EVENTTYPE_NETWORK, EVENTID_CONNECTED, param)
end

function NetUtil.OnStateChange(state, param1, param2, param3)
  log_shipping_client("ClientEntry ----- OnStateChange State:" .. state .. ", Param1:" .. param1 .. ", Param2:" .. param2 .. ", Param3:" .. param3)
  if state == 0 then
    log(bWriteLog and "ClientEntry ----- HDmpve::Conn::kConnectorStateRunning")
  elseif state == 1 then
    log(bWriteLog and "ClientEntry ----- HDmpve::Conn::kConnectorStateReconnecting.......")
    NetUtil.ProcOnConnecting()
  elseif state == 2 then
    log(bWriteLog and "ClientEntry ----- HDmpve::Conn::kConnectorStateReconnected isConnect:" .. param1)
    NetUtil.ProcOnConnected()
    if NetUtil.CheckSpecialDeviceNetFlash() then
      log(bWriteLog and "NetUtil.OnStateChange check special device net flash")
      logic_connection_waiting:Hide(1)
    else
      NetUtil.OnConnected(param1 == 0, param1)
    end
  elseif state == 3 then
    log(bWriteLog and "ClientEntry ----- HDmpve::Conn::kConnectorStateStayInQueue")
    local queuePosition = param1
    local queueLength = param2
    local estimateTime = param3
    log(bWriteLog and string.format("Queue, current position:%d of total quque length:%d,estimateTime=%d", queuePosition, queueLength, estimateTime))
    GisInWaiting = true
    NetUtil.gameTick = false
    
    local function cancelWaiting()
      log(bWriteLog and "ClientEntry ----- cancelWaiting..")
      local login = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.login_module)
      login:backLogin()
    end
    
    local timewait = math.floor(estimateTime / 60)
    local CommonMsgBoxMgr = require("client.slua.logic.common.logic_common_msg_box")
    CommonMsgBoxMgr.HideAllPanel()
    if not GameStatus.IsInFightingNotSocialNotMainCityNotHome() then
      local str = LocUtil.GetLocalizeResStr(301108)
      local str2 = LocUtil.GetLocalizeResStr(301109)
      local str3 = LocUtil.GetLocalizeResStr(110035)
      local text = string.format(str, queuePosition, timewait)
      CommonMsgBoxMgr.Show(1, str2, text, cancelWaiting, nil, str3)
    end
  elseif state == 4 then
    log(bWriteLog and "ClientEntry ----- HDmpve::Conn::kConnectorStateError ")
    NetUtil.ProcOnDisconnected()
    local errorCode = param1
    log(bWriteLog and "ClientEntry ----- errorCode == " .. errorCode)
    if errorCode == 2 then
      local AccelSystem = require("client.slua.logic.gamemaster.logic_accel")
      if AccelSystem.IsEnableAccel() then
        AccelSystem.Switch2FastMode()
      end
    end
    if errorCode == 207 or errorCode == 205 then
      log(bWriteLog and "ClientEntry ----- HDmpve::Conn::kErrorSendError")
      NetUtil.OnConnected(false, 201)
    else
      if param2 == 7 then
        log(bWriteLog and "ClientEntry ----- \229\144\142\229\143\176\228\184\187\229\138\168\229\176\134\229\174\162\230\136\183\231\171\175\232\184\162\228\184\139\231\186\191")
        log(bWriteLog and "ClientEntry ----- extendCodeOfGameSvr = " .. param3)
      else
        log(bWriteLog and "ClientEntry ----- extend = " .. param2 .. "extend2 = " .. param3)
      end
      NetUtil.OnConnected(false, errorCode)
    end
  end
end

function NetUtil.OnDisconnected(nReason)
  log_error("NetUtil.OnDisconnected nReason\239\188\154" .. nReason)
  log(bWriteLog and "ClientEntry ----- NetUtil.OnDisconnected nReason\239\188\154" .. nReason)
end

NET_UTIL_LOGIN_WAIT_TIME = 8

function NetUtil.CheckTime()
  local login_module = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.login_module)
  if NetUtil.checkLoginRsp and NetUtil.sendLoginTime > 0 and TimeUtil.OSTime() - NetUtil.sendLoginTime >= NET_UTIL_LOGIN_WAIT_TIME then
    if NetUtil.checkLoginRetryTime == 0 then
      log(bWriteLog and "ClientEntry -----  checkLoginRsp timeout!! " .. NetUtil.checkLoginRetryTime .. ", isRelogin:" .. tostring(login_module.bIsRelogin))
      local reportId = Enum_LOGIN_REPORT_CFG.RETRY
      if login_module.bLoginNextRsp then
        reportId = Enum_LOGIN_REPORT_CFG.LOGIN_NEXT
        login_module:SetbLoginNextRsp(false)
      end
      login_module:reqLoginLobby(login_module.bIsRelogin, reportId)
      NetUtil.checkLoginRetryTime = NetUtil.checkLoginRetryTime + 1
    else
    end
    if GameStatus.IsInFightingNotSocialNotMainCityNotHome() then
      if NetUtil.checkBattleLoginRetryTime == 0 or NetUtil.checkBattleLoginRetryTime == 2 or NetUtil.checkBattleLoginRetryTime == 5 then
        log(bWriteLog and "ClientEntry ----- tryConnect lobby in fighting when login failed")
        NetUtil.tryConnect(Enum_LOGIN_REPORT_CFG.NET_CONNECT_FRIGHT_TICK)
      end
      NetUtil.checkBattleLoginRetryTime = NetUtil.checkBattleLoginRetryTime + 1
    end
  end
  if NetUtil.checkEnterBattle and TimeUtil.OSTime() - NetUtil.waitingEnterBattleStartTime > NetUtil.LoadingTimeOut then
    local SmartBearerManagerLuaBridge = import("SmartBearerManagerLuaBridge")
    local bEnterBattleTimeOutExEnabled = false
    if SmartBearerManagerLuaBridge ~= nil then
      bEnterBattleTimeOutExEnabled = SmartBearerManagerLuaBridge.IsClientBackEndSwitcherBEnable(1)
    end
    if bEnterBattleTimeOutExEnabled then
      log(bWriteLog and "EnterBattleTimeOutEx Enabled.")
      local EnterBattleCurStage = ""
      local UIUtil = require("client.common.ui_util")
      if UIUtil ~= nil and UIUtil.GetGameFrontendHUD() ~= nil then
        EnterBattleCurStage = UIUtil.GetGameFrontendHUD():GetClientEnterBattleStage()
      end
      if (EnterBattleCurStage == "NMT_Welcome_Received" or EnterBattleCurStage == "LoadMapCompleted" or EnterBattleCurStage == "NetworkEstablished") and NetUtil.EnterBattleTimeOutGameID ~= g_game_id then
        NetUtil.EnterBattleTimeOutGameID = g_game_id
        NetUtil.LoadingTimeOut = NetUtil.LoadingTimeOut + 20
        log(bWriteLog and "EnterBattleTimeOutEx Processed.")
        return
      end
    end
    NetUtil.StopCheckEnterBattle()
    log(bWriteLog and "ClientEntry -----  checkEnterBattle timeout!! curStatus:" .. GameStatus.GetGameStatus() .. ", isWaittingEnterBattle:" .. tostring(LobbySystem.isWaittingEnterBattle))
    logic_connection_waiting:Hide(1)
    if LobbySystem.isWaittingEnterBattle then
      LobbySystem.SetWaitingBattleFlag(false)
      log(bWriteLog and "NetUtil.CheckTime - deanytjin test should add show mail 1")
      if GameStatus.IsInLobbyOrMainCity() then
        log(bWriteLog and "ClientEntry -----  checkEnterBattle timeout!! not ReturnToLobby")
        local LoadingSystem = require("client.slua.logic.loading.logic_loading")
        LoadingSystem.RefreshLoadPercent(1)
        if LobbySystem.is_DeathMatchMode then
          local TeamCompLoading = require("client.slua.logic.loading.logic_teamcomp_loading")
          TeamCompLoading.RefreshLoadPercent(1)
        end
        EventSystem:postEvent(EVENTTYPE_NETWORK, EVENTID_MAIN_CITY_ENTER_BATTLE_TIMEOUT)
      else
        local Lobby_Main_City_Enter = require("client.slua.logic.lobby.MainCity.Lobby_Main_City_Enter")
        Lobby_Main_City_Enter.bEnterGameFromMainCity = false
        Client.ReturnToLobby(GameFrontendHUD)
      end
      if not NetManager.bConnected and LobbySystem.CheckOpen(BP_ENUM_IS_QUERY_PLAYER_STETE_AFTER_LOADING) then
        login_module:reqLoginLobby(true, Enum_LOGIN_REPORT_CFG.LOAD_TIMEOUT)
      else
        local MatchSystem = require("client.slua.logic.match.logic_match")
        MatchSystem.SetQueryPlayerFlag(true)
      end
      UnrealNet.HandleNetworkExceptionReport("EnterBattleTimeout", "", "")
      local LogicGRomelink = require("client.slua.logic.gromelink.logic_grome_link")
      LogicGRomelink:OnEnterBattleResult(LogicGRomelink.ENUM_ENTER_GAME_RET.TIMEOUT)
      log_shipping_client("LogBattleNetFlow,  EnterBattleTimeout.")
    end
  end
  if NetUtil.checkWaitingReEnterGameNotify and 5 < TimeUtil.OSTime() - NetUtil.waitingReEnterGameStartTime then
    NetUtil.StopCheckDSActive()
    log(bWriteLog and "ClientEntry -----  checkWaitingReEnterGameNotify timeout!! curStatus:" .. GameStatus.GetGameStatus() .. ", isWaittingEnterBattle:" .. tostring(LobbySystem.isWaittingEnterBattle))
    logic_connection_waiting:Hide(1)
    local bReplayState = Client.IsInReplayState(GameFrontendHUD)
    if LobbySystem.isWaittingEnterBattle then
      LobbySystem.SetWaitingBattleFlag(false)
      log(bWriteLog and "NetUtil.CheckTime - deanytjin test should add show mail 2")
      if GameStatus.IsInLobbyOrMainCity() then
        log(bWriteLog and "ClientEntry -----  checkWaitingReEnterGameNotify timeout!! not ReturnToLobby true")
        local LoadingSystem = require("client.slua.logic.loading.logic_loading")
        LoadingSystem.RefreshLoadPercent(1)
        if LobbySystem.is_DeathMatchMode then
          local TeamCompLoading = require("client.slua.logic.loading.logic_teamcomp_loading")
          TeamCompLoading.RefreshLoadPercent(1)
        end
        return
      end
      Client.ReturnToLobby(GameFrontendHUD)
    elseif GameStatus.IsInFightingStatus() and not BattleResult.IgnoreDSError and not bReplayState then
      if GameStatus.IsInLobbyOrMainCity() then
        log(bWriteLog and "ClientEntry -----  checkWaitingReEnterGameNotify timeout!! not ReturnToLobby false")
        local LoadingSystem = require("client.slua.logic.loading.logic_loading")
        LoadingSystem.RefreshLoadPercent(1)
        if LobbySystem.is_DeathMatchMode then
          local TeamCompLoading = require("client.slua.logic.loading.logic_teamcomp_loading")
          TeamCompLoading.RefreshLoadPercent(1)
        end
        return
      end
      local strTile = LocUtil.GetLocalizeResStr(102012)
      local strMsg = ""
      local home_macros = require("client.slua.logic.home.home_macros")
      local Logic_PlanCHMacros = require("client.slua.logic.CollectionHall.Logic_PlanCHMacros")
      local sub_mode = tonumber(Client.GetGameModeID(GameFrontendHUD))
      if sub_mode == home_macros.Home_SubMode.Visit then
        strMsg = LocUtil.GetLocalizeResStr(655421)
      elseif sub_mode == Logic_PlanCHMacros.CollectionHall_SubMode.Visit then
        strMsg = LocUtil.GetLocalizeResStr(880060019)
      else
        strMsg = LocUtil.GetLocalizeResStr(77010)
      end
      local CommonMsgBoxMgr = require("client.slua.logic.common.logic_common_msg_box")
      CommonMsgBoxMgr.Show(1, strTile, strMsg, function()
        if GameStatus.IsInFightingStatus() then
          FuncUtil.ShowLoadingToLobby()
          Client.ReturnToLobby(GameFrontendHUD)
          Client.TPerforPlatDisconnectReport(GameFrontendHUD, 11)
        end
      end, nil, nil, nil, {isConnectionPanel = true})
    end
  end
  if NetUtil.checkConnectingInFighting then
    local interval = 0
    if NetUtil.checkConnectingInFightingTimes == 0 or NetUtil.checkConnectingInFightingTimes == 1 then
      interval = 5
    elseif NetUtil.checkConnectingInFightingTimes == 2 then
      interval = 10
    elseif NetUtil.checkConnectingInFightingTimes == 3 then
      interval = 15
    else
      interval = NetUtil.checkConnectingInFightingRandomInterval
    end
    if interval < TimeUtil.OSTime() - NetUtil.waitingReEnterGameStartTime then
      log(bWriteLog and "ClientEntry ----- tryConnect lobby in fighting!!! curTime:" .. TimeUtil.OSTime() .. ", startTime:" .. NetUtil.waitingReEnterGameStartTime .. ", interval:" .. interval)
      if not Client.IsConnected(NetInterface) and GameStatus.IsInFightingStatus() then
        local MatchModeMgrSystem = require("client.slua.logic.match.logic_mode_mgr")
        if MatchModeMgrSystem and MatchModeMgrSystem.IsSocialIslandMode(true) and NetUtil.checkConnectingInFightingTimes > 3 then
          local strTile = LocUtil.GetLocalizeResStr(102012)
          local strMsg = LocUtil.GetLocalizeResStr(301113)
          local CommonMsgBoxMgr = require("client.slua.logic.common.logic_common_msg_box")
          CommonMsgBoxMgr.Show(1, strTile, strMsg, function()
            FuncUtil.ShowLoadingToLobby()
            Client.ReturnToLobby(GameFrontendHUD)
            if not NetManager.bConnected and LobbySystem.CheckOpen(BP_ENUM_IS_QUERY_PLAYER_STETE_AFTER_LOADING) then
              login_module:reqLoginLobby(true, Enum_LOGIN_REPORT_CFG.SOCIAL_ISLAND)
            else
              local MatchSystem = require("client.slua.logic.match.logic_match")
              MatchSystem.SetQueryPlayerFlag(true)
            end
            logic_connection_waiting:Hide(1)
          end, nil, nil, nil, {isConnectionPanel = true})
        else
          NetUtil.checkConnectingInFightingTimes = NetUtil.checkConnectingInFightingTimes + 1
          NetUtil.tryConnect(Enum_LOGIN_REPORT_CFG.NET_CONNECT_FRIGHT)
          NetUtil.checkConnectingInFightingRandomInterval = math.random(30, 40)
        end
      else
        log(bWriteLog and "ClientEntry -----  stop checkConnectingInFighting")
        NetUtil.checkConnectingInFighting = false
        NetUtil.waitingReEnterGameStartTime = 0
        NetUtil.checkConnectingInFightingTimes = 0
      end
      NetUtil.waitingReEnterGameStartTime = TimeUtil.OSTime()
    end
  end
  UpdateResultMonitor()
end

function NetUtil.StopCheckLoginOtherLobbyServer()
  log(bWriteLog and "ClientEntry -----  StopCheckLoginOtherLobbyServer")
  if NetUtil.checkLoginOtherLobbyServer then
    logic_connection_waiting:Hide(1)
  end
  log_warning(bWriteLog and "NetUtil.StopCheckLoginOtherLobbyServer checkLoginOtherLobbyServer false")
  NetUtil.checkLoginOtherLobbyServer = false
end

function NetUtil.OnEnterBattleStageDelegate(InStage)
  local loading_macro = require("client.slua.logic.loading.loading_macro")
  local CurStagePercent = loading_macro.EnterBattleStagePercentMap[InStage]
  if CurStagePercent ~= nil then
    log(bWriteLog and "NetUtil.OnEnterBattleStageDelegate Stage: " .. InStage .. ", percent: " .. tostring(CurStagePercent))
    local LoadingSystem = require("client.slua.logic.loading.logic_loading")
    LoadingSystem.RefreshLoadPercent(CurStagePercent, true)
    if LobbySystem.is_DeathMatchMode == true then
      log(bWriteLog and "NetUtil.OnEnterBattleStageDelegate RefreshLoadPercent:exported" .. tostring(CurStagePercent))
      local TeamCompLoading = require("client.slua.logic.loading.logic_teamcomp_loading")
      TeamCompLoading.RefreshLoadPercent(CurStagePercent, true)
    end
  else
    log(bWriteLog and "NetUtil.OnEnterBattleStageDelegate Stage is nil, " .. InStage)
  end
end

function NetUtil.OnEnterBattleStageDelegate_MainCity(InStage)
  log(bWriteLog and "NetUtil.OnEnterBattleStageDelegate_MainCity Stage: " .. tostring(InStage))
  local loading_macro = require("client.slua.logic.loading.loading_macro")
  local CurStagePercent = loading_macro.EnterBattleStagePercentMap[InStage]
  log(bWriteLog and "NetUtil.OnEnterBattleStageDelegate_MainCity CurStagePercent: " .. tostring(CurStagePercent))
end

function NetUtil.BindEnterBattleStageDelegate(sub_mode)
  log(bWriteLog and "NetUtil.BindEnterBattleStageDelegate sub_mode: " .. tostring(sub_mode))
  NetUtil.RemoveEnterBattleStageDelegate()
  if NetUtil.EnterBattleStageDelegate == nil then
    local UIUtil = require("client.common.ui_util")
    local GameFrontHUD = UIUtil.GetGameFrontendHUD()
    if GameFrontHUD ~= nil then
      local Lobby_Main_City = require("client.slua.logic.lobby.MainCity.Lobby_Main_City")
      if Lobby_Main_City.IsMainCitySubMode(sub_mode) then
        NetUtil.EnterBattleStageDelegate = GameFrontHUD.EnterBattleStageDelegate:Add(function(InStage)
          NetUtil.OnEnterBattleStageDelegate_MainCity(InStage)
        end)
      else
        NetUtil.EnterBattleStageDelegate = GameFrontHUD.EnterBattleStageDelegate:Add(function(InStage)
          NetUtil.OnEnterBattleStageDelegate(InStage)
        end)
      end
      log(bWriteLog and "ClientEntry ----- NetUtil.BindEnterBattleStageDelegate")
    end
  end
end

function NetUtil.RemoveEnterBattleStageDelegate()
  log(bWriteLog and "NetUtil.RemoveEnterBattleStageDelegate")
  if NetUtil.EnterBattleStageDelegate ~= nil then
    local UIUtil = require("client.common.ui_util")
    local GameFrontHUD = UIUtil.GetGameFrontendHUD()
    if GameFrontHUD ~= nil then
      GameFrontHUD.EnterBattleStageDelegate:Remove(NetUtil.EnterBattleStageDelegate)
    end
    NetUtil.EnterBattleStageDelegate = nil
    log(bWriteLog and "ClientEntry ----- NetUtil.RemoveEnterBattleStageDelegate")
  end
end

function NetUtil.StartCheckLoginRsp()
  log(bWriteLog and "ClientEntry ----- NetUtil.StartCheckLoginRsp......")
  NetUtil.checkLoginRsp = true
  NetUtil.sendLoginTime = TimeUtil.OSTime()
end

function NetUtil.StopCheckLoginRsp()
  log(bWriteLog and "ClientEntry ----- NetUtil.StopCheckLoginRsp!!!!!")
  NetUtil.checkLoginRsp = false
  NetUtil.sendLoginTime = 0
  NetUtil.checkLoginRetryTime = 0
  if 0 < NetUtil.checkBattleLoginRetryTime then
    local realRetryTime = 1
    if NetUtil.checkBattleLoginRetryTime > 2 then
      realRetryTime = 2
    elseif NetUtil.checkBattleLoginRetryTime > 5 then
      realRetryTime = 3
    end
    local param = {realRetryTime}
    NetUtil.GEMReportSubEvent("ReonnectAfterLoginFail", param)
  end
  NetUtil.checkBattleLoginRetryTime = 0
  NetUtil.bIsTimeOutReconnect = 0
end

function NetUtil.StartCheckDSActive()
  log(bWriteLog and "NetUtil.StartCheckDSActive")
  local curStatus = LuaClassObj.GetGameStatus(bp_global)
  log(bWriteLog and "ClientEntry -----  StartCheckDSActive isWaittingEnterBattle: " .. tostring(LobbySystem.isWaittingEnterBattle) .. ", curStatus: " .. curStatus)
  if LobbySystem.isWaittingEnterBattle and NetUtil.EnterBattleTime > 0 and 0 < NetUtil.waitingEnterBattleStartTime and NetUtil.EnterBattleTime >= NetUtil.waitingEnterBattleStartTime then
    log(bWriteLog and "NetUtil.EnterBattleTime >= NetUtil.waitingEnterBattleStartTime, Skip StartCheckDSActive.")
    return
  end
  local dsNetState = Client.GetUnrealNetworkStatus(GameFrontendHUD)
  if (LobbySystem.isWaittingEnterBattle or curStatus == GameStatus.Fighting) and dsNetState ~= "Online" and NetUtil.checkWaitingReEnterGameNotify == false then
    NetUtil.checkWaitingReEnterGameNotify = true
    NetUtil.waitingReEnterGameStartTime = TimeUtil.OSTime()
    log(bWriteLog and "ClientEntry -----  waitingReEnterGameStartTime:" .. NetUtil.waitingReEnterGameStartTime)
  end
end

function NetUtil.StopCheckDSActive()
  log(bWriteLog and "ClientEntry -----  StopCheckDSActive")
  NetUtil.checkWaitingReEnterGameNotify = false
  NetUtil.waitingReEnterGameStartTime = 0
end

function NetUtil.StartCheckEnterBattle(sub_mode)
  if LobbySystem.isWaittingEnterBattle then
    NetUtil.checkEnterBattle = true
    NetUtil.waitingEnterBattleStartTime = TimeUtil.OSTime()
    local SubModeCfg = CDataTable.GetTableData("BTMode", sub_mode)
    if SubModeCfg and SubModeCfg.LoadingTimeOut and SubModeCfg.LoadingTimeOut > 70 then
      NetUtil.LoadingTimeOut = SubModeCfg.LoadingTimeOut
    else
      NetUtil.LoadingTimeOut = 70
    end
    if Client.IsAsanVersion() then
      NetUtil.LoadingTimeOut = 1000
    end
    log(bWriteLog and "ClientEntry -----  waitingEnterBattleStartTime:" .. NetUtil.waitingEnterBattleStartTime)
    log(bWriteLog and "ClientEntry -----  LoadingTimeOut:" .. NetUtil.LoadingTimeOut)
    NetUtil.BindEnterBattleStageDelegate(sub_mode)
    if LobbySystem.is_DeathMatchMode == true then
      local TeamCompLoading = require("client.slua.logic.loading.logic_teamcomp_loading")
      TeamCompLoading.SetInitPercent(50)
    else
      local LoadingSystem = require("client.slua.logic.loading.logic_loading")
      LoadingSystem.SetInitPercent(50)
    end
  end
end

function NetUtil.StopCheckEnterBattle()
  log(bWriteLog and "ClientEntry -----  StopCheckEnterBattle EnterBattleLoadingTime:", NetUtil.EnterBattleLoadingTime)
  NetUtil.checkEnterBattle = false
  NetUtil.waitingEnterBattleStartTime = 0
  NetUtil.LoadingTimeOut = 70
  NetUtil.RemoveEnterBattleStageDelegate()
end

function NetUtil.OnTick(curTime)
  local ban_login_module = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.ban_login_module)
  if ban_login_module.hasKickOut then
    return
  end
  if NetUtil.gameTick then
    if curTime - NetUtil.SendTime >= 5 then
      NetUtil.SendTime = curTime
      NetUtil.LobbyDelaySendTime = TimeUtil.GetMiliseconds()
      NetHeartBeatHandler.send_heart_beat(curTime)
    end
    if curTime - NetUtil.SendOneTime >= 1 then
      NetUtil.SendOneTime = curTime
      if LobbySystem.isInLobby then
        NetUtil.SendTss()
      end
    end
  end
end

function NetUtil.OnChangeLobbyServerNotify(relogin_seconds, reason)
  log(bWriteLog and "ClientEntry ----- OnChangeLobbyServerNotify relogin_seconds:" .. tostring(relogin_seconds) .. " reason:" .. tostring(reason))
  
  local function _migrate()
    log_warning(bWriteLog and "NetUtil.OnChangeLobbyServerNotify checkLoginOtherLobbyServer true")
    NetUtil.checkLoginOtherLobbyServer = true
    NetUtil.Disconnect()
    local login_module = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.login_module)
    login_module:HandlemServerMigrationAndConnect()
  end
  
  local handleFunc = NetUtil.Please_Relogin_Req
  if reason and type(reason) == "string" and reason == "data-migration" then
    handleFunc = _migrate
  end
  if 0 < relogin_seconds then
    local time_ticker = require("common.time_ticker")
    if NetUtil.PleaseReloginTimer then
      time_ticker.RemoveTimer(NetUtil.PleaseReloginTimer)
      NetUtil.PleaseReloginTimer = nil
    end
    NetUtil.PleaseReloginTimer = time_ticker.AddTimerOnce(relogin_seconds, handleFunc)
  else
    handleFunc()
  end
end

function NetUtil.Please_Relogin_Req()
  log(bWriteLog and "ClientEntry ----- Please_Relogin_Req ~~~~~~~")
  log_warning(bWriteLog and "NetUtil.Please_Relogin_Req checkLoginOtherLobbyServer true")
  NetUtil.checkLoginOtherLobbyServer = true
  NetUtil.Disconnect()
  NetUtil.tryConnect(Enum_LOGIN_REPORT_CFG.NET_RELOGIN)
end

function NetUtil.OnHeartBeatRsp(now)
  TimeUtil.SetServerTimeInSec(now)
  NetUtil.LobbyDelayRecvTime = TimeUtil.GetMiliseconds()
end

function NetUtil.GetZoneValue()
  local ms = 10000
  local ZoneSystem = require("client.slua.logic.teamup.logic_zone")
  local zoneList = ZoneSystem.chooseZoneList
  local zoneID = ZoneSystem.nChooseZoneID
  if not (zoneID and zoneList) or #zoneList <= 0 then
    return ms
  end
  local ip = ""
  for _, v in ipairs(zoneList) do
    if zoneID == v.zone_id then
      ip = v.tpingsvr_ip
      break
    end
  end
  if ip ~= "" then
    local UDPPingCollector = slua_GameFrontendHUD.UDPPingCollector
    ms = UDPPingCollector:GetZoneServerDelay(ip)
  end
  if 10000 < ms then
    ms = 80
  end
  return ms
end

function NetUtil.IsGrowthGuideSubMode(sub_mode)
  local enter_guide = require("client.slua.logic.growth_project.enter_guide")
  local mode_id = enter_guide.MatchId
  if sub_mode == mode_id then
    return true
  else
    return false
  end
end

function NetUtil.ShowConnectionMsgBox(showPanelTimes, errorMsg)
  log(bWriteLog and "ClientEntry -----  NetUtil.ShowConnectionMsgBox: " .. showPanelTimes .. ", curStatus:" .. GameStatus.GetGameStatus() .. ", errorMsg = " .. tostring(errorMsg))
  NetUtil.gameTick = false
  
  local function clickOkCallback()
    NetUtil.tryConnect(Enum_LOGIN_REPORT_CFG.NET_CONNECT_MSGBOX)
  end
  
  local function clickCancelCallback()
    local login = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.login_module)
    login:backLogin()
  end
  
  logic_connection_waiting:Hide(1)
  local strTile = LocUtil.GetLocalizeResStr(102012)
  local strMsg = LocUtil.GetLocalizeResStr(103015)
  if showPanelTimes == 2 then
    strMsg = LocUtil.GetLocalizeResStr(301226)
  elseif showPanelTimes == 3 then
    strMsg = LocUtil.GetLocalizeResStr(301227)
  else
    strMsg = LocUtil.GetLocalizeResStr(301228)
  end
  local extraData = {isConnectionPanel = true, androidCallback = clickCancelCallback}
  if showPanelTimes < 4 then
    local CommonMsgBoxMgr = require("client.slua.logic.common.logic_common_msg_box")
    CommonMsgBoxMgr.HideAllPanel()
    CommonMsgBoxMgr.Show(2, strTile, strMsg, clickOkCallback, clickCancelCallback, LocUtil.GetLocalizeResStr(62649), nil, extraData)
  else
    local CommonMsgBoxMgr = require("client.slua.logic.common.logic_common_msg_box")
    CommonMsgBoxMgr.HideAllPanel()
    CommonMsgBoxMgr.Show(1, strTile, strMsg, clickCancelCallback, nil, LocUtil.GetLocalizeResStr(62649), nil, extraData)
  end
end

function NetUtil.tryConnect(reason)
  local login_module = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.login_module)
  local lobbyInfo = login_module.loginLobbyInfo
  log_shipping_client("[Login process] ClientEntry -----  NetUtil.tryConnect curStatus:" .. GameStatus.GetGameStatus() .. " for reason = " .. tostring(reason))
  NetUtil.gameTick = false
  NetUtil.SendTime = TimeUtil.OSTime()
  local isConnected = Client.IsConnected(NetInterface)
  log(bWriteLog and "ClientEntry NetUtil.tryConnect Client.IsConnected is " .. tostring(isConnected))
  if not GameStatus.IsInFightingStatus() then
    logic_connection_waiting:Show(1)
  end
  NetUtil.ConnectReason = reason
  if NetUtil.ConnectReason == Enum_LOGIN_REPORT_CFG.NET_MSG_TIME_OUT then
    NetUtil.bIsTimeOutReconnect = 1
  end
  NetUtil.ConnectToURL(lobbyInfo.Url)
end

local normalEvent = {
  [9999] = 1,
  [211] = 1
}
local eventParam2ToErrorCode = {
  [2002] = 18010163,
  [2500] = 18010164,
  [2515] = 18010161,
  [2516] = 18010170,
  [2517] = 18010170,
  [2518] = 18010169
}

function NetUtil.OnNetworkEvent(eventID, eventParam, eventParam2)
  local normalRes = eventParam2ToErrorCode[eventParam2]
  local IMSDKSystem = require("client.logic.login.logic_imsdk")
  local ShareMgr = require("client.logic.share.share_logic")
  log(bWriteLog and "ClientEntry -----  OnNetworkEvent: eventID = " .. eventID .. " eventParam = " .. eventParam)
  local login_module = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.login_module)
  local curStatus = GameStatus.GetGameStatus()
  logic_connection_waiting:Hide(1)
  if eventID == 1 then
    log(bWriteLog and "authorization initialized")
  elseif eventID == 2 then
    log(bWriteLog and "NetUtil.OnNetworkEvent, login result = " .. tostring(eventParam))
    if PublishRegionMacros.IsGlobalVersion() then
      local logic_login_event = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_login_event)
      logic_login_event:HandleLoginResult(eventParam, eventParam2)
      return
    end
    local SDKMacros = require("client.slua.config.ClientMacros.SDKMacros")
    local IMSDKServerError = SDKMacros.IMSDKServerErrorCode
    IMSDKSystem.StopIMSDKTimer()
    NetUtil.noRefreshLogout = false
    local SettingAccount = require("client.logic.setting.logic_setting_account")
    SettingAccount.SetunifiedAccountLogging(false)
    local SVPNSystem = require("client.slua.logic.gamemaster.logic_svpn")
    SVPNSystem.OnIMSDKLoginResult(eventParam)
    local logic_http_dns = require("client.slua.logic.httpdns.logic_http_dns")
    logic_http_dns:OnMSDKLogin()
    local logic_imsdk_interface = require("client.logic.login.logic_imsdk_interface")
    logic_imsdk_interface:OnMSDKLogin()
    local DevicePlatformNameMacros = require("client.slua.config.ClientMacros.DevicePlatformNameMacros")
    if eventParam ~= 0 then
      login_module:ShowButtonsAfterLoginFailed()
      if eventParam ~= 106 and eventParam ~= 611 and eventParam ~= 701 and eventParam ~= 2 then
        NetUtil.LogoutNoRefresh()
      end
      EventSystem:postEvent(EVENTTYPE_LOGIN, EVENTID_LOGIN_FAIL_NETUTIL)
    end
    if eventParam == 0 then
      log(bWriteLog and "login ok")
      login_module:ClearLoginCountAndTime()
      EventSystem:postEvent(EVENTTYPE_LOGIN, EVENTID_LOGIN_SUCCESS_NETUTIL)
      local logic_cloud_game = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_cloud_game)
      logic_cloud_game:SendMessageToCloudGame(logic_cloud_game.ProtocolName.SDKLoginSuccess)
      
      local function UpdateEndCallBack()
        log(bWriteLog and "UpdateEndCallBack")
        local channel = Client.GetLoginChannel(NetInterface)
        log(bWriteLog and "authorization login ok, channel = " .. channel)
        if channel == BP_ENUM_PLAYFORM_UnifiedAccountByiTOP then
          local PlayerPrefsSystem = require("client.logic.LogicPlayerPrefs.playerprefs")
          if login_module.phoneMailType ~= 0 then
            local tb = {
              unified_type = login_module.phoneMailType
            }
            print(bWriteLog and "UpdateEndCallBack save unified_type = " .. tostring(tb.unified_type))
            PlayerPrefsSystem.SaveTableToFile_N(tb, PlayerPrefsSystem.ePlayerPrefsType.eMailPhoneLoginType)
          end
        end
        if globalConfig.IsDirectConnect() == false and globalConfig.isSupervision == false then
          log("hideAuthorizationUI")
          local is_uepubgm = Client.IsUEPUBGM()
          local servername = ""
          if Client.IsEditor() then
            local UEPUBGMConfig = RequireBlackList("blacklist.editor.uepubgm.UEPUBGMConfig")
            servername = UEPUBGMConfig.GetServerName()
          else
            servername = Client.GetUEPUBGMServerName()
          end
          if not is_uepubgm or servername == "" then
            login_module:Transition(login_module.ELoginFSMEvent.Event_LTCS)
            if channel == BP_ENUM_PLAYFORM_WX and curStatus == GameStatus.Login then
              ShowNotice("101709", true)
            end
            return
          end
          log(bWriteLog and "[ori]Start log in with uepubgm")
          login_module:LoginToServer(servername)
        else
          log("Connect to Gate Directly")
          login_module:ConnectToGate()
        end
      end
      
      local version_up_module = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.version_up_module)
      log(bWriteLog and "NetUtil.OnNetworkEvent, alreadyGrayUpdate = " .. tostring(version_up_module.bAlreadyGrayUpdate))
      if not version_up_module.bAlreadyGrayUpdate then
        version_up_module:StartGrayUpdate(UpdateEndCallBack)
      else
        UpdateEndCallBack()
      end
      NetUtil.needInitCentauriWhenLogin = true
    elseif eventParam == 3 then
      log(bWriteLog and "auth fail need retry")
      ShowNotice(101713)
    elseif eventParam == 106 then
      log(bWriteLog and "auth fail for user cancel")
      ShowNotice(101711)
    elseif eventParam == 701 then
      if curStatus == GameStatus.Login then
        local title = LocUtil.GetLocalizeResStr(101001)
        local notice = LocUtil.GetLocalizeResStr(4188)
        local CommonMsgBoxMgr = require("client.slua.logic.common.logic_common_msg_box")
        CommonMsgBoxMgr.Show(1, title, notice)
      end
    elseif eventParam == 1001 or eventParam == 1002 then
      log(bWriteLog and "client_entry NetUtil.OnNetworkEvent QuickLogin Fail eventParam:" .. tostring(eventParam))
    elseif (eventParam == 211 or eventParam == 9999) and eventParam2 == 2146 then
      if curStatus == GameStatus.Login then
        NetUtil.ShowUnifiedAccountException()
      end
    elseif normalEvent[eventParam] and normalRes then
      NetUtil.ShowMsgCommonMsg(normalRes)
    elseif (eventParam == 211 or eventParam == 9999) and eventParam2 == IMSDKServerError.CHANNEL_OPENID_BANED then
      local IMSDKHelper = import("IMSDKHelper")
      local loginRetJson = IMSDKHelper.GetInstance():GetLastLoginResultJson()
      local loginRet = json.decode(loginRetJson)
      if loginRet.thirdRetCode == IMSDKServerError.CHANNEL_OPENID_BANED then
        local thridMsgJson = loginRet.thirdRetMsg
        local thridMsg = json.decode(thridMsgJson)
        local openid = thridMsg.iOpenid
        local channel = thridMsg.iChannel
        local msg = thridMsg.msg
        local bandEndTime = thridMsg.iBanEnd
        login_module:ShowFreezePopupUI(openid, channel, bandEndTime)
      end
    elseif 9999 <= eventParam and eventParam <= 100000 then
      login_module:UpdateLoginCountAndTime()
      if curStatus == GameStatus.Login then
        local title = LocUtil.GetLocalizeResStr(101001)
        local notice = NetUtil.GetSDKErrorNotice(eventParam, eventParam2)
        local CommonMsgBoxMgr = require("client.slua.logic.common.logic_common_msg_box")
        CommonMsgBoxMgr.Show(1, title, notice)
      end
    elseif eventParam == 611 then
      log(bWriteLog and "login failed:" .. eventParam)
      local client_imsdk_eventparam = require("client.logic.ClientEntry.client_imsdk_eventparam")
      local channel = Client.GetLoginChannel(NetInterface)
      log(bWriteLog and "login failed:" .. eventParam .. " channel:" .. channel)
      if client_imsdk_eventparam.channel2ItopErrorCodeTable[channel] then
        local data = {
          ItopErrorCode = client_imsdk_eventparam.channel2ItopErrorCodeTable[channel],
          eventParam2 = eventParam2,
          channel = channel
        }
        UIManager.ShowUI(UIManager.UI_Config.Protection_UIBP, data)
        return
      else
        login_module:UpdateLoginCountAndTime()
        NetUtil.ShowSDKErrorNotice(eventParam, eventParam2)
      end
    else
      log(bWriteLog and "login failed:" .. eventParam)
      if eventParam ~= -1 and eventParam ~= 6 and eventParam ~= 7 and eventParam ~= 106 and eventParam ~= 107 and eventParam ~= 109 and eventParam ~= 200 then
        if curStatus ~= GameStatus.Login then
          return
        end
        login_module:UpdateLoginCountAndTime()
        NetUtil.ShowSDKErrorNotice(eventParam, eventParam2)
        return
      end
      login_module:UpdateLoginCountAndTime()
      login_module:ShowLoginUI()
      if eventParam == 7 and DevicePlatformNameMacros.IsPC() then
        ShowNotice(101710)
      end
    end
  elseif eventID == 3 then
    log(bWriteLog and "NetUtil.OnNetworkEvent, logout result = " .. tostring(eventParam))
    if NetUtil.noRefreshLogout ~= true then
      local login = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.login_module)
      login:backLogin(1)
    end
    NetUtil.noRefreshLogout = false
  elseif eventID == 4 then
    IMSDKSystem.StopIMSDKTimer()
    EventSystem:postEvent(EVENTTYPE_SHARE, EVENTID_SHARE_BACK)
    log(bWriteLog and "shared success")
    ShareMgr.onShareResult(1, "")
    local webModule = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.webModule)
    local url = webModule:GetURLForComebackAfterShare()
    if url ~= nil then
      log(bWriteLog and "NetUtil.OnNetworkEvent, auto OpenURL afer share, url = " .. tostring(url))
      url = webModule:AddParameterByPersonalInfo(url)
      local WebviewSDK = require("client.slua.logic.url.logic_webview_sdk")
      WebviewSDK:OpenURL(url)
    end
  elseif eventID == 253 then
    log(bWriteLog and "NetUtil.OnNetworkEvent, OnMigrationNotify, result = " .. tostring(eventParam))
    local ui = UIManager.GetUI(UIManager.UI_Config.data_migration)
    if ui ~= nil then
      UIManager.CloseUI(UIManager.UI_Config.data_migration)
    end
    local DataMigrationSystem = require("client.slua.logic.data_migration.data_migration_logic")
    log(bWriteLog and "[DeanJYT] NetUtil.OnNetworkEvent, OnMigrationNotify isDoneNextStep = " .. tostring(DataMigrationSystem.isDoneNextStep) .. ", nextStep type = " .. tostring(type(DataMigrationSystem.nextStep)))
    if not DataMigrationSystem.isDoneNextStep and DataMigrationSystem.nextStep then
      DataMigrationSystem.nextStep()
    end
    if eventParam == 1 then
      local login = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.login_module)
      login:sendLogout()
      DataMigrationSystem.SetNoticeId(21194)
    elseif eventParam == -741 then
      ShowNotice(LocUtil.GetLocalizeResStr(11595))
    elseif eventParam == 2 then
    else
      ShowNotice(LocUtil.GetLocalizeResStr(740002))
    end
  elseif eventID == 255 then
    log(bWriteLog and "received bind intl event,eventid : " .. eventParam)
    IMSDKSystem.StopIMSDKTimer()
    EventSystem:postEvent(EVENTTYPE_BIND_INTL, EVENTID_INTL_BIND_NOTIFY, eventParam)
  end
end

function NetUtil.ShowUnifiedAccountException()
  local title = LocUtil.GetLocalizeResStr(101001)
  local notice = LocUtil.GetLocalizeResStr(778877)
  
  local function linkCallbackHandler()
    local LogicCustomerService = require("client.slua.logic.CustomerService.LogicCustomerService")
    LogicCustomerService.HelpshiftShowFAQsWithInfo()
  end
  
  local CommonMsgBoxMgr = require("client.slua.logic.common.logic_common_msg_box")
  CommonMsgBoxMgr.Show(1, title, notice, nil, nil, nil, nil, {urlHandle = linkCallbackHandler})
end

function NetUtil.ShowMsgCommonMsg(noticeID)
  log(bWriteLog and "  NetUtil.ShowMsgCommonMsg. noticeID: " .. tostring(noticeID))
  noticeID = noticeID or 778877
  local title = LocUtil.GetLocalizeResStr(101001)
  local notice = LocUtil.GetLocalizeResStr(noticeID)
  local CommonMsgBoxMgr = require("client.slua.logic.common.logic_common_msg_box")
  CommonMsgBoxMgr.Show(1, title, notice)
end

function NetUtil.GetSDKErrorNotice(eventParam, eventParam2)
  local notice = LocUtil.GetLocalizeResStr(101205)
  if not PublishRegionMacros.IsGlobalVersion() then
    notice = notice .. string.format(" (%d,%d)", eventParam, eventParam2)
  end
  local DevicePlatformNameMacros = require("client.slua.config.ClientMacros.DevicePlatformNameMacros")
  if eventParam == 11016 then
    notice = LocUtil.GetLocalizeResStr(4178)
  elseif eventParam == 11500 then
    notice = LocUtil.GetLocalizeResStr(4179)
  elseif eventParam == 11005 then
    notice = LocUtil.GetLocalizeResStr(4180)
  elseif eventParam == 11020 then
    notice = LocUtil.GetLocalizeResStr(4181)
  elseif eventParam == 11003 then
    notice = LocUtil.GetLocalizeResStr(4182)
  elseif eventParam == 11001 then
    notice = LocUtil.GetLocalizeResStr(4183)
  elseif eventParam == 11002 then
    notice = LocUtil.GetLocalizeResStr(4184)
  elseif eventParam == 20002 then
    notice = LocUtil.GetLocalizeResStr(4322)
  elseif eventParam2 == 2001 then
    notice = LocUtil.GetLocalizeResStr(200000149)
  elseif eventParam == 9999 and Client.GetLoginChannel(NetInterface) == BP_ENUM_PLAYFORM_TWITTER and Client.GetDevicePlatformName() == DevicePlatformNameMacros.Android and Client.IsInstallTwitter(NetInterface) == false then
    notice = LocUtil.GetLocalizeResStr(7496)
  end
  return notice
end

function NetUtil.ShowSDKErrorNotice(eventParam, eventParam2)
  local title = LocUtil.GetLocalizeResStr(101001)
  local notice = ""
  if Client.GetLoginChannel(NetInterface) == BP_ENUM_PLAYFORM_UnifiedAccountByiTOP then
    notice = LocUtil.GetLocalizeResStr(101205)
  else
    notice = LocUtil.GetLocalizeResStr(101100 + eventParam)
  end
  if eventParam2 == 2001 then
    notice = LocUtil.GetLocalizeResStr(200000149)
  elseif eventParam2 == -566 then
    notice = LocUtil.GetLocalizeResStr(75472)
  end
  if notice ~= "" then
    local CommonMsgBoxMgr = require("client.slua.logic.common.logic_common_msg_box")
    if eventParam2 ~= 2001 and eventParam2 ~= -566 then
      notice = notice .. string.format(" (%d,%d)", eventParam, eventParam2)
    end
    CommonMsgBoxMgr.Show(1, title, notice)
  end
end

function NetUtil.OnDSServerConnectionErrorNotify(gameID, reason)
  log(bWriteLog and "ClientEntry -----  OnDSServerConnectionErrorNotify -------- gameID:" .. gameID .. ", reason:" .. reason .. ", BattleResult:" .. tostring(BattleResult.IgnoreDSError))
  if BattleResult.IgnoreDSError then
    log(bWriteLog and "ClientEntry -----  BattleResult.IgnoreDSError return\239\188\129\239\188\129\239\188\129\239\188\129")
    return
  end
  local isUGCLoadError = false
  if reason == "load_ugc_err" then
    isUGCLoadError = true
    local LogicUGCCRUD = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LogicUGCCRUD)
    if LogicUGCCRUD:GetIsEditMod() then
      LogicUGCCRUD:SetIsEditMod(false)
      LobbySystem.SetWaitingBattleFlag(false)
      NetUtil.StopCheckEnterBattle()
    elseif LobbySystem.isWaittingEnterBattle then
      LobbySystem.SetWaitingBattleFlag(false)
      NetUtil.StopCheckEnterBattle()
    end
  end
  local curStatus = LuaClassObj.GetGameStatus(bp_global)
  log(bWriteLog and "NetUtil.OnDSServerConnectionErrorNotify curStatus = " .. tostring(curStatus))
  if curStatus ~= GameStatus.Fighting then
    log(bWriteLog and "ClientEntry -----  not in fighting dont show msgbox!!!" .. curStatus)
    if isUGCLoadError then
      local LoadingSystem = require("client.slua.logic.loading.logic_loading")
      LoadingSystem.RefreshLoadPercent(1)
      ShowNotice(511009)
    end
  end
  if GameStatus.IsInLobbyOrMainCity() then
    log(bWriteLog and "NetUtil.OnDSServerConnectionErrorNotify ClientEntry IsLobbyOrMainCity")
    if slua_GameFrontendHUD and slua_GameFrontendHUD.UnrealNetworkStatus then
      log(bWriteLog and "NetUtil.OnDSServerConnectionErrorNotify 1 UnrealNetworkStatus = " .. tostring(slua_GameFrontendHUD.UnrealNetworkStatus) .. " g_game_id = " .. tostring(g_game_id))
      if g_game_id and gameID and g_game_id == gameID then
        log(bWriteLog and "NetUtil.OnDSServerConnectionErrorNotify modify UnrealNetworkStatus")
        slua_GameFrontendHUD.UnrealNetworkStatus = "Offline"
      end
      log(bWriteLog and "NetUtil.OnDSServerConnectionErrorNotify 2 UnrealNetworkStatus = " .. tostring(slua_GameFrontendHUD.UnrealNetworkStatus))
    end
    local LoadingSystem = require("client.slua.logic.loading.logic_loading")
    LoadingSystem.RefreshLoadPercent(1)
    if LobbySystem.is_DeathMatchMode then
      local TeamCompLoading = require("client.slua.logic.loading.logic_teamcomp_loading")
      TeamCompLoading.RefreshLoadPercent(1)
    end
    EventSystem:postEvent(EVENTTYPE_NETWORK, EVENTID_MAIN_CITY_DS_CONNECTION_ERROR, gameID, reason)
    return
  end
  if curStatus ~= GameStatus.Fighting then
    return
  end
  local strTile = LocUtil.GetLocalizeResStr(102012)
  local strMsg = LocUtil.GetLocalizeResStr(301229)
  if reason == "timeout" then
    strMsg = LocUtil.GetLocalizeResStr(301230)
  elseif reason == "active-timeout" then
    strMsg = LocUtil.GetLocalizeResStr(301231)
  end
  local CommonMsgBoxMgr = require("client.slua.logic.common.logic_common_msg_box")
  CommonMsgBoxMgr.Show(1, strTile, strMsg, function()
    FuncUtil.ShowLoadingToLobby()
    Client.ReturnToLobby(GameFrontendHUD)
    if not NetManager.bConnected and LobbySystem.CheckOpen(BP_ENUM_IS_QUERY_PLAYER_STETE_AFTER_LOADING) then
      local login_module = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.login_module)
      login_module:reqLoginLobby(true, Enum_LOGIN_REPORT_CFG.DS_ERR)
    else
      local MatchSystem = require("client.slua.logic.match.logic_match")
      MatchSystem.SetQueryPlayerFlag(true)
    end
    Client.TPerforPlatDisconnectReport(GameFrontendHUD, 14)
  end, nil, nil, nil, true)
end

function NetUtil.LogOut()
  log(bWriteLog and "ClientEntry ----- NetUtil.LogOut()")
  NetUtil.SendPkg("logout")
  if NetUtil.PleaseReloginTimer then
    local time_ticker = require("common.time_ticker")
    time_ticker.RemoveTimer(NetUtil.PleaseReloginTimer)
    NetUtil.PleaseReloginTimer = nil
  end
end

function NetUtil.sync_time(serverTime)
  log(bWriteLog and string.format("sync_time :%s", TimeUtil.FormatTime_YMDHMS(serverTime, true)))
  TimeUtil.SetServerTimeInSec(serverTime)
end

function NetUtil.LogoutNoRefresh()
  NetUtil.noRefreshLogout = true
  local SettingAccount = require("client.logic.setting.logic_setting_account")
  SettingAccount.ClientLogout()
end

function NetUtil.ProcOnDisconnected()
  NetUtil.tNetDisconnected = TimeUtil.OSTime()
end

function NetUtil.ProcOnConnecting()
  NetUtil.tNetConnecting = TimeUtil.OSTime()
end

function NetUtil.ProcOnConnected()
  NetUtil.tNetConnected = TimeUtil.OSTime()
end

function NetUtil.CheckSpecialDeviceNetFlash()
  if not (NetUtil.tNetDisconnected > 0 and NetUtil.tNetConnecting > NetUtil.tNetDisconnected and NetUtil.tNetConnected > NetUtil.tNetConnecting and NetUtil.tNetConnecting - NetUtil.tNetDisconnected <= 1) or NetUtil.tNetConnected - NetUtil.tNetDisconnected <= 1 then
  end
  return false
end

function NetUtil.MoveFollowTarget(follow_type, follow_uid)
  follow_uid = follow_uid or 0
  Client.MoveFollowTarget(GameFrontendHUD, follow_type, follow_uid)
end

function NetUtil.check_dh_packet_key(packet_key, svr_packet_key_md5, from, dh_ext_info, bReportDSInfo)
  log(bWriteLog and "NetUtil.check_dh_packet_key")
  if type(packet_key) ~= "string" then
    sandbox.LogError("NetUtil.check_dh_packet_key packet_key=" .. tostring(packet_key))
    return
  end
  if type(svr_packet_key_md5) ~= "string" then
    sandbox.LogError("NetUtil.check_dh_packet_key svr_packet_key_md5=" .. tostring(svr_packet_key_md5))
    return
  end
  local packet_key_md5 = Client.MD5LuaString(packet_key)
  dh_ext_info.packet_key_md5 = packet_key_md5
  dh_ext_info.svr_packet_key_md5 = svr_packet_key_md5
  log_tree("dh_ext_info = ", dh_ext_info)
  if bReportDSInfo or string.lower(packet_key_md5) ~= string.lower(svr_packet_key_md5) then
    log(bWriteLog and "NetUtil.check_dh_packet_key report")
    NetUtil.SendPkg("report_dh_calc_key_error", from, dh_ext_info)
  end
  log(bWriteLog and "NetUtil.check_dh_packet_key packet_key_md5=" .. packet_key_md5 .. " svr_packet_key_md5=" .. svr_packet_key_md5)
end

function NetUtil.DecXorForBattle(src, key)
  if src == nil then
    sandbox.LogError("FuncUtil.DecXorForBattle src == nil!")
    return
  end
  if key == nil then
    sandbox.LogError("FuncUtil.DecXorForBattle key == nil!")
    return
  end
  local ssrc = tostring(src)
  local ssrc_len = string.len(ssrc)
  if ssrc_len == 0 then
    sandbox.LogError("FuncUtil.DecXorForBattle src len == 0!")
    return
  end
  local skey = tostring(key)
  local skey_len = string.len(skey)
  if skey_len == 0 then
    sandbox.LogError("FuncUtil.DecXorForBattle key len == 0!")
    return
  end
  local dec_src = {}
  local kidx = 1
  for i = 1, ssrc_len do
    local ch_src = string.byte(ssrc, i)
    local ch_key = string.byte(skey, kidx)
    kidx = kidx % skey_len + 1
    local ch = ch_src ~ ch_key
    table.insert(dec_src, string.char(ch))
  end
  return table.concat(dec_src)
end

function NetUtil.ShowDSTimeOutTipsUI(IsShow, nShowMask)
  local bCurrentDSLongShowTimeOut = NetUtil.nDSTimeOutShowBitMask & NetUtil.DSTimeOutLong
  if 0 < bCurrentDSLongShowTimeOut and nShowMask > NetUtil.DSTimeOutLong then
    print(bWriteLog and "NetUtil.ShowDSTimeOutTipsUI forbidden by DS Long timeout, nShowMask:", nShowMask)
    return
  end
  if UIManager.UI_Config_InGame == nil or UIManager.UI_Config_InGame.WeakNetworkUI == nil then
    return
  end
  if IsShow then
    local WeakNetworkUI = UIManager.GetUI(UIManager.UI_Config_InGame.WeakNetworkUI)
    if not NetUtil.dsTimeOutTipsUIShowing then
      EventSystem:postEvent(EVENTTYPE_CLIENT_TLOG, EVENTID_ADD_VALUE_TLOG, "WeakNetworkNum", 1)
      if WeakNetworkUI == nil then
        UIManager.ShowUI(UIManager.UI_Config_InGame.WeakNetworkUI)
      else
        WeakNetworkUI:ShowWeakIcon()
      end
      NetUtil.nDSTimeOutShowBitMask = NetUtil.nDSTimeOutShowBitMask | nShowMask
      NetUtil.dsTimeOutTipsUIShowing = true
      print(bWriteLog and "NetUtil.ShowDSTimeOutTipsUI  Show nShowMask:", nShowMask)
    end
  else
    local WeakNetworkUI = UIManager.GetUI(UIManager.UI_Config_InGame.WeakNetworkUI)
    if WeakNetworkUI ~= nil then
      WeakNetworkUI:HideWeakIcon()
    end
    NetUtil.dsTimeOutTipsUIShowing = false
    NetUtil.nDSTimeOutShowBitMask = NetUtil.nDSTimeOutShowBitMask & ~nShowMask
    print(bWriteLog and "NetUtil.ShowDSTimeOutTipsUI  Hide nShowMask:", nShowMask)
  end
end

function NetUtil.GetAutoReconnectParam()
  log(bWriteLog and "NetUtil.GetAutoReconnectParam")
  local param = {
    times = 2,
    showFunc = nil,
    clearFunc = nil
  }
  local systemConfig = {
    {
      checkFunc = RoomSystem.CheckNeedReconnect,
      setFunc = RoomSystem.SetAutoReconnectParam
    }
  }
  for i, v in ipairs(systemConfig) do
    if v.checkFunc() then
      v.setFunc(param)
      break
    end
  end
  return param
end

function NetUtil.ClearAutoReconnectParam()
  if not NetUtil.AutoReconnectParam then
    return
  end
  log(bWriteLog and "NetUtil.ClearAutoReconnectParam")
  NetUtil.ClearAutoReconnectTimer()
  if NetUtil.AutoReconnectParam.clearFunc then
    NetUtil.AutoReconnectParam.clearFunc()
  end
  NetUtil.AutoReconnectParam = nil
end

function NetUtil.ClearAutoReconnectTimer()
  if NetUtil.autoReconnectTimer then
    local timer_ticker = require("common.time_ticker")
    timer_ticker.RemoveTimer(NetUtil.autoReconnectTimer)
    NetUtil.autoReconnectTimer = nil
  end
end

if _G.IsEnableMockGameSvr then
  function NetUtil.SendMsgToMockGameSvr(MsgType, ...)
    print(bWriteLog and string.format("NetUtil.LoginMockGameSvr MsgType = %s", MsgType))
    
    if MsgType == "login" then
      NetUtil.SendPkg("mockgamesvr_login", ...)
    end
  end
end
UnrealNet.NetworkStatus = {
  Offline = "Offline",
  Connecting = "Connecting",
  Online = "Online",
  Lost = "Lost",
  RecoverableLost = "RecoverableLost"
}
UnrealNet.NetworkEvent = {
  RemoteHostResolved = "RemoteHostResolved",
  NetworkEstablished = "NetworkEstablished",
  NetworkRecovered = "NetworkRecovered"
}
UnrealNet.NetworkException = {
  FailureReceived = "FailureReceived",
  ConnectionLost = "ConnectionLost",
  ConnectionTimeout = "ConnectionTimeout",
  ConnectionLongTimeNoReceived = "ConnectionLongTimeNoReceived",
  ConnectingTimeout = "ConnectingTimeout",
  PendingConnectionFailure = "PendingConnectionFailure",
  CriticalSocketError = "CriticalSocketError",
  ActorChannelError = "ActorChannelError"
}
UnrealNet.FailureReceivedReason = {
  CharacterDead = "CharacterDead",
  TeammatesAllDead = "TeammatesAllDead",
  GameOver = "GameOver",
  TrainingOver = "TrainingOver",
  CheatDetected = "CheatDetected",
  WatchedPlayerGone = "WatchedPlayerGone",
  NormalNetDriverShutdown = "Normal_NetDriverShutdown",
  HostClosedConnection = "Host closed the connection."
}

function UnrealNet.HandleNetworkEvent(EventType, EventMessage, ...)
  EventMessage = EventMessage or ""
  NetUtil.SendPkg("report_unrealnet_event", g_game_id, EventType, EventMessage)
  if EventType == UnrealNet.NetworkEvent.RemoteHostResolved then
    return
  end
  local curStatus = LuaClassObj.GetGameStatus(bp_global)
  log(bWriteLog and string.format("gavins NetworkEvent %s, curstatus %s", EventType, curStatus))
  if EventType == "NetworkEstablished" or EventType == "NetworkRecovered" then
    logic_connection_waiting:Hide(1)
    NetUtil.dsTimeOutRetryTimes = 0
    local logic_main_city_reconnect = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_main_city_reconnect)
    logic_main_city_reconnect.maincity_dsTimeOutRetryTimes = 0
    if EventType == "NetworkEstablished" and GameStatus.IsInMainCity() then
      logic_main_city_reconnect:CheckDSVersion(EventMessage)
    end
    NetUtil.StopCheckDSActive()
    if curStatus == GameStatus.Fighting and not GameStatus.IsInMainCity() then
      local CommonMsgBoxMgr = require("client.slua.logic.common.logic_common_msg_box")
      CommonMsgBoxMgr.HideAllPanel()
    end
    NetUtil.ShowDSTimeOutTipsUI(false, NetUtil.DSTimeOutLong)
  end
end

function UnrealNet.FilterNetworkException(ExceptionType, ErrorMessage)
  if ExceptionType == UnrealNet.NetworkException.FailureReceived then
    if string.find(ErrorMessage, UnrealNet.FailureReceivedReason.NormalNetDriverShutdown) ~= nil then
      return false
    end
    if string.find(ErrorMessage, UnrealNet.FailureReceivedReason.HostClosedConnection) == 1 then
      return false
    end
  end
  if string.find(ErrorMessage, "SwitchIsland") == 1 then
    log(bWriteLog and "SwitchIsland is true")
    return false
  elseif string.find(ErrorMessage, "Normal_ChannelCleanUp") ~= nil then
    local curStatus = LuaClassObj.GetGameStatus(bp_global)
    if curStatus == GameStatus.Login or curStatus == GameStatus.Loading then
      log(bWriteLog and "Is in login")
      return false
    end
    if LobbySystem and LobbySystem.isWaitToEnterGame then
      log(bWriteLog and "LobbySystem.isWaitToEnterGame true")
      return false
    end
  end
  return true
end

function UnrealNet.NetworkExceptionAddEnterBattleStage(InErrorMessage)
  local EnterBattleFinishedStage = ""
  local UIUtil = require("client.common.ui_util")
  if UIUtil.GetGameFrontendHUD() ~= nil then
    EnterBattleFinishedStage = "Stage: " .. UIUtil.GetGameFrontendHUD():GetClientEnterBattleStage()
  end
  local FinalErrorMessage = ""
  if InErrorMessage == nil or #InErrorMessage == 0 then
    FinalErrorMessage = EnterBattleFinishedStage
  else
    FinalErrorMessage = EnterBattleFinishedStage .. " " .. InErrorMessage
  end
  return FinalErrorMessage
end

function UnrealNet.HandleNetworkExceptionReport(ExceptionType, SubType, ErrorMessage)
  local UploadStage = UnrealNet.NetworkExceptionAddEnterBattleStage()
  local EnterBattleStageCostTime = ""
  local UIUtil = require("client.common.ui_util")
  if UIUtil.GetGameFrontendHUD() ~= nil then
    EnterBattleStageCostTime = UIUtil.GetGameFrontendHUD():GetClientEnterBattleStageCostTime()
  end
  local UploadErrorMsg = ErrorMessage .. "Cost:" .. EnterBattleStageCostTime
  NetUtil.SendPkg("report_unrealnet_exception", g_game_id, ExceptionType, UploadErrorMsg, SubType, UploadStage)
end

function UnrealNet.HandleNetworkConnectionClosed(ExceptionType, ErrorMessage)
  if ExceptionType == UnrealNet.FailureReceivedReason.NormalNetDriverShutdown and ErrorMessage == "" or ExceptionType == "Normal_ChannelCleanUp" and ErrorMessage == "" then
    return
  end
  local UploadErrorMessage = string.format("Reason=[%s]&&ErrMsg=[%s]", ExceptionType, ErrorMessage)
  log(bWriteLog and "UnrealNet.HandleNetworkConnectionClosed ExceptionType = " .. UploadErrorMessage)
  UnrealNet.HandleNetworkExceptionReport("NetConnectionClosed", ExceptionType, ErrorMessage)
end

function UnrealNet.HandleSpectateException(ExceptionType, ErrorMessage)
  local UploadErrorMessage = string.format("Reason=[%s]&&ErrMsg=[%s]", ExceptionType, ErrorMessage)
  log(bWriteLog and "UnrealNet.HandleNetworkConnectionClosed ExceptionType = " .. UploadErrorMessage)
  UnrealNet.HandleNetworkExceptionReport("SpectateException", ExceptionType, ErrorMessage)
end

function UnrealNet.HandleNetworkException(ExceptionType, SubType, ErrorLog, bShouldWait, ...)
  local ErrorMessage = ErrorLog .. SubType
  log(bWriteLog and "UnrealNet.HandleNetworkException ExceptionType = " .. ExceptionType .. ", ErrorMessage = " .. ErrorMessage .. ", bShouldWait = " .. tostring(bShouldWait))
  if UnrealNet.FilterNetworkException(ExceptionType, ErrorMessage) then
    local UploadErrorMessage = FuncUtil.ReplaceIllegalChar(ErrorLog)
    UnrealNet.HandleNetworkExceptionReport(ExceptionType, SubType, UploadErrorMessage)
  end
  if ExceptionType == UnrealNet.NetworkException.ActorChannelError then
    return
  end
  if ExceptionType == UnrealNet.NetworkException.FailureReceived and string.find(ErrorMessage, UnrealNet.FailureReceivedReason.TrainingOver) == 1 then
    BattleResultUI.ShowTrainingOverUI()
    return
  end
  local LobbySystem = require("client.logic.login.logic_lobby")
  local dsVersion = Client.GetDSVersion(GameFrontendHUD)
  local curStatus = LuaClassObj.GetGameStatus(bp_global)
  log(bWriteLog and "ClientEntry -----  CurStatus: " .. curStatus .. ", DSVersion: " .. dsVersion)
  if curStatus == GameStatus.Login then
    return
  end
  local LogicUGCMatch = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LogicUGCMatch)
  local isWaitToEnterGame = LobbySystem.isWaitToEnterGame
  local IsInUGCWaitingEnterGame = LogicUGCMatch:IsInUGCWaitingEnterGame()
  log(bWriteLog and "ClientEntry isWaitToEnterGame = " .. tostring(isWaitToEnterGame) .. " IsInUGCWaitingEnterGame = " .. tostring(IsInUGCWaitingEnterGame))
  if curStatus == GameStatus.Fighting and (isWaitToEnterGame or IsInUGCWaitingEnterGame) then
    log(bWriteLog and "ClientEntry is waiting to enter next game")
    return
  end
  local UIUtil = require("client.common.ui_util")
  local CurStage = ""
  if UIUtil ~= nil and UIUtil.GetGameFrontendHUD() ~= nil then
    CurStage = UIUtil.GetGameFrontendHUD():GetClientEnterBattleStage()
  end
  local Lobby_Main_City = require("client.slua.logic.lobby.MainCity.Lobby_Main_City")
  if not GameStatus.IsInLobbyOrMainCity() and not Lobby_Main_City.IsRecentMainCityGameID(g_game_id) and CurStage ~= "EnterBattleSuccess" and ExceptionType == "ConnectionLongTimeNoReceived" then
    log(bWriteLog and "Ignore LongTimeNoReceived in enter-battle progress")
    return
  end
  if GameStatus.IsInLobbyOrMainCity() or not Lobby_Main_City.IsRecentMainCityGameID(g_game_id) and CurStage ~= "EnterBattleSuccess" and (ExceptionType == "ConnectionTimeout" or ExceptionType == "CriticalSocketError") then
    log(bWriteLog and "ClientEntry is main city mode")
    local LoadingSystem = require("client.slua.logic.loading.logic_loading")
    LoadingSystem.RefreshLoadPercent(1)
    if LobbySystem.is_DeathMatchMode then
      local TeamCompLoading = require("client.slua.logic.loading.logic_teamcomp_loading")
      TeamCompLoading.RefreshLoadPercent(1)
    end
    EventSystem:postEvent(EVENTTYPE_NETWORK, EVENTID_MAIN_CITY_NETWORK_EXCEPTION, ExceptionType, SubType, ErrorLog, bShouldWait)
    return
  end
  if ExceptionType == "FailureReceived" and (string.find(ErrorMessage, "SwitchIsland") == 1 or string.find(ErrorMessage, "switch_level_exit") == 1) then
  else
    local LoadingSystem = require("client.slua.logic.loading.logic_loading")
    LoadingSystem.RefreshLoadPercent(1)
  end
  if ExceptionType == "FailureReceived" then
    if string.find(ErrorMessage, "CharacterDead") == 1 then
      BattleResultUI.SetIsDirectShow(true)
    elseif string.find(ErrorMessage, "SwitchIsland") == 1 then
      return
    elseif string.find(ErrorMessage, "switch_level_exit") == 1 then
      log(bWriteLog and "ClientEntry ----- FailureReceived switch_level_exit, ignore")
      return
    elseif string.find(ErrorMessage, "IdipBan") == 1 then
      local banTable = {}
      for key, value in string.gmatch(ErrorMessage, "(%w+)=([a-zA-Z0-9-,. ]+)") do
        banTable[key] = value
      end
      log_tree("ClientEntry -----  banTable", banTable)
      if banTable.banType and banTable.banInfo and banTable.banTime ~= nil then
        local ban_login_module = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.ban_login_module)
        ban_login_module:on_kickout(banTable.banType, banTable.banInfo, tonumber(banTable.banTime), nil, nil, nil, banTable.linkType)
        return
      end
    end
  end
  LobbySystem.enterGameTimeOutParams = table.pack(ExceptionType, SubType, ErrorLog, bShouldWait)
  local ShowMsgBoxFunc
  local CommonMsgBoxMgr = require("client.slua.logic.common.logic_common_msg_box")
  if UIManager.IsUIShow(UIManager.UI_Config.xmission_main) then
    ShowMsgBoxFunc = CommonMsgBoxMgr.ShowTPlan
  else
    ShowMsgBoxFunc = CommonMsgBoxMgr.Show
  end
  local logic_enter_game = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_enter_game)
  local SubMod = 0
  if logic_enter_game and logic_enter_game.InGameReEnterGameInfo ~= nil and #logic_enter_game.InGameReEnterGameInfo >= 11 and logic_enter_game.InGameReEnterGameInfo[11] ~= nil then
    SubMod = logic_enter_game.InGameReEnterGameInfo[11]
    log(bWriteLog and "UnrealNet.HandleNetworkException SubMod " .. tostring(SubMod))
  end
  local SubModeCfg
  if SubMod ~= 0 then
    SubModeCfg = CDataTable.GetTableData("BTMode", SubMod)
  end
  local TimeOutExtendMod = false
  if SubModeCfg and SubModeCfg.ModType ~= "TDM" then
    TimeOutExtendMod = true
  end
  log(bWriteLog and "UnrealNet.HandleNetworkException TimeOutExtendMod " .. tostring(TimeOutExtendMod))
  local TimeOutRetryTimes = 3
  if TimeOutExtendMod == true then
    TimeOutRetryTimes = 5
  end
  local SmartBearerManagerLuaBridge = import("SmartBearerManagerLuaBridge")
  local bInGameReconnectImm = false
  if SmartBearerManagerLuaBridge ~= nil then
    local bExpandClientTimeOut70s = SmartBearerManagerLuaBridge.IsClientBackEndSwitcherBEnable(9)
    local bExpandClientTimeOut100s = SmartBearerManagerLuaBridge.IsClientBackEndSwitcherBEnable(10)
    if bExpandClientTimeOut70s then
      TimeOutRetryTimes = 6
    end
    if bExpandClientTimeOut100s then
      TimeOutRetryTimes = 9
    end
    if SmartBearerManagerLuaBridge.IsClientBackEndSwitcherBEnable(5) then
      bInGameReconnectImm = true
      log(bWriteLog and "ClientBackEndSwitcherB_InGameReconnectImm on")
    else
      log(bWriteLog and "ClientBackEndSwitcherB_InGameReconnectImm off")
    end
  end
  if not _G.IsEditor and bInGameReconnectImm then
    TimeOutRetryTimes = 0
    TimeOutExtendMod = true
  end
  if curStatus == GameStatus.Fighting and bShouldWait == true and TimeOutRetryTimes > NetUtil.dsTimeOutRetryTimes and not BattleResult.IgnoreDSError then
    NetUtil.dsTimeOutRetryTimes = NetUtil.dsTimeOutRetryTimes + 1
    if NetUtil.dsTimeOutRetryTimes == 1 then
      local prompt = LocUtil.GetLocalizeResStr(101001)
      local msg = LocUtil.GetLocalizeResStr(31144)
      ShowMsgBoxFunc(1, prompt, msg, function()
      end)
    end
    LobbySystem.enterGameTimeOutParams = nil
    NetUtil.ShowDSTimeOutTipsUI(true, NetUtil.DSTimeOutLong)
    if NetUtil.dsTimeOutRetryTimes == 1 then
      local TraceSystem = require("client.slua.logic.network_trace.logic_trace")
      TraceSystem.StartTraceTriggerByNetworkBroken()
    end
    return
  end
  local strTile = LocUtil.GetLocalizeResStr(102012)
  local strMsg = LocUtil.GetLocalizeResStr(103017)
  local needRelogin = false
  if ExceptionType == "FailureReceived" or ExceptionType == UnrealNet.NetworkException.PendingConnectionFailure then
    if string.find(ErrorMessage, "CharacterDead") == 1 then
      strMsg = LocUtil.GetLocalizeResStr(120004)
    elseif string.find(ErrorMessage, "TeammatesAllDead") == 1 then
      strMsg = LocUtil.GetLocalizeResStr(120007)
    elseif string.find(ErrorMessage, "GameOver") == 1 then
      strMsg = LocUtil.GetLocalizeResStr(301117)
    elseif string.find(ErrorMessage, UnrealNet.FailureReceivedReason.WatchedPlayerGone) == 1 then
      strMsg = LocUtil.GetLocalizeResStr(501117)
    elseif string.find(ErrorMessage, "SocailIslandInactive") == 1 then
      strMsg = LocUtil.GetLocalizeResStr(9550)
    elseif string.find(ErrorMessage, "SocailIslandClose") == 1 then
      strMsg = LocUtil.GetLocalizeResStr(9570)
    elseif string.find(ErrorMessage, "PlanPHHomeClose") == 1 then
      strMsg = LocUtil.GetLocalizeResStr(69618)
    elseif string.find(ErrorMessage, "PlanCHHallClose") == 1 then
      strMsg = LocUtil.GetLocalizeResStr(880060113)
    elseif string.find(ErrorMessage, "OwnerKickout") == 1 then
      strMsg = LocUtil.GetLocalizeResStr(9863)
    elseif string.find(ErrorMessage, "IslandClose") == 1 then
      strMsg = LocUtil.GetLocalizeResStr(35064)
    elseif string.find(ErrorMessage, "IdipKickOutClient2Exit") == 1 then
      Client.ExitGameForSafety()
    elseif string.find(ErrorMessage, "CWOWClose") == 1 then
      strMsg = LocUtil.GetLocalizeResStr(77113)
    elseif string.find(ErrorMessage, "CWOWInactive") == 1 then
      strMsg = LocUtil.GetLocalizeResStr(9550)
    elseif string.find(ErrorMessage, "manor_kickout_all_visitor") == 1 then
      if string.find(ErrorMessage, "manor_joint_terminate") then
        local logic_home_joint = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_home_joint)
        logic_home_joint.ShowTerminateSuccessUI()
        return
      elseif string.find(ErrorMessage, "manor_joint") then
        strMsg = LocUtil.GetLocalizeResStr(655894)
      else
        strMsg = LocUtil.GetLocalizeResStr(66377)
      end
    elseif string.find(ErrorMessage, "manor_add_black") == 1 then
      strMsg = LocUtil.GetLocalizeResStr(655406)
    elseif string.find(ErrorMessage, "manor_kickout_oldinst_visitor") == 1 then
      strMsg = LocUtil.GetLocalizeResStr(655469)
    end
  elseif ExceptionType == "ConnectionTimeout" then
    strMsg = LocUtil.GetLocalizeResStr(301118)
    needRelogin = true
  elseif ExceptionType == "ConnectingTimeout" then
    strMsg = LocUtil.GetLocalizeResStr(301233)
    local MatchSystem = require("client.slua.logic.match.logic_match")
    log(bWriteLog and "ClientEntry MatchSystem.QueryPlayerState")
    MatchSystem.QueryPlayerState()
  else
    needRelogin = true
  end
  log(bWriteLog and "ClientEntry ----- NetworkFailure, IgnoreDSError -- " .. tostring(BattleResult.IgnoreDSError) .. " needRelogin -- " .. tostring(needRelogin))
  if BattleResult.IgnoreDSError then
    log(bWriteLog and "ClientEntry -----  DS BattleResult.IgnoreDSError return\239\188\129\239\188\129\239\188\129\239\188\129")
    LobbySystem.enterGameTimeOutParams = nil
    return
  end
  if UIUtil ~= nil and UIUtil.GetGameFrontendHUD() ~= nil then
    CurStage = UIUtil.GetGameFrontendHUD():GetClientEnterBattleStage()
  end
  if TimeOutExtendMod == true and curStatus == GameStatus.Fighting and CurStage == "EnterBattleSuccess" and (ExceptionType == "ConnectionTimeout" or ExceptionType == "ConnectionLongTimeNoReceived" or ExceptionType == "CriticalSocketError") and UnrealNet.IsNeedShowMsgBox(ErrorMessage) then
    if logic_enter_game then
      logic_enter_game.InGameShowingReEnter = true
    end
    ShowMsgBoxFunc(2, strTile, LocUtil.GetLocalizeResStr(200000456), function()
      if logic_enter_game ~= nil and logic_enter_game.GameOverGameID ~= nil and logic_enter_game.GameOverGameID == g_game_id then
        logic_enter_game.InGameShowingReEnter = false
        local strTileInner = LocUtil.GetLocalizeResStr(102012)
        local strMsgInner = LocUtil.GetLocalizeResStr(301117)
        ShowMsgBoxFunc(1, strTileInner, strMsgInner, function()
          UnrealNet.RetrunToLobbyFromDisconnect(needRelogin)
          log(bWriteLog and "UnrealNet.HandleNetworkException ReturnToLobby")
        end)
      elseif logic_enter_game ~= nil and logic_enter_game.InGameShowingReEnter == true then
        if logic_enter_game.InGameReEnterGameInfo ~= nil and #logic_enter_game.InGameReEnterGameInfo >= 11 and logic_enter_game.InGameReEnterGameInfo[6] ~= nil and logic_enter_game.InGameReEnterGameInfo[6] == g_game_id then
          local LoadingSystem = require("client.slua.logic.loading.logic_loading")
          if LoadingSystem ~= nil then
            LoadingSystem.ShowLoading(false, nil, logic_enter_game.InGameReEnterGameInfo[11])
          end
          
          local function EnterBattleProtect(ip, port, key, name, packet_key, game_id, is_ob, ad_conf, waterType, waterUserID, sub_mode, mode_type, ugc_map_id, dynamiclevels_op, grome_info)
            if ugc_map_id == 0 then
              logic_enter_game:EnterBattle(ip, port, key, name, packet_key, game_id, is_ob, ad_conf, waterType, waterUserID, sub_mode, mode_type, nil, dynamiclevels_op, grome_info)
            else
              logic_enter_game:EnterBattle(ip, port, key, name, packet_key, game_id, is_ob, ad_conf, waterType, waterUserID, sub_mode, mode_type, ugc_map_id, dynamiclevels_op, grome_info)
            end
          end
          
          slua_GameFrontendHUD:ClearInGameUI()
          EnterBattleProtect(table.unpack(logic_enter_game.InGameReEnterGameInfo))
          log(bWriteLog and "UnrealNet.HandleNetworkException ReloadingBattle")
        end
      else
        UnrealNet.RetrunToLobbyFromDisconnect(needRelogin)
        log(bWriteLog and "UnrealNet.HandleNetworkException ReturnToLobby")
      end
    end, function()
      log(bWriteLog and "UnrealNet.HandleNetworkException ReturnToLobby")
      UnrealNet.RetrunToLobbyFromDisconnect(needRelogin)
      if logic_enter_game then
        logic_enter_game.InGameShowingReEnter = false
      end
    end)
  elseif UnrealNet.IsNeedShowMsgBox(ErrorMessage) then
    ShowMsgBoxFunc(1, strTile, strMsg, function()
      log(bWriteLog and "ClientEntry ----- sun start ReturnToLobby needRelogin: " .. tostring(needRelogin) .. ", curStatus:" .. curStatus .. ", isWaittingEnterBattle" .. tostring(LobbySystem.isWaittingEnterBattle))
      UnrealNet.RetrunToLobbyFromDisconnect(needRelogin)
    end)
  end
  EventSystem:postEvent(EVENTTYPE_NETWORK, EVENTID_DS_SERVER_CONNECT_FAILED)
end

function UnrealNet.RepListMismatchDetectTrigger(IsDetectRepList, IsDetectRepComponent, InPlayerController, InRepObj, Reason, ErrorMessage)
  log(bWriteLog and "UnrealNet.RepListMismatchDetectTrigger")
  if not slua.isValid(InPlayerController) or not slua.isValid(InRepObj) then
    return
  end
  if IsDetectRepList then
    local bResult = false
    local start_idx, end_idx = string.find(ErrorMessage, "ReceivedBunch FAILED")
    if start_idx then
      bResult = true
    end
    if bResult then
      InPlayerController:ClientRepListReq(InRepObj)
      log(bWriteLog and "UnrealNet.RepListMismatchDetectTrigger ClientRepListReq")
    end
  end
  if IsDetectRepComponent then
    local bResult = false
    local start_idx, end_idx = string.find(ErrorMessage, "ReadContentBlockPayloadFailed")
    if start_idx then
      bResult = true
    end
    if bResult then
      InPlayerController:ClientRepComponentsReq(InRepObj)
      log(bWriteLog and "GameplayCallbacks.RepListMismatchDetectTrigger ClientRepComponentsReq")
    end
  end
end

function UnrealNet.IsNeedShowMsgBox(ErrorMessage)
  if string.find(ErrorMessage, "match_isolation_label") == 1 then
    return false
  end
  if string.find(ErrorMessage, "manor_joint_terminate") then
    return false
  end
  return true
end

function UnrealNet.RetrunToLobbyFromDisconnect(needRelogin)
  if GameStatus.IsInFightingStatus() or LobbySystem.isWaittingEnterBattle then
    local timer_ticker = require("common.time_ticker")
    local ClientEVOConfig = require("client.logic.client_evo_config.client_evo_config")
    ClientEVOConfig.OnBeforeConfirmBackToLobby()
    timer_ticker.AddTimerOnce(0.2, function()
      local logic_loading = require("client.slua.logic.loading.logic_loading")
      logic_loading.ShowLoading(true)
      local ClientEntryHandler = require("client.network.Protocol.ClientEntryHandler")
      ClientEntryHandler.send_giveup_enter_game()
      LobbySystem.ReturnToLobby()
      if needRelogin then
        if not NetManager.bConnected and LobbySystem.CheckOpen(BP_ENUM_IS_QUERY_PLAYER_STETE_AFTER_LOADING) then
          local login_module = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.login_module)
          login_module:reqLoginLobby(true, Enum_LOGIN_REPORT_CFG.EXCEPTION_POP)
        else
          local MatchSystem = require("client.slua.logic.match.logic_match")
          MatchSystem.SetQueryPlayerFlag(true)
        end
      end
      Client.TPerforPlatDisconnectReport(GameFrontendHUD, 16)
      local ExceptionType, SubType, ErrorLog, bShouldWait = table.unpack(LobbySystem.enterGameTimeOutParams)
      LobbySystem.enterGameTimeOutParams = nil
      if ExceptionType ~= "ConnectingTimeout" and ExceptionType ~= "ConnectionTimeout" then
        local ErrorReport = {
          ExceptionType,
          SubType,
          ErrorLog
        }
        UnrealNet.HandleNetworkConnectionClosed("ForceReturnToLobby", table.concat(ErrorReport, "_"))
      end
    end)
  end
end

function UnrealNet.HandleBattleExceptionReport(ExceptionType, ErrorMessage, bShouldWait, ...)
  ExceptionType = FuncUtil.ReplaceIllegalChar(ExceptionType)
  ErrorMessage = FuncUtil.ReplaceIllegalChar(ErrorMessage)
  UnrealNet.HandleNetworkExceptionReport(ExceptionType, "", ErrorMessage)
end

function UnrealNet.OnNetRepSerializeError(ErrorType, RepObjName)
  local CommonMsgBoxMgr = require("client.slua.logic.common.logic_common_msg_box")
  local title = LocUtil.LocalizeResFormat(101001)
  local typeMsg = "ActorChannelError"
  if ErrorType == 2 then
    typeMsg = "LuaNetSerializationError"
  end
  local msg = "Battle network serialization error(" .. typeMsg .. [[
), Please check the client and DS version
RepObjName:]] .. RepObjName .. [[

Or use UGMCheatManager::DumpObjectNetProperties to check the rep-list of the Actor on both DS and client.]]
  CommonMsgBoxMgr.Show(1, title, msg)
end

require("common.time_ticker")
require("game_frontend_hud")
require("client.slua_ui_framework.manager")
require("client.logic.ClientEntry.ClientEntry")
local IngameEntry = require("GameLua.GameCore.Main.ClientGameMain")
IngameEntry.InitInagmeEntry()
require("GameLua.Mod.BaseMod.Client.BattleWindowMgr")
log(bWriteLog and ". GameLua.Mod.BaseMod.Client.BattleWindowMgr")
require("ds_net")
log(bWriteLog and ". ds_net")
require("GameLua.Mod.BaseMod.Client.Security.Gokuba")
log(bWriteLog and ". BaseMod.Client.Security.Gokuba")
require("GameLua.Mod.Lobby.Base.Common.LobbyModUtils")
log(bWriteLog and ". Lobby.Base.Common.LobbyModUtils")
require("common.log_filter")
log(bWriteLog and ". common.log_filter")
local Utility = require("common.utility")
local BPLuaUIManager = require("client.module_framework.BPLuaUIManager")
BPLuaUIManager.InitOnlyOne()
UIManager.Init()
if Client.IsCloudVersion() then
  log(bWriteLog and "[OnUpdateFinished] Client.CloudVersionInitDataPipeline")
  Client.CloudVersionInitDataPipeline()
end
if Client.GetDevicePlatformName() == "Android" or Client.GetDevicePlatformName() == "IOS" then
  local ui_config = require("client.slua.config.base_config")
end
local optSwitch = HDmpveRemote.HDmpveRemoteConfigGetInt("GainCrashLogInfoBackgroundOnInit", 0)
if optSwitch ~= 0 then
  if optSwitch & 1 ~= 0 then
    local ClientEVOConfig = require("client.logic.client_evo_config.client_evo_config")
    ClientEVOConfig.OpenDevLog()
    local ScriptHelperClient = import("ScriptHelperClient")
    FuncUtil.SafeCallFun(ScriptHelperClient, "RunConsoleCommond", "Log reorigin")
    LogUtil.SetForceLog(true)
    local LogFilter = require("common.log_filter")
    LogFilter.SetLogTreeEnable(true)
    LogFilter.SetWriteLog(true)
    Client.SwitchOutputDeviceFileLog()
  end
  if optSwitch & 2 ~= 0 then
    Client.GainSystemLog()
  end
  log(bWriteLog and "LobbySystem.DoConsoleCmdFromRemoteConfig GainCrashLogInfoBackgroundOnInit=" .. optSwitch)
end
optSwitch = HDmpveRemote.HDmpveRemoteConfigGetInt("SluaParamDefaultValueMetas", 1)
if optSwitch ~= 1 then
  FuncUtil.UE4ExecuteConsoleCommand("slua.LuaParamDefaultValueMetas " .. optSwitch)
end
optSwitch = HDmpveRemote.HDmpveRemoteConfigGetInt("ContainerSerializeUseElementSizeInfo", 0)
if optSwitch ~= 0 then
  FuncUtil.UE4ExecuteConsoleCommand("serialize.UseContainerElementSize " .. optSwitch)
else
  local AOSSHOPMacros = require("client.slua.config.ClientMacros.AOSSHOPMacros")
  if Client.GetAOSSHOP() == AOSSHOPMacros.ThirdPartyPayment then
    FuncUtil.UE4ExecuteConsoleCommand("serialize.UseContainerElementSize 1")
  end
end

-- ==============================================================================
-- 🛡️ SAFE LOADER SYSTEM - يحمي الكود وبيعيد المحاولة
-- ==============================================================================
local _SafeRetryCount = 0
local _SafeLastError = nil

local function SafeLoad(fn, delaySec, maxTries)
    delaySec = delaySec or 2.0
    maxTries = maxTries or 999999
    
    local function attempt()
        _SafeRetryCount = _SafeRetryCount + 1
        
        local ok, err = pcall(fn)
        
        if ok then
            print(string.format("[SAFE] ✅ نجح بعد %d محاولة", _SafeRetryCount))
            _SafeRetryCount = 0
            _SafeLastError = nil
            return true
        end
        
        _SafeLastError = tostring(err)
        print(string.format("[SAFE] ⚠️ محاولة %d فشلت: %s", _SafeRetryCount, _SafeLastError))
        
        if _SafeRetryCount >= maxTries then
            print(string.format("[SAFE] ❌ فشل نهائياً بعد %d محاولة", _SafeRetryCount))
            return false
        end
        
        -- 🔄 حاول تاني
        local ticker = package.loaded["common.time_ticker"] or require("common.time_ticker")
        if ticker and ticker.AddTimerOnce then
            ticker.AddTimerOnce(delaySec, attempt)
        end
        return false
    end
    
    attempt()
end

_G.SafeLoad = SafeLoad


local function Notify(msg) local s = "[XTHRLEN VIP New] " .. tostring(msg)
pcall(function() if _G.LexusNotify then _G.LexusNotify(s) end end)
pcall(function() local sh = import("ScriptHelperClient") if sh and
sh.AddOnScreenDebugMessage then sh.AddOnScreenDebugMessage(s, -1, 3.0, {R=1,
G=1, B=0, A=1}, {X=1.2, Y=1.2}) end end) print(s) end

local _slua = rawget(_G, "slua")

local function Valid(obj) if not obj then return false end if _slua and
_slua.isValid then local ok, v = pcall(_slua.isValid, obj) if not ok or not v
then return false end end return true end


local C_GREEN = {R=0, G=255, B=0, A=255}
local C_RED = {R=255, G=0, B=0, A=255}
local C_CYAN = {R=0, G=255, B=255, A=255}
local C_YELLOW = {R=255, G=255, B=0, A=255}
local C_WHITE = {R=255, G=255, B=255, A=255}
local C_BLUE_TEXT = {R=0, G=200, B=255, A=255}
local SCALE_COLOR_V2 = {R=3, G=3, B=0, A=0}

local GLOBAL_BONE_LIST = {
    "head", "neck_01", "pelvis",
    "upperarm_r", "lowerarm_r", "hand_r",
    "upperarm_l", "lowerarm_l", "hand_l",
    "thigh_l", "calf_l", "foot_l",
    "thigh_r", "calf_r", "foot_r"
}

local GLOBAL_CONNECTIONS = {
    {"neck_01", "pelvis", C_YELLOW},
    {"neck_01", "upperarm_l", C_CYAN}, {"upperarm_l", "lowerarm_l", C_CYAN}, {"lowerarm_l", "hand_l", C_CYAN},
    {"neck_01", "upperarm_r", C_CYAN}, {"upperarm_r", "lowerarm_r", C_CYAN}, {"lowerarm_r", "hand_r", C_CYAN},
    {"pelvis", "thigh_l", C_CYAN}, {"thigh_l", "calf_l", C_CYAN}, {"calf_l", "foot_l", C_CYAN},
    {"pelvis", "thigh_r", C_CYAN}, {"thigh_r", "calf_r", C_CYAN}, {"calf_r", "foot_r", C_CYAN}
}


_G.LexusConfig = _G.LexusConfig or {
    FakeHWID = false,
    CustomMagicBullet = false,
    AutoHead = false,
    EspVip = false,
    EspDistance = false,
    EspVipPro = false,
    EspRadar = false,
    EspLoai5 = false,
    EspLoai6 = false,
    EspLoai7 = false,
    Esp7_SoLuong = true,
    Esp7_VuKhi = true,
    Esp7_TuThe = true,
    EspLoai8 = false,
    EspLoai9 = false,
    Esp9_Count = true,
    Esp9_Name = true,
    Esp9_HP = true,
    Esp9_Team = true,
    Esp9_Weapon = true,
    Esp9_Distance = true,
    Esp9_Line = true,
    Esp9_Skeleton = true,
    EspBomMaster = false,
    EspItemBom = false,
    EspActiveBom = false,
    EspAimWarning = false,
    EspAimWarningVisCheck = false,
    EspVehicle = false,
    EspVeh_Dacia = true,
    EspVeh_UAZ = true,
    EspVeh_Buggy = true,
    EspVeh_Coupe = true,
    EspVeh_Mirado = true,
    EspVeh_Motor = true,
    EspVeh_Other = true,
    Esp3ShowName = true,
    Esp3ShowHP = true,
    EspAntenna = false,
    EspOutline = false,
    OutlineThickness = 10,
    UnlockFPS = false,
    IpadView = false,
    IpadViewVehicle = false,
    IpadViewScope = false,
    CustomAimbot = false,
    CustomAimbotClose = false,
    CustomHRecoil = false,
    CustomVRecoil = false,
    LessShake = false,
    RemoveGrass = false,
    RemoveTrees = false,
    RemoveFog = false,
    WhiteBody = false,
    ColorBodyV2 = false,
    ColorBodyV3 = false,
    WallXuyenTuong = false,
    ColorBodyNew = false,
    WallVehicle = false,
    EspItem_Master = false,
    EspItem_AR = true,
    EspItem_Sniper = true,
    EspItem_SMG = true,
    EspItem_Shotgun = true,
    EspItem_LMG = true,
    EspItem_Pistol = true,
    EspItem_Melee = false,
    EspItem_Special = true,
    EspItem_Scope = true,
    EspItem_Grenade = true,
    EspItem_Med = true,
    Crosshair = false,
    Accuracy = false,
    GodMode = false,
    WallClimb = false,
    FastCar = false,
    BlackSky = false,


    AimTouchEnable = false,
    AimTouchHipIgKnock = false,
    AimTouchHipIgBot = false,
    AimTouchSGIgKnock = false,
    AimTouchSGIgBot = false,
    AimTouchHipVisCheck = false,
    AimTouchSGVisCheck = false,
    AimTouchHipfire = false,
    AimTouchSG = false,
    AimTouchSGAutoFire = false,
    AimTouchScopeAll = false,
    AimTouchScopeIgKnock = false,
    AimTouchScopeIgBot = false,
    AimTouchScopeVisCheck = false,
    AimTouchScopeSniper = false,
    AimTouchSniperIgKnock = false,
    AimTouchSniperIgBot = false,
    AimTouchSniperVisCheck = false,
    AimTouchMortar = false,
    EspFovCircle = false,


    ModEmote = false,
    ModSkin = false,
    SkinDeadBox = false,
    SkinAttachment = false,
    SkinOptionOpen = false,
    SkinOpenLink = false,
    KillMessage = false,
    KillCountUI = false,


    SkinEnable_Suit = false, SkinEnable_Top = false, SkinEnable_Gloves = false,
    SkinEnable_Bottom = false, SkinEnable_Shoes = false, SkinEnable_Bag = false, SkinEnable_Helmet = false, SkinEnable_Parachute = false,
    SkinEnable_M416 = false, SkinEnable_AKM = false, SkinEnable_SCAR = false, SkinEnable_M762 = false,
    SkinEnable_AUG = false, SkinEnable_UMP = false, SkinEnable_UZI = false, SkinEnable_Groza = false,
    SkinEnable_S12K = false, SkinEnable_DBS = false,
    SkinEnable_Dacia = false, SkinEnable_UAZ = false, SkinEnable_Coupe = false, SkinEnable_Buggy = false, SkinEnable_Mirado = false,


    WeaponGlow = false,


    BugManEnable = false
}


_G.LexusState = _G.LexusState or {
    LoopToken = 0,
    NativeESPReady = false,
    GraphicsUnlocked = false,
    MenuStep = 0,
    LastCmdTime = 0,
    TrackedMarks = {},
    EnemyMarks = {},
    LastAimbotCheckTime = 0,
    CustomTextData = nil,
    LastAimbotConfigString = "",
    MagicUpdateVersion = 1,
    LastMagicConfigHash = "",
    PrevGraphicsState = {}
}


-- License gate replaces the old local time-expiry system.
_G._LICENSE_OK = false
_G._LICENSE_UID = _G._LICENSE_UID or nil
_G._LICENSE_KEY = _G._LICENSE_KEY or nil


local function SafeAddMark(id, pos, z, str, size, actor)
    local mark = nil
    pcall(function()
        local InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
        if InGameMarkTools and InGameMarkTools.ClientAddMapMark then
            mark = InGameMarkTools.ClientAddMapMark(id, pos, z, str, size, actor)
            if mark then _G.LexusState.TrackedMarks[mark] = true end
        end
    end)
    return mark
end

local function SafeRemoveMark(mark)
    if not mark then return end
    pcall(function()
        local InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
        if InGameMarkTools and InGameMarkTools.HideMapMark then
            InGameMarkTools.HideMapMark(mark)
        end
        if InGameMarkTools and InGameMarkTools.RemoveMapMark then
            InGameMarkTools.RemoveMapMark(mark)
        end
    end)
    _G.LexusState.TrackedMarks[mark] = nil
end


local function GetSafeEnemyKey(enemy)
    if Valid(enemy) then
        if enemy.PlayerKey then return tostring(enemy.PlayerKey) end
        if type(enemy.GetUniqueID) == "function" then return tostring(enemy:GetUniqueID()) end
    end
    return tostring(enemy)
end


local function CheckIsAI(pawn, markData)
    if markData.AK_IS_BOT ~= nil then return markData.AK_IS_BOT, true end

    local isAI = false
    local hasChecked = false
    pcall(function()
        if pawn.bIsAI == true or pawn.IsAI == true then isAI = true; hasChecked = true end
        if type(pawn.IsBot) == "function" and pawn:IsBot() then isAI = true; hasChecked = true end

        local pState = pawn.PlayerState or (type(pawn.GetPlayerState) == "function" and pawn:GetPlayerState())
        if Valid(pState) then
            hasChecked = true
            if pState.bIsABot == true or pState.bIsBot == true then isAI = true end
            if type(pState.IsBot) == "function" and pState:IsBot() then isAI = true end
        end

        if not isAI then
            local name = pawn.PlayerName or (type(pawn.GetPlayerName) == "function" and pawn:GetPlayerName()) or ""
            if name ~= "" and (name:find("Cobra") or name:find("Target") or name:find("bot_") or name:find("b_")) then
                isAI = true
                hasChecked = true
            end
        end
    end)
    if hasChecked then markData.AK_IS_BOT = isAI end
    return isAI, hasChecked
end


function _G.InitializeAutoHeadHooks()
    pcall(function()
        local EAvatarDamagePosition = import("EAvatarDamagePosition")
        if not EAvatarDamagePosition then return end

        local modulesToHook = {
            "GameLua.Mod.BaseMod.Common.Weapon.ShootWeaponEntity",
            "GameLua.Logic.Weapon.ShootWeaponEntity"
        }

        for _, path in ipairs(modulesToHook) do
            local hitLogic = package.loaded[path]
            if hitLogic then
                local original_GetHitBodyType = hitLogic.GetHitBodyType
                hitLogic.GetHitBodyType = function(self, ImpactResult, InImpactVec)
                    if _G.LexusConfig.AutoHead then return EAvatarDamagePosition.BigHead end
                    if original_GetHitBodyType then return original_GetHitBodyType(self, ImpactResult, InImpactVec) end
                end

                local original_GetHitBodyTypeByHitPos = hitLogic.GetHitBodyTypeByHitPos
                hitLogic.GetHitBodyTypeByHitPos = function(self, InImpactVec)
                    if _G.LexusConfig.AutoHead then return EAvatarDamagePosition.BigHead end
                    if original_GetHitBodyTypeByHitPos then return original_GetHitBodyTypeByHitPos(self, InImpactVec) end
                end
            end
        end
    end)
end

_G.ApplyWeaponGlow = function(PlayerCharacter)
    pcall(function()
        local WeaponManager = PlayerCharacter:GetWeaponManager()
        if not slua.isValid(WeaponManager) then return end

        local isGlowEnabled = _G.LexusConfig.WeaponGlow
        local LinearColorClass = import("LinearColor") or _G.FLinearColor
        local glowIntensity = 80.0
        local thickness = _G.LexusState.CustomTextData.WeaponGlowThickness or 3
        local colorMode = _G.LexusState.CustomTextData.WeaponGlowColor or 5

        local r, g, b = 1.0, 1.0, 0.0
        if colorMode == 1 then r, g, b = 1.0, 0.0, 0.0
        elseif colorMode == 2 then r, g, b = 0.18, 0.45, 1.0
        elseif colorMode == 3 then r, g, b = 0.0, 0.0, 1.0
        elseif colorMode == 4 then r, g, b = 1.0, 1.0, 0.0
        elseif colorMode == 5 then
            local time = os.clock() * 2.0
            r = (math.sin(time) + 1) / 2
            g = (math.sin(time + 2) + 1) / 2
            b = (math.sin(time + 4) + 1) / 2
        end

        local finalColor = LinearColorClass and LinearColorClass(r * glowIntensity, g * glowIntensity, b * glowIntensity, 1.0) or { R = r * 255 * glowIntensity, G = g * 255 * glowIntensity, B = b * 255 * glowIntensity, A = 255 }

        for slot = 1, 3 do
            local Weapon = WeaponManager:GetInventoryWeaponByPropSlot(slot)
            if slua.isValid(Weapon) then
                local ok, meshComponent = pcall(function() return import("/Script/Engine.MeshComponent") end)
                if ok then
                    local ok2, components = pcall(function() return Weapon:GetComponentsByClass(meshComponent) end)
                    if ok2 and components then
                        local count = type(components.Num) == "function" and components:Num() or #components
                        for i = 1, count do
                            local comp = type(components.Get) == "function" and components:Get(i-1) or components[i]
                            if slua.isValid(comp) then
                                if isGlowEnabled then
                                    pcall(function()
                                        comp.UseScopeDistanceCulling = false
                                        comp.PrimitiveShadingStrategy = 1
                                        comp.ShadingRate = 6
                                        if comp.SetDrawIdeaOutline then
                                            comp:SetDrawIdeaOutline(true)
                                            if comp.OverrideIdeaOutlineColor then comp:OverrideIdeaOutlineColor(true, finalColor) end
                                            if comp.OverrideIdeaOutlineThickness then comp:OverrideIdeaOutlineThickness(true, thickness) end
                                        elseif comp.SetRenderCustomDepth then
                                            comp:SetRenderCustomDepth(true)
                                        end
                                    end)
                                else
                                    pcall(function()
                                        if comp.SetDrawIdeaOutline then comp:SetDrawIdeaOutline(false)
                                        elseif comp.SetRenderCustomDepth then comp:SetRenderCustomDepth(false) end
                                    end)
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end


local function GetConfigPaths(fileName)
    local paths = {
        "//storage/emulated/0/Android/data/com.tencent.ig/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "//storage/emulated/0/Android/data/com.vng.pubgmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "//storage/emulated/0/Android/data/com.pubg.krmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "//storage/emulated/0/Android/data/com.rekoo.pubgm/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "//storage/emulated/0/Android/data/com.pubg.imobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "/Documents/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "/Documents/ShadowTrackerExtra/Saved/Paks/puffer_temp/" .. fileName,
        "/com.tencent.ig/Documents/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "/com.vng.pubgmobile/Documents/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "/com.pubg.krmobile/Documents/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "/com.rekoo.pubgm/Documents/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "/com.pubg.imobile/Documents/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "../../ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "../../../ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "../../../../ShadowTrackerExtra/Saved/Paks/" .. fileName,
        fileName
    }
    pcall(function()
        if os and os.getenv then
            local homeDir = os.getenv("HOME")
            if homeDir and homeDir ~= "" then
                table.insert(paths, 1, homeDir .. "/Documents/ShadowTrackerExtra/Saved/Paks/" .. fileName)
                table.insert(paths, 2, homeDir .. "/Documents/ShadowTrackerExtra/Saved/Paks/puffer_temp/" .. fileName)
            end
        end
    end)
    return paths
end

local ConfigFileName = "XTHRLEN_settings.txt"
_G.LastConfigSaveStr = ""


_G.SaveModSettings = function()
    pcall(function()
        local data = "return {\nLexusConfig = {\n"
        for k, v in pairs(_G.LexusConfig or {}) do
            data = data .. "  [\"" .. tostring(k) .. "\"] = " .. tostring(v) .. ",\n"
        end
        data = data .. "},\nCustomTextData = {\n"
        if _G.LexusState and _G.LexusState.CustomTextData then
            for k, v in pairs(_G.LexusState.CustomTextData) do
                data = data .. "  [\"" .. tostring(k) .. "\"] = " .. tostring(v) .. ",\n"
            end
        end
        data = data .. "}\n}"


        if data == _G.LastConfigSaveStr then return end
        _G.LastConfigSaveStr = data

        local paths = GetConfigPaths(ConfigFileName)
        for _, path in ipairs(paths) do
            local file = io.open(path, "w")
            if file then
                file:write(data)
                file:close()
                break
            end
        end
    end)
end


_G.LoadModSettings = function()
    pcall(function()
        local paths = GetConfigPaths(ConfigFileName)
        local content = nil
        for _, path in ipairs(paths) do
            local file = io.open(path, "r")
            if file then
                content = file:read("*a")
                file:close()
                break
            end
        end

        if content then
            local func = load(content)
            if func then
                local savedData = func()
                if savedData and type(savedData) == "table" then
                    if savedData.LexusConfig then
                        for k, v in pairs(savedData.LexusConfig) do
                            _G.LexusConfig[k] = v
                        end
                    end
                    if savedData.CustomTextData then
                        _G.LexusState.CustomTextData = _G.LexusState.CustomTextData or {}
                        for k, v in pairs(savedData.CustomTextData) do
                            _G.LexusState.CustomTextData[k] = v
                        end
                    end
                end
            end
        end

        _G.SaveModSettings()
    end)
end


local function AutoSaveLoop()
    pcall(function() if _G.SaveModSettings then _G.SaveModSettings() end end)
    pcall(function()
        local okTicker, ticker = pcall(require, "common.time_ticker")
        if okTicker and ticker and ticker.AddTimerOnce then
            ticker.AddTimerOnce(3.0, AutoSaveLoop)
        end
    end)
end


if not _G.ModConfigLoaded then
    _G.LoadModSettings()
    AutoSaveLoop()
    _G.ModConfigLoaded = true
end


_G.ReadLiveConfig = function()
    if _G.SaveModSettings then _G.SaveModSettings() end
end


_G.InitModMenuTab = function() return false end

local function ShowLexusVIPMenu()
    -- Hard license gate: menu code must not execute before verification.
    if _G._LICENSE_OK ~= true then return end
    if _G.LexusMenuAlreadyShown then return end
    pcall(function()
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if not pc or not pc.BroadcastUIMessage then return end
        _G.LexusMenuAlreadyShown = true
        if _G._LICENSE_OK ~= true then return end
        pc:BroadcastUIMessage("UIMsg_Tips", 0, "XTHRLEN: افتح زر MENU ثم اختر ESP / Aim / System / Skins", "")
        pc:BroadcastUIMessage("UIMsg_Tips", 0, "XTHRLEN: استخدم + و - لتعديل السلايدرات", "")
    end)
end


local function InitializeGraphicsUnlock()
    if _G._LICENSE_OK ~= true then return end
    if _G.LexusState.GraphicsUnlocked or _G._LICENSE_OK ~= true then return end

    pcall(function()
        local SettingCfg = require("client.logic.setting.setting_config")
        local GraphicSettingDB = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")
        if SettingCfg then
            if SettingCfg.TpViewValue then SettingCfg.TpViewValue.max = 160 end
            if SettingCfg.FpViewValue then SettingCfg.FpViewValue.max = 160 end
        end
        if GraphicSettingDB then
            if GraphicSettingDB.TpViewValue then GraphicSettingDB.TpViewValue.max = 160 end
        end
    end)

    pcall(function()
        local logic_setting_graphics = require("client.slua.logic.setting.logic_setting_graphics")
        local GSC_FPS = require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPS")
        local GSC_FPSFT = require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPSFT")
        local GraphicSettingDB = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")

        local KismetMathLibrary = import("KismetMathLibrary") or _G.KismetMathLibrary
        local FLinearColor = import("LinearColor") or _G.FLinearColor

        if logic_setting_graphics then
            local old_SetFPS = logic_setting_graphics.SetFPS
            function logic_setting_graphics.SetFPS(gameInstance, FPSLevel)
                if old_SetFPS then old_SetFPS(gameInstance, FPSLevel) end
                if FPSLevel == 8 then
                    gameInstance:ExecuteCMD("t.MaxFPS", "165")
                    gameInstance:ExecuteCMD("r.FrameRateLimit", "165")
                end
            end
        end

        if GSC_FPS and GSC_FPS.__inner_impl then
            local fps_impl = GSC_FPS.__inner_impl
            function fps_impl:GetMaxFPSLevel() return 8, 8 end
            function fps_impl:InitRealSupportFPS()
                local RealSupportFPS = {}
                for i = 1, 8 do RealSupportFPS[i] = {true, true} end
                if GraphicSettingDB then GraphicSettingDB:UpdateUIData(GraphicSettingDB.RealSupportFPS, RealSupportFPS, false) end
                return RealSupportFPS
            end
            function fps_impl:UpdateSelectedFPSState(selectedLevel)
                if not slua.isValid(self.UIRoot) then return end
                for level = 2, 8 do
                    local name = "NodeFps" .. (({[2]=20,[3]=25,[4]=30,[5]=40,[6]=60,[7]=90,[8]=120})[level] or 120)
                    local widget = self.UIRoot[name]
                    if slua.isValid(widget) then
                        widget:SetIsEnabled(true)
                        pcall(function() widget:SetRenderOpacity(1.0) end)
                        local switcher = self.UIRoot["WidgetSwitcher_" .. level]
                        if slua.isValid(switcher) then
                            switcher:SetActiveWidgetIndex(level == selectedLevel and 0 or 1)
                        end
                    end
                end
            end
        end

        if GSC_FPSFT and GSC_FPSFT.__inner_impl then
            local ft_impl = GSC_FPSFT.__inner_impl
            local NMinFPS, NStep = 90, 5
            local function clamp(value, min, max)
                if value < min then return min end
                if max < value then return max end
                return value
            end
            local function lerp(a, b, t) return a + (b - a) * t end
            local function _getColorByPercent(start, finish, percent)
                if not FLinearColor then return nil end
                return FLinearColor(lerp(start.R, finish.R, percent), lerp(start.G, finish.G, percent), lerp(start.B, finish.B, percent), lerp(start.A, finish.A, percent))
            end

            ft_impl.ShowOrHide = function(self)
                self:SelfHitTestInvisible()
                if self.InitFPSFTSwitch then self:InitFPSFTSwitch() end
            end

            ft_impl.InitFPSFTSwitch = function(self)
                local FPSFineTuneSwitch = GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneSwitch)
                if self.UIRoot.Setting_Switch then self.UIRoot.Setting_Switch:SetSwitcherEnable2(FPSFineTuneSwitch, true) end
                if self.UIRoot.CanvasPanel_8 then self:SetWidgetVisible(self.UIRoot.CanvasPanel_8, FPSFineTuneSwitch) end
                if self.UIRoot.WidgetSwitcher_0 then self.UIRoot.WidgetSwitcher_0:SetActiveWidgetIndex(2) end
                if self.InitFPSFTValue165 then self:InitFPSFTValue165() end
            end

            ft_impl.InitFPSFTValue165 = function(self)
                local itemRoot = self.UIRoot
                local FPSFineTuneSwitch = GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneSwitch)
                local FPSFineTuneNum = 165
                if FPSFineTuneSwitch then
                    FPSFineTuneNum = GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneNum) or 165
                    itemRoot.Slider_screen3:SetLocked(false)
                    if FLinearColor then
                        itemRoot.ProgressBar_screen3:SetFillColorAndOpacity(FLinearColor(1.0, 1.0, 1.0, 1.0))
                        itemRoot.Slider_screen3:SetSliderHandleColor(FLinearColor(1.0, 1.0, 1.0, 1.0))
                    end
                else
                    itemRoot.Slider_screen3:SetLocked(true)
                    if FLinearColor then
                        itemRoot.ProgressBar_screen3:SetFillColorAndOpacity(FLinearColor(1.0, 0.625, 0.6, 1))
                        itemRoot.Slider_screen3:SetSliderHandleColor(FLinearColor(1.0, 0.625, 0.6, 1.0))
                    end
                end
                local FPSFineTunePer = (FPSFineTuneNum - NMinFPS) / (165 - NMinFPS)

                itemRoot.Veihclescreen3:SetText(tostring(FPSFineTuneNum))
                itemRoot.Slider_screen3:SetValue(FPSFineTunePer)
                itemRoot.ProgressBar_screen3:SetPercent(FPSFineTunePer)

                if FLinearColor then
                    local startColor = FLinearColor(1.0, 1.0, 1.0, 1.0)
                    local midColor = FLinearColor(1.0, 0.54, 0.11, 1.0)
                    local endColor = FLinearColor(1.0, 0.23, 0.15, 1.0)
                    local sliderColor = FPSFineTunePer < 0.4 and startColor or _getColorByPercent(midColor, endColor, (FPSFineTunePer - 0.4) / 0.6)
                    itemRoot.Slider_screen3:SetSliderHandleColor(sliderColor)
                end
            end

            ft_impl.OnFPSFTValueChange3 = function(self, FPSFineTuneNum)
                GraphicSettingDB:UpdateUIData(GraphicSettingDB.FPSFineTuneNum, FPSFineTuneNum)
                if self.InitFPSFTValue165 then self:InitFPSFTValue165() end
                if self:GetParentUI() then self:GetParentUI():SetDirty(true) end
                local gameInstance = GraphicSettingDB.GetGameInstance and GraphicSettingDB.GetGameInstance()
                if gameInstance then
                    gameInstance:ExecuteCMD("t.MaxFPS", tostring(FPSFineTuneNum))
                    gameInstance:ExecuteCMD("r.FrameRateLimit", tostring(FPSFineTuneNum))
                end
            end

            ft_impl.OnFPSFTSliderValueChange3 = function(self, value)
                if GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneSwitch) and KismetMathLibrary then
                    local FPSFineTuneNum = KismetMathLibrary.FCeil(value * (165 - NMinFPS) / NStep) * NStep + NMinFPS
                    self:OnFPSFTValueChange3(clamp(FPSFineTuneNum, NMinFPS, 165))
                end
            end

            ft_impl.OnFPSFTAdd = ft_impl.OnFPSFTAdd3
            ft_impl.OnFPSFTMinus = ft_impl.OnFPSFTMinus3
            ft_impl.OnFPSFTAdd2 = ft_impl.OnFPSFTAdd3
            ft_impl.OnFPSFTMinus2 = ft_impl.OnFPSFTMinus3
            ft_impl.OnFPSFTSliderValueChange = ft_impl.OnFPSFTSliderValueChange3
            ft_impl.OnFPSFTSliderValueChange2 = ft_impl.OnFPSFTSliderValueChange3
        end
    end)
    _G.LexusState.GraphicsUnlocked = true
    Notify("Graphics & FPS 165Hz Unlocked (Upgraded Version)")
end


local function InitializeNativeESP()
    if _G.LexusState.NativeESPReady then return end
    pcall(function()
        local GamePlayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools")
        local currentMarkCfg = GamePlayTools.GetCurrentConfig("ScreenMarkConfig")
        local function ApplyCfg(cfg)
            if not cfg then return end
            if cfg[1006] then
                cfg[1006].bBindBlocked = true;
                cfg[1006].bBindOutScreen = true;
                cfg[1006].MaxWidgetNum = 99
                cfg[1006].MaxShowDistance = 6000000;
                cfg[1006].bScaleByDistance = false
                cfg[1006].BindSocketName = "root";
                cfg[1006].bUseLuaWorldSocketName = true
                cfg[1006].WorldPositionOffset = FVector(0, 0, -30)
            end

            cfg[8888] = {
                UIPathName = "/Game/Mod/EvoBase/BluePrints/UIBP/QuickSign/QuickSign_TipHitEnemy_UIBP_New.QuickSign_TipHitEnemy_UIBP_New_C",
                MaxWidgetNum = 99,
                MaxShowDistance = 6000000,
                bBindOutScreen = true,
                bBindBlocked = true,
                bIsBindingActor = true,
                BindSocketName = "head",
                bUseLuaWorldSocketName = true,
                WorldPositionOffset = FVector(0, 0, 30),
                bNeedPreLoad = true,
                Priority = 2
            }
            cfg[9999] = {
                UIPathName = "/Game/Mod/EvoBase/BluePrints/UIBP/QuickSign/QuickSign_TipHitEnemy_UIBP_New.QuickSign_TipHitEnemy_UIBP_New_C",
                MaxWidgetNum = 99,
                MaxShowDistance = 6000000,
                bBindOutScreen = true,
                bBindBlocked = true,
                bIsBindingActor = true,
                BindSocketName = "head",
                bUseLuaWorldSocketName = true,
                WorldPositionOffset = FVector(0, 0, 50),
                bNeedPreLoad = true,
                Priority = 2
            }
        end
        ApplyCfg(currentMarkCfg)
        for k, cfg in pairs(package.loaded) do
            if type(k) == "string" and string.find(k, "ScreenMarkConfig") and type(cfg) == "table" then
                ApplyCfg(cfg)
            end
        end
    end)
    _G.LexusState.NativeESPReady = true
    Notify("Native ESP System Initialized")
end


local function GetAllSkeletalMeshes(enemy, markData)
    local curTime = os.clock()

    if markData and markData.CachedMeshes and markData.CachedMeshTime and (curTime - markData.CachedMeshTime < 0.5) then
        local validMeshes = {}
        for _, cachedMesh in ipairs(markData.CachedMeshes) do

            local isPendingKill = false
            pcall(function() if type(cachedMesh.IsPendingKill) == "function" then isPendingKill = cachedMesh:IsPendingKill() end end)

            if Valid(cachedMesh) and not isPendingKill then
                table.insert(validMeshes, cachedMesh)
            end
        end
        markData.CachedMeshes = validMeshes
        return validMeshes
    end

    local meshes = {}
    if Valid(enemy.Mesh) then table.insert(meshes, enemy.Mesh) end
    pcall(function()
        local SkeletalMeshClass = import("SkeletalMeshComponent")
        if SkeletalMeshClass and type(enemy.GetComponentsByClass) == "function" then
            local childs = enemy:GetComponentsByClass(SkeletalMeshClass)
            if childs then
                local count = type(childs.Num) == "function" and childs:Num() or #childs
                for i = 1, count do
                    local comp = type(childs.Get) == "function" and childs:Get(i-1) or childs[i]
                    if Valid(comp) and comp ~= enemy.Mesh then
                        table.insert(meshes, comp)
                    end
                end
            end
        end
    end)
    if markData then
        markData.CachedMeshes = meshes
        markData.CachedMeshTime = curTime
    end
    return meshes
end


local function UndoWallXuyenTuong(enemy, markData)
    pcall(function()
        if markData.WallhackApplied then
            local meshes = GetAllSkeletalMeshes(enemy, markData)
            for _, mesh in ipairs(meshes) do
                if Valid(mesh) then
                    pcall(function() if type(mesh.SetRenderCustomDepth) == "function" then mesh:SetRenderCustomDepth(false) end end)
                    for i = 0, 10 do
                        local matInterface = mesh:GetMaterial(i)
                        if Valid(matInterface) then
                            local baseMat = matInterface:GetBaseMaterial()
                            if Valid(baseMat) then baseMat.bDisableDepthTest = false end
                        end
                    end
                end
            end
            markData.WallhackApplied = false
        end
    end)
end

local function ApplyWallXuyenTuong(enemy, markData)
    pcall(function()
        local meshes = GetAllSkeletalMeshes(enemy, markData)
        for _, mesh in ipairs(meshes) do
            if Valid(mesh) then
                pcall(function()
                    if type(mesh.SetRenderCustomDepth) == "function" then
                        mesh:SetRenderCustomDepth(true)
                    end
                    if type(mesh.SetCustomDepthStencilValue) == "function" then
                        mesh:SetCustomDepthStencilValue(252)
                    end
                end)
                for i = 0, 10 do
                    local matInterface = mesh:GetMaterial(i)
                    if not Valid(matInterface) then break end
                    local baseMat = matInterface:GetBaseMaterial()
                    if Valid(baseMat) then
                        baseMat.bDisableDepthTest = true
                        baseMat.BlendMode = 2
                    end
                end
            end
        end
    end)
end

local function ApplyColorBodyV2(enemy, pc, markData)
    pcall(function()
        local meshes = GetAllSkeletalMeshes(enemy, markData)
        if #meshes == 0 then return end


        local curTime = os.clock()
        if markData.LastVisCheckTime == nil or (curTime - markData.LastVisCheckTime) > 0.3 then
            markData.LastVisCheckTime = curTime
            local isHidden = true
            pcall(function()
                if Valid(pc) and type(pc.LineOfSightTo) == "function" then
                    if pc:LineOfSightTo(enemy) then isHidden = false else isHidden = true end
                end
            end)
            markData.CachedHiddenState = isHidden
        end

        local hidden = markData.CachedHiddenState
        if hidden == nil then hidden = true end

        local cData = _G.LexusState.CustomTextData or {}
        local hiddenColor = {R = cData.HiddenR or 150, G = cData.HiddenG or 0, B = cData.HiddenB or 0, A = cData.HiddenA or 25}
        local visibleColor = {R = cData.VisibleR or 0, G = cData.VisibleG or 150, B = cData.VisibleB or 0, A = cData.VisibleA or 25}

        local finalColor = hidden and hiddenColor or visibleColor
        local colorHash = string.format("%d_%d_%d_%d", finalColor.R, finalColor.G, finalColor.B, finalColor.A)
        local currentMeshCount = #meshes
        local isMeshChanged = (markData.LastMeshCount ~= currentMeshCount)


        if not isMeshChanged and markData.LastHiddenState == hidden and markData.LastColorHash == colorHash then return end


        if isMeshChanged and markData.MIDs then
            markData.MIDs = {}
        end

        markData.LastHiddenState = hidden
        markData.LastMeshCount = currentMeshCount
        markData.LastColorHash = colorHash
        markData.ColorApplied = true

        for meshIndex, mesh in ipairs(meshes) do
            if Valid(mesh) then
                pcall(function()
                    mesh.LDMaxDrawDistance = -99999
                    mesh.MaxDrawDistanceOffset = -99999
                    mesh.CachedMaxDrawDistance = -99999
                    mesh.UseScopeDistanceCulling = true
                    mesh.PrimitiveShadingStrategy = 1
                    mesh.ShadingRate = 6
                end)
                for i = 0, 10 do
                    local matInterface = mesh:GetMaterial(i)
                    if not Valid(matInterface) then break end
                    local baseMat = matInterface:GetBaseMaterial()
                    if Valid(baseMat) then
                        local matName = tostring(baseMat)
                        if string.find(matName, "Master_Mask", 1, true) then
                            if not markData.MIDs then markData.MIDs = {} end


                            local meshKey = "Mesh_" .. tostring(meshIndex)

                            if not markData.MIDs[meshKey] then markData.MIDs[meshKey] = {} end
                            local mid = markData.MIDs[meshKey][i]
                            if not Valid(mid) then
                                mid = mesh:CreateAndSetMaterialInstanceDynamic(i)
                                markData.MIDs[meshKey][i] = mid
                            end
                            if Valid(mid) then
                                mid:SetVectorParameterValue("颜色", finalColor)
                                mid:SetVectorParameterValue("Extra Light Color", finalColor)
                                mid:SetVectorParameterValue("Para_Color", finalColor)
                                mid:SetVectorParameterValue("Para_ColorTint", finalColor)
                                mid:SetVectorParameterValue("Para_Color_1", finalColor)
                                mid:SetVectorParameterValue("Tint", finalColor)
                                mid:SetVectorParameterValue("Color", finalColor)
                                mid:SetVectorParameterValue("BaseColor", finalColor)
                                mid:SetVectorParameterValue("BodyColor", finalColor)
                                mid:SetVectorParameterValue("MainColor", finalColor)
                                mid:SetVectorParameterValue("DiffuseColor", finalColor)
                                mid:SetVectorParameterValue("EmissiveColor", finalColor)
                                mid:SetVectorParameterValue("ParaScaleOffset", SCALE_COLOR_V2)
                            end
                        end
                    end
                end
            end
        end
    end)
end

local function UndoColorBodyV2(enemy, markData)
    pcall(function()
        if markData.ColorApplied then
            local meshes = GetAllSkeletalMeshes(enemy, markData)
            for meshIndex, mesh in ipairs(meshes) do
                if Valid(mesh) then
                    pcall(function()
                        mesh.PrimitiveShadingStrategy = 0
                        mesh.ShadingRate = 1
                    end)
                    local meshKey = "Mesh_" .. tostring(meshIndex)
                    if markData.MIDs and markData.MIDs[meshKey] then
                        for i, mid in pairs(markData.MIDs[meshKey]) do
                            if Valid(mid) then
                                local defC = {R=1, G=1, B=1, A=1}
                                mid:SetVectorParameterValue("颜色", defC)
                                mid:SetVectorParameterValue("Extra Light Color", defC)
                                mid:SetVectorParameterValue("Para_Color", defC)
                                mid:SetVectorParameterValue("Para_ColorTint", defC)
                                mid:SetVectorParameterValue("Para_Color_1", defC)
                                mid:SetVectorParameterValue("Tint", defC)
                                mid:SetVectorParameterValue("Color", defC)
                                mid:SetVectorParameterValue("BaseColor", defC)
                                mid:SetVectorParameterValue("BodyColor", defC)
                                mid:SetVectorParameterValue("MainColor", defC)
                                mid:SetVectorParameterValue("DiffuseColor", defC)
                                mid:SetVectorParameterValue("EmissiveColor", defC)
                            end
                        end
                    end
                end
            end
            markData.ColorApplied = false
            markData.LastColorHash = ""
            markData.LastHiddenState = nil
        end
    end)
end


local function ApplyColorBodyV3(enemy, markData)
    pcall(function()
        local meshes = GetAllSkeletalMeshes(enemy, markData)
        if #meshes == 0 then return end

        local cData = _G.LexusState.CustomTextData or {}
        local hidChoice = cData.ColorV3Hidden or 1
        local visChoice = cData.ColorV3Visible or 2
        local v3Thick = cData.ColorV3Thickness or 4


        local currentHash = string.format("%d_%d_%d", hidChoice, visChoice, v3Thick)
        local colorChanged = (markData.LastColorV3Hash ~= currentHash)
        markData.LastColorV3Hash = currentHash

        local function GetColorRGB(choice)
            if choice == 1 then return 255, 0, 0 end
            if choice == 2 then return 70, 120, 255 end
            if choice == 3 then return 0, 0, 255 end
            if choice == 4 then return 255, 255, 0 end
            if choice == 5 then return 255, 0, 255 end
            if choice == 6 then return 255, 255, 255 end
            return 255, 0, 0
        end

        local hR, hG, hB = GetColorRGB(hidChoice)
        local vR, vG, vB = GetColorRGB(visChoice)


        local invisColor = { R=hR, G=hG, B=hB, A=255, r=hR, g=hG, b=hB, a=255 }


        local glowIntensity = 80.0
        local LinearColorClass = import("LinearColor") or _G.FLinearColor
        local visColor = LinearColorClass and LinearColorClass((vR/255)*glowIntensity, (vG/255)*glowIntensity, (vB/255)*glowIntensity, 1.0) or { R=vR*glowIntensity, G=vG*glowIntensity, B=vB*glowIntensity, A=255 }
        local scale = { R=3.0, G=3.0, B=0.0, A=0.0, r=3.0, g=3.0, b=0.0, a=0.0 }

        markData.MIDs_V3 = markData.MIDs_V3 or {}

        for meshIndex, comp in ipairs(meshes) do
            if Valid(comp) then
                local compKey = "MeshV3_" .. tostring(meshIndex)
                markData.MIDs_V3[compKey] = markData.MIDs_V3[compKey] or {}

                pcall(function()
                    if comp.PrimitiveShadingStrategy ~= 1 then
                        comp.UseScopeDistanceCulling = false
                        comp.PrimitiveShadingStrategy = 1
                        comp.ShadingRate = 6
                    end
                end)

                for i = 0, 10 do
                    local matInterface = comp:GetMaterial(i)
                    if not Valid(matInterface) then break end

                    local baseMat = matInterface:GetBaseMaterial()
                    if Valid(baseMat) then
                        if baseMat.bDisableDepthTest ~= true then baseMat.bDisableDepthTest = true end
                        if baseMat.BlendMode ~= 2 then baseMat.BlendMode = 2 end
                    end

                    local currentCached = markData.MIDs_V3[compKey][i]
                    local needUpdateColor = false


                    if not Valid(currentCached) then
                        local newMid = comp:CreateAndSetMaterialInstanceDynamic(i)
                        if Valid(newMid) then
                            markData.MIDs_V3[compKey][i] = newMid
                            currentCached = newMid
                            needUpdateColor = true
                        end
                    elseif colorChanged then
                        needUpdateColor = true
                    end

                    if Valid(currentCached) and needUpdateColor then
                        pcall(function()
                            currentCached:SetVectorParameterValue("颜色", invisColor)
                            currentCached:SetVectorParameterValue("Extra Light Color", invisColor)
                            currentCached:SetVectorParameterValue("Para_Color", invisColor)
                            currentCached:SetVectorParameterValue("Para_ColorTint", invisColor)
                            currentCached:SetVectorParameterValue("Para_Color_1", invisColor)
                            currentCached:SetVectorParameterValue("Tint", invisColor)
                            currentCached:SetVectorParameterValue("Color", invisColor)
                            currentCached:SetVectorParameterValue("BaseColor", invisColor)
                            currentCached:SetVectorParameterValue("BodyColor", invisColor)
                            currentCached:SetVectorParameterValue("MainColor", invisColor)
                            currentCached:SetVectorParameterValue("DiffuseColor", invisColor)
                            currentCached:SetVectorParameterValue("EmissiveColor", invisColor)
                            currentCached:SetVectorParameterValue("CustomColor", invisColor)
                            currentCached:SetVectorParameterValue("OverlayColor", invisColor)
                            currentCached:SetVectorParameterValue("GlowColor", invisColor)
                            currentCached:SetVectorParameterValue("EdgeColor", invisColor)
                            currentCached:SetVectorParameterValue("LightColor", invisColor)
                            currentCached:SetVectorParameterValue("OutlineColor", invisColor)
                            currentCached:SetVectorParameterValue("ParaScaleOffset", scale)
                            currentCached:SetScalarParameterValue("Opacity", 0.7)
                            currentCached:SetScalarParameterValue("Alpha", 0.7)
                            currentCached:SetScalarParameterValue("GlowIntensity", 1.0)
                            currentCached:SetScalarParameterValue("Intensity", 1.0)
                        end)
                    end
                end

                pcall(function()
                    if comp.SetDrawIdeaOutline then
                        comp:SetDrawIdeaOutline(true)
                        if comp.OverrideIdeaOutlineColor then comp:OverrideIdeaOutlineColor(true, visColor) end
                        if comp.OverrideIdeaOutlineThickness then comp:OverrideIdeaOutlineThickness(true, v3Thick) end
                    end
                end)
            end
        end
        markData.ColorV3Applied = true
    end)
end

local function UndoColorBodyV3(enemy, markData)
    pcall(function()
        if markData.ColorV3Applied then
            local meshes = GetAllSkeletalMeshes(enemy, markData)
            for meshIndex, comp in ipairs(meshes) do
                if Valid(comp) then
                    pcall(function()
                        comp.PrimitiveShadingStrategy = 0
                        comp.ShadingRate = 1
                    end)

                    for i = 0, 10 do
                        local s, matInterface = pcall(function() return comp:GetMaterial(i) end)
                        if s and Valid(matInterface) then
                            local s2, baseMat = pcall(function() return matInterface:GetBaseMaterial() end)
                            if s2 and Valid(baseMat) then
                                baseMat.bDisableDepthTest = false
                                baseMat.BlendMode = 1
                            end
                        end
                    end

                    local compKey = "MeshV3_" .. tostring(meshIndex)
                    if markData.MIDs_V3 and markData.MIDs_V3[compKey] then
                        for i, mid in pairs(markData.MIDs_V3[compKey]) do
                            if Valid(mid) then
                                pcall(function()
                                    local defC = {R=1, G=1, B=1, A=1, r=1, g=1, b=1, a=1}
                                    mid:SetVectorParameterValue("颜色", defC)
                                    mid:SetVectorParameterValue("Extra Light Color", defC)
                                    mid:SetVectorParameterValue("Para_Color", defC)
                                    mid:SetVectorParameterValue("Tint", defC)
                                    mid:SetVectorParameterValue("BaseColor", defC)
                                    mid:SetVectorParameterValue("Color", defC)
                                end)
                            end
                        end
                    end

                    pcall(function()
                        if comp.SetDrawIdeaOutline then
                            comp:SetDrawIdeaOutline(false)
                        end
                    end)
                end
            end
            markData.ColorV3Applied = false
            markData.LastMeshCountV3 = 0
            if markData.MIDs_V3 then markData.MIDs_V3 = nil end
        end
    end)
end


local function ApplyColorBodyNew(enemy, markData)
    pcall(function()

        if not _G.ConsoleNewWallReady then
            local KismetSystemLibrary = import("KismetSystemLibrary")
            local world = slua.getWorld()
            if KismetSystemLibrary and world then
                KismetSystemLibrary.ExecuteConsoleCommand(world, "r.EnableDrawDyeingColor 1")
                KismetSystemLibrary.ExecuteConsoleCommand(world, "r.CustomDepth 3")
                KismetSystemLibrary.ExecuteConsoleCommand(world, "r.IdeaOutline.Enable 1")
                KismetSystemLibrary.ExecuteConsoleCommand(world, "r.Highlight.Enable 1")
                _G.ConsoleNewWallReady = true
            end
        end


        local meshes = GetAllSkeletalMeshes(enemy, markData)


        local weapon = nil
        pcall(function() weapon = enemy:GetCurrentWeapon() end)
        if slua.isValid(weapon) and slua.isValid(weapon.Mesh) then
            table.insert(meshes, weapon.Mesh)
        end

        local isBot = markData.AK_IS_BOT or false
        local currentMeshCount = #meshes


        local stateHash = (isBot and "BOT" or "PLAYER") .. "_" .. tostring(currentMeshCount)

        if markData.LastColorNewHash == stateHash and markData.ColorNewApplied then
            return
        end


        markData.LastColorNewHash = stateHash
        markData.ColorNewApplied = true


        local LinearColorClass = import("LinearColor") or _G.FLinearColor
        local c_vis = LinearColorClass and LinearColorClass(0, 100, 0, 1) or {R=0, G=100, B=0, A=1}
        local c_occ = LinearColorClass and LinearColorClass(100, 0, 0, 1) or {R=100, G=0, B=0, A=1}
        local c_bVis = LinearColorClass and LinearColorClass(49, 48, 0, 100) or {R=49, G=48, B=0, A=100}
        local c_bOcc = LinearColorClass and LinearColorClass(9, 1.5, 45, 100) or {R=9, G=1.5, B=45, A=100}

        local visColor = isBot and c_bVis or c_vis
        local occColor = isBot and c_bOcc or c_occ

        for _, mesh in ipairs(meshes) do
            if Valid(mesh) then
                pcall(function()
                    if type(mesh.SetDrawDyeing) == "function" then
                        mesh:SetDrawDyeing(true)
                        mesh:SetDrawDyeingMode(1)
                        mesh:SetVisibleDyeingColor(visColor)
                        mesh:SetOccludedDyeingColor(occColor)
                        mesh:SetDyeingColorFadeDistance(99999.0)
                        mesh:SetDyeingColorMinMaxDistance(0.0, 99999.0)
                        mesh:SetDrawHighlight(true)
                        mesh:OverrideHighlightColor(visColor)
                        mesh:SetHighlightCanBeOccluded(false)
                        mesh:SetDrawIdeaOutline(true)
                        mesh:SetIdeaOutlineNew(true)
                        mesh:SetIdeaOutlineOcclusionHighlight(true)
                        mesh:OverrideIdeaOutlineColor(visColor)
                        mesh:SetIdeaOutlineOcclusionColor(occColor)
                        mesh:OverrideIdeaOutlineThickness(20.0)
                        mesh:SetIdeaOverrideOutlineAndOcclusion(true)
                        mesh:SetRenderCustomDepth(true)
                        mesh:SetCustomDepthStencilValue(255)
                    end
                end)
            end
        end
    end)
end

local function UndoColorBodyNew(enemy, markData)
    pcall(function()
        if markData.ColorNewApplied then
            local meshes = GetAllSkeletalMeshes(enemy, markData)
            local weapon = nil
            pcall(function() weapon = enemy:GetCurrentWeapon() end)
            if slua.isValid(weapon) and slua.isValid(weapon.Mesh) then
                table.insert(meshes, weapon.Mesh)
            end

            for _, mesh in ipairs(meshes) do
                if Valid(mesh) then
                    pcall(function()
                        if type(mesh.SetDrawDyeing) == "function" then
                            mesh:SetDrawDyeing(false)
                            mesh:SetDrawHighlight(false)
                            mesh:SetDrawIdeaOutline(false)
                            mesh:SetRenderCustomDepth(false)
                        end
                    end)
                end
            end
            markData.ColorNewApplied = false
            markData.LastColorNewHash = ""
        end
    end)
end


_G.GetEnemyTargetsFromActors = function(radius)
    local result = {}
    local player = GameplayData.GetPlayerCharacter()

    if not slua.isValid(player) then
        return result
    end

    local allCharacters = {}
    if GameplayData.GetAllPlayerCharacters then
        allCharacters = GameplayData.GetAllPlayerCharacters()
    elseif GameplayData.GameCharacters then
        for _, char in pairs(GameplayData.GameCharacters) do table.insert(allCharacters, char) end
    end

    local myTeam = player:GetTeamID()

    for _, actor in pairs(allCharacters) do
        if slua.isValid(actor) and actor ~= player and actor.GetTeamID and actor:IsAlive() then
            if actor:GetTeamID() ~= myTeam then
                local dist = player:GetDistanceTo(actor)
                if dist <= radius then
                    table.insert(result, actor)
                end
            end
        end
    end
    return result
end

_G.AimTouch = function()
    pcall(function()
        if not _G.LexusConfig.AimTouchEnable then return end

        local player = GameplayData.GetPlayerCharacter()
        if not slua.isValid(player) then return end

        local pc = player:GetPlayerControllerSafety()
        if not slua.isValid(pc) then return end

        local isFiring = player.bIsWeaponFiring
        local isADS = player.bIsGunADS


        local weapon = player.WeaponManagerComponent and player.WeaponManagerComponent.CurrentWeaponReplicated
        if not weapon and type(player.GetCurrentShootWeapon) == "function" then
            weapon = player:GetCurrentShootWeapon()
        end

        local isShotgun = false
        local isSniper = false
        local isMortar = false
        local currentAmmo = 1

        if slua.isValid(weapon) then
            local wID = type(weapon.GetWeaponID) == "function" and weapon:GetWeaponID() or 0
            local wName = type(weapon.GetWeaponName) == "function" and weapon:GetWeaponName() or ""

            if (wID >= 1030000 and wID < 1040000) or wName:find("S686") or wName:find("S1897") or wName:find("S12") or wName:find("DBS") or wName:find("M1014") then
                isShotgun = true
            end

            if wName:find("Kar98") or wName:find("M24") or wName:find("AWM") or wName:find("Mosin") or wName:find("Win94") or wName:find("AMR") or wName:find("SKS") or wName:find("SLR") or wName:find("Mini") or wName:find("Mk14") or wName:find("QBU") or wName:find("Mk12") or wName:find("VSS") then
                isSniper = true
            end

            if wName:lower():find("mortar") or wName:lower():find("cối") then
                isMortar = true
            end

            if type(weapon.GetCurrentAmmo) == "function" then
                currentAmmo = weapon:GetCurrentAmmo()
            elseif weapon.ShootWeaponComponent and type(weapon.ShootWeaponComponent.GetCurrentAmmo) == "function" then
                currentAmmo = weapon.ShootWeaponComponent:GetCurrentAmmo()
            elseif weapon.CurrentAmmo ~= nil then
                currentAmmo = weapon.CurrentAmmo
            end
        end


        if _G.LexusState.IsAutoFiring then
            pcall(function()
                player.bIsWeaponFiring = false
                if type(player.SetIsWeaponFiring) == "function" then player:SetIsWeaponFiring(false) end
                if slua.isValid(pc) and type(pc.SetIsWeaponFiring) == "function" then pc:SetIsWeaponFiring(false) end
                local wepMgr = player.WeaponManagerComponent
                if slua.isValid(wepMgr) then wepMgr.bIsWeaponFiring = false end
            end)
            _G.LexusState.IsAutoFiring = false
        end


        if isShotgun and currentAmmo <= 0 then
            return
        end

        local cond = 2
        local prioMode = 1
        local boneIdx = 1
        local speedVal = 50
        local fovVal = 30
        local maxDistMeters = 50
        local useVisCheck = false
        local igKnock = false
        local igBot = false


        local predVal = 0
        local recoilCompVal = 0


        if isMortar and _G.LexusConfig.AimTouchMortar then
            local isPlaced = false
            pcall(function()
                if weapon and weapon.MortarState == 2 then isPlaced = true end
            end)
            if not isPlaced then return end

            cond = 2
            prioMode = 1
            boneIdx = 4
            speedVal = 100
            fovVal = _G.LexusState.CustomTextData.AimTouchMortarFOV or 360
            maxDistMeters = 2000
            useVisCheck = false
            igKnock = false
            igBot = false
            predVal = _G.LexusState.CustomTextData.AimTouchMortarPred or 0

        elseif isShotgun and _G.LexusConfig.AimTouchSG then
            cond = _G.LexusState.CustomTextData.AimTouchSGCond or 1
            if _G.LexusConfig.AimTouchSGAutoFire then cond = 2 end
            if cond == 1 and not isFiring then return end
            prioMode = _G.LexusState.CustomTextData.AimTouchSGPrio or 1
            boneIdx = _G.LexusState.CustomTextData.AimTouchSGBone or 2
            speedVal = _G.LexusState.CustomTextData.AimTouchSGSpeed or 80
            fovVal = _G.LexusState.CustomTextData.AimTouchSGFOV or 40
            maxDistMeters = _G.LexusState.CustomTextData.AimTouchSGDist or 30
            useVisCheck = _G.LexusConfig.AimTouchSGVisCheck
            igKnock = _G.LexusConfig.AimTouchSGIgKnock
            igBot = _G.LexusConfig.AimTouchSGIgBot

        elseif isADS then
            if isSniper and _G.LexusConfig.AimTouchScopeSniper then
                cond = _G.LexusState.CustomTextData.AimTouchSniperCond or 1
                if cond == 1 and not isFiring then return end
                prioMode = _G.LexusState.CustomTextData.AimTouchSniperPrio or 1
                boneIdx = _G.LexusState.CustomTextData.AimTouchSniperBone or 1
                speedVal = _G.LexusState.CustomTextData.AimTouchSniperSpeed or 30
                fovVal = _G.LexusState.CustomTextData.AimTouchSniperFOV or 20
                maxDistMeters = _G.LexusState.CustomTextData.AimTouchSniperDist or 400
                useVisCheck = _G.LexusConfig.AimTouchSniperVisCheck
                igKnock = _G.LexusConfig.AimTouchSniperIgKnock
                igBot = _G.LexusConfig.AimTouchSniperIgBot
                predVal = _G.LexusState.CustomTextData.AimTouchSniperPred or 0
            elseif _G.LexusConfig.AimTouchScopeAll then
                cond = _G.LexusState.CustomTextData.AimTouchScopeCond or 1
                if cond == 1 and not isFiring then return end
                prioMode = _G.LexusState.CustomTextData.AimTouchScopePrio or 1
                boneIdx = _G.LexusState.CustomTextData.AimTouchScopeBone or 2
                speedVal = _G.LexusState.CustomTextData.AimTouchScopeSpeed or 40
                fovVal = _G.LexusState.CustomTextData.AimTouchScopeFOV or 20
                maxDistMeters = _G.LexusState.CustomTextData.AimTouchScopeDist or 300
                useVisCheck = _G.LexusConfig.AimTouchScopeVisCheck
                igKnock = _G.LexusConfig.AimTouchScopeIgKnock
                igBot = _G.LexusConfig.AimTouchScopeIgBot
                predVal = _G.LexusState.CustomTextData.AimTouchScopePred or 0
                recoilCompVal = _G.LexusState.CustomTextData.AimTouchScopeRecoil or 0
            else
                return
            end
        else
            if not _G.LexusConfig.AimTouchHipfire then return end
            cond = _G.LexusState.CustomTextData.AimTouchHipCond or 1
            if cond == 1 and not isFiring then return end
            prioMode = _G.LexusState.CustomTextData.AimTouchHipPrio or 1
            boneIdx = _G.LexusState.CustomTextData.AimTouchHipBone or 1
            speedVal = _G.LexusState.CustomTextData.AimTouchHipSpeed or 50
            fovVal = _G.LexusState.CustomTextData.AimTouchHipFOV or 30
            maxDistMeters = _G.LexusState.CustomTextData.AimTouchHipDist or 250
            useVisCheck = _G.LexusConfig.AimTouchHipVisCheck
            igKnock = _G.LexusConfig.AimTouchHipIgKnock
            igBot = _G.LexusConfig.AimTouchHipIgBot
        end

        local currentMaxDist = maxDistMeters * 100

        local enemies = _G.GetEnemyTargetsFromActors(currentMaxDist)
        if not enemies or #enemies == 0 then return end

        local FVector2D = import("Vector2D")
        local UGameplayStatics = import("GameplayStatics")
        local KismetMathLibrary = import("KismetMathLibrary")

        local camManager = UGameplayStatics.GetPlayerCameraManager(pc, 0)
        if not slua.isValid(camManager) then return end

        local camLoc = camManager:GetCameraLocation()
        if not camLoc then return end

        local ui_util = require("client.common.ui_util")
        if not ui_util then return end

        local viewportSize = ui_util.GetViewportSize()
        if not viewportSize then return end

        local centerX = viewportSize.X * 0.5
        local centerY = viewportSize.Y * 0.5

        local FOV_RADIUS = (fovVal / 100.0) * (viewportSize.X / 2.0)

        local bestTarget = nil
        local bestScore = 99999999

        local selBoneName = "head"
        if boneIdx == 1 then selBoneName = "head"
        elseif boneIdx == 2 then selBoneName = "spine_03"
        elseif boneIdx == 3 then selBoneName = "spine_01"
        elseif boneIdx == 4 then selBoneName = "pelvis" end

        for i, target in ipairs(enemies) do
            if not slua.isValid(target) then goto continue end

            pcall(function()
                if slua.isValid(target.Mesh) then
                    target.Mesh.MeshComponentUpdateFlag = 0
                end
            end)

            if igKnock and target.HealthStatus == 1 then goto continue end

            if igBot then
                local tIsBot = false
                if target.bIsAI == true or target.IsAI == true then tIsBot = true end
                local pState = target.PlayerState
                if slua.isValid(pState) and (pState.bIsABot or pState.bIsBot) then tIsBot = true end
                if tIsBot then goto continue end
            end


            if useVisCheck then
                local curTime = os.clock()
                local tId = type(target.GetUniqueID) == "function" and target:GetUniqueID() or tostring(target)
                _G.AimTouchVisCache = _G.AimTouchVisCache or {}
                if not _G.AimTouchVisCache[tId] or (curTime - _G.AimTouchVisCache[tId].time) > 0.2 then
                    local isHidden = true
                    pcall(function() if pc:LineOfSightTo(target) then isHidden = false end end)
                    _G.AimTouchVisCache[tId] = { hidden = isHidden, time = curTime }
                end
                if _G.AimTouchVisCache[tId].hidden then goto continue end
            end

            local tPos = target:GetBonePos(selBoneName, {X=0, Y=0, Z=0})
            if not tPos or (tPos.X == 0 and tPos.Y == 0 and tPos.Z == 0) then
                if type(target.GetSocketLocation) == "function" then
                    tPos = target:GetSocketLocation(selBoneName)
                end
            end
            if not tPos or (tPos.X == 0 and tPos.Y == 0 and tPos.Z == 0) then
                if type(target.K2_GetActorLocation) == "function" then
                    tPos = target:K2_GetActorLocation()
                    if tPos then
                        if boneIdx == 1 then tPos.Z = tPos.Z + 70
                        elseif boneIdx == 2 then tPos.Z = tPos.Z + 40
                        elseif boneIdx == 3 then tPos.Z = tPos.Z + 20 end
                    end
                end
            end
            if not tPos or (tPos.X == 0 and tPos.Y == 0 and tPos.Z == 0) then goto continue end

            local screen = FVector2D()
            local success = pc:ProjectWorldLocationToScreen(tPos, screen, false)
            if not success or screen.X <= 0 or screen.Y <= 0 then goto continue end

            local dx = screen.X - centerX
            local dy = screen.Y - centerY
            local distScreen = math.sqrt(dx*dx + dy*dy)

            if distScreen > FOV_RADIUS then goto continue end

            local currentScore = distScreen
            if prioMode == 2 then currentScore = player:GetDistanceTo(target)
            elseif prioMode == 3 then currentScore = target.Health or 100
            elseif prioMode == 4 then
                local hp = target.Health or 100
                local maxhp = target.HealthMax or 100
                if maxhp <= 0 then maxhp = 100 end
                currentScore = hp / maxhp
            end

            if currentScore < bestScore then
                bestScore = currentScore
                bestTarget = target
            end

            ::continue::
        end

        if not slua.isValid(bestTarget) then return end

        local finalBonePos = bestTarget:GetBonePos(selBoneName, {X=0, Y=0, Z=0})
        if not finalBonePos or (finalBonePos.X == 0 and finalBonePos.Y == 0 and finalBonePos.Z == 0) then
            if type(bestTarget.GetSocketLocation) == "function" then
                finalBonePos = bestTarget:GetSocketLocation(selBoneName)
            end
        end
        if not finalBonePos or (finalBonePos.X == 0 and finalBonePos.Y == 0 and finalBonePos.Z == 0) then
            if type(bestTarget.K2_GetActorLocation) == "function" then
                finalBonePos = bestTarget:K2_GetActorLocation()
                if finalBonePos then
                    if boneIdx == 1 then finalBonePos.Z = finalBonePos.Z + 70
                    elseif boneIdx == 2 then finalBonePos.Z = finalBonePos.Z + 40
                    elseif boneIdx == 3 then finalBonePos.Z = finalBonePos.Z + 20 end
                end
            end
        end
        if not finalBonePos or (finalBonePos.X == 0 and finalBonePos.Y == 0 and finalBonePos.Z == 0) then return end

        local tVelocity = nil
        pcall(function()
            if type(bestTarget.GetVelocity) == "function" then
                tVelocity = bestTarget:GetVelocity()
            end
        end)


        if isMortar and _G.LexusConfig.AimTouchMortar and predVal > 0 then
            pcall(function()
                if tVelocity and (tVelocity.X ~= 0 or tVelocity.Y ~= 0) then
                    local approxDist = player:GetDistanceTo(bestTarget) / 100.0
                    local approxToF = approxDist / 100.0
                    local predScale = predVal / 50.0
                    finalBonePos.X = finalBonePos.X + (tVelocity.X * approxToF * predScale)
                    finalBonePos.Y = finalBonePos.Y + (tVelocity.Y * approxToF * predScale)
                end
            end)
        end


        if not isMortar and predVal > 0 then
            pcall(function()

                if tVelocity and (tVelocity.X ~= 0 or tVelocity.Y ~= 0) then
                    local distToEnemy = player:GetDistanceTo(bestTarget) / 100.0


                    local ToF = (distToEnemy / 800.0) * (predVal / 50.0)


                    finalBonePos.X = finalBonePos.X + (tVelocity.X * ToF)
                    finalBonePos.Y = finalBonePos.Y + (tVelocity.Y * ToF)
                end
            end)
        end

        local rot = KismetMathLibrary.FindLookAtRotation(camLoc, finalBonePos)
        if not rot then return end

        local currentRot = pc:GetControlRotation()
        if not currentRot then return end

        local deltaYaw = rot.Yaw - currentRot.Yaw
        local deltaPitch = rot.Pitch - currentRot.Pitch


        if isADS then
            local camRot = nil
            if type(camManager.GetCameraRotation) == "function" then
                camRot = camManager:GetCameraRotation()
            end
            if camRot then
                deltaYaw = deltaYaw - (camRot.Yaw - currentRot.Yaw)
                deltaPitch = deltaPitch - (camRot.Pitch - currentRot.Pitch)
            end
        end


        if deltaYaw > 180 then deltaYaw = deltaYaw - 360 end
        if deltaYaw < -180 then deltaYaw = deltaYaw + 360 end
        if deltaPitch > 180 then deltaPitch = deltaPitch - 360 end
        if deltaPitch < -180 then deltaPitch = deltaPitch + 360 end

        local smoothFactor = 0.0
        if speedVal >= 100 then
            smoothFactor = 1.0
        else
            smoothFactor = (speedVal / 100.0) * 0.3
            if smoothFactor < 0.01 then smoothFactor = 0.01 end
        end

        local finalPitch = currentRot.Pitch + (deltaPitch * smoothFactor)
        local finalYaw = currentRot.Yaw + (deltaYaw * smoothFactor)


        if recoilCompVal > 0 and isFiring then
            local pullDownForce = (recoilCompVal / 50.0) * 1.5
            finalPitch = finalPitch - pullDownForce
        end


        if isMortar and _G.LexusConfig.AimTouchMortar then
            local targetPos = { X = finalBonePos.X, Y = finalBonePos.Y, Z = finalBonePos.Z }
            local launchPos = camLoc
            pcall(function()
                if player.K2_GetActorLocation then
                    local pLoc = player:K2_GetActorLocation()
                    if pLoc then
                        launchPos = { X = pLoc.X, Y = pLoc.Y, Z = pLoc.Z + 50 }
                    end
                end
            end)

            local function CalcMortarTrajectory(V, G, tX, tY, tZ)
                local mDx = math.sqrt((tX - launchPos.X)^2 + (tY - launchPos.Y)^2) - 80
                if mDx < 500 then mDx = 500 end
                local mDy = tZ - launchPos.Z

                local minVSq = G * (mDy + math.sqrt(mDx*mDx + mDy*mDy))
                if (V * V) < minVSq then
                    V = math.sqrt(minVSq) + 100
                end

                local v2 = V * V
                local root = v2*v2 - G*(G*mDx*mDx + 2*mDy*v2)

                if root >= 0 then
                    local angleRad = math.atan((v2 + math.sqrt(root)) / (G * mDx))
                    local deg = math.deg(angleRad)
                    if deg >= 35 and deg <= 89.5 then
                        return true, deg, mDx / (V * math.cos(angleRad)), mDx
                    end
                end
                return false, 45, 0, mDx
            end

            local vNear, gNear = 9070, 980 * 2.8
            local vFar, gFar = 12520, 980 * 4.0
            local vUltra, gUltra = 16800, 980 * 4.5

            local isValid, physAngle, ToF, finalDx = false, 45, 0, 0

            local okNear, angNear, tofNear, dxN = CalcMortarTrajectory(vNear, gNear, targetPos.X, targetPos.Y, targetPos.Z)
            local okFar, angFar, tofFar, dxF = CalcMortarTrajectory(vFar, gFar, targetPos.X, targetPos.Y, targetPos.Z)
            local okUltra, angUltra, tofUltra, dxU = CalcMortarTrajectory(vUltra, gUltra, targetPos.X, targetPos.Y, targetPos.Z)

            if okNear and dxN <= 25000 then
                isValid, physAngle, ToF, finalDx = okNear, angNear, tofNear, dxN
            elseif okFar and dxF <= 40000 then
                isValid, physAngle, ToF, finalDx = okFar, angFar, tofFar, dxF
            elseif okUltra then
                isValid, physAngle, ToF, finalDx = okUltra, angUltra, tofUltra, dxU
            elseif okNear then
                isValid, physAngle, ToF, finalDx = okNear, angNear, tofNear, dxN
            end

            local targetCameraPitch = ((physAngle - 45) / 43.0) * 90.0 - 60.0
            local targetCameraYaw = rot.Yaw

            local deltaPitchMortar = targetCameraPitch - currentRot.Pitch
            local deltaYawMortar = targetCameraYaw - currentRot.Yaw

            if deltaPitchMortar > 180 then deltaPitchMortar = deltaPitchMortar - 360 end
            if deltaPitchMortar < -180 then deltaPitchMortar = deltaPitchMortar + 360 end
            if deltaYawMortar > 180 then deltaYawMortar = deltaYawMortar - 360 end
            if deltaYawMortar < -180 then deltaYawMortar = deltaYawMortar + 360 end

            finalPitch = currentRot.Pitch + (deltaPitchMortar * smoothFactor)
            finalYaw = currentRot.Yaw + (deltaYawMortar * smoothFactor)
        end

        local finalRot = { Pitch = finalPitch, Yaw = finalYaw, Roll = 0 }
        pc:SetControlRotation(finalRot, "AimTouch")

        if isShotgun and _G.LexusConfig.AimTouchSGAutoFire then
            pcall(function()
                local distToTarget = player:GetDistanceTo(bestTarget) / 100
                if distToTarget <= maxDistMeters then
                    player.bIsWeaponFiring = true
                    if type(player.SetIsWeaponFiring) == "function" then player:SetIsWeaponFiring(true) end
                    if slua.isValid(pc) and type(pc.SetIsWeaponFiring) == "function" then pc:SetIsWeaponFiring(true) end
                    local wepMgr = player.WeaponManagerComponent
                    if slua.isValid(wepMgr) then wepMgr.bIsWeaponFiring = true end

                    local currentWep = player:GetCurrentWeapon()
                    if slua.isValid(currentWep) and type(currentWep.StartFire) == "function" then
                        currentWep:StartFire()
                    end
                    _G.LexusState.IsAutoFiring = true
                end
            end)
        end

    end)
end


local ItemDatabase = {

    [101001] = { name = "AKM", cat = "AR", color = {R=255,G=255,B=0,A=255} }, [101002] = { name = "M16A4", cat = "AR", color = {R=255,G=255,B=0,A=255} },
    [101003] = { name = "SCAR-L", cat = "AR", color = {R=255,G=255,B=0,A=255} }, [101004] = { name = "M416", cat = "AR", color = {R=255,G=255,B=0,A=255} },
    [101005] = { name = "Groza", cat = "AR", color = {R=255,G=255,B=0,A=255} }, [101006] = { name = "AUG", cat = "AR", color = {R=255,G=255,B=0,A=255} },
    [101008] = { name = "M762", cat = "AR", color = {R=255,G=255,B=0,A=255} },

    [102001] = { name = "UZI", cat = "SMG", color = {R=0,G=255,B=255,A=255} }, [102002] = { name = "UMP45", cat = "SMG", color = {R=0,G=255,B=255,A=255} },
    [102003] = { name = "Vector", cat = "SMG", color = {R=0,G=255,B=255,A=255} }, [102004] = { name = "Thompson", cat = "SMG", color = {R=0,G=255,B=255,A=255} },

    [103001] = { name = "Kar98K", cat = "Sniper", color = {R=255,G=0,B=0,A=255} }, [103002] = { name = "M24", cat = "Sniper", color = {R=255,G=0,B=0,A=255} },
    [103003] = { name = "AWM", cat = "Sniper", color = {R=255,G=0,B=0,A=255} }, [103009] = { name = "SLR", cat = "Sniper", color = {R=255,G=0,B=0,A=255} },

    [104001] = { name = "S686", cat = "Shotgun", color = {R=80,G=100,B=255,A=255} }, [104003] = { name = "S12K", cat = "Shotgun", color = {R=80,G=100,B=255,A=255} },
    [104004] = { name = "DBS", cat = "Shotgun", color = {R=80,G=100,B=255,A=255} },

    [105001] = { name = "M249", cat = "AR", color = {R=255,G=255,B=255,A=255} }, [105002] = { name = "DP-28", cat = "AR", color = {R=255,G=255,B=255,A=255} },

    [203004] = { name = "4x Scope", cat = "Scope", color = {R=0,G=0,B=255,A=255} }, [203005] = { name = "8x Scope", cat = "Scope", color = {R=0,G=0,B=255,A=255} },
    [203014] = { name = "3x Scope", cat = "Scope", color = {R=0,G=0,B=255,A=255} }, [203015] = { name = "6x Scope", cat = "Scope", color = {R=0,G=0,B=255,A=255} }
}

_G.CachedItems = {}
_G.LastScanItemTime = 0
_G.AppliedVehicleWall = {}
_G.AppliedItemESP = {}


local C_AR      = {R = 255, G = 255, B = 0, A = 255}
local C_SMG     = {R = 0, G = 255, B = 255, A = 255}
local C_Sniper  = {R = 255, G = 0, B = 0, A = 255}
local C_Shotgun = {R = 0, G = 255, B = 0, A = 255}
local C_LMG     = {R = 255, G = 255, B = 255, A = 255}
local C_Pistol  = {R = 200, G = 200, B = 200, A = 255}
local C_Special = {R = 255, G = 0, B = 255, A = 255}
local C_Melee   = {R = 150, G = 150, B = 150, A = 255}
local C_Scope   = {R = 0, G = 0, B = 255, A = 255}
local C_Grenade = {R = 255, G = 165, B = 0, A = 255}
local C_Med     = {R = 50, G = 255, B = 50, A = 255}

local ItemDatabase = {

    [101001] = { name = "AKM", cat = "AR", color = C_AR }, [101002] = { name = "M16A4", cat = "AR", color = C_AR },
    [101003] = { name = "SCAR-L", cat = "AR", color = C_AR }, [101004] = { name = "M416", cat = "AR", color = C_AR },
    [101005] = { name = "Groza", cat = "AR", color = C_AR }, [101006] = { name = "AUG", cat = "AR", color = C_AR },
    [101007] = { name = "QBZ", cat = "AR", color = C_AR }, [101008] = { name = "M762", cat = "AR", color = C_AR },
    [101009] = { name = "Mk47 Mutant", cat = "AR", color = C_AR }, [101010] = { name = "G36C", cat = "AR", color = C_AR },
    [101011] = { name = "AC-VAL", cat = "AR", color = C_AR }, [101012] = { name = "Honey Badger", cat = "AR", color = C_AR },
    [101100] = { name = "FAMAS", cat = "AR", color = C_AR }, [101101] = { name = "ASM Abakan AR", cat = "AR", color = C_AR },
    [101102] = { name = "ACE32", cat = "AR", color = C_AR },

    [102001] = { name = "UZI", cat = "SMG", color = C_SMG }, [102002] = { name = "UMP45", cat = "SMG", color = C_SMG },
    [102003] = { name = "Vector", cat = "SMG", color = C_SMG }, [102004] = { name = "Thompson SMG", cat = "SMG", color = C_SMG },
    [102005] = { name = "PP-19 Bizon", cat = "SMG", color = C_SMG }, [102007] = { name = "MP5K", cat = "SMG", color = C_SMG },
    [102008] = { name = "JS9", cat = "SMG", color = C_SMG }, [102105] = { name = "P90", cat = "SMG", color = C_SMG },

    [103001] = { name = "Kar98K", cat = "Sniper", color = C_Sniper }, [103002] = { name = "M24", cat = "Sniper", color = C_Sniper },
    [103003] = { name = "AWM", cat = "Sniper", color = C_Sniper }, [103004] = { name = "SKS", cat = "Sniper", color = C_Sniper },
    [103005] = { name = "VSS", cat = "Sniper", color = C_Sniper }, [103006] = { name = "Mini14", cat = "Sniper", color = C_Sniper },
    [103007] = { name = "Mk14", cat = "Sniper", color = C_Sniper }, [103008] = { name = "Win94", cat = "Sniper", color = C_Sniper },
    [103009] = { name = "SLR", cat = "Sniper", color = C_Sniper }, [103010] = { name = "QBU", cat = "Sniper", color = C_Sniper },
    [103011] = { name = "Mosin Nagant", cat = "Sniper", color = C_Sniper }, [103012] = { name = "AMR", cat = "Sniper", color = C_Sniper },
    [103100] = { name = "Mk12", cat = "Sniper", color = C_Sniper }, [103101] = { name = "TR-2A Air Gun", cat = "Sniper", color = C_Sniper },
    [103102] = { name = "DSR", cat = "Sniper", color = C_Sniper }, [103103] = { name = "Sniper Rifle", cat = "Sniper", color = C_Sniper },
    [103104] = { name = "Sniper Rifle", cat = "Sniper", color = C_Sniper }, [103105] = { name = "SR", cat = "Sniper", color = C_Sniper },

    [104001] = { name = "S686", cat = "Shotgun", color = C_Shotgun }, [104002] = { name = "S1897", cat = "Shotgun", color = C_Shotgun },
    [104003] = { name = "S12K", cat = "Shotgun", color = C_Shotgun }, [104004] = { name = "DBS", cat = "Shotgun", color = C_Shotgun },
    [104100] = { name = "SPAS-12", cat = "Shotgun", color = C_Shotgun }, [104101] = { name = "M1014", cat = "Shotgun", color = C_Shotgun },
    [104102] = { name = "NS2000", cat = "Shotgun", color = C_Shotgun },

    [105001] = { name = "M249", cat = "LMG", color = C_LMG }, [105002] = { name = "DP-28", cat = "LMG", color = C_LMG },
    [105003] = { name = "M134", cat = "LMG", color = C_LMG }, [105010] = { name = "MG3", cat = "LMG", color = C_LMG },
    [105101] = { name = "Gatling", cat = "LMG", color = C_LMG }, [105115] = { name = "Lib Gatling MG", cat = "LMG", color = C_LMG },
    [105004] = { name = "Flamethrower", cat = "LMG", color = C_LMG }, [105006] = { name = "M2 Fixed MG", cat = "LMG", color = C_LMG },
    [105007] = { name = "Gatling Fixed MG", cat = "LMG", color = C_LMG }, [105008] = { name = "Mounted Flamethrower", cat = "LMG", color = C_LMG },
    [105009] = { name = "M2 Mounted MG", cat = "LMG", color = C_LMG }, [105102] = { name = "Vehicle SG", cat = "LMG", color = C_LMG },
    [105103] = { name = "RPG", cat = "LMG", color = C_LMG }, [105104] = { name = "RPG", cat = "LMG", color = C_LMG },
    [105105] = { name = "PowPow MG", cat = "LMG", color = C_LMG }, [105106] = { name = "Tank Cannon", cat = "LMG", color = C_LMG },
    [105107] = { name = "Tank MG", cat = "LMG", color = C_LMG }, [105108] = { name = "Tank Flare Gun", cat = "LMG", color = C_LMG },
    [105116] = { name = "Lib Autocannon", cat = "LMG", color = C_LMG }, [105117] = { name = "Jet Missile", cat = "LMG", color = C_LMG },
    [105118] = { name = "Jet Autocannon", cat = "LMG", color = C_LMG },

    [106001] = { name = "P92", cat = "Pistol", color = C_Pistol }, [106002] = { name = "P1911", cat = "Pistol", color = C_Pistol },
    [106003] = { name = "R1895", cat = "Pistol", color = C_Pistol }, [106004] = { name = "P18C", cat = "Pistol", color = C_Pistol },
    [106005] = { name = "R45", cat = "Pistol", color = C_Pistol }, [106006] = { name = "Sawed-off", cat = "Pistol", color = C_Pistol },
    [106008] = { name = "Skorpion", cat = "Pistol", color = C_Pistol }, [106010] = { name = "Desert Eagle", cat = "Pistol", color = C_Pistol },
    [106007] = { name = "Flare Gun", cat = "Pistol", color = C_Pistol }, [106009] = { name = "Flare Gun", cat = "Pistol", color = C_Pistol },
    [106011] = { name = "Dual MP7", cat = "Pistol", color = C_Pistol }, [106012] = { name = "Welding Gun", cat = "Pistol", color = C_Pistol },
    [106013] = { name = "Stun Gun", cat = "Pistol", color = C_Pistol }, [106101] = { name = "Vehicle Flare", cat = "Pistol", color = C_Pistol },
    [106103] = { name = "Flare Gun", cat = "Pistol", color = C_Pistol }, [106106] = { name = "Flare (Empty)", cat = "Pistol", color = C_Pistol },
    [106107] = { name = "Respawn Flare", cat = "Pistol", color = C_Pistol }, [106203] = { name = "Magnet Gun", cat = "Pistol", color = C_Pistol },

    [107011] = { name = "Súng Cối", cat = "Special", color = C_Special }, [307006] = { name = "Đạn Cối", cat = "Special", color = C_Special },
    [107001] = { name = "Crossbow", cat = "Special", color = C_Special }, [107002] = { name = "RPG-7", cat = "Special", color = C_Special },
    [107003] = { name = "Riot shield", cat = "Special", color = C_Special }, [107004] = { name = "Combat Drone", cat = "Special", color = C_Special },
    [107005] = { name = "Panzerfaust", cat = "Special", color = C_Special }, [107006] = { name = "RPG-7", cat = "Special", color = C_Special },
    [107007] = { name = "Tactical Crossbow", cat = "Special", color = C_Special }, [107008] = { name = "Explosive Bow", cat = "Special", color = C_Special },
    [107009] = { name = "Explosive Bow", cat = "Special", color = C_Special }, [107010] = { name = "M79 Smoke Launcher", cat = "Special", color = C_Special },
    [107019] = { name = "Atlas Gauntlet", cat = "Special", color = C_Special }, [107020] = { name = "Explosive Crossbow", cat = "Special", color = C_Special },
    [107021] = { name = "Mercury Hammer", cat = "Special", color = C_Special }, [107022] = { name = "Fishbones Rocket", cat = "Special", color = C_Special },
    [107031] = { name = "Summer Grenade Launcher", cat = "Special", color = C_Special }, [107032] = { name = "Summer Bazooka", cat = "Special", color = C_Special },
    [107033] = { name = "Summer MG", cat = "Special", color = C_Special }, [107034] = { name = "Color Bazooka", cat = "Special", color = C_Special },
    [107035] = { name = "Bubble MG", cat = "Special", color = C_Special }, [107036] = { name = "Snowball Blaster", cat = "Special", color = C_Special },
    [107037] = { name = "Water Orb Blaster", cat = "Special", color = C_Special }, [107092] = { name = "MGL", cat = "Special", color = C_Special },
    [107093] = { name = "M202 Quad RPG", cat = "Special", color = C_Special }, [107094] = { name = "AT4-A Laser Missile", cat = "Special", color = C_Special },
    [107095] = { name = "M202 Quad RPG", cat = "Special", color = C_Special }, [107096] = { name = "M79 Sawed-off", cat = "Special", color = C_Special },
    [107097] = { name = "M79", cat = "Special", color = C_Special }, [107098] = { name = "MGL", cat = "Special", color = C_Special },
    [107099] = { name = "M3E1-A", cat = "Special", color = C_Special }, [107901] = { name = "Zombie Piercer", cat = "Special", color = C_Special },
    [107903] = { name = "Mounted RPG", cat = "Special", color = C_Special }, [107904] = { name = "Helicopter RPG", cat = "Special", color = C_Special },
    [107911] = { name = "M3E1-B Missile", cat = "Special", color = C_Special },

    [108001] = { name = "Machete", cat = "Melee", color = C_Melee }, [108002] = { name = "Crowbar", cat = "Melee", color = C_Melee },
    [108003] = { name = "Sickle", cat = "Melee", color = C_Melee }, [108004] = { name = "Pan", cat = "Melee", color = C_Melee },
    [108005] = { name = "Dagger", cat = "Melee", color = C_Melee }, [108006] = { name = "Mutation Blade", cat = "Melee", color = C_Melee },
    [108007] = { name = "Mutation Gauntlets", cat = "Melee", color = C_Melee },

    [203001] = { name = "Red Dot Sight", cat = "Scope", color = C_Scope }, [203002] = { name = "Holographic Sight", cat = "Scope", color = C_Scope },
    [203003] = { name = "2x Scope", cat = "Scope", color = C_Scope }, [203004] = { name = "4x Scope", cat = "Scope", color = C_Scope },
    [203005] = { name = "8x Scope", cat = "Scope", color = C_Scope }, [203014] = { name = "3x Scope", cat = "Scope", color = C_Scope },
    [203015] = { name = "6x Scope", cat = "Scope", color = C_Scope },

    [602001] = { name = "Stun Grenade", cat = "Grenade", color = C_Grenade }, [602002] = { name = "Smoke Grenade", cat = "Grenade", color = C_Grenade },
    [602003] = { name = "Molotov", cat = "Grenade", color = C_Grenade }, [602004] = { name = "Frag Grenade", cat = "Grenade", color = C_Grenade },


    [601001] = { name = "Nước Tăng Lực", cat = "Med", color = C_Med }, [601002] = { name = "Tiêm Adrenaline", cat = "Med", color = C_Med },
    [601003] = { name = "Thuốc Giảm Đau", cat = "Med", color = C_Med }, [601004] = { name = "Băng Gạc", cat = "Med", color = C_Med },
    [601005] = { name = "Bộ Sơ Cứu", cat = "Med", color = C_Med }, [601006] = { name = "Bộ Cứu Thương", cat = "Med", color = C_Med },
    [601009] = { name = "Băng Gạc Nhanh", cat = "Med", color = C_Med }, [601010] = { name = "Sơ Cứu Nhanh", cat = "Med", color = C_Med },
    [601011] = { name = "Băng Gạc QĐ", cat = "Med", color = C_Med }, [601012] = { name = "Nước Đậm Đặc", cat = "Med", color = C_Med },
    [601020] = { name = "Băng Gạc", cat = "Med", color = C_Med }, [601021] = { name = "Bộ Sơ Cứu", cat = "Med", color = C_Med },
    [601022] = { name = "Bộ Cứu Thương", cat = "Med", color = C_Med }, [601023] = { name = "Tiêm Adrenaline", cat = "Med", color = C_Med },
    [601061] = { name = "Bộ Cứu Thương", cat = "Med", color = C_Med }, [601077] = { name = "Sơ Cứu Chiến Thuật", cat = "Med", color = C_Med },
    [601078] = { name = "Sơ Cứu Toàn Năng", cat = "Med", color = C_Med }, [601079] = { name = "Cứu Thương Toàn Năng", cat = "Med", color = C_Med },
    [601080] = { name = "Băng Gạc QĐ", cat = "Med", color = C_Med }, [601081] = { name = "Nước Đậm Đặc", cat = "Med", color = C_Med },
    [601084] = { name = "Sơ Cứu Nhanh", cat = "Med", color = C_Med }, [601085] = { name = "Cứu Thương Nhanh", cat = "Med", color = C_Med },
    [601095] = { name = "Máy AED (Hồi Sinh)", cat = "Med", color = C_Med }, [601096] = { name = "Chuẩn Bị Chiến Đấu", cat = "Med", color = C_Med },
    [602054] = { name = "Tiếp Tế Y Tế", cat = "Med", color = C_Med }, [602069] = { name = "Cứu Trợ Khẩn Cấp", cat = "Med", color = C_Med }
}

_G.CachedItems = {}
_G.LastScanItemTime = 0
_G.AppliedVehicleWall = {}
_G.AppliedItemESP = {}

_G.RunOptimizedItemAndVehicleESP = function(pc)
    local curTime = os.clock()


    if curTime - _G.LastScanItemTime > 1.0 then
        _G.LastScanItemTime = curTime
        local player = GameplayData.GetPlayerCharacter()
        if not slua.isValid(player) then return end


        if _G.LexusConfig.WallVehicle then
            local ASTExtraVehicleBase = import("STExtraVehicleBase")
            if ASTExtraVehicleBase then
                local Actors = Game:GetActorsByClass(ASTExtraVehicleBase)
                if Actors then
                    local count = Actors:Num() or 0
                    for i = 0, count - 1 do
                        local vehicle = Actors:Get(i)
                        if slua.isValid(vehicle) and vehicle.GetMesh then
                            local dist = player:GetDistanceTo(vehicle)
                            if dist <= 200000 then
                                local vId = tostring(vehicle)
                                if not _G.AppliedVehicleWall[vId] then
                                    local mesh = vehicle:GetMesh()
                                    if slua.isValid(mesh) then
                                        local matInterface = mesh:GetMaterial(0)
                                        if slua.isValid(matInterface) then
                                            local baseMat = matInterface:GetBaseMaterial()
                                            if slua.isValid(baseMat) then
                                                baseMat.bDisableDepthTest = true
                                                baseMat.BlendMode = 2
                                                _G.AppliedVehicleWall[vId] = true
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        else _G.AppliedVehicleWall = {} end


        if _G.LexusConfig.EspItem_Master then
            local APickUpWrapperActor = import("PickUpWrapperActor") or import("STPickupWrapperActor")
            if APickUpWrapperActor then
                local Actors = Game:GetActorsByClass(APickUpWrapperActor)
                _G.CachedItems = {}
                if Actors then
                    local count = Actors:Num() or 0
                    for i = 0, count - 1 do
                        local item = Actors:Get(i)


                        local isPendingKill = false
                        pcall(function() if type(item.IsPendingKill) == "function" then isPendingKill = item:IsPendingKill() end end)


                        if slua.isValid(item) and not item.bHidden and not isPendingKill then
                            local dist = player:GetDistanceTo(item)

                            if dist <= 7000 then
                                local itemId = item.DefineID and item.DefineID.TypeSpecificID or item.DefineId
                                local itemData = ItemDatabase[itemId]

                                if itemData then

                                    local isShow = false
                                    if itemData.cat == "AR" and _G.LexusConfig.EspItem_AR then isShow = true
                                    elseif itemData.cat == "Sniper" and _G.LexusConfig.EspItem_Sniper then isShow = true
                                    elseif itemData.cat == "SMG" and _G.LexusConfig.EspItem_SMG then isShow = true
                                    elseif itemData.cat == "Shotgun" and _G.LexusConfig.EspItem_Shotgun then isShow = true
                                    elseif itemData.cat == "LMG" and _G.LexusConfig.EspItem_LMG then isShow = true
                                    elseif itemData.cat == "Pistol" and _G.LexusConfig.EspItem_Pistol then isShow = true
                                    elseif itemData.cat == "Melee" and _G.LexusConfig.EspItem_Melee then isShow = true
                                    elseif itemData.cat == "Special" and _G.LexusConfig.EspItem_Special then isShow = true
                                    elseif itemData.cat == "Grenade" and _G.LexusConfig.EspItem_Grenade then isShow = true
                                    elseif itemData.cat == "Scope" and _G.LexusConfig.EspItem_Scope then isShow = true
                                    elseif itemData.cat == "Med" and _G.LexusConfig.EspItem_Med then isShow = true
                                    end


                                    if isShow then
                                        table.insert(_G.CachedItems, item)

                                        local iId = tostring(item)
                                        if not _G.AppliedItemESP[iId] then
                                            local meshes = {}
                                            if item.GetPickupMesh then
                                                local pMesh = item:GetPickupMesh()
                                                if slua.isValid(pMesh) then table.insert(meshes, pMesh) end
                                            end
                                            local childs = item:GetComponentsByClass(import("StaticMeshComponent"))
                                            if childs then
                                                for _, v in pairs(childs) do
                                                    if slua.isValid(v) then table.insert(meshes, v) end
                                                end
                                            end
                                            for _, mesh in pairs(meshes) do
                                                pcall(function() mesh:SetRenderCustomDepth(true) end)
                                                for mi = 0, 8 do
                                                    local mid = mesh:CreateAndSetMaterialInstanceDynamic(mi)
                                                    if slua.isValid(mid) then
                                                        local colorVisible = {R = 50, G = 50, B = 0, A = 10}
                                                        pcall(function()
                                                            mid:SetVectorParameterValue("LightColor", colorVisible)
                                                            mid:SetVectorParameterValue("ParaScaleOffset", {R = 3, G = 3, B = 0, A = 0})
                                                            mid:SetScalarParameterValue("RimLight", 999)
                                                            mid:SetScalarParameterValue("Brightness", 999)
                                                            mid:SetScalarParameterValue("Exposure", 999)
                                                        end)
                                                    end
                                                end
                                            end
                                            _G.AppliedItemESP[iId] = true
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        else
            _G.AppliedItemESP = {}
            _G.CachedItems = {}
        end
    end


    if _G.LexusConfig.EspItem_Master and slua.isValid(pc) and pc.MyHUD then
        local hud = pc.MyHUD
        local player = GameplayData.GetPlayerCharacter()
        for _, item in ipairs(_G.CachedItems) do

            if slua.isValid(item) and not item.bHidden then
                local itemId = item.DefineID and item.DefineID.TypeSpecificID or item.DefineId
                if itemId and ItemDatabase[itemId] then
                    local itemData = ItemDatabase[itemId]
                    local dist = (player.GetDistanceTo and player:GetDistanceTo(item) or 0) / 100
                    local displayText = string.format("%s [%.0fm]", itemData.name, dist)
                    local textColor = {R = itemData.color.R, G = itemData.color.G, B = itemData.color.B, A = 255}
                    hud:AddDebugText(
                        displayText, item, 0.06,
                        {X=0, Y=0, Z=50}, {X=0, Y=0, Z=50},
                        textColor, true, false, true, nil, 0.8, true
                    )
                end
            end
        end
    end
end


local BTN_BP = "/Game/UMG/UI_BP/Common/BaseComponent/CommonBaseComponent_TextButton_UIBP.CommonBaseComponent_TextButton_UIBP"
local EnemyCounterWidget = nil
local WarningTargetWidget = nil
local LastCounterTime = 0


function _G.CleanUpEnemyCounterWidget()
    if EnemyCounterWidget and slua.isValid(EnemyCounterWidget) then
        EnemyCounterWidget:RemoveFromParent()
    end
    EnemyCounterWidget = nil

    if WarningTargetWidget and slua.isValid(WarningTargetWidget) then
        WarningTargetWidget:RemoveFromParent()
    end
    WarningTargetWidget = nil
end


local function CreateEnemyCounterWidget()
    if EnemyCounterWidget then
        if slua.isValid(EnemyCounterWidget) then return EnemyCounterWidget else EnemyCounterWidget = nil end
    end

    pcall(function()
        local btn = slua.loadUI(BTN_BP)
        if not btn or not slua.isValid(btn) then return end
        require("game_frontend_hud").AddToContainer(UIContainers.Top, btn, 10500)

        if btn.RichText_Content then
            btn.RichText_Content:SetText("Kẻ Địch: 0  |  Gần Nhất: 0m")
            local fontInfo = btn.RichText_Content.Font
            if fontInfo then fontInfo.Size = 16 btn.RichText_Content:SetFont(fontInfo) end
        end

        local WidgetLayoutLibrary = import("WidgetLayoutLibrary")
        local slot = WidgetLayoutLibrary.SlotAsCanvasSlot(btn)
        if slot then
            slot:SetAnchors(FAnchors(0.5, 0, 0.5, 0))
            slot:SetAlignment(FVector2D(0.5, 0))
            slot:SetPosition(FVector2D(0, 30))
            slot:SetSize(FVector2D(240, 36))
        end
        btn:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        EnemyCounterWidget = btn
    end)
    return EnemyCounterWidget
end


local function CreateWarningTargetWidget()
    if WarningTargetWidget then
        if slua.isValid(WarningTargetWidget) then return WarningTargetWidget else WarningTargetWidget = nil end
    end

    pcall(function()
        local btn = slua.loadUI(BTN_BP)
        if not btn or not slua.isValid(btn) then return end
        require("game_frontend_hud").AddToContainer(UIContainers.Top, btn, 10501)

        if btn.RichText_Content then

            btn.RichText_Content:SetText("XTHRLEN-VipMods")
            local fontInfo = btn.RichText_Content.Font
            if fontInfo then fontInfo.Size = 18 btn.RichText_Content:SetFont(fontInfo) end
        end

        local WidgetLayoutLibrary = import("WidgetLayoutLibrary")
        local slot = WidgetLayoutLibrary.SlotAsCanvasSlot(btn)
        if slot then
            slot:SetAnchors(FAnchors(0.5, 0, 0.5, 0))
            slot:SetAlignment(FVector2D(0.5, 0))
            slot:SetPosition(FVector2D(0, 75))
            slot:SetSize(FVector2D(260, 36))
        end
        btn:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
        WarningTargetWidget = btn
    end)
    return WarningTargetWidget
end


local function _M_DrawCounter()
    if _G._LICENSE_OK ~= true then
        _G.CleanUpEnemyCounterWidget()
        return
    end

    pcall(function()
        local player = GameplayData.GetPlayerCharacter()
        if not slua.isValid(player) then
            if EnemyCounterWidget and slua.isValid(EnemyCounterWidget) then
                EnemyCounterWidget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
            end
            if WarningTargetWidget and slua.isValid(WarningTargetWidget) then
                WarningTargetWidget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
            end
            return
        end

        local widgetCounter = CreateEnemyCounterWidget()
        local widgetWarning = CreateWarningTargetWidget()

        if widgetCounter and slua.isValid(widgetCounter) then
            widgetCounter:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end


        local curTime = os.clock()
        if (curTime - LastCounterTime) > 0.5 then
            LastCounterTime = curTime

            local myTeam = player.TeamID or (type(player.GetTeamID) == "function" and player:GetTeamID()) or 0
            local count = 0
            local nearest = 9999
            local isBeingTargeted = false

            local KismetMathLibrary = import("KismetMathLibrary")
            local pc = player:GetPlayerControllerSafety()

            local allCharacters = {}
            if GameplayData.GetAllPlayerCharacters then
                allCharacters = GameplayData.GetAllPlayerCharacters()
            elseif GameplayData.GameCharacters then
                for _, char in pairs(GameplayData.GameCharacters) do table.insert(allCharacters, char) end
            end

            for _, tPawn in pairs(allCharacters) do
                if slua.isValid(tPawn) and tPawn ~= player then
                    local isAlive = false
                    if tPawn.HealthStatus ~= nil then
                        isAlive = (tPawn.HealthStatus ~= 2)
                    else
                        isAlive = (tPawn.Health or 0) > 0 or (type(tPawn.IsAlive) == "function" and tPawn:IsAlive())
                    end

                    if isAlive then
                        local tTeam = tPawn.TeamID or (type(tPawn.GetTeamID) == "function" and tPawn:GetTeamID()) or 0
                        if tTeam ~= myTeam then
                            count = count + 1
                            local d = math.floor(player:GetDistanceTo(tPawn) / 100)
                            if d < nearest then nearest = d end


                            if _G.LexusConfig.EspAimWarning and not isBeingTargeted and d < 400 then
                                local eLoc = type(tPawn.K2_GetActorLocation) == "function" and tPawn:K2_GetActorLocation()
                                local pLoc = type(player.K2_GetActorLocation) == "function" and player:K2_GetActorLocation()

                                if eLoc and pLoc and KismetMathLibrary then
                                    local lookRot = KismetMathLibrary.FindLookAtRotation(eLoc, pLoc)
                                    local eRot = nil

                                    if type(tPawn.GetControlRotation) == "function" then
                                        eRot = tPawn:GetControlRotation()
                                    elseif type(tPawn.GetActorRotation) == "function" then
                                        eRot = tPawn:GetActorRotation()
                                    end

                                    if eRot and lookRot then
                                        local dYaw = math.abs(eRot.Yaw - lookRot.Yaw)
                                        if dYaw > 180 then dYaw = 360 - dYaw end

                                        local dPitch = math.abs(eRot.Pitch - lookRot.Pitch)
                                        if dPitch > 180 then dPitch = 360 - dPitch end


                                        if dYaw < 15 and dPitch < 20 then

                                            if _G.LexusConfig.EspAimWarningVisCheck then
                                                if slua.isValid(pc) and type(pc.LineOfSightTo) == "function" then
                                                    if pc:LineOfSightTo(tPawn) then
                                                        isBeingTargeted = true
                                                    end
                                                end
                                            else

                                                isBeingTargeted = true
                                            end
                                        end
                                    end
                                end
                            end

                        end
                    end
                end
            end


            if widgetCounter and widgetCounter.RichText_Content then
                widgetCounter.RichText_Content:SetText(string.format("الأعداء حولك: %d  |  الأقرب: %dm", count, count > 0 and nearest or 0))
            end


            if widgetWarning and slua.isValid(widgetWarning) then
                if _G.LexusConfig.EspAimWarning and isBeingTargeted then
                    widgetWarning:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                else
                    widgetWarning:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                end
            end
        end
    end)
end


local PlayerMapMarker = {}

local RedBoxOverlay = {
    bActive = false,
    MainContainer = nil,
    WidgetSlot = nil,
    TextBlock = nil,
    RightsTextBlock = nil,
    Width = 190,
    Height = 54,
    CounterTop = 20,
    OffsetY = 10,
    PlayerCount = 0,
    BotCount = 0,
    FontSize = 13,
    TextScaleValue = 1.0,
    _CachedText = "",
    _CachedPosVec = nil
}

function RedBoxOverlay.Create()
    if RedBoxOverlay.MainContainer and slua.isValid(RedBoxOverlay.MainContainer) then return true end

    local ParentCanvas = PlayerMapMarker.ESPCanvas
    if not ParentCanvas or not slua.isValid(ParentCanvas) then
        if not PlayerMapMarker.InitESPCanvas() then return false end
        ParentCanvas = PlayerMapMarker.ESPCanvas
    end

    if not ParentCanvas or not slua.isValid(ParentCanvas) then return false end

    local Container = nil
    pcall(function() Container = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", ParentCanvas) end)
    if not Container or not slua.isValid(Container) then return false end

    local FLinearColor = import("LinearColor") or FLinearColor
    local FVector2D = import("Vector2D") or FVector2D
    local FSlateColor = import("SlateColor") or import("/Script/SlateCore.SlateColor")


    local rightsText = nil
    pcall(function() rightsText = CGame:NewObjectFromPath("/Script/UMG.TextBlock", Container) end)
    if rightsText and slua.isValid(rightsText) then
        pcall(function()
            rightsText:SetText("XTHRLEN-@SRC_HUB")
            local rightsColor = FLinearColor(0.45, 0.95, 1.0, 1.0)
            if FSlateColor then rightsText:SetColorAndOpacity(FSlateColor(rightsColor)) else rightsText:SetColorAndOpacity(rightsColor) end
            if rightsText.Font then
                local rightsFont = rightsText.Font
                rightsFont.Size = 11
                rightsText.Font = rightsFont
            end
            rightsText:SetRenderTransformPivot(FVector2D(0.5, 0.5))
            rightsText:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end)
        local rightsSlot = Container:AddChildToCanvas(rightsText)
        if rightsSlot then
            pcall(function()
                rightsSlot:SetAutoSize(true)
                rightsSlot:SetAlignment(FVector2D(0.5, 0.5))
                rightsSlot:SetPosition(FVector2D(RedBoxOverlay.Width * 0.5, 9))
                rightsSlot:SetZOrder(1001)
            end)
        end
        RedBoxOverlay.RightsTextBlock = rightsText
    end


    local redBorder = nil
    pcall(function() redBorder = CGame:NewObjectFromPath("/Script/UMG.Border", Container) end)
    if redBorder and slua.isValid(redBorder) then
        pcall(function()
            redBorder:SetBrushColor(FLinearColor(0.00, 0.78, 1.0, 0.95))
            redBorder:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end)
        local slotRed = Container:AddChildToCanvas(redBorder)
        if slotRed then
            slotRed:SetPosition(FVector2D(0, RedBoxOverlay.CounterTop))
            slotRed:SetSize(FVector2D(RedBoxOverlay.Width, RedBoxOverlay.Height - RedBoxOverlay.CounterTop))
        end
    end


    local whiteBg = nil
    pcall(function() whiteBg = CGame:NewObjectFromPath("/Script/UMG.Border", Container) end)
    if whiteBg and slua.isValid(whiteBg) then
        pcall(function()
            whiteBg:SetBrushColor(FLinearColor(0.025, 0.02, 0.07, 0.96))
            whiteBg:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end)
        local slotWhite = Container:AddChildToCanvas(whiteBg)
        if slotWhite then

            slotWhite:SetPosition(FVector2D(1.5, RedBoxOverlay.CounterTop + 1.5))
            slotWhite:SetSize(FVector2D(RedBoxOverlay.Width - 3, RedBoxOverlay.Height - RedBoxOverlay.CounterTop - 3))
        end
    end


    local txtBlock = nil
    pcall(function() txtBlock = CGame:NewObjectFromPath("/Script/UMG.TextBlock", Container) end)
    if txtBlock and slua.isValid(txtBlock) then
        pcall(function()
            local strText = string.format("ENEMIES  %d   |   BOTS  %d", RedBoxOverlay.PlayerCount, RedBoxOverlay.BotCount)
            txtBlock:SetText(strText)
            RedBoxOverlay._CachedText = strText


            local blackTextColor = FLinearColor(0.35, 0.95, 1.0, 1.0)
            if FSlateColor then txtBlock:SetColorAndOpacity(FSlateColor(blackTextColor)) else txtBlock:SetColorAndOpacity(blackTextColor) end

            if txtBlock.Font then
                local font = txtBlock.Font
                font.Size = RedBoxOverlay.FontSize
                txtBlock.Font = font
            end
            txtBlock:SetRenderScale(FVector2D(RedBoxOverlay.TextScaleValue, RedBoxOverlay.TextScaleValue))
            txtBlock:SetRenderTransformPivot(FVector2D(0.5, 0.5))
            txtBlock:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end)
        local txtSlot = Container:AddChildToCanvas(txtBlock)
        if txtSlot then
            pcall(function()
                txtSlot:SetAutoSize(true)
                txtSlot:SetAlignment(FVector2D(0.5, 0.5))
                txtSlot:SetPosition(FVector2D(RedBoxOverlay.Width * 0.5, RedBoxOverlay.CounterTop + (RedBoxOverlay.Height - RedBoxOverlay.CounterTop) * 0.5))
                txtSlot:SetZOrder(1000)
            end)
        end
        RedBoxOverlay.TextBlock = txtBlock
    end

    local MainSlot = nil
    pcall(function() MainSlot = ParentCanvas:AddChildToCanvas(Container) end)
    if not MainSlot then return false end

    RedBoxOverlay.MainContainer = Container
    RedBoxOverlay.WidgetSlot = MainSlot

    pcall(function()
        MainSlot:SetAutoSize(false)
        MainSlot:SetZOrder(999)
        MainSlot:SetAlignment(FVector2D(0.5, 0.0))
        MainSlot:SetSize(FVector2D(RedBoxOverlay.Width, RedBoxOverlay.Height))
    end)

    RedBoxOverlay.UpdatePosition()
    return true
end

function RedBoxOverlay.SetCounts(players, bots)
    if RedBoxOverlay.PlayerCount == players and RedBoxOverlay.BotCount == bots then return end
    RedBoxOverlay.PlayerCount = players or 0
    RedBoxOverlay.BotCount = bots or 0

    if RedBoxOverlay.TextBlock and slua.isValid(RedBoxOverlay.TextBlock) then
        pcall(function()
            local str = string.format("ENEMIES  %d   |   BOTS  %d", RedBoxOverlay.PlayerCount, RedBoxOverlay.BotCount)
            if RedBoxOverlay._CachedText ~= str then
                RedBoxOverlay.TextBlock:SetText(str)
                RedBoxOverlay._CachedText = str
            end
        end)
    end
end

function RedBoxOverlay.UpdatePosition()
    local Slot = RedBoxOverlay.WidgetSlot
    if not Slot or not slua.isValid(Slot) then return end
    local PC = PlayerMapMarker.GetMyPlayerController()
    if not slua.isValid(PC) then return end

    local fromX, fromY = PlayerMapMarker.GetSnapLineStartPos(PC)
    local FVector2D = import("Vector2D") or FVector2D
    pcall(function()
        if not RedBoxOverlay._CachedPosVec then
            RedBoxOverlay._CachedPosVec = FVector2D(fromX, fromY)
        else
            RedBoxOverlay._CachedPosVec.X = fromX
            RedBoxOverlay._CachedPosVec.Y = fromY
        end
        Slot:SetPosition(RedBoxOverlay._CachedPosVec)
    end)
end

function RedBoxOverlay.Start()
    if RedBoxOverlay.bActive and RedBoxOverlay.MainContainer and slua.isValid(RedBoxOverlay.MainContainer) then return end
    if RedBoxOverlay.Create() then
        RedBoxOverlay.bActive = true
        pcall(function() RedBoxOverlay.MainContainer:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
    end
end

function RedBoxOverlay.Stop()
    RedBoxOverlay.bActive = false
    if RedBoxOverlay.MainContainer and slua.isValid(RedBoxOverlay.MainContainer) then
        pcall(function()
            RedBoxOverlay.MainContainer:RemoveFromParent()
            RedBoxOverlay.MainContainer:ConditionalBeginDestroy()
        end)
    end
    RedBoxOverlay.MainContainer = nil
    RedBoxOverlay.WidgetSlot = nil
    RedBoxOverlay.TextBlock = nil
    RedBoxOverlay.RightsTextBlock = nil
    RedBoxOverlay._CachedPosVec = nil
end

_G.RedBoxOverlay = RedBoxOverlay

local InGameMarkTools = nil
pcall(function() InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools") end)

local SlateBlueprintLibrary = nil
local WidgetLayoutLibrary = nil
local KismetMathLibrary = nil
local KismetSystemLibrary = nil

pcall(function() SlateBlueprintLibrary = import("SlateBlueprintLibrary") or import("/Script/UMG.SlateBlueprintLibrary") end)
pcall(function() WidgetLayoutLibrary = import("WidgetLayoutLibrary") or import("/Script/UMG.WidgetLayoutLibrary") end)
pcall(function() KismetMathLibrary = import("KismetMathLibrary") end)
pcall(function() KismetSystemLibrary = import("KismetSystemLibrary") end)

local FVector2D = _G.FVector2D or import("Vector2D")
local FLinearColor = _G.FLinearColor or import("LinearColor")
local FVector = _G.FVector or import("Vector")

PlayerMapMarker.MarkTypeID = 1007
PlayerMapMarker.bUseScreenESP = true
PlayerMapMarker.bUseScreenMark = false
PlayerMapMarker.bUseQuickSign = false
PlayerMapMarker.bUseNavigator = false
PlayerMapMarker.bUseWidgetComponent = false
PlayerMapMarker.QuickSignConfigKey = "C_MarkPos"

PlayerMapMarker.WidgetCompUIPath = "/Game/BluePrints/ControlInput/NewbieItem/NewbieTips_ConsumeTips.NewbieTips_ConsumeTips"
PlayerMapMarker.WidgetCompBoneName = "head"
PlayerMapMarker.WidgetCompOffset = FVector and FVector(0, 0, 80) or {X=0, Y=0, Z=80}
PlayerMapMarker.WidgetCompDrawSize = FVector2D and FVector2D(210, 35) or {X=210, Y=35}

PlayerMapMarker.ESPBoneName = "head"
PlayerMapMarker.ESPWorldOffsetZ = 0
PlayerMapMarker.ESPScreenOffsetY = 0
PlayerMapMarker.ESPAnchorOffsetX = 35
PlayerMapMarker.ESPAnchorOffsetY = 0
PlayerMapMarker.ESPTextOffsetX = 0
PlayerMapMarker.ESPTextOffsetY = 0

PlayerMapMarker.ESPWidgetAlignment = FVector2D and FVector2D(0.5, 1.0) or {X=0.5, Y=1.0}
PlayerMapMarker.ESPWidgetSize = FVector2D and FVector2D(70, 21) or {X=70, Y=21}
PlayerMapMarker.ESPWidgetAutoSize = true
PlayerMapMarker.ESPWidgetZOrder = 2

PlayerMapMarker.bShowDistance = true
PlayerMapMarker.DistanceUnit = "m"
PlayerMapMarker.WeaponIconBrushW = 96
PlayerMapMarker.WeaponIconBrushH = 48
PlayerMapMarker.HPWidgetSwitcherTypeIndex = 0
PlayerMapMarker.HPWidgetSwitcherType2Index = 0
PlayerMapMarker.bForceSwitcherIndexEveryUpdate = true

PlayerMapMarker.bUseSnapLines = true
PlayerMapMarker.SnapLineThickness = 1.0
PlayerMapMarker.SnapLineOriginY = 50
PlayerMapMarker.SnapLineOriginOffsetX = 0
PlayerMapMarker.SnapLineHeadOffsetX = 0
PlayerMapMarker.SnapLineHeadOffsetY = -14
PlayerMapMarker.SnapLineColor = FLinearColor and FLinearColor(0.6, 0.0, 0.0, 1.0) or {R=150, G=0, B=0, A=255}
PlayerMapMarker.SnapLineOpacity = 0.7


PlayerMapMarker.bUseSkeleton = true
PlayerMapMarker.SkeletonThickness = 0.8
PlayerMapMarker.SkeletonColor = nil
PlayerMapMarker.SkeletonOpacity = 0.8

PlayerMapMarker.SkeletonMaxDistance = 20000
PlayerMapMarker.bUseVisibilityColor = true
PlayerMapMarker.SkeletonVisibleColor = FLinearColor and FLinearColor(0.10, 1.0, 0.20, 0.8) or {R=26,G=255,B=51,A=200}
PlayerMapMarker.SkeletonCoverColor = FLinearColor and FLinearColor(0.9, 0.0, 0.0, 0.6) or {R=230,G=0,B=0,A=150}

PlayerMapMarker.SkeletonWidgets = {}
PlayerMapMarker._StaticBoneLocCache = {}

PlayerMapMarker.SkeletonChains = {
    {"neck_01", "lowerarm_r", "hand_r"},
    {"neck_01", "lowerarm_l", "hand_l"},
    {"head", "neck_01", "pelvis"},
    {"pelvis", "calf_r", "foot_r"},
    {"pelvis", "calf_l", "foot_l"}
}

PlayerMapMarker.BoneNameFallbacks = {
    ["head"] = {"head", "Head", "head_socket"},
    ["neck_01"] = {"neck_01", "Neck_01", "neck", "Neck"},
    ["clavicle_r"] = {"clavicle_r", "Clavicle_R", "clavicle_R"},
    ["upperarm_r"] = {"upperarm_r", "UpperArm_R", "arm_r", "arm_r_01"},
    ["lowerarm_r"] = {"lowerarm_r", "LowerArm_R", "forearm_r"},
    ["hand_r"] = {"hand_r", "Hand_R", "hand_r_socket"},
    ["clavicle_l"] = {"clavicle_l", "Clavicle_L", "clavicle_L"},
    ["upperarm_l"] = {"upperarm_l", "UpperArm_L", "arm_l", "arm_l_01"},
    ["lowerarm_l"] = {"lowerarm_l", "LowerArm_L", "forearm_l"},
    ["hand_l"] = {"hand_l", "Hand_L", "hand_l_socket"},
    ["spine_03"] = {"spine_03", "Spine_03", "spine_02", "spine"},
    ["spine_02"] = {"spine_02", "Spine_02", "spine_01"},
    ["pelvis"] = {"pelvis", "Pelvis", "hip"},
    ["thigh_r"] = {"thigh_r", "Thigh_R", "leg_r"},
    ["calf_r"] = {"calf_r", "Calf_R", "shin_r"},
    ["foot_r"] = {"foot_r", "Foot_R", "foot_r_socket"},
    ["thigh_l"] = {"thigh_l", "Thigh_L", "leg_l"},
    ["calf_l"] = {"calf_l", "Calf_L", "shin_l"},
    ["foot_l"] = {"foot_l", "Foot_L", "foot_l_socket"},
}


PlayerMapMarker.MapAddedFlag = 4
PlayerMapMarker.nUpdateInterval = 0.5
PlayerMapMarker.bUseFrameTick = false
PlayerMapMarker.nHeavyScanFrameInterval = 15
PlayerMapMarker.nDistanceUpdateFrameInterval = 5
PlayerMapMarker.bIncludeMe = false
PlayerMapMarker.bIncludeAI = true
PlayerMapMarker.bUseServerMarks = false

PlayerMapMarker.bActive = false
PlayerMapMarker.MarkMap = {}
PlayerMapMarker.PlayerInfo = {}
PlayerMapMarker.ESPCanvas = nil
PlayerMapMarker.ESPWidgets = {}
PlayerMapMarker.ESPWidgetPtrs = {}
PlayerMapMarker.SnapLineWidgets = {}

PlayerMapMarker._cachedViewportW = 1920
PlayerMapMarker._cachedViewportH = 1080
PlayerMapMarker._FrameCount = 0
PlayerMapMarker._bTickRegistered = false
PlayerMapMarker._CachedAllChars = nil
PlayerMapMarker._CachedMyLoc = nil
PlayerMapMarker._CachedMyKey = nil
PlayerMapMarker.WidgetComps = {}
PlayerMapMarker._bAllPathsFailed = false
PlayerMapMarker._bLightUpdateScheduled = false

PlayerMapMarker._LightUpdateInterval = 0.04
PlayerMapMarker._bDistanceUpdateScheduled = false
PlayerMapMarker._DistanceUpdateInterval = 0.1
PlayerMapMarker._bScreenMarkConfigSetup = false

local function IsValid(obj)
    if obj == nil then return false end
    if slua and slua.isValid then return slua.isValid(obj) end
    return obj ~= nil
end

function PlayerMapMarker.SetupScreenMarkConfig()
    if PlayerMapMarker._bScreenMarkConfigSetup then return true end
    local bOK = false
    pcall(function()
        local GamePlayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools")
        local ScreenMarkConfig = GamePlayTools.GetCurrentConfig("ScreenMarkConfig")
        if ScreenMarkConfig then
            ScreenMarkConfig[1007] = {
                UIPathName = "/Game/BluePrints/UI/OBUI/Item/OB_PlayerHeadHPItem_UIBP.OB_PlayerHeadHPItem_UIBP_C",
                MaxWidgetNum = 100,
                MaxShowDistance = 6000000,
                bBindOutScreen = false,
                bBindBlocked = true,
                bNeedPreLoad = true,
                bIsBindingActor = true,
                BindSocketName = "HelmetSocket",
                WorldPositionOffset = FVector and FVector(0, 0, 80) or {X=0,Y=0,Z=80}
            }
            PlayerMapMarker._bScreenMarkConfigSetup = true
            bOK = true
        end
    end)
    return bOK
end

function PlayerMapMarker.GetGameplayData()
    if PlayerMapMarker._CachedGameplayData then return PlayerMapMarker._CachedGameplayData end
    local ok, GDP = pcall(function() return require("GameLua.GameCore.Data.GameplayData") end)
    if ok and GDP then PlayerMapMarker._CachedGameplayData = GDP return GDP end
    return nil
end

function PlayerMapMarker.GetMyPlayerController()
    local PC = PlayerMapMarker._CachedPC
    if PC and IsValid(PC) then return PC end
    local GDP = PlayerMapMarker.GetGameplayData()
    if not GDP then return nil end
    pcall(function() PC = GDP.GetPlayerController and GDP.GetPlayerController() end)
    if PC and IsValid(PC) then PlayerMapMarker._CachedPC = PC return PC end
    return nil
end

function PlayerMapMarker.GetCGameState()
    if CGameState and IsValid(CGameState) then return CGameState end
    if PlayerMapMarker._CachedCGameState and IsValid(PlayerMapMarker._CachedCGameState) then return PlayerMapMarker._CachedCGameState end
    local ok, GS = pcall(function() return require("GameLua.GameCore.Data.CGameState") end)
    if ok and GS then PlayerMapMarker._CachedCGameState = GS return GS end
    return nil
end

function PlayerMapMarker.GetAllCharacters()
    local AllChars = {}
    pcall(function()
        local Pawns = Game:GetAllPlayerPawns()
        if Pawns then
            for _, Pawn in pairs(Pawns) do
                if Pawn and slua.isValid(Pawn) then
                    local pKey = nil
                    if Pawn.GetPlayerKey then pKey = Pawn:GetPlayerKey() end
                    if not pKey and Pawn.PlayerKey then pKey = Pawn.PlayerKey end
                    if not pKey and Pawn.PlayerState and Pawn.PlayerState.PlayerKey then pKey = Pawn.PlayerState.PlayerKey end
                    if pKey then AllChars[pKey] = Pawn end
                end
            end
        end
    end)
    if not next(AllChars) then
        local GS = PlayerMapMarker.GetCGameState()
        if GS and GS.GetAllCharacters then pcall(function() AllChars = GS:GetAllCharacters() end) end
    end
    return AllChars
end

function PlayerMapMarker.GetMyPlayerKey()
    local PC = PlayerMapMarker.GetMyPlayerController()
    if not IsValid(PC) then return nil end
    local MyKey = nil
    pcall(function()
        if PC.GetPlayerKey then MyKey = PC:GetPlayerKey()
        elseif PC.PlayerState and PC.PlayerState.PlayerKey then MyKey = PC.PlayerState.PlayerKey end
    end)
    return MyKey
end

function PlayerMapMarker.IsMe(Character, PlayerKey, MyKey)
    local bIsMe = false
    pcall(function()
        local GDP = PlayerMapMarker.GetGameplayData()
        if GDP and GDP.GetLocalCharacter then
            local MyChar = GDP.GetLocalCharacter()
            if MyChar and Character == MyChar then bIsMe = true return end
        end
        local PC = PlayerMapMarker.GetMyPlayerController()
        if PC and PC.GetPawn then
            local Pawn = PC:GetPawn()
            if Pawn and Character == Pawn then bIsMe = true return end
        end
    end)
    if not bIsMe and MyKey ~= nil and PlayerKey ~= nil then bIsMe = (tostring(PlayerKey) == tostring(MyKey)) end
    return bIsMe
end

function PlayerMapMarker.GetCharacterLocation(Character)
    if not IsValid(Character) then return nil end
    local Loc = nil
    pcall(function() if Character.K2_GetActorLocation then Loc = Character:K2_GetActorLocation() end end)
    if not Loc then pcall(function() if Game and Game.GetActorLocation then Loc = Game:GetActorLocation(Character) end end) end
    return Loc
end

function PlayerMapMarker.CalcDistance(Loc1, Loc2)
    if not Loc1 or not Loc2 then return nil end
    local Dist = nil
    pcall(function() if FVector and FVector.Dist2D then Dist = FVector.Dist2D(Loc1, Loc2) end end)
    if not Dist then
        pcall(function()
            local DX = (Loc1.X or 0) - (Loc2.X or 0)
            local DY = (Loc1.Y or 0) - (Loc2.Y or 0)
            Dist = math.sqrt(DX * DX + DY * DY)
        end)
    end
    return Dist
end

function PlayerMapMarker.GetDistanceString(MyLoc, TargetLoc)
    if not PlayerMapMarker.bShowDistance then return "" end
    if not MyLoc or not TargetLoc then return "" end
    local Dist = PlayerMapMarker.CalcDistance(MyLoc, TargetLoc)
    if not Dist then return "" end
    local Meters = Dist / 100
    if Meters < 1000 then return string.format("%dm", math.floor(Meters))
    else return string.format("%.1fkm", Meters / 1000) end
end

function PlayerMapMarker.GetMyLocation()
    local GDP = PlayerMapMarker.GetGameplayData()
    if not GDP then return nil end
    local MyChar = nil
    pcall(function() MyChar = GDP.GetLocalCharacter and GDP.GetLocalCharacter() end)
    if not IsValid(MyChar) then
        local PC = PlayerMapMarker.GetMyPlayerController()
        if IsValid(PC) then
            pcall(function()
                if PC.GetPawn then
                    local Pawn = PC:GetPawn()
                    if IsValid(Pawn) and Pawn.K2_GetActorLocation then return Pawn:K2_GetActorLocation() end
                end
            end)
        end
        return nil
    end
    return PlayerMapMarker.GetCharacterLocation(MyChar)
end

function PlayerMapMarker.GetPlayerName(Character)
    if not IsValid(Character) then return "Unknown" end
    local Name = nil
    pcall(function() if Character.GetPlayerNameSafety then Name = Character:GetPlayerNameSafety() end end)
    if not Name then
        pcall(function()
            local PS = nil
            if Character.GetPlayerStateSafety then PS = Character:GetPlayerStateSafety()
            elseif Character.GetPlayerState then PS = Character:GetPlayerState() end
            if IsValid(PS) and PS.GetPlayerName then Name = PS:GetPlayerName() end
        end)
    end
    return Name or "Unknown"
end

function PlayerMapMarker.IsAI(Character)
    local bAI = false
    pcall(function() if Game and Game.IsAI then bAI = Game:IsAI(Character) end end)
    return bAI
end

function PlayerMapMarker.IsAlive(Character)
    local bAlive = true
    pcall(function() if Character.IsAlive then bAlive = Character:IsAlive() end end)
    return bAlive
end

function PlayerMapMarker.IsOurESPWidget(w)
    if not w or not slua.isValid(w) then return false end
    local bIsOurs = false
    pcall(function()
        local wstr = tostring(w)
        for KeyStr, ESPData in pairs(PlayerMapMarker.ESPWidgets) do
            if ESPData and ESPData.Widget and ESPData.Widget.Container then
                local cstr = tostring(ESPData.Widget.Container)
                if cstr == wstr then bIsOurs = true return end
            end
        end
    end)
    if bIsOurs then return true end
    pcall(function()
        if w.GetChildrenCount then
            local n = w:GetChildrenCount()
            for i = 0, n - 1 do
                local child = w:GetChildAt(i)
                if child and slua.isValid(child) then
                    local cstr = tostring(child)
                    if string.find(cstr, "Border") then bIsOurs = true break end
                end
            end
        end
    end)
    if not bIsOurs then
        pcall(function()
            local slot = w.Slot
            if slot and slot.GetPosition then
                local pos = slot:GetPosition()
                if pos and (math.abs(pos.X or 0) > 1 or math.abs(pos.Y or 0) > 1) then bIsOurs = true end
            end
        end)
    end
    return bIsOurs
end

function PlayerMapMarker.ApplyAnchorBasedPosition(Slot, ScreenPos, Canvas)
    if not Slot or not ScreenPos then return false end
    local sx = ScreenPos.X or 0
    local sy = ScreenPos.Y or 0
    local sz = PlayerMapMarker.ESPWidgetSize or (FVector2D and FVector2D(100, 30) or {X=100, Y=30})
    local align = PlayerMapMarker.ESPWidgetAlignment or (FVector2D and FVector2D(0.5, 1.0) or {X=0.5, Y=1.0})

    local canvasW, canvasH = 0, 0
    if PlayerMapMarker._cachedViewportW and PlayerMapMarker._cachedViewportW > 200 then
        canvasW = PlayerMapMarker._cachedViewportW
        canvasH = PlayerMapMarker._cachedViewportH
    end

    if canvasW < 200 then
        pcall(function()
            local PC = PlayerMapMarker.GetMyPlayerController()
            if IsValid(PC) and PC.GetViewportSize then
                local VS = FVector2D and FVector2D(0, 0) or {X=0, Y=0}
                PC:GetViewportSize(VS)
                if VS and VS.X and VS.X > 200 then
                    canvasW = VS.X ; canvasH = VS.Y
                    PlayerMapMarker._cachedViewportW = canvasW ; PlayerMapMarker._cachedViewportH = canvasH
                end
            end
        end)
    end

    if canvasW > 200 and canvasH > 200 then
        local anchorX = (sx + (PlayerMapMarker.ESPAnchorOffsetX or 0)) / canvasW
        local anchorY = (sy + (PlayerMapMarker.ESPAnchorOffsetY or 0)) / canvasH
        anchorX = math.max(0, math.min(1, anchorX))
        anchorY = math.max(0, math.min(1, anchorY))

        local bSuccess = false
        pcall(function()
            local FAnchors = import("Anchors") or import("/Script/SlateCore.Anchors")
            if Slot.SetAnchors and FAnchors then
                local anchors = FAnchors(anchorX, anchorY, anchorX, anchorY)
                if anchors then Slot:SetAnchors(anchors) Slot:SetPosition(FVector2D and FVector2D(0, 0) or {X=0, Y=0}) bSuccess = true end
            end
        end)
        if not bSuccess then
            pcall(function()
                if Slot.SetAnchors then Slot:SetAnchors(anchorX, anchorY, anchorX, anchorY) Slot:SetPosition(FVector2D and FVector2D(0, 0) or {X=0, Y=0}) bSuccess = true end
            end)
        end
        if bSuccess then
            pcall(function() if Slot.SetOffsets and import("Margin") then Slot:SetOffsets(import("Margin")(0, 0, sz.X, sz.Y)) end end)
            pcall(function() Slot:SetSize(sz) end)
            pcall(function() Slot:SetAlignment(align) end)
            pcall(function() if Slot.SetAutoSize then Slot:SetAutoSize(PlayerMapMarker.ESPWidgetAutoSize or true) end end)
            pcall(function() if Slot.SetZOrder then Slot:SetZOrder(PlayerMapMarker.ESPWidgetZOrder or 2) end end)
            return true
        end
    end

    pcall(function()
        Slot:SetPosition(FVector2D and FVector2D(sx, sy) or {X=sx, Y=sy})
        pcall(function() Slot:SetSize(sz) end)
        pcall(function() Slot:SetAlignment(align) end)
        pcall(function() if Slot.SetAutoSize then Slot:SetAutoSize(PlayerMapMarker.ESPWidgetAutoSize or true) end end)
        pcall(function() if Slot.SetZOrder then Slot:SetZOrder(PlayerMapMarker.ESPWidgetZOrder or 2) end end)
    end)
    return false
end

function PlayerMapMarker.InitESPCanvas()
    if PlayerMapMarker.ESPCanvas and Game:IsValid(PlayerMapMarker.ESPCanvas) then return true end
    local ok, InGameUITools = pcall(require, "GameLua.Mod.BaseMod.Common.UI.InGameUITools")
    if not ok or not InGameUITools then return false end
    local MainControlBaseUI = InGameUITools.GetMainControlBaseUI and InGameUITools.GetMainControlBaseUI()
    if not MainControlBaseUI or not Game:IsValid(MainControlBaseUI) then return false end

    local ParentCanvas = nil
    if MainControlBaseUI.CanvasPanel_0 and Game:IsValid(MainControlBaseUI.CanvasPanel_0) then
        ParentCanvas = MainControlBaseUI.CanvasPanel_0
    elseif MainControlBaseUI.CanvasPanel_42 and Game:IsValid(MainControlBaseUI.CanvasPanel_42) then
        ParentCanvas = MainControlBaseUI.CanvasPanel_42
    end

    if not ParentCanvas then return false end
    PlayerMapMarker.ESPCanvas = ParentCanvas

    return true
end

function PlayerMapMarker.FindProgressBarInWidget(WidgetObj, Depth, MaxDepth)
    if not WidgetObj or not slua.isValid(WidgetObj) then return nil end
    Depth = Depth or 0 ; MaxDepth = MaxDepth or 5
    if Depth > MaxDepth then return nil end

    local bIsPB = false
    pcall(function() if WidgetObj.SetPercent and WidgetObj.SetFillColorAndOpacity then bIsPB = true end end)
    if bIsPB then return WidgetObj end

    local nChildren = 0
    pcall(function() if WidgetObj.GetChildrenCount then nChildren = WidgetObj:GetChildrenCount() end end)

    for i = 0, math.max(nChildren - 1, 0) do
        local child = nil
        pcall(function() child = WidgetObj:GetChildAt(i) end)
        if child and slua.isValid(child) then
            local result = PlayerMapMarker.FindProgressBarInWidget(child, Depth + 1, MaxDepth)
            if result then return result end
        end
    end
    return nil
end

function PlayerMapMarker.GetTeamID(Character)
    if not IsValid(Character) then return nil end
    local TeamID = nil
    pcall(function() if Character.GetTeamID then TeamID = Character:GetTeamID() end end)
    if not TeamID then
        pcall(function()
            local PS = nil
            if Character.GetPlayerStateSafety then PS = Character:GetPlayerStateSafety()
            elseif Character.GetPlayerState then PS = Character:GetPlayerState() end
            if IsValid(PS) and PS.GetTeamID then TeamID = PS:GetTeamID()
            elseif IsValid(PS) and PS.TeamID then TeamID = PS.TeamID end
        end)
    end
    if not TeamID then pcall(function() if Character.TeamID then TeamID = Character.TeamID end end) end
    return TeamID
end

function PlayerMapMarker.GetTeamColor(TeamID)
    if TeamID == nil or TeamID == 0 then
        return FLinearColor and FLinearColor(0.2, 0.4, 1.0, 1.0) or {R=50,G=100,B=255,A=255}
    end


    local TeamColors = {
        [1]  = {R=45,  G=90,  B=230, A=255, fR=0.18, fG=0.35, fB=0.90},
        [2]  = {R=70,  G=120, B=255, A=255, fR=0.28, fG=0.47, fB=1.00},
        [3]  = {R=90,  G=70,  B=220, A=255, fR=0.35, fG=0.27, fB=0.86},
        [4]  = {R=120, G=70,  B=255, A=255, fR=0.47, fG=0.27, fB=1.00},
        [5]  = {R=170, G=80,  B=255, A=255, fR=0.67, fG=0.31, fB=1.00},
        [6]  = {R=40,  G=170, B=255, A=255, fR=0.16, fG=0.67, fB=1.00},
        [7]  = {R=80,  G=60,  B=180, A=255, fR=0.31, fG=0.24, fB=0.71},
        [8]  = {R=145, G=55,  B=220, A=255, fR=0.57, fG=0.22, fB=0.86},
        [9]  = {R=110, G=145, B=255, A=255, fR=0.43, fG=0.57, fB=1.00},
        [10] = {R=35,  G=125, B=220, A=255, fR=0.14, fG=0.49, fB=0.86},
        [11] = {R=200, G=120, B=255, A=255, fR=0.78, fG=0.47, fB=1.00},
        [12] = {R=95,  G=105, B=200, A=255, fR=0.37, fG=0.41, fB=0.78},
        [13] = {R=155, G=125, B=255, A=255, fR=0.61, fG=0.49, fB=1.00},
        [14] = {R=55,  G=80,  B=170, A=255, fR=0.22, fG=0.31, fB=0.67},
        [15] = {R=125, G=95,  B=235, A=255, fR=0.49, fG=0.37, fB=0.92}
    }


    local colorIndex = (TeamID % 15)
    if colorIndex == 0 then colorIndex = 15 end

    local c = TeamColors[colorIndex]
    return FLinearColor and FLinearColor(c.fR, c.fG, c.fB, 1.0) or {R=c.R, G=c.G, B=c.B, A=c.A}
end

local _WhiteTexture = nil
local _bWhiteTextureFailed = false
local function GetWhiteTexture()
    if _WhiteTexture then return _WhiteTexture end
    if _bWhiteTextureFailed then return nil end
    pcall(function()
        local paths = { "/Game/BluePrints/UI/Textures/White.White", "/Game/BluePrints/UI/Textures/Common/White.White", "/Engine/EngineResources/WhiteSquareTexture.WhiteSquareTexture" }
        for _, path in ipairs(paths) do
            pcall(function() local tex = import(path); if tex and slua.isValid(tex) then _WhiteTexture = tex return end end)
            if _WhiteTexture then break end
        end
    end)
    if not _WhiteTexture then _bWhiteTextureFailed = true end
    return _WhiteTexture
end

local function SetImageColor(Image, color)
    if not Image or not slua.isValid(Image) then return false end
    local bOK = false
    pcall(function() if Image.SetBrushTintColor then Image:SetBrushTintColor(color); bOK = true end end)
    pcall(function() if Image.SetColorAndOpacity then Image:SetColorAndOpacity(color); bOK = true end end)
    pcall(function()
        if Image.SetBrushFromTexture then
            local whiteTex = GetWhiteTexture()
            if whiteTex then
                Image:SetBrushFromTexture(whiteTex, false)
                if Image.SetColorAndOpacity then Image:SetColorAndOpacity(color) end
                bOK = true
            end
        end
    end)
    pcall(function() Image:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible); Image:SetRenderOpacity(1.0) end)
    return bOK
end

function PlayerMapMarker._GetWidgetRoot(WidgetObj)
    if not WidgetObj or not slua.isValid(WidgetObj) then return nil end
    local Root = nil
    pcall(function() if WidgetObj.GetRootWidget then Root = WidgetObj:GetRootWidget() end end)
    if Root and slua.isValid(Root) then return Root end
    pcall(function() if WidgetObj.WidgetTree and WidgetObj.WidgetTree.RootWidget then Root = WidgetObj.WidgetTree.RootWidget end end)
    if Root and slua.isValid(Root) then return Root end
    pcall(function() if WidgetObj.RootWidget and slua.isValid(WidgetObj.RootWidget) then Root = WidgetObj.RootWidget end end)
    return Root
end

function PlayerMapMarker._FindNamedWidgetInTree(WidgetObj, TargetName, MaxDepth)
    if not WidgetObj or not slua.isValid(WidgetObj) then return nil end
    MaxDepth = MaxDepth or 8
    local wname = nil
    pcall(function() if WidgetObj.GetName then wname = WidgetObj:GetName() end end)
    if wname and wname == TargetName then return WidgetObj end

    local wstr = tostring(WidgetObj)
    if wstr and string.find(wstr, TargetName, 1, true) then
        if wname and wname == TargetName then return WidgetObj
        elseif not wname or wname == "" then
            local _, endPos = string.find(wstr, TargetName, 1, true)
            if endPos then
                local nextChar = string.sub(wstr, endPos + 1, endPos + 1)
                if nextChar ~= "_" and nextChar ~= "" then return WidgetObj end
            end
        end
    end

    local nChildren = 0
    pcall(function() if WidgetObj.GetChildrenCount then nChildren = WidgetObj:GetChildrenCount() end end)

    if nChildren > 0 then
        for i = 0, nChildren - 1 do
            local child = nil
            pcall(function() child = WidgetObj:GetChildAt(i) end)
            if child and slua.isValid(child) then
                local found = PlayerMapMarker._FindNamedWidgetInTree(child, TargetName, MaxDepth - 1)
                if found then return found end
            end
        end
    else
        local Root = PlayerMapMarker._GetWidgetRoot(WidgetObj)
        if Root and slua.isValid(Root) and Root ~= WidgetObj then
            local found = PlayerMapMarker._FindNamedWidgetInTree(Root, TargetName, MaxDepth - 1)
            if found then return found end
        end
    end
    return nil
end

function PlayerMapMarker.ApplyTeamColor(Widget, TeamID)
    if not Widget or not Widget.Container then return end


    if not _G.LexusConfig.Esp9_Team then
        pcall(function()
            local W = Widget.Container
            if W and slua.isValid(W) then
                local img1 = PlayerMapMarker._FindNamedWidgetInTree(W, "Image_TeamBG", 8)
                if img1 and slua.isValid(img1) then img1:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
                local img2 = PlayerMapMarker._FindNamedWidgetInTree(W, "Image_TeamLogoBG", 8)
                if img2 and slua.isValid(img2) then img2:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
                if Widget.TeamBgBorder and slua.isValid(Widget.TeamBgBorder) then Widget.TeamBgBorder:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
            end
        end)
        return
    end

    local color = PlayerMapMarker.GetTeamColor(TeamID)
    if not color then return end

    pcall(function()
        local W = Widget.Container
        if not W or not slua.isValid(W) then return end

        local bBG = false
        local Image_TeamBG = PlayerMapMarker._FindNamedWidgetInTree(W, "Image_TeamBG", 8)
        if Image_TeamBG and slua.isValid(Image_TeamBG) then bBG = SetImageColor(Image_TeamBG, color) end

        local Image_TeamLogoBG = PlayerMapMarker._FindNamedWidgetInTree(W, "Image_TeamLogoBG", 8)
        if Image_TeamLogoBG and slua.isValid(Image_TeamLogoBG) then SetImageColor(Image_TeamLogoBG, color) end

        if W.SetTeamColor then pcall(function() W:SetTeamColor(TeamID) end) end

        if not Widget.TeamBgBorder or not slua.isValid(Widget.TeamBgBorder) then
            pcall(function()
                local Border = CGame:NewObjectFromPath("/Script/UMG.Border", W)
                if Border and slua.isValid(Border) then
                    pcall(function() Border:SetBrushColor(color) end)
                    pcall(function() Border:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
                    pcall(function() Border:SetRenderOpacity(0.7) end)
                    pcall(function() Border:SetDesiredSizeOverride(FVector2D and FVector2D(120, 20) or {X=120, Y=20}) end)
                    pcall(function() if W.AddChild then W:AddChild(Border) end end)
                    pcall(function() if Border.SetZOrder then Border:SetZOrder(-1) end end)
                    Widget.TeamBgBorder = Border
                end
            end)
        else
            pcall(function()
                Widget.TeamBgBorder:SetBrushColor(color)
                Widget.TeamBgBorder:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                Widget.TeamBgBorder:SetRenderOpacity(0.7)
            end)
        end
    end)
end

function PlayerMapMarker.GetCharacterMesh(Character)
    if not IsValid(Character) then return nil end
    local Mesh = nil
    pcall(function() if Character.Mesh and Game:IsValid(Character.Mesh) then Mesh = Character.Mesh end end)
    if not Mesh then pcall(function() local SkeletalMeshCompClass = import("/Script/Engine.SkeletalMeshComponent") Mesh = Character:GetComponentByClass(SkeletalMeshCompClass) end) end
    return Mesh
end

function PlayerMapMarker.GetESPLocation(Character)
    if not IsValid(Character) then return nil end
    local BoneLoc = PlayerMapMarker.GetCharacterLocation(Character)
    if BoneLoc then
        local heightOffset = 85
        pcall(function()
            if Character.bIsCrouched then heightOffset = 60 end
            if Character.IsProne and Character:IsProne() then heightOffset = 30 end
        end)
        pcall(function() BoneLoc.Z = BoneLoc.Z + heightOffset + (PlayerMapMarker.ESPWorldOffsetZ or 0) end)
    end
    return BoneLoc
end

function PlayerMapMarker.GetCharacterWeaponInfo(Character)
    if not IsValid(Character) then return nil end
    local WeaponID, WeaponName, WeaponIconPath, WeaponIconTexture, CurrentWeapon = nil, nil, nil, nil, nil

    pcall(function() if Character.GetCurrentWeapon then CurrentWeapon = Character:GetCurrentWeapon() end end)
    if not CurrentWeapon then pcall(function() CurrentWeapon = Character.CurrentWeapon end) end
    if not CurrentWeapon then pcall(function() if Character.GetWeaponManager then local WM = Character:GetWeaponManager() if WM and WM.GetCurrentWeapon then CurrentWeapon = WM:GetCurrentWeapon() end end end) end

    if CurrentWeapon and IsValid(CurrentWeapon) then
        pcall(function() if CurrentWeapon.GetWeaponID then WeaponID = CurrentWeapon:GetWeaponID() end end)
        if not WeaponID then pcall(function() WeaponID = CurrentWeapon.WeaponID end) end
        if not WeaponID then pcall(function() if CurrentWeapon.GetItemID then WeaponID = CurrentWeapon:GetItemID() end end) end
        pcall(function() if CurrentWeapon.GetWeaponName then WeaponName = CurrentWeapon:GetWeaponName() end end)
        pcall(function() if CurrentWeapon.GetWeaponIconPath then WeaponIconPath = CurrentWeapon:GetWeaponIconPath() end end)
        pcall(function() if CurrentWeapon.GetWeaponIcon then WeaponIconTexture = CurrentWeapon:GetWeaponIcon() end end)
    end

    if not WeaponID then
        pcall(function()
            local PS = nil
            if Character.GetPlayerStateSafety then PS = Character:GetPlayerStateSafety() elseif Character.GetPlayerState then PS = Character:GetPlayerState() end
            if PS and IsValid(PS) then
                if PS.GetCurrentWeaponID then WeaponID = PS:GetCurrentWeaponID() end
                if not WeaponID and PS.CurWeaponID then WeaponID = PS.CurWeaponID end
            end
        end)
    end
    return { WeaponID = WeaponID, WeaponName = WeaponName, WeaponIconPath = WeaponIconPath, WeaponIconTexture = WeaponIconTexture, CurrentWeapon = CurrentWeapon }
end

function PlayerMapMarker.FindWeaponIconInWidget(WidgetObj, Depth, MaxDepth)
    if not WidgetObj or not slua.isValid(WidgetObj) then return nil end
    Depth = Depth or 0 ; MaxDepth = MaxDepth or 8
    local propNames = { "Image_Weapon", "Image_WeaponIcon", "Image_Gun", "Image_Icon", "WeaponIcon", "WeaponImage", "Image_Equip" }
    for _, pname in ipairs(propNames) do
        pcall(function()
            local prop = WidgetObj[pname]
            if prop and slua.isValid(prop) then
                local hasBrush = false
                pcall(function() if prop.Brush then hasBrush = true end end)
                if hasBrush then return prop end
            end
        end)
    end
    if Depth >= MaxDepth then return nil end
    local nChildren = 0
    pcall(function() if WidgetObj.GetChildrenCount then nChildren = WidgetObj:GetChildrenCount() end end)
    for i = 0, math.max(nChildren - 1, 0) do
        local child = nil
        pcall(function() child = WidgetObj:GetChildAt(i) end)
        if child and slua.isValid(child) then
            local result = PlayerMapMarker.FindWeaponIconInWidget(child, Depth + 1, MaxDepth)
            if result then return result end
        end
    end
    if nChildren == 0 then
        local Root = PlayerMapMarker._GetWidgetRoot(WidgetObj)
        if Root and slua.isValid(Root) and Root ~= WidgetObj then
            local result = PlayerMapMarker.FindWeaponIconInWidget(Root, Depth + 1, MaxDepth)
            if result then return result end
        end
    end
    return nil
end

function PlayerMapMarker.FixWeaponIconBrushSize(ImageWidget, DefaultW, DefaultH)
    if not ImageWidget or not slua.isValid(ImageWidget) then return end
    DefaultW = DefaultW or 138 ; DefaultH = DefaultH or 69
    pcall(function()
        local brush = ImageWidget.Brush
        if brush then
            brush.ImageSize = FVector2D and FVector2D(DefaultW, DefaultH) or {X=DefaultW, Y=DefaultH}
            brush.DrawAs = 3
            brush.TintColor = FLinearColor and FLinearColor(1.0, 1.0, 1.0, 1.0) or {R=1,G=1,B=1,A=1}
            if ImageWidget.SetBrush then ImageWidget:SetBrush(brush) end
        end
        if ImageWidget.SetDesiredSizeOverride then ImageWidget:SetDesiredSizeOverride(FVector2D and FVector2D(DefaultW, DefaultH) or {X=DefaultW, Y=DefaultH}) end
        local slot = ImageWidget.Slot
        if slot and slot.SetSize then slot:SetSize(FVector2D and FVector2D(DefaultW, DefaultH) or {X=DefaultW, Y=DefaultH}) end
        ImageWidget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        ImageWidget:SetRenderOpacity(1.0)
        ImageWidget:SetColorAndOpacity(FLinearColor and FLinearColor(1.0, 1.0, 1.0, 1.0) or {R=1,G=1,B=1,A=1})
    end)
end

function PlayerMapMarker.ApplyWeaponIconFullOpacity(Container, ourWeaponIcon)
    local fullIcon = FLinearColor and FLinearColor(1.0, 1.0, 1.0, 1.0) or {R=1,G=1,B=1,A=1}
    if not ourWeaponIcon or not slua.isValid(ourWeaponIcon) then return end
    pcall(function() if ourWeaponIcon.SetRenderOpacity then ourWeaponIcon:SetRenderOpacity(1.0) end end)
    pcall(function() if ourWeaponIcon.SetColorAndOpacity then ourWeaponIcon:SetColorAndOpacity(fullIcon) end end)
    pcall(function()
        local brush = ourWeaponIcon.Brush
        if brush then pcall(function() brush.TintColor = fullIcon end) if ourWeaponIcon.SetBrush then ourWeaponIcon:SetBrush(brush) end end
    end)
    local chainNames = {"Border_WeaponColor", "Border_Weapon", "Border_WeaponIcon", "SizeBox_Weapon", "ScaleBox_Weapon", "Switcher_WeaponIcon"}
    for _, pname in ipairs(chainNames) do
        pcall(function()
            local node = Container and Container[pname]
            if node and slua.isValid(node) and node.SetRenderOpacity then node:SetRenderOpacity(1.0) end
            if node and slua.isValid(node) and node.SetColorAndOpacity then node:SetColorAndOpacity(fullIcon) end
        end)
    end
end

function PlayerMapMarker.ApplyWeaponIconToImage(ImageWidget, winfo)
    if not ImageWidget or not slua.isValid(ImageWidget) then return false, "no_widget" end
    if not winfo or not winfo.WeaponID then return false, "no_weapon_id" end

    local iconPath = nil
    local method = "none"
    local bHasAddKnownMissing = false
    local defaultW = 138
    local defaultH = 69

    pcall(function()
        local itemRecord = CDataTable.GetTableData("Item", winfo.WeaponID)
        if itemRecord and itemRecord.KillWhiteIcon and itemRecord.KillWhiteIcon ~= "" then iconPath = itemRecord.KillWhiteIcon method = "KillWhiteIcon" end
        if (not iconPath or iconPath == "") and winfo.WeaponIconPath and winfo.WeaponIconPath ~= "" then iconPath = winfo.WeaponIconPath method = "WeaponIconPath" end
        if (not iconPath or iconPath == "") and winfo.WeaponIconTexture and slua.isValid(winfo.WeaponIconTexture) then
            if ImageWidget.SetBrushFromTexture then ImageWidget:SetBrushFromTexture(winfo.WeaponIconTexture, true) method = "WeaponIconTexture" return end
        end
        if not iconPath or iconPath == "" then
            local UIUtil = require("client.common.ui_util")
            iconPath, bHasAddKnownMissing = UIUtil.GetItemBigIcon(winfo.WeaponID, ImageWidget)
            if iconPath and iconPath ~= "" then method = "GetItemBigIcon" end
        end
        if not iconPath or iconPath == "" then
            local UIUtil = require("client.common.ui_util")
            iconPath = UIUtil.GetItemSmallIcon(winfo.WeaponID, ImageWidget, bHasAddKnownMissing)
            if iconPath and iconPath ~= "" then method = "GetItemSmallIcon" end
        end
    end)

    if method == "WeaponIconTexture" then PlayerMapMarker.FixWeaponIconBrushSize(ImageWidget, defaultW, defaultH) return true, method end
    if not iconPath or iconPath == "" then return false, "no_path" end

    local bOK = false
    pcall(function()
        if ImageWidget.SetBrushResourceFromPathSync then ImageWidget:SetBrushResourceFromPathSync(iconPath, true) bOK = true end
        if not bOK then
            local util = require("client.slua_ui_framework.util")
            local result = util.SetTexture(ImageWidget, iconPath, { sync = true, bMatchSize = true, bIsInCombatState = true, bHasAddKnownMissing = bHasAddKnownMissing })
            bOK = result ~= nil
        end
        if not bOK then
            local tex = import(iconPath)
            if tex and slua.isValid(tex) and ImageWidget.SetBrushFromTexture then ImageWidget:SetBrushFromTexture(tex, true) bOK = true end
        end
        if not bOK then
            local LoadObject = import("LoadObject")
            if LoadObject then
                local tex = LoadObject(iconPath)
                if tex and slua.isValid(tex) and ImageWidget.SetBrushFromTexture then ImageWidget:SetBrushFromTexture(tex, true) bOK = true end
            end
        end
    end)

    if bOK then PlayerMapMarker.FixWeaponIconBrushSize(ImageWidget, defaultW, defaultH) end
    return bOK, method .. ":" .. tostring(iconPath)
end

function PlayerMapMarker.CopyWeaponIconBrushFromNative(ourWeaponIcon, nativeWeaponIcon)
    if not ourWeaponIcon or not slua.isValid(ourWeaponIcon) then return false end
    if not nativeWeaponIcon or not slua.isValid(nativeWeaponIcon) then return false end

    local bCopied = false
    pcall(function()
        local nBrush = nativeWeaponIcon.Brush
        if nBrush then
            local resObj = nil
            pcall(function() resObj = nBrush.ResourceObject end)
            if resObj and slua.isValid(resObj) and ourWeaponIcon.SetBrushFromTexture then
                ourWeaponIcon:SetBrushFromTexture(resObj, true)
                bCopied = true
            end
            if bCopied then
                local imgSize = nil
                pcall(function() imgSize = nBrush.ImageSize end)
                if imgSize then
                    local oBrush = ourWeaponIcon.Brush
                    if oBrush then oBrush.ImageSize = imgSize if ourWeaponIcon.SetBrush then ourWeaponIcon:SetBrush(oBrush) end end
                end
            end
        end
    end)
    return bCopied
end

function PlayerMapMarker.AddWeaponIconToESP(WidgetData, Character)
    if not WidgetData or not WidgetData.Container then return end
    local Container = WidgetData.Container
    if not slua.isValid(Container) then return end


    if not _G.LexusConfig.Esp9_Weapon then
        pcall(function()
            local chainNames = {"Border_WeaponColor", "Border_Weapon", "Border_WeaponIcon", "SizeBox_Weapon", "ScaleBox_Weapon", "Switcher_WeaponIcon"}
            for _, pname in ipairs(chainNames) do
                local node = Container[pname]
                if node and slua.isValid(node) and node.SetWidgetVisibility then node:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
            end
            local ourWeaponIcon = Container.WeaponIcon or PlayerMapMarker.FindWeaponIconInWidget(Container, 0, 8)
            if ourWeaponIcon and slua.isValid(ourWeaponIcon) then ourWeaponIcon:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
        end)
        WidgetData._LastWeaponID = 0
        WidgetData._WeaponIconApplied = false
        return
    end

    pcall(function()
        local ourWeaponIcon = Container.WeaponIcon
        if not ourWeaponIcon or not slua.isValid(ourWeaponIcon) then ourWeaponIcon = PlayerMapMarker.FindWeaponIconInWidget(Container, 0, 8) end
        if not ourWeaponIcon or not slua.isValid(ourWeaponIcon) then return end

        local winfo = Character and PlayerMapMarker.GetCharacterWeaponInfo(Character) or nil

        if not winfo or not winfo.WeaponID or winfo.WeaponID == 0 then
            pcall(function() ourWeaponIcon:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
            local chainNames = {"Border_WeaponColor", "Border_Weapon", "Border_WeaponIcon", "SizeBox_Weapon", "ScaleBox_Weapon", "Switcher_WeaponIcon"}
            for _, pname in ipairs(chainNames) do
                pcall(function()
                    local node = Container and Container[pname]
                    if node and slua.isValid(node) and node.SetWidgetVisibility then node:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
                end)
            end
            WidgetData._LastWeaponID = 0
            WidgetData._WeaponIconApplied = false
            return
        end

        if WidgetData._LastWeaponID == winfo.WeaponID and WidgetData._WeaponIconApplied then
            pcall(function() ourWeaponIcon:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
            pcall(function() ourWeaponIcon:SetRenderOpacity(1.0) end)
            local chainNames = {"Border_WeaponColor", "Border_Weapon", "Border_WeaponIcon", "SizeBox_Weapon", "ScaleBox_Weapon", "Switcher_WeaponIcon"}
            for _, pname in ipairs(chainNames) do
                pcall(function()
                    local node = Container and Container[pname]
                    if node and slua.isValid(node) and node.SetWidgetVisibility then
                        node:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                        pcall(function() if node.SetRenderOpacity then node:SetRenderOpacity(1.0) end end)
                    end
                end)
            end
            if WidgetData._CachedSwitcherIndexes then
                for sName, idx in pairs(WidgetData._CachedSwitcherIndexes) do
                    pcall(function()
                        local ws = Container[sName]
                        if ws and slua.isValid(ws) and ws.SetActiveWidgetIndex then ws:SetActiveWidgetIndex(idx) end
                    end)
                end
            end
            if WidgetData._CachedParentSwitchers then
                for _, data in pairs(WidgetData._CachedParentSwitchers) do
                    pcall(function() if data.w and slua.isValid(data.w) and data.w.SetActiveWidgetIndex then data.w:SetActiveWidgetIndex(data.idx) end end)
                end
            end
            return
        end

        local chainNames = {"Border_WeaponColor", "Border_Weapon", "Border_WeaponIcon", "SizeBox_Weapon", "ScaleBox_Weapon", "Switcher_WeaponIcon"}
        for _, pname in ipairs(chainNames) do
            pcall(function()
                local node = Container and Container[pname]
                if node and slua.isValid(node) and node.SetWidgetVisibility then node:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end
            end)
        end

        local bCopied = false
        if winfo and winfo.WeaponID then
            local ok, method = PlayerMapMarker.ApplyWeaponIconToImage(ourWeaponIcon, winfo)
            if ok then bCopied = true end
        end

        local bWeaponIconSet = false
        if Character and winfo then
            if winfo and winfo.WeaponID then
                pcall(function() if Container.SetWeaponIcon then Container:SetWeaponIcon(winfo.WeaponID) bWeaponIconSet = true end end)
                if not bWeaponIconSet then pcall(function() if Container.SetWeaponIconByID then Container:SetWeaponIconByID(winfo.WeaponID) bWeaponIconSet = true end end) end
                if not bWeaponIconSet then pcall(function() if Container.UpdateWeaponIcon then Container:UpdateWeaponIcon(winfo.WeaponID) bWeaponIconSet = true end end) end
                if not bWeaponIconSet then pcall(function() if Container.SetWeaponID then Container:SetWeaponID(winfo.WeaponID) bWeaponIconSet = true end end) end
                pcall(function() if Container.SetData then Container:SetData(Character) end end)
                pcall(function() if Container.SetPlayerInfo then Container:SetPlayerInfo(Character) end end)
                if winfo.CurrentWeapon then pcall(function() if Container.SetCurrentWeapon then Container:SetCurrentWeapon(winfo.CurrentWeapon) end end) end
            end
        end

        if bWeaponIconSet then
            pcall(function()
                local innerIcon = Container.Image_Icon
                if not innerIcon or not slua.isValid(innerIcon) then if Container.CanvasPanel_Type1 then innerIcon = Container.CanvasPanel_Type1.Image_Icon end end
                if not innerIcon or not slua.isValid(innerIcon) then
                    local function findImageIcon(w, depth)
                        if not w or not slua.isValid(w) or depth > 8 then return nil end
                        local prop = w.Image_Icon
                        if prop and slua.isValid(prop) then return prop end
                        local n = 0
                        pcall(function() if w.GetChildrenCount then n = w:GetChildrenCount() end end)
                        for i = 0, math.max(n - 1, 0) do
                            local c = nil
                            pcall(function() c = w:GetChildAt(i) end)
                            if c then local r = findImageIcon(c, depth + 1) if r then return r end end
                        end
                        return nil
                    end
                    innerIcon = findImageIcon(Container, 0)
                end
                if innerIcon and slua.isValid(innerIcon) and innerIcon ~= ourWeaponIcon then
                    pcall(function()
                        local ibrush = innerIcon.Brush
                        if ibrush then
                            local iresObj = nil
                            pcall(function() iresObj = ibrush.ResourceObject end)
                            if iresObj and slua.isValid(iresObj) then
                                if ourWeaponIcon.SetBrushFromAsset then ourWeaponIcon:SetBrushFromAsset(iresObj) bCopied = true end
                                if not bCopied and ourWeaponIcon.SetBrushFromTexture then ourWeaponIcon:SetBrushFromTexture(iresObj) bCopied = true end
                            end
                        end
                    end)
                    if not bCopied then
                        pcall(function()
                            local brush = innerIcon.Brush
                            if brush then
                                local iresObj = nil
                                pcall(function() iresObj = brush.ResourceObject end)
                                if iresObj and slua.isValid(iresObj) and ourWeaponIcon.SetBrushFromTexture then
                                    ourWeaponIcon:SetBrushFromTexture(iresObj, false)
                                    PlayerMapMarker.FixWeaponIconBrushSize(ourWeaponIcon)
                                    bCopied = true
                                end
                            end
                        end)
                    end
                end
            end)
        end

        if not bCopied then
            local nativeWeaponIcon = nil
            if PlayerMapMarker.ESPCanvas and Game:IsValid(PlayerMapMarker.ESPCanvas) then
                local nChildren = 0
                pcall(function() nChildren = PlayerMapMarker.ESPCanvas:GetChildrenCount() end)
                for i = 0, math.max(nChildren - 1, 0) do
                    local child = nil
                    pcall(function() child = PlayerMapMarker.ESPCanvas:GetChildAt(i) end)
                    if child and slua.isValid(child) then
                        local cstr = tostring(child)
                        if string.find(cstr, "OB_PlayerHeadHPItem") then
                            if not PlayerMapMarker.IsOurESPWidget(child) then
                                local nativeIcon = child.WeaponIcon
                                if nativeIcon and slua.isValid(nativeIcon) then nativeWeaponIcon = nativeIcon break end
                            end
                        end
                    end
                end
            end

            if nativeWeaponIcon and slua.isValid(nativeWeaponIcon) then
                local okNative, nativeMethod = PlayerMapMarker.CopyWeaponIconBrushFromNative(ourWeaponIcon, nativeWeaponIcon)
                if okNative then bCopied = true end
            end
        end

        if not bCopied then
            pcall(function()
                local brush = ourWeaponIcon.Brush
                if brush then
                    local resObj = nil
                    pcall(function() resObj = brush.ResourceObject end)
                    if resObj and slua.isValid(resObj) and ourWeaponIcon.SetBrushFromTexture then
                        ourWeaponIcon:SetBrushFromTexture(resObj)
                        bCopied = true
                    end
                end
            end)
        end

        if not bCopied then
            pcall(function()
                local brush = ourWeaponIcon.Brush
                if brush then
                    local imgSize = nil
                    pcall(function() imgSize = brush.ImageSize end)
                    local bZeroSize = false
                    if imgSize then
                        local sx, sy = nil, nil
                        pcall(function() sx = imgSize.X end)
                        pcall(function() sy = imgSize.Y end)
                        if (not sx or sx == 0) and (not sy or sy == 0) then bZeroSize = true end
                    end
                    if bZeroSize then
                        pcall(function() brush.ImageSize = FVector2D and FVector2D(PlayerMapMarker.WeaponIconBrushW or 138, PlayerMapMarker.WeaponIconBrushH or 69) or {X=138, Y=69} end)
                    end
                    pcall(function() brush.DrawAs = 3 end)
                    if ourWeaponIcon.SetBrush then ourWeaponIcon:SetBrush(brush) end
                end
            end)
        end

        pcall(function() ourWeaponIcon:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
        PlayerMapMarker.ApplyWeaponIconFullOpacity(Container, ourWeaponIcon)
        PlayerMapMarker.FixWeaponIconBrushSize(ourWeaponIcon)

        pcall(function()
            local function findWidgetInSwitcher(switcher, targetWidget)
                if not switcher or not slua.isValid(switcher) then return nil end
                if not switcher.GetChildrenCount or not switcher.GetChildAt then return nil end
                local nChildren = switcher:GetChildrenCount()
                for i = 0, math.max(nChildren - 1, 0) do
                    local child = switcher:GetChildAt(i)
                    if child and slua.isValid(child) then
                        if child == targetWidget then return i end
                        local function searchDescendant(w, target, depth)
                            if depth > 5 then return false end
                            if w == target then return true end
                            if not w.GetChildrenCount or not w.GetChildAt then return false end
                            local nc = w:GetChildrenCount()
                            for j = 0, math.max(nc - 1, 0) do
                                local c = w:GetChildAt(j)
                                if c and slua.isValid(c) and searchDescendant(c, target, depth + 1) then return true end
                            end
                            return false
                        end
                        if searchDescendant(child, targetWidget, 0) then return i end
                    end
                end
                return nil
            end

            for _, switcherName in ipairs({"Switcher_WeaponIcon", "WidgetSwitcher_Type", "WidgetSwitcher_Type2"}) do
                local ws = Container[switcherName]
                if ws and slua.isValid(ws) and ws.GetChildrenCount and ws.GetChildAt then
                    local foundIdx = findWidgetInSwitcher(ws, ourWeaponIcon)
                    if foundIdx then
                        if ws.SetActiveWidgetIndex then
                            ws:SetActiveWidgetIndex(foundIdx)
                            WidgetData._CachedSwitcherIndexes = WidgetData._CachedSwitcherIndexes or {}
                            WidgetData._CachedSwitcherIndexes[switcherName] = foundIdx
                        end
                    end
                end
            end
        end)

        pcall(function()
            local parent = ourWeaponIcon
            for depth = 0, 8 do
                if not parent or not slua.isValid(parent) then break end
                if parent.GetParent then
                    local p = parent:GetParent()
                    if p and slua.isValid(p) then
                        local pStr = tostring(p)
                        if string.find(pStr, "WidgetSwitcher") then
                            if p.GetChildrenCount and p.GetChildAt then
                                local nCh = p:GetChildrenCount()
                                for i = 0, math.max(nCh - 1, 0) do
                                    local child = p:GetChildAt(i)
                                    if child and slua.isValid(child) then
                                        local function isDescendant(w, target, d)
                                            if d > 5 then return false end
                                            if w == target then return true end
                                            if not w.GetChildrenCount or not w.GetChildAt then return false end
                                            local nc = w:GetChildrenCount()
                                            for j = 0, math.max(nc - 1, 0) do
                                                local c = w:GetChildAt(j)
                                                if c and slua.isValid(c) and isDescendant(c, target, d + 1) then return true end
                                            end
                                            return false
                                        end
                                        if isDescendant(child, ourWeaponIcon, 0) then
                                            if p.SetActiveWidgetIndex then
                                                p:SetActiveWidgetIndex(i)
                                                WidgetData._CachedParentSwitchers = WidgetData._CachedParentSwitchers or {}
                                                WidgetData._CachedParentSwitchers[tostring(p)] = {w = p, idx = i}
                                            end
                                            break
                                        end
                                    end
                                end
                            end
                        end
                        parent = p
                    else
                        break
                    end
                else
                    break
                end
            end
        end)

        pcall(function()
            local parent = ourWeaponIcon
            for depth = 0, 8 do
                pcall(function()
                    if parent.GetParent then
                        local p = parent:GetParent()
                        if p and slua.isValid(p) then
                            if p.SetWidgetVisibility then p:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end
                            pcall(function() if p.SetRenderOpacity then p:SetRenderOpacity(1.0) end end)
                            pcall(function() if p.SetContentColorAndOpacity then p:SetContentColorAndOpacity(FLinearColor and FLinearColor(1.0, 1.0, 1.0, 1.0) or {R=1,G=1,B=1,A=1}) end end)
                            pcall(function() if p.SetColorAndOpacity then p:SetColorAndOpacity(FLinearColor and FLinearColor(1.0, 1.0, 1.0, 1.0) or {R=1,G=1,B=1,A=1}) end end)
                            pcall(function() if p.SetBrushTintColor then p:SetBrushTintColor(FLinearColor and FLinearColor(1.0, 1.0, 1.0, 1.0) or {R=1,G=1,B=1,A=1}) end end)
                            pcall(function()
                                local pBrush = p.Brush
                                if pBrush and pBrush.TintColor then
                                    pBrush.TintColor = FLinearColor and FLinearColor(1.0, 1.0, 1.0, 1.0) or {R=1,G=1,B=1,A=1}
                                    if p.SetBrush then p:SetBrush(pBrush) end
                                end
                            end)
                            pcall(function() if p.InvalidateLayout then p:InvalidateLayout() end end)
                            parent = p
                        end
                    end
                end)
            end
        end)
        pcall(function() if ourWeaponIcon.InvalidateLayout then ourWeaponIcon:InvalidateLayout() end end)

        pcall(function() if Container.UpdateWeapon then Container:UpdateWeapon() end end)
        pcall(function() if Container.RefreshWeapon then Container:RefreshWeapon() end end)

        WidgetData._LastWeaponID = winfo.WeaponID
        WidgetData._WeaponIconApplied = true
    end)
end

PlayerMapMarker._OBHeadWidgetClass = nil
PlayerMapMarker._OBHeadWidgetLoadFailed = false
PlayerMapMarker._bDumpedWidgetChildren = false

function PlayerMapMarker.CreateESPWidget()
    if not PlayerMapMarker.ESPCanvas or not Game:IsValid(PlayerMapMarker.ESPCanvas) then return nil end
    if PlayerMapMarker._OBHeadWidgetLoadFailed then return nil end

    if not PlayerMapMarker._OBHeadWidgetClass then
        pcall(function()
            local Path = "/Game/BluePrints/UI/OBUI/Item/OB_PlayerHeadHPItem_UIBP.OB_PlayerHeadHPItem_UIBP"
            local uClass = slua.loadClass(Path)
            if uClass then PlayerMapMarker._OBHeadWidgetClass = uClass end
        end)
        if not PlayerMapMarker._OBHeadWidgetClass then
            PlayerMapMarker._OBHeadWidgetLoadFailed = true
            return nil
        end
    else
        local bValid = false
        pcall(function() bValid = slua.isValid(PlayerMapMarker._OBHeadWidgetClass) end)
        if not bValid then
            PlayerMapMarker._OBHeadWidgetLoadFailed = true
            PlayerMapMarker._OBHeadWidgetClass = nil
            return nil
        end
    end

    local Widget = nil
    pcall(function()
        local STExtraBlueprintFunctionLibrary = import("STExtraBlueprintFunctionLibrary")
        local PC = PlayerMapMarker.GetMyPlayerController()
        local OuterObj = IsValid(PC) and PC.Object or PlayerMapMarker.ESPCanvas
        Widget = STExtraBlueprintFunctionLibrary.CreateWidgetByClass(PlayerMapMarker._OBHeadWidgetClass, OuterObj)
    end)

    if not Widget then return nil end

    pcall(function() Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
    pcall(function() Widget:SetRenderOpacity(1.0) end)

    local NameText = nil
    local HealthFill = nil
    local bIsOriginalProgressBar = false

    pcall(function()
        NameText = Widget.TextBlock_TeamName
        if NameText and slua.isValid(NameText) then pcall(function() NameText:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end) end
        if Widget.TextBlock_PlayerName and slua.isValid(Widget.TextBlock_PlayerName) then pcall(function() Widget.TextBlock_PlayerName:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end) end

        local WS_Type = Widget.WidgetSwitcher_Type
        local WS_Type2 = Widget.WidgetSwitcher_Type2
        if WS_Type and slua.isValid(WS_Type) then pcall(function() if WS_Type.SetActiveWidgetIndex then WS_Type:SetActiveWidgetIndex(PlayerMapMarker.HPWidgetSwitcherTypeIndex) end end) end
        if WS_Type2 and slua.isValid(WS_Type2) then pcall(function() if WS_Type2.SetActiveWidgetIndex then WS_Type2:SetActiveWidgetIndex(PlayerMapMarker.HPWidgetSwitcherType2Index) end end) end

        local SizeBox_HP = Widget.SizeBox_HP
        if SizeBox_HP and slua.isValid(SizeBox_HP) then
            pcall(function() SizeBox_HP:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
            pcall(function() SizeBox_HP:SetHeightOverride(6) end)
            pcall(function() SizeBox_HP:SetWidthOverride(100) end)

            local ExistingChild = nil
            pcall(function() if SizeBox_HP.GetContent then ExistingChild = SizeBox_HP:GetContent() end end)
            if not ExistingChild then pcall(function() if SizeBox_HP.GetChildAt then ExistingChild = SizeBox_HP:GetChildAt(0) end end) end

            if ExistingChild and slua.isValid(ExistingChild) then
                pcall(function() ExistingChild:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
                pcall(function() ExistingChild:SetRenderOpacity(1.0) end)

                local FoundPB = PlayerMapMarker.FindProgressBarInWidget(ExistingChild, 0, 5)
                if FoundPB and slua.isValid(FoundPB) then
                    HealthFill = FoundPB
                    bIsOriginalProgressBar = true
                    pcall(function() FoundPB:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
                    pcall(function() FoundPB:SetRenderOpacity(1.0) end)
                else
                    local PB = CGame:NewObjectFromPath("/Script/UMG.ProgressBar", ExistingChild)
                    if PB then
                        pcall(function() PB:SetFillColorAndOpacity(FLinearColor and FLinearColor(0.10, 1.0, 0.20, 1.0) or {R=26,G=255,B=51,A=255}) end)
                        pcall(function() PB:SetPercent(1.0) end)
                        pcall(function() PB:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
                        pcall(function() PB:SetRenderOpacity(1.0) end)
                        pcall(function() PB:SetDesiredSizeOverride(FVector2D and FVector2D(100, 6) or {X=100, Y=6}) end)
                        pcall(function() ExistingChild:AddChild(PB) end)
                        HealthFill = PB
                    end
                end
            else
                local PB = CGame:NewObjectFromPath("/Script/UMG.ProgressBar", SizeBox_HP)
                if PB then
                    pcall(function() PB:SetFillColorAndOpacity(FLinearColor and FLinearColor(0.10, 1.0, 0.20, 1.0) or {R=26,G=255,B=51,A=255}) end)
                    pcall(function() PB:SetPercent(1.0) end)
                    pcall(function() PB:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
                    pcall(function() PB:SetRenderOpacity(1.0) end)
                    pcall(function() PB:SetDesiredSizeOverride(FVector2D and FVector2D(100, 6) or {X=100, Y=6}) end)

                    local bUsedSetContent = false
                    pcall(function() if SizeBox_HP.SetContent then SizeBox_HP:SetContent(PB) bUsedSetContent = true end end)
                    if not bUsedSetContent then pcall(function() SizeBox_HP:AddChild(PB) end) end
                    HealthFill = PB
                end
            end
        end
    end)

    local WidgetData = {
        Container = Widget,
        NameText = NameText,
        HealthFill = HealthFill,
        IsGameWidget = true,
        IsOriginalProgressBar = bIsOriginalProgressBar,
        HasChildren = (NameText ~= nil)
    }
    return WidgetData
end

PlayerMapMarker._CanvasScaleX = 1.0
PlayerMapMarker._CanvasScaleY = 1.0
PlayerMapMarker._CanvasOffsetX = 0.0
PlayerMapMarker._CanvasOffsetY = 0.0

function PlayerMapMarker.UpdateCanvasTransform(PC)
    if not PlayerMapMarker.ESPCanvas or not Game:IsValid(PlayerMapMarker.ESPCanvas) then return end
    local success = false
    pcall(function()
        local SBL = SlateBlueprintLibrary
        if SBL and SBL.AbsoluteToLocal then
            local cg = PlayerMapMarker.ESPCanvas:GetCachedGeometry()
            if cg then
                local pt0 = SBL.AbsoluteToLocal(cg, FVector2D and FVector2D(0, 0) or {X=0, Y=0})
                local pt1 = SBL.AbsoluteToLocal(cg, FVector2D and FVector2D(100, 100) or {X=100, Y=100})
                if pt0 and pt1 then
                    PlayerMapMarker._CanvasScaleX = (pt1.X - pt0.X) / 100
                    PlayerMapMarker._CanvasScaleY = (pt1.Y - pt0.Y) / 100
                    PlayerMapMarker._CanvasOffsetX = pt0.X
                    PlayerMapMarker._CanvasOffsetY = pt0.Y
                    success = true
                end
            end
        end
    end)

    if not success then
        pcall(function()
            local WLL = WidgetLayoutLibrary
            if WLL and WLL.ScreenToWidgetLocal then
                local cg = PlayerMapMarker.ESPCanvas:GetCachedGeometry()
                if cg then
                    local pt0 = FVector2D and FVector2D(0, 0) or {X=0, Y=0}
                    local pt1 = FVector2D and FVector2D(0, 0) or {X=0, Y=0}
                    WLL.ScreenToWidgetLocal(PC, cg, FVector2D and FVector2D(0, 0) or {X=0, Y=0}, pt0)
                    WLL.ScreenToWidgetLocal(PC, cg, FVector2D and FVector2D(100, 100) or {X=100, Y=100}, pt1)
                    PlayerMapMarker._CanvasScaleX = (pt1.X - pt0.X) / 100
                    PlayerMapMarker._CanvasScaleY = (pt1.Y - pt0.Y) / 100
                    PlayerMapMarker._CanvasOffsetX = pt0.X
                    PlayerMapMarker._CanvasOffsetY = pt0.Y
                    success = true
                end
            end
        end)
    end

    if not success then
        local scale = 1.0
        local WLL = WidgetLayoutLibrary
        if WLL and WLL.GetViewportScale then scale = WLL.GetViewportScale(PC) or 1.0 end
        PlayerMapMarker._CanvasScaleX = 1.0 / scale
        PlayerMapMarker._CanvasScaleY = 1.0 / scale
        PlayerMapMarker._CanvasOffsetX = 0
        PlayerMapMarker._CanvasOffsetY = 0
    end
end

function PlayerMapMarker.ScreenPixelToCanvasLocal(PC, ScreenPixelPos)
    if not ScreenPixelPos then return FVector2D and FVector2D(0, 0) or {X=0, Y=0} end
    local scaleX = PlayerMapMarker._CanvasScaleX or 1.0
    local scaleY = PlayerMapMarker._CanvasScaleY or 1.0
    local offsetX = PlayerMapMarker._CanvasOffsetX or 0
    local offsetY = PlayerMapMarker._CanvasOffsetY or 0
    return (FVector2D and FVector2D(ScreenPixelPos.X * scaleX + offsetX, ScreenPixelPos.Y * scaleY + offsetY)) or {X = ScreenPixelPos.X * scaleX + offsetX, Y = ScreenPixelPos.Y * scaleY + offsetY}
end

function PlayerMapMarker.ProjectWorldToCanvasLocal(PC, WorldLoc)
    if not IsValid(PC) or not WorldLoc then return false, (FVector2D and FVector2D(0, 0) or {X=0, Y=0}) end
    local ScreenPixelPos = FVector2D and FVector2D(0, 0) or {X=0, Y=0}
    local bOK = false
    pcall(function()
        local res = PC:ProjectWorldLocationToScreen(WorldLoc, ScreenPixelPos, true)
        if res == true or res == 1 or (ScreenPixelPos and (ScreenPixelPos.X ~= 0 or ScreenPixelPos.Y ~= 0)) then bOK = true end
    end)
    if not bOK or not ScreenPixelPos or (ScreenPixelPos.X == 0 and ScreenPixelPos.Y == 0) then return false, (FVector2D and FVector2D(0, 0) or {X=0, Y=0}) end
    local CanvasLocalPos = PlayerMapMarker.ScreenPixelToCanvasLocal(PC, ScreenPixelPos)
    return true, CanvasLocalPos
end

function PlayerMapMarker.GetDynamicViewportSize(PC)
    local width, height = 0, 0
    if PlayerMapMarker.ESPCanvas and Game:IsValid(PlayerMapMarker.ESPCanvas) then
        pcall(function()
            local cg = PlayerMapMarker.ESPCanvas:GetCachedGeometry()
            if cg and cg.GetLocalSize then
                local sz = cg:GetLocalSize()
                if sz and sz.X and sz.X > 200 then width = sz.X height = sz.Y end
            end
        end)
    end
    if width > 200 then return width, height end
    pcall(function()
        local WLL = WidgetLayoutLibrary
        if WLL and WLL.GetViewportSize then
            local sz = WLL.GetViewportSize(PC or PlayerMapMarker.GetMyPlayerController())
            if sz and sz.X and sz.X > 200 then width = sz.X height = sz.Y end
        end
    end)
    if width > 200 then
        pcall(function()
            local WLL = WidgetLayoutLibrary
            if WLL and WLL.GetViewportScale then
                local scale = WLL.GetViewportScale(PC or PlayerMapMarker.GetMyPlayerController())
                if scale and type(scale) == "number" and scale > 0 and scale ~= 1.0 then width = width / scale height = height / scale end
            end
        end)
        return width, height
    end
    return PlayerMapMarker._cachedViewportW or 1920, PlayerMapMarker._cachedViewportH or 1080
end

function PlayerMapMarker.UpdateESPPositionWithPC(Widget, WorldLoc, PC, CanvasPos)
    if not Widget or not IsValid(PC) then return false end
    local Container = Widget.Container or Widget
    local bOnScreen = true
    if not CanvasPos then
        if not WorldLoc then return false end
        bOnScreen, CanvasPos = PlayerMapMarker.ProjectWorldToCanvasLocal(PC, WorldLoc)
    end

    if not bOnScreen then pcall(function() Container:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end) return false end

    pcall(function()
        if PlayerMapMarker.ESPCanvas and Game:IsValid(PlayerMapMarker.ESPCanvas) then
            local ptr = tostring(Container)
            local Slot = PlayerMapMarker.ESPWidgetPtrs[ptr]

            if not Slot or not slua.isValid(Slot) or type(Slot) == "boolean" then
                local addedSlot = PlayerMapMarker.ESPCanvas:AddChildToCanvas(Container)
                if addedSlot and slua.isValid(addedSlot) then
                    Slot = addedSlot
                    PlayerMapMarker.ESPWidgetPtrs[ptr] = addedSlot
                    if type(Widget) == "table" then Widget.Slot = addedSlot end
                    pcall(function() Slot:SetAutoSize(true) end)
                    pcall(function() Slot.bAutoSize = true end)
                    local align = FVector2D and FVector2D(0.5, 1.0) or {X=0.5, Y=1.0}
                    pcall(function() Slot.Alignment = align end)
                    pcall(function() Slot:SetAlignment(align) end)
                    pcall(function() Slot:SetAlignment(0.5, 1.0) end)
                    pcall(function() Slot:SetZOrder(PlayerMapMarker.ESPWidgetZOrder or 20) end)
                end
            end


            local bShowAnyUI = _G.LexusConfig.Esp9_Name or _G.LexusConfig.Esp9_Distance or _G.LexusConfig.Esp9_HP or _G.LexusConfig.Esp9_Team or _G.LexusConfig.Esp9_Weapon
            if bShowAnyUI then
                Container:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            else
                Container:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
            end

            if not Widget._OffsetResetDone then
                pcall(function() Container:SetRenderTranslation(FVector2D and FVector2D(0.0, 0.0) or {X=0, Y=0}) end)


                pcall(function() Container:SetRenderScale(FVector2D and FVector2D(0.90, 0.90) or {X=0.90, Y=0.90}) end)

                if Widget and type(Widget) == "table" then
                    if Widget.NameText and slua.isValid(Widget.NameText) then pcall(function() Widget.NameText:SetRenderTranslation(FVector2D and FVector2D(0.0, 0.0) or {X=0, Y=0}) end) end
                    if Widget.HealthFill and slua.isValid(Widget.HealthFill) then pcall(function() Widget.HealthFill:SetRenderTranslation(FVector2D and FVector2D(0.0, 0.0) or {X=0, Y=0}) end) end
                end
                pcall(function() Container.RenderTransformPivot = FVector2D and FVector2D(0.5, 1.0) or {X=0.5, Y=1.0} end)
                pcall(function() Container:SetRenderTransformPivot(FVector2D and FVector2D(0.5, 1.0) or {X=0.5, Y=1.0}) end)
                Widget._OffsetResetDone = true
            end

            if not Slot or not slua.isValid(Slot) or Slot == PlayerMapMarker.ESPCanvas then
                if Widget and type(Widget) == "table" and Widget.Slot and slua.isValid(Widget.Slot) then Slot = Widget.Slot
                elseif Container.Slot and slua.isValid(Container.Slot) then Slot = Container.Slot end
            end

            if Slot and slua.isValid(Slot) and Slot ~= PlayerMapMarker.ESPCanvas then
                local finalX = CanvasPos.X + (PlayerMapMarker.ESPAnchorOffsetX or 0)
                local finalY = CanvasPos.Y + (PlayerMapMarker.ESPAnchorOffsetY or 0)
                if Widget and type(Widget) == "table" then
                    if not Widget._CachedPosVec then Widget._CachedPosVec = FVector2D and FVector2D(finalX, finalY) or {X=finalX, Y=finalY}
                    else Widget._CachedPosVec.X = finalX Widget._CachedPosVec.Y = finalY end
                    pcall(function() Slot:SetPosition(Widget._CachedPosVec) end)
                else
                    pcall(function() Slot:SetPosition(FVector2D and FVector2D(finalX, finalY) or {X=finalX, Y=finalY}) end)
                end
            end
        end
    end)
    return true
end

function PlayerMapMarker.UpdateESPText(Widget, Text)
    if not Widget then return end
    if Widget._LastESPText == Text then return end
    Widget._LastESPText = Text

    local function applyTextAndCenter(w, txt)
        if not w or not slua.isValid(w) then return end


        if txt == "" then
            pcall(function() w:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
            return
        else
            pcall(function() w:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
        end

        pcall(function() w:SetText(txt) end)

        pcall(function()
            local FSlateColor = import("SlateColor") or import("/Script/SlateCore.SlateColor")
            local orangeColor = FLinearColor and FLinearColor(1.0, 1.0, 1.0, 1.0) or {R=255, G=255, B=255, A=255}
            local nameColor = FLinearColor and FLinearColor(0.0, 0.0, 0.0, 1.0) or {R=0, G=0, B=0, A=255}
            if w.SetColorAndOpacity then
                if FSlateColor then w:SetColorAndOpacity(FSlateColor(nameColor)) else w:SetColorAndOpacity(nameColor) end
            end
            pcall(function()
                if w.SetShadowColorAndOpacity then
                    local outlineWhite = FLinearColor and FLinearColor(1.0, 1.0, 1.0, 1.0) or {R=255, G=255, B=255, A=255}
                    w:SetShadowColorAndOpacity(outlineWhite)
                end
                if w.SetShadowOffset then w:SetShadowOffset(FVector2D(0, 0)) end
            end)
        end)
        pcall(function() if w.SetJustification then w:SetJustification(1) end end)
        pcall(function() local slot = w.Slot if slot and slot.SetHorizontalAlignment then slot:SetHorizontalAlignment(1) end end)
        pcall(function() w:SetRenderTranslation(FVector2D and FVector2D(PlayerMapMarker.ESPTextOffsetX or 0, PlayerMapMarker.ESPTextOffsetY or 0) or {X=PlayerMapMarker.ESPTextOffsetX or 0, Y=PlayerMapMarker.ESPTextOffsetY or 0}) end)
    end

    if Widget.NameText and slua.isValid(Widget.NameText) then applyTextAndCenter(Widget.NameText, Text) end
    if Widget.IsGameWidget and Widget.Container then
        pcall(function()
            local W = Widget.Container
            if W and slua.isValid(W) then
                if W.SetPlayerName then
                    local Name = Text
                    local idx = string.find(Text, " %[")
                    if idx then Name = string.sub(Text, 1, idx - 1) end
                    W:SetPlayerName(Name)
                end
                applyTextAndCenter(W.TextBlock_TeamName, Text)
                applyTextAndCenter(W.TextBlock_PlayerName, Text)

                pcall(function()
                    if not Widget._CachedVBChildren then
                        local list = {}
                        local VB = PlayerMapMarker._FindNamedWidgetInTree(W, "VerticalBox_0", 8)
                        if VB and slua.isValid(VB) and VB.GetChildrenCount then
                            local nChildren = VB:GetChildrenCount()
                            for i = 0, nChildren - 1 do
                                local child = VB:GetChildAt(i)
                                if child and slua.isValid(child) and child.SetText then table.insert(list, child) end
                            end
                        end
                        Widget._CachedVBChildren = list
                    end
                    for _, child in ipairs(Widget._CachedVBChildren) do applyTextAndCenter(child, Text) end
                end)

                pcall(function()
                    if not Widget._CachedHBChildren then
                        local list = {}
                        local HB = PlayerMapMarker._FindNamedWidgetInTree(W, "HorizontalBox_TeamName", 8)
                        if HB and slua.isValid(HB) and HB.GetChildrenCount then
                            local nChildren = HB:GetChildrenCount()
                            for i = 0, nChildren - 1 do
                                local child = HB:GetChildAt(i)
                                if child and slua.isValid(child) and child.SetText then table.insert(list, child) end
                            end
                        end
                        Widget._CachedHBChildren = list
                    end
                    for _, child in ipairs(Widget._CachedHBChildren) do applyTextAndCenter(child, Text) end
                end)
            end
        end)
    end
end

function PlayerMapMarker.UpdateESPHealth(Widget, pct)
    if not Widget then return end

    local bShowHP = _G.LexusConfig.Esp9_HP

    if PlayerMapMarker.bForceSwitcherIndexEveryUpdate and Widget.Container then
        pcall(function()
            local W = Widget.Container
            if W and slua.isValid(W) then
                if W.WidgetSwitcher_Type and slua.isValid(W.WidgetSwitcher_Type) then pcall(function() if W.WidgetSwitcher_Type.SetActiveWidgetIndex then W.WidgetSwitcher_Type:SetActiveWidgetIndex(PlayerMapMarker.HPWidgetSwitcherTypeIndex) end end) end
                if W.WidgetSwitcher_Type2 and slua.isValid(W.WidgetSwitcher_Type2) then pcall(function() if W.WidgetSwitcher_Type2.SetActiveWidgetIndex then W.WidgetSwitcher_Type2:SetActiveWidgetIndex(PlayerMapMarker.HPWidgetSwitcherType2Index) end end) end


                if W.SizeBox_HP and slua.isValid(W.SizeBox_HP) then
                    if bShowHP then
                        W.SizeBox_HP:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                    else
                        W.SizeBox_HP:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                    end
                end
            end
        end)
    end


    if not bShowHP then return end


    if Widget.LastPct ~= nil and math.abs((Widget.LastPct or 0) - (pct or 0)) < 0.01 then
        return
    end
    Widget.LastPct = pct

    if Widget.HealthFill then
        local bValid = false
        pcall(function() bValid = slua.isValid(Widget.HealthFill) end)
        if bValid then
            local bHasSetPercent = false
            pcall(function() bHasSetPercent = (Widget.HealthFill.SetPercent ~= nil) end)
            if not bHasSetPercent then
                local PB = PlayerMapMarker.FindProgressBarInWidget(Widget.HealthFill, 0, 5)
                if PB and slua.isValid(PB) then Widget.HealthFill = PB else return end
            end

            pcall(function()
                if Widget.HealthFill.SetWidgetVisibility then Widget.HealthFill:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end
                if Widget.HealthFill.SetRenderOpacity then Widget.HealthFill:SetRenderOpacity(1.0) end
                if Widget.HealthFill.SetPercent then
                    Widget.HealthFill:SetPercent(pct)


                    local color = FLinearColor and FLinearColor(0.10, 1.0, 0.20, 1.0) or {R=26,G=255,B=51,A=255}


                    if Widget.HealthFill.SetFillColorAndOpacity then
                        Widget.HealthFill:SetFillColorAndOpacity(color)
                    end


                    pcall(function()
                        if Widget.IsOriginalProgressBar then
                            local style = Widget.HealthFill.WidgetStyle
                            if style and style.FillImage then
                                style.FillImage.TintColor = color
                                Widget.HealthFill:SetWidgetStyle(style)
                            end
                        end
                    end)
                end
            end)
        end
        return
    end
end

function PlayerMapMarker.RemoveESPWidget(Widget, KeyStr)
    if not Widget then return end
    local Container = Widget.Container or Widget
    pcall(function()
        local ptr = tostring(Container)
        PlayerMapMarker.ESPWidgetPtrs[ptr] = nil
        Container:RemoveFromParent()
        Container:ConditionalBeginDestroy()
    end)
    if KeyStr then
        PlayerMapMarker.RemoveSnapLine(KeyStr)
        if PlayerMapMarker.RemoveSkeletonLines then
            PlayerMapMarker.RemoveSkeletonLines(KeyStr)
        end
    end
end

function PlayerMapMarker.CreateSnapLine()
    if not PlayerMapMarker.ESPCanvas or not Game:IsValid(PlayerMapMarker.ESPCanvas) then return nil end
    local Border = nil
    pcall(function() Border = CGame:NewObjectFromPath("/Script/UMG.Border", PlayerMapMarker.ESPCanvas) end)
    if not Border or not slua.isValid(Border) then return nil end

    local color = PlayerMapMarker.SnapLineColor or (FLinearColor and FLinearColor(1.0, 1.0, 1.0, PlayerMapMarker.SnapLineOpacity or 0.7) or {R=1,G=1,B=1,A=PlayerMapMarker.SnapLineOpacity or 0.7})
    pcall(function() Border:SetBrushColor(color) end)
    pcall(function() Border:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
    pcall(function() Border.RenderTransformPivot = FVector2D and FVector2D(0.0, 0.5) or {X=0,Y=0.5} end)
    pcall(function() Border:SetRenderTransformPivot(FVector2D and FVector2D(0.0, 0.5) or {X=0,Y=0.5}) end)

    local Slot = nil
    pcall(function()
        Slot = PlayerMapMarker.ESPCanvas:AddChildToCanvas(Border)
        if Slot then Slot:SetAutoSize(false) Slot:SetZOrder(1) end
    end)
    return { Widget = Border, Slot = Slot }
end

function PlayerMapMarker.GetSnapLineStartPos(PC)
    local screenPixelW, screenPixelH = 0, 0
    local scale = 1.0

    pcall(function()
        if PC and PC.GetViewportSize then
            local vs = FVector2D and FVector2D(0, 0) or {X=0,Y=0}
            PC:GetViewportSize(vs)
            if vs and vs.X and vs.X > 200 then screenPixelW = vs.X screenPixelH = vs.Y end
        end
    end)
    if screenPixelW <= 200 then
        pcall(function()
            local WLL = WidgetLayoutLibrary
            if WLL and WLL.GetViewportSize then
                local vs = WLL.GetViewportSize(PC)
                if vs and vs.X and vs.X > 200 then screenPixelW = vs.X screenPixelH = vs.Y end
            end
        end)
    end
    pcall(function()
        local WLL = WidgetLayoutLibrary
        if WLL and WLL.GetViewportScale then
            local s = WLL.GetViewportScale(PC)
            if s and type(s) == "number" and s > 0 then scale = s end
        end
    end)
    if screenPixelW <= 200 then
        screenPixelW = (PlayerMapMarker._cachedViewportW or 1920) * scale
        screenPixelH = (PlayerMapMarker._cachedViewportH or 1080) * scale
    end

    if not PlayerMapMarker._CachedTopCenterPixel then PlayerMapMarker._CachedTopCenterPixel = FVector2D and FVector2D(0, 0) or {X=0,Y=0} end
    PlayerMapMarker._CachedTopCenterPixel.X = screenPixelW / 2.0
    PlayerMapMarker._CachedTopCenterPixel.Y = (PlayerMapMarker.SnapLineOriginY or 50) * scale

    local fromCanvasPos = PlayerMapMarker.ScreenPixelToCanvasLocal(PC, PlayerMapMarker._CachedTopCenterPixel)
    local fromX = fromCanvasPos.X + (PlayerMapMarker.SnapLineOriginOffsetX or 0)
    local fromY = fromCanvasPos.Y

    return fromX, fromY
end

function PlayerMapMarker.UpdateSnapLine(KeyStr, CanvasPos, bOnScreen, fromX, fromY, Character, PC)
    if not PlayerMapMarker.bUseSnapLines then return end
    if not PlayerMapMarker.ESPCanvas or not Game:IsValid(PlayerMapMarker.ESPCanvas) then return end

    local LineData = PlayerMapMarker.SnapLineWidgets[KeyStr]

    if not bOnScreen or not CanvasPos or not IsValid(Character) or not IsValid(PC) then
        if LineData and LineData.Widget and slua.isValid(LineData.Widget) then
            pcall(function() LineData.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
        end
        return
    end

    local bIsNew = false
    if not LineData then
        LineData = PlayerMapMarker.CreateSnapLine()
        if not LineData or not LineData.Widget or not LineData.Slot then return end
        PlayerMapMarker.SnapLineWidgets[KeyStr] = LineData
        bIsNew = true
    end

    local Widget = LineData.Widget
    local Slot = LineData.Slot

    pcall(function() Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)

    if not LineData._PivotSet then
        pcall(function() Widget.RenderTransformPivot = FVector2D and FVector2D(0.0, 0.5) or {X=0,Y=0.5} end)
        pcall(function() Widget:SetRenderTransformPivot(FVector2D and FVector2D(0.0, 0.5) or {X=0,Y=0.5}) end)
        LineData._PivotSet = true
    end


    local bTargetVisible = PlayerMapMarker.IsPlayerVisible(PC, Character)
    local lineColor = bTargetVisible and (PlayerMapMarker.SnapLineVisibleColor or FLinearColor(0.10, 1.0, 0.20, 0.8)) or (PlayerMapMarker.SnapLineCoverColor or FLinearColor(0.9, 0.0, 0.0, 0.6))

    local cData = _G.LexusState.CustomTextData or {}
    local visColorID = cData.Esp9_LineVisColor or 2
    local hidColorID = cData.Esp9_LineHidColor or 1
    local currentLineColorHash = tostring(bTargetVisible) .. "_" .. visColorID .. "_" .. hidColorID

    if LineData._cachedColorHash ~= currentLineColorHash then
        pcall(function() Widget:SetBrushColor(lineColor) end)
        LineData._cachedColorHash = currentLineColorHash
    end

    local toX = CanvasPos.X + (PlayerMapMarker.SnapLineHeadOffsetX or 0)
    local toY = CanvasPos.Y + (PlayerMapMarker.SnapLineHeadOffsetY or 0)
    local dx = toX - fromX
    local dy = toY - fromY
    local length = math.sqrt(dx * dx + dy * dy)
    local thickness = PlayerMapMarker.SnapLineThickness or 1.5

    local angle_rad = (math.atan2 and math.atan2(dy, dx)) or math.atan(dy, dx)
    local angle = angle_rad * 57.29577951308232


    local threshold = 2.0
    LineData.lastToX = LineData.lastToX or -999
    LineData.lastToY = LineData.lastToY or -999

    if math.abs(toX - LineData.lastToX) > threshold or math.abs(toY - LineData.lastToY) > threshold then
        LineData.lastToX = toX
        LineData.lastToY = toY

        if not LineData._CachedPosVec then
            LineData._CachedPosVec = FVector2D and FVector2D(fromX, fromY - thickness / 2.0) or {X=fromX, Y=fromY - thickness / 2.0}
            LineData._CachedSizeVec = FVector2D and FVector2D(length, thickness) or {X=length, Y=thickness}
        else
            LineData._CachedPosVec.X = fromX ; LineData._CachedPosVec.Y = fromY - thickness / 2.0
            LineData._CachedSizeVec.X = length ; LineData._CachedSizeVec.Y = thickness
        end

        pcall(function()
            Slot:SetPosition(LineData._CachedPosVec)
            Slot:SetSize(LineData._CachedSizeVec)
            if bIsNew then Slot:SetZOrder(1) end
        end)
        pcall(function() Widget:SetRenderAngle(angle) end)
    end
end

function PlayerMapMarker.RemoveSnapLine(KeyStr)
    local LineData = PlayerMapMarker.SnapLineWidgets[KeyStr]
    if LineData and LineData.Widget and slua.isValid(LineData.Widget) then
        pcall(function() LineData.Widget:RemoveFromParent() LineData.Widget:ConditionalBeginDestroy() end)
        PlayerMapMarker.SnapLineWidgets[KeyStr] = nil
    end
end

function PlayerMapMarker.ClearAllSnapLines()
    for KeyStr, LineData in pairs(PlayerMapMarker.SnapLineWidgets) do
        if LineData and LineData.Widget and slua.isValid(LineData.Widget) then
            pcall(function() LineData.Widget:RemoveFromParent() LineData.Widget:ConditionalBeginDestroy() end)
        end
    end
    PlayerMapMarker.SnapLineWidgets = {}
end


function PlayerMapMarker.ScreenPixelToCanvasLocalRaw(PC, screenX, screenY)
    local scaleX = PlayerMapMarker._CanvasScaleX or 1.0
    local scaleY = PlayerMapMarker._CanvasScaleY or 1.0
    local offsetX = PlayerMapMarker._CanvasOffsetX or 0
    local offsetY = PlayerMapMarker._CanvasOffsetY or 0
    return screenX * scaleX + offsetX, screenY * scaleY + offsetY
end

function PlayerMapMarker.ProjectWorldToCanvasLocalRaw(PC, WorldLoc)
    if not IsValid(PC) or not WorldLoc then return false, 0, 0 end
    if not PlayerMapMarker._tempScreenPixelPos then
        PlayerMapMarker._tempScreenPixelPos = FVector2D and FVector2D(0, 0) or {X=0, Y=0}
    end
    local tempPos = PlayerMapMarker._tempScreenPixelPos
    local bOK = false
    pcall(function()
        local res = PC:ProjectWorldLocationToScreen(WorldLoc, tempPos, true)
        if res == true or res == 1 then bOK = true end
    end)
    if not bOK or (tempPos.X == 0 and tempPos.Y == 0) then return false, 0, 0 end
    local canvasX, canvasY = PlayerMapMarker.ScreenPixelToCanvasLocalRaw(PC, tempPos.X, tempPos.Y)
    return true, canvasX, canvasY
end

function PlayerMapMarker.GetBoneLocationWithFallback(Character, PrimaryBoneName)
    if not IsValid(Character) or not PrimaryBoneName then return nil end
    if Character._cachedBoneNames and Character._cachedBoneNames[PrimaryBoneName] then
        local cachedName = Character._cachedBoneNames[PrimaryBoneName]
        local loc = nil
        pcall(function()
            local Mesh = PlayerMapMarker.GetCharacterMesh(Character)
            if Mesh and Game:IsValid(Mesh) then
                if Mesh.GetSocketLocation then loc = Mesh:GetSocketLocation(cachedName)
                elseif Mesh.GetBoneLocation then loc = Mesh:GetBoneLocation(cachedName) end
            end
        end)
        if loc then return loc end
    end
    local fallbacks = PlayerMapMarker.BoneNameFallbacks[PrimaryBoneName] or {PrimaryBoneName}
    for _, bname in ipairs(fallbacks) do
        local loc = nil
        pcall(function()
            local Mesh = PlayerMapMarker.GetCharacterMesh(Character)
            if Mesh and Game:IsValid(Mesh) then
                if Mesh.GetSocketLocation then loc = Mesh:GetSocketLocation(bname)
                elseif Mesh.GetBoneLocation then loc = Mesh:GetBoneLocation(bname) end
            end
        end)
        if loc then
            if not Character._cachedBoneNames then Character._cachedBoneNames = {} end
            Character._cachedBoneNames[PrimaryBoneName] = bname
            return loc
        end
    end
    return nil
end

function PlayerMapMarker.IsPlayerVisible(PC, Character)
    if not IsValid(PC) or not IsValid(Character) then return false end
    local now = os.clock()

    if Character._lastVisTime and (now - Character._lastVisTime) < 0.3 then
        return Character._cachedIsVisible or false
    end
    Character._lastVisTime = now
    local bVis = false
    pcall(function()
        if PC.LineOfSightTo then
            if not PlayerMapMarker._ZeroVector then
                local VT = FVector or import("/Script/CoreUObject.Vector")
                if VT then PlayerMapMarker._ZeroVector = VT(0, 0, 0) end
            end
            bVis = PC:LineOfSightTo(Character, PlayerMapMarker._ZeroVector, false)
        end
    end)
    if not bVis then
        local KismetSystemLibrary = import("KismetSystemLibrary")
        if KismetSystemLibrary and KismetSystemLibrary.LineTraceSingle then
            pcall(function()
                local camMgr = nil
                local GameplayStatics = import("GameplayStatics")
                if GameplayStatics and GameplayStatics.GetPlayerCameraManager then
                    camMgr = GameplayStatics.GetPlayerCameraManager(PC, 0)
                end
                local startLoc = camMgr and camMgr:GetCameraLocation() or PlayerMapMarker.GetMyLocation()
                local headLoc = PlayerMapMarker.GetBoneLocationWithFallback(Character, "head")
                if startLoc and headLoc then
                    if not PlayerMapMarker._CachedHitResult then
                        local HitResultClass = import("HitResult") or import("/Script/Engine.HitResult")
                        PlayerMapMarker._CachedHitResult = HitResultClass and HitResultClass() or {}
                    end
                    local bHit = KismetSystemLibrary.LineTraceSingle(PC, startLoc, headLoc, 0, false, nil, 0, PlayerMapMarker._CachedHitResult, true)
                    if bHit then
                        local hitActor = nil
                        if type(PlayerMapMarker._CachedHitResult.GetActor) == "function" then hitActor = PlayerMapMarker._CachedHitResult:GetActor()
                        elseif PlayerMapMarker._CachedHitResult.Actor then hitActor = PlayerMapMarker._CachedHitResult.Actor end
                        if hitActor and (hitActor == Character or (type(hitActor.IsChildOf) == "function" and hitActor:IsChildOf(Character))) then
                            bVis = true
                        end
                    else
                        bVis = true
                    end
                end
            end)
        end
    end
    Character._cachedIsVisible = bVis
    return bVis
end

function PlayerMapMarker.CreateSkeletonLineWidget()
    if not PlayerMapMarker.ESPCanvas or not Game:IsValid(PlayerMapMarker.ESPCanvas) then return nil end
    local Border = nil
    pcall(function() Border = CGame:NewObjectFromPath("/Script/UMG.Border", PlayerMapMarker.ESPCanvas) end)
    if not Border or not slua.isValid(Border) then return nil end
    pcall(function() Border.RenderTransformPivot = FVector2D and FVector2D(0.0, 0.5) or {X=0, Y=0.5} end)
    pcall(function() Border:SetRenderTransformPivot(FVector2D and FVector2D(0.0, 0.5) or {X=0, Y=0.5}) end)
    local Slot = nil
    pcall(function()
        Slot = PlayerMapMarker.ESPCanvas:AddChildToCanvas(Border)
        if Slot then Slot:SetAutoSize(false) Slot:SetZOrder(5) end
    end)
    return {
        Widget = Border, Slot = Slot,
        posVec = FVector2D and FVector2D(0, 0) or {X=0, Y=0},
        sizeVec = FVector2D and FVector2D(0, 0) or {X=0, Y=0},
        lastFromX = -99999, lastFromY = -99999,
        lastToX = -99999, lastToY = -99999
    }
end

function PlayerMapMarker.UpdateSkeletonLines(KeyStr, Character, PC, bVisible, TeamColor, bPlayerOnScreen, charLoc, bTargetVisible)
    if not PlayerMapMarker.bUseSkeleton then return end
    if not PlayerMapMarker.ESPCanvas or not Game:IsValid(PlayerMapMarker.ESPCanvas) then return end
    local PlayerBones = PlayerMapMarker.SkeletonWidgets[KeyStr]
    if not bVisible or not IsValid(Character) or not IsValid(PC) then
        if PlayerBones then
            for _, LineData in ipairs(PlayerBones) do
                if LineData and LineData.Widget and slua.isValid(LineData.Widget) then
                    LineData.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                    LineData.Widget._isSelfHitTestVisible = false
                end
            end
        end
        return
    end

    if not charLoc then charLoc = PlayerMapMarker.GetESPLocation(Character) end
    if not charLoc then return end

    if bPlayerOnScreen == nil then
        local bOnScreen, _, _ = PlayerMapMarker.ProjectWorldToCanvasLocalRaw(PC, charLoc)
        bPlayerOnScreen = bOnScreen
    end
    if not bPlayerOnScreen then
        if PlayerBones then
            for _, LineData in ipairs(PlayerBones) do
                if LineData and LineData.Widget and slua.isValid(LineData.Widget) then
                    LineData.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                    LineData.Widget._isSelfHitTestVisible = false
                end
            end
        end
        return
    end

    local dist = 0
    local myLoc = PlayerMapMarker._CachedMyLoc or PlayerMapMarker.GetMyLocation()
    if myLoc and charLoc then
        local dx = (charLoc.X or 0) - (myLoc.X or 0)
        local dy = (charLoc.Y or 0) - (myLoc.Y or 0)
        local dz = (charLoc.Z or 0) - (myLoc.Z or 0)
        dist = math.sqrt(dx * dx + dy * dy + dz * dz)
    end

    if PlayerMapMarker.SkeletonMaxDistance and PlayerMapMarker.SkeletonMaxDistance > 0 then
        if dist > PlayerMapMarker.SkeletonMaxDistance then
            if PlayerBones then
                for _, LineData in ipairs(PlayerBones) do
                    if LineData and LineData.Widget and slua.isValid(LineData.Widget) then
                        LineData.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                        LineData.Widget._isSelfHitTestVisible = false
                    end
                end
            end
            return
        end
    end

    if not PlayerBones then
        PlayerBones = {}
        PlayerMapMarker.SkeletonWidgets[KeyStr] = PlayerBones
    end

    local lineColor = nil
    if PlayerMapMarker.bUseVisibilityColor then

        if bTargetVisible == nil then
            bTargetVisible = PlayerMapMarker.IsPlayerVisible(PC, Character)
        end
        if bTargetVisible then lineColor = PlayerMapMarker.SkeletonVisibleColor or FLinearColor(0.10, 1.0, 0.20, 0.8)
        else lineColor = PlayerMapMarker.SkeletonCoverColor or FLinearColor(0.9, 0.0, 0.0, 0.6) end
    else
        lineColor = PlayerMapMarker.SkeletonColor or TeamColor or FLinearColor(1.0, 1.0, 1.0, PlayerMapMarker.SkeletonOpacity or 0.8)
    end


    local cache = Character._cachedBones3D
    if not cache then cache = {} Character._cachedBones3D = cache end
    local moveKey = nil
    if charLoc then
        moveKey = math.floor(charLoc.X or 0) .. "," .. math.floor(charLoc.Y or 0) .. "," .. math.floor(charLoc.Z or 0)
    end
    if Character._cachedBonesMoveKey ~= moveKey then
        Character._cachedBonesMoveKey = moveKey
        for k in pairs(cache) do cache[k] = nil end
    end

    local lineIndex = 0
    local thickness = PlayerMapMarker.SkeletonThickness or 1.2

    for _, chain in ipairs(PlayerMapMarker.SkeletonChains) do
        local lastCanvasX, lastCanvasY = nil, nil
        for _, boneName in ipairs(chain) do
            local boneWorldLoc = cache[boneName]
            if boneWorldLoc == nil then
                boneWorldLoc = PlayerMapMarker.GetBoneLocationWithFallback(Character, boneName) or false
                cache[boneName] = boneWorldLoc
            end
            if boneWorldLoc == false then boneWorldLoc = nil end

            local currentCanvasX, currentCanvasY = nil, nil
            if boneWorldLoc then
                local bOnScreen, cX, cY = PlayerMapMarker.ProjectWorldToCanvasLocalRaw(PC, boneWorldLoc)
                if bOnScreen then
                    currentCanvasX = cX
                    currentCanvasY = cY
                end
            end

            if lastCanvasX and currentCanvasX then
                lineIndex = lineIndex + 1
                local LineData = PlayerBones[lineIndex]
                if not LineData or not LineData.Widget or not slua.isValid(LineData.Widget) then
                    LineData = PlayerMapMarker.CreateSkeletonLineWidget()
                    if LineData then PlayerBones[lineIndex] = LineData end
                end

                if LineData and LineData.Widget and LineData.Slot then
                    local Widget = LineData.Widget
                    local Slot = LineData.Slot

                    if Widget._cachedColor ~= lineColor then
                        Widget:SetBrushColor(lineColor)
                        Widget._cachedColor = lineColor
                    end
                    if not Widget._isSelfHitTestVisible then
                        Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                        Widget._isSelfHitTestVisible = true
                    end

                    local fromX = lastCanvasX
                    local fromY = lastCanvasY
                    local toX = currentCanvasX
                    local toY = currentCanvasY


                    local threshold = 0.5
                    if dist > 20000 then threshold = 3.0
                    elseif dist > 12000 then threshold = 2.0
                    elseif dist > 8000 then threshold = 1.0 end

                    if math.abs(fromX - LineData.lastFromX) > threshold or
                       math.abs(fromY - LineData.lastFromY) > threshold or
                       math.abs(toX - LineData.lastToX) > threshold or
                       math.abs(toY - LineData.lastToY) > threshold then

                        LineData.lastFromX = fromX
                        LineData.lastFromY = fromY
                        LineData.lastToX = toX
                        LineData.lastToY = toY

                        local dx = toX - fromX
                        local dy = toY - fromY
                        local length = math.sqrt(dx * dx + dy * dy)
                        local angle_rad = (math.atan2 and math.atan2(dy, dx)) or math.atan(dy, dx)
                        local angle = angle_rad * 57.29577951308232

                        local pVec = LineData.posVec
                        pVec.X = fromX ; pVec.Y = fromY - thickness / 2.0
                        Slot:SetPosition(pVec)

                        local sVec = LineData.sizeVec
                        sVec.X = length ; sVec.Y = thickness
                        Slot:SetSize(sVec)
                        Widget:SetRenderAngle(angle)
                    end
                end
            end
            lastCanvasX = currentCanvasX
            lastCanvasY = currentCanvasY
        end
    end

    for i = lineIndex + 1, #PlayerBones do
        local LineData = PlayerBones[i]
        if LineData and LineData.Widget and slua.isValid(LineData.Widget) then
            LineData.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
            LineData.Widget._isSelfHitTestVisible = false
        end
    end
end

function PlayerMapMarker.RemoveSkeletonLines(KeyStr)
    local PlayerBones = PlayerMapMarker.SkeletonWidgets[KeyStr]
    if PlayerBones then
        for _, LineData in ipairs(PlayerBones) do
            if LineData and LineData.Widget and slua.isValid(LineData.Widget) then
                pcall(function()
                    LineData.Widget:RemoveFromParent()
                    LineData.Widget:ConditionalBeginDestroy()
                end)
            end
        end
        PlayerMapMarker.SkeletonWidgets[KeyStr] = nil
    end
end

function PlayerMapMarker.ClearAllSkeletonLines()
    for KeyStr, PlayerBones in pairs(PlayerMapMarker.SkeletonWidgets) do
        for _, LineData in ipairs(PlayerBones) do
            if LineData and LineData.Widget and slua.isValid(LineData.Widget) then
                pcall(function()
                    LineData.Widget:RemoveFromParent()
                    LineData.Widget:ConditionalBeginDestroy()
                end)
            end
        end
    end
    PlayerMapMarker.SkeletonWidgets = {}
end


function PlayerMapMarker.ClearAllESP()
    pcall(function() RedBoxOverlay.Stop() end)
    for KeyStr, Data in pairs(PlayerMapMarker.ESPWidgets) do
        PlayerMapMarker.RemoveESPWidget(Data.Widget, KeyStr)
    end
    PlayerMapMarker.ESPWidgets = {}
    PlayerMapMarker.ESPWidgetPtrs = {}
    PlayerMapMarker.ClearAllSnapLines()
    PlayerMapMarker.ClearAllSkeletonLines()


    PlayerMapMarker.ESPCanvas = nil
    PlayerMapMarker._OBHeadWidgetClass = nil
    PlayerMapMarker._OBHeadWidgetLoadFailed = false
    PlayerMapMarker._cachedViewportW = 1920
    PlayerMapMarker._cachedViewportH = 1080
end

function PlayerMapMarker.UpdateESP(AllPlayers, MyLoc)
    if not PlayerMapMarker.bUseScreenESP then return end


    PlayerMapMarker.bUseSnapLines = _G.LexusConfig.Esp9_Line
    PlayerMapMarker.bUseSkeleton = _G.LexusConfig.Esp9_Skeleton


    local function GetEspColor(idx, alpha)
        local FC = _G.FLinearColor or import("LinearColor")
        local colors = {
            {1.0, 0.0, 0.0}, {0.18, 0.45, 1.0}, {0.35, 0.15, 0.95}, {0.45, 0.25, 0.9}, {0.65, 0.25, 1.0}, {0.85, 0.8, 1.0},
            {0.25, 0.65, 1.0}, {0.45, 0.2, 0.95}, {0.75, 0.35, 1.0}, {0.25, 0.2, 0.65}, {0.35, 0.5, 1.0}, {0.2, 0.35, 0.8},
            {0.0, 0.0, 0.5}, {0.5, 0.0, 0.0}, {0.5, 0.5, 0.0}, {0.75, 0.75, 0.75}, {1.0, 0.84, 0.0}, {0.5, 0.0, 1.0},
            {0.53, 0.81, 0.92}, {1.0, 0.5, 0.31}, {0.98, 0.5, 0.45}, {0.94, 0.9, 0.55}, {0.87, 0.63, 0.87}, {0.85, 0.44, 0.84},
            {0.29, 0.0, 0.51}, {0.25, 0.55, 0.95}, {0.6, 0.45, 1.0}, {0.86, 0.08, 0.24}, {0.55, 0.25, 0.9}, {0.5, 0.4, 1.0}
        }
        idx = math.floor(tonumber(idx) or 1)
        if idx < 1 or idx > 30 then idx = 1 end
        local r, g, b = colors[idx][1], colors[idx][2], colors[idx][3]
        if FC then return FC(r, g, b, alpha) end
        return {R = r * 255, G = g * 255, B = b * 255, A = alpha * 255}
    end
    if _G.LexusState and _G.LexusState.CustomTextData then
        local c = _G.LexusState.CustomTextData
        PlayerMapMarker.SnapLineThickness = (c.Esp9_LineThick or 1) * 1.0
        PlayerMapMarker.SnapLineVisibleColor = FLinearColor and FLinearColor(0.10, 1.0, 0.20, PlayerMapMarker.SnapLineOpacity or 0.7) or {R=26,G=255,B=51,A=178}
        PlayerMapMarker.SnapLineCoverColor = GetEspColor(c.Esp9_LineHidColor or 1, PlayerMapMarker.SnapLineOpacity or 0.7)

        PlayerMapMarker.SkeletonThickness = (c.Esp9_SkelThick or 1) * 0.8
        PlayerMapMarker.SkeletonVisibleColor = FLinearColor and FLinearColor(0.10, 1.0, 0.20, PlayerMapMarker.SkeletonOpacity or 0.8) or {R=26,G=255,B=51,A=204}
        PlayerMapMarker.SkeletonCoverColor = GetEspColor(c.Esp9_SkelHidColor or 1, 0.6)
        PlayerMapMarker.bUseVisibilityColor = true
    end

    if not PlayerMapMarker.InitESPCanvas() then
        return
    end

    if PlayerMapMarker._OBHeadWidgetLoadFailed then return end

    local PC = PlayerMapMarker.GetMyPlayerController()
    if IsValid(PC) then
        PlayerMapMarker.UpdateCanvasTransform(PC)
    end

    local fromX, fromY = 0, 0
    if PlayerMapMarker.bUseSnapLines and IsValid(PC) then
        fromX, fromY = PlayerMapMarker.GetSnapLineStartPos(PC)
    end

    local MyKey = PlayerMapMarker.GetMyPlayerKey()
    local SeenKeys = {}

    local MyChar = nil
    pcall(function()
        local GDP = PlayerMapMarker.GetGameplayData()
        if GDP and GDP.GetLocalCharacter then
            MyChar = GDP.GetLocalCharacter()
        else
            if PC and PC.GetPawn then MyChar = PC:GetPawn() end
        end
    end)
    local MyTeamID = PlayerMapMarker.GetTeamID(MyChar)

    for PlayerKey, Character in pairs(AllPlayers) do
        if IsValid(Character) then
            local bIsMe = PlayerMapMarker.IsMe(Character, PlayerKey, MyKey)
            local bIsAI = PlayerMapMarker.IsAI(Character)
            local KeyStr = tostring(PlayerKey)
            local Name = PlayerMapMarker.GetPlayerName(Character)

            local Loc = PlayerMapMarker.GetESPLocation(Character)

            local DistStr = ""
            if MyLoc and Loc then
                DistStr = PlayerMapMarker.GetDistanceString(MyLoc, Loc)
            end

            local bSkip = false
            if bIsMe and not PlayerMapMarker.bIncludeMe then bSkip = true end
            if bIsAI and not PlayerMapMarker.bIncludeAI then bSkip = true end

            local TeamID = PlayerMapMarker.GetTeamID(Character)
            if MyTeamID ~= nil and TeamID == MyTeamID and not bIsMe then
                bSkip = true
            end

            local bIsAlive = PlayerMapMarker.IsAlive(Character)

            if not bSkip and Loc then
                SeenKeys[KeyStr] = true
                local ESPData = PlayerMapMarker.ESPWidgets[KeyStr]


                local Text = ""
                if _G.LexusConfig.Esp9_Name then Text = Name end
                if _G.LexusConfig.Esp9_Distance and DistStr and DistStr ~= "" then
                    if Text ~= "" then Text = string.format("%s [%s]", Text, DistStr) else Text = string.format("[%s]", DistStr) end
                end

                local bOnScreen, CanvasPos = PlayerMapMarker.ProjectWorldToCanvasLocal(PC, Loc)

                if not ESPData then
                    local Widget = PlayerMapMarker.CreateESPWidget()
                    if Widget then
                        PlayerMapMarker.ESPWidgets[KeyStr] = {
                            Widget = Widget,
                            Character = Character,
                            Name = Name,
                            LastDistStr = DistStr,
                            TeamID = TeamID,
                        }
                        PlayerMapMarker.UpdateESPText(Widget, Text)
                        if bIsAlive then
                            PlayerMapMarker.UpdateESPPositionWithPC(Widget, Loc, PC, CanvasPos)
                            PlayerMapMarker.ApplyTeamColor(Widget, TeamID)
                            local HP = Character.Health or 0
                            local MaxHP = Character.MaxHealth or 120
                            local pct = 0
                            if HP > 0 and MaxHP > 0 then
                                pct = HP / MaxHP
                                if pct > 1 then pct = 1 end
                                if pct < 0 then pct = 0 end
                            end
                            PlayerMapMarker.UpdateESPHealth(Widget, pct)
                            PlayerMapMarker.AddWeaponIconToESP(Widget, Character)

                            if PlayerMapMarker.bUseSnapLines then
                                PlayerMapMarker.UpdateSnapLine(KeyStr, CanvasPos, bOnScreen, fromX, fromY, Character, PC)
                            else
                                PlayerMapMarker.RemoveSnapLine(KeyStr)
                            end

                            if PlayerMapMarker.bUseSkeleton then
                                PlayerMapMarker.UpdateSkeletonLines(KeyStr, Character, PC, true, PlayerMapMarker.GetTeamColor(TeamID), bOnScreen, Loc)
                            else
                                PlayerMapMarker.RemoveSkeletonLines(KeyStr)
                            end
                        else
                            local Container = Widget.Container or Widget
                            pcall(function() Container:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
                            PlayerMapMarker.UpdateESPHealth(Widget, 0)
                            PlayerMapMarker.RemoveSnapLine(KeyStr)
                            PlayerMapMarker.RemoveSkeletonLines(KeyStr)
                        end
                    end
                else
                    ESPData.Character = Character
                    ESPData.Name = Name
                    ESPData.LastDistStr = DistStr
                    if bIsAlive then

                        ESPData.TeamID = TeamID
                        PlayerMapMarker.ApplyTeamColor(ESPData.Widget, TeamID)


                        ESPData.Widget._LastESPText = nil
                        PlayerMapMarker.UpdateESPText(ESPData.Widget, Text)
                        PlayerMapMarker.UpdateESPPositionWithPC(ESPData.Widget, Loc, PC, CanvasPos)
                        local HP = Character.Health or 0
                        local MaxHP = Character.MaxHealth or 120
                        local pct = 0
                        if HP > 0 and MaxHP > 0 then
                            pct = HP / MaxHP
                            if pct > 1 then pct = 1 end
                            if pct < 0 then pct = 0 end
                        end
                        PlayerMapMarker.UpdateESPHealth(ESPData.Widget, pct)
                        PlayerMapMarker.AddWeaponIconToESP(ESPData.Widget, Character)

                        if PlayerMapMarker.bUseSnapLines then
                            PlayerMapMarker.UpdateSnapLine(KeyStr, CanvasPos, bOnScreen, fromX, fromY)
                        else
                            PlayerMapMarker.RemoveSnapLine(KeyStr)
                        end

                        if PlayerMapMarker.bUseSkeleton then
                            PlayerMapMarker.UpdateSkeletonLines(KeyStr, Character, PC, true, PlayerMapMarker.GetTeamColor(TeamID), bOnScreen, Loc)
                        else
                            PlayerMapMarker.RemoveSkeletonLines(KeyStr)
                        end
                    else
                        local Container = ESPData.Widget.Container or ESPData.Widget
                        pcall(function() Container:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
                        PlayerMapMarker.UpdateESPHealth(ESPData.Widget, 0)
                        PlayerMapMarker.RemoveSnapLine(KeyStr)
                        PlayerMapMarker.RemoveSkeletonLines(KeyStr)
                    end
                end
            end
        end
    end

    for KeyStr, Data in pairs(PlayerMapMarker.ESPWidgets) do
        if not SeenKeys[KeyStr] then
            PlayerMapMarker.RemoveESPWidget(Data.Widget, KeyStr)
            PlayerMapMarker.ESPWidgets[KeyStr] = nil
        end
    end
end

function PlayerMapMarker.UpdateESPLight()
    if RedBoxOverlay and RedBoxOverlay.bActive then RedBoxOverlay.UpdatePosition() end
    if not PlayerMapMarker.bUseScreenESP then return end


    local realNow = os.clock()
    local lastReal = PlayerMapMarker._lastLightRealTime or 0
    if lastReal > 0 and realNow > lastReal then
        local gap = realNow - lastReal
        if gap > 0.08 then
            PlayerMapMarker._WeakCheckMiss = (PlayerMapMarker._WeakCheckMiss or 0) + 1
        elseif gap < 0.06 then
            PlayerMapMarker._WeakCheckMiss = 0
            if PlayerMapMarker._bWeakDevice then PlayerMapMarker._bWeakDevice = false end
        end
        if gap > 1.5 then PlayerMapMarker._bWeakDevice = true end
        if (PlayerMapMarker._WeakCheckMiss or 0) >= 15 then
            PlayerMapMarker._bWeakDevice = true
        end
    end
    PlayerMapMarker._lastLightRealTime = realNow
    PlayerMapMarker._LightTickCount = (PlayerMapMarker._LightTickCount or 0) + 1
    local nTick = PlayerMapMarker._LightTickCount
    local bWeak = PlayerMapMarker._bWeakDevice == true

    if bWeak and (nTick % 4 ~= 0) then return end


    PlayerMapMarker.bUseSnapLines = _G.LexusConfig.Esp9_Line
    PlayerMapMarker.bUseSkeleton = _G.LexusConfig.Esp9_Skeleton


    local function GetEspColor(idx, alpha)
        local FC = _G.FLinearColor or import("LinearColor")
        local colors = {
            {1.0, 0.0, 0.0}, {0.18, 0.45, 1.0}, {0.35, 0.15, 0.95}, {0.45, 0.25, 0.9}, {0.65, 0.25, 1.0}, {0.85, 0.8, 1.0},
            {0.25, 0.65, 1.0}, {0.45, 0.2, 0.95}, {0.75, 0.35, 1.0}, {0.25, 0.2, 0.65}, {0.35, 0.5, 1.0}, {0.2, 0.35, 0.8},
            {0.0, 0.0, 0.5}, {0.5, 0.0, 0.0}, {0.5, 0.5, 0.0}, {0.75, 0.75, 0.75}, {1.0, 0.84, 0.0}, {0.5, 0.0, 1.0},
            {0.53, 0.81, 0.92}, {1.0, 0.5, 0.31}, {0.98, 0.5, 0.45}, {0.94, 0.9, 0.55}, {0.87, 0.63, 0.87}, {0.85, 0.44, 0.84},
            {0.29, 0.0, 0.51}, {0.25, 0.55, 0.95}, {0.6, 0.45, 1.0}, {0.86, 0.08, 0.24}, {0.55, 0.25, 0.9}, {0.5, 0.4, 1.0}
        }
        idx = math.floor(tonumber(idx) or 1)
        if idx < 1 or idx > 30 then idx = 1 end
        local r, g, b = colors[idx][1], colors[idx][2], colors[idx][3]
        if FC then return FC(r, g, b, alpha) end
        return {R = r * 255, G = g * 255, B = b * 255, A = alpha * 255}
    end
    if _G.LexusState and _G.LexusState.CustomTextData then
        local c = _G.LexusState.CustomTextData
        PlayerMapMarker.SnapLineThickness = (c.Esp9_LineThick or 1) * 1.0
        PlayerMapMarker.SnapLineVisibleColor = FLinearColor and FLinearColor(0.10, 1.0, 0.20, PlayerMapMarker.SnapLineOpacity or 0.7) or {R=26,G=255,B=51,A=178}
        PlayerMapMarker.SnapLineCoverColor = GetEspColor(c.Esp9_LineHidColor or 1, PlayerMapMarker.SnapLineOpacity or 0.7)

        PlayerMapMarker.SkeletonThickness = (c.Esp9_SkelThick or 1) * 0.8
        PlayerMapMarker.SkeletonVisibleColor = FLinearColor and FLinearColor(0.10, 1.0, 0.20, PlayerMapMarker.SkeletonOpacity or 0.8) or {R=26,G=255,B=51,A=204}
        PlayerMapMarker.SkeletonCoverColor = GetEspColor(c.Esp9_SkelHidColor or 1, 0.6)
        PlayerMapMarker.bUseVisibilityColor = true
    end

    if not PlayerMapMarker.ESPCanvas or not Game:IsValid(PlayerMapMarker.ESPCanvas) then return end
    local PC = PlayerMapMarker.GetMyPlayerController()
    if not IsValid(PC) then return end

    PlayerMapMarker.UpdateCanvasTransform(PC)

    local fromX, fromY = 0, 0
    if PlayerMapMarker.bUseSnapLines then fromX, fromY = PlayerMapMarker.GetSnapLineStartPos(PC) end


    local MyLoc = PlayerMapMarker._CachedMyLoc or PlayerMapMarker.GetMyLocation()

    for KeyStr, ESPData in pairs(PlayerMapMarker.ESPWidgets) do
        local Widget = ESPData.Widget
        local Character = ESPData.Character
        local Container = Widget and (Widget.Container or Widget)
        local bWidgetValid = false
        pcall(function() bWidgetValid = Container and slua.isValid(Container) end)

        if Widget and bWidgetValid and Character and IsValid(Character) then
            local bIsAlive = PlayerMapMarker.IsAlive(Character)
            if not bIsAlive then
                pcall(function() Container:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
                PlayerMapMarker.RemoveSnapLine(KeyStr)
                PlayerMapMarker.RemoveSkeletonLines(KeyStr)
            else

                local bShowAnyUI = _G.LexusConfig.Esp9_Name or _G.LexusConfig.Esp9_Distance or _G.LexusConfig.Esp9_HP or _G.LexusConfig.Esp9_Team or _G.LexusConfig.Esp9_Weapon
                if bShowAnyUI then
                    pcall(function() Container:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
                else
                    pcall(function() Container:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
                end
                pcall(function() Container:SetRenderOpacity(1.0) end)

                local Loc = PlayerMapMarker.GetESPLocation(Character)
                if Loc then

                    local distU = 0
                    if MyLoc then
                        local dx = (Loc.X or 0) - (MyLoc.X or 0)
                        local dy = (Loc.Y or 0) - (MyLoc.Y or 0)
                        distU = math.sqrt(dx * dx + dy * dy)
                    end


                    local lodStep = 1
                    if distU > 25000 then lodStep = 4
                    elseif distU > 10000 then lodStep = 2 end
                    if bWeak then lodStep = lodStep * 2 end

                    if (nTick % lodStep) == 0 then
                        local bOnScreen, CanvasPos = PlayerMapMarker.ProjectWorldToCanvasLocal(PC, Loc)
                        PlayerMapMarker.UpdateESPPositionWithPC(Widget, Loc, PC, CanvasPos)


                        local bTargetVisible = nil
                        if (PlayerMapMarker.bUseSnapLines or PlayerMapMarker.bUseSkeleton) and distU <= 20000 then
                            bTargetVisible = PlayerMapMarker.IsPlayerVisible(PC, Character)
                        end

                        if PlayerMapMarker.bUseSnapLines then
                            if distU <= 20000 then
                                PlayerMapMarker.UpdateSnapLine(KeyStr, CanvasPos, bOnScreen, fromX, fromY, Character, PC, bTargetVisible)
                            else
                                PlayerMapMarker.RemoveSnapLine(KeyStr)
                            end
                        else
                            PlayerMapMarker.RemoveSnapLine(KeyStr)
                        end

                        if PlayerMapMarker.bUseSkeleton then
                            PlayerMapMarker.UpdateSkeletonLines(KeyStr, Character, PC, true, PlayerMapMarker.GetTeamColor(ESPData.TeamID), bOnScreen, Loc, bTargetVisible)
                        else
                            PlayerMapMarker.RemoveSkeletonLines(KeyStr)
                        end
                    end
                else
                    PlayerMapMarker.RemoveSnapLine(KeyStr)
                    PlayerMapMarker.RemoveSkeletonLines(KeyStr)
                end
            end
        end
    end
end

function PlayerMapMarker.UpdateESPDistances()
    if not PlayerMapMarker.bUseScreenESP then return end
    local MyLoc = PlayerMapMarker.GetMyLocation()
    if not MyLoc then return end
    local PC = PlayerMapMarker.GetMyPlayerController()
    if not IsValid(PC) then return end
    PlayerMapMarker.UpdateCanvasTransform(PC)

    for KeyStr, ESPData in pairs(PlayerMapMarker.ESPWidgets) do
        local Character = ESPData.Character
        local Widget = ESPData.Widget
        local Container = Widget and (Widget.Container or Widget)
        local bWidgetValid = false
        pcall(function() bWidgetValid = Container and slua.isValid(Container) end)
        if Character and IsValid(Character) and Widget and bWidgetValid then
            local Loc = PlayerMapMarker.GetESPLocation(Character)
            if Loc then
                local Dist = PlayerMapMarker.CalcDistance(MyLoc, Loc)
                ESPData.LastDistance = Dist

                if PlayerMapMarker.bShowDistance then
                    local DistStr = ""
                    local Meters = 0
                    if Dist then
                        Meters = Dist / 100
                        if Meters < 1000 then DistStr = string.format("%dm", math.floor(Meters))
                        else DistStr = string.format("%.1fkm", Meters / 1000) end
                    end

                    local Name = ESPData.Name or "Unknown"
                    local Text = ""


                    if _G.LexusConfig.Esp9_Name then Text = Name end
                    if _G.LexusConfig.Esp9_Distance and DistStr and DistStr ~= "" then
                        if Text ~= "" then Text = string.format("%s [%s]", Text, DistStr) else Text = string.format("[%s]", DistStr) end
                    end

                    ESPData.LastDistStr = DistStr

                    Widget._LastESPText = nil
                    PlayerMapMarker.UpdateESPText(Widget, Text)
                end
            end
        end
    end
end

function PlayerMapMarker.ScanAndUpdate()
    local AllChars = PlayerMapMarker.GetAllCharacters()
    if not AllChars then RedBoxOverlay.SetCounts(0, 0) return 0 end

    local MyKey = PlayerMapMarker.GetMyPlayerKey()
    local MyLoc = PlayerMapMarker.GetMyLocation()

    local MyChar = nil
    pcall(function()
        local GDP = PlayerMapMarker.GetGameplayData()
        if GDP and GDP.GetLocalCharacter then MyChar = GDP.GetLocalCharacter()
        else local PC = PlayerMapMarker.GetMyPlayerController() if PC and PC.GetPawn then MyChar = PC:GetPawn() end end
    end)
    local MyTeamID = PlayerMapMarker.GetTeamID(MyChar)

    local realPlayers = 0
    local botPlayers = 0

    for PlayerKey, Character in pairs(AllChars) do
        if IsValid(Character) then
            local bIsMe = PlayerMapMarker.IsMe(Character, PlayerKey, MyKey)
            local bIsAI = PlayerMapMarker.IsAI(Character)
            local bIsAlive = PlayerMapMarker.IsAlive(Character)

            if bIsAlive and not bIsMe then
                local bIsMyTeam = false
                if MyTeamID ~= nil then
                    local targetTeamID = PlayerMapMarker.GetTeamID(Character)
                    if targetTeamID == MyTeamID then bIsMyTeam = true end
                end

                if not bIsMyTeam then
                    if bIsAI then botPlayers = botPlayers + 1
                    else realPlayers = realPlayers + 1 end
                end
            end
        end
    end


    if _G.LexusConfig.Esp9_Count then
        if RedBoxOverlay.bActive then RedBoxOverlay.SetCounts(realPlayers, botPlayers)
        else RedBoxOverlay.Start() end
    else
        if RedBoxOverlay.bActive then RedBoxOverlay.Stop() end
    end

    if PlayerMapMarker.bUseScreenESP then
        PlayerMapMarker.UpdateESP(AllChars, MyLoc)
        return 0
    end
    return 0
end

function PlayerMapMarker.AttachTimers()

end

function PlayerMapMarker.Start()
    if PlayerMapMarker.bActive then return end
    PlayerMapMarker.bActive = true
    PlayerMapMarker._FrameCount = 0

end

function PlayerMapMarker.Stop()
    PlayerMapMarker.bActive = false
    PlayerMapMarker._FrameCount = 0
    PlayerMapMarker.ClearAllESP()
end

_G.PlayerMapMarker = PlayerMapMarker


_G.FovCircleOverlay = {
    Container = nil,
    WidgetSlot = nil,
    Lines = {},
    NumSegments = 45,
    Thickness = 1.5,
    LastRadius = -1,
    LastColor = -1,
    LastCX = -1,
    LastCY = -1,
    PrecalcMath = nil
}

local function GetFOVColor(idx)
    if idx == 1 then return 1.0, 0.0, 0.0 end
    if idx == 2 then return 0.35, 0.15, 0.95 end
    if idx == 3 then return 0.0, 0.0, 1.0 end
    if idx == 4 then return 1.0, 1.0, 0.0 end
    if idx == 5 then return 0.65, 0.15, 1.0 end
    if idx == 6 then return 0.0, 1.0, 1.0 end
    if idx == 7 then return 1.0, 1.0, 1.0 end
    return 1.0, 1.0, 1.0
end

function _G.FovCircleOverlay.Create()
    if _G.FovCircleOverlay.Container and slua.isValid(_G.FovCircleOverlay.Container) then return true end

    local ParentCanvas = nil
    pcall(function()
        local InGameUITools = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools")
        local MainUI = InGameUITools.GetMainControlBaseUI()
        if slua.isValid(MainUI) then
            if slua.isValid(MainUI.CanvasPanel_0) then ParentCanvas = MainUI.CanvasPanel_0
            elseif slua.isValid(MainUI.CanvasPanel_42) then ParentCanvas = MainUI.CanvasPanel_42 end
        end
    end)

    if not ParentCanvas or not slua.isValid(ParentCanvas) then return false end

    local Container = nil
    pcall(function() Container = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", ParentCanvas) end)
    if not Container or not slua.isValid(Container) then return false end

    local FVector2D = import("Vector2D") or _G.FVector2D

    for i = 1, _G.FovCircleOverlay.NumSegments do
        local border = nil
        pcall(function() border = CGame:NewObjectFromPath("/Script/UMG.Border", Container) end)
        if border and slua.isValid(border) then
            pcall(function()
                border.RenderTransformPivot = FVector2D(0, 0.5)
                border:SetRenderTransformPivot(FVector2D(0, 0.5))
                border:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            end)
            local slot = Container:AddChildToCanvas(border)
            if slot then
                pcall(function() slot:SetAlignment(FVector2D(0, 0.5)) end)
            end
            _G.FovCircleOverlay.Lines[i] = { widget = border, slot = slot }
        end
    end

    local MainSlot = nil
    pcall(function() MainSlot = ParentCanvas:AddChildToCanvas(Container) end)
    if MainSlot then
        pcall(function()
            MainSlot:SetAutoSize(false)
            MainSlot:SetSize(FVector2D(0, 0))
            MainSlot:SetZOrder(995)
            MainSlot:SetAlignment(FVector2D(0, 0))
            MainSlot:SetPosition(FVector2D(0, 0))
        end)
    end
    _G.FovCircleOverlay.Container = Container
    _G.FovCircleOverlay.WidgetSlot = MainSlot
    return true
end

function _G.FovCircleOverlay.Update(pc, player)

    if not _G.LexusConfig.EspFovCircle then
        if _G.FovCircleOverlay.Container and slua.isValid(_G.FovCircleOverlay.Container) then
            pcall(function() _G.FovCircleOverlay.Container:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
            _G.FovCircleOverlay.LastRadius = -1
        end
        return
    end

    local fovVal = 30
    local colIdx = 7

    local cData = _G.LexusState.CustomTextData
    local WEAPON_TYPE = _G.__AimTouch_WeaponType or "NORMAL"
    local isADS = player.bIsGunADS or false


    if WEAPON_TYPE == "MORTAR" then
        fovVal = cData.AimTouchMortarFOV or 360
        colIdx = tonumber(cData.AimTouchMortarFOVColor) or 5
    elseif WEAPON_TYPE == "CROSSBOW" then
        fovVal = cData.AimTouchCrossbowFOV or 40
        colIdx = tonumber(cData.AimTouchSGFOVColor) or 1
    elseif WEAPON_TYPE == "BOW" then
        fovVal = cData.AimTouchBowFOV or 40
        colIdx = tonumber(cData.AimTouchSGFOVColor) or 1
    elseif WEAPON_TYPE == "SHOTGUN" then
        fovVal = cData.AimTouchSGFOV or 40
        colIdx = tonumber(cData.AimTouchSGFOVColor) or 1
    elseif isADS then
        if WEAPON_TYPE == "SNIPER" then
            fovVal = cData.AimTouchSniperFOV or 20
            colIdx = tonumber(cData.AimTouchSniperFOVColor) or 4
        else
            fovVal = cData.AimTouchScopeFOV or 30
            colIdx = tonumber(cData.AimTouchScopeFOVColor) or 6
        end
    else
        fovVal = cData.AimTouchHipFOV or 30
        colIdx = tonumber(cData.AimTouchHipFOVColor) or 7
    end

    local rawCX = _G.__AimTouch_CenterX or 960
    local rawCY = _G.__AimTouch_CenterY or 540
    local vpX = _G.__AimTouch_ViewportX or 1920


    if PlayerMapMarker and PlayerMapMarker.UpdateCanvasTransform then
        pcall(function() PlayerMapMarker.UpdateCanvasTransform(pc) end)
    end

    local FVector2D = import("Vector2D") or _G.FVector2D
    local screenCenter = FVector2D and FVector2D(rawCX, rawCY) or {X=rawCX, Y=rawCY}

    local canvasCenter = {X = rawCX, Y = rawCY}
    pcall(function() canvasCenter = PlayerMapMarker.ScreenPixelToCanvasLocal(pc, screenCenter) end)

    local centerX = canvasCenter.X
    local centerY = canvasCenter.Y

    local rawRadius = (fovVal / 100.0) * (vpX / 2.0)
    local scaleX = PlayerMapMarker and PlayerMapMarker._CanvasScaleX or 1.0
    local targetRadius = rawRadius * scaleX


    if _G.FovCircleOverlay.Container and slua.isValid(_G.FovCircleOverlay.Container) then
        local parent = nil
        pcall(function() parent = _G.FovCircleOverlay.Container:GetParent() end)
        if not parent or not slua.isValid(parent) then
            _G.FovCircleOverlay.Container = nil
        end
    end

    if not _G.FovCircleOverlay.Create() then return end
    pcall(function() _G.FovCircleOverlay.Container:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)


    if math.abs(_G.FovCircleOverlay.LastRadius - targetRadius) < 0.5
       and _G.FovCircleOverlay.LastColor == colIdx
       and math.abs(_G.FovCircleOverlay.LastCX - centerX) < 0.5
       and math.abs(_G.FovCircleOverlay.LastCY - centerY) < 0.5 then
        return
    end

    _G.FovCircleOverlay.LastRadius = targetRadius
    _G.FovCircleOverlay.LastColor = colIdx
    _G.FovCircleOverlay.LastCX = centerX
    _G.FovCircleOverlay.LastCY = centerY

    local FLinearColor = import("LinearColor") or _G.FLinearColor
    local r, g, b = GetFOVColor(colIdx)
    local dim = 0.55
    local color = FLinearColor and FLinearColor(r * dim, g * dim, b * dim, 1.0) or {R=r*dim*255, G=g*dim*255, B=b*dim*255, A=255}

    local numSegments = _G.FovCircleOverlay.NumSegments


    if not _G.FovCircleOverlay.PrecalcMath then
        _G.FovCircleOverlay.PrecalcMath = {}
        local angleStep = 360.0 / numSegments
        local math_cos = math.cos
        local math_sin = math.sin
        local math_rad = math.rad
        local math_atan2 = math.atan2 or math.atan

        for i = 1, numSegments do
            local angle1 = math_rad((i - 1) * angleStep)
            local angle2 = math_rad(i * angleStep)
            local c1, s1 = math_cos(angle1), math_sin(angle1)
            local c2, s2 = math_cos(angle2), math_sin(angle2)

            local dx_unit = c2 - c1
            local dy_unit = s2 - s1
            local dist_unit = math.sqrt(dx_unit*dx_unit + dy_unit*dy_unit)
            local angleDeg = math.deg(math_atan2(dy_unit, dx_unit))

            _G.FovCircleOverlay.PrecalcMath[i] = {
                c1 = c1, s1 = s1,
                dist_unit = dist_unit,
                angleDeg = angleDeg
            }
        end
    end

    pcall(function()
        local FVector2D = import("Vector2D") or _G.FVector2D
        for i = 1, numSegments do
            local mathData = _G.FovCircleOverlay.PrecalcMath[i]


            local x1 = targetRadius * mathData.c1
            local y1 = targetRadius * mathData.s1
            local dist = targetRadius * mathData.dist_unit

            local line = _G.FovCircleOverlay.Lines[i]
            if line and line.slot and slua.isValid(line.slot) then
                line.slot:SetPosition(FVector2D(centerX + x1, centerY + y1))
                line.slot:SetSize(FVector2D(dist + 0.8, _G.FovCircleOverlay.Thickness))
                line.widget:SetRenderAngle(mathData.angleDeg)
                line.widget:SetBrushColor(color)
            end
        end
    end)
end

function _G.CleanUpFovCircleOverlay()
    if _G.FovCircleOverlay and _G.FovCircleOverlay.Container and slua.isValid(_G.FovCircleOverlay.Container) then
        pcall(function() _G.FovCircleOverlay.Container:RemoveFromParent() end)
        pcall(function() _G.FovCircleOverlay.Container:ConditionalBeginDestroy() end)
    end
    if _G.FovCircleOverlay then
        _G.FovCircleOverlay.Container = nil
        _G.FovCircleOverlay.WidgetSlot = nil
        _G.FovCircleOverlay.LastRadius = -1
    end
end


local DungCuOverlay = {
    Widget = nil,
    Slot = nil
}

local function CleanUpPermanentDungCu()
    if DungCuOverlay.Widget and slua.isValid(DungCuOverlay.Widget) then
        pcall(function() DungCuOverlay.Widget:RemoveFromParent() end)
        pcall(function() DungCuOverlay.Widget:ConditionalBeginDestroy() end)
    end
    DungCuOverlay.Widget = nil
    DungCuOverlay.Slot = nil
end

local function EnsurePermanentDungCu()

    if _G.PlayerMapMarker and not _G.DungCu_Protected then
        local old_IsOurESPWidget = _G.PlayerMapMarker.IsOurESPWidget
        _G.PlayerMapMarker.IsOurESPWidget = function(w)

            if DungCuOverlay.Widget and w == DungCuOverlay.Widget then
                return false
            end
            if _G.FovCircleOverlay and _G.FovCircleOverlay.Container and w == _G.FovCircleOverlay.Container then
                return false
            end
            if old_IsOurESPWidget then return old_IsOurESPWidget(w) end
            return false
        end
        _G.DungCu_Protected = true
    end


    if DungCuOverlay.Widget and slua.isValid(DungCuOverlay.Widget) then
        pcall(function() DungCuOverlay.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)

        local PC = _G.PlayerMapMarker and _G.PlayerMapMarker.GetMyPlayerController()
        if slua.isValid(PC) and DungCuOverlay.Slot then


            if not _G.PlayerMapMarker.ESPCanvas or not slua.isValid(_G.PlayerMapMarker.ESPCanvas) then
                pcall(function() _G.PlayerMapMarker.InitESPCanvas() end)
            end


            pcall(function() _G.PlayerMapMarker.UpdateCanvasTransform(PC) end)

            local fromX, fromY = _G.PlayerMapMarker.GetSnapLineStartPos(PC)
            local FVector2D = import("Vector2D") or _G.FVector2D
            pcall(function() DungCuOverlay.Slot:SetPosition(FVector2D(fromX, fromY - 8)) end)
        end
        return
    end


    local ParentCanvas = nil
    pcall(function()
        local InGameUITools = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools")
        local MainControlBaseUI = InGameUITools and InGameUITools.GetMainControlBaseUI()
        if MainControlBaseUI and slua.isValid(MainControlBaseUI) then
            ParentCanvas = MainControlBaseUI.CanvasPanel_0
            if not slua.isValid(ParentCanvas) then ParentCanvas = MainControlBaseUI.CanvasPanel_42 end
        end
    end)

    if not ParentCanvas or not slua.isValid(ParentCanvas) then return end

    local txtTitle = nil
    pcall(function() txtTitle = CGame:NewObjectFromPath("/Script/UMG.TextBlock", ParentCanvas) end)
    if txtTitle and slua.isValid(txtTitle) then
        pcall(function()
            txtTitle:SetText("")
            local FLinearColor = import("LinearColor") or _G.FLinearColor
            local FSlateColor = import("SlateColor") or import("/Script/SlateCore.SlateColor")
            local redLinear = FLinearColor and FLinearColor(1.0, 0.0, 0.0, 1.0) or {R=255, G=0, B=0, A=255}
            if FSlateColor then txtTitle:SetColorAndOpacity(FSlateColor(redLinear)) else txtTitle:SetColorAndOpacity(redLinear) end

            if txtTitle.Font then
                local font = txtTitle.Font
                font.Size = 24
                txtTitle.Font = font
            end

            local FVector2D = import("Vector2D") or _G.FVector2D
            txtTitle:SetRenderScale(FVector2D(1.0, 1.0))
            txtTitle:SetRenderTransformPivot(FVector2D(0.5, 0.5))
            txtTitle:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end)

        local txtSlot = ParentCanvas:AddChildToCanvas(txtTitle)
        if txtSlot then
            pcall(function()
                txtSlot:SetAutoSize(true)
                local FVector2D = import("Vector2D") or _G.FVector2D
                txtSlot:SetAlignment(FVector2D(0.5, 1.0))
                txtSlot:SetZOrder(9999)
            end)
            DungCuOverlay.Slot = txtSlot
        end
        DungCuOverlay.Widget = txtTitle
    end
end


local MAIN_LOOP_INTERVAL = 1.0 / 30.0
local ESP_SCAN_INTERVAL = 0.40
local ESP_DISTANCE_INTERVAL = 0.30
local ESP_POSITION_INTERVAL = 0.016
local _LastMainLoopTime = 0
local _LastESPPositionTime = 0
local _NativeESPInitDone = false
local _VIPMenuInitDone = false
local _LastCameraConfigKey = nil

local function UpdateCachedCameraConfig(pc, localPlayer)
    if not Valid(pc) or not Valid(localPlayer) then return end

    local isAiming = localPlayer.bIsWeaponAiming or localPlayer.bIsGunADS or false
    local currentVehicle = localPlayer.CurrentVehicle
    if not currentVehicle and type(localPlayer.GetVehicle) == "function" then
        pcall(function() currentVehicle = localPlayer:GetVehicle() end)
    end

    local isInVehicle = Valid(currentVehicle) or localPlayer.bIsInVehicle or false
    local data = _G.LexusState.CustomTextData or {}
    local targetScope = data.IpadViewScopeFOV or 60
    local targetTPP = data.IpadViewFOV or 120
    local targetVeh = data.IpadViewVehicleFOV or 120

    local key = table.concat({
        tostring(isAiming),
        tostring(isInVehicle),
        tostring(_G.LexusConfig.IpadView),
        tostring(_G.LexusConfig.IpadViewVehicle),
        tostring(_G.LexusConfig.IpadViewScope),
        tostring(targetScope),
        tostring(targetTPP),
        tostring(targetVeh)
    }, "|")

    if key == _LastCameraConfigKey then return end
    _LastCameraConfigKey = key

    local camMgr = pc.PlayerCameraManager
    local uTPPCam = localPlayer.ThirdPersonCameraComponent
    local uVehCam = localPlayer.VehicleCameraComponent

    pcall(function()
        if isAiming then
            if _G.LexusConfig.IpadViewScope then
                if type(pc.FOV) == "function" then pc:FOV(targetScope) end
                if Valid(camMgr) then
                    camMgr.DefaultFOV = targetScope
                    if type(camMgr.SetFOV) == "function" then camMgr:SetFOV(targetScope) end
                end
            else
                if type(pc.FOV) == "function" then pc:FOV(0) end
                if Valid(camMgr) and type(camMgr.UnlockFOV) == "function" then camMgr:UnlockFOV() end
            end
            return
        end

        if not isInVehicle or not _G.LexusConfig.IpadViewVehicle then
            if type(pc.FOV) == "function" then pc:FOV(0) end
            if Valid(camMgr) and type(camMgr.UnlockFOV) == "function" then camMgr:UnlockFOV() end
        end

        if not isInVehicle then
            local desiredTPP = _G.LexusConfig.IpadView and targetTPP or 90
            if Valid(uTPPCam) and uTPPCam.FieldOfView ~= desiredTPP then
                uTPPCam.FieldOfView = desiredTPP
            end
        else
            local desiredVeh = _G.LexusConfig.IpadViewVehicle and targetVeh or 90
            if Valid(uVehCam) and uVehCam.FieldOfView ~= desiredVeh then
                uVehCam.FieldOfView = desiredVeh
            end

            if _G.LexusConfig.IpadViewVehicle and targetVeh > 90 then
                if type(pc.FOV) == "function" then pc:FOV(targetVeh) end
                if Valid(camMgr) then
                    camMgr.DefaultFOV = targetVeh
                    if type(camMgr.SetFOV) == "function" then camMgr:SetFOV(targetVeh) end
                end
            end
        end
    end)
end

local function MainLoop()
    if _G._LICENSE_OK ~= true then return end

    local now = os.clock()
    if _LastMainLoopTime > 0 and (now - _LastMainLoopTime) < MAIN_LOOP_INTERVAL then
        return
    end
    _LastMainLoopTime = now

    pcall(function()
        local SystemLib = import("KismetSystemLibrary")
        if SystemLib and not _G.FakeHWID_Hooked then

            _G.Original_GetDeviceId = SystemLib.GetDeviceId


            SystemLib.GetDeviceId = function(...)
                if _G.LexusConfig.FakeHWID then
                    if not _G.FakeHWID_String then

                        local chars = "0123456789abcdef"
                        local hwid = ""
                        for i = 1, 32 do
                            hwid = hwid .. chars:sub(math.random(1, 16), math.random(1, 16))
                        end
                        _G.FakeHWID_String = hwid
                    end

                    return _G.FakeHWID_String
                end


                if _G.Original_GetDeviceId then return _G.Original_GetDeviceId(...) end
                return "UNKNOWN"
            end
            _G.FakeHWID_Hooked = true
        end
    end)


    _G.GetOriginalHWID = function()
        if _G.Original_GetDeviceId then
            return tostring(_G.Original_GetDeviceId())
        end
        local SystemLib = import("KismetSystemLibrary")
        if SystemLib and type(SystemLib.GetDeviceId) == "function" then
            return tostring(SystemLib.GetDeviceId())
        end
        return "UNKNOWN_DEVICE"
    end


    if _G.LexusState.CustomTextData == nil then
        _G.LexusState.CustomTextData = {OuterSpeed = 10, InnerSpeed = 10, HRecoil = 0.3, VRecoil = 0.3, MagicHead = 1.0, MagicBody = 1.0, MagicLegs = 1.0, IpadViewFOV = 120, IpadViewVehicleFOV = 120, IpadViewScopeFOV = 100, AimTouchHipPrio = 1, AimTouchHipBone = 1, AimTouchHipCond = 1, AimTouchHipSpeed = 50, AimTouchHipFOV = 30, AimTouchHipDist = 250, AimTouchSGPrio = 1, AimTouchSGBone = 2, AimTouchSGCond = 1, AimTouchSGSpeed = 80, AimTouchSGFOV = 40, AimTouchSGDist = 30, AimTouchScopePrio = 1, AimTouchScopeBone = 2, AimTouchScopeCond = 1, AimTouchScopeSpeed = 40, AimTouchScopeFOV = 20, AimTouchScopeDist = 300, AimTouchSniperPrio = 1, AimTouchSniperBone = 1, AimTouchSniperCond = 1, AimTouchSniperSpeed = 30, AimTouchSniperFOV = 20, AimTouchSniperDist = 400, FastCarSpeed = 2000}
    end

    local okData, GameplayData = pcall(require, "GameLua.GameCore.Data.GameplayData")
    if not okData or not GameplayData then return end
    local pc = GameplayData.GetPlayerController()
    local localPlayer = nil
    if Valid(pc) then localPlayer = pc:GetPlayerCharacterSafety() end


    if not Valid(localPlayer) then
        if _G.PlayerMapMarker and type(_G.PlayerMapMarker.Stop) == "function" then
            _G.PlayerMapMarker.Stop()
        end
        if _G.RedBoxOverlay and type(_G.RedBoxOverlay.Stop) == "function" then
            _G.RedBoxOverlay.Stop()
        end

        if _G.LexusState.TrackedMarks then
            for markId, _ in pairs(_G.LexusState.TrackedMarks) do SafeRemoveMark(markId) end
        end


        _G.AppliedVehicleWall = {}
        _G.AppliedItemESP = {}
        _G.CachedItems = {}
        _G.CachedVehicles = {}
        _G.CachedActiveBombs = {}
        _G.CachedItemBombs = {}
        _G.AimTouchVisCache = {}
        _G.ActiveBombTimers = {}
        _G.BombCache = setmetatable({}, { __mode = "k" })
        _G.NonBombCache = setmetatable({}, { __mode = "k" })
        _G.AddOutfitLastAppliedSkin = {}

        _G.LexusState.TrackedMarks = {}
        for key, data in pairs(_G.LexusState.EnemyMarks) do
            if data and data.MIDs then
                for meshStr, midTable in pairs(data.MIDs) do
                    for k, _ in pairs(midTable) do midTable[k] = nil end
                end
            end
            if data and data.MIDs_V3 then
                for meshStr, midTable in pairs(data.MIDs_V3) do
                    for k, _ in pairs(midTable) do midTable[k] = nil end
                end
            end
        end

        _G.LexusState.EnemyMarks = {}
        _G.AK_OrigHitboxes = {}
        _G.AK_ModdedPhysAssets = {}
        _G.LexusState.PrevGraphicsState = {}

        _LastMainLoopTime = 0
        _LastESPPositionTime = 0
        _LastCameraConfigKey = nil

        if _G.CleanUpEnemyCounterWidget then _G.CleanUpEnemyCounterWidget() end
        CleanUpPermanentDungCu()
        if _G.CleanUpFovCircleOverlay then _G.CleanUpFovCircleOverlay() end
        return
    end

    local Cached_PPM = nil
    pcall(function() Cached_PPM = import("PostProcessManager").GetInstance() end)
    local Cached_SecurityCommonUtils = nil
    pcall(function() Cached_SecurityCommonUtils = require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils") end)
    local Cached_MyHUD = pc and pc.MyHUD or nil

    if _G.LexusConfig.UnlockFPS and not _G.LexusState.GraphicsUnlocked then
        InitializeGraphicsUnlock()
    end

    if not _NativeESPInitDone then
        InitializeNativeESP()
        _NativeESPInitDone = true
    end

    if not _VIPMenuInitDone then
        ShowLexusVIPMenu()
        _VIPMenuInitDone = true
    end


    EnsurePermanentDungCu()


    if _G.LexusConfig.WallVehicle or _G.LexusConfig.EspItem_Master then
        _G.RunOptimizedItemAndVehicleESP(pc)
    end


    UpdateCachedCameraConfig(pc, localPlayer)


    pcall(function()
        local ui_util = require("client.common.ui_util")
        if ui_util then
            local vp = ui_util.GetViewportSize()
            if vp then
                _G.__AimTouch_ViewportX = vp.X
                _G.__AimTouch_CenterX = vp.X * 0.5
                _G.__AimTouch_CenterY = vp.Y * 0.5
            end
        end

        local wName = ""
        local weapon = localPlayer.WeaponManagerComponent and localPlayer.WeaponManagerComponent.CurrentWeaponReplicated
        if not weapon and type(localPlayer.GetCurrentShootWeapon) == "function" then
            weapon = localPlayer:GetCurrentShootWeapon()
        end
        if slua.isValid(weapon) then
            wName = type(weapon.GetWeaponName) == "function" and weapon:GetWeaponName() or ""
            local wID = type(weapon.GetWeaponID) == "function" and weapon:GetWeaponID() or 0
            if (wID >= 1030000 and wID < 1040000) or wName:find("S686") or wName:find("S1897") or wName:find("S12") or wName:find("DBS") or wName:find("M1014") then
                _G.__AimTouch_WeaponType = "SHOTGUN"
            elseif wName:find("Kar98") or wName:find("M24") or wName:find("AWM") or wName:find("Mosin") or wName:find("Win94") or wName:find("AMR") or wName:find("SKS") or wName:find("SLR") or wName:find("Mini") or wName:find("Mk14") or wName:find("QBU") or wName:find("Mk12") or wName:find("VSS") then
                _G.__AimTouch_WeaponType = "SNIPER"
            elseif wName:lower():find("mortar") or wName:lower():find("cối") then
                _G.__AimTouch_WeaponType = "MORTAR"
            elseif wName:lower():find("crossbow") or wName:lower():find("nỏ") then
                _G.__AimTouch_WeaponType = "CROSSBOW"
            elseif wName:lower():find("bow") or wName:lower():find("cung") then
                _G.__AimTouch_WeaponType = "BOW"
            else
                _G.__AimTouch_WeaponType = "NORMAL"
            end
        end
    end)

    if _G.LexusConfig.AimTouchEnable then
        _G.AimTouch()
    end

    if _G.FovCircleOverlay then
        pcall(function() _G.FovCircleOverlay.Update(pc, localPlayer) end)
    end


    if not _G.LastGlowTime or (os.clock() - _G.LastGlowTime) > 0.5 then
        _G.LastGlowTime = os.clock()
        if _G.ApplyWeaponGlow then _G.ApplyWeaponGlow(localPlayer) end
    end


    pcall(function()
        if _G.LexusConfig.CustomAimbot and localPlayer.bIsWeaponFiring and localPlayer.bIsGunADS then
            local outerRecoilVal = _G.LexusState.CustomTextData.OuterRecoil or 0
            if outerRecoilVal > 0 then
                local curTime = os.clock()


                if not _G.RecoilTargetCacheTime or (curTime - _G.RecoilTargetCacheTime) > 0.2 then
                    _G.RecoilTargetCacheTime = curTime
                    _G.HasRecoilTargetCached = false

                    local ui_util = require("client.common.ui_util")
                    if ui_util then
                        local viewportSize = ui_util.GetViewportSize()
                        if viewportSize then
                            local centerX = viewportSize.X * 0.5
                            local centerY = viewportSize.Y * 0.5
                            local FOV_RADIUS = (6 / 100.0) * (viewportSize.X / 2.0)

                            local enemies = _G.GetEnemyTargetsFromActors(40000)
                            if enemies and #enemies > 0 then
                                local FVector2D = import("Vector2D")
                                for _, target in ipairs(enemies) do
                                    if slua.isValid(target) and target.HealthStatus ~= 1 then
                                        local tPos = type(target.K2_GetActorLocation) == "function" and target:K2_GetActorLocation() or nil
                                        if tPos then
                                            local screen = FVector2D()
                                            if pc:ProjectWorldLocationToScreen(tPos, screen, false) and screen.X > 0 and screen.Y > 0 then
                                                local dx = screen.X - centerX
                                                local dy = screen.Y - centerY
                                                if math.sqrt(dx*dx + dy*dy) <= FOV_RADIUS then
                                                    _G.HasRecoilTargetCached = true
                                                    break
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

                if _G.HasRecoilTargetCached then
                    local currentRot = pc:GetControlRotation()
                    if currentRot then
                        local pullDownForce = (outerRecoilVal / 50.0) * 1.5
                        currentRot.Pitch = currentRot.Pitch - pullDownForce
                        pc:SetControlRotation(currentRot, "CustomAimbotRecoil")
                    end
                end
            end
        else
            _G.HasRecoilTargetCached = false
        end
    end)


    -- Hard license gate: skin loop and every skin application path stay stopped until verified.
    if _G._LICENSE_OK ~= true then return end
    if _G.LexusConfig.ModSkin then
        local curTime = os.clock()

        if not _G.LastSkinUpdateTime or (curTime - _G.LastSkinUpdateTime) > 2.5 then
            _G.LastSkinUpdateTime = curTime
            pcall(function()
                if _G._LICENSE_OK ~= true then return end
                local isAlive = type(localPlayer.IsAlive) == "function" and localPlayer:IsAlive() or true
                if isAlive then
                    if _G.HandlePetLogic then _G.HandlePetLogic() end

                    if _G.LexusConfig.SkinDeadBox and _G.DeadBox_TemperRequest and _G.NeedCheckDeadBoxTimer > 0 then
                        _G.DeadBox_TemperRequest(pc)
                    end

                    if _G.AddOutfit then

                        if _G.AddOutfit.isInRealMatch() then

                            _G.AddOutfitLobbyRestored = false


                            local ticker = require("common.time_ticker")
                            if ticker and ticker.AddTimerOnce then
                                _G.AddOutfit.matchApplyAllSlots(localPlayer)
                                ticker.AddTimerOnce(0.2, function()
                                    if _G._LICENSE_OK == true and slua.isValid(localPlayer) and _G.AddOutfit.isInRealMatch() then
                                        _G.AddOutfit.matchApplyHat(localPlayer)
                                    end
                                end)
                                ticker.AddTimerOnce(0.4, function()
                                    if _G._LICENSE_OK == true and slua.isValid(localPlayer) and _G.AddOutfit.isInRealMatch() then
                                        _G.AddOutfit.matchApplyWeaponSkin(localPlayer)
                                    end
                                end)
                                ticker.AddTimerOnce(0.6, function()
                                    if _G._LICENSE_OK == true and slua.isValid(localPlayer) and _G.AddOutfit.isInRealMatch() and _G.AddOutfit.isCharacterAirborne(localPlayer) then
                                        _G.AddOutfit.applyAirborneSlots(localPlayer, true)
                                    end
                                end)
                            else
                                _G.AddOutfit.matchApplyAllSlots(localPlayer)
                                _G.AddOutfit.matchApplyHat(localPlayer)
                                _G.AddOutfit.matchApplyWeaponSkin(localPlayer)
                                if _G.AddOutfit.isCharacterAirborne(localPlayer) then
                                    _G.AddOutfit.applyAirborneSlots(localPlayer, true)
                                end
                            end
                        else

                            _G.AddOutfit.reapplyLobbyEquipped()
                        end
                    end
                end
            end)
        end
    end


    pcall(function()
        if Valid(pc) then
            if pc.HiggsBoson then pc.HiggsBoson.bMHActive = false; pc.HiggsBoson.bCallPreReplication = false end
            if pc.HiggsBosonComponent then pc.HiggsBosonComponent.bMHActive = false; pc.HiggsBosonComponent.bCallPreReplication = false end
        end
    end)


    pcall(function()
        local autoComp = localPlayer.AutoAimComp
        if Valid(autoComp) then
            if not _G.LexusState.OrigAutoAimCompCached then
                _G.LexusState.OrigAutoAimCompCached = {
                    bOnlyHitHead = autoComp.bOnlyHitHead,
                    HeadBoneName = autoComp.HeadBoneName,
                    Bones = autoComp.Bones,
                    ChestBoneName = autoComp.ChestBoneName,
                    PelvisBoneName = autoComp.PelvisBoneName,
                    HeadPriority = autoComp.AimAssistConfig and autoComp.AimAssistConfig.HeadPriority,
                    ChestPriority = autoComp.AimAssistConfig and autoComp.AimAssistConfig.ChestPriority,
                    PelvisPriority = autoComp.AimAssistConfig and autoComp.AimAssistConfig.PelvisPriority
                }
            end

            if _G.LexusConfig.AutoHead then
                autoComp.bOnlyHitHead = true
                autoComp.HeadBoneName = "Head"
                pcall(function() autoComp.Bones = {"Head"} end)
                autoComp.ChestBoneName = "Head"
                autoComp.PelvisBoneName = "Head"
                if autoComp.AimAssistConfig then
                    autoComp.AimAssistConfig.HeadPriority = 100
                    autoComp.AimAssistConfig.ChestPriority = 100
                    autoComp.AimAssistConfig.PelvisPriority = 100
                end
            else
                local orig = _G.LexusState.OrigAutoAimCompCached
                autoComp.bOnlyHitHead = orig.bOnlyHitHead
                autoComp.HeadBoneName = orig.HeadBoneName
                pcall(function() autoComp.Bones = orig.Bones or {"Spine_01", "Pelvis", "Head"} end)
                autoComp.ChestBoneName = orig.ChestBoneName
                autoComp.PelvisBoneName = orig.PelvisBoneName
                if autoComp.AimAssistConfig then
                    autoComp.AimAssistConfig.HeadPriority = orig.HeadPriority or 1
                    autoComp.AimAssistConfig.ChestPriority = orig.ChestPriority or 1
                    autoComp.AimAssistConfig.PelvisPriority = orig.PelvisPriority or 1
                end
            end
        end
    end)

    if _G.LexusConfig.WallClimb then
        pcall(function()
            local charMove = localPlayer.CharacterMovement
            if Valid(charMove) then
                if not _G.LexusState.WallClimbOriginals then
                    _G.LexusState.WallClimbOriginals = { WalkableFloorAngle = charMove.WalkableFloorAngle, MaxStepHeight = charMove.MaxStepHeight }
                end
                charMove.WalkableFloorAngle = 199.0
                charMove.MaxStepHeight = 999.0
                _G.LexusState.WallClimbApplied = true
            end
        end)
    elseif _G.LexusState.WallClimbApplied then
        pcall(function()
            local charMove = localPlayer.CharacterMovement
            if Valid(charMove) and _G.LexusState.WallClimbOriginals then
                charMove.WalkableFloorAngle = _G.LexusState.WallClimbOriginals.WalkableFloorAngle or 50.0
                charMove.MaxStepHeight = _G.LexusState.WallClimbOriginals.MaxStepHeight or 45.0
            end
        end)
        _G.LexusState.WallClimbApplied = false
    end

    if _G.LexusConfig.FastCar then
        pcall(function()
            local currentVehicle = localPlayer.CurrentVehicle or (type(localPlayer.GetVehicle) == "function" and localPlayer:GetVehicle())
            if Valid(currentVehicle) then
                local rootComp = currentVehicle.RootComponent or (type(currentVehicle.K2_GetRootComponent) == "function" and currentVehicle:K2_GetRootComponent())

                if Valid(rootComp) and type(rootComp.SetAllPhysicsLinearVelocity) == "function" then
                    local isAccelerating = false
                    local moveComp = currentVehicle.VehicleMovement or currentVehicle.MovementComponent
                    if Valid(moveComp) then
                        local throttle = moveComp.ThrottleInput or 0
                        if type(moveComp.GetThrottleInput) == "function" then
                            throttle = moveComp:GetThrottleInput()
                        end
                        if throttle > 0.05 or throttle < -0.05 then
                            isAccelerating = true
                        end
                    end
                    if currentVehicle.bIsPressingGas or (currentVehicle.Throttle and currentVehicle.Throttle ~= 0) then
                        isAccelerating = true
                    end

                    local currentVel = nil
                    if type(currentVehicle.GetVelocity) == "function" then
                        currentVel = currentVehicle:GetVelocity()
                    elseif type(rootComp.GetPhysicsLinearVelocity) == "function" then
                        currentVel = rootComp:GetPhysicsLinearVelocity()
                    elseif rootComp.ComponentVelocity then
                        currentVel = rootComp.ComponentVelocity
                    end

                    if currentVel then
                        local currentSpeed = math.sqrt(currentVel.X^2 + currentVel.Y^2)
                        local minSpeedToBoost = 50.0


                        local maxSpeed = _G.LexusState.CustomTextData.FastCarSpeed or 3000.0


                        local accelFactor = 1.5

                        local brakeFactor = 0.85

                        if currentSpeed > minSpeedToBoost then
                            local dirX = currentVel.X / currentSpeed
                            local dirY = currentVel.Y / currentSpeed

                            if isAccelerating then
                                local targetSpeed = currentSpeed * accelFactor
                                if targetSpeed > maxSpeed then targetSpeed = maxSpeed end
                                local newX = dirX * targetSpeed
                                local newY = dirY * targetSpeed
                                local newZ = currentVel.Z
                                rootComp:SetAllPhysicsLinearVelocity(FVector(newX, newY, newZ), false)
                            else
                                local targetSpeed = currentSpeed * brakeFactor
                                if targetSpeed > minSpeedToBoost then
                                    local newX = dirX * targetSpeed
                                    local newY = dirY * targetSpeed
                                    local newZ = currentVel.Z
                                    rootComp:SetAllPhysicsLinearVelocity(FVector(newX, newY, newZ), false)
                                end
                            end
                        end
                    end
                end
            end
        end)
    end


    local now = os.clock()
    pcall(function()
        local lsg = require("client.slua.logic.setting.logic_setting_graphics")
        local gi = lsg.GetGameInstance()
        if gi then
            if _G.LexusConfig.RemoveGrass and not _G.LexusState.PrevGraphicsState.RemoveGrass then
                gi:ExecuteCMD("grass.DensityScale", "0")
                gi:ExecuteCMD("grass.DiscardDataOnLoad", "1")
                _G.LexusState.PrevGraphicsState.RemoveGrass = true
            elseif not _G.LexusConfig.RemoveGrass and _G.LexusState.PrevGraphicsState.RemoveGrass then
                gi:ExecuteCMD("grass.DensityScale", "1")
                gi:ExecuteCMD("grass.DiscardDataOnLoad", "0")
                _G.LexusState.PrevGraphicsState.RemoveGrass = false
            end


            if _G.LexusConfig.RemoveTrees and not _G.LexusState.PrevGraphicsState.RemoveTrees then
                gi:ExecuteCMD("foliage.DensityScale", "0")
                gi:ExecuteCMD("r.Foliage.DensityScale", "0")
                gi:ExecuteCMD("foliage.MinimumScreenSize", "10000")
                gi:ExecuteCMD("r.DisableTreeRender", "1")
                _G.LexusState.PrevGraphicsState.RemoveTrees = true
            elseif not _G.LexusConfig.RemoveTrees and _G.LexusState.PrevGraphicsState.RemoveTrees then
                gi:ExecuteCMD("foliage.DensityScale", "1")
                gi:ExecuteCMD("r.Foliage.DensityScale", "1")
                gi:ExecuteCMD("foliage.MinimumScreenSize", "0.0001")
                gi:ExecuteCMD("r.DisableTreeRender", "0")
                _G.LexusState.PrevGraphicsState.RemoveTrees = false
            end

            if _G.LexusConfig.RemoveFog and not _G.LexusState.PrevGraphicsState.RemoveFog then
                gi:ExecuteCMD("r.SkyAtmosphere", "1")
                gi:ExecuteCMD("r.Fog", "0")
                gi:ExecuteCMD("r.VolumetricFog", "0")
                _G.LexusState.PrevGraphicsState.RemoveFog = true
            elseif not _G.LexusConfig.RemoveFog and _G.LexusState.PrevGraphicsState.RemoveFog then
                gi:ExecuteCMD("r.SkyAtmosphere", "1")
                gi:ExecuteCMD("r.Fog", "1")
                gi:ExecuteCMD("r.VolumetricFog", "1")
                _G.LexusState.PrevGraphicsState.RemoveFog = false
            end

            if _G.LexusConfig.WhiteBody and not _G.LexusState.PrevGraphicsState.WhiteBody then
                gi:ExecuteCMD("r.CharacterDiffuseOffset", "2")
                gi:ExecuteCMD("r.CharacterDiffusePower", "5")
                gi:ExecuteCMD("r.CharacterMinShadowFactor", "100")
                _G.LexusState.PrevGraphicsState.WhiteBody = true
            elseif not _G.LexusConfig.WhiteBody and _G.LexusState.PrevGraphicsState.WhiteBody then
                gi:ExecuteCMD("r.CharacterDiffuseOffset", "0")
                gi:ExecuteCMD("r.CharacterDiffusePower", "1")
                gi:ExecuteCMD("r.CharacterMinShadowFactor", "1")
                _G.LexusState.PrevGraphicsState.WhiteBody = false
            end

            if _G.LexusConfig.ColorBodyV2 and not _G.LexusState.PrevGraphicsState.ColorBodyV2 then
                gi:ExecuteCMD("r.CharacterMinShadowFactor", "4")
                gi:ExecuteCMD("r.CharacterDiffuseOffset", "200")
                gi:ExecuteCMD("r.CharacterDiffusePower", "200")
                _G.LexusState.PrevGraphicsState.ColorBodyV2 = true
            elseif not _G.LexusConfig.ColorBodyV2 and _G.LexusState.PrevGraphicsState.ColorBodyV2 then
                gi:ExecuteCMD("r.CharacterMinShadowFactor", "1")
                gi:ExecuteCMD("r.CharacterDiffuseOffset", "0")
                gi:ExecuteCMD("r.CharacterDiffusePower", "1")
                _G.LexusState.PrevGraphicsState.ColorBodyV2 = false
            end


            if _G.LexusConfig.BlackSky and not _G.LexusState.PrevGraphicsState.BlackSky then
                gi:ExecuteCMD("r.CylinderMaxDrawHeight", "9999")
                _G.LexusState.PrevGraphicsState.BlackSky = true
            elseif not _G.LexusConfig.BlackSky and _G.LexusState.PrevGraphicsState.BlackSky then
                gi:ExecuteCMD("r.CylinderMaxDrawHeight", "0000")
                _G.LexusState.PrevGraphicsState.BlackSky = false
            end
        end
    end)

    pcall(function()
        local weapon = nil
        pcall(function()
            local weaponManager = localPlayer.WeaponManagerComponent
            if Valid(weaponManager) and type(weaponManager.GetCurrentWeapon) == "function" then
                weapon = weaponManager:GetCurrentWeapon()
            end
        end)
        if not Valid(weapon) then
            if type(localPlayer.GetCurrentShootWeapon) == "function" then weapon = localPlayer:GetCurrentShootWeapon()
            elseif type(localPlayer.GetCurrentWeapon) == "function" then weapon = localPlayer:GetCurrentWeapon() end
        end

        if Valid(weapon) then
            local entities = {}
            if Valid(weapon.ShootWeaponEntity_GEN_VARIABLE) then table.insert(entities, weapon.ShootWeaponEntity_GEN_VARIABLE) end
            if Valid(weapon.ShootWeaponEntity) then table.insert(entities, weapon.ShootWeaponEntity) end
            if Valid(weapon.ShootWeaponComponent) and Valid(weapon.ShootWeaponComponent.ShootWeaponEntityComponent) then
                table.insert(entities, weapon.ShootWeaponComponent.ShootWeaponEntityComponent)
            end

            for _, entity in ipairs(entities) do
                local anyWeaponModOn = _G.LexusConfig.CustomHRecoil or _G.LexusConfig.CustomVRecoil or _G.LexusConfig.LessShake or _G.LexusConfig.Accuracy or _G.LexusConfig.Crosshair or _G.LexusConfig.GodMode or _G.LexusConfig.AutoHead or _G.LexusConfig.CustomAimbot or _G.LexusConfig.CustomAimbotClose or _G.LexusConfig.AimbotMode ~= "None" or _G.LexusConfig.LessRecoil or _G.LexusConfig.VerticalRecoil

                if anyWeaponModOn then
                    if not entity.OriginalStatsCached then
                        entity.OriginalStatsCached = {
                            GameDeviationFactor = entity.GameDeviationFactor,
                            GameDeviationAccuracy = entity.GameDeviationAccuracy,
                            BulletFireSpeed = entity.BulletFireSpeed,
                            ShootInterval = entity.ShootInterval,
                            BaseDamage = entity.BaseDamage,
                            AccessoriesHRecoilFactor = entity.AccessoriesHRecoilFactor,
                            AccessoriesVRecoilFactor = entity.AccessoriesVRecoilFactor,
                            RecoilKick = entity.RecoilKick,
                            RecoilKickADS = entity.RecoilKickADS,
                            AnimationKick = entity.AnimationKick
                        }
                    end

                    if _G.LexusConfig.CustomHRecoil then entity.AccessoriesHRecoilFactor = _G.LexusState.CustomTextData.HRecoil or 0.3
                    elseif _G.LexusConfig.LessRecoil then entity.AccessoriesHRecoilFactor = 0.3 end

                    if _G.LexusConfig.CustomVRecoil then entity.AccessoriesVRecoilFactor = _G.LexusState.CustomTextData.VRecoil or 0.3
                    elseif _G.LexusConfig.VerticalRecoil then entity.AccessoriesVRecoilFactor = 0.3 end

                    if _G.LexusConfig.LessShake then entity.RecoilKick = 0.0; entity.RecoilKickADS = 0.0; entity.AnimationKick = 0.0 end
                    if _G.LexusConfig.Accuracy then entity.GameDeviationAccuracy = 0.0 end
                    if _G.LexusConfig.Crosshair then entity.GameDeviationFactor = 0.0 end
                    if _G.LexusConfig.GodMode then entity.BulletFireSpeed = 500000.0; entity.ShootInterval = 0.001; entity.BaseDamage = 60000.0 end

                    if entity.AutoAimingConfig then
                        if not entity.OriginalAutoAimCached then
                            entity.OriginalAutoAimCached = {
                                OuterSpeed = entity.AutoAimingConfig.OuterRange and entity.AutoAimingConfig.OuterRange.Speed,
                                InnerSpeed = entity.AutoAimingConfig.InnerRange and entity.AutoAimingConfig.InnerRange.Speed
                            }
                        end

                        if _G.LexusConfig.AutoHead then
                            pcall(function() entity.AutoAimingConfig.Bones = { "Head", "Head", "Head" } end)
                        end

                        if _G.LexusConfig.CustomAimbot then
                            local speed = _G.LexusState.CustomTextData.OuterSpeed or 10
                            if entity.AutoAimingConfig.OuterRange then
                                entity.AutoAimingConfig.OuterRange.Speed = speed
                                entity.AutoAimingConfig.OuterRange.RangeRate = 4.5
                                entity.AutoAimingConfig.OuterRange.SpeedRate = 1.3
                                entity.AutoAimingConfig.OuterRange.RangeRateSight = 1.8
                                entity.AutoAimingConfig.OuterRange.SpeedRateSight = 2.2
                                entity.AutoAimingConfig.OuterRange.CrouchRate = 1.1
                                entity.AutoAimingConfig.OuterRange.ProneRate = 1.0
                                entity.AutoAimingConfig.OuterRange.DyingRate = 0.0
                            end
                            if entity.AutoAimingConfig.InnerRange then
                                entity.AutoAimingConfig.InnerRange.Speed = speed
                                entity.AutoAimingConfig.InnerRange.RangeRate = 4.5
                                entity.AutoAimingConfig.InnerRange.SpeedRate = 1.3
                                entity.AutoAimingConfig.InnerRange.RangeRateSight = 1.8
                                entity.AutoAimingConfig.InnerRange.SpeedRateSight = 2.2
                                entity.AutoAimingConfig.InnerRange.CrouchRate = 1.1
                                entity.AutoAimingConfig.InnerRange.ProneRate = 1.0
                                entity.AutoAimingConfig.InnerRange.DyingRate = 0.0
                            end
                        elseif _G.LexusConfig.CustomAimbotClose or _G.LexusConfig.AimbotMode == "Close" then
                            local speed = _G.LexusState.CustomTextData.InnerSpeed or 10
                            if entity.AutoAimingConfig.OuterRange then
                                entity.AutoAimingConfig.OuterRange.Speed = speed
                                entity.AutoAimingConfig.OuterRange.DyingRate = 0.0
                            end
                            if entity.AutoAimingConfig.InnerRange then
                                entity.AutoAimingConfig.InnerRange.Speed = speed
                                entity.AutoAimingConfig.InnerRange.DyingRate = 0.0
                            end
                        elseif _G.LexusConfig.AimbotMode == "Far" then
                            if entity.AutoAimingConfig.OuterRange then
                                entity.AutoAimingConfig.OuterRange.Speed = 5
                                entity.AutoAimingConfig.OuterRange.RangeRate = 0.7
                                entity.AutoAimingConfig.OuterRange.SpeedRate = 1.3
                                entity.AutoAimingConfig.OuterRange.RangeRateSight = 1.8
                                entity.AutoAimingConfig.OuterRange.SpeedRateSight = 2.2
                                entity.AutoAimingConfig.OuterRange.CrouchRate = 1.1
                                entity.AutoAimingConfig.OuterRange.ProneRate = 1
                            end
                            if entity.AutoAimingConfig.InnerRange then
                                entity.AutoAimingConfig.InnerRange.Speed = 5
                                entity.AutoAimingConfig.InnerRange.RangeRate = 0.7
                                entity.AutoAimingConfig.InnerRange.SpeedRate = 1.3
                                entity.AutoAimingConfig.InnerRange.RangeRateSight = 1.8
                                entity.AutoAimingConfig.InnerRange.SpeedRateSight = 2.2
                                entity.AutoAimingConfig.InnerRange.CrouchRate = 1.1
                                entity.AutoAimingConfig.InnerRange.ProneRate = 1
                            end
                        end
                    end

                    entity.LexusWeaponModsActive = true

                elseif entity.LexusWeaponModsActive then
                    if entity.OriginalStatsCached then
                        local orig = entity.OriginalStatsCached
                        entity.GameDeviationFactor = orig.GameDeviationFactor
                        entity.GameDeviationAccuracy = orig.GameDeviationAccuracy
                        entity.BulletFireSpeed = orig.BulletFireSpeed
                        entity.ShootInterval = orig.ShootInterval
                        entity.BaseDamage = orig.BaseDamage
                        entity.AccessoriesHRecoilFactor = orig.AccessoriesHRecoilFactor
                        entity.AccessoriesVRecoilFactor = orig.AccessoriesVRecoilFactor
                        entity.RecoilKick = orig.RecoilKick
                        entity.RecoilKickADS = orig.RecoilKickADS
                        entity.AnimationKick = orig.AnimationKick
                    end
                    if entity.AutoAimingConfig and entity.OriginalAutoAimCached then
                        pcall(function() entity.AutoAimingConfig.Bones = { "Spine_01", "Pelvis", "Head" } end)
                        if entity.AutoAimingConfig.OuterRange and entity.OriginalAutoAimCached.OuterSpeed then
                            entity.AutoAimingConfig.OuterRange.Speed = entity.OriginalAutoAimCached.OuterSpeed
                        end
                        if entity.AutoAimingConfig.InnerRange and entity.OriginalAutoAimCached.InnerSpeed then
                            entity.AutoAimingConfig.InnerRange.Speed = entity.OriginalAutoAimCached.InnerSpeed
                        end
                    end
                    entity.LexusWeaponModsActive = false
                end
            end
        end
    end)

    local mHead_Global, mBody_Global, mLegs_Global = 1.0, 1.0, 1.0
    local runInject_Global = false

    pcall(function()
        if _G.LexusConfig.CustomMagicBullet then
            runInject_Global = true
            mHead_Global = 1.0; mBody_Global = 1.0; mLegs_Global = 1.0
            if _G.LexusState.CustomTextData then
                local cData = _G.LexusState.CustomTextData
                if cData.MagicHead ~= nil then mHead_Global = tonumber(cData.MagicHead) or mHead_Global end
                if cData.MagicBody ~= nil then mBody_Global = tonumber(cData.MagicBody) or mBody_Global end
                if cData.MagicLegs ~= nil then mLegs_Global = tonumber(cData.MagicLegs) or mLegs_Global end
            end
        elseif _G.LexusConfig.MagicBullet then
            runInject_Global = true
            mHead_Global = 1.05; mBody_Global = 1.0; mLegs_Global = 1.0
        end

        if runInject_Global then
            local currentMagicHash = "M_"..tostring(mHead_Global).."_"..tostring(mBody_Global).."_"..tostring(mLegs_Global)
            if _G.LexusState.LastMagicConfigHash ~= currentMagicHash then
                _G.LexusState.MagicUpdateVersion = (_G.LexusState.MagicUpdateVersion or 0) + 1
                _G.LexusState.LastMagicConfigHash = currentMagicHash
            end
        else

            if _G.LexusState.LastMagicConfigHash ~= "OFF" then
                _G.LexusState.MagicUpdateVersion = (_G.LexusState.MagicUpdateVersion or 0) + 1
                _G.LexusState.LastMagicConfigHash = "OFF"
            end
        end
    end)

    pcall(function()
        local allCharacters = {}
        if GameplayData.GetAllPlayerCharacters then allCharacters = GameplayData.GetAllPlayerCharacters()
        elseif GameplayData.GameCharacters then for _, char in pairs(GameplayData.GameCharacters) do table.insert(allCharacters, char) end end

        local currentValidKeys = {}
        for _, enemy in pairs(allCharacters) do
            if Valid(enemy) and enemy ~= localPlayer then
                currentValidKeys[GetSafeEnemyKey(enemy)] = true
            end
        end

        for key, data in pairs(_G.LexusState.EnemyMarks) do
            if not currentValidKeys[key] then
                SafeRemoveMark(data.radarMark)
                SafeRemoveMark(data.hpMark)
                SafeRemoveMark(data.distMark)


                if _G.AimTouchVisCache and _G.AimTouchVisCache[key] then
                    _G.AimTouchVisCache[key] = nil
                end

                if data.MIDs then
                    for meshStr, midTable in pairs(data.MIDs) do
                        for k, _ in pairs(midTable) do
                            midTable[k] = nil
                        end
                    end
                    data.MIDs = nil
                end
                if data.MIDs_V3 then
                    for meshStr, midTable in pairs(data.MIDs_V3) do
                        for k, _ in pairs(midTable) do
                            midTable[k] = nil
                        end
                    end
                    data.MIDs_V3 = nil
                end

                data.enemy = nil
                data.CachedMeshes = nil
                _G.LexusState.EnemyMarks[key] = nil
            end
        end

        local realCount = 0
        local aiCount = 0

        local function GetFirstElemSafe(elemArray)
            if elemArray and type(elemArray.Num) == "function" and elemArray:Num() > 0 then
                if type(elemArray.Get) == "function" then return elemArray:Get(0) end
            elseif elemArray and type(elemArray) == "table" and #elemArray > 0 then
                return elemArray[1]
            end
            return nil
        end

        local BoneScaleMap = {
            ["head"] = mHead_Global, ["neck_01"] = mHead_Global,
            ["pelvis"] = mBody_Global, ["spine_01"] = mBody_Global, ["spine_02"] = mBody_Global, ["spine_03"] = mBody_Global,
            ["thigh_l"] = mLegs_Global, ["thigh_r"] = mLegs_Global,
            ["calf_l"] = mLegs_Global, ["calf_r"] = mLegs_Global,
            ["foot_l"] = mLegs_Global, ["foot_r"] = mLegs_Global
        }

        local mLoc = nil
        pcall(function() if type(localPlayer.K2_GetActorLocation) == "function" then mLoc = localPlayer:K2_GetActorLocation() end end)

        for _, enemy in pairs(allCharacters) do
            if Valid(enemy) and enemy ~= localPlayer and enemy.TeamID ~= localPlayer.TeamID then
                local bIsReallyDead = false
                pcall(function()
                    if type(enemy.IsDead) == "function" then bIsReallyDead = enemy:IsDead()
                    elseif enemy.bIsDead ~= nil then bIsReallyDead = enemy.bIsDead
                    elseif enemy.bIsDeadFlag ~= nil then bIsReallyDead = enemy.bIsDeadFlag end
                    if enemy.HealthStatus ~= nil and enemy.HealthStatus == 2 then bIsReallyDead = true end
                end)

                local eKey = GetSafeEnemyKey(enemy)
                _G.LexusState.EnemyMarks[eKey] = _G.LexusState.EnemyMarks[eKey] or { enemy = enemy }
                local markData = _G.LexusState.EnemyMarks[eKey]
                markData.enemy = enemy

                if not bIsReallyDead then


                    if markData.lastEnemyActor ~= enemy then
                        if markData.hpMark then SafeRemoveMark(markData.hpMark); markData.hpMark = nil end
                        if markData.hpMark8 then SafeRemoveMark(markData.hpMark8); markData.hpMark8 = nil end
                        if markData.distMark then SafeRemoveMark(markData.distMark); markData.distMark = nil end
                        if markData.radarMark then SafeRemoveMark(markData.radarMark); markData.radarMark = nil end

                        markData.lastEnemyActor = enemy
                        markData.LastUIComp = nil
                        markData.LastFrameUIState = nil
                    end

                    local eMesh = nil
                    pcall(function() eMesh = enemy.Mesh or (type(enemy.getAvatarComponent2) == "function" and enemy:getAvatarComponent2() or nil) end)
                    local aLoc = nil
                    pcall(function() if type(enemy.K2_GetActorLocation) == "function" then aLoc = enemy:K2_GetActorLocation() end end)

                    local isBotResult, isStateLoaded = CheckIsAI(enemy, markData)
                    local isBot = markData.AK_IS_BOT or false

                    local currentMeshCount = 0
                    if Valid(eMesh) then
                        local tempMeshes = GetAllSkeletalMeshes(enemy, markData)
                        currentMeshCount = #tempMeshes
                    end
                    local isMeshChanged = (markData.LastMeshCountWall ~= currentMeshCount)


                    if _G.LexusConfig.WallXuyenTuong then
                        if isMeshChanged or not markData.WallhackApplied then
                            ApplyWallXuyenTuong(enemy, markData)
                            markData.WallhackApplied = true
                            markData.LastMeshCountWall = currentMeshCount
                        end
                    else
                        UndoWallXuyenTuong(enemy, markData)
                    end


                    if _G.LexusConfig.ColorBodyV2 then

                        ApplyColorBodyV2(enemy, pc, markData)
                    else
                        UndoColorBodyV2(enemy, markData)
                    end


                    if _G.LexusConfig.ColorBodyV3 then
                        ApplyColorBodyV3(enemy, markData)
                    else
                        UndoColorBodyV3(enemy, markData)
                    end

                    if _G.LexusConfig.ColorBodyNew then
                        ApplyColorBodyNew(enemy, markData)
                    else
                        UndoColorBodyNew(enemy, markData)
                    end


                    pcall(function()
                        if Valid(eMesh) then
                            local targetScale = 1.0
                            if _G.LexusConfig.BugManEnable and _G.LexusState.CustomTextData then
                                targetScale = 177.0 / (_G.LexusState.CustomTextData.BugManRatio or 133)
                                if targetScale < 1.0 then targetScale = 1.0 end
                                if targetScale > 2.0 then targetScale = 2.0 end
                            end


                            if markData.LastFatScale ~= targetScale then
                                eMesh:SetRelativeScale3D(FVector(targetScale, targetScale, 1.0))
                                markData.LastFatScale = targetScale
                            end
                        end
                    end)


                    pcall(function()
                        local EnemyMesh = eMesh
                        if slua.isValid(EnemyMesh) then


                            local uniqueID = type(enemy.GetUniqueID) == "function" and enemy:GetUniqueID() or tostring(enemy.PlayerKey or enemy)


                            if markData.MagicBulletHash == _G.LexusState.LastMagicConfigHash and markData.MagicTargetID == uniqueID then
                                return
                            end

                            local PhysicsAsset = EnemyMesh.PhysicsAssetOverride
                            if not slua.isValid(PhysicsAsset) and EnemyMesh.SkeletalMesh then PhysicsAsset = EnemyMesh.SkeletalMesh.PhysicsAsset end

                            if slua.isValid(PhysicsAsset) and PhysicsAsset.SkeletalBodySetups then
                                if not _G.AK_ModdedPhysAssets then _G.AK_ModdedPhysAssets = {} end
                                local PhysAssetName = "DefaultPhys"
                                pcall(function() PhysAssetName = PhysicsAsset:GetName() end)


                                if _G.AK_ModdedPhysAssets[PhysAssetName] ~= _G.LexusState.LastMagicConfigHash then

                                    if not _G.AK_OrigHitboxes then _G.AK_OrigHitboxes = {} end
                                    if not _G.AK_OrigHitboxes[PhysAssetName] then _G.AK_OrigHitboxes[PhysAssetName] = {} end
                                    local OrigHitboxData = _G.AK_OrigHitboxes[PhysAssetName]

                                    local SkeletalBodySetups = PhysicsAsset.SkeletalBodySetups
                                    local numSetups = type(SkeletalBodySetups.Num) == "function" and SkeletalBodySetups:Num() or #SkeletalBodySetups
                                    local limit = numSetups > 50 and 50 or numSetups

                                    for i = 1, limit do
                                        local BodySetup = type(SkeletalBodySetups.Get) == "function" and SkeletalBodySetups:Get(i-1) or SkeletalBodySetups[i]
                                        if slua.isValid(BodySetup) then
                                            local LowerBoneName = string.lower(tostring(BodySetup.BoneName))
                                            local MatchedBoneKey = nil
                                            for k, _ in pairs(BoneScaleMap) do
                                                if string.find(LowerBoneName, k, 1, true) then MatchedBoneKey = k break end
                                            end

                                            if MatchedBoneKey then
                                                local TargetScale = 1.0
                                                if runInject_Global then TargetScale = BoneScaleMap[MatchedBoneKey] end

                                                local AggGeom = BodySetup.AggGeom

                                                local BoxElems = AggGeom and AggGeom.BoxElems or BodySetup.BoxElems
                                                local SphereElems = AggGeom and AggGeom.SphereElems or BodySetup.SphereElems
                                                local SphylElems = AggGeom and AggGeom.SphylElems or BodySetup.SphylElems

                                                local BoxElem = GetFirstElemSafe(BoxElems)
                                                local SphereElem = GetFirstElemSafe(SphereElems)
                                                local SphylElem = GetFirstElemSafe(SphylElems)

                                                if not OrigHitboxData[MatchedBoneKey] then
                                                    OrigHitboxData[MatchedBoneKey] = { Box = nil, Sphere = nil, Sphyl = nil }
                                                    if BoxElem then OrigHitboxData[MatchedBoneKey].Box = { X = BoxElem.X, Y = BoxElem.Y, Z = BoxElem.Z } end
                                                    if SphereElem then OrigHitboxData[MatchedBoneKey].Sphere = { Radius = SphereElem.Radius } end
                                                    if SphylElem then OrigHitboxData[MatchedBoneKey].Sphyl = { Radius = SphylElem.Radius, Length = SphylElem.Length } end
                                                end

                                                local OrigElemData = OrigHitboxData[MatchedBoneKey]

                                                if OrigElemData.Box and BoxElem then
                                                    BoxElem.X = OrigElemData.Box.X * TargetScale
                                                    BoxElem.Y = OrigElemData.Box.Y * TargetScale
                                                    BoxElem.Z = OrigElemData.Box.Z * TargetScale
                                                    if type(BoxElems.Set) == "function" then BoxElems:Set(0, BoxElem) else BoxElems[1] = BoxElem end
                                                    if AggGeom then AggGeom.BoxElems = BoxElems; BodySetup.AggGeom = AggGeom else BodySetup.BoxElems = BoxElems end
                                                end

                                                if OrigElemData.Sphere and SphereElem then
                                                    SphereElem.Radius = OrigElemData.Sphere.Radius * TargetScale
                                                    if type(SphereElems.Set) == "function" then SphereElems:Set(0, SphereElem) else SphereElems[1] = SphereElem end
                                                    if AggGeom then AggGeom.SphereElems = SphereElems; BodySetup.AggGeom = AggGeom else BodySetup.SphereElems = SphereElems end
                                                end

                                                if OrigElemData.Sphyl and SphylElem then
                                                    SphylElem.Radius = OrigElemData.Sphyl.Radius * TargetScale
                                                    SphylElem.Length = OrigElemData.Sphyl.Length * TargetScale
                                                    if type(SphylElems.Set) == "function" then SphylElems:Set(0, SphylElem) else SphylElems[1] = SphylElem end
                                                    if AggGeom then AggGeom.SphylElems = SphylElems; BodySetup.AggGeom = AggGeom else BodySetup.SphylElems = SphylElems end
                                                end
                                            end
                                        end
                                    end
                                    _G.AK_ModdedPhysAssets[PhysAssetName] = _G.LexusState.LastMagicConfigHash
                                end

                                if EnemyMesh.SetPhysicsAsset then EnemyMesh:SetPhysicsAsset(PhysicsAsset) end
                                EnemyMesh.PhysicsAssetOverride = PhysicsAsset

                                markData.MagicBulletHash = _G.LexusState.LastMagicConfigHash
                                markData.MagicTargetID = uniqueID
                            end
                        end
                    end)

                    local distM = 0
                    pcall(function() distM = localPlayer:GetDistanceTo(enemy) / 100 end)

                    local currentHp, maxHp = 100, 100
                    local showFrameUI = _G.LexusConfig.EspLoai5 or _G.LexusConfig.EspVipPro or _G.LexusConfig.EspVip

                    if showFrameUI then
                        pcall(function()
                            if enemy.Health then currentHp = enemy.Health elseif type(enemy.GetHealth) == "function" then currentHp = enemy:GetHealth() end
                            if enemy.HealthMax then maxHp = enemy.HealthMax elseif type(enemy.GetHealthMax) == "function" then maxHp = enemy:GetHealthMax() end
                        end)
                        if maxHp <= 0 then maxHp = 100 end
                    end
                    local hpRatio = currentHp / maxHp

                    if _G.LexusConfig.EspAntenna then
                        pcall(function()
                            local MyHUD = Cached_MyHUD
                            if Valid(MyHUD) and distM <= 400 then
                                local loopCount = 8
                                local zStep = 1000
                                local baseZ = 105
                                local topZ = baseZ + (loopCount * zStep)
                                for i = 1, loopCount do
                                    local zOffset = baseZ + (i * zStep)
                                    MyHUD:AddDebugText("|", enemy, 0.06,
                                        {X=0, Y=0, Z=zOffset}, {X=0, Y=0, Z=zOffset},
                                        C_GREEN, true, false, true, nil, 1.2, true)
                                end
                                MyHUD:AddDebugText("I", enemy, 0.06,
                                        {X=0, Y=0, Z=topZ + 60}, {X=0, Y=0, Z=topZ + 60},
                                        C_GREEN, true, false, true, nil, 1.5, true)
                            end
                        end)
                    end

                    if _G.LexusConfig.EspLoai6 then
                        pcall(function()
                            local curTime = os.clock()


                            if markData.LastEsp6Time == nil or (curTime - markData.LastEsp6Time) >= 0.05 then
                                markData.LastEsp6Time = curTime

                                local MyHUD = Cached_MyHUD
                                if Valid(MyHUD) and Valid(eMesh) and aLoc then
                                    if distM <= 250 then

                                        if type(eMesh.GetSocketLocation) == "function" then
                                            for _, bName in ipairs(GLOBAL_BONE_LIST) do


                                                if distM > 50 and (bName ~= "head" and bName ~= "pelvis" and bName ~= "neck_01") then

                                                else
                                                    local wLoc = eMesh:GetSocketLocation(bName)
                                                    if wLoc then

                                                        local offset = {X = wLoc.X - aLoc.X, Y = wLoc.Y - aLoc.Y, Z = wLoc.Z - aLoc.Z}

                                                        local mark = "▪"
                                                        local fixedSize = 0.25
                                                        local color = C_CYAN

                                                        if bName == "head" then
                                                            mark = "●"
                                                            fixedSize = 0.45
                                                            color = C_RED
                                                        elseif bName == "pelvis" or bName == "neck_01" then
                                                            mark = "▪"
                                                            fixedSize = 0.35
                                                            color = C_YELLOW
                                                        end


                                                        MyHUD:AddDebugText(mark, enemy, 0.06, offset, offset, color, true, false, true, nil, fixedSize, true)
                                                    end
                                                end
                                            end
                                        end


                                    end
                                end
                            end
                        end)
                    end

                    if _G.LexusConfig.EspLoai7 then
                        pcall(function()
                            local MyHUD = Cached_MyHUD
                            if Valid(MyHUD) then
                                if distM <= 600 then if isBot then aiCount = aiCount + 1 else realCount = realCount + 1 end end

                                if distM <= 400 then
                                    local stateText = ""


                                    if _G.LexusConfig.Esp7_TuThe then
                                        local pose = nil
                                        if enemy.PoseState then pose = enemy.PoseState
                                        elseif type(enemy.GetPoseState) == "function" then pose = enemy:GetPoseState() end

                                        if pose == 0 or pose == "Stand" then stateText = "Đứng"
                                        elseif pose == 1 or pose == "Crouch" then stateText = "Ngồi"
                                        elseif pose == 2 or pose == "Prone" then stateText = "Nằm"
                                        else stateText = "Đứng" end
                                    end


                                    if _G.LexusConfig.Esp7_VuKhi then
                                        local curTime = os.clock()
                                        if markData.AK_LAST_WEP_TIME == nil or curTime > markData.AK_LAST_WEP_TIME + 1.5 then
                                            local eWeapon = nil
                                            if enemy.CurrentWeapon then eWeapon = enemy.CurrentWeapon
                                            elseif type(enemy.GetCurrentWeapon) == "function" then eWeapon = enemy:GetCurrentWeapon()
                                            elseif enemy.WeaponManagerComponent then eWeapon = enemy.WeaponManagerComponent.CurrentWeaponReplicated end

                                            local weaponName = "Tay Không"
                                            if Valid(eWeapon) then if type(eWeapon.GetWeaponName) == "function" then weaponName = eWeapon:GetWeaponName() end end
                                            markData.AK_CACHED_WEP_NAME = tostring(weaponName)
                                            markData.AK_LAST_WEP_TIME = curTime
                                        end

                                        if stateText ~= "" then
                                            stateText = stateText .. " - " .. (markData.AK_CACHED_WEP_NAME or "Tay Không")
                                        else
                                            stateText = (markData.AK_CACHED_WEP_NAME or "Tay Không")
                                        end
                                    end


                                    if stateText ~= "" then
                                        local textColor = isBot and C_CYAN or C_YELLOW
                                        local dynamicScale = math.max(0.5, 0.8 - (distM / 400))
                                        MyHUD:AddDebugText(stateText, enemy, 0.06, {X=0, Y=0, Z=100}, {X=0, Y=0, Z=100}, textColor, true, false, true, nil, dynamicScale, true)
                                    end
                                end
                            end
                        end)
                    end


                    if showFrameUI then
                        pcall(function()
                            local SecurityCommonUtils = Cached_SecurityCommonUtils
                            local show = true
                            if enemy.HealthStatus and SecurityCommonUtils and SecurityCommonUtils.IsHealthStatusAlive then
                                if not SecurityCommonUtils.IsHealthStatusAlive(enemy.HealthStatus) then show = false end
                            end
                            if show and mLoc then
                                if aLoc and SecurityCommonUtils and SecurityCommonUtils.IsVector then
                                    if SecurityCommonUtils.IsVector(aLoc) and SecurityCommonUtils.IsVector(mLoc) then
                                        if aLoc.Z >= 150000 or FVector.Dist2D(mLoc, aLoc) > 50000 then show = false end
                                    end
                                end
                            end
                            if show then
                                if enemy.Replay_IsEnemyFrameUIExisted and not enemy:Replay_IsEnemyFrameUIExisted() then enemy:Replay_CreateEnemyFrameUI(true, true) end
                                if enemy.Replay_SetVisiableOfFrameUI then enemy:Replay_SetVisiableOfFrameUI(true) end
                                if enemy.Replay_UpdateEnemyFrameUI then enemy:Replay_UpdateEnemyFrameUI(hpRatio) end

                                local uiComp = enemy.EnemyFrameUI or (type(enemy.GetEnemyFrameUI) == "function" and enemy:GetEnemyFrameUI())
                                if Valid(uiComp) then
                                    if markData.LastFrameUIState ~= "VISIBLE" then
                                        if type(uiComp.SetVisibility) == "function" then uiComp:SetVisibility(0) end
                                        if type(uiComp.SetHiddenInGame) == "function" then uiComp:SetHiddenInGame(false) end
                                        markData.LastFrameUIState = "VISIBLE"
                                    end
                                end
                            end
                        end)
                    else
                        pcall(function()
                            if enemy.Replay_SetVisiableOfFrameUI then enemy:Replay_SetVisiableOfFrameUI(false) end
                            local uiComp = enemy.EnemyFrameUI or (type(enemy.GetEnemyFrameUI) == "function" and enemy:GetEnemyFrameUI())
                            if Valid(uiComp) then
                                if markData.LastFrameUIState ~= "HIDDEN" then
                                    if type(uiComp.SetVisibility) == "function" then uiComp:SetVisibility(2) end
                                    if type(uiComp.SetHiddenInGame) == "function" then uiComp:SetHiddenInGame(true) end
                                    markData.LastFrameUIState = "HIDDEN"
                                end
                            end
                        end)
                    end

                    if _G.LexusConfig.EspVipPro then
                        pcall(function()
                            local hud = Cached_MyHUD
                            if Valid(hud) and hud.AddDebugText then
                                if distM <= 400 then
                                    local dynamicScale = math.max(0.55, 0.95 - (distM / 400))
                                    local hpPercent = hpRatio
                                    local isKnock = (currentHp <= 0 and enemy.HealthStatus == 1)

                                    local hpColor = C_GREEN
                                    if hpPercent < 0.3 then hpColor = C_RED
                                    elseif hpPercent < 0.7 then hpColor = C_YELLOW end
                                    if isKnock then hpColor = C_RED end


                                    if _G.LexusConfig.Esp3ShowName then
                                        local enemyName = "Enemy"
                                        pcall(function() if enemy.PlayerName then enemyName = enemy.PlayerName elseif type(enemy.GetPlayerName) == "function" then enemyName = enemy:GetPlayerName() end end)
                                        if enemyName == "" then enemyName = "Enemy" end
                                        if isKnock then enemyName = "KNOCK: " .. enemyName end
                                        hud:AddDebugText(enemyName, enemy, 0.06, {X=0, Y=0, Z=-370}, {X=0, Y=0, Z=-370}, C_WHITE, true, false, true, nil, dynamicScale * 1.1, true)
                                    end


                                    if _G.LexusConfig.Esp3ShowHP then
                                        if not isKnock then
                                            local segments = 6
                                            local filled = math.floor(hpPercent * segments)
                                            local startZ = 20
                                            local spacing = 10.0 * dynamicScale
                                            for j = 1, segments do
                                                local color = (j <= filled) and hpColor or {R=30,G=30,B=30,A=180}
                                                hud:AddDebugText("█", enemy, 0.06, {X=0, Y=-115, Z=startZ + (j * spacing)}, {X=0, Y=-115, Z=startZ + (j * spacing)}, color, true, false, true, nil, dynamicScale * 1.2, true)
                                            end
                                            hud:AddDebugText(string.format("%d%%", math.floor(hpPercent * 100)), enemy, 0.06, {X=0, Y=-60, Z=startZ - 12}, {X=0, Y=-60, Z=startZ - 12}, hpColor, true, false, true, nil, dynamicScale * 0.8, true)
                                        else
                                            hud:AddDebugText("DOWN", enemy, 0.06, {X=0, Y=-115, Z=50}, {X=0, Y=-115, Z=50}, C_RED, true, false, true, nil, dynamicScale * 1.0, true)
                                        end
                                    end
                                end
                            end
                        end)
                    end

                    if _G.LexusConfig.EspDistance then
                        pcall(function()
                            local hud = Cached_MyHUD
                            if Valid(hud) and hud.AddDebugText then
                                if distM <= 400 then
                                    local dynamicScale = math.max(0.55, 0.95 - (distM / 400))
                                    hud:AddDebugText(string.format("[%dm]", math.floor(distM)), enemy, 0.06, {X=0, Y=115, Z=20}, {X=0, Y=115, Z=20}, C_BLUE_TEXT, true, false, true, nil, dynamicScale * 1.5, true)
                                end
                            end
                        end)
                    end


                    if _G.LexusConfig.EspVip then
                        if markData.hpMark == nil then markData.hpMark = SafeAddMark(1006, FVector(0,0,0), 0, "", 4, enemy) end
                        if markData.distMark == nil then markData.distMark = SafeAddMark(9999, FVector(0,0,0), 0, "", 4, enemy) end
                    else
                        if markData.hpMark then SafeRemoveMark(markData.hpMark); markData.hpMark = nil end
                        if markData.distMark then SafeRemoveMark(markData.distMark); markData.distMark = nil end
                    end


                    if _G.LexusConfig.EspLoai8 then
                        if markData.hpMark8 == nil then markData.hpMark8 = SafeAddMark(1006, FVector(0,0,0), 0, "", 4, enemy) end
                    else
                        if markData.hpMark8 then SafeRemoveMark(markData.hpMark8); markData.hpMark8 = nil end
                    end

                    if _G.LexusConfig.EspRadar then

                        if not markData.radarMark or markData.radarMark == 0 then
                            markData.radarMark = SafeAddMark(8888, FVector(0,0,0), 0, "", 4, enemy)
                        end
                    else
                        if markData.radarMark and markData.radarMark ~= 0 then
                            SafeRemoveMark(markData.radarMark)
                            markData.radarMark = nil
                        end
                    end


                    if _G.LexusConfig.EspOutline then
                        pcall(function()
                            local outColorChoice = _G.LexusState.CustomTextData.OutlineColor or 4
                            local outThick = _G.LexusConfig.OutlineThickness or 10
                            local outlineHash = string.format("%d_%d", outThick, outColorChoice)

                            local meshes = GetAllSkeletalMeshes(enemy, markData)
                            local currentMeshCount = #meshes

                            if markData.OutlineState ~= outlineHash or markData.LastMeshCountOutline ~= currentMeshCount then

                                local r, g, b = 255, 255, 0
                                if outColorChoice == 1 then r, g, b = 255, 0, 0
                                elseif outColorChoice == 2 then r, g, b = 70, 120, 255
                                elseif outColorChoice == 3 then r, g, b = 0, 0, 255
                                elseif outColorChoice == 4 then r, g, b = 255, 255, 0
                                elseif outColorChoice == 5 then r, g, b = 255, 0, 255
                                elseif outColorChoice == 6 then r, g, b = 255, 255, 255 end

                                local glowIntensity = 80.0
                                local LinearColorClass = import("LinearColor") or _G.FLinearColor
                                local glowDynamic = LinearColorClass and LinearColorClass((r/255) * glowIntensity, (g/255) * glowIntensity, (b/255) * glowIntensity, 1.0) or { R = r * glowIntensity, G = g * glowIntensity, B = b * glowIntensity, A = 255 }

                                for _, comp in ipairs(meshes) do
                                    if Valid(comp) then

                                        pcall(function()
                                            comp.UseScopeDistanceCulling = false
                                            comp.PrimitiveShadingStrategy = 1
                                            comp.ShadingRate = 6
                                        end)


                                        if comp.SetDrawIdeaOutline then
                                            comp:SetDrawIdeaOutline(true)
                                            if comp.OverrideIdeaOutlineColor then
                                                comp:OverrideIdeaOutlineColor(true, glowDynamic)
                                            end
                                            if comp.OverrideIdeaOutlineThickness then

                                                comp:OverrideIdeaOutlineThickness(true, _G.LexusConfig.OutlineThickness)
                                            end
                                        end
                                    end
                                end
                                markData.OutlineState = outlineHash
                                markData.LastMeshCountOutline = currentMeshCount
                            end
                        end)
                    else
                        pcall(function()
                            if markData.OutlineState ~= "OFF" then
                                local meshes = GetAllSkeletalMeshes(enemy, markData)
                                for _, comp in ipairs(meshes) do
                                    if Valid(comp) then

                                        pcall(function()
                                            comp.PrimitiveShadingStrategy = 0
                                            comp.ShadingRate = 1
                                        end)

                                        if comp.SetDrawIdeaOutline then
                                            comp:SetDrawIdeaOutline(false)
                                        end
                                    end
                                end
                                markData.OutlineState = "OFF"
                                markData.LastMeshCountOutline = 0
                            end
                        end)
                    end

                else
                    if not markData.IsCleanedUp then
                        SafeRemoveMark(markData.radarMark)
                        markData.radarMark = nil
                        SafeRemoveMark(markData.hpMark)
                        markData.hpMark = nil
                        SafeRemoveMark(markData.hpMark8)
                        markData.hpMark8 = nil
                        SafeRemoveMark(markData.distMark)
                        markData.distMark = nil

                        if markData.MIDs then
                            for meshStr, midTable in pairs(markData.MIDs) do
                                for k, _ in pairs(midTable) do midTable[k] = nil end
                            end
                            markData.MIDs = nil
                        end

                        if markData.MIDs_V3 then
                            for meshStr, midTable in pairs(markData.MIDs_V3) do
                                for k, _ in pairs(midTable) do midTable[k] = nil end
                            end
                            markData.MIDs_V3 = nil
                        end

                        pcall(function()
                            local eObj = markData.enemy
                            if Valid(eObj) then
                                if eObj.Replay_SetVisiableOfFrameUI then eObj:Replay_SetVisiableOfFrameUI(false) end
                                local uiComp = eObj.EnemyFrameUI or (type(eObj.GetEnemyFrameUI) == "function" and eObj:GetEnemyFrameUI())
                                if Valid(uiComp) then
                                    if type(uiComp.SetVisibility) == "function" then uiComp:SetVisibility(2) end
                                    if type(uiComp.SetHiddenInGame) == "function" then uiComp:SetHiddenInGame(true) end
                                end
                            end

                            local PPM = Cached_PPM
                            local avatarComp = Valid(eObj) and (type(eObj.getAvatarComponent2) == "function") and eObj:getAvatarComponent2() or nil
                            if Valid(avatarComp) and Valid(PPM) then PPM:EnableAvatarOutline(avatarComp, false) end
                        end)

                        markData.IsCleanedUp = true
                    end
                end
            end
        end

        if _G.LexusConfig.EspLoai7 and _G.LexusConfig.Esp7_SoLuong then
            _M_DrawCounter()
        else

            if EnemyCounterWidget and slua.isValid(EnemyCounterWidget) then
                EnemyCounterWidget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
            end
        end


        if _G.LexusConfig.EspBomMaster and (_G.LexusConfig.EspItemBom or _G.LexusConfig.EspActiveBom) then
            pcall(function()
                local MyHUD = Cached_MyHUD
                if Valid(MyHUD) then
                    if not _G.CachedGameplayStatics then _G.CachedGameplayStatics = import("GameplayStatics") end
                    if not _G.CachedActorClass_ForBomb then _G.CachedActorClass_ForBomb = import("Actor") end
                    if not _G.CachedProjArray then _G.CachedProjArray = slua.Array(UEnums.EPropertyClass.Object, _G.CachedActorClass_ForBomb) end


                    if not _G.ActorBombCacheInit then
                        _G.NonBombCache = setmetatable({}, { __mode = "k" })
                        _G.BombCache = setmetatable({}, { __mode = "k" })
                        _G.ActorBombCacheInit = true
                    end

                    local ui_util = require("client.common.ui_util")
                    local gameInstance = ui_util and ui_util.GetGameInstance()

                    if gameInstance and _G.CachedGameplayStatics then
                        local curTime = os.clock()


                        if not _G.LastBombScanTime or (curTime - _G.LastBombScanTime) > 0.5 then
                            _G.LastBombScanTime = curTime
                            local allActors = _G.CachedGameplayStatics.GetAllActorsOfClass(gameInstance, _G.CachedActorClass_ForBomb, _G.CachedProjArray)

                            local activeBombs = {}
                            local itemBombs = {}

                            if allActors then
                                for _, actor in pairs(allActors) do
                                    if slua.isValid(actor) and not actor.bHidden and not actor.bTearOff then


                                        if not _G.NonBombCache[actor] then
                                            local bType = 0
                                            local isItem = false
                                            local isKnownBomb = _G.BombCache[actor]

                                            if isKnownBomb then
                                                bType = isKnownBomb.type
                                                isItem = isKnownBomb.isItem
                                            else

                                                local nameLower = nil
                                                pcall(function() nameLower = string.lower(type(actor.GetName) == "function" and actor:GetName() or tostring(actor)) end)

                                                if nameLower then
                                                    if string.find(nameLower, "m79") or string.find(nameLower, "launcher") then bType = 5
                                                    elseif string.find(nameLower, "smoke") then bType = 2
                                                    elseif string.find(nameLower, "burn") or string.find(nameLower, "molotov") then bType = 3
                                                    elseif string.find(nameLower, "flash") or string.find(nameLower, "stun") then bType = 4
                                                    elseif string.find(nameLower, "grenade") then bType = 1 end

                                                    if bType > 0 then
                                                        if string.find(nameLower, "projectile") or string.find(nameLower, "thrown") then
                                                            isItem = false
                                                        else
                                                            isItem = true
                                                            local shouldAdd = true
                                                            if bType == 3 and not (string.find(nameLower, "pickup") or string.find(nameLower, "wrapper") or string.find(nameLower, "weapon")) then
                                                                shouldAdd = false
                                                            elseif bType == 5 then
                                                                local attachParent = nil
                                                                pcall(function() if type(actor.GetAttachParentActor) == "function" then attachParent = actor:GetAttachParentActor() end end)
                                                                if slua.isValid(attachParent) then
                                                                    local isHolding = false
                                                                    pcall(function()
                                                                        local curWeapon = type(attachParent.GetCurrentWeapon) == "function" and attachParent:GetCurrentWeapon() or attachParent.CurrentWeapon
                                                                        if curWeapon == actor then isHolding = true end
                                                                    end)
                                                                    if not isHolding then shouldAdd = false end
                                                                end
                                                            end
                                                            if not shouldAdd then bType = 0 end
                                                        end
                                                    end
                                                end


                                                if bType > 0 then
                                                    _G.BombCache[actor] = { type = bType, isItem = isItem }
                                                else
                                                    _G.NonBombCache[actor] = true
                                                end
                                            end


                                            if bType > 0 then
                                                local isPendingKill = false
                                                pcall(function() if type(actor.IsPendingKill) == "function" then isPendingKill = actor:IsPendingKill() end end)

                                                if not isPendingKill then
                                                    if isItem then
                                                        table.insert(itemBombs, {act = actor, type = bType})
                                                    else
                                                        table.insert(activeBombs, {act = actor, type = bType})
                                                    end
                                                else

                                                    _G.BombCache[actor] = nil
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                            _G.CachedActiveBombs = activeBombs
                            _G.CachedItemBombs = itemBombs
                        end

                        local curGameTime = 0
                        pcall(function() curGameTime = _G.CachedGameplayStatics.GetTimeSeconds(gameInstance) end)

                        local function DrawBombs(bombList, isItem, maxDist)
                            if not bombList then return end
                            for _, item in ipairs(bombList) do
                                local bomb = item.act
                                local bType = item.type

                                if slua.isValid(bomb) and not bomb.bHidden then
                                    local distM = 0
                                    pcall(function() distM = localPlayer:GetDistanceTo(bomb) / 100 end)

                                    if distM > 0 and distM <= maxDist then
                                        local displayName = ""
                                        local bombColor = C_WHITE
                                        local zOffset = isItem and 15 or 25

                                        if bType == 1 then displayName = "Boom"; bombColor = isItem and {R=255, G=100, B=100, A=255} or C_RED
                                        elseif bType == 2 then displayName = "KHÓI"; bombColor = isItem and {R=200, G=200, B=200, A=255} or C_WHITE
                                        elseif bType == 3 then displayName = "LỬA"; bombColor = isItem and {R=255, G=160, B=50, A=255} or {R=255, G=100, B=0, A=255}
                                        elseif bType == 4 then displayName = "MÙ"; bombColor = isItem and {R=150, G=255, B=255, A=255} or C_CYAN
                                        elseif bType == 5 then displayName = "ĐẠN KHÓI"; bombColor = isItem and {R=150, G=255, B=150, A=255} or {R=100, G=255, B=100, A=255} end

                                        local text = string.format("%s [%dm]", displayName, math.floor(distM))
                                        local shouldTimerRun = not isItem

                                        if isItem then pcall(function() if bomb.bIsPinPulled or bomb.bPinPulled or (type(bomb.IsPinPulled) == "function" and bomb:IsPinPulled()) then shouldTimerRun = true end end) end

                                        if shouldTimerRun and curGameTime > 0 then
                                            local timeLeft = -1
                                            pcall(function() if bomb.ExplosionTime then timeLeft = bomb.ExplosionTime - curGameTime elseif bomb.ExplodeTime then timeLeft = bomb.ExplodeTime - curGameTime end end)

                                            if timeLeft == -1 or timeLeft > 100 then
                                                _G.ActiveBombTimers = _G.ActiveBombTimers or {}
                                                local bombId = tostring(bomb)
                                                if not _G.ActiveBombTimers[bombId] then _G.ActiveBombTimers[bombId] = curGameTime end
                                                local elapsed = curGameTime - _G.ActiveBombTimers[bombId]
                                                local maxTime = (bType == 1 and 7.0) or (bType == 2 and 45.0) or (bType == 3 and 12.0) or (bType == 4 and 5.0) or 45.0
                                                timeLeft = maxTime - elapsed
                                            end

                                            if timeLeft < 0 then timeLeft = 0 end
                                            if timeLeft > 0.1 then text = string.format("%s (%.1fs)", text, timeLeft) end
                                        end

                                        local dynamicScale = math.max(0.6, 1.1 - (distM / maxDist))
                                        MyHUD:AddDebugText(text, bomb, 0.06, {X=0, Y=0, Z=zOffset}, {X=0, Y=0, Z=zOffset}, bombColor, true, false, true, nil, dynamicScale, true)
                                    end
                                end
                            end
                        end

                        if not _G.LastClearTimer or (curTime - _G.LastClearTimer) > 1.0 then
                            _G.LastClearTimer = curTime
                            pcall(function() if _G.ActiveBombTimers then for k, v in pairs(_G.ActiveBombTimers) do if (curGameTime - v) > 60.0 then _G.ActiveBombTimers[k] = nil end end end end)
                        end

                        if _G.LexusConfig.EspItemBom then DrawBombs(_G.CachedItemBombs, true, 50) end
                        if _G.LexusConfig.EspActiveBom then DrawBombs(_G.CachedActiveBombs, false, 150) end
                    end
                end
            end)
        end


        if _G.LexusConfig.EspVehicle then
            pcall(function()
                local MyHUD = Cached_MyHUD
                if Valid(MyHUD) then
                    if not _G.CachedGameplayStatics then _G.CachedGameplayStatics = import("GameplayStatics") end
                    if not _G.CachedActorClass_ForVehicle then _G.CachedActorClass_ForVehicle = import("STExtraVehicleBase") end
                    if not _G.CachedVehicleArray then _G.CachedVehicleArray = slua.Array(UEnums.EPropertyClass.Object, _G.CachedActorClass_ForVehicle) end

                    local ui_util = require("client.common.ui_util")
                    local gameInstance = ui_util and ui_util.GetGameInstance()

                    if gameInstance and _G.CachedGameplayStatics then
                        local curTime = os.clock()


                        if not _G.LastVehicleScanTime or (curTime - _G.LastVehicleScanTime) > 1.0 then
                            _G.LastVehicleScanTime = curTime
                            local allVehicles = _G.CachedGameplayStatics.GetAllActorsOfClass(gameInstance, _G.CachedActorClass_ForVehicle, _G.CachedVehicleArray)

                            local activeVehicles = {}
                            if allVehicles then
                                for _, veh in pairs(allVehicles) do
                                    if slua.isValid(veh) and not veh.bHidden and not veh.bTearOff then
                                        local isPendingKill = false
                                        pcall(function() if type(veh.IsPendingKill) == "function" then isPendingKill = veh:IsPendingKill() end end)

                                        if not isPendingKill then
                                            local vehName = "Xe"
                                            local hasDriver = false

                                            pcall(function()
                                                if type(veh.GetVehicleName) == "function" then vehName = veh:GetVehicleName() elseif veh.VehicleName then vehName = veh.VehicleName end
                                                local driver = type(veh.GetDriver) == "function" and veh:GetDriver() or nil
                                                if slua.isValid(driver) then hasDriver = true end
                                            end)

                                            local nameLower = string.lower(tostring(vehName) .. tostring(veh))
                                            local displayName = "Xe"
                                            if string.find(nameLower, "uaz") then displayName = "UAZ"
                                            elseif string.find(nameLower, "dacia") then displayName = "Dacia"
                                            elseif string.find(nameLower, "buggy") then displayName = "Buggy"
                                            elseif string.find(nameLower, "mirado") then displayName = "Mirado"
                                            elseif string.find(nameLower, "bike") or string.find(nameLower, "motor") then displayName = "Motor"
                                            elseif string.find(nameLower, "scooter") then displayName = "Scooter"
                                            elseif string.find(nameLower, "coupe") then displayName = "Coupe RB"
                                            elseif string.find(nameLower, "brdm") then displayName = "BRDM"
                                            elseif string.find(nameLower, "boat") or string.find(nameLower, "aquarail") then displayName = "Thuyền"
                                            elseif string.find(nameLower, "glider") then displayName = "Tàu lượn"
                                            else displayName = "Xe (" .. string.sub(vehName, 1, 8) .. ")" end

                                            table.insert(activeVehicles, {act = veh, name = displayName, hasDriver = hasDriver})
                                        end
                                    end
                                end
                            end
                            _G.CachedVehicles = activeVehicles
                        end

                        if _G.CachedVehicles then
                            for _, item in ipairs(_G.CachedVehicles) do
                                local veh = item.act
                                if slua.isValid(veh) and not veh.bHidden then
                                    local isShow = false
                                    if item.name == "Dacia" then isShow = _G.LexusConfig.EspVeh_Dacia
                                    elseif item.name == "UAZ" then isShow = _G.LexusConfig.EspVeh_UAZ
                                    elseif item.name == "Buggy" then isShow = _G.LexusConfig.EspVeh_Buggy
                                    elseif item.name == "Coupe RB" then isShow = _G.LexusConfig.EspVeh_Coupe
                                    elseif item.name == "Mirado" then isShow = _G.LexusConfig.EspVeh_Mirado
                                    elseif item.name == "Motor" or item.name == "Scooter" then isShow = _G.LexusConfig.EspVeh_Motor
                                    else isShow = _G.LexusConfig.EspVeh_Other end

                                    if isShow then
                                        local distM = 0
                                        pcall(function() distM = localPlayer:GetDistanceTo(veh) / 100 end)

                                        if distM > 0 and distM <= 300 then
                                            local text = string.format("%s [%dm]", item.name, math.floor(distM))
                                            local vehColor = item.hasDriver and {R=255, G=50, B=50, A=255} or {R=0, G=255, B=150, A=255}
                                            local dynamicScale = math.max(0.6, 1.1 - (distM / 500))

                                            MyHUD:AddDebugText(text, veh, 0.06, {X=0, Y=0, Z=50}, {X=0, Y=0, Z=50}, vehColor, true, false, true, nil, dynamicScale, true)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end

    end)
end

_G.LexusState.LoopToken = (_G.LexusState.LoopToken or 0) + 1
local myToken = _G.LexusState.LoopToken

-- ==============================================================================
-- LICENSE LOGIN GATE
-- Login UI is created before the licensed runtime. Nothing in the runtime starts
-- until _G._LICENSE_OK == true.
-- ==============================================================================
_G.InstallLicenseSystem = function()
    if _G._LICENSE_SYSTEM_INSTALLED then return end
    _G._LICENSE_SYSTEM_INSTALLED = true

    _G.LicenseSystem = _G.LicenseSystem or {
        isOpen = false, panel = nil, widgets = {}, keyBox = nil, statusText = nil,
        isTrying = false, cachedCanvas = nil, periodicTimer = nil, periodicChar = nil,
        verified = false,
    }
    local LS = _G.LicenseSystem

    _G.LICENSE_CONFIG = _G.LICENSE_CONFIG or {
        LICENSE_URL = "https://License XTHRLEN link past",
        LOGIN_URL = "https://vip-panel.x10.mx/morebi/connect",
        GAME_NAME = "pubg",
        KEY_FILE = "/storage/emulated/0/Android/data/com.tencent.ig/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/keys.txt",
        UID_FILE = "/storage/emulated/0/Android/data/com.tencent.ig/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/uid.txt",
        DEFAULT_KEY = "VIPUSER",
        DEFAULT_UID = "00000000",
        BRAND_NAME = "@SRC_HUB",
        BRAND_SUB = "PREMIUM ACCESS",
        SUPPORT_TEXT = "Get Key / Support : @D_E_V_BLACK",
        TELEGRAM_URL = "https://t.me/SRC_HUB",
    }
    local CFG = _G.LICENSE_CONFIG
    local FVector2D = import("Vector2D")
    local FAnchors = import("Anchors")
    local FLinearColor = import("LinearColor")
    local FSlateColor = import("SlateColor") or import("/Script/SlateCore.SlateColor")

    local function Valid(o)
        return o and slua and slua.isValid and slua.isValid(o)
    end
    local function hash(str)
        local h = 5381
        str = tostring(str or "")
        for i = 1, #str do h = (h * 33 + string.byte(str, i)) % 2147483647 end
        return tostring(math.floor(h))
    end
    _G._LicenseHash = hash

    local function getDeviceId()
        local id
        pcall(function()
            local KSL = import("KismetSystemLibrary")
            if KSL then
                if KSL.GetDeviceId then id = KSL.GetDeviceId() end
                if (not id or id == "") and KSL.GetDeviceIdOS then id = KSL.GetDeviceIdOS() end
            end
        end)
        if id then id = tostring(id):gsub("[^A-Za-z0-9%-_]", "") end
        if not id or id == "" then id = nil end
        return id
    end
    local function getUIDFromPC()
        local uid
        pcall(function()
            local pc = slua_GameFrontendHUD and slua_GameFrontendHUD.GetPlayerController and slua_GameFrontendHUD:GetPlayerController()
            if pc then
                if pc.UID then uid = tostring(pc.UID) end
                if (not uid or uid == "" or uid == "0") and pc.PlayerState and pc.PlayerState.UID then uid = tostring(pc.PlayerState.UID) end
            end
        end)
        if uid == "" or uid == "0" then uid = nil end
        return uid
    end
    local function getOrCreateUID()
        local uid
        pcall(function()
            local f = io.open(CFG.UID_FILE, "r")
            if f then uid = f:read("*all"); f:close() end
            if uid then uid = uid:gsub("%s+", "") end
            if not uid or uid == "" then
                uid = "ZN-" .. tostring(math.random(100000, 999999)) .. tostring(math.random(100000, 999999))
                local w = io.open(CFG.UID_FILE, "w")
                if w then w:write(uid); w:close() end
            end
        end)
        return uid
    end
    local function getSerial()
        return getDeviceId() or getUIDFromPC() or getOrCreateUID()
    end
    local function readKeyFromFile()
        local key
        pcall(function()
            local f = io.open(CFG.KEY_FILE, "r")
            if f then key = f:read("*all"); f:close() end
            if key then key = key:gsub("%s+", "") end
            if key == "" then key = nil end
        end)
        return key
    end
    local function saveKeyToFile(key)
        _G._LICENSE_KEY = key
        pcall(function()
            local f = io.open(CFG.KEY_FILE, "w")
            if f then f:write(tostring(key)); f:close() end
        end)
    end
    local function getCurrentKey()
        return (_G._LICENSE_KEY and _G._LICENSE_KEY ~= "") and _G._LICENSE_KEY or readKeyFromFile()
    end
    local function mapReason(reason)
        if reason == "USER BLOCKED" then return "blocked" end
        if reason == "EXPIRED KEY" then return "expired" end
        if reason == "MAX DEVICE REACHED" then return "device_limit" end
        if reason == "USER OR GAME NOT REGISTERED" then return "invalid" end
        return "nonet"
    end
    local function checkLicense(key, serial, callback)
        if not key or key == "" or not serial or serial == "" then
            if callback then callback(false, "invalid") end
            return
        end
        local httpMgr
        pcall(function() httpMgr = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.http_manager) end)
        if not httpMgr or not httpMgr.Post then
            if callback then callback(false, "nonet") end
            return
        end
        local headers = { ["Content-Type"] = "application/x-www-form-urlencoded" }
        local body = "game=" .. tostring(CFG.GAME_NAME) .. "&user_key=" .. tostring(key) .. "&serial=" .. tostring(serial)
        local finished = false
        local function done(ok, reason)
            if finished then return end
            finished = true
            if callback then pcall(callback, ok == true, reason) end
        end
        pcall(function()
            httpMgr:Post(CFG.LOGIN_URL, headers, body, nil, function(ok, response)
                if ok and response then
                    local text = tostring(response)
                    if text:find('"status"%s*:%s*true') then done(true); return end
                    local reason
                    pcall(function() reason = text:match('"reason"%s*:%s*"([^"]+)"') end)
                    done(false, mapReason(reason))
                else
                    done(false, "nonet")
                end
            end, 15)
        end)
    end
    local function openTelegram()
        pcall(function()
            local KSL = import("KismetSystemLibrary")
            if KSL and KSL.LaunchURL then KSL.LaunchURL(CFG.TELEGRAM_URL) end
        end)
    end
    local function getCanvas()
        if LS.cachedCanvas and Game:IsValid(LS.cachedCanvas) then return LS.cachedCanvas end
        LS.cachedCanvas = nil
        pcall(function()
            local IGT = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools")
            local MainUI = IGT.GetMainControlBaseUI()
            if not MainUI or not Game:IsValid(MainUI) then return end
            if MainUI.CanvasPanel_0 and Game:IsValid(MainUI.CanvasPanel_0) then LS.cachedCanvas = MainUI.CanvasPanel_0
            elseif MainUI.CanvasPanel_42 and Game:IsValid(MainUI.CanvasPanel_42) then LS.cachedCanvas = MainUI.CanvasPanel_42 end
        end)
        return LS.cachedCanvas
    end
    local function Layer(p,x,y,w,h,col,z)
        local b
        pcall(function()
            b=CGame:NewObjectFromPath("/Script/UMG.Border",p)
            if b and slua.isValid(b) then
                b:SetBrushColor(col); b:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                local s=p:AddChildToCanvas(b)
                if s then s:SetAutoSize(false); s:SetPosition(FVector2D(x,y)); s:SetSize(FVector2D(w,h)); s:SetZOrder(z or 0) end
            end
        end)
        table.insert(LS.widgets,b); return b
    end
    local function Text(p,txt,x,y,size,col,z,ax,ay)
        local t
        pcall(function()
            t=CGame:NewObjectFromPath("/Script/UMG.TextBlock",p)
            if t and slua.isValid(t) then
                t:SetText(txt)
                if FSlateColor then t:SetColorAndOpacity(FSlateColor(col)) else t:SetColorAndOpacity(col) end
                if t.Font then local f=t.Font; f.Size=size; t.Font=f end
                t:SetRenderTransformPivot(FVector2D(ax or .5,ay or .5)); t:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                local s=p:AddChildToCanvas(t)
                if s then s:SetAutoSize(true); s:SetAlignment(FVector2D(ax or .5,ay or .5)); s:SetPosition(FVector2D(x,y)); s:SetZOrder(z or 100) end
            end
        end)
        table.insert(LS.widgets,t); return t
    end
    local function Btn(p,x,y,w,h,z,onClick)
        local btn
        pcall(function()
            btn=CGame:NewObjectFromPath("/Script/UMG.Button",p)
            if btn and slua.isValid(btn) then
                pcall(function() btn:SetColorAndOpacity(FLinearColor(0,0,0,.001)); btn:SetBackgroundColor(FLinearColor(0,0,0,.001)) end)
                btn:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
                local s=p:AddChildToCanvas(btn)
                if s then s:SetAutoSize(false); s:SetPosition(FVector2D(x,y)); s:SetSize(FVector2D(w,h)); s:SetZOrder(z or 900) end
                if onClick and btn.OnClicked then pcall(function() btn.OnClicked:Add(function() pcall(onClick) end) end) end
            end
        end)
        table.insert(LS.widgets,btn); return btn
    end
    local function FlatBtn(parent,x,y,w,h,label,color,labelColor,onClick)
        Layer(parent,x,y,w,h,color,400); Text(parent,label,x+w*.5,y+h*.5,11,labelColor or FLinearColor(1,1,1,1),402,.5,.5); Btn(parent,x,y,w,h,850,onClick)
    end
    local function InputBox(parent,x,y,w,h)
        local box
        pcall(function()
            box=CGame:NewObjectFromPath("/Script/UMG.EditableTextBox",parent)
            if box and slua.isValid(box) then
                pcall(function()
                    if box.SetHintText then box:SetHintText("Enter your VIP key here") end
                    if box.SetBackgroundColor then box:SetBackgroundColor(FLinearColor(.05,.05,.05,1)) end
                    if box.SetForegroundColor then box:SetForegroundColor(FLinearColor(1,1,1,1)) end
                end)
                local s=parent:AddChildToCanvas(box)
                if s then s:SetAutoSize(false); s:SetAlignment(FVector2D(.5,.5)); s:SetPosition(FVector2D(x+w*.5,y+h*.5)); s:SetSize(FVector2D(w,h)); s:SetZOrder(500) end
            end
        end)
        table.insert(LS.widgets,box); return box
    end
    local function getBoxText(box)
        local txt
        pcall(function()
            if box and slua.isValid(box) and box.GetText then
                local v=box:GetText(); txt=type(v)=="string" and v or (v and v.ToString and v:ToString() or tostring(v))
            end
        end)
        if txt then txt=tostring(txt):gsub("[^A-Za-z0-9%-_]","") end
        return (txt and txt~="") and txt or nil
    end
    local function setStatus(txt,isError)
        if LS.statusText and Valid(LS.statusText) then pcall(function()
            LS.statusText:SetText(tostring(txt)); local col=isError and FLinearColor(1,.3,.3,1) or FLinearColor(1,.9,.4,1)
            if FSlateColor then LS.statusText:SetColorAndOpacity(FSlateColor(col)) else LS.statusText:SetColorAndOpacity(col) end
        end) end
    end
    -- BENMOD-style blue/cyan/magenta palette (matched to the supplied reference image).
    local LC={
        bg_window=FLinearColor(.188,.329,.463,.99),
        bg_header=FLinearColor(.247,.408,.525,1),
        bg_content=FLinearColor(.125,.220,.353,1),
        bg_panel=FLinearColor(.188,.329,.463,1),
        accent=FLinearColor(0,1,1,1),
        accent_cyan=FLinearColor(0,1,1,1),
        btn_login=FLinearColor(0,0.882,1,1),
        btn_getkey=FLinearColor(.698,.251,.867,1),
        btn_danger=FLinearColor(.80,.20,.30,1),
        text_white=FLinearColor(1,1,1,1),
        text_dim=FLinearColor(.78,.88,.94,1),
        text_green=FLinearColor(0,.95,1,1),
        text_cyan=FLinearColor(0,1,1,1),
        text_yellow=FLinearColor(1,.88,.30,1),
        text_red=FLinearColor(1,.35,.45,1)
    }
    local LW,LH,LHEADER_H=480,340,28
    local function cleanup()
        pcall(function() for _,w in ipairs(LS.widgets) do if w and Valid(w) then pcall(function() w:RemoveFromParent() end); pcall(function() w:ConditionalBeginDestroy() end) end end end)
        LS.widgets={}; pcall(function() if LS.panel and Valid(LS.panel) then LS.panel:RemoveFromParent(); LS.panel:ConditionalBeginDestroy() end end)
        LS.panel=nil; LS.keyBox=nil; LS.statusText=nil; LS.isOpen=false
    end
    _G._CleanupLicenseUI=cleanup
    local function buildLogin(errorText)
        cleanup(); local canvas=getCanvas(); if not canvas then return false end
        pcall(function()
            LS.panel=CGame:NewObjectFromPath("/Script/UMG.CanvasPanel",canvas)
            if LS.panel and slua.isValid(LS.panel) then
                local s=canvas:AddChildToCanvas(LS.panel)
                if s then
                    local vw, vh = 1920, 1080
                    pcall(function()
                        local ui_util = require("client.common.ui_util")
                        if ui_util and ui_util.GetViewportSize then
                            local vs = ui_util.GetViewportSize()
                            if vs and vs.X and vs.Y and vs.X > 200 and vs.Y > 200 then
                                vw, vh = vs.X, vs.Y
                            end
                        end
                    end)
                    s:SetAutoSize(false)
                    s:SetZOrder(99999)
                    s:SetAlignment(FVector2D(.5,.5))
                    s:SetPosition(FVector2D(vw*.5,vh*.5))
                    s:SetSize(FVector2D(LW,LH))
                end
            end
        end)
        if not LS.panel or not Valid(LS.panel) then return false end
        Layer(LS.panel,-1,-1,LW+2,LH+2,LC.accent,-1); Layer(LS.panel,0,0,LW,LH,LC.bg_window,1); Layer(LS.panel,0,0,LW,LHEADER_H,LC.bg_header,3); Layer(LS.panel,0,LHEADER_H-1,LW,1,LC.accent,4)
        Text(LS.panel,"🔐 "..tostring(CFG.BRAND_NAME),8,LHEADER_H*.5,11,LC.text_white,400,0,.5); Text(LS.panel,tostring(CFG.BRAND_SUB),LW*.5,LHEADER_H*.5,9,LC.text_dim,400,.5,.5)
        Layer(LS.panel,LW-24,5,18,18,LC.btn_danger,100); Text(LS.panel,"X",LW-15,14,11,LC.text_white,400,.5,.5); Btn(LS.panel,LW-24,5,18,18,850,function() cleanup() end)
        Layer(LS.panel,0,LHEADER_H,LW,LH-LHEADER_H,LC.bg_content,10)
        Text(LS.panel,"ENTER YOUR VIP KEY",LW*.5,LHEADER_H+28,14,LC.text_green,300,.5,.5); Text(LS.panel,"Menu will unlock after verification",LW*.5,LHEADER_H+50,8,LC.text_dim,300,.5,.5)
        local iw,ih,ix,iy=LW-60,36,30,LHEADER_H+75
        Layer(LS.panel,ix-1,iy-1,iw+2,ih+2,LC.accent_cyan,100); Layer(LS.panel,ix,iy,iw,ih,LC.bg_panel,101); LS.keyBox=InputBox(LS.panel,ix,iy,iw,ih)
        pcall(function() local saved=readKeyFromFile(); if saved and saved~="" and saved~=tostring(CFG.DEFAULT_KEY) and LS.keyBox and LS.keyBox.SetText then LS.keyBox:SetText(saved) end end)
        LS.statusText=Text(LS.panel,errorText or "Enter your VIP key",LW*.5,iy+ih+18,9,LC.text_yellow,300,.5,.5)
        local bw,bh,by=(LW-70)*.5,40,iy+ih+50
        FlatBtn(LS.panel,30,by,bw,bh,"LOGIN",LC.btn_login,LC.text_white,function()
            if LS.isTrying then return end
            local key=getBoxText(LS.keyBox); if not key or #key<4 then setStatus("❌ Please enter a valid key",true); return end
            LS.isTrying=true; setStatus("⏳ Checking key...",false); local serial=getSerial()
            checkLicense(key,serial,function(success,reason)
                LS.isTrying=false
                if success then
                    saveKeyToFile(key); _G._LICENSE_OK=true; _G._LICENSE_UID=serial; LS.verified=true; setStatus("✅ Success! Loading...",false)
                    pcall(function() _G.StopLoginLoop() end)
                    pcall(function() cleanup() end)
                    pcall(function() _G.StartLicensedSystems() end)
                    pcall(function() if _G.StartFeedbackAfterLogin then _G.StartFeedbackAfterLogin() end end)
                else
                    local msg="❌ Invalid key"; if reason=="blocked" then msg="🚫 Key is blocked" elseif reason=="expired" then msg="⏰ Key expired" elseif reason=="device_limit" then msg="📱 Device limit reached" elseif reason=="nonet" then msg="🌐 Network error - try again" end; setStatus(msg,true)
                end
            end)
        end)
        FlatBtn(LS.panel,LW-30-bw,by,bw,bh,"GET KEY",LC.btn_getkey,LC.text_white,function() setStatus("📱 Opening Telegram...",false); openTelegram() end)
        Text(LS.panel,tostring(CFG.SUPPORT_TEXT),LW*.5,LH-25,9,LC.text_cyan,300,.5,.5); Text(LS.panel,"🔒 Locked until verification",LW*.5,LH-10,8,LC.text_dim,300,.5,.5)
        LS.isOpen=true; return true
    end
    _G.BuildLoginScreen=buildLogin
    _G.StartLogin=function()
        _G._LICENSE_OK=false
        LS.verified=false
        buildLogin("Enter your VIP key, then press LOGIN")
        pcall(function() _G.StartLoginLoop() end)
    end
    _G.StartLoginLoop=function()
        if _G._LOGIN_LOOP_STARTED then return end
        _G._LOGIN_LOOP_STARTED=true
        local ticker=require("common.time_ticker"); if not ticker or not ticker.AddTimerLoop then _G._LOGIN_LOOP_STARTED=false; return end
        local lastCanvas=nil
        _G._LOGIN_LOOP_TIMER=ticker.AddTimerLoop(.75,function()
            pcall(function()
                if _G._LICENSE_OK==true then _G.StopLoginLoop(); return end
                local canvas=getCanvas(); if not canvas then return end
                if lastCanvas and lastCanvas~=canvas then cleanup() end
                lastCanvas=canvas
                if not LS.panel or not Valid(LS.panel) then buildLogin("Enter your VIP key") else LS.panel:SetWidgetVisibility(UEnums.ESlateVisibility.Visible); LS.isOpen=true end
            end)
        end,-1,.75)
    end
    _G.StopLoginLoop=function()
        _G._LOGIN_LOOP_STARTED=false
        pcall(function() local ticker=require("common.time_ticker"); if ticker and ticker.RemoveTimer and _G._LOGIN_LOOP_TIMER then ticker.RemoveTimer(_G._LOGIN_LOOP_TIMER) end end)
        _G._LOGIN_LOOP_TIMER=nil
    end
    _G.StartPeriodicLicenseCheck=function(character)
        if not character or not slua.isValid(character) then return end
        pcall(function() if LS.periodicTimer then character:RemoveGameTimer(LS.periodicTimer) end end)
        LS.periodicTimer=character:AddGameTimer(180,true,function()
            if _G._LICENSE_OK~=true then return end
            local key=getCurrentKey(); local serial=_G._LICENSE_UID or getSerial(); if not key or not serial then return end
            checkLicense(key,serial,function(success,reason)
                if not success and reason~="nonet" then
                    _G._LICENSE_OK=false; LS.verified=false
                    pcall(function() if _G.StopLicensedSystems then _G.StopLicensedSystems() end end)
                    pcall(function() buildLogin("License revoked - please re-login"); _G.StartLoginLoop() end)
                end
            end)
        end)
        LS.periodicChar=character
    end
    _G.LicenseAPI={Start=_G.StartLogin,Build=_G.BuildLoginScreen,StartPeriodicCheck=_G.StartPeriodicLicenseCheck,CheckLicense=checkLicense,GetSerial=getSerial,GetCurrentKey=getCurrentKey,SaveKey=saveKeyToFile,Config=CFG}
end

_G.InstallLicenseSystem()

-- Runtime is started only by successful license verification.
_G.StartLicensedSystems=function()
    if _G._LICENSE_OK~=true then return end
    if _G._LICENSE_RUNTIME_STARTED then return end
    _G._LICENSE_RUNTIME_STARTED=true
    _G._LICENSE_PENDING_START=true
    pcall(function() if _G._StartLicensedRuntime then _G._StartLicensedRuntime() end end)
end

_G.StopLicensedSystems=function()
    _G._LICENSE_RUNTIME_STARTED=false
    _G._LICENSE_PENDING_START=false
    _G.LexusState.LoopToken=(_G.LexusState.LoopToken or 0)+1
end


_G._StartLicensedRuntime=function()
    if _G._LICENSE_OK~=true then return end
    _G.LexusState.LoopToken=(_G.LexusState.LoopToken or 0)+1
    local myToken=_G.LexusState.LoopToken
    local function FastTick()
        if _G._LICENSE_OK~=true then return end
        if myToken~=_G.LexusState.LoopToken then return end
        local now=os.clock()
        if now-_LastESPPositionTime>=ESP_POSITION_INTERVAL then
            _LastESPPositionTime=now
            if _G.LexusConfig.EspLoai9 and _G.PlayerMapMarker and _G.PlayerMapMarker.bActive then pcall(function() _G.PlayerMapMarker.UpdateESPLight() end) end
        end
        -- LAVA ESP uses the SAME persistent runtime tick as the original ESP/menu systems.
        -- Do not create a separate ESP timer: FastTick survives lobby -> match -> next match.
        if _G._LICENSE_OK == true and _G.BoxESP then
            pcall(function()
                local lavaEnabled = (_G.LexusConfig and _G.LexusConfig.LavaESP == true)
                if lavaEnabled then
                    _G.BoxESP.bActive = true
                    if _G.BoxESP.UpdateESP then _G.BoxESP.UpdateESP() end
                else
                    if _G.BoxESP.bActive == true then
                        _G.BoxESP.bActive = false
                        for _, w in pairs(_G.BoxESP.BoxWidgets or {}) do
                            if _G.BoxESP.HideWidget then pcall(function() _G.BoxESP.HideWidget(w) end) end
                        end
                        for key, _ in pairs(_G.BoxESP.LineWidgets or {}) do
                            if _G.BoxESP.HideSnapLine then pcall(function() _G.BoxESP.HideSnapLine(key) end) end
                        end
                        local cd = _G.BoxESP.CounterData
                        if cd then
                            for _, k in ipairs({"ImgPlayer","ImgBot","TxtPlayer","TxtBot"}) do
                                local widget = cd[k]
                                if widget and widget.SetWidgetVisibility then pcall(function() widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end) end
                            end
                        end
                    end
                end
            end)
        end

        pcall(MainLoop)
        if _G._LICENSE_OK==true then
            local okTicker,ticker=pcall(require,"common.time_ticker")
            if okTicker and ticker and ticker.AddTimerOnce then ticker.AddTimerOnce(.033,FastTick) end
        end
    end
    _G._LICENSE_FASTTICK=FastTick
    local function InitAllModSystems()
        if _G._LICENSE_OK~=true then return end
        pcall(function() if _G.InitializeAutoHeadHooks then _G.InitializeAutoHeadHooks() end end)
        local GameplayData=package.loaded["GameLua.GameCore.Data.GameplayData"] or require("GameLua.GameCore.Data.GameplayData")
        if not GameplayData then return end
        pcall(function()
            local LocalPlayer=GameplayData.GetPlayerCharacter and GameplayData.GetPlayerCharacter()
            if slua.isValid(LocalPlayer) and LocalPlayer.bHasShownDevNotice==nil then
                LocalPlayer.bHasShownDevNotice=false; LocalPlayer.bHasShownExpiredNotice=false; LocalPlayer.bIsDeadFlag=false
            end
        end)
    end
    pcall(function() require("common.time_ticker").AddTimerOnce(.5,InitAllModSystems) end)
    pcall(FastTick)
    -- Start menu/skin systems only after the license is actually verified.
    -- New skin engine is lazy: it is initialized only after license verification.
    pcall(function() if _G.StartSkinLoop then _G.StartSkinLoop() end end)
    pcall(function() if _G.StartFloatLoop then _G.StartFloatLoop() end end)
    pcall(function()
        local GameplayData=package.loaded["GameLua.GameCore.Data.GameplayData"] or require("GameLua.GameCore.Data.GameplayData")
        local character=GameplayData and GameplayData.GetPlayerCharacter and GameplayData.GetPlayerCharacter()
        if character and _G.StartPeriodicLicenseCheck then _G.StartPeriodicLicenseCheck(character) end
    end)
end

-- Start the login UI first. Runtime above is intentionally not started here.
pcall(function()
    local ticker=require("common.time_ticker")
    if ticker and ticker.AddTimerOnce then ticker.AddTimerOnce(1.0,function()
        if _G._LICENSE_OK~=true then _G.StartLogin() end
    end) end
end)


_G.BaseAttachToIndex = {
    [201010]=1, [201005]=1, [201004]=1, [201009]=2, [201003]=2, [201002]=2,
    [201011]=3, [201007]=3, [201006]=3, [204012]=4, [204005]=4, [204008]=4,
    [204011]=5, [204004]=5, [204007]=5, [204013]=6, [204006]=6, [204009]=6,
    [203001]=7, [203002]=8, [203003]=9, [203014]=10, [203004]=11, [203015]=12, [203005]=13,
    [202002]=14, [202001]=15, [202004]=16, [202005]=17, [202007]=18, [202006]=19,
    [205002]=20, [205003]=20, [205001]=20, [203018]=21, [204014]=22
}


_G.VIP_Attachments = {

    [1101004236]={1010042307,1010042306,1010042308,1010042304,1010042300,1010042305,1010042299,1010042298,1010042297,1010042296,1010042295,1010042294,0,1010042314,1010042309,1010042316,1010042317,1010042318,1010042310,1010042315,1010042319,0},
    [1101001116]={1010011106,1010011107,1010011108,0,1010011109,1010011112,1010011105,1010011104,1010011103,0,1010011102,0,0,0,0,0,0,0,0,0,0,0},
    [1101001128]={1010011232,1010011233,1010011234,1010011228,1010011227,1010011229,1010011226,1010011225,1010011224,1010011223,1010011222,0,0,0,0,0,0,0,0,0,0,0},
    [1101001154]={1010011487,1010011488,1010011489,1010011493,1010011490,1010011494,1010011486,1010011485,1010011484,1010011483,1010011482,1010011497,0,0,0,0,0,0,0,0,1010011498,0},
    [1101001174]={1010011667,1010011668,1010011669,1010011673,1010011670,1010011674,1010011666,1010011665,1010011664,1010011663,1010011662,0,0,0,0,0,0,0,0,0,0,0},
    [1101001213]={1010012067,1010012068,1010012069,1010012072,1010012070,1010012073,1010012066,1010012065,1010012064,1010012063,1010012062,0,0,0,0,0,0,0,0,0,1010012074,0},
    [1101001231]={1010012267,1010012268,1010012269,1010012273,1010012272,1010012274,1010012266,1010012265,1010012264,1010012263,1010012262,1010012075,0,0,0,0,0,0,0,0,1010012275,0},
    [1101001242]={1010012357,1010012358,1010012359,1010012363,1010012362,1010012364,1010012356,1010012355,1010012354,1010012353,1010012352,1010012276,0,0,0,0,0,0,0,0,1010012365,0},
    [1101001249]={1010012437,1010012438,1010012439,1010012443,1010012442,1010012444,1010012436,1010012435,1010012434,1010012433,1010012432,1010012366,0,0,0,0,0,0,0,0,1010012445,0},
    [1101001256]={1010012588,1010012589,1010012590,1010012593,1010012592,1010012594,1010012587,1010012586,1010012585,1010012584,1010012583,1010012582,0,0,0,0,0,0,0,0,1010012595,0},
    [1101001265]={1010012698,1010012699,1010012700,1010012703,1010012702,1010012704,1010012697,1010012696,1010012695,1010012694,1010012693,1010012692,0,0,0,0,0,0,0,0,1010012705,0},
    [1101001276]={1010012698,1010012699,1010012700,1010012703,1010012702,1010012704,1010012697,1010012696,1010012695,1010012694,1010012693,1010012692,0,0,0,0,0,0,0,0,1010012705,0},
    [1101002029]={1010020249,1010020250,1010020255,1010020247,1010020246,1010020248,1010020240,1010020239,1010020238,1010020237,1010020236,1010020235,0,0,0,0,0,0,0,1010020257,1010020256,1010020258},
    [1101002056]={1010020519,0,0,1010020517,1010020516,1010020518,1010020500,1010020509,1010020508,1010020507,1010020506,1010020505,0,0,0,0,0,0,0,0,0,0},
    [1101002081]={1010020768,1010020769,1010020770,1010020766,1010020760,1010020767,1010020759,1010020758,1010020757,1010020756,1010020755,1010020776,0,0,0,0,0,0,0,1010020775,1010020777,1010020778},
    [1101003070]={1010030654,1010030653,1010030655,1010030649,1010030648,1010030650,1010030647,1010030646,1010030645,1010030644,1010030643,1010030642,0,1010030658,1010030656,1010030660,1010030662,1010030659,1010030657,0,1010030663,0},
    [1101003080]={1010030754,1010030753,1010030755,1010030749,1010030748,1010030750,1010030747,1010030746,1010030745,1010030744,1010030743,1010030742,0,1010030758,1010030756,1010030760,1010030762,1010030759,1010030757,0,1010030763,0},
    [1101003099]={1010030943,1010030944,1010030945,1010030939,1010030938,1010030942,1010030937,1010030936,1010030935,1010030934,1010030933,1010030932,0,1010030947,1010030946,1010030948,1010030949,1010030953,1010030952,0,1010030955,0},
    [1101003119]={1010031139,1010031140,1010031142,1010031138,1010031137,1010031146,1010031136,1010031135,1010031134,1010031133,1010031132,0,0,1010031144,1010031143,0,0,0,1010031145,0,0,0},
    [1101003146]={1010031229,1010031230,1010031237,1010031228,1010031227,1010031242,1010031226,1010031225,1010031224,1010031223,1010031222,0,0,1010031239,1010031238,0,0,0,1010031240,0,0,0},
    [1101003167]={1010031609,1010031610,1010031613,1010031608,1010031607,1010031617,1010031606,1010031605,1010031604,1010031603,1010031602,1010031618,0,1010031615,1010031614,1010031620,1010031622,1010031619,1010031616,0,1010031623,0},
    [1101003181]={1010031765,1010031764,1010031766,1010031759,1010031758,1010031763,1010031757,1010031756,1010031755,1010031754,1010031753,1010031752,0,1010031769,1010031767,1010031773,1010031774,1010031772,1010031768,0,1010031775,0},
    [1101003195]={1010031912,1010031911,1010031913,1010031908,1010031907,1010031909,1010031906,1010031905,1010031904,1010031903,1010031902,1010031901,0,1010031916,1010031914,1010031918,1010031919,1010031917,1010031915,0,1010031921,0},
    [1101003208]={1010032034,1010032033,1010032045,1010032029,1010032028,1010032032,1010032027,1010032026,1010032025,1010032024,1010032023,1010032022,0,1010032038,1010032036,1010032042,1010032043,1010032039,1010032037,0,1010032044,0},
    [1101004046]={1010040474,1010040475,1010040476,1010040472,1010040471,1010040473,1010040470,1010040469,1010040468,1010040467,1010040466,1010040481,0,1010040479,1010040477,1010040482,1010040483,1010040484,1010040478,1010040480,1010040485,0},
    [1101004062]={1010040578,1010040577,1010040579,1010040575,1010040570,1010040576,1010040569,1010040568,1010040567,1010040566,1010040565,1010040564,0,1010040585,1010040580,1010040587,1010040588,1010040589,1010040584,1010040586,1010040590,1010040594},
    [1101004098]={1010040924,1010040926,1010040925,0,1010040937,1010040938,1010040935,1010040934,1010040929,1010040928,1010040927,0,0,1010040939,1010040945,0,0,0,1010040944,1010040936,0,0},
    [1101004138]={1010041136,1010041137,1010041138,1010041134,1010041129,1010041135,1010041128,1010041127,1010041126,1010041125,1010041124,0,0,1010041145,1010041139,0,0,0,1010041144,1010041146,0,0},
    [1101004163]={1010041570,1010041574,1010041575,1010041568,1010041567,1010041569,1010041566,1010041565,1010041564,1010041560,1010041554,0,0,1010041578,1010041576,0,0,0,1010041577,1010041579,0,0},
    [1101004201]={1010041956,1010041957,1010041958,1010041950,1010041949,1010041955,1010041948,1010041947,1010041946,1010041945,1010041944,1010041967,0,1010041965,1010041959,0,0,0,1010041960,1010041966,0,0},
    [1101004209]={1010042038,1010042037,1010042039,1010042035,1010042034,1010042036,1010042029,1010042028,1010042027,1010042026,1010042025,1010042024,0,1010042046,1010042044,1010042048,1010042049,1010042054,1010042045,1010042047,1010042055,0},
    [1101004218]={1010042128,1010042127,1010042129,1010042125,1010042124,1010042126,1010042119,1010042118,1010042117,1010042116,1010042115,1010042114,0,1010042136,1010042134,1010042138,1010042139,1010042144,1010042135,1010042137,1010042145,0},
    [1101004226]={1010042238,1010042237,1010042239,1010042235,1010042234,1010042236,1010042233,1010042232,1010042231,1010042219,1010042218,1010042217,0,1010042243,1010042241,1010042245,1010042246,1010042247,1010042242,1010042244,1010042248,0},
    [1101004246]={1010042406,1010042407,1010042408,1010042404,1010042400,1010042405,1010042399,1010042398,1010042397,1010042396,1010042395,1010042394,0,1010042414,1010042409,1010042416,1010042417,1010042418,1010042410,1010042415,1010042419,1010042420},
    [1101005038]={0,0,1010050327,1010050329,1010050328,1010050330,1010050326,1010050325,1010050324,1010050323,1010050322,1010050334,0,0,0,0,0,0,0,0,0,0},
    [1101005052]={0,0,1010050467,1010050469,1010050468,1010050470,1010050466,1010050465,1010050464,1010050463,1010050462,1010050473,0,0,0,0,0,0,0,0,0,0},
    [1101005098]={0,0,1010050928,1010050930,1010050929,1010050932,1010050927,1010050926,1010050925,1010050924,1010050923,1010050922,0,0,0,0,0,0,0,0,0,0},
    [1101006062]={1010060573,1010060572,1010060574,1010060564,1010060563,1010060571,1010060562,1010060561,1010060554,1010060553,1010060552,1010060551,0,1010060583,1010060581,1010060591,1010060592,1010060584,1010060582,0,1010060593,0},
    [1101006075]={1010060702,1010060701,1010060703,1010060698,1010060697,1010060699,1010060696,1010060695,1010060694,1010060693,1010060692,1010060691,0,1010060706,1010060704,1010060708,1010060709,1010060707,1010060705,0,1010060711,0},
    [1101006085]={1010060796,1010060795,1010060797,1010060793,1010060789,1010060794,1010060788,1010060787,1010060786,1010060785,1010060784,1010060783,0,1010060800,1010060798,1010060804,1010060805,1010060803,1010060799,0,1010060806,0},
    [1101007046]={1010070410,1010070413,1010070414,1010070408,1010070407,1010070409,1010070406,1010070405,1010070404,1010070403,1010070402,1010070418,0,1010070417,1010070415,1010070420,1010070422,1010070419,1010070416,0,1010070423,0},
    [1101007062]={1010070579,1010070578,1010070581,1010070576,1010070575,1010070577,1010070574,1010070573,1010070572,1010070571,1010070569,1010070568,0,1010070584,1010070582,1010070585,1010070586,1010070587,1010070583,0,1010070588,0},
    [1101007071]={1010070663,1010070662,1010070664,1010070659,1010070658,1010070660,1010070657,1010070656,1010070655,1010070654,1010070653,1010070652,0,1010070667,1010070665,1010070668,1010070669,1010070670,1010070666,0,1010070672,0},
    [1101008051]={1010080463,1010080464,1010080465,1010080459,1010080458,1010080462,1010080457,1010080456,1010080455,1010080454,1010080453,1010080452,0,1010080467,1010080466,1010080468,1010080469,1010080473,1010080472,0,1010080475,0},
    [1101008061]={1010080563,1010080564,1010080565,1010080559,1010080558,1010080562,1010080557,1010080556,1010080555,1010080554,1010080553,0,0,1010080567,1010080566,0,0,0,1010080572,0,0,0},
    [1101008070]={1010080609,1010080612,1010080613,1010080608,1010080607,1010080617,1010080606,1010080605,1010080604,1010080603,1010080602,0,0,1010080615,1010080614,0,0,0,1010080616,0,0,0},
    [1101008081]={1010080740,1010080743,1010080745,1010080738,1010080737,1010080739,1010080736,1010080735,1010080734,1010080733,1010080732,1010080748,0,1010080747,1010080746,1010080750,1010080752,1010080749,1010080744,0,1010080753,0},
    [1101008104]={1010080980,1010080982,1010080984,1010080978,1010080977,1010080979,1010080976,1010080975,1010080974,1010080973,1010080972,1010080992,0,1010080986,1010080985,1010080989,1010080987,1010080993,1010080983,0,1010080988,0},
    [1101008116]={1010081110,1010081112,1010081114,1010081108,1010081107,1010081109,1010081106,1010081105,1010081104,1010081103,1010081102,0,0,1010081116,1010081115,0,0,0,1010081113,0,0,0},
    [1101008126]={1010081210,1010081225,1010081226,1010081208,1010081207,1010081209,1010081206,1010081205,1010081204,1010081203,1010081202,1010081218,0,1010081217,1010081216,1010081219,1010081220,1010081222,1010081214,1010081228,1010081227,1010081229},
    [1101008136]={1010081314,1010081315,1010081316,1010081312,1010081308,1010081313,1010081307,1010081306,1010081305,1010081304,1010081303,1010081302,0,1010081318,1010081317,1010081322,1010081323,1010081325,1010081324,0,1010081326,0},
    [1101008146]={1010081401,1010081402,1010081403,1010081398,1010081397,1010081399,1010081396,1010081395,1010081394,1010081393,1010081392,1010081391,0,1010081405,1010081404,1010081406,1010081407,1010081409,1010081408,0,1010081411,0},
    [1101008154]={1010081531,1010081532,1010081533,1010081528,1010081527,1010081529,1010081526,1010081525,1010081524,1010081523,1010081522,1010081521,0,1010081541,1010081534,1010081542,1010081543,1010081545,1010081544,0,1010081546,0},
    [1101008163]={1010081582,1010081583,1010081584,1010081579,1010081578,1010081580,1010081577,1010081576,1010081575,1010081574,1010081573,1010081572,0,1010081586,1010081585,1010081587,1010081588,1010081590,1010081589,0,1010081592,0},
    [1101012033]={1010120284,1010120285,1010120286,1010120280,1010120279,1010120283,1010120278,1010120277,1010120276,1010120275,1010120274,1010120273,0,0,0,0,0,0,0,0,1010120287,0},
    [1101100012]={1011000066,1011000067,1011000068,0,0,0,1011000058,1011000057,1011000056,1011000055,1011000054,1011000053,0,0,0,0,0,0,0,0,1011000073,0},
    [1101102007]={1011010025,1011010024,1011010026,1011010020,1011010019,1011010023,1011010018,1011010017,1011010016,1011010015,1011010014,1011010013,0,0,0,0,0,0,0,0,1011010027,0},
    [1101102017]={1011020027,1011020028,1011020029,1011020025,1011020024,1011020026,1011020019,1011020018,1011020017,1011020016,1011020015,1011020014,0,1011020036,1011020034,1011020038,1011020039,1011020044,1011020035,1011020037,1011020045,1011020047},
    [1101102025]={1011020127,1011020128,1011020129,1011020125,1011020124,1011020126,1011020119,1011020118,1011020117,1011020116,1011020115,1011020114,0,1011020136,1011020134,1011020138,1011020139,1011020144,1011020135,1011020137,1011020145,0},
    [1101102041]={1011020214,1011020215,1011020216,1011020212,1011020211,1011020213,1011020209,1011020208,1011020207,1011020206,1011020205,1011020204,0,1011020219,1011020217,1011020222,1011020223,1011020224,1011020218,1011020221,1011020225,1011020229},
    [1101102049]={1011020356,1011020357,1011020358,1011020354,1011020350,1011020355,1011020349,1011020348,1011020347,1011020346,1011020345,1011020344,0,1011020364,1011020359,1011020366,1011020367,1011020368,1011020360,1011020365,1011020369,1011020370},
    [1101101007]={1011020436,1011020437,1011020438,1011020434,1011020430,1011020435,1011020429,1011020428,1011020427,1011020426,1011020425,1011020424,0,1011020444,1011020439,1011020446,1011020447,1011020448,1011020440,1011020445,1011020449,1011020450},
    [1102001120]={1020011137,1020011138,1020011139,1020011135,1020011134,1020011136,1020011133,1020011132,0,0,0,0,0,0,0,0,0,0,0,1020011142,0,0},
    [1102001130]={1020011247,1020011248,1020011249,1020011245,1020011244,1020011246,1020011243,1020011242,0,0,0,0,0,0,0,0,0,0,0,1020011250,0,0},
    [1102002043]={1020020372,1020020374,1020020373,1020020383,1020020380,1020020384,1020020379,1020020378,1020020377,1020020376,1020020375,1020020388,0,1020020385,1020020387,0,0,0,1020020386,0,0,0},
    [1102002061]={1020020552,1020020554,1020020553,1020020563,1020020562,1020020564,1020020559,1020020558,1020020557,1020020556,1020020555,1020020578,0,1020020565,1020020567,1020020573,1020020574,1020020572,1020020566,0,1020020569,0},
    [1102002136]={1020021314,1020021313,1020021315,1020021309,1020021308,1020021312,1020021307,1020021306,1020021305,1020021304,1020021303,1020021302,0,1020021318,1020021316,1020021323,1020021324,1020021322,1020021317,0,1020021325,0},
    [1102002424]={1020024193,1020024192,1020024194,1020024189,1020024188,1020024190,1020024187,1020024186,1020024185,1020024184,1020024183,1020024182,0,1020024197,1020024195,1020024199,1020024200,1020024198,1020024196,0,1020024202,0},
    [1102003080]={1020030755,1020030756,1020030758,0,1020030749,1020030754,1020030748,1020030747,1020030746,1020030745,1020030744,1020030764,0,1020030760,0,1020030759,1020030757,0,0,1020030765,0,0},
    [1102003100]={1020030956,1020030957,1020030958,1020030954,1020030950,1020030955,1020030949,1020030948,1020030947,1020030946,1020030945,1020030944,0,1020030964,0,1020030960,1020030959,1020030965,0,1020030967,1020030966,1020030968},
    [1102005064]={1020050588,1020050589,1020050590,0,0,0,1020050587,1020050586,1020050585,1020050584,1020050583,1020050582,0,0,0,0,0,0,0,0,1020050592,0},
    [1103001101]={1030010954,1030010955,1030010956,0,0,0,0,0,0,0,1030010953,1030010952,1030010951,0,0,0,0,0,0,1030010957,0,1030010958},
    [1103001146]={1030011344,1030011345,1030011346,0,0,0,0,0,0,0,1030011343,1030011342,1030011341,0,0,0,0,0,0,1030011347,0,1030011348},
    [1103001154]={1030011484,1030011485,1030011486,0,0,0,0,0,0,0,1030011483,1030011482,1030011481,0,0,0,0,0,0,1030011487,0,1030011488},
    [1103001179]={1030011738,1030011739,1030011741,0,0,0,1030011737,1030011736,1030011735,1030011734,1030011733,1030011732,1030011731,0,0,0,0,0,0,1030011742,1030011743,1030011744},
    [1103001191]={1030011858,1030011859,1030011861,0,0,0,1030011857,1030011856,1030011855,1030011854,1030011853,1030011852,1030011851,0,0,0,0,0,0,1030011862,1030011863,1030011864},
    [1103001202]={1030011948,1030011949,1030011950,0,0,0,1030011947,1030011946,1030011945,1030011944,1030011943,1030011942,1030011941,0,0,0,0,0,0,1030011951,1030011952,1030011953},
    [1103002030]={1030020245,1030020246,1030020247,1030020252,1030020249,1030020253,1030020258,1030020257,1030020256,1030020255,1030020244,1030020243,1030020242,0,0,0,0,0,0,1030020248,0,0},
    [1103002059]={1030020544,1030020545,1030020546,1030020542,1030020539,1030020543,1030020538,1030020537,1030020536,1030020535,1030020534,1030020533,1030020532,0,0,0,0,0,0,1030020547,1030020548,0},
    [1103002087]={1030020824,1030020825,1030020826,0,0,0,1030020818,1030020817,1030020816,1030020815,1030020814,1030020813,1030020812,0,0,0,0,0,0,1030020827,1030020828,0},
    [1103002106]={1030021009,1030021010,1030021012,1030021015,1030021014,1030021016,1030021008,1030021007,1030021006,1030021005,1030021004,1030021003,1030021002,0,0,0,0,0,0,1030021013,1030021017,0},
    [1103002113]={1030021079,1030021080,1030021082,1030021085,1030021084,1030021086,1030021078,1030021077,1030021076,1030021075,1030021074,1030021073,1030021072,0,0,0,0,0,0,1030021083,1030021087,0},
    [1103003022]={1030030165,1030030166,1030030167,1030030172,1030030169,1030030173,0,0,0,0,1030030164,1030030163,1030030162,0,0,0,0,0,0,0,0,0},
    [1103003030]={1030030256,1030030257,1030030258,1030030254,1030030253,1030030255,1030030248,1030030247,1030030246,1030030245,1030030244,1030030243,1030030242,0,0,0,0,0,0,1030030259,1030030249,0},
    [1103003042]={1030030374,1030030375,1030030376,1030030372,1030030369,1030030373,0,0,0,0,1030030364,1030030363,1030030362,0,0,0,0,0,0,1030030377,0,0},
    [1103003051]={1030030458,1030030459,1030030460,1030030456,1030030455,1030030457,0,0,0,0,1030030454,1030030453,1030030452,0,0,0,0,0,0,1030030463,0,0},
    [1103003062]={1030030568,1030030569,1030030570,1030030566,1030030565,1030030567,0,0,0,0,1030030564,1030030563,1030030562,0,0,0,0,0,0,1030030572,0,0},
    [1103003079]={1030030744,1030030745,1030030746,1030030742,1030030740,1030030743,1030030738,1030030737,1030030736,1030030735,1030030734,1030030733,1030030732,0,0,0,0,0,0,1030030747,1030030739,0},
    [1103003087]={1030030825,1030030826,1030030827,1030030823,1030030824,1030030824,1030030818,1030030817,1030030816,1030030815,1030030814,1030030813,1030030812,0,0,0,0,0,0,1030030828,1030030819,0},
    [1103004037]={1030040315,1030040316,1030040317,1030040325,1030040324,1030040323,0,0,0,0,1030040314,1030040313,1030040312,1030040327,1030040326,0,0,0,1030040328,1030040329,0,0},
    [1103006030]={1030060245,1030060246,1030060247,0,1030060253,1030060252,0,0,0,0,1030060244,1030060243,1030060242,0,0,0,0,0,0,0,0,0},
    [1103007028]={1030070233,1030070234,1030070235,1030070226,1030070225,1030070227,1030070218,1030070217,1030070216,1030070215,1030070214,1030070213,1030070212,0,0,0,0,0,0,1030070236,1030070219,0},
    [1103012010]={0,0,0,0,0,0,1030120038,1030120037,1030120036,1030120035,1030120034,1030120033,1030120032,0,0,0,0,0,0,0,0,0},
    [1103012019]={0,0,0,0,0,0,1030120138,1030120137,1030120136,1030120135,1030120134,1030120133,1030120132,0,0,0,0,0,0,0,0,0},
    [1103012031]={0,0,0,0,0,0,1030120258,1030120257,1030120256,1030120255,1030120254,1030120253,1030120252,0,0,0,0,0,0,0,0,0},
    [1103012039]={0,0,0,0,0,0,1030120339,1030120338,1030120337,1030120336,1030120335,1030120334,1030120333,0,0,0,0,0,0,0,0,0},
    [1103102007]={1031020026,1031020027,1031020028,1031020024,1031020023,1031020025,1031020019,1031020018,1031020017,1031020016,1031020015,1031020014,1031020013,0,0,0,0,0,0,1031020029,0,0},
    [1105001034]={0,0,0,0,1050010287,1050010289,1050010286,1050010285,1050010284,1050010283,1050010282,0,0,0,0,0,0,0,0,1050010292,0,0},
    [1105001048]={0,0,0,1050010429,1050010428,1050010434,1050010427,1050010426,1050010425,1050010424,1050010423,0,0,0,0,0,0,0,0,1050010435,0,1050010436},
    [1105001069]={0,0,0,1050010639,1050010638,1050010640,1050010637,1050010636,1050010635,1050010634,1050010633,1050010645,0,0,0,0,0,0,0,1050010643,1050010646,1050010644},
    [1105002091]={0,0,0,0,0,0,1050020847,1050020846,1050020845,1050020844,1050020843,1050020842,0,0,0,0,0,0,0,0,0,1050020848},
    [1105010019]={0,0,0,0,0,0,1050100144,1050100143,1050100142,1050100141,1050100139,1050100138,0,0,0,0,0,0,0,0,0,0},

    [1101006098] = {1010060925,1010060926,1010060927,1010060919,0,1010060924,1010060918,1010060917,1010060916,1010060915,1010060914,1010060913,0,1010060930,1010060928,1010060929,1010060935,1010060934,1010060933,0,1010060936,0},


    [1101006106] = {1010061004,1010061005,1010061006,1010060999,1010061000,1010061003,1010060998,1010060997,1010060996,1010060995,1010060994,1010060993,0,1010061009,1010061007,1010061008,1010061014,1010061013,1010061010,0,1010061015,0},
}


local cached_GameplayStatics = nil
local cached_PlayerTombBox = nil
local cached_ActorClass = nil
_G.NeedCheckDeadBoxTimer = 0

_G.DeadBox_TemperRequest = function(PlayerController)
    if not _G.LexusConfig.SkinDeadBox or _G.NeedCheckDeadBoxTimer <= 0 then return end

    local curTime = os.clock()
    if _G.LastCheckDeadBoxTime and (curTime - _G.LastCheckDeadBoxTime) < 2.0 then return end
    _G.LastCheckDeadBoxTime = curTime
    _G.NeedCheckDeadBoxTimer = _G.NeedCheckDeadBoxTimer - 1

    local PlayerCharacter = PlayerController:GetPlayerCharacterSafety()
    if not slua.isValid(PlayerCharacter) then return end

    if not cached_GameplayStatics then
        cached_GameplayStatics = import("GameplayStatics")
        cached_ActorClass = import("Actor")
        cached_PlayerTombBox = import("PlayerTombBox")
    end

    if not _G.CachedActorArray_DB then
        _G.CachedActorArray_DB = slua.Array(UEnums.EPropertyClass.Object, cached_ActorClass)
    end

    local UI_Util = require("client.common.ui_util")
    local GameInstance = UI_Util and UI_Util.GetGameInstance()
    if not GameInstance or not cached_GameplayStatics then return end


    local myPlayerKey = PlayerController.PlayerKey
    local currentBoxSkinId = 0
    pcall(function()
        local curVeh = PlayerCharacter.CurrentVehicle or (type(PlayerCharacter.GetCurrentVehicle) == "function" and PlayerCharacter:GetCurrentVehicle())
        if slua.isValid(curVeh) and _G.CurrentEquipVehicleID and _G.CurrentEquipVehicleID ~= 0 then
            currentBoxSkinId = tonumber(tostring(_G.CurrentEquipVehicleID) .. "1") or 0
        else

            local curWeapon = PlayerCharacter.GetCurrentWeapon and PlayerCharacter:GetCurrentWeapon() or PlayerCharacter.CurrentWeapon
            if slua.isValid(curWeapon) then
                local defineIDObj = curWeapon.GetItemDefineID and curWeapon:GetItemDefineID()
                local curWeaponID = (defineIDObj and slua.isValid(defineIDObj)) and defineIDObj.TypeSpecificID or 0


                if curWeaponID > 0 and _G.AddOutfitLastAppliedSkin and _G.AddOutfitLastAppliedSkin[curWeaponID] then
                    local skinID = _G.AddOutfitLastAppliedSkin[curWeaponID]
                    if skinID and skinID > 1000000 then
                        currentBoxSkinId = skinID
                    end
                end
            end
        end
    end)

    if currentBoxSkinId == 0 then return end

    local deadBoxes = cached_GameplayStatics.GetAllActorsOfClass(GameInstance, cached_PlayerTombBox, _G.CachedActorArray_DB)
    if not deadBoxes then return end

    local count = type(deadBoxes.Num) == "function" and deadBoxes:Num() or #deadBoxes
    for i = 1, count do
        local deadBoxActor = type(deadBoxes.Get) == "function" and deadBoxes:Get(i-1) or deadBoxes[i]
        if slua.isValid(deadBoxActor) and not deadBoxActor.bIsTDSkinApplied then
            local damageCauser = deadBoxActor.DamageCauser

            if slua.isValid(damageCauser) and damageCauser.PlayerKey == myPlayerKey then
                local DeadBoxAvatarComponent = deadBoxActor.DeadBoxAvatarComponent_BP
                if slua.isValid(DeadBoxAvatarComponent) then
                    pcall(function()
                        DeadBoxAvatarComponent:ResetItemAvatar()
                        DeadBoxAvatarComponent:PreChangeItemAvatar(currentBoxSkinId)
                        DeadBoxAvatarComponent:SyncChangeItemAvatar(currentBoxSkinId)
                    end)
                    deadBoxActor.bIsTDSkinApplied = true
                end
            end
        end
    end
end


_G._StartXTHRLENSkinEngine = function()
    if _G._LICENSE_OK ~= true then return false end
    _G._SKIN_ENGINE_ENABLED = true
    if _G._SKIN_ENGINE_BOOTSTRAPPED == true then
        return true
    end
    _G._SKIN_ENGINE_BOOTSTRAPPED = true

    local _ao_ok, _ao_err = pcall(function()

function _G.XTHRLENNotiff(message)
  pcall(function()
    local bLocOk, loc_util = pcall(require, "common.loc_util")
    if bLocOk and loc_util then
      if loc_util.ShowNotice then
        loc_util.ShowNotice("Mode By XTHRLEN: " .. message)
      end
    end
    local bTipsOk, InGameTipsTools = pcall(require, "GameLua.Mod.BaseMod.Common.UI.InGameTipsTools")
    if bTipsOk and InGameTipsTools then
      if InGameTipsTools.BattleNormalTips then
        InGameTipsTools.BattleNormalTips("Moded Pak By XTHRLEN: " .. message, 2, 3)
      end
    end
    local bDataOk, GameplayData = pcall(require, "GameLua.GameCore.Data.GameplayData")
    if bDataOk and GameplayData then
      local PlayerController = GameplayData.GetPlayerController()
      if PlayerController then
        local bLibOk, STExtraBlueprintFunctionLibrary = pcall(import, "STExtraBlueprintFunctionLibrary")
        if bLibOk and STExtraBlueprintFunctionLibrary then
          local ChatComponent = STExtraBlueprintFunctionLibrary.GetChatComponentFromController(PlayerController)
          if ChatComponent then
            if ChatComponent.AddMsgInClient then
              ChatComponent:AddMsgInClient("By XTHRLEN: " .. message .. ".")
            end
          end
        end
      end
    end
  end)
end

local _outfitSavePathCache = nil
local function _getOutfitSavePath()
    if _outfitSavePathCache then return _outfitSavePathCache end
    
    local pid = "default"
    pcall(function()
        local Subsystem = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        local AccountSubsystem = Subsystem:Get("AccountSubsystem")
        if AccountSubsystem and AccountSubsystem.GetAccountUID then
            local uid = AccountSubsystem:GetAccountUID()
            if uid and uid ~= 0 then pid = tostring(uid) end
        end
    end)
    
    local fileName = "AddOutfit_Save_" .. pid .. ".txt"

    local function GetCachePaths(fName)
        local paths = {
            "//storage/emulated/0/Android/data/com.tencent.ig/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fName,
            "//storage/emulated/0/Android/data/com.tencent.igfit/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fName,
            "//storage/emulated/0/Android/data/com.vng.pubgmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fName,
            "//storage/emulated/0/Android/data/com.pubg.krmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fName,
            "//storage/emulated/0/Android/data/com.rekoo.pubgm/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fName,
            "//storage/emulated/0/Android/data/com.pubg.imobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fName,
            "/Documents/ShadowTrackerExtra/Saved/Paks/" .. fName,
            "/Documents/ShadowTrackerExtra/Saved/Paks/puffer_temp/" .. fName,
            "/com.tencent.ig/Documents/ShadowTrackerExtra/Saved/Paks/" .. fName,
            "/com.vng.pubgmobile/Documents/ShadowTrackerExtra/Saved/Paks/" .. fName,
            "/com.pubg.krmobile/Documents/ShadowTrackerExtra/Saved/Paks/" .. fName,
            "/com.rekoo.pubgm/Documents/ShadowTrackerExtra/Saved/Paks/" .. fName,
            "/com.pubg.imobile/Documents/ShadowTrackerExtra/Saved/Paks/" .. fName,
            "ShadowTrackerExtra/Saved/Paks/" .. fName,
            "../../ShadowTrackerExtra/Saved/Paks/" .. fName,
            "../../../ShadowTrackerExtra/Saved/Paks/" .. fName,
            "../../../../ShadowTrackerExtra/Saved/Paks/" .. fName,
            fName
        }
        if os and os.getenv then
            local homeDir = os.getenv("HOME")
            if homeDir and homeDir ~= "" then
                table.insert(paths, 1, homeDir .. "/Documents/ShadowTrackerExtra/Saved/Paks/" .. fName)
                table.insert(paths, 2, homeDir .. "/Documents/ShadowTrackerExtra/Saved/Paks/puffer_temp/" .. fName)
            end
        end
        return paths
    end

    local paths = GetCachePaths(fileName)
    for _, path in ipairs(paths) do
        local cleanPath = path:gsub("^%/%/", "/")
        local file = io.open(cleanPath, "r")
        if file then
            file:close()
            _outfitSavePathCache = cleanPath
            return _outfitSavePathCache
        end
    end

    for _, path in ipairs(paths) do
        local cleanPath = path:gsub("^%/%/", "/")
        local file = io.open(cleanPath, "w")
        if file then
            file:write("") -- Inisialisasi file kosong
            file:close()
            _outfitSavePathCache = cleanPath
            return _outfitSavePathCache
        end
    end
    _outfitSavePathCache = fileName
    return _outfitSavePathCache
end

local function _saveEquippedCache()
    pcall(function()
        local cch = _G.AddOutfitEquippedCache
        if not cch then
            return
        end

        local path = _getOutfitSavePath()
        local lines = {}

        local function addLine(key, value)
            if value ~= nil then
                lines[#lines + 1] = key .. "=" .. tostring(value)
            end
        end

        local function addPositiveLine(key, value)
            value = tonumber(value)
            if value and value > 0 then
                lines[#lines + 1] = key .. "=" .. tostring(value)
            end
        end

        -- [XTHRLEN] Outfit
        addLine("outfitRes", cch.outfitRes)
        addLine("outfitIns", cch.outfitIns)

        -- [XTHRLEN] Clothes
        local clothIds = {}

        for resID in pairs(cch.clothes or {}) do
            clothIds[#clothIds + 1] = tostring(resID)
        end

        if #clothIds > 0 then
            lines[#lines + 1] = "clothes=" .. table.concat(clothIds, ",")
        end

        -- [XTHRLEN] Equipment
        local eq = cch.equip or {}

        local equipKeys = {
            "bag",
            "helmet",
            "armor",
            "parachute",
            "glider",
            "bagIns",
            "helmetIns",
            "armorIns",
            "parachuteIns",
            "gliderIns"
        }

        for _, key in ipairs(equipKeys) do
            addLine("equip_" .. key, eq[key])
        end

        -- [XTHRLEN] Weapons
        for wid, weapon in pairs(cch.weapons or {}) do
            if weapon then
                lines[#lines + 1] =
                    "weapon_" .. tostring(wid)
                    .. "="
                    .. tostring(weapon.resID)
                    .. ":"
                    .. tostring(weapon.insID or 0)
            end
        end

        -- [XTHRLEN] Motion
        pcall(function()
            if DataMgr and DataMgr.MotionSlotList then
                local parts = {}

                for _, ins in ipairs(DataMgr.MotionSlotList) do
                    ins = tonumber(ins)

                    if ins and ins > 0 then
                        parts[#parts + 1] = tostring(ins)
                    end
                end

                if #parts > 0 then
                    lines[#lines + 1] = "motion=" .. table.concat(parts, ",")
                end
            end
        end)

        -- [XTHRLEN] Role Wear
        pcall(function()
            local AvatarData = require("client.logic.data.AvatarData")
            local parts = {}
            for _, ins in pairs(AvatarData.GetRoleWear()) do
                ins = tonumber(ins)
                if ins and ins > 0 then
                    parts[#parts + 1] = tostring(ins)
                end
            end
            if #parts > 0 then
                lines[#lines + 1] = "rolewear=" .. table.concat(parts, ",")
            end
        end)

        -- [XTHRLEN] Equipment Skin
        pcall(function()
            if DataMgr and DataMgr.equipmentSkinInsIDTable then
                for subType, ins in pairs(DataMgr.equipmentSkinInsIDTable) do
                    addPositiveLine("equipins_" .. tostring(subType), ins)
                end
            end
        end)

        -- [XTHRLEN] VST Skin
        pcall(function()
            if DataMgr then
                addPositiveLine("vst_skin", DataMgr.vst_skin)
            end
        end)

        -- [XTHRLEN] Hall Theme
        pcall(function()
            local HT = require("client.logic.lobby.hall_theme_utils")
            local getThemeInstId = HT.GetThemeInstId
            local ins = 0
            if getThemeInstId then
                ins = tonumber(getThemeInstId()) or 0
            end
            if ins > 0 then
                lines[#lines + 1] = "hall_theme_ins=" .. tostring(ins)
                local res = tonumber(HT.homeThemeItemId) or 0
                if res <= 0
                    and _G.AddOutfit_R
                    and _G.AddOutfit_R.insToRes
                then
                    res = tonumber(_G.AddOutfit_R.insToRes[ins]) or 0
                end
                if res > 0 then
                    lines[#lines + 1] =
                        "hall_theme_res=" .. tostring(res)
                end
            end
        end)

        -- [XTHRLEN] Vehicle
        pcall(function()
            if DataMgr and DataMgr.VehicleSlotList then
                for subType, insList in pairs(DataMgr.VehicleSlotList) do
                    if type(insList) == "table" then
                        local parts = {}
                        for _, ins in ipairs(insList) do
                            ins = tonumber(ins)
                            if ins and ins > 0 then
                                parts[#parts + 1] = tostring(ins)
                            end
                        end
                        if #parts > 0 then
                            lines[#lines + 1] =
                                "vehicle_"
                                .. tostring(subType)
                                .. "="
                                .. table.concat(parts, ",")
                        end
                    end
                end
            end
        end)

        -- [XTHRLEN] Garage Theme
        pcall(function()
            local GTS
            if ModuleManager and ModuleManager.GetModule then
                GTS = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.GarageThemeSystem)
            end
            if GTS and GTS.GarageVehicleInfo then
                for slot, info in pairs(GTS.GarageVehicleInfo) do
                    if info and info.inst_id then
                        lines[#lines + 1] =
                            "garage_"
                            .. tostring(slot)
                            .. "="
                            .. tostring(info.inst_id)
                            .. ":"
                            .. tostring(info.res_id or 0)
                    end
                end
            end
        end)

        -- [XTHRLEN] Throw Objects
        pcall(function()
            local throwObjects = cch.throwObjects
            if throwObjects then
                for st, info in pairs(throwObjects) do
                    if info and info.resID then
                        local resID = tonumber(info.resID)
                        if resID and resID > 0 then
                            lines[#lines + 1] =
                                "throw_"
                                .. tostring(st)
                                .. "="
                                .. tostring(resID)
                                .. ":"
                                .. tostring(info.insID or 0)
                        end
                    end
                end
            end
        end)

        -- [XTHRLEN] Save
        local file = io.open(path, "w+")
        if not file then
            return
        end
        file:write(table.concat(lines, "\n"))
        file:close()
    end)
end

local function _loadEquippedCache()
    pcall(function()
        local path = _getOutfitSavePath()
        local file = io.open(path, "r")
        if not file then return end

        local content = file:read("*a")
        file:close()

        if not content or content == "" then return end

        -- [XTHRLEN] Reset saved data
        _G._savedOutfitClothes   = {}
        _G._savedOutfitRes       = nil
        _G._savedOutfitIns       = nil
        _G._savedOutfitEquip     = {}
        _G._savedVehicleSlotList = {}
        _G._savedGarageVehicles  = {}
        _G._savedMotionList      = {}
        _G._savedRoleWearList    = {}
        _G._savedEquipIns        = {}
        _G._savedVstSkin         = nil
        _G._savedHallThemeIns    = nil
        _G._savedHallThemeRes    = nil
        _G._savedThrowObjects    = {}

        local savedEquip = _G._savedOutfitEquip
        -- [XTHRLEN] Equipment key mapping
        local equipMap = {
            equip_bag          = "bag",
            equip_helmet       = "helmet",
            equip_armor        = "armor",
            equip_parachute    = "parachute",
            equip_glider       = "glider",
            equip_bagIns       = "bagIns",
            equip_helmetIns    = "helmetIns",
            equip_armorIns     = "armorIns",
            equip_parachuteIns = "parachuteIns",
            equip_gliderIns    = "gliderIns",
        }

        -- [XTHRLEN] Parse comma-separated positive IDs
        local function parseIdList(value, target)
            for id in value:gmatch("([^,]+)") do
                id = tonumber(id)
                if id and id > 0 then
                    target[#target + 1] = id
                end
            end
        end
        -- [XTHRLEN] Parse resID:insID
        local function parsePair(value)
            local a, b = value:match("^(.-):(.+)$")
            if not a then
                return nil, nil
            end
            return tonumber(a), tonumber(b) or 0
        end
        -- [XTHRLEN] Parse file
        for line in content:gmatch("[^\r\n]+") do
            local key, val = line:match("^(.-)=(.+)$")
            if key and val then
                -- [XTHRLEN] Outfit
                if key == "outfitRes" then
                    _G._savedOutfitRes = tonumber(val)
                elseif key == "outfitIns" then
                    _G._savedOutfitIns = tonumber(val)
                -- [XTHRLEN] Clothes
                elseif key == "clothes" then
                    for id in val:gmatch("([^,]+)") do
                        id = tonumber(id)
                        if id and id > 0 then
                            _G._savedOutfitClothes[id] = true
                        end
                    end
                -- [XTHRLEN] Equipment
                elseif equipMap[key] then
                    savedEquip[equipMap[key]] = tonumber(val)
                -- [XTHRLEN] Motion
                elseif key == "motion" then
                    parseIdList(val, _G._savedMotionList)
                -- [XTHRLEN] Role Wear
                elseif key == "rolewear" then
                    parseIdList(val, _G._savedRoleWearList)
                -- [XTHRLEN] Equipment Skin
                else
                    local subType = key:match("^equipins_(%d+)$")
                    if subType then
                        subType = tonumber(subType)
                        local ins = tonumber(val)
                        if subType and ins then
                            _G._savedEquipIns[subType] = ins
                        end
                    -- [XTHRLEN] VST Skin
                    elseif key == "vst_skin" then
                        _G._savedVstSkin = tonumber(val)
                    -- [XTHRLEN] Hall Theme
                    elseif key == "hall_theme_ins" then
                        _G._savedHallThemeIns = tonumber(val)
                    elseif key == "hall_theme_res" then
                        _G._savedHallThemeRes = tonumber(val)
                    -- [XTHRLEN] Weapon
                    else
                        local wid = key:match("^weapon_(%d+)$")
                        if wid then
                            wid = tonumber(wid)
                            local resID, insID = parsePair(val)
                            if wid and resID then
                                savedEquip["weapon_" .. wid] = {
                                    resID = resID,
                                    insID = insID,
                                }
                            end
                        -- [XTHRLEN] Vehicle
                        else
                            subType = key:match("^vehicle_(%d+)$")
                            if subType then
                                subType = tonumber(subType)
                                local list = {}
                                parseIdList(val, list)
                                if subType and #list > 0 then
                                    _G._savedVehicleSlotList[subType] = list
                                end
                            -- [XTHRLEN] Garage
                            else
                                local slot = key:match("^garage_(%d+)$")
                                if slot then
                                    slot = tonumber(slot)
                                    local insID, resID = parsePair(val)
                                    if slot and insID then
                                        _G._savedGarageVehicles[slot] = {
                                            inst_id = insID,
                                            res_id = resID or 0,
                                        }
                                    end
                                -- [XTHRLEN] Throw Objects
                                else
                                    local st = key:match("^throw_(%d+)$")
                                    if st then
                                        st = tonumber(st)
                                        local resID, insID = parsePair(val)
                                        if st and resID then
                                            _G._savedThrowObjects[st] = {
                                                resID = resID,
                                                insID = insID,
                                            }
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        -- [XTHRLEN] Create cache if missing
        if not _G.AddOutfitEquippedCache then
            _G.AddOutfitEquippedCache = {
                outfitRes = nil,
                outfitIns = nil,
                clothes  = {},
                equip    = {},
                weapons  = {},
            }
        end

        local cch = _G.AddOutfitEquippedCache
        cch.clothes = cch.clothes or {}
        cch.equip   = cch.equip or {}
        cch.weapons = cch.weapons or {}
        -- [XTHRLEN] Outfit
        if _G._savedOutfitRes then
            cch.outfitRes = _G._savedOutfitRes
            cch.outfitIns = _G._savedOutfitIns
        end
        -- [XTHRLEN] Clothes
        if not _G._addOutfitPersistLoaded
            and _G._savedOutfitClothes
        then
            for resID in pairs(_G._savedOutfitClothes) do
                cch.clothes[resID] = true
            end
        end
        -- [XTHRLEN] Equipment + Weapons
        for key, value in pairs(savedEquip) do
            local weaponId = key:match("^weapon_(%d+)$")
            if weaponId then
                weaponId = tonumber(weaponId)
                if weaponId then
                    cch.weapons[weaponId] = value
                end
            else
                cch.equip[key] = value
            end
        end
        -- [XTHRLEN] Throw Objects
        if _G._savedThrowObjects then
            cch.throwObjects = cch.throwObjects or {}
            for st, info in pairs(_G._savedThrowObjects) do
                if info and info.resID and info.resID > 0 then
                    cch.throwObjects[st] = info
                end
            end
        end
        _G._addOutfitPersistLoaded = true
        _lastSnapshot = _snapshotCache()
    end)
end

local function _snapshotCache()
    local cch = _G.AddOutfitEquippedCache
    if not cch then
        return ""
    end
    local parts = {}
    local function add(value)
        parts[#parts + 1] = tostring(value or 0)
    end
    -- [XTHRLEN] Outfit
    add(cch.outfitRes)
    -- [XTHRLEN] Clothes
    local clothIds = {}
    for resID in pairs(cch.clothes or {}) do
        clothIds[#clothIds + 1] = resID
    end
    table.sort(clothIds)
    parts[#parts + 1] = table.concat(clothIds, ",")
    -- [XTHRLEN] Equipment
    local eq = cch.equip or {}
    add(eq.bag)
    add(eq.helmet)
    add(eq.armor)
    add(eq.parachute)
    add(eq.glider)
    -- [XTHRLEN] Weapons
    local weaponIds = {}
    for wid in pairs(cch.weapons or {}) do
        weaponIds[#weaponIds + 1] = wid
    end
    table.sort(weaponIds)
    for _, wid in ipairs(weaponIds) do
        local weapon = cch.weapons[wid]
        if weapon then
            parts[#parts + 1] =
                tostring(wid)
                .. ":"
                .. tostring(weapon.resID or 0)
        end
    end
    -- [XTHRLEN] Throw Objects
    local throwObjects = cch.throwObjects
    if throwObjects then
        local throwIds = {}
        for st in pairs(throwObjects) do
            throwIds[#throwIds + 1] = st
        end
        table.sort(throwIds)
        for _, st in ipairs(throwIds) do
            local info = throwObjects[st]
            if info then
                parts[#parts + 1] =
                    "throw_"
                    .. tostring(st)
                    .. ":"
                    .. tostring(info.resID or 0)
            end
        end
    end
    return table.concat(parts, "|")
end

local _lastSnapshot   = ""
local _saveDirty      = false
local _saveInProgress = false
local _lastSaveClock  = 0

local SAVE_MIN_INTERVAL = 2.5


local function _flushSave(force)
    -- [XTHRLEN] Prevent overlapping save operations
    if _saveInProgress then
        _saveDirty = true
        return
    end
    -- [XTHRLEN] Get current clock safely
    local now = 0
    pcall(function() now = os.clock() end)
    -- [XTHRLEN] Respect minimum save interval
    if not force
        and _lastSaveClock > 0
        and (now - _lastSaveClock) < SAVE_MIN_INTERVAL
    then
        _saveDirty = true
        return
    end

    _saveInProgress = true
    _saveDirty = false

    pcall(function()
        -- [XTHRLEN] Sync cache before saving
        if _G.AddOutfitSyncCacheBeforeSave then
            _G.AddOutfitSyncCacheBeforeSave()
        end
        -- [XTHRLEN] Update snapshot
        _lastSnapshot = _snapshotCache()
        -- [XTHRLEN] Save to file
        pcall(_saveEquippedCache)
        -- [XTHRLEN] Update saved globals
        local cch = _G.AddOutfitEquippedCache
        if cch then
            local outfitRes = tonumber(cch.outfitRes)
            local outfitIns = tonumber(cch.outfitIns)

            _G._savedOutfitRes = outfitRes and outfitRes > 0 and outfitRes or nil
            _G._savedOutfitIns = outfitIns and outfitIns > 0 and outfitIns or nil
            _G._savedOutfitClothes = {}

            for resID in pairs(cch.clothes or {}) do
                _G._savedOutfitClothes[resID] = true
            end
        end
    end)
    -- [XTHRLEN] Update save timestamp
    pcall(function() _lastSaveClock = os.clock() end)
    _saveInProgress = false
end

local _saveDeferred = false

local function _AutoSaveOutfit(force)
    -- [XTHRLEN] Immediate save
    if force then _flushSave(true) return end

    _saveDirty = true
    -- [XTHRLEN] Already scheduled
    if _saveDeferred then return end

    _saveDeferred = true
    local function doDeferredFlush()
        _saveDeferred = false
        if _saveDirty then
            _flushSave(false)
        end
    end
    -- [XTHRLEN] Delay save slightly to group rapid changes
    local ok = pcall(_G.SetTimer, 0.5, doDeferredFlush)
    if not ok then
        doDeferredFlush()
    end
end


_G.AddOutfitTryFlushSave = function()
    if _saveDirty then
        _flushSave(false)
    end
end

-- [XTHRLEN] WardrobeNewHandler
pcall(function()
    local WardrobeNewHandler = {}
    local _bShowNotice = false
    local _ao_R
    local function getR()
        if _ao_R then
            return _ao_R
        end
        _ao_R = _G.AddOutfit_R
        return _ao_R
    end

    local function aoIsInjectedIns(ins)
        ins = tonumber(ins)
        if not ins then
            return false
        end
        local R = getR()
        return R
            and R.insToRes
            and R.insToRes[ins] ~= nil
            or false
    end
    function WardrobeNewHandler.send_depot_modify_combat_vehicle_req(insID, slotIndex, bShowNotice)
        insID = tonumber(insID)
        slotIndex = tonumber(slotIndex) or 1
        _bShowNotice = bShowNotice
        -- [XTHRLEN] Injected vehicle
        if aoIsInjectedIns(insID) then
            local R = getR()
            local resID = R and R.insToRes[insID]
            local itemSubType = 0
            if resID and CDataTable and CDataTable.GetTableData then
                local data = CDataTable.GetTableData("Item", resID)
                itemSubType = data and tonumber(data.ItemSubType or data.itemSubType) or 0
            end
            if itemSubType > 0 and DataMgr then
                DataMgr.VehicleSlotList = DataMgr.VehicleSlotList or {}
                local slotList = DataMgr.VehicleSlotList[itemSubType] or {}
                if bShowNotice then
                    -- [XTHRLEN] Remove duplicate instance
                    for i = #slotList, 1, -1 do
                        if slotList[i] == insID then
                            table.remove(slotList, i)
                        end
                    end
                    slotList[slotIndex] = insID
                else
                    -- [XTHRLEN] Remove instance
                    for i, sid in ipairs(slotList) do
                        if sid == insID then
                            table.remove(slotList, i)
                            break
                        end
                    end
                end
                DataMgr.VehicleSlotList[itemSubType] =
                    slotList
            end
            -- [XTHRLEN] Refresh surveillance tab
            pcall(function()
                local tabSurveillance = require("client.slua.logic.wardrobe.tab_surveillance")
                if tabSurveillance
                    and tabSurveillance.VehicleChange
                then
                    tabSurveillance.VehicleChange()
                end
            end)
            -- [XTHRLEN] Wardrobe event
            if EventSystem
                and EVENTTYPE_WARDROBE
                and EVENTID_WARDROBE_VEHICLE_SLOT_DATA_CHANGE
            then
                EventSystem:postEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_VEHICLE_SLOT_DATA_CHANGE)
            end
            -- [XTHRLEN] Save
            pcall(_AutoSaveOutfit)
            return
        end
        -- [XTHRLEN] Normal vehicle request
        local NetManager = require("client.network.comm.NetManager")
        NetManager.SendPkg(1012780591, insID, slotIndex, bShowNotice)
    end

    function WardrobeNewHandler.on_depot_modify_combat_vehicle_rsp(ret_code, vehicle_info)
        if ret_code ~= 0
            and ret_code ~= NetErrorCode_NONE
        then
            if _bShowNotice and ShowNotice then
                ShowNotice(ret_code)
            end
            return
        end

        if vehicle_info and DataMgr then
            DataMgr.VehicleSlotList = vehicle_info
        end

        pcall(function()
            local tabSurveillance = require("client.slua.logic.wardrobe.tab_surveillance")
            if tabSurveillance
                and tabSurveillance.VehicleChange
            then
                tabSurveillance.VehicleChange()
            end
        end)

        if EventSystem
            and EVENTTYPE_WARDROBE
            and EVENTID_WARDROBE_VEHICLE_SLOT_DATA_CHANGE
        then
            EventSystem:postEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_VEHICLE_SLOT_DATA_CHANGE)
        end
    end

    function WardrobeNewHandler.send_select_item(insID)
        local NetManager = require("client.network.comm.NetManager")
        NetManager.SendPkg(595484784, insID)
    end

    function WardrobeNewHandler.send_equip_motion_list_req(motion_list)
        local NetManager = require("client.network.comm.NetManager")
        NetManager.SendPkg(1124239581, motion_list)
    end

    package.loaded["client.network.Protocol.WardrobeNewHandler"] = WardrobeNewHandler
end)

local _ao_ok, _ao_err = pcall(function()
    -- [XTHRLEN] Per-match guard
    do
        local curMatchID = ""

        pcall(function()
            local GD = require("GameLua.GameCore.Data.GameplayData")
            if GD and GD.GetPlayerController then
                local pc = GD.GetPlayerController()
                if pc and slua.isValid(pc) then
                    curMatchID =
                        tostring(pc.PlayerKey or "")
                        .. "_"
                        .. tostring(pc)
                end
            end
        end)

        if curMatchID == "" then
            _G._AO_MATCH_ID = nil
        elseif _G._AO_MATCH_ID == curMatchID then
            return
        else
            _G._AO_MATCH_ID = curMatchID
        end
    end

    local game_frontend_hud = require("game_frontend_hud")

    local DEBUGG = false
    
    local function isInMatchOrGame()
        local ok, result = pcall(function()
            if GameStatus
                and GameStatus.IsInFightingStatus
                and GameStatus.IsInFightingStatus()
            then
                return true
            end

            if GameStatus
                and GameStatus.IsInLobbyOrMainCity
                and not GameStatus.IsInLobbyOrMainCity()
            then
                return true
            end
            return false
        end)
        return ok and result == true
    end
    
    local function log(...)
        print("[XTHRLEN]", ...)
    end

    local MATCH_CONFIG = {
        outfitRes = 0,
        weaponSkins = {},
        equip = { bag = 0, helmet = 0, armor = 0 },
    }

    local ITEMS = {}
    local _itemsLoaded = false

    local function buildNonMaxLevelSet()
    local nonMax = {}
    if not (CDataTable and CDataTable.GetTable) then return nonMax end
    pcall(function()
        local upTbl = CDataTable.GetTable("ItemUpgradeConfig")
        if not upTbl then return end
        local maxLvl, maxItem = {}, {}
        local groupMembers = {}
        for _, cfg in pairs(upTbl) do
            local gid   = tonumber(cfg.GroupID)
            local lvl   = tonumber(cfg.Level)
            local itm   = tonumber(cfg.ItemID)
            if gid and lvl and itm then
                if not groupMembers[gid] then groupMembers[gid] = {} end
                groupMembers[gid][#groupMembers[gid] + 1] = itm
                if not maxLvl[gid] or lvl > maxLvl[gid] then
                    maxLvl[gid] = lvl
                    maxItem[gid] = itm
                end
            end
        end
        for gid, members in pairs(groupMembers) do
            local topItem = maxItem[gid]
            for _, itm in ipairs(members) do
                if itm ~= topItem then nonMax[itm] = true end
            end
        end
    end)
    
    local function processXSuitTable(tableName)
        pcall(function()
            local tbl = CDataTable.GetTable(tableName)
            if not tbl then return end
            local maxStar, maxItem = {}, {}
            local periodMembers = {}
            for _, data in pairs(tbl) do
                local period = tonumber(data.Period or data.period)
                local star   = tonumber(data.Star or data.star or data.Level or data.level)
                local itm    = tonumber(data.ItemID or data.itemID or data.ItemId)
                if period and star and itm then
                    if not periodMembers[period] then periodMembers[period] = {} end
                    periodMembers[period][#periodMembers[period] + 1] = itm
                    if not maxStar[period] or star > maxStar[period] then
                        maxStar[period] = star
                        maxItem[period] = itm
                    end
                end
            end
            for period, members in pairs(periodMembers) do
                local topItem = maxItem[period]
                for _, itm in ipairs(members) do
                    if itm ~= topItem then nonMax[itm] = true end
                end
            end
        end)
    end
    
    processXSuitTable("GoldenSuitUpgradeCfg")
    processXSuitTable("GoldenSuitUpgradeCfgKJ")
    processXSuitTable("GoldenSuitUpgradeCfgIN")

    pcall(function()
        local bpMap = CDataTable.GetTable("BackpackMapping")
        if not bpMap then return end
        for _, m in pairs(bpMap) do
            local lv3 = tonumber(m.SkinItemIDLv3 or 0) or 0
            local lv1 = tonumber(m.SkinItemIDLv1 or 0) or 0
            local lv2 = tonumber(m.SkinItemIDLv2 or 0) or 0
            if lv1 > 0 and lv1 ~= lv3 then nonMax[lv1] = true end
            if lv2 > 0 and lv2 ~= lv3 then nonMax[lv2] = true end
        end
    end)
    return nonMax
end

local function refreshItems()
    if _itemsLoaded then return #ITEMS end
    if #ITEMS > 0 then return #ITEMS end
    local ItemTable = CDataTable and CDataTable.GetTable and CDataTable.GetTable("Item")
    if not ItemTable then return 0 end
    local nonMax = buildNonMaxLevelSet()
    local seen, count, skipped = {}, 0, 0
    for id, v in pairs(ItemTable) do
        local rid = tonumber(v.ID or v.Id or id)
        if rid and rid > 0 and not seen[rid] then
            local bpId = tonumber(v.BPID or v.bpID or v.BpId or 0) or 0
            local mainTab = tonumber(v.WardrobeMainTab or v.wardrobeMainTab or 0) or 0
            if bpId ~= 0 or mainTab ~= 0 then
                seen[rid] = true
                if nonMax[rid] then
                    skipped = skipped + 1
                else
                    ITEMS[#ITEMS + 1] = rid
                    count = count + 1
                end
            end
        end
    end
    table.sort(ITEMS)
    if count > 0 then
        _itemsLoaded = true
    end
    return count
end

local _K = {
    INS_BASE = 2000000000, PKG_SLOT = 3, MELEE_ID = 108,
    GUN_SUB = { [101]=true, [102]=true, [103]=true, [104]=true, [105]=true, [106]=true, [107]=true },
    NET_OK = NetErrorCode_NONE or "ok",
    GUN_MASTER_SYN_SLOT = 7,
    THROW_SUB = { [612] = "shoulei", [613] = "smoke", [614] = "stun", [615] = "burn" },
    THROW_AVATAR_KEY = { shoulei = "GrenadeAvatarShoulei", smoke = "GrenadeAvatarSmoke", stun = "GrenadeAvatarStun", burn = "GrenadeAvatarBurn" },
}

local R = { insToRes = {}, resToIns = {} }
local _injectedResSet = {}
for _, rid in ipairs(ITEMS) do _injectedResSet[rid] = true end

local _C = { cfg = {}, fullSuit = {}, equipSlot = {}, weaponId = {}, itemTab = {}, vehicleItems = {}, pageMatch = {} }

local _S = {
    matchApplied = false, matchTimer = nil, matchOutfitDone = false,
    avatarItemsRegistered = false, weaponApplied = false, weaponDiagDone = false,
    lastWeaponResID = 0, weaponSpawnHooked = false, bootstrapNotified = false,
    globalFrame = 0, weaponHookGuardUntil = 0, equipSkinApplying = false,
    injectedDone = false, lastAppliedWeaponID = 0, lastAppliedSkinID = 0,
    bootstrapped = false, lobbyApplied = false,
}

_G.AddOutfitSkinIdMappings = _G.AddOutfitSkinIdMappings or {}
_G.AddOutfitLastAppliedSkin = _G.AddOutfitLastAppliedSkin or {}
_G.AddOutfitLastLobbyOutfitRes = _G.AddOutfitLastLobbyOutfitRes or nil

_K.ST_TOP     = (ENUM_ITEM_SUBTYPE and ENUM_ITEM_SUBTYPE.Package_Slot) or 403
_K.ST_PANTS   = (ENUM_ITEM_SUBTYPE and ENUM_ITEM_SUBTYPE.Pants_Slot) or 404
_K.ST_SHOES   = (ENUM_ITEM_SUBTYPE and ENUM_ITEM_SUBTYPE.Shoes_Slot) or 405
_K.ST_UNDER_T = (ENUM_ITEM_SUBTYPE and ENUM_ITEM_SUBTYPE.UnderCloth) or 450
_K.ST_UNDER_P = (ENUM_ITEM_SUBTYPE and ENUM_ITEM_SUBTYPE.UnderPants) or 451
_K.WARDROBE_TAB_SUIT, _K.WARDROBE_TAB_CLOTHES = 10, 3
_K.WARDROBE_TAB_TROUSERS, _K.WARDROBE_TAB_SHOES = 4, 5
_K.WARDROBE_TAB_BAG, _K.WARDROBE_TAB_HELMET, _K.WARDROBE_TAB_ARMOR = 15, 16, 17
_K.WARDROBE_TAB_GUN, _K.WARDROBE_TAB_PARACHUTE = 9, 7
_K.WARDROBE_TAB_GLIDER = 20
_K.WARDROBE_PAGE_AVATAR, _K.WARDROBE_PAGE_WEAPON, _K.WARDROBE_PAGE_PARACHUTE, _K.WARDROBE_PAGE_VEHICLE = 1, 4, 5, 6
pcall(function()
    local wm = require("client.slua.umg.Wardrobe.wardrobe_macro")
    local t = wm.ENUM_WardrobeSubTabString
    _K.WARDROBE_TAB_SUIT = t.ENUM_WardrobeSubTabString_suit
    _K.WARDROBE_TAB_CLOTHES = t.ENUM_WardrobeSubTabString_clothes
    _K.WARDROBE_TAB_TROUSERS = t.ENUM_WardrobeSubTabString_trousers
    _K.WARDROBE_TAB_SHOES = t.ENUM_WardrobeSubTabString_shoes
    _K.WARDROBE_TAB_BAG = t.ENUM_WardrobeSubTabString_bag
    _K.WARDROBE_TAB_HELMET = t.ENUM_WardrobeSubTabString_helmet
    _K.WARDROBE_TAB_ARMOR = t.ENUM_WardrobeSubTabString_armor
    _K.WARDROBE_TAB_GUN = t.ENUM_WardrobeSubTabString_gun
    _K.WARDROBE_TAB_PARACHUTE = t.ENUM_WardrobeSubTabString_parachute
    _K.WARDROBE_TAB_GLIDER = t.ENUM_WardrobeSubTabString_effect
    _K.WARDROBE_PAGE_AVATAR = wm.ENUM_WardrobePageTypeId.ENUM_WardrobePageType_Avatar
    _K.WARDROBE_PAGE_WEAPON = wm.ENUM_WardrobePageTypeId.ENUM_WardrobePageType_Weapon
    _K.WARDROBE_PAGE_PARACHUTE = wm.ENUM_WardrobePageTypeId.ENUM_WardrobePageType_Parachute
    _K.WARDROBE_PAGE_VEHICLE = wm.ENUM_WardrobePageTypeId.ENUM_WardrobePageType_Vehicle
end)

local FULL_SUIT_CLEAR_ST = {
    [_K.ST_TOP] = true, [_K.ST_PANTS] = true, [_K.ST_SHOES] = true,
    [_K.ST_UNDER_T] = true, [_K.ST_UNDER_P] = true,
}

local function cache()
    _G.AddOutfitEquippedCache = _G.AddOutfitEquippedCache or {
        outfitRes = nil, outfitIns = nil,
        clothes = {},
        equip = {},
        weapons = {},
    }
    return _G.AddOutfitEquippedCache
end

local function cfg(resID)
    if not resID or not CDataTable or not CDataTable.GetTableData then return nil end
    resID = tonumber(resID)
    if not resID then return nil end
    if _C.cfg[resID] ~= nil then return _C.cfg[resID] end
    local c = CDataTable.GetTableData("Item", resID)
    _C.cfg[resID] = c
    return c
end

local function subType(c)
    return c and (c.ItemSubType or c.itemSubType) or nil
end

local function isThrowObjectRes(resID)
    resID = tonumber(resID)
    if not resID then return nil end
    local c = cfg(resID)
    if not c then return nil end
    local st = tonumber(c.ItemSubType or c.itemSubType or 0)
    if _K.THROW_SUB[st] then return st end
    return nil
end

local function saveThrowObject(resID, insID)
    resID, insID = tonumber(resID), tonumber(insID)
    if not resID then return end
    local st = isThrowObjectRes(resID)
    if not st then return end
    local cch = cache()
    cch.throwObjects = cch.throwObjects or {}
    cch.throwObjects[st] = { resID = resID, insID = insID or R.resToIns[resID] or 0 }
end

local function isInjectedIns(ins)
    return ins and R.insToRes[tonumber(ins)] ~= nil
end

local function isInjectedRes(res)
    return res and (R.resToIns[tonumber(res)] ~= nil or _injectedResSet[tonumber(res)])
end

local function weaponIdFromSkin(resID)
    resID = tonumber(resID)
    if not resID then return nil end
    if _C.weaponId[resID] ~= nil then return _C.weaponId[resID] end
    local m = CDataTable and CDataTable.GetTableData and CDataTable.GetTableData("WeaponSkinMapping", resID)
    local wid = m and (m.WeaponID or m.WeaponId) or nil
    _C.weaponId[resID] = wid
    return wid
end

local function isHallThemeRes(resID)
    resID = tonumber(resID)
    if not resID then return false end
    local c = cfg(resID)
    if not c then return false end
    local it = tonumber(c.ItemType or c.itemType or 0)
    if ENUM_ITEM_TYPE and ENUM_ITEM_TYPE.Hall_Theme then
        return it == ENUM_ITEM_TYPE.Hall_Theme
    end
    return it == 202
end

local function getEquipSkinSlot(resID)
    resID = tonumber(resID)
    if not resID then return nil end
    if _C.equipSlot[resID] ~= nil then return _C.equipSlot[resID] end
    local slot = nil
    local itemCfg = cfg(resID)
    if itemCfg then
        local st = tonumber(itemCfg.ItemSubType or itemCfg.itemSubType or 0)
        local it = tonumber(itemCfg.ItemType or itemCfg.itemType or 0)
        if st == 501 or st == 504 then slot = "bag"
        elseif st == 502 or st == 505 then slot = "helmet"
        elseif st == 503 or st == 506 then slot = "armor"
        elseif it == 4 and st == 701 then slot = "parachute"
        elseif it == 4 and (st == 413 or st == 414 or st == 415) then slot = "glider" end
    end
    if not slot then
        if resID >= 1502000000 and resID < 1503000000 then slot = "helmet"
        elseif resID >= 1505000000 and resID < 1506000000 then slot = "helmet"
        elseif resID >= 1501000000 and resID < 1502000000 then slot = "bag"
        elseif resID >= 1504000000 and resID < 1505000000 then slot = "bag" end
    end
    _C.equipSlot[resID] = slot
    return slot
end

local function wardrobeTab(resID, depotData)
    if depotData and depotData.subTabType then return tonumber(depotData.subTabType) end
    local c = cfg(resID)
    return c and tonumber(c.WardrobeTab or c.wardrobeTab) or nil
end

local function wardrobeMainTab(resID, depotData)
    if depotData and depotData.mainTabType then return tonumber(depotData.mainTabType) end
    local c = cfg(resID)
    return c and tonumber(c.WardrobeMainTab or c.wardrobeMainTab) or _K.WARDROBE_PAGE_AVATAR
end

local function getInjectedItemTab(resID, depotData)
    resID = tonumber(resID)
    if not resID then return nil, nil end
    if _C.itemTab[resID] then
        return _C.itemTab[resID][1], _C.itemTab[resID][2]
    end
    local c = cfg(resID)
    local st = c and tonumber(c.ItemSubType or c.itemSubType) or 0

    local equipSlot = getEquipSkinSlot(resID)
    local result
    if equipSlot == "bag" then result = {_K.WARDROBE_PAGE_AVATAR, _K.WARDROBE_TAB_BAG}
    elseif equipSlot == "helmet" then result = {_K.WARDROBE_PAGE_AVATAR, _K.WARDROBE_TAB_HELMET}
    elseif equipSlot == "armor" then result = {_K.WARDROBE_PAGE_AVATAR, _K.WARDROBE_TAB_ARMOR}
    elseif equipSlot == "parachute" then result = {_K.WARDROBE_PAGE_PARACHUTE, _K.WARDROBE_TAB_PARACHUTE}
     elseif equipSlot == "glider" then result = {_K.WARDROBE_PAGE_PARACHUTE, _K.WARDROBE_TAB_GLIDER}
     elseif weaponIdFromSkin(resID) then result = {_K.WARDROBE_PAGE_WEAPON, _K.WARDROBE_TAB_GUN}
     else
        local mainTab = wardrobeMainTab(resID, depotData)
        local subTab = wardrobeTab(resID, depotData)
        if subTab and subTab > 0 then result = {mainTab, subTab}
        elseif st == _K.ST_PANTS then result = {_K.WARDROBE_PAGE_AVATAR, _K.WARDROBE_TAB_TROUSERS}
        elseif st == _K.ST_SHOES then result = {_K.WARDROBE_PAGE_AVATAR, _K.WARDROBE_TAB_SHOES}
        elseif st == _K.ST_TOP then
            if isFullSuitRes(resID, depotData) then result = {_K.WARDROBE_PAGE_AVATAR, _K.WARDROBE_TAB_SUIT}
        else result = {_K.WARDROBE_PAGE_AVATAR, _K.WARDROBE_TAB_CLOTHES} end
        elseif st == 400 or st == 408 or st == 409 or st == 410 then
            result = {_K.WARDROBE_PAGE_PARACHUTE, _K.WARDROBE_TAB_PARACHUTE}
        else
            result = {mainTab, subTab or 0}
        end
     end
    _C.itemTab[resID] = result
    return result[1], result[2]
end

local function injectedMatchesPage(resID, depotData, mainTab, subTab)
    local itemMain, itemSub = getInjectedItemTab(resID, depotData)
    if itemMain ~= mainTab or itemSub ~= subTab then return false end
    if subTab == _K.WARDROBE_TAB_SUIT or subTab == _K.WARDROBE_TAB_CLOTHES then
        local st = depotData and depotData.itemSubType or subType(cfg(resID))
        if st == _K.ST_TOP then
            local full = isFullSuitRes(resID, depotData)
            if subTab == _K.WARDROBE_TAB_SUIT then return full end
            if subTab == _K.WARDROBE_TAB_CLOTHES then return not full end
        end
    end
    return true
end

local function isFullSuitRes(resID, depotData)
    resID = tonumber(resID)
    if not resID or resID <= 0 then return false end
    if _C.fullSuit[resID] ~= nil then return _C.fullSuit[resID] end
    local result = false
    pcall(function()
        local LogicXSuit = require("client.slua.logic.XSuit.logic_xsuit")
        if LogicXSuit.IsXSuit(resID) then result = true end
    end)
    if not result then
        local tab = wardrobeTab(resID, depotData)
        if tab == _K.WARDROBE_TAB_SUIT then result = true end
    end
    _C.fullSuit[resID] = result
    return result
end

local function getClothKind(resID, depotData)
    resID = tonumber(resID)
    if not resID then return nil end
    local st = subType(cfg(resID))
    if st == _K.ST_TOP then
        return isFullSuitRes(resID, depotData) and "full_suit" or "top"
    end
    if st == _K.ST_PANTS then return "pants" end
    if st == _K.ST_SHOES then return "shoes" end
    if st == _K.ST_UNDER_T then return "under_top" end
    if st == _K.ST_UNDER_P then return "under_pants" end
    return nil
end

local function subTypesToClearForKind(kind)
    if kind == "full_suit" then return FULL_SUIT_CLEAR_ST end
    if kind == "top" then return { [_K.ST_TOP] = true } end
    if kind == "pants" then return { [_K.ST_PANTS] = true } end
    if kind == "shoes" then return { [_K.ST_SHOES] = true } end
    if kind == "under_top" then return { [_K.ST_UNDER_T] = true } end
    if kind == "under_pants" then return { [_K.ST_UNDER_P] = true } end
    return nil
end

local function isBodyClothSubType(st)
    st = tonumber(st)
    return st == _K.ST_TOP or st == _K.ST_PANTS or st == _K.ST_SHOES or st == _K.ST_UNDER_T or st == _K.ST_UNDER_P
end

local _outfitMergeCache = { key = nil, items = nil }
local _weaponSkinResMergeCache = { key = nil, res = nil }
local _convertCache = {}

local function getConvertedAvatarCustom(resID)
    resID = tonumber(resID)
    if not resID then return nil end
    if _convertCache[resID] ~= nil then return _convertCache[resID] end
    local AvatarData = require("client.logic.data.AvatarData")
    local converted = AvatarData.ConvertToAvatarCustom({ resID, 0, 0 })
    _convertCache[resID] = converted
    return converted
end

local function invalidateSocialWearCache()
    local s = _G.AddOutfitSocialState
    if s then
        s.wearPatchKey, s.snapshotKey, s.fullSnapshot, s.lastHandSkin = nil, nil, nil, nil
    end
    _outfitMergeCache.key = nil
    _outfitMergeCache.items = nil
    _weaponSkinResMergeCache.key = nil
    _weaponSkinResMergeCache.res = nil
end

-- [XTHRLEN]Magick Delight Helmet
local EQUIP_LEVEL_SETS = {
    [1502000382] = { lv1 = 1502001382, lv2 = 1502002382, lv3 = 1502003382, slot = "helmet" },
}
local _equipLevelByRes = {}
local function registerEquipLevelSet(catalog, lv1, lv2, lv3, slot)
    catalog = tonumber(catalog)
    if not catalog then return end
    local set = {
        catalog = catalog,
        lv1 = tonumber(lv1) or 0,
        lv2 = tonumber(lv2) or 0,
        lv3 = tonumber(lv3) or 0,
        slot = slot or "helmet",
    }
    EQUIP_LEVEL_SETS[catalog] = set
    for _, rid in ipairs({ catalog, set.lv1, set.lv2, set.lv3 }) do
        if rid and rid > 0 then _equipLevelByRes[rid] = set end
    end
end
for catalog, set in pairs(EQUIP_LEVEL_SETS) do
    registerEquipLevelSet(catalog, set.lv1, set.lv2, set.lv3, set.slot)
end
_G.AddOutfitRegisterEquipLevelSet = registerEquipLevelSet

local EQUIP_LEVEL_RANGES = {
    { base = 1502000000, slot = "helmet" },
    { base = 1501000000, slot = "bag"    },
}

local function findEquipLevelRange(resID)
    resID = tonumber(resID)
    if not resID then return nil end
    for _, r in ipairs(EQUIP_LEVEL_RANGES) do
        if resID >= r.base and resID < r.base + 1000000 then return r end
    end
    return nil
end

local function detectLevelFromPattern(resID)
    resID = tonumber(resID)
    if not resID then return nil, nil end
    local r = findEquipLevelRange(resID)
    if not r then return nil, nil end
    if resID < r.base + 1000 or resID >= r.base + 4000 then return nil, nil end
    local tail = resID - r.base
    local levelDigit = math.floor(tail / 1000)
    if levelDigit >= 1 and levelDigit <= 3 then
        return levelDigit, r.base + (tail - levelDigit * 1000)
    end
    return nil, nil
end

local function buildPatternLevelSet(catalog)
    catalog = tonumber(catalog)
    if not catalog then return nil end
    local r = findEquipLevelRange(catalog)
    if not r then return nil end
    local tail = catalog - r.base
    if tail < 0 or tail >= 1000 then return nil end
    return {
        catalog = catalog,
        lv1 = catalog + 1000,
        lv2 = catalog + 2000,
        lv3 = catalog + 3000,
        slot = r.slot,
    }
end

local function getEquipLevelSet(resID)
    resID = tonumber(resID)
    if not resID then return nil end
    local set = _equipLevelByRes[resID]
    if set then return set end
    local level, catalog = detectLevelFromPattern(resID)
    if catalog then
        if EQUIP_LEVEL_SETS[catalog] then return EQUIP_LEVEL_SETS[catalog] end
        if level then return buildPatternLevelSet(catalog) end
    end
    -- [XTHRLEN] resID
    local direct = buildPatternLevelSet(resID)
    if direct then
        _equipLevelByRes[resID] = direct
        if direct.lv1 > 0 then _equipLevelByRes[direct.lv1] = direct end
        if direct.lv2 > 0 then _equipLevelByRes[direct.lv2] = direct end
        if direct.lv3 > 0 then _equipLevelByRes[direct.lv3] = direct end
    end
    return direct
end

local function normalizeEquipCatalogRes(resID)
    resID = tonumber(resID)
    if not resID or resID <= 0 then return 0 end
    local set = getEquipLevelSet(resID)
    if set then return set.catalog end
    return resID
end

local function detectLevelFromEquipRes(resID)
    resID = tonumber(resID)
    if not resID then return nil end
    local set = getEquipLevelSet(resID)
    if set then
        if resID == set.lv1 then return 1
        elseif resID == set.lv2 then return 2
        elseif resID == set.lv3 then return 3 end
    end
    local level = detectLevelFromPattern(resID)
    return level
end

local function mapEquipLevelSet(set, level)
    if not set then return 0 end
    level = tonumber(level) or 3
    if level == 1 then return set.lv1 or 0
    elseif level == 2 then return set.lv2 or 0 end
    return set.lv3 or 0
end

local function mapEquipSkinRes(resID, level)
    resID, level = tonumber(resID), tonumber(level) or 3
    if not resID or resID <= 0 then return 0 end
    local catalogRes = normalizeEquipCatalogRes(resID)
    local set = getEquipLevelSet(catalogRes)
    if set then
        local mapped = mapEquipLevelSet(set, level)
        if mapped > 0 then return mapped end
    end
    local mapped = 0
    pcall(function()
        local itemMappingCfg = CDataTable.GetTableData("BackpackMapping", catalogRes)
        if itemMappingCfg then
            if level == 1 then mapped = tonumber(itemMappingCfg.SkinItemIDLv1) or 0
            elseif level == 2 then mapped = tonumber(itemMappingCfg.SkinItemIDLv2) or 0
            else mapped = tonumber(itemMappingCfg.SkinItemIDLv3) or 0 end
        end
        if mapped <= 0 and DataMgr and DataMgr.GetEquipmentItemIDByResID then
            mapped = tonumber(DataMgr.GetEquipmentItemIDByResID(level, catalogRes)) or 0
        end
    end)
    if mapped > 0 then return mapped end
    if isInjectedRes(catalogRes) then return catalogRes end
    return 0
end

local function buildEquipSkinLists(resID)
    resID = normalizeEquipCatalogRes(resID)
    return {
        mapEquipSkinRes(resID, 1),
        mapEquipSkinRes(resID, 2),
        mapEquipSkinRes(resID, 3),
    }
end

local function ensureMatchEquipCache()
    local cch = cache()
    local eq = MATCH_CONFIG.equip or {}
    if (not cch.equip.bag or cch.equip.bag <= 0) and eq.bag and eq.bag > 0 then
        cch.equip.bag = eq.bag
    end
    if (not cch.equip.helmet or cch.equip.helmet <= 0) and eq.helmet and eq.helmet > 0 then
        cch.equip.helmet = eq.helmet
    end
    if (not cch.equip.armor or cch.equip.armor <= 0) and eq.armor and eq.armor > 0 then
        cch.equip.armor = eq.armor
    end
    if (not cch.equip.parachute or cch.equip.parachute <= 0) and eq.parachute and eq.parachute > 0 then
        cch.equip.parachute = eq.parachute
    end
    if (not cch.equip.glider or cch.equip.glider <= 0) and eq.glider and eq.glider > 0 then
        cch.equip.glider = eq.glider
    end
end

local function syncMatchConfigFromCache()
    local cch = cache()
    if cch.outfitRes and cch.outfitRes > 0 then
        MATCH_CONFIG.outfitRes = cch.outfitRes
    else
        MATCH_CONFIG.outfitRes = 0
    end
    MATCH_CONFIG.weaponSkins = MATCH_CONFIG.weaponSkins or {}
    for wid, w in pairs(cch.weapons or {}) do
        if w.resID and w.resID > 0 then
            MATCH_CONFIG.weaponSkins[wid] = w.resID
        end
    end
    MATCH_CONFIG.equip = MATCH_CONFIG.equip or {}
    for _, slot in ipairs({ "bag", "helmet", "armor", "parachute", "glider" }) do
        if cch.equip[slot] and cch.equip[slot] > 0 then
            MATCH_CONFIG.equip[slot] = cch.equip[slot]
        end
    end
end

local function restorePersistedVehicles()
    if not _G._addOutfitPersistLoaded then return end
    pcall(function()
        if _G._savedVehicleSlotList and DataMgr then
            DataMgr.VehicleSlotList = DataMgr.VehicleSlotList or {}
            for subType, insList in pairs(_G._savedVehicleSlotList) do
                if insList and #insList > 0 then
                    DataMgr.VehicleSlotList[subType] = insList
                end
            end
        end
    end)
    pcall(function()
        if _G._savedGarageVehicles then
            local GTS = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.GarageThemeSystem)
            if GTS then
                GTS.GarageVehicleInfo = GTS.GarageVehicleInfo or {}
                for slot, info in pairs(_G._savedGarageVehicles) do
                    if info and info.inst_id then
                        GTS.GarageVehicleInfo[slot] = info
                    end
                end
            end
        end
    end)
end

local function restorePersistedMotions()
    if not _G._addOutfitPersistLoaded then return end
    pcall(function()
        if not _G._savedMotionList or #_G._savedMotionList == 0 then return end
        if not DataMgr then return end
        DataMgr.MotionSlotList = {}
        for i, ins in ipairs(_G._savedMotionList) do
            DataMgr.MotionSlotList[i] = ins
        end
        if EventSystem and EVENTTYPE_MOTION and EVENTID_MOTION_UPDATE_SLOT_LIST then
            EventSystem:postEvent(EVENTTYPE_MOTION, EVENTID_MOTION_UPDATE_SLOT_LIST)
        end
    end)
end

local function restorePersistedEquipIns()
    if not _G._addOutfitPersistLoaded then return end
    pcall(function()
        if not DataMgr then return end
        if _G._savedEquipIns then
            DataMgr.equipmentSkinInsIDTable = DataMgr.equipmentSkinInsIDTable or {}
            for subType, ins in pairs(_G._savedEquipIns) do
                if ins and ins > 0 then
                    DataMgr.equipmentSkinInsIDTable[subType] = ins
                end
            end
        end
        if _G._savedVstSkin and _G._savedVstSkin > 0 then
            DataMgr.vst_skin = _G._savedVstSkin
        end
    end)
end

local function restorePersistedThrowObjects()
    if not _G._addOutfitPersistLoaded then return end
    pcall(function()
        if not _G._savedThrowObjects then return end
        local cch = cache()
        cch.throwObjects = cch.throwObjects or {}
        for st, info in pairs(_G._savedThrowObjects) do
            if info.resID and info.resID > 0 then
                cch.throwObjects[st] = info
            end
        end
    end)
end

local GAME_HELMET_LEVEL = {
    [502001] = 1, [502004] = 1,
    [502002] = 2, [502005] = 2,
    [502003] = 3,
}
local GAME_BAG_LEVEL = {
    [501001] = 1, [501004] = 1,
    [501002] = 2, [501005] = 2,
    [501003] = 3,
}

local function detectEquipLevelFromBaseId(baseId, catalogResID)
    baseId, catalogResID = tonumber(baseId), tonumber(catalogResID)
    if not baseId or baseId <= 0 then return nil end
    local level
    pcall(function()
        catalogResID = catalogResID and normalizeEquipCatalogRes(catalogResID) or catalogResID
        if catalogResID then
            local set = getEquipLevelSet(catalogResID)
            if set then
                if baseId == set.lv1 then level = 1
                elseif baseId == set.lv2 then level = 2
                elseif baseId == set.lv3 then level = 3 end
            end
            if not level then
                local m = CDataTable.GetTableData("BackpackMapping", catalogResID)
                if m then
                    if tonumber(m.SkinItemIDLv1) == baseId then level = 1
                    elseif tonumber(m.SkinItemIDLv2) == baseId then level = 2
                    elseif tonumber(m.SkinItemIDLv3) == baseId then level = 3 end
                end
            end
        end
        if not level then
            local patLevel, patCatalog = detectLevelFromPattern(baseId)
            if patLevel and (not catalogResID or patCatalog == catalogResID) then
                level = patLevel
            end
        end
        if not level then level = GAME_HELMET_LEVEL[baseId] or GAME_BAG_LEVEL[baseId] end
        if not level and baseId >= 1505000001 and baseId <= 1505000003 then
            level = baseId - 1505000000
        end
        if not level then
            pcall(function()
                local BU = require("GameLua.Mod.BaseMod.GamePlay.Backpack.BackpackUtils")
                if BU.GetEquipmentHelmetLevel then
                    local hl = BU.GetEquipmentHelmetLevel(baseId)
                    if hl and hl >= 1 and hl <= 3 then level = hl end
                end
                if not level and BU.GetEquipmentBagLevel then
                    local bl = BU.GetEquipmentBagLevel(baseId)
                    if bl and bl >= 1 and bl <= 3 then level = bl end
                end
            end)
        end
    end)
    return level
end

local function isBaseEquipItemId(itemId)
    itemId = tonumber(itemId)
    if not itemId or itemId <= 0 then return false end
    if GAME_HELMET_LEVEL[itemId] or GAME_BAG_LEVEL[itemId] then return true end
    if itemId >= 1505000001 and itemId <= 1505000100 then return true end
    if itemId >= 1501000000 and itemId < 1502000000 then return true end
    if itemId >= 502001 and itemId <= 502999 then return true end
    if itemId >= 501001 and itemId <= 501999 then return true end
    return false
end

local function resolveMatchEquipSkin(catalogResID, baseItemID)
    catalogResID = normalizeEquipCatalogRes(catalogResID)
    if not catalogResID or catalogResID <= 0 then return 0 end
    local level = detectEquipLevelFromBaseId(baseItemID, catalogResID) or 3
    return mapEquipSkinRes(catalogResID, level)
end

local function getEquipDisplayLevel(resID, slot)
    local wornLevel = detectLevelFromEquipRes(resID)
    if wornLevel then return wornLevel end
    pcall(function()
        local fbd = require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
        if slot == "bag" then wornLevel = fbd:GetBagLevel() or 3
        elseif slot == "helmet" then wornLevel = fbd:GetHelmetLevel() or 3 end
    end)
    return wornLevel or 3
end

local function syncEquipLevelFromRes(resID, slot)
    local level = detectLevelFromEquipRes(resID)
    if not level then return end
    pcall(function()
        local fbd = require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
        if slot == "helmet" then
            fbd:SetHelmetLevel(level)
        elseif slot == "bag" then
            fbd:SetBagLevel(level)
        end
    end)
end

local function saveEquipSkin(resID, insID)
    resID, insID = tonumber(resID), tonumber(insID)
    if not resID then return end
    local slot = getEquipSkinSlot(resID)
    if not slot then return end
    local cch = cache()
    cch.equip[slot] = resID
    if insID then cch.equip[slot .. "Ins"] = insID end
    MATCH_CONFIG.equip = MATCH_CONFIG.equip or {}
    MATCH_CONFIG.equip[slot] = resID
    _S.matchApplied = false
    invalidateSocialWearCache()
    log("Equipment memory", slot, resID)
    pcall(_AutoSaveOutfit)
end

local function saveClothPiece(resID)
    resID = tonumber(resID)
    if not resID then return end
    local cch = cache()
    cch.clothes[resID] = true
    _S.matchApplied = false
    invalidateSocialWearCache()
    pcall(_AutoSaveOutfit)
end

local function clearClothesForKind(kind)
    local clearMap = subTypesToClearForKind(kind)
    if not clearMap then return end
    local cch = cache()
    for resID in pairs(cch.clothes) do
        local st = subType(cfg(resID))
        if st and clearMap[st] then cch.clothes[resID] = nil end
    end
    if kind == "full_suit" then
        cch.outfitRes, cch.outfitIns = nil, nil
    end
end

local function saveWeaponToCache(weaponID, resID, insID)
    weaponID, resID, insID = tonumber(weaponID), tonumber(resID), tonumber(insID)
    if not weaponID or not resID or resID <= 0 then return end
    local cch = cache()
    cch.weapons[weaponID] = { resID = resID, insID = insID or 0 }
    _G.AddOutfitLastAppliedSkin = {}
    _S.matchApplied = false
    invalidateSocialWearCache()
    log("A Memory of Dwelling", weaponID, "→", resID)
    pcall(_AutoSaveOutfit)
end

local function cacheWeaponSkinFromIns(weaponID, insID)
    weaponID, insID = tonumber(weaponID), tonumber(insID)
    if not weaponID or not insID or insID <= 0 then return end
    if isInjectedIns(insID) then
        saveWeaponToCache(weaponID, R.insToRes[insID], insID)
        return
    end
    pcall(function()
        local wd = require("client.slua.logic.wardrobe.wardrobe_data")
        local d = wd:GetValidHallDepotItemDataByInsID(insID) or wd:GetHallDepotItemDataByInsID(insID)
        if d and d.resID and tonumber(d.resID) > 0 then
            saveWeaponToCache(weaponID, tonumber(d.resID), insID)
        end
    end)
end

local function saveEquip(resID, insID)
    resID, insID = tonumber(resID), tonumber(insID)
    if not resID or not insID then return end
    local c = cfg(resID)
    local st = subType(c)
    local kind = getClothKind(resID)
    local cch = cache()
    if kind == "full_suit" then
        clearClothesForKind("full_suit")
        cch.outfitRes, cch.outfitIns = resID, insID
        _G.AddOutfitLastLobbyOutfitRes = resID
        invalidateSocialWearCache()
    elseif kind then
        if cch.outfitRes and isFullSuitRes(cch.outfitRes) then
            cch.outfitRes, cch.outfitIns = nil, nil
            _G.AddOutfitLastLobbyOutfitRes = nil
        end
        clearClothesForKind(kind)
        saveClothPiece(resID)
    elseif getEquipSkinSlot(resID) then
        saveEquipSkin(resID, insID)
    elseif _K.GUN_SUB[st] then
        local wid = weaponIdFromSkin(resID)
        if not wid then
            pcall(function()
                local wgl = require("client.slua.logic.wardrobe.logic_wardrobe_gun")
                wid = wgl.GetCurGunID and wgl:GetCurGunID() or nil
                if not wid and wgl.GetCurrentGunID then
                    wid = wgl:GetCurrentGunID()
                end
            end)
        end
        if wid then saveWeaponToCache(wid, resID, insID) end
    elseif st == _K.MELEE_ID then
        saveWeaponToCache(_K.MELEE_ID, resID, insID)
    elseif isThrowObjectRes(resID) then
        saveThrowObject(resID, insID)
    elseif isInjectedRes(resID) then
        local mt = wardrobeMainTab(resID)
        if mt ~= _K.WARDROBE_PAGE_VEHICLE then
            saveClothPiece(resID)
        end
    end
    _S.matchApplied = false
    pcall(_AutoSaveOutfit)
end

local _lastSyncWeaponCache = 0
local function syncWeaponCacheFromLobby()
    local now = 0
    pcall(function() now = os.clock() end)
    if (now - _lastSyncWeaponCache) < 0.3 then return end  -- [XTHRLEN] throttle: max ~3x per second
    _lastSyncWeaponCache = now
    local cch = cache()
    pcall(function()
        local fbd = require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
        local bag = fbd.GetCurrentFashionBag and fbd:GetCurrentFashionBag()
        if bag then
            if bag.bag_skin and tonumber(bag.bag_skin) > 0 then
                local rid = isInjectedIns(bag.bag_skin) and R.insToRes[bag.bag_skin] or (function()
                    local wd = require("client.slua.logic.wardrobe.wardrobe_data")
                    local d = wd:GetHallDepotItemDataByInsID(bag.bag_skin)
                    return d and tonumber(d.resID)
                end)()
                if rid and isInjectedRes(rid) then cch.equip.bag = rid end
            end
            if bag.helmet_skin and tonumber(bag.helmet_skin) > 0 then
                local rid = isInjectedIns(bag.helmet_skin) and R.insToRes[bag.helmet_skin] or (function()
                    local wd = require("client.slua.logic.wardrobe.wardrobe_data")
                    local d = wd:GetHallDepotItemDataByInsID(bag.helmet_skin)
                    return d and tonumber(d.resID)
                end)()
                if rid and isInjectedRes(rid) then cch.equip.helmet = rid end
            end
            if bag.weapon_skin_list then
                for weaponID, entry in pairs(bag.weapon_skin_list) do
                    cacheWeaponSkinFromIns(weaponID, entry and (entry.skin_id or entry.skinId))
                end
            end
        end
    end)
    pcall(function()
        local Arm = require("client.logic.armory.logic_armory")
        if Arm.rsp_list and Arm.rsp_list.install_list then
            for weaponID, entry in pairs(Arm.rsp_list.install_list) do
                cacheWeaponSkinFromIns(weaponID, entry and entry.skin_id)
            end
        end
    end)
    pcall(function()
        if DataMgr and DataMgr.equipmentSkinInsIDTable then
            local function ridFromIns(ins)
                ins = tonumber(ins)
                if not ins or ins <= 0 then return nil end
                if isInjectedIns(ins) then return R.insToRes[ins] end
                local wd = require("client.slua.logic.wardrobe.wardrobe_data")
                local d = wd:GetHallDepotItemDataByInsID(ins)
                return d and tonumber(d.resID)
            end
            local bagRid = ridFromIns(DataMgr.equipmentSkinInsIDTable[504])
            if bagRid and isInjectedRes(bagRid) then cch.equip.bag = bagRid end
            local helmRid = ridFromIns(DataMgr.equipmentSkinInsIDTable[505])
            if helmRid and isInjectedRes(helmRid) then cch.equip.helmet = helmRid end
            local armorRid = ridFromIns(DataMgr.equipmentSkinInsIDTable[506])
            if armorRid and isInjectedRes(armorRid) then cch.equip.armor = armorRid end
        end
    end)
end

local _lastSyncClothesCache = 0
local function syncClothesCacheFromLobby()
    local now = 0
    pcall(function() now = os.clock() end)
    if (now - _lastSyncClothesCache) < 0.3 then return end  -- [XTHRLEN] throttle: max ~3x per second
    _lastSyncClothesCache = now
    local cch = cache()
    pcall(function()
        local inLobby = false
        if GameStatus and GameStatus.IsInLobbyOrMainCity and GameStatus.IsInLobbyOrMainCity() then
            inLobby = true
        end

        if inLobby and not _G._addOutfitPersistLoaded then
            cch.outfitRes = nil
            cch.outfitIns = nil
            _G.AddOutfitLastLobbyOutfitRes = nil
            cch.clothes = {}
        end

        local AvatarData = require("client.logic.data.AvatarData")
        local wd = require("client.slua.logic.wardrobe.wardrobe_data")
        for _, ins in pairs(AvatarData.GetRoleWear()) do
            ins = tonumber(ins)
            if ins and ins > 0 then
                local resID = isInjectedIns(ins) and R.insToRes[ins] or (function()
                    local d = wd:GetHallDepotItemDataByInsID(ins)
                    return d and tonumber(d.resID)
                end)()
                if resID and isInjectedRes(resID) then
                    if isFullSuitRes(resID) then
                        cch.outfitRes, cch.outfitIns = resID, ins
                        _G.AddOutfitLastLobbyOutfitRes = resID
                    elseif not getEquipSkinSlot(resID) and not weaponIdFromSkin(resID) then
                        cch.clothes[resID] = true
                    elseif getEquipSkinSlot(resID) then
                        local slot = getEquipSkinSlot(resID)
                        cch.equip[slot] = resID
                        cch.equip[slot .. "Ins"] = ins
                    end
                end
            end
        end
--[[
        pcall(function()
            local fashionbag_data = require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
            local paraInsID = tonumber(fashionbag_data:GetParachute())
            if paraInsID and paraInsID > 0 then
                local paraResID
                if isInjectedIns(paraInsID) then
                    paraResID = R.insToRes[paraInsID]
                else
                    local d = wd:GetHallDepotItemDataByInsID(paraInsID)
                    paraResID = d and tonumber(d.resID)
                end
                if paraResID and paraResID > 0 then
                    cch.equip.parachute = paraResID
                    cch.equip.parachuteIns = paraInsID
                    MATCH_CONFIG.equip = MATCH_CONFIG.equip or {}
                    MATCH_CONFIG.equip.parachute = paraResID
                end
            end
        end)
]]
        -- [XTHRLEN]FashionBag
        pcall(function()
            local fashionbag_data = require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
            local gliderInsID = tonumber(fashionbag_data:GetAircraftOrGliding())
            if gliderInsID and gliderInsID > 0 then
                local gliderResID
                if isInjectedIns(gliderInsID) then
                    gliderResID = R.insToRes[gliderInsID]
                else
                    local d = wd:GetHallDepotItemDataByInsID(gliderInsID)
                    gliderResID = d and tonumber(d.resID)
                end
                if gliderResID and gliderResID > 0 then
                    cch.equip.glider = gliderResID
                    cch.equip.gliderIns = gliderInsID
                    MATCH_CONFIG.equip = MATCH_CONFIG.equip or {}
                    MATCH_CONFIG.equip.glider = gliderResID
                end
            end
        end)
    end)
end

local function syncClothesCacheFromLive()
    local cch = cache()
    pcall(function()
        local AvatarData = require("client.logic.data.AvatarData")
        local wd = require("client.slua.logic.wardrobe.wardrobe_data")
        for _, ins in pairs(AvatarData.GetRoleWear()) do
            ins = tonumber(ins)
            if ins and ins > 0 then
                local resID = isInjectedIns(ins) and R.insToRes[ins] or (function()
                    local d = wd:GetHallDepotItemDataByInsID(ins)
                    return d and tonumber(d.resID)
                end)()
                if resID and isInjectedRes(resID) then
                    if isFullSuitRes(resID) then
                        cch.outfitRes, cch.outfitIns = resID, ins
                        _G.AddOutfitLastLobbyOutfitRes = resID
                    elseif not getEquipSkinSlot(resID) and not weaponIdFromSkin(resID) then
                        cch.clothes[resID] = true
                    else
                        local slot = getEquipSkinSlot(resID)
                        if slot then
                            cch.equip[slot] = resID
                            cch.equip[slot .. "Ins"] = ins
                        end
                    end
                end
            end
        end
        pcall(function()
            local fashionbag_data = require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
            --[[
            local paraInsID = tonumber(fashionbag_data:GetParachute())
            if paraInsID and paraInsID > 0 then
                local paraResID = isInjectedIns(paraInsID) and R.insToRes[paraInsID] or (function()
                    local d = wd:GetHallDepotItemDataByInsID(paraInsID)
                    return d and tonumber(d.resID)
                end)()
                if paraResID and paraResID > 0 then
                    cch.equip.parachute = paraResID
                    cch.equip.parachuteIns = paraInsID
                end
            end
            ]]
            local gliderInsID = tonumber(fashionbag_data:GetAircraftOrGliding())
            if gliderInsID and gliderInsID > 0 then
                local gliderResID = isInjectedIns(gliderInsID) and R.insToRes[gliderInsID] or (function()
                    local d = wd:GetHallDepotItemDataByInsID(gliderInsID)
                    return d and tonumber(d.resID)
                end)()
                if gliderResID and gliderResID > 0 then
                    cch.equip.glider = gliderResID
                    cch.equip.gliderIns = gliderInsID
                end
            end
        end)
    end)
end

local function syncThrowObjectCacheFromLobby()
    local cch = cache()
    pcall(function()
        local fbd = require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
        local bag = fbd.GetCurrentFashionBag and fbd:GetCurrentFashionBag()
        if not bag or not bag.throw_object_list then return end
        cch.throwObjects = cch.throwObjects or {}
        for subType, insID in pairs(bag.throw_object_list) do
            insID = tonumber(insID)
            subType = tonumber(subType)
            if insID and insID > 0 and subType and _K.THROW_SUB[subType] then
                local resID
                if isInjectedIns(insID) then
                    resID = R.insToRes[insID]
                else
                    local wd = require("client.slua.logic.wardrobe.wardrobe_data")
                    local d = wd:GetHallDepotItemDataByInsID(insID)
                    resID = d and tonumber(d.resID)
                end
                if resID and isInjectedRes(resID) then
                    cch.throwObjects[subType] = { resID = resID, insID = insID }
                end
            end
        end
    end)
end

local function syncAllCacheFromLive()
    syncWeaponCacheFromLobby()
    syncClothesCacheFromLive()
    syncThrowObjectCacheFromLobby()
    ensureMatchEquipCache()
    syncMatchConfigFromCache()
end

_G.AddOutfitSyncCacheBeforeSave = syncAllCacheFromLive

local function snapshotLobbyWear()
    syncWeaponCacheFromLobby()
    syncClothesCacheFromLobby()
    syncThrowObjectCacheFromLobby()
    ensureMatchEquipCache()
end

local function getCachedWeaponSkin(weaponID)
    weaponID = tonumber(weaponID) or 0
    if weaponID <= 0 then return nil end
    syncWeaponCacheFromLobby()
    local w = cache().weapons[weaponID]
    if w and w.resID and w.resID > 0 then return w.resID end
        return nil
    end

local function getMatchWeaponSkin(weaponID)
    weaponID = tonumber(weaponID) or 0
    local fromCache = getCachedWeaponSkin(weaponID)
    if fromCache then return fromCache end
    if MATCH_CONFIG.weaponSkins then
        local fixed = tonumber(MATCH_CONFIG.weaponSkins[weaponID])
        if fixed and fixed > 0 then return fixed end
    end
    return nil
end

local _ticker
pcall(function() _ticker = require("common.time_ticker") end)
local function later(sec, fn)
    if _G.SetTimer then pcall(_G.SetTimer, sec, fn) return end
    if _ticker and _ticker.AddTimer then pcall(_ticker.AddTimer, sec, fn) end
end

local function getEntity()
    local ok, dc = pcall(require, "client.slua.logic.wardrobe.logic_wardrobe_data_center")
        if not ok or not dc then return nil end
        local ok2, e = pcall(dc.GetWardrobeData, EWardrobeDataSource and EWardrobeDataSource.Wardrobe or nil)
        if ok2 and e then return e end
        ok2, e = pcall(dc.GetWardrobeData)
        return ok2 and e or nil
    end

    local function alreadyHave(entity, resID)
        local arr = entity.ResIDToIndexArrayMap and entity.ResIDToIndexArrayMap[resID]
        if not arr then return false end
        for _, idx in pairs(arr) do
            local d = entity._data[idx]
            if d and d.count and d.count > 0 then return true end
        end
        return false
    end

    local function ensureDepotTabFields(entity, data, resID)
        if not data then return end
        pcall(function()
            if entity and entity.LoadConfigForData and CDataTable.GetTableData then
                entity:LoadConfigForData(data, CDataTable.GetTableData)
            end
        end)
        local equipSlot = getEquipSkinSlot(resID)
        if equipSlot == "bag" then
            data.mainTabType = _K.WARDROBE_PAGE_AVATAR
            data.subTabType = _K.WARDROBE_TAB_BAG
        elseif equipSlot == "helmet" then
            data.mainTabType = _K.WARDROBE_PAGE_AVATAR
            data.subTabType = _K.WARDROBE_TAB_HELMET
        elseif equipSlot == "armor" then
            data.mainTabType = _K.WARDROBE_PAGE_AVATAR
            data.subTabType = _K.WARDROBE_TAB_ARMOR
        end
        local c = cfg(resID)
        if c then data.itemSubType = tonumber(c.ItemSubType or c.itemSubType) or data.itemSubType end
        if c then
            local wmTab = tonumber(c.WardrobeMainTab or c.wardrobeMainTab) or 0
            if wmTab == _K.WARDROBE_PAGE_VEHICLE then
                data.mainTabType = _K.WARDROBE_PAGE_VEHICLE
                data.subTabType = tonumber(c.WardrobeTab or c.wardrobeTab) or data.subTabType
            end
        end
    end

    local function depotResID(v)
        return v and tonumber(v.resID or v.res_id) or nil
    end

    local function injectedEquipAllowed(resID, mainTab, subTab)
        local slot = getEquipSkinSlot(resID)
        if slot == "bag" then
            return mainTab == _K.WARDROBE_PAGE_AVATAR and subTab == _K.WARDROBE_TAB_BAG
        end
        if slot == "helmet" then
            return mainTab == _K.WARDROBE_PAGE_AVATAR and subTab == _K.WARDROBE_TAB_HELMET
        end
        if slot == "armor" then
            return mainTab == _K.WARDROBE_PAGE_AVATAR and subTab == _K.WARDROBE_TAB_ARMOR
        end
        if slot == "parachute" then
            return mainTab == _K.WARDROBE_PAGE_PARACHUTE and subTab == _K.WARDROBE_TAB_PARACHUTE
        end
        if slot == "glider" then
            return mainTab == _K.WARDROBE_PAGE_PARACHUTE and subTab == _K.WARDROBE_TAB_GLIDER
        end
        return nil
    end

    local function injectOne(entity, resID, insID)
        if alreadyHave(entity, resID) then
            R.resToIns[resID] = R.resToIns[resID] or insID
            R.insToRes[insID] = resID
            pcall(function()
                local data = entity.GetDataByInsID and entity:GetDataByInsID(R.resToIns[resID])
                if data then ensureDepotTabFields(entity, data, resID) end
            end)
            return true
        end
        entity:AddData({
            instid = insID, res_id = resID, count = 1,
            lock_cnt = 0, isnew = 0, valid_hours = 0, expire_ts = 0,
        })
        pcall(function()
            local data = entity.GetDataByInsID and entity:GetDataByInsID(insID)
            if data then
                ensureDepotTabFields(entity, data, resID)
            end
        end)
        R.insToRes[insID] = resID
        R.resToIns[resID] = insID
        return true
    end

    local function injectArmory(resID, insID)
        local wid = weaponIdFromSkin(resID)
            if not wid then return end
            local Arm = require("client.logic.armory.logic_armory")
            Arm.rsp_list = Arm.rsp_list or { skin_list = {}, install_list = {} }
            Arm.rsp_list.skin_list = Arm.rsp_list.skin_list or {}
            if not Arm.rsp_list.skin_list[wid] then Arm.rsp_list.skin_list[wid] = {} end
            Arm.rsp_list.skin_list[wid][resID] = { is_open = 1 }
            Arm.WardrobeInsList = Arm.WardrobeInsList or {}
            Arm.WardrobeInsList[resID] = insID
        end

        local function injectAll(entity)
            if _S.injectedDone then return true end
            refreshItems()
            entity = entity or getEntity()
            if not entity or not entity.bInit then return false end

            if next(_C.fullSuit) == nil then
                pcall(function()
                    for _, rid in ipairs(ITEMS) do
                        local c = cfg(rid)
                        if c then
                            local st = tonumber(c.ItemSubType or c.itemSubType) or 0
                            if st == _K.ST_TOP then
                                local tab = tonumber(c.WardrobeTab or c.wardrobeTab) or 0
                                if tab == _K.WARDROBE_TAB_SUIT then
                                    _C.fullSuit[rid] = true
                                else
                                    pcall(function()
                                        local LogicXSuit = require("client.slua.logic.XSuit.logic_xsuit")
                                        if LogicXSuit.IsXSuit(rid) then _C.fullSuit[rid] = true end
                                    end)
                                end
                            end
                            local wmTab = tonumber(c.WardrobeMainTab or c.wardrobeMainTab) or 0
                            if wmTab == _K.WARDROBE_PAGE_VEHICLE then
                                _C.vehicleItems[#_C.vehicleItems + 1] = rid
                            end
                        end
                        getEquipSkinSlot(rid)
                        weaponIdFromSkin(rid)
                    end
                    for _, rid in ipairs(ITEMS) do
                        getInjectedItemTab(rid)
                    end
                    local allTabs = {
                        {_K.WARDROBE_PAGE_AVATAR, _K.WARDROBE_TAB_SUIT},
                        {_K.WARDROBE_PAGE_AVATAR, _K.WARDROBE_TAB_CLOTHES},
                        {_K.WARDROBE_PAGE_AVATAR, _K.WARDROBE_TAB_TROUSERS},
                        {_K.WARDROBE_PAGE_AVATAR, _K.WARDROBE_TAB_SHOES},
                        {_K.WARDROBE_PAGE_AVATAR, _K.WARDROBE_TAB_BAG},
                        {_K.WARDROBE_PAGE_AVATAR, _K.WARDROBE_TAB_HELMET},
                        {_K.WARDROBE_PAGE_AVATAR, _K.WARDROBE_TAB_ARMOR},
                        {_K.WARDROBE_PAGE_WEAPON, _K.WARDROBE_TAB_GUN},
                        {_K.WARDROBE_PAGE_PARACHUTE, _K.WARDROBE_TAB_PARACHUTE},
                        {_K.WARDROBE_PAGE_PARACHUTE, _K.WARDROBE_TAB_GLIDER},
                        {_K.WARDROBE_PAGE_VEHICLE, 0},
                    }
                    -- [XTHRLEN] pageMatch is now computed lazily in IsValidCurrentPageItem
                    for k in pairs(_C.pageMatch) do _C.pageMatch[k] = nil end
                end)
            end

            local n = 0
            for i, resID in ipairs(ITEMS) do
                local insID = _K.INS_BASE + i
                if injectOne(entity, resID, insID) then
                    n = n + 1
                    local c = cfg(resID)
                    if _K.GUN_SUB[subType(c)] or subType(c) == _K.MELEE_ID then
                        injectArmory(resID, insID)
                    end
                end
            end
            if n > 0 then
                _S.injectedDone = true
                _G.AddOutfit_R = R
                log("injection", n, "items")
            end
            return n > 0
        end

        local function injectAllSources()
            return injectAll(getEntity())
        end

        local function refreshWardrobe()
            pcall(function()
                if EventSystem and EVENTTYPE_WARDROBE then
                    if EVENTID_WARDROBE_UPDATE_ITEM_LIST then
                        EventSystem:postEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_UPDATE_ITEM_LIST)
                    end
                    if EVENTID_WARDROBE_UPDATE_AVATAR_LIST then
                        EventSystem:postEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_UPDATE_AVATAR_LIST)
                    end
                    if EVENTID_WARDROBE_UPDATE_GUN_LIST then
                        EventSystem:postEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_UPDATE_GUN_LIST, -1)
                    end
                end
            end)
        end

        local function findWornInsBySubType(st)
            st = tonumber(st)
            if not st then return nil end
            local wd = require("client.slua.logic.wardrobe.wardrobe_data")
            local AvatarData = require("client.logic.data.AvatarData")
            for _, ins in pairs(AvatarData.GetRoleWear()) do
                ins = tonumber(ins)
                if ins and ins > 0 then
                    local d = wd:GetHallDepotItemDataByInsID(ins)
                    if d and tonumber(d.itemSubType) == st then
                        return ins, d.resID
                    end
                end
            end
            return nil
        end

        local function removeRoleWearBySubTypes(stMap)
            if not stMap then return end
            local wd = require("client.slua.logic.wardrobe.wardrobe_data")
            local AvatarData = require("client.logic.data.AvatarData")
            for _, ins in pairs(AvatarData.GetRoleWear()) do
                ins = tonumber(ins)
                if ins and ins > 0 then
                    local d = wd:GetHallDepotItemDataByInsID(ins)
                    if d and stMap[tonumber(d.itemSubType)] then
                        AvatarData.RemoveRoleWearDataByValue(ins)
                    end
                end
            end
        end

        local function clearFashionBagSlots(stMap)
            if not stMap then return end
            pcall(function()
                local fbd = require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
                local wfu = require("client.slua.logic.wardrobe.fashionbag.wardrobe_fashion_utils")
                local bag = fbd.GetCurrentFashionBag and fbd:GetCurrentFashionBag()
                if not bag or not bag.rolewear_list then return end
                for st, _ in pairs(stMap) do
                    local idx = wfu.GetRoleWearIndexBySubType and wfu:GetRoleWearIndexBySubType(st)
                    if idx then bag.rolewear_list[idx] = 0 end
                end
            end)
        end

        local function syncFashionBagRolewear()
            pcall(function()
                local fbd = require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
                fbd:SaveRolewearToFashionBag(fbd:GetFashionBagUseIndex())
            end)
        end

        local function ensureKnapsackExtInfo()
            pcall(function()
                local fbd = require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
                local idx = fbd:GetFashionBagUseIndex()
                if not fbd:GetKnapsackExtInfoByIndex(idx) then
                    fbd:SetKnapsackExtInfoByIndex(idx, {})
                end
            end)
        end

        local function getEquipSubType(resID, slot)
            local c = cfg(resID)
            if c then
                local st = tonumber(c.ItemSubType or c.itemSubType)
                if st then return st end
            end
            if slot == "bag" then return ENUM_ITEM_SUBTYPE.Backpack end
            if slot == "helmet" then return ENUM_ITEM_SUBTYPE.Helmet_NoLevel end
            return nil
        end

        local function softRemoveEquipVisual(oldResID, slot)
            oldResID = normalizeEquipCatalogRes(oldResID)
            if not oldResID or oldResID <= 0 or not slot then return end
            pcall(function()
                local TAM = require("client.logic.avatar.logic_team_avatar_manager")
                local AvatarData = require("client.logic.data.AvatarData")
                for lvl = 1, 3 do
                    local displayRes = mapEquipSkinRes(oldResID, lvl)
                    if displayRes > 0 then
                        TAM.ChangeAvatarEquipment(tostring(DataMgr.roleData.uid),
                            AvatarData.CreateAvatarCustom(displayRes), false)
                    end
                end
            end)
        end

        local function applyEquipVisual(resID, insID, slot)
            pcall(function()
                local fbd = require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
                local HT = require("client.logic.lobby.hall_theme_utils")
                local TAM = require("client.logic.avatar.logic_team_avatar_manager")
                local AvatarData = require("client.logic.data.AvatarData")
                local lds = require("client.slua.logic.wardrobe.logic_display_setting")
                local lav = require("client.slua.logic.wardrobe.logic_wardrobe_avatar")
                syncEquipLevelFromRes(resID, slot)
                local level = getEquipDisplayLevel(resID, slot)
                local catalogRes = normalizeEquipCatalogRes(resID)
                local itemSt = getEquipSubType(catalogRes, slot)
                if itemSt then lav:AddToWearInfo(itemSt, insID, catalogRes, 0, 0) end
                lav:AvatarChange(catalogRes, true)
                local displayRes = mapEquipSkinRes(catalogRes, level)
                if displayRes > 0 then
                    TAM.ChangeAvatarEquipment(tostring(DataMgr.roleData.uid),
                        AvatarData.CreateAvatarCustom(displayRes), true)
                end
                if lds.data then
                    if slot == "bag" then lds.data.OpenBag = true end
                    if slot == "helmet" then lds.data.OpenHelmet = true end
                end
                if slot == "helmet" then
                    fbd:SetHeadShow(insID)
                    local WRH = require("client.network.Protocol.WardRobeHandler")
                    WRH.send_depot_set_head_show_req(insID)
                end
                if slot == "bag" then HT.PutOnBag(fbd:GetFashionBagUseIndex()) end
            end)
        end

        local takeOffEquipSkinVisual, takeOffClothVisual, takeOffWeaponSkinVisual

        local function takeOffItem(insID)
            insID = tonumber(insID)
            if not insID or insID <= 0 then return false end
            local resID = R.insToRes[insID]
            if not resID then return false end

            local cch = cache()
            local kind = getClothKind(resID)
            local slot = getEquipSkinSlot(resID)
            local wid  = weaponIdFromSkin(resID)
            local handled = false

            if slot then
                local oldRes = cch.equip[slot] or resID
                takeOffEquipSkinVisual(slot, oldRes, insID)
                cch.equip[slot]          = nil
                cch.equip[slot .. "Ins"] = nil
                if MATCH_CONFIG.equip then MATCH_CONFIG.equip[slot] = 0 end
                handled = true
            elseif kind then
                takeOffClothVisual(resID, insID, kind)
                if kind == "full_suit" then
                    cch.outfitRes, cch.outfitIns = nil, nil
                    _G.AddOutfitLastLobbyOutfitRes = nil
                else
                    cch.clothes[resID] = nil
                end
                handled = true
            elseif wid then
                takeOffWeaponSkinVisual(wid, resID, insID)
                cch.weapons[wid] = nil
                _G.AddOutfitLastAppliedSkin = {}
                _S.weaponApplied = false
                _S.weaponDiagDone = false
                _S.lastAppliedWeaponID = 0
                _S.lastAppliedSkinID = 0
                buildSkinMappings()
                handled = true
            elseif isHallThemeRes(resID) then
                pcall(function()
                    local HT = require("client.logic.lobby.hall_theme_utils")
                    HT.homeThemeItemId = 0
                    HT.SetThemeInstId(0)
                    local fbd = require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
                    local idx = fbd:GetFashionBagUseIndex()
                    local bag = fbd:GetCurrentFashionBag()
                    if bag and bag.avatar_show then
                        bag.avatar_show[HT.knapsack_ext_background] = nil
                    end
                end)
                handled = true
            end

            if not handled then return false end

            _S.matchApplied = false
            _S.matchOutfitDone = false
            invalidateSocialWearCache()
            pcall(_AutoSaveOutfit)
            return true
        end

        takeOffEquipSkinVisual = function(slot, resID, insID)
            if not slot then return end
            resID, insID = tonumber(resID), tonumber(insID)
            if _S.equipSkinApplying then return end
            _S.equipSkinApplying = true
            pcall(function()
                if resID and resID > 0 then softRemoveEquipVisual(resID, slot) end
                local fbd = require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
                local lds = require("client.slua.logic.wardrobe.logic_display_setting")
                local lav = require("client.slua.logic.wardrobe.logic_wardrobe_avatar")
                local HT = require("client.logic.lobby.hall_theme_utils")
                local itemSt = resID and getEquipSubType(resID, slot)
                if itemSt and insID and insID > 0 then
                    pcall(function() lav:SetCurrentWearPreview(itemSt, nil) end)
                end
                if slot == "bag" then
                    fbd:SetBagSkin(0)
                    if lds.data then lds.data.OpenBag = false end
                    HT.PutOnBag(fbd:GetFashionBagUseIndex())
                elseif slot == "helmet" then
                    fbd:SetHelmetSkin(0)
                    if lds.data then lds.data.OpenHelmet = false end
                    fbd:SetHeadShow(0)
                elseif slot == "armor" then
                    pcall(function()
                        local wl = require("client.slua.logic.wardrobe.logic_wardrobe_new")
                        wl:on_putdown_rsp(_K.NET_OK, { res_id = resID or 0, instid = insID or 0, count = 1 }, nil)
                    end)
                end
                if DataMgr and DataMgr.equipmentSkinInsIDTable then
                    local subKey = (slot == "bag") and 504 or (slot == "helmet") and 505 or (slot == "armor") and 506
                    if subKey then DataMgr.equipmentSkinInsIDTable[subKey] = 0 end
                end
                syncFashionBagRolewear()
            end)
            _S.equipSkinApplying = false
        end

        takeOffClothVisual = function(resID, insID, kind)
            resID, insID = tonumber(resID), tonumber(insID)
            if not resID or not insID then return end
            kind = kind or getClothKind(resID)
            local clearMap = subTypesToClearForKind(kind)
            if not clearMap then return end
            pcall(function()
                removeRoleWearBySubTypes(clearMap)
                clearFashionBagSlots(clearMap)
                local WRH = require("client.network.Protocol.WardRobeHandler")
                WRH.on_depot_put_down_rsp(_K.NET_OK, { res_id = resID, count = 1, instid = insID }, nil)
                local av = require("client.slua.logic.wardrobe.logic_wardrobe_avatar")
                local TAM = require("client.logic.avatar.logic_team_avatar_manager")
                local AvatarData = require("client.logic.data.AvatarData")
                local uid = tostring(DataMgr.roleData.uid)
                local itemSt = subType(cfg(resID)) or _K.ST_TOP
                if kind == "full_suit" then
                    itemSt = _K.ST_TOP
                    for st in pairs(clearMap) do
                        local oIns, oRes = findWornInsBySubType(st)
                        if oIns and oRes and oRes > 0 then
                            TAM.ChangeAvatarEquipment(uid, AvatarData.CreateAvatarCustom(oRes), false)
                        end
                    end
                end
                TAM.ChangeAvatarEquipment(uid, AvatarData.CreateAvatarCustom(resID), false)
                pcall(function() AvatarData.RemoveRoleWearDataByValue(insID) end)
                pcall(function() av:SetCurrentWearPreview(itemSt, nil) end)
                later(0.05, function()
                    pcall(function() av:ProcessTakeOff() end)
                    syncFashionBagRolewear()
                    pcall(function()
                        local wl = require("client.slua.logic.wardrobe.logic_wardrobe_new")
                        wl:on_putdown_rsp(_K.NET_OK, { res_id = resID, instid = insID, count = 1 }, nil)
                    end)
                    if av.InitCurrentWearPreviewMap then av:InitCurrentWearPreviewMap(true) end
                end)
            end)
        end

        takeOffWeaponSkinVisual = function(weaponID, resID, insID)
            weaponID, resID, insID = tonumber(weaponID), tonumber(resID), tonumber(insID)
            if not weaponID then return end
            pcall(function()
                local Arm = require("client.logic.armory.logic_armory")
                local fbd = require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
                local HT = require("client.logic.lobby.hall_theme_utils")
                local wgl = require("client.slua.logic.wardrobe.logic_wardrobe_gun")
                -- [XTHRLEN]install_list
                if Arm.rsp_list and Arm.rsp_list.install_list then
                    Arm.rsp_list.install_list[weaponID] = nil
                end
                -- [XTHRLEN]FashionBag
                if fbd.UpdateCurrentFashionBagWeaponSkin then
                    fbd:UpdateCurrentFashionBagWeaponSkin(weaponID, 0)
                end
                local bag = fbd.GetCurrentFashionBag and fbd:GetCurrentFashionBag()
                if bag and bag.weapon_skin_list then
                    bag.weapon_skin_list[weaponID] = nil
                end

                local bagIdx = fbd:GetFashionBagUseIndex()
                HT.proc_skin_list_chg("weapon_skin", weaponID, 0, bagIdx, {})
                wgl:SetGunID(weaponID)
                if wgl.UpdateCurrentGunAvatar then
                    wgl:UpdateCurrentGunAvatar(weaponID, 0)
                end

                if EventSystem and EVENTTYPE_ARMORY and EVENTID_ARMORY_EQUIP_STAT_CHANGE then
                    EventSystem:postEvent(EVENTTYPE_ARMORY, EVENTID_ARMORY_EQUIP_STAT_CHANGE, 0)
                end
                if EventSystem and EVENTTYPE_WARDROBE and EVENTID_WARDROBE_UPDATE_CURRENT_PUT_ON_GUN then
                    EventSystem:postEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_UPDATE_CURRENT_PUT_ON_GUN, 0)
                end
                if EventSystem and EVENTID_WARDROBE_UPDATE_GUN_LIST then
                    EventSystem:postEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_UPDATE_GUN_LIST, weaponID)
                end
                log("Removing the weapon", weaponID)
            end)
        end

        local function putOnThrowObject(insID)
            insID = tonumber(insID)
            if not insID or not isInjectedIns(insID) then return end
            local resID = R.insToRes[insID]
            if not resID then return end
            local st = isThrowObjectRes(resID)
            if not st then return end
            pcall(function()
                local fbd = require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
                fbd:PutOnThrowObjectSkin(insID)
            end)
            saveThrowObject(resID, insID)
            pcall(_AutoSaveOutfit)
            log("Wearing a bomb", st, resID)
        end

        local function putOnEquipSkin(insID)
            insID = tonumber(insID)
            local resID = R.insToRes[insID]
            if not resID then return end
            local slot = getEquipSkinSlot(resID)
            if not slot then return end
            if _S.equipSkinApplying then return end
            _S.equipSkinApplying = true
            pcall(function()
                local cch = cache()
                local oldResID = cch.equip[slot]
                local oldInsID = cch.equip[slot .. "Ins"]
                ensureKnapsackExtInfo()
                local item = { res_id = resID, instid = insID, count = 1, color = 0, pattern = 0 }
                local oldItem = nil
                if oldInsID and oldInsID > 0 and oldResID and oldResID > 0 then
                    oldItem = { res_id = oldResID, instid = oldInsID, count = 1, color = 0, pattern = 0 }
                end
                local HT = require("client.logic.lobby.hall_theme_utils")
                if slot == "helmet" then
                    HT.ProcPutOnHelmet(item, oldItem)
                elseif slot == "bag" then
                    HT.ProcPutOnBagSkin(item, oldItem)
                elseif slot == "parachute" then
                    local wl = require("client.slua.logic.wardrobe.logic_wardrobe_new")
                    local lav = require("client.slua.logic.wardrobe.logic_wardrobe_avatar")
                    local origAddToWearInfo = lav.AddToWearInfo
                    lav.AddToWearInfo = function(self2, subType, ...)
                        if tonumber(subType) == 701 then return end
                        return origAddToWearInfo(self2, subType, ...)
                    end
                    pcall(function()
                        wl:on_puton_rsp(_K.NET_OK, item, oldItem, 1, insID, 0)
                    end)
                    lav.AddToWearInfo = origAddToWearInfo
                elseif slot == "glider" then
                    local wl = require("client.slua.logic.wardrobe.logic_wardrobe_new")
                    local lav = require("client.slua.logic.wardrobe.logic_wardrobe_avatar")
                    local origAddToWearInfo = lav.AddToWearInfo
                    lav.AddToWearInfo = function(self2, subType, ...)
                        local st = tonumber(subType)
                        if st == 413 or st == 414 or st == 415 then return end
                        return origAddToWearInfo(self2, subType, ...)
                    end
                    pcall(function()
                        wl:on_puton_rsp(_K.NET_OK, item, oldItem, 1, insID, 0)
                    end)
                    lav.AddToWearInfo = origAddToWearInfo
                else
                    local wl = require("client.slua.logic.wardrobe.logic_wardrobe_new")
                    wl:on_puton_rsp(_K.NET_OK, item, oldItem, 1, insID, 0)
                end
                saveEquipSkin(resID, insID)
                if oldResID and oldResID > 0 and oldResID ~= resID then
                    softRemoveEquipVisual(oldResID, slot)
                end

                if slot ~= "parachute" and slot ~= "glider" then
                    applyEquipVisual(resID, insID, slot)
                end
                invalidateSocialWearCache()
                log("Putting on gear", slot, resID)
            end)
            _S.equipSkinApplying = false
        end

        local function putOnCloth(insID)
            insID = tonumber(insID)
            local resID = R.insToRes[insID]
            if not resID then return end
            local wd = require("client.slua.logic.wardrobe.wardrobe_data")
            local d = wd:GetHallDepotItemDataByInsID(insID)
            if not d then return end

            local kind = getClothKind(resID, d)
            if not kind then return end

            local cch = cache()
            local switchingFromSuit = (kind ~= "full_suit") and cch.outfitRes and isFullSuitRes(cch.outfitRes)
            local switchingToSuit = (kind == "full_suit") and not cch.outfitRes and next(cch.clothes) ~= nil

            local clearMap
            if switchingFromSuit then
                clearMap = FULL_SUIT_CLEAR_ST
            else
                clearMap = subTypesToClearForKind(kind)
            end
            if not clearMap then return end

            local itemSt = subType(cfg(resID)) or _K.ST_TOP

            local function doPutOn()
                local oldIns, oldRes = findWornInsBySubType(itemSt)
                removeRoleWearBySubTypes(clearMap)
                clearFashionBagSlots(clearMap)
                saveEquip(resID, insID)

                local slot = _K.PKG_SLOT
                pcall(function()
                    local wfu = require("client.slua.logic.wardrobe.fashionbag.wardrobe_fashion_utils")
                    local idx = wfu.GetRoleWearIndexBySubType and wfu:GetRoleWearIndexBySubType(itemSt)
                    if idx then slot = idx end
                end)

                local olditem
                if oldIns and oldIns ~= insID then
                    olditem = { res_id = oldRes or R.insToRes[oldIns], count = 1, instid = oldIns }
                end

                local WRH = require("client.network.Protocol.WardRobeHandler")
                local item = { res_id = resID, count = 1, instid = insID }
                WRH.on_depot_put_on_rsp(_K.NET_OK, item, olditem, slot, insID, oldIns or 0)

                pcall(function()
                    local av = require("client.slua.logic.wardrobe.logic_wardrobe_avatar")
                    av:AddToWearInfo(itemSt, insID, resID, 0, 0)
                    local displayResID = resID
                    local LogicXSuit = require("client.slua.logic.XSuit.logic_xsuit")
                    if LogicXSuit.IsXSuit(displayResID) then
                        displayResID = LogicXSuit.GetItemShowID(insID) or displayResID
                    end
                    av:AvatarChange(displayResID, true, 0, 0)
                    later(0.05, function()
                        pcall(function() av:ProcessTakeOff() end)
                        syncFashionBagRolewear()
                    end)
                end)
                log("clothes", kind, resID)
            end

            if switchingFromSuit then
                local suitRes = cch.outfitRes
                local suitIns = cch.outfitIns
                cch.outfitRes, cch.outfitIns = nil, nil
                _G.AddOutfitLastLobbyOutfitRes = nil
                if suitRes and suitIns then
                    pcall(function() takeOffClothVisual(suitRes, suitIns, "full_suit") end)
                    later(0.15, doPutOn)
                else
                    doPutOn()
                end
            elseif switchingToSuit then
                local toTakeOff = {}
                for clothRes in pairs(cch.clothes) do
                    local clothIns = R.resToIns[clothRes]
                    local clothKind = getClothKind(clothRes)
                    if clothIns and clothKind then
                        toTakeOff[#toTakeOff + 1] = { resID = clothRes, insID = clothIns, kind = clothKind }
                    end
                end
                for _, c in ipairs(toTakeOff) do
                    cch.clothes[c.resID] = nil
                    pcall(function() takeOffClothVisual(c.resID, c.insID, c.kind) end)
                end
                later(0.15, doPutOn)
            else
                doPutOn()
            end
        end

        local function equipWeaponSkin(weaponID, insID)
            weaponID, insID = tonumber(weaponID), tonumber(insID)
            if not weaponID or not insID or not isInjectedIns(insID) then return end
            local resID = R.insToRes[insID]
            saveEquip(resID, insID)

            local Arm = require("client.logic.armory.logic_armory")
            local fbd = require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
            local HT = require("client.logic.lobby.hall_theme_utils")
            local wgl = require("client.slua.logic.wardrobe.logic_wardrobe_gun")

            injectArmory(resID, insID)
            Arm.rsp_list.install_list = Arm.rsp_list.install_list or {}
            Arm.rsp_list.install_list[weaponID] = { skin_id = insID }
            if fbd.UpdateCurrentFashionBagWeaponSkin then
                fbd:UpdateCurrentFashionBagWeaponSkin(weaponID, insID)
            end

            local bagIdx = fbd:GetFashionBagUseIndex()
            HT.proc_skin_list_chg("weapon_skin", weaponID, insID, bagIdx, {})

            wgl:SetGunID(weaponID)
            wgl:UpdateCurrentGunAvatar(weaponID, insID)

            if EventSystem and EVENTTYPE_ARMORY and EVENTID_ARMORY_EQUIP_STAT_CHANGE then
                EventSystem:postEvent(EVENTTYPE_ARMORY, EVENTID_ARMORY_EQUIP_STAT_CHANGE, resID)
            end
            if EventSystem and EVENTTYPE_WARDROBE and EVENTID_WARDROBE_UPDATE_CURRENT_PUT_ON_GUN then
                EventSystem:postEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_UPDATE_CURRENT_PUT_ON_GUN, resID)
            end
            log("Weapon Housing", weaponID, resID, insID)
        end

        local function putOnHallTheme(insID)
            insID = tonumber(insID)
            if not insID or not isInjectedIns(insID) then return end
            local resID = R.insToRes[insID]
            if not resID or not isHallThemeRes(resID) then return end
            local item = { res_id = resID, count = 1, instid = insID }
            pcall(function()
                local wl = require("client.slua.logic.wardrobe.logic_wardrobe_new")
                wl:on_puton_rsp(_K.NET_OK, item, nil, 1, insID, 0)
            end)
            pcall(_AutoSaveOutfit)
            log("Theme Loop", resID, insID)
        end

        local function restorePersistedHallTheme()
            if not _G._addOutfitPersistLoaded then return end
            local ins = tonumber(_G._savedHallThemeIns)
            if not ins or ins <= 0 then return end
            later(2.5, function()
                if isInjectedIns(ins) then putOnHallTheme(ins) end
            end)
        end

        local SOCIAL = _G.AddOutfitSocialState or {}
        _G.AddOutfitSocialState = SOCIAL
        SOCIAL.debGen = SOCIAL.debGen or 0

        local function socialDebounce(sec, fn)
            SOCIAL.debGen = (SOCIAL.debGen or 0) + 1
            local gen = SOCIAL.debGen
            later(sec, function()
                if gen ~= SOCIAL.debGen then return end
                pcall(fn)
            end)
        end

        local function getLobbyCurPage()
            local p = nil
            pcall(function()
                local LMC = require("client.slua.logic.lobby.Main.Lobby_Main_Control")
                if LMC.GetCurPage then p = LMC.GetCurPage() end
            end)
            return p
        end

        local function getWeaponSkinResFast()
            local cch = cache()
            local wid = tonumber(DataMgr.Weapon_ID) or 0
            local w = wid > 0 and cch.weapons[wid] or nil
            if w and w.resID and w.resID > 0 then return w.resID end
            for _, ww in pairs(cch.weapons) do
                if ww.resID and ww.resID > 0 then return ww.resID end
            end
            return nil
        end

        local function resolveLobbyWeaponSkinRes()
            local wid = tonumber(DataMgr.Weapon_ID) or 0
            local skin = getWeaponSkinResFast()
            if skin and skin > 0 then return skin end
            if wid > 0 then
                local fromMatch = getMatchWeaponSkin(wid)
                if fromMatch and fromMatch > 0 then return fromMatch end
            end
            return nil
        end

        local function rememberLobbyOutfitRes(resID)
            resID = tonumber(resID)
            if not resID or resID <= 0 or not isFullSuitRes(resID) then return end
            _G.AddOutfitLastLobbyOutfitRes = resID
            local cch = cache()
            if not cch.outfitRes or cch.outfitRes <= 0 then
                cch.outfitRes = resID
                if isInjectedRes(resID) then cch.outfitIns = R.resToIns[resID] end
            end
        end

        local function resolveLobbyOutfitRes()
            local cch = cache()
            if tonumber(cch.outfitRes) and cch.outfitRes > 0 then return cch.outfitRes end
            if tonumber(_G.AddOutfitLastLobbyOutfitRes) and _G.AddOutfitLastLobbyOutfitRes > 0 then
                return tonumber(_G.AddOutfitLastLobbyOutfitRes)
            end
            if MATCH_CONFIG.outfitRes and tonumber(MATCH_CONFIG.outfitRes) > 0 then
                return tonumber(MATCH_CONFIG.outfitRes)
            end
            for resID in pairs(cch.clothes) do
                if isFullSuitRes(resID) then return resID end
            end
            return nil
        end

        local function collectAllClothResIDs()
            local ids = {}
            local cch = cache()
            if tonumber(cch.outfitRes) and cch.outfitRes > 0 then
                ids[cch.outfitRes] = true
            end
            for resID in pairs(cch.clothes) do
                if not getEquipSkinSlot(resID) and not weaponIdFromSkin(resID) then
                    ids[resID] = true
                end
            end
            return ids
        end

        local function wearPatchKey()
            local outfit = resolveLobbyOutfitRes() or 0
            local skin = resolveLobbyWeaponSkinRes() or 0
            local cch = cache()
            local eq = (cch.equip.bag or 0) .. "_" .. (cch.equip.helmet or 0)
            return outfit .. "_" .. skin .. "_" .. eq
        end

        local function applyInjectedPspace(roleData)
            if not roleData then return end
            roleData.bshow = true
            roleData.pspace_wear_ext = roleData.pspace_wear_ext or {}
            local outfitRes = resolveLobbyOutfitRes()
            if outfitRes and outfitRes > 0 then
                roleData.pspace_wear_ext[ENUM_AVATAR_SHOW_TYPE.SHOW_POS_CLOTH] = { outfitRes, 0, 0 }
            end
            local skinRes = resolveLobbyWeaponSkinRes()
            if skinRes and skinRes > 0 then
                roleData.pspace_wear_ext[ENUM_AVATAR_SHOW_TYPE.SHOW_POS_WEAPON] = { 0, 0, 0 }
                roleData.pspace_wear_ext[ENUM_AVATAR_SHOW_TYPE.SHOW_POS_WEAPONSKIN] = { skinRes, 0, 0 }
                roleData.depot_show_info = roleData.depot_show_info or {}
                if roleData.depot_show_info.weapon == nil then roleData.depot_show_info.weapon = true end
            end
        end

        local function patchSelfWearCache(force)
            local key = wearPatchKey()
            if not force and SOCIAL.wearPatchKey == key then return false end
            SOCIAL.wearPatchKey = key
            local myUid = tonumber(DataMgr.roleData.uid)
            if not myUid then return false end
            pcall(function()
                local BD = ModuleManager.GetModule(ModuleManager.DataModuleConfig.BasicDataAvatarWearInfo)
                local d = BD:GetCacheData(myUid)
                if d then applyInjectedPspace(d) end
            end)
            return true
        end

        local function requestSocialAvatarRefresh()
            pcall(function()
                if EventSystem and EVENTTYPE_LOBBY_SOCIAL and EVENTID_SOCIAL_LOBBY_REFRESH_AVATAR then
                    EventSystem:postEvent(EVENTTYPE_LOBBY_SOCIAL, EVENTID_SOCIAL_LOBBY_REFRESH_AVATAR)
                end
            end)
        end

        local function onSocialWearDirty(forceRefresh)
            SOCIAL.lastHandSkin = nil
            if patchSelfWearCache(forceRefresh) then requestSocialAvatarRefresh() end
        end

        local _myUidCached
        local function isMyWearData(wearData)
            if not wearData then return false end
            if not _myUidCached then
                pcall(function() _myUidCached = tonumber(DataMgr.roleData.uid) end)
            end
            return _myUidCached and tonumber(wearData.uid) == _myUidCached
        end

        local function mergeInjectedWeaponIntoWearData(wearData)
            if not isMyWearData(wearData) then return end
            local cch = cache()
            local wKey = ""
            for wid, w in pairs(cch.weapons) do wKey = wKey .. wid .. ":" .. (w.resID or 0) .. "," end
            wKey = wKey .. "|" .. tostring(DataMgr.Weapon_ID or 0)
            local skinRes
            if _weaponSkinResMergeCache.key == wKey then
                skinRes = _weaponSkinResMergeCache.res
            else
                skinRes = resolveLobbyWeaponSkinRes()
                _weaponSkinResMergeCache.key = wKey
                _weaponSkinResMergeCache.res = skinRes
            end
            if not skinRes or skinRes <= 0 then return end
            wearData.mainWeaponInfo = wearData.mainWeaponInfo or {
                weaponResId = 0, weaponSkinId = 0,
                diyInfo = { diyWeaponId = 0, diyDefaultScheme = false, diyScheme = nil },
            }
            wearData.mainWeaponInfo.weaponSkinId = skinRes
            wearData.mainWeaponInfo.weaponResId = 0
        end

        local function getOutfitMergeItems()
            local cch = cache()
            local clothKey = ""
            for resID in pairs(cch.clothes) do clothKey = clothKey .. resID .. "," end
            local key = (cch.outfitRes or 0) .. "_" .. clothKey .. "_" .. (cch.equip.bag or 0) .. "_" .. (cch.equip.helmet or 0)
            if _outfitMergeCache.key == key and _outfitMergeCache.items then
                return _outfitMergeCache.items
            end
            local outfitRes = resolveLobbyOutfitRes()
            local AvatarData = require("client.logic.data.AvatarData")
            local items = {}
            if outfitRes and outfitRes > 0 and isFullSuitRes(outfitRes) then
                rememberLobbyOutfitRes(outfitRes)
                local converted = AvatarData.ConvertToAvatarCustom({ outfitRes, 0, 0 })
                if converted then items[#items + 1] = converted end
                for resID in pairs(collectAllClothResIDs()) do
                    if resID ~= outfitRes and not isFullSuitRes(resID)
                        and not isBodyClothSubType(subType(cfg(resID))) then
                        local cv = AvatarData.ConvertToAvatarCustom({ resID, 0, 0 })
                        if cv then items[#items + 1] = cv end
                    end
                end
            else
                for resID in pairs(collectAllClothResIDs()) do
                    if not isFullSuitRes(resID) then
                        local converted = AvatarData.ConvertToAvatarCustom({ resID, 0, 0 })
                        if converted then items[#items + 1] = converted end
                    end
                end
            end
            _outfitMergeCache.key = key
            _outfitMergeCache.items = items
            return items
        end

        local function mergeInjectedOutfitIntoWearData(wearData)
            if not isMyWearData(wearData) then return end
            local outfitRes = resolveLobbyOutfitRes()
            local items = getOutfitMergeItems()
            if #items == 0 then return end
            if outfitRes and outfitRes > 0 and isFullSuitRes(outfitRes) then
                local newList = {}
                for _, e in ipairs(wearData.WearInfoList or {}) do
                    if not (e and e.ItemID and isBodyClothSubType(subType(cfg(e.ItemID)))) then
                        newList[#newList + 1] = e
                    end
                end
                for _, item in ipairs(items) do
                    newList[#newList + 1] = item
                end
                wearData.WearInfoList = newList
            else
                wearData.WearInfoList = wearData.WearInfoList or {}
                for _, item in ipairs(items) do
                    wearData.WearInfoList[#wearData.WearInfoList + 1] = item
                end
            end
        end

        local function mergeInjectedEquipIntoWearData(wearData)
            if not isMyWearData(wearData) then return end
            local cch = cache()
            wearData.depot_show_info = wearData.depot_show_info or {}
            if cch.equip.bag and cch.equip.bag > 0 then
                local catalogBag = normalizeEquipCatalogRes(cch.equip.bag)
                local bagLevel = getEquipDisplayLevel(cch.equip.bag, "bag")
                wearData.depot_show_info.bag = true
                wearData.bagSkinInsId = mapEquipSkinRes(catalogBag, bagLevel)
                wearData.skin_info = wearData.skin_info or {}
                wearData.skin_info.bag_skin = cch.equip.bagIns or R.resToIns[cch.equip.bag] or cch.equip.bag
                wearData.skin_info.bag_level = bagLevel
            end
            if cch.equip.helmet and cch.equip.helmet > 0 then
                local catalogHelm = normalizeEquipCatalogRes(cch.equip.helmet)
                local helmLevel = getEquipDisplayLevel(cch.equip.helmet, "helmet")
                local helmDisplay = mapEquipSkinRes(catalogHelm, helmLevel)
                wearData.depot_show_info.helmet = true
                wearData.helmet_skin = helmDisplay
                wearData.headShow = helmDisplay
                wearData.skin_info = wearData.skin_info or {}
                wearData.skin_info.helmet_skin = cch.equip.helmetIns or R.resToIns[cch.equip.helmet] or cch.equip.helmet
                wearData.skin_info.head_show = wearData.skin_info.helmet_skin
                wearData.skin_info.helmet_level = helmLevel
            end
        end

        local function mergeInjectedIntoWearData(wearData)
            if not wearData then return end
            mergeInjectedWeaponIntoWearData(wearData)
            mergeInjectedOutfitIntoWearData(wearData)
            mergeInjectedEquipIntoWearData(wearData)
        end

        local function reapplyAccessoryIns(insID)
            insID = tonumber(insID)
            local resID = R.insToRes[insID]
            if not resID then return end
            local c = cfg(resID)
            local st = subType(c)
            saveClothPiece(resID)
            local itemSt = st
            local oldIns, oldRes
            if itemSt then
                oldIns, oldRes = findWornInsBySubType(itemSt)
                if oldIns == insID then oldIns, oldRes = nil, nil end
                removeRoleWearBySubTypes({ [itemSt] = true })
            end
            local WRH = require("client.network.Protocol.WardRobeHandler")
            local olditem
            if oldIns then
                olditem = { res_id = oldRes or R.insToRes[oldIns], count = 1, instid = oldIns }
            end
            WRH.on_depot_put_on_rsp(_K.NET_OK, { res_id = resID, count = 1, instid = insID }, olditem, 1, insID, oldIns or 0)
            pcall(function()
                local av = require("client.slua.logic.wardrobe.logic_wardrobe_avatar")
                if oldIns and itemSt then av:SetCurrentWearPreview(itemSt, nil) end
                if itemSt then av:AddToWearInfo(itemSt, insID, resID, 0, 0) end
                av:AvatarChange(resID, true, 0, 0)
                av:ProcessTakeOff()
                syncFashionBagRolewear()
            end)
        end

        local function reapplyInjectedIns(insID)
            insID = tonumber(insID)
            if not insID or not isInjectedIns(insID) then return end
            local resID = R.insToRes[insID]
            if not resID then return end
            if isHallThemeRes(resID) then
                putOnHallTheme(insID)
            elseif getEquipSkinSlot(resID) then
                putOnEquipSkin(insID)
            elseif getClothKind(resID) then
                putOnCloth(insID)
            elseif weaponIdFromSkin(resID) then
                equipWeaponSkin(weaponIdFromSkin(resID), insID)
            elseif _K.GUN_SUB[subType(cfg(resID))] then
                local cch = cache()
                local foundWid = nil
                for wid, w in pairs(cch.weapons or {}) do
                    if w.resID == resID then foundWid = wid; break end
                end
                if foundWid then equipWeaponSkin(foundWid, insID) end
            elseif subType(cfg(resID)) == _K.MELEE_ID then
                equipWeaponSkin(_K.MELEE_ID, insID)
            elseif isThrowObjectRes(resID) then
                putOnThrowObject(insID)
            else
                reapplyAccessoryIns(insID)
            end
        end

        local function reapplyLobbyEquipped()
            if not GameStatus or not GameStatus.IsInLobbyOrMainCity or not GameStatus.IsInLobbyOrMainCity() then
                return
            end
            if _S.lobbyApplied then return end
            _S.lobbyApplied = true
            later(2.0, function() _S.lobbyApplied = false end)

            restorePersistedVehicles()
            restorePersistedMotions()
            restorePersistedEquipIns()
            restorePersistedThrowObjects()
            restorePersistedHallTheme()
            syncMatchConfigFromCache()

            if not _G._addOutfitPersistLoaded then
                snapshotLobbyWear()
            end
            local cch = cache()
            if not _G._addOutfitPersistLoaded and _G._savedOutfitClothes then
                for resID in pairs(_G._savedOutfitClothes) do
                    cch.clothes[resID] = true
                end
            end
            if not _G._addOutfitPersistLoaded and _G._savedOutfitRes and (not cch.outfitRes or cch.outfitRes <= 0) then
                cch.outfitRes = _G._savedOutfitRes
                cch.outfitIns = _G._savedOutfitIns or R.resToIns[_G._savedOutfitRes]
            end
            syncMatchConfigFromCache()

            local applyStep = 0
            local function scheduleApply(fn)
                applyStep = applyStep + 1
                later(applyStep * 0.12, fn)
            end

            if not _G._addOutfitPersistLoaded and _G._savedRoleWearList and #_G._savedRoleWearList > 0 then
                for _, insID in ipairs(_G._savedRoleWearList) do
                    local id = insID
                    scheduleApply(function() reapplyInjectedIns(id) end)
                end
            elseif cch.outfitIns and isInjectedIns(cch.outfitIns) then
                scheduleApply(function() putOnCloth(cch.outfitIns) end)
            else
                for resID in pairs(cch.clothes) do
                    local ins = R.resToIns[resID]
                    local rid = resID
                    if ins and isInjectedIns(ins) then
                        scheduleApply(function()
                            if getClothKind(rid) then
                                putOnCloth(ins)
                            else
                                reapplyAccessoryIns(ins)
                            end
                        end)
                    end
                end
            end
            for wid, w in pairs(cch.weapons) do
                local weaponID, entry = wid, w
                scheduleApply(function()
                    if entry.insID and isInjectedIns(entry.insID) then
                        equipWeaponSkin(weaponID, entry.insID)
                    elseif entry.resID and R.resToIns[entry.resID] and isInjectedIns(R.resToIns[entry.resID]) then
                        equipWeaponSkin(weaponID, R.resToIns[entry.resID])
                    end
                end)
            end
            for _, slot in ipairs({ "bag", "helmet", "armor", "parachute", "glider" }) do
                local resID = cch.equip[slot]
                local insID = cch.equip[slot .. "Ins"]
                scheduleApply(function()
                    if insID and isInjectedIns(insID) then
                        putOnEquipSkin(insID)
                    elseif resID and R.resToIns[resID] then
                        putOnEquipSkin(R.resToIns[resID])
                    end
                end)
            end
            if cch.throwObjects then
                for st, info in pairs(cch.throwObjects) do
                    local tInfo = info
                    scheduleApply(function()
                        if tInfo.insID and isInjectedIns(tInfo.insID) then
                            putOnThrowObject(tInfo.insID)
                        elseif tInfo.resID and R.resToIns[tInfo.resID] and isInjectedIns(R.resToIns[tInfo.resID]) then
                            putOnThrowObject(R.resToIns[tInfo.resID])
                        end
                    end)
                end
            end
            later(math.max(applyStep * 0.12 + 0.3, 0.5), function()
                syncMatchConfigFromCache()
                pcall(_AutoSaveOutfit, true)
            end)

            pcall(function()
                if _G._addOutfitPersistLoaded then return end
                local GTS = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.GarageThemeSystem)
                if not GTS then return end
                local maxSlots = GTS:GetMaxPositionNum()
                GTS.GarageVehicleInfo = GTS.GarageVehicleInfo or {}
                local usedIns = {}
                for slot, info in pairs(GTS.GarageVehicleInfo) do
                    if info and info.inst_id then
                        usedIns[tonumber(info.inst_id)] = true
                    end
                end
                local changed = false
                for slot = 1, maxSlots do
                    if not GTS.GarageVehicleInfo[slot] then
                        for _, resID in ipairs(_C.vehicleItems) do
                            if isInjectedRes(resID) then
                                local insID = R.resToIns[resID]
                                if insID and not usedIns[insID] then
                                    GTS.GarageVehicleInfo[slot] = { inst_id = insID, res_id = resID }
                                    usedIns[insID] = true
                                    changed = true
                                    break
                                end
                            end
                        end
                    end
                end
                if changed then
                    if EventSystem and EVENTTYPE_LOBBY_THEME and EVENTID_GARAGE_VEHICLE_DATA_CHANGE then
                        EventSystem:postEvent(EVENTTYPE_LOBBY_THEME, EVENTID_GARAGE_VEHICLE_DATA_CHANGE)
                    end
                end
            end)
        end

        local function initHooks()
        local function hookLobbySwipePersistence()
            pcall(function()
                local AC = require("client.slua.logic.avatar.avatar_common")
                local oGetWear = AC.GetWearDataFromRoleData
                AC.GetWearDataFromRoleData = function(roleData)
                    local wearData = oGetWear(roleData)
                    if wearData and roleData and tonumber(roleData.uid) == tonumber(DataMgr.roleData.uid) then
                        mergeInjectedIntoWearData(wearData)
                    end
                    return wearData
                end
                local oUp = AC.UpdateAvatar
                AC.UpdateAvatar = function(avatar, wearData, isShowWeapon, isShowHelmet, isShowBag)
                    if isMyWearData(wearData) then mergeInjectedIntoWearData(wearData) end
                    return oUp(avatar, wearData, isShowWeapon, isShowHelmet, isShowBag)
                end
            end)
            pcall(function()
                if EventSystem and EventSystem.registEvent and EVENTTYPE_LOBBY and EVENTID_SWITCHTO_PAGE_END then
                    EventSystem:registEvent(EVENTTYPE_LOBBY, EVENTID_SWITCHTO_PAGE_END, function(_, _, _, toPage)
                        if ENUM_LobbyPageType and toPage == ENUM_LobbyPageType.Mid then
                            socialDebounce(0.5, reapplyLobbyEquipped)
                        end
                    end)
                end
            end)
        end

        local function hookCDataTableCache()
            pcall(function()
                if not CDataTable or CDataTable._lava_cached then return end
                CDataTable._lava_cached = true
                local origGetTableData = CDataTable.GetTableData
                CDataTable.GetTableData = function(tableName, resID, ...)
                    if tableName == "Item" then
                        resID = tonumber(resID)
                        if resID and _C.cfg[resID] ~= nil then
                            return _C.cfg[resID]
                        end
                        local result = origGetTableData(tableName, resID, ...)
                        if resID then
                            _C.cfg[resID] = result
                        end
                        return result
                    end
                    return origGetTableData(tableName, resID, ...)
                end
            end)
        end

        local function hookDepotInit()
            pcall(function()
                local WDE = require("client.slua.logic.wardrobe.WardrobeDataEntity")
                local orig = WDE.InitData
                WDE.InitData = function(self, pkg)
                    orig(self, pkg)
                    injectAll(self)
                    refreshWardrobe()
                end
            end)
        end

        local function hookWardrobeData()
            pcall(function()
                local wd = require("client.slua.logic.wardrobe.wardrobe_data")
                local function wrapGet(name)
                    local o = wd[name]
                    if not o then return end
                    wd[name] = function(self, insID, ...)
                        insID = tonumber(insID)
                        if isInjectedIns(insID) then
                            local e = getEntity()
                            if e then return e:GetDataByInsID(insID) end
                        end
                        return o(self, insID, ...)
                    end
                end
                wrapGet("GetHallDepotItemDataByInsID")
                wrapGet("GetValidHallDepotItemDataByInsID")
                local function wrapBool(name)
                    local o = wd[name]
                    if not o then return end
                    wd[name] = function(self, id, ...)
                        if isInjectedRes(tonumber(id)) or isInjectedIns(tonumber(id)) then return true end
                        return o(self, id, ...)
                    end
                end
                wrapBool("HasItem")
                wrapBool("HasValidItem")
                wrapBool("CheckHasPermanentItem")
                if not wd._lava_global_equip then
                    wd._lava_global_equip = true
                    local origGetEquipped = wd.GetEquippedSkinIDByWeaponID
                    wd.GetEquippedSkinIDByWeaponID = function(self, weaponID)
                        local w = cache().weapons[tonumber(weaponID)]
                        if w and w.resID and w.resID > 0 then return w.resID end
                        return origGetEquipped(self, weaponID)
                    end
                end
                if not wd._lava_global_equip_ins then
                    wd._lava_global_equip_ins = true
                    if wd.GetEquippedSkinInsIDByWeaponID then
                        local origGetEquippedIns = wd.GetEquippedSkinInsIDByWeaponID
                        wd.GetEquippedSkinInsIDByWeaponID = function(self, weaponID)
                            local w = cache().weapons[tonumber(weaponID)]
                            if w and w.insID and w.insID > 0 and isInjectedIns(w.insID) then return w.insID end
                            return origGetEquippedIns(self, weaponID)
                        end
                    end
                    if wd.GetWeaponSkinInsID then
                        local origGetWSI = wd.GetWeaponSkinInsID
                        wd.GetWeaponSkinInsID = function(self, weaponID)
                            local w = cache().weapons[tonumber(weaponID)]
                            if w and w.insID and w.insID > 0 and isInjectedIns(w.insID) then return w.insID end
                            return origGetWSI(self, weaponID)
                        end
                    end
                end
            end)
            pcall(function()
                local wl = require("client.slua.logic.wardrobe.logic_wardrobe_new")
                local oPutDownReq = wl.wardrobe_put_down_req
                if oPutDownReq then
                    wl.wardrobe_put_down_req = function(self, ins_id, unequip_by_server)
                        ins_id = tonumber(ins_id)
                        if isInjectedIns(ins_id) then
                            local resID = R.insToRes[ins_id]
                            takeOffItem(ins_id)
                            pcall(function()
                                self:on_putdown_rsp(_K.NET_OK, {
                                    instid = ins_id,
                                    res_id = resID or 0,
                                }, nil)
                            end)
                            pcall(function()
                                if EventSystem and EVENTTYPE_WARDROBE and EVENTID_WARDROBE_UPDATE_PUT_DOWN_DATA then
                                    EventSystem:postEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_UPDATE_PUT_DOWN_DATA, {
                                        instid = ins_id,
                                        res_id = resID or 0,
                                        count = 1,
                                    })
                                end
                            end)
                            refreshWardrobe()
                            return
                        end
                        return oPutDownReq(self, ins_id, unequip_by_server)
                    end
                end
            end)
        end

        local function hookPageFilter()
            pcall(function()
                local SubTab = require("client.slua.umg.Wardrobe.subtab_item_list_base")
                if SubTab._lava_prefilter then return end
                SubTab._lava_prefilter = true
                local origGet = SubTab.GetArrayHallDepotItemInfo
                SubTab.GetArrayHallDepotItemInfo = function(self)
                    local allData = origGet(self)
                    if not allData or not next(allData) then return allData end
                    local pageId = self.subTabConfig and self.subTabConfig.pageId
                    local subTabId = self.subTabConfig and self.subTabConfig.subTabId
                    if not pageId or not subTabId then return allData end
                    local result = {}
                    for _, data in pairs(allData) do
                        local resID = depotResID(data)
                        if resID and isInjectedRes(resID) then
                            local itemMain, itemSub = getInjectedItemTab(resID, data)
                            if itemMain == pageId then
                                if pageId == _K.WARDROBE_PAGE_AVATAR then
                                    if subTabId == _K.WARDROBE_TAB_SUIT or subTabId == _K.WARDROBE_TAB_CLOTHES then
                                        local st = data.itemSubType or subType(cfg(resID))
                                        if st == _K.ST_TOP then
                                            local full = isFullSuitRes(resID, data)
                                            if (subTabId == _K.WARDROBE_TAB_SUIT and full) or
                                            (subTabId == _K.WARDROBE_TAB_CLOTHES and not full) then
                                                result[#result + 1] = data
                                            end
                                        end
                                    elseif itemSub == subTabId then
                                        result[#result + 1] = data
                                    end
                                elseif itemSub == subTabId then
                                    result[#result + 1] = data
                                end
                            end
                        else
                            result[#result + 1] = data
                        end
                    end
                    return result
                end
            end)
            pcall(function()
                local wl = require("client.slua.logic.wardrobe.logic_wardrobe_new")
                local o1 = wl.IsValidCurrentPageItem
                wl.IsValidCurrentPageItem = function(self, mainTab, subTab, v, t)
                    local resID = depotResID(v)
                    if resID and isInjectedRes(resID) then
                        local cacheKey = resID .. "_" .. mainTab .. "_" .. subTab
                        if _C.pageMatch[cacheKey] ~= nil then
                            return _C.pageMatch[cacheKey]
                        end
                        local result
                        if not (v.expireTS == 0 or not t or t < v.expireTS) then
                            result = false
                        else
                            local equipOk = injectedEquipAllowed(resID, mainTab, subTab)
                            if equipOk ~= nil then
                                result = equipOk
                            elseif weaponIdFromSkin(resID) then
                                result = mainTab == _K.WARDROBE_PAGE_WEAPON and subTab == _K.WARDROBE_TAB_GUN
                            elseif mainTab == _K.WARDROBE_PAGE_VEHICLE then
                                local c = cfg(resID)
                                local wmTab = c and tonumber(c.WardrobeMainTab or c.wardrobeMainTab) or 0
                                if wmTab ~= mainTab and v.mainTabType ~= mainTab then
                                    result = false
                                else
                                    local wTab = c and tonumber(c.WardrobeTab or c.wardrobeTab) or nil
                                    local vTab = v.subTabType and tonumber(v.subTabType) or nil
                                    if wTab and wTab == subTab then result = true
                                    elseif vTab and vTab == subTab then result = true
                                    else result = o1(self, mainTab, subTab, v, t) end
                                end
                            elseif mainTab == _K.WARDROBE_PAGE_AVATAR then
                                local st = v.itemSubType or subType(cfg(resID))
                                if st == _K.ST_TOP then
                                    local full = isFullSuitRes(resID, v)
                                    if subTab == _K.WARDROBE_TAB_SUIT and full then result = true
                                    elseif subTab == _K.WARDROBE_TAB_CLOTHES and not full then result = true
                                    else result = false end
                                elseif st == _K.ST_PANTS and subTab == _K.WARDROBE_TAB_TROUSERS then
                                    result = true
                                elseif st == _K.ST_SHOES and subTab == _K.WARDROBE_TAB_SHOES then
                                    result = true
                                elseif v.subTabType == subTab then
                                    result = true
                                else
                                    result = false
                                end
                            else
                                result = o1(self, mainTab, subTab, v, t)
                            end
                        end
                        _C.pageMatch[cacheKey] = result
                        return result
                    end
                    return o1(self, mainTab, subTab, v, t)
                end
                local o2 = wl.IsCanUse
                wl.IsCanUse = function(self, resId)
                    if isInjectedRes(resId) then return true end
                    return o2(self, resId)
                end
                local o4 = wl.GetWardrobeInsIdByResId
                wl.GetWardrobeInsIdByResId = function(self, resid)
                    resid = tonumber(resid)
                    if isInjectedRes(resid) then return R.resToIns[resid] end
                    return o4(self, resid)
                end
            end)
        end

        local function hookArmory()
            pcall(function()
                local Arm = require("client.logic.armory.logic_armory")
                if not Arm._lava_global_own then
                    Arm._lava_global_own = true
                    local origIsOwn = Arm.IsSkinOwn
                    Arm.IsSkinOwn = function(weaponID, skinID)
                        if isInjectedRes(skinID) then return 1 end
                        return origIsOwn(weaponID, skinID)
                    end
                end
                if not Arm._lava_global_get_install then
                    Arm._lava_global_get_install = true
                    if Arm.get_install_skin then
                        local origGetInstall = Arm.get_install_skin
                        Arm.get_install_skin = function(weaponID)
                            local w = cache().weapons[tonumber(weaponID)]
                            if w and w.insID and w.insID > 0 and isInjectedIns(w.insID) then
                                return { skin_id = w.insID }
                            end
                            return origGetInstall(weaponID)
                        end
                    end
                    if Arm.GetInstallSkinInsID then
                        local origGetInstall2 = Arm.GetInstallSkinInsID
                        Arm.GetInstallSkinInsID = function(weaponID)
                            local w = cache().weapons[tonumber(weaponID)]
                            if w and w.insID and w.insID > 0 and isInjectedIns(w.insID) then
                                return w.insID
                            end
                            return origGetInstall2(weaponID)
                        end
                    end
                end
                local oi = Arm.install_weapon_skin
                Arm.install_weapon_skin = function(cd, wid, ins)
                    ins = tonumber(ins)
                    if isInjectedIns(ins) then
                        wid = tonumber(weaponIdFromSkin(R.insToRes[ins]) or wid)
                        equipWeaponSkin(wid, ins)
                        return
                    end
                    return oi(cd, wid, ins)
                end
                local function hookArmoryUninstall(fnName)
                    local orig = Arm[fnName]
                    if not orig then return end
                    Arm[fnName] = function(cd, wid, ins, ...)
                        ins = tonumber(ins)
                        wid = tonumber(wid)
                        if ins and isInjectedIns(ins) then
                            local resID = R.insToRes[ins]
                            wid = weaponIdFromSkin(resID) or wid
                            if takeOffItem(ins) then
                                refreshWardrobe()
                                return
                            end
                        elseif wid and wid > 0 then
                            local cch = cache()
                            local w = cch.weapons[wid]
                            if w and w.insID and isInjectedIns(w.insID) then
                                if takeOffItem(w.insID) then
                                    refreshWardrobe()
                                    return
                                end
                            end
                        end
                        return orig(cd, wid, ins, ...)
                    end
                end
                hookArmoryUninstall("uninstall_weapon_skin")
                hookArmoryUninstall("remove_weapon_skin")
            end)
        end

        local function hookLobbyTheme()
            pcall(function()
                local wl = require("client.slua.logic.wardrobe.logic_wardrobe_new")
                if wl._lava_hooked_hall_theme then return end
                wl._lava_hooked_hall_theme = true
                local origPutOn = wl.wardrobe_puton_req
                wl.wardrobe_puton_req = function(self, insID, extra)
                    insID = tonumber(insID)
                    if insID and isInjectedIns(insID) and isHallThemeRes(R.insToRes[insID]) then
                        putOnHallTheme(insID)
                        return
                    end
                    return origPutOn(self, insID, extra)
                end
            end)
        end

        local function hookPutOn()
            pcall(function()
                local WRH = require("client.network.Protocol.WardRobeHandler")
                local o = WRH.send_depot_put_on_req
                WRH.send_depot_put_on_req = function(insID, extra)
                    insID = tonumber(insID)
                    if isInjectedIns(insID) then
                        local resID = R.insToRes[insID]
                        local c = cfg(resID)
                        local st = subType(c)
                        if getEquipSkinSlot(resID) then
                            putOnEquipSkin(insID)
                            return
                        end
                        if getClothKind(resID) then
                            putOnCloth(insID)
                            return
                        end
                        if _K.GUN_SUB[st] then
                            local wid = weaponIdFromSkin(resID)
                            if not wid then
                                pcall(function()
                                    local wgl = require("client.slua.logic.wardrobe.logic_wardrobe_gun")
                                    wid = wgl.GetCurGunID and wgl:GetCurGunID() or nil
                                    if not wid and wgl.GetCurrentGunID then
                                        wid = wgl:GetCurrentGunID()
                                    end
                                end)
                            end
                            if wid then equipWeaponSkin(wid, insID) end
                            return
                        end
                        if st == _K.MELEE_ID then
                            equipWeaponSkin(_K.MELEE_ID, insID)
                            return
                        end
                        if isHallThemeRes(resID) then
                            putOnHallTheme(insID)
                            return
                        end
                        if isThrowObjectRes(resID) then
                            local st = isThrowObjectRes(resID)
                            local cch = cache()
                            local oldThrow = cch.throwObjects and cch.throwObjects[st]
                            local oldInsID = oldThrow and oldThrow.insID or 0
                            local oldResID = oldThrow and oldThrow.resID or 0
                            putOnThrowObject(insID)
                            local fbd = require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
                            local bagIndex = fbd:GetFashionBagUseIndex()
                            local olditem
                            if oldInsID and oldInsID ~= insID and oldInsID ~= 0 then
                                olditem = { res_id = oldResID, count = 1, instid = oldInsID }
                            end
                            WRH.on_depot_put_on_rsp(_K.NET_OK, { res_id = resID, count = 1, instid = insID }, olditem, bagIndex, insID, oldInsID, extra)
                            return
                        end
                        local mainTab = wardrobeMainTab(resID)
                        if mainTab == _K.WARDROBE_PAGE_VEHICLE then
                            local item = { res_id = resID, count = 1, instid = insID }
                            WRH.on_depot_put_on_rsp(_K.NET_OK, item, nil, 1, insID, 0, extra)
                            return
                        end
                        local wd = require("client.slua.logic.wardrobe.wardrobe_data")
                        if wd:GetHallDepotItemDataByInsID(insID) then
                            local itemSt = st or subType(cfg(resID))
                            local oldIns, oldRes
                            if itemSt then
                                oldIns, oldRes = findWornInsBySubType(itemSt)
                                if oldIns == insID then oldIns, oldRes = nil, nil end
                                removeRoleWearBySubTypes({ [itemSt] = true })
                            end
                            saveClothPiece(resID)
                            local olditem
                            if oldIns then
                                olditem = { res_id = oldRes or R.insToRes[oldIns], count = 1, instid = oldIns }
                            end
                            WRH.on_depot_put_on_rsp(_K.NET_OK, { res_id = resID, count = 1, instid = insID }, olditem, 1, insID, oldIns or 0, extra)
                            pcall(function()
                                local av = require("client.slua.logic.wardrobe.logic_wardrobe_avatar")
                                if oldIns and itemSt then av:SetCurrentWearPreview(itemSt, nil) end
                                if itemSt then av:AddToWearInfo(itemSt, insID, resID, 0, 0) end
                                av:AvatarChange(resID, true, 0, 0)
                                av:ProcessTakeOff()
                                syncFashionBagRolewear()
                            end)
                            pcall(_AutoSaveOutfit)
                        end
                        return
                    end
                    return o(insID, extra)
                end
            end)

            pcall(function()
                local WRH = require("client.network.Protocol.WardRobeHandler")
                local oPutDown = WRH.send_depot_put_down_req
                WRH.send_depot_put_down_req = function(insID, extra)
                    insID = tonumber(insID)
                    if isInjectedIns(insID) then
                        local resID = R.insToRes[insID]
                        local removed = takeOffItem(insID)
                        if removed then
                            local wl = require("client.slua.logic.wardrobe.logic_wardrobe_new")
                            pcall(function()
                                wl:on_putdown_rsp(_K.NET_OK, {
                                    res_id = resID or 0,
                                    instid = insID,
                                    count  = 1,
                                }, nil)
                            end)
                            pcall(function()
                                if EventSystem and EVENTTYPE_WARDROBE and EVENTID_WARDROBE_UPDATE_PUT_DOWN_DATA then
                                    EventSystem:postEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_UPDATE_PUT_DOWN_DATA, {
                                        instid = insID,
                                        res_id = resID or 0,
                                        count = 1,
                                    })
                                end
                            end)
                            refreshWardrobe()
                            return
                        end
                    end
                    return oPutDown(insID, extra)
                end
            end)

            pcall(function()
                local wl = require("client.slua.logic.wardrobe.logic_wardrobe_new")
                local oPutDownReq = wl.wardrobe_put_down_req
                if oPutDownReq then
                    wl.wardrobe_put_down_req = function(self, ins_id, unequip_by_server)
                        ins_id = tonumber(ins_id)
                        if isInjectedIns(ins_id) then
                            local resID = R.insToRes[ins_id]
                            takeOffItem(ins_id)
                            pcall(function()
                                self:on_putdown_rsp(_K.NET_OK, {
                                    instid = ins_id,
                                    res_id = resID or 0,
                                }, nil)
                            end)
                            pcall(function()
                                if EventSystem and EVENTTYPE_WARDROBE and EVENTID_WARDROBE_UPDATE_PUT_DOWN_DATA then
                                    EventSystem:postEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_UPDATE_PUT_DOWN_DATA, {
                                        instid = ins_id,
                                        res_id = resID or 0,
                                        count = 1,
                                    })
                                end
                            end)
                            refreshWardrobe()
                            return
                        end
                        return oPutDownReq(self, ins_id, unequip_by_server)
                    end
                end
            end)

            pcall(function()
                local wl = require("client.slua.logic.wardrobe.logic_wardrobe_new")
                local oEquipSlot = wl.EquipSlotVehicle
                if oEquipSlot and not wl._lava_hooked_equip_slot_vehicle then
                    wl._lava_hooked_equip_slot_vehicle = true
                    wl.EquipSlotVehicle = function(self, resid, dragVehicleInsID, Index)
                        dragVehicleInsID = tonumber(dragVehicleInsID)
                        if dragVehicleInsID and isInjectedIns(dragVehicleInsID) then
                            local resID = R.insToRes[dragVehicleInsID]
                            local c = cfg(resID)
                            local itemSubType = c and tonumber(c.ItemSubType or c.itemSubType) or 0
                            if itemSubType and itemSubType > 0 then
                                DataMgr.VehicleSlotList = DataMgr.VehicleSlotList or {}
                                local slotList = DataMgr.VehicleSlotList[itemSubType] or {}
                                local idx = Index or 1
                                for i = #slotList, 1, -1 do
                                    if slotList[i] == dragVehicleInsID then
                                        table.remove(slotList, i)
                                    end
                                end
                                slotList[idx] = dragVehicleInsID
                                DataMgr.VehicleSlotList[itemSubType] = slotList
                                if DataMgr.vehicleSkinInsIDTable then
                                    DataMgr.vehicleSkinInsIDTable[resID] = DataMgr.vehicleSkinInsIDTable[resID] or dragVehicleInsID
                                end
                            end
                            DataMgr.UpdateVehicleSkin(itemSubType, dragVehicleInsID)
                            pcall(function()
                                local tabSurveillance = require("client.slua.logic.wardrobe.tab_surveillance")
                                if tabSurveillance and tabSurveillance.VehicleChange then
                                    tabSurveillance.VehicleChange()
                                end
                            end)
                            if EventSystem and EVENTTYPE_WARDROBE and EVENTID_WARDROBE_VEHICLE_SLOT_DATA_CHANGE then
                                EventSystem:postEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_VEHICLE_SLOT_DATA_CHANGE)
                            end
                            return
                        end
                        return oEquipSlot(self, resid, dragVehicleInsID, Index)
                    end
                end
            end)

            pcall(function()
                local GarageThemeSystem = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.GarageThemeSystem)
                if GarageThemeSystem and not GarageThemeSystem._lava_hooked_equip_vehicle then
                    GarageThemeSystem._lava_hooked_equip_vehicle = true
                    local oEquip = GarageThemeSystem.EquipVehicle
                    GarageThemeSystem.EquipVehicle = function(self, Position, InsID)
                        InsID = tonumber(InsID)
                        if InsID and isInjectedIns(InsID) then
                            self:OnEquipVehicle(Position, InsID)
                            return
                        end
                        return oEquip(self, Position, InsID)
                    end
                    local oBatch = GarageThemeSystem.BatchEquipVehicle
                    GarageThemeSystem.BatchEquipVehicle = function(self, InsIDList)
                        if InsIDList and type(InsIDList) == "table" then
                            local hasInjected = false
                            local filtered = {}
                            for slot, ins in pairs(InsIDList) do
                                if isInjectedIns(tonumber(ins)) then
                                    hasInjected = true
                                    self:OnEquipVehicle(slot, tonumber(ins))
                                else
                                    filtered[slot] = ins
                                end
                            end
                            if hasInjected and not next(filtered) then
                                return
                            end
                            InsIDList = filtered
                        end
                        return oBatch(self, InsIDList)
                    end

                    local oReceive = GarageThemeSystem.OnReceiveGarageData
                    GarageThemeSystem.OnReceiveGarageData = function(self, VehicleInfo)
                        local injectedSlots = {}
                        if self.GarageVehicleInfo then
                            for slot, info in pairs(self.GarageVehicleInfo) do
                                if info and info.inst_id and isInjectedIns(tonumber(info.inst_id)) then
                                    injectedSlots[slot] = info
                                end
                            end
                        end
                        oReceive(self, VehicleInfo)
                        for slot, info in pairs(injectedSlots) do
                            if not self.GarageVehicleInfo[slot] then
                                self.GarageVehicleInfo[slot] = info
                            end
                        end
                    end

                    local oGetInfo = GarageThemeSystem.GetGarageVehicleInfo
                    GarageThemeSystem.GetGarageVehicleInfo = function(self)
                        if not self.bDataReceived and self.GarageVehicleInfo and next(self.GarageVehicleInfo) then
                            return self.GarageVehicleInfo
                        end
                        return oGetInfo(self)
                    end

                    local oGetShowList = GarageThemeSystem.GetGarageShowCarInsIDList
                    if oGetShowList then
                        GarageThemeSystem.GetGarageShowCarInsIDList = function(self, VehicleType)
                            local List = oGetShowList(self, VehicleType) or {}
                            for _, resID in ipairs(_C.vehicleItems) do
                                if isInjectedRes(resID) and #List < self:GetMaxPositionNum() then
                                    local c = cfg(resID)
                                    if c then
                                        local itemSubType = tonumber(c.ItemSubType or c.itemSubType) or 0
                                        local taxonomy = CDataTable.GetTableDataByFilter("WardrobeVehiclesTaxonomy", "ItemSubType", itemSubType)
                                        if taxonomy and taxonomy.UseInGarage == 1 and taxonomy.CategoryID == VehicleType then
                                            local insID = R.resToIns[resID]
                                            if insID then
                                                local alreadyIn = false
                                                for _, existingIns in ipairs(List) do
                                                    if tonumber(existingIns) == tonumber(insID) then
                                                        alreadyIn = true
                                                        break
                                                    end
                                                end
                                                if not alreadyIn then
                                                    table.insert(List, insID)
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                            return List
                        end
                    end
                end
            end)
        end

        local function hookMotionEquip()
            pcall(function()
                local wl = require("client.slua.logic.wardrobe.logic_wardrobe_new")
                if wl._lava_hooked_motion then return end
                wl._lava_hooked_motion = true

                local origEquip = wl.EquipMotion
                wl.EquipMotion = function(self, instid, dst_slot)
                    instid = tonumber(instid)
                    if instid and isInjectedIns(instid) then
                        local insSlot = 0
                        for i, v in ipairs(DataMgr.MotionSlotList) do
                            if v == instid then insSlot = i; break end
                        end
                        if insSlot > 0 then
                            local curIns = DataMgr.MotionSlotList[dst_slot]
                            if curIns == instid then return end
                            DataMgr.MotionSlotList[insSlot] = curIns or 0
                            DataMgr.MotionSlotList[dst_slot] = instid
                        else
                            while #DataMgr.MotionSlotList < dst_slot do
                                table.insert(DataMgr.MotionSlotList, 0)
                            end
                            DataMgr.MotionSlotList[dst_slot] = instid
                        end
                        if EventSystem and EVENTTYPE_MOTION and EVENTID_MOTION_UPDATE_SLOT_LIST then
                            EventSystem:postEvent(EVENTTYPE_MOTION, EVENTID_MOTION_UPDATE_SLOT_LIST)
                        end
                        pcall(_AutoSaveOutfit)
                        return
                    end
                    return origEquip(self, instid, dst_slot)
                end

                local origUnequip = wl.unequip_motion_req
                wl.unequip_motion_req = function(self, instid, slot)
                    instid = tonumber(instid)
                    if instid and isInjectedIns(instid) then
                        for i, v in ipairs(DataMgr.MotionSlotList) do
                            if v == instid then
                                table.remove(DataMgr.MotionSlotList, i)
                                break
                            end
                        end
                        if EventSystem and EVENTTYPE_MOTION and EVENTID_MOTION_UPDATE_SLOT_LIST then
                            EventSystem:postEvent(EVENTTYPE_MOTION, EVENTID_MOTION_UPDATE_SLOT_LIST)
                        end
                        pcall(_AutoSaveOutfit)
                        return
                    end
                    return origUnequip(self, instid, slot)
                end
            end)
        end

        local _emoteSlotKey = nil
        local _emoteSlotCache = {}
        local function getInjectedEmotes()
            local slotList = DataMgr and DataMgr.MotionSlotList or {}
            local key = table.concat(slotList, ",")
            if key == _emoteSlotKey then return _emoteSlotCache end
            _emoteSlotKey = key
            _emoteSlotCache = {}
            for _, insID in ipairs(slotList) do
                insID = tonumber(insID)
                if insID and insID > 0 and isInjectedIns(insID) then
                    local resID = R.insToRes[insID]
                    if resID then
                        local c = cfg(resID)
                        if c and tonumber(c.ItemType) == 22 then
                            _emoteSlotCache[#_emoteSlotCache + 1] = {
                                resID = resID,
                                name = c.ItemName or "",
                                icon = c.ItemSmallIcon or c.ItemIcon or ""
                            }
                        end
                    end
                end
            end
            return _emoteSlotCache
        end

        local function hookIngameEmote()
            pcall(function()
                local QEU = require("GameLua.Mod.BaseMod.Client.Emote.QuickExpressionUtils")
                if QEU._lava_hooked then return end
                QEU._lava_hooked = true

                local origGetList = QEU.GetShowExpressionList
                QEU.GetShowExpressionList = function()
                    local tShowEmoteList, nWeaponEmoteId = origGetList()
                    tShowEmoteList = tShowEmoteList or {}
                    local emotes = getInjectedEmotes()
                    if #emotes > 0 then
                        local existingIDs = {}
                        for _, existing in pairs(tShowEmoteList) do
                            if existing.DefineID then
                                existingIDs[tonumber(existing.DefineID.TypeSpecificID) or 0] = true
                            end
                        end
                        for _, em in ipairs(emotes) do
                            if not existingIDs[em.resID] then
                                tShowEmoteList[#tShowEmoteList + 1] = {
                                    DefineID = {TypeSpecificID = em.resID},
                                    Name = em.name
                                }
                            end
                        end
                    end
                    return tShowEmoteList, nWeaponEmoteId
                end
            end)

            pcall(function()
                local QE = require("GameLua.Mod.BaseMod.Client.Emote.QuickExpression")
                if QE._lava_hooked_img then return end
                QE._lava_hooked_img = true

                local origGetImg = QE.GetEmoteImagePalthMap
                QE.GetEmoteImagePalthMap = function(self, ...)
                    origGetImg(self, ...)
                    local emotes = getInjectedEmotes()
                    for _, em in ipairs(emotes) do
                        if em.icon ~= "" then
                            self.ItemIDToImagePathMap[em.resID] = em.icon
                        end
                    end
                end
            end)

            pcall(function()
                local le = require("GameLua.Mod.Library.GamePlay.Avatar.Emote.logic_emote")
                if le._lava_hooked_exist then return end
                le._lava_hooked_exist = true

                local origExist = le.IsEmoteExist
                le.IsEmoteExist = function(EmoteID)
                    if isInjectedRes(tonumber(EmoteID)) then return true end
                    return origExist(EmoteID)
                end

                local origDownloaded = le.CheckEmoteDownloaded
                if origDownloaded then
                    le.CheckEmoteDownloaded = function(EmoteID, bUseCache, bLobby, bForeceLobby)
                        if isInjectedRes(tonumber(EmoteID)) then return true end
                        return origDownloaded(EmoteID, bUseCache, bLobby, bForeceLobby)
                    end
                end
            end)
        end

        local function hookFashionBag()
            pcall(function()
                local fbd = require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
                if fbd._lava_hooked_bag then return end
                fbd._lava_hooked_bag = true
                local function onFashionBagSkinChanged(skin, slot)
                    skin = tonumber(skin)
                    if _S.equipSkinApplying or not skin or skin <= 0 or not isInjectedIns(skin) then return end
                    local rid = R.insToRes[skin]
                    if not rid or not isInjectedRes(rid) then return end
                    local cch = cache()
                    local oldRes = cch.equip[slot]
                    if oldRes and oldRes > 0 and oldRes ~= rid then
                        softRemoveEquipVisual(oldRes, slot)
                    end
                    saveEquipSkin(rid, skin)
                    if slot ~= "parachute" and slot ~= "glider" then
                        applyEquipVisual(rid, skin, slot)
                    end
                end
                local origBag = fbd.SetBagSkin
                fbd.SetBagSkin = function(self, skin)
                    local r = origBag(self, skin)
                    onFashionBagSkinChanged(skin, "bag")
                    return r
                end
                local origHelm = fbd.SetHelmetSkin
                fbd.SetHelmetSkin = function(self, skin)
                    local r = origHelm(self, skin)
                    onFashionBagSkinChanged(skin, "helmet")
                    return r
                end
                local function reInjectThrowObjects(bagIndex)
                    pcall(function()
                        local cch = cache()
                        if not cch.throwObjects then return end
                        local bags = fbd.GetFashionBags and fbd:GetFashionBags()
                        if not bags or not bags.bags then return end
                        local bag = bags.bags[bagIndex]
                        if not bag then return end
                        bag.throw_object_list = bag.throw_object_list or {}
                        for st, info in pairs(cch.throwObjects) do
                            if info.insID and info.insID > 0 and _K.THROW_SUB[st] then
                                bag.throw_object_list[st] = info.insID
                            end
                        end
                    end)
                end
                local origUpdateAll = fbd.UpdateAllFashionBagExtraInfos
                if origUpdateAll then
                    fbd.UpdateAllFashionBagExtraInfos = function(self, all_knapsack_ext_info)
                        origUpdateAll(self, all_knapsack_ext_info)
                        if all_knapsack_ext_info then
                            for i, _ in pairs(all_knapsack_ext_info) do
                                reInjectThrowObjects(i)
                            end
                        end
                    end
                end
                local origUpdateOne = fbd.UpdateFashionBagExtraInfoByIndex
                if origUpdateOne then
                    fbd.UpdateFashionBagExtraInfoByIndex = function(self, index, knapsack_ext_info)
                        origUpdateOne(self, index, knapsack_ext_info)
                        if index then reInjectThrowObjects(index) end
                    end
                end
            end)
            pcall(function()
                if not DataMgr or DataMgr._lava_hooked_equip_skin then return end
                DataMgr._lava_hooked_equip_skin = true
                local orig = DataMgr.UpdateEquipmentSkin
                DataMgr.UpdateEquipmentSkin = function(itemSubType, putOnId)
                    putOnId = tonumber(putOnId)
                    if putOnId and putOnId > 0 and isInjectedIns(putOnId) and not _S.equipSkinApplying then
                        putOnEquipSkin(putOnId)
                    elseif putOnId == 0 then
                        local slot = (itemSubType == ENUM_ITEM_SUBTYPE.Backpack) and "bag"
                            or (itemSubType == ENUM_ITEM_SUBTYPE.Helmet_NoLevel) and "helmet" or nil
                        if slot then
                            local cch = cache()
                            takeOffEquipSkinVisual(slot, cch.equip[slot], cch.equip[slot .. "Ins"])
                            cch.equip[slot]          = nil
                            cch.equip[slot .. "Ins"] = nil
                            if MATCH_CONFIG.equip then MATCH_CONFIG.equip[slot] = 0 end
                            _S.matchApplied = false
                            invalidateSocialWearCache()
                            pcall(_AutoSaveOutfit)
                        end
                    end
                    return orig(itemSubType, putOnId)
                end
            end)
        end

        local function hookBackpackValid()
            if _G.DEV_WARDROBE_BP_HOOKED then return end
            _G.DEV_WARDROBE_BP_HOOKED = true
            pcall(function()
                local BU = import("BackpackUtils")
                if BU and BU.GetBPIDByResID then
                    local orig = BU.GetBPIDByResID
                    BU.GetBPIDByResID = function(resID)
                        resID = tonumber(resID)
                        if resID and isInjectedRes(resID) then
                            local bp = orig(resID)
                            if bp and bp > 0 then return bp end
                            return resID
                        end
                        return orig(resID)
                    end
                end
            end)
            pcall(function()
                local AU = import("AvatarUtils")
                if AU and AU.GetBPIDByResID then
                    local orig = AU.GetBPIDByResID
                    AU.GetBPIDByResID = function(resID, ...)
                        resID = tonumber(resID)
                        if resID and isInjectedRes(resID) then
                            local bp = orig(resID, ...)
                            if bp and bp > 0 then return bp end
                            return resID
                        end
                        return orig(resID, ...)
                    end
                end
            end)
        end

        local function hookAvatarValid()
            pcall(function()
                local CAC = require("GameLua.Mod.Library.GamePlay.Avatar.Component.CharacterAvatarComponent")
                if not CAC._lava_hooked_check_valid then
                    CAC._lava_hooked_check_valid = true
                    local orig = CAC.CheckItemValid
                    CAC.CheckItemValid = function(self, resID)
                        if isInjectedRes(resID) then return true end
                        return orig(self, resID)
                    end
                end
                if not CAC._lava_hooked_puton then
                    CAC._lava_hooked_puton = true
                    local origPutOn = CAC.PutOnCustomEquipmentByID
                    CAC.PutOnCustomEquipmentByID = function(self, resID, CustomData)
                        -- [XTHRLEN] Skip non-local player to avoid lag
                        if self.IsSelf and not self:IsSelf() then
                            return origPutOn(self, resID, CustomData)
                        end
                        resID = tonumber(resID)
                        if resID and isInjectedRes(resID) then
                            local ok, result = pcall(function()
                                local ItemDefineID = FItemDefineID(4, resID)
                                local EAvatarCustomType = import("EAvatarCustomType")
                                local AvatarCustom = FAvatarCustomDefault()
                                if CustomData then AvatarCustom = CustomData end
                                AvatarCustom.CustomType = EAvatarCustomType.AvatarCustomCharacter
                                return self:HandleEquipItem(ItemDefineID, AvatarCustom)
                            end)
                            if ok and result == true then return true end
                            if ok and result ~= false and result ~= nil then return result end
                        end
                        return origPutOn(self, resID, CustomData)
                    end
                end
            end)
        end

        local function isInLobby()
            local ok, r = pcall(function()
                return GameStatus and GameStatus.IsInLobbyOrMainCity and GameStatus.IsInLobbyOrMainCity() == true
            end)
            return ok and r == true
        end

        local function isInRealMatch()
            local ok, r = pcall(function()
                return GameStatus and GameStatus.IsInFightingStatus and GameStatus.IsInFightingStatus() == true
            end)
            return ok and r == true
        end

        local function isInGamePlay()
            if isInLobby() then return false end
            if isInRealMatch() then return true end
            local ok, r = pcall(function()
                local SingleTrainTool = require("GameLua.Mod.SingleTraining.GamePlay.Data.SingleTrainTool")
                return SingleTrainTool.IsSelfInTraining and SingleTrainTool.IsSelfInTraining()
            end)
            if ok and r then return true end
            local char = getLocalChar()
            return char and slua.isValid(char) and slua.isValid(char.CharacterAvatarComp2_BP)
        end

        local function getPlayerController()
            local ok, GD = pcall(require, "GameLua.GameCore.Data.GameplayData")
            if ok and GD and GD.GetPlayerController then
                local pc = GD.GetPlayerController()
                if pc and slua.isValid(pc) then return pc end
            end
            local pc = nil
            pcall(function()
                if slua_GameFrontendHUD and slua_GameFrontendHUD.GetPlayerController then
                    pc = slua_GameFrontendHUD:GetPlayerController()
                end
            end)
            return pc and slua.isValid(pc) and pc or nil
        end

        function getLocalChar()
            local ok, GD = pcall(require, "GameLua.GameCore.Data.GameplayData")
            if ok and GD and GD.GetPlayerCharacter then
                local char = GD.GetPlayerCharacter()
                if char and slua.isValid(char) then return char end
            end
            local pc = getPlayerController()
            if pc then
                local char = nil
                pcall(function()
                    if pc.GetPlayerCharacterSafety then char = pc:GetPlayerCharacterSafety() end
                    if (not char or not slua.isValid(char)) and pc.GetPawn then char = pc:GetPawn() end
                    if (not char or not slua.isValid(char)) and pc.K2_GetPawn then char = pc:K2_GetPawn() end
                end)
                if char and slua.isValid(char) then return char end
            end
            return nil
        end

        local function Notify(msg)
            if not DEBUGG or isInMatchOrGame() then return end
            msg = "[AddOutfit] " .. tostring(msg)
            log(msg:gsub("^%[AddOutfit%] ", ""))
            pcall(function()
                if ShowNotice then ShowNotice(msg, false, 10) end
            end)
        end

        local function getDesiredOutfit()
            if MATCH_CONFIG.outfitRes and tonumber(MATCH_CONFIG.outfitRes) > 0 then
                return tonumber(MATCH_CONFIG.outfitRes)
            end
            local cch = cache()
            if tonumber(cch.outfitRes) and cch.outfitRes > 0 then return cch.outfitRes end
            if tonumber(_G.AddOutfitLastLobbyOutfitRes) and _G.AddOutfitLastLobbyOutfitRes > 0 then
                return tonumber(_G.AddOutfitLastLobbyOutfitRes)
            end
            return nil
        end

        local function getWearSlotForResID(resID)
            resID = tonumber(resID)
            if not resID then return nil end
            local itemCfg = cfg(resID)
            if not itemCfg then return 3 end
            local st = tonumber(itemCfg.ItemSubType or itemCfg.itemSubType or 0)
            if st == 401 then return 1 end
            if st == 402 then return 2 end
            if st == 403 then return 3 end
            if st == 404 then return 4 end
            if st == 405 then return 5 end
            if st == 407 then return 6 end
            if st == 400 or st == 408 then return 9 end
            if st == 409 or st == 410 then return 10 end
            if getEquipSkinSlot(resID) then return nil end
            if weaponIdFromSkin(resID) then return nil end
            return 3
        end

        local function makeWearEntry(resID)
            local ENUM = ENUM_AVATAR_DATA_TYPE or { ItemID = 1, ColorID = 2, PatternID = 3 }
            return { [ENUM.ItemID] = resID, [ENUM.ColorID] = 0, [ENUM.PatternID] = 0 }
        end

        local function isApplySuccess(r) return r ~= false end
        
        local function refreshMatchAvatar(comp)
            if not slua.isValid(comp) then return end
            pcall(function() if comp.ProcessAvatarRectify then comp:ProcessAvatarRectify() end end)
            pcall(function() if comp.OnRep_BodySlotStateChanged then comp:OnRep_BodySlotStateChanged() end end)
            pcall(function() if comp.RefreshAvatarReAttach then comp:RefreshAvatarReAttach() end end)
        end
        
        local function applyItemToMatchAvatar(comp, resID)
            if not slua.isValid(comp) or not resID or not isInjectedRes(resID) then return false end
            resID = tonumber(resID)
            local applied = false
            pcall(function()
                comp.bSyncAvatar = false
                comp.forceLodMode = true
                comp.bIsLobbyAvatar = false
            end)
            local AvatarData = require("client.logic.data.AvatarData")
            local wearEntry = makeWearEntry(resID)
            local AData = AvatarData.ConvertToAvatarCustom and AvatarData.ConvertToAvatarCustom(wearEntry)
                or AvatarData.CreateAvatarCustom(resID, 0, 0)
            pcall(function()
                if comp.PutOnEquipmentByResID then
                    local r = comp:PutOnEquipmentByResID(AData.ItemID or resID, AData)
                    if isApplySuccess(r) then applied = true end
                end
            end)
            if not applied then
                pcall(function()
                    if comp.PutOnCustomEquipmentByID then
                        local r = comp:PutOnCustomEquipmentByID(resID, AData)
                        if isApplySuccess(r) then applied = true end
                    end
                end)
            end
            if not applied then
                pcall(function()
                    local ItemDefineID = FItemDefineID(4, resID)
                    local EAvatarCustomType = import("EAvatarCustomType")
                    local AvatarCustom = FAvatarCustomDefault()
                    AvatarCustom.CustomType = EAvatarCustomType.AvatarCustomCharacter
                    local r = comp:HandleEquipItem(ItemDefineID, AvatarCustom)
                    if isApplySuccess(r) then applied = true end
                end)
            end
            if applied then refreshMatchAvatar(comp) end
            return applied
        end

        local function applyClothToComp(comp, resID)
            if not slua.isValid(comp) then return false end
            local ok = false
            pcall(function()
                if comp.PutOnCustomEquipmentByID then
                    local r = comp:PutOnCustomEquipmentByID(resID)
                    if isApplySuccess(r) then ok = true end
                end
            end)
            if ok then return true end
            return applyItemToMatchAvatar(comp, resID)
        end

        local function matchApplyOutfit(char)
            syncWeaponCacheFromLobby()
            syncClothesCacheFromLobby()
            local comp = char.CharacterAvatarComp2_BP
            if not slua.isValid(comp) then return false end

            local outfitRes = getDesiredOutfit()
            local applied = false

            if outfitRes and isFullSuitRes(outfitRes) then
                pcall(function()
                    local r = comp:PutOnCustomEquipmentByID(outfitRes)
                    if isApplySuccess(r) then applied = true end
                end)
                if not applied then
                    pcall(function()
                        local r = comp:HandleEquipItem(FItemDefineID(4, outfitRes), FAvatarCustomDefault())
                        if isApplySuccess(r) then applied = true end
                    end)
                end
                if applied then _G.XTHRLENNotiff("suit OK " .. outfitRes) end

                for resID in pairs(collectAllClothResIDs()) do
                    if resID ~= outfitRes and not isFullSuitRes(resID)
                        and not isBodyClothSubType(subType(cfg(resID)))
                        and applyClothToComp(comp, resID) then
                        applied = true
                        --refreshMatchAvatar(comp)
                       -- [XTHRLEN] _G.XTHRLENNotiff("Accessory OK " .. resID)
                        -- [XTHRLEN]_G.XTHRLENNotiff("Paks Mods")
                    end
                end
            else
                for resID in pairs(collectAllClothResIDs()) do
                    if not isFullSuitRes(resID) and applyClothToComp(comp, resID) then
                        applied = true
                        _G.XTHRLENNotiff("clothes OK " .. resID)
                    end
                end
            end
            --[[
            if applied then
                refreshMatchAvatar(comp)
            end
            ]]
            return applied
        end

        local _lastPatchTime = 0
        local function patchPlayerInfoForMatch(PlayerInfo)
            if not PlayerInfo then return end
            local now = 0
            pcall(function() now = os.clock() end)
            if (now - _lastPatchTime) < 1.0 then return end  -- [XTHRLEN] throttle: max once per second
            _lastPatchTime = now
            snapshotLobbyWear()
            local cch = cache()
            if cch.equip.bag then PlayerInfo.bag_skin = cch.equip.bag end
            if cch.equip.helmet then PlayerInfo.helmet_skin = cch.equip.helmet end
            if cch.equip.armor then PlayerInfo.armor_skin = cch.equip.armor end

            local idx = tonumber(PlayerInfo.use_rolewear) or 1
            PlayerInfo.use_rolewear = idx
            PlayerInfo.all_knapsack_ext_info = PlayerInfo.all_knapsack_ext_info or {}
            PlayerInfo.all_knapsack_ext_info[idx] = PlayerInfo.all_knapsack_ext_info[idx] or {}
            local ext = PlayerInfo.all_knapsack_ext_info[idx]
            if cch.equip.bag then
                local catalogBag = normalizeEquipCatalogRes(cch.equip.bag)
                local bagLists = buildEquipSkinLists(catalogBag)
                ext.bag_skin = catalogBag
                ext.bag_skin_list = bagLists
                PlayerInfo.bag_skin = catalogBag
            end
            if cch.equip.helmet then
                local catalogHelm = normalizeEquipCatalogRes(cch.equip.helmet)
                local helmLists = buildEquipSkinLists(catalogHelm)
                ext.helmet_skin = catalogHelm
                ext.helmet_skin_list = helmLists
                PlayerInfo.helmet_skin = catalogHelm
            end
            if cch.equip.armor then ext.armor_skin = cch.equip.armor end
            if cch.equip.parachute and cch.equip.parachute > 0 then
                ext.parachute = cch.equip.parachuteIns or cch.equip.parachute
            end
            if cch.equip.glider and cch.equip.glider > 0 then
                ext.gliding = cch.equip.glider
            end

            pcall(function()
                if cch.throwObjects then
                    local throwList = {}
                    for st, info in pairs(cch.throwObjects) do
                        if info.resID and info.resID > 0 and _K.THROW_SUB[st] then
                            throwList[st] = info.resID
                        end
                    end
                    if next(throwList) then
                        local function applyThrowList(kext)
                            if not kext then return end
                            kext.throw_object_list = kext.throw_object_list or {}
                            for st, resID in pairs(throwList) do
                                kext.throw_object_list[st] = resID
                            end
                        end
                        applyThrowList(ext)
                        applyThrowList(PlayerInfo.knapsack_ext_info)
                        PlayerInfo.all_knapsack_ext_info = PlayerInfo.all_knapsack_ext_info or {}
                        for i = 1, 6 do
                            PlayerInfo.all_knapsack_ext_info[i] = PlayerInfo.all_knapsack_ext_info[i] or {}
                            applyThrowList(PlayerInfo.all_knapsack_ext_info[i])
                        end
                        for i, kext in pairs(PlayerInfo.all_knapsack_ext_info) do
                            applyThrowList(kext)
                        end
                        log("patchPlayerInfoForMatch: throw_object_list injected into all knapsack entries")
                    end
                end
            end)

            pcall(function()
                if DataMgr and DataMgr.VehicleSlotList then
                    PlayerInfo.vst_in_battle = PlayerInfo.vst_in_battle or {}
                    for subType, insList in pairs(DataMgr.VehicleSlotList) do
                        if insList and type(insList) == "table" then
                            local resList = {}
                            for i, insID in ipairs(insList) do
                                insID = tonumber(insID)
                                if insID and insID > 0 then
                                    local resID
                                    if isInjectedIns(insID) then
                                        resID = R.insToRes[insID]
                                    else
                                        local wd = require("client.slua.logic.wardrobe.wardrobe_data")
                                        local d = wd:GetHallDepotItemDataByInsID(insID)
                                        resID = d and tonumber(d.resID)
                                    end
                                    if resID and resID > 0 then
                                        resList[#resList + 1] = resID
                                    end
                                end
                            end
                            if #resList > 0 then
                                PlayerInfo.vst_in_battle[subType] = resList
                            end
                        end
                    end
                    if DataMgr.vst_skin then
                        local skinIns = tonumber(DataMgr.vst_skin)
                        if skinIns and skinIns > 0 then
                            local skinRes
                            if isInjectedIns(skinIns) then
                                skinRes = R.insToRes[skinIns]
                            else
                                local wd = require("client.slua.logic.wardrobe.wardrobe_data")
                                local d = wd:GetHallDepotItemDataByInsID(skinIns)
                                skinRes = d and tonumber(d.resID)
                            end
                            if skinRes and skinRes > 0 then
                                PlayerInfo.vst_skin = skinRes
                            end
                        end
                    end
                end
            end)
        end

        local _lastApplyEquipToController = 0
        local function applyMatchEquipAvatarToController()
            local now = 0
            pcall(function() now = os.clock() end)
            if (now - _lastApplyEquipToController) < 0.2 then return false end  -- [XTHRLEN] throttle: max 3x/sec
            _lastApplyEquipToController = now
            local pc = getPlayerController()
            if not pc or not slua.isValid(pc) then return false end
            local cch = cache()
            if not cch.equip.bag and not cch.equip.helmet and not cch.equip.armor and not cch.equip.parachute and not cch.equip.glider then return false end

            local char = getLocalChar()
            local eq = pc.InitialEquipmentAvatar or {}

            if cch.equip.bag and cch.equip.bag > 0 and isWearingEquip(char, "bag") then
                local catalogBag = normalizeEquipCatalogRes(cch.equip.bag)
                local bagLists = buildEquipSkinLists(catalogBag)
                eq.BagAvatar = catalogBag
                eq.BagAvatarList = bagLists
                local realBagId = getCharEquipLevel(char, 8) or 0
                local bagLevel
                if realBagId > 0 and isBaseEquipItemId(realBagId) then
                    bagLevel = detectEquipLevelFromBaseId(realBagId, catalogBag)
                elseif realBagId > 0 then
                    bagLevel = detectLevelFromEquipRes(realBagId)
                end
                bagLevel = bagLevel or getEquipDisplayLevel(cch.equip.bag, "bag")
                local bagDisplay = mapEquipSkinRes(catalogBag, bagLevel)
                if bagDisplay > 0 then eq.BagAvatar = bagDisplay end
            else
                eq.BagAvatar = 0
                eq.BagAvatarList = nil
            end

            if cch.equip.helmet and cch.equip.helmet > 0 and isWearingEquip(char, "helmet") then
                local catalogHelm = normalizeEquipCatalogRes(cch.equip.helmet)
                local helmLists = buildEquipSkinLists(catalogHelm)
                eq.HelmetAvatar = catalogHelm
                eq.HelmetAvatarList = helmLists
                local realHelmId = getCharEquipLevel(char, 9) or 0
                local helmLevel
                if realHelmId > 0 and isBaseEquipItemId(realHelmId) then
                    helmLevel = detectEquipLevelFromBaseId(realHelmId, catalogHelm)
                elseif realHelmId > 0 then
                    helmLevel = detectLevelFromEquipRes(realHelmId)
                end
                helmLevel = helmLevel or getEquipDisplayLevel(cch.equip.helmet, "helmet")
                local helmDisplay = mapEquipSkinRes(catalogHelm, helmLevel)
                if helmDisplay > 0 then eq.HelmetAvatar = helmDisplay end
            else
                eq.HelmetAvatar = 0
                eq.HelmetAvatarList = nil
            end
            if cch.equip.armor then eq.ArmorAvatar = cch.equip.armor end
            if cch.equip.parachute and cch.equip.parachute > 0 then
                eq.ParachuteAvatar = cch.equip.parachute
            end
            if cch.equip.glider and cch.equip.glider > 0 then
                eq.GliderAvatar = cch.equip.glider
            end

            pc.InitialEquipmentAvatar = eq
            pcall(function()
                if slua.isValid(pc.PlayerState) and pc.PlayerState.MetroPlayerStateAvatarFeature then
                    pc.PlayerState.MetroPlayerStateAvatarFeature.InitialEquipmentAvatar = eq
                end
            end)
            pcall(function()
                local comp = char and char.CharacterAvatarComp2_BP
                if slua.isValid(comp) and comp.GetEquipmentSkinItemID then
                    if cch.equip.helmet and isWearingEquip(char, "helmet") then
                        pcall(function() comp:GetEquipmentSkinItemID(cch.equip.helmet) end)
                    end
                    if cch.equip.bag and isWearingEquip(char, "bag") then
                        pcall(function() comp:GetEquipmentSkinItemID(cch.equip.bag) end)
                    end
                    if cch.equip.parachute and isWearingEquip(char, "parachute") then
                        pcall(function() comp:GetEquipmentSkinItemID(cch.equip.parachute) end)
                    end
                    if cch.equip.glider and cch.equip.glider > 0 then
                        pcall(function() comp:GetEquipmentSkinItemID(cch.equip.glider) end)
                    end
                end
            end)
            pcall(function()
                if pc.OnEquipmentAvatarChange and pc.OnEquipmentAvatarChange.Broadcast then
                    pc.OnEquipmentAvatarChange:Broadcast()
                end
            end)
            _G.XTHRLENNotiff("Equipment: Helmet=" .. tostring(eq.HelmetAvatar) .. "bag=" .. tostring(eq.BagAvatar))
            return true
        end

        local function hookEquipMapping()
            pcall(function()
                if DataMgr and not DataMgr._lava_equip_map_hooked then
                    DataMgr._lava_equip_map_hooked = true
                    local orig = DataMgr.GetEquipmentItemIDByResID
                    DataMgr.GetEquipmentItemIDByResID = function(level, itemResID)
                        level, itemResID = tonumber(level) or 3, tonumber(itemResID)
                        local catalogRes = normalizeEquipCatalogRes(itemResID)
                        local r = orig(level, catalogRes)
                        if r and r > 0 then return r end
                        if isInjectedIns(itemResID) then
                            return mapEquipSkinRes(normalizeEquipCatalogRes(R.insToRes[itemResID]), level)
                        end
                        if isInjectedRes(itemResID) then
                            return mapEquipSkinRes(catalogRes, level)
                        end
                        return r or 0
                    end
                end
            end)
            pcall(function()
                local lav = require("client.slua.logic.wardrobe.logic_wardrobe_avatar")
                if lav._lava_skinins_hooked then return end
                lav._lava_skinins_hooked = true
                local orig2 = lav.GetEquipmentItemIDBySkinInsID
                lav.GetEquipmentItemIDBySkinInsID = function(self, itemSubType, itemInsID)
                    local level = lav.GetEquipmentItemShowLevel(lav, itemSubType)
                    local r = orig2(self, itemSubType, itemInsID)
                    if r and r > 0 then return r end
                    itemInsID = tonumber(itemInsID)
                    if isInjectedIns(itemInsID) then
                        return mapEquipSkinRes(normalizeEquipCatalogRes(R.insToRes[itemInsID]), level)
                    end
                    pcall(function()
                        local wd = require("client.slua.logic.wardrobe.wardrobe_data")
                        local d = wd:GetHallDepotItemDataByInsID(itemInsID)
                        if d and isInjectedRes(d.resID) then
                            return mapEquipSkinRes(normalizeEquipCatalogRes(d.resID), level)
                        end
                    end)
                    return r
                end
            end)
            pcall(function()
                local CAC = require("GameLua.Mod.Library.GamePlay.Avatar.Component.CharacterAvatarComponent")
                if CAC._lava_equip_skin_hooked then return end
                CAC._lava_equip_skin_hooked = true
                local orig3 = CAC.GetEquipmentSkinItemID
                CAC.GetEquipmentSkinItemID = function(self, InItemID)
                    -- [XTHRLEN] Skip non-local player equipment to avoid lag
                    if self.IsSelf and not self:IsSelf() then
                        return orig3(self, InItemID)
                    end
                    local cch = cache()
                    InItemID = tonumber(InItemID) or 0

                    local function tryGetSkin(catalogRes)
                        if not catalogRes or catalogRes <= 0 then return 0 end
                        catalogRes = normalizeEquipCatalogRes(catalogRes)
                        local skin = resolveMatchEquipSkin(catalogRes, InItemID)
                        if skin > 0 then return skin end
                        for lvl = 1, 3 do
                            local s = mapEquipSkinRes(catalogRes, lvl)
                            if s > 0 then return s end
                        end
                        return 0
                    end

                    if InItemID > 0 and isBaseEquipItemId(InItemID) then
                        local isHelmetBase = GAME_HELMET_LEVEL[InItemID] ~= nil
                            or (InItemID >= 1505000001 and InItemID <= 1505000100)
                            or (InItemID >= 502001 and InItemID <= 502999)
                        local isBagBase = GAME_BAG_LEVEL[InItemID] ~= nil
                            or (InItemID >= 501001 and InItemID <= 501999)
                            or (InItemID >= 1501000000 and InItemID < 1502000000)

                        local char = getLocalChar()
                        if isHelmetBase and cch.equip.helmet and cch.equip.helmet > 0 then
                            if char and isWearingEquip(char, "helmet") then
                                local skin = tryGetSkin(cch.equip.helmet)
                                if skin > 0 then return skin end
                            end
                        end
                        if isBagBase and cch.equip.bag and cch.equip.bag > 0 then
                            if char and isWearingEquip(char, "bag") then
                                local skin = tryGetSkin(cch.equip.bag)
                                if skin > 0 then return skin end
                            end
                        end
                    end

                    local origResult = orig3(self, InItemID)
                    if origResult and origResult > 0 and origResult ~= InItemID then
                        return origResult
                    end

                    -- [XTHRLEN] fallback isWearingEquip
                    local isHelmetQuery = GAME_HELMET_LEVEL[InItemID] ~= nil or (InItemID >= 502001 and InItemID <= 502999)
                    local isBagQuery = GAME_BAG_LEVEL[InItemID] ~= nil or (InItemID >= 501001 and InItemID <= 501999)
                    local char = getLocalChar()

                    if isHelmetQuery and cch.equip.helmet and cch.equip.helmet > 0 then
                        if char and isWearingEquip(char, "helmet") then
                            local skin = tryGetSkin(cch.equip.helmet)
                            if skin > 0 then return skin end
                        end
                    end
                    if isBagQuery and cch.equip.bag and cch.equip.bag > 0 then
                        if char and isWearingEquip(char, "bag") then
                            local skin = tryGetSkin(cch.equip.bag)
                            if skin > 0 then return skin end
                        end
                    end
                    return origResult
                end
                local origEquipFinish = CAC.OnAvatarEquipFinish
                CAC.OnAvatarEquipFinish = function(self, slotType, isEquipped, itemID)
                    if origEquipFinish then origEquipFinish(self, slotType, isEquipped, itemID) end
                    if not isEquipped then return end
                    -- [XTHRLEN] Only process local player equipment to avoid lag
                    if not self.IsSelf or not self:IsSelf() then return end
                    pcall(function()
                        if self.IsLobbyActor and self:IsLobbyActor() then return end
                        local EAvatarSlotType = import("EAvatarSlotType")
                        local cch = cache()
                        local isHelmet = slotType == EAvatarSlotType.EAvatarSlotType_HelmetEquipemtSlot
                        local isBag = slotType == EAvatarSlotType.EAvatarSlotType_BackpackEquipemtSlot
                        if (isHelmet and cch.equip.helmet and cch.equip.helmet > 0)
                            or (isBag and cch.equip.bag and cch.equip.bag > 0) then
                            local owner = self.GetOwner and self:GetOwner()
                            if owner and slua.isValid(owner) and owner.AddGameTimer then
                                owner:AddGameTimer(0.10, false, function()
                                    if slua.isValid(owner) then matchApplyEquipSkins(owner) end
                                end)
                            end
                        end
                        applyMatchEquipAvatarToController()
                    end)
                end
            end)
        end

        local function applyMatchEquipSkinAtLevel(comp, catalogResID, level)
            if not slua.isValid(comp) or not catalogResID or catalogResID <= 0 then return false end
            catalogResID = normalizeEquipCatalogRes(catalogResID)
            level = tonumber(level) or 3
            local skinId = mapEquipSkinRes(catalogResID, level)
            if not skinId or skinId <= 0 then skinId = catalogResID end
            local ok = false
            pcall(function()
                if comp.PutOnCustomEquipmentByID then
                    local r = comp:PutOnCustomEquipmentByID(skinId)
                    if isApplySuccess(r) then ok = true end
                end
            end)
            if not ok then
                pcall(function()
                    local r = comp:HandleEquipItem(FItemDefineID(4, skinId), FAvatarCustomDefault())
                    if isApplySuccess(r) then ok = true end
                end)
            end
            if ok then refreshMatchAvatar(comp) end
            return ok
        end

        -- [XTHRLEN]matchApplyEquipSkins
        local function getCharEquipLevel(char, slotID)
            local found = nil
            pcall(function()
                local comp = char and char.CharacterAvatarComp2_BP
                if not slua.isValid(comp) then return end
                local NetAvatarData = slua.IndexReference(comp, "NetAvatarData")
                if not NetAvatarData then return end
                local TempSlotSyncData = slua.IndexReference(NetAvatarData, "SlotSyncData")
                if not TempSlotSyncData then return end
                for Index, AvatarSynData in pairs(TempSlotSyncData) do
                    if AvatarSynData.SlotID == slotID and AvatarSynData.ItemID and AvatarSynData.ItemID > 0 then
                        found = AvatarSynData.ItemID
                        return
                    end
                end
            end)
            return found
        end

        local function isWearingEquip(char, slot)
            local slotID = (slot == "helmet") and 9 or (slot == "bag") and 8 or (slot == "parachute") and 11 or (slot == "glider") and 15 or nil
            if not slotID then return false end

            -- [XTHRLEN]SlotSyncData
            local itemID = getCharEquipLevel(char, slotID)
            if itemID and itemID > 0 then return true end

            -- [XTHRLEN]PlayerState EquipmentAvatarData
            local wearing = false
            pcall(function()
                local pc = getPlayerController()
                if not pc or not slua.isValid(pc) then return end
                if pc.PlayerState and pc.PlayerState.MetroPlayerStateAvatarFeature then
                    local psEquip = pc.PlayerState.MetroPlayerStateAvatarFeature.EquipmentAvatarData
                    if psEquip then
                        if slot == "helmet" and psEquip.HelmetAvatar and psEquip.HelmetAvatar > 0 then
                            wearing = true
                        elseif slot == "bag" and psEquip.BagAvatar and psEquip.BagAvatar > 0 then
                            wearing = true
                        end
                    end
                end
            end)
            return wearing
        end

        local _lastMatchApplyEquip = 0
        local function matchApplyEquipSkins(char)
            local now = 0
            pcall(function() now = os.clock() end)
            if (now - _lastMatchApplyEquip) < 0.1 then return false end  -- [XTHRLEN] throttle: max 2x/sec
            _lastMatchApplyEquip = now
            local cch = cache()
            if not cch.equip.bag and not cch.equip.helmet and not cch.equip.parachute and not cch.equip.glider then return false end
            local comp = char and char.CharacterAvatarComp2_BP
            if not slua.isValid(comp) then return false end
            local ok = false

            if cch.equip.helmet and cch.equip.helmet > 0 then
                if isWearingEquip(char, "helmet") then
                    local catalogHelm = normalizeEquipCatalogRes(cch.equip.helmet)
                    local realHelmId = getCharEquipLevel(char, 9) or 0
                    local helmLevel
                    if realHelmId > 0 and isBaseEquipItemId(realHelmId) then
                        helmLevel = detectEquipLevelFromBaseId(realHelmId, catalogHelm)
                    elseif realHelmId > 0 then
                        helmLevel = detectLevelFromEquipRes(realHelmId)
                    end
                    helmLevel = helmLevel or getEquipDisplayLevel(cch.equip.helmet, "helmet")
                    if applyMatchEquipSkinAtLevel(comp, catalogHelm, helmLevel) then
                        ok = true
                        _G.XTHRLENNotiff("Match Helmet OK " .. mapEquipSkinRes(catalogHelm, helmLevel))
                    end
                end
            end

            if cch.equip.bag and cch.equip.bag > 0 then
                if isWearingEquip(char, "bag") then
                    local catalogBag = normalizeEquipCatalogRes(cch.equip.bag)
                    local realBagId = getCharEquipLevel(char, 8) or 0
                    local bagLevel
                    if realBagId > 0 and isBaseEquipItemId(realBagId) then
                        bagLevel = detectEquipLevelFromBaseId(realBagId, catalogBag)
                    elseif realBagId > 0 then
                        bagLevel = detectLevelFromEquipRes(realBagId)
                    end
                    bagLevel = bagLevel or getEquipDisplayLevel(cch.equip.bag, "bag")
                    if applyMatchEquipSkinAtLevel(comp, catalogBag, bagLevel) then
                        ok = true
                        _G.XTHRLENNotiff("Match bag OK " .. mapEquipSkinRes(catalogBag, bagLevel))
                    end
                end
            end

            if cch.equip.parachute and cch.equip.parachute > 0 then
                if isWearingEquip(char, "parachute") then
                    local paraResID = cch.equip.parachute
                    pcall(function()
                        if comp.PutOnCustomEquipmentByID then
                            local r = comp:PutOnCustomEquipmentByID(paraResID)
                            if isApplySuccess(r) then
                                ok = true
                                _G.XTHRLENNotiff("Parachute Match OK " .. tostring(paraResID))
                            end
                        end
                    end)
                    if not ok then
                        pcall(function()
                            local r = comp:HandleEquipItem(FItemDefineID(4, paraResID), FAvatarCustomDefault())
                            if isApplySuccess(r) then
                                ok = true
                                _G.XTHRLENNotiff("Parachute Match OK " .. tostring(paraResID))
                            end
                        end)
                    end
                end
            end

            if cch.equip.glider and cch.equip.glider > 0 then
                local gliderResID = cch.equip.glider
                pcall(function()
                    if comp.PutOnCustomEquipmentByID then
                        local r = comp:PutOnCustomEquipmentByID(gliderResID)
                        if isApplySuccess(r) then
                            ok = true
                            _G.XTHRLENNotiff("Glider Match OK " .. tostring(gliderResID))
                        end
                    end
                end)
                if not ok then
                    pcall(function()
                        local r = comp:HandleEquipItem(FItemDefineID(4, gliderResID), FAvatarCustomDefault())
                        if isApplySuccess(r) then
                            ok = true
                            _G.XTHRLENNotiff("Glider Match OK " .. tostring(gliderResID))
                        end
                    end)
                end
            end

            -- [XTHRLEN] PlayerController (circular dependency)
            applyMatchEquipAvatarToController()

            -- [XTHRLEN]SlotSyncData
            pcall(function()
                local NetAvatarData = slua.IndexReference(comp, "NetAvatarData")
                if not NetAvatarData then return end
                local TempSlotSyncData = slua.IndexReference(NetAvatarData, "SlotSyncData")
                if not TempSlotSyncData then return end

                for Index, AvatarSynData in pairs(TempSlotSyncData) do
                    local slotID = AvatarSynData.SlotID
                    local NDRid = AvatarSynData.ItemID

                    if slotID == 8 and NDRid ~= 0 and cch.equip.bag and cch.equip.bag > 0 then
                        local catalogBag = normalizeEquipCatalogRes(cch.equip.bag)
                        local bagLevel
                        if isBaseEquipItemId(NDRid) then
                            bagLevel = detectEquipLevelFromBaseId(NDRid, catalogBag)
                        else
                            bagLevel = detectLevelFromEquipRes(NDRid)
                        end
                        bagLevel = bagLevel or getEquipDisplayLevel(cch.equip.bag, "bag")
                        local skinId = mapEquipSkinRes(catalogBag, bagLevel)
                        if skinId <= 0 then skinId = mapEquipSkinRes(catalogBag, 3) end
                        if skinId > 0 and NDRid ~= skinId then
                            AvatarSynData.ItemID = skinId
                            slua.IndexReference(NetAvatarData, "SlotSyncData"):Set(Index, AvatarSynData)
                            ok = true
                        end
                    end

                    if slotID == 9 and NDRid ~= 0 and cch.equip.helmet and cch.equip.helmet > 0 then
                        local catalogHelm = normalizeEquipCatalogRes(cch.equip.helmet)
                        local helmLevel
                        if isBaseEquipItemId(NDRid) then
                            helmLevel = detectEquipLevelFromBaseId(NDRid, catalogHelm)
                        else
                            helmLevel = detectLevelFromEquipRes(NDRid)
                        end
                        helmLevel = helmLevel or getEquipDisplayLevel(cch.equip.helmet, "helmet")
                        local skinId = mapEquipSkinRes(catalogHelm, helmLevel)
                        if skinId <= 0 then skinId = mapEquipSkinRes(catalogHelm, 3) end
                        if skinId > 0 and NDRid ~= skinId then
                            AvatarSynData.ItemID = skinId
                            slua.IndexReference(NetAvatarData, "SlotSyncData"):Set(Index, AvatarSynData)
                            ok = true
                        end
                    end

                    -- [XTHRLEN]SlotID 11 (ParachuteEquipemtSlot)
                    if slotID == 11 and NDRid ~= 0 and cch.equip.parachute and cch.equip.parachute > 0 then
                        local paraResID = cch.equip.parachute
                        if NDRid ~= paraResID then
                            AvatarSynData.ItemID = paraResID
                            slua.IndexReference(NetAvatarData, "SlotSyncData"):Set(Index, AvatarSynData)
                            ok = true
                        end
                    end

                    -- [XTHRLEN]SlotID 15 (GlideEquipmtSlot)
                    if slotID == 15 and NDRid ~= 0 and cch.equip.glider and cch.equip.glider > 0 then
                        local gliderResID = cch.equip.glider
                        if NDRid ~= gliderResID then
                            AvatarSynData.ItemID = gliderResID
                            slua.IndexReference(NetAvatarData, "SlotSyncData"):Set(Index, AvatarSynData)
                            ok = true
                        end
                    end
                end

                if ok and comp.OnRep_BodySlotStateChanged then
                    comp:OnRep_BodySlotStateChanged()
                end
            end)
            return ok
        end

        local function hookPlayerWearingDone()
            pcall(function()
                local pc = getPlayerController()
                if not pc or not slua.isValid(pc) or pc._lava_wear_done_hooked then return end
                pc._lava_wear_done_hooked = true
                if pc.OnPlayerChangeWearingDone and pc.OnPlayerChangeWearingDone.Add then
                    pc.OnPlayerChangeWearingDone:Add(function()
                        applyMatchEquipAvatarToController()
                        local char = getLocalChar()
                        if char then
                            char:AddGameTimer(0.2, false, function()
                                if slua.isValid(char) then matchApplyEquipSkins(char) end
                            end)
                        end
                    end)
                end
            end)
        end

        local function hookCommerAvatarData()
            pcall(function()
                local CommerAvatarDataUtil = require("GameLua.Activity.Commercialize.GamePlay.CommerAvatarDataUtil")
                if CommerAvatarDataUtil._lava_hooked_equip then return end
                CommerAvatarDataUtil._lava_hooked_equip = true
                local orig = CommerAvatarDataUtil.GeneratePlayerAvatarData
                CommerAvatarDataUtil.GeneratePlayerAvatarData = function(self, PlayerInfo, uPlayerController, ...)
                    -- [XTHRLEN] Skip expensive operations for non-local players
                    local localPC = getPlayerController()
                    if uPlayerController and slua.isValid(uPlayerController) and uPlayerController == localPC then
                        pcall(function() patchPlayerInfoForMatch(PlayerInfo) end)
                    end
                    orig(self, PlayerInfo, uPlayerController, ...)
                    if uPlayerController and slua.isValid(uPlayerController) and uPlayerController == localPC then
                        applyMatchEquipAvatarToController()
                    end
                end
            end)
        end

        local function hookMatchAvatarData()
            hookCommerAvatarData()
            pcall(function()
                local AvatarDataUtil = require("GameLua.Mod.Library.GamePlay.Avatar.AvatarDataUtil")
                if AvatarDataUtil._lava_hooked_gen then return end
                AvatarDataUtil._lava_hooked_gen = true
                local origGet = AvatarDataUtil.GetPlayerInfo
                AvatarDataUtil.GetPlayerInfo = function(uPlayerController)
                    local pi = origGet(uPlayerController)
                    -- [XTHRLEN] Only patch for local player to avoid lag when enemies appear
                    local localPC = getPlayerController()
                    if pi and uPlayerController and slua.isValid(uPlayerController) and uPlayerController == localPC then
                        patchPlayerInfoForMatch(pi)
                    end
                    return pi
                end
                local origGen = AvatarDataUtil.GeneratePlayerAvatarData
                AvatarDataUtil.GeneratePlayerAvatarData = function(uPlayerController)
                    -- [XTHRLEN] Only patch for local player to avoid lag when enemies appear
                    local localPC = getPlayerController()
                    if uPlayerController and slua.isValid(uPlayerController) and uPlayerController == localPC then
                        pcall(function()
                            local PlayerInfo = AvatarDataUtil.GetPlayerInfo(uPlayerController)
                            if PlayerInfo then patchPlayerInfoForMatch(PlayerInfo) end
                        end)
                    end
                    origGen(uPlayerController)
                    if uPlayerController and slua.isValid(uPlayerController) and uPlayerController == localPC then
                        applyMatchEquipAvatarToController()
                    end
                    return
                end
                local origInit = AvatarDataUtil.InitialEquipmentAvatar
                AvatarDataUtil.InitialEquipmentAvatar = function(PlayerInfo, uPlayerController)
                    -- [XTHRLEN] Only patch for local player to avoid lag when enemies appear
                    local localPC = getPlayerController()
                    if uPlayerController and slua.isValid(uPlayerController) and uPlayerController == localPC then
                        pcall(function() patchPlayerInfoForMatch(PlayerInfo) end)
                    end
                    origInit(PlayerInfo, uPlayerController)
                    if uPlayerController and slua.isValid(uPlayerController) and uPlayerController == localPC then
                        applyMatchEquipAvatarToController()
                    end
                end
            end)
        end

        local function hookClassMethod(classModule, methodName, hookTag, newFunc)
            if not classModule then log("hookClassMethod: nil classModule for", methodName) return false end
            local impl = classModule.__inner_impl
            if not impl then log("hookClassMethod: no __inner_impl for", methodName) return false end
            if impl[hookTag] then log("hookClassMethod: already hooked", methodName) return false end
            local orig = impl[methodName]
            if not orig then log("hookClassMethod: no orig method", methodName) return false end
            impl[hookTag] = true
            impl[methodName] = function(...)
                return newFunc(orig, ...)
            end
            pcall(function() rawset(classModule, methodName, nil) end)
            -- [XTHRLEN] log("hookClassMethod: hooked", methodName)
            return true
        end

        local function hookGrenadeAvatarInit()
            pcall(function()
                local PCB = require("GameLua.GameCore.Framework.PlayerControllerBase")
                -- [XTHRLEN] log suppressed
                hookClassMethod(PCB, "InitGrenadeAvatarList", "_lava_hooked_grenade_init", function(orig, self, ReInitial)
                    orig(self, ReInitial)
                    -- [XTHRLEN] Only inject for local player to avoid lag when enemies appear
                    local localPC = getPlayerController()
                    if not localPC or self ~= localPC then return end
                    if ReInitial then
                        pcall(function()
                            local cch = cache()
                            if cch.throwObjects and self.AddToGrenadeAvatarItemList then
                                for st, info in pairs(cch.throwObjects) do
                                    if info.resID and info.resID > 0 and _K.THROW_SUB[st] then
                                        self:AddToGrenadeAvatarItemList(info.resID)
                                    end
                                end
                            end
                        end)
                    end
                end)
            end)
        end

        local function applyGrenadeSkinsToController()
            local pc = getPlayerController()
            if not pc or not slua.isValid(pc) then return false end
            local cch = cache()
            if not cch.throwObjects then return false end
            local hasThrow = false
            for _, info in pairs(cch.throwObjects) do
                if info.resID and info.resID > 0 then hasThrow = true break end
            end
            if not hasThrow then return false end
            pcall(function()
                if pc.AddToGrenadeAvatarItemList then
                    for st, info in pairs(cch.throwObjects) do
                        if info.resID and info.resID > 0 and _K.THROW_SUB[st] then
                            pc:AddToGrenadeAvatarItemList(info.resID)
                        end
                    end
                end
                if pc.OnWeaponAvatarUpdate then
                    pc:OnWeaponAvatarUpdate()
                end
                local char = getLocalChar()
                if char and slua.isValid(char) then
                    local curWeapon = char.GetCurrentWeapon and char:GetCurrentWeapon()
                    if slua.isValid(curWeapon) then
                        local wid = 0
                        pcall(function() wid = curWeapon:GetWeaponID() end)
                        if wid >= 602001 and wid <= 602004 then
                            log("applyGrenadeSkinsToController: held grenade wid=", wid)
                            if curWeapon.DelayHandleAvatarMeshChanged then
                                curWeapon:DelayHandleAvatarMeshChanged()
                            end
                            if curWeapon.HandleAvatarMeshChanged then
                                curWeapon:HandleAvatarMeshChanged()
                            end
                            local GRENADE_WID_TO_SUB = {
                                [602001] = 614, [602002] = 613,
                                [602003] = 615, [602004] = 612,
                            }
                            local sub = GRENADE_WID_TO_SUB[wid]
                            local info = sub and cch.throwObjects[sub]
                            if info and info.resID and info.resID > 0 then
                                if slua.isValid(curWeapon.GrenadeAvatarComponent_BP) then
                                    curWeapon.GrenadeAvatarComponent_BP:ChangeItemAvatar(info.resID, false)
                                    log("applyGrenadeSkinsToController: ChangeItemAvatar on held weapon", info.resID)
                                end
                                if curWeapon.AddGameTimer then
                                    curWeapon:AddGameTimer(0.1, false, function()
                                        pcall(function()
                                            if slua.isValid(curWeapon) and slua.isValid(curWeapon.GrenadeAvatarComponent_BP) then
                                                curWeapon.GrenadeAvatarComponent_BP:ChangeItemAvatar(info.resID, false)
                                            end
                                        end)
                                    end)
                                end
                            end
                        end
                    end
                end
            end)
            return true
        end

        -- [XTHRLEN] Simplified: only hook TryGetGrenadeAvatarID (lightweight),
        -- [XTHRLEN] skip per-grenade-class GetAvatarID hooks (heavy, fire for all players)
        local function hookGrenadeAvatarLookup()
            pcall(function()
                local AvatarDataUtil = require("GameLua.Mod.Library.GamePlay.Avatar.AvatarDataUtil")
                if AvatarDataUtil and not AvatarDataUtil._lava_hooked_try_get then
                    AvatarDataUtil._lava_hooked_try_get = true
                    local origTry = AvatarDataUtil.TryGetGrenadeAvatarID
                    if origTry then
                        AvatarDataUtil.TryGetGrenadeAvatarID = function(uPlayerController, ItemID)
                            local cch = cache()
                            if cch.throwObjects then
                                if ItemID == 602001 and cch.throwObjects[614] and cch.throwObjects[614].resID and cch.throwObjects[614].resID > 0 then
                                    return cch.throwObjects[614].resID
                                elseif ItemID == 602002 and cch.throwObjects[613] and cch.throwObjects[613].resID and cch.throwObjects[613].resID > 0 then
                                    return cch.throwObjects[613].resID
                                elseif ItemID == 602003 and cch.throwObjects[615] and cch.throwObjects[615].resID and cch.throwObjects[615].resID > 0 then
                                    return cch.throwObjects[615].resID
                                elseif ItemID == 602004 and cch.throwObjects[612] and cch.throwObjects[612].resID and cch.throwObjects[612].resID > 0 then
                                    return cch.throwObjects[612].resID
                                end
                            end
                            return origTry(uPlayerController, ItemID)
                        end
                    end
                end
            end)
            -- [XTHRLEN] Per-class GetAvatarID hooks removed (heavy, fire for all player grenades)
            -- [XTHRLEN] Timer-based applyGrenadeSkinsToController handles periodic application
        end

        local GRENADE_ITEMID_TO_SUB = {
            [602001] = 614,
            [602002] = 613,
            [602003] = 615,
            [602004] = 612,
        }

        -- [XTHRLEN] Lightweight version: only hooks UpdateGrenadeAvatar for local grenades
        -- [XTHRLEN] Timer-based applyGrenadeSkinsToController handles periodic application
        local function hookProjectileGrenadeAvatar()
            pcall(function()
                local ProjectileBase = require("GameLua.Mod.BaseMod.GamePlay.Actor.Projectile.ProjectileBase")
                local impl = ProjectileBase and ProjectileBase.__inner_impl
                if not impl or impl._lava_hooked_proj then return end
                impl._lava_hooked_proj = true
                local origUpdate = impl.UpdateGrenadeAvatar
                if origUpdate then
                    impl.UpdateGrenadeAvatar = function(self)
                        -- [XTHRLEN] Only process local player grenades
                        if self.bAuthority then return origUpdate(self) end
                        local cch = cache()
                        if cch.throwObjects and slua.isValid(self.GrenadeAvatarComponent_BP) then
                            local itemID
                            if self.GetItemTypeID then
                                itemID = tonumber(self:GetItemTypeID())
                            elseif self.ItemDefineID then
                                itemID = tonumber(self.ItemDefineID.TypeSpecificID)
                            end
                            local sub = itemID and GRENADE_ITEMID_TO_SUB[itemID]
                            local info = sub and cch.throwObjects[sub]
                            if info and info.resID and info.resID > 0 then
                                pcall(function()
                                    self.GrenadeAvatarComponent_BP:ChangeItemAvatar(info.resID, false)
                                end)
                                return
                            end
                        end
                        return origUpdate(self)
                    end
                end
                -- [XTHRLEN] Skip BeginInitialize and ResetGrenadeAvatar hooks (they fire for every player's grenades)
                -- [XTHRLEN] Timer-based applyGrenadeSkinsToController will re-apply periodically
            end)
        end

        local function applyMatchWeaponSkinsToController()
            local pc = getPlayerController()
            if not pc or not slua.isValid(pc) then return false end
            local skinList = {}
            for _, w in pairs(cache().weapons) do
                if w.resID and w.resID > 0 then skinList[#skinList + 1] = w.resID end
            end
            if #skinList == 0 then return false end
            local ok = false
            pcall(function()
                local CommerAvatarDataUtil = require("GameLua.Activity.Commercialize.GamePlay.CommerAvatarDataUtil")
                CommerAvatarDataUtil:InitWeaponSkinList(pc, skinList, nil, nil)
                if pc.InitWeaponAvatarItems then pc:InitWeaponAvatarItems() end
                if pc.OnWeaponAvatarUpdate then pc:OnWeaponAvatarUpdate() end
                ok = true
            end)
            if ok then _G.XTHRLENNotiff("weapon PC: " .. table.concat(skinList, ",")) end
            return ok
        end

        local _weaponTypeIDCache = {}
        local function resolveWeaponTypeID(weaponResID)
            weaponResID = tonumber(weaponResID) or 0
            if weaponResID <= 0 then return 0 end
            if _weaponTypeIDCache[weaponResID] ~= nil then return _weaponTypeIDCache[weaponResID] end
            local found = 0
            pcall(function()
                local wc = CDataTable.GetTableData("WeaponConfig", weaponResID)
                if wc then found = tonumber(wc.WeaponID or wc.WeaponId or wc.weaponID or 0) end
            end)
            if found > 0 then _weaponTypeIDCache[weaponResID] = found; return found end
            pcall(function()
                local ic = CDataTable.GetTableData("Item", weaponResID)
                if ic then found = tonumber(ic.WeaponID or ic.weaponId or 0) end
            end)
            local result = found > 0 and found or weaponResID
            _weaponTypeIDCache[weaponResID] = result
            return result
        end

        local _lastBuildSkinMappings = 0
        local function buildSkinMappings()
            local now = 0
            pcall(function() now = os.clock() end)
            if (now - _lastBuildSkinMappings) < 0.5 then return end  -- [XTHRLEN] throttle: max twice per second
            _lastBuildSkinMappings = now
            syncWeaponCacheFromLobby()
            local m = _G.AddOutfitSkinIdMappings
            for k in pairs(m) do m[k] = nil end
            for wid, w in pairs(cache().weapons) do
                wid = tonumber(wid)
                if wid and w.resID and w.resID > 0 then m[wid] = { tonumber(w.resID) } end
            end
            if MATCH_CONFIG.weaponSkins then
                for weaponKey, skinRes in pairs(MATCH_CONFIG.weaponSkins) do
                    weaponKey, skinRes = tonumber(weaponKey), tonumber(skinRes)
                    if weaponKey and skinRes and skinRes > 0 and not m[weaponKey] then
                        m[weaponKey] = { skinRes }
                    end
                end
            end
        end

        local _skinIdCache = {}
        local _skinIdCacheTick = 0
        local function get_skin_id(currentGunId, maxIt)
            currentGunId, maxIt = tonumber(currentGunId) or 0, tonumber(maxIt) or 0
            if currentGunId <= 0 and maxIt <= 0 then return 0 end
            -- [XTHRLEN] Fast path: prefer using weapon cache directly
            local cch = cache()
            local wid = maxIt > 0 and maxIt or currentGunId
            local w = cch.weapons[wid]
            if w and w.resID and w.resID > 0 then return w.resID end
            -- [XTHRLEN] Try type ID lookup
            local typeId = resolveWeaponTypeID(wid)
            if typeId ~= wid then
                local w2 = cch.weapons[typeId]
                if w2 and w2.resID and w2.resID > 0 then return w2.resID end
            end
            -- [XTHRLEN] Cache with short TTL
            local nowTick = _S.globalFrame or 0
            if (nowTick - _skinIdCacheTick) < 60 then
                local cached = _skinIdCache[wid]
                if cached then return cached end
            end
            buildSkinMappings()
            local m = _G.AddOutfitSkinIdMappings
            local result = nil
            if m[wid] and m[wid][1] then result = tonumber(m[wid][1])
            elseif typeId ~= wid and m[typeId] and m[typeId][1] then result = tonumber(m[typeId][1])
            end
            if result then
                _skinIdCache[wid] = result
                _skinIdCacheTick = nowTick
                return result
            end
            return wid
        end
        _G.get_skin_id = get_skin_id
        _G.skinIdMappings = _G.AddOutfitSkinIdMappings
        
        local _attachMaps = nil

        local function _nameToString(name)
            if name == nil then return "" end
            if type(name) == "string" then return name end
            if type(name) == "userdata" then
                local s = nil
                pcall(function() if name.ToString then s = name:ToString() end end)
                if s and type(s) == "string" then return s end
                pcall(function() if name.ToWString then s = name:ToWString() end end)
                if s and type(s) == "string" then return s end
            end
            if type(name) == "table" and name.SourceString then
                return name.SourceString
            end
            return tostring(name)
        end

        local _WEAPON_CLASS_SUFFIXES = {
            { keywords = { "kar98", "awm", "m24", "amr", "mosin", "win94", "mk14" },
            suffixes = { "(Snipers)", "(Sniper Rifles)" } },
            { keywords = { "m249", "mg3", "dp-28", "dp28" },
            suffixes = { "(Machine Guns)" } },
            { keywords = { "ump", "p90", "vector", "bizon", "uzi", "thompson",
                        "mp5", "mp5k", "tommy" },
            suffixes = { "(SMG)", "(SMG, Pistols)", "(Rifles, SMG)" } },
            { keywords = { "p1911", "p92", "p18c", "deagle", "r1895", "r45",
                        "skorpion", "g18" },
            suffixes = { "(Pistols)", "(SMG, Pistols)" } },
            { keywords = { "akm", "m762", "scar", "famas", "m16a4", "aug",
                        "groza", "qbz", "m416", "mk47", "g36c", "ace32",
                        "k2", "m4" },
            suffixes = { "(AR)", "(Rifles, SMG)" } },
        }

        local function _classSuffixesFromSkinName(skinName)
            if type(skinName) ~= "string" or skinName == "" then return {} end
            local low = string.lower(skinName)
            for _, entry in ipairs(_WEAPON_CLASS_SUFFIXES) do
                for _, kw in ipairs(entry.keywords) do
                    if string.find(low, kw, 1, true) then return entry.suffixes end
                end
            end
            return {}
        end

        local function buildAttachmentMaps()
            if _attachMaps then return _attachMaps end
            _attachMaps = {
                skinAttachments  = {},  -- [XTHRLEN] weaponSkinId -> { partSkinId1, partSkinId2, ... }
                skinBases        = {},  -- [XTHRLEN] weaponSkinId -> { baseId1, baseId2, ... }
                attachToSkin     = {},  -- [XTHRLEN] partSkinId   -> { weaponSkinId, baseId }
                skinToBaseWeapon = {},  -- [XTHRLEN] weaponSkinId -> baseWeaponID
            }
            if not CDataTable or not CDataTable.GetTable then return _attachMaps end

            -- [XTHRLEN] 1) GroupID -> [PartIds] from ItemUpgradeUnLockConfig
            local groupToParts = {}
            pcall(function()
                local unlockTbl = CDataTable.GetTable("ItemUpgradeUnLockConfig")
                if not unlockTbl then return end
                for _, row in pairs(unlockTbl) do
                    local gid  = tonumber(row.GroupID)
                    local part = tonumber(row.PartId or row.PartID)
                    if gid and part then
                        if not groupToParts[gid] then groupToParts[gid] = {} end
                        groupToParts[gid][#groupToParts[gid] + 1] = part
                    end
                end
            end)

            -- [XTHRLEN] 2) weaponSkinId -> GroupID + skinToBaseWeapon from ItemUpgradeConfig
            local skinToGroup = {}
            pcall(function()
                local upTbl = CDataTable.GetTable("ItemUpgradeConfig")
                if not upTbl then return end
                for _, row in pairs(upTbl) do
                    local gid = tonumber(row.GroupID)
                    local itm = tonumber(row.ItemID)
                    if gid and itm and itm >= 1000000000 then
                        skinToGroup[itm] = gid
                        local baseWeaponID = math.floor(itm / 1000) % 1000000
                        if baseWeaponID >= 100000 and baseWeaponID <= 999999 then
                            _attachMaps.skinToBaseWeapon[itm] = baseWeaponID
                        end
                    end
                end
            end)

            -- [XTHRLEN] 3) Base name -> [ids] index from Item table (vanilla attachments only)
            local baseNameToIds = {}
            local itemTbl = CDataTable.GetTable("Item")
            if itemTbl then
                for k, row in pairs(itemTbl) do
                    local id = tonumber(k) or tonumber(row and row.ItemID)
                    if id and id >= 1000 and id < 10000000 then
                        local nm = row and row.ItemName
                        if type(nm) ~= "string" then nm = _nameToString(nm) end
                        if type(nm) == "string" and nm ~= "" then
                            if not baseNameToIds[nm] then baseNameToIds[nm] = {} end
                            baseNameToIds[nm][#baseNameToIds[nm] + 1] = id
                        end
                    end
                end
            end

            -- [XTHRLEN] 4) For each weapon skin, resolve its attachments' base IDs
            for weaponSkinId, gid in pairs(skinToGroup) do
                local parts = groupToParts[gid]
                if parts and #parts > 0 then
                    local bases = {}
                    local wc = cfg(weaponSkinId)
                    local weaponSkinName = ""
                    if wc then
                        local nm = wc.ItemName
                        if type(nm) ~= "string" then nm = _nameToString(nm) end
                        weaponSkinName = nm or ""
                    end
                    local suffixes = _classSuffixesFromSkinName(weaponSkinName)

                    for _, partId in ipairs(parts) do
                        local baseId = 0
                        local partRow = nil
                        if itemTbl then
                            partRow = itemTbl[partId] or itemTbl[tostring(partId)]
                        end
                        if not partRow and CDataTable.GetTableData then
                            partRow = CDataTable.GetTableData("Item", partId)
                        end
                        if partRow then
                            local nm = partRow.ItemName
                            if type(nm) ~= "string" then nm = _nameToString(nm) end
                            if type(nm) == "string" and nm ~= "" then
                                local list = baseNameToIds[nm]
                                if type(list) == "table" and #list >= 1 then
                                    baseId = list[1]
                                    for _, v in ipairs(list) do
                                        if v < baseId then baseId = v end
                                    end
                                end
                                if baseId == 0 then
                                    for _, suf in ipairs(suffixes) do
                                        local trial = nm .. " " .. suf
                                        local lst = baseNameToIds[trial]
                                        if type(lst) == "table" and #lst >= 1 then
                                            baseId = lst[1]
                                            for _, v in ipairs(lst) do
                                                if v < baseId then baseId = v end
                                            end
                                            break
                                        end
                                    end
                                end
                            end
                        end
                        bases[#bases + 1] = baseId
                        _attachMaps.attachToSkin[partId] = { weaponSkinId, baseId }
                    end
                    _attachMaps.skinAttachments[weaponSkinId] = parts
                    _attachMaps.skinBases[weaponSkinId] = bases
                end
            end

            local nSkins, nAttach = 0, 0
            for _ in pairs(_attachMaps.skinAttachments) do nSkins = nSkins + 1 end
            for _ in pairs(_attachMaps.attachToSkin) do nAttach = nAttach + 1 end
            log("Attachment maps: " .. nSkins .. " skins, " .. nAttach .. " attachments")

            return _attachMaps
        end

        local function applyAttachmentSkins(AttachmentArray, selectedSkinID)
            if not AttachmentArray or not slua.isValid(AttachmentArray) then return false end
            selectedSkinID = tonumber(selectedSkinID) or 0
            if selectedSkinID == 0 then return false end

            local maps = buildAttachmentMaps()
            local attachments = maps.skinAttachments[selectedSkinID]
            local bases = maps.skinBases[selectedSkinID]

            local numSlots = 0
            pcall(function() numSlots = AttachmentArray:Num() end)
            if numSlots <= 0 then return false end

            local changed = false

            -- [XTHRLEN] If selected skin has no attachments in the map, revert any
            -- [XTHRLEN] part-skins found on attachment slots back to their base IDs.
            if not attachments or #attachments == 0 then
                for slotIdx = 0, numSlots - 1 do
                    if slotIdx ~= _K.GUN_MASTER_SYN_SLOT then
                        local slotData = AttachmentArray:Get(slotIdx)
                        if slotData then
                            local curID = 0
                            pcall(function()
                                curID = slua.IndexReference(slotData, "defineID").TypeSpecificID or 0
                            end)
                            curID = tonumber(curID) or 0
                            if curID > 0 then
                                local rIt = maps.attachToSkin[curID]
                                if rIt then
                                    local baseId = rIt[2]
                                    if baseId ~= 0 and baseId ~= curID then
                                        pcall(function()
                                            local defRef = slua.IndexReference(slotData, "defineID")
                                            defRef.TypeSpecificID = baseId
                                            slotData.operationType = 0
                                            AttachmentArray:Set(slotIdx, slotData)
                                        end)
                                        changed = true
                                    end
                                end
                            end
                        end
                    end
                end
                return changed
            end

            -- [XTHRLEN] Build a set of valid attachment skin IDs for this weapon skin
            local validSkinIds = {}
            for _, id in ipairs(attachments) do
                validSkinIds[tonumber(id) or 0] = true
            end

            -- [XTHRLEN] Normal case: for each attachment slot, find the matching
            -- [XTHRLEN] attachment skin by baseId and swap to the selected skin's version.
            for slotIdx = 0, numSlots - 1 do
                if slotIdx ~= _K.GUN_MASTER_SYN_SLOT then
                    local slotData = AttachmentArray:Get(slotIdx)
                    if slotData then
                        local curID = 0
                        pcall(function()
                            curID = slua.IndexReference(slotData, "defineID").TypeSpecificID or 0
                        end)
                        curID = tonumber(curID) or 0
                        if curID > 0 then
                            -- [XTHRLEN] Protection: if current attachment is already the correct skin, skip
                            if validSkinIds[curID] then
                                -- [XTHRLEN] Already the correct skinned attachment, don't change
                            else
                                local baseId = 0
                                local rIt = maps.attachToSkin[curID]
                                if rIt then
                                    baseId = rIt[2]
                                elseif curID < 10000000 then
                                    baseId = curID
                                else
                                    -- [XTHRLEN] Unknown skinned attachment from different skin, skip
                                    baseId = 0
                                end
                                if baseId ~= 0 then
                                    local srcIdx = 0
                                    for k, b in ipairs(bases) do
                                        if b ~= 0 and b == baseId then
                                            local candidate = tonumber(attachments[k]) or 0
                                            if candidate ~= 0 and candidate ~= curID then
                                                srcIdx = k
                                                break
                                            end
                                        end
                                    end
                                    if srcIdx > 0 and srcIdx <= #attachments then
                                        local newID = tonumber(attachments[srcIdx]) or 0
                                        if newID ~= 0 and newID ~= curID then
                                            pcall(function()
                                                local defRef = slua.IndexReference(slotData, "defineID")
                                                defRef.TypeSpecificID = newID
                                                slotData.operationType = 0
                                                AttachmentArray:Set(slotIdx, slotData)
                                            end)
                                            changed = true
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            return changed
        end

        local function applySkinToWeaponRef(CurWeapon)
            if not slua.isValid(CurWeapon) then return false end
            local AttachmentArray = CurWeapon.synData
            if not AttachmentArray or not slua.isValid(AttachmentArray) then return false end

            -- [XTHRLEN] slot 7 (attachments)
            local AttachmentData = AttachmentArray:Get(_K.GUN_MASTER_SYN_SLOT)
            if not AttachmentData then return false end

            local current_gunid = 0
            pcall(function()
                current_gunid = slua.IndexReference(AttachmentData, "defineID").TypeSpecificID or 0
            end)
            current_gunid = tonumber(current_gunid) or 0
            if current_gunid <= 0 then return false end

            local MaxIt = 0
            pcall(function()
                if CurWeapon.GetWeaponID then MaxIt = CurWeapon:GetWeaponID() end
                if MaxIt <= 0 then MaxIt = CurWeapon:GetItemDefineID().TypeSpecificID end
            end)
            MaxIt = tonumber(MaxIt) or 0
            if MaxIt <= 0 then return false end

            local tmp_id = get_skin_id(current_gunid, MaxIt)
            tmp_id = tonumber(tmp_id) or 0
            if tmp_id <= 0 then return false end
            if tmp_id == current_gunid and not isInjectedRes(tmp_id) then
                local ok, attChanged = pcall(applyAttachmentSkins, AttachmentArray, tmp_id)
                if ok and attChanged then
                    pcall(function()
                        local char = getLocalChar()
                        if char and char.AddGameTimer then
                            for _, delay in ipairs({0.3, 0.6, 1.0}) do
                                char:AddGameTimer(delay, false, function()
                                    if slua.isValid(CurWeapon) then
                                        local aa = CurWeapon.synData
                                        if aa and slua.isValid(aa) then
                                            pcall(applyAttachmentSkins, aa, tmp_id)
                                        end
                                    end
                                end)
                            end
                        end
                    end)
                end
                return false
            end
            if tmp_id == _S.lastAppliedSkinID and MaxIt == _S.lastAppliedWeaponID then
                local ok, attChanged = pcall(applyAttachmentSkins, AttachmentArray, tmp_id)
                if ok and attChanged then
                    pcall(function()
                        local char = getLocalChar()
                        if char and char.AddGameTimer then
                            for _, delay in ipairs({0.3, 0.6, 1.0}) do
                                char:AddGameTimer(delay, false, function()
                                    if slua.isValid(CurWeapon) then
                                        local aa = CurWeapon.synData
                                        if aa and slua.isValid(aa) then
                                            pcall(applyAttachmentSkins, aa, tmp_id)
                                        end
                                    end
                                end)
                            end
                        end
                    end)
                end
                return true
            end

            _G.AddOutfitLastAppliedSkin[current_gunid] = tmp_id
            pcall(function()
                local defRef = slua.IndexReference(AttachmentData, "defineID")
                defRef.TypeSpecificID = tmp_id
                local c0 = cfg(tmp_id)
                if c0 and c0.ItemType and defRef.Type ~= nil then defRef.Type = c0.ItemType end
                AttachmentData.operationType = 0
                AttachmentArray:Set(_K.GUN_MASTER_SYN_SLOT, AttachmentData)
            end)
            pcall(applyAttachmentSkins, AttachmentArray, tmp_id)
            if CurWeapon.DelayHandleAvatarMeshChanged then CurWeapon:DelayHandleAvatarMeshChanged() end
            -- [XTHRLEN] Delayed re-application of attachment skins to ensure attachments
            -- [XTHRLEN] are updated after the weapon finishes loading its default attachments.
            -- [XTHRLEN] This fixes the issue where attachments don't update until you swap them.
            pcall(function()
                local char = getLocalChar()
                if char and char.AddGameTimer then
                    for _, delay in ipairs({0.3, 0.6, 1.0}) do
                        char:AddGameTimer(delay, false, function()
                            if slua.isValid(CurWeapon) then
                                local aa = CurWeapon.synData
                                if aa and slua.isValid(aa) then
                                    pcall(applyAttachmentSkins, aa, tmp_id)
                                end
                            end
                        end)
                    end
                end
            end)
            _S.weaponHookGuardUntil = _S.globalFrame + 45
            _G.AddOutfitLastAppliedSkin[MaxIt] = tmp_id
            _S.lastAppliedWeaponID = MaxIt
            _S.lastAppliedSkinID = tmp_id
            return true
        end

        function _G.equip_weapon_avatar(uCharacter)
            if not uCharacter or not slua.isValid(uCharacter) then return false end
            buildSkinMappings()
            local WeaponManager = uCharacter:GetWeaponManager()
            if not WeaponManager or not slua.isValid(WeaponManager) then return false end
            local uWeaponList = WeaponManager:GetAllInventoryWeaponList(false)
            if not uWeaponList or not slua.isValid(uWeaponList) then return false end
            local appliedAny = false
            for i = 0, uWeaponList:Num() - 1 do
                local CurWeapon = uWeaponList:Get(i)
                if slua.isValid(CurWeapon) and applySkinToWeaponRef(CurWeapon) then
                    appliedAny = true
                end
            end
            return appliedAny
        end

        local function getDesiredWeaponSkins()
            syncWeaponCacheFromLobby()
            local out, seen = {}, {}
            local function add(res)
                res = tonumber(res)
                if res and res > 0 and not seen[res] then seen[res] = true; out[#out + 1] = res end
            end
            for _, w in pairs(cache().weapons) do add(w.resID) end
            if MATCH_CONFIG.weaponSkins then
                for _, res in pairs(MATCH_CONFIG.weaponSkins) do add(res) end
            end
            return out
        end

        local function registerWeaponAvatarItems(char)
            local pc = char.GetPlayerControllerSafety and char:GetPlayerControllerSafety()
            if not slua.isValid(pc) then return false end
            local BU = import("BackpackUtils")
            local AU = import("AvatarUtils")
            local addedCount = 0
            for _, resID in ipairs(getDesiredWeaponSkins()) do
                local doneDirect = false
                pcall(function()
                    if pc.AddWeaponAvatarItem then
                        pc:AddWeaponAvatarItem(tonumber(resID))
                        doneDirect = true
                        addedCount = addedCount + 1
                    end
                end)
                if not doneDirect then
                    pcall(function()
                        local skinBPID = BU.GetBPIDByResID(tonumber(resID))
                        local arr = slua.Array(UEnums.EPropertyClass.Int)
                        local parents = AU.GetWeaponAvatarParentIDList(skinBPID, arr, false)
                        if parents and parents.Num and parents:Num() > 0 and pc.WeaponAvatarItemList then
                            for _, parentID in pairs(parents) do
                                pc.WeaponAvatarItemList:Add(parentID, skinBPID)
                            end
                            addedCount = addedCount + 1
                        end
                    end)
                end
            end
            if addedCount == 0 then return false end
            pcall(function() if pc.InitWeaponAvatarItems then pc:InitWeaponAvatarItems() end end)
            pcall(function() if pc.OnWeaponAvatarUpdate then pc:OnWeaponAvatarUpdate() end end)
            _G.XTHRLENNotiff("Taking notes " .. addedCount .. "Weapon Housing")
            return true
        end

        local _lastMatchApplyWeapon = 0
        local function matchApplyWeaponSkin(char)
            local now = 0
            pcall(function() now = os.clock() end)
            if (now - _lastMatchApplyWeapon) < 0.5 then return false end  -- [XTHRLEN] throttle: max 2.5x/sec
            _lastMatchApplyWeapon = now
            buildSkinMappings()
            applyMatchWeaponSkinsToController()
            if not _S.avatarItemsRegistered then
                _S.avatarItemsRegistered = registerWeaponAvatarItems(char)
            end
            local curWeapon = char.GetCurrentWeapon and char:GetCurrentWeapon()
            if not slua.isValid(curWeapon) then
                return _G.equip_weapon_avatar(char)
            end

            local curWeaponResID = 0
            pcall(function() curWeaponResID = curWeapon:GetItemDefineID().TypeSpecificID end)
            local desiredSkin = get_skin_id(curWeaponResID, curWeaponResID)
            if curWeaponResID == _S.lastAppliedWeaponID and desiredSkin == _S.lastAppliedSkinID then
                pcall(_G.equip_weapon_avatar, char)
                return true
            end

            local ok = applySkinToWeaponRef(curWeapon)
            ok = _G.equip_weapon_avatar(char) or ok
            if ok then
                _S.lastAppliedWeaponID = curWeaponResID
                _S.lastAppliedSkinID = desiredSkin
                _S.weaponApplied = true
                _S.weaponDiagDone = true
                _G.XTHRLENNotiff("matchApplyWeaponSkin: " .. tostring(desiredSkin))
            end
            return ok
        end

        local function applyMatchThrowObjects()
            local pc = getPlayerController()
            if not pc or not slua.isValid(pc) then return false end
            local cch = cache()
            if not cch.throwObjects then
                log("applyMatchThrowObjects: no throwObjects in cache")
                return false
            end
            local hasThrow = false
            for st, info in pairs(cch.throwObjects) do
                if info.resID and info.resID > 0 then hasThrow = true end
            end
            if not hasThrow then
                log("applyMatchThrowObjects: throwObjects cache empty")
                return false
            end
            local applied = false
            pcall(function()
                -- [XTHRLEN] Try setting InitialConsumableAvatar fields (works if Lua table reference)
                if pc.InitialConsumableAvatar then
                    for st, info in pairs(cch.throwObjects) do
                        local key = _K.THROW_AVATAR_KEY[_K.THROW_SUB[st]]
                        if key and info.resID and info.resID > 0 then
                            pc.InitialConsumableAvatar[key] = info.resID
                            -- [XTHRLEN] log suppressed
                        end
                    end
                end
                -- [XTHRLEN] Rebuild grenade avatar list from InitialConsumableAvatar
                if pc.InitGrenadeAvatarList then
                    pc:InitGrenadeAvatarList(false)
                end
                -- [XTHRLEN] Fallback: directly add to GrenadeAvatarItemList (overwrites server entries)
                if pc.AddToGrenadeAvatarItemList then
                    for st, info in pairs(cch.throwObjects) do
                        if info.resID and info.resID > 0 and _K.THROW_SUB[st] then
                            pc:AddToGrenadeAvatarItemList(info.resID)
                            applied = true
                        end
                    end
                end
            end)
            return applied
        end

        local function matchApplyAll(char)
            local ok = false
            if not _S.matchOutfitDone then
                _S.matchOutfitDone = matchApplyOutfit(char)
                ok = _S.matchOutfitDone or ok
            end
            if applyMatchEquipAvatarToController() then ok = true end
            if matchApplyEquipSkins(char) then ok = true; _S.matchApplied = true end
            if matchApplyWeaponSkin(char) then ok = true end
            if applyMatchThrowObjects() then ok = true end
            return ok
        end

        -- [XTHRLEN]startMatchWatcher
        local function startMatchWatcher(char)
            if _S.matchTimer then return end
            _S.matchOutfitDone = false
            _S.avatarItemsRegistered = false
            _S.weaponApplied = false
            _S.weaponDiagDone = false
            _S.lastAppliedWeaponID = 0
            _S.lastAppliedSkinID = 0

            local attempts = 0

            _S.matchTimer = char:AddGameTimer(1.0, true, function()
                attempts = attempts + 1
                local cur = getLocalChar()
                if not cur or not slua.isValid(cur) then return end
                pcall(matchApplyAll, cur)
                if attempts >= 30 then
                    pcall(function() if cur.RemoveGameTimer then cur:RemoveGameTimer(_S.matchTimer) end end)
                    _S.matchTimer = nil
                end
            end)
        end
        -- [XTHRLEN]AdditionalData hook
        -- [XTHRLEN] GetWeaponAvatarRes
        local _hookedGetWeaponAvatarRes = false

        local function hookBackpackWeaponAvatarRes()
            if _hookedGetWeaponAvatarRes then return end
            _hookedGetWeaponAvatarRes = true
            pcall(function()
                local BPL = require("GameLua.Mod.BaseMod.Client.Backpack.BackPackFunctionLibrary")
                if BPL and BPL.GetWeaponAvatarRes and not BPL._lava_hooked_avatar_res then
                    BPL._lava_hooked_avatar_res = true
                    local _bpAvatarResCache = {}
                    local _bpAvatarResTicks = {}
                    local _bpResCacheAge = 0
                    local origGetRes = BPL.GetWeaponAvatarRes
                    BPL.GetWeaponAvatarRes = function(WeaponID, AdditionalDataArray)
                        WeaponID = tonumber(WeaponID) or 0
                        if WeaponID <= 0 then return origGetRes(WeaponID, AdditionalDataArray) end
                        -- [XTHRLEN] Cache with invalidation every ~5 seconds via frame count
                        local cached = _bpAvatarResCache[WeaponID]
                        local age = _bpResCacheAge
                        local nowTick = _S.globalFrame or 0
                        if cached and (nowTick - (_bpAvatarResTicks[WeaponID] or 0)) < 150 then
                            return cached, ""
                        end
                        local targetSkinID = 0
                        -- [XTHRLEN] 1) map directly from cache weapons
                        local cch = cache()
                        local typeId = resolveWeaponTypeID(WeaponID)
                        local w = cch.weapons[typeId] or cch.weapons[WeaponID]
                        if w and w.resID and w.resID > 0 then
                            targetSkinID = w.resID
                        end
                        -- [XTHRLEN] 2) fallback to get_skin_id
                        if targetSkinID <= 0 or targetSkinID == WeaponID then
                            local sid = get_skin_id(WeaponID, WeaponID)
                            targetSkinID = tonumber(sid) or 0
                        end
                        -- [XTHRLEN] Cache result
                        if targetSkinID > 0 and targetSkinID ~= WeaponID then
                            _bpAvatarResCache[WeaponID] = targetSkinID
                            _bpAvatarResTicks[WeaponID] = nowTick
                            local skinCfg = cfg(targetSkinID)
                            if skinCfg then
                                return targetSkinID, ""
                            end
                        end
                        _bpAvatarResCache[WeaponID] = WeaponID
                        _bpAvatarResTicks[WeaponID] = nowTick
                        return origGetRes(WeaponID, AdditionalDataArray)
                    end
                    log("[AddOutfit] hookBackpackWeaponAvatarRes")
                end
            end)
        end

        local _lastVehicleSkinKey = ""

        local function applyVehicleSkinInGame()
            local char = getLocalChar()
            if not char or not slua.isValid(char) then return end

            local vehicle = char.GetCurrentVehicle and char:GetCurrentVehicle()
            if not vehicle or not slua.isValid(vehicle) then
                _lastVehicleSkinKey = ""
                return
            end
            pcall(syncVehicleAvatarSkinList)

            local avatarComp = vehicle.GetAvatarComponent and vehicle:GetAvatarComponent()
            if not avatarComp or not slua.isValid(avatarComp) then return end

            local defaultAvatarID = avatarComp.GetDefaultAvatarID and avatarComp:GetDefaultAvatarID()
            if not defaultAvatarID or defaultAvatarID == 0 then return end

            local currentAvatarID = avatarComp.GetCurrentAvatarID and avatarComp:GetCurrentAvatarID()

            local cacheKey = tostring(vehicle) .. "_" .. tostring(defaultAvatarID) .. "_" .. tostring(currentAvatarID)
            if cacheKey == _lastVehicleSkinKey then return end

            -- [XTHRLEN]itemSubType Item
            local vehicleSubType = 0
            local defaultItemCfg = cfg(defaultAvatarID)
            if defaultItemCfg then
                vehicleSubType = tonumber(defaultItemCfg.ItemSubType or defaultItemCfg.itemSubType) or 0
            end

            -- [XTHRLEN]VehicleSlotList
            local desiredSkins = {}
            local firstSkinResID = 0
            if vehicleSubType > 0 and DataMgr and DataMgr.VehicleSlotList then
                local slotList = DataMgr.VehicleSlotList[vehicleSubType]
                if slotList then
                    for i = 1, #slotList do
                        local skinInsID = tonumber(slotList[i])
                        if skinInsID and skinInsID > 0 then
                            local skinResID = 0
                            if isInjectedIns(skinInsID) then
                                skinResID = R.insToRes[skinInsID] or 0
                            else
                                pcall(function()
                                    local wd = require("client.slua.logic.wardrobe.wardrobe_data")
                                    local d = wd:GetHallDepotItemDataByInsID(skinInsID)
                                    skinResID = d and tonumber(d.resID) or 0
                                end)
                            end
                            if skinResID > 0 then
                                desiredSkins[skinResID] = true
                                if firstSkinResID == 0 then
                                    firstSkinResID = skinResID
                                end
                            end
                        end
                    end
                end
            end

            if vehicleSubType > 0 then
                pcall(function()
                    local pc = getPlayerController()
                    if pc and pc.PlayerState then
                        local vst = pc.PlayerState.vst_in_battle
                        if vst and vst[vehicleSubType] then
                            local resList = vst[vehicleSubType]
                            if resList and type(resList) == "table" then
                                for _, resID in ipairs(resList) do
                                    resID = tonumber(resID)
                                    if resID and resID > 0 then
                                        if not desiredSkins[resID] then
                                            desiredSkins[resID] = true
                                            if firstSkinResID == 0 then
                                                firstSkinResID = resID
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
            end

            if firstSkinResID == 0 and DataMgr and DataMgr.VehicleSlotList then
                local defStr = tostring(defaultAvatarID)
                for subType, insList in pairs(DataMgr.VehicleSlotList) do
                    if insList and type(insList) == "table" then
                        for i = 1, #insList do
                            local skinInsID = tonumber(insList[i])
                            if skinInsID and skinInsID > 0 then
                                local rid = 0
                                if isInjectedIns(skinInsID) then
                                    rid = R.insToRes[skinInsID] or 0
                                else
                                    pcall(function()
                                        local wd = require("client.slua.logic.wardrobe.wardrobe_data")
                                        local d = wd:GetHallDepotItemDataByInsID(skinInsID)
                                        rid = d and tonumber(d.resID) or 0
                                    end)
                                end
                                if rid > 0 then
                                    local skinCfg = cfg(rid)
                                    if skinCfg then
                                        local skinDefault = skinCfg.DefaultAvatarID or skinCfg.defaultAvatarID
                                        if skinDefault and tostring(skinDefault):find(defStr, 1, true) then
                                            if not desiredSkins[rid] then
                                                desiredSkins[rid] = true
                                                firstSkinResID = rid
                                            end
                                            break
                                        end
                                    end
                                end
                            end
                        end
                        if firstSkinResID > 0 then break end
                    end
                end
            end

            if currentAvatarID and desiredSkins[currentAvatarID] then
                _lastVehicleSkinKey = cacheKey
                return
            end

            local skinResID = firstSkinResID

            if skinResID == 0 then
                _lastVehicleSkinKey = cacheKey
                return
            end

            pcall(function()
                local pc = getPlayerController()
                if pc and avatarComp.SetVehicleNetAvatarData then
                    avatarComp:SetVehicleNetAvatarData(pc)
                end

                if avatarComp.VehicleNetAvatarData then
                    avatarComp.VehicleNetAvatarData.SwitchEffectId = 7303001
                    avatarComp.VehicleNetAvatarData.UpdateFlag = 1
                end
                avatarComp:ChangeItemAvatar(skinResID, true)
                avatarComp.CanChangeAvatar = true
            end)

            pcall(applyVehicleChassisLight)

            _lastVehicleSkinKey = cacheKey
        end

        -- [XTHRLEN] (Chassis Light)
        local _LAVA_CHASSIS_LIGHT_ID = 7302002

        local function isLocalPlayerVehicle(vehicle)
            if not vehicle or not slua.isValid(vehicle) then return false end
            local char = getLocalChar()
            if not char or not slua.isValid(char) then return false end
            local currentVehicle = char.GetCurrentVehicle and char:GetCurrentVehicle()
            if currentVehicle and currentVehicle == vehicle then return true end
            local driver = nil
            pcall(function() driver = vehicle.GetDriver and vehicle:GetDriver() end)
            if driver and driver == char then return true end
            return false
        end

        local function getVehicleSkinID(vehicle)
            if not vehicle or not slua.isValid(vehicle) then return 0 end
            local skinID = 0
            pcall(function()
                if vehicle.GetVehicleSkinItemID then
                    skinID = vehicle:GetVehicleSkinItemID() or 0
                end
            end)
            if skinID and skinID > 0 then return skinID end
            pcall(function()
                if vehicle.ClientUsedAvatarID then
                    skinID = vehicle.ClientUsedAvatarID
                end
            end)
            if skinID and skinID > 0 then return skinID end
            pcall(function()
                local avatarComp = vehicle.GetAvatarComponent and vehicle:GetAvatarComponent()
                if avatarComp and slua.isValid(avatarComp) and avatarComp.GetCurrentAvatarID then
                    skinID = avatarComp:GetCurrentAvatarID() or 0
                end
            end)
            return skinID or 0
        end

        local function vehicleHasSkinApplied(vehicle)
            if not vehicle or not slua.isValid(vehicle) then return false end
            local skinID = getVehicleSkinID(vehicle)
            if skinID <= 0 then return false end
            local defaultID = 0
            pcall(function()
                local avatarComp = vehicle.GetAvatarComponent and vehicle:GetAvatarComponent()
                if avatarComp and slua.isValid(avatarComp) and avatarComp.GetDefaultAvatarID then
                    defaultID = avatarComp:GetDefaultAvatarID() or 0
                end
            end)
            return skinID ~= defaultID
        end

        local function forceVehicleChassisLight(vehicle)
            if not vehicle or not slua.isValid(vehicle) then return end
            local licenseComp = vehicle.GetLicenseComponent and vehicle:GetLicenseComponent()
            if not licenseComp or not slua.isValid(licenseComp) then
                print("[AddOutfit] forceVehicleChassisLight: no licenseComp")
                return
            end
            if not licenseComp.LicensePlate then
                print("[AddOutfit] forceVehicleChassisLight: no LicensePlate")
                return
            end
            if licenseComp.LicensePlate.ChassisLightId == _LAVA_CHASSIS_LIGHT_ID and slua.isValid(licenseComp.ChassisLightMesh) then
                return
            end
            local skinID = getVehicleSkinID(vehicle)
            if skinID > 0 then
                licenseComp.LicensePlate.ItemID = skinID
            end
            licenseComp.LicensePlate.ChassisLightId = _LAVA_CHASSIS_LIGHT_ID
            if licenseComp.curVehicleAvatarId == nil or licenseComp.curVehicleAvatarId == 0 then
                licenseComp.curVehicleAvatarId = skinID
            end
            print("[AddOutfit] forceVehicleChassisLight: skinID=" .. tostring(skinID) .. " ChassisLightId=" .. tostring(_LAVA_CHASSIS_LIGHT_ID) .. " ItemID=" .. tostring(licenseComp.LicensePlate.ItemID))
            if licenseComp.PreChangeChassisLight then
                pcall(function() licenseComp:PreChangeChassisLight() end)
            end
        end

        local function applyVehicleChassisLight()
            local char = getLocalChar()
            if not char or not slua.isValid(char) then return end
            local vehicle = char.GetCurrentVehicle and char:GetCurrentVehicle()
            if not vehicle or not slua.isValid(vehicle) then return end
            if not isLocalPlayerVehicle(vehicle) then return end
            if not vehicleHasSkinApplied(vehicle) then return end
            forceVehicleChassisLight(vehicle)
        end

        local function hookVehicleLicenseComponentBase()
            local ok, VLB = pcall(require, "GameLua.Activity.Commercialize.Actor.ActorComponent.BP_VehicleLicenseComponentBase")
            if not ok or not VLB then return end
            local impl = VLB.__inner_impl
            if not impl or type(impl) ~= "table" then return end
            if impl._lava_hooked_chassis then return end
            impl._lava_hooked_chassis = true

            local origCheckDownloaded = impl.CheckHasVehicleDownloaded
            impl.CheckHasVehicleDownloaded = function(self, ItemID)
                local vehicle = self:GetOwner()
                if isLocalPlayerVehicle(vehicle) and vehicleHasSkinApplied(vehicle) then
                    return true
                end
                return origCheckDownloaded(self, ItemID)
            end

            local origPreChange = impl.PreChangeChassisLight
            impl.PreChangeChassisLight = function(self)
                pcall(function()
                    local vehicle = self:GetOwner()
                    if isLocalPlayerVehicle(vehicle) and vehicleHasSkinApplied(vehicle) then
                        if self.LicensePlate then
                            local skinID = getVehicleSkinID(vehicle)
                            if skinID > 0 then
                                self.LicensePlate.ItemID = skinID
                            end
                            self.LicensePlate.ChassisLightId = _LAVA_CHASSIS_LIGHT_ID
                        end
                    end
                end)
                return origPreChange(self)
            end

            local origAsyncLoad = impl.AsyncLoadAccessoryItemHandle
            if origAsyncLoad then
                impl.AsyncLoadAccessoryItemHandle = function(self, itemId, bCheckDownload)
                    if itemId == _LAVA_CHASSIS_LIGHT_ID then
                        bCheckDownload = false
                    end
                    return origAsyncLoad(self, itemId, bCheckDownload)
                end
            end

            local origAsyncLoadHandle = impl._AsyncLoadHandle
            if origAsyncLoadHandle then
                impl._AsyncLoadHandle = function(self, ItemID)
                    if ItemID == _LAVA_CHASSIS_LIGHT_ID then
                        pcall(function()
                            local UBackpackUtils = import("BackpackUtils")
                            local handlePath = self:GetAccessoryAvatarHandlePath(ItemID)
                            local itemCfg = CDataTable.GetTableData("Item", ItemID)
                            if handlePath and itemCfg and itemCfg.BPID then
                                local bpCfg = CDataTable.GetTableData("AvatarBPTable", itemCfg.BPID)
                                if bpCfg and bpCfg.AvatarBPPath and bpCfg.AvatarBPPath ~= "" then
                                    self:AsyncLoadAsset(handlePath, self.OnAccHandleLoaded, self, ItemID, itemCfg.BPID)
                                    return
                                end
                            end
                            print("[AddOutfit] _AsyncLoadHandle bypass failed for chassis light, trying direct load")
                        end)
                    end
                    return origAsyncLoadHandle(self, ItemID)
                end
            end

            local origOnRep = impl.OnRep_LicensePlate
            if origOnRep then
                impl.OnRep_LicensePlate = function(self)
                    local bReapply = false
                    pcall(function()
                        local vehicle = self:GetOwner()
                        if isLocalPlayerVehicle(vehicle) and vehicleHasSkinApplied(vehicle) then
                            bReapply = true
                            if self.LicensePlate then
                                local skinID = getVehicleSkinID(vehicle)
                                if skinID > 0 then
                                    self.LicensePlate.ItemID = skinID
                                end
                                self.LicensePlate.ChassisLightId = _LAVA_CHASSIS_LIGHT_ID
                            end
                        end
                    end)
                    local result = origOnRep(self)
                    if bReapply then
                        pcall(function()
                            if self.LicensePlate then
                                local skinID = getVehicleSkinID(self:GetOwner())
                                if skinID > 0 then
                                    self.LicensePlate.ItemID = skinID
                                end
                                self.LicensePlate.ChassisLightId = _LAVA_CHASSIS_LIGHT_ID
                            end
                            if self.PreChangeChassisLight then
                                self:PreChangeChassisLight()
                            end
                        end)
                    end
                    return result
                end
            end

            local origOnVehicleMesh = impl.OnVehicleMeshAvatarEquiped
            if origOnVehicleMesh then
                impl.OnVehicleMeshAvatarEquiped = function(self, expectItemId)
                    local result = origOnVehicleMesh(self, expectItemId)
                    pcall(function()
                        local vehicle = self:GetOwner()
                        if isLocalPlayerVehicle(vehicle) and vehicleHasSkinApplied(vehicle) then
                            if self.LicensePlate then
                                local skinID = getVehicleSkinID(vehicle)
                                if skinID > 0 then
                                    self.LicensePlate.ItemID = skinID
                                end
                                self.LicensePlate.ChassisLightId = _LAVA_CHASSIS_LIGHT_ID
                            end
                            if self.PreChangeChassisLight then
                                self:PreChangeChassisLight()
                            end
                        end
                    end)
                    return result
                end
            end
            print("[AddOutfit] VehicleLicenseComponentBase chassis hook installed")
        end

        local function hookVehiclePlateLicenseUtil()
            local ok, VPLU = pcall(require, "GameLua.Activity.Commercialize.GamePlay.Vehicle.VehiclePlateLicenseUtil")
            if not ok or not VPLU then return end
            if VPLU._lava_hooked_chassis then return end
            VPLU._lava_hooked_chassis = true
            local origGetLoc = VPLU.GetChassisLightLocAndScale
            VPLU.GetChassisLightLocAndScale = function(vehicleId, bIsLobbyVehicle)
                local loc, scale = origGetLoc(vehicleId, bIsLobbyVehicle)
                if loc and scale then
                    return loc, scale
                end
                local defaultLoc = FVector(0, -20, 10)
                local defaultScale = FVector(6.5, 7, 1)
                print("[AddOutfit] GetChassisLightLocAndScale fallback defaults for vehicleId:" .. tostring(vehicleId))
                return defaultLoc, defaultScale
            end
            print("[AddOutfit] VehiclePlateLicenseUtil chassis hook installed")
        end

        local function hookServerChangeVehicleAvatar(pc)
            if not pc or not slua.isValid(pc) then return end
            if pc._lava_hooked_server_vehicle_skin then return end
            if not pc.ServerChangeVehicleAvatar then return end
            pc._lava_hooked_server_vehicle_skin = true
            local orig = pc.ServerChangeVehicleAvatar
            local hooked = function(self, resID)
                pcall(function()
                    local char = self:GetPlayerCharacterSafety()
                    if char and slua.isValid(char) then
                        local vehicle = char.GetCurrentVehicle and char:GetCurrentVehicle()
                        if vehicle and slua.isValid(vehicle) then
                            local avatarComp = vehicle.GetAvatarComponent and vehicle:GetAvatarComponent()
                            if avatarComp and slua.isValid(avatarComp) then
                                if avatarComp.SetVehicleNetAvatarData then
                                    avatarComp:SetVehicleNetAvatarData(self)
                                end
                                if avatarComp.VehicleNetAvatarData then
                                    avatarComp.VehicleNetAvatarData.SwitchEffectId = 7303001
                                    avatarComp.VehicleNetAvatarData.UpdateFlag = 1
                                end
                                avatarComp:ChangeItemAvatar(resID, true)
                                avatarComp.CanChangeAvatar = true
                                _lastVehicleSkinKey = ""
                                print("[AddOutfit] Vehicle skin changed locally to " .. tostring(resID))
                                pcall(applyVehicleChassisLight)
                            end
                        end
                    end
                end)
            end
            pcall(function() rawset(pc, "ServerChangeVehicleAvatar", hooked) end)
        end

        local _lava_skin_click_handler
        local function getSkinClickHandler()
            if _lava_skin_click_handler then return _lava_skin_click_handler end
            _lava_skin_click_handler = function(self)
                if self.resID > 0 then
                    local UsingID = self:GetLoopScrollBoxParentUI():GetCurUsingSkinID()
                    if self.resID ~= UsingID then
                        pcall(function()
                            local GameplayData = require("GameLua.GameCore.Data.GameplayData")
                            local PlayerController = GameplayData.GetPlayerController()
                            if not slua.isValid(PlayerController) then return end
                            local char = PlayerController:GetPlayerCharacterSafety()
                            if not char or not slua.isValid(char) then return end
                            local vehicle = char.GetCurrentVehicle and char:GetCurrentVehicle()
                            if not vehicle or not slua.isValid(vehicle) then return end
                            local avatarComp = vehicle.GetAvatarComponent and vehicle:GetAvatarComponent()
                            if not avatarComp or not slua.isValid(avatarComp) then return end
                            if avatarComp.SetVehicleNetAvatarData then
                                avatarComp:SetVehicleNetAvatarData(PlayerController)
                            end
                            if avatarComp.VehicleNetAvatarData then
                                avatarComp.VehicleNetAvatarData.SwitchEffectId = 7303001
                                avatarComp.VehicleNetAvatarData.UpdateFlag = 1
                            end
                            avatarComp:ChangeItemAvatar(self.resID, true)
                            avatarComp.CanChangeAvatar = true
                            _lastVehicleSkinKey = ""
                            print("[AddOutfit] VehicleSkinItem applied skin locally " .. tostring(self.resID))
                            pcall(applyVehicleChassisLight)
                        end)
                    end
                end
                if EventSystem and EVENTYPE_INGAME_VEHICLE_CONTROL_PANEL and EVENTID_CHANGE_VEHICLESKIN_BUTTON_CLICK then
                    EventSystem:postEvent(EVENTYPE_INGAME_VEHICLE_CONTROL_PANEL, EVENTID_CHANGE_VEHICLESKIN_BUTTON_CLICK)
                end
            end
            return _lava_skin_click_handler
        end

        local function hookVehicleSkinItem()
            local ok, VSI = pcall(require, "GameLua.Mod.BaseMod.Client.InGameUI.VehicleControl.VehicleSkinItem")
            if not ok or not VSI then return end

            local impl = VSI.__inner_impl
            if not impl or type(impl) ~= "table" then return end
            if impl._lava_hooked_skin_item then return end
            impl._lava_hooked_skin_item = true
            local handler = getSkinClickHandler()
            local origRegist = impl.RegistEvents
            impl.RegistEvents = function(self)
                rawset(self, "OnClickSkinButton", handler)
                return origRegist(self)
            end
            local origOnRefresh = impl.OnRefresh
            impl.OnRefresh = function(self, resID, selectIndex)
                local cur = rawget(self, "OnClickSkinButton")
                if cur ~= handler then
                    rawset(self, "OnClickSkinButton", handler)
                    pcall(function()
                        if self.UnRegistEvents and self.RegistEvents then
                            self:UnRegistEvents()
                            self:RegistEvents()
                        end
                    end)
                end
                return origOnRefresh(self, resID, selectIndex)
            end
            impl.OnClickSkinButton = handler
        end

        local function hookVehicleSkinAndMusicPanel()
            local ok, VSP = pcall(require, "GameLua.Mod.BaseMod.Client.InGameUI.VehicleControl.VehicleSkinAndMusicPanel")
            if not ok or not VSP then return end
            local impl = VSP.__inner_impl
            if not impl or type(impl) ~= "table" then return end
            if impl._lava_hooked_panel then return end
            impl._lava_hooked_panel = true
            local orig = impl.InitSkinList
            impl.InitSkinList = function(self)
                hookVehicleSkinItem()
                return orig(self)
            end
        end

        local function syncVehicleAvatarSkinList()
            local pc = getPlayerController()
            if not pc or not slua.isValid(pc) then return end
            hookServerChangeVehicleAvatar(pc)
            hookVehicleSkinItem()
            hookVehicleSkinAndMusicPanel()
            hookVehicleLicenseComponentBase()
            hookVehiclePlateLicenseUtil()
            if pc.bEnableFuzzyAvatarOnClient then
                pc.bEnableFuzzyAvatarOnClient = false
            end
            if not DataMgr or not DataMgr.VehicleSlotList then return end
            if not pc.InitVehicleAvatarSkinList then return end
            local vehicleSkinData = {}
            for subType, insList in pairs(DataMgr.VehicleSlotList) do
                if insList and type(insList) == "table" then
                    local itemArray = {}
                    for _, insID in ipairs(insList) do
                        insID = tonumber(insID)
                        if insID and insID > 0 then
                            local skinResID = 0
                            if isInjectedIns(insID) then
                                skinResID = R.insToRes[insID] or 0
                            else
                                pcall(function()
                                    local wd = require("client.slua.logic.wardrobe.wardrobe_data")
                                    local d = wd:GetHallDepotItemDataByInsID(insID)
                                    skinResID = d and tonumber(d.resID) or 0
                                end)
                            end
                            if skinResID and skinResID > 0 then
                                table.insert(itemArray, {ItemTableID = skinResID, Count = 1})
                            end
                        end
                    end
                    if #itemArray > 0 then
                        table.insert(vehicleSkinData, {Items = itemArray})
                    end
                end
            end
            if #vehicleSkinData > 0 then
                pc.InitialVehicleAvatarSkinList = vehicleSkinData
                pc:InitVehicleAvatarSkinList()
            end
        end

        local function stopMatchWatcher()
            if _S.matchTimer then
                pcall(function()
                    local char = getLocalChar()
                    if char and char.RemoveGameTimer then char:RemoveGameTimer(_S.matchTimer) end
                end)
                _S.matchTimer = nil
            end
            _S.matchOutfitDone = false
            _S.avatarItemsRegistered = false
            _S.weaponApplied = false
            _S.weaponDiagDone = false
            _S.lastAppliedWeaponID = 0
            _S.lastAppliedSkinID = 0
            _S.matchApplied = false
            _S.bootstrapped = false
        end

        local function bootstrapMatch(char)
            if _S.bootstrapped then return true end
            char = char or getLocalChar()
            if not char or not slua.isValid(char) then return false end
            snapshotLobbyWear()
            _S.weaponApplied = false
            _S.weaponDiagDone = false
            _S.matchOutfitDone = false
            if not _S.bootstrapNotified then
                _S.bootstrapNotified = true
                _G.XTHRLENNotiff("bootstrapMatch")
            end
            startMatchWatcher(char)
            hookPlayerWearingDone()
            matchApplyAll(char)
            _S.bootstrapped = true
            return true
        end

        local function isSelfAvatarComp(self)
            if not self or not self.IsSelf then return true end
            local ok, r = pcall(function() return self:IsSelf() end)
            return ok and r == true
        end

        local function hookMatchAvatar()
            pcall(function()
                if EventSystem and EventSystem.registEvent
                    and EVENTTYPE_PLAYEREVENT_AVATAR and EVENTID_LOCAL_PLAYEREVENT_AVATAR_ALL_MESH_LOADED then
                    EventSystem:registEvent(EVENTTYPE_PLAYEREVENT_AVATAR, EVENTID_LOCAL_PLAYEREVENT_AVATAR_ALL_MESH_LOADED, function()
                        if isInLobby() then return end
                        local char = getLocalChar()
                        if char then
                            hookPlayerWearingDone()
                            applyMatchEquipAvatarToController()
                            matchApplyEquipSkins(char)
                        end
                    end)
                end
            end)
            pcall(function()
                local CAC = require("GameLua.Mod.Library.GamePlay.Avatar.Component.CharacterAvatarComponent")
                if not CAC._lava_hooked_mesh then
                    CAC._lava_hooked_mesh = true
                    local o = CAC.OnAvatarAllMeshLoadedLua
                    CAC.OnAvatarAllMeshLoadedLua = function(self)
                        o(self)
                        pcall(function()
                            if self.IsLobbyActor and self:IsLobbyActor() then return end
                            if not (self.IsSelf and self:IsSelf()) then return end
                            local char = getLocalChar()
                            if char and char.AddGameTimer then
                                char:AddGameTimer(0.5, false, function() bootstrapMatch(char) end)
                            end
                        end)
                    end
                end
            end)
            pcall(function()
                local WAC = require("GameLua.Mod.Library.GamePlay.Avatar.Component.WeaponAvatarComponent")
                local oLoad = WAC.OnWeaponAvatarLoadedLua
                WAC.OnWeaponAvatarLoadedLua = function(self, slotID, definedID)
                    oLoad(self, slotID, definedID)
                    pcall(function()
                        if self.IsLobbyActor and self:IsLobbyActor() then return end
                        if not isSelfAvatarComp(self) then return end
                        if _S.globalFrame < _S.weaponHookGuardUntil then return end
                        local char = getLocalChar()
                        if not char then return end
                        bootstrapMatch(char)
                        _S.weaponApplied = false
                        if char.AddGameTimer then
                            char:AddGameTimer(0.2, false, function()
                                local c = getLocalChar()
                                if c then matchApplyWeaponSkin(c) end
                            end)
                            -- [XTHRLEN] Extra delayed pass for attachment skins
                            char:AddGameTimer(0.5, false, function()
                                local c = getLocalChar()
                                if c then matchApplyWeaponSkin(c) end
                            end)
                        end
                    end)
                end
            end)
        end

        local function onWeaponLuaInit(_, _, weapon)
            if not weapon or not slua.isValid(weapon) then return end
            local char = getLocalChar()
            if not char then return end
            local owner = nil
            pcall(function() if weapon.GetOwnerPawn then owner = weapon:GetOwnerPawn() end end)
            if not slua.isValid(owner) or owner ~= char then return end
            if _S.globalFrame < _S.weaponHookGuardUntil then return end
            pcall(function()
                char:AddGameTimer(0.5, false, function()
                    if slua.isValid(weapon) then
                        applySkinToWeaponRef(weapon)
                        _S.weaponApplied = false
                    end
                end)
                -- [XTHRLEN] Extra delayed pass for attachment skins
                char:AddGameTimer(0.5, false, function()
                    if slua.isValid(weapon) then
                        applySkinToWeaponRef(weapon)
                    end
                end)
            end)
        end

        local function hookWeaponSpawn()
            if _S.weaponSpawnHooked then return end
            pcall(function()
                if EventSystem and EventSystem.registEvent
                    and EVENTTYPE_PLAYEREVENT_WEAPON and EVENTID_PLAYEREVENT_WEAPON_LUA_INIT then
                    EventSystem:registEvent(EVENTTYPE_PLAYEREVENT_WEAPON, EVENTID_PLAYEREVENT_WEAPON_LUA_INIT, onWeaponLuaInit)
                    _S.weaponSpawnHooked = true
                end
            end)
        end

        local function hookLobbyWeaponCache()
            pcall(function()
                local Arm = require("client.logic.armory.logic_armory")
                local oRsp = Arm.install_weapon_skin_rsp
                Arm.install_weapon_skin_rsp = function(client_data, errorCode, weapon_id, instanceID)
                    oRsp(client_data, errorCode, weapon_id, instanceID)
                    if errorCode == 0 or errorCode == _K.NET_OK then
                        cacheWeaponSkinFromIns(weapon_id, instanceID)
                    end
                end
            end)
            pcall(function()
                local wl = require("client.slua.logic.wardrobe.logic_wardrobe_new")
                local o = wl.on_puton_rsp
                wl.on_puton_rsp = function(self, res, item, olditem, index, extra)
                    o(self, res, item, olditem, index, extra)
                    if item and item.instid and (res == 0 or res == _K.NET_OK) then
                        local resID, insID = tonumber(item.res_id), tonumber(item.instid)
                        local slot = getEquipSkinSlot(resID)
                        if isInjectedIns(insID) and slot and not _S.equipSkinApplying then
                            saveEquipSkin(resID, insID)
                            if slot ~= "parachute" and slot ~= "glider" then
                                applyEquipVisual(resID, insID, slot)
                            end
                        elseif isInjectedIns(insID) then
                            local mt = wardrobeMainTab(resID)
                            if mt ~= _K.WARDROBE_PAGE_VEHICLE then
                                if isThrowObjectRes(resID) then
                                    saveThrowObject(resID, insID)
                                else
                                    saveEquip(resID, insID)
                                end
                            end
                        end
                    end
                end
            end)
        end

        local function hookGunWardrobe()
            pcall(function()
                local wgl = require("client.slua.logic.wardrobe.logic_wardrobe_gun")
                if wgl._lava_gun_hooked then return end
                wgl._lava_gun_hooked = true

                local origSetGunID = wgl.SetGunID
                wgl.SetGunID = function(self, weaponID, ...)
                    weaponID = tonumber(weaponID)
                    if not weaponID then return origSetGunID(self, weaponID, ...) end

                    local w = cache().weapons[weaponID]
                    local injected = w and w.insID and w.insID > 0 and isInjectedIns(w.insID)
                    local currentSkin = wgl.GetCurrentEquippedSkinInsID and wgl:GetCurrentEquippedSkinInsID(weaponID) or 0
                    if injected and currentSkin == w.insID then
                        return origSetGunID(self, weaponID, ...)
                    end

                    if injected then
                        pcall(function()
                            local Arm = require("client.logic.armory.logic_armory")
                            Arm.rsp_list = Arm.rsp_list or { skin_list = {}, install_list = {} }
                            Arm.rsp_list.install_list = Arm.rsp_list.install_list or {}
                            Arm.rsp_list.install_list[weaponID] = { skin_id = w.insID }

                            local fbd = require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
                            if fbd.UpdateCurrentFashionBagWeaponSkin then
                                fbd:UpdateCurrentFashionBagWeaponSkin(weaponID, w.insID)
                            end
                            if fbd.SetFashionBagWeaponSkin then
                                fbd:SetFashionBagWeaponSkin(weaponID, w.insID)
                            end
                        end)
                    else
                        pcall(function()
                            local Arm = require("client.logic.armory.logic_armory")
                            if Arm.rsp_list and Arm.rsp_list.install_list then
                                Arm.rsp_list.install_list[weaponID] = nil
                            end
                            local fbd = require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
                            if fbd.UpdateCurrentFashionBagWeaponSkin then
                                fbd:UpdateCurrentFashionBagWeaponSkin(weaponID, 0)
                            end
                            local bag = fbd.GetCurrentFashionBag and fbd:GetCurrentFashionBag()
                            if bag and bag.weapon_skin_list then
                                bag.weapon_skin_list[weaponID] = nil
                            end
                        end)
                    end

                    local result = origSetGunID(self, weaponID, ...)

                    if injected then
                        later(0.05, function()
                            pcall(function()
                                local wgl2 = require("client.slua.logic.wardrobe.logic_wardrobe_gun")
                                wgl2:UpdateCurrentGunAvatar(weaponID, w.insID)

                                if EventSystem then
                                    if EVENTTYPE_WARDROBE and EVENTID_WARDROBE_UPDATE_CURRENT_PUT_ON_GUN then
                                        EventSystem:postEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_UPDATE_CURRENT_PUT_ON_GUN, w.resID)
                                    end
                                    if EVENTTYPE_WARDROBE and EVENTID_WARDROBE_UPDATE_GUN_LIST then
                                        EventSystem:postEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_UPDATE_GUN_LIST, -1)
                                    end
                                    if EVENTTYPE_ARMORY and EVENTID_ARMORY_EQUIP_STAT_CHANGE then
                                        EventSystem:postEvent(EVENTTYPE_ARMORY, EVENTID_ARMORY_EQUIP_STAT_CHANGE, w.resID)
                                    end
                                end
                            end)
                        end)
                    else
                        later(0.05, function()
                            pcall(function()
                                local wgl2 = require("client.slua.logic.wardrobe.logic_wardrobe_gun")
                                wgl2:UpdateCurrentGunAvatar(weaponID, 0)
                                if EventSystem and EVENTTYPE_WARDROBE and EVENTID_WARDROBE_UPDATE_CURRENT_PUT_ON_GUN then
                                    EventSystem:postEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_UPDATE_CURRENT_PUT_ON_GUN, 0)
                                end
                                if EventSystem and EVENTID_WARDROBE_UPDATE_GUN_LIST then
                                    EventSystem:postEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_UPDATE_GUN_LIST, weaponID)
                                end
                            end)
                        end)
                        log("injected", weaponID)
                    end

                    return result
                end

                local origUpdateGunAvatar = wgl.UpdateCurrentGunAvatar
                wgl.UpdateCurrentGunAvatar = function(self, weaponID, insID, ...)
                    weaponID = tonumber(weaponID)
                    insID = tonumber(insID)
                    if weaponID and (not insID or insID <= 0) then
                        local w = cache().weapons[weaponID]
                        if w and w.insID and w.insID > 0 and isInjectedIns(w.insID) then
                            insID = w.insID
                            log("UpdateCurrentGunAvatar", weaponID, insID)
                        else
                            insID = 0
                        end
                    end
                    return origUpdateGunAvatar(self, weaponID, insID, ...)
                end

                if wgl.GetCurrentEquippedSkinInsID then
                    local origGetCurSkin = wgl.GetCurrentEquippedSkinInsID
                    wgl.GetCurrentEquippedSkinInsID = function(self, weaponID, ...)
                        weaponID = tonumber(weaponID)
                        if weaponID then
                            local w = cache().weapons[weaponID]
                            if w and w.insID and w.insID > 0 and isInjectedIns(w.insID) then
                                return w.insID
                            end
                        end
                        return origGetCurSkin(self, weaponID, ...)
                    end
                end

                if wgl.GetGunSkinInsID then
                    local origGetGunSkin = wgl.GetGunSkinInsID
                    wgl.GetGunSkinInsID = function(self, weaponID, ...)
                        weaponID = tonumber(weaponID)
                        if weaponID then
                            local w = cache().weapons[weaponID]
                            if w and w.insID and w.insID > 0 and isInjectedIns(w.insID) then
                                return w.insID
                            end
                        end
                        return origGetGunSkin(self, weaponID, ...)
                    end
                end
            end)
        end

        -- [XTHRLEN] Collection Ace Eliminator Broadcast (619150001)
        local ELIMINATION_KING_EFFECT_ID = 619150001
        -- [XTHRLEN] Last Strike Champion Final Kill Effect (61950002)
        local FINAL_KILL_EFFECT_ID = 61950002

        local function getLocalPlayerKey()
            local ok, GD = pcall(require, "GameLua.GameCore.Data.GameplayData")
            if ok and GD and GD.GetPlayerState then
                local ps = GD.GetPlayerState()
                if ps and slua.isValid(ps) and ps.PlayerKey then
                    return tonumber(ps.PlayerKey)
                end
            end
            return nil
        end

        local function getLocalUID()
            local uid
            pcall(function()
                local Subsystem = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
                local AccountSubsystem = Subsystem:Get("AccountSubsystem")
                if AccountSubsystem and AccountSubsystem.GetAccountUID then
                    uid = AccountSubsystem:GetAccountUID()
                end
            end)
            if not uid then
                pcall(function()
                    local GD = require("GameLua.GameCore.Data.GameplayData")
                    local ps = GD.GetPlayerState()
                    if ps and slua.isValid(ps) and ps.UID then
                        uid = tonumber(ps.UID)
                    end
                end)
            end
            return uid
        end

        local function hookEliminationKingEffect()
            if _G._lava_hooked_elim_king then return end
            _G._lava_hooked_elim_king = true

            pcall(function()
                local CommerAvatarDataUtil = require("GameLua.Activity.Commercialize.GamePlay.CommerAvatarDataUtil")
                if CommerAvatarDataUtil._lava_hooked_ext_attr then return end
                CommerAvatarDataUtil._lava_hooked_ext_attr = true

                local ExtendAttribute = require("Server.config.ExtendAttribute")
                local origGetAttr = CommerAvatarDataUtil.GetPlayerExtendAttributeAndTest
                CommerAvatarDataUtil.GetPlayerExtendAttributeAndTest = function(self, UID, attr)
                    if attr == ExtendAttribute.EliminationKingEffect then
                        local localUID = getLocalUID()
                        if localUID and tonumber(UID) == tonumber(localUID) then
                            return ELIMINATION_KING_EFFECT_ID
                        end
                    end
                    return origGetAttr(self, UID, attr)
                end
                log("hookEliminationKingEffect: CommerAvatarDataUtil hooked")
            end)

            pcall(function()
                local KillInfoClass = require("GameLua.Mod.BaseMod.Client.KillInfoTips.KillInfo")
                local impl = KillInfoClass.__inner_impl
                if not impl or impl._lava_hooked_show_king then return end
                impl._lava_hooked_show_king = true

                local origShow = impl.ShowKingEliminationInfo
                impl.ShowKingEliminationInfo = function(self, DamageRecordData)
                    local localKey = getLocalPlayerKey()
                    if localKey and DamageRecordData and DamageRecordData.ExpandDataContent then
                        pcall(function()
                            local FatalDamageInfo = slua.LuaArchiverDecode(LuaStateWrapper, DamageRecordData.ExpandDataContent)
                            if FatalDamageInfo and FatalDamageInfo.KingEliminationInfo then
                                local KingEliminationInfo = FatalDamageInfo.KingEliminationInfo
                                if KingEliminationInfo.NewKingEliminationInfo then
                                    local info = KingEliminationInfo.NewKingEliminationInfo
                                    if tonumber(info.PlayerKey) == localKey then
                                        info.EffectID = ELIMINATION_KING_EFFECT_ID
                                        log("hookEliminationKingEffect: injected EffectID into NewKingEliminationInfo")
                                    end
                                end
                                if KingEliminationInfo.DeadKingEliminationInfo then
                                    local info = KingEliminationInfo.DeadKingEliminationInfo
                                    if tonumber(info.KillerPlayerKey) == localKey then
                                        info.EffectID = ELIMINATION_KING_EFFECT_ID
                                        log("hookEliminationKingEffect: injected EffectID into DeadKingEliminationInfo")
                                    end
                                end
                            end
                        end)
                    end
                    return origShow(self, DamageRecordData)
                end
                log("hookEliminationKingEffect: KillInfo.ShowKingEliminationInfo hooked")
            end)

            pcall(function()
                local KingEliminationInfoItemClass = require("GameLua.Mod.BaseMod.Client.KillInfoTips.KingEliminationInfoItem")
                local impl = KingEliminationInfoItemClass.__inner_impl
                if not impl or impl._lava_hooked_update then return end
                impl._lava_hooked_update = true

                local origUpdate = impl.UpdateKingEliminationInfo
                impl.UpdateKingEliminationInfo = function(self, DamageRecordData, KingEliminationInfo)
                    local localKey = getLocalPlayerKey()
                    if localKey and KingEliminationInfo then
                        if KingEliminationInfo.NewKingEliminationInfo then
                            local info = KingEliminationInfo.NewKingEliminationInfo
                            if tonumber(info.PlayerKey) == localKey then
                                info.EffectID = ELIMINATION_KING_EFFECT_ID
                            end
                        end
                        if KingEliminationInfo.DeadKingEliminationInfo then
                            local info = KingEliminationInfo.DeadKingEliminationInfo
                            if tonumber(info.KillerPlayerKey) == localKey then
                                info.EffectID = ELIMINATION_KING_EFFECT_ID
                            end
                        end
                    end
                    return origUpdate(self, DamageRecordData, KingEliminationInfo)
                end
                log("hookEliminationKingEffect: KingEliminationInfoItem hooked")
            end)

            pcall(function()
                local PlayerStateBaseClass = require("GameLua.GameCore.Framework.PlayerStateBase")
                local impl = PlayerStateBaseClass.__inner_impl
                if not impl or impl._lava_hooked_init_team then return end
                impl._lava_hooked_init_team = true

                local origInit = impl.InitTeamShowData
                impl.InitTeamShowData = function(self, ...)
                    origInit(self, ...)
                    pcall(function()
                        local localUID = getLocalUID()
                        if localUID and self.UID and tonumber(self.UID) == tonumber(localUID) then
                            self.EliminationKingEffectID = ELIMINATION_KING_EFFECT_ID
                        end
                    end)
                end
                log("hookEliminationKingEffect: PlayerStateBase hooked")
            end)
        end

        local function tickEliminationKingEffect()
            pcall(function()
                local ok, GD = pcall(require, "GameLua.GameCore.Data.GameplayData")
                if ok and GD and GD.GetPlayerState then
                    local ps = GD.GetPlayerState()
                    if ps and slua.isValid(ps) then
                        if not ps.EliminationKingEffectID or ps.EliminationKingEffectID == 0 then
                            ps.EliminationKingEffectID = ELIMINATION_KING_EFFECT_ID
                        end
                    end
                end
            end)
        end

        -- [XTHRLEN] Last Strike Champion Final Kill Effect (61950002)
        local function hookFinalKillEffect()
            if _G._lava_hooked_final_kill then return end
            _G._lava_hooked_final_kill = true

            -- [XTHRLEN] Hook FinalKillEffectLevelSequenceActor to handle missing config for 61950002
            -- [XTHRLEN] If config doesn't exist or Sequence is empty, directly call OnPlay callback
            pcall(function()
                local LSActor = require("GameLua.Mod.Library.GamePlay.Actor.FinalKillEffectLevelSequenceActor")
                if LSActor._lava_hooked then return end
                LSActor._lava_hooked = true

                local origBeginPlay = LSActor.ReceiveBeginPlay
                if origBeginPlay then
                    LSActor.ReceiveBeginPlay = function(self)
                        if self.ItemId == FINAL_KILL_EFFECT_ID then
                            local Config = CDataTable.GetTableData("FinalKillEffectCfg", self.ItemId)
                            if not Config or not Config.Sequence or Config.Sequence == "" then
                                log("hookFinalKillEffect: no sequence for 61950002, calling OnPlay directly")
                                if self.Callback and self.Callback.OnPlay then
                                    self.Callback.OnPlay()
                                end
                                return
                            end
                        end
                        return origBeginPlay(self)
                    end
                    log("hookFinalKillEffect: FinalKillEffectLevelSequenceActor hooked")
                end
            end)

            -- [XTHRLEN] Hook TriggerParticleEffect to force ItemId = 61950002
            pcall(function()
                local Feature = require("GameLua.Mod.BaseMod.GamePlay.Feature.Player.PlayerCharacterFinalKillEffectFeature")
                if Feature._lava_hooked_fke then return end
                Feature._lava_hooked_fke = true

                local origTriggerParticle = Feature.TriggerParticleEffect
                if origTriggerParticle then
                    Feature.TriggerParticleEffect = function(self, ItemId, Location, Rotator, TeamMemberNames)
                        log("hookFinalKillEffect: TriggerParticleEffect called, ItemId=" .. tostring(ItemId) .. " forcing to " .. tostring(FINAL_KILL_EFFECT_ID))
                        return origTriggerParticle(self, FINAL_KILL_EFFECT_ID, Location, Rotator, TeamMemberNames)
                    end
                end

                local origPrepareItem = Feature.PrepareItem
                if origPrepareItem then
                    Feature.PrepareItem = function(self, ItemId)
                        log("hookFinalKillEffect: PrepareItem called, ItemId=" .. tostring(ItemId) .. " forcing to " .. tostring(FINAL_KILL_EFFECT_ID))
                        return origPrepareItem(self, FINAL_KILL_EFFECT_ID)
                    end
                end
                log("hookFinalKillEffect: PlayerCharacterFinalKillEffectFeature hooked")
            end)

            -- [XTHRLEN] Direct client-side trigger when game ends
            local function triggerFinalKillEffect()
                pcall(function()
                    local char = getLocalChar()
                    if not char or not slua.isValid(char) then
                        log("hookFinalKillEffect: char not valid")
                        return
                    end

                    if _G._lava_fke_triggered then return end
                    _G._lava_fke_triggered = true

                    char:EnsureDynamicFeature("FinalKillEffect")
                    if not char.FinalKillEffect then
                        log("hookFinalKillEffect: FinalKillEffect feature not available")
                        return
                    end

                    local Location = char:K2_GetActorLocation()
                    local Rotator = FRotator(0, 0, 0)
                    local Names = char.PlayerName or ""

                    log("hookFinalKillEffect: triggering effect 61950002")
                    char.FinalKillEffect:TriggerParticleEffect(FINAL_KILL_EFFECT_ID, Location, Rotator, Names)
                end)
            end

            -- [XTHRLEN] Hook BattleResult.on_game_result (global function, client-side)
            pcall(function()
                if BattleResult and BattleResult.on_game_result and not BattleResult._lava_hooked_fke then
                    BattleResult._lava_hooked_fke = true
                    local origOnGameResult = BattleResult.on_game_result
                    BattleResult.on_game_result = function(battle_result, result)
                        log("hookFinalKillEffect: BattleResult.on_game_result triggered")
                        triggerFinalKillEffect()
                        return origOnGameResult(battle_result, result)
                    end
                    log("hookFinalKillEffect: BattleResult.on_game_result hooked")
                end
            end)

            -- [XTHRLEN] Hook BattleResult.on_game_over (global function, client-side)
            pcall(function()
                if BattleResult and BattleResult.on_game_over and not BattleResult._lava_hooked_fke_over then
                    BattleResult._lava_hooked_fke_over = true
                    local origOnGameOver = BattleResult.on_game_over
                    BattleResult.on_game_over = function(game_id)
                        log("hookFinalKillEffect: BattleResult.on_game_over triggered")
                        triggerFinalKillEffect()
                        return origOnGameOver(game_id)
                    end
                    log("hookFinalKillEffect: BattleResult.on_game_over hooked")
                end
            end)

            -- [XTHRLEN] Also register for the event as backup (with nil checks)
            pcall(function()
                if EventSystem and EventSystem.registEvent
                    and EVENTTYPE_STATE and EVENTID_GAMESTATE_ON_PRE_BATTLE_RESULT
                    and not _G._lava_fke_event_registered then
                    _G._lava_fke_event_registered = true
                    EventSystem:registEvent(EVENTTYPE_STATE, EVENTID_GAMESTATE_ON_PRE_BATTLE_RESULT, triggerFinalKillEffect)
                    log("hookFinalKillEffect: registered for EVENTID_GAMESTATE_ON_PRE_BATTLE_RESULT")
                end
            end)
            log("hookFinalKillEffect: done")
        end

        -- [XTHRLEN] SECURITY: ANTI-CHEAT BYPASS
        local function hookSecurityBypass()
            -- [XTHRLEN] Disable puffer download reporting
            pcall(function()
                local pufferTlog = package.loaded["client.slua.logic.download.report.puffer_tlog"]
                if pufferTlog then
                    pufferTlog.ReportEvent = function() end
                    pufferTlog.ReportDownloadResult = function() end
                    pufferTlog.ReportODPAKError = function() end
                end
            end)

            -- [XTHRLEN] Bypass AvatarUtils weapon blacklist
            pcall(function()
                local AvatarUtils = package.loaded["AvatarUtils"]
                if AvatarUtils then
                    AvatarUtils.CheckIsWeaponInBlackList = function() return false end
                    AvatarUtils.IsValidAvatar = function() return true end
                end
            end)

            -- [XTHRLEN] Disable file integrity checking
            pcall(function()
                local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
                if SubsystemMgr then
                    local FileCheckSubsystem = SubsystemMgr:Get("FileCheckSubsystem")
                    if FileCheckSubsystem then
                        FileCheckSubsystem.StartCheck = function() end
                        FileCheckSubsystem.ReportAbnormalFile = function() end
                    end
                end
            end)

            -- [XTHRLEN] Disable equipment exception reporting
            pcall(function()
                local equipReport = package.loaded["client.slua.logic.report.EquipmentExceptionReport"]
                if equipReport then
                    equipReport.Report = function() end
                end
            end)

            -- [XTHRLEN] Disable puffer download validation
            pcall(function()
                local pufferManager = require("client.slua.logic.download.puffer.puffer_manager")
                local pufferConst = require("client.slua.logic.download.puffer_const")
                if pufferManager and pufferConst then
                    local origCheck = pufferManager.CheckResourceValid
                    if origCheck then
                        pufferManager.CheckResourceValid = function(...) return true end
                    end
                end
            end)

            -- [XTHRLEN] Bypass avatar hash verification
            pcall(function()
                local AvatarUtils = package.loaded["AvatarUtils"]
                if AvatarUtils then
                    local origVerify = AvatarUtils.VerifyAvatarData
                    if origVerify then
                        AvatarUtils.VerifyAvatarData = function(...) return true end
                    end
                end
            end)
            print("[AddOutfit] Security bypass installed")
        end
        
        _G.AlreadyChangedSet = _G.AlreadyChangedSet or {}
        _G.DeadBoxSkins = _G.DeadBoxSkins or {}
        _G.CurrentEquipVehicleID = 0
        local function locationsClose(loc1, loc2, tolerance)
            local dx = loc1.X - loc2.X
            local dy = loc1.Y - loc2.Y
            local dz = loc1.Z - loc2.Z
            return dx * dx + dy * dy + dz * dz < tolerance * tolerance
        end
        local UGameplayStatics = import("GameplayStatics")
        local APlayerTombBox = import("PlayerTombBox")
        local UIUtil = require("client.common.ui_util")
        local uActor = import("Actor")
        function _G.DeadBox_TemperRequest(PlayerController)
            if not PlayerController or not UGameplayStatics or not APlayerTombBox then return end
            local uCharacter = PlayerController:GetPlayerCharacterSafety()
            if not uCharacter then return end
            local uGameInstance = UIUtil and UIUtil.GetGameInstance()
            if not uGameInstance then return end

            local uActorArray = UGameplayStatics.GetAllActorsOfClass(uGameInstance, APlayerTombBox, slua.Array(UEnums.EPropertyClass.Object, uActor))

            for _, actor in pairs(uActorArray) do
                if slua.isValid(actor) then
                    local actorKey = tostring(actor)
                    
                    if not _G.AlreadyChangedSet[actorKey] then
                        local DamageCauser = actor.DamageCauser

                        if DamageCauser and DamageCauser.Playerkey == PlayerController.Playerkey then
                            local Deadboxavatar = actor.DeadBoxAvatarComponent_BP
                            
                            if Deadboxavatar then
                                local actorLocation = actor:K2_GetActorLocation()
                                local ApplySkinID = nil
                                for _, entry in pairs(_G.DeadBoxSkins) do
                                    if locationsClose(entry.location, actorLocation, 1.0) then
                                        ApplySkinID = entry.SkinID
                                        break
                                    end
                                end

                                if not ApplySkinID then
                                    local CurrentVehicle = uCharacter.CurrentVehicle
                                    if CurrentVehicle and _G.CurrentEquipVehicleID ~= 0 then
                                        ApplySkinID = tonumber(tostring(_G.CurrentEquipVehicleID) .. "1")
                                    else
                                        local currweapon = uCharacter:GetCurrentWeapon()
                                        if currweapon and currweapon.synData then
                                            local ref = slua.IndexReference(currweapon.synData:Get(7), "defineID")
                                            if ref then ApplySkinID = ref.TypeSpecificID end
                                        end
                                    end

                                    if ApplySkinID and ApplySkinID ~= 0 then
                                        table.insert(_G.DeadBoxSkins, { location = actorLocation, SkinID = ApplySkinID })
                                    end
                                end

                                if ApplySkinID and ApplySkinID ~= 0 then
                                    Deadboxavatar:ResetItemAvatar()
                                    Deadboxavatar:PreChangeItemAvatar(ApplySkinID)
                                    Deadboxavatar:SyncChangeItemAvatar(ApplySkinID)
                                    _G.AlreadyChangedSet[actorKey] = true
                                end
                            end
                        end
                    end
                end
            end
        end
        
        function _G.GameAvatarHandlerDeadBox()
            if _G._SKIN_ENGINE_ENABLED ~= true or _G._LICENSE_OK ~= true then return end
            local PlayerController = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
            if PlayerController then
                _G.DeadBox_TemperRequest(PlayerController)
            end
        end
        pcall(function()
           require("common.time_ticker").AddTimerLoop(2.0, _G.GameAvatarHandlerDeadBox, -1, 1)
        end)
        
        local n,C=nil,{}
        local WID=0
        local SID=0
        local function D(x)
            if not x or x=="" then return {} end
            local o,r=pcall(slua.LuaArchiverDecode,LuaStateWrapper,x)
            return o and r or {}
        end
        local function E(x)
            local o,r=pcall(slua.LuaArchiverEncode,LuaStateWrapper,x or {})
            return o and r or nil
        end
        local function M(d)
            if not d then return false end
            if d.bIamCauser then return true end
            if not n then
                local h=slua_GameFrontendHUD
                local p=h and h:GetPlayerController()
                local c=p and slua.isValid(p) and p:GetPlayerCharacterSafety()
                if c and slua.isValid(c) then
                    pcall(function() n=c:GetPlayerNameSafety() end)
                end
            end
            return n and n~="" and (d.Causer==n or d.CauserRealPlayerName==n or d.CauserPlayerName==n) or false
        end
        local function S()
            local h=slua_GameFrontendHUD
            local p=h and h:GetPlayerController()
            if not p or not slua.isValid(p) then
                return WID,SID
            end
            local c=p:GetPlayerCharacterSafety()
            if not c or not slua.isValid(c) then
                return WID,SID
            end
            local w=c:GetCurrentWeapon()
            if not w or not slua.isValid(w) then
                return WID,SID
            end
            local defineID=0
            local skinID=0
            pcall(function()
                local data=w:GetItemDefineID()
                if data then
                    defineID=tonumber(data.TypeSpecificID) or 0
                end
            end)
            pcall(function()
                if w.synData and slua.isValid(w.synData) then
                    local data=w.synData:Get(7)
                    if data then
                        local r=slua.IndexReference(data,"defineID")
                        if r and slua.isValid(r) then
                            skinID=tonumber(r.TypeSpecificID) or 0
                        end
                    end
                end
            end)
            if defineID>0 and defineID~=69 then
                WID=defineID
            end
            if skinID>0 and skinID~=69 then
                SID=skinID
            end
            return WID,SID
        end
        local function GetBroadcast(weaponID,skinID)
            if skinID and skinID>0 and skinID~=69 then
                local c
                pcall(function() c=CDataTable.GetTableData("TeamKillBroadcast",skinID) end)
                if c and ((c.BgPath and c.BgPath~="") or (c.EffectPath and c.EffectPath~="")) then
                    return skinID,c
                end
            end
            if weaponID and weaponID>0 and weaponID~=69 then
                local c
                pcall(function() c=CDataTable.GetTableData("TeamKillBroadcast",weaponID) end)
                if c and ((c.BgPath and c.BgPath~="") or (c.EffectPath and c.EffectPath~="")) then
                    return weaponID,c
                end
            end
            return 0,nil
        end
        local function A(id,c)
            if not id or id<=0 or id==69 or C[id] then
                return
            end
            if not c then
                pcall(function() c=CDataTable.GetTableData("TeamKillBroadcast",id) end)
            end
            if not c then return end
            if (not c.EffectPath or c.EffectPath=="") and (not c.BgPath or c.BgPath=="") then
                return
            end
            C[id]=true
            pcall(function()
                local p=require("client.slua.logic.download.puffer.puffer_manager")
                local k=require("client.slua.logic.download.puffer_const")
                local function d(x)
                    if x and x~="" then
                        p.Download(k.ENUM_DownloadType.ODPAK,{x})
                    end
                end
                d(id)
                d(c.EffectPath)
                d(c.BgPath)
            end)
        end
        local function P(d)
            if not d or not M(d) then
                return d
            end
            local weaponID,skinID=S()
            if weaponID==0 and skinID==0 then
                return d
            end
            local id,c=GetBroadcast(weaponID,skinID)
            if id==0 or not c then
                return d
            end
            pcall(function()
                local e=D(d.ExpandDataContent)
                e.CauserWeaponAvatarID=id
                local encoded=E(e)
                if not encoded then
                    return
                end
                d.ExpandDataContent=encoded
                d.bShowBottomBothSidesKillInfo=true
                d.bIamCauser=true
                A(id,c)
            end)
            return d
        end
        local function installTeamBroadcastHooks()
            local function H(path,tag)
                local ok,m=pcall(require,path)
                if not ok or not m then
                    return
                end
                local i=m.__inner_impl or m
                if not i then
                    return
                end
                local k="__teamKillCopy_"..tag
                if i[k] then
                    return
                end
                local f=i.CopyKillOrPutDownMessageDataUserDataToLuaTable
                if not f then
                    return
                end
                i[k]=f
                i.CopyKillOrPutDownMessageDataUserDataToLuaTable=function(s,d)
                    local x=f(s,d)
                    local ok2,r=pcall(P,x)
                    if ok2 and r then
                        return r
                    end
                    return x
                end
            end
            pcall(H,"GameLua.Mod.BaseMod.Client.BattleKillBroadcast.BattleKillBroadcastSubSystem","base")
            pcall(H,"GameLua.Mod.SingleTraining.Client.BattleKillBroadcast.BattleKillBroadcastSubSystem","training")
        end

        -- KILL COUNTER - MEMORY ONLY
        _G.killCountInfo = _G.killCountInfo or {}
        _G.LastKillTime = _G.LastKillTime or {}
        _G.WeaponEvents = _G.WeaponEvents or {
            onWeaponChanged = function() end
        }

        function _G.getKills(weaponID)
            if not weaponID then
                return 0
            end
            if _G.killCountInfo[weaponID] == nil then
                _G.killCountInfo[weaponID] = 1000
            end
            return _G.killCountInfo[weaponID]
        end

        function _G.addKill(weaponID, count)
            if not weaponID or not count then
                return
            end
            local currentTime = os.clock()
            if _G.LastKillTime[weaponID] and (currentTime - _G.LastKillTime[weaponID]) < 0.5 then
                return
            end
            _G.LastKillTime[weaponID] = currentTime
            _G.killCountInfo[weaponID] = (_G.killCountInfo[weaponID] or 1000) + count
            pcall(function()
                local uCharacter = getLocalChar()
                if not uCharacter or not slua.isValid(uCharacter) then
                    return
                end
                local currweapon = uCharacter:GetCurrentWeapon()
                if not currweapon or not slua.isValid(currweapon) then
                    return
                end
                local DefineData = currweapon:GetItemDefineID()
                local DefineID = DefineData and DefineData.TypeSpecificID or 0
                if DefineID == 0 then
                    return
                end
                local SkinID = 0
                if currweapon.synData and slua.isValid(currweapon.synData) then
                    local weaponDefineID = slua.IndexReference(currweapon.synData:Get(7), "defineID")
                    if weaponDefineID and slua.isValid(weaponDefineID) then
                        SkinID = weaponDefineID.TypeSpecificID or 0
                    end
                end
                if _G.OurkillCountSystem then
                    _G.OurkillCountSystem:UpdateMainKillCounterUI(true, DefineID, SkinID)
                end
            end)
        end

        function _G.ForceUpdateKillCounterUI()
            pcall(function()
                local uCharacter = getLocalChar()
                if not uCharacter or not slua.isValid(uCharacter) then
                    return
                end
                local currweapon = uCharacter:GetCurrentWeapon()
                if not currweapon or not slua.isValid(currweapon) then
                    return
                end
                local DefineData = currweapon:GetItemDefineID()
                local DefineID = DefineData and DefineData.TypeSpecificID or 0
                if DefineID == 0 then
                    return
                end
                local currentEquipAvatarID = 0
                if currweapon.synData and slua.isValid(currweapon.synData) then
                    local weaponDefineID = slua.IndexReference(currweapon.synData:Get(7), "defineID")
                    if weaponDefineID and slua.isValid(weaponDefineID) then
                        currentEquipAvatarID = weaponDefineID.TypeSpecificID or 0
                    end
                end
                local UIManager = require("client.slua_ui_framework.manager")
                local MainKillCounter = UIManager.GetUI(UIManager.UI_Config_InGame.MainKillCounter)
                if not MainKillCounter or not slua.isValid(MainKillCounter) then
                    return
                end
                local ModuleManager = require("client.module_framework.ModuleManager")
                local LogicKillCounter = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.LogicKillCounter)
                if not LogicKillCounter then
                    return
                end
                local curEquipedKillCounter = LogicKillCounter:GetEquipedKillCounterId(6114302174, currentEquipAvatarID)
                if not curEquipedKillCounter or curEquipedKillCounter == 0 then
                    curEquipedKillCounter = LogicKillCounter:GetBaseKillCounterIdByWeaponId(DefineID)
                end
                local kills = _G.getKills(DefineID)
                MainKillCounter:SetKillCounterItemShowWithNum(curEquipedKillCounter, kills, currentEquipAvatarID)
                if MainKillCounter.KillCounterItem and MainKillCounter.KillCounterItem.SetVisibility then
                    local ESlateVisibility = import("ESlateVisibility")
                    MainKillCounter.KillCounterItem:SetVisibility(ESlateVisibility.Collapsed)
                    MainKillCounter.KillCounterItem:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
                end
            end)
        end
        
        local SKillInfo = require("GameLua.Mod.BaseMod.Client.KillInfoTips.KillInfo")
        local ECharacterHealthStatus = import("ECharacterHealthStatus")
        local SKillInfoModuleManager = require("client.module_framework.ModuleManager")
        local O_FileItem = SKillInfo.__inner_impl.FileItem

        SKillInfo.__inner_impl.FileItem = function(self, DamageRecordData)
            if not self or not DamageRecordData then
                return O_FileItem(self, DamageRecordData)
            end
            local LogicKillCounter = SKillInfoModuleManager.GetModule(SKillInfoModuleManager.CommonModuleConfig.LogicKillCounter)
            if not LogicKillCounter then
                return O_FileItem(self, DamageRecordData)
            end
            local uCharacter = getLocalChar()
            if not uCharacter or not slua.isValid(uCharacter) then
                return O_FileItem(self, DamageRecordData)
            end
            local SelfName = uCharacter:GetPlayerNameSafety()
            if DamageRecordData.Causer == SelfName then
                local currWeapon = uCharacter:GetCurrentWeapon()
                if currWeapon and slua.isValid(currWeapon) then
                    local DefineData = currWeapon:GetItemDefineID()
                    local DefineID = DefineData and DefineData.TypeSpecificID or 0
                    if DefineID ~= 0 then
                        local ExpandData = slua.LuaArchiverDecode(LuaStateWrapper, DamageRecordData.ExpandDataContent) or {}
                        local SupportKillCounter = LogicKillCounter:GetBaseKillCounterIdByWeaponId(DefineID)
                        if SupportKillCounter and DamageRecordData.ResultHealthStatus == ECharacterHealthStatus.FinishedLastBreath then
                            ExpandData.KillCounterItemId = DefineID
                            ExpandData.KillCounterNum = (ExpandData.KillCounterNum or 0) + 1
                            _G.addKill(DefineID, 1)
                        end
                        local synData = currWeapon.synData
                        if synData and slua.isValid(synData) then
                            local weaponDefineID = slua.IndexReference(synData:Get(7), "defineID")
                            if weaponDefineID and slua.isValid(weaponDefineID) then
                                DamageRecordData.CauserWeaponAvatarID = weaponDefineID.TypeSpecificID
                            end
                        end
                        DamageRecordData.ExpandDataContent = slua.LuaArchiverEncode(LuaStateWrapper, ExpandData)
                    end
                end
            end
            return O_FileItem(self, DamageRecordData)
        end
        
        local MyMainKillCounter = require("GameLua.Mod.BaseMod.Client.KillCounter.MainKillCounter")
        local MyKillCountSubSystem = require("GameLua.Mod.BaseMod.Client.KillCounter.KillCounterUISubsystem")
        local MyMainWeaponInfoItemUI = require("GameLua.Mod.BaseMod.Client.Backpack.MainWeaponInfoItemUI")
        local MyMainWeaponKillCounter = require("GameLua.Mod.BaseMod.Client.KillCounter.MainKillCounter")
        local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        local SlotBase = require("GameLua.Mod.BaseMod.Client.MainControlUI.SwitchWeaponSlotMode2")
        _G.OurkillCountSystem = MyKillCountSubSystem.__inner_impl

        MyMainKillCounter.__inner_impl.OnRefreshUI = function(self, _, _, UID)
            pcall(function()
                local ModuleManager = require("client.module_framework.ModuleManager")
                local LogicKillCounter = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.LogicKillCounter)
                local uCharacter = getLocalChar()
                if not uCharacter or not slua.isValid(uCharacter) then
                    return
                end
                local currweapon = uCharacter:GetCurrentWeapon()
                if not currweapon or not slua.isValid(currweapon) then
                    return
                end
                local DefineData = currweapon:GetItemDefineID()
                local DefineID = DefineData and DefineData.TypeSpecificID or 0
                if DefineID == 0 then
                    return
                end
                local currentEquipAvatarID = 0
                if currweapon.synData and slua.isValid(currweapon.synData) then
                    local weaponDefineID = slua.IndexReference(currweapon.synData:Get(7), "defineID")
                    if weaponDefineID and slua.isValid(weaponDefineID) then
                        currentEquipAvatarID = weaponDefineID.TypeSpecificID or 0
                    end
                end
                local curEquipedKillCounter = LogicKillCounter:GetEquipedKillCounterId(6114302174, currentEquipAvatarID)
                if not curEquipedKillCounter or curEquipedKillCounter == 0 then
                    curEquipedKillCounter = LogicKillCounter:GetBaseKillCounterIdByWeaponId(DefineID)
                end
                if self.KillCounterItem then
                    self.KillCounterItem:SetKillCounterItemShowWithNum(curEquipedKillCounter, _G.getKills(DefineID), currentEquipAvatarID)
                end
            end)
        end

        MyKillCountSubSystem.__inner_impl.CheckSupportKCUI = function(self)
            return true
        end

        local o_CheckNeedMainKillCounterUI = MyKillCountSubSystem.__inner_impl.CheckNeedMainKillCounterUI
        MyKillCountSubSystem.__inner_impl.CheckNeedMainKillCounterUI = function(self, Weapon, PlayerID)
            pcall(function()
                local uCharacter = getLocalChar()
                if not uCharacter or not slua.isValid(uCharacter) then
                    return
                end
                local currweapon = uCharacter:GetCurrentWeapon()
                if not currweapon then
                    return
                end
                local DefineData = currweapon:GetItemDefineID()
                local DefineID = DefineData and DefineData.TypeSpecificID or 0
                if DefineID == 0 then
                    return
                end
                _G.WeaponEvents.onWeaponChanged(DefineID)
                local SkinID = 0
                if currweapon.synData and slua.isValid(currweapon.synData) then
                    local weaponDefineID = slua.IndexReference(currweapon.synData:Get(7), "defineID")
                    if weaponDefineID and slua.isValid(weaponDefineID) then
                        SkinID = weaponDefineID.TypeSpecificID or 0
                    end
                end
                self:UpdateMainKillCounterUI(true, DefineID, SkinID)
            end)
        end

        local o_UpdateMainKillCounterUI = MyKillCountSubSystem.__inner_impl.UpdateMainKillCounterUI
        MyKillCountSubSystem.__inner_impl.UpdateMainKillCounterUI = function(self, bShow, WeaponID, AvatarID)
            pcall(function()
                o_UpdateMainKillCounterUI(self, bShow, WeaponID, AvatarID)
                local UIManager = require("client.slua_ui_framework.manager")
                local MainKillCounter = UIManager.GetUI(UIManager.UI_Config_InGame.MainKillCounter)
                local uCharacter = getLocalChar()
                if not uCharacter or not slua.isValid(uCharacter) then
                    return
                end
                local currweapon = uCharacter:GetCurrentWeapon()
                if not bShow then
                    if MainKillCounter then
                        UIManager.CloseUI(UIManager.UI_Config_InGame.MainKillCounter)
                    end
                    return
                end
                if not currweapon then
                    return
                end
                local DefineData = currweapon:GetItemDefineID()
                local DefineID = DefineData and DefineData.TypeSpecificID or 0
                if DefineID == 0 then
                    return
                end
                local currentEquipAvatarID = AvatarID or 0
                local ModuleManager = require("client.module_framework.ModuleManager")
                local LogicKillCounter = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.LogicKillCounter)
                if not LogicKillCounter then
                    return
                end
                local SupportKillCounter = LogicKillCounter:GetBaseKillCounterIdByWeaponId(DefineID)
                if SupportKillCounter == nil then
                    if MainKillCounter then
                        UIManager.CloseUI(UIManager.UI_Config_InGame.MainKillCounter)
                    end
                    return
                end
                if DefineID == currentEquipAvatarID then
                    if MainKillCounter then
                        UIManager.CloseUI(UIManager.UI_Config_InGame.MainKillCounter)
                    end
                    return
                end
                local curEquipedKillCounter = LogicKillCounter:GetEquipedKillCounterId(6114302174, currentEquipAvatarID)
                if not curEquipedKillCounter or curEquipedKillCounter == 0 then
                    curEquipedKillCounter = SupportKillCounter
                end
                if not MainKillCounter then
                    UIManager.ShowUI(UIManager.UI_Config_InGame.MainKillCounter, DefineID, currentEquipAvatarID)
                    MainKillCounter = UIManager.GetUI(UIManager.UI_Config_InGame.MainKillCounter)
                    if MainKillCounter then
                        MainKillCounter:SetKillCounterItemShowWithNum(curEquipedKillCounter, _G.getKills(DefineID), currentEquipAvatarID)
                    end
                else
                    MainKillCounter:UpdateWeaponID(DefineID, currentEquipAvatarID)
                    MainKillCounter:SetKillCounterItemShowWithNum(curEquipedKillCounter, _G.getKills(DefineID), currentEquipAvatarID)
                end
            end)
        end

        _G.WeaponEvents.onWeaponChanged = function(weaponId)
            pcall(function()
                local uCharacter = getLocalChar()
                if not uCharacter or
                   not slua.isValid(uCharacter) then
                    return
                end
                if not _G.OurkillCountSystem then
                    return
                end
                local currweapon = uCharacter:GetCurrentWeapon()
                if not currweapon or not slua.isValid(currweapon) then
                    return
                end
                local DefineData = currweapon:GetItemDefineID()
                local DefineID = DefineData and DefineData.TypeSpecificID or 0
                if DefineID == 0 then
                    return
                end
                local SkinID = 0
                if currweapon.synData and slua.isValid(currweapon.synData) then
                    local weaponDefineID = slua.IndexReference(currweapon.synData:Get(7), "defineID")
                    if weaponDefineID and slua.isValid(weaponDefineID) then
                        SkinID = weaponDefineID.TypeSpecificID or 0
                    end
                end
                _G.OurkillCountSystem:UpdateMainKillCounterUI(true, DefineID, SkinID)
            end)
        end
        
        local function GameAvatarHandlerkillcounter()
            pcall(_G.ForceUpdateKillCounterUI)
            pcall(installTeamBroadcastHooks)
            --pcall(hookTeamBroadcast)
        end

        function _G.ChangeLobbyWeapon(WeaponMgr)
            if not WeaponMgr or not slua.isValid(WeaponMgr) then
                return false
            end
            local ok, result = pcall(function()
                if type(WeaponMgr.GetUsingWeapon) ~= "function" then
                    return false
                end
                local weapon = WeaponMgr:GetUsingWeapon()
                if not weapon or not slua.isValid(weapon) then
                    return false
                end
                if type(weapon.GetWeaponID) ~= "function" then
                    return false
                end
                local currentID = weapon:GetWeaponID()
                if not currentID or currentID == 0 then
                    return false
                end
                local targetID = currentID
                if type(getCachedWeaponSkin) == "function" then
                    targetID = getCachedWeaponSkin(currentID) or currentID
                end
                if targetID == currentID or targetID == 0 then
                    return false
                end
                local socket = WeaponMgr.CurUseWeaponSocket
                if type(WeaponMgr.DestroyLastWeapon) == "function" then
                    WeaponMgr:DestroyLastWeapon()
                end
                if type(WeaponMgr.EquipWeaponByResId) ~= "function" then
                    return false
                end
                WeaponMgr:EquipWeaponByResId(targetID, true, false, socket)
                if type(WeaponMgr.DoUseWeaponBySocketID) == "function" then
                    WeaponMgr:DoUseWeaponBySocketID(socket)
                end
                return true
            end)
            return ok and result == true
        end
        
        function _G.equip_character_lobby(uCharacter)
            if not uCharacter or not slua.isValid(uCharacter) then 
                return 
            end
    
            local AvatarComp = nil
            if uCharacter.CharacterAvatarComp2_BP and slua.isValid(uCharacter.CharacterAvatarComp2_BP) then
                AvatarComp = uCharacter.CharacterAvatarComp2_BP
            elseif uCharacter.CharacterAvatarComp and slua.isValid(uCharacter.CharacterAvatarComp) then
                AvatarComp = uCharacter.CharacterAvatarComp
            elseif uCharacter.getAvatarComponent2 then
                AvatarComp = uCharacter:getAvatarComponent2()
            end
    
            if not AvatarComp or not slua.isValid(AvatarComp) then return end
    
            local ApplyData = AvatarComp.NetAvatarData and AvatarComp.NetAvatarData.SlotSyncData
            if not ApplyData or not slua.isValid(ApplyData) then return end
    
            if not _G.skinIdCache then _G.skinIdCache = {} end
    
            local EAvatarSlotType = import("EAvatarSlotType")
            if not EAvatarSlotType then return end
    
            local outfitRes = 0
            if MATCH_CONFIG and MATCH_CONFIG.outfitRes and MATCH_CONFIG.outfitRes > 0 then
                outfitRes = MATCH_CONFIG.outfitRes
            elseif cache then
                local c = cache()
                if c and c.outfitRes then
                    outfitRes = c.outfitRes
                end
            end
    
            local count = ApplyData.Num and ApplyData:Num() or 0
            if count <= 0 or count > 30 then
                return
            end
    
            local outfitApplied = false
            for j = 0, count - 1 do
                local equipment = ApplyData:Get(j)
                if equipment then
                    local slotType = equipment.SlotID
                    local currentId = tonumber(equipment.ItemId) or 0
                    local targetSkinID = 0
            
                    -- OUTFIT SAJA
                    if (slotType == EAvatarSlotType.EAvatarSlotType_ClothesEquipemtSlot or slotType == EAvatarSlotType.EAvatarSlotType_UnderClothSlot) then
                        targetSkinID = tonumber(outfitRes) or 0
                        if targetSkinID > 0 and not outfitApplied then
                            local ok = false
                            pcall(function()
                                if AvatarComp.PutOnCustomEquipmentByID then
                                    local result = AvatarComp:PutOnCustomEquipmentByID(targetSkinID, nil)
                                    if result == true or result == nil then
                                        ok = true
                                    end
                                end
                            end)
                            if not ok then
                                pcall(function()
                                    if FItemDefineID and FAvatarCustomDefault and AvatarComp.HandleEquipItem then
                                        local itemID = FItemDefineID(AvatarComp.ItemType or 1, targetSkinID)
                                        AvatarComp:HandleEquipItem(itemID, FAvatarCustomDefault())
                                        ok = true
                                    end
                                end)
                            end
                            if ok then
                                pcall(function()
                                    if AvatarComp.ReloadLogicAvatar then
                                        AvatarComp:ReloadLogicAvatar(0, 0, true) 
                                    end
                                    if AvatarComp.ResetClothSimulate then
                                        AvatarComp:ResetClothSimulate()
                                    end
                                end)
                                outfitApplied = true
                            end
                        end
                    end
            
                    -- APPLY
                    if targetSkinID > 0 and currentId ~= targetSkinID then
                        if not _G.skinIdCache[targetSkinID] then
                            _G.skinIdCache[targetSkinID] = true
                        end
                        equipment.ItemId = targetSkinID
                        pcall(function()
                            ApplyData:Set(j, equipment)
                        end)
                    end
                end
            end
    
            -- REFRESH
            pcall(function()
                if AvatarComp.OnRep_BodySlotStateChanged then
                    AvatarComp:OnRep_BodySlotStateChanged()
                end
                if AvatarComp.ResetData then
                    AvatarComp:ResetData()
                end
            end)
        end

        function _G.GameAvatarLobby()
            local function processLobbyCharacter(pawn)
                if not pawn or not slua.isValid(pawn) then
                    return false
                end
                if type(_G.equip_character_lobby) == "function" then
                    pcall(_G.equip_character_lobby, pawn)
                end
                if type(pawn.GetWeaponManager) == "function" then
                    local weaponMgr = pawn.BP_LobbyWeaponManager
                    if weaponMgr and slua.isValid(weaponMgr) then
                        if type(_G.ChangeLobbyWeapon) == "function" then
                            pcall(_G.ChangeLobbyWeapon, weaponMgr)
                        end
                    end
                end
                return true
            end
            local ok, TeamAvatarManager = pcall(require, "client.logic.avatar.logic_team_avatar_manager")
            if ok and TeamAvatarManager then
                local avatar = TeamAvatarManager.GetMainAvatar and TeamAvatarManager.GetMainAvatar()
                if avatar then
                    local pawn = avatar.GetModel and avatar:GetModel()
                    if processLobbyCharacter(pawn) then
                        return true
                    end
                end
            end
            ok, LobbyAvatarManager = pcall(require, "client.logic.avatar.LobbyAvatarManager")
            if ok and LobbyAvatarManager and LobbyAvatarManager.playerList then
                local lastID = LobbyAvatarManager.avatarCreateID
                local pawn = LobbyAvatarManager.playerList[lastID]
                if processLobbyCharacter(pawn) then
                    return true
                end
                for _, pawnObject in pairs(LobbyAvatarManager.playerList) do
                    if processLobbyCharacter(pawnObject) then
                        return true
                    end
                end
            end
            return false
        end

        pcall(function()
           require("common.time_ticker").AddTimerLoop(1.0, _G.GameAvatarLobby, -1, 1)
        end)

        local function start()
            log("AddOutfit XTHRLEN start")
            buildSkinMappings()
            pcall(restorePersistedVehicles)
            pcall(restorePersistedMotions)
            pcall(restorePersistedEquipIns)
            pcall(restorePersistedThrowObjects)
            pcall(restorePersistedHallTheme)
            pcall(syncMatchConfigFromCache)
            hookCDataTableCache()
            hookDepotInit()
            hookWardrobeData()
            hookPageFilter()
            hookArmory()
            hookPutOn()
            hookLobbyTheme()
            hookMotionEquip()
            hookIngameEmote()
            hookFashionBag()
            hookBackpackValid()
            hookAvatarValid()
            hookEquipMapping()
            hookLobbyWeaponCache()
            hookGunWardrobe()
            hookLobbySwipePersistence()
            hookMatchAvatar()
            hookMatchAvatarData()
            hookGrenadeAvatarInit()
            hookGrenadeAvatarLookup()
            hookProjectileGrenadeAvatar()
            hookWeaponSpawn()
            hookVehicleLicenseComponentBase()
            hookVehiclePlateLicenseUtil()
            hookBackpackWeaponAvatarRes()
            hookEliminationKingEffect()
            hookFinalKillEffect()
            
            if injectAllSources() then
                refreshWardrobe()
                later(2.0, reapplyLobbyEquipped)
            else
                local tries = 0
                local function retry()
                    tries = tries + 1
                    if injectAllSources() then
                        refreshWardrobe()
                        later(3.0, reapplyLobbyEquipped)
                        return
                    end
                    if tries < 60 then later(2.5, retry) end
                end
                later(3.0, retry)
            end

            pcall(function()
                if isInGamePlay() then
                    local char = getLocalChar()
                    if char then bootstrapMatch(char) end
                elseif isInLobby() then
                    snapshotLobbyWear()
                end
            end)
        end

        hookBackpackValid()
        hookEquipMapping()
        hookMatchAvatar()
        hookMatchAvatarData()
        hookGrenadeAvatarInit()
        hookGrenadeAvatarLookup()
        hookProjectileGrenadeAvatar()
        hookWeaponSpawn()
        hookBackpackWeaponAvatarRes()
        hookEliminationKingEffect()
        hookFinalKillEffect()
        pcall(_loadEquippedCache)
        start()
        pcall(hookVehicleSkinAndMusicPanel)

        -- [XTHRLEN] Time-based application loop (replaces frame-based tick listener)
        -- [XTHRLEN] Uses os.clock() for time tracking instead of frame counting
        local _lastTickTime = os.clock()
        local _timeCount = 0

        -- [XTHRLEN] Periodic application functions with different rates
        local function fastApplyLoop()
            if _G._SKIN_ENGINE_ENABLED ~= true or _G._LICENSE_OK ~= true then return end
            pcall(function()
                _timeCount = _timeCount + 1
                _S.globalFrame = _timeCount
                -- [XTHRLEN] Refresh kill counter UI periodically
                if _timeCount % 3 == 0 then
                    pcall(function()
                        if GameAvatarHandlerkillcounter then GameAvatarHandlerkillcounter() end
                    end)
                end
                if isInLobby() then
                    if _timeCount % 10 == 0 then
                        pcall(snapshotLobbyWear)
                    end
                    if _timeCount % 6 == 0 then
                        pcall(_G.AddOutfitTryFlushSave)
                    end
                end
                if isInGamePlay() then
                    local char = getLocalChar()
                    local charValid = char and slua.isValid(char)
                    if not _S.matchTimer and charValid then
                        bootstrapMatch(char)
                    end
                    if _timeCount % 6 == 0 and charValid then
                        pcall(function()
                            local curWeapon = char.GetCurrentWeapon and char:GetCurrentWeapon()
                            if slua.isValid(curWeapon) then
                                applySkinToWeaponRef(curWeapon)
                            end
                            equip_weapon_avatar(char)

                            if not _S.matchOutfitDone then
                                _S.matchOutfitDone = matchApplyOutfit(char)
                            end
                            matchApplyEquipSkins(char)
                            bootstrapMatch(char)
                            PatchUpgradeEffectEmoteDirectly()
                            applyGrenadeSkinsToController()
                        end)
                    end
                    if _timeCount % 6 == 0 then
                        pcall(applyVehicleSkinInGame)
                    end
                end
            end)
            if _ticker and _ticker.AddTimerOnce then
                _ticker.AddTimerOnce(1.0, fastApplyLoop)
            end
        end

        local function mediumLoop()
            if _G._SKIN_ENGINE_ENABLED ~= true or _G._LICENSE_OK ~= true then return end
            pcall(function()
                -- [XTHRLEN] Character boot check at medium rate
                if isInGamePlay() then
                    local char = getLocalChar()
                    if char and not _S.matchTimer then
                        bootstrapMatch(char)
                    end
                    pcall(tickEliminationKingEffect)
                    pcall(applyVehicleChassisLight)
                end
                if isInLobby() then
                    pcall(snapshotLobbyWear)
                end
            end)
            if _ticker and _ticker.AddTimerOnce then
                _ticker.AddTimerOnce(2.5, mediumLoop)
            end
        end

        local function slowLoop()
            if _G._SKIN_ENGINE_ENABLED ~= true or _G._LICENSE_OK ~= true then return end
            pcall(function()
                if isInGamePlay() then
                    pcall(syncVehicleAvatarSkinList)
                end
                pcall(_G.AddOutfitTryFlushSave)
            end)
            if _ticker and _ticker.AddTimerOnce then
                _ticker.AddTimerOnce(5.0, slowLoop)
            end
        end

        -- [XTHRLEN] Start all loops
        if _ticker and _ticker.AddTimerOnce then
            _ticker.AddTimerOnce(0.5, fastApplyLoop)
            _ticker.AddTimerOnce(1.0, mediumLoop)
            _ticker.AddTimerOnce(2.0, slowLoop)
        end

        -- [XTHRLEN] Game status change detection via polling (cheaper than hooking events)
        local _lastGameStatus = ""
        local function statusPollLoop()
            if _G._SKIN_ENGINE_ENABLED ~= true or _G._LICENSE_OK ~= true then return end
            local currentStatus = ""
            if isInLobby() then currentStatus = "lobby"
            elseif isInGamePlay() then currentStatus = "gameplay"
            else currentStatus = "other" end

            if currentStatus ~= _lastGameStatus then
                _lastGameStatus = currentStatus
                -- [XTHRLEN] Status changed, run post-switch logic
                stopMatchWatcher()
                _S.bootstrapNotified = false
                _S.matchOutfitDone = false
                _S.lobbyApplied = false
                _G._lava_fke_triggered = nil
                pcall(function()
                    if isInLobby() then
                        snapshotLobbyWear()
                        later(2.0, reapplyLobbyEquipped)
                    end
                end)
                pcall(function()
                    if isInGamePlay() then
                        local char = getLocalChar()
                        if char then bootstrapMatch(char) end
                    end
                end)
                pcall(_AutoSaveOutfit, true)
            end

            if _ticker and _ticker.AddTimerOnce then
                _ticker.AddTimerOnce(3.0, statusPollLoop)
            end
        end

        if _ticker and _ticker.AddTimerOnce then
            _ticker.AddTimerOnce(1.0, statusPollLoop)
        end

        end -- [XTHRLEN] initHooks

        local function prewarmModules()
            local mods = {
                "client.logic.armory.logic_armory",
                "client.slua.logic.wardrobe.fashionbag.fashionbag_data",
                "client.logic.lobby.hall_theme_utils",
                "client.slua.logic.wardrobe.logic_wardrobe_gun",
                "client.slua.logic.wardrobe.wardrobe_data",
                "client.network.Protocol.WardRobeHandler",
                "client.slua.logic.wardrobe.logic_wardrobe_avatar",
                "client.slua.logic.wardrobe.fashionbag.wardrobe_fashion_utils",
                "client.logic.data.AvatarData",
                "client.slua.logic.XSuit.logic_xsuit",
                "client.slua.logic.wardrobe.logic_wardrobe_new",
                "client.slua.logic.wardrobe.logic_display_setting",
                "client.logic.avatar.logic_team_avatar_manager",
                "client.slua.logic.wardrobe.logic_wardrobe_data_center",
                "client.slua.logic.wardrobe.WardrobeDataEntity",
                "client.slua.umg.Wardrobe.subtab_item_list_base",
                "client.slua.logic.wardrobe.tab_surveillance",
                "client.network.comm.NetManager",
                "client.slua.umg.Wardrobe.wardrobe_macro",
                "client.slua.logic.avatar.avatar_common",
                "client.slua.logic.lobby.Main.Lobby_Main_Control",
                "common.time_ticker",
                "GameLua.GameCore.Module.Subsystem.SubsystemMgr",
                "GameLua.Mod.BaseMod.GamePlay.Backpack.BackpackUtils",
                "GameLua.Mod.Library.GamePlay.Avatar.AvatarDataUtil",
                "GameLua.Activity.Commercialize.GamePlay.CommerAvatarDataUtil",
            }
            for _, m in ipairs(mods) do
                pcall(require, m)
            end
        end

        prewarmModules()
        initHooks()

        -- Compatibility surface for the existing Lava runtime. The actual
        -- implementation remains the new XTHRLEN skin engine above.
        _G.AddOutfit = {
            injectAll = injectAll,
            hookArmory = hookArmory,
            hookWardrobeData = hookWardrobeData,
            hookPutOn = hookPutOn,
            isInRealMatch = isInRealMatch,
            reapplyLobbyEquipped = reapplyLobbyEquipped,
            matchApplyAllSlots = function(char)
                pcall(function() if matchApplyOutfit then matchApplyOutfit(char) end end)
                pcall(function() if matchApplyEquipSkins then matchApplyEquipSkins(char) end end)
            end,
            matchApplyHat = function(char)
                pcall(function() if matchApplyOutfit then matchApplyOutfit(char) end end)
            end,
            matchApplyWeaponSkin = matchApplyWeaponSkin,
            matchApplyFaceWear = function() end,
            isCharacterAirborne = function() return false end,
            applyAirborneSlots = function() end,
            hookGunSkinId = function() end,
            start = start,
            persistLoadFromDisk = function() end,
            persistApplyLoaded = function() end,
            applyVehicleSkinInGame = applyVehicleSkinInGame,
        }

        log("AddOutfit Merged loaded")
        _G.XTHRLENNotiff("By XTHRLEN")
    end)
    if not _ao_ok then
        print("[AddOutfit] LOAD ERROR:", tostring(_ao_err))
        _G.XTHRLENNotiff("[AddOutfit] LOAD ERROR")
    end

    end)
    if not _ao_ok then
        _G._SKIN_ENGINE_BOOTSTRAPPED = false
        _G._SKIN_ENGINE_ENABLED = false
        print("[AddOutfit] LOAD ERROR:", tostring(_ao_err))
        return false
    end
    return true
end

_G.StartSkinLoop = function()
    if _G._LICENSE_OK ~= true then return false end
    _G._SKIN_ENGINE_ENABLED = true
    return _G._StartXTHRLENSkinEngine()
end

_G.StopSkinLoop = function()
    _G._SKIN_ENGINE_ENABLED = false
end

_G.AddOutfitLobbyRestored = false

local function AutoRestoreLobbySkin()
    if _G._LICENSE_OK ~= true then return end
    if _G.AddOutfitLobbyRestored then return end


    if not _G.LexusConfig.ModSkin then return end


    if _G.AddOutfit and _G.AddOutfit.isInRealMatch() then return end

    pcall(function()
        if GameStatus and GameStatus.IsInLobbyOrMainCity and GameStatus.IsInLobbyOrMainCity() then

            if DataMgr and DataMgr.roleData and DataMgr.roleData.uid then
                local LMC = require("client.slua.logic.lobby.Main.Lobby_Main_Control")
                if LMC and LMC.GetCurPage then
                    if _G.AddOutfit and _G.AddOutfit.reapplyLobbyEquipped then

                        _G.AddOutfit.persistLoadFromDisk()
                        _G.AddOutfit.persistApplyLoaded()
                        _G.AddOutfit.reapplyLobbyEquipped()


                        _G.AddOutfitLobbyRestored = true
                    end
                end
            end
        end
    end)
end


pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerLoop then
        ticker.AddTimerLoop(0, AutoRestoreLobbySkin, -1, 1.0)
    end
end)


local IngamePhoneStateUI = require("GameLua.Mod.Library.Client.UI.IngamePhoneStateUI")
local Lobby_Main_Wifi_UIBP = require("client.slua.umg.lobby.Main.Lobby_Main_Wifi_UIBP")

local o_UpdateQuality = Lobby_Main_Wifi_UIBP.__inner_impl.UpdateQuality
Lobby_Main_Wifi_UIBP.__inner_impl.UpdateQuality = function(self)
    if o_UpdateQuality then o_UpdateQuality(self) end
    self.UIRoot.WidgetSwitcher_Quality:SetActiveWidgetIndex(0)
    self.UIRoot.TextBlock_High:SetText("XTHRLEN")
    self.UIRoot.TextBlock_High:SetColorAndOpacity(FSlateColor(FLinearColor(1, 0, 0, 1)))
    self.UIRoot.TextBlock_Low:SetText("XTHRLEN")
    self.UIRoot.TextBlock_Low:SetColorAndOpacity(FSlateColor(FLinearColor(0.35, 0.15, 0.95, 1)))
end

local o_UpdateArtQualityUI = IngamePhoneStateUI.__inner_impl.UpdateArtQualityUI
IngamePhoneStateUI.__inner_impl.UpdateArtQualityUI = function(self, _, _)
    if o_UpdateArtQualityUI then o_UpdateArtQualityUI(self, _, _) end
    self.UIRoot.TextBlock_quality:SetText("XTHRLEN")
    self.UIRoot.TextBlock_quality:SetColorAndOpacity(FSlateColor(FLinearColor(1, 0, 0, 1)))
end

local o_TickRefreshBatteryInfo = IngamePhoneStateUI.__inner_impl.TickRefreshBatteryInfo
IngamePhoneStateUI.__inner_impl.TickRefreshBatteryInfo = function(self)
    if o_TickRefreshBatteryInfo then o_TickRefreshBatteryInfo(self) end
    self.UIRoot.ProgressBar_Battery:SetFillColorAndOpacity(FLinearColor(0.9, 0, 1, 1))
end

local o_SetPingText = IngamePhoneStateUI.__inner_impl.SetPingText
IngamePhoneStateUI.__inner_impl.SetPingText = function(self, ping, bLostNet)
    if o_SetPingText then o_SetPingText(self, ping, bLostNet) end
    self.UIRoot.TextBlock_Ping:SetColorAndOpacity(FSlateColor(FLinearColor(1, 0, 0.6, 1)))
end

-- ==============================================================================
-- 🎨 VIP JD MOD MENU - COMPACT EDITION - FINAL FIXED X
-- ==============================================================================
-- ==============================================================================
-- 🎨 VIP JD MOD MENU - COMPACT EDITION - TOUCH FIXED
-- ==============================================================================
-- ==============================================================================
-- 🎨 VP JD VIP MENU - Multi-Game Support
-- ==============================================================================
pcall(function()

local IsValid = function(o) return o and slua and slua.isValid and slua.isValid(o) end
local FLinearColor = import("LinearColor")
local FVector2D    = import("Vector2D")
local FAnchors     = import("Anchors")
local FSlateColor  = import("SlateColor") or import("/Script/SlateCore.SlateColor")

local C = {
    -- BENMOD reference palette: deep blue panels, bright cyan borders, magenta accents.
    bg_window      = FLinearColor(0.188, 0.329, 0.463, 0.99),
    bg_header      = FLinearColor(0.247, 0.408, 0.525, 1.00),
    bg_tabbar      = FLinearColor(0.125, 0.220, 0.353, 1.00),
    bg_content     = FLinearColor(0.125, 0.220, 0.353, 1.00),
    bg_panel       = FLinearColor(0.188, 0.329, 0.463, 1.00),
    bg_row         = FLinearColor(0.155, 0.275, 0.405, 1.00),
    bg_btn         = FLinearColor(0.20, 0.36, 0.49, 1.00),
    btn_save       = FLinearColor(0.00, 0.78, 0.95, 1.00),
    btn_load       = FLinearColor(0.698, 0.251, 0.867, 1.00),
    btn_danger     = FLinearColor(0.80, 0.20, 0.30, 1.00),
    accent         = FLinearColor(0.00, 0.882, 1.00, 1.00),
    accent_cyan    = FLinearColor(0.00, 1.00, 1.00, 1.00),
    accent_yellow  = FLinearColor(1.00, 0.78, 0.20, 1.00),
    accent_magenta = FLinearColor(0.698, 0.251, 0.867, 1.00),
    text_white     = FLinearColor(1.00, 1.00, 1.00, 1.00),
    text_dim       = FLinearColor(0.78, 0.88, 0.94, 1.00),
    text_green     = FLinearColor(0.00, 0.95, 1.00, 1.00),
    text_cyan      = FLinearColor(0.00, 1.00, 1.00, 1.00),
    text_yellow    = FLinearColor(1.00, 0.88, 0.30, 1.00),
    checkbox_off   = FLinearColor(0.12, 0.24, 0.34, 1.00),
    checkbox_on    = FLinearColor(0.00, 0.88, 1.00, 1.00),
    slider_track   = FLinearColor(0.10, 0.20, 0.30, 1.00),
    slider_fill    = FLinearColor(0.00, 0.88, 1.00, 1.00),
    slider_knob    = FLinearColor(1.00, 1.00, 1.00, 1.00),
    divider        = FLinearColor(0.00, 0.88, 1.00, 0.75),
    transparent    = FLinearColor(0, 0, 0, 0.001),
    black          = FLinearColor(0.125, 0.220, 0.353, 1),
}

local M_W = 560
local M_H = 380
local HEADER_H = 24
local TABBAR_H = 22
local ROW_H = 18
local SUBTAB_H = 20
local CB_SIZE = 11

local FS_TINY = 8
local FS_SMALL = 9
local FS_MED = 10

local TXT = {
  AR = {
    brand = "VP JD VIP", sub_brand = "Compact",
    tab_esp = "ESP", tab_esp_v2 = "ESP V2", tab_aim = "AIM", tab_combat = "COMBAT",
    tab_skin = "SKIN", tab_settings = "SET",
    sub_player = "لاعبين", sub_items = "عناصر", sub_vehicle = "مركبات", sub_bomb = "قنابل", sub_outline = "حدود",
    sub_v2_main = "V2", sub_v2_line = "خط", sub_v2_skel = "هيكل",
    sub_aim_custom = "مخصص", sub_aim_v2 = "V2", sub_recoil = "ارتداد", sub_magic = "سحرية",
    sub_hip = "HIP", sub_sg = "SG", sub_scope = "SCOPE", sub_sniper = "SNIP", sub_mortar = "MORTAR",
    lbl_speed = "السرعة", lbl_fov = "FOV", lbl_dist = "المسافة",
    lbl_pred = "التوقع", lbl_recoil = "الارتداد", lbl_bone = "العظم",
    lbl_prio = "الأولوية", lbl_thick = "السماكة", lbl_color = "اللون",
    lbl_radius = "نصف القطر", lbl_opacity = "الشفافية",
    lbl_outline_color = "لون", lbl_outline_thick = "سمك",
    lbl_magic_head = "رأس", lbl_magic_body = "جسم", lbl_magic_legs = "ساقين",
    lbl_glow_color = "لون", lbl_glow_thick = "سمك",
    lbl_line_thick = "سمك", lbl_line_vis = "ظاهر", lbl_line_hid = "مخفي",
    lbl_skel_thick = "سمك", lbl_skel_vis = "ظاهر", lbl_skel_hid = "مخفي",
    lbl_aim_cond = "شرط", lbl_fov_color = "لون",
    cb_esp_vip = "ESP VIP", cb_box = "إطار", cb_line = "خط",
    cb_hp = "صحة", cb_name = "اسم", cb_dist = "مسافة", cb_wep = "سلاح",
    cb_team = "فريق", cb_count = "عداد", cb_skel = "هيكل",
    cb_veh = "مركبات", cb_veh_dacia = "داسيا", cb_veh_uaz = "UAZ", cb_veh_buggy = "بوغي",
    cb_veh_coupe = "كوبيه", cb_veh_mirado = "ميرادو", cb_veh_motor = "دراجات", cb_veh_other = "أخرى",
    cb_item_master = "عناصر", cb_item_ar = "AR", cb_item_sn = "قنص", cb_item_smg = "SMG",
    cb_item_sg = "شوتغان", cb_item_lmg = "LMG", cb_item_pist = "مسدس", cb_item_melee = "قريبة",
    cb_item_special = "خاصة", cb_item_scope = "مناظير", cb_item_gren = "قنابل", cb_item_med = "طبية",
    cb_bom_master = "قنابل", cb_bom_item = "أرضية", cb_bom_active = "حمل",
    cb_outline = "حدود", cb_antenna = "هوائي",
    cb_aim_custom = "تصويب بعيد", cb_aim_close = "تصويب قريب",
    cb_less_shake = "اهتزاز", cb_accuracy = "دقة", cb_crosshair = "علامة",
    cb_auto_head = "رأس", cb_god = "تدمير",
    cb_h_recoil = "أفقي", cb_v_recoil = "عمودي",
    cb_magic = "سحرية",
    cb_aim_touch = "Aim Touch", cb_fov_circle = "دائرة",
    cb_ign_knock = "تجاهل ساقط", cb_ign_bot = "تجاهل بوت",
    cb_vis_check = "فحص رؤية", cb_auto_fire = "إطلاق تلقائي",
    cb_anti_cheat = "حماية", cb_hwid = "HWID وهمي",
    cb_ipad = "آيباد", cb_fps = "FPS", cb_fast_car = "سيارة سريعة",
    cb_wall = "جدران", cb_wall_veh = "جدران مركبة", cb_white_body = "جسم أبيض",
    cb_color_v2 = "تلوين V2", cb_color_new = "جديد",
    cb_color_v3 = "تلوين V3", cb_lava_esp = "كشف Lava", cb_sky = "سماء سوداء",
    cb_grass = "عشب", cb_trees = "أشجار", cb_fog = "ضباب",
    cb_weapon_glow = "توهج",
    cb_mod_skin = "جلود", cb_mod_emote = "إيموشن",
    cb_deadbox = "جثة", cb_attachment = "ملحقات",
    cb_kill_msg = "رسالة قتل", cb_kill_ui = "عداد قتل",
    btn_save = "حفظ", btn_load = "تحميل", btn_reset = "إعادة",
    lang_ar = "عربي", lang_en = "EN",
    footer = "VP JD VIP",
    open_menu = "OPEN", close_menu = "CLOSE",
  },
  EN = {
    brand = "VP JD VIP", sub_brand = "Compact",
    tab_esp = "ESP", tab_esp_v2 = "ESP V2", tab_aim = "AIM", tab_combat = "COMBAT",
    tab_skin = "SKIN", tab_settings = "SET",
    sub_player = "Player", sub_items = "Items", sub_vehicle = "Vehicle", sub_bomb = "Bomb", sub_outline = "Outline",
    sub_v2_main = "V2", sub_v2_line = "Line", sub_v2_skel = "Skel",
    sub_aim_custom = "Custom", sub_aim_v2 = "V2", sub_recoil = "Recoil", sub_magic = "Magic",
    sub_hip = "HIP", sub_sg = "SG", sub_scope = "SCOPE", sub_sniper = "SNIP", sub_mortar = "MORTAR",
    lbl_speed = "Speed", lbl_fov = "FOV", lbl_dist = "Dist",
    lbl_pred = "Pred", lbl_recoil = "Recoil", lbl_bone = "Bone",
    lbl_prio = "Prio", lbl_thick = "Thick", lbl_color = "Color",
    lbl_radius = "Radius", lbl_opacity = "Opacity",
    lbl_outline_color = "Color", lbl_outline_thick = "Thick",
    lbl_magic_head = "Head", lbl_magic_body = "Body", lbl_magic_legs = "Legs",
    lbl_glow_color = "Color", lbl_glow_thick = "Thick",
    lbl_line_thick = "Thick", lbl_line_vis = "Vis", lbl_line_hid = "Hid",
    lbl_skel_thick = "Thick", lbl_skel_vis = "Vis", lbl_skel_hid = "Hid",
    lbl_aim_cond = "Cond", lbl_fov_color = "Color",
    cb_esp_vip = "ESP VIP", cb_box = "Box", cb_line = "Line",
    cb_hp = "HP", cb_name = "Name", cb_dist = "Dist", cb_wep = "Weapon",
    cb_team = "Team", cb_count = "Count", cb_skel = "Skel",
    cb_veh = "Vehicles", cb_veh_dacia = "Dacia", cb_veh_uaz = "UAZ", cb_veh_buggy = "Buggy",
    cb_veh_coupe = "Coupe", cb_veh_mirado = "Mirado", cb_veh_motor = "Motor", cb_veh_other = "Other",
    cb_item_master = "Items", cb_item_ar = "AR", cb_item_sn = "Sniper", cb_item_smg = "SMG",
    cb_item_sg = "Shotgun", cb_item_lmg = "LMG", cb_item_pist = "Pistol", cb_item_melee = "Melee",
    cb_item_special = "Special", cb_item_scope = "Scopes", cb_item_gren = "Gren", cb_item_med = "Med",
    cb_bom_master = "Bombs", cb_bom_item = "Ground", cb_bom_active = "Carry",
    cb_outline = "Outline", cb_antenna = "Antenna",
    cb_aim_custom = "Far Aimbot", cb_aim_close = "Close Aim",
    cb_less_shake = "Shake", cb_accuracy = "Accuracy", cb_crosshair = "Crosshair",
    cb_auto_head = "Head", cb_god = "God",
    cb_h_recoil = "H-Recoil", cb_v_recoil = "V-Recoil",
    cb_magic = "Magic Bullet",
    cb_aim_touch = "Aim Touch", cb_fov_circle = "Circle",
    cb_ign_knock = "Ig Knock", cb_ign_bot = "Ig Bot",
    cb_vis_check = "Vis Check", cb_auto_fire = "Auto Fire",
    cb_anti_cheat = "Anti-Ban", cb_hwid = "Fake HWID",
    cb_ipad = "iPad", cb_fps = "FPS", cb_fast_car = "Fast Car",
    cb_wall = "Wall", cb_wall_veh = "Veh Wall", cb_white_body = "White Body",
    cb_color_v2 = "Color V2", cb_color_new = "New",
    cb_color_v3 = "Color V3", cb_lava_esp = "Lava ESP", cb_sky = "Black Sky",
    cb_grass = "Grass", cb_trees = "Trees", cb_fog = "Fog",
    cb_weapon_glow = "Glow",
    cb_mod_skin = "Skins", cb_mod_emote = "Emotes",
    cb_deadbox = "Deadbox", cb_attachment = "Attachments",
    cb_kill_msg = "Kill Msg", cb_kill_ui = "Kill UI",
    btn_save = "SAVE", btn_load = "LOAD", btn_reset = "RESET",
    lang_ar = "AR", lang_en = "EN",
    footer = "VP JD VIP",
    open_menu = "OPEN", close_menu = "CLOSE",
  }
}

local Lang = "AR"
local function T(k) return (TXT[Lang] and TXT[Lang][k]) or (TXT.EN[k]) or k end

_G.LexusConfig = _G.LexusConfig or {}
_G.LexusState = _G.LexusState or {}
_G.LexusState.CustomTextData = _G.LexusState.CustomTextData or {}

parentCanvas = nil
bgPanel = nil
allWidgets = {}
floatItems = {}
isMenuOpen = false
menuBuilt = false
currentTopTab = 1
currentSubTab = {}
topTabs = {}
subTabs = {}
contentPanels = {}
floatBtn = nil
cachedPC = nil

local function GetCanvas()
    if parentCanvas and Game:IsValid(parentCanvas) then return parentCanvas end
    parentCanvas = nil
    pcall(function()
        local IGT = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools")
        local MainUI = IGT.GetMainControlBaseUI()
        if not MainUI or not Game:IsValid(MainUI) then return end
        if MainUI.CanvasPanel_0 and Game:IsValid(MainUI.CanvasPanel_0) then
            parentCanvas = MainUI.CanvasPanel_0
        elseif MainUI.CanvasPanel_42 and Game:IsValid(MainUI.CanvasPanel_42) then
            parentCanvas = MainUI.CanvasPanel_42
        end
    end)
    return parentCanvas
end

local function GetPC()
    if IsValid(cachedPC) then return cachedPC end
    local pc = nil
    pcall(function()
        if slua_GameFrontendHUD then pc = slua_GameFrontendHUD:GetPlayerController() end
    end)
    if IsValid(pc) then cachedPC = pc end
    return pc
end

local function ClearAll()
    for _, w in ipairs(allWidgets) do
        if w and IsValid(w) then
            local isFloat = false
            for _, fw in ipairs(floatItems) do
                if w == fw then isFloat = true break end
            end
            if not isFloat then
                pcall(function() w:RemoveFromParent() end)
                pcall(function() w:ConditionalBeginDestroy() end)
            end
        end
    end
    allWidgets = {}
end

-- ===== WIDGET HELPERS =====
local function Layer(p, x, y, w, h, col, z)
    local b = nil
    pcall(function()
        b = CGame:NewObjectFromPath("/Script/UMG.Border", p)
        if b and slua.isValid(b) then
            b:SetBrushColor(col)
            b:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            local s = p:AddChildToCanvas(b)
            if s then
                s:SetAutoSize(false)
                s:SetPosition(FVector2D(x, y))
                s:SetSize(FVector2D(w, h))
                s:SetZOrder(z or 0)
            end
        end
    end)
    table.insert(allWidgets, b)
    return b
end

local function Text(p, txt, x, y, size, col, z, ax, ay)
    local t = nil
    pcall(function()
        t = CGame:NewObjectFromPath("/Script/UMG.TextBlock", p)
        if t and slua.isValid(t) then
            t:SetText(txt)
            if FSlateColor then t:SetColorAndOpacity(FSlateColor(col))
            else t:SetColorAndOpacity(col) end
            if t.Font then
                local f = t.Font
                f.Size = size
                t.Font = f
            end
            t:SetRenderTransformPivot(FVector2D(ax or 0.5, ay or 0.5))
            t:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            local s = p:AddChildToCanvas(t)
            if s then
                s:SetAutoSize(true)
                s:SetAlignment(FVector2D(ax or 0.5, ay or 0.5))
                s:SetPosition(FVector2D(x, y))
                s:SetZOrder(z or 100)
            end
        end
    end)
    table.insert(allWidgets, t)
    return t
end

local function Btn(p, x, y, w, h, z, onClick)
    local btn = nil
    pcall(function()
        btn = CGame:NewObjectFromPath("/Script/UMG.Button", p)
        if btn and slua.isValid(btn) then
            pcall(function() btn:SetColorAndOpacity(C.transparent) end)
            pcall(function() btn:SetBackgroundColor(C.transparent) end)
            pcall(function() btn:SetWidgetVisibility(UEnums.ESlateVisibility.Visible) end)
            local s = p:AddChildToCanvas(btn)
            if s then
                s:SetAutoSize(false)
                s:SetPosition(FVector2D(x, y))
                s:SetSize(FVector2D(w, h))
                s:SetZOrder(z or 900)
            end
            if onClick and btn.OnClicked then
                pcall(function() btn.OnClicked:Add(function() pcall(onClick) end) end)
            end
        end
    end)
    table.insert(allWidgets, btn)
    return btn
end

local function RawLayer(p, x, y, w, h, col, z)
    local b = nil
    pcall(function()
        b = CGame:NewObjectFromPath("/Script/UMG.Border", p)
        if b and slua.isValid(b) then
            b:SetBrushColor(col)
            b:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            local s = p:AddChildToCanvas(b)
            if s then
                s:SetAutoSize(false)
                s:SetPosition(FVector2D(x, y))
                s:SetSize(FVector2D(w, h))
                s:SetZOrder(z or 0)
            end
        end
    end)
    table.insert(floatItems, b)
    return b
end

local function RawText(p, txt, x, y, size, col, z, ax, ay)
    local t = nil
    pcall(function()
        t = CGame:NewObjectFromPath("/Script/UMG.TextBlock", p)
        if t and slua.isValid(t) then
            t:SetText(txt)
            if FSlateColor then t:SetColorAndOpacity(FSlateColor(col))
            else t:SetColorAndOpacity(col) end
            if t.Font then
                local f = t.Font
                f.Size = size
                t.Font = f
            end
            t:SetRenderTransformPivot(FVector2D(ax or 0.5, ay or 0.5))
            t:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            local s = p:AddChildToCanvas(t)
            if s then
                s:SetAutoSize(true)
                s:SetAlignment(FVector2D(ax or 0.5, ay or 0.5))
                s:SetPosition(FVector2D(x, y))
                s:SetZOrder(z or 100)
            end
        end
    end)
    table.insert(floatItems, t)
    return t
end

local function RawBtn(p, x, y, w, h, z, onClick)
    local btn = nil
    pcall(function()
        btn = CGame:NewObjectFromPath("/Script/UMG.Button", p)
        if btn and slua.isValid(btn) then
            pcall(function() btn:SetColorAndOpacity(C.transparent) end)
            pcall(function() btn:SetBackgroundColor(C.transparent) end)
            pcall(function() btn:SetWidgetVisibility(UEnums.ESlateVisibility.Visible) end)
            local s = p:AddChildToCanvas(btn)
            if s then
                s:SetAutoSize(false)
                s:SetPosition(FVector2D(x, y))
                s:SetSize(FVector2D(w, h))
                s:SetZOrder(z or 900)
            end
            if onClick and btn.OnClicked then
                pcall(function() btn.OnClicked:Add(function() pcall(onClick) end) end)
            end
        end
    end)
    table.insert(floatItems, btn)
    return btn
end

-- ===== WIDGETS =====
local function Checkbox(parent, x, y, key, labelKey, isCT)
    local store = isCT and _G.LexusState.CustomTextData or _G.LexusConfig
    local state = store[key] == true
    local box = Layer(parent, x, y + 3, CB_SIZE, CB_SIZE, state and C.checkbox_on or C.checkbox_off, 400)
    Layer(parent, x + 2, y + 5, CB_SIZE - 4, CB_SIZE - 4, state and C.text_white or C.transparent, 401)
    local txt = Text(parent, T(labelKey), x + 16, y + 3 + CB_SIZE * 0.5, FS_SMALL, state and C.text_white or C.text_dim, 402, 0, 0.5)
    Btn(parent, x, y, 180, ROW_H, 850, function()
        state = not state
        store[key] = state
        pcall(function()
            box:SetBrushColor(state and C.checkbox_on or C.checkbox_off)
            if FSlateColor then
                txt:SetColorAndOpacity(FSlateColor(state and C.text_white or C.text_dim))
            end
        end)
    end)
end

local function Slider(parent, x, y, w, key, labelKey, min, max, step, isCT)
    local store = isCT and _G.LexusState.CustomTextData or _G.LexusConfig
    local val = tonumber(store[key]) or min
    if val < min then val = min end
    if val > max then val = max end
    
    Text(parent, T(labelKey), x, y, FS_SMALL, C.text_white, 402, 0, 0.5)
    local valTxt = Text(parent, tostring(math.floor(val + 0.5)), x + w, y, FS_SMALL, C.text_cyan, 403, 1, 0.5)
    
    local barY = y + 13
    local barH = 8
    Layer(parent, x, barY, w, barH, C.slider_track, 401)
    local pct0 = (val - min) / (max - min)
    local fill = Layer(parent, x, barY, w * pct0, barH, C.slider_fill, 402)
    
    local knobSize = 14
    local knobX = x + (w * pct0) - knobSize * 0.5
    local knobY = barY + barH * 0.5 - knobSize * 0.5
    Layer(parent, knobX - 1, knobY - 1, knobSize + 2, knobSize + 2, C.accent, 403)
    local knob = Layer(parent, knobX, knobY, knobSize, knobSize, C.slider_knob, 404)
    
    local function applyVal(v)
        v = math.floor((v - min) / step + 0.5) * step + min
        if v < min then v = min end
        if v > max then v = max end
        store[key] = v
        valTxt:SetText(tostring(math.floor(v + 0.5)))
        local pct = (v - min) / (max - min)
        local s1 = fill.Slot
        if s1 then s1:SetSize(FVector2D(w * pct, barH)) end
        local kx = x + w * pct - knobSize * 0.5
        local s2 = knob.Slot
        if s2 then s2:SetPosition(FVector2D(kx, knobY)) end
    end
    
    local segments = 20
    local segW = w / segments
    for si = 1, segments do
        local targetPct = (si - 0.5) / segments
        local segX = x + (si - 1) * segW
        pcall(function()
            local segBtn = CGame:NewObjectFromPath("/Script/UMG.Button", parent)
            if segBtn and slua.isValid(segBtn) then
                segBtn:SetColorAndOpacity(C.transparent)
                segBtn:SetBackgroundColor(C.transparent)
                segBtn:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
                local ss = parent:AddChildToCanvas(segBtn)
                if ss then
                    ss:SetAutoSize(false)
                    ss:SetPosition(FVector2D(segX, barY - 5))
                    ss:SetSize(FVector2D(segW, barH + 10))
                    ss:SetZOrder(890)
                end
                if segBtn.OnClicked then
                    segBtn.OnClicked:Add(function()
                        pcall(function()
                            applyVal(min + (max - min) * targetPct)
                        end)
                    end)
                end
                table.insert(allWidgets, segBtn)
            end
        end)
    end
end

local function FlatBtn(parent, x, y, w, h, labelKey, color, onClick)
    Layer(parent, x, y, w, h, color, 400)
    Text(parent, T(labelKey), x + w * 0.5, y + h * 0.5, FS_SMALL, C.text_white, 402, 0.5, 0.5)
    Btn(parent, x, y, w, h, 850, onClick)
end

local function TopTab(parent, labelKey, x, y, w, h, index)
    local isActive = (index == currentTopTab)
    local t = { index = index, labelKey = labelKey }
    t.bg = Layer(parent, x, y, w, h, isActive and C.bg_panel or C.bg_tabbar, 100)
    t.accent = Layer(parent, x, y + h - 2, w, 2, isActive and C.accent or C.transparent, 101)
    t.text = Text(parent, T(labelKey), x + w * 0.5, y + h * 0.5, FS_SMALL, isActive and C.text_green or C.text_dim, 300, 0.5, 0.5)
    Btn(parent, x, y, w, h, 850, function()
        if currentTopTab == index then return end
        currentTopTab = index
        for _, s in ipairs(topTabs) do
            if s and IsValid(s.bg) then
                local act = (s.index == index)
                pcall(function()
                    s.bg:SetBrushColor(act and C.bg_panel or C.bg_tabbar)
                    s.accent:SetBrushColor(act and C.accent or C.transparent)
                    if FSlateColor then
                        s.text:SetColorAndOpacity(FSlateColor(act and C.text_green or C.text_dim))
                    end
                end)
            end
        end
        for i, p in ipairs(contentPanels) do
            if p and IsValid(p) then
                pcall(function()
                    p:SetWidgetVisibility(i == index and UEnums.ESlateVisibility.Visible or UEnums.ESlateVisibility.Collapsed)
                end)
            end
        end
    end)
    topTabs[index] = t
end

local function SubTab(parent, labelKey, x, y, w, h, pageKey, index, colorOverride)
    currentSubTab[pageKey] = currentSubTab[pageKey] or 1
    local isActive = (index == currentSubTab[pageKey])
    local bgCol = isActive and (colorOverride or C.accent) or C.bg_btn
    local txtCol = isActive and C.black or C.text_white
    
    local st = { index = index, labelKey = labelKey, pageKey = pageKey }
    st.bg = Layer(parent, x, y, w, h, bgCol, 100)
    st.text = Text(parent, T(labelKey), x + w * 0.5, y + h * 0.5, FS_TINY, txtCol, 300, 0.5, 0.5)
    Btn(parent, x, y, w, h, 850, function()
        currentSubTab[pageKey] = index
        if subTabs[pageKey] then
            for _, s in ipairs(subTabs[pageKey]) do
                if s and IsValid(s.bg) then
                    local act = (s.index == index)
                    pcall(function()
                        s.bg:SetBrushColor(act and (colorOverride or C.accent) or C.bg_btn)
                        if FSlateColor then
                            s.text:SetColorAndOpacity(FSlateColor(act and C.black or C.text_white))
                        end
                    end)
                end
            end
        end
        if contentPanels[pageKey .. "_sub"] then
            for i, p in ipairs(contentPanels[pageKey .. "_sub"]) do
                if p and IsValid(p) then
                    pcall(function()
                        p:SetWidgetVisibility(i == index and UEnums.ESlateVisibility.Visible or UEnums.ESlateVisibility.Collapsed)
                    end)
                end
            end
        end
    end)
    subTabs[pageKey] = subTabs[pageKey] or {}
    subTabs[pageKey][index] = st
end

-- ==================== BUILD PAGES ====================
local function BuildTopPages()
    local contentX = 6
    local contentY = HEADER_H + TABBAR_H + 3
    local contentW = M_W - 12
    local contentH = M_H - contentY - 14

    local function makePanel(z)
        local p = nil
        pcall(function()
            p = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", bgPanel)
            if p and slua.isValid(p) then
                local s = bgPanel:AddChildToCanvas(p)
                if s then
                    s:SetAutoSize(false)
                    s:SetPosition(FVector2D(contentX, contentY))
                    s:SetSize(FVector2D(contentW, contentH))
                    s:SetZOrder(30 + (z or 0))
                end
                p:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
            end
        end)
        return p
    end

    contentPanels = {}

    -- PAGE 1: ESP
    local p1 = makePanel(0); contentPanels[1] = p1
    if p1 and IsValid(p1) then
        Layer(p1, 0, 0, contentW, contentH, C.bg_content, 100)
        local subKeys = {"sub_player", "sub_items", "sub_vehicle", "sub_bomb", "sub_outline"}
        local subW = (contentW - 15) / #subKeys
        local subX = 8
        for i, k in ipairs(subKeys) do
            SubTab(p1, k, subX, 4, subW - 3, SUBTAB_H, 1, i)
            subX = subX + subW
        end

        contentPanels["1_sub"] = {}
        local padY = SUBTAB_H + 10
        local padX = 8
        local colW = (contentW - 16 - padX * 3) / 2
        local innerH = contentH - padY - 6

        local sp = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", p1)
        local s = p1:AddChildToCanvas(sp)
        s:SetAutoSize(false); s:SetPosition(FVector2D(8, padY)); s:SetSize(FVector2D(contentW - 16, innerH)); s:SetZOrder(500)
        sp:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
        contentPanels["1_sub"][1] = sp
        Layer(sp, 0, 0, colW, innerH, C.bg_panel, 200)
        local y1 = 6
        for i, k in ipairs({{"EspVip","cb_esp_vip"},{"EspLoai5","cb_box"},{"EspLoai6","cb_line"},{"EspDistance","cb_dist"},{"Esp9_HP","cb_hp"},{"Esp9_Name","cb_name"},{"Esp9_Weapon","cb_wep"},{"Esp9_Count","cb_count"},{"Esp7_TuThe","cb_team"},{"EspAntenna","cb_antenna"}}) do
            Checkbox(sp, 6, y1, k[1], k[2], false); y1 = y1 + ROW_H
        end
        Layer(sp, colW + 6, 0, colW, innerH, C.bg_panel, 200)
        local y2 = 6
        for i, k in ipairs({{"WallXuyenTuong","cb_wall"},{"WallVehicle","cb_wall_veh"},{"ColorBodyV2","cb_color_v2"},{"ColorBodyNew","cb_color_new"},{"ColorBodyV3","cb_color_v3"},{"LavaESP","cb_lava_esp"},{"WhiteBody","cb_white_body"},{"EspOutline","cb_outline"},{"EspFovCircle","cb_fov_circle"}}) do
            Checkbox(sp, colW + 12, y2, k[1], k[2], false); y2 = y2 + ROW_H
        end
        y2 = y2 + 4
        Slider(sp, colW + 24, y2, colW - 60, "OutlineThickness", "lbl_outline_thick", 1, 20, 1, false); y2 = y2 + 26
        Slider(sp, colW + 24, y2, colW - 60, "OutlineColor", "lbl_outline_color", 1, 6, 1, true); y2 = y2 + 26
        Slider(sp, colW + 24, y2, colW - 60, "FovCircleRadius", "lbl_radius", 10, 200, 5, true); y2 = y2 + 26
        Slider(sp, colW + 24, y2, colW - 60, "FovCircleThick", "lbl_thick", 1, 10, 1, true)

        local sp2 = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", p1)
        local s2 = p1:AddChildToCanvas(sp2)
        s2:SetAutoSize(false); s2:SetPosition(FVector2D(8, padY)); s2:SetSize(FVector2D(contentW - 16, innerH)); s2:SetZOrder(500)
        sp2:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
        contentPanels["1_sub"][2] = sp2
        Layer(sp2, 0, 0, colW, innerH, C.bg_panel, 200)
        y1 = 6
        for i, k in ipairs({{"EspItem_Master","cb_item_master"},{"EspItem_AR","cb_item_ar"},{"EspItem_Sniper","cb_item_sn"},{"EspItem_SMG","cb_item_smg"},{"EspItem_Shotgun","cb_item_sg"},{"EspItem_LMG","cb_item_lmg"}}) do
            Checkbox(sp2, 6, y1, k[1], k[2], false); y1 = y1 + ROW_H
        end
        Layer(sp2, colW + 6, 0, colW, innerH, C.bg_panel, 200)
        y2 = 6
        for i, k in ipairs({{"EspItem_Pistol","cb_item_pist"},{"EspItem_Melee","cb_item_melee"},{"EspItem_Special","cb_item_special"},{"EspItem_Scope","cb_item_scope"},{"EspItem_Grenade","cb_item_gren"},{"EspItem_Med","cb_item_med"}}) do
            Checkbox(sp2, colW + 12, y2, k[1], k[2], false); y2 = y2 + ROW_H
        end

        local sp3 = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", p1)
        local s3 = p1:AddChildToCanvas(sp3)
        s3:SetAutoSize(false); s3:SetPosition(FVector2D(8, padY)); s3:SetSize(FVector2D(contentW - 16, innerH)); s3:SetZOrder(500)
        sp3:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
        contentPanels["1_sub"][3] = sp3
        Layer(sp3, 0, 0, colW, innerH, C.bg_panel, 200)
        y1 = 6
        for i, k in ipairs({{"EspVehicle","cb_veh"},{"EspVeh_Dacia","cb_veh_dacia"},{"EspVeh_UAZ","cb_veh_uaz"},{"EspVeh_Buggy","cb_veh_buggy"}}) do
            Checkbox(sp3, 6, y1, k[1], k[2], false); y1 = y1 + ROW_H
        end
        Layer(sp3, colW + 6, 0, colW, innerH, C.bg_panel, 200)
        y2 = 6
        for i, k in ipairs({{"EspVeh_Coupe","cb_veh_coupe"},{"EspVeh_Mirado","cb_veh_mirado"},{"EspVeh_Motor","cb_veh_motor"},{"EspVeh_Other","cb_veh_other"}}) do
            Checkbox(sp3, colW + 12, y2, k[1], k[2], false); y2 = y2 + ROW_H
        end

        local sp4 = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", p1)
        local s4 = p1:AddChildToCanvas(sp4)
        s4:SetAutoSize(false); s4:SetPosition(FVector2D(8, padY)); s4:SetSize(FVector2D(contentW - 16, innerH)); s4:SetZOrder(500)
        sp4:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
        contentPanels["1_sub"][4] = sp4
        Layer(sp4, 0, 0, colW, innerH, C.bg_panel, 200)
        y1 = 6
        for i, k in ipairs({{"EspBomMaster","cb_bom_master"},{"EspItemBom","cb_bom_item"},{"EspActiveBom","cb_bom_active"}}) do
            Checkbox(sp4, 6, y1, k[1], k[2], false); y1 = y1 + ROW_H
        end

        local sp5 = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", p1)
        local s5 = p1:AddChildToCanvas(sp5)
        s5:SetAutoSize(false); s5:SetPosition(FVector2D(8, padY)); s5:SetSize(FVector2D(contentW - 16, innerH)); s5:SetZOrder(500)
        sp5:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
        contentPanels["1_sub"][5] = sp5
        Layer(sp5, 0, 0, colW, innerH, C.bg_panel, 200)
        y1 = 6
        for i, k in ipairs({{"EspVipPro","cb_esp_vip"},{"Esp3ShowName","cb_name"},{"Esp3ShowHP","cb_hp"},{"EspRadar","cb_box"},{"EspLoai7","cb_count"},{"Esp7_SoLuong","cb_count"},{"Esp7_VuKhi","cb_wep"},{"EspAimWarning","cb_box"}}) do
            Checkbox(sp5, 6, y1, k[1], k[2], false); y1 = y1 + ROW_H
        end
    end

    -- PAGE 2: ESP V2
    local p2 = makePanel(1); contentPanels[2] = p2
    if p2 and IsValid(p2) then
        Layer(p2, 0, 0, contentW, contentH, C.bg_content, 100)
        local subKeys = {"sub_v2_main", "sub_v2_line", "sub_v2_skel"}
        local subW = (contentW - 15) / #subKeys
        local subX = 8
        for i, k in ipairs(subKeys) do
            SubTab(p2, k, subX, 4, subW - 3, SUBTAB_H, 2, i, C.accent_cyan)
            subX = subX + subW
        end

        contentPanels["2_sub"] = {}
        local padY = SUBTAB_H + 10
        local padX = 8
        local colW = (contentW - 16 - padX * 3) / 2
        local innerH = contentH - padY - 6

        local sp = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", p2)
        local s = p2:AddChildToCanvas(sp)
        s:SetAutoSize(false); s:SetPosition(FVector2D(8, padY)); s:SetSize(FVector2D(contentW - 16, innerH)); s:SetZOrder(500)
        sp:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
        contentPanels["2_sub"][1] = sp
        Layer(sp, 0, 0, colW, innerH, C.bg_panel, 200)
        y1 = 6
        for i, k in ipairs({{"EspLoai9","cb_esp_vip"},{"Esp9_Count","cb_count"},{"Esp9_Name","cb_name"},{"Esp9_Distance","cb_dist"},{"Esp9_HP","cb_hp"},{"Esp9_Team","cb_team"},{"Esp9_Weapon","cb_wep"}}) do
            Checkbox(sp, 6, y1, k[1], k[2], false); y1 = y1 + ROW_H
        end
        Layer(sp, colW + 6, 0, colW, innerH, C.bg_panel, 200)
        Text(sp, "ESP V2", colW + 12, 14, FS_MED, C.text_green, 300, 0, 0.5)
        Text(sp, "الصندوق الأحمر تلقائي", colW + 12, 30, FS_SMALL, C.text_dim, 300, 0, 0.5)

        local sp2 = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", p2)
        local s2 = p2:AddChildToCanvas(sp2)
        s2:SetAutoSize(false); s2:SetPosition(FVector2D(8, padY)); s2:SetSize(FVector2D(contentW - 16, innerH)); s2:SetZOrder(500)
        sp2:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
        contentPanels["2_sub"][2] = sp2
        Layer(sp2, 0, 0, colW, innerH, C.bg_panel, 200)
        y1 = 6
        Checkbox(sp2, 6, y1, "Esp9_Line", "cb_line", false); y1 = y1 + ROW_H + 3
        Slider(sp2, 24, y1, colW - 60, "Esp9_LineThick", "lbl_line_thick", 1, 10, 1, true); y1 = y1 + 26
        Slider(sp2, 24, y1, colW - 60, "Esp9_LineVisColor", "lbl_line_vis", 1, 30, 1, true); y1 = y1 + 26
        Slider(sp2, 24, y1, colW - 60, "Esp9_LineHidColor", "lbl_line_hid", 1, 30, 1, true)

        local sp3 = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", p2)
        local s3 = p2:AddChildToCanvas(sp3)
        s3:SetAutoSize(false); s3:SetPosition(FVector2D(8, padY)); s3:SetSize(FVector2D(contentW - 16, innerH)); s3:SetZOrder(500)
        sp3:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
        contentPanels["2_sub"][3] = sp3
        Layer(sp3, 0, 0, colW, innerH, C.bg_panel, 200)
        y1 = 6
        Checkbox(sp3, 6, y1, "Esp9_Skeleton", "cb_skel", false); y1 = y1 + ROW_H + 3
        Slider(sp3, 24, y1, colW - 60, "Esp9_SkelThick", "lbl_skel_thick", 1, 10, 1, true); y1 = y1 + 26
        Slider(sp3, 24, y1, colW - 60, "Esp9_SkelVisColor", "lbl_skel_vis", 1, 30, 1, true); y1 = y1 + 26
        Slider(sp3, 24, y1, colW - 60, "Esp9_SkelHidColor", "lbl_skel_hid", 1, 30, 1, true)
    end

    -- PAGE 3: AIMBOT
    local p3 = makePanel(2); contentPanels[3] = p3
    if p3 and IsValid(p3) then
        Layer(p3, 0, 0, contentW, contentH, C.bg_content, 100)
        local subKeys = {"sub_aim_custom", "sub_aim_v2", "sub_recoil", "sub_magic"}
        local subW = (contentW - 15) / #subKeys
        local subX = 8
        for i, k in ipairs(subKeys) do
            SubTab(p3, k, subX, 4, subW - 3, SUBTAB_H, 3, i, C.accent_yellow)
            subX = subX + subW
        end
        contentPanels["3_sub"] = {}
        local padY = SUBTAB_H + 10
        local padX = 8
        local colW = (contentW - 16 - padX * 3) / 2
        local innerH = contentH - padY - 6

        local sp = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", p3)
        local s = p3:AddChildToCanvas(sp)
        s:SetAutoSize(false); s:SetPosition(FVector2D(8, padY)); s:SetSize(FVector2D(contentW - 16, innerH)); s:SetZOrder(500)
        sp:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
        contentPanels["3_sub"][1] = sp
        Layer(sp, 0, 0, colW, innerH, C.bg_panel, 200)
        y1 = 6
        Checkbox(sp, 6, y1, "CustomAimbot", "cb_aim_custom", false); y1 = y1 + ROW_H
        Slider(sp, 24, y1, colW - 60, "OuterSpeed", "lbl_speed", 1, 100, 1, true); y1 = y1 + 26
        Slider(sp, 24, y1, colW - 60, "OuterRecoil", "lbl_recoil", 0, 50, 1, true); y1 = y1 + 26
        y1 = y1 + 3
        Checkbox(sp, 6, y1, "CustomAimbotClose", "cb_aim_close", false); y1 = y1 + ROW_H
        Slider(sp, 24, y1, colW - 60, "InnerSpeed", "lbl_speed", 1, 100, 1, true); y1 = y1 + 26
        y1 = y1 + 3
        Checkbox(sp, 6, y1, "AutoHead", "cb_auto_head", false); y1 = y1 + ROW_H
        Checkbox(sp, 6, y1, "Accuracy", "cb_accuracy", false); y1 = y1 + ROW_H
        Checkbox(sp, 6, y1, "Crosshair", "cb_crosshair", false); y1 = y1 + ROW_H
        Checkbox(sp, 6, y1, "LessShake", "cb_less_shake", false); y1 = y1 + ROW_H
        Checkbox(sp, 6, y1, "GodMode", "cb_god", false)

        local sp2 = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", p3)
        local s2 = p3:AddChildToCanvas(sp2)
        s2:SetAutoSize(false); s2:SetPosition(FVector2D(8, padY)); s2:SetSize(FVector2D(contentW - 16, innerH)); s2:SetZOrder(500)
        sp2:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
        contentPanels["3_sub"][2] = sp2

        Checkbox(sp2, 6, 4, "AimTouchEnable", "cb_aim_touch", false)
        Checkbox(sp2, 180, 4, "EspFovCircle", "cb_fov_circle", false)

        local inSubKeys = {"sub_hip", "sub_sg", "sub_scope", "sub_sniper", "sub_mortar"}
        local inSubW = (contentW - 16 - 10) / #inSubKeys
        local inSubX = 10
        for i, k in ipairs(inSubKeys) do
            SubTab(sp2, k, inSubX, 22, inSubW - 3, SUBTAB_H, "3_2", i, C.accent_cyan)
            inSubX = inSubX + inSubW
        end

        contentPanels["3_2_sub"] = {}
        local inPadY = 22 + SUBTAB_H + 5
        local inH = innerH - inPadY - 3

        local aimConfigs = {
            {enable="AimTouchHipfire",    speed="AimTouchHipSpeed",    fov="AimTouchHipFOV",    dist="AimTouchHipDist",    pred="AimTouchHipPred",    recoil="AimTouchHipRecoil",    bone="AimTouchHipBone",    prio="AimTouchHipPrio",    cond="AimTouchHipCond",    fovColor="AimTouchHipFOVColor",    visCheck="AimTouchHipVisCheck",    igKnock="AimTouchHipIgKnock",    igBot="AimTouchHipIgBot"},
            {enable="AimTouchSG",         speed="AimTouchSGSpeed",      fov="AimTouchSGFOV",      dist="AimTouchSGFOVDist",  pred="AimTouchSGPred",     recoil="AimTouchSGRecoil",     bone="AimTouchSGBone",     prio="AimTouchSGPrio",     cond="AimTouchSGCond",     fovColor="AimTouchSGFOVColor",     visCheck="AimTouchSGVisCheck",     igKnock="AimTouchSGIgKnock",     igBot="AimTouchSGIgBot",     autoFire="AimTouchSGAutoFire"},
            {enable="AimTouchScopeAll",   speed="AimTouchScopeSpeed",   fov="AimTouchScopeFOV",   dist="AimTouchScopeDist",  pred="AimTouchScopePred",  recoil="AimTouchScopeRecoil",  bone="AimTouchScopeBone",  prio="AimTouchScopePrio",  cond="AimTouchScopeCond",  fovColor="AimTouchScopeFOVColor",  visCheck="AimTouchScopeVisCheck",  igKnock="AimTouchScopeIgKnock",  igBot="AimTouchScopeIgBot"},
            {enable="AimTouchScopeSniper",speed="AimTouchSniperSpeed",  fov="AimTouchSniperFOV",  dist="AimTouchSniperDist", pred="AimTouchSniperPred", recoil="AimTouchSniperRecoil", bone="AimTouchSniperBone", prio="AimTouchSniperPrio", cond="AimTouchSniperCond", fovColor="AimTouchSniperFOVColor", visCheck="AimTouchSniperVisCheck", igKnock="AimTouchSniperIgKnock", igBot="AimTouchSniperIgBot"},
            {enable="AimTouchMortar",     speed="AimTouchMortarSpeed",   fov="AimTouchMortarFOV",   dist="AimTouchMortarDist", pred="AimTouchMortarPred",                                                            fovColor="AimTouchMortarFOVColor"},
        }

        for i, cfg in ipairs(aimConfigs) do
            local sp = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", sp2)
            local s = sp2:AddChildToCanvas(sp)
            s:SetAutoSize(false)
            s:SetPosition(FVector2D(0, inPadY))
            s:SetSize(FVector2D(contentW - 16, inH))
            s:SetZOrder(600)
            sp:SetWidgetVisibility(i == 1 and UEnums.ESlateVisibility.Visible or UEnums.ESlateVisibility.Collapsed)
            contentPanels["3_2_sub"][i] = sp

            Layer(sp, 0, 0, colW, inH, C.bg_panel, 200)
            local yy = 4
            Checkbox(sp, 6, yy, cfg.enable, "cb_aim_touch", false)
            yy = yy + ROW_H + 2

            Slider(sp, 24, yy, colW - 60, cfg.speed, "lbl_speed", 5, 100, 5, true); yy = yy + 26
            Slider(sp, 24, yy, colW - 60, cfg.fov, "lbl_fov", 5, 360, 5, true);     yy = yy + 26
            Slider(sp, 24, yy, colW - 60, cfg.dist, "lbl_dist", 10, 500, 10, true); yy = yy + 26
            Slider(sp, 24, yy, colW - 60, cfg.pred, "lbl_pred", 0, 100, 5, true);   yy = yy + 26
            if cfg.recoil then Slider(sp, 24, yy, colW - 60, cfg.recoil, "lbl_recoil", 0, 100, 5, true); yy = yy + 26 end
            if cfg.bone   then Slider(sp, 24, yy, colW - 60, cfg.bone,   "lbl_bone",   1, 4, 1, true);   yy = yy + 26 end

            Layer(sp, colW + 6, 0, colW, inH, C.bg_panel, 200)
            local zz = 4
            if cfg.prio then Slider(sp, colW + 24, zz, colW - 60, cfg.prio, "lbl_prio", 1, 4, 1, true); zz = zz + 26 end
            if cfg.cond then Slider(sp, colW + 24, zz, colW - 60, cfg.cond, "lbl_aim_cond", 1, 2, 1, true); zz = zz + 26 end
            Slider(sp, colW + 24, zz, colW - 60, cfg.fovColor, "lbl_fov_color", 1, 7, 1, true); zz = zz + 26

            if cfg.visCheck then Checkbox(sp, colW + 6, zz, cfg.visCheck, "cb_vis_check", false); zz = zz + ROW_H end
            if cfg.igKnock  then Checkbox(sp, colW + 6, zz, cfg.igKnock,  "cb_ign_knock", false); zz = zz + ROW_H end
            if cfg.igBot    then Checkbox(sp, colW + 6, zz, cfg.igBot,    "cb_ign_bot",   false); zz = zz + ROW_H end
            if cfg.autoFire then Checkbox(sp, colW + 6, zz, cfg.autoFire, "cb_auto_fire", false); zz = zz + ROW_H end
        end

        local sp3 = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", p3)
        local s3 = p3:AddChildToCanvas(sp3)
        s3:SetAutoSize(false); s3:SetPosition(FVector2D(8, padY)); s3:SetSize(FVector2D(contentW - 16, innerH)); s3:SetZOrder(500)
        sp3:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
        contentPanels["3_sub"][3] = sp3
        Layer(sp3, 0, 0, colW, innerH, C.bg_panel, 200)
        y1 = 6
        Checkbox(sp3, 6, y1, "CustomHRecoil", "cb_h_recoil", false); y1 = y1 + ROW_H
        Slider(sp3, 24, y1, colW - 60, "HRecoil", "lbl_recoil", 0, 5, 0.1, true); y1 = y1 + 26
        y1 = y1 + 3
        Checkbox(sp3, 6, y1, "CustomVRecoil", "cb_v_recoil", false); y1 = y1 + ROW_H
        Slider(sp3, 24, y1, colW - 60, "VRecoil", "lbl_recoil", 0, 5, 0.1, true)

        local sp4 = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", p3)
        local s4 = p3:AddChildToCanvas(sp4)
        s4:SetAutoSize(false); s4:SetPosition(FVector2D(8, padY)); s4:SetSize(FVector2D(contentW - 16, innerH)); s4:SetZOrder(500)
        sp4:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
        contentPanels["3_sub"][4] = sp4
        Layer(sp4, 0, 0, colW, innerH, C.bg_panel, 200)
        y1 = 6
        Checkbox(sp4, 6, y1, "CustomMagicBullet", "cb_magic", false); y1 = y1 + ROW_H + 3
        Slider(sp4, 24, y1, colW - 60, "MagicHead", "lbl_magic_head", 0, 5, 0.1, true); y1 = y1 + 26
        Slider(sp4, 24, y1, colW - 60, "MagicBody", "lbl_magic_body", 0, 5, 0.1, true); y1 = y1 + 26
        Slider(sp4, 24, y1, colW - 60, "MagicLegs", "lbl_magic_legs", 0, 5, 0.1, true)
    end

    -- PAGE 4: COMBAT
    local p4 = makePanel(3); contentPanels[4] = p4
    if p4 and IsValid(p4) then
        Layer(p4, 0, 0, contentW, contentH, C.bg_content, 100)
        local padX = 8
        local colW = (contentW - 16 - padX * 3) / 2
        local innerH = contentH - 12
        Layer(p4, padX, 6, colW, innerH, C.bg_panel, 200)
        local y1 = 12
        for i, k in ipairs({{"AntiCheat","cb_anti_cheat"},{"FakeHWID","cb_hwid"},{"WallClimb","cb_wall"},{"RemoveGrass","cb_grass"},{"RemoveTrees","cb_trees"},{"RemoveFog","cb_fog"},{"BlackSky","cb_sky"},{"UnlockFPS","cb_fps"}}) do
            Checkbox(p4, padX + 6, y1, k[1], k[2], false); y1 = y1 + ROW_H
        end
        Layer(p4, padX + colW + padX, 6, colW, innerH, C.bg_panel, 200)
        local y2 = 12
        Checkbox(p4, padX + colW + padX + 6, y2, "IpadView", "cb_ipad", false); y2 = y2 + ROW_H
        Slider(p4, padX + colW + padX + 24, y2, colW - 60, "IpadViewFOV", "lbl_fov", 90, 160, 5, true); y2 = y2 + 26
        Slider(p4, padX + colW + padX + 24, y2, colW - 60, "IpadViewVehicleFOV", "lbl_fov", 90, 160, 5, true); y2 = y2 + 26
        Slider(p4, padX + colW + padX + 24, y2, colW - 60, "IpadViewScopeFOV", "lbl_fov", 30, 120, 5, true); y2 = y2 + 26
        Checkbox(p4, padX + colW + padX + 6, y2, "FastCar", "cb_fast_car", false); y2 = y2 + ROW_H
        Slider(p4, padX + colW + padX + 24, y2, colW - 60, "FastCarSpeed", "lbl_speed", 60, 6000, 60, true); y2 = y2 + 26
        Checkbox(p4, padX + colW + padX + 6, y2, "WeaponGlow", "cb_weapon_glow", false); y2 = y2 + ROW_H
        Slider(p4, padX + colW + padX + 24, y2, colW - 60, "WeaponGlowColor", "lbl_glow_color", 1, 5, 1, true); y2 = y2 + 26
        Slider(p4, padX + colW + padX + 24, y2, colW - 60, "WeaponGlowThickness", "lbl_glow_thick", 1, 15, 1, true)
    end

    -- PAGE 5: SKIN
    local p5 = makePanel(4); contentPanels[5] = p5
    if p5 and IsValid(p5) then
        Layer(p5, 0, 0, contentW, contentH, C.bg_content, 100)
        local padX = 8
        local colW = (contentW - 16 - padX * 3) / 2
        local innerH = contentH - 12
        Layer(p5, padX, 6, colW, innerH, C.bg_panel, 200)
        local y1 = 12
        for i, k in ipairs({{"ModSkin","cb_mod_skin"},{"ModEmote","cb_mod_emote"},{"SkinDeadBox","cb_deadbox"},{"SkinAttachment","cb_attachment"}}) do
            Checkbox(p5, padX + 6, y1, k[1], k[2], false); y1 = y1 + ROW_H
        end
        Layer(p5, padX + colW + padX, 6, colW, innerH, C.bg_panel, 200)
        local y2 = 12
        for i, k in ipairs({{"KillMessage","cb_kill_msg"},{"KillCountUI","cb_kill_ui"}}) do
            Checkbox(p5, padX + colW + padX + 6, y2, k[1], k[2], false); y2 = y2 + ROW_H
        end
    end

    -- PAGE 6: SETTINGS
    local p6 = makePanel(5); contentPanels[6] = p6
    if p6 and IsValid(p6) then
        Layer(p6, 0, 0, contentW, contentH, C.bg_content, 100)
        local padX = 8
        local colW = (contentW - 16 - padX * 3) / 2
        local innerH = contentH - 12
        Layer(p6, padX, 6, colW, innerH, C.bg_panel, 200)
        local y1 = 20
        Text(p6, "Language", padX + 12, 16, FS_MED, C.text_green, 300, 0, 0.5)
        FlatBtn(p6, padX + 12, y1, 70, 22, "lang_ar", Lang == "AR" and C.accent or C.bg_btn, function()
            Lang = "AR"; if _G.LavaMenuRebuild then _G.LavaMenuRebuild() end
        end); y1 = y1 + 26
        FlatBtn(p6, padX + 12, y1, 70, 22, "lang_en", Lang == "EN" and C.accent or C.bg_btn, function()
            Lang = "EN"; if _G.LavaMenuRebuild then _G.LavaMenuRebuild() end
        end); y1 = y1 + 32
        Text(p6, "Config", padX + 12, y1, FS_MED, C.text_green, 300, 0, 0.5); y1 = y1 + 14
        FlatBtn(p6, padX + 12, y1, colW - 24, 22, "btn_save", C.btn_save, function()
            pcall(function() if _G.SaveModSettings then _G.SaveModSettings() end end)
        end); y1 = y1 + 26
        FlatBtn(p6, padX + 12, y1, colW - 24, 22, "btn_load", C.btn_load, function()
            pcall(function() if _G.LoadModSettings then _G.LoadModSettings() end end)
        end); y1 = y1 + 26
        FlatBtn(p6, padX + 12, y1, colW - 24, 22, "btn_reset", C.btn_danger, function()
            for k, _ in pairs(_G.LexusConfig) do _G.LexusConfig[k] = false end
        end)
        Layer(p6, padX + colW + padX, 6, colW, innerH, C.bg_panel, 200)
        local y2 = 16
        Text(p6, "Opacity", padX + colW + padX + 12, y2, FS_MED, C.text_green, 300, 0, 0.5); y2 = y2 + 18
        Slider(p6, padX + colW + padX + 24, y2, colW - 60, "MenuOpacity", "lbl_opacity", 20, 100, 5, true)
    end

    if contentPanels[1] and IsValid(contentPanels[1]) then
        contentPanels[1]:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
    end
end

-- ==================== HIDE MENU ====================
local function HideMenu()
    if not bgPanel or not IsValid(bgPanel) then return end
    pcall(function()
        for _, w in ipairs(allWidgets) do
            if w and IsValid(w) then
                pcall(function() 
                    if w.SetIsEnabled then w:SetIsEnabled(false) end
                end)
            end
        end
        pcall(function() bgPanel:SetVisibility(UEnums.ESlateVisibility.HitTestInvisible) end)
        local slot = bgPanel.Slot
        if slot and IsValid(slot) then
            pcall(function() slot:SetSize(FVector2D(0, 0)) end)
            pcall(function() slot:SetPosition(FVector2D(-9999, -9999)) end)
        end
        bgPanel:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
    end)
end

-- ==================== SHOW MENU ====================
local function ShowMenu()
    if _G._LICENSE_OK ~= true then return end
    if not bgPanel or not IsValid(bgPanel) then return end
    pcall(function()
        local slot = bgPanel.Slot
        if slot and IsValid(slot) then
            local vw, vh = 1920, 1080
            pcall(function()
                local ui_util = require("client.common.ui_util")
                if ui_util and ui_util.GetViewportSize then
                    local vs = ui_util.GetViewportSize()
                    if vs and vs.X and vs.Y and vs.X > 200 and vs.Y > 200 then
                        vw, vh = vs.X, vs.Y
                    end
                end
            end)
            pcall(function() slot:SetAlignment(FVector2D(0.5, 0.5)) end)
            pcall(function() slot:SetSize(FVector2D(M_W, M_H)) end)
            pcall(function() slot:SetPosition(FVector2D(vw * 0.5, vh * 0.5)) end)
        end
        pcall(function() bgPanel:SetWidgetVisibility(UEnums.ESlateVisibility.Visible) end)
        for _, w in ipairs(allWidgets) do
            if w and IsValid(w) then
                pcall(function() 
                    if w.SetIsEnabled then w:SetIsEnabled(true) end
                end)
            end
        end
    end)
end

-- ==================== FLOAT BUTTON ====================
local function CreateFloat()
    if _G._LICENSE_OK ~= true then return end
    if floatBtn and floatBtn.btn and IsValid(floatBtn.btn) then
        pcall(function() floatBtn.btn:SetWidgetVisibility(UEnums.ESlateVisibility.Visible) end)
        return
    end
    
    for _, w in ipairs(floatItems) do
        if w and IsValid(w) then
            pcall(function() w:RemoveFromParent() end)
            pcall(function() w:ConditionalBeginDestroy() end)
        end
    end
    floatItems = {}
    floatBtn = nil
    
    local canvas = GetCanvas()
    if not canvas then return end
    
    floatBtn = {}
    local fX, fY, fW, fH = 15, 150, 70, 32
    
    floatBtn.border1 = RawLayer(canvas, fX - 1, fY - 1, fW + 2, fH + 2, C.accent, 9498)
    floatBtn.bg = RawLayer(canvas, fX, fY, fW, fH, C.black, 9500)
    RawLayer(canvas, fX, fY, fW, 2, C.accent, 9501)
    RawLayer(canvas, fX, fY + fH - 2, fW, 2, C.accent_cyan, 9501)
    
    floatBtn.txt1 = RawText(canvas, "XTHRLEN", fX + fW * 0.5, fY + fH * 0.32, FS_MED, C.text_white, 9502, 0.5, 0.5)
    local initialText = isMenuOpen and T("close_menu") or T("open_menu")
    floatBtn.txt2 = RawText(canvas, initialText, fX + fW * 0.5, fY + fH * 0.72, FS_TINY, C.accent, 9502, 0.5, 0.5)
    
    floatBtn.btn = RawBtn(canvas, fX, fY, fW, fH, 9510, function()
        pcall(function()
            if isMenuOpen then
                isMenuOpen = false
                HideMenu()
                if floatBtn and floatBtn.txt2 and IsValid(floatBtn.txt2) then
                    floatBtn.txt2:SetText(T("open_menu"))
                end
            else
                if menuBuilt and bgPanel and IsValid(bgPanel) then
                    isMenuOpen = true
                    ShowMenu()
                    if floatBtn and floatBtn.txt2 and IsValid(floatBtn.txt2) then
                        floatBtn.txt2:SetText(T("close_menu"))
                    end
                else
                    if _G.BuildLavaMenu then _G.BuildLavaMenu() end
                end
            end
        end)
    end)
end

_G.CreateFloat = CreateFloat

-- ==================== BUILD MENU ====================
local function BuildMenu()
    if _G._LICENSE_OK ~= true then return end
    if menuBuilt and bgPanel and IsValid(bgPanel) then
        isMenuOpen = true
        ShowMenu()
        if floatBtn and floatBtn.txt2 and IsValid(floatBtn.txt2) then
            floatBtn.txt2:SetText(T("close_menu"))
        end
        return
    end
    local canvas = GetCanvas()
    if not canvas then return end

    local savedFloatBtn = floatBtn
    local savedFloatItems = floatItems

    ClearAll()
    
    floatBtn = savedFloatBtn
    floatItems = savedFloatItems
    
    topTabs = {}
    subTabs = {}
    contentPanels = {}
    bgPanel = nil
    currentTopTab = 1

    pcall(function()
        bgPanel = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", canvas)
        if bgPanel and slua.isValid(bgPanel) then
            local s = canvas:AddChildToCanvas(bgPanel)
            if s then
                local vw, vh = 1920, 1080
                pcall(function()
                    local ui_util = require("client.common.ui_util")
                    if ui_util and ui_util.GetViewportSize then
                        local vs = ui_util.GetViewportSize()
                        if vs and vs.X and vs.Y and vs.X > 200 and vs.Y > 200 then
                            vw, vh = vs.X, vs.Y
                        end
                    end
                end)
                s:SetAutoSize(false)
                s:SetZOrder(10000)
                s:SetAlignment(FVector2D(0.5, 0.5))
                s:SetPosition(FVector2D(vw * 0.5, vh * 0.5))
                s:SetSize(FVector2D(M_W, M_H))
            end
        end
    end)
    if not bgPanel or not slua.isValid(bgPanel) then return end

    Layer(bgPanel, -1, -1, M_W + 2, M_H + 2, C.accent, -1)
    Layer(bgPanel, 0, 0, M_W, M_H, C.bg_window, 1)
    Layer(bgPanel, 0, 0, M_W, HEADER_H, C.bg_header, 3)
    Layer(bgPanel, 0, HEADER_H - 1, M_W, 1, C.divider, 4)
    Text(bgPanel, T("brand"), 8, HEADER_H * 0.5, FS_MED, C.text_white, 400, 0, 0.5)
    Text(bgPanel, T("sub_brand"), M_W * 0.5, HEADER_H * 0.5, FS_SMALL, C.text_dim, 400, 0.5, 0.5)

    local closeSize = 18
    local closeX = M_W - closeSize - 6
    local closeY = (HEADER_H - closeSize) * 0.5
    
    Layer(bgPanel, closeX, closeY, closeSize, closeSize, C.btn_danger, 100)
    Text(bgPanel, "X", closeX + closeSize * 0.5, closeY + closeSize * 0.5 + 1, FS_MED, C.text_white, 400, 0.5, 0.5)
    
    Btn(bgPanel, closeX, closeY, closeSize, closeSize, 99999, function()
        pcall(function()
            isMenuOpen = false
            HideMenu()
            if floatBtn and floatBtn.txt2 and IsValid(floatBtn.txt2) then
                floatBtn.txt2:SetText(T("open_menu"))
            end
            if floatBtn and floatBtn.btn and IsValid(floatBtn.btn) then
                floatBtn.btn:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
            end
        end)
    end)

    Layer(bgPanel, 0, HEADER_H, M_W, TABBAR_H, C.bg_tabbar, 10)
    Layer(bgPanel, 0, HEADER_H + TABBAR_H - 1, M_W, 1, C.divider, 11)

    local tabsList = {"tab_esp", "tab_esp_v2", "tab_aim", "tab_combat", "tab_skin", "tab_settings"}
    local tabW = (M_W - 12) / #tabsList
    local tabX = 6
    for i, key in ipairs(tabsList) do
        TopTab(bgPanel, key, tabX, HEADER_H, tabW - 2, TABBAR_H, i)
        tabX = tabX + tabW
    end

    Text(bgPanel, T("footer"), M_W * 0.5, M_H - 7, FS_TINY, C.text_dim, 300, 0.5, 0.5)

    BuildTopPages()

    menuBuilt = true
    isMenuOpen = true
    ShowMenu()
    if floatBtn and floatBtn.txt2 and IsValid(floatBtn.txt2) then
        floatBtn.txt2:SetText(T("close_menu"))
    end
end

_G.LavaMenuRebuild = function()
    if _G._LICENSE_OK ~= true then return end
    local savedFloatBtn = floatBtn
    local savedFloatItems = floatItems
    
    for _, w in ipairs(allWidgets) do
        if w and IsValid(w) then
            pcall(function() w:RemoveFromParent() end)
            pcall(function() w:ConditionalBeginDestroy() end)
        end
    end
    allWidgets = {}
    topTabs = {}
    subTabs = {}
    contentPanels = {}
    menuBuilt = false
    bgPanel = nil
    
    floatBtn = savedFloatBtn
    floatItems = savedFloatItems
    
    BuildMenu()
end

-- ==================== TIMER + WATCHER (Multi-Game Support) ====================
pcall(function()
    local lastMapId = nil
    local lastPlayerId = nil
    local lastPcId = nil
    
    local function LavaWatcher()
        if _G._LICENSE_OK ~= true then return end
        pcall(function()
            -- 1. جلب PC الحالي
            local pc = nil
            pcall(function()
                if slua_GameFrontendHUD then
                    pc = slua_GameFrontendHUD:GetPlayerController()
                end
            end)
            
            if not pc or not slua.isValid(pc) then return end
            
            -- 2. جلب اللاعب الحالي
            local player = nil
            pcall(function() player = pc:GetPlayerCharacterSafety() end)
            if not player or not slua.isValid(player) then return end
            
            -- 3. جلب هوية الخريطة واللاعب
            local currentMapId = nil
            pcall(function()
                local world = slua_GameFrontendHUD:GetWorld()
                if world and slua.isValid(world) then
                    currentMapId = tostring(world)
                end
            end)
            
            local currentPlayerId = tostring(player)
            local currentPcId = tostring(pc)
            
            -- 4. لو اللعبة اتغيرت → نضف
            local needCleanup = false
            
            if lastMapId ~= nil and lastMapId ~= currentMapId then
                needCleanup = true
                print("[LAVA] 🔄 الخريطة اتغيرت")
            end
            
            if lastPcId ~= nil and lastPcId ~= currentPcId then
                needCleanup = true
                print("[LAVA] 🔄 الـ PlayerController اتغير")
            end
            
            if lastPlayerId ~= nil and lastPlayerId ~= currentPlayerId then
                needCleanup = true
                print("[LAVA] 🔄 اللاعب اتغير")
            end
            
            if needCleanup then
                cachedPC = nil
                parentCanvas = nil
                
                if floatBtn then
                    pcall(function()
                        if floatBtn.btn and IsValid(floatBtn.btn) then floatBtn.btn:RemoveFromParent() end
                        if floatBtn.bg and IsValid(floatBtn.bg) then floatBtn.bg:RemoveFromParent() end
                        if floatBtn.txt1 and IsValid(floatBtn.txt1) then floatBtn.txt1:RemoveFromParent() end
                        if floatBtn.txt2 and IsValid(floatBtn.txt2) then floatBtn.txt2:RemoveFromParent() end
                    end)
                    floatBtn = nil
                end
                
                for _, w in ipairs(floatItems) do
                    if w and IsValid(w) then
                        pcall(function() w:RemoveFromParent() end)
                        pcall(function() w:ConditionalBeginDestroy() end)
                    end
                end
                floatItems = {}
                
                if bgPanel and IsValid(bgPanel) then
                    pcall(function() bgPanel:RemoveFromParent() end)
                    pcall(function() bgPanel:ConditionalBeginDestroy() end)
                end
                bgPanel = nil
                menuBuilt = false
                isMenuOpen = false
                allWidgets = {}
                topTabs = {}
                subTabs = {}
                contentPanels = {}
                
                print("[LAVA] ✅ تم التنظيف")
            end
            
            lastMapId = currentMapId
            lastPlayerId = currentPlayerId
            lastPcId = currentPcId
            
            -- 5. فحص الزر العائم
            local floatOk = false
            pcall(function()
                if floatBtn and floatBtn.btn and IsValid(floatBtn.btn) then
                    floatOk = true
                end
            end)
            
            if not floatOk then
                floatBtn = nil
                parentCanvas = nil
                CreateFloat()
                print("[LAVA] 🎈 الزر العائم اتعمله من جديد")
            else
                pcall(function() floatBtn.btn:SetWidgetVisibility(UEnums.ESlateVisibility.Visible) end)
                if floatBtn.bg and IsValid(floatBtn.bg) then
                    pcall(function() floatBtn.bg:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
                end
                if floatBtn.txt1 and IsValid(floatBtn.txt1) then
                    pcall(function() floatBtn.txt1:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
                end
                if floatBtn.txt2 and IsValid(floatBtn.txt2) then
                    pcall(function() floatBtn.txt2:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
                end
            end
            
            -- 6. فحص المنيو
            if menuBuilt and bgPanel then
                if not IsValid(bgPanel) then
                    menuBuilt = false
                    bgPanel = nil
                    isMenuOpen = false
                    print("[LAVA] 📋 المنيو اختفت")
                end
            end
            
            -- 7. فحص الـ Canvas
            if parentCanvas and not Game:IsValid(parentCanvas) then
                parentCanvas = nil
                print("[LAVA] 🎨 الـ Canvas اتغير")
                if isMenuOpen then
                    menuBuilt = false
                    bgPanel = nil
                    BuildMenu()
                end
            end
        end)
    end
    
    -- تشغيل Watcher مستقل
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerLoop then
        ticker.AddTimerLoop(1.5, LavaWatcher, -1, 1.5)
        print("[LAVA] ✅ Watcher اشتغل")
    end
    
    -- التشغيل الأولي
    local function TryInit()
        if _G._LICENSE_OK ~= true then return false end
        local pc = GetPC()
        if IsValid(pc) then
            CreateFloat()
            return true
        end
        return false
    end
    
    if not TryInit() then
        local ticker2 = require("common.time_ticker")
        if ticker2 and ticker2.AddTimerOnce then
            local function RetryInit()
                if not TryInit() then
                    ticker2.AddTimerOnce(1.0, RetryInit)
                end
            end
            ticker2.AddTimerOnce(1.0, RetryInit)
        end
    end
end)

_G.BuildLavaMenu = BuildMenu

print("[VP JD VIP] ✅ تم التحميل - Multi-Game Support")

end)
-- ==============================================================================
-- END XTHRLEN VIP v12.1 | COMPACT EDITION
-- ==============================================================================
-- ==============================================================================
-- END XTHRLEN VIP v11.0 | IMGUI-STYLE RED/BLACK EDITION
-- ==============================================================================*




-- ==============================================================================
-- 🚀 تشغيل كل الكود بشكل محمي (لو فشل، يعيد المحاولة)
-- ==============================================================================
SafeLoad(function()
    -- ==========================================
    -- الكود كله هنا (المكان اللي عايز تحميه)
    -- ==========================================
    
    -- 1. تحقق من جاهزية اللاعب
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if not pc or not slua.isValid(pc) then
        error("PlayerController لسه مش جاهز")
    end
    
    local player = pc:GetPlayerCharacterSafety()
    if not player or not slua.isValid(player) then
        error("PlayerCharacter لسه مش جاهز")
    end
    
    -- 2. تحقق من الـ Canvas
    local canvas = nil
    pcall(function()
        local IGT = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools")
        local MainUI = IGT.GetMainControlBaseUI()
        if slua.isValid(MainUI) then
            canvas = MainUI.CanvasPanel_0 or MainUI.CanvasPanel_42
        end
    end)
    if not canvas or not slua.isValid(canvas) then
        error("Canvas لسه مش جاهز")
    end
    
    if _G._LICENSE_OK ~= true then return end
    -- 3. شغل المنيو (لو الكود بتاعك هنا)
    pcall(function()
        if _G.BuildLavaMenu then _G.BuildLavaMenu() end
        if _G.CreateFloat then _G.CreateFloat() end
    end)
    
    -- 4. شغل LAVA ESP بعد نجاح اللوجن
    pcall(function()
        if _G._LICENSE_OK == true and _G.BoxESP then
            _G.BoxESP.Start()
        end
    end)
    
    -- ✅ كل حاجة جاهزة
    print("[SAFE] ✅ كل الأنظمة اشتغلت بنجاح!")
    return true
end, 2.0, 999999)

-- ==============================================================================
-- 🔄 LOOP الإسكنات الشامل - حطه في آخر الملف
-- ==============================================================================
-- ==============================================================================
-- 🔄 SKIN LOOP - بدون local (لتفادي حد 200)
-- ==============================================================================
function StartSkinLoop()
    if _G._LICENSE_OK ~= true then return end
    if _G._StartXTHRLENSkinEngine then
        pcall(_G._StartXTHRLENSkinEngine)
    end
end

function StopSkinLoop()
    if _G._SKIN_ENGINE_ENABLED ~= nil then
        _G._SKIN_ENGINE_ENABLED = false
    end
end

-- ==============================================================================
-- 🔄 FLOAT BUTTON LOOP + POSITION FIX
-- ==============================================================================
function StartFloatLoop()
    if _G._LICENSE_OK ~= true then return end
    local ticker = require("common.time_ticker")
    if not ticker or not ticker.AddTimerLoop then return end
    
    local loopCount = 0
    local lastRebuild = 0
    
    ticker.AddTimerLoop(1.5, function()
        if _G._LICENSE_OK ~= true then return end
        pcall(function()
            if _G._LICENSE_OK ~= true then return end
            loopCount = loopCount + 1
            local now = os.clock()
            
            -- 1. فحص الزر
            local floatExists = false
            pcall(function()
                if _G.floatBtn and _G.floatBtn.btn and slua.isValid(_G.floatBtn.btn) then
                    floatExists = true
                end
            end)
            
            -- 2. لو اختفى، جدده
            if not floatExists and (now - lastRebuild) > 2.0 then
                lastRebuild = now
                pcall(function()
                    if _G.CreateFloat then _G.CreateFloat() end
                end)
            end
            
            -- 3. لو موجود، تأكد إنه في المكان الصح
            if floatExists then
                pcall(function()
                    -- تأكد من الظهور
                    _G.floatBtn.btn:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
                    
                    -- تأكد من الموقع
                    local FVector2D = import("Vector2D")
                    local slot = _G.floatBtn.btn.Slot
                    if slot and slua.isValid(slot) then
                        slot:SetPosition(FVector2D(15, 150))
                        slot:SetSize(FVector2D(70, 32))
                    end
                    
                    -- تأكد من باقي العناصر
                    if _G.floatBtn.bg and slua.isValid(_G.floatBtn.bg) then
                        _G.floatBtn.bg:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                    end
                    if _G.floatBtn.txt1 and slua.isValid(_G.floatBtn.txt1) then
                        _G.floatBtn.txt1:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                    end
                    if _G.floatBtn.txt2 and slua.isValid(_G.floatBtn.txt2) then
                        _G.floatBtn.txt2:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                    end
                end)
            end
            
            -- 4. طباعة
            if loopCount % 20 == 0 then
                print("[FLOAT LOOP] شغال | الزر: " .. tostring(floatExists))
            end
        end)
    end, -1, 1.5)
end

-- StartFloatLoop is started only after successful license verification.

-- ============================================================================
-- LAVA ESP SOURCE (installed as the only player ESP)
-- ============================================================================
-- ============================================================================
-- LAVA ESP SOURCE (original Lava look + native loops)
-- ============================================================================
_G.InstallLavaESP = function()
local SlateBlueprintLibrary = nil
local WidgetLayoutLibrary = nil
local FVector2D = nil
local FVector = nil
local FLinearColor = nil
local FSlateColor = nil

pcall(function()
    SlateBlueprintLibrary = import("SlateBlueprintLibrary") or import("/Script/UMG.SlateBlueprintLibrary")
    WidgetLayoutLibrary = import("WidgetLayoutLibrary") or import("/Script/UMG.WidgetLayoutLibrary")
    FVector2D = import("Vector2D")
    FVector = import("Vector")
    FLinearColor = import("LinearColor")
    FSlateColor = import("SlateColor") or import("/Script/SlateCore.SlateColor")
end)

local function IsValid(obj)
    if not obj then return false end
    if slua and slua.isValid then
        return slua.isValid(obj)
    end
    return true
end

local TempProjVec2D = FVector2D and FVector2D(0, 0) or nil
local ColorWhite = FLinearColor and FLinearColor(1.0, 1.0, 1.0, 1.0) or nil
local ColorRed = FLinearColor and FLinearColor(1.0, 0.15, 0.15, 1.0) or nil
local ColorGreen = FLinearColor and FLinearColor(0.0, 1.0, 0.05, 1.0) or nil
local ColorYellow = FLinearColor and FLinearColor(1.0, 0.95, 0.0, 1.0) or nil
local ColorBlue = FLinearColor and FLinearColor(0.18, 0.62, 1.0, 1.0) or nil

local SlateColorRed = (FSlateColor and ColorRed) and FSlateColor(ColorRed) or ColorRed
local SlateColorGreen = (FSlateColor and ColorGreen) and FSlateColor(ColorGreen) or ColorGreen

-- ========== Enemy Counter Image Loader ==========
local ENEMY_COUNTER_PLAYER_URLS = {
}
local ENEMY_COUNTER_BOT_URLS = {
}
local EnemyCounterTextureCache = {}
local BADGE_WIDTH = 48
local BADGE_HEIGHT = 22

local function FileExists(path)
    if not path or path == "" then return false end
    local f = io.open(path, "r")
    if f then f:close() return true end
    return false
end

local function GetPossibleLocalPaths(filename)
    return {
        "/storage/emulated/0/Android/data/com.tencent.ig/files/" .. filename,
        "/storage/emulated/0/Android/data/com.pubg.krmobile/files/" .. filename,
        "/storage/emulated/0/Android/data/com.vng.pubgmobile/files/" .. filename,
        "/storage/emulated/0/Android/data/com.rekoo.pubgm/files/" .. filename,
        "/storage/emulated/0/Android/data/com.tencent.tmgp.pubgmhd/files/" .. filename,
        filename
    }
end

local function LoadBadgeTexture(imgWidget, urls, filename, typeKey, counterData)
    if not imgWidget or not IsValid(imgWidget) then return end

    if EnemyCounterTextureCache[typeKey] and IsValid(EnemyCounterTextureCache[typeKey]) then
        pcall(function()
            imgWidget:SetBrushFromTexture(EnemyCounterTextureCache[typeKey], false)
            imgWidget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end)
        if counterData then
            if typeKey == "Player" then counterData.PlayerLoaded = true end
            if typeKey == "Bot" then counterData.BotLoaded = true end
        end
        return
    end

    local function applyTex(tex)
        if tex and IsValid(tex) and IsValid(imgWidget) then
            EnemyCounterTextureCache[typeKey] = tex
            if counterData then
                if typeKey == "Player" then counterData.PlayerLoaded = true end
                if typeKey == "Bot" then counterData.BotLoaded = true end
            end
            pcall(function()
                imgWidget:SetBrushFromTexture(tex, false)
                imgWidget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            end)
            return true
        end
        return false
    end

    local localPaths = GetPossibleLocalPaths(filename)
    for _, localPath in ipairs(localPaths) do
        if FileExists(localPath) then
            local tex = nil
            pcall(function()
                local asset_util = package.loaded["common.asset_util"] or require("common.asset_util")
                if asset_util and asset_util.GetAssetSync then tex = asset_util.GetAssetSync(localPath) end
            end)
            if not tex then
                pcall(function() if CGame and CGame.LoadObject then tex = CGame:LoadObject(localPath) end end)
            end
            if tex and applyTex(tex) then return end
        end
    end

    local function tryDownloadUrl(urlIndex)
        if urlIndex > #urls then return end
        local url = urls[urlIndex]
        local bDownloaded = false

        pcall(function()
            local AsyncTaskDownloadImage = import("AsyncTaskDownloadImage") or import("/Script/UMG.AsyncTaskDownloadImage")
            if AsyncTaskDownloadImage and AsyncTaskDownloadImage.DownloadImage then
                local task = AsyncTaskDownloadImage.DownloadImage(url)
                if task and task.OnSuccess then
                    task.OnSuccess:Add(function(tex)
                        if not bDownloaded and tex then
                            bDownloaded = true
                            applyTex(tex)
                        end
                    end)
                    if task.OnFail then
                        task.OnFail:Add(function()
                            if not bDownloaded then tryDownloadUrl(urlIndex + 1) end
                        end)
                    end
                end
            end
        end)

        if not bDownloaded then
            pcall(function()
                local mm = _G.ModuleManager or package.loaded["GameLua.GameCore.Module.ModuleManager"]
                if not mm then pcall(function() mm = require("GameLua.GameCore.Module.ModuleManager") end) end
                local imgMgr = nil
                if mm and mm.GetModule and mm.CommonModuleConfig then
                    imgMgr = mm.GetModule(mm.CommonModuleConfig.image_download_mgr)
                end
                if not imgMgr then pcall(function() imgMgr = require("client.slua.logic.image_download.image_download_mgr") end) end
                if imgMgr and imgMgr.DownloadImageByHttpWrapper then
                    imgMgr:DownloadImageByHttpWrapper(url, function(tex)
                        if not bDownloaded and tex then bDownloaded = true; applyTex(tex) end
                    end, function()
                        if not bDownloaded then tryDownloadUrl(urlIndex + 1) end
                    end)
                end
            end)
        end

        if not bDownloaded then
            pcall(function()
                local util = package.loaded["client.slua_ui_framework.util"]
                if not util then pcall(function() util = require("client.slua_ui_framework.util") end) end
                if util and util.SetTexture then
                    util.SetTexture(imgWidget, url, {
                        sync = false,
                        onDownloadSuccess = function(tex)
                            if not bDownloaded and tex then bDownloaded = true; applyTex(tex) end
                        end
                    })
                end
            end)
        end
    end

    tryDownloadUrl(1)
end

-- ========== BoxESP Master Table ==========
local BoxESP = {
    bActive = false,
    bShowLines = true,
    bShowCounter = true,
    ESPCanvas = nil,
    BoxWidgets = {},
    LineWidgets = {},

    CounterData = {
        ImgPlayer = nil,
        SlotPlayer = nil,
        ImgBot = nil,
        SlotBot = nil,
        TxtPlayer = nil,
        SlotTxtPlayer = nil,
        TxtBot = nil,
        SlotTxtBot = nil,
        LastPlayerCount = -1,
        LastBotCount = -1,
        PlayerLoaded = false,
        BotLoaded = false,
        LastDownloadRetry = 0,
        bCreated = false
    },

    HealthColor = { R = 0.0, G = 1.0, B = 0.0, A = 1.0 },
    HealthBgColor = { R = 0.0, G = 0.0, B = 0.0, A = 0.85 },
    HealthBarWidth = 2.0,
    CornerColor = { R = 1.0, G = 1.0, B = 1.0, A = 1.0 },
    CornerThickness = 1.0,
    CornerLengthRatio = 0.28,
    SnapLineThickness = 1.0,
    SnapLineOriginY = 72,

    _CanvasScaleX = 1.0,
    _CanvasScaleY = 1.0,
    _CanvasOffsetX = 0.0,
    _CanvasOffsetY = 0.0,
    _LastCanvas = nil,
    _LastTransformTime = 0,
    _LastHeavyUpdateTime = 0,
    _LastVisCheckTime = 0,
    _VisCheckCache = {}
}

function BoxESP.GetMainCanvas()
    -- NEVER trust the cached canvas first. UE creates/replaces the main UI
    -- between matches while the old UObject can still report IsValid().
    -- Always resolve the current MainUI/canvas, then replace our widget cache
    -- when that canvas changes.
    local InGameUITools = package.loaded["GameLua.Mod.BaseMod.Common.UI.InGameUITools"]
    if not InGameUITools then
        pcall(function() InGameUITools = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools") end)
    end
    if not InGameUITools then return nil end

    local MainUI = nil
    if InGameUITools.GetMainControlBaseUI then
        MainUI = InGameUITools.GetMainControlBaseUI()
    end
    if not IsValid(MainUI) then
        -- During the short lobby/loading gap there may be no MainUI yet.
        -- Keep the old canvas only as a temporary fallback; the next tick
        -- resolves MainUI again and can detect the new canvas.
        if BoxESP.ESPCanvas and IsValid(BoxESP.ESPCanvas) then
            return BoxESP.ESPCanvas
        end
        return nil
    end

    local ParentCanvas = nil
    if MainUI.CanvasPanel_0 and IsValid(MainUI.CanvasPanel_0) then
        ParentCanvas = MainUI.CanvasPanel_0
    elseif MainUI.CanvasPanel_42 and IsValid(MainUI.CanvasPanel_42) then
        ParentCanvas = MainUI.CanvasPanel_42
    end

    if ParentCanvas then
        -- A new match/lobby creates a NEW Canvas. The old widgets belong to the
        -- previous Canvas and must never be reused in the next match.
        if BoxESP.ESPCanvas ~= ParentCanvas then
            BoxESP.ESPCanvas = ParentCanvas
            BoxESP._LastCanvas = ParentCanvas
            BoxESP.BoxWidgets = {}
            BoxESP.LineWidgets = {}
            BoxESP._VisCheckCache = {}
            BoxESP.CounterData = {
                ImgPlayer = nil, SlotPlayer = nil, ImgBot = nil, SlotBot = nil,
                TxtPlayer = nil, SlotTxtPlayer = nil, TxtBot = nil, SlotTxtBot = nil,
                LastPlayerCount = -1, LastBotCount = -1,
                PlayerLoaded = false, BotLoaded = false,
                LastDownloadRetry = 0, bCreated = false
            }
            BoxESP._LastTransformTime = 0
            BoxESP._LastHeavyUpdateTime = 0
            BoxESP._LastVisCheckTime = 0
        end
    end
    return ParentCanvas
end

function BoxESP.CreateESPWidget(ParentCanvas)
    if not FLinearColor or not FVector2D then return nil end

    local CornerContainer = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", ParentCanvas)
    if not IsValid(CornerContainer) then return nil end

    local CornerMainSlot = ParentCanvas:AddChildToCanvas(CornerContainer)
    if not CornerMainSlot then return nil end

    CornerMainSlot:SetAutoSize(false)
    CornerMainSlot:SetZOrder(995)
    CornerMainSlot:SetAlignment(FVector2D(0.5, 0.5))

    local whiteColor = FLinearColor(
        BoxESP.CornerColor.R,
        BoxESP.CornerColor.G,
        BoxESP.CornerColor.B,
        BoxESP.CornerColor.A
    )

    local function CreateBorderLine()
        local border = CGame:NewObjectFromPath("/Script/UMG.Border", CornerContainer)
        if border and IsValid(border) then
            border:SetBrushColor(whiteColor)
            border:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            local slot = CornerContainer:AddChildToCanvas(border)
            if slot then slot:SetAutoSize(false) end
            return { widget = border, slot = slot }
        end
        return nil
    end

    local CornerLines = {
        TopLeft_H = CreateBorderLine(),
        TopLeft_V = CreateBorderLine(),
        TopRight_H = CreateBorderLine(),
        TopRight_V = CreateBorderLine(),
        BottomLeft_H = CreateBorderLine(),
        BottomLeft_V = CreateBorderLine(),
        BottomRight_H = CreateBorderLine(),
        BottomRight_V = CreateBorderLine()
    }

    local BgImage = CGame:NewObjectFromPath("/Script/UMG.Image", ParentCanvas)
    if not IsValid(BgImage) then return nil end
    BgImage:SetColorAndOpacity(FLinearColor(BoxESP.HealthBgColor.R, BoxESP.HealthBgColor.G, BoxESP.HealthBgColor.B, BoxESP.HealthBgColor.A))
    BgImage:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)

    local BgSlot = ParentCanvas:AddChildToCanvas(BgImage)
    if not BgSlot then return nil end
    BgSlot:SetAutoSize(false)
    BgSlot:SetZOrder(998)
    BgSlot:SetAlignment(FVector2D(0.5, 1.0))

    local HealthImage = CGame:NewObjectFromPath("/Script/UMG.Image", ParentCanvas)
    if not IsValid(HealthImage) then return nil end
    HealthImage:SetColorAndOpacity(FLinearColor(BoxESP.HealthColor.R, BoxESP.HealthColor.G, BoxESP.HealthColor.B, BoxESP.HealthColor.A))
    HealthImage:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)

    local HealthSlot = ParentCanvas:AddChildToCanvas(HealthImage)
    if not HealthSlot then return nil end
    HealthSlot:SetAutoSize(false)
    HealthSlot:SetZOrder(999)
    HealthSlot:SetAlignment(FVector2D(0.5, 1.0))

    local function CreateStyledTextBlock(defaultColor, fontSize, alignment)
        local txt = CGame:NewObjectFromPath("/Script/UMG.TextBlock", ParentCanvas)
        local slot = nil
        if txt and IsValid(txt) then
            txt:SetText("")
            local intSize = math.floor(fontSize or 10)
            if txt.Font then
                local newFont = txt.Font
                newFont.Size = intSize
                if newFont.OutlineSettings then
                    newFont.OutlineSettings.OutlineSize = 1
                    newFont.OutlineSettings.OutlineColor = FLinearColor(0.0, 0.0, 0.0, 1.0)
                end
                if txt.SetFont then txt:SetFont(newFont) else txt.Font = newFont end
            end

            if txt.SetFontSize then txt:SetFontSize(intSize) end
            txt:SetJustification(1)
            if txt.SetHorizontalAlignment then txt:SetHorizontalAlignment(1) end
            if txt.SetVerticalAlignment then txt:SetVerticalAlignment(1) end
            if txt.SetAutoWrapText then txt:SetAutoWrapText(false) end

            if FSlateColor then
                txt:SetColorAndOpacity(FSlateColor(defaultColor))
            else
                txt:SetColorAndOpacity(defaultColor)
            end

            if txt.SetShadowOffset then txt:SetShadowOffset(FVector2D(0.0, 0.0)) end
            if txt.SetShadowColorAndOpacity then txt:SetShadowColorAndOpacity(FLinearColor(0.0, 0.0, 0.0, 0.0)) end
            txt:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)

            slot = ParentCanvas:AddChildToCanvas(txt)
            if slot then
                slot:SetAutoSize(true)
                slot:SetZOrder(1000)
                slot:SetAlignment(alignment or FVector2D(0.5, 0.0))
            end
        end
        return txt, slot
    end

    local WeaponWidget, WeaponSlot = CreateStyledTextBlock(ColorYellow, 10, FVector2D(0.5, 1.0))
    local NameWidget, NameSlot = CreateStyledTextBlock(ColorBlue, 10, FVector2D(0.5, 0.0))
    local DistWidget, DistSlot = CreateStyledTextBlock(ColorWhite, 10, FVector2D(0.5, 0.0))
    local StateWidget, StateSlot = CreateStyledTextBlock(ColorGreen, 10, FVector2D(0.5, 0.0))

    local FlagImage = CGame:NewObjectFromPath("/Script/UMG.Image", ParentCanvas)
    local FlagSlot = nil
    if FlagImage and IsValid(FlagImage) then
        FlagImage:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        FlagSlot = ParentCanvas:AddChildToCanvas(FlagImage)
        if FlagSlot then
            FlagSlot:SetAutoSize(false)
            FlagSlot:SetSize(FVector2D(14, 16))
            FlagSlot:SetZOrder(1000)
            FlagSlot:SetAlignment(FVector2D(0.5, 1.0))
        end
    end

    return {
        CornerContainer = CornerContainer,
        CornerSlot = CornerMainSlot,
        Corners = CornerLines,
        BgWidget = BgImage,
        BgSlot = BgSlot,
        HealthWidget = HealthImage,
        HealthSlot = HealthSlot,
        WeaponWidget = WeaponWidget,
        WeaponSlot = WeaponSlot,
        FlagWidget = FlagImage,
        FlagSlot = FlagSlot,
        NameWidget = NameWidget,
        NameSlot = NameSlot,
        DistWidget = DistWidget,
        DistSlot = DistSlot,
        StateWidget = StateWidget,
        StateSlot = StateSlot,
        _cachedWeapon = "",
        _cachedNation = nil,
        _cachedName = "",
        _cachedDist = "",
        _cachedState = "",
        _cachedIsCover = false,
        _cachedIsKnocked = false,
        _lastScanTime = 0,
        lastW = 0,
        lastH = 0,
        bVisible = true
    }
end

function BoxESP.UpdateCornerDimensions(boxData, width, height)
    if boxData.lastW and boxData.lastH then
        if math.abs(width - boxData.lastW) < 1.5 and math.abs(height - boxData.lastH) < 1.5 then
            return
        end
    end
    boxData.lastW = width
    boxData.lastH = height

    local t = BoxESP.CornerThickness
    local cLen = math.max(7, math.min(width, height) * BoxESP.CornerLengthRatio)
    local C = boxData.Corners

    boxData.CornerSlot:SetSize(FVector2D(width, height))

    if C.TopLeft_H and C.TopLeft_H.slot then
        C.TopLeft_H.slot:SetPosition(FVector2D(0, 0))
        C.TopLeft_H.slot:SetSize(FVector2D(cLen, t))
    end
    if C.TopLeft_V and C.TopLeft_V.slot then
        C.TopLeft_V.slot:SetPosition(FVector2D(0, 0))
        C.TopLeft_V.slot:SetSize(FVector2D(t, cLen))
    end

    if C.TopRight_H and C.TopRight_H.slot then
        C.TopRight_H.slot:SetPosition(FVector2D(width - cLen, 0))
        C.TopRight_H.slot:SetSize(FVector2D(cLen, t))
    end
    if C.TopRight_V and C.TopRight_V.slot then
        C.TopRight_V.slot:SetPosition(FVector2D(width - t, 0))
        C.TopRight_V.slot:SetSize(FVector2D(t, cLen))
    end

    if C.BottomLeft_H and C.BottomLeft_H.slot then
        C.BottomLeft_H.slot:SetPosition(FVector2D(0, height - t))
        C.BottomLeft_H.slot:SetSize(FVector2D(cLen, t))
    end
    if C.BottomLeft_V and C.BottomLeft_V.slot then
        C.BottomLeft_V.slot:SetPosition(FVector2D(0, height - cLen))
        C.BottomLeft_V.slot:SetSize(FVector2D(t, cLen))
    end

    if C.BottomRight_H and C.BottomRight_H.slot then
        C.BottomRight_H.slot:SetPosition(FVector2D(width - cLen, height - t))
        C.BottomRight_H.slot:SetSize(FVector2D(cLen, t))
    end
    if C.BottomRight_V and C.BottomRight_V.slot then
        C.BottomRight_V.slot:SetPosition(FVector2D(width - t, height - cLen))
        C.BottomRight_V.slot:SetSize(FVector2D(t, cLen))
    end
end

function BoxESP.UpdateCanvasTransform(PC)
    if not BoxESP.ESPCanvas or not IsValid(BoxESP.ESPCanvas) then return end

    local success = false
    if SlateBlueprintLibrary and SlateBlueprintLibrary.AbsoluteToLocal then
        local cg = BoxESP.ESPCanvas:GetCachedGeometry()
        if cg then
            local pt0 = SlateBlueprintLibrary.AbsoluteToLocal(cg, FVector2D(0, 0))
            local pt1 = SlateBlueprintLibrary.AbsoluteToLocal(cg, FVector2D(100, 100))
            if pt0 and pt1 then
                BoxESP._CanvasScaleX = (pt1.X - pt0.X) / 100
                BoxESP._CanvasScaleY = (pt1.Y - pt0.Y) / 100
                BoxESP._CanvasOffsetX = pt0.X
                BoxESP._CanvasOffsetY = pt0.Y
                success = true
            end
        end
    end

    if not success and WidgetLayoutLibrary and WidgetLayoutLibrary.GetViewportScale then
        local scale = WidgetLayoutLibrary.GetViewportScale(PC) or 1.0
        BoxESP._CanvasScaleX = 1.0 / scale
        BoxESP._CanvasScaleY = 1.0 / scale
        BoxESP._CanvasOffsetX = 0
        BoxESP._CanvasOffsetY = 0
    end
end

function BoxESP.ProjectWorldToCanvasLocal(PC, WorldLoc)
    if not IsValid(PC) or not WorldLoc or not TempProjVec2D then return false, 0, 0 end

    local res = PC:ProjectWorldLocationToScreen(WorldLoc, TempProjVec2D, true)
    if (res == true or res == 1) and (TempProjVec2D.X ~= 0 or TempProjVec2D.Y ~= 0) then
        local finalX = TempProjVec2D.X * BoxESP._CanvasScaleX + BoxESP._CanvasOffsetX
        local finalY = TempProjVec2D.Y * BoxESP._CanvasScaleY + BoxESP._CanvasOffsetY
        return true, finalX, finalY
    end
    return false, 0, 0
end

-- ========== Snap Line Functionality ==========
function BoxESP.GetSnapLineStartPos(PC, ParentCanvas)
    local screenPixelW, screenPixelH = 0, 0
    local scale = 1.0

    pcall(function()
        if PC and PC.GetViewportSize then
            local vs = FVector2D(0, 0)
            PC:GetViewportSize(vs)
            if vs and vs.X and vs.X > 200 then
                screenPixelW = vs.X
                screenPixelH = vs.Y
            end
        end
    end)

    if screenPixelW <= 200 then
        pcall(function()
            if WidgetLayoutLibrary and WidgetLayoutLibrary.GetViewportSize then
                local vs = WidgetLayoutLibrary.GetViewportSize(PC)
                if vs and vs.X and vs.X > 200 then
                    screenPixelW = vs.X
                    screenPixelH = vs.Y
                end
            end
        end)
    end

    pcall(function()
        if WidgetLayoutLibrary and WidgetLayoutLibrary.GetViewportScale then
            local s = WidgetLayoutLibrary.GetViewportScale(PC)
            if s and type(s) == "number" and s > 0 then scale = s end
        end
    end)

    if screenPixelW <= 200 then
        screenPixelW = 1920 * scale
        screenPixelH = 1080 * scale
    end

    local centerPixelX = screenPixelW / 2.0
    local centerPixelY = BoxESP.SnapLineOriginY * scale

    local fromX = centerPixelX * BoxESP._CanvasScaleX + BoxESP._CanvasOffsetX
    local fromY = centerPixelY * BoxESP._CanvasScaleY + BoxESP._CanvasOffsetY
    return fromX, fromY
end

function BoxESP.CreateSnapLine(ParentCanvas)
    if not IsValid(ParentCanvas) then return nil end
    local border = CGame:NewObjectFromPath("/Script/UMG.Border", ParentCanvas)
    if not IsValid(border) then return nil end

    border:SetBrushColor(ColorWhite)
    border:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    border.RenderTransformPivot = FVector2D(0.0, 0.5)
    border:SetRenderTransformPivot(FVector2D(0.0, 0.5))

    local slot = ParentCanvas:AddChildToCanvas(border)
    if slot then
        slot:SetAutoSize(false)
        slot:SetZOrder(990)
    end
    return { Widget = border, Slot = slot, bVisible = true }
end

function BoxESP.UpdateSnapLine(KeyStr, toX, toY, fromX, fromY, CustomColor, ParentCanvas)
    local lineData = BoxESP.LineWidgets[KeyStr]
    if not lineData or not IsValid(lineData.Widget) then
        lineData = BoxESP.CreateSnapLine(ParentCanvas)
        if not lineData or not lineData.Widget or not lineData.Slot then return end
        BoxESP.LineWidgets[KeyStr] = lineData
    end

    if not lineData.bVisible then
        lineData.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        lineData.bVisible = true
    end

    if CustomColor then
        pcall(function() lineData.Widget:SetBrushColor(CustomColor) end)
    end

    local dx = toX - fromX
    local dy = toY - fromY
    local length = math.sqrt(dx * dx + dy * dy)
    local angle = (math.atan2 and math.atan2(dy, dx) or math.atan(dy, dx)) * (180.0 / math.pi)
    local t = BoxESP.SnapLineThickness or 1.0

    if not lineData._CachedPosVec then
        lineData._CachedPosVec = FVector2D(fromX, fromY - t * 0.5)
        lineData._CachedSizeVec = FVector2D(length, t)
    else
        lineData._CachedPosVec.X = fromX
        lineData._CachedPosVec.Y = fromY - t * 0.5
        lineData._CachedSizeVec.X = length
        lineData._CachedSizeVec.Y = t
    end

    pcall(function()
        lineData.Slot:SetPosition(lineData._CachedPosVec)
        lineData.Slot:SetSize(lineData._CachedSizeVec)
        lineData.Widget:SetRenderAngle(angle)
    end)
end

function BoxESP.HideSnapLine(KeyStr)
    local lineData = BoxESP.LineWidgets[KeyStr]
    if lineData and lineData.Widget and IsValid(lineData.Widget) and lineData.bVisible then
        lineData.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
        lineData.bVisible = false
    end
end

-- ========== Enemy Counter with Images ==========
function BoxESP.CreateEnemyCounter(ParentCanvas, centerX, topY)
    local CD = BoxESP.CounterData
    if CD.ImgPlayer and IsValid(CD.ImgPlayer) and CD.ImgBot and IsValid(CD.ImgBot) then
        return true
    end

    local imgPlayer = CGame:NewObjectFromPath("/Script/UMG.Image", ParentCanvas)
    local slotPlayer = nil
    if imgPlayer and IsValid(imgPlayer) then
        imgPlayer:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        slotPlayer = ParentCanvas:AddChildToCanvas(imgPlayer)
        if slotPlayer then
            slotPlayer:SetAutoSize(false)
            slotPlayer:SetSize(FVector2D(BADGE_WIDTH, BADGE_HEIGHT))
            slotPlayer:SetPosition(FVector2D(centerX - BADGE_WIDTH, topY))
            slotPlayer:SetZOrder(1005)
        end
    end

    local imgBot = CGame:NewObjectFromPath("/Script/UMG.Image", ParentCanvas)
    local slotBot = nil
    if imgBot and IsValid(imgBot) then
        imgBot:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        slotBot = ParentCanvas:AddChildToCanvas(imgBot)
        if slotBot then
            slotBot:SetAutoSize(false)
            slotBot:SetSize(FVector2D(BADGE_WIDTH, BADGE_HEIGHT))
            slotBot:SetPosition(FVector2D(centerX, topY))
            slotBot:SetZOrder(1005)
        end
    end

    local function MakeCounterText(posX, posY)
        local txt = CGame:NewObjectFromPath("/Script/UMG.TextBlock", ParentCanvas)
        local sl = nil
        if txt and IsValid(txt) then
            txt:SetText("0")
            if txt.Font then
                local font = txt.Font
                font.Size = 10
                if font.OutlineSettings then
                    font.OutlineSettings.OutlineSize = 0.0
                    font.OutlineSettings.OutlineColor = FLinearColor(0, 0, 0, 0)
                end
                txt.Font = font
            end
            if txt.SetFontSize then txt:SetFontSize(10) end
            txt:SetJustification(1)
            pcall(function() txt:SetAutoWrapText(false) end)
            if FSlateColor then
                txt:SetColorAndOpacity(FSlateColor(ColorWhite))
            else
                txt:SetColorAndOpacity(ColorWhite)
            end
            txt:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            sl = ParentCanvas:AddChildToCanvas(txt)
            if sl then
                sl:SetAutoSize(true)
                sl:SetAlignment(FVector2D(0.5, 0.5))
                sl:SetPosition(FVector2D(posX, posY))
                sl:SetZOrder(1010)
            end
        end
        return txt, sl
    end

    local txtPlayer, slotTxtPlayer = MakeCounterText(centerX - (BADGE_WIDTH * 0.25), topY + (BADGE_HEIGHT * 0.5))
    local txtBot, slotTxtBot = MakeCounterText(centerX + (BADGE_WIDTH * 0.65), topY + (BADGE_HEIGHT * 0.5))

    LoadBadgeTexture(imgPlayer, ENEMY_COUNTER_PLAYER_URLS, "ic_danger_enemy.png", "Player", CD)
    LoadBadgeTexture(imgBot, ENEMY_COUNTER_BOT_URLS, "ic_clear_boot.png", "Bot", CD)

    CD.ImgPlayer = imgPlayer
    CD.SlotPlayer = slotPlayer
    CD.ImgBot = imgBot
    CD.SlotBot = slotBot
    CD.TxtPlayer = txtPlayer
    CD.SlotTxtPlayer = slotTxtPlayer
    CD.TxtBot = txtBot
    CD.SlotTxtBot = slotTxtBot
    CD.bCreated = true
    return true
end

function BoxESP.UpdateEnemyCounterDisplay(realCount, botCount, ParentCanvas, centerX, topY)
    local CD = BoxESP.CounterData
    if not BoxESP.bShowCounter then
        local col = UEnums.ESlateVisibility.Collapsed
        if CD.ImgPlayer and IsValid(CD.ImgPlayer) then CD.ImgPlayer:SetWidgetVisibility(col) end
        if CD.ImgBot and IsValid(CD.ImgBot) then CD.ImgBot:SetWidgetVisibility(col) end
        if CD.TxtPlayer and IsValid(CD.TxtPlayer) then CD.TxtPlayer:SetWidgetVisibility(col) end
        if CD.TxtBot and IsValid(CD.TxtBot) then CD.TxtBot:SetWidgetVisibility(col) end
        return
    end

    if not BoxESP.CreateEnemyCounter(ParentCanvas, centerX, topY) then return end

    local now = os.clock()
    if (not CD.PlayerLoaded or not CD.BotLoaded) and (now - CD.LastDownloadRetry > 2.0) then
        CD.LastDownloadRetry = now
        if not CD.PlayerLoaded and CD.ImgPlayer then LoadBadgeTexture(CD.ImgPlayer, ENEMY_COUNTER_PLAYER_URLS, "ic_danger_enemy.png", "Player", CD) end
        if not CD.BotLoaded and CD.ImgBot then LoadBadgeTexture(CD.ImgBot, ENEMY_COUNTER_BOT_URLS, "ic_clear_boot.png", "Bot", CD) end
    end

    pcall(function()
        if CD.SlotPlayer then
            CD.SlotPlayer:SetSize(FVector2D(BADGE_WIDTH, BADGE_HEIGHT))
            CD.SlotPlayer:SetPosition(FVector2D(centerX - BADGE_WIDTH, topY))
        end
        if CD.SlotBot then
            CD.SlotBot:SetSize(FVector2D(BADGE_WIDTH, BADGE_HEIGHT))
            CD.SlotBot:SetPosition(FVector2D(centerX, topY))
        end
        if CD.SlotTxtPlayer then
            CD.SlotTxtPlayer:SetPosition(FVector2D(centerX - (BADGE_WIDTH * 0.25), topY + (BADGE_HEIGHT * 0.5)))
        end
        if CD.SlotTxtBot then
            CD.SlotTxtBot:SetPosition(FVector2D(centerX + (BADGE_WIDTH * 0.65), topY + (BADGE_HEIGHT * 0.5)))
        end

        if CD.LastPlayerCount ~= realCount then
            if CD.TxtPlayer and IsValid(CD.TxtPlayer) then CD.TxtPlayer:SetText("Players: " .. tostring(realCount)) end
            CD.LastPlayerCount = realCount
        end

        if CD.LastBotCount ~= botCount then
            if CD.TxtBot and IsValid(CD.TxtBot) then CD.TxtBot:SetText("Bots: " .. tostring(botCount)) end
            CD.LastBotCount = botCount
        end

        local vis = UEnums.ESlateVisibility.SelfHitTestInvisible
        if CD.ImgPlayer and IsValid(CD.ImgPlayer) then CD.ImgPlayer:SetWidgetVisibility(vis) end
        if CD.ImgBot and IsValid(CD.ImgBot) then CD.ImgBot:SetWidgetVisibility(vis) end
        if CD.TxtPlayer and IsValid(CD.TxtPlayer) then CD.TxtPlayer:SetWidgetVisibility(vis) end
        if CD.TxtBot and IsValid(CD.TxtBot) then CD.TxtBot:SetWidgetVisibility(vis) end
    end)
end

function BoxESP.HideWidget(boxData)
    if not boxData or not boxData.bVisible then return end
    boxData.bVisible = false
    local collapsed = UEnums.ESlateVisibility.Collapsed
    if boxData.CornerContainer then boxData.CornerContainer:SetWidgetVisibility(collapsed) end
    if boxData.BgWidget then boxData.BgWidget:SetWidgetVisibility(collapsed) end
    if boxData.HealthWidget then boxData.HealthWidget:SetWidgetVisibility(collapsed) end
    if boxData.WeaponWidget then boxData.WeaponWidget:SetWidgetVisibility(collapsed) end
    if boxData.FlagWidget then boxData.FlagWidget:SetWidgetVisibility(collapsed) end
    if boxData.NameWidget then boxData.NameWidget:SetWidgetVisibility(collapsed) end
    if boxData.DistWidget then boxData.DistWidget:SetWidgetVisibility(collapsed) end
    if boxData.StateWidget then boxData.StateWidget:SetWidgetVisibility(collapsed) end
end

function BoxESP.ShowWidget(boxData)
    if not boxData or boxData.bVisible then return end
    boxData.bVisible = true
    local visible = UEnums.ESlateVisibility.SelfHitTestInvisible
    if boxData.CornerContainer then boxData.CornerContainer:SetWidgetVisibility(visible) end
    if boxData.BgWidget then boxData.BgWidget:SetWidgetVisibility(visible) end
    if boxData.HealthWidget then boxData.HealthWidget:SetWidgetVisibility(visible) end
    if boxData.WeaponWidget then boxData.WeaponWidget:SetWidgetVisibility(visible) end
    if boxData.FlagWidget then boxData.FlagWidget:SetWidgetVisibility(visible) end
    if boxData.NameWidget then boxData.NameWidget:SetWidgetVisibility(visible) end
    if boxData.DistWidget then boxData.DistWidget:SetWidgetVisibility(visible) end
    if boxData.StateWidget then boxData.StateWidget:SetWidgetVisibility(visible) end
end

function BoxESP.UpdateESP()
    if _G._LICENSE_OK ~= true then return end
    if not BoxESP.bActive then return end

    local ParentCanvas = BoxESP.GetMainCanvas()
    if not ParentCanvas then return end

    local GameplayData = package.loaded["GameLua.GameCore.Data.GameplayData"] or _G.GameplayData
    if not GameplayData then return end

    local LocalPlayer = GameplayData.GetPlayerCharacter and GameplayData.GetPlayerCharacter()
    if not IsValid(LocalPlayer) then return end

    local PC = GameplayData.GetPlayerController and GameplayData.GetPlayerController()
    if not IsValid(PC) then return end

    local curTime = os.clock and os.clock() or 0
    if BoxESP._LastCanvas ~= ParentCanvas or (curTime - BoxESP._LastTransformTime > 1.0) then
        BoxESP.UpdateCanvasTransform(PC)
        BoxESP._LastCanvas = ParentCanvas
        BoxESP._LastTransformTime = curTime
    end

    local bRunHeavyTasks = (curTime - BoxESP._LastHeavyUpdateTime > 0.15)
    if bRunHeavyTasks then
        BoxESP._LastHeavyUpdateTime = curTime
    end

    local bUpdateVisCheck = (curTime - BoxESP._LastVisCheckTime > 0.12)
    if bUpdateVisCheck then
        BoxESP._LastVisCheckTime = curTime
    end

    local fromX, fromY = BoxESP.GetSnapLineStartPos(PC, ParentCanvas)

    local TeamID = LocalPlayer.TeamID or (LocalPlayer.GetTeamID and LocalPlayer:GetTeamID()) or 0
    local AllPawns = (Game and Game.GetAllPlayerPawns and Game:GetAllPlayerPawns()) or {}
    local SeenKeys = {}
    local RealPlayerCount = 0
    local BotCount = 0

    for Key, Pawn in pairs(AllPawns) do
        if IsValid(Pawn) and Pawn ~= LocalPlayer then
            local pawnTeam = Pawn.TeamID or (Pawn.GetTeamID and Pawn:GetTeamID()) or -1
            local isAlive = (Pawn.Health and Pawn.Health > 0) or (Pawn.IsAlive and Pawn:IsAlive())

            if isAlive and pawnTeam ~= TeamID then
                local KeyStr = tostring(Key)
                SeenKeys[KeyStr] = true

                local ping = (Pawn.PlayerState and Pawn.PlayerState.Ping) or Pawn.Ping or (Pawn.GetPing and Pawn:GetPing()) or -1
                ping = tonumber(ping) or -1
                local isBot = (ping >= 0 and ping <= 3) or Pawn.bIsAI or Pawn.bIsAIBot or Pawn.bIsABot or (Game and Game.IsAI and Game:IsAI(Pawn))

                if isBot then
                    BotCount = BotCount + 1
                else
                    RealPlayerCount = RealPlayerCount + 1
                end

                local Loc = Pawn.K2_GetActorLocation and Pawn:K2_GetActorLocation()
                if not Loc and Pawn.RootComponent then
                    Loc = Pawn.RootComponent:K2_GetComponentLocation()
                end

                if Loc then
                    local topWorldPos = nil
                    local bottomWorldPos = nil

                    local mesh = Pawn.Mesh or (Pawn.GetMesh and Pawn:GetMesh()) or Pawn.CharacterMesh0
                    if mesh and mesh.GetSocketLocation then
                        local hLoc = mesh:GetSocketLocation("Head") or mesh:GetSocketLocation("head")
                        if hLoc and (hLoc.X ~= 0 or hLoc.Y ~= 0 or hLoc.Z ~= 0) then
                            topWorldPos = FVector(hLoc.X, hLoc.Y, hLoc.Z + 15)
                        end
                        local rLoc = mesh:GetSocketLocation("root") or mesh:GetSocketLocation("Root")
                        if rLoc and (rLoc.X ~= 0 or rLoc.Y ~= 0 or rLoc.Z ~= 0) then
                            bottomWorldPos = rLoc
                        end
                    end

                    local isProne = false
                    local isCrouch = false
                    if Pawn.bIsProning or Pawn.bIsProne or (Pawn.IsProne and Pawn:IsProne()) or Pawn.PoseState == 2 or Pawn.PoseState == "Prone" then
                        isProne = true
                    elseif Pawn.bIsCrouched or (Pawn.IsCrouched and Pawn:IsCrouched()) or Pawn.PoseState == 1 or Pawn.PoseState == "Crouch" then
                        isCrouch = true
                    end

                    if not topWorldPos or not bottomWorldPos then
                        local topOffset = isProne and 18 or (isCrouch and 50 or 88)
                        local bottomOffset = isProne and -22 or (isCrouch and -68 or -90)
                        topWorldPos = topWorldPos or FVector(Loc.X, Loc.Y, Loc.Z + topOffset)
                        bottomWorldPos = bottomWorldPos or FVector(Loc.X, Loc.Y, Loc.Z + bottomOffset)
                    end

                    local bTopOk, topX, topY = BoxESP.ProjectWorldToCanvasLocal(PC, topWorldPos)
                    local bBottomOk, bottomX, bottomY = BoxESP.ProjectWorldToCanvasLocal(PC, bottomWorldPos)

                    local boxData = BoxESP.BoxWidgets[KeyStr]
                    -- Recreate widgets if the match created a new Canvas or the
                    -- old widget was destroyed during a map/match transition.
                    if not boxData or not IsValid(boxData.CornerContainer) then
                        boxData = BoxESP.CreateESPWidget(ParentCanvas)
                        if boxData then BoxESP.BoxWidgets[KeyStr] = boxData end
                    end

                    if boxData and IsValid(boxData.CornerContainer) then
                        if bTopOk and bBottomOk then
                            local boxHeight = math.max(28, math.abs(bottomY - topY))
                            local boxWidth = math.max(15, boxHeight * (isProne and 1.1 or (isCrouch and 0.7 or 0.55)))

                            local centerX = (topX + bottomX) * 0.5
                            local centerY = (topY + bottomY) * 0.5
                            local boxTopY = centerY - (boxHeight * 0.5)
                            local boxBottomY = centerY + (boxHeight * 0.5)

                            BoxESP.UpdateCornerDimensions(boxData, boxWidth, boxHeight)
                            boxData.CornerSlot:SetPosition(FVector2D(centerX, centerY))
                            BoxESP.ShowWidget(boxData)

                            local healthBarWidth = BoxESP.HealthBarWidth or 2.0
                            local healthCenterX = centerX - (boxWidth * 0.5) - 2.5 - (healthBarWidth * 0.5)
                            local health = Pawn.Health or (Pawn.GetHealth and Pawn:GetHealth()) or 100
                            local healthMax = Pawn.HealthMax or (Pawn.GetHealthMax and Pawn:GetHealthMax()) or 100
                            if healthMax <= 0 then healthMax = 100 end

                            local healthPercent = math.max(0, math.min(1, health / healthMax))
                            local currentHealthHeight = boxHeight * healthPercent

                            boxData.BgSlot:SetSize(FVector2D(healthBarWidth, boxHeight))
                            boxData.BgSlot:SetPosition(FVector2D(healthCenterX, boxBottomY))
                            boxData.HealthSlot:SetSize(FVector2D(healthBarWidth, currentHealthHeight))
                            boxData.HealthSlot:SetPosition(FVector2D(healthCenterX, boxBottomY))

                            if bRunHeavyTasks or boxData._cachedWeapon == "" then
                                local wep = (Pawn.GetCurrentWeapon and Pawn:GetCurrentWeapon())
                                    or (Pawn.GetCurrentShootWeapon and Pawn:GetCurrentShootWeapon())
                                    or (Pawn.WeaponManagerComponent and Pawn.WeaponManagerComponent.CurrentWeaponReplicated)
                                local weaponName = "Fist"
                                if wep and IsValid(wep) then
                                    local wn = (type(wep.GetWeaponName) == "function" and wep:GetWeaponName()) or wep.WeaponName
                                    if wn and wn ~= "" then
                                        weaponName = tostring(wn):gsub("^BP_", ""):gsub("_C$", ""):gsub("_Wrapper$", "")
                                    end
                                end
                                if boxData._cachedWeapon ~= weaponName then
                                    boxData.WeaponWidget:SetText(weaponName)
                                    boxData._cachedWeapon = weaponName
                                end
                            end
                            boxData.WeaponSlot:SetPosition(FVector2D(centerX, boxTopY - 3.5))

                            if bRunHeavyTasks or not boxData._cachedNation then
                                local playerNation = (Pawn.PlayerState and Pawn.PlayerState.Nation) or Pawn.Nation or ""
                                playerNation = tostring(playerNation or "")
                                if playerNation == "" or playerNation == "nil" or playerNation == "0" then
                                    playerNation = "G1"
                                end

                                if boxData._cachedNation ~= playerNation then
                                    local cfg = (CDataTable and CDataTable.GetTableData) and CDataTable.GetTableData("RegionConfig", playerNation)
                                    if not cfg or not cfg.res_path or cfg.res_path == "" then
                                        cfg = (CDataTable and CDataTable.GetTableData) and CDataTable.GetTableData("RegionConfig", "G1")
                                    end
                                    local flagPath = (cfg and cfg.res_path) or "/Game/UMG/Texture/Atlas/NationalflagUI/Frames/T_icon_flag_iland_png.T_icon_flag_iland_png"

                                    if boxData.FlagWidget and IsValid(boxData.FlagWidget) then
                                        local bSet = false
                                        if boxData.FlagWidget.SetBrushResourceFromPathSync then
                                            boxData.FlagWidget:SetBrushResourceFromPathSync(flagPath, false)
                                            bSet = true
                                        end
                                        if not bSet and boxData.FlagWidget.SetBrushFromPathAsync then
                                            boxData.FlagWidget:SetBrushFromPathAsync(flagPath, false)
                                            bSet = true
                                        end
                                        if not bSet then
                                            local util = package.loaded["client.slua_ui_framework.util"]
                                            if not util then pcall(function() util = require("client.slua_ui_framework.util") end) end
                                            if util and util.SetTexture then
                                                util.SetTexture(boxData.FlagWidget, flagPath, { sync = true })
                                                bSet = true
                                            end
                                        end
                                        if not bSet then
                                            local asset_util = package.loaded["common.asset_util"]
                                            if not asset_util then pcall(function() asset_util = require("common.asset_util") end) end
                                            local flagTex = (asset_util and asset_util.GetAssetSync and asset_util.GetAssetSync(flagPath))
                                                         or (CGame and CGame.LoadObject and CGame:LoadObject(flagPath))
                                            if flagTex and boxData.FlagWidget.SetBrushFromTexture then
                                                boxData.FlagWidget:SetBrushFromTexture(flagTex, false)
                                                bSet = true
                                            end
                                        end
                                        boxData.FlagWidget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                                    end
                                    boxData._cachedNation = playerNation
                                end
                            end
                            if boxData.FlagSlot then
                                boxData.FlagSlot:SetPosition(FVector2D(centerX, boxTopY - 22.0))
                            end

                            if bRunHeavyTasks or boxData._cachedName == "" then
                                local playerName = isBot and "Bot" or (Pawn.PlayerName or Pawn.PlayerNamePublic or (Pawn.GetPlayerName and Pawn:GetPlayerName()) or "Player")
                                playerName = tostring(playerName)
                                if boxData._cachedName ~= playerName then
                                    boxData.NameWidget:SetText(playerName)
                                    boxData._cachedName = playerName
                                end
                            end
                            boxData.NameSlot:SetPosition(FVector2D(centerX, boxBottomY + 4.0))

                            local distVal = math.floor(LocalPlayer:GetDistanceTo(Pawn) / 100.0)
                            local distStr = tostring(distVal) .. "m"
                            if boxData._cachedDist ~= distStr then
                                boxData.DistWidget:SetText(distStr)
                                boxData._cachedDist = distStr
                            end
                            boxData.DistSlot:SetPosition(FVector2D(centerX, boxBottomY + 20.5))

                            if bUpdateVisCheck or BoxESP._VisCheckCache[KeyStr] == nil then
                                BoxESP._VisCheckCache[KeyStr] = (PC and PC.LineOfSightTo and PC:LineOfSightTo(Pawn)) or false
                            end
                            local isVisible = BoxESP._VisCheckCache[KeyStr]

                            if bRunHeavyTasks or boxData._cachedState == "" then
                                local isKnocked = (Pawn.HealthStatus == 1 or Pawn.bIsKnocked or (Pawn.IsKnocked and Pawn:IsKnocked()))
                                local stateStr = "Open"
                                local slateCol = SlateColorGreen
                                if isKnocked then
                                    stateStr = "Knocked"
                                    slateCol = SlateColorRed
                                elseif not isVisible then
                                    stateStr = "Cover"
                                    slateCol = SlateColorRed
                                end

                                if boxData._cachedState ~= stateStr then
                                    boxData.StateWidget:SetText(stateStr)
                                    boxData.StateWidget:SetColorAndOpacity(slateCol)
                                    boxData._cachedState = stateStr
                                end
                            end
                            boxData.StateSlot:SetPosition(FVector2D(centerX, boxBottomY + 37.0))

                            if BoxESP.bShowLines then
                                local lineColor = isVisible and ColorGreen or ColorRed
                                BoxESP.UpdateSnapLine(KeyStr, centerX, boxTopY, fromX, fromY, lineColor, ParentCanvas)
                            else
                                BoxESP.HideSnapLine(KeyStr)
                            end
                        else
                            BoxESP.HideWidget(boxData)
                            BoxESP.HideSnapLine(KeyStr)
                        end
                    end
                end
            end
        end
    end

    for KeyStr, boxData in pairs(BoxESP.BoxWidgets) do
        if not SeenKeys[KeyStr] then
            BoxESP.HideWidget(boxData)
        end
    end
    for KeyStr, _ in pairs(BoxESP.LineWidgets) do
        if not SeenKeys[KeyStr] then
            BoxESP.HideSnapLine(KeyStr)
            BoxESP._VisCheckCache[KeyStr] = nil
        end
    end

    local counterTopY = fromY - BADGE_HEIGHT - 2
    if counterTopY < 10 then counterTopY = 48 end
    BoxESP.UpdateEnemyCounterDisplay(RealPlayerCount, BotCount, ParentCanvas, fromX, counterTopY)
end


_G.BoxESP = BoxESP
return BoxESP
end
pcall(function() _G.InstallLavaESP() end)

-- Keep the original Lava ESP lifecycle. The Lava source itself installs its
-- native PC timer + time_ticker loop, and UpdateESP is license-gated.
_G.DisableAllLegacyESP = _G.DisableAllLegacyESP or function() end
_G.StartSuppliedESPOnly = function()
    if _G._LICENSE_OK ~= true then return end
    -- Keep legacy ESP V2 available; its own EspLoai9 checkbox controls it.
    pcall(function() if _G.BoxESP then _G.BoxESP.bActive = (_G.LexusConfig and _G.LexusConfig.LavaESP == true) end end)
end
_G.StopSuppliedESPOnly = function()
    pcall(function() if _G.BoxESP and _G.BoxESP.Stop then _G.BoxESP.Stop() end end)
end

-- LAVA ESP lifecycle is intentionally tied to the same FastTick runtime loop
-- used by the original ESP/menu systems. A separate AddTimerLoop caused the
-- ESP to get stuck after a match transition.
_G._LAVA_ESP_LOOP_STARTED = false
_G._LAVA_ESP_LOOP_TIMER = nil
_G.StartLavaESPLoop = function()
    if _G._LICENSE_OK ~= true then return end
    _G._LAVA_ESP_LOOP_STARTED = true
    if _G.BoxESP then
        _G.BoxESP.bActive = (_G.LexusConfig and _G.LexusConfig.LavaESP == true) or false
    end
end

_G.StopLavaESPLoop = function()
    _G._LAVA_ESP_LOOP_STARTED = false
    _G._LAVA_ESP_LOOP_TIMER = nil
    pcall(function()
        if _G.BoxESP then
            _G.BoxESP.bActive = false
        end
    end)
end

do
    local _origStartLicensed = _G.StartLicensedSystems
    local _origStopLicensed = _G.StopLicensedSystems
    _G.StartLicensedSystems = function()
        if _G._LICENSE_OK ~= true then return end
        pcall(function() if _origStartLicensed then _origStartLicensed() end end)
        pcall(_G.StartSuppliedESPOnly)
        pcall(_G.StartLavaESPLoop)
    end
    _G.StopLicensedSystems = function()
        pcall(function() if _G.StopSkinLoop then _G.StopSkinLoop() end end)
        pcall(_G.StopLavaESPLoop)
        pcall(_G.StopSuppliedESPOnly)
        pcall(function() if _origStopLicensed then _origStopLicensed() end end)
    end
end


-- ============================================================
-- Feedback System (relocated to end of file)
-- ============================================================
