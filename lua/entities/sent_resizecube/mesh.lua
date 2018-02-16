
local material = Material( "hunter/myplastic" )

function ENT:GetRenderMesh()
    if not self.Mesh then
        return
    end

    return { Mesh = self.Mesh, Material = material }
end

function ENT:CreateMesh()
    if self.Mesh then
        self.Mesh:Destroy()
    end

    self.Mesh = Mesh()

    local positions = {
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
        1, 7, 5,
        1, 3, 7,
        6, 4, 2,
        6, 8, 4,
        1, 6, 2,
        1, 5, 6,
        3, 8, 7,
        3, 4, 8,
        1, 4, 3,
        1, 2, 4,
        5, 8, 6,
        5, 7, 8,
    }

    local normals = {
       Vector( -1,  0,  0 ),
       Vector(  1,  0,  0 ),
       Vector(  0, -1,  0 ),
       Vector(  0,  1,  0 ),
       Vector(  0,  0, -1 ),
       Vector(  0,  0,  1 ),
    }

    local tangents = {
        { 0, 1, 0, -1 },
        { 0, 1, 0, -1 },
        { 0, 0, 1, -1 },
        { 1, 0, 0, -1 },
        { 1, 0, 0, -1 },
        { 0, 1, 0, -1 },
    }

    -- Our texture is a 4x4 grid, divide by 4 so that 1 source unit = 1 texture unit.
    local w, h, d = self:GetScaleY() / 4, self:GetScaleZ() / 4, self:GetScaleX() / 4

    local uCoords = {
       0, w, 0,
       0, w, w,
       0, w, 0,
       0, w, w,
       0, h, 0,
       0, h, h,
       0, d, 0,
       0, d, d,
       0, d, 0,
       0, d, d,
       0, w, 0,
       0, w, w,
    }

    local vCoords = {
       0, h, h,
       0, 0, h,
       0, h, h,
       0, 0, h,
       0, d, d,
       0, 0, d,
       0, h, h,
       0, 0, h,
       0, w, w,
       0, 0, w,
       0, d, d,
       0, 0, d,
    }

    local verts = {}
    local scale = self:GetScaledMax() - self:GetScaledMin()    

    for vert_i = 1, #indices do
        local face_i = math.ceil( vert_i / 6 )

        verts[vert_i] = {
            pos = positions[indices[vert_i]] * scale,
            normal = normals[face_i],
            u = uCoords[vert_i],
            v = vCoords[vert_i],
            userdata = tangents[face_i]
        }
    end
    
    self.Mesh:BuildFromTriangles( verts )

end