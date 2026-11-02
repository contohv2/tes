local BattleKillBroadcastSubSystem = require("GameLua.Mod.BaseMod.Client.BattleKillBroadcast.BattleKillBroadcastSubSystem")

if BattleKillBroadcastSubSystem then
    local O_CopyKillOrPutDownMessageDataUserDataToLuaTable =
        BattleKillBroadcastSubSystem.CopyKillOrPutDownMessageDataUserDataToLuaTable

    BattleKillBroadcastSubSystem.CopyKillOrPutDownMessageDataUserDataToLuaTable = function(self, messageData)
        local msgData = O_CopyKillOrPutDownMessageDataUserDataToLuaTable(self, messageData)

        if msgData and msgData.bIamCauser then
            local playerController = nil

            if slua_GameFrontendHUD and slua_GameFrontendHUD.GetPlayerController then
                playerController = slua_GameFrontendHUD:GetPlayerController()
            end

            local uCharacter = nil

            if playerController and playerController.GetPlayerCharacterSafety then
                uCharacter = playerController:GetPlayerCharacterSafety()
            end

            if uCharacter and slua.isValid(uCharacter) then
                if msgData.DamageType == UEnums.DamageType.VehicleDamage then
                    local carSkinID = _G.CurrentEquipVehicleID

                    if carSkinID and carSkinID ~= 0 then
                        local ExpandData =
                            slua.LuaArchiverDecode(LuaStateWrapper, msgData.ExpandDataContent) or {}

                        ExpandData.CauserVehicleSkinID = carSkinID
                        ExpandData.CauserWeaponAvatarID = carSkinID

                        msgData.ExpandDataContent =
                            slua.LuaArchiverEncode(LuaStateWrapper, ExpandData)
                    end
                else
                    local currWeapon = nil

                    if uCharacter.GetCurrentWeapon then
                        currWeapon = uCharacter:GetCurrentWeapon()
                    end

                    if currWeapon and slua.isValid(currWeapon) then
                        local synData = currWeapon.synData

                        if synData and slua.isValid(synData) and synData.Get then
                            local synValue = synData:Get(7)

                            if synValue then
                                local weaponDefineID =
                                    slua.IndexReference(synValue, "defineID")

                                if weaponDefineID and slua.isValid(weaponDefineID) then
                                    local ExpandData =
                                        slua.LuaArchiverDecode(
                                            LuaStateWrapper,
                                            msgData.ExpandDataContent
                                        ) or {}

                                    ExpandData.CauserWeaponAvatarID =
                                        weaponDefineID.TypeSpecificID

                                    msgData.ExpandDataContent =
                                        slua.LuaArchiverEncode(
                                            LuaStateWrapper,
                                            ExpandData
                                        )
                                end
                            end
                        end
                    end
                end
            end
        end

        return msgData
    end
end