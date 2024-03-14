const std = @import("std");
const ecs = @import("flecs");
const scene = @import("scene");

pub const exp_component_decs_t = ecs.component_desc_t;
pub const exp_entity_desc_t = ecs.entity_desc_t;

pub const exp_counter_t = extern struct{
    value: i32,
};

export fn exp_world_init() *ecs.world_t {
    std.debug.print("Initializing world\n", .{});
    return ecs.init();
}

export fn exp_app_init(world: *ecs.world_t) void {
    std.debug.print("Initializing app\n", .{});
    ecs.COMPONENT(world, exp_counter_t);
    _ = ecs.singleton_set(world, exp_counter_t, .{.value = 0 });

    var counter_desc = ecs.system_desc_t{};
    counter_desc.callback = sampleCounter;
    counter_desc.query.filter.terms[0] = .{ 
        .id = ecs.id(exp_counter_t), 
        .src = .{
            .id = ecs.id(exp_counter_t), 
        },
    };

    _ = ecs.SYSTEM(world, "SampleCounter", ecs.OnUpdate, &counter_desc);
}

fn sampleCounter(it: *ecs.iter_t) callconv(.C) void {
    var counter = ecs.singleton_get_mut(it.world, exp_counter_t).?;

    if (counter.value >= 1000) {
        counter.value = 0;
    }
    
    counter.value += 1;
    std.debug.print("Counter: {}\n", .{counter.value});
}


export fn exp_world_progress(world: *ecs.world_t, delta_time: f32) bool {
    return ecs.progress(world, delta_time);
}

export fn exp_entity_init(world: *ecs.world_t, desc: *const ecs.entity_desc_t) ecs.entity_t {
    return ecs.entity_init(world, desc);
}

export fn exp_world_fini(world: *ecs.world_t) i32 {
    std.debug.print("Finalizing world\n", .{});
    return ecs.fini(world);
}