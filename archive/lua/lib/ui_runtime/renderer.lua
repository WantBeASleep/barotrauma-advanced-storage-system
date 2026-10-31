---@type ui_runtime.RendererLoadArgs
local load_args = ...

if load_args == nil then
    error("ui_runtime renderer load args are required", 0)
end

if load_args.module_path == nil then
    error("ui_runtime renderer load arg module_path is required", 0)
end

local Node = assert(loadfile(load_args.module_path .. "/node.lua"))()
local Tree = assert(loadfile(load_args.module_path .. "/tree.lua"))()

---@type ui_runtime.Renderer
local renderer = {
    deps = {},
}

local ANCHOR_NAMES = {
    BottomCenter = true,
    BottomLeft = true,
    BottomRight = true,
    Center = true,
    CenterLeft = true,
    CenterRight = true,
    TopCenter = true,
    TopLeft = true,
    TopRight = true,
}

---Returns initialized dependencies or fails on a composition-root wiring error.
---@private
---@return errors.Lib
---@return logger.logger
---@return ui_runtime.Error
local function get_dependencies()
    if renderer.deps.errors == nil or renderer.deps.log == nil or renderer.deps.ERROR == nil then
        error("ui_runtime renderer.init must be called before renderer is used", 0)
    end

    return renderer.deps.errors, renderer.deps.log, renderer.deps.ERROR
end

---Raises one renderer error with operation context.
---@private
---@param root_cause string
---@param context string
local function raise_renderer_error(root_cause, context)
    local errors = get_dependencies()
    error(errors.wrap(context, errors.new(root_cause)), 0)
end

---Initializes renderer dependencies and its loaded model classes.
---@param dependencies ui_runtime.InternalDependencies
---@return ui_runtime.Renderer
function renderer.init(dependencies)
    if dependencies == nil then
        error("ui_runtime renderer dependencies are required", 0)
    end

    if dependencies.errors == nil then
        error("ui_runtime renderer dependency errors is required", 0)
    end

    if dependencies.log == nil then
        error("ui_runtime renderer dependency log is required", 0)
    end

    if dependencies.ERROR == nil then
        error("ui_runtime renderer dependency ERROR is required", 0)
    end

    renderer.deps.errors = dependencies.errors
    renderer.deps.log = dependencies.log
    renderer.deps.ERROR = dependencies.ERROR

    Node.init({
        errors = dependencies.errors,
        ERROR = dependencies.ERROR,
    })
    Tree.init({
        errors = dependencies.errors,
        ERROR = dependencies.ERROR,
    })

    return renderer
end

---Returns a Barotrauma enum value for a validated layout enum name.
---@private
---@param enum table
---@param name string|nil
---@param default any
---@return any
local function enum_value(enum, name, default)
    if name == nil then
        return default
    end

    return enum[name]
end

---Builds a color from a validated `[r, g, b, a]` array.
---@private
---@param value table|nil
---@return Microsoft.Xna.Framework.Color|nil
local function make_color(value)
    if value == nil then
        return nil
    end

    return Color(value[1], value[2], value[3], value[4])
end

---Builds a fixed or relative RectTransform size from a validated node.
---@private
---@param node table
---@return Microsoft.Xna.Framework.Vector2|Microsoft.Xna.Framework.Point
local function make_size(node)
    if node.fixedSize ~= nil then
        return Point(node.fixedSize[1], node.fixedSize[2])
    end

    return Vector2(node.size[1], node.size[2])
end

---Builds one RectTransform for a validated layout node.
---@private
---@param node table
---@param parent_transform Barotrauma.RectTransform
---@return Barotrauma.RectTransform
local function make_rect(node, parent_transform)
    local anchor = enum_value(GUI.Anchor, node.anchor, GUI.Anchor.TopLeft)
    local pivot = enum_value(GUI.Pivot, node.pivot, GUI.Pivot.TopLeft)
    if ANCHOR_NAMES[node.anchor] and node.pivot == nil then
        return GUI.RectTransform(make_size(node), parent_transform, anchor)
    end
    return GUI.RectTransform(make_size(node), parent_transform, anchor, pivot)
end

---Returns whether a path is absolute on Windows or Unix-like paths.
---@private
---@param path string
---@return boolean
local function is_absolute_path(path)
    return string.match(path, "^%a:[/\\]") ~= nil or string.sub(path, 1, 1) == "/"
end

---Resolves a layout asset path using the caller-provided mod path.
---@private
---@param path string
---@param mod_path string|nil
---@return string
---@throws errors.Error
local function resolve_asset_path(path, mod_path)
    local _, _, ERROR = get_dependencies()
    if is_absolute_path(path) then
        return path
    end
    if mod_path == nil or mod_path == "" then
        raise_renderer_error(ERROR.relative_asset_mod_path_required, "resolve UI asset path: " .. path)
    end
    return mod_path .. "/" .. path
end

---Applies properties common to all rendered components.
---@private
---@param component Barotrauma.GUIComponent
---@param spec table
local function apply_common(component, spec)
    component.UserData = spec.id
    if spec.canBeFocused ~= nil then
        component.CanBeFocused = spec.canBeFocused
    end

    local color = make_color(spec.color)
    if color ~= nil then
        component.Color = color
    end
    local hover_color = make_color(spec.hoverColor)
    if hover_color ~= nil then
        component.HoverColor = hover_color
    end
    local selected_color = make_color(spec.selectedColor)
    if selected_color ~= nil then
        component.SelectedColor = selected_color
    end
    if spec.absoluteOffset ~= nil then
        component.RectTransform.AbsoluteOffset = Point(spec.absoluteOffset[1], spec.absoluteOffset[2])
    end
end

---Applies properties specific to GUILayoutGroup.
---@private
---@param layout Barotrauma.GUILayoutGroup
---@param spec table
local function apply_layout_props(layout, spec)
    if spec.stretch ~= nil then
        layout.Stretch = spec.stretch
    end
    if spec.childAnchor ~= nil then
        layout.ChildAnchor = enum_value(GUI.Anchor, spec.childAnchor, GUI.Anchor.TopLeft)
    end
    if spec.relativeSpacing ~= nil then
        layout.RelativeSpacing = spec.relativeSpacing
    end
    if spec.absoluteSpacing ~= nil then
        layout.AbsoluteSpacing = spec.absoluteSpacing
    end
end

---Returns static text for components whose label may intentionally be empty.
---@private
---@param spec table
---@return string
local function get_static_text(spec)
    if spec.text == nil then
        return ""
    end

    return spec.text
end

---Creates an Image component for a validated image layout node.
---@private
---@param spec table
---@param rect Barotrauma.RectTransform
---@param diagnostics ui_runtime.Diagnostics
---@param mod_path string|nil
---@return Barotrauma.GUIComponent
---@throws errors.Error
local function create_image(spec, rect, diagnostics, mod_path)
    local _, _, ERROR = get_dependencies()
    if spec.path == nil then
        table.insert(diagnostics.warnings, {
            id = spec.id,
            kind = "image_missing_path",
            message = "Image node has no static path; set sprite from Lua if this is intentional.",
        })
        return GUI.Image(rect, nil, spec.scaleToFit ~= false)
    end

    local full_path = resolve_asset_path(spec.path, mod_path)
    local ok, sprite = pcall(function()
        if spec.sourceRect ~= nil then
            return Sprite(
                full_path,
                Rectangle(spec.sourceRect[1], spec.sourceRect[2], spec.sourceRect[3], spec.sourceRect[4]),
                Vector2(0.5, 0.5),
                0
            )
        end
        return Sprite(full_path, nil, Vector2(0.5, 0.5), 0)
    end)

    if not ok then
        raise_renderer_error(ERROR.image_load_failed, "load UI image: " .. full_path .. ": " .. tostring(sprite))
    end

    return GUI.Image(rect, sprite, spec.scaleToFit ~= false)
end

---Returns the transform that should parent children for this component type.
---@private
---@param component Barotrauma.GUIComponent
---@param node_type string
---@param path string
---@return Barotrauma.RectTransform
---@throws errors.Error
local function get_child_parent_transform(component, node_type, path)
    local _, _, ERROR = get_dependencies()
    if node_type ~= "ListBox" and node_type ~= "ScissorComponent" then
        return component.RectTransform
    end

    local content = component.Content
    if content == nil then
        raise_renderer_error(ERROR.content_required, "get UI content transform: " .. path)
    end

    return content.RectTransform
end

---Creates the GUI component for one validated layout node.
---@private
---@param spec table
---@param rect Barotrauma.RectTransform
---@param diagnostics ui_runtime.Diagnostics
---@param mod_path string|nil
---@return Barotrauma.GUIComponent
---@throws errors.Error
local function create_component(spec, rect, diagnostics, mod_path)
    local _, _, ERROR = get_dependencies()
    local node_type = spec.type
    local style = spec.style

    if node_type == "Frame" then
        local color = make_color(spec.color)
        if color ~= nil then
            return GUI.Frame(rect, style, color)
        end
        if style ~= nil then
            return GUI.Frame(rect, style)
        end
        return GUI.Frame(rect)
    elseif node_type == "LayoutGroup" then
        local component = GUI.LayoutGroup(rect, spec.direction == "horizontal")
        apply_layout_props(component, spec)
        return component
    elseif node_type == "TextBlock" then
        local component = GUI.TextBlock(
            rect,
            get_static_text(spec),
            make_color(spec.textColor),
            nil,
            enum_value(GUI.Alignment, spec.alignment, GUI.Alignment.CenterLeft)
        )
        if spec.textScale ~= nil then
            component.TextScale = spec.textScale
        end
        return component
    elseif node_type == "Button" then
        if style ~= nil then
            return GUI.Button(rect, get_static_text(spec), GUI.Alignment.Center, style)
        end
        return GUI.Button(rect, get_static_text(spec))
    elseif node_type == "DropDown" then
        return GUI.DropDown(rect, "", spec.maxVisibleItems)
    elseif node_type == "ListBox" then
        local component = GUI.ListBox(rect, spec.isHorizontal == true, nil, style)
        if spec.spacing ~= nil then
            component.Spacing = spec.spacing
        end
        if spec.autoHideScrollBar ~= nil then
            component.AutoHideScrollBar = spec.autoHideScrollBar
        end
        if spec.keepSpaceForScrollBar ~= nil then
            component.KeepSpaceForScrollBar = spec.keepSpaceForScrollBar
        end
        return component
    elseif node_type == "ScrollBar" then
        local component = GUI.ScrollBar(rect, spec.barSize, nil, style)
        if spec.range ~= nil then
            component.Range = Vector2(spec.range[1], spec.range[2])
        end
        if spec.step ~= nil then
            component.StepValue = spec.step
        end
        return component
    elseif node_type == "TickBox" then
        return GUI.TickBox(rect, get_static_text(spec))
    elseif node_type == "Image" then
        return create_image(spec, rect, diagnostics, mod_path)
    elseif node_type == "ScissorComponent" then
        return GUI.ScissorComponent(rect)
    end

    raise_renderer_error(ERROR.component_type_unknown, "create UI component: " .. tostring(node_type))
end

local render_node

---Renders one validated layout node and its children.
---@private
---@param spec table
---@param parent_transform Barotrauma.RectTransform
---@param parent_node ui_runtime.Node|nil
---@param path string
---@param diagnostics ui_runtime.Diagnostics
---@param mod_path string|nil
---@param indexable boolean
---@return ui_runtime.Node
---@throws errors.Error
-- selene: allow(high_cyclomatic_complexity)
function render_node(spec, parent_transform, parent_node, path, diagnostics, mod_path, indexable)
    local rect = make_rect(spec, parent_transform)
    local component = create_component(spec, rect, diagnostics, mod_path)
    local node = Node.new(component, spec.type, spec.id, path, parent_node)

    apply_common(component, spec)

    if parent_node ~= nil then
        parent_node:add_child(node, indexable)
    end

    local child_parent = get_child_parent_transform(component, spec.type, path)
    if type(spec.children) == "table" then
        for _, child in ipairs(spec.children) do
            render_node(child, child_parent, node, path .. "." .. tostring(child.id), diagnostics, mod_path, true)
        end
    end

    return node
end

---Returns a normalized render options table.
---@private
---@param options ui_runtime.RenderOptions|nil
---@return ui_runtime.RenderOptions
local function get_render_options(options)
    if options == nil then
        return {}
    end

    return options
end

---Renders one validated UI layout.
---@param layout table
---@param parent Barotrauma.RectTransform
---@param options ui_runtime.RenderOptions|nil
---@return ui_runtime.Tree
---@throws errors.Error
function renderer.render(layout, parent, options)
    local _, log, ERROR = get_dependencies()
    local render_options = get_render_options(options)
    local diagnostics = { warnings = {} }
    local templates = layout.templates
    if templates == nil then
        templates = {}
    end

    log:trace("rendering UI root: " .. tostring(layout.root.id))
    local root =
        render_node(layout.root, parent, nil, tostring(layout.root.id), diagnostics, render_options.mod_path, true)
    local tree = Tree.new(root, templates, diagnostics)

    tree.instantiate = function(template_name, parent_node)
        log:trace("rendering UI template: " .. tostring(template_name))

        local template = tree.templates[template_name]
        if template == nil then
            raise_renderer_error(ERROR.template_not_found, "render UI template: " .. tostring(template_name))
        end
        if parent_node == nil or parent_node:component() == nil then
            raise_renderer_error(ERROR.template_parent_required, "render UI template: " .. tostring(template_name))
        end

        local parent_transform = get_child_parent_transform(parent_node:component(), parent_node.type, parent_node.path)

        return render_node(
            template,
            parent_transform,
            parent_node,
            parent_node.path .. "." .. tostring(template.id),
            diagnostics,
            render_options.mod_path,
            false
        )
    end

    return tree
end

return renderer
