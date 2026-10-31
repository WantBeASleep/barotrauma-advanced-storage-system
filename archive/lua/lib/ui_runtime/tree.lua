---@type ui_runtime.TreeClass
local Tree = {
    deps = {},
}
Tree.__index = Tree

---Returns initialized dependencies or fails on a composition-root wiring error.
---@private
---@return errors.Lib
---@return ui_runtime.Error
local function get_dependencies()
    if Tree.deps.errors == nil or Tree.deps.ERROR == nil then
        error("ui_runtime Tree.init must be called before Tree is used", 0)
    end

    return Tree.deps.errors, Tree.deps.ERROR
end

---Raises one tree error with lookup context.
---@private
---@param root_cause string
---@param context string
local function raise_tree_error(root_cause, context)
    local errors = get_dependencies()
    error(errors.wrap(context, errors.new(root_cause)), 0)
end

---Initializes tree dependencies.
---@param dependencies ui_runtime.InternalDependencies
---@return ui_runtime.TreeClass
function Tree.init(dependencies)
    if dependencies == nil then
        error("ui_runtime Tree dependencies are required", 0)
    end

    if dependencies.errors == nil then
        error("ui_runtime Tree dependency errors is required", 0)
    end

    if dependencies.ERROR == nil then
        error("ui_runtime Tree dependency ERROR is required", 0)
    end

    Tree.deps.errors = dependencies.errors
    Tree.deps.ERROR = dependencies.ERROR

    return Tree
end

---Creates one rendered UI tree.
---@param root ui_runtime.Node
---@param templates table<string, table>
---@param diagnostics ui_runtime.Diagnostics
---@return ui_runtime.Tree
function Tree.new(root, templates, diagnostics)
    ---@type ui_runtime.Tree
    local tree = {
        root = root,
        templates = templates,
        diagnostics = diagnostics,
        instantiate = nil,
    }

    return setmetatable(tree, Tree)
end

---Returns a required node by root-relative dot path.
---@param path string
---@return ui_runtime.Node
---@throws errors.Error
function Tree:get(path)
    local root_id = self.root.id
    if path == root_id then
        return self.root
    end
    local prefix = root_id .. "."
    if string.sub(path, 1, #prefix) == prefix then
        return self.root:get(string.sub(path, #prefix + 1))
    end
    return self.root:get(path)
end

---Returns a node by root-relative dot path when it exists.
---@param path string
---@return ui_runtime.Node|nil
function Tree:maybe(path)
    local root_id = self.root.id
    if path == root_id then
        return self.root
    end
    local prefix = root_id .. "."
    if string.sub(path, 1, #prefix) == prefix then
        return self.root:maybe(string.sub(path, #prefix + 1))
    end
    return self.root:maybe(path)
end

---Creates one template instance under a rendered parent node.
---@param template_name string
---@param parent ui_runtime.Node|ui_runtime.ContainerAdapter
---@return ui_runtime.Node
---@throws errors.Error
function Tree:create(template_name, parent)
    local _, ERROR = get_dependencies()
    if self.instantiate == nil then
        raise_tree_error(ERROR.tree_instantiator_required, "create UI template: " .. tostring(template_name))
    end

    local parent_node = parent
    if type(parent) == "table" and parent._node ~= nil then
        parent_node = parent._node
    end

    return self.instantiate(template_name, parent_node)
end

return Tree
