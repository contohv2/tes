(function()
_G._FULLSKIN_SCRIPT_VER = 64
_G._FULLSKIN_BATTLE_READY = false
if not _G._FULLSKIN_AVATAR_FRAME_LIST then
    _G._FULLSKIN_AVATAR_FRAME_LIST = {}
end

local notice_text = "加载皮肤工具"
local notice_enabled = true
local last_notice_time = 0
local notice_guard = false

local function throttled_notice()
    if not notice_enabled or not notice_text or notice_text == "" then return end
    local now = os.clock()
    if now - last_notice_time < 0.3 then return end
    last_notice_time = now
    pcall(function()
        if ShowNotice then ShowNotice(notice_text, true) end
    end)
end

local function is_blocked_notice(msg)
    if not notice_guard then return false end
    local id = tonumber(msg)
    if id == 4464 or id == 4465 then return true end
    if type(msg) == "string" and msg ~= "" then
        local blocked = false
        pcall(function()
            if LocUtil and LocUtil.GetLocalizeResStr then
                local loc = LocUtil.GetLocalizeResStr(4464)
                if loc and loc ~= "" and msg == loc then
                    blocked = true
                end
            end
        end)
        if blocked then return true end
    end
    return false
end

pcall(function()
    if ShowNotice and not ShowNotice.__fs_fullskin then
        local original_show = ShowNotice
        ShowNotice = function(text, ...)
            if is_blocked_notice(text) then return end
            return original_show(text, ...)
        end
        ShowNotice.__fs_fullskin = true
    end
end)

local expire_time = os.time({year=2026, month=7, day=13, hour=23, min=59, sec=59})
local function is_expired()
    return os.time() > expire_time
end

local function safe_exec(func)
    local ok, err = pcall(func)
    if not ok then error(err) end
end

if is_expired() then
    return
end

local BASE_ID = 990000000000
local SKIN_CACHE_INIT = false
local owned_skin_set = {}
local skin_item_cache = {}
local all_skin_items = {}
local weapon_skin_map = nil
local weapon_skin_count = {}
local weapon_install_map = {}
local weapon_skin_list_cache = {}
local weapon_skin_map_loaded = false
local weapon_skin_map_ts = nil
local gold_suit_switch = nil
local gold_suit_all = nil
local apply_pending_timer = nil
local apply_loop_timer = nil
local local_avatar_box_id = nil
local local_uid = nil

local function get_item_config(res_id)
    if not res_id then return nil end
    local ok, data = pcall(CDataTable.GetTableData, "Item", tonumber(res_id))
    return ok and data or nil
end

local function make_ins_id(res_id)
    return BASE_ID + tonumber(res_id)
end

local function to_number(val)
    return tonumber(val) or 0
end

local function extract_original_id(ins_id)
    local num = tonumber(ins_id)
    if num and num < BASE_ID then return nil end
    return num - BASE_ID
end

local function is_custom_item(res_id)
    return extract_original_id(res_id) ~= nil
end

local function create_virtual_item(res_id)
    local rid = tonumber(res_id)
    if not rid then return nil end
    local cfg = get_item_config(rid)
    if not cfg then return nil end
    local ins = make_ins_id(rid)
    return {
        insID = ins, resID = rid, count = 1,
        expireTS = 0, expire_ts = 0, validHours = 0, valid_hours = 0,
        isNew = 0, isnew = 0, lockCnt = 0, lock_cnt = 0,
        colorID = 0, color_id = 0, patternID = 0, pattern_id = 0,
        itemQuality = cfg.ItemQuality or 6,
        item_quality = cfg.ItemQuality or 6,
        mainTabType = cfg.WardrobeMainTab,
        subTabType = cfg.WardrobeTab,
        itemType = cfg.ItemType,
        itemSubType = cfg.ItemSubType,
        instid = ins, res_id = rid,
        bConfigLoaded = true,
    }
end

local function get_or_create_virtual_item(res_id)
    local rid = tonumber(res_id)
    if not rid then return nil end
    if not skin_item_cache[rid] then
        skin_item_cache[rid] = create_virtual_item(rid)
    end
    return skin_item_cache[rid]
end

local function mark_owned(res_id)
    local rid = tonumber(res_id)
    if rid and rid > 0 then
        owned_skin_set[rid] = true
    end
end

local function init_skin_collection()
    if SKIN_CACHE_INIT then return end
    SKIN_CACHE_INIT = true
    local item_table = CDataTable.GetTable("Item")
    local ModelDisplayTypeHelper
    pcall(function()
        ModelDisplayTypeHelper = require("client.logic.avatar.ModelDisplayTypeHelper")
    end)
    if item_table then
        for id, cfg in pairs(item_table) do
            local rid = tonumber(id)
            if rid and cfg then
                local is_personal = false
                if cfg.WardrobeMainTab and cfg.WardrobeTab then
                    is_personal = true
                elseif ModelDisplayTypeHelper and ModelDisplayTypeHelper.IsEmotion and ModelDisplayTypeHelper.IsEmotion(cfg.ItemType) then
                    is_personal = true
                elseif ENUM_ITEM_TYPE and cfg.ItemType == ENUM_ITEM_TYPE.Personalization then
                    is_personal = true
                end
                if is_personal then
                    mark_owned(rid)
                end
            end
        end
    end

    local function add_from_table(tab, keyField)
        local t = CDataTable.GetTable(tab)
        if t then
            for _, entry in pairs(t) do
                local rid = keyField and entry[keyField] or _
                mark_owned(rid)
                if entry.BattleActionID and entry.BattleActionID > 0 then
                    mark_owned(entry.BattleActionID)
                end
                if entry.LobbyActionID and entry.LobbyActionID > 0 then
                    mark_owned(entry.LobbyActionID)
                end
            end
        end
    end

    add_from_table("NicknameEffectCfg", "ID")
    add_from_table("ChatEffectCfg", "ID")
    add_from_table("TeamUpPopFrame", "ID")
    add_from_table("NameFrame", "ID")
    add_from_table("DoorPlate", "ID")
    add_from_table("RoleInfoBackgroundCfg", "ID")
    add_from_table("NicknameColorCfg", "PlanID")
    add_from_table("ChatRoomBgConfig", "ID")
    add_from_table("PersonalOpeningCfg", "ID")
    add_from_table("SocialCardBGInfo", "ID")
    add_from_table("CarteFrameConfig", "SkinID")
    add_from_table("AvatarFrame", "ID")
    add_from_table("GoldenSuitMapCfg", "Period")

    pcall(function()
        local gsMap = CDataTable.GetTable("GoldenSuitMapCfg") or {}
        for _, cfg in pairs(gsMap) do
            if cfg.BattleActionID and cfg.BattleActionID > 0 then
                mark_owned(cfg.BattleActionID)
            end
        end
        local clothesEmote = CDataTable.GetTable("Clothes2EmoteCfg") or {}
        for _, cfg in pairs(clothesEmote) do
            if cfg.EmoteID then
                mark_owned(cfg.EmoteID)
            end
        end
    end)

    pcall(function()
        local collectLevel = CDataTable.GetTable("CollectLevel") or {}
        local maxScore = 0
        local maxLevel = 0
        for _, cfg in pairs(collectLevel) do
            local score = tonumber(cfg.Score) or 0
            if score > maxScore then maxScore = score end
            local level = tonumber(_) or 0
            if level > maxLevel then maxLevel = level end
        end
        local newSeason = CDataTable.GetTable("NewCollectSeasonLevel") or {}
        local maxSeason = 0
        for _, cfg in pairs(newSeason) do
            local lvl = tonumber(cfg.Level) or 0
            if lvl > maxSeason then maxSeason = lvl end
        end
        if maxScore > 0 then _G._FULLSKIN_MAX_COLLECT_SCORE = maxScore + 1 end
        if maxLevel > 0 then _G._FULLSKIN_MAX_COLLECT_LEVEL = maxLevel end
        if maxSeason > 0 then _G._FULLSKIN_MAX_SEASON_LEVEL = maxSeason end
    end)

    local function add_skin_mapping(tab)
        local t = CDataTable.GetTable(tab)
        if t then
            for _, entry in pairs(t) do
                mark_owned(_)
            end
        end
    end
    add_skin_mapping("WeaponSkinMapping")
    add_skin_mapping("VehiclePlaneSkinMapping")
    add_skin_mapping("PetTable")
    add_skin_mapping("PetDressTable")

    pcall(function()
        local upMod = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.ItemUpgradeModule)
        if upMod then
            upMod.InitItemUpgradeConfig(upMod)
            local upTab = CDataTable.GetTable("ItemUpgradeConfig")
            if upTab then
                for _, cfg in pairs(upTab) do
                    if cfg.ItemID then
                        mark_owned(cfg.ItemID)
                    end
                end
            end
        end
    end)

    pcall(function()
        local xsuit = require("client.slua.logic.XSuit.logic_xsuit")
        if xsuit.InitXSuitItemList then
            xsuit.InitXSuitItemList()
        end
        if xsuit.itemInfoList then
            for id in pairs(xsuit.itemInfoList) do
                mark_owned(id)
            end
        end
    end)
end

local function get_all_skin_items()
    if all_skin_items and next(all_skin_items) then
        return all_skin_items
    end
    init_skin_collection()
    all_skin_items = {}
    for rid in pairs(owned_skin_set) do
        local item = get_or_create_virtual_item(rid)
        if item then
            all_skin_items[item.insID] = item
        end
    end
    pcall(function()
        local ticker = require("common.time_ticker")
        ticker.AddTimerOnce(0.3, function()
            tryCaptureLobbyNetAvatar("depot")
        end)
    end)
    return all_skin_items
end

local function extend_table_with_skins(t)
    if type(t) == "table" and skin_item_cache[t] then
        return t
    end
    local items = get_all_skin_items()
    for ins, data in pairs(items) do
        if not t[ins] then
            t[ins] = data
        end
    end
    skin_item_cache[t] = true
    return t
end

local function has_skin(res_id)
    init_skin_collection()
    local rid = tonumber(res_id)
    return owned_skin_set[rid] == true
end

local function get_skin_item(res_id)
    if has_skin(res_id) then
        return get_or_create_virtual_item(res_id)
    end
    return nil
end

if DataMgr and DataMgr.IsValidTime then
    local original_isValid = DataMgr.IsValidTime
    DataMgr.IsValidTime = function(ts)
        if ts == 0 or ts == nil then
            return true
        end
        return original_isValid(ts)
    end
end

local wardrobe_data = require("client.slua.logic.wardrobe.wardrobe_data")
local logic_wardrobe = require("client.slua.logic.wardrobe.logic_wardrobe_new")
local logic_gun = require("client.slua.logic.wardrobe.logic_wardrobe_gun")
local logic_armory = require("client.logic.armory.logic_armory")
local fashionbag = require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
local table_util = require("common.table_util")

local orig_funcs = {
    GetArray = wardrobe_data.GetArrayHallDepotItemInfo,
    GetByIns = wardrobe_data.GetHallDepotItemDataByInsID,
    GetByRes = wardrobe_data.GetHallDepotItemDataByResID,
    GetValid = wardrobe_data.GetValidHallDepotItemDataByInsID,
    GetListByRes = wardrobe_data.GetHallDepotItemListByResID,
    GetAllByRes = wardrobe_data.GetAllHallDepotItemDataByResID,
    GetByResValid = wardrobe_data.GetHallDepotItemDataByResIDAndValidExpireTime,
    GetByResTime = wardrobe_data.GetHallDepotItemDataByResIDAndTimeliness,
    CheckPerm = wardrobe_data.CheckHasPermanentItem,
    HasItem = wardrobe_data.HasItem,
    CheckGun = wardrobe_data.CheckHasPermanentGun,
    GetCountByRes = wardrobe_data.GetHallDepotItemCountByResID,
    puton = logic_wardrobe.wardrobe_puton_req,
    putdown = logic_wardrobe.wardrobe_put_down_req,
    IsWearValid = logic_wardrobe.IsWearValid,
    GetInsByRes = logic_wardrobe.GetWardrobeInsIdByResId,
    EquipMotion = logic_wardrobe.EquipMotion,
    ArmoryGetSkin = logic_armory.GetSkinListByWeaponID,
    install = logic_armory.install_weapon_skin,
    install_rsp = logic_armory.install_weapon_skin_rsp,
    uninstall = logic_armory.uninstall_weapon_skin,
    uninstall_rsp = logic_armory.uninstall_weapon_skin_rsp,
    put_on_wear = logic_gun.put_on_weapon_wear,
    pspace_wear = logic_gun.pspace_put_on_weapon_wear,
    on_wear_rsp = logic_gun.on_put_on_weapon_wear_rsp,
    OnPutOnStateChange = logic_gun.OnPutOnStateChange,
    UpdateGunAvatar = logic_gun.UpdateCurrentGunAvatar,
    HasValid = wardrobe_data.HasValidItem,
}

wardrobe_data.GetArrayHallDepotItemInfo = function(...)
    return extend_table_with_skins(orig_funcs.GetArray(...))
end

wardrobe_data.GetHallDepotItemDataByInsID = function(_, ins, ...)
    local data = orig_funcs.GetByIns(_, ins, ...)
    if data and data.resID then
        local rid = data.resID or data.res_id
        if rid and has_skin(rid) and data.expireTS and data.expireTS > 0 then
            return get_or_create_virtual_item(rid)
        end
        return data
    end
    local original = extract_original_id(ins)
    if original then
        return get_skin_item(original)
    end
    return nil
end

wardrobe_data.GetHallDepotItemDataByResID = function(_, res, ...)
    local data = orig_funcs.GetByRes(_, res, ...)
    if not data then
        return get_skin_item(res)
    end
    return data
end

wardrobe_data.GetValidHallDepotItemDataByInsID = function(_, ins, ...)
    local data = orig_funcs.GetValid(_, ins, ...)
    if not data then
        data = wardrobe_data.GetHallDepotItemDataByInsID(_, ins)
    end
    return data
end

wardrobe_data.GetHallDepotItemListByResID = function(_, res, ...)
    local list = orig_funcs.GetListByRes(_, res, ...)
    if list and next(list) then
        return list
    end
    if has_skin(res) then
        local ins = make_ins_id(res)
        return { { insID = ins, resID = res, count = 1, expireTS = 0, expire_ts = 0 } }
    end
    return list or {}
end

wardrobe_data.GetAllHallDepotItemDataByResID = function(_, res, ...)
    local list = orig_funcs.GetAllByRes and orig_funcs.GetAllByRes(_, res, ...)
    if list and next(list) then
        return list
    end
    return get_skin_item(res)
end

if orig_funcs.GetByResValid then
    wardrobe_data.GetHallDepotItemDataByResIDAndValidExpireTime = function(_, res, ...)
        local data = orig_funcs.GetByResValid(_, res, ...)
        if not data then
            return get_skin_item(res)
        end
        return data
    end
end

if orig_funcs.GetByResTime then
    wardrobe_data.GetHallDepotItemDataByResIDAndTimeliness = function(_, res, isTimely, ...)
        if has_skin(res) then
            if isTimely then
                return nil
            end
            return get_skin_item(res)
        end
        local data = orig_funcs.GetByResTime(_, res, isTimely, ...)
        if data then
            return data
        end
        return get_skin_item(res)
    end
end

wardrobe_data.CheckHasPermanentItem = function(_, res, ...)
    if has_skin(res) then
        return true
    end
    return orig_funcs.CheckPerm(_, res, ...)
end

wardrobe_data.HasItem = function(_, res, isPermanent, ...)
    if has_skin(res) then
        return true
    end
    if isPermanent and ... then
        local data = wardrobe_data.GetHallDepotItemDataByResID(_, res, ...)
        if data then
            return true
        end
    end
    return orig_funcs.HasItem(_, res, isPermanent, ...)
end

wardrobe_data.HasValidItem = function(_, res, ...)
    if has_skin(res) then
        return true
    end
    return orig_funcs.HasValid(_, res, ...)
end

wardrobe_data.CheckHasPermanentGun = function(_, res, ...)
    if has_skin(res) then
        return true
    end
    return orig_funcs.CheckGun and orig_funcs.CheckGun(_, res, ...) or false
end

wardrobe_data.GetHallDepotItemCountByResID = function(_, res, ...)
    if has_skin(res) then
        return 1
    end
    return orig_funcs.GetCountByRes(_, res, ...)
end

local function build_weapon_skin_map()
    if weapon_skin_map_loaded then
        return weapon_skin_map
    end
    weapon_skin_map_loaded = true
    weapon_skin_map = {}
    local mapping = CDataTable.GetTable("WeaponSkinMapping")
    if mapping then
        for skin_id, cfg in pairs(mapping) do
            local wid = tonumber(cfg.WeaponID)
            local sid = tonumber(skin_id)
            if wid and sid then
                if not weapon_skin_map[wid] then
                    weapon_skin_map[wid] = {}
                end
                weapon_skin_map[wid][sid] = true
            end
        end
    end
    return weapon_skin_map
end

local function init_armory_data()
    build_weapon_skin_map()
    if not logic_armory.rsp_list then
        logic_armory.rsp_list = { install_list = {}, skin_list = {} }
    end
    if not logic_armory.rsp_list.skin_list then
        logic_armory.rsp_list.skin_list = {}
    end
    local armory = CDataTable.GetTable("ArmoryConfig") or {}
    for _, cfg in pairs(armory) do
        local wid = tonumber(cfg.WeaponID)
        if wid and not logic_armory.rsp_list.skin_list[wid] then
            logic_armory.rsp_list.skin_list[wid] = {}
        end
    end
    for wid, skins in pairs(weapon_skin_map or {}) do
        if logic_armory.rsp_list.skin_list[wid] then
            for sid in pairs(skins) do
                if not logic_armory.rsp_list.skin_list[wid][sid] then
                    logic_armory.rsp_list.skin_list[wid][sid] = { weaponID = wid, is_open = 1, is_install = 0 }
                end
            end
        end
    end
    if not weapon_skin_map_loaded then
        weapon_skin_map_loaded = true
        weapon_install_map = {}
        local cnt = 0
        for _ in pairs(logic_armory.rsp_list.skin_list) do
            cnt = cnt + 1
        end
    end
end

local function get_weapon_skin_count(weapon_id)
    local wid = tonumber(weapon_id)
    if not wid then return 0 end
    if weapon_skin_count[wid] then
        return weapon_skin_count[wid]
    end
    init_armory_data()
    local skins = logic_armory.rsp_list and logic_armory.rsp_list.skin_list and logic_armory.rsp_list.skin_list[wid]
    local cnt = 0
    if skins then
        for _ in pairs(skins) do cnt = cnt + 1 end
    end
    if cnt == 0 and weapon_skin_map and weapon_skin_map[wid] then
        for _ in pairs(weapon_skin_map[wid]) do cnt = cnt + 1 end
    end
    weapon_skin_count[wid] = cnt
    return cnt
end

local function refresh_weapon_skin_count()
    init_armory_data()
    weapon_skin_count = {}
    local skins = logic_armory.rsp_list and logic_armory.rsp_list.skin_list
    if skins then
        for wid, list in pairs(skins) do
            local cnt = 0
            for _ in pairs(list) do cnt = cnt + 1 end
            if cnt > 0 then
                weapon_skin_count[wid] = cnt
            end
        end
    end
    pcall(function()
        logic_gun.InitGunTable(logic_gun)
    end)
end

logic_wardrobe.IsWearValid = function(_, res, ...)
    if has_skin(res) then
        return true
    end
    return orig_funcs.IsWearValid(_, res, ...)
end

logic_wardrobe.IsCanUse = function(_, res)
    if has_skin(res) then
        return true
    end
    return orig_funcs.IsCanUse(_, res)
end

logic_wardrobe.GetWardrobeInsIdByResId = function(_, res)
    if has_skin(res) then
        return make_ins_id(res)
    end
    return orig_funcs.GetInsByRes(_, res)
end

local function get_res_id_by_ins(ins)
    local num = tonumber(ins)
    if num and num > 0 then
        local data = wardrobe_data.GetHallDepotItemDataByInsID(ins)
        if data then
            return data.resID or data.res_id
        end
        local orig = extract_original_id(ins)
        if orig then
            return orig
        end
    end
    return nil
end

local BACKPACK_SUBTYPES = {
    [ENUM_ITEM_SUBTYPE.Backpack] = true,
    [ENUM_ITEM_SUBTYPE.Upgrade_Backpack] = true,
    [ENUM_ITEM_SUBTYPE.Helmet] = true,
    [ENUM_ITEM_SUBTYPE.Helmet_NoLevel] = true,
}

local function get_current_wear_skin(ins, slotType)
    local ins_num = to_number(ins)
    if ins_num == 0 then return nil end
    local wear = AvatarData.GetRoleWear() or {}
    for _, worn_ins in pairs(wear) do
        local worn = to_number(worn_ins)
        if worn ~= ins_num then
            local data = wardrobe_data.GetHallDepotItemDataByInsID(worn)
            if data and data.itemSubType == slotType then
                return data
            end
        end
    end
    return nil
end

local function get_equipment_skin(ins, slotType)
    if BACKPACK_SUBTYPES[slotType] then
        local equip_ins = to_number(DataMgr.equipmentSkinInsIDTable and DataMgr.equipmentSkinInsIDTable[slotType])
        if equip_ins > 0 and equip_ins ~= to_number(ins) then
            local data = wardrobe_data.GetHallDepotItemDataByInsID(equip_ins)
            if data then
                return data
            end
        end
    end
    return nil
end

local wardrobe_macro = nil
pcall(function()
    wardrobe_macro = require("client.slua.umg.Wardrobe.wardrobe_macro").ENUM_WardrobeSubTabString
end)

local function get_fashionbag_skin(ins, cfg)
    if not wardrobe_macro then return nil end
    local subTab = cfg.WardrobeTab
    local skin_ins = 0
    if subTab == wardrobe_macro.ENUM_WardrobeSubTabString_parachute then
        skin_ins = fashionbag.GetParachute()
    elseif subTab == wardrobe_macro.ENUM_WardrobeSubTabString_plane then
        skin_ins = fashionbag.GetPlanSkin()
    elseif subTab == wardrobe_macro.ENUM_WardrobeSubTabString_Wingman then
        skin_ins = fashionbag.GetWingmanSkin()
    elseif subTab == wardrobe_macro.ENUM_WardrobeSubTabString_effect then
        skin_ins = fashionbag.GetAircraftOrGliding()
    elseif subTab == wardrobe_macro.ENUM_WardrobeSubTabString_throw_object then
        if cfg.ItemSubType then
            skin_ins = fashionbag.GetThrowObjectSkin(cfg.ItemSubType) or 0
        end
    elseif cfg.ItemType == ENUM_ITEM_TYPE and cfg.ItemType == ENUM_ITEM_TYPE.Hall_Theme then
        pcall(function()
            local theme = require("client.logic.lobby.hall_theme_utils")
            skin_ins = theme.GetThemeInstId() or 0
        end)
    end
    skin_ins = to_number(skin_ins)
    if skin_ins > 0 and skin_ins ~= to_number(ins) then
        local data = wardrobe_data.GetHallDepotItemDataByInsID(skin_ins)
        if data then
            return data
        end
    end
    return nil
end

local function get_any_skin_override(ins, slotType, cfg)
    local from_fashion = get_fashionbag_skin(ins, cfg)
    if from_fashion then return from_fashion end
    local from_wear = get_current_wear_skin(ins, slotType)
    if from_wear then return from_wear end
    return get_equipment_skin(ins, slotType)
end

local function apply_backpack_helmet_skin(item)
    if not item then return end
    local cfg = get_item_config(item.res_id)
    if not cfg then return end
    local ins = to_number(item.instid)
    local sub = cfg.itemSubType
    if sub == ENUM_ITEM_SUBTYPE.Backpack or sub == ENUM_ITEM_SUBTYPE.Upgrade_Backpack then
        fashionbag.SetBagSkin(ins)
        pcall(function()
            local lvl = fashionbag.GetBagLevel() or 3
            fashionbag.SetBagSkinByLevel(ins, lvl)
        end)
    elseif sub == ENUM_ITEM_SUBTYPE.Helmet or sub == ENUM_ITEM_SUBTYPE.Helmet_NoLevel then
        fashionbag.SetHelmetSkin(ins)
        pcall(function()
            local lvl = fashionbag.GetHelmetLevel() or 3
            fashionbag.SetHelmetSkinByLevel(ins, lvl)
        end)
    end
end

function get_current_loadout()
    return _G._FULLSKIN_LOBBY_LOADOUT or _G._FULLSKIN_SNAPSHOT
end

function build_loadout_snapshot(force)
    if _G._FULLSKIN_BUILDING_SNAPSHOT then return end
    _G._FULLSKIN_BUILDING_SNAPSHOT = true
    pcall(function()
        local loadout = _G._FULLSKIN_SNAPSHOT or {}
        local wear_ext = {}
        local wear = AvatarData.GetRoleWear() or {}
        for _, ins in pairs(wear) do
            local data = wardrobe_data.GetHallDepotItemDataByInsID(ins)
            if data then
                local slot = get_slot_by_subtype(data.itemSubType)
                if slot then
                    wear_ext[slot] = AvatarData.GetItemWearInfoEnumFormat(ins, data)
                end
            end
        end
        loadout.wear_ext = wear_ext
        loadout.knapsack = loadout.knapsack or {}
        _G._FULLSKIN_SNAPSHOT = loadout
        _G._FULLSKIN_LOBBY_LOADOUT = loadout
    end)
    _G._FULLSKIN_BUILDING_SNAPSHOT = nil
end

function make_full_sig(loadout)
    if not loadout then return "" end
    local parts = {}
    if loadout.wear_ext then
        for k, v in pairs(loadout.wear_ext) do
            local item_id = type(v) == "table" and (v[1] or v.ItemID) or 0
            table.insert(parts, tostring(k) .. ":" .. tostring(item_id))
        end
    end
    table.sort(parts)
    return table.concat(parts, "|")
end

function rebuildWeaponSkinMap(force)
    if _G._FULLSKIN_WM then
        return _G._FULLSKIN_WM
    end
    _G._FULLSKIN_WM = {}
    local mapping = CDataTable.GetTable("WeaponSkinMapping") or {}
    for sid, cfg in pairs(mapping) do
        local wid = tonumber(cfg.WeaponID)
        if wid then
            if not _G._FULLSKIN_WM[wid] then
                _G._FULLSKIN_WM[wid] = {}
            end
            _G._FULLSKIN_WM[wid][sid] = true
        end
    end
    return _G._FULLSKIN_WM
end

function start_battle_skin_loop(reason)
    if _G._FULLSKIN_BATTLE_LOOP_ACTIVE then return end
    _G._FULLSKIN_BATTLE_LOOP_ACTIVE = true
    local function tick()
        local pc = get_local_player_controller()
        if pc and is_local_controller(pc) then
            apply_weapon_skin_to_current_weapon(pc)
        end
        local ticker = require("common.time_ticker")
        ticker.AddTimerOnce(3, tick)
    end
    tick()
end

function trigger_weapon_refresh(controller)
    if not controller then return end
    pcall(function()
        local pawn = controller.GetPlayerCharacterSafety and controller:GetPlayerCharacterSafety()
        if pawn then
            rebuildWeaponSkinMap(true)
            local comp = pawn.CharacterAvatarComp2_BP
            if comp then
                comp.OnRep_BodySlotStateChanged(comp)
            end
        end
    end)
end

function filterNetAvatarStripEquipment(net_avatar)
    if not net_avatar then return end
    local slots_to_clear = {8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21}
    for _, slot in ipairs(slots_to_clear) do
        if net_avatar[slot] then
            net_avatar[slot] = nil
        end
    end
end

function fix_slot_sync_data(sync_data)
    if not sync_data then return end
    for slot, data in pairs(sync_data) do
        if data and data.ForceHideState and data.ForceHideState > 0 then
            if slot ~= 2 and slot ~= 3 and slot ~= 5 then
                data.ForceHideState = 0
            end
        end
    end
end

function inject_loadout_into_profile(profile)
    if not profile then return end
    local loadout = get_current_loadout()
    if loadout and loadout.wear_ext then
        inject_wear_ext_into_profile(profile, loadout)
    end
end

function inject_wear_ext_into_profile(profile, loadout)
    if not profile or not loadout then return end
    profile.wear_ext = loadout.wear_ext
    if loadout.knapsack then
        profile.bag_skin = loadout.knapsack.bag_skin or 0
        profile.helmet_skin = loadout.knapsack.helmet_skin or 0
    end
end

function get_valid_avatar_frame(cur_id)
    local fid = tonumber(cur_id) or 0
    if fid > 0 and CDataTable.GetTableData("AvatarFrame", fid) then
        return fid
    end
    return 0
end

function force_collect_level(collect_mod)
    if collect_mod then
        collect_mod.my_collect_data = collect_mod.my_collect_data or {}
        collect_mod.my_collect_data.total_score = 999999999
    end
end

function inject_collect_data(data)
    if not data then return end
    data.total_score = 999999999
    data.cur_season_collect_score = 999999999
end

function is_local_uid(uid)
    local local_uid = DataMgr and DataMgr.roleData and DataMgr.roleData.uid
    return tonumber(uid) == tonumber(local_uid)
end

function get_local_uid()
    return DataMgr and DataMgr.roleData and DataMgr.roleData.uid
end

function get_mapped_weapon_skin(weapon_id)
    local wm = rebuildWeaponSkinMap()
    if wm and wm[weapon_id] then
        for skin_id in pairs(wm[weapon_id]) do
            return skin_id
        end
    end
    return nil
end

function apply_backpack_helmet_skin_by_slot(controller, slot_type, item_id)
    if slot_type == 8 then
        fashionbag.SetBagSkin(item_id)
    elseif slot_type == 9 then
        fashionbag.SetHelmetSkin(item_id)
    end
end

function get_player_controller_by_uid(uid)
    local pc = get_local_player_controller()
    if pc and pc.UID == uid then return pc end
    return nil
end

function has_valid_pawn(controller)
    if not controller then return false end
    local pawn = controller.GetPlayerCharacterSafety and controller:GetPlayerCharacterSafety()
    return pawn ~= nil
end

function force_sync_player_info(uid)
    pcall(function()
        local data_mgr = require("Server.Data.ServerPlayerDataMgr")
        if data_mgr and data_mgr.OnSyncPlayerInfo then
            data_mgr.OnSyncPlayerInfo(uid, {})
        end
    end)
end

function generate_player_avatar(controller)
    return pcall(function()
        local avatar_util = require("GameLua.Mod.Library.GamePlay.Avatar.AvatarDataUtil")
        if avatar_util and avatar_util.GeneratePlayerAvatarData then
            local profile = {}
            profile.uid = controller.UID
            avatar_util.GeneratePlayerAvatarData(profile, controller)
        end
    end)
end

function refresh_player_avatar(controller)
    pcall(function()
        if controller and controller.CommerFeature then
            local avatar_util = require("GameLua.Mod.Library.GamePlay.Avatar.AvatarDataUtil")
            if avatar_util and avatar_util.InitialEquipmentAvatar then
                local profile = { uid = controller.UID }
                avatar_util.InitialEquipmentAvatar(profile, controller)
            end
        end
    end)
end

function apply_vehicle_skins(controller)
    pcall(function()
        if controller and controller.InitVehicleAvatarList then
            controller:InitVehicleAvatarList()
            controller:InitVehicleAvatarSkinList()
        end
    end)
end

function refresh_weapon_skin_on_pawn(controller, reason)
    pcall(function()
        local pawn = controller and controller.GetPlayerCharacterSafety and controller:GetPlayerCharacterSafety()
        if pawn then
            rebuildWeaponSkinMap(true)
            local comp = pawn.CharacterAvatarComp2_BP
            if comp then
                comp.OnRep_BodySlotStateChanged(comp)
            end
            if pawn.GetWeaponManager then
                local wm = pawn:GetWeaponManager()
                if wm and wm.GetCurrentUsingWeapon then
                    local weapon = wm:GetCurrentUsingWeapon()
                    if weapon then
                        apply_weapon_skin(weapon.GetWeaponID and weapon:GetWeaponID(), nil)
                    end
                end
            end
        end
    end)
end

function trigger_gold_suit_refresh(data)
    pcall(function()
        local xsuit = require("client.slua.logic.XSuit.logic_xsuit")
        if xsuit and xsuit.RefreshTeamInfo then
            xsuit.RefreshTeamInfo()
        end
    end)
end

function get_group_level(group_id)
    local mod = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.ItemUpgradeModule)
    if mod then
        local group = mod.GetUpgradeGroupByID(mod, group_id)
        if group and #group > 0 then
            return #group
        end
    end
    return 0
end

function rebuild_order_pet_list()
    pcall(function()
        local pet_mod = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_pet)
        if pet_mod and pet_mod.UpdateOrderPetList then
            pet_mod:UpdateOrderPetList()
        end
    end)
end

function tryCaptureLobbyNetAvatar(reason)
    pcall(function()
        ensure_net_avatar(reason, true)
    end)
end

function get_local_player_controller()
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD.GetPlayerController(slua_GameFrontendHUD)
    if slua.isValid(pc) then return pc end
    pcall(function()
        pc = require("GameLua.GameCore.Data.GameplayData").GetPlayerController()
    end)
    return slua.isValid(pc) and pc or nil
end

function resolveLocalUid(controller)
    if not controller then return nil end
    local uid = controller.UID
    if uid and uid > 0 then return tonumber(uid) end
    if controller.PlayerState and controller.PlayerState.UID then
        return tonumber(controller.PlayerState.UID)
    end
    return nil
end

function is_local_controller(controller)
    if not controller then return false end
    if controller.IsLocalController and controller:IsLocalController() then return true end
    if controller.IsLocalPlayerController and controller:IsLocalPlayerController() then return true end
    local uid = resolveLocalUid(controller)
    local local_uid = DataMgr and DataMgr.roleData and DataMgr.roleData.uid
    return uid and local_uid and tonumber(uid) == tonumber(local_uid)
end

function init_collect_data()
    if DataMgr and DataMgr.roleData then
        DataMgr.roleData.brief_collect_data = DataMgr.roleData.brief_collect_data or {}
        DataMgr.roleData.brief_collect_data.total_score = 999999999
    end
end

function trigger_collect_update()
    EventSystem.postEvent(EVENTTYPE_COLLECT, EVENTID_COLLECT_DATA_NOTIFY)
end

function update_avatar_frame()
    local cur_id = DataMgr and DataMgr.roleData and DataMgr.roleData.cur_avatar_box_id
    if cur_id then
        _G._FULLSKIN_LOCAL_AVATAR_BOX_ID = cur_id
    end
end

function ensure_all_avatar_frames()
    local frame_mod = require("client.slua.logic.roleInfo.logic_RoleInfoAvatarFrame")
    if frame_mod then
        frame_mod.get_avatar_box_list_rsp(0, nil, _G._FULLSKIN_LOCAL_AVATAR_BOX_ID or 0)
    end
end

slot_mapping_backward = {}

function apply_weapon_skin_to_current_weapon(controller)
    local pawn = controller and controller.GetPlayerCharacterSafety and controller:GetPlayerCharacterSafety()
    if not pawn then return end
    local cur_weapon_id = pawn.GetCurrentWeaponID and pawn:GetCurrentWeaponID()
    if cur_weapon_id and cur_weapon_id > 0 then
        local skin = get_mapped_weapon_skin(cur_weapon_id)
        if skin then
            apply_weapon_skin(cur_weapon_id, skin)
        end
    end
end

function get_slot_by_subtype(subtype)
    local mapping = {
        [ENUM_ITEM_SUBTYPE.Hat_Slot] = ENUM_AVATAR_SHOW_TYPE.SHOW_POS_HEADWEAR,
        [ENUM_ITEM_SUBTYPE.Mask_Slot] = ENUM_AVATAR_SHOW_TYPE.SHOW_POS_FACE,
        [ENUM_ITEM_SUBTYPE.Package_Slot] = ENUM_AVATAR_SHOW_TYPE.SHOW_POS_CLOTH,
        [ENUM_ITEM_SUBTYPE.Pants_Slot] = ENUM_AVATAR_SHOW_TYPE.SHOW_POS_PANTS,
        [ENUM_ITEM_SUBTYPE.Shoes_Slot] = ENUM_AVATAR_SHOW_TYPE.SHOW_POS_SHOES,
        [ENUM_ITEM_SUBTYPE.Eye_Slot] = ENUM_AVATAR_SHOW_TYPE.SHOW_POS_GLASS,
        [ENUM_ITEM_SUBTYPE.Backpack] = ENUM_AVATAR_SHOW_TYPE.SHOW_POS_BAG,
        [ENUM_ITEM_SUBTYPE.Helmet] = ENUM_AVATAR_SHOW_TYPE.SHOW_POS_HELMET,
        [ENUM_ITEM_SUBTYPE.Helmet_NoLevel] = ENUM_AVATAR_SHOW_TYPE.SHOW_POS_HELMET,
    }
    return mapping[subtype]
end

function ensure_net_avatar(reason, force_refresh)
    local loadout = get_current_loadout()
    local full_sig = make_full_sig(loadout)
    if _G._FULLSKIN_LOBBY_NET_AVATAR and full_sig ~= "" then
        if _G._FULLSKIN_NET_AVATAR_SIG == full_sig then
            return true, "cached"
        end
    end
    if not force_refresh and _G._FULLSKIN_NET_AVATAR_SIG and full_sig ~= "" and full_sig == _G._FULLSKIN_NET_AVATAR_SIG then
        reset_net_avatar_cache("recapture")
    end
    local status = "no_pawn"
    pcall(function()
        local uid = DataMgr and DataMgr.roleData and DataMgr.roleData.uid
        if not uid then
            status = "no_uid"
            return
        end
        local mgr = get_team_avatar_manager()
        if not mgr then
            status = "no_mgr"
            return
        end
        local model = mgr.GetModel(uid)
        if not slua.isValid(model) then
            if mgr.GetMainAvatar then
                model = mgr.GetMainAvatar()
                if slua.isValid(model) then
                    status = "main_avatar"
                end
            end
        end
        if not slua.isValid(model) then
            pcall(function()
                local lobbymgr = require("client.logic.avatar.LobbyAvatarManager")
                local player = lobbymgr and lobbymgr.playerList and lobbymgr.playerList[tostring(uid)]
                if player and player.GetModel then
                    model = player.GetModel(player)
                    if slua.isValid(model) then
                        status = "lobby_list"
                    end
                end
            end)
        end
        if not slua.isValid(model) then
            status = "no_pawn"
            return
        end
        status = "team_model"
        local comp = get_avatar_component(model)
        if not comp or not comp.NetAvatarData then
            status = "no_net"
            return
        end
        if Game and Game.CopyNetAvatarDataToLobbyPawn then
            _G._FULLSKIN_LOBBY_NET_AVATAR = Game.CopyNetAvatarDataToLobbyPawn(comp, false)
        else
            _G._FULLSKIN_LOBBY_NET_AVATAR = comp.NetAvatarData.clone()
            filterNetAvatarStripEquipment(_G._FULLSKIN_LOBBY_NET_AVATAR)
        end
        _G._FULLSKIN_LOBBY_AVATAR_GENDER = comp.gender
        if _G._FULLSKIN_LOBBY_AVATAR_GENDER == nil then
            pcall(function()
                _G._FULLSKIN_LOBBY_AVATAR_GENDER = model.GetGender(model)
            end)
        end
        _G._FULLSKIN_LOBBY_AVATAR_HEAD = comp.HeadAvatarID
        if full_sig ~= "" then
            _G._FULLSKIN_NET_AVATAR_SIG = full_sig
        end
    end)
    if _G._FULLSKIN_LOBBY_NET_AVATAR then
        return true, status
    end
    return false, status
end

function get_team_avatar_manager()
    local modules = {
        "client.logic.avatar.logic_team_avatar_manager",
        "client.slua.logic.team_avatar_manager",
    }
    for _, name in ipairs(modules) do
        local ok, mod = pcall(require, name)
        if ok and mod and mod.GetModel then
            return mod
        end
    end
    return nil
end

function get_player_pawn(controller)
    if not controller or not slua.isValid(controller) then
        return nil
    end
    local pawn = nil
    pcall(function()
        if controller.GetPlayerCharacterSafety then
            pawn = controller.GetPlayerCharacterSafety(controller)
        end
    end)
    if not slua.isValid(pawn) then
        pcall(function()
            if controller.K2_GetPawn then
                pawn = controller.K2_GetPawn(controller)
            end
        end)
    end
    return slua.isValid(pawn) and pawn or nil
end

function get_avatar_component(pawn)
    if not slua.isValid(pawn) then
        return nil
    end
    local comp = pawn.CharacterAvatarComp2_BP
    if not slua.isValid(comp) then
        pcall(function()
            if pawn.getAvatarComponent2 then
                comp = pawn.getAvatarComponent2(pawn)
            end
        end)
    end
    return slua.isValid(comp) and comp or nil
end

function reset_net_avatar_cache(reason)
    _G._FULLSKIN_LOBBY_NET_AVATAR = nil
    _G._FULLSKIN_LOBBY_AVATAR_GENDER = nil
    _G._FULLSKIN_LOBBY_AVATAR_HEAD = nil
    _G._FULLSKIN_NET_AVATAR_SIG = nil
end

function reset_apply_state()
    _G._FULLSKIN_INGAME_APPLIED = nil
    _G._FULLSKIN_APPLY_PENDING = nil
    _G._FULLSKIN_APPLY_LOOP = nil
end

function apply_net_avatar_to_pawn(controller)
    if not controller or not slua.isValid(controller) then
        return false
    end
    local pawn = get_player_pawn(controller)
    if not pawn then return false end
    local comp = get_avatar_component(pawn)
    if not comp then return false end
    comp.bSyncAvatar = false
    pcall(function() comp.bAutonomousLoadRes = true end)
    local net_avatar = _G._FULLSKIN_LOBBY_NET_AVATAR
    if net_avatar then
        pcall(function()
            local cloned = net_avatar.clone()
            fix_slot_sync_data(cloned)
            comp.NetAvatarData = cloned
            if _G._FULLSKIN_LOBBY_AVATAR_GENDER ~= nil and comp.SetAvatarGender then
                comp.SetAvatarGender(comp, _G._FULLSKIN_LOBBY_AVATAR_GENDER)
            end
            comp.OnRep_BodySlotStateChanged(comp)
        end)
        return true
    end
    return false
end

function apply_loadout_direct(controller, skip_head)
    local loadout = get_current_loadout()
    if not loadout or not loadout.wear_ext or not next(loadout.wear_ext) then
        return false, "no_loadout"
    end
    local pawn = get_player_pawn(controller)
    if not pawn then return false, "no_pawn" end
    local comp = get_avatar_component(pawn)
    if not comp then return false, "no_avatar_comp" end
    local wear_ext = table_util.CopyTable(loadout.wear_ext)
    comp.bSyncAvatar = false
    pcall(function() comp.bAutonomousLoadRes = true end)
    if skip_head then
        local gender = AvatarData.GetGameGender() or 0
        local head_id = AvatarData.GetHeadID() or 0
        pcall(function() pawn.InitDefaultAvatarByResID(pawn, gender, head_id, 0) end)
        local head_slot = wear_ext[ENUM_AVATAR_SHOW_TYPE.SHOW_POS_HEAD]
        if head_slot then
            local item_id = head_slot[ENUM_AVATAR_DATA_TYPE.ItemID] or head_slot[1]
            if item_id and item_id > 0 then
                head_id = item_id
            end
        end
    end
    local puton_count = 0
    for slot, data in pairs(wear_ext) do
        if not slot_mapping_backward[slot] then
            if type(data) == "table" then
                local item_id = data[ENUM_AVATAR_DATA_TYPE.ItemID] or data[1]
                if item_id and item_id > 0 then
                    local avatar_data = data
                    pcall(function()
                        avatar_data = AvatarData.ConvertToAvatarCustom(data)
                    end)
                    if not avatar_data then
                        avatar_data = { ItemID = item_id }
                    end
                    pcall(function()
                        comp.PutOnEquipmentByResID(comp, avatar_data.ItemID or item_id, avatar_data)
                    end)
                    puton_count = puton_count + 1
                end
            end
        end
    end
    local weapon_skin = wear_ext[ENUM_AVATAR_SHOW_TYPE.SHOW_POS_WEAPONSKIN]
    local weapon_skin_id = weapon_skin and (weapon_skin[ENUM_AVATAR_DATA_TYPE.ItemID] or weapon_skin[1])
    if pawn.CharEquipWeaponByResId and weapon_skin_id and weapon_skin_id > 0 then
        pcall(function() pawn.CharEquipWeaponByResId(pawn, weapon_skin_id, true) end)
    end
    pcall(function() comp.OnRep_BodySlotStateChanged(comp) end)
    if puton_count <= 0 then
        return false, "put_on_0"
    end
    return true, "ok put=" .. puton_count
end

function apply_net_avatar_fallback(controller)
    if not ensure_net_avatar("ensure", false) then
        return false, "no_net_avatar"
    end
    local pawn = get_player_pawn(controller)
    if not pawn then return false, "no_pawn" end
    local comp = get_avatar_component(pawn)
    if not comp then return false, "no_comp" end
    pcall(function()
        comp.bSyncAvatar = false
        pcall(function() comp.bAutonomousLoadRes = true end)
        pcall(function() comp.bIsLobbyAvatar = false end)
        local net_avatar = _G._FULLSKIN_LOBBY_NET_AVATAR.clone()
        fix_slot_sync_data(net_avatar)
        comp.NetAvatarData = net_avatar
        if _G._FULLSKIN_LOBBY_AVATAR_GENDER ~= nil and comp.SetAvatarGender then
            comp.SetAvatarGender(comp, _G._FULLSKIN_LOBBY_AVATAR_GENDER)
        end
        comp.OnRep_BodySlotStateChanged(comp)
    end)
    return true, "net_avatar_ok"
end

function apply_best_avatar(controller)
    local ok, msg = apply_net_avatar_fallback(controller)
    if ok then return true, msg end
    return apply_loadout_direct(controller, false)
end

function apply_loadout_to_pawn(controller)
    local ok, msg = apply_best_avatar(controller)
    if ok then
        pcall(function() rebuildWeaponSkinMap(true) end)
        return true
    end
    return false
end

function has_loadout_applied()
    local sig = make_full_sig(get_current_loadout())
    return sig ~= "" and _G._FULLSKIN_INGAME_APPLIED == sig
end

function mark_loadout_applied()
    _G._FULLSKIN_INGAME_APPLIED = make_full_sig(get_current_loadout())
end

function get_uid_from_controller(controller)
    if not slua.isValid(controller) then return nil end
    local uid = tonumber(controller.UID)
    if uid and uid > 0 then return uid end
    pcall(function()
        local state = controller.GetPlayerStateSafety and controller.GetPlayerStateSafety(controller)
        if state and slua.isValid(state) then
            uid = tonumber(state.UID)
        end
    end)
    if uid and uid > 0 then return uid end
    pcall(function()
        if controller.PlayerState and slua.isValid(controller.PlayerState) then
            uid = tonumber(controller.PlayerState.UID)
        end
    end)
    if uid and uid > 0 then return uid end
    uid = tonumber(_G._FULLSKIN_LOCAL_UID)
    if uid and uid > 0 then return uid end
    if DataMgr and DataMgr.roleData then
        uid = tonumber(DataMgr.roleData.uid)
    end
    if (not uid or uid <= 0) and get_current_loadout() then
        uid = tonumber(get_current_loadout().local_uid)
    end
    return uid
end

_G._FULLSKIN_isLocalPC = is_local_controller

function apply_full_skin(controller)
    if _G._FULLSKIN_APPLYING then return false, "applying" end
    if not is_local_controller(controller) then return false, "not_local" end
    if has_loadout_applied() then return true end
    local loadout = get_current_loadout()
    if not loadout then return false, "no_loadout" end
    local uid = get_uid_from_controller(controller)
    if not uid then return false, "no_uid" end
    _G._FULLSKIN_APPLYING = true
    local sync_ok = false
    local sync_msg = "skip"
    local cloth_ok = false
    local cloth_msg = "skip"
    local has_pawn = false
    pcall(function()
        pcall(function() force_sync_player_info(uid) end)
        ensure_net_avatar(controller)
        local gen_ok, gen_msg = generate_player_avatar(controller)
        cloth_ok = gen_ok
        cloth_msg = gen_msg
        refresh_player_avatar(controller)
        apply_vehicle_skins(controller)
        rebuildWeaponSkinMap(true)
        trigger_weapon_refresh(controller)
        has_pawn = has_valid_pawn(controller)
        if not has_pawn then return end
        local net_ok, net_msg = apply_net_avatar_fallback(controller)
        cloth_ok = net_ok
        cloth_msg = net_msg
        if not cloth_ok then return end
        pcall(function()
            local pawn = get_player_pawn(controller)
            if pawn then
                rebuildWeaponSkinMap(pawn)
            end
        end)
        mark_loadout_applied()
        start_battle_skin_loop()
        local gen = (_G._FULLSKIN_REINFORCE_GEN or 0) + 1
        _G._FULLSKIN_REINFORCE_GEN = gen
        local ticker = require("common.time_ticker")
        local delays = { 3, 8, 15, 30 }
        for _, delay in ipairs(delays) do
            ticker.AddTimerOnce(delay, function()
                if _G._FULLSKIN_REINFORCE_GEN ~= gen then return end
                refresh_weapon_skin_on_pawn(controller, "n=" .. delay)
            end)
        end
    end)
    _G._FULLSKIN_APPLYING = nil
    if not sync_ok then
        if not _G._FULLSKIN_LOBBY_NET_AVATAR then
            return false, sync_msg
        end
    end
    if not has_pawn then return false, "wait_pawn" end
    if not cloth_ok then return false, cloth_msg or "cloth_fail" end
    return true
end

function schedule_apply(controller, attempt)
    if not attempt then attempt = 1 end
    if has_loadout_applied() or attempt > 5 then return end
    if _G._FULLSKIN_APPLY_PENDING then return end
    _G._FULLSKIN_APPLY_PENDING = true
    local delays = { 0.6, 1.5, 3, 5, 8 }
    local delay = delays[attempt] or 8
    pcall(function()
        local ticker = require("common.time_ticker")
        ticker.AddTimerOnce(delay, function()
            _G._FULLSKIN_APPLY_PENDING = nil
            if not slua.isValid(controller) then return end
            if has_loadout_applied() then return end
            if not apply_full_skin(controller) then
                schedule_apply(controller, attempt + 1)
            end
        end)
    end)
end

function on_player_controller_ready(controller)
    if not is_local_controller(controller) then return end
    local uid = get_uid_from_controller(controller)
    if uid then
        force_sync_player_info(uid)
    end
end

function start_apply_loop()
    if _G._FULLSKIN_APPLY_LOOP then return end
    local gen = (_G._FULLSKIN_LOOP_GEN or 0) + 1
    _G._FULLSKIN_LOOP_GEN = gen
    local loadout = get_current_loadout()
    if not loadout then return end
    reset_apply_state()
    _G._FULLSKIN_APPLY_LOOP = true
    local count = 0
    local function tick()
        if _G._FULLSKIN_LOOP_GEN ~= gen then return end
        count = count + 1
        if has_loadout_applied() then
            _G._FULLSKIN_APPLY_LOOP = nil
            return
        end
        if count > 60 then
            _G._FULLSKIN_APPLY_LOOP = nil
            return
        end
        local pc = get_local_player_controller()
        if pc and is_local_controller(pc) then
            local uid = get_uid_from_controller(pc)
            if uid and uid > 0 then
                if apply_loadout_to_pawn(pc) then
                    _G._FULLSKIN_APPLY_LOOP = nil
                    return
                end
            end
        end
        local ticker = require("common.time_ticker")
        ticker.AddTimerOnce(1, tick)
    end
    tick()
end

function init_all_hooks()
    init_skin_collection()
    init_armory_data()
    refresh_weapon_skin_count()
    pcall(function() logic_gun.OnGunSkinListRes(logic_gun) end)
    pcall(function() logic_gun.InitGunCountData(logic_gun) end)
    pcall(function() init_collect_data() end)
    pcall(function() update_avatar_frame() end)
    pcall(function() ensure_all_avatar_frames() end)
end

if not _G._FULLSKIN_BATTLE_READY then
    _G._FULLSKIN_BATTLE_READY = true
    pcall(init_all_hooks)
end

function on_enter_fighting()
    local loadout = get_current_loadout()
    if loadout then
        rebuildWeaponSkinMap(true)
        start_battle_skin_loop("boot")
        start_apply_loop()
    end
end

function hook_events()
    pcall(function()
        EventSystem.registEvent(EVENTTYPE_PLAYER, EVENTID_SYNC_PLAYER_INFO, function(_, _, uid, data)
            if data and is_local_uid(uid) then
                inject_loadout_into_profile(data)
            end
        end)
    end)
    pcall(function()
        EventSystem.registEvent(EVENTTYPE_INGAME, EVENTID_INGAME_CONTROLLER_BEGINPLAY, function(_, _, controller)
            if is_local_controller(controller) then
                rebuildWeaponSkinMap(true)
                start_battle_skin_loop("beginplay")
                if not has_loadout_applied() then
                    schedule_apply(controller)
                end
            end
        end)
    end)
    pcall(function()
        EventSystem.registEvent(EVENTTYPE_PLAYEREVENT_WEAPON, EVENTID_PLAYEREVENT_WEAPON_PICK_UP, function(_, _, uid, weapon_id)
            local local_uid = get_local_uid()
            if local_uid and tonumber(uid) == local_uid then
                local skin = get_mapped_weapon_skin(weapon_id)
                rebuildWeaponSkinMap(true)
                local pc = get_local_player_controller()
                if pc then trigger_weapon_refresh(pc) end
            end
        end)
    end)
    pcall(function()
        EventSystem.registEvent(EVENTTYPE_PLAYEREVENT_AVATAR, EVENTID_PLAYEREVENT_AVATAR_LOGIC_EQUIPPED, function(_, _, uid, slot_type, item_id)
            local pc = get_player_controller_by_uid(uid)
            if pc and is_local_controller(pc) and (slot_type == 8 or slot_type == 9) then
                apply_backpack_helmet_skin_by_slot(pc, slot_type, item_id)
            end
        end)
    end)
    pcall(function()
        EventSystem.registEvent(EVENTTYPE_STATE, EVENTID_ON_MODE_PRE_SWITCH, function(_, _, new_state)
            if new_state and new_state.current == GameStatus.Fighting then
                _G._FULLSKIN_BATTLE_READY = false
                _G._FULLSKIN_INGAME_APPLIED = nil
                build_loadout_snapshot(true)
            end
        end)
    end)
end

hook_events()

logic_wardrobe.wardrobe_puton_req = function(_, res, callback)
    local rid = get_res_id_by_ins(res)
    if rid and has_skin(rid) then
        local cfg = get_item_config(rid)
        if cfg then
            local ins = make_ins_id(rid)
            safe_exec(function()
                _.on_puton_rsp(0, { res_id = rid, instid = ins, expire_ts = 0, count = 1, color_id = 0, pattern_id = 0, itemType = cfg.ItemType, itemSubType = cfg.itemSubType }, get_any_skin_override(ins, cfg.itemSubType, cfg), nil, callback)
            end)
            throttled_notice()
            return
        end
    end
    return orig_funcs.puton(_, res, callback)
end

logic_wardrobe.wardrobe_put_down_req = function(_, res)
    local rid = get_res_id_by_ins(res)
    if rid and has_skin(rid) then
        safe_exec(function()
            _.on_putdown_rsp(0, { res_id = rid, instid = make_ins_id(rid), expire_ts = 0, count = 1 })
        end)
        return
    end
    return orig_funcs.putdown(_, res)
end

logic_wardrobe.EquipMotion = function(_, motion, slot)
    local rid = get_res_id_by_ins(motion)
    if rid and has_skin(rid) then
        if not DataMgr.MotionSlotList then DataMgr.MotionSlotList = {} end
        while slot > #DataMgr.MotionSlotList do
            table.insert(DataMgr.MotionSlotList, 0)
        end
        local ins = make_ins_id(rid)
        DataMgr.MotionSlotList[slot] = ins
        EventSystem.postEvent(EVENTTYPE_MOTION, EVENTID_MOTION_UPDATE_SLOT_LIST)
        return
    end
    return orig_funcs.EquipMotion(_, motion, slot)
end

logic_armory.GetSkinListByWeaponID = function(weapon_id)
    local wid = tonumber(weapon_id)
    if not wid then return {} end
    if weapon_skin_list_cache[wid] then
        return weapon_skin_list_cache[wid]
    end
    init_armory_data()
    local list = orig_funcs.ArmoryGetSkin(wid) or {}
    local cache = {}
    for k, v in pairs(list) do cache[k] = v end
    weapon_skin_list_cache[wid] = cache
    return cache
end

if logic_armory.get_weapon_skin_list_rsp and not logic_armory.__fs_skin_rsp then
    local old_rsp = logic_armory.get_weapon_skin_list_rsp
    logic_armory.__fs_skin_rsp = old_rsp
    logic_armory.get_weapon_skin_list_rsp = function(_, ret, data, isDecode)
        if ret ~= 0 then ret = 0 end
        if not data then data = {} end
        if isDecode and data.skin_list then
            pcall(function()
                data.skin_list = slua.LuaArchiverDecode(LuaStateWrapper, data.skin_list)
            end)
        end
        if not logic_armory.rsp_list then
            logic_armory.rsp_list = { install_list = {}, skin_list = {} }
        end
        if data.skin_list then
            for wid, skins in pairs(data.skin_list) do
                if not logic_armory.rsp_list.skin_list[wid] then
                    logic_armory.rsp_list.skin_list[wid] = {}
                end
                for sid, info in pairs(skins) do
                    logic_armory.rsp_list.skin_list[wid][sid] = info
                end
            end
        end
        weapon_skin_list_cache = {}
        init_armory_data()
        pcall(function() logic_armory.ReBuildInitData(logic_armory.rsp_list) end)
        pcall(function() logic_armory.ContructResIdToWardrobeInsID() end)
        pcall(function() logic_gun.OnGunSkinListRes(logic_gun) end)
        refresh_weapon_skin_count()
        pcall(function() EventSystem.postEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_UPDATE_GUN_LIST, -1) end)
    end
end

if logic_gun.GetSubTabItemCount and not logic_gun.__fs_subcnt then
    local old_cnt = logic_gun.GetSubTabItemCount
    logic_gun.__fs_subcnt = old_cnt
    logic_gun.GetSubTabItemCount = function(_, tab)
        local tab_num = tonumber(tab)
        if tab_num and weapon_skin_count[tab_num] then
            return weapon_skin_count[tab_num]
        end
        local cnt = old_cnt(_, tab)
        if cnt == 0 then
            cnt = get_weapon_skin_count(tab_num)
            if cnt > 0 then weapon_skin_count[tab_num] = cnt end
        end
        return cnt
    end
end

if logic_gun.UpdateSubTabItemCount and not logic_gun.__fs_updcnt then
    local old_upd = logic_gun.UpdateSubTabItemCount
    logic_gun.__fs_updcnt = old_upd
    logic_gun.UpdateSubTabItemCount = function(_, tab)
        refresh_weapon_skin_count()
        return old_upd(_, tab)
    end
end

if logic_gun.InitGunCountData and not logic_gun.__fs_guncnt then
    local old_init = logic_gun.InitGunCountData
    logic_gun.__fs_guncnt = old_init
    logic_gun.InitGunCountData = function(_)
        init_armory_data()
        refresh_weapon_skin_count()
        return old_init(_)
    end
end

if not logic_armory.rsp_list then
    logic_armory.rsp_list = { install_list = {}, skin_list = {} }
elseif not logic_armory.rsp_list.install_list then
    logic_armory.rsp_list.install_list = {}
end

function is_skin_valid(ins)
    local num = to_number(ins)
    if num <= 0 then return false end
    if is_custom_item(num) then return true end
    local rid = get_res_id_by_ins(num)
    if rid and has_skin(rid) then return true end
    return false
end

function get_current_weapon_skin(weapon_id)
    local wid = tonumber(weapon_id)
    if not wid or wid <= 0 then return 0 end
    local ins = logic_gun.GetSkinIdByWeaponID(wid)
    if ins and ins > 0 then
        return to_number(ins)
    end
    local install = logic_armory.rsp_list and logic_armory.rsp_list.install_list and logic_armory.rsp_list.install_list[wid]
    if install and install.skin_id then
        return to_number(install.skin_id)
    end
    return 0
end

local last_weapon_skin = { id = 0, skin = 0, ts = 0 }
function apply_weapon_skin(weapon_id, skin_ins)
    local wid = tonumber(weapon_id)
    if not wid or wid <= 0 then return end
    local skin = tonumber(skin_ins) or 0
    if skin <= 0 then
        skin = get_current_weapon_skin(wid)
    end
    local now = os.clock()
    if last_weapon_skin.id == wid and last_weapon_skin.skin == skin and now - last_weapon_skin.ts < 0.15 then
        return
    end
    last_weapon_skin = { id = wid, skin = skin, ts = now }
    logic_gun.SetPreviewGunResID(0)
    local rid = nil
    if skin > 0 then
        local data = wardrobe_data.GetValidHallDepotItemDataByInsID(skin)
        if data then
            rid = data.resID or data.res_id
        else
            rid = extract_original_id(skin)
        end
    end
    pcall(function()
        local mgr = require("client.logic.avatar.LobbyAvatarManager")
        mgr.EquipWeapon(DataMgr.roleData.uid, { weaponId = wid, skinId = rid or 0 }, nil, true)
    end)
end

logic_armory.install_weapon_skin = function(_, ret, weapon_id, skin_ins)
    local skin = to_number(skin_ins)
    if skin > 0 and is_skin_valid(skin) then
        safe_exec(function()
            orig_funcs.install_rsp(_, 0, weapon_id, skin)
        end)
        pcall(function() logic_gun.UpdateCurrentGunAvatar(logic_gun, weapon_id, skin) end)
        throttled_notice()
        return
    end
    return orig_funcs.install(_, ret, weapon_id, skin_ins)
end

logic_armory.uninstall_weapon_skin = function(_, weapon_id)
    orig_funcs.uninstall_rsp(_, 0, weapon_id)
    apply_weapon_skin(weapon_id, 0)
end

logic_gun.UpdateCurrentGunAvatar = function(_, weapon_id, skin_ins)
    local skin = to_number(skin_ins)
    if skin > 0 and is_skin_valid(skin) then
        local data = wardrobe_data.GetValidHallDepotItemDataByInsID(skin)
        local rid = data and (data.resID or data.res_id) or extract_original_id(skin)
        if rid then
            pcall(function()
                _.PutOnGunAvatar(weapon_id, rid, nil)
            end)
            return
        end
    end
    return orig_funcs.UpdateGunAvatar(_, weapon_id, skin_ins)
end

function is_skin_equipped(ins)
    local num = to_number(ins)
    if num > 0 and is_skin_valid(num) then
        return true
    end
    if num > 0 then
        local data = wardrobe_data.GetValidHallDepotItemDataByInsID(num)
        if data then
            local rid = data.resID or data.res_id
            if rid and has_skin(rid) then
                return true
            end
        end
    end
    return false
end

function apply_weapon_change(_, req_type, weapon_id, skin_ins, extra_list)
    local wid = tonumber(weapon_id)
    local skin = to_number(skin_ins)
    if skin <= 0 then
        pcall(function() _.PutOffGunAvatar(_) end)
        DataMgr.InitWeaponData(0, 0, 0)
        _.SetGunID(0)
        return
    end
    local rid = 0
    if skin > 0 then
        local data = wardrobe_data.GetValidHallDepotItemDataByInsID(skin)
        if data then
            rid = data.resID or data.res_id
        else
            rid = extract_original_id(skin)
        end
    end
    DataMgr.InitWeaponData(wid, rid, skin)
    if extra_list then
        DataMgr.InitExtraWeaponList(extra_list)
    end
    pcall(function() fashionbag.UpdateCurrentFashionBagWeaponSkin(wid, skin) end)
    if logic_armory.rsp_list and logic_armory.rsp_list.install_list then
        if not logic_armory.rsp_list.install_list[wid] then
            logic_armory.rsp_list.install_list[wid] = {}
        end
        logic_armory.rsp_list.install_list[wid].skin_id = skin
    end
    pcall(function() _.PutOnGunAvatar(wid, rid, nil) end)
    pcall(rebuildWeaponSkinMap, true)
    if req_type == logic_armory.ENUM_REQ_Wardrobe then
        _.SetKeepGunID(_.GetGunID())
        _.SetGunID(wid)
        EventSystem.postEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_UPDATE_CURRENT_PUT_ON_GUN, true, wid, true)
    end
    if skin > 0 and is_skin_valid(skin) then
        throttled_notice()
    end
end

logic_gun.put_on_weapon_wear = function(_, req_type, weapon_id, skin_ins, extra_list)
    local wid = tonumber(weapon_id)
    if wid and wid > 0 then
        local skin = get_current_weapon_skin(wid)
        if skin > 0 and is_skin_valid(skin) then
            logic_gun.SetPreviewGunResID(0)
            apply_weapon_change(_, req_type, wid, skin, extra_list)
            return
        end
    end
    return orig_funcs.put_on_wear(_, req_type, weapon_id, skin_ins, extra_list)
end

logic_gun.pspace_put_on_weapon_wear = function(_, req_type, weapon_id, skin_ins, extra_list)
    local wid = tonumber(weapon_id)
    if wid and wid > 0 then
        local skin = get_current_weapon_skin(wid)
        if skin > 0 and is_skin_valid(skin) then
            apply_weapon_change(_, req_type, wid, skin, extra_list)
            return
        end
    end
    return orig_funcs.pspace_wear(_, req_type, weapon_id, skin_ins, extra_list)
end

logic_gun.on_put_on_weapon_wear_rsp = function(_, req_type, ret, weapon_id, skin_ins, extra_list)
    if is_skin_valid(skin_ins) then
        apply_weapon_change(_, req_type, weapon_id, skin_ins, extra_list)
        return
    end
    return orig_funcs.on_wear_rsp(_, req_type, ret, weapon_id, skin_ins, extra_list)
end

logic_gun.OnPutOnStateChange = function(_)
    local cur = _.GetGunID()
    if cur == 0 then
        cur = _.GetKeepGunID() or 0
    end
    if cur > 0 then
        local skin = get_current_weapon_skin(cur)
        if skin > 0 and is_skin_valid(skin) then
            logic_gun.SetPreviewGunResID(0)
            apply_weapon_change(_, logic_armory.ENUM_REQ_Wardrobe, cur, skin, _.GetExtraWeaponIdList())
            return
        end
    end
    return orig_funcs.OnPutOnStateChange(_)
end

local slot_mapping = {
    [ENUM_ITEM_SUBTYPE.Hat_Slot] = ENUM_AVATAR_SHOW_TYPE.SHOW_POS_HEADWEAR,
    [ENUM_ITEM_SUBTYPE.Mask_Slot] = ENUM_AVATAR_SHOW_TYPE.SHOW_POS_FACE,
    [ENUM_ITEM_SUBTYPE.Package_Slot] = ENUM_AVATAR_SHOW_TYPE.SHOW_POS_CLOTH,
    [ENUM_ITEM_SUBTYPE.Pants_Slot] = ENUM_AVATAR_SHOW_TYPE.SHOW_POS_PANTS,
    [ENUM_ITEM_SUBTYPE.Shoes_Slot] = ENUM_AVATAR_SHOW_TYPE.SHOW_POS_SHOES,
    [ENUM_ITEM_SUBTYPE.Eye_Slot] = ENUM_AVATAR_SHOW_TYPE.SHOW_POS_GLASS,
    [ENUM_ITEM_SUBTYPE.Gloves] = ENUM_AVATAR_SHOW_TYPE.SHOW_POS_GLOVES,
    [ENUM_ITEM_SUBTYPE.Backpack] = ENUM_AVATAR_SHOW_TYPE.SHOW_POS_BAG,
    [ENUM_ITEM_SUBTYPE.Helmet_NoLevel] = ENUM_AVATAR_SHOW_TYPE.SHOW_POS_HELMET,
    [ENUM_ITEM_SUBTYPE.Helmet] = ENUM_AVATAR_SHOW_TYPE.SHOW_POS_HELMET,
    [ENUM_ITEM_SUBTYPE.Upgrade_Backpack] = ENUM_AVATAR_SHOW_TYPE.SHOW_POS_BAG,
}

function get_current_avatar_show()
    local result = {}
    local wear = AvatarData.GetRoleWear() or {}
    for _, ins in pairs(wear) do
        local data = wardrobe_data.GetHallDepotItemDataByInsID(ins)
        if data then
            local slot = slot_mapping[data.itemSubType]
            if slot then
                result[slot] = AvatarData.GetItemWearInfoEnumFormat(ins, data)
            end
        end
    end
    if DataMgr.equipmentSkinInsIDTable then
        local function add_equip(slotType, showPos)
            local ins = to_number(DataMgr.equipmentSkinInsIDTable[slotType])
            if ins > 0 then
                local data = wardrobe_data.GetHallDepotItemDataByInsID(ins)
                if data then
                    result[showPos] = AvatarData.GetItemWearInfoEnumFormat(ins, data)
                end
            end
        end
        add_equip(ENUM_ITEM_SUBTYPE.Backpack, ENUM_AVATAR_SHOW_TYPE.SHOW_POS_BAG)
        add_equip(ENUM_ITEM_SUBTYPE.Upgrade_Backpack, ENUM_AVATAR_SHOW_TYPE.SHOW_POS_BAG)
        add_equip(ENUM_ITEM_SUBTYPE.Helmet, ENUM_AVATAR_SHOW_TYPE.SHOW_POS_HELMET)
        add_equip(ENUM_ITEM_SUBTYPE.Helmet_NoLevel, ENUM_AVATAR_SHOW_TYPE.SHOW_POS_HELMET)
        add_equip(504, ENUM_AVATAR_SHOW_TYPE.SHOW_POS_BAG)
        add_equip(505, ENUM_AVATAR_SHOW_TYPE.SHOW_POS_HELMET)
    end
    local head = AvatarData.GetHeadID() or 0
    if head > 0 then
        result[ENUM_AVATAR_SHOW_TYPE.SHOW_POS_HEAD] = AvatarData.CreateEnumFormatAvatarCustom(head)
    end
    local hair = AvatarData.GetHairID() or 0
    if hair > 0 then
        result[ENUM_AVATAR_SHOW_TYPE.SHOW_POS_HAIR] = AvatarData.CreateEnumFormatAvatarCustom(hair)
    end
    if DataMgr.avatarData and DataMgr.avatarData.attr_info then
        for k, v in pairs(DataMgr.avatarData.attr_info) do
            if type(v) == "table" and next(v) then
                result[k] = table_util.CopyTable(v)
            end
        end
    end
    local gun = logic_gun.GetGunID() or 0
    if gun == 0 then gun = logic_gun.GetKeepGunID() or 0 end
    if gun > 0 then
        result[ENUM_AVATAR_SHOW_TYPE.SHOW_POS_WEAPON] = AvatarData.CreateEnumFormatAvatarCustom(gun)
        local skin_ins = logic_gun.GetSkinIdByWeaponID(gun)
        if skin_ins and to_number(skin_ins) > 0 then
            local data = wardrobe_data.GetHallDepotItemDataByInsID(skin_ins)
            if data then
                result[ENUM_AVATAR_SHOW_TYPE.SHOW_POS_WEAPONSKIN] = AvatarData.GetItemWearInfoEnumFormat(skin_ins, data)
            end
        end
    end
    return result
end

function get_gold_suit_data()
    local switch = {}
    local all = {}
    pcall(function()
        local xsuit = require("client.slua.logic.XSuit.logic_xsuit")
        if not xsuit.switchLevel then xsuit.switchLevel = {} end
        local default_unlock = {
            [2] = { { state = 1 }, { state = 1 } },
            [5] = { { state = 1 } },
            [6] = { { state = 1 } },
            [7] = { { state = 1 } },
        }
        local wear = AvatarData.GetRoleWear() or {}
        for _, ins in pairs(wear) do
            local data = wardrobe_data.GetHallDepotItemDataByInsID(ins)
            if data then
                local rid = data.resID
                if xsuit.IsXSuit(rid) then
                    local period = xsuit.GetPeriodByItemId(rid)
                    if period then
                        local lvl = xsuit.GetLevelByPeriod(period)
                        local cfg = xsuit.GetConfig("switchLevelList")
                        local switch_lvl = cfg and cfg[lvl] or xsuit.GetDefaultSwitchLevelByItemID(rid) or 7
                        switch[period] = switch_lvl
                        xsuit.switchLevel[period] = switch_lvl
                        all[period] = { bicolor_state = 2, unlock_info = default_unlock }
                    end
                end
            end
        end
    end)
    return switch, all
end

if logic_wardrobe.on_puton_rsp and not logic_wardrobe.__fs_puton then
    logic_wardrobe.__fs_puton = true
    local old_puton_rsp = logic_wardrobe.on_puton_rsp
    local old_putdown_rsp = logic_wardrobe.on_putdown_rsp
    logic_wardrobe.on_puton_rsp = function(_, ret, data, ...)
        local result = old_puton_rsp(_, ret, data, ...)
        if ret == 0 and data then
            local cfg = get_item_config(data.res_id)
            if cfg and BACKPACK_SUBTYPES[cfg.itemSubType] then
                apply_backpack_helmet_skin(data)
            end
            trigger_gold_suit_refresh(data)
        end
        build_loadout_snapshot(true)
        return result
    end
    logic_wardrobe.on_putdown_rsp = function(_, ret, data, ...)
        local result = old_putdown_rsp(_, ret, data, ...)
        if ret == 0 and data then
            local cfg = get_item_config(data.res_id)
            if cfg and BACKPACK_SUBTYPES[cfg.itemSubType] then
                if cfg.itemSubType == ENUM_ITEM_SUBTYPE.Backpack or cfg.itemSubType == ENUM_ITEM_SUBTYPE.Upgrade_Backpack then
                    fashionbag.SetBagSkin(0)
                elseif cfg.itemSubType == ENUM_ITEM_SUBTYPE.Helmet or cfg.itemSubType == ENUM_ITEM_SUBTYPE.Helmet_NoLevel then
                    fashionbag.SetHelmetSkin(0)
                end
            end
            trigger_gold_suit_refresh(data)
        end
        build_loadout_snapshot(true)
        return result
    end
end

function get_basic_data_avatar_module()
    return ModuleManager.GetModule(ModuleManager.DataModuleConfig.BasicDataAvatarWearInfo)
end

function build_avatar_show_data(uid, loadout)
    if not uid or not loadout or not loadout.wear_ext or not next(loadout.wear_ext) then
        return nil
    end
    local data = { uid = uid }
    pcall(function() data.gender = AvatarData.GetGameGender() end)
    data.depot_show_info = { weapon = true, vehicle = true, helmet = true, bag = true, social_weapon = true, idle = true }
    inject_wear_ext_into_profile(data, loadout)
    local knap = loadout.knapsack or {}
    data.skin_info = {
        bag_skin = knap.bag_skin or 0,
        helmet_skin = knap.helmet_skin or 0,
        bag_level = knap.bag_level or 3,
        helmet_level = knap.helmet_level or 3,
        head_show = knap.helmet_skin or 0,
    }
    data.pspace_skin_info = table_util.CopyTable(data.skin_info)
    return data
end

function hook_basic_data_avatar()
    local mod = get_basic_data_avatar_module()
    if not mod then return end
    if mod.GetCacheData and not mod.__fs_getcache then
        local old = mod.GetCacheData
        mod.__fs_getcache = true
        mod.GetCacheData = function(_, uid, ...)
            local uid_num = tonumber(uid)
            local local_uid = tonumber(DataMgr and DataMgr.roleData and DataMgr.roleData.uid)
            if uid_num and local_uid and uid_num == local_uid then
                local loadout = get_current_loadout()
                if not loadout or not loadout.wear_ext or not next(loadout.wear_ext) then
                    build_loadout_snapshot(false)
                    loadout = get_current_loadout()
                end
                local custom = build_avatar_show_data(uid_num, loadout)
                if custom then
                    return custom
                end
            end
            return old(_, uid, ...)
        end
    end
    if mod.GetOrReqData and not mod.__fs_getorreq then
        local old = mod.GetOrReqData
        mod.__fs_getorreq = true
        mod.GetOrReqData = function(_, uid, ...)
            local uid_num = tonumber(uid)
            local local_uid = tonumber(DataMgr and DataMgr.roleData and DataMgr.roleData.uid)
            if uid_num and local_uid and uid_num == local_uid then
                local loadout = get_current_loadout()
                if loadout and loadout.wear_ext and next(loadout.wear_ext) then
                    local custom = build_avatar_show_data(uid_num, loadout)
                    if custom then
                        _.OnHandleMsgDataAndCallback(uid, custom)
                        return custom
                    end
                end
            end
            return old(_, uid, ...)
        end
    end
    if mod.on_get_avatar_show_rsp and not mod.__fs_avatar_rsp_hook then
        local old_rsp = mod.on_get_avatar_show_rsp
        mod.__fs_avatar_rsp_fn = old_rsp
        mod.on_get_avatar_show_rsp = function(_, ret, uid, data)
            local local_uid = tonumber(DataMgr and DataMgr.roleData and DataMgr.roleData.uid)
            if ret == 0 and local_uid and tonumber(uid) == local_uid and data then
                local loadout = get_current_loadout()
                if loadout and loadout.wear_ext and next(loadout.wear_ext) then
                    inject_wear_ext_into_profile(data, loadout)
                end
            end
            return old_rsp(_, ret, uid, data)
        end
        mod.__fs_avatar_rsp_hook = true
    end
end

pcall(hook_basic_data_avatar)

EventSystem.registEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_UPDATE_PUT_ON_DATA, function()
    build_loadout_snapshot(true)
end)

EventSystem.registEvent(EVENTTYPE_LOBBY_SOCIAL, EVENTID_LOBBY_SOCIAL_ENTER, function(_, _, uid)
    local local_uid = tonumber(DataMgr and DataMgr.roleData and DataMgr.roleData.uid)
    if tonumber(uid) == local_uid then
        build_loadout_snapshot(false)
    end
end)

function hook_roleinfo_show()
    local mod = require("client.slua.umg.roleInfoNew.logic_new_roleinfo")
    if mod.Show and not mod.__fs_show then
        local old_show = mod.Show
        mod.__fs_show = old_show
        mod.Show = function(_, target_uid, ...)
            local result = old_show(_, target_uid, ...)
            local local_uid = tonumber(DataMgr and DataMgr.roleData and DataMgr.roleData.uid)
            if tonumber(target_uid) == local_uid then
                build_loadout_snapshot(false)
            end
            return result
        end
    end
end
pcall(hook_roleinfo_show)

function hook_xsuit()
    local xsuit = require("client.slua.logic.XSuit.logic_xsuit")
    local old_get_level_by_period = xsuit.GetLevelByPeriod
    xsuit.GetLevelByPeriod = function(period, ...)
        local upgrade = xsuit.GetUpgradeInfo(period)
        if upgrade then
            local max_lvl = 0
            for lvl in pairs(upgrade) do
                local num = tonumber(lvl)
                if num and num > max_lvl then max_lvl = num end
            end
            if max_lvl > 0 then return max_lvl end
        end
        return old_get_level_by_period(period, ...)
    end
    local old_get_level_by_item = xsuit.GetLevelByItemId
    xsuit.GetLevelByItemId = function(item_id)
        if has_skin(item_id) then
            local period = xsuit.GetPeriodByItemId(item_id)
            if period then
                local lvl = xsuit.GetLevelByPeriod(period)
                if lvl and lvl >= 2 then return lvl end
            end
        end
        return old_get_level_by_item(item_id)
    end
    local old_check_has = xsuit.CheckHasEquipXSuit
    xsuit.CheckHasEquipXSuit = function(_, _, period)
        local wear = AvatarData.GetRoleWear() or {}
        for _, ins in pairs(wear) do
            local data = wardrobe_data.GetHallDepotItemDataByInsID(ins)
            if data and xsuit.IsXSuit(data.resID) then
                local p = xsuit.GetPeriodByItemId(data.resID)
                if not period or p == period then
                    return true
                end
            end
        end
        return old_check_has(_, _, period)
    end
    local old_refresh = xsuit.RefreshTeamInfo
    xsuit.RefreshTeamInfo = function(...)
        pcall(function()
            local team = require("client.slua.logic.teamup.logic_team_up")
            local info = team.teamInfo
            if info and info.members then
                local my_uid = DataMgr and DataMgr.roleData and tonumber(DataMgr.roleData.uid)
                if my_uid then
                    local member = info.members[my_uid]
                    if member then
                        inject_gold_suit_into_member(member)
                    end
                end
            end
        end)
        return old_refresh(...)
    end
    local old_check_group = xsuit.CheckHasSameGroupItem
    xsuit.CheckHasSameGroupItem = function(item_id)
        if has_skin(item_id) then
            return true, item_id
        end
        return old_check_group(item_id)
    end
    local old_check_unlock = xsuit.CheckUnlockState
    xsuit.CheckUnlockState = function(...)
        return true
    end
    local old_get_cur_state = xsuit.GetCurStateByPeriod
    xsuit.GetCurStateByPeriod = function(...)
        return 2
    end
end
pcall(hook_xsuit)

function hook_team_up()
    local team = require("client.slua.logic.teamup.logic_team_up")
    if team.GetMemberInfo and not team.__fs_gmi then
        local old = team.GetMemberInfo
        team.__fs_gmi = old
        team.GetMemberInfo = function(uid)
            local data = old(uid)
            if data then
                local local_uid = DataMgr and DataMgr.roleData and tonumber(DataMgr.roleData.uid)
                if tonumber(uid) == local_uid then
                    inject_gold_suit_into_member(data)
                end
            end
            return data
        end
    end
end
pcall(hook_team_up)

function hook_item_upgrade()
    local mod = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.ItemUpgradeModule)
    if not mod then return end
    mod.InitItemUpgradeConfig(mod)
    local function get_upgrade_group(item_id)
        return mod.GetUpgradeGroupByItemID(mod, item_id)
    end
    local function get_max_item_in_group(group)
        if not group or #group == 0 then return nil end
        return group[#group].ItemID
    end
    local function is_upgrade_item(item_id)
        return mod.GetUpgradeCfg(mod, item_id) ~= nil
    end
    local old_check_group = mod.CheckHasSameGroupItem
    mod.CheckHasSameGroupItem = function(_, item_id)
        if is_upgrade_item(item_id) then return true end
        return old_check_group(_, item_id)
    end
    local old_check_refit = mod.CheckHasSameGroupItemAndRefitItem
    mod.CheckHasSameGroupItemAndRefitItem = function(_, item_id)
        if is_upgrade_item(item_id) then
            return true, get_max_item_in_group(get_upgrade_group(item_id))
        end
        return old_check_refit(_, item_id)
    end
    local old_get_cur_level = mod.GetCurLevelByGroupID
    mod.GetCurLevelByGroupID = function(_, group_id)
        local lvl = get_group_level(group_id)
        if lvl > 0 then return lvl end
        return old_get_cur_level(_, group_id)
    end
    local old_get_level_pure = mod.GetLevelByGroupIDPure
    mod.GetLevelByGroupIDPure = function(_, group_id)
        local lvl = get_group_level(group_id)
        if lvl > 0 then return lvl end
        return old_get_level_pure(_, group_id)
    end
    local old_get_level_full = mod.GetLevelByGroupIDFull
    mod.GetLevelByGroupIDFull = function(_, group_id)
        local lvl = get_group_level(group_id)
        if lvl > 0 then return lvl end
        return old_get_level_full(_, group_id)
    end
    local old_get_obtained_max = mod.GetObtainedMaxLevelItemByGroupID
    mod.GetObtainedMaxLevelItemByGroupID = function(_, group_id)
        local group = mod.GetUpgradeGroupByID(mod, group_id)
        if group and #group > 0 and is_upgrade_item(group[1].ItemID) then
            return group[#group].ItemID
        end
        return old_get_obtained_max(_, group_id)
    end
    local old_is_unlock = mod.IsUnlockWeapon
    mod.IsUnlockWeapon = function(_, weapon_id)
        if is_upgrade_item(weapon_id) then return true end
        return old_is_unlock(_, weapon_id)
    end
end
pcall(hook_item_upgrade)

function hook_pet()
    local pet_mod = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_pet)
    if not pet_mod then return end
    local function get_pet_cfg(pet_id)
        return CDataTable.GetTableData("PetTable", pet_id)
    end
    local function get_pet_dress_cfg(dress_id)
        return CDataTable.GetTableData("PetDressTable", dress_id)
    end
    local function get_base_pet_id(ins_or_id)
        local num = tonumber(ins_or_id)
        if not num then return nil end
        local real_id = num
        pcall(function()
            real_id = pet_mod.ConvertToPetID(pet_mod, ins_or_id) or real_id
        end)
        return real_id
    end
    local function create_virtual_pet(pet_id)
        local cfg = get_pet_cfg(pet_id)
        if not cfg then return nil end
        return {
            id = pet_id, ins_id = pet_id, exp = 999999999,
            dress = {}, color = 1, change = 0,
            name = cfg.PetName or "",
        }
    end
    local function ensure_pet_owned(pet_id)
        local pets = pet_mod.MyPetInfo and pet_mod.MyPetInfo.pets
        if not pets then
            if not pet_mod.MyPetInfo then pet_mod.MyPetInfo = {} end
            if not pet_mod.MyPetInfo.pets then pet_mod.MyPetInfo.pets = {} end
            pets = pet_mod.MyPetInfo.pets
        end
        if not pets[pet_id] then
            pets[pet_id] = create_virtual_pet(pet_id)
        end
        local cnt = 0
        for _ in pairs(pets) do cnt = cnt + 1 end
        pet_mod.MyPetInfo.pet_cnt = cnt
        return pets[pet_id]
    end
    local old_has_pet = pet_mod.HasPet
    pet_mod.HasPet = function(_, pet_id)
        local base = get_base_pet_id(pet_id)
        if base and get_pet_cfg(base) then return true end
        return old_has_pet(_, pet_id)
    end
    local old_has_perm = pet_mod.HasPetPermanently
    pet_mod.HasPetPermanently = function(_, pet_id)
        local base = get_base_pet_id(pet_id)
        if base and get_pet_cfg(base) then return true end
        return old_has_perm(_, pet_id)
    end
    local old_has_dress = pet_mod.HasPetDress
    pet_mod.HasPetDress = function(_, _, dress_id)
        if get_pet_dress_cfg(dress_id) then return true end
        return old_has_dress(_, _, dress_id)
    end
    local old_get_by_item = pet_mod.GetPetDataByPetItemID
    pet_mod.GetPetDataByPetItemID = function(_, pet_id)
        local data = old_get_by_item(_, pet_id)
        if not data then
            data = ensure_pet_owned(pet_id)
        end
        return data
    end
    local old_get_by_ins = pet_mod.GetPetDataByInsID
    pet_mod.GetPetDataByInsID = function(_, ins_id)
        local data = old_get_by_ins(_, ins_id)
        if not data then
            local base = get_base_pet_id(ins_id)
            if base then
                data = ensure_pet_owned(base)
            end
        end
        return data
    end
    if pet_mod.UpdateOrderPetList then
        local old_update = pet_mod.UpdateOrderPetList
        pet_mod.UpdateOrderPetList = function(_, list)
            old_update(_, list)
            rebuild_order_pet_list()
        end
    end
    local old_equip = pet_mod.equip_pet_req
    pet_mod.equip_pet_req = function(_, pet_id)
        local base = get_base_pet_id(pet_id)
        if base and get_pet_cfg(base) then
            ensure_pet_owned(base)
            local ins = pet_id
            pcall(function() ins = _.ConvertToInsID(_, base, EPetSource.Self) or base end)
            _.equip_pet_rsp(0, ins)
            return
        end
        return old_equip(_, pet_id)
    end
    local old_unequip = pet_mod.unequip_pet_req
    pet_mod.unequip_pet_req = function(_)
        if _.unequip_pet_rsp then
            _.unequip_pet_rsp(0)
            return
        end
        return old_unequip(_)
    end
end
pcall(hook_pet)

function hook_wardrobe_data_center()
    local center = require("client.slua.logic.wardrobe.logic_wardrobe_data_center")
    local inherit = center.GetWardrobeData(EWardrobeDataSource.InheritWardrobe)
    if inherit and inherit.GetData and not inherit.__fs_getdata then
        local old = inherit.GetData
        inherit.__fs_getdata = old
        inherit.GetData = function(_, flag)
            return extend_table_with_skins(old(_, flag))
        end
    end
    local inherit_logic = require("client.slua.logic.Inherit.LogicInheritWardrobe")
    if inherit_logic and inherit_logic.GetArrayHallDepotItemInfo and not inherit_logic.__fs_inherit_depot then
        local old = inherit_logic.GetArrayHallDepotItemInfo
        inherit_logic.__fs_inherit_depot = old
        inherit_logic.GetArrayHallDepotItemInfo = function(...)
            return extend_table_with_skins(old(...))
        end
    end
end
pcall(hook_wardrobe_data_center)

function hook_avatar_frame()
    local frame_mod = require("client.slua.logic.roleInfo.logic_RoleInfoAvatarFrame")
    local frame_map = _G._FULLSKIN_AVATAR_FRAME_LIST
    local function get_frame_id(id, cfg)
        return tonumber(cfg and (cfg.ID or cfg.Id) or id)
    end
    local function ensure_frame_list()
        if not frame_mod.AvatarFrameList then frame_mod.AvatarFrameList = {} end
        for id, data in pairs(frame_map) do
            frame_mod.AvatarFrameList[id] = data
        end
        if next(frame_map) then
            frame_mod.HasGet = true
            frame_mod._hasGotData = true
        end
    end
    local function build_full_frame_list()
        local tab = CDataTable.GetTable("AvatarFrame") or {}
        local cnt = 0
        for id, cfg in pairs(tab) do
            local fid = get_frame_id(id, cfg)
            if fid and fid > 0 then
                mark_owned(fid)
                if not frame_map[fid] then
                    frame_map[fid] = { expire_time = 1 }
                end
                frame_map[fid].expire_time = 1
                cnt = cnt + 1
            end
        end
        ensure_frame_list()
        return cnt
    end
    local old_has = frame_mod.HasAvatarFrame
    frame_mod.HasAvatarFrame = function(frame_id)
        local fid = tonumber(frame_id)
        if fid and CDataTable.GetTableData("AvatarFrame", fid) then
            return true
        end
        return old_has(fid)
    end
    local old_has_cond = frame_mod.HasAvatarFrameCond
    frame_mod.HasAvatarFrameCond = function(frame_id, ...)
        local fid = tonumber(frame_id)
        if fid and CDataTable.GetTableData("AvatarFrame", fid) then
            return true
        end
        return old_has_cond(fid, ...)
    end
    local old_used_got = frame_mod.UsedGotData
    frame_mod.UsedGotData = function(...)
        build_full_frame_list()
        if old_used_got then return old_used_got(...) end
    end
    local old_set_has = frame_mod.SetHasGetData
    frame_mod.SetHasGetData = function(flag)
        if flag == false then
            build_full_frame_list()
            return
        end
        if old_set_has then old_set_has(flag) end
    end
    local old_list_rsp = frame_mod.get_avatar_box_list_rsp
    frame_mod.get_avatar_box_list_rsp = function(_, ret, list, cur_id)
        init_skin_collection()
        if type(list) ~= "table" or not list then list = {} end
        build_full_frame_list()
        for id, expire in pairs(list) do
            local fid = tonumber(id)
            if fid and fid > 0 then
                if not frame_map[fid] then frame_map[fid] = {} end
                frame_map[fid].expire_time = expire or 1
            end
        end
        ensure_frame_list()
        local new_cur = get_valid_avatar_frame(cur_id)
        if ret == 0 then
            pcall(function() frame_mod.UpdateCurAvatarBoxID(new_cur) end)
        end
        pcall(function() frame_mod.ReadRedDotCacheData() end)
        EventSystem.postEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_UPDATE_AVATAR_FRAME_INFO)
    end
    _G._FULLSKIN_ensureAllAvatarFrames = build_full_frame_list
    _G._FULLSKIN_applyAvatarBoxListRsp = frame_mod.get_avatar_box_list_rsp
    _G._FULLSKIN_prepareAvatarFrameUI = build_full_frame_list
    local old_update_cur = frame_mod.UpdateCurAvatarBoxID
    frame_mod.UpdateCurAvatarBoxID = function(cur_id)
        local new_id = get_valid_avatar_frame(cur_id)
        if new_id > 0 then
            _G._FULLSKIN_LOCAL_AVATAR_BOX_ID = new_id
        end
        return old_update_cur(new_id)
    end
    local old_change_rsp = frame_mod.change_avatar_box_rsp
    frame_mod.change_avatar_box_rsp = function(_, ret, new_id)
        if ret == 0 then
            local fid = tonumber(new_id) or 0
            if fid > 0 then
                _G._FULLSKIN_LOCAL_AVATAR_BOX_ID = fid
                if not frame_map[fid] then frame_map[fid] = { expire_time = 1 } end
                frame_map[fid].expire_time = 1
                ensure_frame_list()
            else
                _G._FULLSKIN_LOCAL_AVATAR_BOX_ID = nil
            end
        end
        return old_change_rsp(_, ret, new_id)
    end
    local old_change_req = frame_mod.change_avatar_box
    frame_mod.change_avatar_box = function(new_id)
        local fid = tonumber(new_id) or 0
        if fid > 0 and CDataTable.GetTableData("AvatarFrame", fid) then
            _G._FULLSKIN_LOCAL_AVATAR_BOX_ID = fid
            frame_mod.change_avatar_box_rsp(0, fid)
            return
        end
        if fid == 0 then
            _G._FULLSKIN_LOCAL_AVATAR_BOX_ID = nil
        end
        return old_change_req(fid)
    end
end
pcall(hook_avatar_frame)

function hook_avatar_frame_handler()
    local handler = require("client.network.Protocol.WardRobeHandler")
    if handler.on_get_avatar_box_list_rsp and not handler.__fs_avatar_box_rsp then
        local old = handler.on_get_avatar_box_list_rsp
        handler.__fs_avatar_box_rsp = old
        handler.on_get_avatar_box_list_rsp = function(_, ret, list, cur_id)
            local frame_mod = require("client.slua.logic.roleInfo.logic_RoleInfoAvatarFrame")
            if frame_mod.get_avatar_box_list_rsp then
                frame_mod.get_avatar_box_list_rsp(ret, list, cur_id)
            else
                old(_, ret, list, cur_id)
            end
        end
    end
end
pcall(hook_avatar_frame_handler)

function hook_avatar_frame_ui()
    local ui = require("client.slua.umg.roleInfoNew.Personalization_AvatarFrame_UIBP")
    if ui and ui.GetItemList and not ui.__fs_get_list then
        local old = ui.GetItemList
        ui.__fs_get_list = true
        ui.GetItemList = function(...)
            if _G._FULLSKIN_prepareAvatarFrameUI then
                _G._FULLSKIN_prepareAvatarFrameUI()
            end
            return old(...)
        end
    end
    local personal = require("client.slua.umg.roleInfoNew.Personalization_UIBP")
    if personal and personal.ShowMainUI and not personal.__fs_show_main then
        local old = personal.ShowMainUI
        personal.__fs_show_main = true
        personal.ShowMainUI = function(...)
            if _G._FULLSKIN_prepareAvatarFrameUI then
                _G._FULLSKIN_prepareAvatarFrameUI()
            end
            return old(...)
        end
    end
end
pcall(hook_avatar_frame_ui)

function hook_avatar_head()
    local avatar_mod = require("client.slua.logic.roleInfo.logic_roleInfo_Avatar")
    local old_has = avatar_mod.HasAvatar
    avatar_mod.HasAvatar = function(avatar_id, ...)
        if CDataTable.GetTableData("Headportrait", tonumber(avatar_id)) then
            return true
        end
        return old_has(avatar_id, ...)
    end
    local old_has_own = avatar_mod.HasOwnHeadPortrait
    avatar_mod.HasOwnHeadPortrait = function(avatar_id)
        if CDataTable.GetTableData("Headportrait", tonumber(avatar_id)) then
            return true
        end
        return old_has_own(avatar_id)
    end
end
pcall(hook_avatar_head)

function hook_title()
    local title_mod = require("client.slua.logic.roleInfo.logic_roleinfo_title")
    local time_util = require("client.common.time_util")
    local STATE_HAVE = 1
    local function build_full_title_list()
        local list = {}
        local now = time_util.GetServerTimeInSec()
        local alias_tab = CDataTable.GetTable("AliasCfg") or {}
        for id, cfg in pairs(alias_tab) do
            local rid = tonumber(id)
            if rid and cfg then
                list[rid] = {
                    state = STATE_HAVE,
                    rank = 0,
                    ext_info = {},
                    rank_id = 0,
                    receive_time = now,
                    expire_ts = 1,
                    have_used = 0,
                    nation = "",
                    title = cfg.AliasName,
                }
            end
        end
        return list
    end
    local old_list_rsp = title_mod.alias_list_res
    title_mod.alias_list_res = function(_, ret, list, ...)
        if ret == 0 then
            local full = build_full_title_list()
            if type(list) == "table" then
                for id, data in pairs(list) do
                    local rid = tonumber(id) or (type(data) == "table" and tonumber(data.id))
                    if rid and full[rid] then
                        if type(data) == "table" then
                            for k, v in pairs(data) do
                                full[rid][k] = v
                            end
                        end
                    end
                end
            end
            title_mod.alias_list_info = full
            list = full
        end
        return old_list_rsp(_, ret, list, ...)
    end
    local old_change_req = title_mod.change_alias_req
    title_mod.change_alias_req = function(title_id, state)
        local tid = tonumber(title_id) or 0
        local st = tonumber(state) or 0
        local cfg = tid > 0 and CDataTable.GetTableData("AliasCfg", tid)
        if cfg then
            if not DataMgr.roleData.alias then DataMgr.roleData.alias = {} end
            if st == 2 then
                local title_text = cfg.AliasName
                pcall(function()
                    if FuncUtil and FuncUtil.Gen_title then
                        local gen = FuncUtil.Gen_title(tid, 0, {}, 0)
                        if gen then title_text = gen end
                    end
                end)
                DataMgr.roleData.alias.id = tid
                DataMgr.roleData.alias.title = title_text
                DataMgr.roleData.alias.nation = ""
                DataMgr.roleData.alias.rank_id = 0
                for _, info in pairs(title_mod.alias_list_info or {}) do
                    if info.state == 2 then
                        info.state = STATE_HAVE
                    end
                end
                if title_mod.alias_list_info and title_mod.alias_list_info[tid] then
                    title_mod.alias_list_info[tid].state = 2
                end
            else
                DataMgr.roleData.alias.id = 0
                DataMgr.roleData.alias.title = ""
                DataMgr.roleData.alias.nation = ""
                DataMgr.roleData.alias.rank_id = 0
                for _, info in pairs(title_mod.alias_list_info or {}) do
                    if info.state == 2 then
                        info.state = STATE_HAVE
                    end
                end
            end
            pcall(function() title_mod.initAliasInfo() end)
            EventSystem.postEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_UPDATE_ALL_TITLE)
            EventSystem.postEvent(EVENTTYPE_LOBBY, EVENTID_UPDATE_LOBBY_AVATAR)
            pcall(function() RoomSystem.RefreshMyProfileInRoom() end)
            return
        end
        return old_change_req(tid, st)
    end
    title_mod.alias_list_info = build_full_title_list()
    pcall(function() title_mod.initAliasInfo() end)
end
pcall(hook_title)

function hook_extra_events()
    EventSystem.registEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_RECEIVE_INHERIT_DATA, function()
        pcall(function()
            local center = require("client.slua.logic.wardrobe.logic_wardrobe_data_center")
            local inherit = center.GetWardrobeData(EWardrobeDataSource.InheritWardrobe)
            if inherit then
                local data = inherit.GetData(true)
                extend_table_with_skins(data)
            end
        end)
    end)
    EventSystem.registEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_UPDATE_USE_AVATAR, function()
        build_loadout_snapshot(false)
    end)
end
pcall(hook_extra_events)

function hook_store_utils()
    local utils = require("client.slua.logic.store.utils.store_utils_config")
    if utils and utils.HasItem and not utils.__fs_hasitem then
        local old = utils.HasItem
        utils.__fs_hasitem = old
        utils.HasItem = function(item_id, ...)
            if has_skin(item_id) then return true end
            return old(item_id, ...)
        end
    end
end
pcall(hook_store_utils)

function hook_datamgr_avatar()
    if DataMgr and DataMgr.HasAvatarById and not DataMgr.__fs_hasavatar then
        local old = DataMgr.HasAvatarById
        DataMgr.__fs_hasavatar = old
        DataMgr.HasAvatarById = function(avatar_id)
            if has_skin(avatar_id) then return true end
            return old(avatar_id)
        end
    end
end
pcall(hook_datamgr_avatar)

function hook_collect_module()
    local collect_mod = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.collect_module)
    if not collect_mod then return false end
    if collect_mod.OnGetMainData and not collect_mod.__fs_main then
        local old = collect_mod.OnGetMainData
        collect_mod.__fs_main = old
        collect_mod.OnGetMainData = function(_, ret, data, ...)
            if data then
                data.total_score = _G._FULLSKIN_MAX_COLLECT_SCORE or 999999999
                data.cur_season_collect_score = data.total_score
                if not data.season_score then data.season_score = {} end
                if DataMgr and DataMgr.season_id then
                    data.season_score[DataMgr.season_id] = data.total_score
                end
                inject_collect_data(data)
            end
            local result = old(_, ret, data, ...)
            force_collect_level(collect_mod)
            trigger_collect_update()
            return result
        end
    end
    if collect_mod.NotifyCollectData and not collect_mod.__fs_notify then
        local old = collect_mod.NotifyCollectData
        collect_mod.__fs_notify = old
        collect_mod.NotifyCollectData = function(_, data)
            if data then
                data.total_score = _G._FULLSKIN_MAX_COLLECT_SCORE or 999999999
                data.cur_season_collect_score = data.total_score
                if not data.season_score then data.season_score = {} end
                if DataMgr and DataMgr.season_id then
                    data.season_score[DataMgr.season_id] = data.total_score
                end
                inject_collect_data(data)
            end
            local result = old(_, data)
            force_collect_level(collect_mod)
            return result
        end
    end
    if collect_mod.GetCollectTotalScore and not collect_mod.__fs_totalscore then
        local old = collect_mod.GetCollectTotalScore
        collect_mod.__fs_totalscore = old
        collect_mod.GetCollectTotalScore = function(_)
            force_collect_level(_)
            return _G._FULLSKIN_MAX_COLLECT_SCORE or 999999999, _G._FULLSKIN_MAX_COLLECT_LEVEL or 100
        end
    end
    if collect_mod.GetLevelByScore and not collect_mod.__fs_lvscore then
        local old = collect_mod.GetLevelByScore
        collect_mod.__fs_lvscore = old
        collect_mod.GetLevelByScore = function(_, score)
            if score and score >= (_G._FULLSKIN_MAX_COLLECT_SCORE or 999999999) then
                return _G._FULLSKIN_MAX_COLLECT_LEVEL or 100, 100, _G._FULLSKIN_MAX_COLLECT_LEVEL or 100, 0, 0
            end
            return old(_, score)
        end
    end
    if collect_mod.GetLevelDataByScore and not collect_mod.__fs_lvdata then
        local old = collect_mod.GetLevelDataByScore
        collect_mod.__fs_lvdata = old
        collect_mod.GetLevelDataByScore = function(_, score, isSeason)
            if score and score >= (_G._FULLSKIN_MAX_COLLECT_SCORE or 999999999) then
                if isSeason then
                    return _G._FULLSKIN_MAX_SEASON_LEVEL or 100, "", 100
                else
                    return _G._FULLSKIN_MAX_COLLECT_LEVEL or 100, "", 100
                end
            end
            return old(_, score, isSeason)
        end
    end
    if collect_mod.GetSeasonLevelByScore and not collect_mod.__fs_seasonlv then
        local old = collect_mod.GetSeasonLevelByScore
        collect_mod.__fs_seasonlv = old
        collect_mod.GetSeasonLevelByScore = function(_, score, ...)
            if score and score >= (_G._FULLSKIN_MAX_COLLECT_SCORE or 999999999) then
                return _G._FULLSKIN_MAX_SEASON_LEVEL or 100, false, ""
            end
            return old(_, score, ...)
        end
    end
    if collect_mod.GetCollectScoreByProfile and not collect_mod.__fs_proscore then
        local old = collect_mod.GetCollectScoreByProfile
        collect_mod.__fs_proscore = old
        collect_mod.GetCollectScoreByProfile = function(_, profile)
            local local_uid = DataMgr and DataMgr.roleData and tonumber(DataMgr.roleData.uid)
            if local_uid and profile then
                if type(profile) == "table" and tonumber(profile.uid) == local_uid then
                    return _G._FULLSKIN_MAX_COLLECT_SCORE or 999999999, _G._FULLSKIN_MAX_COLLECT_SCORE or 999999999
                end
                if profile == local_uid then
                    return _G._FULLSKIN_MAX_COLLECT_SCORE or 999999999, _G._FULLSKIN_MAX_COLLECT_SCORE or 999999999
                end
            end
            local total, cur = old(_, profile)
            if total >= (_G._FULLSKIN_MAX_COLLECT_SCORE or 999999999) then
                return _G._FULLSKIN_MAX_COLLECT_SCORE or 999999999, _G._FULLSKIN_MAX_COLLECT_SCORE or 999999999
            end
            return total, cur
        end
    end
    if collect_mod.GetCollectScoreByCollectData and not collect_mod.__fs_colscore then
        local old = collect_mod.GetCollectScoreByCollectData
        collect_mod.__fs_colscore = old
        collect_mod.GetCollectScoreByCollectData = function(_, data)
            local my_data = DataMgr and DataMgr.roleData and DataMgr.roleData.brief_collect_data
            if data and my_data and data == my_data then
                init_collect_data()
                return _G._FULLSKIN_MAX_COLLECT_SCORE or 999999999, _G._FULLSKIN_MAX_COLLECT_SCORE or 999999999
            end
            if data and data.total_score and data.total_score >= (_G._FULLSKIN_MAX_COLLECT_SCORE or 999999999) then
                return _G._FULLSKIN_MAX_COLLECT_SCORE or 999999999, _G._FULLSKIN_MAX_COLLECT_SCORE or 999999999
            end
            local total, cur = old(_, data)
            if total >= (_G._FULLSKIN_MAX_COLLECT_SCORE or 999999999) then
                return _G._FULLSKIN_MAX_COLLECT_SCORE or 999999999, _G._FULLSKIN_MAX_COLLECT_SCORE or 999999999
            end
            return total, cur
        end
    end
    if collect_mod.OnGetItemData and not collect_mod.__fs_item then
        local old = collect_mod.OnGetItemData
        collect_mod.__fs_item = old
        collect_mod.OnGetItemData = function(_, uid, data)
            local local_uid = DataMgr and DataMgr.roleData and tonumber(DataMgr.roleData.uid)
            if tonumber(uid) == local_uid and data then
                if not data.item_detail then data.item_detail = {} end
                init_skin_collection()
                for rid in pairs(owned_skin_set) do
                    if not data.item_detail[rid] then
                        data.item_detail[rid] = { count = 1, expire_ts = 0 }
                    end
                end
            end
            return old(_, uid, data)
        end
    end
    force_collect_level(collect_mod)
    init_collect_data()
    collect_mod.__fs_hook_logged = true
    return true
end
pcall(hook_collect_module)

function hook_lobby_social()
    local social = require("client.slua.logic.lobby.Left.logic_lobby_social")
    if social and social.GetSelfProfile and not social.__fs_selfprofile then
        local old = social.GetSelfProfile
        social.__fs_selfprofile = true
        social.GetSelfProfile = function()
            init_collect_data()
            local profile = old()
            if profile then
                profile.cur_avatar_box_id = get_valid_avatar_frame(profile.cur_avatar_box_id)
            end
            return profile
        end
    end
end
pcall(hook_lobby_social)

if not _G.__fs_collect_evt then
    _G.__fs_collect_evt = true
    EventSystem.registEvent(EVENTTYPE_COLLECT, EVENTID_COLLECT_MAIN_DATA, function()
        pcall(init_collect_data)
        pcall(trigger_collect_update)
    end)
end

function fill_table_with_ids(t, tabName, idField)
    local tab = CDataTable.GetTable(tabName) or {}
    for _, entry in pairs(tab) do
        local id = idField and entry[idField] or _
        if tonumber(id) and tonumber(id) > 0 then
            t[tonumber(id)] = { expire_ts = 0 }
        end
    end
    return t
end

function build_nickname_effect_map(existing)
    local result = {}
    if type(existing) == "table" then
        for k, v in pairs(existing) do result[k] = v end
    end
    local tab = CDataTable.GetTable("NicknameEffectCfg") or {}
    for id, cfg in pairs(tab) do
        local rid = tonumber(cfg.ID or id)
        if rid and rid > 0 and not result[rid] then
            result[rid] = {
                is_show = tonumber(cfg.is_show or cfg.IsShow) or 1,
                start_display_ts = 0,
                display_order = tonumber(cfg.display_order or cfg.DisplayOrder) or rid,
                access_display_ts = 0,
            }
        end
    end
    return result
end

function build_chat_effect_map(existing)
    local result = {}
    if type(existing) == "table" then
        for k, v in pairs(existing) do result[k] = v end
    end
    local tab = CDataTable.GetTable("ChatEffectCfg") or {}
    for id, cfg in pairs(tab) do
        local rid = tonumber(cfg.ID or id)
        if rid and rid > 0 and not result[rid] then
            result[rid] = {
                is_show = tonumber(cfg.is_show or cfg.IsShow) or 1,
                start_display_ts = 0,
                display_order = tonumber(cfg.display_order or cfg.DisplayOrder) or rid,
                access_display_ts = 0,
            }
        end
    end
    return result
end

function hook_nickname_frame()
    local mod = require("client.slua.logic.roleInfo.logic_roleInfo_nicknameframe")
    local old_proc = mod.ProcNicknameListRsp
    mod.ProcNicknameListRsp = function(_, list, custom)
        if not list then list = {} end
        list.skins = fill_table_with_ids(list.skins or {}, "NicknameEffectCfg", "ID")
        custom = build_nickname_effect_map(custom)
        return old_proc(_, list, custom)
    end
    local old_has = mod.HasFrame
    mod.HasFrame = function(_, frame_id, ...)
        if CDataTable.GetTableData("NicknameEffectCfg", tonumber(frame_id)) then
            return true
        end
        return old_has(_, frame_id, ...)
    end
end
pcall(hook_nickname_frame)

function hook_chat_frame()
    local mod = require("client.slua.logic.roleInfo.logic_roleInfo_chatframe")
    local old_proc = mod.ProcChatListRsp
    mod.ProcChatListRsp = function(_, list, custom)
        if not list then list = {} end
        list.bubbles = fill_table_with_ids(list.bubbles or {}, "ChatEffectCfg", "ID")
        custom = build_chat_effect_map(custom)
        return old_proc(_, list, custom)
    end
    local old_has = mod.HasChatBubble
    mod.HasChatBubble = function(_, bubble_id, ...)
        if CDataTable.GetTableData("ChatEffectCfg", tonumber(bubble_id)) then
            return true
        end
        return old_has(_, bubble_id, ...)
    end
end
pcall(hook_chat_frame)

function hook_teamup_frame()
    local mod = require("client.slua.logic.roleInfo.logic_roleInfo_TeamUpFrame")
    local old_rsp = mod.on_get_team_notify_skin_list_rsp
    mod.on_get_team_notify_skin_list_rsp = function(_, ret, list, cur_id)
        if ret == 0 then
            if not list then list = {} end
            local tab = CDataTable.GetTable("TeamUpPopFrame") or {}
            for id in pairs(tab) do
                local rid = tonumber(id)
                if rid and not list[rid] then
                    list[rid] = { expire_time = 1 }
                end
            end
        end
        return old_rsp(_, ret, list, cur_id)
    end
    local old_change = mod.send_change_team_notify_skin
    mod.send_change_team_notify_skin = function(_, skin_id)
        local sid = tonumber(skin_id) or 0
        if sid > 0 and CDataTable.GetTableData("TeamUpPopFrame", sid) then
            mod.on_change_team_notify_skin_rsp(0, sid)
            return
        end
        return old_change(_, sid)
    end
end
pcall(hook_teamup_frame)

function hook_nameframe()
    if DataMgr and DataMgr.roleData then
        if not DataMgr.roleData.nameFrameData then DataMgr.roleData.nameFrameData = {} end
        local tab = CDataTable.GetTable("NameFrame") or {}
        for id in pairs(tab) do
            local rid = tonumber(id)
            if rid then
                DataMgr.roleData.nameFrameData[rid] = { expire_ts = 0, is_used = 0 }
            end
        end
    end
    local mod = require("client.slua.logic.person_space.logic_roleinfo_nameframe")
    local old_use = mod.use_brand
    mod.use_brand = function(brand_id)
        local bid = tonumber(brand_id) or 0
        if bid ~= 0 and DataMgr.roleData and DataMgr.roleData.nameFrameData and DataMgr.roleData.nameFrameData[bid] then
            mod.use_brand_rsp(0, bid)
            return
        end
        return old_use(bid)
    end
end
pcall(hook_nameframe)

function hook_doorplate()
    local mod = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_home_door_plate)
    if mod and mod.on_get_manor_skin_data_rsp and not mod.__fs_manor then
        local old = mod.on_get_manor_skin_data_rsp
        mod.__fs_manor = old
        mod.on_get_manor_skin_data_rsp = function(_, data)
            if not data then data = {} end
            if not data.unlocked_skin_list then data.unlocked_skin_list = {} end
            local tab = CDataTable.GetTable("DoorPlate") or {}
            for id in pairs(tab) do
                local rid = tonumber(id)
                if rid then
                    data.unlocked_skin_list[rid] = { expire_time = 0 }
                end
            end
            return old(_, data)
        end
    end
end
pcall(hook_doorplate)

function hook_nickname_color()
    local mod = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.NicknameColorManager)
    if mod and mod.on_get_collect_award_privilege_rsp and not mod.__fs_priv then
        local old = mod.on_get_collect_award_privilege_rsp
        mod.__fs_priv = old
        mod.on_get_collect_award_privilege_rsp = function(_, data)
            if not data then data = {} end
            if not data.msg_recolor then data.msg_recolor = {} end
            if not data.msg_recolor.all_colors then data.msg_recolor.all_colors = {} end
            local tab = CDataTable.GetTable("NicknameColorCfg") or {}
            for _, cfg in pairs(tab) do
                local pid = tonumber(cfg.PlanID)
                if pid then
                    data.msg_recolor.all_colors[pid] = { expire_time = 1 }
                end
            end
            return old(_, data)
        end
        if mod.send_set_collect_privilege_req and not mod.__fs_setcolor then
            local old_set = mod.send_set_collect_privilege_req
            mod.__fs_setcolor = old_set
            mod.send_set_collect_privilege_req = function(_, color_id, op_type)
                if not _.msg_recolor then _.msg_recolor = {} end
                if not _.msg_recolor.all_colors then _.msg_recolor.all_colors = {} end
                local tab = CDataTable.GetTable("NicknameColorCfg") or {}
                for _, cfg in pairs(tab) do
                    local pid = tonumber(cfg.PlanID)
                    if pid then
                        _.msg_recolor.all_colors[pid] = { expire_time = 1 }
                    end
                end
                if op_type == _.OPTYPE.PUT_ON then
                    if not color_id then return end
                    if _.msg_recolor.use_color == color_id then return end
                    _.msg_recolor.use_color = color_id
                    _.SetUserData(DataMgr.roleData.uid, color_id)
                    EventSystem.postEvent(EVENTTYPE_COLLECT, EVENTID_COLLECT_NICKNAME_COLOR_CHANGE, tostring(DataMgr.roleData.uid))
                elseif op_type == _.OPTYPE.PUT_OFF then
                    if not _.msg_recolor.use_color then return end
                    _.msg_recolor.use_color = nil
                    _.SetUserData(DataMgr.roleData.uid, _.DEFAULT_PLAN_ID)
                    EventSystem.postEvent(EVENTTYPE_COLLECT, EVENTID_COLLECT_NICKNAME_COLOR_CHANGE, tostring(DataMgr.roleData.uid))
                else
                    return old_set(_, color_id, op_type)
                end
            end
        end
    end
end
pcall(hook_nickname_color)

function hook_chatroom_bg()
    local mod = require("client.slua.logic.lobby_chat.chatroom.LogicChatRoomBG")
    if mod and mod.on_get_chat_background_rsp and not mod.__fs_bg then
        local old = mod.on_get_chat_background_rsp
        mod.__fs_bg = old
        mod.on_get_chat_background_rsp = function(_, ret, list, cur_id)
            if not list then list = {} end
            local tab = CDataTable.GetTable("ChatRoomBgConfig") or {}
            for id in pairs(tab) do
                local rid = tonumber(id)
                if rid and not list[rid] then
                    list[rid] = { expire_ts = 0, is_new = false }
                end
            end
            return old(_, ret, list, cur_id)
        end
    end
end
pcall(hook_chatroom_bg)

function hook_gold_suit()
    local xsuit = require("client.slua.logic.XSuit.logic_xsuit")
    if not xsuit.__fs_levelaction then
        xsuit.__fs_levelaction = xsuit.GetLevelAction
        xsuit.GetLevelAction = function(period)
            if period then
                return 5
            end
            return xsuit.__fs_levelaction(period)
        end
        if not xsuit.levelAction then xsuit.levelAction = {} end
        local gsTab = CDataTable.GetTable("GoldenSuitMapCfg") or {}
        for _, cfg in pairs(gsTab) do
            local period = cfg.Period or cfg.period
            if period then
                xsuit.levelAction[period] = 5
            end
        end
    end
    local handler = require("client.network.Protocol.XSuitHandler")
    if handler and handler.on_gold_dress_get_level_action_rsp and not handler.__fs_larsp then
        local old = handler.on_gold_dress_get_level_action_rsp
        handler.__fs_larsp = old
        handler.on_gold_dress_get_level_action_rsp = function(_, ret, data)
            if ret == 0 then
                if not data then data = {} end
                local gsTab = CDataTable.GetTable("GoldenSuitMapCfg") or {}
                for _, cfg in pairs(gsTab) do
                    local period = cfg.Period or cfg.period
                    if period then
                        data[period] = 5
                    end
                end
                xsuit.levelAction = data
            end
            return old(_, ret, data)
        end
    end
    local gold_mod = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.golden_suit_module)
    if gold_mod and gold_mod.EmoteNeedClothesWithWord then
        local old_need = gold_mod.EmoteNeedClothesWithWord
        gold_mod.EmoteNeedClothesWithWord = function(_, emote_id)
            local cfg = CDataTable.GetTableData("Clothes2EmoteCfg", emote_id)
            if cfg and cfg.ItemID_a then
                for _, rid in pairs(cfg.ItemID_a) do
                    if has_skin(rid) then
                        return
                    end
                end
            end
            return old_need(_, emote_id)
        end
        local old_need_all = gold_mod.EmoteNeedClothesAllWithWord
        gold_mod.EmoteNeedClothesAllWithWord = function(_, emote_id)
            local cfg = CDataTable.GetTableData("EmotionLimitCfg", emote_id)
            if cfg and cfg.ItemID_a then
                local all_ok = true
                for _, rid in pairs(cfg.ItemID_a) do
                    if not has_skin(rid) then
                        all_ok = false
                        break
                    end
                end
                if all_ok then return end
            end
            return old_need_all(_, emote_id)
        end
    end
    local old_is_battle = xsuit.IsBattleEmotion
    xsuit.IsBattleEmotion = function(emote_id)
        if has_skin(emote_id) then return false end
        if CDataTable.GetTableData("Clothes2EmoteCfg", emote_id) then return false end
        return old_is_battle(emote_id)
    end
end
pcall(hook_gold_suit)

function build_milestone_list(data)
    local tab = CDataTable.GetTable("MilestoneConfig") or {}
    for _, cfg in pairs(tab) do
        local id = tonumber(cfg.ID or cfg.Id or _)
        if id and id > 0 then
            data[id] = 1
        end
    end
    return data
end

function inject_milestone_data(data)
    if not data then return end
    data.AcquiredMileList = build_milestone_list(data.AcquiredMileList or {})
    data.bHaveReceivedMileData = true
end

function is_generic_item_owned(item_id)
    local rid = tonumber(item_id)
    if rid and rid > 0 and has_skin(rid) then return true end
    local tables = {
        "PersonalOpeningCfg", "RoleInfoBackgroundCfg", "SocialCardBGInfo",
        "NicknameEffectCfg", "ChatEffectCfg", "TeamUpPopFrame",
        "NameFrame", "DoorPlate", "ChatRoomBgConfig", "CarteFrameConfig", "Headportrait",
    }
    for _, tab in ipairs(tables) do
        if CDataTable.GetTableData(tab, rid) then
            return true
        end
    end
    local carte = CDataTable.GetTableData("CarteFrameConfig", rid)
    if carte and carte.SkinID == rid then return true end
    return false
end

function init_all_misc()
    pcall(function()
        local nick_mod = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_roleInfo_nicknameframe)
        if nick_mod then
            local fake_list = { skins = fill_table_with_ids({}, "NicknameEffectCfg", "ID"), equip = DataMgr.roleData.friend_nickname_skin or 0 }
            nick_mod.ProcNicknameListRsp(nick_mod, fake_list, build_nickname_effect_map(nil))
        end
    end)
    pcall(function()
        local chat_mod = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_roleInfo_chatframe)
        if chat_mod then
            local fake_list = { bubbles = fill_table_with_ids({}, "ChatEffectCfg", "ID"), equip = DataMgr.roleData.chat_bubble or 0 }
            chat_mod.ProcChatListRsp(chat_mod, fake_list, build_chat_effect_map(nil))
        end
    end)
    pcall(function()
        local teamup_mod = require("client.slua.logic.roleInfo.logic_roleInfo_TeamUpFrame")
        local list = {}
        local tab = CDataTable.GetTable("TeamUpPopFrame") or {}
        for id in pairs(tab) do
            local rid = tonumber(id)
            if rid then list[rid] = { expire_time = 1 } end
        end
        teamup_mod.on_get_team_notify_skin_list_rsp(teamup_mod, 0, list, DataMgr.roleData.cur_team_notify_skin_id or 0)
    end)
    pcall(function()
        local carte_mod = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_roleinfo_carte_frame)
        if carte_mod then
            carte_mod.InitCarteFrameMap(carte_mod)
            local list = {}
            for id in pairs(carte_mod.CarteFrameMap or {}) do
                list[id] = { expire_ts = 0 }
                if carte_mod.CarteFrameMap[id] then
                    carte_mod.CarteFrameMap[id].bLock = false
                    carte_mod.CarteFrameMap[id].expire_ts = 0
                end
            end
            local cur = carte_mod.GetCurrentCrateFrameBGID(carte_mod) or 61100001
            carte_mod.get_carte_frame_list_rsp(carte_mod, 0, list, cur)
        end
    end)
    pcall(function()
        if _G._FULLSKIN_ensureAllAvatarFrames then
            _G._FULLSKIN_ensureAllAvatarFrames()
        else
            local frame_mod = require("client.slua.logic.roleInfo.logic_RoleInfoAvatarFrame")
            local tab = CDataTable.GetTable("AvatarFrame") or {}
            for id, cfg in pairs(tab) do
                local fid = tonumber(cfg.ID or cfg.Id or id)
                if fid and fid > 0 then
                    _G._FULLSKIN_AVATAR_FRAME_LIST[fid] = { expire_time = 1 }
                    frame_mod.AvatarFrameList[fid] = _G._FULLSKIN_AVATAR_FRAME_LIST[fid]
                end
            end
            frame_mod.HasGet = true
            frame_mod._hasGotData = true
        end
    end)
    pcall(function()
        local avatar_mod = require("client.slua.logic.roleInfo.logic_roleInfo_Avatar")
        local tab = CDataTable.GetTable("Headportrait") or {}
        for id in pairs(tab) do
            avatar_mod.HeadportraitList[tostring(id)] = 1
        end
        EventSystem.postEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_UPDATE_HEAD_INFO, DataMgr.roleData.headIconUrl)
    end)
    pcall(function()
        local emote_mod = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LobbyEmoteManager)
        if emote_mod then
            inject_milestone_data(emote_mod)
            emote_mod.bHaveReceivedMileData = true
            EventSystem.postEvent(EVENTTYPE_MOTION, EVENTID_MOTION_MILELIST_DATA_CHANGE)
        end
    end)
    pcall(function()
        if hook_collect_module then hook_collect_module() end
        init_collect_data()
        trigger_collect_update()
    end)
end

function hook_roleinfo_bg_handler()
    local handler = require("client.network.Protocol.RoleInfoBGHandler")
    if handler.send_set_social_info_bg_req and not handler.__fs_setbg then
        local old = handler.send_set_social_info_bg_req
        handler.__fs_setbg = old
        handler.send_set_social_info_bg_req = function(_, bg_id)
            if bg_id and is_generic_item_owned(bg_id) then
                handler.on_set_social_info_bg_rsp(0, _, bg_id)
                return
            end
            return old(_, bg_id)
        end
    end
end
pcall(hook_roleinfo_bg_handler)

function hook_social_card_bg()
    local handler = require("client.network.Protocol.SocialCardBGHandler")
    if handler.send_set_social_card_floor_req and not handler.__fs_set then
        local old = handler.send_set_social_card_floor_req
        handler.__fs_set = old
        handler.send_set_social_card_floor_req = function(bg_id)
            local bid = tonumber(bg_id)
            if bid and is_generic_item_owned(bid) then
                pcall(function()
                    local mod = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_social_card_bg)
                    if mod then mod.CurrentSocialCardBGID = bid end
                end)
                handler.on_set_social_card_floor_rsp(0)
                return
            end
            return old(bg_id)
        end
    end
end
pcall(hook_social_card_bg)

function hook_roleinfo_handler()
    local handler = require("client.network.Protocol.RoleInfoHandler")
    if handler.send_set_friend_nickname_skin_req and not handler.__fs_nick then
        local old = handler.send_set_friend_nickname_skin_req
        handler.__fs_nick = old
        handler.send_set_friend_nickname_skin_req = function(skin_id)
            if CDataTable.GetTableData("NicknameEffectCfg", tonumber(skin_id)) then
                handler.on_set_friend_nickname_skin_rsp(0, skin_id)
                return
            end
            return old(skin_id)
        end
    end
    if handler.send_set_chat_bubble_req and not handler.__fs_chat then
        local old = handler.send_set_chat_bubble_req
        handler.__fs_chat = old
        handler.send_set_chat_bubble_req = function(bubble_id)
            if CDataTable.GetTableData("ChatEffectCfg", tonumber(bubble_id)) then
                handler.on_set_chat_bubble_rsp(0, bubble_id)
                return
            end
            return old(bubble_id)
        end
    end
    if handler.send_equip_carte_frame_req and not handler.__fs_carte then
        local old = handler.send_equip_carte_frame_req
        handler.__fs_carte = old
        handler.send_equip_carte_frame_req = function(frame_id, ...)
            if CDataTable.GetTableData("CarteFrameConfig", tonumber(frame_id)) then
                handler.on_equip_carte_frame_rsp(0, frame_id, ...)
                return
            end
            return old(frame_id, ...)
        end
    end
    if handler.on_get_friend_nickname_skin_rsp and not handler.__fs_nick_rsp then
        local old = handler.on_get_friend_nickname_skin_rsp
        handler.__fs_nick_rsp = old
        handler.on_get_friend_nickname_skin_rsp = function(_, ret, data, custom)
            if ret == 0 and data then
                data.skins = fill_table_with_ids(data.skins or {}, "NicknameEffectCfg", "ID")
                custom = build_nickname_effect_map(custom)
            end
            return old(_, ret, data, custom)
        end
    end
    if handler.on_get_chat_bubble_rsp and not handler.__fs_chat_rsp then
        local old = handler.on_get_chat_bubble_rsp
        handler.__fs_chat_rsp = old
        handler.on_get_chat_bubble_rsp = function(_, ret, data, custom)
            if ret == 0 and data then
                data.bubbles = fill_table_with_ids(data.bubbles or {}, "ChatEffectCfg", "ID")
                custom = build_chat_effect_map(custom)
            end
            return old(_, ret, data, custom)
        end
    end
    if handler.send_get_carte_frame_list_req and not handler.__fs_carte_get then
        local old = handler.send_get_carte_frame_list_req
        handler.__fs_carte_get = old
        handler.send_get_carte_frame_list_req = function()
            local list = {}
            local tab = CDataTable.GetTable("CarteFrameConfig") or {}
            for _, cfg in pairs(tab) do
                local sid = cfg.SkinID
                if sid then
                    list[sid] = { expire_ts = 0 }
                end
            end
            local cur = 61100001
            local carte_mod = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_roleinfo_carte_frame)
            if carte_mod and carte_mod.GetCurrentCrateFrameBGID then
                cur = carte_mod.GetCurrentCrateFrameBGID(carte_mod) or cur
            end
            handler.on_get_carte_frame_list_rsp(0, list, cur)
        end
    end
end
pcall(hook_roleinfo_handler)

function hook_character_handler()
    local handler = require("client.network.Protocol.CharacterHandler")
    if handler.send_change_user_avatar and not handler.__fs_avatar then
        local old = handler.send_change_user_avatar
        handler.__fs_avatar = old
        handler.send_change_user_avatar = function(avatar_id)
            local aid = tonumber(avatar_id)
            if aid and CDataTable.GetTableData("Headportrait", aid) then
                local avatar_mod = require("client.slua.logic.roleInfo.logic_roleInfo_Avatar")
                avatar_mod.HeadportraitList[tostring(aid)] = 1
                avatar_mod.change_user_avatar_rsp(0, tostring(aid), 0)
                return
            end
            return old(avatar_id)
        end
    end
end
pcall(hook_character_handler)

function hook_emote_handler()
    local handler = require("client.network.Protocol.EmoteHandler")
    if handler.on_get_all_milestone_data_rsp and not handler.__fs_mile then
        local old = handler.on_get_all_milestone_data_rsp
        handler.__fs_mile = old
        handler.on_get_all_milestone_data_rsp = function(_, ret, list, ...)
            if ret == 0 then
                list = build_milestone_list(list or {})
            end
            return old(_, ret, list, ...)
        end
    end
    if handler.send_save_milestone_slot_info_req and not handler.__fs_save_slot then
        local old = handler.send_save_milestone_slot_info_req
        handler.__fs_save_slot = old
        handler.send_save_milestone_slot_info_req = function(slot_id, milestone_id, ...)
            handler.on_save_milestone_slot_info_rsp(0, slot_id, milestone_id, ...)
        end
    end
end
pcall(hook_emote_handler)

function hook_lobby_emote_manager()
    local emote_mod = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LobbyEmoteManager)
    if emote_mod then
        inject_milestone_data(emote_mod)
        local old_check_self = emote_mod.CheckSelfMilestoneAcquired
        emote_mod.CheckSelfMilestoneAcquired = function(_, milestone_id)
            local mid = tonumber(milestone_id)
            if mid and (_.AcquiredMileList[mid] == 1 or CDataTable.GetTableData("MilestoneConfig", mid)) then
                return true
            end
            return old_check_self(_, mid)
        end
        local old_get_milestones = emote_mod.GetMilestones
        emote_mod.GetMilestones = function(_, type, list, ...)
            list = build_milestone_list(list or {})
            return old_get_milestones(_, type, list, false)
        end
        if emote_mod.SetMilestoneSlotInfo and not emote_mod.__fs_set_slot then
            local old = emote_mod.SetMilestoneSlotInfo
            emote_mod.__fs_set_slot = old
            emote_mod.SetMilestoneSlotInfo = function(_, slot_id, milestone_id, ...)
                local handler = require("client.network.Protocol.EmoteHandler")
                handler.on_save_milestone_slot_info_rsp(0, slot_id, milestone_id, ...)
            end
        end
        if emote_mod.OnMileStoneDataRsp and not emote_mod.__fs_mile_rsp then
            local old = emote_mod.OnMileStoneDataRsp
            emote_mod.__fs_mile_rsp = old
            emote_mod.OnMileStoneDataRsp = function(_, data, ...)
                old(_, data, ...)
                _.AcquiredMileList = build_milestone_list(_.AcquiredMileList or {})
                _.bHaveReceivedMileData = true
            end
        end
    end
end
pcall(hook_lobby_emote_manager)

function hook_collect_pavilions()
    local pav_mod = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.collect_pavilions_module)
    if pav_mod and pav_mod.SetShowMilestoneSlot and not pav_mod.__fs_show_slot then
        local old = pav_mod.SetShowMilestoneSlot
        pav_mod.__fs_show_slot = old
        pav_mod.SetShowMilestoneSlot = function(_, slot_id, milestone_id)
            local mid = tonumber(milestone_id)
            local sid = tonumber(slot_id)
            if sid and sid > 0 and mid and CDataTable.GetTableData("MilestoneConfig", mid) then
                pav_mod.OnSetShowMilestoneSlot(_, mid, sid)
                return
            end
            return old(_, slot_id, milestone_id)
        end
    end
end
pcall(hook_collect_pavilions)

function hook_social_main_page_milestone()
    local handler = require("client.network.Protocol.SocialAndCollection_LobbyHandler")
    if handler.send_set_social_main_page_milestone_req and not handler.__fs_main_mile then
        local old = handler.send_set_social_main_page_milestone_req
        handler.__fs_main_mile = old
        handler.send_set_social_main_page_milestone_req = function(milestone_id)
            local mid = tonumber(milestone_id)
            if mid and CDataTable.GetTableData("MilestoneConfig", mid) then
                handler.on_set_social_main_page_milestone_rsp(0, mid)
                return
            end
            return old(mid)
        end
    end
end
pcall(hook_social_main_page_milestone)

function hook_milestone_show_delayed()
    local ticker = require("common.time_ticker")
    local function apply_milestone_hook()
        pcall(function()
            local collect_handler = RequireModDownload("GameLua.Mod.Lobby.Split.Collect.ModCollectHandler")
            if collect_handler and collect_handler.send_set_show_milestone_data_req and not collect_handler.__fs_show_mile then
                local old = collect_handler.send_set_show_milestone_data_req
                collect_handler.__fs_show_mile = old
                collect_handler.send_set_show_milestone_data_req = function(slot_id, milestone_id)
                    local sid = tonumber(slot_id)
                    local mid = tonumber(milestone_id)
                    local pav_mod = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.collect_pavilions_module)
                    if pav_mod and mid and mid > 0 and sid and CDataTable.GetTableData("MilestoneConfig", mid) then
                        pav_mod.OnSetShowMilestoneSlot(pav_mod, mid, sid)
                        return
                    end
                    return old(slot_id, milestone_id)
                end
            end
        end)
    end
    ticker.AddTimerOnce(2, apply_milestone_hook)
    ticker.AddTimerOnce(8, apply_milestone_hook)
end
pcall(hook_milestone_show_delayed)

function hook_carte_frame_logic()
    local carte_mod = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_roleinfo_carte_frame)
    if carte_mod and carte_mod.get_carte_frame_list_rsp and not carte_mod.__fs_rsp then
        local old = carte_mod.get_carte_frame_list_rsp
        carte_mod.__fs_rsp = old
        carte_mod.get_carte_frame_list_rsp = function(_, ret, list, cur_id)
            if ret == 0 then
                carte_mod.InitCarteFrameMap(carte_mod)
                if not list then list = {} end
                for id in pairs(carte_mod.CarteFrameMap or {}) do
                    list[id] = { expire_ts = 0 }
                end
            end
            return old(_, ret, list, cur_id)
        end
    end
    if carte_mod and carte_mod.IsHaveCarteFrame then
        local old_has = carte_mod.IsHaveCarteFrame
        carte_mod.IsHaveCarteFrame = function(_, frame_id)
            if CDataTable.GetTableData("CarteFrameConfig", tonumber(frame_id)) then
                return true
            end
            return old_has(_, frame_id)
        end
    end
    if carte_mod and carte_mod.equip_carte_frame_req and not carte_mod.__fs_equip then
        local old = carte_mod.equip_carte_frame_req
        carte_mod.__fs_equip = old
        carte_mod.equip_carte_frame_req = function(_, frame_id, ...)
            carte_mod.InitCarteFrameMap(carte_mod)
            local fid = tonumber(frame_id)
            if fid and carte_mod.CarteFrameMap and carte_mod.CarteFrameMap[fid] then
                carte_mod.CarteFrameMap[fid].bLock = false
                carte_mod.CarteFrameMap[fid].expire_ts = 0
            end
            return old(_, fid, ...)
        end
    end
end
pcall(hook_carte_frame_logic)

function hook_avatar_list_rsp()
    local avatar_mod = require("client.slua.logic.roleInfo.logic_roleInfo_Avatar")
    local old_list_rsp = avatar_mod.get_user_avatar_list_rsp
    avatar_mod.get_user_avatar_list_rsp = function(_, ret, list, cur_id)
        if ret == 0 then
            if not list then list = {} end
            local tab = CDataTable.GetTable("Headportrait") or {}
            for id in pairs(tab) do
                list[tostring(id)] = 1
            end
        end
        return old_list_rsp(_, ret, list, cur_id)
    end
end
pcall(hook_avatar_list_rsp)

function final_initialization()
    local ticker = require("common.time_ticker")
    ticker.AddTimerOnce(1, function()
        pcall(function() init_all_misc() end)
    end)
    ticker.AddTimerOnce(4, function()
        pcall(function() init_all_misc() end)
    end)
end
pcall(final_initialization)

function hook_chatroom_bg_handler()
    local handler = require("client.network.Protocol.ChatRoomBGHandler")
    if handler.send_set_chat_background_req and not handler.__fs_set then
        local old = handler.send_set_chat_background_req
        handler.__fs_set = old
        handler.send_set_chat_background_req = function(bg_id)
            if CDataTable.GetTableData("ChatRoomBgConfig", tonumber(bg_id)) then
                handler.on_set_chat_background_rsp(0, tonumber(bg_id))
                return
            end
            return old(bg_id)
        end
    end
    if handler.send_get_chat_background_req and not handler.__fs_get then
        local old = handler.send_get_chat_background_req
        handler.__fs_get = old
        handler.send_get_chat_background_req = function()
            local list = fill_table_with_ids({}, "ChatRoomBgConfig", "ID")
            handler.on_get_chat_background_rsp(0, list, 0)
        end
    end
end
pcall(hook_chatroom_bg_handler)

local in_battle = false
pcall(function()
    if GameStatus and GameStatus.IsInFightingStatus then
        in_battle = GameStatus.IsInFightingStatus()
    end
end)

if not in_battle then
    pcall(init_skin_collection)
    pcall(function()
        if DataMgr and DataMgr.roleData then
            local cur = tonumber(DataMgr.roleData.cur_avatar_box_id)
            if cur and cur > 0 then
                _G._FULLSKIN_LOCAL_AVATAR_BOX_ID = cur
            end
        end
    end)
    pcall(function()
        local ticker = require("common.time_ticker")
        ticker.AddTimerOnce(0.2, function()
            pcall(get_all_skin_items)
        end)
        ticker.AddTimerOnce(1.5, function()
            pcall(function() hook_basic_data_avatar() end)
            pcall(function() init_armory_data() end)
            pcall(function() refresh_weapon_skin_count() end)
            pcall(function() logic_gun.OnGunSkinListRes(logic_gun) end)
            pcall(function() logic_gun.InitGunCountData(logic_gun) end)
            pcall(function() if hook_collect_module then hook_collect_module() end end)
            pcall(function() init_collect_data() end)
            pcall(function() trigger_collect_update() end)
            pcall(function() if _G._FULLSKIN_ensureAllAvatarFrames then _G._FULLSKIN_ensureAllAvatarFrames() end end)
        end)
    end)
end

pcall(function() init_skin_collection() end)
pcall(function() init_armory_data() end)
pcall(function() refresh_weapon_skin_count() end)
pcall(function() logic_gun.OnGunSkinListRes(logic_gun) end)
pcall(function() logic_gun.InitGunCountData(logic_gun) end)
pcall(function() if hook_collect_module then hook_collect_module() end end)
pcall(function() init_collect_data() end)
pcall(function() trigger_collect_update() end)
pcall(function() if _G._FULLSKIN_ensureAllAvatarFrames then _G._FULLSKIN_ensureAllAvatarFrames() end end)

local loadout = get_current_loadout()
if not loadout and not in_battle then
    pcall(function()
        local ticker = require("common.time_ticker")
        ticker.AddTimerOnce(5, function()
            if hook_on_snapshot then
                build_loadout_snapshot(true)
            end
        end)
    end)
end

pcall(function()
    if GameStatus and GameStatus.IsInFightingStatus and GameStatus.IsInFightingStatus() then
        local loadout = get_current_loadout()
        if loadout then
            rebuildWeaponSkinMap(true)
            start_battle_skin_loop("boot")
            start_apply_loop()
        end
    end
end)

function inject_gold_suit_into_member(member)
    if not member then return end
    local gold_data = get_gold_suit_data()
    member.gold_dress_set_info = gold_data
end

function apply_weapon_skin_to_current_weapon(controller)
    local pawn = controller and controller.GetPlayerCharacterSafety and controller:GetPlayerCharacterSafety()
    if not pawn then return end
    local cur_weapon_id = pawn.GetCurrentWeaponID and pawn:GetCurrentWeaponID()
    if cur_weapon_id and cur_weapon_id > 0 then
        local skin = get_mapped_weapon_skin(cur_weapon_id)
        if skin then
            apply_weapon_skin(cur_weapon_id, skin)
        end
    end
end

local function error_handler(msg)
    pcall(function()
        if require("common.loc_util").ShowNotice then
            require("common.loc_util").ShowNotice("错误: " .. tostring(msg))
        end
    end)
    pcall(function()
        local tips = require("GameLua.Mod.BaseMod.Common.UI.InGameTipsTools")
        if tips and tips.BattleNormalTips then
            tips.BattleNormalTips("错误: " .. tostring(msg), 2, 3)
        end
    end)
end

ABC = error_handler
ABC("加载皮肤工具3")
return true
end)()