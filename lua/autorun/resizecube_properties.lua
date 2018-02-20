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

			return ents.FindByClassAndParent( "widget_resizecube" , ent ) == nil
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

			local widget = ents.Create( "widget_resizecube" )
			widget:Setup( ent , 0 )
			widget:Spawn()
			
			ent:SetWidget( widget )

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

			return IsValid( ent:GetWidget() ) and ent:GetWidget():GetClass() == "widget_resizecube"
		end,

		Action = function( self , ent )
			self:MsgStart()
				net.WriteEntity( ent )
			self:MsgEnd()
		end,
		
		Receive = function( self , len , ply )
			local ent = net.ReadEntity()
			if not IsValid( ent ) or not self:Filter( ent , ply ) or not IsValid( ent:GetWidget() ) then
				return
			end
			
			ent:GetWidget():Remove()
			ent:SetWidget( NULL )
		end
	}
)