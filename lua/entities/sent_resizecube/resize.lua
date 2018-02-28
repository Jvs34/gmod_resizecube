-- very insecure
local FACE_FRONT  = 1
local FACE_BACK   = 2
local FACE_RIGHT  = 3
local FACE_LEFT   = 4
local FACE_TOP    = 5
local FACE_BOTTOM = 6

local CurrentCube;
local CurrentFace;
local CurrentEdge;

local Faces = 
{
	-- Front
	{
		DFunc = function(e) return e:GetScaleX() / 2 end,
		XFunc = function(e) return e:GetScaleY() end,
		YFunc = function(e) return e:GetScaleZ() end,
		ForwardFunc = function(e) return e:GetForward() end,
		UpFunc = function(e) return e:GetUp() end,
		RightFunc = function(e) return -e:GetRight() end,
		RotateTo2D = function(e, a)
			a:RotateAroundAxis( e:GetUp(), 90 )
			a:RotateAroundAxis( e:GetRight(), 90 )
		end,
		FaceUp = FACE_TOP,
		FaceRight = FACE_LEFT,
		FaceLeft = FACE_RIGHT,
		FaceDown = FACE_BOTTOM,
	},

	-- Back
	{
		DFunc = function(e) return e:GetScaleX() / 2 end,
		XFunc = function(e) return e:GetScaleY() end,
		YFunc = function(e) return e:GetScaleZ() end,
		ForwardFunc = function(e) return -e:GetForward() end,
		UpFunc = function(e) return e:GetUp() end,
		RightFunc = function(e) return e:GetRight() end,
		RotateTo2D = function(e, a)
			a:RotateAroundAxis( e:GetUp(), 90 )
			a:RotateAroundAxis( e:GetRight(), 90 )
		end,
		FaceUp = FACE_TOP,
		FaceRight = FACE_RIGHT,
		FaceLeft = FACE_LEFT,
		FaceDown = FACE_BOTTOM,
	},

	-- Right
	{
		DFunc = function(e) return e:GetScaleY() / 2 end,
		XFunc = function(e) return e:GetScaleX() end,
		YFunc = function(e) return e:GetScaleZ() end,
		ForwardFunc = function(e) return e:GetRight() end,
		UpFunc = function(e) return e:GetUp() end,
		RightFunc = function(e) return e:GetForward() end,
		RotateTo2D = function(e, a)
			a:RotateAroundAxis( e:GetForward(), 90 )
		end,
		FaceUp = FACE_TOP,
		FaceRight = FACE_FRONT,
		FaceLeft = FACE_BACK,
		FaceDown = FACE_BOTTOM,
	},

	-- Left
	{
		DFunc = function(e) return e:GetScaleY() / 2 end,
		XFunc = function(e) return e:GetScaleX() end,
		YFunc = function(e) return e:GetScaleZ() end,
		ForwardFunc = function(e) return -e:GetRight() end,
		UpFunc = function(e) return e:GetUp() end,
		RightFunc = function(e) return -e:GetForward() end,
		RotateTo2D = function(e, a)
			a:RotateAroundAxis( e:GetForward(), 90 )
		end,
		FaceUp = FACE_TOP,
		FaceRight = FACE_BACK,
		FaceLeft = FACE_FRONT,
		FaceDown = FACE_BOTTOM,
	},

	-- Top
	{
		DFunc = function(e) return e:GetScaleZ() / 2 end,
		XFunc = function(e) return e:GetScaleX() end,
		YFunc = function(e) return e:GetScaleY() end,
		ForwardFunc = function(e) return e:GetUp() end,
		UpFunc = function(e) return e:GetForward() end,
		RightFunc = function(e) return e:GetRight() end,
		RotateTo2D = function(e, a)
			--a:RotateAroundAxis( e:GetForward(), 90 )
		end,
		FaceUp = FACE_FRONT,
		FaceRight = FACE_RIGHT,
		FaceLeft = FACE_LEFT,
		FaceDown = FACE_BACK,
	},

	-- Bototm
	{
		DFunc = function(e) return e:GetScaleZ() / 2 end,
		XFunc = function(e) return e:GetScaleX() end,
		YFunc = function(e) return e:GetScaleY() end,
		ForwardFunc = function(e) return -e:GetUp() end,
		UpFunc = function(e) return e:GetForward() end,
		RightFunc = function(e) return e:GetRight() end,
		RotateTo2D = function(e, a)
			--a:RotateAroundAxis( e:GetForward(), 90 )
		end,
		FaceUp = FACE_FRONT,
		FaceRight = FACE_RIGHT,
		FaceLeft = FACE_LEFT,
		FaceDown = FACE_BACK,
	},
}

function ENT:Draw()
	self:DrawModel()

	if CurrentCube == self and CurrentFace and CurrentEdge then
		local firstF = Faces[CurrentFace]
		local secondF = Faces[CurrentEdge]

		debugoverlay.Line( self:GetPos() + firstF.ForwardFunc( self ) * firstF.DFunc( self ) * self:GetScaleMultiplierValue() * 2, self:GetPos() + secondF.ForwardFunc( self ) * secondF.DFunc( self ) * self:GetScaleMultiplierValue() * 2, 0.1, Color( 0, 255, 0 ) )
	end
end


--[[
-- face: depth, x, y, direction
local faces = {
   { "GetScaleY", "GetScaleX", "GetScaleZ", "GetRight", 1,
	function( ent, ang )
		ang:RotateAroundAxis( ent:GetForward(), 90 )
	end
   },

   { "GetScaleX", "GetScaleY", "GetScaleZ", "GetForward", 1,
	function( ent, ang )
		ang:RotateAroundAxis( ent:GetUp(), 90 )
		ang:RotateAroundAxis( ent:GetRight(), -90 )
	end
   },
   { "GetScaleZ", "GetScaleY", "GetScaleX", "GetUp", 1,
	function( ent, ang )
		ang:RotateAroundAxis( ent:GetUp(), 90 )
		ang:RotateAroundAxis( ent:GetRight(), -90 )
	end
   },
   --{ "GetScaleY", "GetScaleX", "GetScaleZ", "GetRight", -1, "GetUp", 90 },
   --{ "GetScaleX", "GetScaleY", "GetScaleZ", "GetForward", -1, "GetUp", 0 },
   --{ "GetScaleZ", "GetScaleY", "GetScaleX", "GetUp", -1, "GetRight", -90 },
}
]]

if CLIENT then

	hook.Add( "Think", "sent_resizecube", function()
		if LocalPlayer():KeyDown( IN_ATTACK2 ) then
			if not CurrentCube then return end

			net.Start( "sent_resizecube", true )
				net.WriteEntity( CurrentCube )
				net.WriteUInt( CurrentFace, 3 )
				net.WriteUInt( CurrentEdge, 3 )
			net.SendToServer()
			return
		end

		CurrentCube = nil
		CurrentFace = nil
		CurrentEdge = nil

		local cube = LocalPlayer():GetEyeTrace().Entity

		if not IsValid( cube ) or cube:GetClass() ~= "sent_resizecube" then
			return
		end

		for k, v in ipairs( Faces ) do
			local D = v.DFunc( cube ) * cube:GetScaleMultiplierValue()
			local X = v.XFunc( cube ) * cube:GetScaleMultiplierValue()
			local Y = v.YFunc( cube ) * cube:GetScaleMultiplierValue()
			local d = v.ForwardFunc( cube )

			if d:Dot( LocalPlayer():GetAimVector() ) > 0 then
				continue
			end

			local planeCenter = cube:GetPos() + d * D

			debugoverlay.Cross( planeCenter, 4, 0.1, Color( 255, 0, 0 ) )

			local hit = util.IntersectRayWithPlane( LocalPlayer():GetShootPos(), LocalPlayer():GetAimVector(), planeCenter, d )

			if not hit then
				continue
			end

			-- This can be done without dumbAngle or WorldToLocal
			-- It's just checking if we're aiming near an edge of the face
			do
				local dumbAngle = cube:GetAngles()
				v.RotateTo2D( cube, dumbAngle )

				local localHit = WorldToLocal( hit, angle_zero, planeCenter, dumbAngle )

				local xInset = X / 2 - math.abs( localHit.x )
				local yInset = Y / 2 - math.abs( localHit.y )

				if xInset < 0 or yInset < 0 then
					continue
				end

				local xGood = xInset > 4 and yInset < 5
				local yGood = yInset > 4 and xInset < 5

				if not ( xGood and not yGood ) and not ( yGood and not xGood ) then
					-- We know we're at least on the face, so we can skip testing other faces
					break
				end
			end

			CurrentCube = cube
			CurrentFace = k

			local up = v.UpFunc( cube )
			local right = v.RightFunc( cube )

			local hitToPlane = hit - planeCenter
			hitToPlane:Normalize()

			local upRot = math.acos( up:Dot( hitToPlane ) )
			local rightRot = math.acos( right:Dot( hitToPlane ) )
			local deg45 = math.pi / 4
			local deg135 = 3 * math.pi / 4

			if upRot <= deg45 then
				CurrentEdge = Faces[CurrentFace].FaceUp
			elseif upRot >= deg135 then
				CurrentEdge = Faces[CurrentFace].FaceDown
			elseif rightRot <= deg45 then
				CurrentEdge = Faces[CurrentFace].FaceRight
			elseif rightRot >= deg135 then
				CurrentEdge = Faces[CurrentFace].FaceLeft
			end

--			assert( CurrentEdge ~= nil )

			render.DrawLine( hit, hit + d * 4, Color( 0, 255, 0 ) )
			break
		end
	end )

else

	util.AddNetworkString( "sent_resizecube" )

	net.Receive( "sent_resizecube", function( _, ply )
		local cube = net.ReadEntity()

		if not IsValid( cube ) then
			ply.CurrentCube = nil
			return
		end

		if cube:GetClass() ~= "sent_resizecube" then
			return
		end

		local face = net.ReadUInt( 3 )
		local edge = net.ReadUInt( 3 )

		ply.CurrentCube = cube
		cube.CurrentPlayer = ply
		cube.CurrentFace = face
		cube.CurrentEdge = edge
	end )

	function ENT:DoResize()

	end

end