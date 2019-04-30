rollout physicsWireGlobalControllerRollout "Physics Wire Global Controller"
(
    local WIRE_WIDTH = units.decodeValue "3.0mm"
    local DENSITY = 4
    local PADDING = units.decodeValue "0.1mm"
    local SWING_LIMIT = 10
    local TWIST_LIMIT = 10
    local SWING_SPRING = 0.1
    local TWIST_SPRING = 0.1
    local SWING_DAMPING = 100
    local TWIST_DAMPING = 100

    local m_controllerList = #()

    
    multilistbox ui_multiControllers "Wire Controllers" height:10
    button ui_btnRefresh "Refresh" width:60 across:2
    button ui_btnSelect "Select" enabled:false width:60
    button ui_btnPullValues "Pull Values from Selected" enabled:false width:140

    checkbox ui_chkSplineLayer "Spline Layer" checked:true offset:[0,40]
    dropdownlist ui_ddSplineLayer ""
    checkbox ui_chkWireWidth "Width" checked:true across:2
    spinner ui_spinWireWidth "" range:[0.001, 99999999, WIRE_WIDTH] scale:0.1 width:70 align:#right type:#worldunits
    groupBox ui_groupSpline "Spline" offset:[-7, -90] width:150 height:90

    checkbox ui_chkBoneLayer "Bone Layer" checked:true offset:[0,40]
    dropdownlist ui_ddBoneLayer ""
    checkbox ui_chkDensity "Density" checked:true across:2
    spinner ui_spinDensity "" range:[0, 999999, DENSITY] width:70 align:#right
    checkbox ui_chkPadding "Padding" checked:true across:2
    spinner ui_spinPadding "" range:[0, 999999, PADDING] type:#worldUnits width:70 align:#right
    groupBox ui_groupBone "Bones" offset:[-7, -110] width:150 height:110

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

    button ui_btnUseAll "Use All" width:60 across:2
    button ui_btnUseNone "Use None" width:60

    button ui_btnCreateSelected "Create Selected" enabled:false width:140 offset:[0, 40]
    button ui_btnCreateAll "Create All" width:140
    groupBox ui_groupCreate "Create" offset:[-7, -70] width:150 height:70

    button ui_btnUpdateSelected "Update Selected" enabled:false width:140 offset:[0, 20]
    button ui_btnUpdateAll "Update All" width:140
    groupBox ui_groupUpdate "Update" offset:[-7, -70] width:150 height:70

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
    fn controllerFilter obj = ((for m in obj.modifiers where (isKindOf m PhysicsWireController) collect m).count > 0)
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


    on physicsWireGlobalControllerRollout open do (populateListBox())
    on ui_multiControllers selectionEnd do (refreshButtons())
    on ui_multiControllers rightClick do (ui_multiControllers.selection = #{}; refreshButtons())
    on ui_multiControllers doubleClicked val do 
    (
        ui_multiControllers.selection = #{1..ui_multiControllers.items.count}
        refreshButtons()
    )
    on ui_btnRefresh pressed do (populateListbox())
    on ui_btnSelect pressed do (select (getSelectedObjects()))
)
