---@type ui_runtime.LoadArgs
local load_args = ...

if load_args == nil then
    error("ui_runtime load args are required", 0)
end

if load_args.module_path == nil then
    error("ui_runtime load arg module_path is required", 0)
end

---@type ui_runtime.Lib
local ui_runtime = {
    deps = {},
    ERROR = {
        dependencies_required = "ui_runtime dependencies are required",
        errors_required = "ui_runtime errors dependency is required",
        log_required = "ui_runtime log dependency is required",
        path_required = "ui layout path is required",
        open_failed = "ui layout open failed",
        read_failed = "ui layout read failed",
        close_failed = "ui layout close failed",
        empty_file = "ui layout file is empty",
        json_parse_failed = "ui layout JSON parse failed",
        parsed_layout_required = "ui parsed layout must be an object",
        layout_required = "ui layout must be an object",
        schema_invalid = "ui layout schema is invalid",
        unknown_top_level_field = "ui layout has unknown top-level field",
        node_required = "ui layout node must be an object",
        node_type_invalid = "ui layout node type is invalid",
        node_id_required = "ui layout node id is required",
        dynamic_field = "ui layout dynamic field is not allowed",
        unknown_field = "ui layout node has unknown field",
        size_conflict = "ui layout node cannot use size and fixedSize together",
        size_required = "ui layout node size or fixedSize is required",
        number_pair_required = "ui layout field must be a number pair",
        number_quad_required = "ui layout field must be a number quad",
        color_required = "ui layout color field is invalid",
        children_array_required = "ui layout children must be an array",
        duplicate_child_id = "ui layout has duplicate child id",
        templates_required = "ui layout templates must be an object",
        template_name_required = "ui layout template name is required",
        string_required = "ui layout field must be a string",
        number_required = "ui layout field must be a number",
        boolean_required = "ui layout field must be a boolean",
        enum_invalid = "ui layout enum value is invalid",
        component_type_unknown = "ui component type is unknown",
        relative_asset_mod_path_required = "ui relative asset path requires mod_path",
        image_load_failed = "ui image load failed",
        content_required = "ui component content is required",
        node_not_found = "ui node was not found",
        node_type_mismatch = "ui node type mismatch",
        tree_instantiator_required = "ui tree template instantiator is required",
        template_not_found = "ui template was not found",
        template_parent_required = "ui template parent is required",
        dropdown_items_required = "ui dropdown items are required",
        callback_required = "ui callback is required",
        text_required = "ui text value is required",
        sprite_path_required = "ui sprite path is required",
        source_rect_invalid = "ui sprite source rectangle is invalid",
        numeric_value_required = "ui numeric value is required",
        boolean_value_required = "ui boolean value is required",
    },
}

local layout_loader = assert(loadfile(load_args.module_path .. "/layout_loader.lua"))()
local validator = assert(loadfile(load_args.module_path .. "/validator.lua"))()
local renderer = assert(loadfile(load_args.module_path .. "/renderer.lua"))({
    module_path = load_args.module_path,
})

---Returns initialized dependencies or fails on a composition-root wiring error.
---@private
---@return errors.Lib
---@return logger.logger
local function get_dependencies()
    if ui_runtime.deps.errors == nil or ui_runtime.deps.log == nil then
        error("ui_runtime.init must be called before ui_runtime is used", 0)
    end

    return ui_runtime.deps.errors, ui_runtime.deps.log
end

---Initializes runtime dependencies for the UI runtime library.
---@param dependencies ui_runtime.Dependencies
---@return ui_runtime.Lib
function ui_runtime.init(dependencies)
    if dependencies == nil then
        error("ui_runtime dependencies are required", 0)
    end

    if dependencies.errors == nil then
        error("ui_runtime dependency errors is required", 0)
    end

    if dependencies.log == nil then
        error("ui_runtime dependency log is required", 0)
    end

    ui_runtime.deps.errors = dependencies.errors
    ui_runtime.deps.log = dependencies.log

    layout_loader.init({
        errors = dependencies.errors,
        log = dependencies.log,
        ERROR = ui_runtime.ERROR,
    })
    validator.init({
        errors = dependencies.errors,
        ERROR = ui_runtime.ERROR,
    })
    renderer.init({
        errors = dependencies.errors,
        log = dependencies.log,
        ERROR = ui_runtime.ERROR,
    })

    dependencies.log:trace("ui_runtime initialized")

    return ui_runtime
end

---Loads and parses one JSON UI layout file.
---@param path string
---@return table
---@throws errors.Error
function ui_runtime.load_layout(path)
    local _, log = get_dependencies()
    log:trace("loading UI layout: " .. tostring(path))

    local layout = layout_loader.load(path)

    log:trace("loaded UI layout: " .. tostring(path))
    return layout
end

---Validates one parsed UI layout.
---@param layout table
---@throws errors.Error
function ui_runtime.validate(layout)
    local _, log = get_dependencies()
    log:trace("validating UI layout")

    validator.validate(layout)

    log:trace("validated UI layout")
end

---Validates and renders one UI layout into Barotrauma GUI components.
---@param layout table
---@param parent Barotrauma.RectTransform
---@param options ui_runtime.RenderOptions|nil
---@return ui_runtime.Tree
---@throws errors.Error
function ui_runtime.render(layout, parent, options)
    local _, log = get_dependencies()
    log:trace("rendering UI layout")

    validator.validate(layout)
    local tree = renderer.render(layout, parent, options)

    log:trace("rendered UI layout")
    return tree
end

return ui_runtime
