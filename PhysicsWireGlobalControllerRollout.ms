filein "PhysicsWireControllerModifier.ms"

rollout physicsWireGlobalControllerRollout "Physics Wire Global Controller"
(
    -- default values
    local WIRE_WIDTH = units.decodeValue "3.0mm"
    local DENSITY = 4
    local PADDING = units.decodeValue "0.1mm"
    local SWING_LIMIT = 10
    local TWIST_LIMIT = 10
    local SWING_SPRING = 0.1
    local TWIST_SPRING = 0.1
    local SWING_DAMPING = 100
    local TWIST_DAMPING = 100

    -- list of all objects that have the wire modifiers
    local m_controllerList = #()
    local m_helper = PhysicsWireSharedHelpers()

    
    -- wire controller list
    multilistbox ui_multiControllers "Wire Controllers" height:10
    button ui_btnRefresh "Refresh" width:60 across:2
    button ui_btnSelect "Select" enabled:false width:60
    button ui_btnPullValues "Pull Values from Selected" enabled:false width:140

    -- spline config
    checkbox ui_chkSplineLayer "Spline Layer" checked:true offset:[0,40]
    dropdownlist ui_ddSplineLayer ""
    checkbox ui_chkWireWidth "Width" checked:true across:2
    spinner ui_spinWireWidth "" range:[0.001, 99999999, WIRE_WIDTH] scale:0.1 width:70 align:#right type:#worldunits
    groupBox ui_groupSpline "Spline" offset:[-7, -90] width:150 height:90

    -- bone config
    checkbox ui_chkBoneLayer "Bone Layer" checked:true offset:[0,40]
    dropdownlist ui_ddBoneLayer ""
    checkbox ui_chkDensity "Density" checked:true across:2
    spinner ui_spinDensity "" range:[0, 999999, DENSITY] width:70 align:#right
    checkbox ui_chkPadding "Padding" checked:true across:2
    spinner ui_spinPadding "" range:[0, 999999, PADDING] type:#worldUnits width:70 align:#right
    groupBox ui_groupBone "Bones" offset:[-7, -110] width:150 height:110

    -- constraint config
    checkbox ui_chkConstraintLayer "Constraint Layer" checked:true offset:[0,40]
    dropdownlist ui_ddConstraintLayer ""
    checkbox ui_chkSwingLimit "Swing" checked:true across:2
    checkbox ui_chkTwistLimit "Twist" checked:true
    angle ui_aglSwingLimit "" degrees:SWING_LIMIT across:2
    angle ui_aglTwistLimit "" degrees:TWIST_LIMIT
    checkbox ui_chkSwingSpring "S" checked:true across:2
    checkbox ui_chkTwistSpring "S" checked:true offset:[12, 0]
    spinner ui_spinSwingSpring "" range:[0.000, 999999, SWING_SPRING] fieldWidth:45 align:#left across:2
    spinner ui_spinTwistSpring "" range:[0.000, 999999, TWIST_SPRING] fieldWidth:45
    checkbox ui_chkSwingDamping "D" checked:true across:2
    checkbox ui_chkTwistDamping "D" checked:true offset:[12, 0]
    spinner ui_spinSwingDamping "" range:[0.000, 999999, SWING_DAMPING] fieldWidth:45 align:#left across:2
    spinner ui_spinTwistDamping "" range:[0.000, 999999, TWIST_DAMPING] fieldWidth:45
    groupBox ui_groupConstraint "Constraints" offset:[-7, -240] width:150 height:240

    -- checkbox control
    button ui_btnUseAll "Use All" width:60 across:2
    button ui_btnUseNone "Use None" width:60
    button ui_btnRestoreDefaults "Restore Defaults" width:140

    -- create buttons
    button ui_btnCreateSelected "Create Selected" enabled:false width:140 offset:[0, 40]
    button ui_btnCreateAll "Create All" width:140
    groupBox ui_groupCreate "Create" offset:[-7, -70] width:150 height:70

    -- update buttons
    button ui_btnUpdateSelected "Update Selected" enabled:false width:140 offset:[0, 20]
    button ui_btnUpdateAll "Update All" width:140
    groupBox ui_groupUpdate "Update" offset:[-7, -70] width:150 height:70

    -- destroy buttons
    button ui_btnDestroySelected "Destroy Selected" enabled:false width:140 offset:[0, 20]
    button ui_btnDestroyAll "Destroy All" width:140
    groupBox ui_groupDestroy "Destroy" offset:[-7, -70] width:150 height:70


    fn refreshButtons =
    (
        local selectionCount = ui_multiControllers.selection.numberSet
        ui_btnSelect.enabled = ui_btnCreateSelected.enabled = selectionCount > 0
        ui_btnUpdateSelected.enabled = ui_btnDestroySelected.enabled = selectionCount > 0
        ui_btnPullValues.enabled = selectionCount == 1
    )
    fn getSelectedObjects =
    (
        local selectionItems = ui_multiControllers.selection
        for i = 1 to m_controllerList.count where selectionItems[i] collect m_controllerList[i]
    )
    fn getControllerModifier obj = 
    (
        local mList = (for m in obj.modifiers where (isKindOf m PhysicsWireController) collect m)
        if mList.count > 0 then mList[1] else undefined
    )
    fn controllerFilter obj = ((getControllerModifier obj) != undefined)
    fn populateListbox =
    (
        -- gather list of objects that are selected in the listbox currently. We will attempt to re-select them
        -- once the listbox is rebuilt
        local selectedObjects = getSelectedObjects()

        -- gather controllers in scene
        m_controllerList = for obj in objects where (controllerFilter obj) collect obj

        -- compile the names into a list of strings to be used by the listbox. At the same time, set up selection
        local stringList = #()
        local selectionItems = #()
        for obj in m_controllerList do
        (
            local index = findItem selectedObjects obj
            if index > 0 then append selectionItems index
            append stringList obj.name
        )

        -- set listbox
        ui_multiControllers.items = stringList
        ui_multiControllers.selection = selectionItems
        refreshButtons()
    )
    fn refreshDropdowns =
    (
        m_helper.setupDropdownForLayers ui_ddSplineLayer ui_ddSplineLayer.selected
        m_helper.setupDropdownForLayers ui_ddBoneLayer ui_ddBoneLayer.selected
        m_helper.setupDropdownForLayers ui_ddConstraintLayer ui_ddConstraintLayer.selected
    )
    fn refreshControls =
    (
        ui_ddSplineLayer.enabled = ui_chkSplineLayer.checked
        ui_spinWireWidth.enabled = ui_chkWireWidth.checked
        ui_ddBoneLayer.enabled = ui_chkBoneLayer.checked
        ui_spinDensity.enabled = ui_chkDensity.checked
        ui_spinPadding.enabled = ui_chkPadding.checked
        ui_ddConstraintLayer.enabled = ui_chkConstraintLayer.checked
        ui_aglSwingLimit.enabled = ui_chkSwingLimit.checked
        ui_aglTwistLimit.enabled = ui_chkTwistLimit.checked
        ui_spinSwingSpring.enabled = ui_chkSwingSpring.checked
        ui_spinTwistSpring.enabled = ui_chkTwistSpring.checked
        ui_spinSwingDamping.enabled = ui_chkSwingDamping.checked
        ui_spinTwistDamping.enabled = ui_chkTwistDamping.checked
    )
    fn setAllCheckboxes value =
    (
        ui_chkSplineLayer.checked = ui_chkWireWidth.checked = value
        ui_chkBoneLayer.checked = ui_chkDensity.checked = ui_chkPadding.checked = value
        ui_chkConstraintLayer.checked = ui_chkSwingLimit.checked = ui_chkTwistLimit.checked = value
        ui_chkSwingSpring.checked = ui_chkTwistSpring.checked = value
        ui_chkSwingDamping.checked = ui_chkTwistDamping.checked = value
        refreshControls()
    )
    fn setUIFromParams splineParams boneParams constraintParams =
    (
        m_helper.setDropdownSelection ui_ddSplineLayer splineParams.sSplineLayer
        ui_spinWireWidth.value = splineParams.fWireWidth
        m_helper.setDropdownSelection ui_ddBoneLayer boneParams.sBoneLayer
        ui_spinDensity.value = boneParams.fDensity
        ui_spinPadding.value = boneParams.fCollisionPadding
        m_helper.setDropdownSelection ui_ddConstraintLayer constraintParams.sConstraintLayer
        ui_aglSwingLimit.degrees = constraintParams.fSwingAngle
        ui_aglTwistLimit.degrees = constraintParams.fTwistAngle
        ui_spinSwingSpring.value = constraintParams.fSwingSpring
        ui_spinTwistSpring.value = constraintParams.fTwistSpring
        ui_spinSwingDamping.value = constraintParams.fSwingDampening
        ui_spinTwistDamping.value = constraintParams.fTwistDampening
    )
    fn restoreDefaults =
    (
        local currentLayer = LayerManager.current.name
        local splineParams = PhysicsWireSplineParams WIRE_WIDTH "" currentLayer
        local boneParams = PhysicsWireBoneParams false false WIRE_WIDTH PADDING DENSITY "" currentLayer
        local constraintParams = PhysicsWireConstraintParams SWING_LIMIT SWING_SPRING SWING_DAMPING \
                                                             TWIST_LIMIT TWIST_SPRING TWIST_DAMPING \
                                                             WIRE_WIDTH "" currentLayer
        setUIFromParams splineParams boneParams constraintParams
    )
    fn setUIToControllerData obj =
    (
        local controllerMod = getControllerModifier obj
        local splineParams = controllerMod.getSplineData()
        local boneParams = controllerMod.getBoneData()
        local constraintParams = controllerMod.getConstraintData()
        setUIFromParams splineParams boneParams constraintParams
    )

    -- param building functions
    fn decorateSplineParams wireParams =
    (
        if ui_chkSplineLayer.checked then wireParams.sSplineLayer = ui_ddSplineLayer.selected
        if ui_chkWireWidth.checked then wireParams.fWireWidth = ui_spinWireWidth.value
    )
    fn decorateBoneParams boneParams = 
    (
        if ui_chkBoneLayer.checked then boneParams.sBoneLayer = ui_ddBoneLayer.selected
        if ui_chkDensity.checked then boneParams.fDensity = ui_spinDensity.value
        if ui_chkPadding.checked then boneParams.fCollisionPadding = ui_spinPadding.value
    )
    fn decorateConstraintParams constraintParams =
    (
        if ui_chkConstraintLayer.checked then constraintParams.sConstraintLayer = ui_ddConstraintLayer.selected
        if ui_chkSwingLimit.checked then constraintParams.fSwingAngle = ui_aglSwingLimit.degrees
        if ui_chkTwistLimit.checked then constraintParams.fTwistAngle = ui_aglTwistLimit.degrees
        if ui_chkSwingSpring.checked then constraintParams.fSwingSpring = ui_spinSwingSpring.value
        if ui_chkTwistSpring.checked then constraintParams.fTwistSpring = ui_spinTwistSpring.value
        if ui_chkSwingDamping.checked then constraintParams.fSwingDampening = ui_spinSwingDamping.value
        if ui_chkTwistDamping.checked then constraintParams.fTwistDampening = ui_spinTwistDamping.value
    )
    fn buildSplineParamsFor cMod = (local p = cMod.getSplineData(); decorateSplineParams p; p)
    fn buildBoneParamsFor cMod = (local p = cMod.getBoneData(); decorateBoneParams p; p)
    fn buildConstraintParamsFor cMod = (local p = cMod.getConstraintData(); decorateConstraintParams p; p)
    
    -- button action entry functions
    mapped fn performDestroy obj =
    (
        local controllerMod = getControllerModifier obj
        controllerMod.destroyWire()
    )
    mapped fn performUpdate obj =
    (
        local controllerMod = getControllerModifier obj
        local splineParams = buildSplineParamsFor controllerMod
        local boneParams = buildBoneParamsFor controllerMod
        local constraintParams = buildConstraintParamsFor controllerMod
        controllerMod.updateWire splineParams boneParams constraintParams
    )
    mapped fn performCreate obj =
    (
        local controllerMod = getControllerModifier obj
        local splineParams = buildSplineParamsFor controllerMod
        local boneParams = buildBoneParamsFor controllerMod
        local constraintParams = buildConstraintParamsFor controllerMod
        controllerMod.createWire splineParams boneParams constraintParams
    )


    -- rollout events
    on physicsWireGlobalControllerRollout open do (populateListBox(); refreshDropdowns())

    -- list box events
    on ui_multiControllers selectionEnd do (refreshButtons())
    on ui_multiControllers rightClick do (ui_multiControllers.selection = #{}; refreshButtons())
    on ui_multiControllers doubleClicked val do 
    (
        ui_multiControllers.selection = #{1..ui_multiControllers.items.count}
        refreshButtons()
    )

    -- list box button events
    on ui_btnRefresh pressed do (populateListbox())
    on ui_btnSelect pressed do (select (getSelectedObjects()))
    on ui_btnPullValues pressed do
    (
        local objList = getSelectedObjects()
        if objList.count > 0 then setUIToControllerData objList[1]
    )

    -- checkbox events
    on ui_chkSplineLayer changed val do (refreshControls())
    on ui_chkWireWidth changed val do (refreshControls())
    on ui_chkBoneLayer changed val do (refreshControls())
    on ui_chkDensity changed val do (refreshControls())
    on ui_chkPadding changed val do (refreshControls())
    on ui_chkConstraintLayer changed val do (refreshControls())
    on ui_chkSwingLimit changed val do (refreshControls())
    on ui_chkTwistLimit changed val do (refreshControls())
    on ui_chkSwingSpring changed val do (refreshControls())
    on ui_chkTwistSpring changed val do (refreshControls())
    on ui_chkSwingDamping changed val do (refreshControls())
    on ui_chkTwistDamping changed val do (refreshControls())

    -- action button events
    on ui_btnUseAll pressed do (setAllCheckboxes true)
    on ui_btnUseNone pressed do (setAllCheckboxes false)
    on ui_btnRestoreDefaults pressed do (restoreDefaults())
    on ui_btnCreateSelected pressed do (local s = selection; performCreate (getSelectedObjects()); select s)
    on ui_btnCreateAll pressed do (local s = selection; performCreate m_controllerList; select s)
    on ui_btnUpdateSelected pressed do (local s = selection; performUpdate (getSelectedObjects()); select s)
    on ui_btnUpdateAll pressed do (local s = selection; performUpdate m_controllerList; select s)
    on ui_btnDestroySelected pressed do (local s = selection; performDestroy (getSelectedObjects()); select s)
    on ui_btnDestroyAll pressed do (local s = selection; performDestroy m_controllerList; select s)
)
