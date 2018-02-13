
AddCSLuaFile()

DEFINE_BASECLASS( "base_anim" )


ENT.PrintName = "Resizable Cube"
ENT.Author = "Jvs"

ENT.Editable = true
ENT.Spawnable = true

--Min and Max of the edit menu
ENT.MaxSize = 10
ENT.MinSize = 0.25


--ORIGINAL MASS IS 30
--ORIGINAL VOLUME IS 4766
ENT.Density = 0.0002 --used to calculate the weight of the physobj later on

--Hard scale for the base scale
ENT.HardMinSize = Vector( -25 , -25 , -25 )
ENT.HardMaxSize = Vector( 25 , 25 , 25 )


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
				min = self.MinSize, 
				max = self.MaxSize, 
				category = "Scale", 
				order = 1 
				}
		} )
		
	self:NetworkVar( "Float" , 1 , "ScaleY",
		{ 
			KeyName = "scaley" , 
			Edit = { 
				type = "Float", 
				min = self.MinSize, 
				max = self.MaxSize, 
				category = "Scale", 
				}
		} )
	self:NetworkVar( "Float" , 2 , "ScaleZ",
		{ 
			KeyName = "scalez" , 
			Edit = { 
				type = "Float", 
				min = self.MinSize, 
				max = self.MaxSize, 
				category = "Scale", 
				}
		} )

end

function ENT:Initialize()

	if SERVER then
		
		self:NetworkVarNotify( "ScaleX" , self.OnCubeSizeChanged )
		self:NetworkVarNotify( "ScaleY" , self.OnCubeSizeChanged )
		self:NetworkVarNotify( "ScaleZ" , self.OnCubeSizeChanged )
		
		self:SetCubeSize( Vector( 1 , 1 , 1 ) )
	end

	self:AddEffects( EF_NOSHADOW )
	self:UpdateSize()
	self:EnableCustomCollisions()
end


function ENT:SetCubeSize( vec )
	vec.x = math.Clamp( vec.x , self.MinSize , self.MaxSize )
	vec.y = math.Clamp( vec.y , self.MinSize , self.MaxSize )
	vec.z = math.Clamp( vec.z , self.MinSize , self.MaxSize )
	
	self:SetScaleX( vec.x )
	self:SetScaleY( vec.y )
	self:SetScaleZ( vec.z )
end

--TO BE RENAMED

function ENT:GetMin()
	return self.HardMinSize
end

function ENT:GetMax()
	return self.HardMaxSize
end

function ENT:GetCubeSize()
	return Vector( self:GetScaleX() , self:GetScaleY() , self:GetScaleZ() )
end

function ENT:GetScaledMin()
	return self:GetMin() * self:GetCubeSize()
end

function ENT:GetScaledMax()
	return self:GetMax() * self:GetCubeSize()
end

function ENT:OnCubeSizeChanged( varname , oldvalue , newvalue )
	self:UpdateSize()
end

function ENT:UpdateSize()
	if self:GetScaleX() == 0 or self:GetScaleY() == 0 or self:GetScaleZ() == 0 then
		return
	end

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
		self:CreateMesh()
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

if CLIENT then

	-- This is all going away when everything looks nicer
	local material = CreateMaterial( "Penis" .. CurTime(), "VertexLitGeneric", {
	["$basetexture"] =  "hunter/myplastic",
	["$halflambert"] = 	"1",
	} )

	function ENT:CreateMesh()
		if IsValid( self.Mesh ) then
			self.Mesh:Destroy()
		end

		self.Mesh = Mesh()

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

		local scale = self:GetScaledMax() - self:GetScaledMin()

		mesh.Begin( self.Mesh, MATERIAL_TRIANGLES, 12 )
		for i = 1, 6 do
			local normal = Vector( 0, 0, 0 )
			normal[ math.floor( ( i - 1 ) / 2 ) + 1 ] = ( bit.band( i - 1, 0x1 ) > 0 ) and 1 or -1

			for j = 2, 3 do
				mesh.Position( verts[indices[i][1]] * scale )
				mesh.TexCoord( 0, 0, 0 )
				mesh.Normal( normal )
				mesh.Color( 255, 255, 255, 255 )
				mesh.AdvanceVertex()
				mesh.Position( verts[indices[i][j+1]] * scale )
				mesh.TexCoord( 0, 1, j == 2 and 1 or 0 )
				mesh.Normal( normal )
				mesh.Color( 255, 255, 255, 255 )
				mesh.AdvanceVertex()
				mesh.Position( verts[indices[i][j]] * scale )
				mesh.TexCoord( 0, j == 2 and 0 or 1, 1 )
				mesh.Normal( normal )
				mesh.Color( 255, 255, 255, 255 )
				mesh.AdvanceVertex()
			end
		end
		mesh.End()
	end

	function ENT:GetRenderMesh()
		return { Mesh = self.Mesh, Material = material }
	end

end
