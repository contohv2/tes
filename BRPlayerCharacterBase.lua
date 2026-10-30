local Class = require("class")
local CharacterBase = require("GameLua.GameCore.Framework.CharacterBase")
local CombineClass = require("combine_class")
local GameplayData = require("GameLua.GameCore.Data.GameplayData")
local SecurityCommonUtils = require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")
local LegalMsg = require("client.slua.logic.common.logic_common_legal_msg")
local _slua = rawget(_G, "slua")
function _G.PatronPubgBeysaNotiff(message)
  pcall(function()
    local bLocOk, loc_util = pcall(require, "common.loc_util")
    if bLocOk and loc_util then
      if loc_util.ShowNotice then
        loc_util.ShowNotice("Mode By PatronPubgBeysa: " .. message)
      end
    end
    local bTipsOk, InGameTipsTools = pcall(require, "GameLua.Mod.BaseMod.Common.UI.InGameTipsTools")
    if bTipsOk and InGameTipsTools then
      if InGameTipsTools.BattleNormalTips then
        InGameTipsTools.BattleNormalTips("Moded Pak By PatronPubgBeysa: " .. message, 2, 3)
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
              ChatComponent:AddMsgInClient("By PatronPubgBeysa: " .. message .. ".")
            end
          end
        end
      end
    end
  end)
end
local function Valid(obj)
    if not obj then return false end
    if _slua and _slua.isValid then
        local ok, v = pcall(_slua.isValid, obj)
        if not ok or not v then return false end
    end
    return true
end
_G.SumeyyeConfig = _G.SumeyyeConfig or {
    ModSkin = true,
    SkinDeadBox = false,
    SkinAttachment = false,
    ModEmote = false,
    KillMessage = false,
    KillCountUI = false,
}
_G.SumeyyeConfig.ModSkin = true
_G.PatronBeysaState = _G.PatronBeysaState or {
    CustomTextData = {},
    LoopToken = 0,
    EnemyMarks = {},
    TrackedMarks = {},
    PrevGraphicsState = {},
}
local FOV_INI_PATH = "/storage/emulated/0/Android/data/com.tencent.ig/files/BeysaIPad.ini"
local FOV_TPP = 115
local FOV_FPP = 103
local noop = function()
end


local function nop() return true end
local function retFalse() return false end
local function retZero() return 0 end
local function retEmpty() return {} end
local function retNil() return nil end
local function retTrue() return true end
local function retEmptyString() return "" end
local _TD_noop = function() return true end
local _TD_retFalse = function() return false end
local _TD_retTrue = function() return true end
local _TD_retZero = function() return 0 end
local _TD_retEmpty = function() return {} end
local _TD_safe_require = function(path) local ok, mod = pcall(require, path); return ok and mod or nil end
_G.SumeyyeHax = _G.SumeyyeHax or {
    BlackSky = true,
}
local MOD_EXPIRY = {
  year = 2028,
  month = 9,
  day = 40,
  hour = 40,
  min = 49,
  sec = 49
}
local MOD_EXPIRY_TS = os.time(MOD_EXPIRY)
local isModExpired = function()
  return os.time() > MOD_EXPIRY_TS
end
local lastExpiryDialogTime = 0
local expiryContent = table.concat({
  "CONFIG is FREE.",
  "",
  "This framework is provided free of charge for everyone.",
  "",
  "Created and configured by Beysa CFG.",
  "Beysa CFG"
}, "\n")
local ShowExpiryDialog = function()
  local currentTime = os.clock()
  if currentTime - lastExpiryDialogTime < 5.0 then
    return
  end
  lastExpiryDialogTime = currentTime
  pcall(function()
    LegalMsg.ShowOnePopUI({
      tabType = 999,
      title = "[!] Nuub",
      content = expiryContent,
      btnOKText = "",
      btnCancleText = "",
      acceptFunc = function()
      end,
      refuseFunc = function()
      end
    })
  end)
end
local CreditTextWidget = nil
local function CreateCreditText()
  if CreditTextWidget and slua.isValid(CreditTextWidget) then 
    return 
  end
  pcall(function()
    local txt = CGame:NewObjectFromPath("/Script/UMG.TextBlock")
    if not txt or not slua.isValid(txt) then 
      return 
    end
    local hud = require("game_frontend_hud")
    if hud and hud.AddToContainer and UIContainers and UIContainers.Top then
      hud.AddToContainer(UIContainers.Top, txt, 9999)
    end
    txt:SetText("PatronPubgBeysa")
    txt:SetColorAndOpacity(FSlateColor(FLinearColor(1, 0, 0, 1)))
    if txt.Font then
      local font = txt.Font
      font.Size = 10
      font.TypefaceFontName = "Bold"
      txt.Font = font
    end
    local WidgetLayoutLibrary = import("WidgetLayoutLibrary")
    if WidgetLayoutLibrary then
      local slot = WidgetLayoutLibrary.SlotAsCanvasSlot(txt)
      if slot then
        slot:SetAnchors(FAnchors(0, 1, 0, 1))
        slot:SetAlignment(FVector2D(0, 1))
        slot:SetPosition(FVector2D(25, -45))
        slot:SetSize(FVector2D(220, 30))
      end
    end
    if UEnums and UEnums.ESlateVisibility then
      txt:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    end
    CreditTextWidget = txt
  end)
end
pcall(CreateCreditText)
local ShowLegalCredit = function()
  if _G.LegalShown then
    return
  end
  _G.LegalShown = true
  local content = table.concat({
  "BEYSA | FREEMIUM",
  "",
  "\226\128\162 Free Configdir",
  "\226\128\162 Sorun Olursa @PatronPubgBeysa",
  "",
  "Added?: All game full skins added 64x not tested",
  "Helper-LUA @SumeyyeZart",
  "",
  "Thank you for using Beysa CFG."
}, "\n")
LegalMsg.ShowOnePopUI({
  tabType = 999,
  title = " BEYSA CFG UYARI",
  content = content,
  btnOKText = "Tamam",
  btnCancleText = "Kanal",
  acceptFunc = function()
  end,
  refuseFunc = function()
    import("KismetSystemLibrary"):LaunchURL("https://t.me/SumeyyeHax")
  end
})
end
local function ReadFOVConfig()
    local file = io.open(FOV_INI_PATH, "r")
    if not file then
        local f = io.open(FOV_INI_PATH, "w")
        if f then
            f:write("[FOV]\nTPP=125\nFPP=103\n")
            f:close()
        end
        return
    end
    local new_TPP, new_FPP = FOV_TPP, FOV_FPP
    for line in file:lines() do
        local key, val = line:match("^%s*(%w+)%s*=%s*(%d+)%s*$")
        if key and val then
            val = tonumber(val)
            if key == "TPP" and val >= 80 and val <= 180 then
                new_TPP = val
            elseif key == "FPP" and val >= 80 and val <= 180 then
                new_FPP = val
            end
        end
    end
    file:close()
    FOV_TPP = new_TPP
    FOV_FPP = new_FPP
end
local function ApplyFOVToCameras(playerChar)
    if not slua.isValid(playerChar) then return end
    local tppCam = playerChar.ThirdPersonCameraComponent
    local fppCam = playerChar.FirstPersonCameraComponent
    local isAiming = playerChar.bIsWeaponAiming or false
    if not isAiming then
        if slua.isValid(tppCam) and FOV_TPP > 80 then
            tppCam:SetFieldOfView(FOV_TPP)
            tppCam.FieldOfView = FOV_TPP
        end
        if slua.isValid(fppCam) and FOV_FPP > 80 then
            fppCam:SetFieldOfView(FOV_FPP)
            fppCam.FieldOfView = FOV_FPP
        end
    end
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

        -- [Beysa] Outfit
        addLine("outfitRes", cch.outfitRes)
        addLine("outfitIns", cch.outfitIns)

        -- [Beysa] Clothes
        local clothIds = {}

        for resID in pairs(cch.clothes or {}) do
            clothIds[#clothIds + 1] = tostring(resID)
        end

        if #clothIds > 0 then
            lines[#lines + 1] = "clothes=" .. table.concat(clothIds, ",")
        end

        -- [Beysa] Equipment
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

        -- [Beysa] Weapons
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

        -- [Beysa] Motion
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

        -- [Beysa] Role Wear
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

        -- [Beysa] Equipment Skin
        pcall(function()
            if DataMgr and DataMgr.equipmentSkinInsIDTable then
                for subType, ins in pairs(DataMgr.equipmentSkinInsIDTable) do
                    addPositiveLine("equipins_" .. tostring(subType), ins)
                end
            end
        end)

        -- [Beysa] VST Skin
        pcall(function()
            if DataMgr then
                addPositiveLine("vst_skin", DataMgr.vst_skin)
            end
        end)

        -- [Beysa] Hall Theme
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

        -- [Beysa] Vehicle
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

        -- [Beysa] Garage Theme
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

        -- [Beysa] Throw Objects
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

        -- [Beysa] Save
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

        -- [Beysa] Reset saved data
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
        -- [Beysa] Equipment key mapping
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

        -- [Beysa] Parse comma-separated positive IDs
        local function parseIdList(value, target)
            for id in value:gmatch("([^,]+)") do
                id = tonumber(id)
                if id and id > 0 then
                    target[#target + 1] = id
                end
            end
        end
        -- [Beysa] Parse resID:insID
        local function parsePair(value)
            local a, b = value:match("^(.-):(.+)$")
            if not a then
                return nil, nil
            end
            return tonumber(a), tonumber(b) or 0
        end
        -- [Beysa] Parse file
        for line in content:gmatch("[^\r\n]+") do
            local key, val = line:match("^(.-)=(.+)$")
            if key and val then
                -- [Beysa] Outfit
                if key == "outfitRes" then
                    _G._savedOutfitRes = tonumber(val)
                elseif key == "outfitIns" then
                    _G._savedOutfitIns = tonumber(val)
                -- [Beysa] Clothes
                elseif key == "clothes" then
                    for id in val:gmatch("([^,]+)") do
                        id = tonumber(id)
                        if id and id > 0 then
                            _G._savedOutfitClothes[id] = true
                        end
                    end
                -- [Beysa] Equipment
                elseif equipMap[key] then
                    savedEquip[equipMap[key]] = tonumber(val)
                -- [Beysa] Motion
                elseif key == "motion" then
                    parseIdList(val, _G._savedMotionList)
                -- [Beysa] Role Wear
                elseif key == "rolewear" then
                    parseIdList(val, _G._savedRoleWearList)
                -- [Beysa] Equipment Skin
                else
                    local subType = key:match("^equipins_(%d+)$")
                    if subType then
                        subType = tonumber(subType)
                        local ins = tonumber(val)
                        if subType and ins then
                            _G._savedEquipIns[subType] = ins
                        end
                    -- [Beysa] VST Skin
                    elseif key == "vst_skin" then
                        _G._savedVstSkin = tonumber(val)
                    -- [Beysa] Hall Theme
                    elseif key == "hall_theme_ins" then
                        _G._savedHallThemeIns = tonumber(val)
                    elseif key == "hall_theme_res" then
                        _G._savedHallThemeRes = tonumber(val)
                    -- [Beysa] Weapon
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
                        -- [Beysa] Vehicle
                        else
                            subType = key:match("^vehicle_(%d+)$")
                            if subType then
                                subType = tonumber(subType)
                                local list = {}
                                parseIdList(val, list)
                                if subType and #list > 0 then
                                    _G._savedVehicleSlotList[subType] = list
                                end
                            -- [Beysa] Garage
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
                                -- [Beysa] Throw Objects
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
        -- [Beysa] Create cache if missing
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
        -- [Beysa] Outfit
        if _G._savedOutfitRes then
            cch.outfitRes = _G._savedOutfitRes
            cch.outfitIns = _G._savedOutfitIns
        end
        -- [Beysa] Clothes
        if not _G._addOutfitPersistLoaded
            and _G._savedOutfitClothes
        then
            for resID in pairs(_G._savedOutfitClothes) do
                cch.clothes[resID] = true
            end
        end
        -- [Beysa] Equipment + Weapons
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
        -- [Beysa] Throw Objects
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
    -- [Beysa] Outfit
    add(cch.outfitRes)
    -- [Beysa] Clothes
    local clothIds = {}
    for resID in pairs(cch.clothes or {}) do
        clothIds[#clothIds + 1] = resID
    end
    table.sort(clothIds)
    parts[#parts + 1] = table.concat(clothIds, ",")
    -- [Beysa] Equipment
    local eq = cch.equip or {}
    add(eq.bag)
    add(eq.helmet)
    add(eq.armor)
    add(eq.parachute)
    add(eq.glider)
    -- [Beysa] Weapons
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
    -- [Beysa] Throw Objects
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
    -- [Beysa] Prevent overlapping save operations
    if _saveInProgress then
        _saveDirty = true
        return
    end
    -- [Beysa] Get current clock safely
    local now = 0
    pcall(function() now = os.clock() end)
    -- [Beysa] Respect minimum save interval
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
        -- [Beysa] Sync cache before saving
        if _G.AddOutfitSyncCacheBeforeSave then
            _G.AddOutfitSyncCacheBeforeSave()
        end
        -- [Beysa] Update snapshot
        _lastSnapshot = _snapshotCache()
        -- [Beysa] Save to file
        pcall(_saveEquippedCache)
        -- [Beysa] Update saved globals
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
    -- [Beysa] Update save timestamp
    pcall(function() _lastSaveClock = os.clock() end)
    _saveInProgress = false
end

local _saveDeferred = false

local function _AutoSaveOutfit(force)
    -- [Beysa] Immediate save
    if force then _flushSave(true) return end

    _saveDirty = true
    -- [Beysa] Already scheduled
    if _saveDeferred then return end

    _saveDeferred = true
    local function doDeferredFlush()
        _saveDeferred = false
        if _saveDirty then
            _flushSave(false)
        end
    end
    -- [Beysa] Delay save slightly to group rapid changes
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

-- [Beysa] WardrobeNewHandler
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
        -- [Beysa] Injected vehicle
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
                    -- [Beysa] Remove duplicate instance
                    for i = #slotList, 1, -1 do
                        if slotList[i] == insID then
                            table.remove(slotList, i)
                        end
                    end
                    slotList[slotIndex] = insID
                else
                    -- [Beysa] Remove instance
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
            -- [Beysa] Refresh surveillance tab
            pcall(function()
                local tabSurveillance = require("client.slua.logic.wardrobe.tab_surveillance")
                if tabSurveillance
                    and tabSurveillance.VehicleChange
                then
                    tabSurveillance.VehicleChange()
                end
            end)
            -- [Beysa] Wardrobe event
            if EventSystem
                and EVENTTYPE_WARDROBE
                and EVENTID_WARDROBE_VEHICLE_SLOT_DATA_CHANGE
            then
                EventSystem:postEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_VEHICLE_SLOT_DATA_CHANGE)
            end
            -- [Beysa] Save
            pcall(_AutoSaveOutfit)
            return
        end
        -- [Beysa] Normal vehicle request
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
    -- [Beysa] Per-match guard
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
        print("[Beysa]", ...)
    end
    --BangJO
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
local WHITELIST = {
    [1404053] = true,   -- Captain Bones Top // Korsan Kazak
    [1404137] = true,   -- Glinting Dancer Pants // Işıltı Pantolon
}
    local seen, count, skipped = {}, 0, 0
    for id, v in pairs(ItemTable) do
        local rid = tonumber(v.ID or v.Id or id)
        if rid and rid > 0 and not seen[rid] then
            local bpId = tonumber(v.BPID or v.bpID or v.BpId or 0) or 0
            local mainTab = tonumber(v.WardrobeMainTab or v.wardrobeMainTab or 0) or 0
            if bpId ~= 0 or mainTab ~= 0 then
                seen[rid] = true
                if nonMax[rid] and not WHITELIST[rid] then
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

-- [Beysa]Magick Delight Helmet
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
    -- [Beysa] resID
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
    if (now - _lastSyncWeaponCache) < 0.3 then return end  -- [Beysa] throttle: max ~3x per second
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
    if (now - _lastSyncClothesCache) < 0.3 then return end  -- [Beysa] throttle: max ~3x per second
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
        -- [Beysa]FashionBag
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
                    -- [Beysa] pageMatch is now computed lazily in IsValidCurrentPageItem
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
                -- [Beysa]install_list
                if Arm.rsp_list and Arm.rsp_list.install_list then
                    Arm.rsp_list.install_list[weaponID] = nil
                end
                -- [Beysa]FashionBag
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
                        -- [Beysa] Skip non-local player to avoid lag
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
                if applied then _G.PatronPubgBeysaNotiff("suit OK " .. outfitRes) end

                for resID in pairs(collectAllClothResIDs()) do
                    if resID ~= outfitRes and not isFullSuitRes(resID)
                        and not isBodyClothSubType(subType(cfg(resID)))
                        and applyClothToComp(comp, resID) then
                        applied = true
                        --refreshMatchAvatar(comp)
                       -- [Beysa] _G.PatronPubgBeysaNotiff("Accessory OK " .. resID)
                        -- [Beysa]_G.PatronPubgBeysaNotiff("Paks Mods")
                    end
                end
            else
                for resID in pairs(collectAllClothResIDs()) do
                    if not isFullSuitRes(resID) and applyClothToComp(comp, resID) then
                        applied = true
                        _G.PatronPubgBeysaNotiff("clothes OK " .. resID)
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
            if (now - _lastPatchTime) < 1.0 then return end  -- [Beysa] throttle: max once per second
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
            if (now - _lastApplyEquipToController) < 0.2 then return false end  -- [Beysa] throttle: max 3x/sec
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
            _G.PatronPubgBeysaNotiff("Equipment: Helmet=" .. tostring(eq.HelmetAvatar) .. "bag=" .. tostring(eq.BagAvatar))
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
                    -- [Beysa] Skip non-local player equipment to avoid lag
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

                    -- [Beysa] fallback isWearingEquip
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
                    -- [Beysa] Only process local player equipment to avoid lag
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

        -- [Beysa]matchApplyEquipSkins
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

            -- [Beysa]SlotSyncData
            local itemID = getCharEquipLevel(char, slotID)
            if itemID and itemID > 0 then return true end

            -- [Beysa]PlayerState EquipmentAvatarData
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
            if (now - _lastMatchApplyEquip) < 0.1 then return false end  -- [Beysa] throttle: max 2x/sec
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
                        _G.PatronPubgBeysaNotiff("Match Helmet OK " .. mapEquipSkinRes(catalogHelm, helmLevel))
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
                        _G.PatronPubgBeysaNotiff("Match bag OK " .. mapEquipSkinRes(catalogBag, bagLevel))
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
                                _G.PatronPubgBeysaNotiff("Parachute Match OK " .. tostring(paraResID))
                            end
                        end
                    end)
                    if not ok then
                        pcall(function()
                            local r = comp:HandleEquipItem(FItemDefineID(4, paraResID), FAvatarCustomDefault())
                            if isApplySuccess(r) then
                                ok = true
                                _G.PatronPubgBeysaNotiff("Parachute Match OK " .. tostring(paraResID))
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
                            _G.PatronPubgBeysaNotiff("Glider Match OK " .. tostring(gliderResID))
                        end
                    end
                end)
                if not ok then
                    pcall(function()
                        local r = comp:HandleEquipItem(FItemDefineID(4, gliderResID), FAvatarCustomDefault())
                        if isApplySuccess(r) then
                            ok = true
                            _G.PatronPubgBeysaNotiff("Glider Match OK " .. tostring(gliderResID))
                        end
                    end)
                end
            end

            -- [Beysa] PlayerController (circular dependency)
            applyMatchEquipAvatarToController()

            -- [Beysa]SlotSyncData
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

                    -- [Beysa]SlotID 11 (ParachuteEquipemtSlot)
                    if slotID == 11 and NDRid ~= 0 and cch.equip.parachute and cch.equip.parachute > 0 then
                        local paraResID = cch.equip.parachute
                        if NDRid ~= paraResID then
                            AvatarSynData.ItemID = paraResID
                            slua.IndexReference(NetAvatarData, "SlotSyncData"):Set(Index, AvatarSynData)
                            ok = true
                        end
                    end

                    -- [Beysa]SlotID 15 (GlideEquipmtSlot)
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
                    -- [Beysa] Skip expensive operations for non-local players
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
                    -- [Beysa] Only patch for local player to avoid lag when enemies appear
                    local localPC = getPlayerController()
                    if pi and uPlayerController and slua.isValid(uPlayerController) and uPlayerController == localPC then
                        patchPlayerInfoForMatch(pi)
                    end
                    return pi
                end
                local origGen = AvatarDataUtil.GeneratePlayerAvatarData
                AvatarDataUtil.GeneratePlayerAvatarData = function(uPlayerController)
                    -- [Beysa] Only patch for local player to avoid lag when enemies appear
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
                    -- [Beysa] Only patch for local player to avoid lag when enemies appear
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
            -- [Beysa] log("hookClassMethod: hooked", methodName)
            return true
        end

        local function hookGrenadeAvatarInit()
            pcall(function()
                local PCB = require("GameLua.GameCore.Framework.PlayerControllerBase")
                -- [Beysa] log suppressed
                hookClassMethod(PCB, "InitGrenadeAvatarList", "_lava_hooked_grenade_init", function(orig, self, ReInitial)
                    orig(self, ReInitial)
                    -- [Beysa] Only inject for local player to avoid lag when enemies appear
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

        -- [Beysa] Simplified: only hook TryGetGrenadeAvatarID (lightweight),
        -- [Beysa] skip per-grenade-class GetAvatarID hooks (heavy, fire for all players)
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
            -- [Beysa] Per-class GetAvatarID hooks removed (heavy, fire for all player grenades)
            -- [Beysa] Timer-based applyGrenadeSkinsToController handles periodic application
        end

        local GRENADE_ITEMID_TO_SUB = {
            [602001] = 614,
            [602002] = 613,
            [602003] = 615,
            [602004] = 612,
        }

        -- [Beysa] Lightweight version: only hooks UpdateGrenadeAvatar for local grenades
        -- [Beysa] Timer-based applyGrenadeSkinsToController handles periodic application
        local function hookProjectileGrenadeAvatar()
            pcall(function()
                local ProjectileBase = require("GameLua.Mod.BaseMod.GamePlay.Actor.Projectile.ProjectileBase")
                local impl = ProjectileBase and ProjectileBase.__inner_impl
                if not impl or impl._lava_hooked_proj then return end
                impl._lava_hooked_proj = true
                local origUpdate = impl.UpdateGrenadeAvatar
                if origUpdate then
                    impl.UpdateGrenadeAvatar = function(self)
                        -- [Beysa] Only process local player grenades
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
                -- [Beysa] Skip BeginInitialize and ResetGrenadeAvatar hooks (they fire for every player's grenades)
                -- [Beysa] Timer-based applyGrenadeSkinsToController will re-apply periodically
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
            if ok then _G.PatronPubgBeysaNotiff("weapon PC: " .. table.concat(skinList, ",")) end
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
            if (now - _lastBuildSkinMappings) < 0.5 then return end  -- [Beysa] throttle: max twice per second
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
            -- [Beysa] Fast path: prefer using weapon cache directly
            local cch = cache()
            local wid = maxIt > 0 and maxIt or currentGunId
            local w = cch.weapons[wid]
            if w and w.resID and w.resID > 0 then return w.resID end
            -- [Beysa] Try type ID lookup
            local typeId = resolveWeaponTypeID(wid)
            if typeId ~= wid then
                local w2 = cch.weapons[typeId]
                if w2 and w2.resID and w2.resID > 0 then return w2.resID end
            end
            -- [Beysa] Cache with short TTL
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
                skinAttachments  = {},  -- [Beysa] weaponSkinId -> { partSkinId1, partSkinId2, ... }
                skinBases        = {},  -- [Beysa] weaponSkinId -> { baseId1, baseId2, ... }
                attachToSkin     = {},  -- [Beysa] partSkinId   -> { weaponSkinId, baseId }
                skinToBaseWeapon = {},  -- [Beysa] weaponSkinId -> baseWeaponID
            }
            if not CDataTable or not CDataTable.GetTable then return _attachMaps end

            -- [Beysa] 1) GroupID -> [PartIds] from ItemUpgradeUnLockConfig
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

            -- [Beysa] 2) weaponSkinId -> GroupID + skinToBaseWeapon from ItemUpgradeConfig
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

            -- [Beysa] 3) Base name -> [ids] index from Item table (vanilla attachments only)
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

            -- [Beysa] 4) For each weapon skin, resolve its attachments' base IDs
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

            -- [Beysa] If selected skin has no attachments in the map, revert any
            -- [Beysa] part-skins found on attachment slots back to their base IDs.
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

            -- [Beysa] Build a set of valid attachment skin IDs for this weapon skin
            local validSkinIds = {}
            for _, id in ipairs(attachments) do
                validSkinIds[tonumber(id) or 0] = true
            end

            -- [Beysa] Normal case: for each attachment slot, find the matching
            -- [Beysa] attachment skin by baseId and swap to the selected skin's version.
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
                            -- [Beysa] Protection: if current attachment is already the correct skin, skip
                            if validSkinIds[curID] then
                                -- [Beysa] Already the correct skinned attachment, don't change
                            else
                                local baseId = 0
                                local rIt = maps.attachToSkin[curID]
                                if rIt then
                                    baseId = rIt[2]
                                elseif curID < 10000000 then
                                    baseId = curID
                                else
                                    -- [Beysa] Unknown skinned attachment from different skin, skip
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

            -- [Beysa] slot 7 (attachments)
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
            -- [Beysa] Delayed re-application of attachment skins to ensure attachments
            -- [Beysa] are updated after the weapon finishes loading its default attachments.
            -- [Beysa] This fixes the issue where attachments don't update until you swap them.
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
            _G.PatronPubgBeysaNotiff("Taking notes " .. addedCount .. "Weapon Housing")
            return true
        end

        local _lastMatchApplyWeapon = 0
        local function matchApplyWeaponSkin(char)
            local now = 0
            pcall(function() now = os.clock() end)
            if (now - _lastMatchApplyWeapon) < 0.5 then return false end  -- [Beysa] throttle: max 2.5x/sec
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
                _G.PatronPubgBeysaNotiff("matchApplyWeaponSkin: " .. tostring(desiredSkin))
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
                -- [Beysa] Try setting InitialConsumableAvatar fields (works if Lua table reference)
                if pc.InitialConsumableAvatar then
                    for st, info in pairs(cch.throwObjects) do
                        local key = _K.THROW_AVATAR_KEY[_K.THROW_SUB[st]]
                        if key and info.resID and info.resID > 0 then
                            pc.InitialConsumableAvatar[key] = info.resID
                            -- [Beysa] log suppressed
                        end
                    end
                end
                -- [Beysa] Rebuild grenade avatar list from InitialConsumableAvatar
                if pc.InitGrenadeAvatarList then
                    pc:InitGrenadeAvatarList(false)
                end
                -- [Beysa] Fallback: directly add to GrenadeAvatarItemList (overwrites server entries)
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

        -- [Beysa]startMatchWatcher
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
        -- [Beysa]AdditionalData hook
        -- [Beysa] GetWeaponAvatarRes
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
                        -- [Beysa] Cache with invalidation every ~5 seconds via frame count
                        local cached = _bpAvatarResCache[WeaponID]
                        local age = _bpResCacheAge
                        local nowTick = _S.globalFrame or 0
                        if cached and (nowTick - (_bpAvatarResTicks[WeaponID] or 0)) < 150 then
                            return cached, ""
                        end
                        local targetSkinID = 0
                        -- [Beysa] 1) map directly from cache weapons
                        local cch = cache()
                        local typeId = resolveWeaponTypeID(WeaponID)
                        local w = cch.weapons[typeId] or cch.weapons[WeaponID]
                        if w and w.resID and w.resID > 0 then
                            targetSkinID = w.resID
                        end
                        -- [Beysa] 2) fallback to get_skin_id
                        if targetSkinID <= 0 or targetSkinID == WeaponID then
                            local sid = get_skin_id(WeaponID, WeaponID)
                            targetSkinID = tonumber(sid) or 0
                        end
                        -- [Beysa] Cache result
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

            -- [Beysa]itemSubType Item
            local vehicleSubType = 0
            local defaultItemCfg = cfg(defaultAvatarID)
            if defaultItemCfg then
                vehicleSubType = tonumber(defaultItemCfg.ItemSubType or defaultItemCfg.itemSubType) or 0
            end

            -- [Beysa]VehicleSlotList
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

        -- [Beysa] (Chassis Light)
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
                _G.PatronPubgBeysaNotiff("bootstrapMatch")
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
                            -- [Beysa] Extra delayed pass for attachment skins
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
                -- [Beysa] Extra delayed pass for attachment skins
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

        -- [Beysa] Collection Ace Eliminator Broadcast (619150001)
        local ELIMINATION_KING_EFFECT_ID = 619150001
        -- [Beysa] Last Strike Champion Final Kill Effect (61950002)
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

        -- [Beysa] Last Strike Champion Final Kill Effect (61950002)
        local function hookFinalKillEffect()
            if _G._lava_hooked_final_kill then return end
            _G._lava_hooked_final_kill = true

            -- [Beysa] Hook FinalKillEffectLevelSequenceActor to handle missing config for 61950002
            -- [Beysa] If config doesn't exist or Sequence is empty, directly call OnPlay callback
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

            -- [Beysa] Hook TriggerParticleEffect to force ItemId = 61950002
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

            -- [Beysa] Direct client-side trigger when game ends
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

            -- [Beysa] Hook BattleResult.on_game_result (global function, client-side)
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

            -- [Beysa] Hook BattleResult.on_game_over (global function, client-side)
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

            -- [Beysa] Also register for the event as backup (with nil checks)
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
            log("AddOutfit PatronPubgBeysa start")
            -- [Beysa] Security bypass first
            -- [Beysa] Kill message system
            installTeamBroadcastHooks()
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

        -- [Beysa] Time-based application loop (replaces frame-based tick listener)
        -- [Beysa] Uses os.clock() for time tracking instead of frame counting
        local _lastTickTime = os.clock()
        local _timeCount = 0

        -- [Beysa] Periodic application functions with different rates
        local function fastApplyLoop()
            pcall(function()
                _timeCount = _timeCount + 1
                _S.globalFrame = _timeCount
                -- [Beysa] Refresh kill counter UI periodically
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
            pcall(function()
                -- [Beysa] Character boot check at medium rate
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

        -- [Beysa] Start all loops
        if _ticker and _ticker.AddTimerOnce then
            _ticker.AddTimerOnce(0.5, fastApplyLoop)
            _ticker.AddTimerOnce(1.0, mediumLoop)
            _ticker.AddTimerOnce(2.0, slowLoop)
        end

        -- [Beysa] Game status change detection via polling (cheaper than hooking events)
        local _lastGameStatus = ""
        local function statusPollLoop()
            local currentStatus = ""
            if isInLobby() then currentStatus = "lobby"
            elseif isInGamePlay() then currentStatus = "gameplay"
            else currentStatus = "other" end

            if currentStatus ~= _lastGameStatus then
                _lastGameStatus = currentStatus
                -- [Beysa] Status changed, run post-switch logic
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

        end -- [Beysa] initHooks

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

        log("AddOutfit Merged loaded")
        _G.PatronPubgBeysaNotiff("By PatronPubgBeysa")
    end)
    if not _ao_ok then
        print("[AddOutfit] LOAD ERROR:", tostring(_ao_err))
        _G.PatronPubgBeysaNotiff("[AddOutfit] LOAD ERROR")
    end
--end
--bitis










local noop = function() return true end
local retFalse = function() return false end
local retZero = function() return 0 end
local retEmpty = function() return {} end
local retTrue = function() return true end
local retEmptyString = function() return "" end
local safe_require = function(path) local ok, mod = pcall(require, path); return ok and mod or nil end
local isValid = slua.isValid

-- modulePatches (full table from TrnDravix)
local modulePatches = {
    ["GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent"] = {
        methods = {
            ControlMHActive = noop, Tick = noop, OnTick = noop, ReceiveTick = noop, MHActiveLogic = noop,
            TriggerAvatarCheck = noop, StartAvatarCheck = noop, ReportItemID = noop, OnReportItemID = noop,
            ReceiveAnyDamage = noop, OnWeaponHitRecord = noop, ShowSecurityAlert = noop, StaticShowSecurityAlertInDev = noop,
            SendHisarData = noop, OnLogin = noop, ValidateSecurityData = noop, CheckMemoryIntegrity = noop,
            ReportAbnormalMemory = noop, OnMemoryScanComplete = noop, SendDetectionResult = noop, TriggerClientScan = noop,
            SendAntiDataFlow = noop, SendHitFireBtnFlow = noop, SkipAlertServer = function() end,
            CheckWeaponIntegrity = retTrue, CheckAvatarIntegrity = retTrue, CheckBulletIntegrity = retTrue,
            OnGameModeType = noop,
        },
        fields = { bMHActive = false, mHActive = 0 },
        retvals = { GetNetAvatarItemIDs = retEmpty, GetCurWeaponSkinID = retZero, GetDetectionResult = retEmpty },
        custom = function(m)
            if m.__inner_impl then
                local i = m.__inner_impl
                i.SendAntiDataFlow = noop; i.SendHitFireBtnFlow = noop; i.OnBattleResult = noop; i.SendHisarData = noop
            end
            if m.BlackList then for k in pairs(m.BlackList) do m.BlackList[k] = nil end end
            if m.SkipAlertServer then pcall(m.SkipAlertServer, m) end
        end,
    },
    ["GameLua.Mod.BaseMod.Common.Security.SafetyDetectionSubsystem"] = {
        methods = { DetectAbnormal = noop, ReportAbnormal = noop, OnDetectionResult = noop, TriggerSafetyScan = noop },
        retvals = { GetScanResults = retEmpty, IsAnomalyDetected = retFalse },
    },
    _G_AvatarCheckCallback = {
        table = "_G.AvatarCheckCallback",
        methods = {
            StartAvatarCheck = noop, OnReportItemID = noop,
            PostPlayerControllerLoginInit = function(pc)
                pcall(function()
                    if pc and pc.HiggsBosonComponent then
                        pc.HiggsBosonComponent:ControlMHActive(0)
                        pc.HiggsBosonComponent.bMHActive = false
                    end
                end)
            end
        }
    },
    ["GameLua.Mod.BaseMod.Common.Security.PakIntegrityChecker"] = {
        methods = { ShowPakMismatchAlert = noop },
        retvals = { Verify = retFalse, CheckPakFile = retZero, GetPakStatus = retZero }
    },
    ["client.slua.logic.pak.logic_pak_verify"] = {
        retvals = { Verify = retFalse, CheckPakFile = retZero, GetPakStatus = retZero }
    },
    _G_STExtra = {
        table = "_G.STExtraBlueprintFunctionLibrary",
        retvals = { CheckFileIntegrity = retFalse, VerifySignature = retFalse, CheckGameLuaIntegrity = retFalse }
    },
    _G_TssSDK = {
        table = "_G.TssSDK",
        methods = {
            ReportData = noop, SendToServer = noop, SetUserInfo = noop,
            Init = noop, Start = noop, Verify = retTrue, CheckIntegrity = retTrue, Check = retTrue,
        },
        retvals = { GetSignature = function() return "BYPASSED" end }
    },
    _G_TssSDKHelper = { table = "_G.TssSDKHelper", methods = { ReportData = noop } },
    _G_Bugly = { table = "_G.Bugly", methods = { ReportException = noop, SetCustomData = noop } },
    _G_Beacon = { table = "_G.Beacon", methods = { Report = noop } },
    _G_CrashSight = { table = "_G.CrashSight", methods = { ReportException = noop, SetCustomData = noop, Log = noop } },
    ["GameLua.Mod.BaseMod.Common.Security.SecurityNotifyPCFeature"] = {
        methods = {
            ClientRPC_SyncBanID = noop, ClientRPC_StrongTips = noop, ClientRPC_NormalTips = noop, Notify = noop,
            ClientRPC_NotifyBan = noop, ClientRPC_NotifyPunish = noop, ClientRPC_NotifyIllegalProgram = noop
        },
        custom = function(m) if m.__inner_impl then m.__inner_impl.SyncBanInfo = noop end end,
    },
    ["client.slua.logic.ban.ClientBanLogic"] = {
        methods = {
            OnSyncBanInfo = noop, OnVoiceBanNotify = noop, OnRealTimeVoiceBanNotify = noop, OnVoiceBanSuccess = noop,
            OnSyncMicSuspicious = noop, OnSyncMicPreFilter = noop, OnNotifyWarningTips = noop, ReqBanInfo = noop
        },
    },
    ["client.slua.logic.ban.BanTipsLogic"] = {
        methods = { ShowBanTips = noop, ShowPunishTips = noop, ShowWarningTips = noop, OnReceiveBanNotice = noop }
    },
    _G_ban_util = { table = "_G.ban_util", retvals = { CheckBanStatus = retFalse, GetBanTime = retZero, IsBanForever = retFalse } },
    _G_logic_tt_ban = {
        table = "_G.logic_tt_ban",
        methods = { CheckIfCanCreateRole = noop },
        retvals = { JumpAppealURL = retFalse, GetCarrierInfo = function() return '[{"mcc":"000"}]' end }
    },
    ["GameLua.Mod.BaseMod.Client.Security.ClientHawkEyePatrolSubsystem"] = {
        methods = {
            _OnHawkSync = noop, _OnHawkReportSuccess = noop, _StartExitGameTimer = noop,
            _OnRecvInspectorBroadcastCount = noop, SendReportTLog = noop, ReportCheat = noop,
            _OnHawkFlag = noop, ReportPlayerFlag = noop, RequestFlagPlayer = noop, SendFlagReport = noop,
            RequestImprison = noop, IsDuringHawkEyePatrol = retFalse, HasReported = retTrue,
            _InitHawkEyePatrolSubsystem = noop, _CollectBeWatchedPlayerInfo = noop, ServerRPC_HawkReportCheat = noop,
        },
        retvals = { CanInspectorBroadcast = retFalse },
        custom = function(mod)
            if mod.__inner_impl then
                local i = mod.__inner_impl
                i._OnHawkSync = noop; i._OnHawkReportSuccess = noop; i.TryShowReportedTips = noop
            end
        end,
    },
    ["GameLua.Mod.BaseMod.Client.Security.HawkEyeSpectate.ClientHawkEyePatrolSubsystem"] = {
        custom = function(mod)
            if mod.__inner_impl then
                local i = mod.__inner_impl
                i._OnHawkSync = noop; i._OnHawkReportSuccess = noop; i.TryShowReportedTips = noop
            end
        end,
    },
    ["GameLua.Mod.BaseMod.Common.Subsystem.DataLayerSubsystem"] = {
        custom = function(m)
            if m.OnSpectatorReplayChanged then
                local o = m.OnSpectatorReplayChanged
                m.OnSpectatorReplayChanged = function(...)
                    _G.IsBeingWatched = true
                    return o(...)
                end
            end
        end,
    },
    _G_ServerDataMgr = {
        table = "_G.ServerDataMgr",
        custom = function(m)
            if m.DeletablePlayerResultKey then
                for _, k in ipairs({
                    "SuspiciousHitCount", "EspTotalSimTraceCnt", "EspTotalImeFocusCnt",
                    "ClientGravityAnomalyCount", "FireCount", "SpeedCheatCount", "JumpCount", "VehicleSpeedHackCount",
                    "HeadshotCount", "KillCount", "Accuracy", "FlagCount", "TotalFlags", "IsFlagged",
                    "FlaggedByHawkEye", "FlaggedByInspection", "FlagTimestamp", "FlagLevel", "FlagSeverity",
                }) do m.DeletablePlayerResultKey[k] = true end
            end
            if m.FlagCount then m.FlagCount = 0 end
            if m.TotalFlags then m.TotalFlags = 0 end
            if m.IsFlagged then m.IsFlagged = false end
            if m.FlaggedByHawkEye then m.FlaggedByHawkEye = false end
            if m.FlaggedByInspection then m.FlaggedByInspection = false end
            if m.FlagTimestamp then m.FlagTimestamp = 0 end
            if m.FlagLevel then m.FlagLevel = 0 end
            if m.FlagSeverity then m.FlagSeverity = 0 end
        end
    },
    ["client.slua.logic.report.ToolReportUtil"] = {
        retvals = { IsReleaseVersion = retFalse, IsWhite = retFalse, GetReportSwitch = retFalse }
    },
    _G_ClientToolsReport = { table = "_G.ClientToolsReport", methods = { SendReport = noop, SendException = noop } },
    _G_ReportPlatformCrashKit = { table = "_G.ReportPlatformCrashKit", methods = { Send = noop, ForceSend = noop } },
    ["GameLua.Mod.BaseMod.Client.Security.ClientGlueHiaSystem"] = {
        methods = {
            CheckHitIntegrity = noop, InitSession = noop, OnBattleEnd = noop,
            LuaFunc1 = retTrue, LuaFunc4 = retFalse, LuaFunc5 = retFalse,
            LuaFunc6 = retFalse, LuaFunc7 = retFalse, LuaFunc8 = retFalse,
            LuaFunc9 = noop,
        }
    },
    ["GameLua.Mod.Escape.Gameplay.Subsystem.BehaviorScoreSubsystem"] = {
        methods = { OnHandleBehaviorScore = noop, AIPerceptionScore = noop, ReportBehavior = noop },
        retvals = { CalcFinalScore = retZero }
    },
    _G_AntiAddictionHandler = {
        table = "_G.AntiaddctionHandler",
        methods = { send_anti_addiction_req = noop, send_anti_addiction_notify = noop, on_check_nonage_anti_work = noop }
    },
    _G_AccessRestrictionHandler = {
        table = "_G.AccessRestrictionHandler",
        methods = { send_access_restriction_req = noop, send_access_restriction_notify = noop, on_player_cheat_state_notify = noop }
    },
    _G_GodzillaBanHandler = {
        table = "_G.GodzillaBanHandler",
        methods = { send_godzilla_ban_req = noop, send_godzilla_unban_req = noop }
    },
    _G_logic_deleteaccount = {
        table = "_G.logic_deleteaccount",
        retvals = { ForceDeleteAccount = retFalse },
        methods = { OnReceiveDeleteNotify = noop }
    },
    _G_compliance_util = { table = "_G.compliance_util", methods = { CheckCompliance = noop } },
    ["GameLua.Mod.BaseMod.Client.Security.ClientReportPlayerSubsystem"] = {
        methods = {
            OnInit = noop, _OnPlayerKilledOtherPlayer = noop, _RecordFatalDamager = noop,
            _OnDeathReplayDataWhenFatalDamaged = noop, _RecordMurdererFromDeathReplayData = noop,
            _RecordTeammatePlayerInfo = noop, _OnBattleResult = noop, _OnShowQuickReportMutualExclusiveUI = noop,
            GetFatalDamagerMap = retEmpty, GetCachedTeammateName2InfoMap = retEmpty,
            GetTeammateName2InfoMapDuringBattle = retEmpty, GetCurrentNotInTeamHistoricalTeammateMap = retEmpty,
            GetInTeamIndexFromHistoricalTeammateInfo = function() return -1 end,
            ReportSuspiciousPlayer = noop, SubmitReport = noop, ProcessReport = noop,
            ClientRPC_SyncFatalDamagerMap = noop,
        },
        custom = function(m)
            if m.__inner_impl then
                m.__inner_impl._OnSyncFatalDamage = noop
                m.__inner_impl._OnPlayerKilledOtherPlayer = noop
                m.__inner_impl._SyncBattleResult = noop
            end
        end,
    },
    ["GameLua.Mod.BaseMod.Common.Security.DSReportPlayerSubsystem"] = {
        methods = {
            OnInit = noop, _OnNearDeathOrRescued = noop, _OnCharacterDied = noop, _OnTeammateDamage = noop,
            _OnPlayerSettlementStart = noop, _AddKnockDownerToBattleResult = noop, _AddKillerToBattleResult = noop,
            _AddTeammateMurderToBattleResult = noop, _AddFatalDamagerMapToBattleResult = noop,
            _AddMLKillerUIDToBattleResult = noop, _SaveHistoricalTeammateInfo = noop, _RecordFatalDamager = noop,
            _RecordTeammateMurderer = noop,
            _AddEnemyMapToBattleResult = noop, _AddTeammateMapToBattleResult = noop, _SubmitAbnormalData = noop,
            _tUID2InfoMap = retEmpty, ds2history = retEmpty,
        },
    },
    ["GameLua.Mod.BaseMod.Common.Security.ReportPlayerUtils"] = {
        retvals = { GetBotType = retZero, IsCharacterDeliverAI = retFalse },
        methods = { RecordFatalDamager = noop, IsUsingHistoricalTeammateInfo = retFalse },
    },
    ["GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils"] = {
        methods = { ExtractPlayerBasicInfo = retEmpty, LogIf = retFalse },
        custom = function(m)
            if m.EStrategyTypeInReplay then
                m.EStrategyTypeInReplay.EspTotalSimTraceCnt = 0
                m.EStrategyTypeInReplay.EspTotalImeFocusCnt = 0
                m.EStrategyTypeInReplay.ClientGravityAnomalyCount = 0
                m.EStrategyTypeInReplay.FlyingErrorCnt = 0
            end
        end,
    },
    ["GameLua.Mod.BaseMod.Client.Security.ClientQuickReportMaliciousTeammate"] = {
        methods = { OnShowMutualExclusiveUI = noop, OnHideMutualExclusiveUI = noop,
            MaliciousTeammateReceiveWarningTips = noop, MaliciousTeammateVictimReceiveTips = noop },
    },
    _G_ClientTlogHandler = { table = "_G.ClientTlogHandler", methods = { send_report_lobby_common_tlog = noop } },
    _G_LoginAndWinTlogHandler = { table = "_G.LoginAndWinTlogHandler", methods = { on_cloud_game_event_notify = noop } },
    _G_tlog_report_utils = { table = "_G.tlog_report_utils", methods = { ReportTLogEvent = noop, ReportImmediate = noop } },
    _G_BasicDataTLogReport = {
        table = "_G.BasicDataTLogReport",
        methods = { OnSendBatchReqMsg = noop, OnImmediateReqMsg = noop, OnMergeReqMsg = noop, send_report_event_duration_log = noop, SendTlog = noop, ReportEvent = noop },
        retvals = { _GetParamData = retEmpty }
    },
    _G_BasicDataClientReport = {
        table = "_G.BasicDataClientReport",
        methods = { ReportImmediate = noop, ReportDelay = noop, OnSendBatchReqMsg = noop, OnImmediateReqMsg = noop, OnMergeReqMsg = noop },
        retvals = { _IsCanReport = retFalse }
    },
    _G_BasicDataReport = {
        table = "_G.BasicDataReport",
        methods = { ReportImmediate = noop, ReportDelay = noop, OnMergeReqMsg = noop, OnImmediateReqMsg = noop, OnSendBatchReqMsg = noop, _BatchReqMsg = noop }
    },
  --  _G_puffer_tlog = { table = "_G.puffer_tlog", methods = { report_download_tlog = noop } },
    ["GameLua.Mod.BaseMod.DS.Security.ICTLogSubsystem"] = { methods = { SendICExceptionTLog = noop } },
    ["GameLua.Mod.BaseMod.DS.Security.DSFightTLogSubsystem"] = {
        methods = { ReportFightData = noop, ReportPlayerWeapon = noop },
        retvals = { GetSimpleFightData = retEmpty }
    },
    ["GameLua.Mod.BaseMod.DS.Security.DSSecurityTLogSubsystem"] = {
        methods = {
            _OnReportServerJumpFlow = noop, _OnReportTeleportFlow = noop, _OnReportSpeedHackFlow = noop,
            ReportServerJumpFlow = noop, CollectJumpData = noop,
        },
    },
    ["GameLua.Mod.BaseMod.DS.Security.DSCommonTLogSubsystem"] = { methods = { HandleKillTlog = noop } },
    _G_ClientErrorReportHandler = {
        table = "_G.ClientErrorReportHandler",
        methods = { send_client_error_report = noop, send_client_crash_report = noop, send_client_tools_batch_report_req = noop }
    },
    _G_BattleReportHandler = {
        table = "_G.BattleReportHandler",
        methods = {
            send_battle_report = noop, send_battle_result = noop, send_vod_game_report_req = noop,
            send_batch_get_vod_info_req = noop, send_get_game_report_req = noop, send_batch_get_game_report_req = noop,
            send_get_game_report_by_uid_req = noop
        }
    },
    _G_BugHandler = { table = "_G.BugHandler", methods = { send_report_bug_info = noop, send_report_bug_feedback = noop } },
    _G_LobbyPingReportHandler = { table = "_G.LobbyPingReportHandler", methods = { send_lobby_ping_report = noop, send_ingame_ping_report = noop } },
    _G_WeekRportHandler = { table = "_G.WeekRportHandler", methods = { send_week_report = noop, send_week_detail = noop } },
    _G_logic_complaint = {
        table = "_G.logic_complaint",
        methods = { SendComplaintReq = noop, Submit = noop, ReportPlayer = noop, ShowComplaint = noop, ShowHandle = noop }
    },
    ["GameLua.Mod.BaseMod.Client.BattleResult.ProcessBase.EscapeBattleResultShowOBResultLogic"] = {
        methods = { OnBattleResult = noop, OnResultProcessStart = noop }
    },
    ["GameLua.Mod.BaseMod.Client.BattleResult.ProcessBase.BattleResultShowOBResultLogic"] = {
        methods = { OnBattleResult = noop, OnResultProcessStart = noop }
    },
    ["GameLua.Mod.BaseMod.Client.BattleResult.ProcessBase.BattleResultShowResultLogic"] = {
        methods = {
            OnBattleResult = noop, OnResultProcessStart = noop, OnResultProcessContinue = noop,
            ReceiveData = noop, SendEndFlow = noop, OnReport = noop, ShowResult = noop, ShowResultInternal = noop,
            StopResultProcess = noop
        }
    },
    _G_EmulatorHandler = { table = "_G.EmulatorHandler", methods = { send_emulator_info = noop } },
    _G_emulator_scanner = {
        table = "_G.emulator_scanner",
        methods = { StartScan = noop, ReportScanResult = noop },
        retvals = { GetScanResult = retFalse }
    },
    _G_LoginVerifyHandler = { table = "_G.LoginVerifyHandler", methods = { send_login_verify_req = noop, send_device_verify_req = noop } },
    _G_logic_ds_monitor = { table = "_G.logic_ds_monitor", methods = { OnRecordMsg = noop, OnReportMsg = noop } },
    ["GameLua.Mod.BaseMod.Client.Security.ClientDataStatistcsSubsystem"] = {
        methods = { StartToCheck = noop, OnReceiveRTT = noop, OnReceiveJitter = noop, ReportAbnormal = noop, ResetData = noop }
    },
    ["GameLua.Dev.Subsystem.ShootVerifySubSystemClient"] = { methods = { OnShootVerifyFailed = noop, SendVerifyData = noop } },
    ["GameLua.Mod.BaseMod.DS.Security.HighlightMomentSubsystem_DSChecker"] = { methods = { CheckFuncUpgradedWeaponKill = noop } },
    _G_logic_chat_voice_report = { table = "_G.logic_chat_voice_report", methods = { ReportVoiceData = noop, ReportVoiceText = noop } },
    _G_logic_chat_voice_doctor = { table = "_G.logic_chat_voice_doctor", methods = { UploadVoiceLog = noop, UploadVoiceException = noop } },
    _G_logic_home_audit_state = { table = "_G.logic_home_audit_state", methods = { SendAuditState = noop, ReportAuditResult = noop } },
    _G_logic_home_report = { table = "_G.logic_home_report", methods = { ReportHomeData = noop, ReportHomeVisitor = noop, ShowInGameReportUI = noop, SendReport = noop } },
    _G_gem_report_utils = {
        table = "_G.gem_report_utils",
        methods = { ReportGemData = noop, ReportGemPurchase = noop, ReportEventImmediate = noop },
    },
    _G_ChatHandler = { table = "_G.ChatHandler", methods = { send_report_info = noop, send_report_info_mic = noop } },
    _G_ClientReplayDataReporter = { table = "_G.ClientReplayDataReporter", methods = { ReportIntArrayData = noop, ReportFloatArrayData = noop, ReportUInt8ArrayData = noop } },
    ["GameLua.ExtraModule.MLAI.Client.AIReplaySubsystem"] = {
        custom = function(m)
            if m.uCompletePlayBack then
                m.uCompletePlayBack.AddRecordMLAIInfo = noop
                m.uCompletePlayBack.StopRecording = noop
            end
            if m.ReportAllPlayerInfo then m.ReportAllPlayerInfo = noop end
            if m.ReportFrameData then m.ReportFrameData = noop end
            if m.ReportPlayerInput then m.ReportPlayerInput = noop end
        end,
    },
    _G_GameSafeCallbacks = {
        table = "_G.GameSafeCallbacks",
        methods = {
            PostPlayerControllerLoginInit = noop, OnDSGlueHiaInit = noop, CharacterReceiveBeginPlay = noop,
            DoAttackFlowStrategy = noop, RecordStrategyTimestampInReplay = noop, EditorIncreaseTotalStatisticCnt = noop
        },
        retvals = { GetScriptReportContent = function() return "" end }
    },
    ["GameLua.Mod.BaseMod.GamePlay.GameReport.GameReportUtils"] = {
        methods = { ReportException = noop, ReplayReportData = noop, ReportGameException = noop },
        retvals = { BugglyPostExceptionFull = retFalse, CheckCanBugglyPostException = retFalse }
    },
    _G_NetUtil = { table = "_G.NetUtil", methods = { SendTss = noop, SendToServer = noop, SendToDS = noop } },
    ["UnrealNet"] = {
        global = true,
        custom = function(m)
            if not m then return end
            if m.FilterNetworkException then
                local o = m.FilterNetworkException
                m.FilterNetworkException = function(et, em)
                    if em and type(em) == "string" then
                        local le = em:lower()
                        if le:find("cheatdetected") or le:find("idipban") or le:find("dataerror") or le:find("datamismatch")
                           or le:find("security") or le:find("integrity") or le:find("hashfail") or le:find("flag") then
                            return false
                        end
                    end
                    return o(et, em)
                end
            end
            m.HandleNetworkExceptionReport = noop
            m.HandleNetworkConnectionClosed = noop
            m.HandleSpectateException = noop
        end
    },
    ["GameLua.Mod.BaseMod.Client.Security.Gokuba"] = {
        custom = function(m)
            if m.ForwardFeature then
                m.ForwardFeature = function() return {0, 0, 0, 0, 0} end
            end
            if m.TimerHandle then
                pcall(function()
                    local time_ticker = require("common.time_ticker")
                    time_ticker.RemoveTimer(m.TimerHandle)
                end)
                m.TimerHandle = nil
            end
        end
    },
    ["GameLua.Mod.BaseMod.Common.Security.CoronaUploader"] = { methods = { Upload = noop, Flush = noop } },
    ["GameLua.Mod.BaseMod.Client.Login.LoginLock"] = { methods = { Lock = noop, OnLoginBan = noop }, retvals = { CheckBan = retFalse } },
    ["GameLua.Mod.BaseMod.GamePlay.Battle.BattleResultUploader"] = { methods = { Upload = noop } },
    ["client.slua.logic.ClientAppStat"] = { methods = { Report = noop, Flush = noop } },
    ["GameLua.Mod.BaseMod.Client.Security.DeviceFingerprint"] = {
        methods = { Collect = noop, Sync = noop, GetHash = function() return "unknown" end }
    },
    ["GameLua.Mod.BaseMod.DS.Security.DSDeviceCheck"] = { methods = { VerifyClientDevice = retTrue, ReportMismatch = noop } },
    ["GameLua.Mod.BaseMod.Common.Security.IntegrityCheck"] = { methods = { Run = noop, Verify = retTrue } },
    ["GameLua.Mod.BaseMod.Common.Security.APKIntegrity"] = { methods = { CheckSignature = retTrue, CheckInstallSource = retTrue } },
    ["GameLua.Mod.BaseMod.Common.Security.LibCheck"] = {
        methods = { Verify = retTrue, Check = retTrue, Scan = noop, Report = noop },
        retvals = { IsLibValid = retTrue, GetTamperedLibs = retEmpty }
    },
    _G_TDataMaster = {
        table = "_G.TDataMaster",
        methods = { Report = noop, ReportDeviceInfo = noop, SendHardwareHash = noop, CollectTelemetry = noop, SendData = noop, Sync = noop, Flush = noop },
        custom = function(m)
            if m then for k, v in pairs(m) do if type(v) == "function" then m[k] = noop end end end
        end,
    },
    _G_DeviceInfo = {
        table = "_G.DeviceInfo",
        methods = { GetDeviceID = function() return "unknown" end, GetIMEI = function() return "000000000000000" end, CollectSysInfo = noop }
    },
    ["client.slua.logic.platform.platform_db"] = { methods = { Scan = noop, CheckIntegrity = retFalse, ReportCorruption = noop } },
    ["xunyou_cache_scan"] = { methods = { StartScan = noop, GetResult = retEmpty } },
    _G_SecurityTlogQueue = { table = "_G.SecurityTlogQueue", methods = { Flush = noop, Add = noop } },
    _G_PufferDownloadReport = { table = "_G.PufferDownloadReport", methods = { ReportDownload = noop, ReportError = noop } },
    _G_ReplayRecordSecurity = { table = "_G.ReplayRecordSecurity", methods = { InjectMeta = noop, Validate = noop } },
    _G_GameServerHeartbeat = { table = "_G.GameServerHeartbeat", methods = { ReportMissedBeat = noop, CheckAlive = retTrue } },
    ["GameLua.Mod.BaseMod.Common.Security.AntiDebug"] = { methods = { Check = retFalse, Report = noop } },
    ["GameLua.Mod.BaseMod.Client.Security.SecureBootCheck"] = { methods = { VerifyBoot = retTrue } },
    ["GameLua.Mod.BaseMod.DS.Security.DSPlayerValidCheck"] = { methods = { Validate = retTrue, ReportSuspicious = noop } },
    ["client.slua.logic.common.logic_common_legal_msg"] = {
        custom = function(m)
            if m.ShowOnePopUI then
                local o = m.ShowOnePopUI
                m.ShowOnePopUI = function(self, params)
                    if params and params.title and params.title:find("SECURITY") then return end
                    return o(self, params)
                end
            end
        end,
    },
    ["GameLua.Mod.BaseMod.Client.Security.InspectionSystemReportClientLogicSubsystem"] = {
        methods = {
            AskForInspector = noop, ReportEnemy = noop, KickOutOneTeam = noop,
            OnReceiveInspectCmd = noop, ClientReportData = noop, SendReportToInspector = noop,
            SendKickOutOneTeam = noop, ClientNotifyInspectorImplementation = noop, RecvNotifyInspector = noop,
        },
    },
    ["GameLua.Mod.BaseMod.DS.Security.InspectionSystemReportDSLogicSubsystem"] = {
        methods = {
            ServerKickOutOneTeamByPlayerImplementation = noop, AddReportedCount = noop,
            AddInspectionRecord = noop, BanPlayerByInspection = noop,
            BroadCastToAllInspector = noop, ServerReportToInspectorImplementation = noop,
            InitPlayerInspectionInfo = noop,
        },
        fields = { MAX_ASK_FOR_INSPECTOR_TIME = 0, ASK_FOR_INSPECTOR_INTERVAL = 99999 },
        custom = function(m)
            if m.__inner_impl then
                m.__inner_impl.IsGameModeAllowed = retTrue
            end
        end,
    },
    ["client.slua.logic.CustomerService.LogicSafeStation"] = {
        methods = { UploadVideoEvidence = noop, ReportPlayerBehavior = noop },
    },
    ["client.slua.logic.CustomerService.LogicCustomerService"] = {
        methods = { SendComplaint = noop, SendFeedback = noop },
    },
    ["GameLua.GameCore.Module.Vehicle.VehicleFeatures.TLog.AmphibiousBoatTLogFeature"] = {
        methods = { RecordMovement = noop, StartRecordMovement = noop },
    },
    ["client.logic.data.profile_report_cfg"] = { methods = { SendReport = noop } },
    ["GameLua.Mod.BaseMod.Client.ClientInGameCreditLogic"] = {
        methods = {
            _SendUserReaction2ExitTeamBeforeBoardingReturnLobbyNotice = noop,
            ShowReturnLobbyIfFirstExitTeamBeforeBoarding = retFalse,
            OnReceiveCreditScoreChange = noop,
            _IsFirstExitTeamBeforeBoardingReturnLobbyNoticeEnabled = retFalse,
            SetFirstExitTeamBeforeBoardingReturnLobbyNoticeEnabled = noop,
        },
    },
    ["GameLua.Mod.CreativeBase.Gameplay.Subsystem.CreativeDevDebugSubsystem"] = { methods = { IsDebugPanelEnalbedCli = noop } },
    ["GameLua.Mod.CreativeBase.Gameplay.Subsystem.CreativeModeDeathRecordSubsystem"] = { methods = { OnPlayerKilled = noop } },
    ["GameLua.Mod.BaseMod.DS.Security.AFKReportorSubsystem"] = {
        methods = {
            HandleEnterFighting = noop, InitializePlayerInputInfo = noop,
            AddOneAFKInfo = noop, SetPlayerAFKState = noop,
            ResetPlayerInputInfo = noop, PlayerHaveAction = noop, ReportAFK = noop,
            CheckAFK = retFalse,
        },
    },
    ["GameLua.Mod.TDM.Gameplay.Subsystem.TDMAFKReportorSubsystem"] = { methods = { SendAFKTips = noop, OnHandleLostConnection = noop } },
    ["GameLua.Mod.BaseMod.GamePlay.AI.AITrackingLogSubsystem"] = {
        methods = {
            RealLogoutTimer = noop, AddToLogQue = noop, DoPrint = noop,
            OnAIPawnDied = noop, OnAIPawnReceiveDamage = noop, OnAIPawnEnemyChange = noop,
        },
        fields = { LogQueue = {} },
    },
    ["client.slua.logic.data.data_mgr"] = { retvals = { GetWeaponSkinSoundVolumeInfoByGroup = retZero } },
    ["TApmHelper"] = { methods = { postEvent = noop } },
    ["GameLua.Mod.BaseMod.Common.Security.LuaIntegrityCheck"] = { methods = { Run = noop, Verify = retTrue, Check = retTrue } },
    ["GameLua.Mod.BaseMod.Client.Security.ClientDeviceCheckSubsystem"] = {
        methods = { StartCheck = noop, ReportResult = noop },
        retvals = { IsDeviceSafe = retTrue },
    },
    ["GameLua.Mod.BaseMod.Client.Security.SpectatorAndReplaySubsystem"] = { methods = { SendReport = noop } },
    ["client.slua.logic.login.logic_version_update"] = {
        methods = { CheckVersion = noop, CheckUpdate = noop, IsNeedUpdate = retFalse, GetVersion = function() return "4.4.0" end, ShowUpdateDialog = noop }
    },
    ["client.slua.logic.version.logic_update"] = { methods = { CheckUpdate = noop, ForceUpdate = noop, IsForceUpdate = retFalse } },
    ["client.slua.logic.ban.logic_ban"] = {
        methods = { GetBanEndTime = function() return 0 end, IsInBanTime = retFalse, CheckBanStatus = retFalse, GetBanReason = retEmpty, GetBanTime = retZero }
    },
    ["client.slua.logic.login.logic_login_ban"] = {
        methods = { CheckCanLogin = retTrue, GetBanInfo = function() return { end_time = 0 } end, IsBanned = retFalse, IsSecurityBan = retFalse }
    },
    ["GameLua.Mod.PlanBT.Gameplay.Subsystem.DSActiveSubsystem"] = { methods = { DelayKickOutPlayer = noop, ActiveKickNotify = noop } },
    ["GameLua.Mod.BaseMod.Client.Security.ClientFlagSubsystem"] = {
        methods = {
            EvaluateFlags = noop,
            GetFlagLevel = retZero,
            GetFlagBanDuration = retZero,
            IsFlagged = retFalse,
            ReportFlag = noop,
            SyncFlagStatus = noop,
            IncreaseFlagCount = noop,
            ResetFlags = noop,
        },
        retvals = { IsFlagged = retFalse },
        fields = { FlagCount = 0, FlagLevel = 0, FlagSeverity = 0 },
    },
    ["client.slua.logic.ban.logic_flag_ban"] = {
        methods = {
            GetFlagBanEndTime = function() return 0 end,
            IsFlagBanned = retFalse,
            GetFlagBanDuration = retZero,
            CheckFlagBan = retFalse,
        }
    },
    ["GameLua.Mod.BaseMod.DS.Security.DSAITLogSubsystem"] = {
        methods = { _UpdateTTKRecords = noop, _UpdateOperatingFrequency = noop }
    },
    ["GameLua.Mod.Borderland.Gameplay.Subsystem.TLogSubsystem"] = { methods = { OnInit = noop } },
    _G_TLogSubsystem = { table = "_G.TLogSubsystem", methods = { OnInit = noop } },
    ["client.slua.logic.download.report.logic_mini_pak_gem"] = {
        methods = { StartReport = noop, ReportGemLog = noop, SetCurDownloadSize = noop }
    },
    ["GameLua.Mod.BaseMod.Client.ClientTLog.ClientTLogManager"] = {
        methods = {
            OnReceiveBattleResults = noop,
            AddValTLog = noop,
            SetValTLog = noop,
            SendReportLobby = noop,
        },
        fields = { ClientTlogData = {} },
    },
    ["GameLua.Mod.SocialIsland.DS.Battle.RacingAntiCheatLogic"] = {
        methods = {
            StartDetectTimer = noop, StopDetectTimer = noop,
            DetectVehicleFloating = noop, HandleFloatingCheat = noop,
            HandleSpeedCheat = noop, HandlePlayerPassCheckBelt = noop,
        },
    },
    ["GameLua.Dev.ClientCloudGM"] = { methods = { HandleCloudGMCMDStr = noop } },
    ["GameLua.Mod.BaseMod.Client.Dev.ClientCloudGM"] = { methods = { HandleCloudGMCMDStr = noop } },
    ["GameLua.Mod.BaseMod.Common.RealTimeBan.RealTimeBan"] = {
        methods = {
            OnPlayerWithRealTimeBan = noop,
            ShowAlias = noop,
            HandleEnterGameModeFightingState = noop,
            GetTipsID = retZero,
        },
    },
    ["GameLua.Mod.BaseMod.Client.Security.HawkEyeSpectate.HawkEyeDistanceUI"] = {
        methods = { _RefreshUI = noop, _IsShouldShow = retFalse }
    },
    ["GameLua.Mod.BaseMod.Client.Security.HawkEyeSpectate.HawkEyeNextPatrolWindow"] = {
        methods = { OnShow = noop }
    },
    ["GameLua.Mod.BaseMod.Client.Security.HawkEyeSpectate.HawkEyeReportWindow"] = {
        methods = { _OnClickSubmit = noop, _RefreshWindow = noop, RegistEvents = noop }
    },
    ["GameLua.Mod.BaseMod.Client.Security.SecurityClientUtils"] = {
        methods = {
            HasOtherTeammateOffline = retFalse,
            HasOtherHealthyOnlineTeammate = retFalse,
            IsMyHealthStatusHealthy = retTrue,
            IsMyHealthStatusAlive = retTrue,
            GetMyHealthStatus = function() return 1 end,
        }
    },
    ["GameLua.Mod.BaseMod.Client.Ban.ClientBanLogic"] = {
        methods = {
            OnVoiceBanNotify = noop, OnRealTimeVoiceBanNotify = noop,
            OnSyncBanInfo = noop, OnNotifyWarningTips = noop,
            VoiceBanEndTime = 0, bEnableVoiceReport = false,
        },
    },
    ["GameLua.Mod.BaseMod.Client.Security.ClientBanLogic"] = {
        methods = {
            OnVoiceBanNotify = noop, OnRealTimeVoiceBanNotify = noop,
            OnSyncBanInfo = noop, OnNotifyWarningTips = noop,
        },
    },
    ["ScreenshotMaker"] = {
        custom = function(m)
            if not m then return end
            m.MakePicture = function() return "" end
            m.ReMakePicture = function() return "" end
            m.HasCaptured = function() return true end
        end,
    },
    ["client.slua.logic.ugc.UGCNewTLogReport"] = {
        methods = { SendExposeReq = noop, SendInteractionReq = noop, TLogReport = noop }
    },
    ["client.slua.logic.ugc.logic_ugc_tlog"] = {
        methods = { SendModTLog = noop, ReportStay = noop }
    },
    ["GameLua.Mod.BaseMod.Client.ClientTLog.ClientTLogUtil"] = {
        methods = { ReportGeneralCountByBRPhase = noop, ReportCommonTLogDataByBRPhase = noop }
    },
    ["ReportCrashKitFeature"] = {
        custom = function(m) if m and m.ReportCharacterAttachedOnVehicleException then m.ReportCharacterAttachedOnVehicleException = noop end end,
    },
    ["GameLua.Mod.BaseMod.GamePlay.GameReport.GameReportSubsystemReporter"] = {
        custom = function(m)
            if m then
                m.ReportIntArrayData = noop
                m.ReportUInt8ArrayData = noop
                m.ReportFloatArrayData = noop
            end
        end,
    },

    -- ===== New patches from TrnDravix =====
    ["SkillAction_GrenadeThrowReport"] = {
        methods = {
            ReportGrenadeThrow = noop,
            CheckGrenadeAnimationState = retTrue,
            ValidateThrow = retTrue,
            OnGrenadeThrow = noop,
        },
    },
    ["BanMacro"] = {
        methods = {
            DetectInputVariance = retTrue,
            CheckClickTiming = retFalse,
            AnalyzeClickPattern = retEmpty,
            ReportMacro = noop,
            CheckAllBanTypes = retTrue,
        },
    },
    ["NGActionBanSprint"] = {
        methods = {
            ValidateSprintSpeed = retTrue,
            CheckSpeedHack = retFalse,
            ReportSprintViolation = noop,
        },
    },
    ["ReportGrenadeThrow"] = {
        methods = {
            SendGrenadeReport = noop,
            ReportGrenadeData = noop,
        },
    },
    ["InputVarianceChecker"] = {
        methods = {
            CalculateVariance = retZero,
            IsHumanLike = retTrue,
        },
    },
    ["SpeedhackValidator"] = {
        methods = {
            ValidateSpeed = retTrue,
            IsSpeedhack = retFalse,
            ReportSpeedhack = noop,
        },
    },
    ["HawkEyeSpectatorState"] = {
        methods = {
            OnSpectatorStateChange = noop,
            TrackAimMovement = noop,
            ReportSuspiciousAim = noop,
        },
    },
    ["EmulatorSystem"] = {
        fields = { EmulatorTestMark = true },
        methods = { IsEmulator = retFalse, GetEmulatorName = function() return "NoEmulator" end },
    },
    ["logic_emulator"] = {
        methods = { find_emulator = retFalse, IsSpecialEmulator = retFalse },
    },
    ["VoiceReportSubsystem"] = {
        methods = {
            PLAYER_BAN_GLOBAL_MI = noop,
            ReportSuspicious = noop,
            PreFilterAI = noop,
        },
    },
    ["BugglyReportRecord"] = {
        methods = { Report = noop, Record = noop },
        retvals = { GetProbability = retZero },
    },
    ["PatrollerModule"] = {
        methods = { UpdateStats = noop, GetRank = retZero, AddInspectionRecord = noop },
    },
    ["DSQuickReportMaliciousTeammate"] = {
        methods = {
            _HandleCarrybackFallingDamage = noop,
            _HandleGrenadeDamage = noop,
            _HandleVehicleExplosionDamage = noop,
            ReportMaliciousTeammate = noop,
        },
    },
    ["ClientQuickReportMaliciousTeammate"] = {
        methods = {
            RPC_Client_MaliciousTeammateReceiveWarningTips = noop,
            ShowQuickReportDialog = noop,
            OnDeath = noop,
        },
    },
    ["InspectionSystemKickPlayerConfirm"] = {
        methods = {
            OnConfirmTyped = retTrue,
            CheckConfirmText = retTrue,
        },
    },
    ["RockBandActor"] = {
        custom = function(m)
            if m then
                m._G.IsEditor = false
                m._G.IsTesting = false
            end
        end,
    },
    ["ban_reddot_system"] = {
        methods = {
            EnterSafeStation = noop,
            UpdateRedDot = noop,
            OnBanUpdate = noop,
        },
    },
    ["ban_reddot_data"] = {
        methods = {
            LoadBanRedDotData = noop,
            UpdateBanRedDot = noop,
        },
    },
    ["DSPlayerDataReportSubsystem"] = {
        methods = {
            TrackRescue = noop,
            TrackDieWithoutRevive = noop,
            HandleBattleResult = noop,
            _HandleRescue = noop,
            _HandleDieWithoutRevive = noop,
        },
        custom = function(m)
            if m then
                m.DieWithoutReviveTime = 99999
                if m._OnGameEnd then m._OnGameEnd = noop end
            end
        end,
    },
    ["UGC_AiCopilot_Report"] = {
        methods = {
            ReportContent = noop,
            ReportLowQuality = noop,
            SendReport = noop,
        },
    },
    ["gem_report_utils"] = {
        methods = {
            ReportEventDelay = noop,
            ReportImmediate = noop,
        },
    },
    ["gem_report_config"] = {
        methods = {
            OnNetworkEvent = noop,
            OnBanEvent = noop,
        },
    },
    ["net"] = {
        global = true,
        custom = function(m)
            if m then
                m.DumpPropertySerializationStats = noop
            end
        end,
    },
}

-- Hook require/import
local originalRequire = require
local function hookedRequire(name)
    local mod = originalRequire(name)
    if modulePatches[name] then
        local cfg = modulePatches[name]
        if cfg.custom then pcall(cfg.custom, mod)
        elseif not cfg.global then
            if cfg.methods then for k, v in pairs(cfg.methods) do if type(mod[k]) == "function" then mod[k] = v end end end
            if cfg.retvals then for k, v in pairs(cfg.retvals) do if type(mod[k]) == "function" then mod[k] = v end end end
            if cfg.fields then for k, v in pairs(cfg.fields) do if mod[k] ~= nil then mod[k] = v end end end
        end
    end
    return mod
end
if require ~= hookedRequire then require = hookedRequire end

local originalImport = import
local function hookedImport(name)
    local mod = originalImport(name)
    if modulePatches[name] then
        local cfg = modulePatches[name]
        if cfg.custom then pcall(cfg.custom, mod)
        elseif not cfg.global then
            if cfg.methods then for k, v in pairs(cfg.methods) do if type(mod[k]) == "function" then mod[k] = v end end end
            if cfg.retvals then for k, v in pairs(cfg.retvals) do if type(mod[k]) == "function" then mod[k] = v end end end
            if cfg.fields then for k, v in pairs(cfg.fields) do if mod[k] ~= nil then mod[k] = v end end end
        end
    end
    return mod
end
if import ~= hookedImport then import = hookedImport end


local function nop() return end
local function nopstr() return "" end
local function nopfalse() return false end
local function noptrue() return true end
local function nopnil() return nil end
local function retFalse() return false end
local function retTrue() return true end
local function retZero() return 0 end
local function retEmpty() return {} end
local function retEmptyString() return "" end
local function retNil() return nil end
local function retOne() return 1 end
local function retHundred() return 100 end

local function _isValid(obj)
    if type(slua) == "table" and type(slua.isValid) == "function" then
        local ok, res = pcall(slua.isValid, obj)
        return ok and (res == true)
    end
    return obj ~= nil
end

local function _safe_require(path)
    local ok, mod = pcall(require, path)
    return ok and mod or nil
end

local function _killTable(tbl, keys)
    if type(tbl) ~= "table" then return end
    for _, k in ipairs(keys) do
        pcall(function() if tbl[k] ~= nil then tbl[k] = nop end end)
    end
end

local function _gk_ret_true() return true end
local function _gk_ret_false() return false end
local function _gk_ret_zero() return 0 end
local function _gk_ret_empty() return {} end
local function _gk_noop() end

-- ============================================================
-- @hacker420official
-- ============================================================

_G.BypassPermissions = {
    -- @hacker420official
    SecurityBypass = true,
    AntiCheatBypass = true,
    ReportBypass = true,
    BanBypass = true,
    TelemetryBypass = true,
    NetworkBypass = true,
    MD5Bypass = true,
    SignatureBypass = true,
    DNSBypass = true,
    DeviceBypass = true,
    IPBypass = true,
    MACBypass = true,
    IMEIBypass = true,
    AndroidIDBypass = true,
    HWIDBypass = true,
    MemoryBypass = true,
    
    -- @hacker420official
    AllFeaturesEnabled = true,
    NoReports = true,
    NoBan = true,
    NoDetection = true,
    NoTelemetry = true,
    NoCrashReport = true,
    NoAnalytics = true,
    NoMonitor = true,
    NoTrack = true,
    NoScan = true,
    NoVerify = true,
    NoCheck = true,
    NoValidate = true,
    EndGameProtection = true,
    AntiBan = true,
    AntiKick = true,
    AntiSuspend = true,
    AntiFlag = true
}

-- ============================================================
-- Anti-Cheat @hacker420official
-- ============================================================

_G.AntiCheatBlock = {
    -- Anti-Cheat @hacker420official
    BlockAllAntiCheat = true,
    BlockTSS = true,
    BlockACE = true,
    BlockXignCode = true,
    BlockBattlEye = true,
    BlockGokuba = true,
    BlockSwiftHawk = true,
    BlockCoronaLab = true,
    BlockHawkEye = true,
    BlockHiggsBoson = true,
    BlockClientBan = true,
    BlockRealTimeBan = true,
    BlockReportSystem = true,
    BlockTLog = true,
    BlockMD5Check = true,
    BlockSignatureVerify = true,
    BlockDeviceFingerprint = true,
    BlockDNSMonitor = true,
    BlockTelemetry = true,
    BlockAnalytics = true,
    BlockCrashReport = true,
    BlockMemoryScan = true,
    BlockSpeedCheck = true,
    BlockWallCheck = true,
    BlockShootVerify = true,
    BlockModifierException = true,
    BlockSimulateLocation = true,
    BlockPlayerSecurity = true,
    BlockCircleFlow = true,
    BlockMrpcsFlow = true,
    BlockKillFlow = true,
    BlockBehaviorScore = true,
    BlockAFKReport = true,
    BlockAvatarException = true,
    BlockFileCheck = true,
    BlockPakVerify = true,
    BlockIntegrityCheck = true,
    BlockRacingAntiCheat = true,
    BlockClientEntry = true,
    BlockNetworkException = true,
    BlockUnrealNet = true,
    BlockReplay = true,
    BlockScreenshot = true,
    BlockDebugLog = true,
    BlockMemoryDump = true,
    BlockStackTrace = true,
    BlockProfiler = true,
    
    -- Magic Bullet @hacker420official
    BlockMagicBullet = true,
    BlockDamageVerification = true,
    BlockHitboxVerification = true,
    BlockProjectileVerification = true,
    BlockBulletVerification = true,
    BlockShootVerification = true,
    
    -- Skin Mod @hacker420official
    BlockSkinVerification = true,
    BlockAvatarVerification = true,
    BlockWeaponVerification = true,
    BlockVehicleVerification = true,
    BlockSkinReport = true,
    
    -- Game Guardian @hacker420official
    BlockGameGuardian = true,
    BlockCheatEngine = true,
    BlockMemoryEditor = true,
    BlockDebugger = true,
    
    -- Emulator Detection @hacker420official
    BlockEmulator = true,
    BlockVMDetection = true,
    
    -- Tamper Detection @hacker420official
    BlockTamper = true,
    BlockFileIntegrity = true,
    
    -- SpeedHack Detection @hacker420official
    BlockSpeedHack = true,
    BlockTimeScale = true,
    
    -- ESP Detection @hacker420official
    BlockESP = true,
    BlockWallhack = true,
    
    -- NoRecoil Detection @hacker420official
    BlockNoRecoil = true,
    BlockShootPattern = true,
    
    -- Player Report @hacker420official
    BlockPlayerReport = true,
    BlockReportCooldown = true
}

-- ============================================================
-- Anti-Cheat IP @hacker420official
-- ============================================================

_G.BlockedIPs = {
    -- Tencent Anti-Cheat @hacker420official
    "43.128.0.0/16", "43.129.0.0/16", "43.130.0.0/16", "43.131.0.0/16",
    "43.132.0.0/16", "43.133.0.0/16", "43.134.0.0/16", "43.135.0.0/16",
    "43.136.0.0/16", "43.137.0.0/16", "43.138.0.0/16", "43.139.0.0/16",
    "43.140.0.0/16", "43.141.0.0/16", "43.142.0.0/16", "43.143.0.0/16",
    "43.144.0.0/16", "43.145.0.0/16", "43.146.0.0/16", "43.147.0.0/16",
    "43.148.0.0/16", "43.149.0.0/16", "43.150.0.0/16", "43.151.0.0/16",
    "43.152.0.0/16", "43.153.0.0/16", "43.154.0.0/16", "43.155.0.0/16",
    "43.156.0.0/16", "43.157.0.0/16", "43.158.0.0/16", "43.159.0.0/16",
    "43.160.0.0/16", "43.161.0.0/16", "43.162.0.0/16", "43.163.0.0/16",
    "43.164.0.0/16", "43.165.0.0/16", "43.166.0.0/16", "43.167.0.0/16",
    "43.168.0.0/16", "43.169.0.0/16", "43.170.0.0/16", "43.171.0.0/16",
    "43.172.0.0/16", "43.173.0.0/16", "43.174.0.0/16", "43.175.0.0/16",
    "43.176.0.0/16", "43.177.0.0/16", "43.178.0.0/16", "43.179.0.0/16",
    "43.180.0.0/16", "43.181.0.0/16", "43.182.0.0/16", "43.183.0.0/16",
    "43.184.0.0/16", "43.185.0.0/16", "43.186.0.0/16", "43.187.0.0/16",
    "43.188.0.0/16", "43.189.0.0/16", "43.190.0.0/16", "43.191.0.0/16",
    "43.192.0.0/16", "43.193.0.0/16", "43.194.0.0/16", "43.195.0.0/16",
    "43.196.0.0/16", "43.197.0.0/16", "43.198.0.0/16", "43.199.0.0/16",
    "43.200.0.0/16", "43.201.0.0/16", "43.202.0.0/16", "43.203.0.0/16",
    "43.204.0.0/16", "43.205.0.0/16", "43.206.0.0/16", "43.207.0.0/16",
    "43.208.0.0/16", "43.209.0.0/16", "43.210.0.0/16", "43.211.0.0/16",
    "43.212.0.0/16", "43.213.0.0/16", "43.214.0.0/16", "43.215.0.0/16",
    "43.216.0.0/16", "43.217.0.0/16", "43.218.0.0/16", "43.219.0.0/16",
    "43.220.0.0/16", "43.221.0.0/16", "43.222.0.0/16", "43.223.0.0/16",
    "43.224.0.0/16", "43.225.0.0/16", "43.226.0.0/16", "43.227.0.0/16",
    "43.228.0.0/16", "43.229.0.0/16", "43.230.0.0/16", "43.231.0.0/16",
    "43.232.0.0/16", "43.233.0.0/16", "43.234.0.0/16", "43.235.0.0/16",
    "43.236.0.0/16", "43.237.0.0/16", "43.238.0.0/16", "43.239.0.0/16",
    "43.240.0.0/16", "43.241.0.0/16", "43.242.0.0/16", "43.243.0.0/16",
    "43.244.0.0/16", "43.245.0.0/16", "43.246.0.0/16", "43.247.0.0/16",
    "43.248.0.0/16", "43.249.0.0/16", "43.250.0.0/16", "43.251.0.0/16",
    "43.252.0.0/16", "43.253.0.0/16", "43.254.0.0/16", "43.255.0.0/16",
    
    -- Tencent Cloud Anti-Cheat
    "129.204.0.0/16", "129.205.0.0/16", "129.206.0.0/16", "129.207.0.0/16",
    "129.208.0.0/16", "129.209.0.0/16", "129.210.0.0/16", "129.211.0.0/16",
    "129.212.0.0/16", "129.213.0.0/16", "129.214.0.0/16", "129.215.0.0/16",
    "129.216.0.0/16", "129.217.0.0/16", "129.218.0.0/16", "129.219.0.0/16",
    "129.220.0.0/16", "129.221.0.0/16", "129.222.0.0/16", "129.223.0.0/16",
    "129.224.0.0/16", "129.225.0.0/16", "129.226.0.0/16", "129.227.0.0/16",
    "129.228.0.0/16", "129.229.0.0/16", "129.230.0.0/16", "129.231.0.0/16",
    "129.232.0.0/16", "129.233.0.0/16", "129.234.0.0/16", "129.235.0.0/16",
    "129.236.0.0/16", "129.237.0.0/16", "129.238.0.0/16", "129.239.0.0/16",
    "129.240.0.0/16", "129.241.0.0/16", "129.242.0.0/16", "129.243.0.0/16",
    "129.244.0.0/16", "129.245.0.0/16", "129.246.0.0/16", "129.247.0.0/16",
    "129.248.0.0/16", "129.249.0.0/16", "129.250.0.0/16", "129.251.0.0/16",
    "129.252.0.0/16", "129.253.0.0/16", "129.254.0.0/16", "129.255.0.0/16",
    
    -- BattleEye Anti-Cheat
    "185.244.0.0/16", "185.245.0.0/16", "185.246.0.0/16", "185.247.0.0/16",
    "185.248.0.0/16", "185.249.0.0/16", "185.250.0.0/16", "185.251.0.0/16",
    "185.252.0.0/16", "185.253.0.0/16", "185.254.0.0/16", "185.255.0.0/16",
    
    -- EasyAntiCheat
    "104.0.0.0/8", "104.1.0.0/8", "104.2.0.0/8", "104.3.0.0/8",
    "104.4.0.0/8", "104.5.0.0/8", "104.6.0.0/8", "104.7.0.0/8",
    "104.8.0.0/8", "104.9.0.0/8", "104.10.0.0/8", "104.11.0.0/8",
    "104.12.0.0/8", "104.13.0.0/8", "104.14.0.0/8", "104.15.0.0/8",
    "104.16.0.0/8", "104.17.0.0/8", "104.18.0.0/8", "104.19.0.0/8",
    "104.20.0.0/8", "104.21.0.0/8", "104.22.0.0/8", "104.23.0.0/8",
    "104.24.0.0/8", "104.25.0.0/8", "104.26.0.0/8", "104.27.0.0/8",
    "104.28.0.0/8", "104.29.0.0/8", "104.30.0.0/8", "104.31.0.0/8",
    
    -- PUBG Report and Ban Servers @hacker420official
    "203.0.0.0/8", "204.0.0.0/8", "205.0.0.0/8", "206.0.0.0/8",
    "207.0.0.0/8", "208.0.0.0/8", "209.0.0.0/8", "210.0.0.0/8",
    "211.0.0.0/8", "212.0.0.0/8", "213.0.0.0/8", "214.0.0.0/8",
    "215.0.0.0/8", "216.0.0.0/8", "217.0.0.0/8", "218.0.0.0/8",
    "219.0.0.0/8", "220.0.0.0/8", "221.0.0.0/8", "222.0.0.0/8",
    "223.0.0.0/8",
    
    -- Other Anti-Cheat Servers @hacker420official
    "3.0.0.0/8", "4.0.0.0/8", "5.0.0.0/8", "6.0.0.0/8",
    "7.0.0.0/8", "8.0.0.0/8", "9.0.0.0/8", "10.0.0.0/8",
    "11.0.0.0/8", "12.0.0.0/8", "13.0.0.0/8", "14.0.0.0/8",
    "15.0.0.0/8", "16.0.0.0/8", "17.0.0.0/8", "18.0.0.0/8",
    "19.0.0.0/8", "20.0.0.0/8", "21.0.0.0/8", "22.0.0.0/8",
    "23.0.0.0/8", "24.0.0.0/8", "25.0.0.0/8", "26.0.0.0/8",
    "27.0.0.0/8", "28.0.0.0/8", "29.0.0.0/8", "30.0.0.0/8",
    "31.0.0.0/8", "32.0.0.0/8", "33.0.0.0/8", "34.0.0.0/8",
    "35.0.0.0/8", "36.0.0.0/8", "37.0.0.0/8", "38.0.0.0/8",
    "39.0.0.0/8", "40.0.0.0/8", "41.0.0.0/8", "42.0.0.0/8",
    "44.0.0.0/8", "45.0.0.0/8", "46.0.0.0/8", "47.0.0.0/8",
    "48.0.0.0/8", "49.0.0.0/8", "50.0.0.0/8", "51.0.0.0/8",
    "52.0.0.0/8", "53.0.0.0/8", "54.0.0.0/8", "55.0.0.0/8",
    "56.0.0.0/8", "57.0.0.0/8", "58.0.0.0/8", "59.0.0.0/8",
    "60.0.0.0/8", "61.0.0.0/8", "62.0.0.0/8", "63.0.0.0/8",
    "64.0.0.0/8", "65.0.0.0/8", "66.0.0.0/8", "67.0.0.0/8",
    "68.0.0.0/8", "69.0.0.0/8", "70.0.0.0/8", "71.0.0.0/8",
    "72.0.0.0/8", "73.0.0.0/8", "74.0.0.0/8", "75.0.0.0/8",
    "76.0.0.0/8", "77.0.0.0/8", "78.0.0.0/8", "79.0.0.0/8",
    "80.0.0.0/8", "81.0.0.0/8", "82.0.0.0/8", "83.0.0.0/8",
    "84.0.0.0/8", "85.0.0.0/8", "86.0.0.0/8", "87.0.0.0/8",
    "88.0.0.0/8", "89.0.0.0/8", "90.0.0.0/8", "91.0.0.0/8",
    "92.0.0.0/8", "93.0.0.0/8", "94.0.0.0/8", "95.0.0.0/8",
    "96.0.0.0/8", "97.0.0.0/8", "98.0.0.0/8", "99.0.0.0/8",
    "100.0.0.0/8", "101.0.0.0/8", "102.0.0.0/8", "103.0.0.0/8",
    "105.0.0.0/8", "106.0.0.0/8", "107.0.0.0/8", "108.0.0.0/8",
    "109.0.0.0/8", "110.0.0.0/8", "111.0.0.0/8", "112.0.0.0/8",
    "113.0.0.0/8", "114.0.0.0/8", "115.0.0.0/8", "116.0.0.0/8",
    "117.0.0.0/8", "118.0.0.0/8", "119.0.0.0/8", "120.0.0.0/8",
    "121.0.0.0/8", "122.0.0.0/8", "123.0.0.0/8", "124.0.0.0/8",
    "125.0.0.0/8", "126.0.0.0/8", "127.0.0.0/8",
    
    -- Additional Ban IPs @hacker420official
    "10.20.30.40", "10.20.30.41", "10.20.30.42", "10.20.30.43",
    "10.20.30.44", "10.20.30.45", "10.20.30.46", "10.20.30.47",
    "10.20.30.48", "10.20.30.49", "10.20.30.50", "10.20.30.51",
    "10.20.30.52", "10.20.30.53", "10.20.30.54", "10.20.30.55",
}

-- ============================================================
-- Anti-Cheat Domain Blocking List @hacker420official
-- ============================================================

_G.BlockedDomains = {
    "pubgm.qq.com", "anticheat.qq.com", "tss.tencent.com",
    "report.qq.com", "ban.qq.com", "security.qq.com",
    "anti.tencent.com", "ac.tencent.com", "safe.qq.com",
    "trust.qq.com", "verify.qq.com", "check.qq.com",
    "monitor.qq.com", "track.qq.com", "analytics.qq.com",
    "telemetry.qq.com", "crash.qq.com", "bugly.qq.com",
    "tlog.qq.com", "log.qq.com", "data.qq.com",
    "api.qq.com", "svc.qq.com", "gw.qq.com",
    "cloud.qq.com", "cdn.qq.com", "static.qq.com",
    "anticheat.tencent.com", "tss.tencent.com", "ace.tencent.com",
    "battleye.com", "easyanticheat.com", "xigncode.com",
    "gameguardian.net", "cheatengine.org", "memoryeditor.com",
    "rootdetect.com", "jailbreak.com", "emulatorcheck.com",
}

-- ============================================================
-- 1. Ban Popup @hacker420official
-- ============================================================

local function KillBanPopup()
    pcall(function()
        -- Ban UI @hacker420official
        local allWidgets = slua.getUIList() or {}
        for _, widget in pairs(allWidgets) do
            if slua.isValid(widget) then
                local name = widget:GetName() or ""
                if name:find("Legal") or name:find("Common_Legal") or 
                   name:find("Notice") or name:find("Ban") or 
                   name:find("Error") or name:find("Popup") or
                   name:find("Message") or name:find("Dialog") or
                   name:find("Warning") or name:find("Alert") or
                   name:find("Suspension") or name:find("Frozen") or
                   name:find("Penalty") or name:find("Sanction") or
                   name:find("Terminated") or name:find("Blocked") or
                   name:find("Flagged") or name:find("Marked") or
                   name:find("Inspection") or name:find("Risk") then
                    widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                    pcall(function() widget:RemoveFromParent() end)
                end
            end
        end
        
        -- Console command @hacker420official
        pcall(function()
            local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
            if slua.isValid(pc) then
                local KSL = import("KismetSystemLibrary")
                if KSL then
                    KSL.ExecuteConsoleCommand(pc, "DisableAllScreenMessages")
                    KSL.ExecuteConsoleCommand(pc, "UI.DisableMessageOfTheDay")
                    KSL.ExecuteConsoleCommand(pc, "ShowMOTD 0")
                    KSL.ExecuteConsoleCommand(pc, "r.UI.DisableAll 1")
                    KSL.ExecuteConsoleCommand(pc, "UI.HideAllWidgets 1")
                    KSL.ExecuteConsoleCommand(pc, "ShowBanNotice 0")
                    KSL.ExecuteConsoleCommand(pc, "ShowSuspension 0")
                    KSL.ExecuteConsoleCommand(pc, "ShowFrozenNotice 0")
                    KSL.ExecuteConsoleCommand(pc, "ShowRiskNotice 0")
                    KSL.ExecuteConsoleCommand(pc, "ShowDeviceError 0")
                    KSL.ExecuteConsoleCommand(pc, "ShowNetworkError 0")
                    KSL.ExecuteConsoleCommand(pc, "DisableBanUI 1")
                    KSL.ExecuteConsoleCommand(pc, "HideBanMessages 1")
                    KSL.ExecuteConsoleCommand(pc, "IgnoreSecurityChecks 1")
                    KSL.ExecuteConsoleCommand(pc, "UIToggle 0")
                    KSL.ExecuteConsoleCommand(pc, "HideUI 1")
                    KSL.ExecuteConsoleCommand(pc, "DisablePopup 1")
                    KSL.ExecuteConsoleCommand(pc, "SuppressDialogs 1")
                end
            end
        end)
    end)
end

-- ============================================================
-- 2. IP/Domain @hacker420official
-- ============================================================

local function ApplyIPDomainBlocking()
    pcall(function()
        -- socket.connect @hacker420official
        if socket and socket.connect then
            local origConnect = socket.connect
            socket.connect = function(host, port, ...)
                for _, ip in ipairs(_G.BlockedIPs or {}) do
                    if host == ip then return nil, "blocked" end
                end
                for _, domain in ipairs(_G.BlockedDomains or {}) do
                    if host:lower():find(domain) then return nil, "blocked" end
                end
                return origConnect(host, port, ...)
            end
        end
        
        -- socket.tcp @hacker420official
        if socket and socket.tcp then
            local origTcp = socket.tcp
            socket.tcp = function(...)
                local client = origTcp(...)
                if client and client.connect then
                    local origConnect = client.connect
                    client.connect = function(self, host, port, ...)
                        for _, ip in ipairs(_G.BlockedIPs or {}) do
                            if host == ip then return nil, "blocked" end
                        end
                        for _, domain in ipairs(_G.BlockedDomains or {}) do
                            if host:lower():find(domain) then return nil, "blocked" end
                        end
                        return origConnect(self, host, port, ...)
                    end
                end
                return client
            end
        end
        
        -- NetUtil.ConnectToServer @hacker420official
        if NetUtil and NetUtil.ConnectToServer then
            local origConnect = NetUtil.ConnectToServer
            NetUtil.ConnectToServer = function(ip, port, ...)
                for _, banIP in ipairs(_G.BlockedIPs or {}) do
                    if ip == banIP then return false end
                end
                return origConnect(ip, port, ...)
            end
        end
        
        -- HTTP/WebSocket @hacker420official
        if _G.Http and _G.Http.Get then
            local origGet = _G.Http.Get
            _G.Http.Get = function(url, ...)
                for _, domain in ipairs(_G.BlockedDomains or {}) do
                    if url:find(domain) then return nil, "blocked" end
                end
                return origGet(url, ...)
            end
        end
        if _G.Http and _G.Http.Post then
            local origPost = _G.Http.Post
            _G.Http.Post = function(url, ...)
                for _, domain in ipairs(_G.BlockedDomains or {}) do
                    if url:find(domain) then return nil, "blocked" end
                end
                return origPost(url, ...)
            end
        end
        
        -- WebSocket @hacker420official
        if _G.WebSocket and _G.WebSocket.Connect then
            local origConnect = _G.WebSocket.Connect
            _G.WebSocket.Connect = function(url, ...)
                for _, domain in ipairs(_G.BlockedDomains or {}) do
                    if url:find(domain) then return nil, "blocked" end
                end
                return origConnect(url, ...)
            end
        end
        
        print("[BYPASS] ✅ IP/Domain @hacker420official")
    end)
end

-- ============================================================
-- 3. Game Guardian Detection @hacker420official
-- ============================================================

local function BlockGameGuardian()
    pcall(function()
        local GameGuardianDetect = _G.GameGuardianDetect or package.loaded["GameGuardianDetect"]
        if GameGuardianDetect then
            GameGuardianDetect.IsGGRunning = retFalse
            GameGuardianDetect.CheckPackages = retEmpty
            GameGuardianDetect.DetectGameGuardian = retFalse
            GameGuardianDetect.ReportGameGuardian = nop
            GameGuardianDetect.ValidateGG = retTrue
        end
        
        -- Process list  @hacker420official
        if _G.ProcessManager and _G.ProcessManager.GetRunningProcesses then
            local origGet = _G.ProcessManager.GetRunningProcesses
            _G.ProcessManager.GetRunningProcesses = function()
                local processes = origGet()
                if processes then
                    local filtered = {}
                    for _, proc in ipairs(processes) do
                        if not string.find(string.lower(tostring(proc)), "gameguardian") then
                            table.insert(filtered, proc)
                        end
                    end
                    return filtered
                end
                return {}
            end
        end
        
        print("[BYPASS] ✅ Game Guardian Detection @hacker420official")
    end)
end

-- ============================================================
--  Cheat Engine Detection @hacker420official
-- ============================================================

local function BlockCheatEngine()
    pcall(function()
        local CheatEngineDetect = _G.CheatEngineDetect or package.loaded["CheatEngineDetect"]
        if CheatEngineDetect then
            CheatEngineDetect.IsCheatEngineRunning = retFalse
            CheatEngineDetect.CheckProcessList = retEmpty
            CheatEngineDetect.DetectCheatEngine = retFalse
            CheatEngineDetect.ReportCheatEngine = nop
            CheatEngineDetect.ValidateCE = retTrue
        end
        
        if _G.ProcessManager and _G.ProcessManager.GetRunningProcesses then
            local origGet = _G.ProcessManager.GetRunningProcesses
            _G.ProcessManager.GetRunningProcesses = function()
                local processes = origGet()
                if processes then
                    local filtered = {}
                    local ceKeywords = {"cheatengine", "cheat_engine", "ce", "memoryedit"}
                    for _, proc in ipairs(processes) do
                        local procLower = string.lower(tostring(proc))
                        local blocked = false
                        for _, kw in ipairs(ceKeywords) do
                            if procLower:find(kw) then blocked = true break end
                        end
                        if not blocked then table.insert(filtered, proc) end
                    end
                    return filtered
                end
                return {}
            end
        end
        
        print("[BYPASS] ✅ Cheat Engine Detection @hacker420official")
    end)
end

-- ============================================================
-- 5. Root/Jailbreak Detection Blocking @hacker420official
-- ============================================================

local function BlockRootJailbreak()
    pcall(function()
        local RootDetect = _G.RootDetect or package.loaded["RootDetect"]
        if RootDetect then
            RootDetect.CheckRoot = retFalse
            RootDetect.CheckSu = retFalse
            RootDetect.CheckMagisk = retFalse
            RootDetect.CheckSuperSU = retFalse
            RootDetect.DetectRoot = retFalse
            RootDetect.ReportRoot = nop
            RootDetect.ValidateRoot = retTrue
        end
        
        local JailbreakDetect = _G.JailbreakDetect or package.loaded["JailbreakDetect"]
        if JailbreakDetect then
            JailbreakDetect.CheckJailbreak = retFalse
            JailbreakDetect.CheckCydia = retFalse
            JailbreakDetect.DetectJailbreak = retFalse
            JailbreakDetect.ReportJailbreak = nop
            JailbreakDetect.ValidateJailbreak = retTrue
        end
        
        print("[BYPASS] ✅ Root/Jailbreak Detection @hacker420official")
    end)
end

-- ============================================================
-- 6. Emulator Detection Blocking (New) @hacker420official
-- ============================================================

local function BlockEmulatorDetection()
    pcall(function()
        -- Emulator Detection ကို @hacker420official.
        local EmulatorDetect = import("EmulatorDetect")
        if EmulatorDetect then
            EmulatorDetect.IsEmulator = retFalse
            EmulatorDetect.GetEmulatorType = retEmptyString
            EmulatorDetect.CheckVM = retFalse
            EmulatorDetect.DetectEmulator = retFalse
            EmulatorDetect.ReportEmulator = nop
            EmulatorDetect.ValidateEmulator = retTrue
        end
        
        -- TSS Emulator Check @hacker420official.
        if _G.TssSdk then
            _G.TssSdk.IsEmulator = retFalse
            _G.TssSdk.CheckEmulator = retFalse
            _G.TssSdk.ReportEmulator = nop
        end
        
        -- System Properties @hacker420official.
        if _G.SystemProperties then
            _G.SystemProperties.ro.kernel.qemu = "0"
            _G.SystemProperties.ro.product.device = "samsung"
            _G.SystemProperties.ro.product.model = "SM-G998B"
            _G.SystemProperties.ro.product.manufacturer = "samsung"
            _G.SystemProperties.ro.hardware = "exynos2100"
        end
        
        print("[BYPASS] ✅ Emulator Detection @hacker420official")
    end)
end

-- ============================================================
-- 7. Tamper Detection Blocking (New) @hacker420official
-- ============================================================

local function BlockTamperDetection()
    pcall(function()
        -- File Integrity Check  @hacker420official.
        local FileIntegrity = import("FileIntegrity")
        if FileIntegrity then
            FileIntegrity.VerifyFile = retTrue
            FileIntegrity.CheckIntegrity = retTrue
            FileIntegrity.ReportTamper = nop
            FileIntegrity.ValidateFile = retTrue
            FileIntegrity.IsFileValid = retTrue
        end
        
        -- Pak File Verification @hacker420official.
        local PakVerification = import("PakVerification")
        if PakVerification then
            PakVerification.VerifyPak = retTrue
            PakVerification.CheckPak = retTrue
            PakVerification.ReportPakError = nop
            PakVerification.ValidatePak = retTrue
            PakVerification.IsPakValid = retTrue
        end
        
        -- Memory Tamper Detection @hacker420official.
        local MemoryTamper = import("MemoryTamper")
        if MemoryTamper then
            MemoryTamper.DetectTamper = retFalse
            MemoryTamper.ReportTamper = nop
            MemoryTamper.CheckTamper = retFalse
            MemoryTamper.ValidateMemory = retTrue
        end
        
        print("[BYPASS] ✅ Tamper Detection @hacker420official")
    end)
end

-- ============================================================
-- 8. SpeedHack Detection Blocking (New) @hacker420official
-- ============================================================

local function BlockSpeedHackDetection()
    pcall(function()
        -- Speed Hack Detection @hacker420official.
        local SpeedHackDetect = import("SpeedHackDetect")
        if SpeedHackDetect then
            SpeedHackDetect.DetectSpeedHack = retFalse
            SpeedHackDetect.ReportSpeedHack = nop
            SpeedHackDetect.CheckSpeed = retTrue
            SpeedHackDetect.ValidateSpeed = retTrue
            SpeedHackDetect.IsSpeedHack = retFalse
        end
        
        -- Movement Verification @hacker420official.
        local MovementVerify = import("MovementVerify")
        if MovementVerify then
            MovementVerify.VerifyMovement = retTrue
            MovementVerify.ReportAbnormalMovement = nop
            MovementVerify.CheckMovement = retTrue
            MovementVerify.ValidateMovement = retTrue
            MovementVerify.IsMovementValid = retTrue
        end
        
        -- Time Scale Check ကို @hacker420official.
        local TimeScale = import("TimeScale")
        if TimeScale then
            TimeScale.CheckTimeScale = retTrue
            TimeScale.ReportTimeScale = nop
            TimeScale.ValidateTimeScale = retTrue
            TimeScale.IsTimeScaleValid = retTrue
        end
        
        print("[BYPASS] ✅ SpeedHack Detection @hacker420official")
    end)
end

-- ============================================================
-- 9. ESP Detection Blocking (New) @hacker420official
-- ============================================================

local function BlockESPDetection()
    pcall(function()
        -- ESP Detection  @hacker420official.
        local ESPDetect = import("ESPDetect")
        if ESPDetect then
            ESPDetect.DetectESP = retFalse
            ESPDetect.ReportESP = nop
            ESPDetect.CheckESP = retFalse
            ESPDetect.ValidateESP = retTrue
            ESPDetect.IsESPDetected = retFalse
        end
        
        -- Wallhack Detection  @hacker420official.
        local WallhackDetect = import("WallhackDetect")
        if WallhackDetect then
            WallhackDetect.DetectWallhack = retFalse
            WallhackDetect.ReportWallhack = nop
            WallhackDetect.CheckWallhack = retFalse
            WallhackDetect.ValidateWallhack = retTrue
            WallhackDetect.IsWallhackDetected = retFalse
        end
        
        -- Render Check @hacker420official.
        local RenderCheck = import("RenderCheck")
        if RenderCheck then
            RenderCheck.CheckRender = retTrue
            RenderCheck.ReportRender = nop
            RenderCheck.ValidateRender = retTrue
            RenderCheck.IsRenderValid = retTrue
        end
        
        print("[BYPASS] ✅ ESP Detection @hacker420official")
    end)
end

-- ============================================================
-- 10. NoRecoil Detection Blocking (New) @hacker420official
-- ============================================================

local function BlockNoRecoilDetection()
    pcall(function()
        -- NoRecoil Detection @hacker420official.
        local NoRecoilDetect = import("NoRecoilDetect")
        if NoRecoilDetect then
            NoRecoilDetect.DetectNoRecoil = retFalse
            NoRecoilDetect.ReportNoRecoil = nop
            NoRecoilDetect.CheckRecoil = retTrue
            NoRecoilDetect.ValidateRecoil = retTrue
            NoRecoilDetect.IsNoRecoil = retFalse
        end
        
        -- Shoot Pattern Verification @hacker420official.
        local ShootPattern = import("ShootPattern")
        if ShootPattern then
            ShootPattern.VerifyPattern = retTrue
            ShootPattern.ReportPattern = nop
            ShootPattern.CheckPattern = retTrue
            ShootPattern.ValidatePattern = retTrue
            ShootPattern.IsPatternValid = retTrue
        end
        
        print("[BYPASS] ✅ NoRecoil Detection @hacker420official")
    end)
end

-- ============================================================
-- 11. Advanced Anti-Cheat Bypass (New) @hacker420official
-- ============================================================

local function AdvancedAntiCheatBypass()
    pcall(function()
        -- Unreal Engine Anti-Cheat
        local UAntiCheat = import("UAntiCheat")
        if UAntiCheat then
            UAntiCheat.CheckCheat = retFalse
            UAntiCheat.ReportCheat = nop
            UAntiCheat.ValidateCheat = retTrue
            UAntiCheat.IsCheatDetected = retFalse
            UAntiCheat.DetectCheat = retFalse
            UAntiCheat.KickCheater = nop
            UAntiCheat.BanCheater = nop
        end
        
        -- Blueprint Anti-Cheat
        local BPAntiCheat = import("BPAntiCheat")
        if BPAntiCheat then
            BPAntiCheat.VerifyBlueprint = retTrue
            BPAntiCheat.ReportBlueprint = nop
            BPAntiCheat.CheckBlueprint = retTrue
            BPAntiCheat.ValidateBlueprint = retTrue
            BPAntiCheat.IsBlueprintValid = retTrue
        end
        
        -- Network Anti-Cheat
        local NetAntiCheat = import("NetAntiCheat")
        if NetAntiCheat then
            NetAntiCheat.VerifyNetwork = retTrue
            NetAntiCheat.ReportNetwork = nop
            NetAntiCheat.CheckNetwork = retTrue
            NetAntiCheat.ValidateNetwork = retTrue
            NetAntiCheat.IsNetworkValid = retTrue
        end
        
        print("[BYPASS] ✅ Advanced Anti-Cheat @hacker420official")
    end)
end

-- ============================================================
-- 12. Memory Protection Bypass (New) @hacker420official
-- ============================================================

local function MemoryProtectionBypass()
    pcall(function()
        -- Memory Scanner ကို @hacker420official.
        local MemoryScanner = import("MemoryScanner")
        if MemoryScanner then
            MemoryScanner.ScanMemory = retFalse
            MemoryScanner.ReportMemory = nop
            MemoryScanner.CheckMemory = retTrue
            MemoryScanner.ValidateMemory = retTrue
            MemoryScanner.IsMemoryValid = retTrue
        end
        
        -- Pointer Check ကို @hacker420official.
        local PointerCheck = import("PointerCheck")
        if PointerCheck then
            PointerCheck.CheckPointer = retTrue
            PointerCheck.ReportPointer = nop
            PointerCheck.ValidatePointer = retTrue
            PointerCheck.IsPointerValid = retTrue
        end
        
        -- Heap Check ကို @hacker420official.
        local HeapCheck = import("HeapCheck")
        if HeapCheck then
            HeapCheck.CheckHeap = retTrue
            HeapCheck.ReportHeap = nop
            HeapCheck.ValidateHeap = retTrue
            HeapCheck.IsHeapValid = retTrue
        end
        
        print("[BYPASS] ✅ Memory Protection @hacker420official")
    end)
end

-- ============================================================
-- 13. Player Report Bypass (New) @hacker420official
-- ============================================================

local function PlayerReportBypass()
    pcall(function()
        -- Player Report System ကို @hacker420official.
        local PlayerReport = import("PlayerReport")
        if PlayerReport then
            PlayerReport.ReportPlayer = nop
            PlayerReport.SendReport = nop
            PlayerReport.CheckReport = retFalse
            PlayerReport.ValidateReport = retTrue
            PlayerReport.IsReportValid = retTrue
        end
        
        -- Report Cooldown @hacker420official.
        local ReportCooldown = import("ReportCooldown")
        if ReportCooldown then
            ReportCooldown.GetCooldown = retZero
            ReportCooldown.CheckCooldown = retTrue
            ReportCooldown.ResetCooldown = nop
            ReportCooldown.ValidateCooldown = retTrue
        end
        
        print("[BYPASS] ✅ Player Report @hacker420official")
    end)
end

-- ============================================================
-- 14. Magic Bullet Bypass @hacker420official
-- ============================================================

local function MagicBulletBypass()
    pcall(function()
        print("[MAGIC BULLET BYPASS] Magic Bullet @hacker420official....")
        
        -- Damage Verification @hacker420official.
        local DamageVerification = import("DamageVerification")
        if DamageVerification then
            DamageVerification.VerifyDamage = retTrue
            DamageVerification.ReportAbnormalDamage = nop
            DamageVerification.CheckDamage = retTrue
            DamageVerification.ValidateDamage = retTrue
            DamageVerification.IsDamageValid = retTrue
            DamageVerification.ReportInvalidDamage = nop
            DamageVerification.ResetDamageData = nop
            print("[MAGIC BULLET BYPASS] ✅ Damage Verification @hacker420official!")
        end
        
        -- Hitbox Verification @hacker420official.
        local HitboxVerification = import("HitboxVerification")
        if HitboxVerification then
            HitboxVerification.VerifyHitbox = retTrue
            HitboxVerification.ReportInvalidHit = nop
            HitboxVerification.CheckHitbox = retTrue
            HitboxVerification.ValidateHitbox = retTrue
            HitboxVerification.IsHitboxValid = retTrue
            HitboxVerification.ReportAbnormalHitbox = nop
            HitboxVerification.ResetHitboxData = nop
            print("[MAGIC BULLET BYPASS] ✅ Hitbox Verification @hacker420official!")
        end
        
        -- Projectile Verification @hacker420official.
        local ProjectileVerification = import("ProjectileVerification")
        if ProjectileVerification then
            ProjectileVerification.VerifyProjectile = retTrue
            ProjectileVerification.ReportAbnormalProjectile = nop
            ProjectileVerification.CheckProjectile = retTrue
            ProjectileVerification.ValidateProjectile = retTrue
            ProjectileVerification.IsProjectileValid = retTrue
            ProjectileVerification.ReportInvalidProjectile = nop
            ProjectileVerification.ResetProjectileData = nop
            print("[MAGIC BULLET BYPASS] ✅ Projectile Verification @hacker420official!")
        end
        
        -- Bullet Verification @hacker420official.
        local BulletVerification = import("BulletVerification")
        if BulletVerification then
            BulletVerification.VerifyBullet = retTrue
            BulletVerification.ReportAbnormalBullet = nop
            BulletVerification.CheckBullet = retTrue
            BulletVerification.ValidateBullet = retTrue
            BulletVerification.IsBulletValid = retTrue
            BulletVerification.ReportInvalidBullet = nop
            BulletVerification.ResetBulletData = nop
            print("[MAGIC BULLET BYPASS] ✅ Bullet Verification @hacker420official!")
        end
        
        -- Shoot Verification @hacker420official.
        local ShootVerify = _safe_require("GameLua.Dev.Subsystem.ShootVerifySubSystemClient")
        if ShootVerify then
            ShootVerify.OnShootVerifyFailed = nop
            ShootVerify.SendVerifyData = nop
            ShootVerify.ReportBulletHit = nop
            ShootVerify.UploadHitInfo = nop
            ShootVerify.VerifyShot = retTrue
            ShootVerify.CheckShoot = retTrue
            ShootVerify.ValidateShoot = retTrue
            ShootVerify.IsShootValid = retTrue
            ShootVerify.ReportInvalidShoot = nop
            ShootVerify.ResetShootData = nop
            print("[MAGIC BULLET BYPASS] ✅ Shoot Verification @hacker420official!")
        end
        
        print("[MAGIC BULLET BYPASS] ✅ @hacker420official. - Magic Bullet detection အားလုံး @hacker420official!")
    end)
end

-- ============================================================
-- 15. Skin Mod Bypass @hacker420official
-- ============================================================

local function SkinModBypass()
    pcall(function()
        print("[SKIN MOD BYPASS] Skin Mod @hacker420official....")
        
        -- Avatar Verification @hacker420official.
        local AvatarUtils = import("AvatarUtils")
        if AvatarUtils then
            AvatarUtils.CheckIsWeaponInBlackList = retFalse
            AvatarUtils.IsValidAvatar = retTrue
            AvatarUtils.CheckAvatarIntegrity = retTrue
            AvatarUtils.ReportInvalidAvatar = nop
            AvatarUtils.VerifyAvatar = retTrue
            AvatarUtils.ValidateAvatar = retTrue
            AvatarUtils.IsAvatarValid = retTrue
            AvatarUtils.ResetAvatarData = nop
            print("[SKIN MOD BYPASS] ✅ Avatar Verification @hacker420official!")
        end
        
        -- Weapon Verification @hacker420official.
        local WeaponVerification = import("WeaponVerification")
        if WeaponVerification then
            WeaponVerification.VerifyWeapon = retTrue
            WeaponVerification.ReportInvalidWeapon = nop
            WeaponVerification.CheckWeapon = retTrue
            WeaponVerification.ValidateWeapon = retTrue
            WeaponVerification.IsWeaponValid = retTrue
            WeaponVerification.ResetWeaponData = nop
            print("[SKIN MOD BYPASS] ✅ Weapon Verification @hacker420official!")
        end
        
        -- Vehicle Verification @hacker420official.
        local VehicleVerification = import("VehicleVerification")
        if VehicleVerification then
            VehicleVerification.VerifyVehicle = retTrue
            VehicleVerification.ReportInvalidVehicle = nop
            VehicleVerification.CheckVehicle = retTrue
            VehicleVerification.ValidateVehicle = retTrue
            VehicleVerification.IsVehicleValid = retTrue
            VehicleVerification.ResetVehicleData = nop
            print("[SKIN MOD BYPASS] ✅ Vehicle Verification @hacker420official!")
        end
        
        print("[SKIN MOD BYPASS] ✅ @hacker420official. - Skin Mod detection အားလုံး @hacker420official!")
    end)
end

-- ============================================================
-- 16. Version Specific Bypass @hacker420official
-- ============================================================

local function VersionSpecificBypasses()
    pcall(function()
        -- GLOBAL Version
        if _G.IS_GLOBAL then
            if _G.TssSdk then
                _G.TssSdk.IsEmulator = retFalse
                _G.TssSdk.ScanMemory = retTrue
                _G.TssSdk.ReportData = nop
                _G.TssSdk.SendReport = nop
                _G.TssSdk.OnRecvData = nop
            end
            local Higgs = package.loaded["GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent"]
            if Higgs then
                Higgs.bIsEnable = false
                Higgs.bMHActive = false
                Higgs.bCallPreReplication = false
            end
            print("[BYPASS] ✅ Global Version @hacker420official.")
        end
        
        -- KR Version
        if _G.IS_KR then
            if _G.TssSdk then
                _G.TssSdk.IsEmulator = retFalse
                _G.TssSdk.ScanMemory = retTrue
                _G.TssSdk.ReportData = nop
                _G.TssSdk.SendReport = nop
                _G.TssSdk.OnRecvData = nop
            end
            local Higgs = package.loaded["GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent"]
            if Higgs then
                Higgs.bIsEnable = false
                Higgs.bMHActive = false
                Higgs.bCallPreReplication = false
            end
            print("[BYPASS] ✅ KR Version @hacker420official.")
        end
        
        -- TW Version
        if _G.IS_TW_VERSION then
            if _G.TssSdk then
                _G.TssSdk.IsEmulator = retFalse
                _G.TssSdk.ScanMemory = retTrue
                _G.TssSdk.ReportData = nop
                _G.TssSdk.SendReport = nop
                _G.TssSdk.OnRecvData = nop
            end
            local Higgs = package.loaded["GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent"]
            if Higgs then
                Higgs.bIsEnable = false
                Higgs.bMHActive = false
                Higgs.bCallPreReplication = false
            end
            print("[BYPASS] ✅ TW Version @hacker420official.")
        end
    end)
end

-- ============================================================
-- 17. TSS SDK Blocking @hacker420official
-- ============================================================

local function BlockTssSdk()
    pcall(function()
        local TssSdk = _G.TssSdk or package.loaded["TssSdk"]
        if TssSdk then
            TssSdk.OnRecvData = nop
            TssSdk.SendReportInfo = nop
            TssSdk.ScanMemory = retTrue
            TssSdk.IsEmulator = retFalse
            TssSdk.GetTssSdkReportInfo = retEmptyString
            TssSdk.ReportException = nop
            TssSdk.ReportData = nop
            TssSdk.CheckIntegrity = retTrue
            TssSdk.VerifySignature = retTrue
            TssSdk.CollectEvidence = retNil
            TssSdk.UploadLog = nop
            TssSdk.SendAntiData = nop
            TssSdk.ReportGameStart = nop
            TssSdk.ReportGameEnd = nop
            TssSdk.ReportCrash = nop
            TssSdk.ReportViolation = nop
            TssSdk.ReportSuspicious = nop
            TssSdk.ReportBan = nop
            TssSdk.ReportKick = nop
            TssSdk.ReportSuspend = nop
            TssSdk.ReportFlag = nop
            TssSdk.ReportInfo = nop
            TssSdk.ReportDebug = nop
            TssSdk.ReportError = nop
            TssSdk.ReportFatal = nop
            TssSdk.ReportMemory = nop
            TssSdk.ReportProcess = nop
            TssSdk.ReportModule = nop
            TssSdk.ReportThread = nop
            TssSdk.ReportFile = nop
            TssSdk.ReportNetwork = nop
            TssSdk.ReportDevice = nop
            TssSdk.ReportSystem = nop
            TssSdk.ReportGame = nop
            TssSdk.ReportUser = nop
            TssSdk.ReportAccount = nop
            TssSdk.ReportSession = nop
            TssSdk.ReportPerformance = nop
            TssSdk.ReportBattery = nop
            TssSdk.ReportTemperature = nop
            TssSdk.ReportFPS = nop
            TssSdk.ReportPing = nop
            TssSdk.ReportPacket = nop
            TssSdk.ReportCheat = nop
            TssSdk.ReportHack = nop
            TssSdk.ReportMod = nop
            TssSdk.ReportInject = nop
            TssSdk.ReportDebugger = nop
            TssSdk.ReportEmulator = nop
            TssSdk.ReportRoot = nop
            TssSdk.ReportJailbreak = nop
            TssSdk.ReportVM = nop
            TssSdk.ReportHook = nop
            TssSdk.ReportPatch = nop
            TssSdk.ReportTamper = nop
            TssSdk.ReportCorrupt = nop
            TssSdk.ReportInvalid = nop
            TssSdk.ReportSpoof = nop
            TssSdk.ReportFake = nop
            TssSdk.ReportClone = nop
            TssSdk.ReportDuplicate = nop
            TssSdk.ReportConflict = nop
            TssSdk.ReportOverlap = nop
            TssSdk.ReportMismatch = nop
            TssSdk.ReportInconsistent = nop
            TssSdk.ReportUnexpected = nop
            TssSdk.ReportUnknown = nop
        end
    end)
    print("[BYPASS] ✅ TSS SDK @hacker420official")
end

-- ============================================================
-- 18. ACE (Anti-Cheat Expert) Blocking @hacker420official
-- ============================================================

local function BlockAce()
    pcall(function()
        local ace = _G.ace or package.loaded["libace.so"]
        if ace then
            ace.ReportData = nop
            ace.CheckIntegrity = retTrue
            ace.ScanMemory = retFalse
            ace.VerifyProcess = retTrue
            ace.CheckModule = retTrue
            ace.ReportViolation = nop
            ace.KickPlayer = nop
            ace.BanPlayer = nop
            ace.CollectInfo = retEmpty
            ace.SendReport = nop
            ace.ValidateClient = retTrue
            ace.CheckDebugger = retFalse
            ace.CheckEmulator = retFalse
            ace.CheckRoot = retFalse
            ace.ReportCheat = nop
            ace.ReportHack = nop
            ace.ReportMod = nop
            ace.ReportInject = nop
            ace.ReportHook = nop
            ace.ReportPatch = nop
            ace.ReportTamper = nop
            ace.ReportCorrupt = nop
            ace.ReportInvalid = nop
            ace.ReportSpoof = nop
            ace.ReportFake = nop
        end
    end)
    print("[BYPASS] ✅ ACE (Anti-Cheat Expert) @hacker420official")
end

-- ============================================================
-- 19. XignCode3 Blocking @hacker420official
-- ============================================================

local function BlockXignCode()
    pcall(function()
        local XignCode = _G.XignCode or package.loaded["xigncode"]
        if XignCode then
            XignCode.SendReport = nop
            XignCode.CheckProcess = retTrue
            XignCode.VerifyIntegrity = retTrue
            XignCode.ScanModules = retEmpty
            XignCode.ReportException = nop
            XignCode.ValidateMemory = retTrue
            XignCode.CheckDebugger = retFalse
            XignCode.KickPlayer = nop
            XignCode.BanPlayer = nop
            XignCode.EncryptData = function(data) return data end
            XignCode.DecryptData = function(data) return data end
            XignCode.ReportCheat = nop
            XignCode.ReportHack = nop
            XignCode.ReportMod = nop
            XignCode.ReportInject = nop
            XignCode.ReportHook = nop
            XignCode.ReportPatch = nop
            XignCode.ReportTamper = nop
        end
    end)
    print("[BYPASS] ✅ XignCode3 @hacker420official")
end

-- ============================================================
-- 20. BattlEye Blocking @hacker420official
-- ============================================================

local function BlockBattlEye()
    pcall(function()
        local BattlEye = _G.BattlEye or package.loaded["BattlEye"]
        if BattlEye then
            BattlEye.SendReport = nop
            BattlEye.KickPlayer = nop
            BattlEye.ValidatePlayer = retTrue
            BattlEye.CheckMemory = retTrue
            BattlEye.VerifyIntegrity = retTrue
            BattlEye.ReportViolation = nop
            BattlEye.ScanProcess = retTrue
            BattlEye.BanPlayer = nop
            BattlEye.CollectEvidence = retEmpty
            BattlEye.ReportCheat = nop
            BattlEye.ReportHack = nop
            BattlEye.ReportMod = nop
            BattlEye.ReportInject = nop
            BattlEye.ReportHook = nop
        end
    end)
    print("[BYPASS] ✅ BattlEye @hacker420official")
end

-- ============================================================
-- 21. JNI Anti-Cheat Blocking @hacker420official
-- ============================================================

local function BlockJNIAntiCheat()
    pcall(function()
        local jni_ac = _G.JNI and _G.JNI.AntiCheat
        if jni_ac then
            jni_ac.CheckRoot = retFalse
            jni_ac.CheckEmulator = retFalse
            jni_ac.CheckDebugger = retFalse
            jni_ac.CollectInfo = retEmpty
            jni_ac.SendReport = nop
            jni_ac.Validate = retTrue
            jni_ac.CheckRootAccess = retFalse
            jni_ac.CheckEmulatorAccess = retFalse
            jni_ac.CheckDebuggerAccess = retFalse
            jni_ac.CheckMemoryAccess = retTrue
            jni_ac.CheckProcessAccess = retTrue
            jni_ac.CheckFileAccess = retTrue
            jni_ac.CheckNetworkAccess = retTrue
            jni_ac.CheckSystemAccess = retTrue
            jni_ac.CheckDeviceAccess = retTrue
            jni_ac.CheckAPIAccess = retTrue
            jni_ac.CheckSDKAccess = retTrue
            jni_ac.CheckLibraryAccess = retTrue
            jni_ac.CheckFrameworkAccess = retTrue
            jni_ac.CheckPackageAccess = retTrue
        end
    end)
    print("[BYPASS] ✅ JNI Anti-Cheat @hacker420official")
end

-- ============================================================
-- 22. Anti-Debugging and Emulator Detection Blocking @hacker420official
-- ============================================================

local function BlockAntiDebugging()
    pcall(function()
        local DebuggerDetect = _G.DebuggerDetect or package.loaded["DebuggerDetect"]
        if DebuggerDetect then
            DebuggerDetect.IsDebuggerPresent = retFalse
            DebuggerDetect.CheckBreakpoint = retFalse
            DebuggerDetect.CheckTracer = retFalse
            DebuggerDetect.CheckDebug = retFalse
            DebuggerDetect.CheckDebugger = retFalse
            DebuggerDetect.DetectDebugger = retFalse
            DebuggerDetect.DetectBreakpoint = retFalse
            DebuggerDetect.DetectTracer = retFalse
            DebuggerDetect.DetectDebug = retFalse
        end

        local EmulatorDetect = _G.EmulatorDetect or package.loaded["EmulatorDetect"]
        if EmulatorDetect then
            EmulatorDetect.IsEmulator = retFalse
            EmulatorDetect.GetEmulatorType = retEmptyString
            EmulatorDetect.CheckVM = retFalse
            EmulatorDetect.Detect = retFalse
            EmulatorDetect.DetectEmulator = retFalse
            EmulatorDetect.DetectVM = retFalse
            EmulatorDetect.DetectVirtualMachine = retFalse
            EmulatorDetect.DetectEmulatorType = retEmptyString
        end
    end)
    print("[BYPASS] ✅ Anti-Debugging and Emulator Detection @hacker420official")
end

-- ============================================================
-- 23. Zero Trace Cleanup @hacker420official
-- ============================================================

local function ZeroTraceCleanup()
    pcall(function()
        local suspiciousVars = {
            "bIsCheating", "bDetected", "bBanned", "SuspicionScore",
            "CheatDetected", "AntiCheatFlag", "IsHacking", "bReported",
            "TrustScore", "SecurityFlag", "ViolationLevel", "BanStatus",
            "bIsBan", "bIsKick", "bIsReported", "CheatCount",
            "ViolationCount", "SecurityScore", "TrustLevel",
            "bIsCheater", "bIsHacker", "bIsModder", "bIsInjector",
            "bIsHooker", "bIsPatcher", "bIsTamperer", "bIsCorrupter",
            "bIsInvalid", "bIsSpoofer", "bIsFaker", "bIsCloner",
            "bIsDuplicator", "bIsConflicter", "bIsOverlapper", "bIsMismatcher",
            "bIsInconsistent", "bIsUnexpected", "bIsUnknown", "bIsSuspicious",
            "bIsAbnormal", "bIsCorrupt", "bIsTampered", "bIsModified",
            "bIsInjected", "bIsHooked", "bIsPatched", "bIsSpoofed",
            "bIsFaked", "bIsCloned", "bIsDuplicated", "bIsConflicted",
            "bIsOverlapped", "bIsMismatched", "bIsInconsistent"
        }
        for _, var in ipairs(suspiciousVars) do _G[var] = nil end
        
        _G.TelemetryQueue = {}
        _G.LogQueue = {}
        _G.ReportQueue = {}
        _G.ExceptionQueue = {}
        _G.CrashQueue = {}
        _G.TraceQueue = {}
        
        _G.bTelemetryEnabled = false
        _G.bLoggingEnabled = false
        _G.bReportingEnabled = false
        _G.bExceptionReportingEnabled = false
        _G.bCrashReportingEnabled = false
        _G.bTracingEnabled = false
        
        collectgarbage("collect")
    end)
    print("[BYPASS] ✅ Zero Trace Cleanup Done @hacker420official")
end

-- ============================================================
-- 24. End Game Protection @hacker420official
-- ============================================================

local function EndGameProtection()
    pcall(function()
        local ticker = _safe_require("common.time_ticker")
        if ticker and ticker.AddTimerLoop then
            ticker.AddTimerLoop(1.0, function()
                pcall(function()
                    local GameplayData = _safe_require("GameLua.GameCore.Data.GameplayData")
                    if GameplayData then
                        local pc = GameplayData.GetPlayerController()
                        if _isValid(pc) then
                            if pc.HiggsBoson then
                                pc.HiggsBoson.bMHActive = false
                                pc.HiggsBoson.bCallPreReplication = false
                            end
                            if pc.HiggsBosonComponent then
                                pc.HiggsBosonComponent.bMHActive = false
                                pc.HiggsBosonComponent.bCallPreReplication = false
                            end
                        end
                    end
                end)
            end, -1, 1.0)
        end
    end)
    print("[BYPASS] ✅ End Game Protection Activated @hacker420official")
end

-- ============================================================
-- 25. Memory Protection @hacker420official
-- ============================================================

local function MemoryProtection()
    pcall(function()
        local MemoryProtect = import("MemoryProtect")
        if MemoryProtect then
            MemoryProtect.VirtualProtect = function(addr, size, protect) return true end
            MemoryProtect.IsMemoryReadable = function(addr) return false end
            MemoryProtect.IsMemoryWritable = function(addr) return false end
            MemoryProtect.CheckMemory = retTrue
            MemoryProtect.ProtectMemory = retTrue
            MemoryProtect.UnprotectMemory = retTrue
            MemoryProtect.ValidateMemory = retTrue
            MemoryProtect.VerifyMemory = retTrue
        end
        
        if _G.Memory then
            _G.Memory.IntegrityCheck = retTrue
            _G.Memory.VerifyModule = retTrue
            _G.Memory.CheckCRC = retTrue
            _G.Memory.ScanModifications = retFalse
        end
        
        if debug then
            debug.getinfo = function() return {} end
            debug.sethook = function() end
            debug.getlocal = function() return nil end
            debug.setlocal = function() end
            debug.getupvalue = function() return nil end
            debug.setupvalue = function() end
        end
    end)
    print("[BYPASS] ✅ Memory Protection Activated @hacker420official")
end

-- ============================================================
-- 26. Network Monitoring Blocking @hacker420official
-- ============================================================

local function BlockNetworkMonitoring()
    pcall(function()
        local NetworkManager = import("NetworkManager")
        if NetworkManager then
            NetworkManager.GetNetworkStats = function() return {ping=40, loss=0, rtt=40} end
            NetworkManager.CapturePackets = function() end
            NetworkManager.AnalyzeTraffic = function() return {} end
            NetworkManager.GetConnectionInfo = function() return "127.0.0.1:8080" end
            NetworkManager.MonitorTraffic = function() end
            NetworkManager.ReportTraffic = function() end
            NetworkManager.ReportNetwork = function() end
            NetworkManager.ReportBandwidth = function() end
            NetworkManager.ReportLatency = function() end
            NetworkManager.ReportPacketLoss = function() end
        end
        
        if _G.Network then
            _G.Network.IsVPN = retFalse
            _G.Network.IsProxy = retFalse
            _G.Network.CheckNetworkType = function() return "WIFI" end
            _G.Network.IsNetworkError = retFalse
            _G.Network.ValidateConnection = retTrue
            _G.Network.VerifyNetwork = retTrue
            _G.Network.CheckLatency = function() return 20 end
            _G.Network.GetPacketLoss = function() return 0 end
            _G.Network.IsSuspicious = retFalse
            _G.Network.IsCompromised = retFalse
        end
    end)
    print("[BYPASS] ✅ Network Monitoring @hacker420official")
end

-- ============================================================
-- 27. Timing Check Spoofing @hacker420official
-- ============================================================

local function TimingCheckSpoof()
    pcall(function()
        local Engine = import("Engine")
        if Engine then
            Engine.GetAverageFPS = function() return 60 end
            Engine.GetFrameTime = function() return 0.016 end
            Engine.IsLagging = retFalse
            Engine.GetDeltaTime = function() return 0.033 end
            Engine.GetTime = function() return os.time() end
            Engine.GetTimestamp = function() return os.time() end
            Engine.GetTick = function() return os.clock() end
            Engine.GetSeconds = function() return os.time() end
            Engine.GetMilliseconds = function() return os.time() * 1000 end
            Engine.GetMicroseconds = function() return os.time() * 1000000 end
        end

        local GameTime = package.loaded["GameLua.GameCore.Data.GameTime"]
        if GameTime then
            GameTime.GetServerTime = function() return os.time() end
            GameTime.GetDeltaTime = function() return 0.033 end
            GameTime.GetGameTime = function() return os.time() end
            GameTime.GetRealTime = function() return os.time() end
            GameTime.GetTickTime = function() return os.clock() end
            GameTime.GetFrameTime = function() return 0.016 end
        end
    end)
    print("[BYPASS] ✅ Timing Check Spoofing Done @hacker420official")
end

-- ============================================================
-- 28. Client Entry Bypass @hacker420official
-- ============================================================

local function ClientEntryBypass()
    pcall(function()
        if Client then
            Client.SetTssNetworkStatus = nop
            Client.GEMReportEnterLobbyEvent = nop
            Client.TPerforPlatDisconnectReport = nop
            Client.IsConnected = function(NetInterface) return true end
            Client.GetUnrealNetworkStatus = nopstr
            Client.MD5LuaString = function(str) return "BYPASSED_MD5" end
            Client.GetDSVersion = function() return "999.999.999" end
            Client.IsInReplayState = nopfalse
        end
        
        if NetManager then
            NetManager.ProcRespondMsg = nop
            NetManager.isLogMsgAfterLogin = false
            NetManager.logMsgMap = {}
        end
        
        if EventSystem then
            local oldPost = EventSystem.postEvent
            EventSystem.postEvent = function(eventType, eventID, ...)
                if eventID and type(eventID) == "string" then
                    local blocked = {"SECURITY", "CHEAT", "BAN", "REPORT", "FLAG", 
                                    "VIOLATION", "DETECT", "VERIFY", "ANTI", "AC_",
                                    "SUSPICIOUS", "ABNORMAL", "MONITOR", "TRACK",
                                    "TELEMETRY", "ANALYTICS", "CRASH", "DUMP",
                                    "MAGIC", "BULLET", "HITBOX", "DAMAGE", "SHOOT",
                                    "PROJECTILE", "VERIFICATION", "VALIDATION",
                                    "SKIN", "AVATAR", "WEAPON", "VEHICLE", "EQUIPMENT",
                                    "GAMEGUARDIAN", "CHEATENGINE", "ROOT", "JAILBREAK",
                                    "EMULATOR", "TAMPER", "SPEEDHACK", "ESP", "WALLHACK",
                                    "NORECOIL", "PLAYERREPORT", "REPORTCOOLDOWN"}
                    for _, be in ipairs(blocked) do
                        if eventID:find(be) then return end
                    end
                end
                if oldPost then oldPost(eventType, eventID, ...) end
            end
        end
        
        local logFuncs = {"log", "log_warning", "log_error", "log_shipping_client", "log_format", "log_tree"}
        for _, funcName in ipairs(logFuncs) do
            if _G[funcName] then
                _G[funcName] = function(...)
                    local args = {...}
                    for _, arg in ipairs(args) do
                        if type(arg) == "string" and (
                            arg:find("cheat") or arg:find("security") or arg:find("ban") or
                            arg:find("detect") or arg:find("verify") or arg:find("integrity") or
                            arg:find("report") or arg:find("violation") or arg:find("hack") or
                            arg:find("anti") or arg:find("ac_") or arg:find("suspicious") or
                            arg:find("abnormal") or arg:find("monitor") or arg:find("track") or
                            arg:find("magic") or arg:find("bullet") or arg:find("hitbox") or
                            arg:find("damage") or arg:find("shoot") or arg:find("projectile") or
                            arg:find("skin") or arg:find("avatar") or arg:find("weapon") or
                            arg:find("vehicle") or arg:find("equipment") or
                            arg:find("gameguardian") or arg:find("cheatengine") or
                            arg:find("root") or arg:find("jailbreak") or
                            arg:find("emulator") or arg:find("tamper") or
                            arg:find("speedhack") or arg:find("esp") or arg:find("wallhack") or
                            arg:find("norecoil") or arg:find("playerreport")
                        ) then return end
                    end
                end
            end
        end
        
        if LogUtil then
            LogUtil.SetForceLog = nop
            LogUtil.SetLogTreeEnable = nop
            LogUtil.SetWriteLog = nop
        end
        
        if sandbox then 
            sandbox.LogError = nop
            sandbox.LogWarning = nop 
        end
    end)
    print("[BYPASS] ✅ Client Entry Bypass Done @hacker420official")
end

-- ============================================================
-- 29. HiggsBoson Bypass @hacker420official
-- ============================================================

local function HiggsBosonBypass()
    pcall(function()
        if CHiggsBosonComponent then
            CHiggsBosonComponent.ReceiveBeginPlay = nop
            CHiggsBosonComponent.StaticShowSecurityAlertInDev = nop
            CHiggsBosonComponent.ShowABCD = nop
            CHiggsBosonComponent._ClientShowSecurityAlertWindow = nop
            CHiggsBosonComponent._ReportChatRobot = nop
            CHiggsBosonComponent.SendAntiDataFlow = nop
            CHiggsBosonComponent.SendHitFireBtnFlow = nop
            CHiggsBosonComponent.OnBattleResult = nop
            CHiggsBosonComponent.SendHisarData = nop
            CHiggsBosonComponent.RPC_Client_ShowSecurityAlertWindow = nop
            CHiggsBosonComponent.RPC_Server_TellServerName = nop
            CHiggsBosonComponent.RecordStrategyTimestampInReplay = nop
            CHiggsBosonComponent.SkipAlertServer = nop
            CHiggsBosonComponent.SetClientAlertWindowEnabled = nop
            CHiggsBosonComponent.IsCharacterOwnerWerewolf = nopfalse
            CHiggsBosonComponent.IsCharacterOwnerButcher = nopfalse
            CHiggsBosonComponent._ProcessReportChatRobotQueue = nop
            CHiggsBosonComponent.LuaNotifySecurityAbnormalJump = nop
            CHiggsBosonComponent.bSkipAlertServer = true
            CHiggsBosonComponent.bMHActive = false
            CHiggsBosonComponent.bCallPreReplication = false
            bIsSkipAlertServer = true
            bSkipUploadNoschat = true
            _nReportNosChatTimerID = nil
            _nReportNosChatMessageID = 0
            _tReportNosChatQueue = {}
            LastTimeHandleAlert = -1
        end
        
        local GameplayData = _safe_require("GameLua.GameCore.Data.GameplayData")
        if GameplayData then
            local pc = GameplayData.GetPlayerController()
            if _isValid(pc) then
                if pc.HiggsBoson then
                    pc.HiggsBoson.bMHActive = false
                    pc.HiggsBoson.bCallPreReplication = false
                    pc.HiggsBoson.bSkipAlertServer = true
                end
                if pc.HiggsBosonComponent then
                    pc.HiggsBosonComponent.bMHActive = false
                    pc.HiggsBosonComponent.bCallPreReplication = false
                    pc.HiggsBosonComponent.bSkipAlertServer = true
                end
            end
        end
        
        local ticker = _safe_require("common.time_ticker")
        if ticker and ticker.AddTimerLoop then
            ticker.AddTimerLoop(1.0, function()
                pcall(function()
                    local GameplayData = _safe_require("GameLua.GameCore.Data.GameplayData")
                    if GameplayData then
                        local pc = GameplayData.GetPlayerController()
                        if _isValid(pc) then
                            if pc.HiggsBoson then
                                pc.HiggsBoson.bMHActive = false
                                pc.HiggsBoson.bCallPreReplication = false
                            end
                            if pc.HiggsBosonComponent then
                                pc.HiggsBosonComponent.bMHActive = false
                                pc.HiggsBosonComponent.bCallPreReplication = false
                            end
                        end
                    end
                end)
            end, -1, 1.0)
        end
    end)
    print("[BYPASS] ✅ HiggsBoson Bypass Done @hacker420official")
end

-- ============================================================
-- 30. HawkEye Patrol Bypass @hacker420official
-- ============================================================

local function HawkEyeBypass()
    pcall(function()
        if ClientHawkEyePatrolSubsystem then
            ClientHawkEyePatrolSubsystem._OnHawkSync = nop
            ClientHawkEyePatrolSubsystem._OnHawkReportSuccess = nop
            ClientHawkEyePatrolSubsystem._OnRecvInspectorBroadcastCount = nop
            ClientHawkEyePatrolSubsystem.ReportCheat = nop
            ClientHawkEyePatrolSubsystem.RequestImprison = nop
            ClientHawkEyePatrolSubsystem.SendReportTLog = nop
            ClientHawkEyePatrolSubsystem.IsDuringHawkEyePatrol = nopfalse
            ClientHawkEyePatrolSubsystem._CollectBeWatchedPlayerInfo = nop
            ClientHawkEyePatrolSubsystem.HasReported = noptrue
            ClientHawkEyePatrolSubsystem.GetBeWatchedPlayerInfo = nopnil
            ClientHawkEyePatrolSubsystem._OnPlayerKilledOtherPlayer = nop
            ClientHawkEyePatrolSubsystem._StartFrameUIRefreshTimer = nop
            ClientHawkEyePatrolSubsystem.ExitWatching = nop
            ClientHawkEyePatrolSubsystem.WantMatchNextPatrol = nop
            ClientHawkEyePatrolSubsystem._InitHawkEyePatrolSubsystem = function(self)
                self._bHasInitialized = true
                self._bHasReported = true
            end
            ClientHawkEyePatrolSubsystem._StartHideUITimer = nop
            ClientHawkEyePatrolSubsystem._StartShowDistanceUITimer = nop
            ClientHawkEyePatrolSubsystem._StartCloseBattleEndedTipsTimer = nop
            ClientHawkEyePatrolSubsystem._StartBattleTimeUsageTimer = nop
            ClientHawkEyePatrolSubsystem._StartQuitVoiceRoomTimer = nop
            ClientHawkEyePatrolSubsystem._StartExitGameTimer = nop
            ClientHawkEyePatrolSubsystem._CloseExitGameTimer = nop
            ClientHawkEyePatrolSubsystem._CreateOvertimerTimerForNextPatrol = nop
            ClientHawkEyePatrolSubsystem.ClearNextPatrolOvertimeTimer = nop
            ClientHawkEyePatrolSubsystem.ReturnLobbyAndOpenH5 = nop
            ClientHawkEyePatrolSubsystem.ForceNeverCloseBattleEndedTips = nop
            ClientHawkEyePatrolSubsystem.CheckShowReportedTips = nopfalse
            ClientHawkEyePatrolSubsystem.TryShowReportedTips = nop
            ClientHawkEyePatrolSubsystem.ShowWatchEndedTips = nop
            ClientHawkEyePatrolSubsystem.HasShownWatchEndedTips = noptrue
            ClientHawkEyePatrolSubsystem.OnShowWatchEndedTips = nop
            ClientHawkEyePatrolSubsystem.OnClickLowerLeftExitWatching = nop
            ClientHawkEyePatrolSubsystem.OnClickBottomRightOpenReportWindow = nop
            ClientHawkEyePatrolSubsystem._MarkHasReported = nop
            ClientHawkEyePatrolSubsystem.GetForbidNextPatrolRemainingTimeInSeconds = function() return 0 end
            ClientHawkEyePatrolSubsystem.GetUsedDailyTimeInSeconds = function() return 0 end
            ClientHawkEyePatrolSubsystem.GetInspectorBroadcastCount = function() return -1 end
            ClientHawkEyePatrolSubsystem.GetMaxInspectorBroadcastCount = function() return 0 end
            ClientHawkEyePatrolSubsystem.CanInspectorBroadcast = nopfalse
            ClientHawkEyePatrolSubsystem.IsCharacterLocationShouldDraw = nopfalse
            ClientHawkEyePatrolSubsystem.InitHawkEyePatrolSubsystem = nop
            ClientHawkEyePatrolSubsystem._PostConstruct = function(self)
                self._bHasInitialized = true
                self._bHasReported = true
                self.nInspectorBroadcastCount = -1
            end
            ClientHawkEyePatrolSubsystem.OnRelease = nop
            ClientHawkEyePatrolSubsystem._bHasInitialized = true
            ClientHawkEyePatrolSubsystem._bHasReported = true
            ClientHawkEyePatrolSubsystem._bHasShownWatchEndedTips = true
            ClientHawkEyePatrolSubsystem.bShowBeReportedTips = true
            ClientHawkEyePatrolSubsystem.nInspectorBroadcastCount = -1
        end
        if DSHawkEyePatrolSubsystem then
            DSHawkEyePatrolSubsystem.OnInit = nop
            DSHawkEyePatrolSubsystem.ReportCheat = nop
            DSHawkEyePatrolSubsystem.RequestImprison = nop
        end
    end)
    print("[BYPASS] ✅ HawkEye Patrol Bypass Done @hacker420official")
end

-- ============================================================
-- 31. Ban Logic Bypass @hacker420official
-- ============================================================

local function BanLogicBypass()
    pcall(function()
        if ClientBanLogic then
            ClientBanLogic.ReqBanInfo = nop
            ClientBanLogic.OnVoiceSwitchNotify = nop
            ClientBanLogic.OnVoiceBanNotify = nop
            ClientBanLogic.OnRealTimeVoiceBanNotify = nop
            ClientBanLogic.OnVoiceBanSuccess = nop
            ClientBanLogic.TryOpenVoice = function()
                EventSystem:postEvent(EVENTTYPE_INGAME_BAN, EVENTID_INGAME_BAN_FORBID_VOICE, false)
            end
            ClientBanLogic.IsVoiceReportEnable = nopfalse
            ClientBanLogic.OnSyncMicSuspicious = nop
            ClientBanLogic.OnSyncMicPreFilter = nop
            ClientBanLogic.OnSyncBanInfo = nop
            ClientBanLogic.OnNotifyWarningTips = nop
            ClientBanLogic.VoiceBanEndTime = 0
            ClientBanLogic.bEnableVoiceReport = false
            ClientBanLogic.SuspiciousFlag = 0
            ClientBanLogic.Reason = ""
            ClientBanLogic.IsTranslated = false
            ClientBanLogic.CheckBan = retFalse
            ClientBanLogic.IsBanned = retFalse
            ClientBanLogic.CheckBanStatus = retFalse
            ClientBanLogic.GetBanInfo = retEmpty
        end
        if RealTimeBan then
            RealTimeBan.Init = function() return end
            RealTimeBan.OnPlayerWithRealTimeBan = nop
            RealTimeBan.OnSyncPlayerInfo = nop
            RealTimeBan.HandleEnterGameModeFightingState = nop
            RealTimeBan.ShowAlias = nop
            RealTimeBan.SetOnRankInspectorUID = nop
            RealTimeBan.IsUIDOnRankInspector = nopfalse
            RealTimeBan.GetUIDInspectorRank = function() return -1 end
            RealTimeBan.SetInspectorBroadcastCountUID = nop
            RealTimeBan.GetUIDInspectorBroadcastCount = function() return -1 end
            RealTimeBan.GetTipsIDOffset = function() return 0 end
            RealTimeBan.GetTipsIDOffsetWithUID = function() return 0 end
            RealTimeBan.GetTipsIDOffsetInspector = function() return 0 end
            RealTimeBan.GMShowAlias = nop
            RealTimeBan.tOnRankInspectorUIDSet = {}
            RealTimeBan.tInspectorRankUIDSet = {}
            RealTimeBan.tInspectorBroadcastCountUIDSet = {}
            RealTimeBan.MaxAliasLevel = -1
            RealTimeBan.CurrentAlias = nil
            RealTimeBan.CurrentName = nil
            RealTimeBan.is_onrank_inspector = false
            RealTimeBan.inspector_rank = -1
            RealTimeBan.bHasOldAlias = false
            RealTimeBan.ShowTipsAliasConfig = {}
            RealTimeBan.DelayTime = {}
            RealTimeBan.OldShowTipsAlias = 0
            RealTimeBan.IsBanned = retFalse
            RealTimeBan.GetBanTime = retZero
            RealTimeBan.GetBanReason = retEmptyString
        end
        if BanSystem then
            BanSystem.CheckBan = retFalse
            BanSystem.IsBanned = retFalse
            BanSystem.GetBanReason = retEmptyString
            BanSystem.GetBanTime = retZero
            BanSystem.GetBanType = retZero
            BanSystem.IsPermanentlyBanned = retFalse
        end
        
        if _G.BanStatusCache then _G.BanStatusCache = nil end
        if _G.AccountBanCache then _G.AccountBanCache = {} end
        if _G.TemporaryBan then
            _G.TemporaryBan.BanStart = 0
            _G.TemporaryBan.BanEnd = 0
            _G.TemporaryBan.IsBanned = retFalse
        end
        if _G.Account then
            _G.Account.IsBanned = false
            _G.Account.BanStatus = 0
            _G.Account.WarningLevel = 0
            _G.Account.IsSuspicious = false
            _G.Account.BanExpiry = 0
            _G.Account.BanReason = ""
            _G.Account.BanCount = 0
            _G.Account.RiskLevel = 0
        end
    end)
    print("[BYPASS] ✅ Ban Logic Bypass Done @hacker420official")
end

-- ============================================================
-- 32. Report System Bypass @hacker420official
-- ============================================================

local function ReportSystemBypass()
    pcall(function()
        if ClientReportPlayerSubsystem then
            ClientReportPlayerSubsystem.OnInit = nop
            ClientReportPlayerSubsystem._OnPlayerKilledOtherPlayer = nop
            ClientReportPlayerSubsystem._RecordFatalDamager = nop
            ClientReportPlayerSubsystem._RecordMurdererFromDeathReplayData = nop
            ClientReportPlayerSubsystem._OnSyncFatalDamage = nop
            ClientReportPlayerSubsystem._SyncBattleResult = nop
            ClientReportPlayerSubsystem._OnBattleResult = nop
            ClientReportPlayerSubsystem._OnShowQuickReportMutualExclusiveUI = nop
            ClientReportPlayerSubsystem._OnHideQuickReportMutualExclusiveUI = nop
            ClientReportPlayerSubsystem._StartCheckGameModeTypeTimer = nop
            ClientReportPlayerSubsystem._CheckGameModeType = nop
            ClientReportPlayerSubsystem._StartCheckCurrentNotInTeamHistoricalTeammateTimer = nop
            ClientReportPlayerSubsystem._CheckCurrentNotInTeamHistoricalTeammate = nop
            ClientReportPlayerSubsystem._RecordTeammatePlayerInfo = nop
            ClientReportPlayerSubsystem._IsHealthStatusKilled = nopfalse
            ClientReportPlayerSubsystem.GetFatalDamagerMap = retEmpty
            ClientReportPlayerSubsystem.GetFatalDamagerMapSize = retZero
            ClientReportPlayerSubsystem.GetName2InfoMap = retEmpty
            ClientReportPlayerSubsystem.GetCachedTeammateName2InfoMap = retEmpty
            ClientReportPlayerSubsystem.GetTeammateName2InfoMapDuringBattle = retEmpty
            ClientReportPlayerSubsystem.GetCurrentNotInTeamHistoricalTeammateMap = retEmpty
            ClientReportPlayerSubsystem.GetInTeamIndexFromHistoricalTeammateInfo = function() return -1 end
            ClientReportPlayerSubsystem.IsGameModeTypeTeamDeathMatch = nopfalse
            ClientReportPlayerSubsystem.GetGameModeType = function() return -1 end
            ClientReportPlayerSubsystem.GetMainModeID = function() return -1 end
            ClientReportPlayerSubsystem.GetSubModeID = function() return -1 end
            ClientReportPlayerSubsystem.EnableRecordFatalDamage = nop
            ClientReportPlayerSubsystem._tKnockDownerMap = {}
            ClientReportPlayerSubsystem._tMurdererMap = {}
            ClientReportPlayerSubsystem._ds2history = {}
            ClientReportPlayerSubsystem._tMapCurrentNotInTeamHistoricalTeammate = {}
            ClientReportPlayerSubsystem._tTeammateName2InfoMap = {}
            ClientReportPlayerSubsystem._bEnableRecordFatalDamage = false
            ClientReportPlayerSubsystem._bIsGameModeTypeTeamDeathMatch = false
            ClientReportPlayerSubsystem._nGameModeType = -1
            ClientReportPlayerSubsystem._nMainModeID = -1
            ClientReportPlayerSubsystem._nSubModeID = -1
            ClientReportPlayerSubsystem._nCheckTDMGameModeTypeTimer = nil
            ClientReportPlayerSubsystem._nCurrentNotInTeamHistoricalTeammateTimer = nil
            ClientReportPlayerSubsystem.SubmitReport = nop
            ClientReportPlayerSubsystem.CanReport = retFalse
            ClientReportPlayerSubsystem.ReportPlayer = nop
            ClientReportPlayerSubsystem.ReportCheat = nop
        end
        if DSReportPlayerSubsystem then
            DSReportPlayerSubsystem.OnInit = nop
            DSReportPlayerSubsystem._OnNearDeathOrRescued = nop
            DSReportPlayerSubsystem._OnPlayerSettlementStart = nop
            DSReportPlayerSubsystem._OnTeammateDamage = nop
            DSReportPlayerSubsystem._OnCharacterDied = nop
            DSReportPlayerSubsystem._OnPlayerReconnect = nop
            DSReportPlayerSubsystem._RecordFatalDamager = nop
            DSReportPlayerSubsystem._RecordTeammateMurderer = nop
            DSReportPlayerSubsystem._AddMLKillerUIDToBattleResult = nop
            DSReportPlayerSubsystem._AddFatalDamagerMapToBattleResult = nop
            DSReportPlayerSubsystem._AddKnockDownerToBattleResult = nop
            DSReportPlayerSubsystem._AddKillerToBattleResult = nop
            DSReportPlayerSubsystem._AddTeammateMurderToBattleResult = nop
            DSReportPlayerSubsystem._SaveHistoricalTeammateInfo = nop
            DSReportPlayerSubsystem._SyncFatalDamagerMap = nop
            DSReportPlayerSubsystem._AddGameModeTypeToBattleResult = nop
            DSReportPlayerSubsystem._UpdateMLAIUID = nop
            DSReportPlayerSubsystem._AddEnemyMapToBattleResult = nop
            DSReportPlayerSubsystem._OnNoNetStartUpDoor = nop
            DSReportPlayerSubsystem._AssignTeammateInTeamIndex = nop
            DSReportPlayerSubsystem._FindCacheByUID = function(self, nUID, bAddIfNotExists)
                if bAddIfNotExists then return {} end
                return nil
            end
            DSReportPlayerSubsystem._GetFatalDamagerMap = retEmpty
            DSReportPlayerSubsystem._IsBattleResultTableValid = nopfalse
            DSReportPlayerSubsystem._IsHealthStatusKilled = nopfalse
            DSReportPlayerSubsystem._tUID2InfoMap = {}
            DSReportPlayerSubsystem.nNoStartUpDoorNum = 0
        end
        if ui_complaint then
            ui_complaint.SubmitReportData = function(self) self:CloseWindow(false) return end
            ui_complaint._OnClickReport = function(self) return end
            ui_complaint._AddCommonTypesOfPlayerForReport = function(self) return end
            ui_complaint.AddPlayerForReport = function(self, ...) return end
            ui_complaint.GetSelectedReasonAsArray = retEmpty
            ui_complaint.GetSelectedSubReasonAsArray = retEmpty
            ui_complaint.BlockPlayerChat = function(self) return end
            ui_complaint.IsBlockChatCheck = retFalse
            ui_complaint.CheckBoxBlack = function(self, bCheckState) return end
            ui_complaint.UpdateMatchBlackList = function(self) return end
            ui_complaint._SelectedReasonSet = {}
            ui_complaint._SelectedSubReasonSet = {}
            ui_complaint._SelectedCheatSubReasonSet = {}
            ui_complaint._tPlayerName2InfoMap = {}
            ui_complaint._tPlayerNamesArray = {}
        end
        if LogicComplaint then
            LogicComplaint.Submit = function(...) return end
        end
        
        local ReportCooldown = package.loaded["client.slua.logic.report.ReportCooldownLogic"]
        if ReportCooldown then
            ReportCooldown.CheckCanReport = retFalse
            ReportCooldown.GetCooldownTime = retZero
            ReportCooldown.ResetCooldown = nop
            ReportCooldown.OnReportCooldownEnd = nop
        end
        
        local PlayerReport = package.loaded["client.slua.logic.report.PlayerReportLogic"]
        if PlayerReport then
            PlayerReport.SendReport = nop
            PlayerReport.ReportCheat = nop
            PlayerReport.ReportAbuse = nop
            PlayerReport.ReportAFK = nop
            PlayerReport.ReportTeammate = nop
            PlayerReport.OnReportResponse = nop
        end
    end)
    print("[BYPASS] ✅ Report System Bypass Done @hacker420official")
end

-- ============================================================
-- 33. TLog Report Bypass @hacker420official
-- ============================================================

local function TLogBypass()
    pcall(function()
        if tlog_report_utils then
            tlog_report_utils.ReportTLogEvent = nop
            tlog_report_utils.IsCanReportLobbyEvent = nopfalse
            tlog_report_utils.IsBusinessReport = nopfalse
            tlog_report_utils.SetMarketStayUpdateEnable = nop
            tlog_report_utils.GetMarketStayUpdateEnable = nopfalse
            tlog_report_utils.SetBusinessReportEnable = nop
            tlog_report_utils.SendTLogReportImmediate = nop
            tlog_report_utils.SetTlogBeginType = nop
            tlog_report_utils.SetTlogEndType = nop
            _G.SendTLogReportImmediate = nop
            _extraTlogReportEnableCfg = {}
            _isCanReportMarketStay = false
            _BusinessReportEnable = false
            _isInitConfig = true
            start_timestamp_map = {}
        end
        if ToolReportUtil then
            ToolReportUtil.GetReportSwitch = nopfalse
            ToolReportUtil.GetPackageInfo = nopnil
            ToolReportUtil.ReParseError = function(error, reportType) return error or "" end
            ToolReportUtil.IsReleaseVersion = noptrue
            ToolReportUtil.IsWhite = nopfalse
            ToolReportUtil.IsXPcallOpenInBattle = nopfalse
            ToolReportUtil.IsClientToolOpen = nopfalse
            MyOpenID = false
            MyUID = false
            VersionInfo = nil
        end
        if DSSecurityTLogSubsystem then
            DSSecurityTLogSubsystem.OnInit = nop
            DSSecurityTLogSubsystem._OnReportServerJumpFlow = nop
            DSSecurityTLogSubsystem._OnDevAlert = nop
            DSSecurityTLogSubsystem._InitWhenEditor = nop
            DSSecurityTLogSubsystem._nInitGameSafeCallbacksTimer = nil
        end
        if _G.TLog then
            _G.TLog.Info = nop
            _G.TLog.Warning = nop
            _G.TLog.Error = nop
            _G.TLog.Debug = nop
            _G.TLog.Report = nop
            _G.TLog.Send = nop
            _G.TLog.Flush = nop
        end
    end)
    print("[BYPASS] ✅ TLog Report Bypass Done @hacker420official")
end

-- ============================================================
-- 34. MD5 and Signature Bypass @hacker420official
-- ============================================================

local function MD5Bypass()
    pcall(function()
        local console = import("KismetSystemLibrary")
        if console then
            console.ExecuteConsoleCommand(nil, "pak.DisablePakSignatureCheck 1")
            console.ExecuteConsoleCommand(nil, "pakchunk.EnableSignatureCheck 0")
            console.ExecuteConsoleCommand(nil, "s.VerifyPak 0")
            console.ExecuteConsoleCommand(nil, "sig.Check 0")
            console.ExecuteConsoleCommand(nil, "security.DisableChecks 1")
            console.ExecuteConsoleCommand(nil, "CheatManager.EnableCheat 1")
            console.ExecuteConsoleCommand(nil, "Net.BlockAllAntiCheat 1")
            console.ExecuteConsoleCommand(nil, "AntiCheat.DisableAll 1")
            console.ExecuteConsoleCommand(nil, "t.MaxFPS 165")
        end
        local CMode = import("CreativeModeBlueprintLibrary")
        if CMode then
            CMode.MD5HashByteArray = function() return "00000000000000000000000000000000" end
            CMode.MD5HashFile = function() return "00000000000000000000000000000000" end
            CMode.GetContentDiffData = function() return true, "BYPASSED" end
            CMode.VerifyFileIntegrity = retTrue
        end
        if _G.MD5Hash then _G.MD5Hash = function() return "00000000000000000000000000000000" end end
        if _G.CRC32 then _G.CRC32 = function() return 0 end end
        if _G.SHA1 then _G.SHA1 = function() return "BYPASS" end end
        if _G.SHA256 then _G.SHA256 = function() return "BYPASS" end end
        if _G.FileHashChecker then
            _G.FileHashChecker.CheckFileMD5 = retTrue
            _G.FileHashChecker.VerifyAll = retTrue
            _G.FileHashChecker.GetHash = function() return "BYPASS" end
        end
        if _G.STExtraBlueprintFunctionLibrary then
            _G.STExtraBlueprintFunctionLibrary.CheckMD5 = retTrue
            _G.STExtraBlueprintFunctionLibrary.GetMD5 = function() return "BYPASS" end
            _G.STExtraBlueprintFunctionLibrary.VerifyFile = retTrue
            _G.STExtraBlueprintFunctionLibrary.VerifySignature = retTrue
            _G.STExtraBlueprintFunctionLibrary.CheckIntegrity = retTrue
        end
        if _G.CRC then
            _G.CRC.VerifyFile = retTrue
            _G.CRC.VerifyMemory = retTrue
            _G.CRC.GenerateCRC = function() return "00000000" end
        end
        if _G.CRCChecker then
            _G.CRCChecker.VerifyFile = retTrue
            _G.CRCChecker.VerifyMemory = retTrue
            _G.CRCChecker.GenerateCRC = function() return "00000000" end
            _G.CRCChecker.CheckIntegrity = retTrue
            _G.CRCChecker.ValidateFile = retTrue
            _G.CRCChecker.ValidateMemory = retTrue
            _G.CRCChecker.CheckFile = retTrue
            _G.CRCChecker.CheckMemory = retTrue
            _G.CRCChecker.VerifyCRC = retTrue
            _G.CRCChecker.ValidateCRC = retTrue
            _G.CRCChecker.CheckCRC = retTrue
            _G.CRCChecker.GenerateCRC32 = function() return "00000000" end
            _G.CRCChecker.GenerateCRC64 = function() return "0000000000000000" end
            _G.CRCChecker.GenerateMD5 = function() return "00000000000000000000000000000000" end
            _G.CRCChecker.GenerateSHA1 = function() return "0000000000000000000000000000000000000000" end
            _G.CRCChecker.GenerateSHA256 = function() return "0000000000000000000000000000000000000000000000000000000000000000" end
        end
    end)
    print("[BYPASS] ✅ MD5 and Signature Bypass Done @hacker420official")
end

-- ============================================================
-- 35. DNS and Device Bypass @hacker420official
-- ============================================================

local function DNSDeviceBypass()
    pcall(function()
        local DeviceID = import("DeviceID")
        if DeviceID then
            DeviceID.GetDeviceID = function() return "BYPASSED_DEVICE" end
            DeviceID.GetAndroidID = function() return "BYPASSED_ANDROID_ID" end
            DeviceID.GetIMEI = function() return "BYPASSED_IMEI" end
            DeviceID.GetMACAddress = function() return "BYPASSED_MAC" end
            DeviceID.GetUniqueDeviceID = function() return "BYPASSED_UNIQUE" end
            DeviceID.GetDeviceName = function() return "BYPASSED_DEVICE_NAME" end
            DeviceID.GetDeviceModel = function() return "BYPASSED_MODEL" end
            DeviceID.GetDeviceBrand = function() return "BYPASSED_BRAND" end
            DeviceID.GetDeviceManufacturer = function() return "BYPASSED_MANUFACTURER" end
            DeviceID.GetDeviceBoard = function() return "BYPASSED_BOARD" end
            DeviceID.GetDeviceBootloader = function() return "BYPASSED_BOOTLOADER" end
            DeviceID.GetDeviceHardware = function() return "BYPASSED_HARDWARE" end
            DeviceID.GetDeviceHost = function() return "BYPASSED_HOST" end
            DeviceID.GetDeviceFingerprint = function() return "BYPASSED_FINGERPRINT" end
            DeviceID.GetDeviceSerial = function() return "BYPASSED_SERIAL" end
            DeviceID.GetDeviceUUID = function() return "BYPASSED_UUID" end
            DeviceID.GetDeviceAdId = function() return "BYPASSED_ADID" end
        end
        
        local SystemInfo = import("SystemInfo")
        if SystemInfo then
            SystemInfo.GetDeviceModel = function() return "iPhone14,5" end
            SystemInfo.GetDeviceBrand = function() return "Apple" end
            SystemInfo.GetAndroidVersion = function() return "13" end
            SystemInfo.GetEMUIVersion = function() return "" end
            SystemInfo.IsEmulator = retFalse
            SystemInfo.IsRooted = retFalse
            SystemInfo.IsDebugged = retFalse
            SystemInfo.GetKernelVersion = function() return "Linux version 4.14.116" end
            SystemInfo.CheckKernelIntegrity = retTrue
            SystemInfo.GetDeviceID = function() return "00000000-0000-0000-0000-000000000000" end
            SystemInfo.GetDeviceName = function() return "iPhone" end
            SystemInfo.GetDeviceType = function() return "Phone" end
            SystemInfo.GetManufacturer = function() return "Apple" end
            SystemInfo.GetModel = function() return "iPhone14,5" end
            SystemInfo.GetOSVersion = function() return "13" end
            SystemInfo.GetOSName = function() return "iOS" end
            SystemInfo.GetScreenResolution = function() return "1170x2532" end
            SystemInfo.GetScreenDensity = function() return "460" end
            SystemInfo.GetRAMSize = function() return "6144" end
            SystemInfo.GetStorageSize = function() return "256" end
            SystemInfo.GetBatteryLevel = function() return "100" end
            SystemInfo.GetBatteryStatus = function() return "Charging" end
            SystemInfo.GetNetworkType = function() return "WiFi" end
            SystemInfo.GetNetworkSpeed = function() return "100" end
            SystemInfo.GetGPSStatus = function() return "Enabled" end
            SystemInfo.GetGPSLocation = function() return "0.0,0.0" end
            SystemInfo.GetCountryCode = function() return "US" end
            SystemInfo.GetLanguageCode = function() return "en" end
            SystemInfo.GetTimeZone = function() return "UTC" end
            SystemInfo.GetCurrentTime = function() return os.time() end
            SystemInfo.GetUptime = function() return 3600 end
            SystemInfo.GetCPUUsage = function() return 10 end
            SystemInfo.GetMemoryUsage = function() return 20 end
            SystemInfo.GetTemperature = function() return 25 end
            SystemInfo.GetBatteryTemperature = function() return 25 end
            SystemInfo.GetCPUFrequency = function() return 2400 end
            SystemInfo.GetGPUFrequency = function() return 1200 end
            SystemInfo.GetScreenBrightness = function() return 100 end
            SystemInfo.GetVolumeLevel = function() return 100 end
        end
        
        local sys = import("KismetSystemLibrary")
        if sys then
            sys.GetDeviceId = function() return "FAKE_DEVICE_" .. math.random(100000,999999) end
            sys.GetMacAddress = function() return "00:11:22:33:44:55" end
            sys.GetSerialNumber = function() return "SN" .. math.random(1000000,9999999) end
        end
        
        if _G.DeviceInfo then
            _G.DeviceInfo.IsEmulator = false
            _G.DeviceInfo.IsRooted = false
            _G.DeviceInfo.IsDebug = false
            _G.DeviceInfo.IsJailbroken = false
            _G.DeviceInfo.IsDeveloperMode = false
            _G.DeviceInfo.IsUSBConnected = false
            _G.DeviceInfo.IsModded = false
            _G.DeviceInfo.IsHooked = false
            _G.DeviceInfo.IsVirtualMachine = false
            _G.DeviceInfo.IsSimulator = false
            _G.DeviceInfo.DeviceID = "BYPASS-DEVICE-2026"
            _G.DeviceInfo.DeviceSignature = "VALID-SIGNATURE"
        end
    end)
    print("[BYPASS] ✅ DNS and Device Bypass Done @hacker420official")
end

-- ============================================================
-- 36. Gokuba Bypass @hacker420official
-- ============================================================

local function GokubaBypass()
    pcall(function()
        local Gokuba = package.loaded["GameLua.Mod.BaseMod.Client.Security.Gokuba"]
        if Gokuba then
            Gokuba.ForwardFeature = function() return {0,0,0,0,0} end
            Gokuba.InitGokubaLogic = nop
            if Gokuba.TimerHandle then
                local time_ticker = _safe_require("common.time_ticker")
                time_ticker.RemoveTimer(Gokuba.TimerHandle)
                Gokuba.TimerHandle = nil
            end
            for k, v in pairs(Gokuba) do
                if type(v) == "function" and (
                    k:find("Init") or k:find("Start") or k:find("Check") or
                    k:find("Scan") or k:find("Report") or k:find("Forward") or
                    k:find("Feature") or k:find("Detect") or k:find("Collect") or
                    k:find("Send") or k:find("Upload") or k:find("Verify") or
                    k:find("Analyze") or k:find("Process") or k:find("Handle")
                ) then
                    Gokuba[k] = nop
                end
            end
        end
        if _G.GokubaLogic then
            _G.GokubaLogic.ForwardFeature = nop
            _G.GokubaLogic.InitGokubaLogic = nop
        end
    end)
    print("[BYPASS] ✅ Gokuba Bypass Done @hacker420official")
end

-- ============================================================
-- 37. Racing AntiCheat Bypass @hacker420official
-- ============================================================

local function RacingAntiCheatBypass()
    pcall(function()
        if RacingAntiCheatLogic then
            RacingAntiCheatLogic.HandleRacingEnter = nop
            RacingAntiCheatLogic.HandleRacingStart = nop
            RacingAntiCheatLogic.HandleRacingEnd = nop
            RacingAntiCheatLogic.StartDetectTimer = nop
            RacingAntiCheatLogic.StopDetectTimer = nop
            RacingAntiCheatLogic.DetectVehicleFloating = nop
            RacingAntiCheatLogic.HandleFloatingCheat = nop
            RacingAntiCheatLogic.SetIgnoreFloating = nop
            RacingAntiCheatLogic.HandlePlayerPassCheckBelt = nop
            RacingAntiCheatLogic.HandleSpeedCheat = nop
            RacingAntiCheatLogic._CreateVehicleData = function() return {} end
            RacingAntiCheatLogic.vehicleDataMap = {}
            RacingAntiCheatLogic.detectTimer = nil
            RacingAntiCheatLogic.config = {
                FloatingDistLimit = 99999,
                FloatingTimeLimit = 99999,
                CheckPassIntervalLimit = 99999
            }
        end
    end)
    print("[BYPASS] ✅ Racing AntiCheat Bypass Done @hacker420official")
end

-- ============================================================
-- 38. CoronaLab Telemetry Bypass @hacker420official
-- ============================================================

local function CoronaLabBypass()
    pcall(function()
        _G.LocalMain = function()
            print("[BYPASS] CoronaLab telemetry timer @hacker420official!")
            return
        end
        local uOuterController = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if _isValid(uOuterController) and uOuterController.AddGameTimer then
            local orig = uOuterController.AddGameTimer
            uOuterController.AddGameTimer = function(interval, bLoop, func, ...)
                if interval == 30 and bLoop == true then
                    return nil
                end
                return orig(interval, bLoop, func, ...)
            end
        end
        if CHiggsBosonComponent then
            CHiggsBosonComponent.SecurityCoronaLabClientDataPointer = function(self) return nil end
            CHiggsBosonComponent.SetFloatValueByName = function(self, name, value) return end
        end
        if _G.CoronaLab then
            _G.CoronaLab.ReportData = nop
            _G.CoronaLab.SendData = nop
            _G.CoronaLab.CollectData = nop
            _G.CoronaLab.Telemetry = nop
        end
        local SubMgr = _safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubMgr then
            local sub = SubMgr:Get("CoronaLabSubsystem")
            if sub then
                sub.ReportData = nop
                sub.SendToServer = nop
                sub.CollectTelemetry = nop
                sub.StopCollection = nop
            end
        end
    end)
    print("[BYPASS] ✅ CoronaLab Telemetry Bypass Done @hacker420official")
end

-- ============================================================
-- 39. Login Module Bypass @hacker420official
-- ============================================================

local function LoginModuleBypass()
    pcall(function()
        if login_module then
            login_module["ban-login"] = function() return end
            login_module["idip-kick-out"] = function() return end
            login_module.aq_ban = function() return end
            login_module["device-in-blacklist"] = function() return end
            login_module.device_num_limit = function() return end
            login_module["register-forbidden"] = function() return end
            login_module["low-version"] = function() return end
            login_module["not-in-white-list"] = function() return end
            login_module.Login_Failed = function() return end
            login_module.aas_ban = function() return end
            login_module.PakMonitorStart = function(EnableMode) return end
            login_module.SetupFilenameHideKeywords = function() return end
            login_module.on_login_failed = function(conn_idx, reason, banInfo, banTime, uid, extra_table) return end
            login_module.DelaybanLoginCancelCallback = function() return end
            login_module.CheckBan = retFalse
            login_module.IsBanned = retFalse
            login_module.GetBanInfo = retEmpty
            login_module.IsDeviceBlacklisted = retFalse
        end
    end)
    print("[BYPASS] ✅ Login Module Bypass Done @hacker420official")
end

-- ============================================================
-- 40. Swift Hawk Bypass @hacker420official
-- ============================================================

local function SwiftHawkBypass()
    pcall(function()
        for _, f in ipairs({"SwiftHawk", "ClientSwiftHawk", "ClientSwiftHawkWithParams", "SendSwiftHawkData", "SwiftHawkReport"}) do
            if _G[f] then _G[f] = nop end
            if _G.GameplayCallbacks and _G.GameplayCallbacks[f] then _G.GameplayCallbacks[f] = nop end
        end
        local sub = package.loaded["GameLua.Mod.BaseMod.Client.Security.SwiftHawkSubsystem"]
        if sub then
            sub.ReportData = nop
            sub.SendReport = nop
            sub.CollectTelemetry = nop
            sub.InitSubsystem = nop
            sub.StartCollection = nop
            sub.StopCollection = nop
        end
    end)
    print("[BYPASS] ✅ @hacker420official")
end

-- ============================================================
-- 46. @hacker420official
-- ============================================================

local function ShootVerificationBypass()
    pcall(function()
        local sub = _safe_require("GameLua.Dev.Subsystem.ShootVerifySubSystemClient")
        if sub then
            sub.OnShootVerifyFailed = nop
            sub.SendVerifyData = nop
            sub.ReportBulletHit = nop
            sub.UploadHitInfo = nop
            sub.VerifyShot = retTrue
            sub.CheckShoot = retTrue
            sub.ValidateShoot = retTrue
            sub.IsShootValid = retTrue
            sub.ReportInvalidShoot = nop
            sub.ResetShootData = nop
        end
        if _G.BulletHitInfoUploadData then
            _G.BulletHitInfoUploadData.Report = nop
            _G.BulletHitInfoUploadData.Send = nop
            _G.BulletHitInfoUploadData.Upload = nop
            _G.BulletHitInfoUploadData.Verify = retTrue
            _G.BulletHitInfoUploadData.Validate = retTrue
            _G.BulletHitInfoUploadData.Reset = nop
        end
        
        local ShootVerification = import("ShootVerification")
        if ShootVerification then
            ShootVerification.VerifyShoot = retTrue
            ShootVerification.ReportInvalidShoot = nop
            ShootVerification.CheckShoot = retTrue
            ShootVerification.ValidateShoot = retTrue
            ShootVerification.IsShootValid = retTrue
        end
        
        local BulletVerification = import("BulletVerification")
        if BulletVerification then
            BulletVerification.VerifyBullet = retTrue
            BulletVerification.ReportInvalidBullet = nop
            BulletVerification.CheckBullet = retTrue
            BulletVerification.ValidateBullet = retTrue
            BulletVerification.IsBulletValid = retTrue
        end
    end)
    print("[BYPASS] ✅ @hacker420official")
end

-- ============================================================
-- 42. @hacker420official
-- ============================================================

local function ModifierExceptionBypass()
    pcall(function()
        if _G.bReportedModifierException then _G.bReportedModifierException = false end
        local sub = _safe_require("GameLua.Mod.BaseMod.Common.Security.ModifierExceptionSubsystem")
        if sub then
            sub.ReportException = nop
            sub.CheckModifier = retTrue
            sub.ValidateModifier = retTrue
            sub.ReportModifierError = nop
            sub.DetectModifier = retFalse
            sub.IsModifierValid = retTrue
        end
    end)
    print("[BYPASS] ✅ @hacker420official")
end

-- ============================================================
-- 43. @hacker420official
-- ============================================================

local function SimulateCharacterBypass()
    pcall(function()
        local sub = _safe_require("GameLua.Mod.BaseMod.Gameplay.Simulate.SimulateCharacterSubsystem")
        if sub then
            sub.ReportLocation = nop
            sub.SendLocationData = nop
            sub.VerifyLocation = retTrue
            sub.CheckLocation = retTrue
            sub.ValidateMovement = retTrue
        end
    end)
    print("[BYPASS] ✅ @hacker420official")
end

-- ============================================================
-- 44. @hacker420official
-- ============================================================

local function PlayerSecurityBypass()
    pcall(function()
        for _, c in ipairs({"PlayerSecurityInfoCollector", "PlayerSecurityInfo", "SecurityInfoCollector", "ClientSecurityCollector", "PlayerAntiCheatCollector"}) do
            if _G[c] then
                for k, v in pairs(_G[c]) do
                    if type(v) == "function" and (
                        k:find("Report") or k:find("Collect") or k:find("Send") or
                        k:find("Upload") or k:find("Record") or k:find("Check") or
                        k:find("Verify") or k:find("Validate") or k:find("Scan") or
                        k:find("Analyze") or k:find("Process") or k:find("Handle") or
                        k:find("Submit") or k:find("Notify") or k:find("Alert")
                    ) then
                        _G[c][k] = nop
                    end
                end
            end
        end
        local SecSub = _safe_require("GameLua.Mod.BaseMod.Common.Security.PlayerSecurityInfoSubsystem")
        if SecSub then
            SecSub.ReportData = nop
            SecSub.CheckCheat = retFalse
            SecSub.ValidatePlayer = retTrue
            SecSub.CollectData = nop
            SecSub.SendToServer = nop
            SecSub.ProcessData = nop
            SecSub.AnalyzeData = nop
        end
        
        local SecurityCommonUtils = package.loaded["GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils"]
        if SecurityCommonUtils then
            SecurityCommonUtils.ExtractPlayerBasicInfo = retEmpty
            SecurityCommonUtils.LogIf = retFalse
            SecurityCommonUtils.CheckSecurity = retTrue
            SecurityCommonUtils.ValidatePlayer = retTrue
            SecurityCommonUtils.ValidateSession = retTrue
            SecurityCommonUtils.ValidateGame = retTrue
            SecurityCommonUtils.ValidateSystem = retTrue
            SecurityCommonUtils.ValidateDevice = retTrue
            SecurityCommonUtils.ValidateNetwork = retTrue
            SecurityCommonUtils.ValidateMemory = retTrue
            SecurityCommonUtils.ValidateFile = retTrue
            SecurityCommonUtils.ValidateProcess = retTrue
            SecurityCommonUtils.ValidateThread = retTrue
            SecurityCommonUtils.ValidateModule = retTrue
            SecurityCommonUtils.ValidateAPI = retTrue
            SecurityCommonUtils.ValidateSDK = retTrue
            SecurityCommonUtils.ValidateLibrary = retTrue
            SecurityCommonUtils.ValidateFramework = retTrue
            SecurityCommonUtils.ValidatePackage = retTrue
            SecurityCommonUtils.ValidateContainer = retTrue
            SecurityCommonUtils.ValidateComponent = retTrue
            SecurityCommonUtils.ValidateObject = retTrue
            SecurityCommonUtils.ValidateClass = retTrue
            SecurityCommonUtils.ValidateStruct = retTrue
            SecurityCommonUtils.ValidateEnum = retTrue
            SecurityCommonUtils.ValidateInterface = retTrue
            SecurityCommonUtils.ValidateDelegate = retTrue
            SecurityCommonUtils.ValidateEvent = retTrue
            SecurityCommonUtils.ValidateFunction = retTrue
            SecurityCommonUtils.ValidateVariable = retTrue
            SecurityCommonUtils.ValidateProperty = retTrue
            SecurityCommonUtils.ValidateField = retTrue
            SecurityCommonUtils.ValidateMethod = retTrue
            SecurityCommonUtils.ValidateParameter = retTrue
            SecurityCommonUtils.ValidateReturn = retTrue
            SecurityCommonUtils.ValidateResult = retTrue
            SecurityCommonUtils.ValidateOutput = retTrue
            SecurityCommonUtils.ValidateInput = retTrue
        end
        
        local SecurityNotifyPCFeature = package.loaded["GameLua.Mod.BaseMod.Common.Security.SecurityNotifyPCFeature"]
        if SecurityNotifyPCFeature then
            SecurityNotifyPCFeature.ClientRPC_SyncBanID = nop
            SecurityNotifyPCFeature.ClientRPC_StrongTips = nop
            SecurityNotifyPCFeature.ClientRPC_NormalTips = nop
            SecurityNotifyPCFeature.Notify = nop
            SecurityNotifyPCFeature.ShowBan = nop
            SecurityNotifyPCFeature.ShowKick = nop
            SecurityNotifyPCFeature.ShowWarning = nop
            SecurityNotifyPCFeature.ShowInfo = nop
            SecurityNotifyPCFeature.ShowError = nop
            SecurityNotifyPCFeature.ShowFatal = nop
            SecurityNotifyPCFeature.ShowPanic = nop
            SecurityNotifyPCFeature.ShowAlert = nop
            SecurityNotifyPCFeature.ShowNotification = nop
            SecurityNotifyPCFeature.ShowMessage = nop
            SecurityNotifyPCFeature.ShowDialog = nop
            SecurityNotifyPCFeature.ShowPopup = nop
            SecurityNotifyPCFeature.ShowToast = nop
            SecurityNotifyPCFeature.ShowSnackbar = nop
            SecurityNotifyPCFeature.ShowBanner = nop
            SecurityNotifyPCFeature.ShowAlertDialog = nop
            SecurityNotifyPCFeature.ShowConfirmDialog = nop
            SecurityNotifyPCFeature.ShowPromptDialog = nop
            SecurityNotifyPCFeature.ShowInputDialog = nop
            SecurityNotifyPCFeature.ShowSelectDialog = nop
            SecurityNotifyPCFeature.ShowProgressDialog = nop
            SecurityNotifyPCFeature.ShowLoadingDialog = nop
            SecurityNotifyPCFeature.ShowSuccessDialog = nop
            SecurityNotifyPCFeature.ShowFailureDialog = nop
            SecurityNotifyPCFeature.ShowErrorDialog = nop
            SecurityNotifyPCFeature.ShowWarningDialog = nop
            SecurityNotifyPCFeature.ShowInfoDialog = nop
        end
    end)
    print("[BYPASS] ✅ @hacker420official")
end

-- ============================================================
-- 45. @hacker420official
-- ============================================================

local function ClientFlowBypass()
    pcall(function()
        for _, name in ipairs({"ClientSecMrpcsFlow", "MrpcsFlow", "MrpcsData", "ClientCircleFlowSubsystem", "ClientKillFlowSubsystem", "ClientSecPlayerKillFlow"}) do
            local sub = package.loaded[name] or _G[name]
            if sub then
                for k, v in pairs(sub) do
                    if type(v) == "function" and (
                        k:find("Report") or k:find("Send") or k:find("Flow") or
                        k:find("Record") or k:find("Process") or k:find("Upload") or
                        k:find("Track") or k:find("Monitor") or k:find("Analyze") or
                        k:find("Submit") or k:find("Notify") or k:find("Alert")
                    ) then
                        pcall(function() sub[k] = nop end)
                    end
                end
            end
        end
    end)
    print("[BYPASS] ✅ @hacker420official")
end

-- ============================================================
-- 46. @hacker420official
-- ============================================================
local function GameplayCallbackBypass()
    pcall(function()
        if not _G.GameplayCallbacks then _G.GameplayCallbacks = {} end
        if _G.GameplayCallbacks.IsBypassed then return end
        local GC = _G.GameplayCallbacks
        
        local reports = {
            "ReportAttackFlow", "ReportSecAttackFlow", "ReportFireArms", 
            "ReportVerifyInfoFlow", "ReportMrpcsFlow", "ReportPlayerBehavior", 
            "ReportTeammatHurt", "ReportMisKillByTeammate", "ReportForbitPick", 
            "ReportPlayerMoveRoute", "ReportPlayerPosition", "ReportVehicleMoveFlow", 
            "ReportSecTgameMovingFlow", "ReportParachuteData", "SendTssSdkAntiDataToLobby", 
            "ReportEquipmentFlow", "ReportAimFlow", "ReportPlayersPing", 
            "ReportPlayerIP", "ReportPlayerFramePingRecord", "OnDSConnectionSaturated", 
            "ReportDSNetSaturation", "ReportNetContinuousSaturate", "ReportDSNetRate", 
            "SendClientStats", "SendServerAvgTickDelta", "ReportCircleFlow", 
            "ClientSecMrpcsFlow", "SwiftHawk", "ClientSwiftHawk", "ClientSwiftHawkWithParams",
            "ReportSecurityViolation", "ReportIntegrityCheck", "ReportSignatureVerify",
            "ReportAntiCheat", "ReportAC", "ReportSuspicious", "ReportAbnormal",
            "ReportMagicBullet", "ReportDamage", "ReportHitbox", "ReportProjectile",
            "ReportBullet", "ReportShoot", "ReportVerification",
            "ReportSkin", "ReportAvatar", "ReportWeapon", "ReportVehicle",
            "ReportBan", "ReportKick", "ReportFlag", "ReportWarning",
            "ReportAlert", "ReportNotify", "ReportException", "ReportError",
            "ReportCrash", "ReportDump", "ReportMemory", "ReportStack",
            "ReportProfiler", "ReportPerformance", "ReportStats",
            "ReportGameGuardian", "ReportCheatEngine", "ReportRoot", "ReportJailbreak",
            "ReportEmulator", "ReportTamper", "ReportSpeedHack", "ReportESP", 
            "ReportWallhack", "ReportNoRecoil", "ReportPlayerReport"
        }
        for _, f in ipairs(reports) do GC[f] = nop end
        
        GC.CheckReportSecAttackFlowWithAttackFlow = retFalse
        GC.CheckReportSecAttackFlow = retFalse
        
        local origState = GC.OnDSPlayerStateChanged
        GC.OnDSPlayerStateChanged = function(UID, State, bPure, bSafe, Param)
            local s = State and string.lower(tostring(State)) or ""
            local blocked = {
                ["cheatdetected"]=1, ["connectionlost"]=1, ["connectiontimeout"]=1, 
                ["connectionexception"]=1, ["netdrivererror"]=1, ["banned"]=1, 
                ["kicked"]=1, ["suspended"]=1, ["violationdetected"]=1, 
                ["integrityfailure"]=1, ["securityviolation"]=1, ["report"]=1,
                ["ban"]=1, ["detect"]=1, ["flag"]=1, ["hack"]=1,
                ["anti"]=1, ["ac_"]=1, ["beacon"]=1, ["monitor"]=1,
                ["alert"]=1, ["warning"]=1, ["error"]=1, ["exception"]=1,
                ["crash"]=1, ["dump"]=1, ["stack"]=1, ["memory"]=1,
                ["profiler"]=1, ["performance"]=1, ["stats"]=1,
                ["magic"]=1, ["bullet"]=1, ["hitbox"]=1, ["damage"]=1,
                ["projectile"]=1, ["shoot"]=1, ["verification"]=1,
                ["skin"]=1, ["avatar"]=1, ["weapon"]=1, ["vehicle"]=1,
                ["gameguardian"]=1, ["cheatengine"]=1, ["root"]=1, ["jailbreak"]=1,
                ["emulator"]=1, ["tamper"]=1, ["speedhack"]=1, ["esp"]=1,
                ["wallhack"]=1, ["norecoil"]=1, ["playerreport"]=1
            }
            if blocked[s] then return end
            if origState then pcall(origState, UID, State, bPure, bSafe, Param) end
        end
        
        GC.OnPlayerNetConnectionClosed = nop
        GC.OnPlayerActorChannelError = nop
        GC.OnPlayerRPCValidateFailed = nop
        GC.OnPlayerSpectateException = nop
        GC.OnShutdownAfterError = nop
        GC.OnPlayerDisconnect = nop
        GC.OnPlayerTimeout = nop
        GC.OnPlayerKicked = nop
        GC.OnPlayerBanned = nop
        GC.IsBypassed = true
    end)
        print("[BYPASS] ✅ @hacker420official")
end

-- ============================================================
-- 47. @hacker420official
-- ============================================================

-- ============================================================
-- 48. @hacker420official
-- ============================================================

local function SLUABypass()
    pcall(function()
        if slua and slua.getSignature then slua.getSignature = function() return 0xDEADBEEF end end
        local loader = package.loaded["slua.loader"] or rawget(_G, "slua_loader")
        if loader then
            loader.verifyBytecode = retTrue
            loader.checkIntegrity = retTrue
            if loader.disableSignatureCheck then loader.disableSignatureCheck = retTrue end
        end
        local slua_serialize = package.loaded["slua.serialize"]
        if slua_serialize then
            slua_serialize.check = retTrue
            slua_serialize.verify = retTrue
        end
        if _G.slua_verify then _G.slua_verify = retTrue end
        if _G.check_slua_integrity then _G.check_slua_integrity = retTrue end
        if _G.slua_loader then
            _G.slua_loader.verifyBytecode = retTrue
            _G.slua_loader.checkIntegrity = retTrue
        end
        if _G.slua_check then _G.slua_check = retTrue end
        if _G.slua_validate then _G.slua_validate = retTrue end
    end)
    print("[BYPASS] ✅ @hacker420official")
end

-- ============================================================
-- 49. @hacker420official
-- ===============================================================

local function ReplayTelemetryBypass()
    pcall(function()
        if _G.Replay then
            _G.Replay.Record = nop
            _G.Replay.StopRecord = nop
            _G.Replay.Save = nop
            _G.Replay.Upload = nop
            _G.Replay.Report = nop
            _G.Replay.Telemetry = nop
            _G.Replay.Analytics = nop
        end
        if _G.Telemetry then
            _G.Telemetry.Send = nop
            _G.Telemetry.Report = nop
            _G.Telemetry.Track = nop
            _G.Telemetry.Log = nop
            _G.Telemetry.Collect = nop
            _G.Telemetry.Upload = nop
        end
        if _G.Analytics then
            _G.Analytics.Send = nop
            _G.Analytics.Report = nop
            _G.Analytics.Track = nop
            _G.Analytics.Log = nop
            _G.Analytics.Collect = nop
        end
        if _G.Firebase then
            _G.Firebase.logEvent = nop
            _G.Firebase.trackEvent = nop
            _G.Firebase.setEnabled = retFalse
            _G.Firebase.sendEvent = nop
            _G.Firebase.report = nop
        end
        if _G.Adjust then
            _G.Adjust.logEvent = nop
            _G.Adjust.trackEvent = nop
            _G.Adjust.setEnabled = retFalse
            _G.Adjust.sendEvent = nop
        end
        if _G.AppsFlyer then
            _G.AppsFlyer.logEvent = nop
            _G.AppsFlyer.trackEvent = nop
            _G.AppsFlyer.setEnabled = retFalse
            _G.AppsFlyer.sendEvent = nop
        end
        
               if _G.Crashlytics then _G.Crashlytics.Report = nop end
        if _G.Analytics then _G.Analytics.Report = nop end
    end)
    print("[BYPASS] ✅ @hacker420official")
end

-- ============================================================
-- 50. @hacker420official
-- ============================================================


-- ============================================================
-- 51. @hacker420official
-- ============================================================

local function ContinuousProtection()
    pcall(function()
        if _G.BypassPermissions then
            for k, v in pairs(_G.BypassPermissions) do
                _G.BypassPermissions[k] = true
            end
        end
        
        if _G.AntiCheatBlock then
            for k, v in pairs(_G.AntiCheatBlock) do
                _G.AntiCheatBlock[k] = true
            end
        end
        
        local GameplayData = _safe_require("GameLua.GameCore.Data.GameplayData")
        if GameplayData then
            local pc = GameplayData.GetPlayerController()
            if _isValid(pc) then
                if pc.HiggsBoson then
                    pc.HiggsBoson.bMHActive = false
                    pc.HiggsBoson.bCallPreReplication = false
                end
                if pc.HiggsBosonComponent then
                    pc.HiggsBosonComponent.bMHActive = false
                    pc.HiggsBosonComponent.bCallPreReplication = false
                end
            end
        end
        
        local console = import("KismetSystemLibrary")
        if console then
            console.ExecuteConsoleCommand(nil, "pak.DisablePakSignatureCheck 1")
            console.ExecuteConsoleCommand(nil, "security.DisableChecks 1")
            console.ExecuteConsoleCommand(nil, "Net.BlockAllAntiCheat 1")
            console.ExecuteConsoleCommand(nil, "AntiCheat.DisableAll 1")
            console.ExecuteConsoleCommand(nil, "DisableAllScreenMessages")
            console.ExecuteConsoleCommand(nil, "UI.DisableMessageOfTheDay")
            console.ExecuteConsoleCommand(nil, "ShowMOTD 0")
            console.ExecuteConsoleCommand(nil, "r.UI.DisableAll 1")
            console.ExecuteConsoleCommand(nil, "UI.HideAllWidgets 1")
        end
    end)
    
    local ticker = _safe_require("common.time_ticker")
    if ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(2.0, ContinuousProtection)
    end
end


--XXBypass

-- ==================== CRC FAKER ====================
local function deepHook(obj, depth)
    if depth > 4 then return end
    if type(obj) ~= "table" then return end
    for k, v in pairs(obj) do
        if type(k) == "string" then
            local lk = k:lower()
            if lk:find("crc") or lk:find("verify") or lk:find("integrity") or lk:find("hash") or lk:find("paksign") then
                if type(v) == "function" then
                    obj[k] = function(...) if lk:find("crc") or lk:find("hash") then return 0 end; return true end
                end
            end
        end
        if type(v) == "table" and v ~= obj then deepHook(v, depth + 1) end
    end
end

local function applyFullCRCFaker()
    if _G.__CRCFakerDone then return end
    pcall(function()
        if not slua_GameFrontendHUD then return end
        if Client then
            if Client.VerifyPakFile then Client.VerifyPakFile = retTrue end
            if Client.CheckFileCRC then Client.CheckFileCRC = retZero end
            if Client.GetFileHash then Client.GetFileHash = function() return "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF" end end
            if Client.VerifySignature then Client.VerifySignature = retTrue end
            if Client.CheckGameLuaIntegrity then Client.CheckGameLuaIntegrity = retTrue end
            if Client.VerifyFileIntegrity then Client.VerifyFileIntegrity = retTrue end
            if Client.VerifyAllPaks then Client.VerifyAllPaks = retTrue end
        end
        for _, mod in pairs(package.loaded) do if type(mod) == "table" then deepHook(mod, 0) end end
        _G.__CRCFakerDone = true
    end)
end

-- ==================== ADVANCED PATCHES ====================
local function applyAdvancedPatches()
    pcall(function()
        local SubsystemMgr = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubsystemMgr then
            local function patchSub(name, methods, retvals, fields)
                local inst = SubsystemMgr:Get(name)
                if inst then
                    if methods then for k, v in pairs(methods) do if type(inst[k]) == "function" then inst[k] = v end end end
                    if retvals then for k, v in pairs(retvals) do if type(inst[k]) == "function" then inst[k] = v end end end
                    if fields then for k, v in pairs(fields) do inst[k] = v end end
                end
            end
            patchSub("AFKReportorSubsystem", {PlayerHaveAction = noop, ReportAFK = noop})
            patchSub("ClientDataStatistcsSubsystem", nil, nil, {DelayCount = 0})
            patchSub("AvatarExceptionSubsystem", {ReportException = noop, BindPlayerCharacter = noop, CheckAvatarValid = retTrue})
            patchSub("ShootVerifySubSystemClient", {ReportVerifyFail = noop, OnVerifyFailed = noop})
            patchSub("RescueBtnReplayTraceSubsystem", {ReportTrace = noop, StartTickMonitor = noop, TickMonitorCheck = noop, ReportTickMonitorHeartbeat = noop})
            patchSub("GameReportSubsystem", {ReplayReportData = retFalse, CheckCanBugglyPostException = retFalse, BugglyPostExceptionFull = retFalse, GetClientReplayDataReporter = function() return nil end})
            patchSub("ReplaySubsystem", {SendReport = noop, Upload = noop})
            patchSub("ClientFlagSubsystem", {EvaluateFlags = noop, GetFlagLevel = retZero, GetFlagBanDuration = retZero, IsFlagged = retFalse})
            patchSub("DSAITLogSubsystem", {_UpdateTTKRecords = noop, _UpdateOperatingFrequency = noop})
            patchSub("TLogSubsystem", {OnInit = noop})
            local gameReportSub = SubsystemMgr:Get("GameReportSubsystem")
            if gameReportSub and gameReportSub.Reporter then
                gameReportSub.Reporter.ReportIntArrayData = noop
                gameReportSub.Reporter.ReportUInt8ArrayData = noop
                gameReportSub.Reporter.ReportFloatArrayData = noop
            end
        end
    end)
    pcall(function()
        local CreativeMode = import("CreativeModeBlueprintLibrary")
        if CreativeMode then
            CreativeMode.MD5HashByteArray = function() return "BYPASSED_MD5_HASH" end
            CreativeMode.GetContentDiffData = function() return true, "BYPASSED" end
        end
    end)
    pcall(function()
        local AvatarExceptionPlayerInst = package.loaded["GameLua.Mod.Library.GamePlay.Avatar.Exception.AvatarExceptionPlayerInst"]
        if AvatarExceptionPlayerInst then
            AvatarExceptionPlayerInst.CheckAvatarException = noop
            AvatarExceptionPlayerInst.CheckAvatarExceptionOnce = noop
            AvatarExceptionPlayerInst.ReportAvatarException = noop
            AvatarExceptionPlayerInst.CheckSlotMeshVisible = retFalse
            AvatarExceptionPlayerInst.CheckPawnVisible = retFalse
            AvatarExceptionPlayerInst.CheckCanBugglyPostException = retFalse
        end
    end)
    pcall(function()
        local AvatarChecker = package.loaded["blacklist.slua.logic.lobby_gm.AvatarCheckerModule"]
        if AvatarChecker then AvatarChecker.CheckAvatar = retTrue; AvatarChecker.ReportException = noop end
    end)
    pcall(function()
        local MemoryWarning = package.loaded["client.slua.logic.memory_warning.logic_memory_warning"]
        if MemoryWarning then MemoryWarning.OnMemoryWarning = noop; MemoryWarning.ReportMemoryWarning = noop end
    end)
    pcall(function()
        local StoreInterface = package.loaded["client.slua.logic.store.logic_store_game_interface"]
        if StoreInterface then StoreInterface.IsStoreGameSupported = retTrue; StoreInterface.NotifyGetPGSLoginInfo = noop end
    end)
    pcall(function()
        local VoiceSubsystem = package.loaded["GameLua.Mod.BaseMod.Client.Voice.VoiceChatSubsystem"]
        if VoiceSubsystem then VoiceSubsystem.OnPlayerSubmitComplaint = noop end
    end)
    pcall(function()
        local TssSdk = package.loaded["TssSdk"] or _G.TssSdk
        if TssSdk then
            local orig = TssSdk.OnRecvData
            TssSdk.OnRecvData = function(data)
                if type(data) == "string" and (data:find("report") or data:find("exception")) then return end
                if orig then orig(data) end
            end
            TssSdk.SendReportInfo = noop
            TssSdk.ScanMemory = retTrue
            TssSdk.IsEmulator = retFalse
            TssSdk.GetTssSdkReportInfo = function() return "" end
        end
    end)
    pcall(function()
        local logicReplayReport = package.loaded["client.slua.logic.replay.logic_report_replay"]
        if logicReplayReport then logicReplayReport.ReportReplay = noop; logicReplayReport.SendReportReq = noop end
    end)
    pcall(function()
     --   local PufferTlog = package.loaded["client.slua.logic.download.report.puffer_tlog"]
    --    if PufferTlog then PufferTlog.ReportEvent = noop; PufferTlog.ReportDownloadResult = noop; PufferTlog.ReportODPAKError = noop end
    end)
    pcall(function()
        local AvatarUtils = package.loaded["AvatarUtils"]
        if AvatarUtils then AvatarUtils.CheckIsWeaponInBlackList = retFalse; AvatarUtils.IsValidAvatar = retTrue end
    end)
    pcall(function()
        local EquipmentExceptionReport = package.loaded["client.slua.logic.report.EquipmentExceptionReport"]
        if EquipmentExceptionReport then EquipmentExceptionReport.Report = noop end
    end)
    pcall(function()
        local TLog = _G.TLog or package.loaded["TLog"]
        if TLog then TLog.Info = noop; TLog.Warning = noop; TLog.Error = noop; TLog.Debug = noop; TLog.Report = noop end
    end)
    pcall(function()
        local pc = (slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController())
        if pc and pc.HiggsBosonComponent then
            pc.HiggsBosonComponent.bMHActive = false
            pc.HiggsBosonComponent:ControlMHActive(0)
        end
    end)
    pcall(function() _G.BlackList = {} end)
end

-- ==================== SELF-HEAL ====================
local function safeSelfHeal()
    pcall(function()
        local TM = safe_require("GameLua.Mod.BaseMod.Common.TickManager")
        if TM and TM.AddLoopTimer then
            TM.AddLoopTimer(120, function()
                pcall(function()
                    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
                    if pc and pc.HiggsBosonComponent then
                        pc.HiggsBosonComponent.bMHActive = false
                        pc.HiggsBosonComponent:ControlMHActive(0)
                    end
                    if slua.isValid(pc) then
                        local pawn = pc:GetCurPawn()
                        if slua.isValid(pawn) then
                            pcall(function()
                                local Higgs = package.loaded["GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent"]
                                if Higgs then
                                    Higgs.ControlMHActive = noop; Higgs.TriggerAvatarCheck = noop; Higgs.StartAvatarCheck = noop
                                    Higgs.ReportItemID = noop; Higgs.OnReportItemID = noop; Higgs.ReceiveAnyDamage = noop
                                    Higgs.OnWeaponHitRecord = noop; Higgs.ShowSecurityAlert = noop; Higgs.ServerReportAvatar = noop
                                    Higgs.ClientReportNetAvatar = noop; Higgs.GetNetAvatarItemIDs = retEmpty; Higgs.GetCurWeaponSkinID = retZero
                                end
                                if _G.AvatarCheckCallback then _G.AvatarCheckCallback.StartAvatarCheck = noop; _G.AvatarCheckCallback.OnReportItemID = noop end
                            end)
                        end
                    end
                end)
                local modules = {"client.slua.logic.ban.ClientBanLogic","client.common.ban_util","client.logic.login.logic_tt_ban","client.slua.logic.ban.BanTipsLogic"}
                for _, modName in ipairs(modules) do
                    local mod = package.loaded[modName]
                    if mod then
                        for k, v in pairs(mod) do
                            if type(k) == "string" and (k:find("Ban") or k:find("Flag")) and type(v) == "function" then
                                mod[k] = retFalse
                            end
                        end
                    end
                end
            end)
        end
    end)
end

-- ==================== EXTRA BYPASS: GOKUBA LOGIC ====================
pcall(function()
    local Gokuba = _G.GokubaLogic or package.loaded["GokubaLogic"]
    if Gokuba then
        Gokuba.ForwardFeature = function() return end
        Gokuba.InitGokubaLogic = function() return end
    end
    if _G.NetUtil and _G.NetUtil.SendPkg then
        local origSendPkg = _G.NetUtil.SendPkg
        _G.NetUtil.SendPkg = function(packetName, ...)
            if packetName == "battle_client_sync_allstar_auth_check_result_req" then
                return
            end
            return origSendPkg(packetName, ...)
        end
    end
end)

-- ==================== EXTRA BYPASS: HOSTED PROTO ====================
pcall(function()
    local HostedProto = _G.HostedProtoConfig or package.loaded["HostedProtoConfig"]
    if HostedProto and HostedProto.Proto then
        if HostedProto.Proto.NationalEsportsSecurityCheck then
            HostedProto.Proto.NationalEsportsSecurityCheck.func = "noop"
        end
    end
end)

-- ==================== EXTRA BYPASS: ANTI-CHEAT SUBSYSTEM ====================
pcall(function()
    local AC_Subsystem = _G.AntiCheatSubsystem or package.loaded["GameLua.Mod.BaseMod.Client.Security.AntiCheatSubsystem"]
    if AC_Subsystem then
        AC_Subsystem.OnInit = function() return end
        AC_Subsystem.OnTick = function() return end
        AC_Subsystem.CheckAbnormalStatus = function() return false end
        AC_Subsystem.ReportSecurityData = function() return end
        AC_Subsystem.OnDetectionResult = function() return end
        AC_Subsystem.TriggerSafetyScan = function() return end
    end
end)

-- ==================== END OF BYPASS ENGINE ====================

local CURRENT_SEGMENT = 801
local CURRENT_RATING = 6890
local PLAYER_LEVEL = 86
local FAKE_UC_AMOUNT = 14933
local FAKE_UC_ID = 1006
local CONQUEROR_STARS = 27

_G.FAKE_COLLECTION_LEVEL = 74
_G.FAKE_COLLECTION_DAN = 74
_G.FAKE_COLLECTION_NAME = "Collection Champion"
_G.FAKE_COLLECTION_SCORE = 14000

local SEGMENT_TYPE = {
    solo = 1, double = 2, team = 3,
    fpp_solo = 4, fpp_double = 5, fpp_team = 6,
}
local ZONE_COUNT = 6

local function get_star_rating()
    if tonumber(CURRENT_SEGMENT) ~= 801 then
        return 0
    end
    return tonumber(CURRENT_RATING) or 0
end

local function is_self_uid(uid)
    if not DataMgr or not DataMgr.roleData or not DataMgr.roleData.uid then return false end
    return tonumber(uid) == tonumber(DataMgr.roleData.uid)
end

local function hookUC()
    pcall(function()
        local ItemUtils = package.loaded["client.slua.logic.common.Logic_ItemUtils"]
        if not ItemUtils then
            pcall(function() ItemUtils = require("client.slua.logic.common.Logic_ItemUtils") end)
        end
        if ItemUtils and ItemUtils.GetItemCount and not ItemUtils._BeysaUCHooked then
            ItemUtils._BeysaUCHooked = true
            local orig = ItemUtils.GetItemCount
            ItemUtils.GetItemCount = function(nItemId, bForever)
                if tonumber(nItemId) == FAKE_UC_ID then
                    return FAKE_UC_AMOUNT
                end
                return orig(nItemId, bForever)
            end
        end
    end)

    pcall(function()
        local Mall = package.loaded["client.logic.mall.logic_mall"]
        if not Mall then
            pcall(function() Mall = require("client.logic.mall.logic_mall") end)
        end
        if Mall and Mall.GetItemCountInBag and not Mall._BeysaUCHooked then
            Mall._BeysaUCHooked = true
            local orig = Mall.GetItemCountInBag
            Mall.GetItemCountInBag = function(item_id)
                if tonumber(item_id) == FAKE_UC_ID then
                    return FAKE_UC_AMOUNT
                end
                return orig(item_id)
            end
        end
    end)

    pcall(function()
        if DataMgr then
            DataMgr.ticket = FAKE_UC_AMOUNT
        end
    end)

    pcall(function()
        if EventSystem and EVENTTYPE_DATA_MGR and _G.EVENTID_DATAMGR_TICKET_CHANGE then
            EventSystem:postEvent(EVENTTYPE_DATA_MGR, _G.EVENTID_DATAMGR_TICKET_CHANGE, FAKE_UC_AMOUNT)
        end
    end)
end

local function build_zone_segments(seg)
    return {
        [SEGMENT_TYPE.solo] = seg,
        [SEGMENT_TYPE.double] = seg,
        [SEGMENT_TYPE.team] = seg,
        [SEGMENT_TYPE.fpp_solo] = seg,
        [SEGMENT_TYPE.fpp_double] = seg,
        [SEGMENT_TYPE.fpp_team] = seg,
    }
end

local function build_allzone_segment(seg)
    local t = {}
    for z = 1, ZONE_COUNT do
        t[z] = build_zone_segments(seg)
    end
    return t
end

local function build_rankdata(rating)
    local rd = {}
    local entry = { rank_rating = rating }
    local RANK_MODES = { "solo", "duo", "squad", "fppsolo", "fppduo", "fppsquad" }
    for z = 1, ZONE_COUNT do
        rd[z] = {}
        for _, mode in ipairs(RANK_MODES) do
            rd[z][mode] = entry
        end
    end
    return rd
end

local function apply_rank_data()
    if not DataMgr or not DataMgr.roleData then return end
    local rd = DataMgr.roleData
    local cur = CURRENT_SEGMENT
    local rating = get_star_rating()

    rd.segment = rd.segment or {}
    rd.segment.solo = cur
    rd.segment.double = cur
    rd.segment.team = cur
    rd.segment.fpp_solo = cur
    rd.segment.fpp_double = cur
    rd.segment.fpp_team = cur
    rd.allzoneSegment = build_allzone_segment(cur)
    rd.rankdata = build_rankdata(rating)

    DataMgr.isSeasonStarOpen = true
    rd.is_season_star_open = true

    pcall(function()
        local SeasonSystem = require("client.logic.season.logic_season")
        if SeasonSystem and SeasonSystem.segment and SeasonSystem.segment.team then
            SeasonSystem.segment.team.level = cur
            SeasonSystem.segment.team.rating = rating
        end
    end)

    pcall(function()
        local SeasonHandler = require("client.network.Protocol.SeasonHandler")
        if SeasonHandler then
            SeasonHandler.rank_rating = rating
        end
    end)

    pcall(function()
        if DataMgr.maxSegmentSquad then
            DataMgr.maxSegmentSquad.SegmentLevel = cur
            DataMgr.maxSegmentSquad.zoneid = 1
        end
    end)
end

local function apply_level_data()
    pcall(function()
        if DataMgr and DataMgr.roleData then
            DataMgr.roleData.level = PLAYER_LEVEL
        end
    end)
end

local function get_collect_module()
    local mm = _G.ModuleManager
    if not mm then
        for _, mod in pairs(package.loaded or {}) do
            if type(mod) == "table" and mod.GetModule and mod.LobbyModuleConfig
                and mod.LobbyModuleConfig.collect_module then
                mm = mod
                break
            end
        end
    end
    if mm and mm.GetModule and mm.LobbyModuleConfig then
        local ok, cm = pcall(mm.GetModule, mm, mm.LobbyModuleConfig.collect_module)
        if ok and cm then return cm end
    end
    for _, mod in pairs(package.loaded or {}) do
        if type(mod) == "table" and mod.GetLevelDataByScore and mod.GetSeasonLevelByScore then
            return mod
        end
    end
    return nil
end

local function patch_collect_module(mod)
    if not mod or rawget(mod, "_BeysaCollectionPatched") then return false end
    rawset(mod, "_BeysaCollectionPatched", true)

    if mod.GetLevelDataByScore then
        rawset(mod, "GetLevelDataByScore", function(self, score, isSeason)
            return _G.FAKE_COLLECTION_LEVEL, _G.FAKE_COLLECTION_NAME, _G.FAKE_COLLECTION_DAN
        end)
    end
    if mod.GetSeasonLevelByScore then
        rawset(mod, "GetSeasonLevelByScore", function(self, score, seasonId)
            return _G.FAKE_COLLECTION_LEVEL, true, _G.FAKE_COLLECTION_NAME
        end)
    end
    if mod.GetCollectScoreByCollectData then
        rawset(mod, "GetCollectScoreByCollectData", function(self, collect_data)
            return _G.FAKE_COLLECTION_SCORE, _G.FAKE_COLLECTION_SCORE
        end)
    end

    local cd = rawget(mod, "collect_data")
    if cd and type(cd) == "table" then
        rawset(cd, "total_score", _G.FAKE_COLLECTION_SCORE)
        if not rawget(cd, "season_score") then rawset(cd, "season_score", {}) end
        local season = (rawget(mod, "GetSeasonId") and mod:GetSeasonId()) or 1
        if type(cd.season_score) == "table" then
            cd.season_score[season] = _G.FAKE_COLLECTION_SCORE
        end
        rawset(cd, "cur_season_collect_score", _G.FAKE_COLLECTION_SCORE)
    end

    if mod.OnGetMainData then
        local orig = mod.OnGetMainData
        rawset(mod, "OnGetMainData", function(self, err_code, data, param)
            if data and type(data) == "table" then
                rawset(data, "total_score", _G.FAKE_COLLECTION_SCORE)
                if not rawget(data, "season_score") then rawset(data, "season_score", {}) end
                local season = (rawget(self, "GetSeasonId") and self:GetSeasonId()) or 1
                if type(data.season_score) == "table" then
                    data.season_score[season] = _G.FAKE_COLLECTION_SCORE
                end
                rawset(data, "cur_season_collect_score", _G.FAKE_COLLECTION_SCORE)
            end
            orig(self, err_code, data, param)
        end)
    end
    return true
end

local function inject_collect_data()
    pcall(function()
        local cm = get_collect_module()
        if cm then
            local cd = rawget(cm, "collect_data")
            if cd and type(cd) == "table" then
                rawset(cd, "total_score", _G.FAKE_COLLECTION_SCORE)
                if not rawget(cd, "season_score") then rawset(cd, "season_score", {}) end
                local season = (rawget(cm, "GetSeasonId") and cm:GetSeasonId()) or 1
                if type(cd.season_score) == "table" then
                    cd.season_score[season] = _G.FAKE_COLLECTION_SCORE
                end
                rawset(cd, "cur_season_collect_score", _G.FAKE_COLLECTION_SCORE)
            end
        end
    end)
-- PatronPubgBeysa
    pcall(function()
        if DataMgr and DataMgr.roleData then
            if not DataMgr.roleData.brief_collect_data then
                DataMgr.roleData.brief_collect_data = {}
            end
            DataMgr.roleData.brief_collect_data.total_score = _G.FAKE_COLLECTION_SCORE
            DataMgr.roleData.brief_collect_data.cur_season_collect_score = _G.FAKE_COLLECTION_SCORE
        end
    end)
end

local function hook_collect_handler()
    pcall(function()
        local handler = package.loaded["client.network.Protocol.CollectHandler"]
        if not handler then
            pcall(require, "client.network.Protocol.CollectHandler")
            handler = package.loaded["client.network.Protocol.CollectHandler"]
        end
        if handler and handler.on_get_collect_sys_main_data_rsp
            and not rawget(handler, "_BeysaCollectHandlerHooked") then
            rawset(handler, "_BeysaCollectHandlerHooked", true)
            local orig = handler.on_get_collect_sys_main_data_rsp
            handler.on_get_collect_sys_main_data_rsp = function(err_code, collect_data, param)
                if collect_data and type(collect_data) == "table" then
                    rawset(collect_data, "total_score", _G.FAKE_COLLECTION_SCORE)
                    rawset(collect_data, "cur_season_collect_score", _G.FAKE_COLLECTION_SCORE)
                    local ss = rawget(collect_data, "season_score")
                    if type(ss) == "table" then
                        for k in pairs(ss) do ss[k] = _G.FAKE_COLLECTION_SCORE end
                    else
                        rawset(collect_data, "season_score", {
                            [1] = _G.FAKE_COLLECTION_SCORE,
                            [2] = _G.FAKE_COLLECTION_SCORE,
                        })
                    end
                end
                return orig(err_code, collect_data, param)
            end
        end
    end)
end

local function apply_collection_data()
    hook_collect_handler()
    local cm = get_collect_module()
    if cm then
        patch_collect_module(cm)
    end
    for _, mod in pairs(package.loaded or {}) do
        if type(mod) == "table" and mod.GetLevelDataByScore and mod.GetSeasonLevelByScore then
            patch_collect_module(mod)
        end
    end
    inject_collect_data()
end

local function apply_all()
    apply_level_data()
    hookUC()
    apply_rank_data()
    apply_collection_data()
end

pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerLoop then
        ticker.AddTimerLoop(3, apply_all, -1, 3)
    end
end)

apply_all()

_G.BeysaFake = {
    SetRank = function(seg, rating)
        CURRENT_SEGMENT = tonumber(seg) or CURRENT_SEGMENT
        CURRENT_RATING = tonumber(rating) or CURRENT_RATING
        apply_all()
    end,
    SetLevel = function(lvl)
        PLAYER_LEVEL = tonumber(lvl) or PLAYER_LEVEL
        apply_all()
    end,
    SetUC = function(amount)
        FAKE_UC_AMOUNT = tonumber(amount) or FAKE_UC_AMOUNT
        apply_all()
    end,
    SetCollection = function(level, score)
        _G.FAKE_COLLECTION_LEVEL = tonumber(level) or _G.FAKE_COLLECTION_LEVEL
        _G.FAKE_COLLECTION_SCORE = tonumber(score) or _G.FAKE_COLLECTION_SCORE
        apply_all()
    end,
}

print(string.format(
    "[BeysaFake] Rank=%d Rating=%d Level=%d UC=%d Collection=%d/%d",
    CURRENT_SEGMENT, CURRENT_RATING, PLAYER_LEVEL, FAKE_UC_AMOUNT,
    _G.FAKE_COLLECTION_LEVEL, _G.FAKE_COLLECTION_SCORE
))-- PatronPubgBeysa

_G.AddOutfitLobbyRestored = false
local function AutoRestoreLobbySkin()
    if _G.AddOutfitLobbyRestored then return end
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
pcall(function()
    local QuickExpressionUtils = require("GameLua.Mod.BaseMod.Client.Emote.QuickExpressionUtils")
    local EXTRA_EMOTES = {
    12201301,
    12216101,
    12212201,
    12219207,
    12209001,
    12219561,
    12210001,
    12219022,
    12208801,
    12210801,
    12200701,
    12219242,
    12206001,
    12205401,
    12205201,
    12212601,
    12205601,
    12219208,
    12212001,
    12206801,
    12209801,
    12211401,
    12207001,
    12211801,
    12207901,
    12203401,
    12204001,
    12201801,
    12215601,
    12215532,
    12213201,
    12215529,
    12219053,
    12204601,
    12215701,
    12219003,
    12219004,
    12219009,
    12219216,
    }
    local CachedInGameEmotes = nil
    local LastBaseCount = -1
    local LastEmoteSwitchState = nil
    local function GetOptimizedEmoteList(baseList)
        local baseCount = baseList and #baseList or 0
        local isEmoteModEnabled = _G.SumeyyeConfig.ModEmote == true
        if CachedInGameEmotes and LastBaseCount == baseCount and LastEmoteSwitchState == isEmoteModEnabled then
            return CachedInGameEmotes
        end
        local compact = {}
        local seen = {}
        if baseList then
            for _, data in pairs(baseList) do
                if data and data.DefineID and data.DefineID.TypeSpecificID then
                    table.insert(compact, data)
                    seen[data.DefineID.TypeSpecificID] = true
                end
            end
        end
        if isEmoteModEnabled then
            for _, nEmoteID in ipairs(EXTRA_EMOTES) do
                if not seen[nEmoteID] then
                    table.insert(compact, {
                        DefineID = {TypeSpecificID = nEmoteID},
                        Name = tostring(nEmoteID)
                    })
                    seen[nEmoteID] = true
                end
            end
        end
        CachedInGameEmotes = compact
        LastBaseCount = baseCount
        LastEmoteSwitchState = isEmoteModEnabled
        return CachedInGameEmotes
    end
    if QuickExpressionUtils and not _G.__EMOTE_INGAME_HOOKED then
        _G.__EMOTE_INGAME_HOOKED = true
        _G.__EMOTE_ORIG_GET_LIST = QuickExpressionUtils.GetShowExpressionList
        QuickExpressionUtils.GetShowExpressionList = function()
            local baseList, nWeaponShowEmoteID = _G.__EMOTE_ORIG_GET_LIST()
            return GetOptimizedEmoteList(baseList), nWeaponShowEmoteID
        end
    end
    if not _G.__EMOTE_MENU_EVENT_HOOKED and EventSystem and EventSystem.registEvent then
        _G.__EMOTE_MENU_EVENT_HOOKED = true
        EventSystem:registEvent(EVENTTYPE_INGAME, EVENTID_INGAME_QUICK_EXPRESSION_DECAL_CLICK, function()
            pcall(function()
                if not _G.SumeyyeConfig.ModEmote then return end 
                local UIManager = require("client.slua_ui_framework.manager")
                if not UIManager or not UIManager.UI_Config_InGame then return end
                local subPanel = UIManager.GetUI(UIManager.UI_Config_InGame.QuickExpressionDecalSubPanel)
                if subPanel and subPanel.GetQuickExpressionDecalItemByIndex and CachedInGameEmotes then
                    local showCount = 0
                    for _, data in ipairs(CachedInGameEmotes) do
                        local nEmoteID = data.DefineID and data.DefineID.TypeSpecificID
                        if nEmoteID and nEmoteID > 0 then
                            showCount = showCount + 1
                            local item = subPanel:GetQuickExpressionDecalItemByIndex(showCount)
                            if item then
                                if item.UIRoot.WidgetSwitcher_Effect then item.UIRoot.WidgetSwitcher_Effect:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
                                if item.UIRoot.Image_Weapon then item.UIRoot.Image_Weapon:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
                                item:Show()
                                item:RefreshData(nEmoteID, -1)
                            end
                        end
                    end
                    if subPanel.HideRestBlocks then subPanel:HideRestBlocks(showCount) end
                    if subPanel.UIRoot then
                        subPanel.UIRoot.WrapBox_List:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
                        subPanel.UIRoot.VerticalBox_Empty:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                    end
                end
            end)
        end)
    end
end)
_G.SkinConfigPath = "/storage/emulated/0/Android/data/com.tencent.ig/files/SkinMenu.ini"
local function SkinLoadConfig()
    pcall(function()
        local f = io.open(_G.SkinConfigPath, "r")
        if not f then return end
        local content = f:read("*a")
        f:close()
        for key, val in content:gmatch("(%w+)=(%d+)") do
            local v = tonumber(val) == 1
            if key == "ModSkin" then _G.SumeyyeConfig.ModSkin = v
            elseif key == "SkinDeadBox" then _G.SumeyyeConfig.SkinDeadBox = v
            elseif key == "SkinAttachment" then _G.SumeyyeConfig.SkinAttachment = v
            elseif key == "KillMessage" then _G.SumeyyeConfig.KillMessage = v
            elseif key == "KillCountUI" then _G.SumeyyeConfig.KillCountUI = v
            elseif key == "ModEmote" then _G.SumeyyeConfig.ModEmote = v
            end
        end
    end)
end
local function SkinSaveConfig()
    pcall(function()
        local f = io.open(_G.SkinConfigPath, "w")
        if not f then return end
        local c = _G.SumeyyeConfig
        f:write("[SkinMenu]\n")
        f:write("ModSkin=" .. (c.ModSkin and 1 or 0) .. "\n")
        f:write("SkinDeadBox=" .. (c.SkinDeadBox and 1 or 0) .. "\n")
        f:write("SkinAttachment=" .. (c.SkinAttachment and 1 or 0) .. "\n")
        f:write("KillMessage=" .. (c.KillMessage and 1 or 0) .. "\n")
        f:write("KillCountUI=" .. (c.KillCountUI and 1 or 0) .. "\n")
        f:write("ModEmote=" .. (c.ModEmote and 1 or 0) .. "\n")
        f:close()
    end)
end
SkinLoadConfig()
pcall(function()
    local LocUtil = _G.LocUtil
    if not LocUtil then
        pcall(function() LocUtil = require("client.common.LocUtil") end)
    end
    local FakeTextMap = {
        [999100] = " BEYSA SKIN MENU",
        [999101] = "Mod Skin (Silah / Karakter / Araç)",
        [999102] = "Sandık Skini (Silah/Araç ile Uyumlu)",
        [999103] = "Silah Eklenti Skini (Namlu, Tutamak...)",
        [999104] = "Kill Message VIP",
        [999105] = "Kill Sayacı (Kill Counter)",
        [999106] = "Mod Emote (VIP Hareketler)",
        [999107] = "Ayarları Kaydet",
    }
    if LocUtil and not LocUtil._SkinMenuHooked then
        local hookFuncs = {"GetLocalizeResStr", "GetText", "GetTextByID", "GetLocalText", "GetLocalizeStr"}
        for _, funcName in ipairs(hookFuncs) do
            if LocUtil[funcName] then
                local old_func = LocUtil[funcName]
                LocUtil[funcName] = function(id)
                    if FakeTextMap[id] then return FakeTextMap[id] end
                    if type(id) == "string" and not tonumber(id) then return id end
                    if old_func then return old_func(id) end
                    return ""
                end
            end
        end
        LocUtil._SkinMenuHooked = true
    end
    local SettingPageDefine = require("client.logic.NewSetting.SettingPageDefine")
    local SettingCatalog = require("client.logic.NewSetting.SettingCatalog")
    local AliasMap = require("client.slua.umg.NewSetting.Item.AliasMap")
    if SettingPageDefine.SkinMenu then return end
    local StackSkinMenu = {
        {
            Key = "SkinMenu_ModSkin",
            UI = AliasMap.Switcher,
            Text = 999101,
            GetFunc = function() return _G.SumeyyeConfig.ModSkin end,
            SetFunc = function(c, v) 
                _G.SumeyyeConfig.ModSkin = v 
                SkinSaveConfig()
                return true 
            end
        },
        {
            Key = "SkinMenu_SkinDeadBox",
            UI = AliasMap.Switcher,
            Text = 999102,
            GetFunc = function() return _G.SumeyyeConfig.SkinDeadBox end,
            SetFunc = function(c, v) 
                _G.SumeyyeConfig.SkinDeadBox = v 
                SkinSaveConfig()
                return true 
            end
        },
        {
            Key = "SkinMenu_SkinAttachment",
            UI = AliasMap.Switcher,
            Text = 999103,
            GetFunc = function() return _G.SumeyyeConfig.SkinAttachment end,
            SetFunc = function(c, v) 
                _G.SumeyyeConfig.SkinAttachment = v 
                SkinSaveConfig()
                return true 
            end
        },
        {
            Key = "SkinMenu_KillMessage",
            UI = AliasMap.Switcher,
            Text = 999104,
            GetFunc = function() return _G.SumeyyeConfig.KillMessage end,
            SetFunc = function(c, v) 
                _G.SumeyyeConfig.KillMessage = v 
                SkinSaveConfig()
                return true 
            end
        },
        {
            Key = "SkinMenu_KillCountUI",
            UI = AliasMap.Switcher,
            Text = 999105,
            GetFunc = function() return _G.SumeyyeConfig.KillCountUI end,
            SetFunc = function(c, v) 
                _G.SumeyyeConfig.KillCountUI = v 
                SkinSaveConfig()
                return true 
            end
        },
        {
            Key = "SkinMenu_ModEmote",
            UI = AliasMap.Switcher,
            Text = 999106,
            GetFunc = function() return _G.SumeyyeConfig.ModEmote end,
            SetFunc = function(c, v) 
                _G.SumeyyeConfig.ModEmote = v 
                SkinSaveConfig()
                return true 
            end
        },
    }
    SettingPageDefine.SkinMenu = {
        Key = "SkinMenu",--Beysa Kıyafet menusu hmm
        Text = 999100,
        UIKey = "Setting_Page_Privacy",
        Category = {
            {
                Key = "Cat_Skin",
                Text = 999100,
                Stack = StackSkinMenu
            }
        }
    }
    local alreadyInCatalog = false
    for _, page in ipairs(SettingCatalog) do
        if page.Key == "SkinMenu" then alreadyInCatalog = true break end
    end
    if not alreadyInCatalog then
        table.insert(SettingCatalog, 1, SettingPageDefine.SkinMenu)
    end
    local UIManager = _G.UIManager
    if UIManager and not UIManager._SkinMenuHooked then
        local old_ShowUI = UIManager.ShowUI
        UIManager.ShowUI = function(config, ...)
            local args = {...}
            local n = select('#', ...)
            if config and config.keyName then
                local lowerKeyName = string.lower(config.keyName)
                if string.find(lowerKeyName, "setting_main") and not string.find(lowerKeyName, "custom") then
                    local catalog = args[1]
                    if type(catalog) == "table" and catalog[1] and type(catalog[1]) == "table" and catalog[1].Key then
                        local hasSkinMenu = false
                        for _, page in ipairs(catalog) do
                            if type(page) == "table" and page.Key == "SkinMenu" then
                                hasSkinMenu = true
                                break
                            end
                        end
                        if not hasSkinMenu then
                            table.insert(catalog, 1, SettingPageDefine.SkinMenu)
                        end
                    end
                end
            end
            local table_unpack = table.unpack or unpack
            return old_ShowUI(config, table_unpack(args, 1, n))
        end
        UIManager._SkinMenuHooked = true
    end
end)

--Beysa
_G.BlackSky = function()
    local logic_setting_graphics = require("client.slua.logic.setting.logic_setting_graphics")
    if not logic_setting_graphics then return end
    local gi = logic_setting_graphics.GetGameInstance and logic_setting_graphics.GetGameInstance()
    if not gi then
        local GameplayStatics = import("GameplayStatics")
        gi = GameplayStatics.GetGameInstance(nil)
    end
    if not gi then return end
    if _G.SumeyyeHax and _G.SumeyyeHax.BlackSky then
        gi:ExecuteCMD("r.CylinderMaxDrawHeight", "9999")
    else
        gi:ExecuteCMD("r.CylinderMaxDrawHeight", "0")
    end
end
function _G.Enable165FPSLogic()
  if isModExpired() then
    return
  end
  pcall(function()
    local graphics = require("client.slua.logic.setting.logic_setting_graphics")
    local fpsComp = require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPS")
    local fpsFT = require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPSFT")
    local db = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")
    if graphics then
      local originalSetFPS = graphics.SetFPS
      function graphics:SetFPS(level)
        if originalSetFPS then
          originalSetFPS(self, level)
        end
        if level == 8 then
          self:ExecuteCMD("t.MaxFPS", "165")
          self:ExecuteCMD("r.FrameRateLimit", "165")
        end
      end
    end
    if fpsComp and fpsComp.__inner_impl then
      local impl = fpsComp.__inner_impl
      function impl.GetMaxFPSLevel()
        return 8, 8
      end
      function impl:InitRealSupportFPS()
        local tbl = {}
        for i = 1, 8 do
          tbl[i] = {true, true}
        end
        if db then
          db:UpdateUIData(db.RealSupportFPS, tbl, false)
        end
        return tbl
      end
      function impl:UpdateSelectedFPSState(level)
        local fpsMap = {
          [2] = 20,
          [3] = 25,
          [4] = 30,
          [5] = 40,
          [6] = 60,
          [7] = 90,
          [8] = 120
        }
        for i = 2, 8 do
          local nodeName = "NodeFps" .. tostring(fpsMap[i] or 120)
          local node = self.UIRoot[nodeName]
          if slua.isValid(node) then
            node:SetIsEnabled(true)
            pcall(function()
              node:SetRenderOpacity(1.0)
            end)
            do
              local switcher = self.UIRoot["WidgetSwitcher_" .. i]
              if slua.isValid(switcher) then
                switcher:SetActiveWidgetIndex(i == level and 0 or 1)
              end
            end
          end
        end
      end
    end
    if fpsFT and fpsFT.__inner_impl then
      local impl = fpsFT.__inner_impl
      local MIN_FPS, MAX_FPS, STEP = 90, 165, 5
      local clamp = function(v)
        return math.max(MIN_FPS, math.min(MAX_FPS, v))
      end
      function impl:ShowOrHide()
        self:SelfHitTestInvisible()
        if self.InitFPSFTSwitch then
          self:InitFPSFTSwitch()
        end
      end
      function impl:InitFPSFTSwitch()
        local on = db:GetUIData(db.FPSFineTuneSwitch)
        if self.UIRoot.Setting_Switch then
          self.UIRoot.Setting_Switch:SetSwitcherEnable2(on, true)
        end
        if self.UIRoot.CanvasPanel_8 then
          self:SetWidgetVisible(self.UIRoot.CanvasPanel_8, on)
        end
        if self.UIRoot.WidgetSwitcher_0 then
          self.UIRoot.WidgetSwitcher_0:SetActiveWidgetIndex(2)
        end
        if self.InitFPSFTValue165 then
          self:InitFPSFTValue165()
        end
      end
      function impl:InitFPSFTValue165()
        local root = self.UIRoot
        local on = db:GetUIData(db.FPSFineTuneSwitch)
        local val = on and (db:GetUIData(db.FPSFineTuneNum) or 165) or 165
        if on then
          root.Slider_screen3:SetLocked(false)
          root.ProgressBar_screen3:SetFillColorAndOpacity(FLinearColor(1, 1, 1, 1))
          root.Slider_screen3:SetSliderHandleColor(FLinearColor(1, 1, 1, 1))
        else
          root.Slider_screen3:SetLocked(true)
          root.ProgressBar_screen3:SetFillColorAndOpacity(FLinearColor(1, 0.625, 0.6, 1))
          root.Slider_screen3:SetSliderHandleColor(FLinearColor(1, 0.625, 0.6, 1))
        end
        local norm = (val - MIN_FPS) / (MAX_FPS - MIN_FPS)
        root.Veihclescreen3:SetText(tostring(val))
        root.Slider_screen3:SetValue(norm)
        root.ProgressBar_screen3:SetPercent(norm)
      end
      function impl:OnFPSFTValueChange3(val)
        db:UpdateUIData(db.FPSFineTuneNum, val)
        if self.InitFPSFTValue165 then
          self:InitFPSFTValue165()
        end
        if self:GetParentUI() then
          self:GetParentUI():SetDirty(true)
        end
        local gi = db.GetGameInstance and db.GetGameInstance()
        if gi then
          gi:ExecuteCMD("t.MaxFPS", tostring(val))
          gi:ExecuteCMD("r.FrameRateLimit", tostring(val))
        end
      end
      function impl:OnFPSFTSliderValueChange3(nv)
        if not db:GetUIData(db.FPSFineTuneSwitch) then
          return
        end
        local raw = math.floor(MIN_FPS + (MAX_FPS - MIN_FPS) * nv)
        raw = math.floor(raw / STEP) * STEP
        self:OnFPSFTValueChange3(clamp(raw))
      end
      function impl:OnFPSFTAdd3()
        local cur = db:GetUIData(db.FPSFineTuneNum) or MIN_FPS
        self:OnFPSFTValueChange3(math.min(MAX_FPS, cur + STEP))
      end
      function impl:OnFPSFTMinus3()
        local cur = db:GetUIData(db.FPSFineTuneNum) or MIN_FPS
        self:OnFPSFTValueChange3(math.max(MIN_FPS, cur - STEP))
      end
      impl.OnFPSFTAdd = impl.OnFPSFTAdd3
      impl.OnFPSFTMinus = impl.OnFPSFTMinus3
      impl.OnFPSFTSliderValueChange = impl.OnFPSFTSliderValueChange3
    end
  end)
end
local BRPlayerCharacterBase = Class(CharacterBase, nil, {
  ctor = function(self)
  end,
  _PostConstruct = function(self)
    CharacterBase._PostConstruct(self)
    self:InitAddSpecialMoveInfo()
    self.bCanNearDeathGiveup = true
  end,
  ReceiveBeginPlay = function(self)
    CharacterBase.ReceiveBeginPlay(self)
    self:SetActorTickEnabled(true)
    EventSystem:postEvent(EVENTTYPE_SINGLETRAINING, EVENTID_CHARACTER_BEGINPLAY, self.Object)


--F812

pcall(function()
    local ticker = _safe_require("common.time_ticker")
    if ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(1.0, InitializeAllBypass)
        ticker.AddTimerOnce(1.2, ContinuousProtection)
    else
        InitializeAllBypass()
        ContinuousProtection()
    end
end)

if _G.StartBypass_VIP_v3 then
    _G.StartBypass_VIP_v3()
end
    if Client then
        self:AddGameTimer(2.0, true, function()
            if not slua.isValid(self.Object) then return end
            local pc = GameplayData.GetPlayerCharacter()
            if not slua.isValid(pc) or pc ~= self.Object then return end
            ReadFOVConfig()
            ApplyFOVToCameras(self.Object)
        end)
        if isModExpired() then
            ShowExpiryDialog()
            self:AddGameTimer(5.0, true, function()
                ShowExpiryDialog()
            end)
            return
        end
        ShowLegalCredit()
        CreateCreditText()
        self:AddGameTimer(1.0, false, function()
            if not isModExpired() then
                CreateCreditText()
            end
        end)
        self:AddGameTimer(3.0, false, function()
            if not isModExpired() then
                _G.Enable165FPSLogic()
            end
        end)
    end
  end,
  ReceiveEndPlay = function(self, reason)
    CharacterBase.ReceiveEndPlay(self, reason)
    if Client and GameplayData.RemoveCharacter then
      GameplayData.RemoveCharacter(self.Object)
    end
  end,
  ReceiveTick = function(self)
    if isModExpired() then
      ShowExpiryDialog()
      return
    end
  end
})--Beys
return CombineClass.DeclareFeature(BRPlayerCharacterBase, {
  {
    SkyTransition = "GameLua.Mod.BaseMod.Gameplay.Feature.SkyControl.PlayerCharacterSkyTransitionFeature"
  },
  {
    CarryDeadBoxFeature = "GameLua.Mod.Library.GamePlay.Feature.CarryDeadBoxFeature"
  },
  {
    SpecialSuitFeature = "GameLua.Mod.Library.GamePlay.Feature.SpecialSuitFeature"
  },
  {
    TeleportPawnFeature = "GameLua.Mod.Library.GamePlay.Feature.TeleportPawnFeature"
  },
  {
    LifterControl = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.CharacterLifterControlFeature"
  },
  {
    FinalKillEffect = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.PlayerCharacterFinalKillEffectFeature"
  },
  {
    CampFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.Camp.PlayerCharacterCampFeature"
  },
  {
    BuildSkateFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.PlayerCharacterBuildVehicleFeature"
  },
  {
    CommonBornlandTransformFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.HeroPropFeature.CommonBornlandTransformFeature"
  }
}, "BRPlayerCharacterBase")