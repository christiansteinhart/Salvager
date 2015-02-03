local loot = {}
local enabled = false

function HelloWorld() 
  print("Hello, World!"); 
end

function TestAddonEventHandler(self, event, ...)
    msg = ...

    -- print(event);
    if event == "CHAT_MSG_LOOT" then
        itemLink = parseLootMessage(msg);
        if tContains(loot, itemLink) == nil then 
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
function SlashCmdList.TESTADDON(msg, editbox)
    print("/lootlist " .. msg)
    if msg == "clear" then
        clear_loot()
    elseif msg == "list" then
        print_table(loot)
    elseif msg == "show" then
        show_lootlist()
    elseif msg == "hide" then
        hide_lootlist()
    else
        print("Usage: /lootlist clear|list")
    end
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

function TestAddonScrollBar_Update()
--   print("sbupdate")
   local line; -- 1 through 5 of our window to scroll
   local lineplusoffset; -- an index into our data calculated from the scroll offset
   FauxScrollFrame_Update(TestAddonScrollBar,#(loot),5,16);
   for line=1,5 do
     lineplusoffset = line + FauxScrollFrame_GetOffset(TestAddonScrollBar);
     if loot[lineplusoffset] ~= nil then
       getglobal("TestAddonEntry"..line).text:SetText(loot[lineplusoffset]);
       getglobal("TestAddonEntry"..line):Show();
     else
       getglobal("TestAddonEntry"..line):Hide();
     end
   end
end

function TestAddonSell(itemLink)
    print(itemLink)
end