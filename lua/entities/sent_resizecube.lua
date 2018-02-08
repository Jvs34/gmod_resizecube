
AddCSLuaFile()

DEFINE_BASECLASS( "base_anim" )


ENT.PrintName = "Resizable Cube"
ENT.Author = "Jvs"

ENT.Editable = true
ENT.Spawnable = true

ENT.MaxSize = 10
ENT.MinSize = 0.25
ENT.Density = 0.0002

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
	
	self:NetworkVar( "Vector" , 0 , "Min" )
	self:NetworkVar( "Vector" , 1 , "Max" )
	
end

function ENT:Initialize()

	if SERVER then
		--ORIGINAL MASS IS 30
		--ORIGINAL VOLUME IS 4766
		
		self:NetworkVarNotify( "ScaleX" , self.OnCubeSizeChanged )
		self:NetworkVarNotify( "ScaleY" , self.OnCubeSizeChanged )
		self:NetworkVarNotify( "ScaleZ" , self.OnCubeSizeChanged )
		
		
		self:SetModel( "models/xqm/boxfull.mdl" )
		local mmin , mmax = self:GetModelBounds()
		self:SetMin( mmin )
		self:SetMax( mmax )
		
		self:SetCubeSize( Vector( 1 , 1 , 1 ) )
	end

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
		self:SetRenderBounds( self:GetScaledMin() , self:GetScaledMax())
	end

	if IsValid( self.PhysCollide ) then
		self.PhysCollide:Destroy()
	end

	self.PhysCollide = CreatePhysCollideBox( self:GetScaledMin(), self:GetScaledMax() )

	-- TODO: This happens when we're making something with 0 height/width/depth, make it not happen
	if ( !IsValid( self.PhysCollide ) ) then print "fuck" end

	self:SetCollisionBounds( self:GetScaledMin() , self:GetScaledMax() )
end

function ENT:OnTakeDamage( dmginfo )
	self:TakePhysicsDamage( dmginfo )
end

function ENT:TestCollision( startpos , delta , isbox , extents )
	if ( !IsValid( self.PhysCollide ) ) then
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

	function ENT:Draw()
		
		local mat = Matrix()
		mat:Scale( self:GetCubeSize() )
		
		
		self:EnableMatrix( "RenderMultiply",mat)
		self:DrawModel()
		
	end

end
