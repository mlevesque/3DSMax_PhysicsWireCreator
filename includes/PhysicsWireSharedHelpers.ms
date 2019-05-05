struct PhysicsWireSharedHelpers
(
    /**
        Returns array of layer names.

        @return Array of strings.
    */
    fn getLayerNames =
    (
        local layerList = #()
        for i = 0 to (LayerManager.count-1) do (append layerList (LayerManager.getLayer i).name)
        layerList -- return
    ),

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
    ),

    /**
        Populates the given dropdown and selects the entry matching the given string. If the given string could not be
        found, then it will try to select the current layer name. If that doesn't work, then will just set selection to
        zero (nothing).

        @param dropDown
            The dropdown UI.
        @param selectionLayer
            The layer name to find in the dropdown and select.
    */
    fn setupDropdownForLayers dropDown selectionLayer =
    (
        dropDown.items = getLayerNames()
        local found = setDropdownSelection dropDown selectionLayer
        if found == false then found = setDropdownSelection dropDown LayerManager.current.name
        if found == false then dropDown.selection = 0
    )
)
