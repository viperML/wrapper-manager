---
title: API
---

# API Documentation

The following are all the options that you can use in wrapper-manager.


<script setup>
import { data } from "./wm.data.js";
import { RenderDocs } from "easy-nix-documentation";
</script>

## Main API

<RenderDocs :options="data" :exclude="[/^_module\.args$/, /^build\.*/, /programs/]"  />

## Program configuration

<RenderDocs :options="data" :include="[/programs/]" />

## Outputs

<RenderDocs :options="data" :include="/^build\.*/" />
