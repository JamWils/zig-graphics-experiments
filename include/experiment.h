#ifndef EXPERIMENT_H
#define EXPERIMENT_H

#include <stdbool.h>

struct exp_counter_t {
    int value;
};

typedef struct world_t {
} world_t;

typedef struct entity_t {
} entity_t;

typedef struct entity_desc_t {
} entity_desc_t;

world_t* exp_world_init();

void exp_app_init(world_t* world);

entity_t exp_entity_init(world_t* world, const entity_desc_t* desc);

bool exp_world_progress(world_t* world, float delta_time);

int exp_world_fini(world_t* world);

#endif