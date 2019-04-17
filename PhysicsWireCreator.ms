plugin modifier phyiscsWireController
name:"Physics Wire Controller"
classID:#(0x5c1773b9, 0x75d4f467)
replaceUI:off
silentErrors:off
version:1
(
    fn getLayerNames =
    (
        local layerList = #()
		for i = 0 to (LayerManager.count-1) do (append layerList (LayerManager.getLayer i).name)
        layerList -- return
    )

    fn setDropdownSelection dropDown selectionText =
    (
        local index = findItem dropDown.items selectionText
        if index == 0 then false else (dropDown.selection = index; true)
    )

    fn setupDropdown dropDown selectionText =
    (
        dropDown.items = getLayerNames()
        local found = setDropdownSelection dropDown selectionText
        if found == false then found = setDropdownSelection dropDown LayerManager.current.name
        if found == false then dropDown.selection = 0
    )


    parameters splineData rollout:splineRollout
    (
        nSpline type:#node ui:ui_pickSplineObj
        sSplineLayer type:#string
        fWireWidth type:#worldUnits default:0.125 ui:ui_spinWireWidth
    )

    parameters boneData rollout:bonesRollout
    (
        ntBones type:#nodeTab tabSizeVariable:true
        sBoneLayer type:#string
        bStartAnchor type:#boolean default:true
        bEndAnchor type:#boolean default:false
        fDensity type:#float default:4
        fCollisionPadding type:#worldUnits default:0.01
    )

    parameters constraintData rollout:constraintsRollout
    (
        ntConstraints type:#nodeTab tabSizeVariable:true
        sConstraintLayer type:#string
        aSwingAngle type:#angle default:10
        fSwingSpring type:#float default:0.1
        fSwingDampening type:#float default:100
        aTwistAngle type:#angle default:10
        fTwistSpring type:#float default:0.1
        fTwistDamping type:#float default:100
    )

    parameters endObjectData rollout:endObjectRollout
    (
        nEndObject type:#node tabSizeVariable:true
        sEndObjectLayer type:#string
    )


    rollout splineRollout "Spline"
    (
        -- FILTERS
        fn filterSpline obj = (IsShapeObject obj)

        -- UI ELEMENTS
        pickButton ui_pickSplineObj "Pick Spline" message:"Pick a spline object that will be the wire." \
                                    autoDisplay:true filter:filterSpline width:140
        dropdownlist ui_ddLayer "Layer"
        spinner ui_spinWireWidth "Wire Width" range:[0.001, 99999999, fWireWidth] scale:0.1

        -- EVENTS
        on splineRollout open do (setupDropdown ui_ddLayer sSplineLayer; sSplineLayer = ui_ddLayer.selected)
        on ui_pickSplineObj picked obj do (nSpline = obj)
        on ui_pickSplineObj rightClick do (ui_pickSplineObj.object = nSpline = undefined)
        on ui_ddLayer selected index do (sSplineLayer = ui_ddLayer.selected)
    )

    rollout bonesRollout "Bones"
    (
        fn getBoneNames = (for b in ntBones collect b.name)

        multilistbox ui_multiBones "Bones"
        button ui_butSelect "Select" enabled:false align:#right
        dropdownlist ui_ddLayer "Layer"
        groupBox ui_groupAnchor "Anchors"
        checkbox ui_chkStartAnchor "Start" checked:bStartAnchor align:#left across:2
        checkbox ui_chkEndAnchor "End" checked:bEndAnchor align:#right
    )

    rollout constraintsRollout "Constraints"
    (

    )

    rollout endObjectRollout "End Object"
    (

    )
)
