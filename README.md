# 3DSMax_PhysicsWireCreator

*****************************************************************
What is this?
*****************************************************************

Physics Wire Creator is a 3DS Max plugin to quickly and easily rig splines to act like electrical wires for MassFX physics simulation. You can also quickly and easily modify a wire to fine tune its behavior. There is also a global utility to create and modify all wires in a scene.

Unlike rope simulations, this can be configured to give the wire some resistence to outside forces to more or less retain its bent shape, as you would expect something like a copper wire to do in the real world.

This uses only built in features in 3DS Max to rig the wire. Bones are created between each successive pair of spline control points. These bones are given MassFX rigid bodies for collisions and each bone is constrained to each other using UConstraints. The constraints allow for various degrees of swing and twist as well as spring and dampening amounts.

When rigged, the wire will be affected by outside forces, such as gravity, and will collide with other rigid bodies.

Wires can be anchored on one or both ends. When an end is anchored, that end will not be affected by forces. This can be used to "attach" an end of the wire to another object.

Other objects can be attached to either end of the wire. If that end of the wire is not anchored, then the attached object will move with that end (using position and orientation constraints).



*****************************************************************
How do I install this plugin?
*****************************************************************

Simply clone this repository straight into your 3DS Max plugins folder, usually located in:
"C:\Program Files\Autodesk\3ds Max 2XXX\plugins"
Once added, restart 3DS Max.

This script was tested in 3DS Max 2016 only, so I am not sure if it works in other versions.



*****************************************************************
How do I use it?
*****************************************************************

1) Create a spline object, shaping it as desired.

2) Create a dummy or point helper (This will contain the elements of the rig as well as the spline and will be the controller for the wire).

3) Add the modifier "Physics Wire Controller" to the helper object.

4) Press the "Pick Spline" picker button and select the spline.

5) Use the controls in the modifier to configure the properties of the wire (width, swing and twist properties, etc)
Press the "Create Wire" button and the wire rigging will be built.

6) Test behavior by running the MassFX simulation.



*****************************************************************
How do I make modifications?
*****************************************************************

1) Select the helper object that contains the modifier.

2) Select the modifier in the Modify tab.

3) Make changes to any controls as desired.

4) Press the "Update Wire" button and the wire will be updated with the changed configurations.



*****************************************************************
How do I remove the wire rigging?
*****************************************************************

1) Select the helper object that contains the modifier.

2) Select the modifier in the Modify tab.

3) Press the "Destroy Wire" to automatically delete all rigging objects and all modifiers from the spline. The spline itself will not be deleted.



*****************************************************************
How do I modify several or all created wires in a scene?
*****************************************************************

1) Go to the Utilities tab.

2) Select the "MAXScript" utility. This is make the "MAXScript" rollout appear.

3) Within the "MAXScript" rollout, select "Physics Wire Global Controller" from the dropdown. This will make the "Physics Wire Global Controller" rollout appear.

4) Within the "Physics Wire Global Controller" rollout, press the "Open Dialog" button to bring up the global controls.

In this popup, a list of all objects that contain the "Physics Wire Controller" modifier will appear. From here, you can re-create/update/destroy selected objects or all objects from the list box.

Each property in the popup has a checkbox next to it. When checked, that property will be applied to the objects you are re-creating/modifying, otherwise that property will not be changed for each object. This allows you to globally change only certain properties as desired on all or selected wires.



*****************************************************************
Disclaimer
*****************************************************************

Be sure to back up your projects before making use of this plugin, just in case.
