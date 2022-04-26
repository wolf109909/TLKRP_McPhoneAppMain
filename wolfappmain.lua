-- ╔═╗╔═╦═══╗╔═══╦╗────────────--
-- ║║╚╝║║╔═╗║║╔═╗║║────────────--
-- ║╔╗╔╗║║─╚╝║╚═╝║╚═╦══╦═╗╔══╗ --
-- ║║║║║║║─╔╗║╔══╣╔╗║╔╗║╔╗╣║═╣ --
-- ║║║║║║╚═╝║║║──║║║║╚╝║║║║║═╣ --
-- ╚╝╚╝╚╩═══╝╚╝──╚╝╚╩══╩╝╚╩══╝ --
-- ───── By Mactavish ─────────--
-- ────────────────────────────--
-- Phone app made for TLK RP server
-- some code is from original stormfox2 module.


if SERVER then
    
    util.AddNetworkString("wolfapp.CallRandomCpStart")
	util.AddNetworkString("wolfapp.CallRandomCpFailed")
    util.AddNetworkString("wolfapp.CallRandomCpGetGPS")

    print("Realm: SERVER")
    local function GetOnlineCP()
    
       local onlinecp = {}
       for index,player in pairs(player.GetHumans()) do
            if player:isCP() then 
                onlinecp[#onlinecp+1] = player
            end
       end
       return onlinecp      
    end    
    
    
    
        

    net.Receive("wolfapp.CallRandomCpStart",function(l,player)
        local c_type, payphone = {0,0}, false
    		
        local wolfapp_CallRandomCpFailed_sv = false   
        local onlinecp = GetOnlineCP()
        for index,cp in pairs(onlinecp) do
            if cp == player then
            
                table.remove(onlinecp,index)
                    
            end
        end
        if #onlinecp == 0 then
            wolfapp_CallRandomCpFailed_sv = true
            
        end
        local randomcp = onlinecp[ math.random( #onlinecp ) ]
        print("Online CP:".. #onlinecp)
        --net.Start("Sv_SendRandomOnlineCPData",false)
        --net.WriteEntity(randomcp)
        --net.Send(player)
        if wolfapp_CallRandomCpFailed_sv then 
            timer.Simple(2, function()    
                print("Timer CALLED!")
                net.Start("wolfapp.CallRandomCpFailed")
                net.Send(player)
            end)
            return
        end
        receiver = randomcp
        caller = player    
        receiver.McPhoneInCall = player
        caller.McPhoneCalling = randomcp
        if caller.McPayPhone then
            c_type, payphone = {1,2}, true
    	end
        print(player:AccountID().."is Attempting to call: "..randomcp:AccountID())
        timer.Simple(2, function()

            net.Start("McPhone.CallStart")
            net.WriteString("Connecting")
            net.WriteEntity(receiver)
            net.WriteInt(c_type[1], 16)
            net.Send(caller)

            net.Start("McPhone.CallStart")
            net.WriteString("Incoming")
            net.WriteEntity(caller)
            net.WriteInt(c_type[2], 16)
            net.Send(receiver)

            net.Start("wolfapp.CallRandomCpGetGPS")
            net.WriteEntity(caller)
            net.Send(receiver)
        end)
        
    
        
    end)
end

if SERVER then return end

function wolfapp_StopGPSThread()
    hook.Remove( "Think", "wolfapp_GPSThread" )
end



function wolfapp_StartGPSThread()
    hook.Add( "Think", "wolfapp_GPSThread",wolfapp_GPSThread)
end



function wolfapp_GPSThread()
    --print("GPS thread called!")
    if not wolfapp_ShouldDisplayGPS then return end
    local distance = LocalPlayer():GetPos():Distance(wolfapp_CurrentTrackingPlayer:GetPos())
    wolfapp_DrawGPS(wolfapp_CurrentTrackingPlayer)
    LocalPlayer():ConCommand( "say /ooc distance:"..distance )
    if distance < 500 then
        LocalPlayer():ConCommand( "say /ooc GPSclear!" )
        clearGPS()
        
    end
end

function clearGPS()
    if wolfapp_isGPSToggledOn then 
        McPhone.ToggleGPS() 
    end
    print("GPS cleared!")
    wolfapp_StopGPSThread()
    wolfapp_isGPSToggledOn = false
    
    
end

function wolfapp_DrawGPS(entity)
    if not wolfapp_ShouldDisplayGPS then print("GPS NOT READY") return end
    if not IsValid(entity) then print("NULL ENTITY") return end

    if wolfapp_isGPSToggledOn and IsValid(entity) then
        McPhone.ToggleGPS()
        McPhone.ToggleGPS(entity:Nick(),entity:GetPos())
    end
    
    if not wolfapp_isGPSToggledOn then
        McPhone.ToggleGPS(entity:Nick(), entity:GetPos())
        wolfapp_isGPSToggledOn = true
    end
    
end

local function startCall()
    if SERVER then return end
    
    net.Start("wolfapp.CallRandomCpStart")
    net.SendToServer()    
end  

local function drawFailure()
    if SERVER then return end
    if wolfapp_CallRandomCpFailed then
        CallRandomCpStartText = "呼叫失败:找不到在线警察"
        CallRandomCpStartColor = zrush.default_colors["red01"]
    end

end

net.Receive("wolfapp.CallRandomCpGetGPS",function(l)
    caller = net.ReadEntity()
    if IsValid(caller) then
        print("Got GPS info from SERVER!")
        wolfapp_ShouldDisplayGPS = true
        McPhone.ToggleGPS(caller:Nick(),caller:GetPos())
        wolfapp_CurrentTrackingPlayer = caller
        wolfapp_StartGPSThread()
    end
end)

net.Receive("wolfapp.CallRandomCpFailed",function(l)
    print("Failed to find CP!")
    wolfapp_CallRandomCpFailed = true
    McPhone.StopSound()
    drawFailure()
end)


function wolfapp_Test()
    if SERVER then return end
    

    McPhone.UI.Menu:Clear(true)
    McPhone.UI.Menu.ConvertToList()
    local bg = Color(26, 41, 72, 255)
    local rc = Color(55, 55, 255, 55)
    local ca = Color(255, 255, 255, 8)
    local frame = vgui.Create("DPanel")

    frame:SetSize(256, 256)
    frame:SetDisabled(true)
    frame:SetAlpha(255)
    
   	PrintTable(McPhone.Config.GPSList[game.GetMap()])
    
    frame.Paint = function(self, w, h)
        McPhone.UI.OpenedMenu = "测试"
        surface.SetDrawColor(bg)
    	surface.DrawRect(0, 0, w, h)    
    	
          
        
        draw.DrawText("Hello World!", "zrush_npc_font03", 128, 128, zrush.default_colors["white01"], TEXT_ALIGN_CENTER)
        
        
        
        
        
    end
    McPhone.UI.Menu:AddItem(frame)
    
    
        
        
end
 
function wolfapp_Emergency()
    if SERVER then return end
    clearGPS()
    wolfapp_isGPSToggledOn = false
    wolfapp_CallRandomCpFailed = false
    timer.Simple(1,drawFailure)
    McPhone.PlaySound("mc_phone/tone.wav")
    startCall()
    
    
    CallRandomCpStartText = "正在呼叫在线警察..."
    CallRandomCpStartColor = zrush.default_colors["white01"]
    McPhone.UI.Menu:Clear(true)
    local bg = Color(26, 41, 72, 255)
    local rc = Color(55, 55, 255, 55)
    local ca = Color(255, 255, 255, 8)
       
    		
    McPhone.UI.Menu.ConvertToList()
    local frame = vgui.Create("DPanel")
    frame:SetSize(256, 256)
    frame:SetDisabled(true)
    frame:SetAlpha(255)
   
   	
    frame.Paint = function(self, w, h)
        McPhone.UI.OpenedMenu = "紧急呼叫"
        surface.SetDrawColor(bg)
    	surface.DrawRect(0, 0, w, h)    
    	
          
        
        draw.DrawText(CallRandomCpStartText, "zrush_npc_font03", 128, 20, CallRandomCpStartColor, TEXT_ALIGN_CENTER)
        
        
        
        
        
    end
    McPhone.UI.Menu:AddItem(frame)
    
    
        
        
end


    if SERVER then return end
    
    local module_id = 12
    
    McPhone.Modules[module_id] = {}
    McPhone.Modules[module_id].name = "WOLF便民服务"
    McPhone.Modules[module_id].icon = "mc_phone/icons/main_menu/web.png"
    McPhone.Modules[module_id].number = 0
    local bg = Color(26, 41, 72, 255)
    local rc = Color(55, 55, 255, 55)
    local ca = Color(255, 255, 255, 8)
    
    local function GetOilRushPriceMul()
          local OilrushPriceMul
        for index, fuelbuyer in pairs(ents.FindByClass("zrush_fuelbuyer_npc")) do 
            OilrushPriceMul = fuelbuyer:GetPrice_Mul()
        end
        if OilrushPriceMul == nil then
            return 0
        end 
        return OilrushPriceMul
    end
    
    local function DrawResourceItem(fuelData, xpos, ypos, size)
       local offsetX = 10
       local offsetY = 10
        local price = math.Round(fuelData.price * (GetOilRushPriceMul() / 100))
        
        surface.SetDrawColor(fuelData.color)
        surface.SetMaterial(zrush.default_materials["barrel_icon"])
        surface.DrawTexturedRect(xpos + offsetX, ypos + offsetY, size, size)
    
        draw.DrawText(zrush.config.Currency .. price, "zrush_npc_font03", xpos + offsetX + 25, ypos + offsetY + size * 0.1, zrush.default_colors["white01"], TEXT_ALIGN_LEFT)
    end
    local function DrawMiningResourceItem(Info, color, xpos, ypos, size)
       local offsetX = 130
       local offsetY = 81
        surface.SetDrawColor(color)
        surface.SetMaterial(zrmine.default_materials["MetalBar"])
        surface.DrawTexturedRect(xpos + offsetX, ypos + offsetY, size*0.5, size*0.5)
        draw.NoTexture()
        draw.DrawText(Info, "zrush_npc_font03", xpos + offsetX + 30, ypos + offsetY + size * 0.1, zrmine.default_colors["white02"], TEXT_ALIGN_LEFT)
    end
    local function GetMiningBuyRate()
           local BuyRate
        for index, buyer in pairs(ents.FindByClass("zrms_buyer")) do 
            BuyRate = buyer:GetBuyRate()
        end
        
        if BuyRate == nil then
            return 0
        end 
    
        return BuyRate
    end
    local function DrawDetailMiningInfo()
        local aIron = ": " .. zrmine.config.Currency .. math.Round(zrmine.config.BarValue["Iron"] * (GetMiningBuyRate() / 100))
        local aBronze = ": " .. zrmine.config.Currency .. math.Round(zrmine.config.BarValue["Bronze"] * (GetMiningBuyRate() / 100))
        local aSilver = ": " .. zrmine.config.Currency .. math.Round(zrmine.config.BarValue["Silver"] * (GetMiningBuyRate() / 100))
        local aGold = ": " .. zrmine.config.Currency .. math.Round(zrmine.config.BarValue["Gold"] * (GetMiningBuyRate() / 100))
    
        DrawMiningResourceItem(aIron, zrmine.default_colors["Iron"], -55, -50, 60)
        DrawMiningResourceItem(aBronze, zrmine.default_colors["Bronze"], -55, -25, 60)
        DrawMiningResourceItem(aSilver, zrmine.default_colors["Silver"], -55, 0, 60)
        DrawMiningResourceItem(aGold, zrmine.default_colors["Gold"], -55, 25, 60)
    end
    
    --Main menu section, add your menu here!
    function wolfapp_Menu()
        clearGPS()
    	McPhone.StopSound()
    	McPhone.UI.GoBack = wolfAppBackFunc
        McPhone.UI.Menu.ConvertToList()
        McPhone.UI.Buttons.Right = {
            "mc_phone/icons/buttons/id1.png", McPhone.MainColors["red"], function()
                wolfapp_page = 1
            end
        }
    
       McPhone.UI.Menu:Clear(true)
       McPhone.UI.OpenedMenu = "WOLF便民服务"
        McPhone.ListIcons(McPhone.UI.Menu, "mc_phone/icons/settings/id_5.png", "信息中心", false, function() 
                wolfapp_Home()
                McPhone.UI.GoBack = wolfapp_Menu
            end)
       McPhone.ListIcons(McPhone.UI.Menu, "mc_phone/icons/settings/id_1.png", "紧急呼叫", false, function() 
                wolfapp_Emergency()
                McPhone.UI.GoBack = wolfapp_Menu
                
            end)
        McPhone.ListIcons(McPhone.UI.Menu, "mc_phone/icons/settings/id_3.png", "测试", false, function() 
            wolfapp_Test()
            McPhone.UI.GoBack = wolfapp_Menu
            
        end)

    end
    
    function wolfapp_Home()  
        clearGPS()
        McPhone.StopSound()
        McPhone.UI.Menu:Clear(true)
        McPhone.UI.Buttons.Left = {
            "mc_phone/icons/buttons/id1.png", McPhone.MainColors["green"], function()
                wolfapp_page = 0
            end
        }
        
            SF2_CurrentForecast = StormFox2.WeatherGen.GetForecast()
            --local NWVarTable = BuildNetworkedVarsTable()
            PrintTable(ents.FindByClass("zrms_buyer"))
            local forecastJson = StormFox2.WeatherGen.GetForecast()
            local fuelpricetable = zrush.Fuel
            McPhone.UI.Menu.ConvertToList()
            local frame = vgui.Create("DPanel")
            frame:SetSize(256, 256)
            frame:SetDisabled(true)
            frame:SetAlpha(255)
                
            frame.Paint = function(self, w, h)
                McPhone.UI.OpenedMenu = "信息中心"
                local y = 0
                surface.SetDrawColor(bg)
                surface.DrawRect(0, 0, w, h)
                local unix = forecastJson.unix_stamp
    
              
                
                -- Fuel price
                table.sort(fuelpricetable, function(a, b) return a.price > b.price end)
                draw.DrawText("油", "zrush_npc_font03", 20, 10, zrush.default_colors["white01"], TEXT_ALIGN_LEFT)
                draw.DrawText("金属", "zrush_npc_font03", 90, 10, zrush.default_colors["white01"], TEXT_ALIGN_LEFT)
                if fuelpricetable then
                    for k, v in pairs(fuelpricetable) do
                        DrawResourceItem(v, 0, 25 * k, 20)
                    end
                end
    
                local ws = math.ceil((w - 20) / 5)
                ws = math.max(ws, 40)
                surface.SetDrawColor(color_white)      
                local temp = math.Round(StormFox2.Temperature.GetDisplay() ,1) .. StormFox2.Temperature.GetDisplaySymbol()
                    
                local x = 10
                surface.SetMaterial(StormFox2.Weather.GetIcon())
                surface.DrawTexturedRect(x + ws * 4 , y + 22, ws * 0.7, ws * 0.7, 0)
                draw.DrawText(StormFox2.Weather.GetDescription(), "McPhone.Main16", x + ws * 4.3, y + 60, color_white, TEXT_ALIGN_CENTER)
                draw.DrawText(temp, "McPhone.Main16", x + ws * 4.3, y + 80, color_white, TEXT_ALIGN_CENTER)
                
                DrawDetailMiningInfo()  
                if GetOilRushPriceMul() == 0 or GetMiningBuyRate() == 0 then
                    draw.DrawText("错误:无法获取信息\n请前往银行进行数据初始化后再试!", "zrush_npc_font03", 5, 185, zrush.default_colors["red01"], TEXT_ALIGN_LEFT)
                end
                local mt
                
                if unix then
                    local n = string.Explode("|", os.date("%H|%M"))
                    mt = "[" .. StormFox2.Time.GetDisplay(n[1] * 60 + n[2]) .. "]"
                else
                    mt = StormFox2.Time.GetDisplay()
                end
    
                draw.DrawText(mt, "McPhone.Main16", x + ws / 2, y + h - 30, color_white, TEXT_ALIGN_CENTER)
            end    
            McPhone.UI.Menu:AddItem(frame)
            
    end
    
    McPhone.Modules[module_id].openMenu = function()
        local wolfapp_page = 0
        if not McPhone.UI or not McPhone.UI.Menu then return end
        if not StormFox2 then return end
        wolfAppBackFunc = McPhone.UI.GoBack
    	  print(wolfAppBackFunc)
        wolfapp_Menu()
        McPhone.UI.GoBack = wolfAppBackFunc
                if wolfapp_page == 1 then
                   
                   wolfapp_Home()
                    
                end
    
                if wolfapp_page == 0 then
                   McPhone.UI.Buttons.Right = {"mc_phone/icons/buttons/id15.png", McPhone.MainColors["red"], nil}

						 	
                  wolfapp_Menu()
        				McPhone.UI.GoBack = wolfAppBackFunc	
        				
                end
                   
            
        
    end
    
    
    
        
    
    
    McPhone.Modules[module_id].CheckFunction = function()
        if not StormFox2 then return false end
    
        return true
    end