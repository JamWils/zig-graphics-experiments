# Setting Up VSCode

I set up a launch config and task script for VSCode.  Make sure that the Vulkan SDK path is correct.  So far this has only been tested on windows.

**launch.json**

```json
{
    "version":"0.2.0",
    "configurations": [    
        {
            "name": "Launch",
            "type": "cppdbg",
            "request": "launch",
            "program": "${workspaceFolder}/zig-out/bin/vulkan-experiments",
            "args": [],
            "stopAtEntry": false,
            "cwd": "${workspaceFolder}",
            "environment": [
                {
                    "name": "VK_SDK_PATH",
                    "value": "C:/VulkanSDK/1.3.261.1",
                }
            ],
            "preLaunchTask": "build engine",
            "osx": { "MIMode": "lldb" },
            "windows": {
                "type": "cppvsdbg",
                "console": "integratedTerminal"
            },
        }
    ]
}
```

**tasks.json**

```json
{
    "version":"2.0.0",
    "tasks": [
        {
            "label": "build engine",
            "type": "shell",
            "command": "zig",
            "args": ["build"],
            "problemMatcher": [],
            "group": "build",
        }
    ]
}
```
