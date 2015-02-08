local loot, ignored_loot = {}, {}
local enabled = false

function HelloWorld() 
  print("Hello, World!"); 
end

function TestAddonEventHandler(self, event, ...)
    msg = ...

    -- print(event);
    if event == "CHAT_MSG_LOOT" then
        itemLink = parseLootMessage(msg);
        if tContains(loot, itemLink) == nil and tContains(ignored_loot, itemLink) == nil then 
            table.insert(loot, itemLink)
        end
    end
    TestAddonScrollBar_Update()
    -- print(#(loot))
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

SLASH_TESTADDON1 = '/lootlist'
SLASH_TESTADDON2 = '/ll'
function SlashCmdList.TESTADDON(msg, editbox)
    show_lootlist()
end


function clear_loot()
    wipe(loot)
    TestAddonScrollBar_Update()
end

function show_lootlist()
    TestAddonScrollBar_Update()
    TestAddonFrame:Show()
end

function hide_lootlist()
    TestAddonFrame:Hide()
end

function remove_from_list(itemLink)
    for k,v in pairs(loot) do
        if v == itemLink then
            tremove(loot, k)
            break
        end
    end
    TestAddonScrollBar_Update();
end

function TestAddonScrollBar_Update()
--   print("sbupdate")
   local line; -- 1 through 5 of our window to scroll
   local lineplusoffset; -- an index into our data calculated from the scroll offset
   FauxScrollFrame_Update(TestAddonScrollBar,#(loot),5,16);
   for line=1,5 do
     lineplusoffset = line + FauxScrollFrame_GetOffset(TestAddonScrollBar);
     if loot[lineplusoffset] ~= nil then
       getglobal("TestAddonEntry"..line).text:SetText(loot[lineplusoffset]);
       getglobal("TestAddonEntry"..line).info:SetText(TestAddonGetItemInfoString(loot[lineplusoffset]));
       getglobal("TestAddonEntry"..line):Show();
     else
       getglobal("TestAddonEntry"..line):Hide();
     end
   end
end

function TestAddonGetItemInfoString(itemLink)
    -- itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(itemLink)
    _, _, _, itemLevel, itemMinLevel = GetItemInfo(itemLink)
    count = GetItemCount(itemLink);
    return "Lvl: " .. itemMinLevel .. ",  iLvl: " .. itemLevel .. ",  Qty: " .. count
end

function TestAddonSellItem(itemLink)
    if GetItemCount(itemLink) > 0 then
        for bag = 0,4,1 do 
            for slot = 1, GetContainerNumSlots(bag), 1 do
                if TestAddonItemEquals(GetContainerItemLink(bag,slot), itemLink, (slot == 1 and bag == 0)) then
                    UseContainerItem(bag,slot);
                end
            end
        end
    end
    remove_from_list(itemLink)
end

function TestAddonDestroyItem(itemLink)
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

function TestAddonIgnoreItem(itemLink)
    if tContains(ignored_loot, itemLink) == nil then 
        table.insert(ignored_loot, itemLink)
    end

    remove_from_list(itemLink)
end


function TestAddonHandleItem(itemLink, action)
    if action == "remove" then
        remove_from_list(itemLink);
    elseif action == "sell" then 
        TestAddonSellItem(itemLink);
    elseif action == "destroy" then
        TestAddonDestroyItem(itemLink);
    elseif action == "ignore" then
        TestAddonIgnoreItem(itemLink);
    else
        print(itemLink)
    end
end

function TestAddonToggleSellButton(self, event, ...)
    if     event == "MERCHANT_SHOW" then self:Enable()
    elseif event == "MERCHANT_CLOSED" then self:Disable()
    end
end

function TestAddonToggleRecord()
    if enabled then
        TestAddonFrameButtonToggle:SetText("Enable")
        TestAddonFrame:UnregisterEvent("CHAT_MSG_LOOT")
        enabled = false
    else
        TestAddonFrameButtonToggle:SetText("Disable")
        TestAddonFrame:RegisterEvent("CHAT_MSG_LOOT")
        enabled = true
    end
end

function TestAddonItemEquals(item1, item2, debug)
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