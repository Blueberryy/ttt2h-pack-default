if SERVER then
	resource.AddFile("materials/vgui/ttt/heroes/frost_overlay.vmt")

	util.AddNetworkString("TTTHFrost")
end

local frostRad = 320

local function PrepareFrostActivation(ply)
	if CLIENT then
		hook.Add("PostDrawTranslucentRenderables", "TTTHFrostPreview", function()
			if LocalPlayer() == ply then
				local et = ply:GetEyeTrace()

				render.SetColorMaterial()
				render.DrawWireframeSphere(et.HitPos, frostRad, 30, 30, Color(0, 255, 255, 100), true)
			end
		end)
	end
end

local function FinishFrostPreparing(ply)
	if CLIENT then
		hook.Remove("PostDrawTranslucentRenderables", "TTTHFrostPreview")
	end
end

local function ActivateFrost(ply)
	if SERVER then
		local pos = ply:GetEyeTrace().HitPos

		hook.Add("TTTPlayerSpeedModifier", "TTTHFrostSpeed" .. ply:UniqueID(), function(pl, _, _, noLag)
			if pl == ply then return end

			local entities = ents.FindInSphere(pos, frostRad)

			for _, v in ipairs(entities) do
				if v == pl then
					noLag[1] = noLag[1] * 0.5
				end
			end
		end)

		net.Start("TTTHFrost")
		net.WriteBit(true)
		net.WriteVector(pos)
		net.WriteUInt(frostRad, 32)
		net.Broadcast()
	end
end

local function DeactivateFrost(ply)
	if SERVER then
		hook.Remove("TTTPlayerSpeedModifier", "TTTHFrostSpeed" .. ply:UniqueID())

		net.Start("TTTHFrost")
		net.WriteBit(false)
		net.Broadcast()
	end
end

HEROES.AddHero("FROST", {
		color = Color(0, 156, 156, 255),
		onPrepareActivation = PrepareFrostActivation,
		onFinishPreparingActivation = FinishFrostPreparing,
		onActivate = ActivateFrost,
		onDeactivate = DeactivateFrost,
		avoidWeaponReset = true,
		time = 10,
		cooldown = 60,
		langs = {
			English = "Frost"
		}
})

if CLIENT then
	local frostMaterial = Material("models/props_c17/frostedglass_01a")

	net.Receive("TTTHFrost", function()
		local client = LocalPlayer()

		if net.ReadBit() == 1 then
			client.ttthfrostindicator = true

			local pos = net.ReadVector()

			hook.Add("PostDrawTranslucentRenderables", "TTTHFrost", function(bDepth, bSkybox)
				if bSkybox then return end

				if client.ttthfrostindicator then
					local entities = ents.FindInSphere(pos, frostRad)
					local selected = false

					for _, v in ipairs(entities) do
						if v == client then
							selected = true

							break
						end
					end

					if not selected then
						render.SetMaterial(frostMaterial)
						render.CullMode(MATERIAL_CULLMODE_CCW)
						render.DrawSphere(pos, frostRad, 30, 30, Color(255, 255, 255, 210))
					else
						render.SetColorMaterial()
						render.CullMode(MATERIAL_CULLMODE_CW)
						render.DrawSphere(pos, frostRad, 30, 30, Color(255, 255, 255, 20))
						render.CullMode(MATERIAL_CULLMODE_CCW)
					end
				end
			end)

			hook.Add("RenderScreenspaceEffects", "TTTHFrostOverlay", function()
				if client.ttthfrostindicator and not client:IsHero(HEROES.HEROES.FROST.index) then
					local entities = ents.FindInSphere(pos, frostRad)
					local selected = false

					for _, v in ipairs(entities) do
						if v == client then
							selected = true

							break
						end
					end

					if selected then
						DrawMaterialOverlay("vgui/ttt/heroes/frost_overlay", 0)
					end
				end
			end)

			sound.Play("ambient/wind/windgust_strong.wav", pos)
		else
			client.ttthfrostindicator = nil

			hook.Remove("PostDrawTranslucentRenderables", "TTTHFrost")
			hook.Remove("RenderScreenspaceEffects", "TTTHFrostOverlay")
		end
	end)
end