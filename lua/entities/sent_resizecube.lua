
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
		self:UpdateSize()
	else
		self:SetSolid( SOLID_CUSTOM )
	end
	
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
	
	
	self:PhysicsInitBox( self:GetScaledMin() , self:GetScaledMax() )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetCollisionBounds( self:GetScaledMin() , self:GetScaledMax() )
	
	
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

function ENT:OnTakeDamage( dmginfo )
	self:TakePhysicsDamage( dmginfo )
end

function ENT:IntersectHullTraceWithBox( startpos , delta , extents )
	local vecexpandedmins = self:GetScaledMin() - extents
	local vecexpandedmaxs = self:GetScaledMax() + extents
	
	local hit , norm , fraction = util.IntersectRayWithOBB( startpos , delta , self:GetPos() , self:GetAngles(), vecexpandedmins , vecexpandedmaxs )
	
	
	
	
	return hit , norm , fraction
end


function ENT:TestCollision( startpos , delta , isbox , extents )
	
	if isbox then
		
		--TODO
		local bmin = extents * -1
		local bmax = extents
		
		local pos = startpos + delta + Vector( 0 , 0 , bmax.z )
		local ang = angle_zero
		
		
		--[[
		math.randomseed( startpos.z * 200 )

        debugoverlay.BoxAngles( self:GetPos(), self:GetScaledMin(), self:GetScaledMax(), self:GetAngles(), 0.1, Color( 255, 0, 0, 20 ) )
        debugoverlay.BoxAngles( startpos , -extents , extents , angle_zero , 0.1 , Color( math.random( 20, 250 ) , math.random( 20, 250 ) , math.random( 20, 250 ) , 1 ) )
		]]
		--debugoverlay.BoxAngles( pos , bmin , bmax , ang , 0.1 , Color( 255 , 255 , 0 , 20 ) )
		
		
			
		local hit , norm , fraction = self:IntersectHullTraceWithBox( startpos , delta , extents )
		
		if not hit then 
			return 
		end
		
		debugoverlay.BoxAngles( hit , bmin , bmax , angle_zero , 0.1 , Color( 255 , 255 , 0 , 20 ) )
		
		return 
		{ 
			HitPos = hit,
			Normal 	= norm,
			Fraction = fraction,
		}
		
	else
	
		local hit , norm , fraction = util.IntersectRayWithOBB( startpos , delta , self:GetPos() , self:GetAngles() , self:GetScaledMin() , self:GetScaledMax() )
		
		if not hit then 
			return 
		end
		
		return 
		{ 
			HitPos = hit,
			Normal 	= norm,
			Fraction = fraction,
		}
	end
end


function ENT:Think()
	if SERVER then
		
	else
		self:SetRenderBounds( self:GetScaledMin() , self:GetScaledMax())
	end
	
	self:SetCollisionBounds( self:GetScaledMin() , self:GetScaledMax() )

end

function ENT:OnRemove()

end



if SERVER then

else

	function ENT:Draw()
		
		local mat = Matrix()
		mat:Scale( self:GetCubeSize() )
		
		
		self:EnableMatrix( "RenderMultiply",mat)
		self:DrawModel()
		
	end

end