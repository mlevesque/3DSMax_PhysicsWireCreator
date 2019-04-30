rollout physicsWireGlobalControllerRollout "Physics Wire Global Controller"
(
    local m_controllerList = #()

    
    multilistbox ui_multiControllers "Wire Controllers" height:10
    button ui_btnSelect "Select" enabled:false


    fn refreshButtons =
    (
        ui_btnSelect.enabled = not ui_multiControllers.selection.isEmpty
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
    on ui_btnSelect pressed do (select (getSelectedObjects()))
)
