ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

local Webhook = 'https://discord.com/api/webhooks/875803972366135356/xtn1ITixwzPB3Dt6xFqbEWQPhuJHz7mBQ7KDfkDEhJ37nHgs6RVW7xQZACtGN9y-en2C'

RegisterServerEvent('nsContract:changeVehicleOwner')
AddEventHandler('nsContract:changeVehicleOwner', function(data)
	_source = data.sourceIDSeller
	target = data.targetIDSeller
	plate = data.plateNumberSeller
	model = data.modelSeller
	source_name = data.sourceNameSeller
	target_name = data.targetNameSeller
	vehicle_price = tonumber(data.vehicle_price)

	local xPlayer = ESX.GetPlayerFromId(_source)
	local tPlayer = ESX.GetPlayerFromId(target)
	local webhookData = {
		model = model,
		plate = plate,
		target_name = target_name,
		source_name = source_name,
		vehicle_price = vehicle_price
	}
	local result = MySQL.Sync.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @identifier AND plate = @plate', {
		['@identifier'] = xPlayer.identifier,
		['@plate'] = plate
	})

	if Config.RemoveMoneyOnSign then
		local bankMoney = tPlayer.getAccount('bank').money

		if result[1] ~= nil  then
			if bankMoney >= vehicle_price then
				MySQL.Async.execute('UPDATE owned_vehicles SET owner = @target WHERE owner = @owner AND plate = @plate', {
					['@owner'] = xPlayer.identifier,
					['@target'] = tPlayer.identifier,
					['@plate'] = plate
				}, function (result2)
					if result2 ~= 0 then	
						tPlayer.removeAccountMoney('bank', vehicle_price)
						xPlayer.addAccountMoney('bank', vehicle_price)

						TriggerClientEvent('notify:Alert', _source, "VEHICLE", "Právě si prodal vozidlo <b>"..model.."</b> s SPZ <b>"..plate.."</b>", 10000, 'success')
						TriggerClientEvent('notify:Alert', target, "VEHICLE", "Právě si koupil vozidlo <b>"..model.."</b> s SPZ <b>"..plate.."</b>", 10000, 'success')

						if Webhook ~= '' then
							sellVehicleWebhook(webhookData)
						end
					end
				end)
			else
				TriggerClientEvent('notify:Alert', _source, "VEHICLE", target_name.." nemá dostatek peněz ke koupi tvého vozidla", 10000, 'error')
				TriggerClientEvent('notify:Alert', target, "VEHICLE", "Nemáš dostatek peněz ke koupi vozidla majitele "..source_name, 10000, 'error')
			end
		else
			TriggerClientEvent('notify:Alert', _source, "VEHICLE", "Vozidlo s SPZ<b> "..plate.."</b> není tvoje", 10000, 'error')
			TriggerClientEvent('notify:Alert', target, "VEHICLE", source_name.." se ti pokusil prodat vozidlo, které nevlastní", 10000, 'error')
		end
	else
		if result[1] ~= nil then
			MySQL.Async.execute('UPDATE owned_vehicles SET owner = @target WHERE owner = @owner AND plate = @plate', {
				['@owner'] = xPlayer.identifier,
				['@target'] = tPlayer.identifier,
				['@plate'] = plate
			}, function (result2)
				if result2 ~= 0 then
					TriggerClientEvent('notify:Alert', _source, "VEHICLE", "Právě si prodal vozidlo <b>"..model.."</b> s SPZ <b>"..plate.."</b>", 10000, 'success')
					TriggerClientEvent('notify:Alert', target, "VEHICLE", "Právě si koupil vozidlo <b>"..model.."</b> s SPZ <b>"..plate.."</b>", 10000, 'success')


					if Webhook ~= '' then
						sellVehicleWebhook(webhookData)
					end
				end
			end)
		else
			TriggerClientEvent('notify:Alert', _source, "VEHICLE", "Vozidlo s SPZ<b> "..plate.."</b> není tvoje", 10000, 'error')
			TriggerClientEvent('notify:Alert', target, "VEHICLE", source_name.." se ti pokusil prodat vozidlo, které nevlastní", 10000, 'error')
		end
	end
end)

ESX.RegisterServerCallback('nsContract:GetTargetName', function(source, cb, targetid)
	local target = ESX.GetPlayerFromId(targetid)
	local targetname = target.getName()

	cb(targetname)
end)

RegisterServerEvent('nsContract:SendVehicleInfo')
AddEventHandler('nsContract:SendVehicleInfo', function(description, price)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)

	TriggerClientEvent('nsContract:GetVehicleInfo', _source, xPlayer.getName(), os.date(Config.DateFormat), description, price, _source)
end)

RegisterServerEvent('nsContract:SendContractToBuyer')
AddEventHandler('nsContract:SendContractToBuyer', function(data)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)

	TriggerClientEvent("nsContract:OpenContractOnBuyer", data.targetID, data)
	TriggerClientEvent('nsContract:startContractAnimation', data.targetID)

	if Config.RemoveContractAfterUse then
		xPlayer.removeInventoryItem('contract', 1)
	end
end)

--[[ESX.RegisterUsableItem('contract', function(source)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)

	TriggerClientEvent('nsContract:OpenContractInfo', _source)
	TriggerClientEvent('nsContract:startContractAnimation', _source)
end)]]

-------------------------- SELL VEHICLE WEBHOOK

function sellVehicleWebhook(data)
	local information = {
		{
			["color"] = Config.sellVehicleWebhookColor,
			["author"] = {
				["icon_url"] = Config.IconURL,
				["name"] = Config.ServerName..' - Logs',
			},
			["title"] = 'VEHICLE SALE',
			["description"] = '**Vehicle: **'..data.model..'**\nPlate: **'..data.plate..'**\nBuyer name: **'..data.target_name..'**\nSeller name: **'..data.source_name..'**\nPrice: **'..data.vehicle_price..'$',

			["footer"] = {
				["text"] = os.date(Config.WebhookDateFormat),
			}
		}
	}
	PerformHttpRequest(Webhook, function(err, text, headers) end, 'POST', json.encode({username = Config.BotName, embeds = information}), {['Content-Type'] = 'application/json'})
end