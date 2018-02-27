AddCSLuaFile()

properties.Add( "resizecube_startresize" ,
	{
		MenuLabel = "Resize",
		Order = 700,
		MenuIcon = "icon16/vector.png",
		
		Filter = function( self , ent , ply )
			if not gamemode.Call( "CanProperty" , ply , "resizecube_resize" , ent ) then
				return false
			end
			
			if ent:GetClass() ~= "sent_resizecube" then
				return false
			end

			--find out if we have resize set to true and the player is this one
			return not ent:GetIsEditing()
		end,

		Action = function( self , ent )
			self:MsgStart()
				net.WriteEntity( ent )
			self:MsgEnd()
		end,
		
		Receive = function( self , len , ply )
			local ent = net.ReadEntity()
			if not IsValid( ent ) or not self:Filter( ent , ply ) then
				return
			end

			ent:SetIsEditing( true )
			ent:SetEditingPlayer( ply )
			--setresize true and setresize player to this one

		end
	}
)

properties.Add( "resizecube_endresize" ,
	{
		MenuLabel = "Stop resizing",
		Order = 700,
		MenuIcon = "icon16/vector.png",
		
		Filter = function( self , ent , ply )
			if ent:GetClass() ~= "sent_resizecube" then
				return false
			end

			return ent:GetIsEditing()
		end,

		Action = function( self , ent )
			self:MsgStart()
				net.WriteEntity( ent )
			self:MsgEnd()
		end,
		
		Receive = function( self , len , ply )
			local ent = net.ReadEntity()
			if not IsValid( ent ) or not self:Filter( ent , ply ) then
				return
			end

			--set resize to false and current resizing player to NULL
		end
	}
)