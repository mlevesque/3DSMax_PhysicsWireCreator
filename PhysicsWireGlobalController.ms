filein "PhysicsWireGlobalControllerRollout.ms"

utility PhysicsWireGlobalController "Physics Wire Global Controller"
(
    button ui_btnOpenDialog "Open Dialog"

    on ui_btnOpenDialog pressed do
    (
        CreateDialog physicsWireGlobalControllerRollout
    )
)
