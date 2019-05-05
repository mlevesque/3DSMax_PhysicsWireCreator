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
        Returns true if the given bone is large enough for the given radius and padding.

        @return true if large enough; false otherwise
     */
    fn __shouldAddCapsuleCollision boneObj radius padding =
    (
        boneObj.length >= ((radius + padding) * 4)
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
    
    /**
        Detaches the given target from the given source transform controller, if the target was appended to the control.

        @param source
            The source object that has the constraints.
        @param sourceTransformController
            A transform controller for the given source object.
        @param target
            The target to detach from the control.
     */
    fn __detachConstraint source sourceTransformController target =
    (
        local constraintControl = sourceTransformController
        local isPos = (isKindOf sourceTransformController Position_Constraint)
        local isRot = (isKindOf sourceTransformController Orientation_Constraint)
        if isPos OR isRot then
        (
            -- if the constraint only has the one target, then reset the controller
            if (constraintControl.getNumTargets() == 1) AND (constraintControl.getNode 1) == target then
            (
                if isPos then source.pos.controller = Position_XYZ() \
                else source.rotation.controller = Euler_XYZ()
            )
            else
            (
                -- remove only the target
                for i = 1 to constraintControl.getNumTargets() do
                (
                    if (constraintControl.getNode i) == target then constraintControl.deleteTarget i
                )
            )
        )
    ),

    /**
        Sets the layer for the given object to the given layer by name.

        @param obj
            The obj to place in the given layer.
        @param layerName
            The name of the layer to add the given object to.

        @return
            Returns true if successful. False if not.
    */
    fn __setLayer obj layerName =
    (
        local layerObj = LayerManager.getLayerFromName layerName
        if layerObj == undefined then false else (layerObj.addnode obj; true)
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
        @param parentObj
            The container object for all the bones.
     */
    fn modifyBones arrBones structBoneParams parentObj =
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
            
            local shouldBeKinematic = (i == 1 AND structBoneParams.bStartAnchor == true) \              -- first bone
                                    OR (i == arrBones.count AND structBoneParams.bEndAnchor == true)    -- last bone
            if shouldBeKinematic == true then rigidBodyMod.type = 2 else rigidBodyMod.type = 1
            rigidBodyMod.density = structBoneParams.fDensity

            -- add capsule collision for all bones as long as it is large enough
            local wireRadius = structBoneParams.fWireWidth / 2
            local padding = structBoneParams.fCollisionPadding
            if __shouldAddCapsuleCollision boneObj wireRadius padding then
            (
                rigidBodyMod.meshType = 3 --capsule
                rigidBodyMod.meshRadius = wireRadius + padding
                rigidBodyMod.meshHeight = boneObj.length - (rigidBodyMod.meshRadius * 4)

                -- position and orient collision
                local trans = Matrix3 1; rotateY trans 90; trans.translation = [rigidBodyMod.meshRadius, 0, 0]
                rigidBodyMod.SetRBMeshTM 1 trans
            )
            -- small bones will use a sphere
            else
            (
                rigidBodyMod.meshType = 1 -- sphere
                rigidBodyMod.meshRadius = boneObj.length / 2
            )

            -- set name
            local sName = (structBoneParams.sPrefixName + ".bone")
            sName += if i == arrBones.count then ".nub" else (formattedPrint i format:"02u")
            boneObj.name = sName

            -- set layer
            __setLayer boneObj structBoneParams.sBoneLayer

            -- set parent
            boneObj.parent = parentObj
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
        @param parentObj
            The container object for all the constraints.
     */
    fn modifyConstraints arrConstraints arrBones structConstraintParams parentObj =
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
            c.helperSize = structConstraintParams.fWireWidth

            -- positional movement
            c.linearModeX = c.linearModeY = c.linearModeZ = 1 -- locked

            -- limit swing movement
            --  (The last constraint, between the last skinable bone and the bone nub will be locked)
			c.swing1Mode = c.swing2Mode = if i == arrConstraints.count then 1 else 2
			c.swing1Angle = c.swing2Angle = structConstraintParams.fSwingAngle
			c.swing1Spring = c.swing2Spring = c.swingSpring = structConstraintParams.fSwingSpring
			c.swing1Damping = c.swing2Damping = c.swingDamping = structConstraintParams.fSwingDampening
			
            -- limit twist movement
            --  (The last constraint, between the last skinable bone and the bone nub will be locked)
			c.twistMode = if i == arrConstraints.count then 1 else 2
			c.twistAngleLow = c.twistAngleHigh = structConstraintParams.fTwistAngle
			c.twistSpringLow = c.twistSpringHigh = c.twistSpring = structConstraintParams.fTwistSpring
            c.twistDampingLow = c.twistDampingHigh = c.twistDamping = structConstraintParams.fTwistDampening
            
            -- set name
            c.name = (structConstraintParams.sPrefixName + ".constraint" + (formattedPrint i format:"02u"))

            -- set layer
            __setLayer c structConstraintParams.sConstraintLayer

            -- set parent
            c.parent = parentObj

            -- constrain position to second bone
            local posCtrl = Position_Constraint()
            c.pos.controller = posCtrl
            local posConstraintInterface = posCtrl.constraints
            posConstraintInterface.appendTarget secondBone 100
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
        @param parentObj
            The container object for the spline.
     */
    fn modifyWireSpline splineObj arrBones structWireParams parentObj =
    (
        -- get Skin modifier
        local skinMod = __getModifier splineObj Skin
        if skinMod == undefined then (skinMod = Skin(); addModifier splineObj skinMod before:1)

        -- add bones to skin modifier (except for bone nub)
        __prepareMaxForSkinOps splineObj
        local lastBoneIndex = arrBones.count - 1 -- don't include bone nub
        for i = 1 to lastBoneIndex do
        (
            -- only update system once we add the last bone
            local last = if i == lastBoneIndex then -1 else 0
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

        -- set layer
        __setLayer splineObj structWireParams.sSplineLayer

        -- set parent
        splineObj.parent = parentObj
    ),

    /**
        Detaches any kind of position and orientation constraint between the given anchor object and bone object.

        @param anchorObj
            The anchor object that would be constrained to/from one end of the wire.
        @param boneObj
            The first or last bone that would be constrained to/from an anchor object.
     */
    fn detachAnchor anchorObj boneObj =
    (
        -- detach bone from anchor
        local mat = anchorObj.transform
        __detachConstraint anchorObj anchorObj.pos.controller boneObj
        __detachConstraint anchorObj anchorObj.rotation.controller boneObj
        anchorObj.transform = mat

        -- detach anchor from bone
        -- we need to reapply the transform because reseting a bone's controllers causes it's position and rotation
        --   to be wonky
        mat = boneObj.transform 
        __detachConstraint boneObj boneObj.pos.controller anchorObj
        __detachConstraint boneObj boneObj.rotation.controller anchorObj
        boneObj.transform = mat
    ),

    /**
        Applies a position and orientation constraint between the anchor object and bone object. Which one getting
        constrained to the other depends on what value the given anchor is.
        If it is true, then the bone will be constrained to the anchor.
        If it is false, then the anchor will be constrained to the bone.

        @param anchorObj
            The anchor object to be attached to an end of the wire.
        @param boneObj
            Either the first or last bone in the wire.
        @param anchorVal
            Boolean value of whether the bone is anchored or not.
     */
    fn attachAnchor anchorObj boneObj anchorVal =
    (
        -- determine which object is constrained to what.
        --   If bone rigid body is kinematic, then bone will be constrained to anchor
        --   Otherwise anchor will be constrained to bone
        local source = if anchorVal then boneObj else anchorObj
        local target = if anchorVal then anchorObj else boneObj

        -- constrain position
        local posCtrl = Position_Constraint()
        source.pos.controller = posCtrl
        posCtrl.relative = true
        local posConstraintInterface = posCtrl.constraints
        posConstraintInterface.appendTarget target 20

        -- constrain rotation
        local rotCtrl = Orientation_Constraint()
        source.rotation.controller = rotCtrl
        rotCtrl.relative = true
        local rotConstraintInterface = rotCtrl.constraints
        rotConstraintInterface.appendTarget target 20
    ),

    /**
        Builds a series of bones positioned at the knot points of the given splne object and returns an array of them.

        @param splineObj
            The spline object to position the bones around.
        @param structBoneParams
            The parameters needed for setting up the bone properties. This should be the struct
            PhysicsWireBoneParams.
        @param parentObj
            The container object for all the bones.

        @return An array of created bones.
     */
    fn buildBones splineObj structBoneParams parentObj =
    (
        -- get spline points
        local arrPoints = __buildPointsArray splineObj

        -- create a bone for each segment of points
        arrBones = #()
        local pointCount = arrPoints.count - 1
		for i = 1 to pointCount by 1 do
		(
            local zAxis = __buildBoneZAxis arrPoints[i] arrPoints[i+1]
            local boneObj = BoneSys.createBone arrPoints[i] arrPoints[i+1] zAxis
			append arrBones boneObj
        )

        -- build bone nub
        if arrPoints.count > 1 then
        (
            -- calculate the end point
            local endPos = normalize (arrPoints[arrPoints.count] - arrPoints[arrPoints.count-1])
            endPos = structBoneParams.fWireWidth * endPos
            endPos = arrPoints[arrPoints.count] + endPos

            -- create bone nub
            local zAxis = __buildBoneZAxis arrPoints[arrPoints.count] endPos
            local boneObj = BoneSys.createBone arrPoints[arrPoints.count] endPos zAxis
            append arrBones boneObj
        )

        -- modifiy properties
        modifyBones arrBones structBoneParams parentObj
        arrBones -- return
    ),

    /**
        Builds a series of constraints between the given array of bones and using the given struct params.

        @param arrBones
            The array of bones that will have the constraints.
        @param structConstraintParams
            The parameters needed for setting up the constraint properties. This should be the struct
            PhysicsWireConstraintParams.
        @param parentObj
            The container object for all the constraints.

        @return An array of created constraints.
     */
    fn buildConstraints arrBones structConstraintParams parentObj =
    (
        -- create a constraint for each pair of adjacent bones in the array
        arrConstraints = #()
        local boneCount = arrBones.count - 1
        for i = 1 to boneCount do
        (
            local c = UConstraint()
            append arrConstraints c
        )

        -- modifiy properties
        modifyConstraints arrConstraints arrBones structConstraintParams parentObj
        arrConstraints -- return
    )
)
