/** Params for modifying bone properties */
struct PhysicsWireBoneParams
(
    bStartAnchor,
    bEndAnchor,
    fWireWidth,
    fCollisionPadding,
    fDensity,
    sPrefixName,
    sBoneLayer
)

/** Params for modifying constraint properties */
struct PhysicsWireConstraintParams
(
    fSwingAngle,
    fSwingSpring,
    fSwingDampening,
    fTwistAngle,
    fTwistSpring,
    fTwistDampening,
    fWireWidth,
    sPrefixName,
    sConstraintLayer
)

/** Params for modifying spline properties */
struct PhysicsWireSplineParams
(
    fWireWidth,
    sPrefixName,
    sSplineLayer
)
