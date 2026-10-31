---@type ui_runtime.NodeClass
local Node = {
    deps = {},
}
Node.__index = Node

---Returns initialized dependencies or fails on a composition-root wiring error.
---@private
---@return errors.Lib
---@return ui_runtime.Error
local function get_dependencies()
    if Node.deps.errors == nil or Node.deps.ERROR == nil then
        error("ui_runtime Node.init must be called before Node is used", 0)
    end

    return Node.deps.errors, Node.deps.ERROR
end

---Raises one node error with concrete node context.
---@private
---@param root_cause string
---@param context string
local function raise_node_error(root_cause, context)
    local errors = get_dependencies()
    error(errors.wrap(context, errors.new(root_cause)), 0)
end

---Initializes node dependencies.
---@param dependencies ui_runtime.InternalDependencies
---@return ui_runtime.NodeClass
function Node.init(dependencies)
    if dependencies == nil then
        error("ui_runtime Node dependencies are required", 0)
    end

    if dependencies.errors == nil then
        error("ui_runtime Node dependency errors is required", 0)
    end

    if dependencies.ERROR == nil then
        error("ui_runtime Node dependency ERROR is required", 0)
    end

    Node.deps.errors = dependencies.errors
    Node.deps.ERROR = dependencies.ERROR

    return Node
end

---Creates one rendered GUI node wrapper.
---@param component Barotrauma.GUIComponent
---@param node_type string
---@param id string
---@param path string
---@param parent ui_runtime.Node|nil
---@return ui_runtime.Node
function Node.new(component, node_type, id, path, parent)
    ---@type ui_runtime.Node
    local node = {
        id = id,
        type = node_type,
        path = path,
        _component = component,
        children = {},
        index = {},
        parent = parent,
    }
    return setmetatable(node, Node)
end

---Adds one rendered child node and optionally indexes it by local id.
---@param child ui_runtime.Node
---@param indexable boolean|nil
function Node:add_child(child, indexable)
    table.insert(self.children, child)
    if indexable ~= false then
        self.index[child.id] = child
    end
end

---Returns a required descendant by dot path.
---@param path string
---@return ui_runtime.Node
---@throws errors.Error
function Node:get(path)
    local _, ERROR = get_dependencies()
    local current = self
    for segment in string.gmatch(path, "[^%.]+") do
        current = current.index[segment]
        if current == nil then
            raise_node_error(ERROR.node_not_found, string.format("get UI node: %s under %s", path, self.path))
        end
    end
    return current
end

---Returns a descendant by dot path when it exists.
---@param path string
---@return ui_runtime.Node|nil
function Node:maybe(path)
    local current = self
    for segment in string.gmatch(path, "[^%.]+") do
        current = current.index[segment]
        if current == nil then
            return nil
        end
    end
    return current
end

---Returns the wrapped Barotrauma component.
---@return Barotrauma.GUIComponent
function Node:component()
    return self._component
end

---Removes this component from its GUI tree.
function Node:remove()
    self._component.Remove()
end

---Returns the component whose children should be mutated for this node type.
---@private
---@return Barotrauma.GUIComponent
local function get_child_container(self)
    local _, ERROR = get_dependencies()
    if self.type ~= "ListBox" and self.type ~= "ScissorComponent" then
        return self._component
    end

    local content = self._component.Content
    if content == nil then
        raise_node_error(ERROR.content_required, "get UI child container: " .. self.path)
    end

    return content
end

---Removes rendered children from this component and resets node lookup state.
function Node:clear()
    local target = get_child_container(self)
    target.ClearChildren()
    self.children = {}
    self.index = {}
end

---Sets whether this component is enabled.
---@param value boolean
---@throws errors.Error
function Node:set_enabled(value)
    local _, ERROR = get_dependencies()
    if type(value) ~= "boolean" then
        raise_node_error(ERROR.boolean_value_required, "set UI node enabled: " .. self.path)
    end

    self._component.Enabled = value
end

---Sets whether this component is visible.
---@param value boolean
---@throws errors.Error
function Node:set_visible(value)
    local _, ERROR = get_dependencies()
    if type(value) ~= "boolean" then
        raise_node_error(ERROR.boolean_value_required, "set UI node visible: " .. self.path)
    end

    self._component.Visible = value
end

---Sets this component color.
---@param color Microsoft.Xna.Framework.Color
function Node:set_color(color)
    self._component.Color = color
end

---Checks that a typed adapter is requested for the correct JSON node type.
---@private
---@param self ui_runtime.Node
---@param expected string
local function assert_type(self, expected)
    local _, ERROR = get_dependencies()
    if self.type ~= expected then
        raise_node_error(
            ERROR.node_type_mismatch,
            string.format("adapt UI node: %s: expected %s, got %s", self.path, expected, self.type)
        )
    end
end

---Checks that a callback was intentionally provided.
---@private
---@param callback any
---@param context string
local function validate_callback(callback, context)
    local _, ERROR = get_dependencies()
    if type(callback) ~= "function" then
        raise_node_error(ERROR.callback_required, context)
    end
end

---Checks that a numeric runtime value was intentionally provided.
---@private
---@param value any
---@param context string
local function validate_number(value, context)
    local _, ERROR = get_dependencies()
    if type(value) ~= "number" then
        raise_node_error(ERROR.numeric_value_required, context)
    end
end

---Returns one source rectangle field by named or array key.
---@private
---@param source_rect ui_runtime.SourceRect
---@param name string
---@param index integer
---@param context string
---@return number
local function get_source_rect_value(source_rect, name, index, context)
    local value = source_rect[name]
    if value == nil then
        value = source_rect[index]
    end

    if type(value) ~= "number" then
        local _, ERROR = get_dependencies()
        raise_node_error(ERROR.source_rect_invalid, context)
    end

    return value
end

---Creates a TextBlock adapter.
---@return ui_runtime.TextAdapter
function Node:as_text()
    assert_type(self, "TextBlock")
    local component = self._component
    local node_path = self.path
    return {
        set_text = function(_, value)
            local _, ERROR = get_dependencies()
            if type(value) ~= "string" then
                raise_node_error(ERROR.text_required, "set UI text: " .. node_path)
            end

            component.Text = value
        end,
    }
end

---Creates a Button adapter.
---@return ui_runtime.ButtonAdapter
function Node:as_button()
    assert_type(self, "Button")
    local component = self._component
    local node_path = self.path
    return {
        on_click = function(_, callback)
            validate_callback(callback, "bind UI button click: " .. node_path)
            component.OnClicked = function()
                return callback()
            end
        end,
    }
end

---Creates a DropDown adapter.
---@return ui_runtime.DropDownAdapter
function Node:as_dropdown()
    assert_type(self, "DropDown")
    local component = self._component
    local node_path = self.path
    return {
        set_items = function(_, items)
            local _, ERROR = get_dependencies()
            if type(items) ~= "table" then
                raise_node_error(ERROR.dropdown_items_required, "set UI dropdown items: " .. node_path)
            end

            component.ClearChildren()
            for _, item in ipairs(items) do
                component.AddItem(tostring(item), item)
            end
        end,
        set_selected = function(_, value)
            component.SelectItem(value)
        end,
        on_selected = function(_, callback)
            validate_callback(callback, "bind UI dropdown selected: " .. node_path)
            component.OnSelected = function(_, selected)
                callback(selected)
                return true
            end
        end,
    }
end

---Creates a ScrollBar adapter.
---@return ui_runtime.SliderAdapter
function Node:as_slider()
    assert_type(self, "ScrollBar")
    local component = self._component
    local node_path = self.path
    return {
        set_value = function(_, value)
            validate_number(value, "set UI slider value: " .. node_path)
            component.BarScrollValue = value
        end,
        on_changed = function(_, callback)
            validate_callback(callback, "bind UI slider changed: " .. node_path)
            component.OnMoved = function()
                callback(component.BarScrollValue)
                return true
            end
        end,
    }
end

---Creates an Image adapter.
---@return ui_runtime.ImageAdapter
function Node:as_image()
    assert_type(self, "Image")
    local component = self._component
    local node_path = self.path
    return {
        set_sprite = function(_, path, source_rect)
            local _, ERROR = get_dependencies()
            if type(path) ~= "string" or path == "" then
                raise_node_error(ERROR.sprite_path_required, "set UI image sprite: " .. node_path)
            end

            local sprite
            if source_rect ~= nil then
                if type(source_rect) ~= "table" then
                    raise_node_error(ERROR.source_rect_invalid, "set UI image sprite source rectangle: " .. node_path)
                end

                sprite = Sprite(
                    path,
                    Rectangle(
                        get_source_rect_value(source_rect, "x", 1, "set UI image sprite source x: " .. node_path),
                        get_source_rect_value(source_rect, "y", 2, "set UI image sprite source y: " .. node_path),
                        get_source_rect_value(
                            source_rect,
                            "width",
                            3,
                            "set UI image sprite source width: " .. node_path
                        ),
                        get_source_rect_value(
                            source_rect,
                            "height",
                            4,
                            "set UI image sprite source height: " .. node_path
                        )
                    ),
                    Vector2(0.5, 0.5),
                    0
                )
            else
                sprite = Sprite(path, nil, Vector2(0.5, 0.5), 0)
            end
            component.Sprite = sprite
        end,
        set_offset = function(_, x, y)
            validate_number(x, "set UI image offset x: " .. node_path)
            validate_number(y, "set UI image offset y: " .. node_path)
            component.RectTransform.AbsoluteOffset = Point(x, y)
        end,
        set_size = function(_, width, height)
            validate_number(width, "set UI image width: " .. node_path)
            validate_number(height, "set UI image height: " .. node_path)
            component.RectTransform.IsFixedSize = true
            component.RectTransform.NonScaledSize = Point(width, height)
        end,
    }
end

---Creates a generic container adapter.
---@return ui_runtime.ContainerAdapter
function Node:as_container()
    local node = self
    return {
        _node = node,
        clear = function()
            node:clear()
        end,
    }
end

return Node
