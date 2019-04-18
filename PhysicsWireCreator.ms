plugin modifier phyiscsWireController
name:"Physics Wire Controller"
classID:#(0x5c1773b9, 0x75d4f467)
replaceUI:off
silentErrors:off
version:1
(
    /*==================================================================================================================
        PLUGIN METHODS
    */
    /**
        Returns array of layer names.

        @return Array of strings.
     */
    fn getLayerNames =
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
    fn setDropdownSelection dropDown selectionText =
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
    fn setupDropdown dropDown selectionText =
    (
        dropDown.items = getLayerNames()
        local found = setDropdownSelection dropDown selectionText
        if found == false then found = setDropdownSelection dropDown LayerManager.current.name
        if found == false then dropDown.selection = 0
    )

    /**
        Sets the layer for the given object to the given layer by name.

        @param obj
            The obj to place in the given layer.
        @param layerName
            The name of the layer to add the given object to.

        @return
            Returns true if successful. False if not.
     */
    fn setLayer obj layerName =
    (
        local layerObj = LayerManager.getLayerFromName layerName
        if layerObj == undefined then false else (layerObj.addnode obj; true)
    )


    /** The rollouts. Declared here so they can be accessed by all other rollouts. */
    local splineRollout, boneRollout, constraintRollout, endObjectRollout


    /*==================================================================================================================
        PARAMETERS
    */
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
        fSwingSpring type:#float default:0.1
        fSwingDamping type:#float default:100
        aTwistAngle type:#angle default:10
        fTwistSpring type:#float default:0.1
        fTwistDamping type:#float default:100
    )

    /** Parameters for End Object Rollout */
    parameters endObjectData rollout:endObjectRollout
    (
        nEndObject type:#node tabSizeVariable:true
        sEndObjectLayer type:#string
    )


    /*==================================================================================================================
        ROLLOUTS
    */
    /** Rollout for spline controls */
    rollout splineRollout "Spline"
    (
        -- FILTERS
        fn filterSpline obj = (IsShapeObject obj)

        -- UI ELEMENTS
        pickButton ui_pickSplineObj "Pick Spline" message:"Pick a spline object that will be the wire." \
                                    autoDisplay:true filter:filterSpline width:140
        checkbox ui_chkUsePrefix "Use Controller Name"
        edittext ui_etPrefix "" width:140
        dropdownlist ui_ddLayer "Layer"
        spinner ui_spinWireWidth "Wire Width" range:[0.001, 99999999, fWireWidth] scale:0.1 align:#right
        button ui_butUpdate "Update" enabled:false

        fn refreshPrefix = 
        (
            if bSplinePrefix == true then sSplinePrefix = $.name
            ui_etPrefix.readOnly = bSplinePrefix
        )

        -- EVENTS
        on splineRollout open do (setupDropdown ui_ddLayer sSplineLayer; refreshPrefix())
        on ui_pickSplineObj rightClick do (ui_pickSplineObj.object = nSpline = undefined)
        on ui_chkUsePrefix changed val do (refreshPrefix())
        on ui_ddLayer selected index do (sSplineLayer = ui_ddLayer.selected)
        on ui_butUpdate pressed do
        (
            -- build params
            local params = PhysicsWireSplineParams fWireWidth 
        )
    )

    /** Rollout for bone controls */
    rollout bonesRollout "Bones"
    (
        fn getBoneNames = (for b in ntBones collect b.name)

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
        button ui_butUpdate "Update" width:65 align:#left across:2
        button ui_butBuild "Build" width:65 align:#right

        fn refreshPrefix = 
        (
            if bBonePrefix == true then sBonePrefix = $.name
            ui_etPrefix.readOnly = bBonePrefix
        )
        fn refresh =
        (
            refreshPrefix()
            setupDropdown ui_ddLayer sBoneLayer
            ui_multiBones.items = for b in ntBones collect b.name
            ui_butSelect.enabled = false
            ui_butUpdate.enabled = (ntBones.count > 0)
            ui_butBuild.enabled = (nSplineObject != undefined)
            ui_butBuild.caption = if ntBones.count > 0 then "Rebuild" else "Build"
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
        button ui_butUpdate "Update" width:65 align:#left across:2
        button ui_butBuild "Build" width:65 align:#right

        fn refreshPrefix = 
        (
            if bConstraintPrefix == true then sConstraintPrefix = $.name
            ui_etPrefix.readOnly = bConstraintPrefix
        )
        fn refresh =
        (
            refreshPrefix()
            setupDropdown ui_ddLayer sConstraintLayer
            ui_multiConstraints.items = for b in ntConstraints collect b.name
            ui_butSelect.enabled = false
            ui_butUpdate.enabled = (ntConstraints.count > 0)
            ui_butBuild.enabled = (ntBones.count > 0)
            ui_butBuild.caption = if ntConstraints.count > 0 then "Rebuild" else "Build"
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
    )

    /** Rollout for end object controls */
    rollout endObjectRollout "End Object"
    (

    )

    /** Rollout for main actions */
    rollout mainRollout "Main Actions"
    (
        button ui_butCreate "Create Wire"

        on ui_butCreate pressed do ()
    )
)
