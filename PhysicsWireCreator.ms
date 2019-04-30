filein "includes/PhysicsWireBuilder.ms"

plugin modifier phyiscsWireController
name:"Physics Wire Controller"
classID:#(0x5c1773b9, 0x75d4f467)
replaceUI:off
silentErrors:off
version:1
(
    /** The rollouts. Declared here so they can be accessed by all other rollouts. */
    local splineRollout, bonesRollout, constraintsRollout, anchorObjectRollout, mainRollout
    /** Instance of the helper struct */
    local builder = PhysicsWireBuilder()


    /*==================================================================================================================
        PARAMETERS
    */
    parameters mainData
    (
        nContainer type:#node
    )
    /** Parameters for Spline Rollout */
    parameters splineData rollout:splineRollout
    (
        nSpline type:#node ui:ui_pickSplineObj
        bSplinePrefix type:#boolean default:true ui:ui_chkUsePrefix
        sSplinePrefix type:#string default:"" ui:ui_etPrefix
        sSplineLayer type:#string
        fWireWidth type:#worldUnits default:0.125 ui:ui_spinWireWidth
    )

    /** Parameters for Bone Rollout */
    parameters boneData rollout:bonesRollout
    (
        ntBones type:#nodeTab tabSizeVariable:true
        bBonePrefix type:#boolean default:true ui:ui_chkUsePrefix
        sBonePrefix type:#string default:"" ui:ui_etPrefix
        sBoneLayer type:#string
        bStartAnchor type:#boolean default:true ui:ui_chkStartAnchor
        bEndAnchor type:#boolean default:false ui:ui_chkEndAnchor
        fDensity type:#float default:4 ui:ui_spinDensity
        fCollisionPadding type:#worldUnits default:0.01 ui:ui_spinPadding
    )

    /** Parameters for Constraint Rollout */
    parameters constraintData rollout:constraintsRollout
    (
        ntConstraints type:#nodeTab tabSizeVariable:true
        bConstraintPrefix type:#boolean default:true ui:ui_chkUsePrefix
        sConstraintPrefix type:#string default:"" ui:ui_etPrefix
        sConstraintLayer type:#string
        aSwingAngle type:#angle default:10
        fSwingSpring type:#float default:0.1 ui:ui_spinSwingSpring
        fSwingDamping type:#float default:100 ui:ui_spinSwingDamping
        aTwistAngle type:#angle default:10
        fTwistSpring type:#float default:0.1 ui:ui_spinTwistSpring
        fTwistDamping type:#float default:100 ui:ui_spinTwistDamping
    )

    /** Parameters for End Object Rollout */
    parameters endObjectData rollout:anchorObjectRollout
    (
        nStartAnchor type:#node ui:ui_pickStart
        nEndAnchor type:#node ui:ui_pickEnd
        nOldStartAnchor type:#node
        nOldEndAnchor type:#node
    )


    /*==================================================================================================================
        PLUGIN METHODS
    */
    /**
        Filter for spline wire objects. Tests if it is a shape object, or otherwise it it contains the modifiers we
        would expect the wire spline to have.

        @param obj
            The object to test.

        @return True if the object is a wire spline. False if not.
     */
    fn __filterSpline obj = 
    (
        IsShapeObject obj \
            OR (for m in obj.modifiers where (classof m == sweep OR classof m == skin) collect m).count > 0
    )

    /**
        Returns the container for all objects for the wire. If the container doesn't exist, then it is automatically
        created.

        @return Container Node
     */
    fn __getContainer =
    (
        local nodeList = for n in $.children where classof n == Point collect n
        if nodeList.count > 0 then nodeList[1] else 
        (
            local n = Point()
            n.transform = $.transform
            n.parent = $
            n.name = ($.name + ".container")
            n.centermarker = n.axistripod = n.cross = n.box = false
            $.layer.addnode n
            n -- return
        )
    )
    /**
        Returns array of layer names.

        @return Array of strings.
    */
    fn __getLayerNames =
    (
        local layerList = #()
        for i = 0 to (LayerManager.count-1) do (append layerList (LayerManager.getLayer i).name)
        layerList -- return
    )
 
    /**
        Sets the dropdown selection to the given string for the given dropdown.

        @param dropDown
            The dropdown UI.
        @param selectionText
            The string to find and select in the dropdown.

        @return
            Returns true if successful. False if not (the string could not be found in the dropdown).
    */
    fn __setDropdownSelection dropDown selectionText =
    (
        local index = findItem dropDown.items selectionText
        if index == 0 then false else (dropDown.selection = index; true)
    )
 
    /**
        Populates the given dropdown and selects the entry matching the given string. If the given string could not be
        found, then it will try to select the current layer name. If that doesn't work, then will just set selection to
        zero (nothing).

        @param dropDown
            The dropdown UI.
        @param selectionText
            The string to find in the dropdown and select.
    */
    fn __setupDropdown dropDown selectionText =
    (
        dropDown.items = __getLayerNames()
        local found = __setDropdownSelection dropDown selectionText
        if found == false then found = __setDropdownSelection dropDown LayerManager.current.name
        if found == false then dropDown.selection = 0
    )

    /**
        Deletes all the modifiers from the spline object.
     */
    fn __removeAllWireModifiers =
    (
        if nSpline != undefined then
        (
            local removeList = for m in nSpline.modifiers collect m
            for m in removeList do deleteModifier nSpline m
        )
    )

    /**
        Destroys all the bones.
     */
    fn __destroyBones =
    (
        local deleteList = for n in ntBones collect n
        ntBones = #()
        for i = 1 to deleteList.count do delete deleteList[i]
    )

    /**
        Destroys all the constraints.
     */
    fn __destroyConstraints =
    (
        local deleteList = for n in ntConstraints collect n
        ntConstraints = #()
        for n in (deleteList as array) do delete n
    )

    /**
        Removes missing bones from the list. This can happen if the bones were destroyed manually.
     */
    fn __cleanupBadBones =
    (
        local toDelete = for i = ntBones.count to 1 by -1 where ntBones[i] == undefined collect i
        for i in toDelete do deleteItem ntBones i
    )

    /**
        Removes missing constraints from the list. This can happen if the constraints were destroyed manually.
     */
    fn __cleanupBadConstraints =
    (
        local toDelete = for i = ntConstraints.count to 1 by -1 where ntConstraints[i] == undefined collect i
        for i in toDelete do deleteItem ntConstraints i
    )

    /**
        Detaches the old anchor objects from the bones. If there are no old anchor objects, then it will detach the
        current anchor objects.
     */
    fn __detachOldAnchors =
    (
        -- this affects old anchors. If there are no old anchors, then we must be working with the same anchor
        --  objects, we we will want to detach those
        if nOldStartAnchor == undefined then nOldStartAnchor = nStartAnchor
        if nOldEndAnchor == undefined then nOldEndAnchor = nEndAnchor

        -- perform detachment
        local hasBone = ntBones != undefined AND ntBones.count > 0
        if nOldStartAnchor != undefined AND hasBone then builder.detachAnchor nOldStartAnchor ntBones[1]
        if nOldEndAnchor != undefined AND hasBone then builder.detachAnchor nOldEndAnchor ntBones[ntBones.count]

        -- clear out old anchors
        nOldStartAnchor = undefined
        nOldEndAnchor = undefined
    )

    /**
        Attaches the current anchor objects to the end bones.
     */
    fn __attachNewAnchors =
    (
        local hasBones = ntBones != undefined AND ntBones.count > 0
        if nStartAnchor != undefined AND hasBones then
        (
            builder.attachAnchor nStartAnchor ntBones[1] bStartAnchor
        )
        if nEndAnchor != undefined AND hasBones then
        (
            builder.attachAnchor nEndAnchor ntBones[ntBones.count] bEndAnchor
        )
    )


    /**
        Builds the Spline Params struct and returns it.

        @return PhysicsWireSplineParams
    */
    fn getSplineData =
    (
        PhysicsWireSplineParams fWireWidth sSplinePrefix sSplineLayer
    )

    /**
        Builds the Bone Params struct and returns it.

        @return PhysicsWireBoneParams
    */
    fn getBoneData =
    (
        PhysicsWireBoneParams bStartAnchor bEndAnchor fWireWidth fCollisionPadding fDensity sBonePrefix sBoneLayer
    )

    /**
        Builds the Constraint Params struct and returns it.

        @return PhysicsWireConstraintParams
    */
    fn getConstraintData =
    (
        PhysicsWireConstraintParams aSwingAngle fSwingSpring fSwingDamping aTwistAngle fTwistSpring fTwistDamping \
                                    fWireWidth sConstraintPrefix sConstraintLayer
    )
    
    /**
        Destroys all bones and constraints, removes spline modifiers, and detaches the anchor objects.
     */
    fn destroyWire =
    (
        -- remove anchor constraints
        __detachOldAnchors()

        -- remove spline modifiers
        __removeAllWireModifiers()

        -- destroy bones and constraints
        __destroyConstraints()
        __destroyBones()
    )

    /**
        Will destroy the old wire elements and build the wire with new elements using the given parameters

        @param splineParams
            The parameters for creating the modifiers for the spline.
        @param boneParams
            The parameters for creating the bones and rigid bodies.
        @param constraintParams
            The parameters for creating the constraints.
        @param layerParams
            The parameters for assigning the wire elements to certain layers.
     */
    fn createWire splineParams boneParams constraintParams layerParams =
    (
        -- destroy old stuff
        destroyWire()

        -- get the constainer
        local parentObj = __getContainer()

        -- build bones and constraints
        ntBones = builder.buildBones nSpline boneParams parentObj
        ntConstraints = builder.buildConstraints ntBones constraintParams parentObj

        -- setup spline modifiers
        builder.modifyWireSpline nSpline ntBones splineParams parentObj

        -- setup anchor objects
        __attachNewAnchors()
    )

    /**
        Modifies the existing wire elements using the given parameters.

        @param splineParams
            The parameters for modifying the modifiers for the spline.
        @param boneParams
            The parameters for modifying the bones and rigid bodies.
        @param constraintParams
            The parameters for modifying the constraints.
        @param layerParams
            The parameters for assigning the wire elements to certain layers.
     */
    fn updateWire splineParams boneParams constraintParams layerParams =
    (
        -- get container
        local parentObj = __getContainer()

        -- modify bones, constraints, and spline
        builder.modifyBones ntBones boneParams parentObj
        builder.modifyConstraints ntConstraints ntBones constraintParams parentObj
        builder.modifyWireSpline nSpline ntBones splineParams parentObj

        -- setup anchors
        __detachOldAnchors()
        __attachNewAnchors()
    )


    /*==================================================================================================================
        ROLLOUTS
    */
    /** Rollout for spline controls */
    rollout splineRollout "Spline"
    (
        -- UI ELEMENTS
        pickButton ui_pickSplineObj "Pick Spline" message:"Pick a spline object that will be the wire." \
                                    autoDisplay:true filter:__filterSpline width:140
        checkbox ui_chkUsePrefix "Use Controller Name"
        edittext ui_etPrefix "" width:140
        dropdownlist ui_ddLayer "Layer"
        spinner ui_spinWireWidth "Wire Width" range:[0.001, 99999999, fWireWidth] scale:0.1 align:#right

        -- METHODS
        fn refreshPrefix = 
        (
            if bSplinePrefix == true then sSplinePrefix = $.name
            ui_etPrefix.readOnly = bSplinePrefix
        )
        fn refresh = ()

        -- EVENTS
        on splineRollout open do 
        (
            __setupDropdown ui_ddLayer sSplineLayer
            if sSplineLayer == undefined then sSplineLayer = ui_ddLayer.selected
            refreshPrefix()
            refresh()
        )
        on ui_pickSplineObj picked obj do 
        (
            nSpline.parent = __getContainer()
            refresh()
            bonesRollout.refresh()
            mainRollout.refresh()
        )
        on ui_pickSplineObj rightClick do
        (
            if nSpline != undefined then nSpline.parent = undefined
            ui_pickSplineObj.object = nSpline = undefined
            refresh()
            bonesRollout.refresh()
            mainRollout.refresh()
        )
        on ui_chkUsePrefix changed val do (refreshPrefix())
        on ui_ddLayer selected index do (sSplineLayer = ui_ddLayer.selected)
    )

    /** Rollout for bone controls */
    rollout bonesRollout "Bones"
    (
        -- UI ELEMENTS
        multilistbox ui_multiBones "Bones" height:5
        button ui_butSelect "Select" enabled:false align:#right
        checkbox ui_chkUsePrefix "Use Controller Name"
        edittext ui_etPrefix "" width:140
        dropdownlist ui_ddLayer "Layer"
        checkbox ui_chkStartAnchor "Start" checked:bStartAnchor align:#left offset:[10,20] across:2
        checkbox ui_chkEndAnchor "End" checked:bEndAnchor align:#right offset:[-10,20]
        groupBox ui_groupAnchor "Anchors" offset:[0,-40] width:140 height:45
        spinner ui_spinDensity "Density" width:100 align:#right
        spinner ui_spinPadding "Padding" type:#worldUnits width:100 align:#right

        -- METHODS
        fn refreshPrefix = 
        (
            if bBonePrefix == true then sBonePrefix = $.name
            ui_etPrefix.readOnly = bBonePrefix
        )
        fn refresh =
        (
            refreshPrefix()
            __setupDropdown ui_ddLayer sBoneLayer
            if sBoneLayer == undefined then sBoneLayer = ui_ddLayer.selected
            __cleanupBadBones()
            ui_multiBones.items = for b in ntBones collect b.name
            ui_butSelect.enabled = false
        )

        -- EVENTS
        on bonesRollout open do (refresh())
        on ui_multiBones selectionEnd do (ui_butSelect.enabled = true)
        on ui_multiBones rightClick do (ui_multiBones.selection = #{}; ui_butSelect.enabled = false)
        on ui_multiBones doubleClicked index do
        (
            ui_multiBones.selection = #{1..ui_multiBones.items.count}
            ui_butSelect.enabled = (ui_multiBones.selection.count > 0)
        )
        on ui_chkUsePrefix changed val do (refreshPrefix())
        on ui_ddLayer selected index do (sBoneLayer = ui_ddLayer.selected)
    )

    /** Rollout for constraint controls */
    rollout constraintsRollout "Constraints"
    (
        -- UI ELEMENTS
        multilistbox ui_multiConstraints "Constraints" height:5
        button ui_butSelect "Select" enabled:false align:#right
        checkbox ui_chkUsePrefix "Use Controller Name"
        edittext ui_etPrefix "" width:140
        dropdownlist ui_ddLayer "Layer"
        angle ui_aglSwingLimit "Swing" degrees:aSwingAngle across:2
        angle ui_aglTwistLimit "Twist" degrees:aTwistAngle
        spinner ui_spinSwingSpring "S" range:[0.000, 999999, fSwingSpring] fieldWidth:45 across:2
        spinner ui_spinTwistSpring "S" range:[0.000, 999999, fTwistSpring] fieldWidth:45
        spinner ui_spinSwingDamping "D" range:[0.000, 999999, fSwingDamping] fieldWidth:45 across:2
        spinner ui_spinTwistDamping "D" range:[0.000, 999999, fTwistDamping] fieldWidth:45

        -- METHODS
        fn refreshPrefix = 
        (
            if bConstraintPrefix == true then sConstraintPrefix = $.name
            ui_etPrefix.readOnly = bConstraintPrefix
        )
        fn refresh =
        (
            refreshPrefix()
            __setupDropdown ui_ddLayer sConstraintLayer
            if sConstraintLayer == undefined then sConstraintLayer = ui_ddLayer.selected
            __cleanupBadConstraints()
            ui_multiConstraints.items = for b in ntConstraints collect b.name
            ui_butSelect.enabled = false
            ui_aglSwingLimit.degrees = aSwingAngle
            ui_aglTwistLimit.degrees = aTwistAngle
        )

        -- EVENTS
        on constraintsRollout open do (refresh())
        on ui_multiConstraints selectionEnd do (ui_butSelect.enabled = true)
        on ui_multiConstraints rightClick do (ui_multiConstraints.selection = #{}; ui_butSelect.enabled = false)
        on ui_multiConstraints doubleClicked index do
        (
            ui_multiConstraints.selection = #{1..ui_multiConstraints.items.count}
            ui_butSelect.enabled = (ui_multiConstraints.selection.count > 0)
        )
        on ui_chkUsePrefix changed val do (refreshPrefix())
        on ui_aglSwingLimit changed val do (aSwingAngle = val)
        on ui_aglTwistLimit changed val do (aTwistAngle = val)
        on ui_ddLayer selected index do (sConstraintLayer = ui_ddLayer.selected)
    )

    /** Rollout for end object controls */
    rollout anchorObjectRollout "Anchor Object"
    (
        -- UI ELEMENTS
        pickButton ui_pickStart "Pick Start Anchor" message:"Pick an rigid body object that will be the start anchor." \
                                    autoDisplay:true width:140
        pickButton ui_pickEnd "Pick End Anchor" message:"Pick an rigid body object that will be the end anchor." \
                                    autoDisplay:true width:140

        -- METHODS
        fn refresh = ()

        -- EVENTS
        on ui_pickStart picked obj do (nOldStartAnchor = nStartAnchor)
        on ui_pickStart rightClick do (nOldStartAnchor = nStartAnchor; ui_pickStart.object = nStartAnchor = undefined)
        on ui_pickEnd picked obj do (nOldEndAnchor = nEndAnchor)
        on ui_pickEnd rightClick do (nOldEndAnchor = nEndAnchor; ui_pickEnd.object = nEndAnchor = undefined)
    )

    /** Rollout for main actions */
    rollout mainRollout "Main Actions"
    (
        button ui_butCreate "Create Wire" enabled:false
        button ui_butUpdate "Update Wire" enabled:false
        button ui_butDestroy "Destroy Wire" enabled:false

        fn refresh =
        (
            ui_butCreate.enabled = (nSpline != undefined)
            ui_butCreate.caption = if ntBones.count > 0 OR ntConstraints.count > 0 then \
                                        "Re-create Wire" else "Create Wire"
            ui_butUpdate.enabled = (nSpline != undefined AND (ntBones.count > 0 OR ntConstraints.count > 0))
            ui_butDestroy.enabled = ((nSpline != undefined AND nSpline.modifiers.count > 0) \
                                    OR ntBones.count > 0 OR ntConstraints.count > 0)
        )
        fn refreshAll =
        (
            refresh()
            splineRollout.refresh()
            bonesRollout.refresh()
            constraintsRollout.refresh()
            anchorObjectRollout.refresh()
        )

        on mainRollout open do (refresh())
        on ui_butCreate pressed do 
        (
            -- store this selected object because the skinning process causes teh spline to be selected
            local sel = $

            -- get param data
            local splineParams = getSplineData()
            local boneParams = getBoneData()
            local constraintParams = getConstraintData()

            -- perform creation
            createWire splineParams boneParams constraintParams layerParams

            -- re-select the controller object
            select sel
        )
        on ui_butUpdate pressed do
        (
            -- store this selected object because the skinning process causes teh spline to be selected
            local sel = $

            -- get param data
            local splineParams = getSplineData()
            local boneParams = getBoneData()
            local constraintParams = getConstraintData()

            -- perform modifications
            updateWire splineParams boneParams constraintParams layerParams

            -- re-select the controller object
            select sel
        )
        on ui_butDestroy pressed do (destroy(); refreshAll())
    )

    /*==================================================================================================================
        EVENTS
    */
    /**
        Event for when the modifier has been created on an object. We will attempt to auto pick the wire spline if we
        can find it already contained within the controller object.
     */
    on postCreate do
    (
        for con in $.children while nSpline == undefined do (
            local objList = for obj in con.children where (__filterSpline obj) collect obj
            if objList.count > 0 then nSpline = objList[1]
        )
    )
)
