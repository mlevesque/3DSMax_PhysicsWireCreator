filein "HelperStructs.ms"

struct PhysicsWireBuilder
(
    private
    /*==================================================================================================================
        PRIVATE METHODS
     */
    /**
        Builds an array of points from the given spline object and returns it. This only cares about the first spline in
        the object.

        @param splineObj
            The spline object to get the points from.

        @return The array of points from the spline.
     */
    fn __buildPointsArray splineObj =
    (
        local arrPoints = #()
		if splineObj != undefined then
		(
			local num = numKnots splineObj
			for i = 1 to num do
			(
				local newPoint = getKnotPoint splineObj 1 i
				-- ignore consecutive knots that are in the same position
				if arrPoints.count == 0 OR arrPoints[i-1] != newPoint then append arrPoints newPoint
			)
        )
        arrPoints -- return
    ),

    /**
        Builds the Z Axis Vector for use in bone creation.

        @param p3Start
            Start position of the bone.
        @param p3End
            End position of the bone.

        @return The Z Axis Vector as a Point3.
     */
    fn __buildBoneZAxis p3Start p3End =
	(
		local boneDir = p3Start - p3End
		local zAxis = cross boneDir [0, 0, 1]
		
        -- if the Z Axis is a zero vector (in the case that the bone is parallel to the up vector), then we use an 
        --  alternate up vector
		if zAxis == [0, 0, 0] then normalize(cross boneDir [0.055, 0, 0.998]) else normalize zAxis
    ),
    
    /**
        Returns a modifier of the given type from the given object. This will get the first occurrance of the
        modifier.

        @param obj
            The object to get the modifier from.
        @param modClass
            The class of the modifier to get.

        @return The modifier of the object of the given class type. If there isn't one, then returns undefined.
     */
    fn __getModifier obj modClass =
    (
        local arrMods = for m in obj.modifiers where classof m == modClass collect m
        if arrMods.count > 0 then arrMods[1] else undefined -- return
    ),

    /**
        This fixes issue where object with skin modifier must be selected and active in order to make chages to the skin
        modifier

        @param obj
            The obj with a skin modifier that we wish to modify.
     */
    fn __prepareMaxForSkinOps obj = 
	(	
		-- Select obj if needed
		if not obj.IsSelected do Select obj
		
		-- Unfreeze obj if needed.
		if obj.IsFrozen do Unfreeze obj DoLayer:true
		
		-- Set Modify Panel active if needed.
		if GetCommandPanelTaskMode() != #modify do SetCommandPanelTaskMode mode:#modify
		
		-- Set obj skin modifier as current object in modpanel if needed.
		if ModPanel.GetCurrentObject() != obj.skin do ModPanel.SetCurrentObject obj.skin
	),

    
    public
    /*==================================================================================================================
        PUBLIC METHODS
     */
    /**
        Modifies the given array of bones with the given struct of properties.

        @param arrBones
            The array of bones to modify.
        @param structBoneParams
            The parameters needed for setting up the bone properties. This should be the struct
            PhysicsWireBoneParams.
     */
    fn modifyBones arrBones structBoneParams =
    (
        -- modify each bone
        for i = 1 to arrBones.count do
        (
            -- get bone
            local boneObj = arrBones[i]

            -- setup bone size
            boneObj.width = boneObj.height = structBoneParams.fWireWidth
            boneObj.taper = 100

            -- get (or create) rigid body on bone
            local rigidBodyMod = __getModifier boneObj MassFX_RBody
            if rigidBodyMod == undefined then (rigidBodyMod = MassFX_RBody(); addModifier boneObj rigidBodyMod)

            -- setup rigid body
            local wireRadius = structBoneParams.fWireWidth / 2
            local shouldBeKinematic = (i == 1 AND structBoneParams.bStartAnchor == true) \              -- first bone
                                    OR (i == arrBones.count AND structBoneParams.bEndAnchor == true)    -- last bone
            if shouldBeKinematic == true then rigidBodyMod.type = 2 else rigidBodyMod.type = 1
            rigidBodyMod.meshType = 3 --capsule
            rigidBodyMod.meshRadius = wireRadius + structBoneParams.fCollisionPadding
            rigidBodyMod.meshHeight = boneObj.length - (rigidBodyMod.meshRadius * 4)
            rigidBodyMod.density = structBoneParams.fDensity

            -- position and orient collision
            local trans = Matrix3 1; rotateY trans 90; trans.translation = [rigidBodyMod.meshRadius, 0, 0]
            rigidBodyMod.SetRBMeshTM 1 trans

            -- set name
            boneObj.name = (structBoneParams.sPrefixName + ".bone" + (formattedPrint i format:"02u"))
        )
    ),

    /**
        Modifies the given array of constraints with the given bones and given struct of properties.

        @param arrConstraints
            The array of constraints to modify.
        @param arrBones
            The array of bones for the constraints. All the bones must have rigid bodies. The length of the array should
            be the size of the constraint array plus one.
        @param structConstraintParams
            The parameters needed for setting up the constraint properties. This should be the struct
            PhysicsWireConstraintParams.
     */
    fn modifyConstraints arrConstraints arrBones structConstraintParams =
    (
        -- modify each constraint
        for i = 1 to arrConstraints.count while i < arrBones.count do
        (
            -- get bones and constraint
            local c = arrConstraints[i]
            local firstBone = arrBones[i]
            local secondBone = arrBones[i+1]

            -- set properties
            c.name = (structConstraintParams.sPrefixName + ".constraint" + (formattedPrint i format:"02u"))
            c.transform = secondBone.transform
            c.body0 = firstBone
            c.body1 = secondBone
            c.breakable = false
            c.helperSize = 0.5

            -- positional movement
            c.linearModeX = c.linearModeY = c.linearModeZ = 1 -- locked

            -- limit swing movement
			c.swing1Mode = c.swing2Mode = 2 -- limited
			c.swing1Angle = c.swing2Angle = structConstraintParams.fSwingAngle
			c.swing1Spring = c.swing2Spring = c.swingSpring = structConstraintParams.fSwingSpring
			c.swing1Damping = c.swing2Damping = c.swingDamping = structConstraintParams.fSwingDampening
			
			-- limit twist movement
			c.twistMode = 2 -- limited
			c.twistAngleLow = c.twistAngleHigh = structConstraintParams.fTwistAngle
			c.twistSpringLow = c.twistSpringHigh = c.twistSpring = structConstraintParams.fTwistSpring
            c.twistDampingLow = c.twistDampingHigh = c.twistDamping = structConstraintParams.fTwistDampening
            
            c.name = (structConstraintParams.sPrefixName + ".constraint" + (formattedPrint i format:"02u"))
        )
    ),

    /**
        Modifies the given wire spline object, giving it a skin and sweep modifier to form the actual renderable wire.

        @param splineObj
            The spline object to make the wire from.
        @param arrBones
            The array of bones to use for skinning.
        @param structWireParams
            The parameters needed for setting up the spline wire properties. This should be the struct
            PhysicsWireSplineParams.
     */
    fn modifyWireSpline splineObj arrBones structWireParams =
    (
        -- get Skin modifier
        local skinMod = __getModifier splineObj Skin
        if skinMod == undefined then (skinMod = Skin(); addModifier splineObj skinMod before:1)

        -- add bones to skin modifier
        __prepareMaxForSkinOps splineObj
        for i = 1 to arrBones.count do
        (
            -- only update system once we add the last bone
            local last = if i == arrBones.count then -1 else 0
            skinOps.addbone skinMod arrBones[i] last
        )

        -- get sweep modifier
        local sweepMod = __getModifier splineObj Sweep
        if sweepMod == undefined then (sweepMod = Sweep(); addModifier splineObj sweepMod)

        -- setup sweep modifier
        local c = Circle radius:(structWireParams.fWireWidth / 2)
        sweepMod.shapes[1] = c
        sweepMod.customShape = 1
        delete c

        -- set name
        splineObj.name = (structWireParams.sPrefixName + ".spline")
    ),

    /**
        Builds a series of bones positioned at the knot points of the given splne object and returns an array of them.

        @param splineObj
            The spline object to position the bones around.
        @param structBoneParams
            The parameters needed for setting up the bone properties. This should be the struct
            PhysicsWireBoneParams.

        @return An array of created bones.
     */
    fn buildBones splineObj structBoneParams =
    (
        -- get spline points
        local arrPoints = __buildPointsArray splineObj

        -- create a bone for each segment of points
        arrBones = #()
        local pointCount = arrPoints.count - 1
		for i = 1 to pointCount do
		(
            local zAxis = __buildBoneZAxis arrPoints[i] arrPoints[i+1]
			append arrBones (BoneSys.createBone arrPoints[i] arrPoints[i+1] zAxis)
        )

        -- modifiy properties
        modifyBones arrBones structBoneParams
        arrBones -- return
    ),

    /**
        Builds a series of constraints between the given array of bones and using the given struct params.

        @param arrBones
            The array of bones that will have the constraints.
        @param structConstraintParams
            The parameters needed for setting up the constraint properties. This should be the struct
            PhysicsWireConstraintParams.

        @return An array of created constraints.
     */
    fn buildConstraints arrBones structConstraintParams =
    (
        -- create a constraint for each pair of adjacent bones in the array
        arrConstraints = #()
        local boneCount = arrBones.count - 1
        for i = 1 to boneCount do (append arrConstraints (UConstraint()))

        -- modifiy properties
        modifyConstraints arrConstraints arrBones structConstraintParams
        arrConstraints -- return
    )
)
