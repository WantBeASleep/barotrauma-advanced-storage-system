---@type ui_runtime.Validator
local validator = {
    deps = {},
}

local SCHEMA = "barotrauma-ui-layout/v1"

local NODE_TYPES = {
    Button = true,
    DropDown = true,
    Frame = true,
    Image = true,
    LayoutGroup = true,
    ListBox = true,
    ScissorComponent = true,
    ScrollBar = true,
    TextBlock = true,
    TickBox = true,
}

local COMMON_FIELDS = {
    absoluteOffset = true,
    anchor = true,
    canBeFocused = true,
    children = true,
    color = true,
    fixedSize = true,
    hoverColor = true,
    id = true,
    pivot = true,
    selectedColor = true,
    size = true,
    style = true,
    type = true,
}

local TYPE_FIELDS = {
    Button = {
        text = true,
    },
    DropDown = {
        maxVisibleItems = true,
    },
    Frame = {},
    Image = {
        path = true,
        scaleToFit = true,
        sourceRect = true,
    },
    LayoutGroup = {
        absoluteSpacing = true,
        childAnchor = true,
        direction = true,
        relativeSpacing = true,
        stretch = true,
    },
    ListBox = {
        autoHideScrollBar = true,
        isHorizontal = true,
        keepSpaceForScrollBar = true,
        spacing = true,
    },
    ScissorComponent = {},
    ScrollBar = {
        barSize = true,
        range = true,
        step = true,
    },
    TextBlock = {
        alignment = true,
        text = true,
        textColor = true,
        textScale = true,
    },
    TickBox = {
        text = true,
    },
}

local BANNED_FIELDS = {
    action = true,
    binding = true,
    enabled = true,
    items = true,
    onClick = true,
    openUrl = true,
    placeholder = true,
    selected = true,
    value = true,
    visible = true,
}

local ANCHORS = {
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

local ALIGNMENTS = {
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

local DIRECTIONS = {
    horizontal = true,
    vertical = true,
}

---Returns initialized dependencies or fails on a composition-root wiring error.
---@private
---@return errors.Lib
---@return ui_runtime.Error
local function get_dependencies()
    if validator.deps.errors == nil or validator.deps.ERROR == nil then
        error("ui_runtime validator.init must be called before validator is used", 0)
    end

    return validator.deps.errors, validator.deps.ERROR
end

---Raises one validation error with a stable root cause and concrete layout path.
---@private
---@param root_cause string
---@param path string
---@param message string
local function fail(root_cause, path, message)
    local errors = get_dependencies()
    error(errors.wrap(string.format("validate UI layout at %s: %s", path, message), errors.new(root_cause)), 0)
end

---Initializes validator dependencies.
---@param dependencies ui_runtime.InternalDependencies
---@return ui_runtime.Validator
function validator.init(dependencies)
    if dependencies == nil then
        error("ui_runtime validator dependencies are required", 0)
    end

    if dependencies.errors == nil then
        error("ui_runtime validator dependency errors is required", 0)
    end

    if dependencies.ERROR == nil then
        error("ui_runtime validator dependency ERROR is required", 0)
    end

    validator.deps.errors = dependencies.errors
    validator.deps.ERROR = dependencies.ERROR

    return validator
end

---Checks that value is a non-empty string.
---@private
---@param value any
---@return boolean
local function is_non_empty_string(value)
    return type(value) == "string" and value ~= ""
end

---Checks that value is a dense Lua array.
---@private
---@param value any
---@return boolean
local function is_array(value)
    if type(value) ~= "table" then
        return false
    end

    local count = 0
    for key in pairs(value) do
        if type(key) ~= "number" or math.floor(key) ~= key or key < 1 then
            return false
        end
        count = count + 1
    end

    return count == #value
end

---Checks that value is an array with exactly count numbers.
---@private
---@param value any
---@param count integer
---@return boolean
local function is_number_array(value, count)
    if not is_array(value) or #value ~= count then
        return false
    end

    for index = 1, count do
        if type(value[index]) ~= "number" then
            return false
        end
    end

    return true
end

---Validates an optional string field.
---@private
---@param node table
---@param field string
---@param path string
local function validate_optional_string(node, field, path)
    local _, ERROR = get_dependencies()
    if node[field] ~= nil and type(node[field]) ~= "string" then
        fail(ERROR.string_required, path .. "." .. field, "field must be a string")
    end
end

---Validates an optional non-empty string field.
---@private
---@param node table
---@param field string
---@param path string
local function validate_optional_non_empty_string(node, field, path)
    local _, ERROR = get_dependencies()
    if node[field] ~= nil and not is_non_empty_string(node[field]) then
        fail(ERROR.string_required, path .. "." .. field, "field must be a non-empty string")
    end
end

---Validates an optional number field.
---@private
---@param node table
---@param field string
---@param path string
local function validate_optional_number(node, field, path)
    local _, ERROR = get_dependencies()
    if node[field] ~= nil and type(node[field]) ~= "number" then
        fail(ERROR.number_required, path .. "." .. field, "field must be a number")
    end
end

---Validates a required number field.
---@private
---@param node table
---@param field string
---@param path string
local function validate_required_number(node, field, path)
    local _, ERROR = get_dependencies()
    if type(node[field]) ~= "number" then
        fail(ERROR.number_required, path .. "." .. field, "field must be a number")
    end
end

---Validates an optional boolean field.
---@private
---@param node table
---@param field string
---@param path string
local function validate_optional_boolean(node, field, path)
    local _, ERROR = get_dependencies()
    if node[field] ~= nil and type(node[field]) ~= "boolean" then
        fail(ERROR.boolean_required, path .. "." .. field, "field must be a boolean")
    end
end

---Validates an optional enum string field.
---@private
---@param node table
---@param field string
---@param allowed table<string, boolean>
---@param path string
local function validate_optional_enum(node, field, allowed, path)
    local _, ERROR = get_dependencies()
    if node[field] ~= nil and (type(node[field]) ~= "string" or allowed[node[field]] ~= true) then
        fail(ERROR.enum_invalid, path .. "." .. field, "field has an unknown enum value")
    end
end

---Validates fields shared by all node types.
---@private
---@param node table
---@param path string
local function validate_common_fields(node, path)
    local _, ERROR = get_dependencies()
    if node.size ~= nil and node.fixedSize ~= nil then
        fail(ERROR.size_conflict, path, "use size or fixedSize, not both")
    end
    if node.size == nil and node.fixedSize == nil then
        fail(ERROR.size_required, path, "size or fixedSize is required")
    end
    if node.size ~= nil and not is_number_array(node.size, 2) then
        fail(ERROR.number_pair_required, path .. ".size", "size must be [number, number]")
    end
    if node.fixedSize ~= nil and not is_number_array(node.fixedSize, 2) then
        fail(ERROR.number_pair_required, path .. ".fixedSize", "fixedSize must be [number, number]")
    end
    if node.absoluteOffset ~= nil and not is_number_array(node.absoluteOffset, 2) then
        fail(ERROR.number_pair_required, path .. ".absoluteOffset", "absoluteOffset must be [number, number]")
    end
    if node.color ~= nil and not is_number_array(node.color, 4) then
        fail(ERROR.color_required, path .. ".color", "color must be [r, g, b, a]")
    end
    if node.hoverColor ~= nil and not is_number_array(node.hoverColor, 4) then
        fail(ERROR.color_required, path .. ".hoverColor", "hoverColor must be [r, g, b, a]")
    end
    if node.selectedColor ~= nil and not is_number_array(node.selectedColor, 4) then
        fail(ERROR.color_required, path .. ".selectedColor", "selectedColor must be [r, g, b, a]")
    end
    if node.children ~= nil and not is_array(node.children) then
        fail(ERROR.children_array_required, path .. ".children", "children must be an array")
    end

    validate_optional_enum(node, "anchor", ANCHORS, path)
    validate_optional_enum(node, "pivot", ANCHORS, path)
    validate_optional_boolean(node, "canBeFocused", path)
    validate_optional_string(node, "style", path)
end

---Validates type-specific fields.
---@private
---@param node table
---@param path string
local function validate_type_fields(node, path)
    local _, ERROR = get_dependencies()
    if node.type == "Button" or node.type == "TickBox" then
        validate_optional_string(node, "text", path)
    elseif node.type == "DropDown" then
        validate_required_number(node, "maxVisibleItems", path)
    elseif node.type == "Image" then
        validate_optional_non_empty_string(node, "path", path)
        validate_optional_boolean(node, "scaleToFit", path)
        if node.sourceRect ~= nil and not is_number_array(node.sourceRect, 4) then
            fail(
                ERROR.number_quad_required,
                path .. ".sourceRect",
                "sourceRect must be [number, number, number, number]"
            )
        end
    elseif node.type == "LayoutGroup" then
        validate_optional_enum(node, "childAnchor", ANCHORS, path)
        validate_optional_enum(node, "direction", DIRECTIONS, path)
        validate_optional_boolean(node, "stretch", path)
        validate_optional_number(node, "relativeSpacing", path)
        validate_optional_number(node, "absoluteSpacing", path)
    elseif node.type == "ListBox" then
        validate_optional_boolean(node, "autoHideScrollBar", path)
        validate_optional_boolean(node, "isHorizontal", path)
        validate_optional_boolean(node, "keepSpaceForScrollBar", path)
        validate_optional_number(node, "spacing", path)
    elseif node.type == "ScrollBar" then
        validate_required_number(node, "barSize", path)
        if node.range ~= nil and not is_number_array(node.range, 2) then
            fail(ERROR.number_pair_required, path .. ".range", "range must be [number, number]")
        end
        validate_optional_number(node, "step", path)
    elseif node.type == "TextBlock" then
        validate_optional_enum(node, "alignment", ALIGNMENTS, path)
        validate_optional_string(node, "text", path)
        validate_optional_number(node, "textScale", path)
        if node.textColor ~= nil and not is_number_array(node.textColor, 4) then
            fail(ERROR.color_required, path .. ".textColor", "textColor must be [r, g, b, a]")
        end
    end
end

---Validates one node and its descendants.
---@private
---@param node table
---@param path string
local function validate_node(node, path)
    local _, ERROR = get_dependencies()
    if type(node) ~= "table" then
        fail(ERROR.node_required, path, "node must be an object")
    end

    if not is_non_empty_string(node.type) or NODE_TYPES[node.type] ~= true then
        fail(ERROR.node_type_invalid, path, "unknown or missing type")
    end

    if not is_non_empty_string(node.id) then
        fail(ERROR.node_id_required, path, "missing id")
    end

    local type_fields = TYPE_FIELDS[node.type]
    for key in pairs(node) do
        if BANNED_FIELDS[key] == true then
            fail(ERROR.dynamic_field, path .. "." .. tostring(key), "dynamic field is not allowed")
        end
        if COMMON_FIELDS[key] ~= true and type_fields[key] ~= true then
            fail(ERROR.unknown_field, path .. "." .. tostring(key), "unknown field")
        end
    end

    validate_common_fields(node, path)
    validate_type_fields(node, path)

    local child_ids = {}
    if type(node.children) == "table" then
        for index, child in ipairs(node.children) do
            if type(child) ~= "table" then
                fail(ERROR.node_required, path .. ".children[" .. tostring(index) .. "]", "child must be an object")
            end
            if child.id ~= nil then
                local child_id = tostring(child.id)
                if child_ids[child_id] == true then
                    fail(ERROR.duplicate_child_id, path, "duplicate child id: " .. child_id)
                end
                child_ids[child_id] = true
            end
            validate_node(child, path .. "." .. tostring(child.id or index))
        end
    end
end

---Validates one parsed UI layout.
---@param layout table
---@throws errors.Error
function validator.validate(layout)
    local _, ERROR = get_dependencies()
    if type(layout) ~= "table" then
        fail(ERROR.layout_required, "$", "layout must be an object")
    end
    if layout.schema ~= SCHEMA then
        fail(ERROR.schema_invalid, "$.schema", "schema must be " .. SCHEMA)
    end
    for key in pairs(layout) do
        if key ~= "schema" and key ~= "root" and key ~= "templates" then
            fail(ERROR.unknown_top_level_field, "$." .. tostring(key), "unknown top-level field")
        end
    end
    validate_node(layout.root, "$.root")

    if layout.templates ~= nil and type(layout.templates) ~= "table" then
        fail(ERROR.templates_required, "$.templates", "templates must be an object")
    end
    if type(layout.templates) == "table" then
        for name, template in pairs(layout.templates) do
            if not is_non_empty_string(name) then
                fail(ERROR.template_name_required, "$.templates", "template name must be a non-empty string")
            end
            validate_node(template, "$.templates." .. tostring(name))
        end
    end
end

return validator
