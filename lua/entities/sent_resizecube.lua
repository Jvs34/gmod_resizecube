
AddCSLuaFile()

DEFINE_BASECLASS( "base_anim" )


ENT.PrintName = "Resizable Cube"
ENT.Author = "Jvs"

ENT.Editable = true
ENT.Spawnable = true

--Min and Max of the edit menu
ENT.MaxEditScale = 10
ENT.MinEditScale = 0.25

--ORIGINAL MASS IS 30
--ORIGINAL VOLUME IS 4766
ENT.Density = 0.0002 --used to calculate the weight of the physobj later on

--Hard scale for the base scale

AccessorFunc( ENT , "HardMinSize" , "MinSize" )
AccessorFunc( ENT , "HardMaxSize" , "MaxSize" )

if CLIENT then
	AccessorFunc( ENT , "LastUpdateCheck" , "LastUpdateCheck" )
end

function ENT:SpawnFunction( ply , tr , ClassName )
	
	local ent = ents.Create( ClassName )
	ent:SetPos( tr.HitPos + tr.HitNormal * 100 )
	ent:Spawn()
	return ent
end

function ENT:SetupDataTables()
	self:NetworkVar( "Float" , 0 , "ScaleX", 
		{ 
			KeyName = "scalex" , 
			Edit = { 
				type = "Float", 
				min = self.MinEditScale, 
				max = self.MaxEditScale, 
				category = "Scale", 
				order = 1 
				}
		} )
		
	self:NetworkVar( "Float" , 1 , "ScaleY",
		{ 
			KeyName = "scaley" , 
			Edit = { 
				type = "Float", 
				min = self.MinEditScale, 
				max = self.MaxEditScale, 
				category = "Scale", 
				}
		} )
	self:NetworkVar( "Float" , 2 , "ScaleZ",
		{ 
			KeyName = "scalez" , 
			Edit = { 
				type = "Float", 
				min = self.MinEditScale, 
				max = self.MaxEditScale, 
				category = "Scale", 
				}
		} )

end

function ENT:Initialize()
	self:SetMinSize( Vector( -25 , -25 , -25 ) )
	self:SetMaxSize( Vector( 25 , 25 , 25 ) )
	
	if SERVER then
		
		self:NetworkVarNotify( "ScaleX" , self.OnCubeSizeChanged )
		self:NetworkVarNotify( "ScaleY" , self.OnCubeSizeChanged )
		self:NetworkVarNotify( "ScaleZ" , self.OnCubeSizeChanged )
		
		self:SetModel "models/hunter/blocks/cube025x025x025.mdl"
		self:SetCubeSize( Vector( 1 , 1 , 1 ) )
	end

	self:UpdateSize()
	self:EnableCustomCollisions()
end


function ENT:SetCubeSize( vec )
	vec.x = math.Clamp( vec.x , self.MinEditScale , self.MaxEditScale )
	vec.y = math.Clamp( vec.y , self.MinEditScale , self.MaxEditScale )
	vec.z = math.Clamp( vec.z , self.MinEditScale , self.MaxEditScale )
	
	self:SetScaleX( vec.x )
	self:SetScaleY( vec.y )
	self:SetScaleZ( vec.z )
end

function ENT:GetCubeSize()
	return Vector( self:GetScaleX() , self:GetScaleY() , self:GetScaleZ() )
end

function ENT:GetScaledMin()
	return self:GetMinSize() * self:GetCubeSize()
end

function ENT:GetScaledMax()
	return self:GetMaxSize() * self:GetCubeSize()
end

function ENT:OnCubeSizeChanged( varname , oldvalue , newvalue )
	if newvalue == 0 then
		return
	end

	if self:GetScaleX() ~= 0 and self:GetScaleY() ~= 0 and self:GetScaleZ() ~= 0 then
		self:UpdateSize()
	end
	
end

function ENT:UpdateSize()
	
	if SERVER then
		local savedproperties = nil
		
		local phys = self:GetPhysicsObject()
		
		if IsValid( phys ) then
			savedproperties = 
			{
				velocity = phys:GetVelocity(),
				ang = phys:GetAngles(),
				pos = phys:GetPos(),
				motion = phys:IsMotionEnabled(),
				angvel = phys:GetAngleVelocity()
			}
		end
		
		self:PhysicsInitBox( self:GetScaledMin(), self:GetScaledMax() )
		self:SetSolid( SOLID_VPHYSICS )

		local newphys = self:GetPhysicsObject()

		if IsValid( newphys ) then
			newphys:SetMass( newphys:GetVolume() * self.Density )
			newphys:SetMaterial( "metal" )
			
			if savedproperties then
				newphys:SetPos( savedproperties.pos )
				newphys:SetVelocity( savedproperties.velocity )
				newphys:SetAngles( savedproperties.ang )
				newphys:EnableMotion( savedproperties.motion )
				newphys:AddAngleVelocity( savedproperties.angvel )
			end
			
		end
	end

	if CLIENT then
		self:SetRenderBounds( self:GetScaledMin() , self:GetScaledMax() )
	end

	if IsValid( self.PhysCollide ) then
		self.PhysCollide:Destroy()
	end

	self.PhysCollide = CreatePhysCollideBox( self:GetScaledMin(), self:GetScaledMax() )

	-- TODO: This happens when we're making something with 0 height/width/depth, make it not happen
	if not IsValid( self.PhysCollide ) then print "fuck" end

	self:SetCollisionBounds( self:GetScaledMin() , self:GetScaledMax() )
end

function ENT:OnTakeDamage( dmginfo )
	self:TakePhysicsDamage( dmginfo )
end

function ENT:TestCollision( startpos , delta , isbox , extents )
	if not IsValid( self.PhysCollide ) then
		return
	end

	-- TODO: Investigate this under `IntersectRayWithBox`
	local min = -extents
	local max = extents
	max.z = max.z - min.z
	min.z = 0
	
	local hit, norm, frac = self.PhysCollide:TraceBox( self:GetPos(), self:GetAngles(), startpos, startpos + delta, min, max )

	if not hit then
		return
	end

	return 
	{ 
		HitPos = hit,
		Normal  = norm,
		Fraction = frac,
	}
end

function ENT:Think()
	-- Things like the Gravity Gun might disable this, so keep it active.
	self:EnableCustomCollisions()

	-- TODO: Only update client when the size has actually changed
	if CLIENT then
		self:UpdateSize()
	end

	self:NextThink( CurTime() )
end

function ENT:OnRemove()
	if IsValid( self.PhysCollide ) then
		self.PhysCollide:Destroy()
	end
end

if SERVER then
		
	function ENT:OnDuplicated( sourcetab )
		self:UpdateSize()
	end

else

	-- This is all going away when everything looks nicer
	local material = CreateMaterial( "Peniasaa" .. CurTime(), "VertexLitGeneric", {
		["$basetexture"] = "hunter/myplastic",
		["$surfaceprop"] = "tile",
		["$halflambert"] = "1"
	} )

	local myMesh = Mesh()

	do
		local verts = {
			Vector(-0.5, -0.5, -0.5),
			Vector(0.5, -0.5, -0.5),
			Vector(-0.5, 0.5, -0.5),
			Vector(0.5, 0.5, -0.5),
			Vector(-0.5, -0.5, 0.5),
			Vector(0.5, -0.5, 0.5),
			Vector(-0.5, 0.5, 0.5),
			Vector(0.5, 0.5, 0.5),
		};

		local indices = {
			{ 1, 5, 7, 3 },
			{ 6, 2, 4, 8 },
			{ 1, 2, 6, 5 },
			{ 3, 7, 8, 4 },
			{ 1, 3, 4, 2 },
			{ 5, 6, 8, 7 },
		};

		mesh.Begin( myMesh, MATERIAL_TRIANGLES, 12 )
		for i = 1, 6 do
			local normal = Vector( 0, 0, 0 )
			normal[ math.floor( ( i - 1 ) / 2 ) + 1 ] = ( bit.band( i - 1, 0x1 ) > 0 ) and 1 or -1

			for j = 2, 3 do
				mesh.Position( verts[indices[i][1]] )
				mesh.TexCoord( 0, 0, 0 )
				mesh.Normal( normal )
				mesh.Color( 255, 255, 255, 255 )
				mesh.AdvanceVertex()
				mesh.Position( verts[indices[i][j+1]] )
				mesh.TexCoord( 0, 1, j == 2 and 1 or 0 )
				mesh.Normal( normal )
				mesh.Color( 255, 255, 255, 255 )
				mesh.AdvanceVertex()
				mesh.Position( verts[indices[i][j]] )
				mesh.TexCoord( 0, j == 2 and 0 or 1, 1 )
				mesh.Normal( normal )
				mesh.Color( 255, 255, 255, 255 )
				mesh.AdvanceVertex()
			end
		end
		mesh.End()
	end

	function ENT:Draw( flags )
		
		if bit.band( flags, STUDIO_SHADOWDEPTHTEXTURE ) == 0 and halo.RenderedEntity() ~= self then
			render.SetBlend( 0 )
			self:DrawModel()
			render.SetBlend( 1 )
		end

		local mat = Matrix()
		mat:Translate( self:GetPos() )
		mat:Rotate( self:GetAngles() )
		mat:Scale( self:GetMaxSize() - self:GetMinSize() )
		mat:Scale( self:GetCubeSize() )
		
		cam.PushModelMatrix( mat )
			render.SetMaterial( material )

			myMesh:Draw()
			--[[
			render.PushFlashlightMode( true )
			myMesh:Draw()
			render.PopFlashlightMode()
			]]
		cam.PopModelMatrix()

	end

end
