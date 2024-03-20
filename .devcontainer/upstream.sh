# If you are running this on windows in a dev container then you may need to run
# dos2unix flecs.sh to clear newline characters from the script file #windows-can-make-me-sad

# Copy flecs src to library folder
cp /opt/flecs-3.2.7/flecs.h /workspaces/zig-graphics-experiments/libs/flecs/upstream/flecs
cp /opt/flecs-3.2.7/flecs.c /workspaces/zig-graphics-experiments/libs/flecs/upstream/flecs
cp /opt/flecs-3.2.7/LICENSE /workspaces/zig-graphics-experiments/libs/flecs/upstream/flecs

IMGUI_VERSION="1.90.4"
cp -r /opt/imgui-${IMGUI_VERSION}/*.h /opt/imgui-${IMGUI_VERSION}/*.cpp /workspaces/zig-graphics-experiments/libs/imgui/upstream
cp -r /opt/imgui-${IMGUI_VERSION}/LICENSE.txt /workspaces/zig-graphics-experiments/libs/imgui/upstream/

CIMGUI_VERSION="1.53.1"
cp -r /opt/cimgui-${CIMGUI_VERSION}/cimgui/cimgui.h /opt/cimgui-${CIMGUI_VERSION}/cimgui/cimgui.cpp /workspaces/zig-graphics-experiments/libs/imgui/src

# cp -r /opt/flecs-3.2.11/include /workspaces/zig-graphics-experiments/libs/flecs/libs
# cp -r /opt/flecs-3.2.11/src /workspaces/zig-graphics-experiments/libs/flecs/libs
# cp /opt/flecs-3.2.11/LICENSE /workspaces/zig-graphics-experiments/libs/flecs/libs

# Remove C++ addon since zig doesn't support translating C++ headers
# rm -rf /workspaces/zig-graphics-experiments/libs/flecs/libs/include/flecs/addons/cpp
