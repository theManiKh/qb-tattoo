local QBCore = exports['qb-core']:GetCoreObject()
local Logedin = false
local currentTattoos = {}
local cam = nil
local view = false
local opacity = 1
local Tattoshopprice = {}
local Tattoshoppriceended = {}

CreateThread(function()
	AddTextEntry("Tattoos", "Tattoo Shop")
	for k, v in pairs(Config.Shops) do
		local blip = AddBlipForCoord(v[1], v[2], v[2])
		SetBlipSprite(blip, 75)
		SetBlipColour(blip, 1)
		SetBlipScale(blip, 0.5)
		SetBlipAsShortRange(blip, true)
		BeginTextCommandSetBlipName("Tattoos")
		EndTextCommandSetBlipName(blip)
	end
	for i = 1, #Config.Shops do
        tatto = Config.Shops[i]
		local model = "u_m_y_tattoo_01"
		RequestModel(GetHashKey(model))
		while not HasModelLoaded(GetHashKey(model)) do
			Wait(1)
		end
		local npc = CreatePed(4, GetHashKey(model), tatto[1], tatto[2], tatto[3] - 1.0,  tatto[4], false, true)
		FreezeEntityPosition(npc, true)
		SetEntityInvincible(npc, true)
		SetBlockingOfNonTemporaryEvents(npc, true)
        exports["qb-target"]:AddTargetEntity(npc, {
            options = {
                {
                    event = "qb-tatto:client:GoToMeno",
                    icon = "fas fa-cash-register",
                    label = "Buy Tattoo",
                },
            },
            distance = 2.0
        })
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
	Logedin = true
	Wait(7000)
    TriggerServerEvent('qb-tattooshop:server:SelectTattoos')
end)

RegisterCommand('haha', function()
	Logedin = true
    TriggerServerEvent('qb-tattooshop:server:SelectTattoos')
end)

function DrawTattoo(collection, name)
	ClearPedDecorations(PlayerPedId())
	for k, v in pairs(currentTattoos) do
		if v.Count ~= nil then
			for i = 1, v.Count do
				SetPedDecoration(PlayerPedId(), v.collection, v.nameHash)
			end
		else
			SetPedDecoration(PlayerPedId(), v.collection, v.nameHash)
		end
	end
	for i = 1, opacity do
		SetPedDecoration(PlayerPedId(), collection, name)
	end
end


function BuyTattoo(collection, name, label, price)
	QBCore.Functions.TriggerCallback('qb-tattooshop:PurchaseTattoo', function(success)
		if success then
			table.insert(currentTattoos, {collection = collection, nameHash = name, Count = opacity})
		end
	end, currentTattoos, price, {collection = collection, nameHash = name, Count = opacity})
end

function RemoveTattoo(name, label)
	for k, v in pairs(currentTattoos) do
		if v.nameHash == name then
			table.remove(currentTattoos, k)
		end
	end
	ClearPedDecorations(PlayerPedId())
	TriggerServerEvent("qb-tattooshop:server:RemoveTattoo", currentTattoos)
	QBCore.Functions.Notify("You have removed the " .. GetLabelText(label) .. " tattoo", 'success')
end

RegisterNetEvent('qb-tattoo:client:SetaCameraForSell', function(data)
	if not view then
		for k, v in pairs(Config.TattooCats) do
			if v[1] == data.db2[1] then
				if not DoesCamExist(cam) then
					cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", 1)
					SetCamActive(cam, true)
					RenderScriptCams(true, false, 0, true, true)
					StopCamShaking(cam, true)
				end
				if GetCamCoord(cam) ~= GetOffsetFromEntityInWorldCoords(PlayerPedId(), v[3][1]) then
					SetCamCoord(cam, GetOffsetFromEntityInWorldCoords(PlayerPedId(), v[3][1]))
					PointCamAtCoord(cam, GetOffsetFromEntityInWorldCoords(PlayerPedId(), data.db2[4].x, data.db2[4].y, data.db2[4].z))
				end
			end
		end
		Tattoshoppriceended = {
			{
				header = '< Go Back',
				params = {
					event = 'qb-tatto:client:gobacktattolist'
				}
			},
			{
				header = '🔄 Change Camera',
				params = {
					event = 'qb-tatto:client:changecamera',
					args = data.db2
				}
			},
		}
		Tattoshoppriceended[#Tattoshoppriceended+1] = {
			header = "Apply tatto",
			txt = "$"..math.floor(data.db.Price / 100),
			params = {
				event = "qb-tattoo:client:EndOftattoIsaccept",
				args = {["price"] = math.floor(data.db.Price / 10), ["Collection"] = data.db.Collection, ["HashNameFemale"] = data.db.HashNameFemale, ["HashNameMale"] = data.db.HashNameMale, ["name"] = data.db.Name},
			}
		}

		exports['qb-menu']:openMenu(Tattoshoppriceended)
	else
		TriggerEvent('qb-tattoo:client:OpenTattooMenu', data.db2)
	end

	if GetEntityModel(PlayerPedId()) == `mp_m_freemode_01` then
		DrawTattoo(data.db.Collection, data.db.HashNameMale)
	else
		DrawTattoo(data.db.Collection, data.db.HashNameFemale)
	end
end)

local cameraname = 1
RegisterNetEvent('qb-tatto:client:changecamera', function(data)
	for k, v in pairs(Config.TattooCats) do
		if v[1] == data[1] then
			if not DoesCamExist(cam) then
				cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", 1)
				SetCamActive(cam, true)
				RenderScriptCams(true, false, 0, true, true)
				StopCamShaking(cam, true)
			end
			if cameraname == 4 then
				cameraname = 1
			else
				cameraname = cameraname + 1
			end
			if GetCamCoord(cam) ~= GetOffsetFromEntityInWorldCoords(PlayerPedId(), v[3][cameraname]) then
				SetCamCoord(cam, GetOffsetFromEntityInWorldCoords(PlayerPedId(), v[3][cameraname]))
				PointCamAtCoord(cam, GetOffsetFromEntityInWorldCoords(PlayerPedId(), v[4]))
			end
		end
	end
	if view then
		TriggerEvent('qb-tattoo:client:OpenTattooMenu', data)
	else
		exports['qb-menu']:openMenu(Tattoshoppriceended)
	end
end)

RegisterNetEvent('qb-tattoo:client:EndOftattoIsaccept', function(data)
	if DoesCamExist(cam) then
		DetachCam(cam)
		SetCamActive(cam, false)
		RenderScriptCams(false, false, 0, 1, 0)
		DestroyCam(cam, false)
	end
	if GetEntityModel(PlayerPedId()) == `mp_m_freemode_01` then
		BuyTattoo(data.Collection, data.HashNameMale, data.name, math.floor(data.price / 10))
	else
		BuyTattoo(data.Collection, data.HashNameFemale, data.name, math.floor(data.price / 10))
	end
end)

RegisterNetEvent('qb-tatto:client:gobacktattolist', function()

	ClearPedDecorations(PlayerPedId())
	if currentTattoos ~= nil then
		for k, v in pairs(currentTattoos) do
			if v.Count ~= nil then
				for i = 1, v.Count do
					SetPedDecoration(PlayerPedId(), v.collection, v.nameHash)
				end
			else
				SetPedDecoration(PlayerPedId(), v.collection, v.nameHash)
			end
		end
	end

	if DoesCamExist(cam) then
		DetachCam(cam)
		SetCamActive(cam, false)
		RenderScriptCams(false, false, 0, 1, 0)
		DestroyCam(cam, false)
	end
	exports['qb-menu']:openMenu(Tattoshopprice)
end)

RegisterNetEvent('qb-tattoo:client:OpenTattooMenu', function(data)
	if view then
		Tattoshopprice = {
			{
				header = "Tattoos for "..data[2],
				isMenuHeader = true
			},
			{
				header = '< Go Back',
				params = {
					event = 'qb-tatto:client:GoToMeno'
				}
			},
			{
				header = 'View Mode: ✅',
				params = {
					event = 'qb-tatto:client:ViewMode',
					args = data,
				}
			},
			{
				header = '🔄 Change Camera',
				params = {
					event = 'qb-tatto:client:changecamera',
					args = data
				}
			},
		}
	else
		Tattoshopprice = {
			{
				header = "Tattoos for "..data[2],
				isMenuHeader = true
			},
			{
				header = '< Go Back',
				params = {
					event = 'qb-tatto:client:GoToMeno'
				}
			},
			{
				header = 'View Mode: ❌',
				params = {
					event = 'qb-tatto:client:ViewMode',
					args = data,
				}
			},
		}
	end
	for _, tattoo in pairs(Config.AllTattooList) do
		if tattoo.Zone == data[1] then
			if GetEntityModel(PlayerPedId()) == `mp_m_freemode_01` then
				if tattoo.HashNameMale ~= '' then
					for k, v in pairs(currentTattoos) do
						if v.nameHash == tattoo.HashNameMale then
							Tattoshopprice[#Tattoshopprice+1] = {
								header = "[✔] "..GetLabelText(tattoo.Name).." (Already have)",
								txt = "Select for forced remove",
								params = {
									event = "qb-tattoo:client:deletetattoo",
									args = {db = tattoo, db2 = data},
								}
							}
							break
						end
					end
					Tattoshopprice[#Tattoshopprice+1] = {
						header = "["..(#Tattoshopprice+1).."] "..GetLabelText(tattoo.Name),
						txt = "$"..math.floor(tattoo.Price / 100),
						params = {
							event = "qb-tattoo:client:SetaCameraForSell",
							args = {db = tattoo, db2 = data},
						}
					}
				end
			else
				if tattoo.HashNameFemale ~= '' then
					for k, v in pairs(currentTattoos) do
						if v.nameHash == tattoo.HashNameFemale then
							Tattoshopprice[#Tattoshopprice+1] = {
								header = "[✔] "..GetLabelText(tattoo.Name).." (Already have)",
								txt = "Select for forced remove",
								params = {
									event = "qb-tattoo:client:deletetattoo",
									args = {db = tattoo, db2 = data},
								}
							}
							break
						end
					end
					Tattoshopprice[#Tattoshopprice+1] = {
						header = "["..(#Tattoshopprice+1).."] "..GetLabelText(tattoo.Name),
						txt = "$"..math.floor(tattoo.Price / 100),
						params = {
							event = "qb-tattoo:client:SetaCameraForSell",
							args = {db = tattoo, db2 = data},
						}
					}
				end
			end
		end
	end

	Tattoshopprice[#Tattoshopprice+1] = {
		header = "⬅ Leave Tatto Shop",
		txt = "",
		params = {
			event = "qb-menu:closeMenu",
		}
	}
	exports['qb-menu']:openMenu(Tattoshopprice)
end)

RegisterNetEvent('qb-tattoo:client:deletetattoo', function(data)
	Wait(100)
	if GetEntityModel(PlayerPedId()) == `mp_m_freemode_01` then
		RemoveTattoo(data.db.HashNameMale, data.db.Name)
	else
		RemoveTattoo(data.db.HashNameFemale, data.db.Name)
	end
end)

RegisterNetEvent('qb-tattoo:server:settattos', function(tattooList)
	ClearPedDecorations(PlayerPedId())
	if tattooList ~= nil then
		for k, v in pairs(tattooList) do
			SetPedDecoration(PlayerPedId(), v.collection, v.nameHash)
		end
		currentTattoos = tattooList
	end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(300000)
		if Logedin then
			QBCore.Functions.TriggerCallback('qb-tattooshop:GetPlayerTattoos', function(tattooList)
				if tattooList then
					ClearPedDecorations(PlayerPedId())
					for k, v in pairs(tattooList) do
						if v.Count ~= nil then
							for i = 1, v.Count do
								SetPedDecoration(PlayerPedId(), v.collection, v.nameHash)
							end
						else
							SetPedDecoration(PlayerPedId(), v.collection, v.nameHash)
						end
					end
					currentTattoos = tattooList
				end
			end)
		end
    end
end)

RegisterNetEvent('qb-tatto:client:ViewMode', function(data)
	view = not view
	TriggerEvent('qb-tattoo:client:OpenTattooMenu', data)
end)

RegisterNetEvent('qb-tatto:client:GoToMeno', function(data)

	ClearPedDecorations(PlayerPedId())
	if currentTattoos ~= nil then
		for k, v in pairs(currentTattoos) do
			if v.Count ~= nil then
				for i = 1, v.Count do
					SetPedDecoration(PlayerPedId(), v.collection, v.nameHash)
				end
			else
				SetPedDecoration(PlayerPedId(), v.collection, v.nameHash)
			end
		end
	end

	if DoesCamExist(cam) then
		DetachCam(cam)
		SetCamActive(cam, false)
		RenderScriptCams(false, false, 0, 1, 0)
		DestroyCam(cam, false)
	end

	local Tattoshoplocal = {
		{
			header = "Tattoo Shop",
			isMenuHeader = true
		},
	}
	for k, v in pairs(Config.TattooCats) do
		Tattoshoplocal[#Tattoshoplocal+1] = {
			header = v[2],
			txt = "Tattoo for "..v[2],
			params = {
				event = "qb-tattoo:client:OpenTattooMenu",
				args = v,
			}
		}
	end

	Tattoshoplocal[#Tattoshoplocal+1] = {
		header = "⬅ Leave Tatto Shop",
		txt = "",
		params = {
			event = "qb-menu:closeMenu",
		}
	}
	exports['qb-menu']:openMenu(Tattoshoplocal)
end)
