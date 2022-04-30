-- ╔═╗╔═╦═══╗╔═══╦╗────────────--
-- ║║╚╝║║╔═╗║║╔═╗║║────────────--
-- ║╔╗╔╗║║─╚╝║╚═╝║╚═╦══╦═╗╔══╗ --
-- ║║║║║║║─╔╗║╔══╣╔╗║╔╗║╔╗╣║═╣ --
-- ║║║║║║╚═╝║║║──║║║║╚╝║║║║║═╣ --
-- ╚╝╚╝╚╩═══╝╚╝──╚╝╚╩══╩╝╚╩══╝ --
-- ───── By Mactavish ─────────--
-- ────────────────────────────--
-- wwww
-- Phone app made for TLK RP server
-- some code is from original stormfox2 module.


-- Put shared functions here

-- End shared functions
if SERVER then
    
    util.AddNetworkString("wolfapp.CallRandomCpStart")
	util.AddNetworkString("wolfapp.CallRandomCpFailed")
    util.AddNetworkString("wolfapp.CallRandomCpGetGPS")
    util.AddNetworkString("wolfapp.FUFUTaxiSendRequest")
    util.AddNetworkString("wolfapp.FUFUTaxiServerResponce")
    util.AddNetworkString("wolfapp.FUFUTaxiSendCancelRequest")
    util.AddNetworkString("wolfapp.InfoCenterQueryNpc")
    util.AddNetworkString("wolfapp.InfoCenterQueryNpcReply")
    
    net.Receive("wolfapp.InfoCenterQueryNpc",function(len,player)
        -- function to get npc data synced on phones
        --PrintTable(ents.FindByClass("zrms_buyer"))
        --PrintTable(ents.FindByClass("zrush_fuelbuyer_npc"))
        for index, buyer in pairs(ents.FindByClass("zrms_buyer")) do 
            wolfapp_InfoCenterBuyRate = buyer:GetBuyRate()
            --print(wolfapp_InfoCenterBuyRate)
        end

        for index, fuelbuyer in pairs(ents.FindByClass("zrush_fuelbuyer_npc")) do 
            wolfapp_InfoCenterPriceMul = fuelbuyer:GetPrice_Mul()
            --print(wolfapp_InfoCenterPriceMul)
        end



        net.Start("wolfapp.InfoCenterQueryNpcReply")
        net.WriteFloat(wolfapp_InfoCenterBuyRate)
        net.WriteFloat(wolfapp_InfoCenterPriceMul)
        net.Send(player)

    end)

    net.Receive("wolfapp.FUFUTaxiSendCancelRequest", function(len, player)
        -- ply is the player who cancels the request
        print("Cancelling request")
        
        for k,v in pairs(FUFU.Taxi.Requests) do
            if v.by == player or v.taken_by == player then
                print("Found request")
                FUFU.Taxi.Requests[k] = nil
            end
    
        end
        PrintTable(FUFU.Taxi.Requests)
    end)

    net.Receive("wolfapp.FUFUTaxiSendRequest",function(l,pPlayer)
        if FUFU.Taxi:HasJob(pPlayer) then
            net.Start("wolfapp.FUFUTaxiServerResponce")
            net.WriteString("1")
            net.Send(pPlayer)
            return
        end
        
        if pPlayer:Taxi_HasRequest() then
            net.Start("wolfapp.FUFUTaxiServerResponce")
            net.WriteString("2")
            net.Send(pPlayer)
            return
        end
        
        local tbl = {
            by = pPlayer,
            pos = pPlayer:GetPos(),
        }
        
        local intId = table.insert(FUFU.Taxi.Requests or {},tbl)
        
        net.Start("wolfapp.FUFUTaxiServerResponce")
        net.WriteString("3")
        net.Send(pPlayer)
        
        for k,v in ipairs(player.GetAll() or {}) do
            if !IsValid(v) then continue end
            if !FUFU.Taxi:HasJob(v) then continue end
        
            FUFU.Taxi:Notify(v,FUFU.Taxi:GetLanguage("request_receive"),FUFU.Taxi:GetColor("green"))
        
            if !v:Taxi_HasMission() then
                FUFU.Taxi:SendEvent('send_request',{id = intId, all = FUFU.Taxi.Requests},v)
            end
        end
        


        return ""
    

    
    end)
    
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

function wolfapp_PublicFund_HTTP_Success()
    McPhone.StopSound()
    McPhone.UI.GoBack = wolfAppBackFunc
    McPhone.UI.Menu.ConvertToList()
    PrintTable(wolfapp_PublicFund_HttpResponse_Table.Company)
-- Menu Item list -- 
    for k,v in pairs(wolfapp_PublicFund_HttpResponse_Table.Company) do
        local name = v.Company_Name
        PrintTable(wolfapp_PublicFund_HttpResponse_Table.Company)
        McPhone.ListIcons(McPhone.UI.Menu, "mc_phone/icons/settings/id_5.png", name , false, function()  
                wolfapp_PublicFund_HttpResponse_DrawResult(v)
                McPhone.UI.GoBack = wolfAppBackFunc
                
        end)
        
    end
end


function wolfapp_PublicFund_HTTP_Loading()
    McPhone.UI.Menu:Clear(true)
    local bg = Color(26, 41, 72, 255)
    
    local frame = vgui.Create("DPanel")
    frame:SetSize(256, 256)
    frame:SetDisabled(true)
    frame:SetAlpha(255)
    
   	
    frame.Paint = function(self, w, h)
        
        surface.SetDrawColor(bg)
    	surface.DrawRect(0, 0, w, h)    
    	

        
        draw.DrawText("loading...", "zrush_npc_font03", 128, 20, zrush.default_colors["red01"], TEXT_ALIGN_CENTER)

        
        
        
        
        
    end
    McPhone.UI.Menu:AddItem(frame)
end

function wolfapp_PublicFund_HttpResponse_DrawResult(object)
    
    PrintTable(object)
    McPhone.UI.Menu:Clear(true)
    local bg = Color(77, 93, 145)
    local rc = Color(55, 55, 255, 55)
    local ca = Color(255, 255, 255, 8)
    McPhone.UI.OpenedMenu = "公款查询"
    McPhone.UI.Menu.ConvertToList()
    local frame = vgui.Create("DPanel")
    frame:SetSize(256, 256)
    frame:SetDisabled(true)
    frame:SetAlpha(255)
    local height = 0
    local isDrawComplete = false
    frame.Paint = function(self, w, h)
        McPhone.UI.OpenedMenu = "公款查询"
        surface.SetDrawColor(bg)
    	surface.DrawRect(0, 0, w, h)    
    	draw.DrawText("该公司拥有公款:"..tostring(object.PublicFund), "zrush_npc_font03", 0, 0 + height, zrush.default_colors["white01"], TEXT_ALIGN_CENTER)

        
        
        
        
    end
    McPhone.UI.Menu:AddItem(frame)
    
end

function wolfapp_PublicFund()
    if SERVER then return end
    wolfapp_PublicFund_Selection = "none"
    McPhone.UI.OpenedMenu = "PublicFund"
    McPhone.UI.Menu:Clear(true)
    McPhone.UI.Menu.ConvertToList()
    
    wolfapp_PublicFund_HTTP_Loading()
   	--PrintTable(McPhone.Config.GPSList[game.GetMap()])
    http.Fetch("https://wolf109909server.ga:63001/api/company/query.php",function(body)
        
        wolfapp_PublicFund_HttpResponse_Table = util.JSONToTable( body )
        wolfapp_PublicFund_HTTP_Success()
    end,function(error)
        print(error)
    end,{
        ["Content-Type"] = "application/json"
    })


        
        
end

local function wolfapp_PublicFund_Main()

end

local function wolfapp_Delivery_GetFoodDesc(id)
    if wolfapp_Delivery_FoodList == nil then
        return 
    end
    --PrintTable(wolfapp_Delivery_FoodList)

    return wolfapp_Delivery_FoodList[id].Food_Description
end


local function wolfapp_GetErrorStringFromCode(errcode)
    if errcode == 1 then
        return "参数错误"
    elseif errcode == 2 then
        return "数据库错误"
    elseif errcode == 3 then
        return "权限错误"
    elseif errcode == 4 then
        return "未知错误"
    elseif errcode == 5 then
        return "沒有數據"
    else
        return "未知错误:"..errcode
    end
end

local function wolfapp_Generic_Error(errcode)
    McPhone.UI.Menu:Clear(true)
    McPhone.UI.Menu.ConvertToList()
    local bg = FUFU.Taxi.Config.Colors["secondary"]
    local rc = Color(55, 55, 255, 55)
    local ca = Color(255, 255, 255, 8)
    local frame = vgui.Create("DPanel")

    frame:SetSize(256, 256)
    frame:SetDisabled(true)
    frame:SetAlpha(255)

    frame.Paint = function(self, w, h)
        local intW, intH = 64,64
        FUFUTaxi_Page_DrawBackGround()
        
        
        local mat = Material("fufu_taxi/error.png")
        
        surface.SetDrawColor(color_white)
        surface.SetMaterial(mat)
        surface.DrawTexturedRect(w/2-intW/2,h/2 - intH/2 - math.sin(CurTime() * 3) * 10 - 20,intW,intH)
        draw.DrawText(wolfapp_GetErrorStringFromCode(errcode), "FUFU:Taxi:24", 128, 150, zrush.default_colors["red01"], TEXT_ALIGN_CENTER)
    end    
    McPhone.UI.Menu:AddItem(frame)
end

function wolfapp_Delivery_InitLocalFoodSelect()
    wolfapp_Delivery_FoodSelect = wolfapp_Delivery_FoodSelect or {}
end

local function wolfapp_Generic_Loading()
    
end
function wolfapp_Delivery_ParseFoodList(response)
    local responsetable = util.JSONToTable(response)
    if responsetable.status != 0 then 
        wolfapp_Generic_Error(responsetable.status)
    return end
    --PrintTable(responsetable)

    wolfapp_Delivery_FoodList = responsetable.result
    wolfapp_Delivery_DrawFoodSelectionMenu()
end
function wolfapp_Delivery_UpdateFoodSelectionMenu()
    McPhone.UI.Menu:Clear(true)
    for k,v in pairs(wolfapp_Delivery_FoodList) do
        local name = v.Food_Name
        local id = v.Food_ID
        wolfapp_Delivery_UI_ListFood( id ,McPhone.UI.Menu, "mc_phone/icons/settings/id_5.png", name , false, function()  
                McPhone.UI.GoBack = wolfAppBackFunc
                
        end)
        
    end
end
function wolfapp_Delivery_DrawFoodSelectionMenu()
    McPhone.StopSound()
    McPhone.UI.GoBack = wolfAppBackFunc
    McPhone.UI.Menu.ConvertToList()
    PrintTable(wolfapp_Delivery_FoodList)
    wolfapp_Delivery_InitLocalFoodSelect()
-- Menu Item list -- 
    for k,v in pairs(wolfapp_Delivery_FoodList) do
        local name = v.Food_Name
        local id = v.Food_ID
        wolfapp_Delivery_UI_ListFood( id ,McPhone.UI.Menu, "mc_phone/icons/settings/id_5.png", name , false, function()  
                McPhone.UI.GoBack = wolfAppBackFunc
                
        end)
        
    end
end

function wolfapp_Delivery_GetFoodList()
    wolfapp_Delivery_FoodList = wolfapp_Delivery_FoodList or {}
    wolfapp_Test_HTTP_Loading()

    http.Fetch("https://wolf109909server.ga:63001/api/food/query.php",function(body)
        wolfapp_Delivery_ParseFoodList(body)
    end,function(error)
        wolfapp_Generic_Error(error)
    end,{
        ["Content-Type"] = "application/json"
    })
end
--CLIENT SECTION
--REGISTER YOUR CLIENT FUNCTIONS HERE
local function drawScrSpaceText(text, x, y, mx, color, parent)
	local font = "McPhone.Main18"
	surface.SetFont(font)
	local w = surface.GetTextSize(text)

	if w + x > mx then
		if parent then
			if parent.text_dir and isnumber(parent.text_dir) and parent.text_dir < CurTime() then
				parent.text_dir = nil
			end

			if parent.text_pos > mx - w - (10 + x) and not parent.text_dir then
				parent.text_pos = math.Approach(parent.text_pos, mx - w - (10 + x), FrameTime() * 50)
			else
				if parent.text_pos >= 0 and not isnumber(parent.text_dir) then
					parent.text_dir = CurTime() + 2
				else
					parent.text_pos = math.Approach(parent.text_pos, 0, FrameTime() * 50)
				end

				if not parent.text_dir then
					parent.text_dir = true
				end
			end

			local sx, sy = parent:LocalToScreen(x, 0)
			render.SetScissorRect(sx, sy, sx + (mx - x), sy + parent:GetTall(), true)
			draw.SimpleText(text, font, x + parent.text_pos, y, color, TEXT_ALIGN_LEFT)
			render.SetScissorRect(0, 0, 0, 0, false)

			return
		else
			font = "McPhone.Main18"
			y = y + 3
		end
	end

	draw.SimpleText(text, font, x, y, color, TEXT_ALIGN_LEFT)
end
function wolfapp_Delivery_UI_ListFood(foodid, parent, icon, text, check, func, ignore, snd, supress )
    if wolfapp_Delivery_FoodList == nil then return end
    if wolfapp_Delivery_FoodSelect == nil then return end
	local icon_nohover, icon_url
    local currentfoodquantity = wolfapp_Delivery_FoodSelect[foodid] or "0"
	if istable(icon) then
		icon_nohover = icon[2]
		icon_url = icon[3]
		icon = icon[1]
	end
    
    

	local buton = vgui.Create("DButton")
	buton.icon = icon
	buton.check = check
	buton:SetSize(180, 25)
	buton:SetText("")
	buton.text_pos = 0
	buton.text_dir = CurTime() + 2

	buton.DoClick = function(self)
		if not snd then
			McPhone.PlaySoundUI("mc_phone/open_1.wav")
		end

		if func then
			func(self)
		end

		if McPhone.UI and not ignore then
			
		end

		return supress
	end

    local desc = wolfapp_Delivery_GetFoodDesc(foodid)
	buton.Paint = function(self, w, h)
		if self.check then
			icon = "mc_phone/icons/settings/id_9.png"
		elseif icon ~= buton.icon then
			icon = buton.icon
		end

		if self.hover then
			draw.RoundedBox(0, 0, 0, w, h, McPhone.UserCfg.Theme["buttons"])

			if isstring(icon) and not icon_nohover then
				McPhone.DrawTexturedRect(5, 5, 16, 16, McPhone.GetUrlIcon(icon, icon_url), color_white)
			end

			drawScrSpaceText(desc, 25, 3, w, color_white, self)
		else
			if isstring(icon) and not icon_nohover then
				McPhone.DrawTexturedRect(5, 5, 16, 16, McPhone.GetUrlIcon(icon, icon_url), color_black)
			end

			drawScrSpaceText(text, 25, 3, w, color_black, self)
		end

		if icon_nohover then
			McPhone.DrawTexturedRect(5, 5, 16, 16, McPhone.GetUrlIcon(icon, icon_url), color_white)
		end

		draw.RoundedBox(0, 0, h - 3, w, 3, McPhone.MainColors.shadow_100)
	end

	buton.OnCursorEntered = function(self, mute)
		if not mute and not snd then
			McPhone.PlaySoundUI("mc_phone/click.wav")
		end

		if snd then
			if snd == "snd" then
				McPhone.StopSound()
			else
				McPhone.PlaySound(snd)
			end
		end

		self.hover = true

		for k, v in pairs(parent:GetItems()) do
			if v == self then continue end
			v:OnCursorExited()
		end
	end

	buton.OnCursorExited = function(self)
		self.hover = false
	end



	if not isstring(icon) then
		local avatar = vgui.Create("AvatarImage", buton)
		avatar:SetSize(32, 32)
		avatar:SetPos(5, 10)
		avatar:SetPlayer(icon, 32)
	end

	parent:AddItem(buton)


    local plusbtn = vgui.Create("DButton", buton)
    plusbtn:SetSize(24, 24)
    plusbtn:SetText("+")
    parent:AddItem(plusbtn)
    plusbtn.DoClick = function()

        if wolfapp_Delivery_FoodSelect[foodid] then
            wolfapp_Delivery_FoodSelect[foodid] = wolfapp_Delivery_FoodSelect[foodid] + 1
        else
            wolfapp_Delivery_FoodSelect[foodid] = 0
        end
        if snd then
            surface.PlaySound(snd)
        end
        wolfapp_Delivery_UpdateFoodSelectionMenu()
    end


    local quantitybtn = vgui.Create("DButton", buton)
    quantitybtn:SetSize(24, 24)
    quantitybtn:SetText(tostring(currentfoodquantity))
    parent:AddItem(quantitybtn)

    local minusbtn = vgui.Create("DButton", buton)
    minusbtn:SetSize(24, 24)
    minusbtn:SetText("-")
    parent:AddItem(minusbtn)
    minusbtn.DoClick = function()
        if wolfapp_Delivery_FoodSelect[foodid] then
            if(wolfapp_Delivery_FoodSelect[foodid] > 0) then
                wolfapp_Delivery_FoodSelect[foodid] = wolfapp_Delivery_FoodSelect[foodid] - 1
            end
        else
            wolfapp_Delivery_FoodSelect[foodid] = 0
        end
        if snd then
            surface.PlaySound(snd)
        end
        wolfapp_Delivery_UpdateFoodSelectionMenu()
    end
	return buton
end


function wolfapp_Delivery_Main()
    McPhone.UI.OpenedMenu = "Test"
    McPhone.UI.Menu:Clear(true)
    McPhone.UI.Menu.ConvertToList()
    
    
    wolfapp_Delivery_GetFoodList()

end

function McPhone.WolfappListIcons(parent, icon, text, check, func, ignore, snd, supress)
	local icon_nohover, icon_url

	if istable(icon) then
		icon_nohover = icon[2]
		icon_url = icon[3]
		icon = icon[1]
	end
    
    local plusbtn = vgui.Create("DButton", buton)
    plusbtn:SetSize(24, 24)
    plusbtn:SetText("+")
    parent:AddItem(plusbtn)

    local quantitybtn = vgui.Create("DButton", buton)
    plusbtn:SetSize(24, 24)
    plusbtn:SetText("+")
    parent:AddItem(plusbtn)

    local minusbtn = vgui.Create("DButton", buton)
    minusbtn:SetSize(24, 24)
    minusbtn:SetText("-")
    parent:AddItem(minusbtn)

	local buton = vgui.Create("DButton")
	buton.icon = icon
	buton.check = check
	buton:SetSize(180, 25)
	buton:SetText("")
	buton.text_pos = 0
	buton.text_dir = CurTime() + 2

	buton.DoClick = function(self)
		if not snd then
			McPhone.PlaySoundUI("mc_phone/open_1.wav")
		end

		if func then
			func(self)
		end

		if McPhone.UI and not ignore then
			McPhone.UI.OpenedMenu = text
		end

		return supress
	end
    local desc = wolfapp_Delivery_GetFoodDesc(id)
	buton.Paint = function(self, w, h)
		if self.check then
			icon = "mc_phone/icons/settings/id_9.png"
		elseif icon ~= buton.icon then
			icon = buton.icon
		end

		if self.hover then
			draw.RoundedBox(0, 0, 0, w, h, McPhone.UserCfg.Theme["buttons"])

			if isstring(icon) and not icon_nohover then
				McPhone.DrawTexturedRect(5, 5, 16, 16, McPhone.GetUrlIcon(icon, icon_url), color_white)
			end

			drawScrSpaceText(text, 25, 3, w, color_white, self)
		else
			if isstring(icon) and not icon_nohover then
				McPhone.DrawTexturedRect(5, 5, 16, 16, McPhone.GetUrlIcon(icon, icon_url), color_black)
			end

			drawScrSpaceText(text, 25, 3, w, color_black, self)
		end

		if icon_nohover then
			McPhone.DrawTexturedRect(5, 5, 16, 16, McPhone.GetUrlIcon(icon, icon_url), color_white)
		end

		draw.RoundedBox(0, 0, h - 3, w, 3, McPhone.MainColors.shadow_100)
	end

	buton.OnCursorEntered = function(self, mute)
		if not mute and not snd then
			McPhone.PlaySoundUI("mc_phone/click.wav")
		end

		if snd then
			if snd == "snd" then
				McPhone.StopSound()
			else
				McPhone.PlaySound(snd)
			end
		end

		self.hover = true

		for k, v in pairs(parent:GetItems()) do
			if v == self then continue end
			v:OnCursorExited()
		end
	end

	buton.OnCursorExited = function(self)
		self.hover = false
	end



	if not isstring(icon) then
		local avatar = vgui.Create("AvatarImage", buton)
		avatar:SetSize(32, 32)
		avatar:SetPos(5, 10)
		avatar:SetPlayer(icon, 32)
	end

	parent:AddItem(buton)

	return buton
end

FUFU.Taxi.IsTaxiAppPresent = true


--FUFU TAXI MODULE FUNCTIONS 

local w,h = 256,256


net.Receive("wolfapp.FUFUTaxiServerResponce",function(l)
    FUFUTaxi_Result = net.ReadString()
    FUFUTaxi_Driver = net.ReadEntity()
    --LocalPlayer():ConCommand( "say /ooc [debug]:" .. FUFUTaxi_Result )
end)


function FUFUTaxi_Page_DrawBackGround()
    local bg = FUFU.Taxi.Config.Colors["secondary"]
    surface.SetDrawColor(bg)
    surface.DrawRect(0, 0, w, h)    
end
local function FUFUTaxi_ClientRequestTaxi()
    
    net.Start("wolfapp.FUFUTaxiSendRequest")
    net.SendToServer()

end  

local function FUFUTaxi_Page_CallingTaxi()
    local intW, intH = 64,64
    local mat = Material("fufu_taxi/call-center.png")
    FUFUTaxi_Page_DrawBackGround()
    surface.SetDrawColor(color_white)
    surface.SetMaterial(mat)
    surface.DrawTexturedRect(w/2-intW/2,h/2 - intH/2 - math.sin(CurTime() * 3) * 10 - 20,intW,intH)
    
    
    draw.DrawText("正在呼叫出租车...", "FUFU:Taxi:24", 128, 150, zrush.default_colors["white01"], TEXT_ALIGN_CENTER)
end

local function FUFUTaxi_Page_DrawStatus(status,str)
    local intW, intH = 64,64
    FUFUTaxi_Page_DrawBackGround()
    
    if status == false then 
        local mat = Material("fufu_taxi/error.png")
        
        surface.SetDrawColor(color_white)
        surface.SetMaterial(mat)
        surface.DrawTexturedRect(w/2-intW/2,h/2 - intH/2 - math.sin(CurTime() * 3) * 10 - 20,intW,intH)
        draw.DrawText(str, "FUFU:Taxi:24", 128, 150, zrush.default_colors["red01"], TEXT_ALIGN_CENTER)
    end
    if status == true then
        if FUFUTaxi_Driver == nil then return end
        local mat = Material("fufu_taxi/correct.png")
        local distance = math.Round(LocalPlayer():GetPos():Distance(FUFUTaxi_Driver:GetPos()))
        if distance < 500 then
            surface.SetDrawColor(color_white)
            surface.SetMaterial(mat)
            surface.DrawTexturedRect(w/2-intW/2,h/2 - intH/2 - math.sin(CurTime() * 3) * 10 - 20,intW,intH)
            draw.DrawText("司机已到达", "FUFU:Taxi:24", 128, 140, FUFU.Taxi:GetColor("green"), TEXT_ALIGN_CENTER)
        end
        surface.SetDrawColor(color_white)
        surface.SetMaterial(mat)
        surface.DrawTexturedRect(w/2-intW/2,h/2 - intH/2 - math.sin(CurTime() * 3) * 10 - 20,intW,intH)
        draw.DrawText(str, "FUFU:Taxi:24", 128, 140, zrush.default_colors["white01"], TEXT_ALIGN_CENTER)
        draw.DrawText("司机距离您还有:", "FUFU:Taxi:16", 128, 164, zrush.default_colors["white01"], TEXT_ALIGN_CENTER)
        draw.DrawText(distance, "FUFU:Taxi:16", 128, 178, zrush.default_colors["white01"], TEXT_ALIGN_CENTER)
    end

end
local function FUFUTaxi_Page_DrawSuccess(str)
    McPhone.UI.Menu:Clear(true)
    McPhone.UI.Menu.ConvertToList()
    local bg = FUFU.Taxi.Config.Colors["secondary"]
    local rc = Color(55, 55, 255, 55)
    local ca = Color(255, 255, 255, 8)
    local frame = vgui.Create("DPanel")

    frame:SetSize(256, 256)
    frame:SetDisabled(true)
    frame:SetAlpha(255)

    frame.Paint = function(self, w, h)
        McPhone.UI.OpenedMenu = "取消订单"
        
        local intW, intH = 64,64
        FUFUTaxi_Page_DrawBackGround()
        local mat = Material("fufu_taxi/correct.png")
        surface.SetDrawColor(color_white)
        surface.SetMaterial(mat)
        surface.DrawTexturedRect(w/2-intW/2,h/2 - intH/2 - math.sin(CurTime() * 3) * 10 - 20,intW,intH)
        draw.DrawText(str, "FUFU:Taxi:24", 128, 150, zrush.default_colors["green"], TEXT_ALIGN_CENTER)
        
        
        
        
        
    end
    McPhone.UI.Menu:AddItem(frame)
end


function wolfapp_Fufutaxi_CancelRequest()
    McPhone.UI.GoBack = print("")
    net.Start("wolfapp.FUFUTaxiSendCancelRequest")
    net.SendToServer()
    timer.Simple(3,function()
        wolfapp_Menu()
    end)
    FUFUTaxi_Page_DrawSuccess("出租车请求已取消!\n芙芙将在3秒后返回主菜单")

end

function wolfapp_Fufutaxi_Welcome()
    local intW, intH = 64,64
    local mat = Material("fufu_taxi/taxi_64.png")
    FUFUTaxi_Page_DrawBackGround()
    surface.SetDrawColor(color_white)
    surface.SetMaterial(mat)
    surface.DrawTexturedRect(w/2-intW/2,h/2 - intH/2 - math.sin(CurTime() * 3) * 10 - 20,intW,intH)
    
    
    draw.DrawText("欢迎使用芙芙打车!\n将在3秒后开始叫车!", "FUFU:Taxi:24", 128, 150, zrush.default_colors["white01"], TEXT_ALIGN_CENTER)

end

function wolfapp_Fufutaxi_Menu()
    McPhone.UI.Buttons.Left = {nil, nil, nil}
    McPhone.UI.Buttons.Middle = {nil, nil, nil}
    McPhone.UI.Buttons.Right = {nil, nil, nil}
    McPhone.UI.GoBack = function()
        wolfapp_Fufutaxi()
    end

    McPhone.UI.Menu.ConvertToList()
        
    McPhone.UI.Menu:Clear(true)
    McPhone.UI.OpenedMenu = "芙芙菜单"
    McPhone.ListIcons(McPhone.UI.Menu, "mc_phone/icons/settings/id_5.png", "取消订单", false, function() 
        
        wolfapp_Fufutaxi_CancelRequest()
        
        
    end)
end
function wolfapp_Fufutaxi()
    McPhone.UI.Buttons.Left = {nil, nil, nil}
    McPhone.UI.Buttons.Right = {"mc_phone/icons/buttons/id4.png", McPhone.MainColors["green"], function()
        wolfapp_Fufutaxi_Menu()
        
    
    end}
    McPhone.UI.Buttons.Middle = {nil, nil, nil}

    timer.Create("FUFUTaxi_Welcome", 3, 1, function()
        FUFUTaxi_ClientRequestTaxi()
    end)

    --FUFUTaxi_IsTaxiAppOpen = true 
    FUFUTaxi_Result = "0"
    
    
    McPhone.UI.Menu:Clear(true)
    McPhone.UI.Menu.ConvertToList()
    local bg = FUFU.Taxi.Config.Colors["secondary"]
    local rc = Color(55, 55, 255, 55)
    local ca = Color(255, 255, 255, 8)
    local frame = vgui.Create("DPanel")

    frame:SetSize(256, 256)
    frame:SetDisabled(true)
    frame:SetAlpha(255)
    
   	PrintTable(McPhone.Config.GPSList[game.GetMap()])
    
    frame.Paint = function(self, w, h)
        
        McPhone.UI.OpenedMenu = "芙芙打车"
        --print(FUFUTaxi_Result)
        if FUFUTaxi_Result == "0" then
            wolfapp_Fufutaxi_Welcome()
        end
        if FUFUTaxi_Result == "1" then
            FUFUTaxi_Page_DrawStatus(false,FUFU.Taxi:GetLanguage("player_can"))
        end
        if FUFUTaxi_Result == "2" then
            FUFUTaxi_Page_DrawStatus(false,FUFU.Taxi:GetLanguage("already_request"))
        end
        if FUFUTaxi_Result == "3" then
            FUFUTaxi_Page_CallingTaxi()
        end
        if FUFUTaxi_Result == "4" then
            FUFUTaxi_Page_DrawStatus(true,"呼叫成功,请等待司机到达！")
        end
        
        
        
        
    end
    McPhone.UI.Menu:AddItem(frame)
    
    
        
        
end
-- END FUFUTAXI MODULE

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
    --LocalPlayer():ConCommand( "say /ooc distance:"..distance )
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
    CallRandomCpStartColor = zrush.default_colors["white01"]
    CallRandomCpStartText = "正在呼叫在线警察..."
    McPhone.PlaySound("mc_phone/tone.wav")
    net.Start("wolfapp.CallRandomCpStart")
    net.SendToServer()    
end  

local function drawFailure()
    
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
function wolfapp_Test_HTTP_Success()
    McPhone.StopSound()
    McPhone.UI.GoBack = wolfAppBackFunc
    McPhone.UI.Menu.ConvertToList()

-- Menu Item list -- 
    for k,v in pairs(wolfapp_Test_HttpResponse_Table) do
        local name = wolfapp_Test_HttpResponse_Table[k].name
        
        McPhone.WolfappListIcons(McPhone.UI.Menu, "mc_phone/icons/settings/id_5.png", name , false, function()  
                wolfapp_Test_HttpResponse_DrawResult(k)
                McPhone.UI.GoBack = wolfapp_Menu
                
        end)
        
    end
end
function wolfapp_Test_HTTP_Loading()
    McPhone.UI.Menu:Clear(true)
    local bg = Color(26, 41, 72, 255)
    
    local frame = vgui.Create("DPanel")
    frame:SetSize(256, 256)
    frame:SetDisabled(true)
    frame:SetAlpha(255)
    
   	
    frame.Paint = function(self, w, h)
        
        surface.SetDrawColor(bg)
    	surface.DrawRect(0, 0, w, h)    
    	

        
        draw.DrawText("loading...", "zrush_npc_font03", 128, 20, zrush.default_colors["red01"], TEXT_ALIGN_CENTER)

        
        
        
        
        
    end
    McPhone.UI.Menu:AddItem(frame)
end

function wolfapp_Test_HttpResponse_DrawResult(k)
    server = wolfapp_Test_HttpResponse_Table[k]
    PrintTable(server)
    McPhone.UI.Menu:Clear(true)
    local bg = Color(77, 93, 145)
    local rc = Color(55, 55, 255, 55)
    local ca = Color(255, 255, 255, 8)
    McPhone.UI.OpenedMenu = "测试"
    McPhone.UI.Menu.ConvertToList()
    local frame = vgui.Create("DPanel")
    frame:SetSize(256, 256)
    frame:SetDisabled(true)
    frame:SetAlpha(255)
    local height = 0
    local isDrawComplete = false
    frame.Paint = function(self, w, h)
        McPhone.UI.OpenedMenu = "测试"
        surface.SetDrawColor(bg)
    	surface.DrawRect(0, 0, w, h)    
    	
        
            for k,v in pairs(server) do
                if k != "modInfo" then
                    --print(tostring(k)..":"..tostring(v))
                    draw.DrawText(tostring(k)..":"..tostring(v), "zrush_npc_font03", 0, 0 + height, zrush.default_colors["white01"], TEXT_ALIGN_LEFT)
                    height = height + 16
                end
            end

            height = 0
        
        
        
        
    end
    McPhone.UI.Menu:AddItem(frame)
    
end
-- Test page for example
function wolfapp_Test()
    if SERVER then return end
    wolfapp_Test_Selection = "none"
    McPhone.UI.OpenedMenu = "Test"
    McPhone.UI.Menu:Clear(true)
    McPhone.UI.Menu.ConvertToList()
    
    wolfapp_Test_HTTP_Loading()
   	--PrintTable(McPhone.Config.GPSList[game.GetMap()])
    http.Fetch("https://northstar.tf/client/servers",function(body)
        
        wolfapp_Test_HttpResponse_Table = util.JSONToTable( body )
        wolfapp_Test_HTTP_Success()
    end,function(error)
        print(error)
    end,{
        ["Content-Type"] = "application/json"
    })


        
        
end
 
function wolfapp_Emergency()

    if SERVER then return end
    McPhone.UI.Buttons.Left = {nil,nil,nil}
    McPhone.UI.Buttons.Right = {nil,nil,nil}
    McPhone.UI.Buttons.Middle = {nil,nil,nil}
    clearGPS()
    wolfapp_isGPSToggledOn = false
    wolfapp_CallRandomCpFailed = false
    timer.Simple(5,drawFailure)
    

    timer.Create("wolfapp_EmergencyCalldelay", 3, 1, function()
        startCall()
    end)

    print(timer.Exists("wolfapp_EmergencyCalldelay"))
    CallRandomCpStartText = "将在3秒后呼叫警察"
    
    
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
local module_id = 12

McPhone.Modules[module_id] = {}
McPhone.Modules[module_id].name = "WOLF便民服务"
McPhone.Modules[module_id].icon = "mc_phone/icons/main_menu/web.png"
McPhone.Modules[module_id].number = 0
local bg = Color(26, 41, 72, 255)
local rc = Color(55, 55, 255, 55)
local ca = Color(255, 255, 255, 8)
    
-- Read Server side entity for info center calculations
net.Receive("wolfapp.InfoCenterQueryNpcReply",function(l)
    wolfapp_InfoCenterBuyRate = net.ReadFloat()
    wolfapp_InfoCenterPriceMul = net.ReadFloat()
end)

function wolfapp_InfoCenterQueueNpc()
    net.Start("wolfapp.InfoCenterQueryNpc")
    net.SendToServer()
end

local function GetMiningBuyRate()
    local BuyRate
    
    BuyRate = wolfapp_InfoCenterBuyRate

    if BuyRate == nil then
        return 0
    end 

    return BuyRate
end
    
local function GetOilRushPriceMul()
        local OilrushPriceMul
    
        OilrushPriceMul = wolfapp_InfoCenterPriceMul

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



function wolfapp_Home()  
    wolfapp_InfoCenterQueueNpc()
    clearGPS()
    McPhone.StopSound()
    McPhone.UI.Menu:Clear(true)
    McPhone.UI.Buttons.Left = {nil,nil,nil}
    McPhone.UI.Buttons.Right = {nil,nil,nil}
    McPhone.UI.Buttons.Middle = {nil,nil,nil}
    
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
-- Menu Item list -- 
    McPhone.UI.Menu:Clear(true)
    McPhone.UI.OpenedMenu = "WOLF便民服务"
    McPhone.ListIcons(McPhone.UI.Menu, "mc_phone/icons/settings/id_5.png", "信息中心", false, function() 
            wolfapp_Home()
            McPhone.UI.GoBack = wolfapp_Menu
    end)
    McPhone.ListIcons(McPhone.UI.Menu, "mc_phone/icons/settings/id_1.png", "紧急呼叫", false, function() 
            wolfapp_Emergency()
            McPhone.UI.GoBack = function()
                timer.Destroy("wolfapp_EmergencyCalldelay")
                wolfapp_Menu()
            end
            
    end)
    McPhone.ListIcons(McPhone.UI.Menu, "fufu_taxi/call_taxi_white.png", "芙芙打车", false, function() 
        wolfapp_Fufutaxi()
        McPhone.UI.GoBack = function()
            timer.Destroy("FUFUTaxi_Welcome")
            wolfapp_Menu()
        end
        
    end)
    McPhone.ListIcons(McPhone.UI.Menu, "mc_phone/icons/settings/id_3.png", "公款查询", false, function() 
        wolfapp_PublicFund()
        McPhone.UI.GoBack = wolfapp_Menu
        
    end)
    McPhone.ListIcons(McPhone.UI.Menu, "mc_phone/icons/settings/id_3.png", "WOLF外卖", false, function() 
        wolfapp_Delivery_Main()
        McPhone.UI.GoBack = wolfapp_Menu
        
    end)
    
end


McPhone.Modules[module_id].openMenu = function()
    local wolfapp_page = 0
    if not McPhone.UI or not McPhone.UI.Menu then return end
    if not StormFox2 then return end
    wolfAppBackFunc = McPhone.UI.GoBack
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
