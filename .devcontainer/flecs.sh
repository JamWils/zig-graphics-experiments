# Copy flecs src to library folder

cp /opt/flecs-3.2.7/flecs.h /workspaces/zig-graphics-experiments/libs/flecs/libs/flecs
cp /opt/flecs-3.2.7/flecs.c /workspaces/zig-graphics-experiments/libs/flecs/libs/flecs

# cp -r /opt/flecs-3.2.11/include /workspaces/zig-graphics-experiments/libs/flecs/libs
# cp -r /opt/flecs-3.2.11/src /workspaces/zig-graphics-experiments/libs/flecs/libs
# cp /opt/flecs-3.2.11/LICENSE /workspaces/zig-graphics-experiments/libs/flecs/libs

# Remove C++ addon since zig doesn't support translating C++ headers
# rm -rf /workspaces/zig-graphics-experiments/libs/flecs/libs/include/flecs/addons/cpp
