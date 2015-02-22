local Salvager = LibStub("AceAddon-3.0"):NewAddon("Salvager", "AceConsole-3.0", "AceEvent-3.0");
Salvager.recording = false;
Salvager.loot = {};
Salvager.ignored_loot = {};

function Salvager:CHAT_MSG_LOOT(event, msg)
    itemLink = parseLootMessage(msg);
    if tContains(Salvager.loot, itemLink) == nil and tContains(Salvager.ignored_loot, itemLink) == nil then 
        table.insert(Salvager.loot, itemLink)
    end
    SalvagerScrollBar_Update()
end

function parseLootMessage (msg)
    -- http://wowprogramming.com/snippets/Print_item_links_posted_in_chat_channels_to_chatframe_6
    for itemLink in msg:gmatch("|%x+|Hitem:.-|h.-|h|r") do
         return itemLink
    end
end

function print_table(t)
    print ("printing table")
    for p,v in pairs(t) do
        print(p .. ": " .. v)
    end
end

Salvager:RegisterChatCommand("ll", "SlashCommand")
Salvager:RegisterChatCommand("salvager", "SlashCommand")
function Salvager:SlashCommand(msg, editbox)
    show_lootlist()
end


function clear_loot()
    wipe(Salvager.loot)
    SalvagerScrollBar_Update()
end

function show_lootlist()
    SalvagerScrollBar_Update()
    SalvagerFrame:Show()
end

function hide_lootlist()
    SalvagerFrame:Hide()
end

function remove_from_list(itemLink)
    for k,v in pairs(Salvager.loot) do
        if v == itemLink then
            tremove(Salvager.loot, k)
            break
        end
    end
    SalvagerScrollBar_Update();
end

function SalvagerScrollBar_Update()
--   print("sbupdate")
   local line; -- 1 through 5 of our window to scroll
   local lineplusoffset; -- an index into our data calculated from the scroll offset
   FauxScrollFrame_Update(SalvagerScrollBar,#(Salvager.loot),5,16);
   for line=1,5 do
     lineplusoffset = line + FauxScrollFrame_GetOffset(SalvagerScrollBar);
     if Salvager.loot[lineplusoffset] ~= nil then
       getglobal("SalvagerEntry"..line).text:SetText(Salvager.loot[lineplusoffset]);
       getglobal("SalvagerEntry"..line).info:SetText(SalvagerGetItemInfoString(Salvager.loot[lineplusoffset]));
       getglobal("SalvagerEntry"..line):Show();
     else
       getglobal("SalvagerEntry"..line):Hide();
     end
   end
end

function SalvagerGetItemInfoString(itemLink)
    -- itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(itemLink)
    _, _, _, itemLevel, itemMinLevel = GetItemInfo(itemLink)
    count = GetItemCount(itemLink);
    return "Lvl: " .. itemMinLevel .. ",  iLvl: " .. itemLevel .. ",  Qty: " .. count
end

function SalvagerFindItem(itemLink)
    if GetItemCount(itemLink) == 0 then
        return nil, nil
    end
    for bag = 0,4,1 do 
        for slot = 1, GetContainerNumSlots(bag), 1 do
            if SalvagerItemEquals(GetContainerItemLink(bag,slot), itemLink, (slot == 1 and bag == 0)) then
                return bag, slot
            end
        end
    end
end

function SalvagerSellItem(itemLink)
    if GetItemCount(itemLink) > 0 then
        for bag = 0,4,1 do 
            for slot = 1, GetContainerNumSlots(bag), 1 do
                if SalvagerItemEquals(GetContainerItemLink(bag,slot), itemLink, (slot == 1 and bag == 0)) then
                    UseContainerItem(bag,slot);
                end
            end
        end
    end
    remove_from_list(itemLink)
end

function SalvagerDestroyItem(itemLink)
    if true then return end
    if GetItemCount(itemLink) > 0 then
        for bag = 0,4,1 do 
            for slot = 1, GetContainerNumSlots(bag), 1 do
                if GetContainerItemLink(bag,slot) == itemLink then
                    ClearCursor();
                    PickupContainerItem(bag, slot);
                    DeleteCursorItem();
                end
            end
        end
    end
    remove_from_list(itemLink)
end

function SalvagerIgnoreItem(itemLink)
    if tContains(Salvager.ignored_loot, itemLink) == nil then 
        table.insert(Salvager.ignored_loot, itemLink)
    end

    remove_from_list(itemLink)
end


function SalvagerHandleItem(itemLink, action)
    if action == "remove" then
        remove_from_list(itemLink);
    elseif action == "sell" then 
        SalvagerSellItem(itemLink);
    elseif action == "destroy" then
        SalvagerDestroyItem(itemLink);
    elseif action == "ignore" then
        SalvagerIgnoreItem(itemLink);
    else
        print(itemLink)
    end
end

function SalvagerToggleSellButton(self, event, ...)
    if     event == "MERCHANT_SHOW" then self:Enable()
    elseif event == "MERCHANT_CLOSED" then self:Disable()
    end
end

function SalvagerToggleRecord()
    if Salvager.recording then
        SalvagerFrameButtonToggle:SetText("Enable")
        Salvager:UnregisterEvent("CHAT_MSG_LOOT")
        Salvager.recording = false
    else
        SalvagerFrameButtonToggle:SetText("Disable")
        Salvager:RegisterEvent("CHAT_MSG_LOOT")
        Salvager.recording = true
    end
end

function SalvagerItemEquals(item1, item2, debug)
    if item1 == nil or item2 == nil then return false end
    itemName1, itemLink1, itemRarity1, itemLevel1, itemMinLevel1, itemType1, itemSubType1, itemStackCount1, itemEquipLoc1, itemTexture1, itemSellPrice1 = GetItemInfo(item1)
    itemName2, itemLink2, itemRarity2, itemLevel2, itemMinLevel2, itemType2, itemSubType2, itemStackCount2, itemEquipLoc2, itemTexture2, itemSellPrice2 = GetItemInfo(item2)
    return (
        itemName1 == itemName2 and
        itemRarity1 == itemRarity2 and
        itemLevel1 == itemLevel2 and
        itemMinLevel1 == itemMinLevel2 and
        itemType1 == itemType2 and
        itemSubType1 == itemSubType2 and
        itemStackCount1 == itemStackCount2 and
        itemEquipLoc1 == itemEquipLoc2
    )
end

function SalvagerInitSpellButton(button, profession)

end

local salvager_spell_disenchant = GetSpellInfo(13262)
local salvager_macro_disenchant = "/cast %s;\n/use %d %d"
function SalvagerSetMacro(button, macro, item)
    macrotext = ""
    if macro == "disenchant" then
        bag, slot = SalvagerFindItem(item)
        macrotext = format(salvager_macro_disenchant, salvager_spell_disenchant, bag, slot)
    end
    button:SetAttribute("macrotext", macrotext)
end