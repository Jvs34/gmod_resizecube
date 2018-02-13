
AddCSLuaFile()

DEFINE_BASECLASS( "base_anim" )


ENT.PrintName = "Resizable Cube"
ENT.Author = "Jvs"

ENT.Editable = true
ENT.Spawnable = true

ENT.RenderGroup = RENDERGROUP_BOTH

--Min and Max of the edit menu
ENT.MaxEditScale = 64
ENT.MinEditScale = 1

--ORIGINAL MASS IS 30
--ORIGINAL VOLUME IS 4766
ENT.Density = 0.0002 --used to calculate the weight of the physobj later on

--Hard scale for the base scale
ENT.ScaleMultipliers = {
	{
		title = "Default (10 to 1)",
		scale = 5
	},
	{
		title = "PHX",
		scale = 11.878124237060546875
	},
	{
		title = "Hammer Units (1 to 1)",
		scale = 1
	}
}


AccessorFunc( ENT , "HardMinSize" , "MinSize" )
AccessorFunc( ENT , "HardMaxSize" , "MaxSize" )
AccessorFunc( ENT , "PhysCollide" , "PhysCollide" )

if CLIENT then
	AccessorFunc( ENT , "LastScaleX" , "LastScaleX" )
	AccessorFunc( ENT , "LastScaleY" , "LastScaleY" )
	AccessorFunc( ENT , "LastScaleZ" , "LastScaleZ" )
	AccessorFunc( ENT , "LastScaleMultiplier" , "LastScaleMultiplier" )

	AccessorFunc( ENT , "IsGizmoActive" , "IsGizmoActive" )
end

function ENT:SpawnFunction( ply , tr , ClassName )
	
	local ent = ents.Create( ClassName )
	ent:SetPos( tr.HitPos + tr.HitNormal * 100 )
	ent:Spawn()
	return ent
end

function ENT:SetupDataTables()
	self:NetworkVar( "Int" , 0 , "ScaleX", 
		{ 
			KeyName = "scalex", 
			Edit = { 
				type = "Int", 
				min = self.MinEditScale, 
				max = self.MaxEditScale, 
				category = "Scale", 
				order = 1 
			}
	} )
		
	self:NetworkVar( "Int" , 1 , "ScaleY",
		{ 
			KeyName = "scaley", 
			Edit = { 
				type = "Int", 
				min = self.MinEditScale, 
				max = self.MaxEditScale, 
				category = "Scale", 
			}
	} )
	self:NetworkVar( "Int" , 2 , "ScaleZ",
		{ 
			KeyName = "scalez", 
			Edit = { 
				type = "Int", 
				min = self.MinEditScale, 
				max = self.MaxEditScale, 
				category = "Scale", 
			}
	} )
	
	local datatab = {}

	for i , v in pairs( self.ScaleMultipliers ) do
		datatab[v.title] = i
	end

	self:NetworkVar( "Int", 3 , "ScaleMultiplier",
		{
			KeyName = "scalemultiplier", 
			Edit = {
				title = "Coordinate System",
				type = "Combo",
				category = "Scale",
				values = datatab
			}
	} )
end

function ENT:Initialize()
	self:SetMinSize( Vector( -0.5 , -0.5 , -0.5 ) )
	self:SetMaxSize( Vector( 0.5 , 0.5 , 0.5 ) )
	
	if SERVER then
		self:NetworkVarNotify( "ScaleX" , self.OnCubeSizeChanged )
		self:NetworkVarNotify( "ScaleY" , self.OnCubeSizeChanged )
		self:NetworkVarNotify( "ScaleZ" , self.OnCubeSizeChanged )
		self:NetworkVarNotify( "ScaleMultiplier" , self.OnCubeSizeChanged )

		self:SetScaleMultiplier( 1 ) --use the first one by default
		self:SetCubeSize( Vector( 1 , 1 , 1 ) * self:GetScaleMultiplierValue() )
	else
		self:SetLastScaleX( 0 )
		self:SetLastScaleY( 0 )
		self:SetLastScaleZ( 0 )
		self:SetLastScaleMultiplier( 0 )
		self:SetIsGizmoActive( false )
	end

	self:AddEffects( EF_NOSHADOW )
	self:UpdateSize()
	self:EnableCustomCollisions()
end

function ENT:GetScaleMultiplierValue()
	local indx = self:GetScaleMultiplier()
	
	if self.ScaleMultipliers[indx] then
		return self.ScaleMultipliers[indx].scale
	end

	return 5
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
	return Vector( self:GetScaleX(), self:GetScaleY() , self:GetScaleZ() ) * self:GetScaleMultiplierValue()
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
		self:CreateMesh()
		self:SetRenderBounds( self:GetScaledMin() , self:GetScaledMax() )
	end

	if IsValid( self:GetPhysCollide() ) then
		self:GetPhysCollide():Destroy()
	end

	local physcollide = CreatePhysCollideBox( self:GetScaledMin(), self:GetScaledMax() )
	

	if not IsValid( physcollide ) then 
		print( "Physcollide somehow not created" ) 
	end

	self:SetPhysCollide( physcollide )

	self:SetCollisionBounds( self:GetScaledMin() , self:GetScaledMax() )
end

function ENT:OnTakeDamage( dmginfo )
	self:TakePhysicsDamage( dmginfo )
end

function ENT:TestCollision( startpos , delta , isbox , extents )
	if not IsValid( self:GetPhysCollide() ) then
		return
	end

	-- TODO: Investigate this under `IntersectRayWithBox`
	local min = -extents
	local max = extents
	max.z = max.z - min.z
	min.z = 0
	
	local hit, norm, frac = self:GetPhysCollide():TraceBox( self:GetPos(), self:GetAngles(), startpos, startpos + delta, min, max )

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

	if CLIENT then
		self:CheckUpdateSize()

		if self:GetIsGizmoActive() then
			self:UpdateResizeGizmo()
		end
	end

	self:NextThink( CurTime() )
end

function ENT:OnRemove()
	if IsValid( self:GetPhysCollide() ) then
		self:GetPhysCollide():Destroy()
	end
end

if SERVER then
	
	function ENT:OnEntityCopyTableFinish( savetab )
		savetab.PhysCollide = nil
	end

	function ENT:OnDuplicated( sourcetab )
		self:UpdateSize()
	end

else

	function ENT:CheckUpdateSize()
		local curx = self:GetScaleX()
		local cury = self:GetScaleY()
		local curz = self:GetScaleZ()
		local curmult = self:GetScaleMultiplier()

		local lastx = self:GetLastScaleX()
		local lasty = self:GetLastScaleY()
		local lastz = self:GetLastScaleZ()
		local lastmult = self:GetLastScaleMultiplier()

		if curx == 0 or cury == 0 or curz == 0 then
			return
		end

		if curx ~= lastx or cury ~= lasty or curz ~= lastz or curmult ~= lastmult then
			self:UpdateSize()

			self:SetLastScaleX( curx )
			self:SetLastScaleY( cury )
			self:SetLastScaleZ( curz )
			self:SetLastScaleMultiplier( curmult )
		end
	end

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
			Vector( -0.5, -0.5, -0.5 ),
			Vector(  0.5, -0.5, -0.5 ),
			Vector( -0.5,  0.5, -0.5 ),
			Vector(  0.5,  0.5, -0.5 ),
			Vector( -0.5, -0.5,  0.5 ),
			Vector(  0.5, -0.5,  0.5 ),
			Vector( -0.5,  0.5,  0.5 ),
			Vector(  0.5,  0.5,  0.5 ),
		};

		local indices = {
			{ 1, 5, 7, 3 }, -- Front
			{ 6, 2, 4, 8 }, -- Back
			{ 1, 2, 6, 5 }, -- Right
			{ 3, 7, 8, 4 }, -- Left
			{ 1, 3, 4, 2 }, -- Bottom
			{ 5, 6, 8, 7 }, -- Top
		};

		-- Todo: should not have to hardcode this so badly
		local x, y, z = self:GetScaleX() / 4, self:GetScaleY() / 4, self:GetScaleZ() / 4

		local uvs = {
			{ { { 0, 0 }, { y, z }, { 0, z } }, { { 0, 0 }, { y, 0 }, { y, z } } },
			{ { { 0, 0 }, { y, z }, { 0, z } }, { { 0, 0 }, { y, 0 }, { y, z } } },
			{ { { 0, 0 }, { z, x }, { 0, x } }, { { 0, 0 }, { z, 0 }, { z, x } } },
			{ { { 0, 0 }, { x, z }, { 0, z } }, { { 0, 0 }, { x, 0 }, { x, z } } },
			{ { { 0, 0 }, { x, y }, { 0, y } }, { { 0, 0 }, { x, 0 }, { x, y } } },
			{ { { 0, 0 }, { y, x }, { 0, x } }, { { 0, 0 }, { y, 0 }, { y, x } } },
		}

		local scale = self:GetScaledMax() - self:GetScaledMin()

		mesh.Begin( self.Mesh, MATERIAL_TRIANGLES, 12 )
		for i = 1, 6 do
			local normal = Vector( 0, 0, 0 )
			normal[ math.floor( ( i - 1 ) / 2 ) + 1 ] = ( bit.band( i - 1, 0x1 ) > 0 ) and 1 or -1

			for j = 2, 3 do
				mesh.Position( verts[indices[i][1]] * scale )
				mesh.TexCoord( 0, uvs[i][j-1][1][1], uvs[i][j-1][1][2] )
				mesh.Normal( normal )
				mesh.Color( 255, 255, 255, 255 )
				mesh.AdvanceVertex()
				mesh.Position( verts[indices[i][j+1]] * scale )
				mesh.TexCoord( 0, uvs[i][j-1][2][1], uvs[i][j-1][2][2] )
				mesh.Normal( normal )
				mesh.Color( 255, 255, 255, 255 )
				mesh.AdvanceVertex()
				mesh.Position( verts[indices[i][j]] * scale )
				mesh.TexCoord( 0, uvs[i][j-1][3][1], uvs[i][j-1][3][2] )
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


	function ENT:DrawResizeGizmo()

	end

end
